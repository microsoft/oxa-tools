#!/bin/bash
#
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

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
          --target-user)
            target_user="${arg_value}"
            ;;
          --private-key)
            private_key=`echo ${arg_value} | base64 --decode`
            ;;
          --public-key)
            public_key=`echo ${arg_value} | base64 --decode`
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

setup_low_storage_test()
{
    # collect the parameters
    low_stroage_configuration="${1}"    # Settings file
    low_stroage_script="${2}"           # Backup script (actually implementation)
    low_stroage_log="${3}"              # Log file for storage job
    low_stroage_frequency="${4}"        # Backup Frequency
    usage_threshold_percent="${5}"      # Threshold for alerting

    log "Setting up recurring test for low disk space"

    # For simplicity, we require all parameters are set
    if [ "$#" -lt 5 ]; then
        log "Some required parameters are missing"
        exit 1;
    fi

    # persist the settings
    bash -c "cat <<EOF >${low_stroage_configuration}
USAGE_THRESHOLD_PERCENT=${usage_threshold_percent}
EOF"

    # todo:consider factor the remaining part of this into its own function

    # this file contains secrets (like storage account key). Secure it
    chmod 600 $low_stroage_configuration

    # create the cron job
    cron_installer_script="${low_stroage_script}"
    lock_file="${cron_installer_script}.lock"
    install_command="sudo flock -n ${lock_file} bash ${low_stroage_script} -s ${low_stroage_configuration} >> ${low_stroage_log} 2>&1"
    echo $install_command > $cron_installer_script

    # secure the file and make it executable
    chmod 700 $cron_installer_script

    # Remove the task if it is already setup
    log "Uninstalling existing job that tests for low remaining disk space"
    crontab -l | grep -v "sudo bash ${cron_installer_script}" | crontab -

    # Setup the background job
    log "Install job that tests for low remaining disk space"
    crontab -l | { cat; echo "${low_stroage_frequency} sudo bash ${cron_installer_script}"; } | crontab -
    exit_on_error "Failed setting up low remaining dis space job." $ERROR_CRONTAB_FAILED

    # setup the cron job
    log "Completed job that tests for low remaining disk space"
}