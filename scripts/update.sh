#!/bin/bash
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.
set -x

EDX_ROLE=${1:-edxapp}

OXA_TOOLS_PATH=/oxa/oxa-tools
OXA_CONFIG_PATH=/oxa/configuration

setup() {
  if [[ ! -d $OXA_CONFIG_PATH ]]; then
    wget https://raw.githubusercontent.com/edx/configuration/master/util/install/ansible-bootstrap.sh -O- | bash

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

ANSIBLE_ARGS='-i localhost, -c local -e@$OXA_TOOLS_PATH/config/server-vars.yml -e@$OXA_TOOLS_PATH/edx-versions.yml'
case "$EDX_ROLE" in
  mongo)
    setup
    sudo ansible-playbook edx_mongo.yml $ANSIBLE_ARGS
    ;;
  mysql)
    setup
    sudo ansible-playbook edx_mysql.yml $ANSIBLE_ARGS
    # minimize tags? "install:base,install:system-requirements,install:configuration,install:app-requirements,install:code"
    sudo ansible-playbook edx_sandbox.yml $ANSIBLE_ARGS -e "migrate_db=yes" --tags "edxapp-sandbox,install,migrate"
    ;;
  edxapp)
    setup
    sudo ansible-playbook edx_sandbox.yml $ANSIBLE_ARGS -e "migrate_db=no"
    ;;
  *)
    echo "Usage: $0 [mongo|mysql|edxapp]"
    exit 1
    ;;
esac