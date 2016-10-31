#!/bin/bash
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.
set -x

OXA_VERSION=${1:-master}

OXA_REPO=https://github.com/Microsoft/oxa-tools.git
OXA_PATH=/oxa/oxa-tools
OXA_LOG_PATH=/var/log/oxa

if [[ ! -d /oxa ]]; then
  mkdir -p $OXA_PATH
  mkdir -p $OXA_LOG_PATH
  git clone --recursive $OXA_REPO $OXA_PATH
fi

cd $OXA_PATH
git checkout $OXA_VERSION

scripts/update.sh &>$OXA_LOG_PATH/update.log.$(date +%Y-%m-%d_%H-%M-%S)