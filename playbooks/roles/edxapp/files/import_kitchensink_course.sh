#!/bin/bash
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

set -x

# If set to true import Kitchen Sink Course, otherwise do nothing
# EDXAPP_IMPORT_KITCHENSINK_COURSE: true
if [ "$1" == "true" ] || [ "$1" == "True" ]; then
	# Remove if kitchen sink course folder exists
	if [[ -d /tmp/ks_source ]]; then
	  sudo rm -fr /tmp/ks_source
	fi

	# Create folder for kitchen sink course
	sudo mkdir /tmp/ks_source
	cd /tmp

	# Download kitchen sink course from github to folder /tmp/ks_source 
	sudo git clone https://github.com/Microsoft/oxa_kitchen_sink.git ks_source

	sudo chown -R edxapp:www-data /tmp/ks_source

	# Go to edx-platform folder for importing
	cd /edx/app/edxapp/edx-platform/

	# Import kitchen sink course into the platform
	sudo -u www-data /edx/bin/python.edxapp ./manage.py cms --settings=aws import /edx/var/edxapp/data /tmp/ks_source
fi




