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

mysqlDbInstallerScript=mysql-ubuntu-install.sh
mysqlServerReplUserName=lexoxamysqlrepl
mysqlServerReplPassword=`echo 1ezP@55w0rd | base64`
mysqlServerAdminUserName=lexoxamysqladmin
mysqlServerAdminPassword=`echo 1ezP@55w0rd | base64`
mysqlServerPackageVersion="5.6"
networkSettings_Ip="10.0.0.16"
copyindex=1

bash $mysqlDbInstallerScript -r $mysqlServerReplUserName -k $mysqlServerReplPassword -u $mysqlServerAdminUserName -p $mysqlServerAdminPassword -v $mysqlServerPackageVersion -m $networkSettings_Ip -n $copyindex

# cleanup
rm vm-disk-utils-0.1*
popd
