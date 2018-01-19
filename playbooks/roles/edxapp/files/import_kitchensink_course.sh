#!/bin/bash
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

set -ex

oxa_tools_path=$1
edx_platform_path=$2
kitchen_sink_course_branch=$3
course_path=/tmp/ks_source

src_utils()
{
    pushd $oxa_tools_path

    echo "source utilities"
    source templates/stamp/utilities.sh

    popd
}

##########################
# Execution Starts
##########################

src_utils

# Download kitchen sink course from github
clone_repository \
    "Microsoft" \
    "oxa_kitchen_sink" \
    $kitchen_sink_course_branch \
    '' \
    $course_path

sudo chown -R edxapp:www-data $course_path

# Go to edx-platform folder for importing
pushd $edx_platform_path

# Import kitchen sink course into the platform
sudo -u www-data /edx/bin/python.edxapp ./manage.py cms --settings=aws import /edx/var/edxapp/data $course_path

popd
