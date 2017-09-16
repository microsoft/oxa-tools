#!/bin/bash
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

set -x
# If comprehensive theming is enabled then install it, otherwise do nothing
# EDXAPP_ENABLE_COMPREHENSIVE_THEMING: true
if [ "$1" == "true" ] || [ "$1" == "True" ]; then
	# Remove if themes folder exists
	if [[ -d /edx/app/edxapp/themes ]]; then
	  sudo rm -fr /edx/app/edxapp/themes
	fi
	
	cd /edx/app/edxapp

	# Download comprehensive theming from github to folder /edx/app/edxapp/themes/comprehensive 
	sudo git clone https://github.com/microsoft/edx-theme.git themes -b oxa/master.fic

	# todo:100627 this no longer works on onebox installations (like fullstack and devstack) which don't have oxa-tools-config
	for i in `ls -d1 /edx/app/edxapp/themes/*/lms/static/images`; do
       sudo cp /oxa/oxa-tools-config/env/$2/*.png $i;
    done
		
	sudo chown -R edxapp:edxapp /edx/app/edxapp/themes
	sudo chmod -R u+rw /edx/app/edxapp/themes

	# Compile LMS assets and then restart the services so that changes take effect
	sudo su edxapp -s /bin/bash -c "source /edx/app/edxapp/edxapp_env;cd /edx/app/edxapp/edx-platform/;paver update_assets lms --settings aws"
	sudo /edx/bin/supervisorctl restart edxapp:
fi




