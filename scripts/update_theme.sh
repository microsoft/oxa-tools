#!/bin/bash
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.
set -x

THEME_PATH=/edx/app/edxapp/themes
THEME_REPO=https://github.com/microsoft/edx-theme.git

if [[ ! -d $THEME_PATH ]]; then
  mkdir -p $THEME_PATH
fi

cd $THEME_PATH
git clone -b pilot $THEME_REPO default

chown -R edxapp:edxapp $THEME_REPO
sudo su edxapp -s /bin/bash
source /edx/app/edxapp/edxapp_env
cd /edx/app/edxapp/edx-platform/
paver update_assets lms --settings aws
sudo su openedxuser -s /bin/bash
sudo /edx/bin/supervisorctl restart edxapp:




 

