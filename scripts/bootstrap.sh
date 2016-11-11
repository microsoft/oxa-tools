#!/bin/bash
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

set -x

# argument defaults
EDX_ROLE=""
DEPLOYMENT_ENV="dev"
ACCESS_TOKEN=""
OXA_TOOLS_CONFIG_VERSION="master"

display_usage() {
  echo "Usage: $0 -a|--access_token {access token} -v|--version {oxa-tools-config version} [-r|--role {jb|vmss|mongo|mysql|edxapp|fullstack}] [-e|--environment {dev|bvt|int|prod}]"
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
        if is_valid_arg "jb vmss mongo mysql edxapp fullstack" $EDX_ROLE; then
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
      -v|--version)
        OXA_TOOLS_CONFIG_VERSION="$2"
        shift # past argument
        ;;
      *)
        # Unknown option encountered
        display_usage
        ;;
    esac

    shift # past argument or value
  done
}

sync_repo() {
  REPO_URL=$1; REPO_VERSION=$2; REPO_PATH=$3
  REPO_TOKEN=$4 # optional

  if [ "$#" -lt 3 ]; then
    echo "sync_repo: invalid number of arguments" && exit 1
  fi
  
  # todo: scorch support?
  
  if [[ ! -d $REPO_PATH ]]; then
    mkdir -p $REPO_PATH
    git clone ${REPO_URL/github/$REPO_TOKEN@github} $REPO_PATH
  fi
  pushd $REPO_PATH && git checkout ${REPO_VERSION:-master} && popd
}

##
## Role-independent OXA environment bootstrap
##
setup() {  
  apt-get -y update
  apt-get -y install git
  
  # sync the private repository
  sync_repo $OXA_TOOLS_CONFIG_REPO $OXA_TOOLS_CONFIG_VERSION $OXA_TOOLS_CONFIG_PATH $ACCESS_TOKEN
  
  # populate the deployment environment
  source $OXA_ENV_FILE
  export $(sed -e 's/#.*$//' $OXA_ENV_FILE | cut -d= -f1)
  export ANSIBLE_REPO=CONFIGURATION_REPO
  export ANSIBLE_VERSION=CONFIGURATION_VERSION
  
  # deployment environment overrides for debugging
  OXA_ENV_OVERRIDE_FILE="$BOOTSTRAP_HOME/overrides.sh"
  if [[ -f $OXA_ENV_OVERRIDE_FILE ]]; then
    source $OXA_ENV_OVERRIDE_FILE
  fi
  export $(sed -e 's/#.*$//' $OXA_ENV_OVERRIDE_FILE | cut -d= -f1)
  
  # sync public repositories
  sync_repo $OXA_TOOLS_REPO $OXA_TOOLS_VERSION $OXA_TOOLS_PATH
  sync_repo $CONFIGURATION_REPO $CONFIGURATION_VERSION $CONFIGURATION_PATH
  
  # run edx bootstrap and install requirements
  cd $CONFIGURATION_PATH
  bash util/install/ansible-bootstrap.sh
  pip install -r requirements.txt
  
  # fix OXA environment ownership
  chown -R $ADMIN_USER:$ADMIN_USER $OXA_PATH
  
  # aggregate edx configuration with deployment environment expansion
  # warning: beware of yaml variable dependencies due to order of aggregation
  echo "---" > $OXA_PLAYBOOK_CONFIG
  for config in $OXA_TOOLS_PATH/config/$TEMPLATE_TYPE/*.yml $OXA_TOOLS_PATH/config/*.yml; do
    sed -e "s/%%\([^%]*\)%%/$\{\\1\}/g" -e "s/^---.*$//g" $config | envsubst >> $OXA_PLAYBOOK_CONFIG
  done
}

##
## Role-based ansible command lines
##

exit_on_error() {
  if [[ $? -ne 0 ]]; then
    echo $1 && exit 1
  fi
}

update_stamp_jb() {    
  # edx playbooks - mysql and memcached
  $ANSIBLE_PLAYBOOK -i ${CLUSTERNAME}mysql1, $OXA_SSH_ARGS -e@$OXA_PLAYBOOK_CONFIG edx_mysql.yml
  exit_on_error "Execution of edX MySQL playbook failed"  
  # minimize tags? "install:base,install:system-requirements,install:configuration,install:app-requirements,install:code"
  $ANSIBLE_PLAYBOOK -i localhost, -c local -e@$OXA_PLAYBOOK_CONFIG edx_sandbox.yml -e "migrate_db=yes" --tags "edxapp-sandbox,install,migrate"
  exit_on_error "Execution of edX MySQL migrations failed"
  
  # oxa playbooks - mongo (enable when customized) and mysql
  #$ANSIBLE_PLAYBOOK -i ${CLUSTERNAME}mongo1, $OXA_SSH_ARGS -e@$OXA_PLAYBOOK_CONFIG $OXA_PLAYBOOK_ARGS $OXA_PLAYBOOK --tags "mongo"
  #exit_on_error "Execution of OXA Mongo playbook failed"
  $ANSIBLE_PLAYBOOK -i ${CLUSTERNAME}mysql1, $OXA_SSH_ARGS -e@$OXA_PLAYBOOK_CONFIG $OXA_PLAYBOOK_ARGS $OXA_PLAYBOOK --tags "mysql"
  exit_on_error "Execution of OXA MySQL playbook failed"
}

update_stamp_vmss() {
  # edx playbooks - sandbox with remote mongo/mysql
  $ANSIBLE_PLAYBOOK -i localhost, -c local -e@$OXA_PLAYBOOK_CONFIG edx_sandbox.yml -e "migrate_db=no" --skip-tags=demo_course
  exit_on_error "Execution of edX sandbox playbook failed"
  
  # oxa playbooks
  $ANSIBLE_PLAYBOOK -i localhost, -c local -e@$OXA_PLAYBOOK_CONFIG $OXA_PLAYBOOK_ARGS $OXA_PLAYBOOK --tags "edxapp"
  exit_on_error "Execution of OXA edxapp playbook failed"
}

update_scalable_mongo() {
  # edx playbooks - mongo
  $ANSIBLE_PLAYBOOK -i localhost, -c local -e@$OXA_PLAYBOOK_CONFIG edx_mongo.yml
  exit_on_error "Execution of edX Mongo playbook failed"
  
  # oxa playbooks - mongo (enable when customized)
  #$ANSIBLE_PLAYBOOK -i localhost, -c local -e@$OXA_PLAYBOOK_CONFIG $OXA_PLAYBOOK_ARGS $OXA_PLAYBOOK --tags "mongo"
  #exit_on_error "Execution of OXA Mongo playbook failed"
}

update_scalable_mysql() {
  # edx playbooks - mysql and memcached
  $ANSIBLE_PLAYBOOK -i localhost, -c local -e@$OXA_PLAYBOOK_CONFIG edx_mysql.yml
  exit_on_error "Execution of edX MySQL playbook failed"  
  # minimize tags? "install:base,install:system-requirements,install:configuration,install:app-requirements,install:code"
  $ANSIBLE_PLAYBOOK -i localhost, -c local -e@$OXA_PLAYBOOK_CONFIG edx_sandbox.yml -e "migrate_db=yes" --tags "edxapp-sandbox,install,migrate"
  exit_on_error "Execution of edX MySQL migrations failed"
  
  # oxa playbooks - mysql
  $ANSIBLE_PLAYBOOK -i localhost, -c local -e@$OXA_PLAYBOOK_CONFIG $OXA_PLAYBOOK_ARGS $OXA_PLAYBOOK --tags "mysql"
  exit_on_error "Execution of OXA MySQL playbook failed"
}

update_fullstack() {
  # edx playbooks - fullstack (single VM)
  $ANSIBLE_PLAYBOOK -i localhost, -c local -e@$OXA_PLAYBOOK_CONFIG vagrant-fullstack.yml
  exit_on_error "Execution of edX fullstack playbook failed"

  # oxa playbooks - all (single VM)
  $ANSIBLE_PLAYBOOK -i localhost, -c local -e@$OXA_PLAYBOOK_CONFIG $OXA_PLAYBOOK_ARGS $OXA_PLAYBOOK
  exit_on_error "Execution of OXA playbook failed"
}

parse_args $@ # pass existing command line arguments

##
## Execute role-independent OXA environment bootstrap
##
BOOTSTRAP_HOME=$(readlink -f $(dirname $0))
OXA_PATH=/oxa
OXA_TOOLS_REPO="https://github.com/microsoft/oxa-tools.git"
OXA_TOOLS_PATH=$OXA_PATH/oxa-tools
OXA_TOOLS_CONFIG_REPO="https://github.com/microsoft/oxa-tools-config.git"
OXA_TOOLS_CONFIG_PATH=$OXA_PATH/oxa-tools-config
CONFIGURATION_PATH=$OXA_PATH/configuration
OXA_ENV_FILE=$OXA_TOOLS_CONFIG_PATH/env/$DEPLOYMENT_ENV/$DEPLOYMENT_ENV.sh
OXA_PLAYBOOK_CONFIG=$OXA_PATH/oxa.yml

setup

##
## Execute role-based automation (edX and OXA playbooks)
## stamp note: assumes DB installations and SSH keys are already in place
##
PATH=$PATH:/edx/bin
ANSIBLE_PLAYBOOK=ansible-playbook
OXA_PLAYBOOK=$OXA_TOOLS_PATH/playbooks/oxa_configuration.yml
OXA_PLAYBOOK_ARGS="-e oxa_tools_path=$OXA_TOOLS_PATH -e oxa_tools_config_path=$OXA_TOOLS_CONFIG_PATH"
OXA_SSH_ARGS="-u $OXA_ADMIN_USER --private-key=/home/$OXA_ADMIN_USER/.ssh/id_rsa"

# Fixes error: RPC failed; result=56, HTTP code = 0'
# fatal: The remote end hung up unexpectedly
git config --global http.postBuffer 1048576000

cd $CONFIGURATION_PATH/playbooks
case "$EDX_ROLE" in
  jb)
    update_stamp_jb
    ;;
  vmss)
    update_stamp_vmss
    ;;
  edxapp)
    # scalable and stamp vmss are equivalent; can combine vmss and edxapp once stamp is ready
    update_stamp_vmss
    ;;
  mongo)
    update_scalable_mongo
    ;;
  mysql)
    update_scalable_mysql
    ;;
  fullstack)
    update_fullstack
    ;;
  *)
    display_usage
    ;;
esac

echo "OXA bootstrap complete"
