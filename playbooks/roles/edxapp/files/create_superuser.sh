#!/bin/bash
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

set -x

# collect the input parameters for easy identification/reference
edxapp_superuser_password=$1
edxapp_superuser_emailaddress=$2
edxapp_superuser_username=$3
edx_platform_path=$4

# When creating the user account that will be used as the application Super User, the username is derived from the email address
# if it is not explicitly specified. When derived and edxapp_superuser_name!=the derived user name, setting the super user status fails quietly
# Fix: explicitly specify the username & emailaddress instead of depending on the default

# Go to edx-platform folder
pushd $edx_platform_path

# Create staff user 
sudo -u www-data /edx/bin/python.edxapp ./manage.py lms --settings=aws create_user -s --password="${edxapp_superuser_password}" --email="${edxapp_superuser_emailaddress}" --username="${edxapp_superuser_username}"

# Make superuser and set to active
echo "from django.contrib.auth.models import User; me = User.objects.get(username='"${edxapp_superuser_username}"'); me.is_superuser=True; me.is_active=True; me.save();" | sudo -u www-data /edx/bin/python.edxapp ./manage.py lms --settings=aws shell

popd
