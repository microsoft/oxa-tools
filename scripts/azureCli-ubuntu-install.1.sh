#!/bin/bash
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

#todo:temp file for validation

OXA_PATH=/oxa
OXA_TOOLS_PATH=$OXA_PATH/oxa-tools

source $OXA_TOOLS_PATH/templates/stamp/utilities.sh

exit_if_limited_user

install-azure-cli
install-mongodb-shell
install-mysql-client
install-json-processor

DEPLOYMENT_ENV=bvt
TEMPLATE_TYPE=stamp
ADMIN_USER=lexoxaadmin
ANSIBLE_PLAYBOOK=ansible-playbook

OXA_PLAYBOOK=$OXA_TOOLS_PATH/playbooks/oxa_configuration.yml
OXA_TOOLS_CONFIG_PATH=$OXA_PATH/oxa-tools-config
OXA_ENV_FILE=$OXA_TOOLS_CONFIG_PATH/env/$DEPLOYMENT_ENV/$DEPLOYMENT_ENV.sh
OXA_PLAYBOOK_ARGS="-e oxa_tools_path=$OXA_TOOLS_PATH -e oxa_env_file=$OXA_ENV_FILE -e admin_user=$ADMIN_USER"

echo $ANSIBLE_PLAYBOOK -i localhost, -c local $OXA_PLAYBOOK_ARGS $OXA_PLAYBOOK --tags "jumpbox"

$ANSIBLE_PLAYBOOK -i localhost, -c local $OXA_PLAYBOOK_ARGS $OXA_PLAYBOOK --tags "jumpbox"
