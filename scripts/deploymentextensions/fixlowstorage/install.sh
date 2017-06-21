#!/bin/bash
#
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

low_storage_configuration=""    # Settings file
low_storage_script=""           # Backup script (actually implementation)
low_storage_log=""              # Log file for storage job
low_storage_frequency=""        # Backup Frequency
usage_threshold_percent=""      # Threshold for alerting

parse_args()
{
    while [[ "$#" -gt 0 ]]
    do
        arg_value="${2}"
        shift_once=0

        if [[ "${arg_value}" =~ "--" ]]; 
        then
            arg_value=""
            shift_once=1
        fi

         # Log input parameters to facilitate troubleshooting
        log "Option '${1}' set with value '"${arg_value}"'"

        case "$1" in
          --low-storage-configuration)
              low_storage_configuration="${arg_value}"
              ;;
          --low-storage-script)
              low_storage_script="${arg_value}"
              ;;
          --low-storage-log)
              low_storage_log="${arg_value}"
              ;;
          --low-storage-frequency)
              low_storage_frequency="${arg_value}"
              ;;
          --usage-threshold-percent)
              usage_threshold_percent="${arg_value}"
              ;;
        esac

        shift # past argument or value

        if [ $shift_once -eq 0 ]; 
        then
            shift # past argument or value
        fi

    done
}

#############################################################################
# Setup Low Storage Test Parameters
#############################################################################

# todo: factor common code into generic function when we transition the
#   db backup cron creation into the deployment extension pattern.

setup_low_storage_test()
{
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
}