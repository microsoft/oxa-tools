#!/bin/bash
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

#todo:temp file for validation

source ./utilities.sh

  exit_if_limited_user

  install-azure-cli
  install-mongodb-shell
  install-mysql-client
  install-json-processor
