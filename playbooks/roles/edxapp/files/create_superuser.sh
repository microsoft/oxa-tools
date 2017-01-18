#!/bin/bash
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

set -x

# Go to edx-platform folder
cd /edx/app/edxapp/edx-platform

# Create staff user 
sudo -u www-data /edx/bin/python.edxapp ./manage.py lms --settings=aws create_user -s -p $1 -e $2

# Make superuser and make active
echo "from django.contrib.auth.models import User; me = User.objects.get(username='"$3"'); me.is_superuser=True; me.is_active=True; me.save()" | sudo -u www-data /edx/bin/python.edxapp ./manage.py lms --settings=aws shell


