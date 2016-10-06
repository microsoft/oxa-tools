#!/bin/bash
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.
set -x

sudo cp server-vars.yml /edx/app/edx_ansible/
sudo chown edx-ansible:edx-ansible /edx/app/edx_ansible/server-vars.yml

cd /tmp/configuration/playbooks
sudo ansible-playbook -i localhost, -c local vagrant-fullstack.yml -e@/edx/app/edx_ansible/server-vars.yml -e@/edx/app/edx_ansible/extra-vars.yml -t 'edxapp_cfg,gather_static_assets'

THEME_PATH=/edx/app/edxapp/themes
THEME_REPO=https://github.com/microsoft/edx-theme.git

if [[ -d $THEME_PATH ]]; then
  sudo rm -fr $THEME_PATH
fi

sudo mkdir -p $THEME_PATH

cd $THEME_PATH
git clone -b pilot $THEME_REPO default

sudo chown -R edxapp:edxapp $THEME_PATH
sudo su edxapp -s /bin/bash -c "source /edx/app/edxapp/edxapp_env;cd /edx/app/edxapp/edx-platform/;paver update_assets lms --settings aws"
sudo /edx/bin/supervisorctl restart edxapp:
echo "Huseyin -> Finished applying Microsoft Stanford Theming." 

