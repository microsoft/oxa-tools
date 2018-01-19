#!/bin/bash
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

set -ex

THEME_BRANCH=$1
EDX_THEME_REPO=$2
ENVIRONMENT=$3
THEME_DIRECTORY_YAML=$4
OXA_TOOLS_PATH=$5
OXA_TOOLS_CONFIG_PATH=$6
edx_platform_path=$7
edxapp_directory=$(dirname $edx_platform_path)

src_utils()
{
    pushd $OXA_TOOLS_PATH

    echo "source utilities"
    source templates/stamp/utilities.sh

    popd
}

# Themes directory comes as a yaml array and needs to be converted to a bash array.
# Generally, a single array item is expected. We currently use the first one specified.
get_theme_directory()
{
    # Remove any spaces
    theme_directory=${THEME_DIRECTORY_YAML// /}

    # Convert comma to space (this is how bash delimits arrays)
    theme_directory=${theme_directory//,/ }

    # Remove opening & closing brackets
    theme_directory=${theme_directory//[u}
    theme_directory=${theme_directory//]}

    # Convert string to bash array by wrapping in parenthesis
    eval theme_directory=($theme_directory)

    echo "${theme_directory[0]}"
}

# Generalizing - Applying custom images isn't applicable for all scenarios. 
# Therefore, it is necessary to first check if custom images are available 
# before attempting to copy them.
copy_images()
{
    custom_image_count=`ls $OXA_TOOLS_CONFIG_PATH/env/${ENVIRONMENT}/*.png 2> /dev/null | wc -w`

    if (( $(echo "$custom_image_count > 0" | bc -l) )); then
        for i in `ls -d1 $theme_path/*/lms/static/images`; do
            sudo cp $OXA_TOOLS_CONFIG_PATH/env/$ENVIRONMENT/*.png $i;
        done
    fi
}

##########################
# Execution Starts
##########################

src_utils
theme_path=$(get_theme_directory)

# Download comprehensive theming from github
clean_repository $theme_path
sync_repo $EDX_THEME_REPO $THEME_BRANCH $theme_path

copy_images

# set appropriate permissions on the new theming folder
sudo chown -R edxapp:edxapp $theme_path
sudo chmod -R u+rw $theme_path

# Compile LMS assets and then restart the services so that changes take effect
sudo su edxapp -s /bin/bash -c "source $edxapp_directory/edxapp_env;cd $edx_platform_path;paver update_assets lms --settings aws"

# This command won't succeed on devstack. Which is totally fine.
set +e
sudo /edx/bin/supervisorctl restart edxapp: || true
