#!/bin/bash
# Copyright (c) Microsoft Corporation. All Rights Reserved.

# Remove if edx-microsite folder exists
if [[ -d /edx/app/edxapp/edx-microsite ]]; then
  echo "*** Deleting the existing edx-microsite/ folder ***"
  sudo rm -fr /edx/app/edxapp/edx-microsite/
fi

cd /edx/app/edxapp/

# Download microsite assets from github to folder ../edx-microsite 
sudo git clone https://github.com/ms-manikarthik/edx-microsite.git

# changing the permissions to the folder
sudo chown -R edxapp:edxapp /edx/app/edxapp/edx-microsite/
