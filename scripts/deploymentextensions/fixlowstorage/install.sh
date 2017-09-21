#!/bin/bash
#
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

# Installs recurring cron job that: rotates big logs AND detects low partition storage (then sends notification).

set -x

# Update working directory
current_script_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
pushd $current_script_path

shared="sharedOperations.sh"
echo "Sourcing file $shared"
source $shared || exit 1

# Source utilities. Exit on failure.
source_utilities || exit 1

log "Installing recurring cron job that: rotates big logs AND detects low partition storage (then sends notification)."

# Script self-idenfitication
print_script_header

# Parse commandline arguments
parse_args "$@"

# Write configurations to disk for use by cron job.
persist_settings_for_cron "$@"

# Setup the background job
create_or_update_cron_job

# Restore working directory
popd
