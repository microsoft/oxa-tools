#!/bin/bash
#
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

set -x

# Update working directory
current_script_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
pushd $current_script_path

# Parse commandline argument, source utilities. Exit on failure.
source sharedOperations.sh || exit 1

# todo: factor common code into generic function when we transition the
#   db backup cron creation into the deployment extension pattern.

persist_settings_for_cron

# create the cron job
cron_installer_script="${script_file}"
lock_file="${cron_installer_script}.lock"
install_command="sudo flock -n ${lock_file} bash ${script_file} -s ${settings_file} >> ${low_storage_log} 2>&1"
echo $install_command > $cron_installer_script

# secure the file and make it executable
chmod 700 $cron_installer_script

# Remove the task if it is already setup
log "Uninstalling existing job that tests for low remaining disk space"
crontab -l | grep -v "sudo bash ${cron_installer_script}" | crontab -

# Setup the background job
log "Install job that tests for low remaining disk space"
crontab -l | { cat; echo "${low_storage_frequency} sudo bash ${cron_installer_script}"; } | crontab -
exit_on_error "Failed setting up low remaining dis space job." $ERROR_CRONTAB_FAILED

# setup the cron job
log "Completed job that tests for low remaining disk space"

# Restore working directory
popd
