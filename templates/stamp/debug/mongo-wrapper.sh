#!/bin/bash
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

# This script is for development and testing purposes. It
# allows execution of the mongo's CustomScript directly.
#
# Note, this was generated manually by grabbing values from stamp.json.
#   todo: generate this file dynamically so that changes in stamp.json will be reflected automatically
#   todo: and/or mask secrets by relying on "replace" transform.

pushd ..
wget -q https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/shared_scripts/ubuntu/vm-disk-utils-0.1.sh -O vm-disk-utils-0.1.sh

mongoDbInstallerScript=mongodb-ubuntu-install.sh
mongoMachineSettings_installerBaseUrl=http:\/\/repo.mongodb.org\/apt\/ubuntu
mongoMachineSettings_installerPackages=mongodb-org
networkSettings_serverIpPrefix=10.0.0.
networkSettings_mongoDataNodeCount=1

# configurable, but hardcoded for now
mongoReplicaSetName=clustername-rs1
mongoServerAdminUserName=mongoUser
mongoServerAdminPassword=`echo mongoPassword | base64`

# generally randomly generated, but hardcoded for now
mongoReplicaSetKey=tcvhiyu5h2o5o

bash $mongoDbInstallerScript -i $mongoMachineSettings_installerBaseUrl -b $mongoMachineSettings_installerPackages -r $mongoReplicaSetName -k $mongoReplicaSetKey -u $mongoServerAdminUserName -p $mongoServerAdminPassword -x $networkSettings_serverIpPrefix -n $networkSettings_mongoDataNodeCount

cleanup
rm vm-disk-utils-0.1*
popd debug
