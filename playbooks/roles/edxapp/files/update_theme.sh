#!/bin/bash
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

set -ex

THEME_BRANCH=$1
EDX_THEME_REPO=$2
ENVIRONMENT=$3

dir_edxapp=/edx/app/edxapp
dir_themes=${dir_edxapp}/themes

# Remove if themes folder exists
if [[ -d $dir_themes ]] ; then
    sudo rm -fr $dir_themes
fi

cd $dir_edxapp

# Download comprehensive theming from github to folder $dir_themes/comprehensive 
sudo git clone $EDX_THEME_REPO $dir_themes -b $THEME_BRANCH

# todo:100627 this doesn't work on onebox installations (fullstack and devstack) which don't use oxa-tools-config
if [[ -n $ENVIRONMENT ]] ; then
    for i in `ls -d1 $dir_themes/*/lms/static/images`; do
        sudo cp /oxa/oxa-tools-config/env/$ENVIRONMENT/*.png $i;
    done
fi
    
sudo chown -R edxapp:edxapp $dir_themes
sudo chmod -R u+rw $dir_themes

# Compile LMS assets and then restart the services so that changes take effect
sudo su edxapp -s /bin/bash -c "source $dir_edxapp/edxapp_env;cd $dir_edxapp/edx-platform/;paver update_assets lms --settings aws"
sudo /edx/bin/supervisorctl restart edxapp:
