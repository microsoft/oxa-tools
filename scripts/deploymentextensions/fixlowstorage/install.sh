#!/bin/bash
#
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

current_script_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# todo: temporary debugging code.
actual_utilities_path=$current_script_path/../../../templates/stamp/utilities.sh
local_utilities_path=current_script_path/utilities.sh
ln -s $actual_utilities_path $local_utilities_path

# Update working directory
pushd $current_script_path

# Parse commandline argument
source sharedOperations.sh

# todo: factor common code into generic function when we transition the
#   db backup cron creation into the deployment extension pattern.

log "Setting up recurring test for low disk space"

# persist the settings
bash -c "cat <<EOF >${low_storage_configuration}
USAGE_THRESHOLD_PERCENT=${usage_threshold_percent}
EOF"

# this file contains secrets (like storage account key). Secure it
chmod 600 $low_storage_configuration

# create the cron job
cron_installer_script="${low_storage_script}"
lock_file="${cron_installer_script}.lock"
install_command="sudo flock -n ${lock_file} bash ${low_storage_script} -s ${low_storage_configuration} >> ${low_storage_log} 2>&1"
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
