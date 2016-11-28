#!/bin/bash
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

set -x

# Delete the folder /tmp/sass-cache if exists. This is the temp folder for compiled assets
if [[ -d /tmp/sass-cache ]]; then
  sudo rm -fr /tmp/sass-cache
fi

# Compile LMS assets and then restart the services so that changes take effect
sudo su edxapp -s /bin/bash -c "source /edx/app/edxapp/edxapp_env;cd /edx/app/edxapp/edx-platform/;paver update_assets lms --settings aws"
sudo /edx/bin/supervisorctl restart edxapp:

# Compile LMS assets and then restart the services so that changes take effect.
# We do the same operation twice here since mostly it doesnot work in the first run. This is a workaround.
sudo su edxapp -s /bin/bash -c "source /edx/app/edxapp/edxapp_env;cd /edx/app/edxapp/edx-platform/;paver update_assets lms --settings aws"
sudo su edxapp -s /bin/bash -c "cp /edx/app/edxapp/themes/default/static/images/*.png /edx/var/edxapp/staticfiles/images/"
sudo /edx/bin/supervisorctl restart edxapp:

# Restart the NGINX web server so that picks up the latest static content
sudo service nginx restart
