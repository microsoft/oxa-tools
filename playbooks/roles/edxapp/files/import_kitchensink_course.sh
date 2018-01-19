#!/bin/bash
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

set -ex

# If EDXAPP_IMPORT_KITCHENSINK_COURSE then import Kitchen Sink Course

pushd /tmp

# Remove if kitchen sink course folder exists
if [[ -d ks_source ]]; then
    sudo rm -fr ks_source
fi

# Download kitchen sink course from github to folder /tmp/ks_source 
sudo git clone https://github.com/Microsoft/oxa_kitchen_sink.git ks_source

sudo chown -R edxapp:www-data ks_source

# Go to edx-platform folder for importing
pushd /edx/app/edxapp/edx-platform/

# Import kitchen sink course into the platform
sudo -u www-data /edx/bin/python.edxapp ./manage.py cms --settings=aws import /edx/var/edxapp/data /tmp/ks_source

popd
popd
