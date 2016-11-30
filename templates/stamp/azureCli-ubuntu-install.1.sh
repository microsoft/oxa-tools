#!/bin/bash
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

#todo:temp file for validation

source ./utilities.sh

  exit_if_limited_user

  install-azure-cli
  install-mongodb-shell
  install-mysql-client
  install-json-processor


OXA_PATH=/oxa
DEPLOYMENT_ENV=bvt
TEMPLATE_TYPE=stamp
ADMIN_USER=lexoxaadmin
ANSIBLE_PLAYBOOK=ansible-playbook

OXA_TOOLS_PATH=$OXA_PATH/oxa-tools
OXA_PLAYBOOK=$OXA_TOOLS_PATH/playbooks/oxa_configuration.yml
OXA_TOOLS_CONFIG_PATH=$OXA_PATH/oxa-tools-config
OXA_ENV_FILE=$OXA_TOOLS_CONFIG_PATH/env/$DEPLOYMENT_ENV/$DEPLOYMENT_ENV.sh
OXA_PLAYBOOK_ARGS="-e oxa_tools_path=$OXA_TOOLS_PATH -e oxa_env_file=$OXA_ENV_FILE -e admin_user=$ADMIN_USER"

    # aggregate edx configuration with deployment environment expansion
    # warning: beware of yaml variable dependencies due to order of aggregation
    echo "---" > $OXA_PLAYBOOK_CONFIG
    for config in $OXA_TOOLS_PATH/config/$TEMPLATE_TYPE/*.yml $OXA_TOOLS_PATH/config/*.yml; do
        sed -e "s/%%\([^%]*\)%%/$\{\\1\}/g" -e "s/^---.*$//g" $config | envsubst >> $OXA_PLAYBOOK_CONFIG
    done

echo $ANSIBLE_PLAYBOOK -i localhost, -c local -e@$OXA_PLAYBOOK_CONFIG $OXA_PLAYBOOK_ARGS $OXA_PLAYBOOK --tags "jumpbox"
$ANSIBLE_PLAYBOOK -i localhost, -c local -e@$OXA_PLAYBOOK_CONFIG $OXA_PLAYBOOK_ARGS $OXA_PLAYBOOK --tags "jumpbox"
