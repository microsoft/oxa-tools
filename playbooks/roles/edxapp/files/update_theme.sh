#!/bin/bash
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

set -ex

THEME_BRANCH=$1
EDX_THEME_REPO=$2
ENVIRONMENT=$3
THEMES_DIRECTORY=$4

themes_parent_directory="$(dirname "${THEMES_DIRECTORY}")"
edxapp_directory="/edx/app/edxapp"

# Check if the base directory exists.
# This is user specified now
if [[ ! -d $themes_parent_directory ]] ; then
    sudo mkdir -p $themes_parent_directory
fi

# Remove the themes folder if it exists
if [[ -d $THEMES_DIRECTORY ]] ; then
    sudo rm -fr $THEMES_DIRECTORY
fi

# Download comprehensive theming from github to folder $dir_themes/comprehensive 
sudo git clone $EDX_THEME_REPO $THEMES_DIRECTORY -b $THEME_BRANCH

# Generalizing - Applying custom images isn't applicable for all scenarios. 
# Therefore, it is necessary to first check if custom images are available 
# before attempting to copy them.
custom_image_count=`ls /oxa/oxa-tools-config/env/${ENVIRONMENT}/*.png 2>/dev/null | wc -w`

if (( $(echo "$custom_image_count > 0" | bc -l) )); then
    for i in `ls -d1 $dir_themes/*/lms/static/images`; do
        sudo cp /oxa/oxa-tools-config/env/$ENVIRONMENT/*.png $i;
    done
fi

# set appropriate permissions on the new theming folder
sudo chown -R edxapp:edxapp $THEMES_DIRECTORY
sudo chmod -R u+rw $THEMES_DIRECTORY

# Compile LMS assets and then restart the services so that changes take effect
sudo su edxapp -s /bin/bash -c "source $edxapp_directory/edxapp_env;cd $edxapp_directory/edx-platform/;paver update_assets lms --settings aws"
sudo /edx/bin/supervisorctl restart edxapp: