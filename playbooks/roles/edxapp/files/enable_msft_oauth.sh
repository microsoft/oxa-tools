#!/bin/bash
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

set -ex

msft_auth=$1
edx_platform_path=$2
oxa_tools_path=$3

pushd $oxa_tools_path

#todo: get utilities

popd

pushd $edx_platform_path

#todo: cherry-pick change

pushd ..

#todo: update urls for int

popd
popd

sudo /edx/bin/supervisorctl restart edxapp:
