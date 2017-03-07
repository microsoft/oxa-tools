#!/bin/bash
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

set -x

# Remove if themes folder exists
if [[ -d /edx/app/edxapp/themes ]]; then
  sudo rm -fr /edx/app/edxapp/themes
fi

# Create themes folder
sudo mkdir /edx/app/edxapp/themes
cd /edx/app/edxapp/themes

# Download comprehensive theming from github to folder /edx/app/edxapp/themes/comprehensive
#todo: replace w/ a clone wrapper in utilities.sh
sudo git clone https://github.com/microsoft/edx-theme.git comprehensive
cd comprehensive
sudo git checkout oxa/master.euc

sudo chown -R edxapp:edxapp /edx/app/edxapp/themes
sudo chmod -R u+rw /edx/app/edxapp/themes

# Compile LMS assets and then restart the services so that changes take effect
sudo su edxapp -s /bin/bash -c "source /edx/app/edxapp/edxapp_env;cd /edx/app/edxapp/edx-platform/;paver update_assets lms --settings aws"
sudo /edx/bin/supervisorctl restart edxapp:




