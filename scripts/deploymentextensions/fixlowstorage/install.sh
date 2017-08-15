#!/bin/bash
#
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

# Installs recurring cron job that rotates big logs AND detects low partition storage (then sends notification).

set -x

# Update working directory
current_script_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
pushd $current_script_path

# Parse commandline argument, source utilities. Exit on failure.
source sharedOperations.sh || exit 1

# Write configurations to disk for use by cron job.
persist_settings_for_cron "$@"

# Setup the background job
create_or_update_cron_job

# Restore working directory
popd
