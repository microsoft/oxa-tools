#!/bin/bash
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.
set -x

EDX_ROLE="edxapp"
DEPLOYMENT_ENV="dev"
ACCESS_TOKEN=""

OXA_PATH=/oxa
OXA_TOOLS_PATH=$OXA_PATH/oxa-tools
OXA_CONFIG_PATH=$OXA_PATH/edx-configuration
OXA_ENV_SETTINGS_PATH=$OXA_PATH/oxa-tools-config

display_usage() {
  echo "Usage: $0 -a|--access_token {access token} [-r|--role {mongo|mysql|edxapp|fullstack}] [-e|--environment {dev|bvt|int|prod}]"
  exit 1
}

is_valid_arg() {
  local list="$1"
  local arg="$2"

  if [[ $list =~ (^|[[:space:]])"$arg"($|[[:space:]]) ]] ; then
    result=0
  else
    result=1
  fi

  return $result
}

parse_args() {
  while [[ "$#" -gt 0 ]]
  do
    case "$1" in
      -r|--role)
        EDX_ROLE="${2,,}" # convert to lowercase
        if is_valid_arg "mongo mysql edxapp fullstack" $EDX_ROLE; then
          shift # past argument
        else
          echo "Invalid role specified\n"
          display_usage
        fi
        ;;
      -e|--environment)
        DEPLOYMENT_ENV="${2,,}" # convert to lowercase
        if is_valid_arg "dev bvt int prod" $DEPLOYMENT_ENV; then
          shift # past argument
        else
          echo "Invalid environment specified\n"
          display_usage
        fi
        ;;
      -a|--access_token)
        ACCESS_TOKEN="$2"
        if [[ ${#ACCESS_TOKEN} -eq 40 ]]; then
          shift # past argument
        else
          echo "Invalid access token specified\n"
          display_usage
        fi
        ;;
      *)
        # Unknown option encountered
        display_usage
        ;;
    esac

    shift # past argument or value
  done
}

setup() {
  if [[ ! -d $OXA_ENV_SETTINGS_PATH ]]; then
    cd $OXA_PATH

    # Fetch the latest secrets from the private repo via a personal access token
    # this will create $OXA_ENV_SETTINGS_PATH directory.
    sudo git clone -b master https://$ACCESS_TOKEN@github.com/microsoft/oxa-tools-config.git
  fi
  source $OXA_ENV_SETTINGS_PATH/env/$DEPLOYMENT_ENV/$DEPLOYMENT_ENV.sh
  export CONFIGURATION_REPO CONFIGURATION_VERSION

  if [[ ! -d $OXA_CONFIG_PATH ]]; then
    sudo git clone -b $CONFIGURATION_VERSION $CONFIGURATION_REPO $OXA_CONFIG_PATH
    cd $OXA_CONFIG_PATH

    # install ansible
    util/install/ansible-bootstrap.sh

    pip install -r requirements.txt
  fi

  # Apply secrets to the configuration file
  bash $OXA_TOOLS_PATH/scripts/replace.sh $OXA_ENV_SETTINGS_PATH/env/$DEPLOYMENT_ENV/$DEPLOYMENT_ENV.sh $OXA_TOOLS_PATH/config/server-vars.yml
  bash $OXA_TOOLS_PATH/scripts/replace.sh $OXA_ENV_SETTINGS_PATH/env/$DEPLOYMENT_ENV/$DEPLOYMENT_ENV.sh $OXA_TOOLS_PATH/config/edx-versions.yml

  cd $OXA_CONFIG_PATH/playbooks
}

update() {
  local ANSIBLE_ARGS="-i localhost, -c local -e @$OXA_TOOLS_PATH/config/server-vars.yml -e @$OXA_TOOLS_PATH/config/edx-versions.yml"
  local ANSIBLE_ARGS_SCALABLE="$ANSIBLE_ARGS -e @$OXA_TOOLS_PATH/config/scalable.yml"
  local ANSIBLE_ARGS_OXA_CONFIG="-i localhost, -c local -e oxa_tools_path=$OXA_TOOLS_PATH"

  case "$EDX_ROLE" in
    mongo)
      sudo ansible-playbook edx_mongo.yml $ANSIBLE_ARGS_SCALABLE
      #sudo ansible-playbook $OXA_TOOLS_PATH/playbooks/oxa_configuration.yml $ANSIBLE_ARGS_OXA_CONFIG --tags "mongo"
      ;;
    mysql)
      sudo ansible-playbook edx_mysql.yml $ANSIBLE_ARGS_SCALABLE
      # minimize tags? "install:base,install:system-requirements,install:configuration,install:app-requirements,install:code"
      sudo ansible-playbook edx_sandbox.yml $ANSIBLE_ARGS_SCALABLE -e "migrate_db=yes" --tags "edxapp-sandbox,install,migrate"
      sudo ansible-playbook $OXA_TOOLS_PATH/playbooks/oxa_configuration.yml $ANSIBLE_ARGS_OXA_CONFIG --tags "mysql"
      ;;
    edxapp)
      # Fixes error: RPC failed; result=56, HTTP code = 0'
      # fatal: The remote end hung up unexpectedly
      git config --global http.postBuffer 1048576000
      sudo ansible-playbook edx_sandbox.yml $ANSIBLE_ARGS_SCALABLE -e "migrate_db=no"
      sudo ansible-playbook $OXA_TOOLS_PATH/playbooks/oxa_configuration.yml $ANSIBLE_ARGS_OXA_CONFIG --tags "edxapp"
      ;;
    fullstack)
      sudo ansible-playbook vagrant-fullstack.yml $ANSIBLE_ARGS
      sudo ansible-playbook $OXA_TOOLS_PATH/playbooks/oxa_configuration.yml $ANSIBLE_ARGS_OXA_CONFIG
      ;;
    *)
      display_usage
      ;;
  esac
}

parse_args $@ # pass existing command line arguments
setup
update
