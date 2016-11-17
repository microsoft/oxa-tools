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

  INSTALLER=mongodb-ubuntu-install.sh
  mongoMachineSettings_installerBaseUrl=http://repo.mongodb.org/apt/ubuntu
  mongoMachineSettings_installerPackages=mongodb-org
  mongoVer=2.6.12
  networkSettings_serverIpPrefix=10.0.0.
  mongoIpOffset=10


  #master
  NODE_COUNT=3
  EXTRA_ARGS="-l"

  MONGO_USER=lexoxamongoadmin
  MONGO_PASSWORD=`echo hidden | base64`

  mongoReplicaSetKey=tcvhiyu5h2o5o
  mongoReplicaSetName=loxabvtwuc2rs1

  bash $INSTALLER -i $mongoMachineSettings_installerBaseUrl -b $mongoMachineSettings_installerPackages -v $mongoVer -r $mongoReplicaSetName -k $mongoReplicaSetKey -u $MONGO_USER -p $MONGO_PASSWORD -x $networkSettings_serverIpPrefix -n $NODE_COUNT -o $mongoIpOffset $EXTRA_ARGS

# cleanup
rm vm-disk-utils-0.1*
popd
