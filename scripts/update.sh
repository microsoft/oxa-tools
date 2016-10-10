#!/bin/bash
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.
set -x

EDX_ROLE=${1:-edxapp}

OXA_TOOLS_PATH=/oxa/oxa-tools
OXA_CONFIG_PATH=/oxa/configuration

setup() {
  if [[ ! -d $OXA_CONFIG_PATH ]]; then
    wget https://raw.githubusercontent.com/edx/configuration/master/util/install/ansible-bootstrap.sh -O - | bash

    # must match $OXA_TOOLS_PATH/config/edx-versions.yml for now
    CONFIGURATION_REPO=https://github.com/Microsoft/edx-configuration.git
    CONFIGURATION_VERSION="lex/scalable-dogwood"

    git clone $CONFIGURATION_REPO $OXA_CONFIG_PATH
    cd $OXA_CONFIG_PATH
    git checkout $CONFIGURATION_VERSION

    pip install -r requirements.txt
  fi
  
  cd $OXA_CONFIG_PATH/playbooks
}

ANSIBLE_ARGS="-i localhost, -c local -e @$OXA_TOOLS_PATH/config/server-vars.yml -e @$OXA_TOOLS_PATH/config/edx-versions.yml"
ANSIBLE_ARGS_SCALABLE="$ANSIBLE_ARGS -e @$OXA_TOOLS_PATH/config/scalable.yml"
ANSIBLE_ARGS_OXA_CONFIG="-i localhost, -c local -e oxa_tools_path=$OXA_TOOLS_PATH"
case "$EDX_ROLE" in
  mongo)
    setup
    sudo ansible-playbook edx_mongo.yml $ANSIBLE_ARGS_SCALABLE
    #sudo ansible-playbook $OXA_TOOLS_PATH/playbooks/oxa_configuration.yml $ANSIBLE_ARGS_OXA_CONFIG --tags "mongo"
    ;;
  mysql)
    setup
    sudo ansible-playbook edx_mysql.yml $ANSIBLE_ARGS_SCALABLE
    # minimize tags? "install:base,install:system-requirements,install:configuration,install:app-requirements,install:code"
    sudo ansible-playbook edx_sandbox.yml $ANSIBLE_ARGS_SCALABLE -e "migrate_db=yes" --tags "edxapp-sandbox,install,migrate"
    sudo ansible-playbook $OXA_TOOLS_PATH/playbooks/oxa_configuration.yml $ANSIBLE_ARGS_OXA_CONFIG --tags "mysql"
    ;;
  edxapp)
    setup
    # Fixes error: RPC failed; result=56, HTTP code = 0'
    # fatal: The remote end hung up unexpectedly
    git config --global http.postBuffer 1048576000
    sudo ansible-playbook edx_sandbox.yml $ANSIBLE_ARGS_SCALABLE -e "migrate_db=no" --tags "edxapp"
    #sudo ansible-playbook $OXA_TOOLS_PATH/playbooks/oxa_configuration.yml $ANSIBLE_ARGS_OXA_CONFIG --tags "edxapp"
    ;;
  fullstack)
    setup
    #sudo ansible-playbook vagrant-fullstack.yml $ANSIBLE_ARGS
    sudo ansible-playbook $OXA_TOOLS_PATH/playbooks/oxa_configuration.yml $ANSIBLE_ARGS_OXA_CONFIG
    ;;
  *)
    echo "Usage: $0 [mongo|mysql|edxapp|fullstack]"
    exit 1
    ;;
esac
