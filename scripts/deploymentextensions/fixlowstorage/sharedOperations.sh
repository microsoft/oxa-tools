#!/bin/bash
#
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

set -x

# Cron Job Setup/Execution
    script_file=""
    settings_file=""
    low_storage_log=""
    low_storage_frequency=""

# Settings file (scp and ssh)
    backend_server_list=()
    target_user=""
    paths_to_copy_list=()
    destination_path="~"

# Disk usage alert AND Log rotation


    usage_threshold_percent=""      # Threshold for alerting

current_script_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source_wrapper()
{
    if [[ -f "$1" ]] ; then
        echo "Sourcing file $1"
        source "$1"

        # The sourced file could have a non-zero (failing) exit code,
        # but this function is exclusively concerned with whether the
        # file can be sourced successfully.
        true
    fi

    # else case: the non-zero (failing) exit code will bubble up to caller.
}

source_utilities()
{
    # expected case
    source_wrapper "utilities.sh" && return

    # created
    actual_utilities_path=$current_script_path/../../../templates/stamp/utilities.sh
    local_utilities_path=$current_script_path/utilities.sh
    ln -s $actual_utilities_path $local_utilities_path

    # expected case
    source_wrapper "utilities.sh"
}

parse_args()
{
    while [[ "$#" -gt 0 ]] ; do
        arg_value="${2}"
        shift_once=0

        if [[ "${arg_value}" =~ "--" ]] ; then
            arg_value=""
            shift_once=1
        fi

         # Log input parameters to facilitate troubleshooting
        log "Option '${1}' set with value '"${arg_value}"'"

        case "$1" in
          --script-file)
            script_file="${arg_value}"
            ;;
          --settings-file)
            settings_file="${arg_value}"
            ;;
          --backend-server-list)
            backend_server_list=(`echo ${arg_value} | base64 --decode`)
            ;;
          --target-user)
            target_user="${arg_value}"
            ;;
          --paths-to-copy-list)
            paths_to_copy_list=(`echo ${arg_value} | base64 --decode`)
            ;;
          --destination-path)
            destination_path="${arg_value}"
            ;;
          --remote-command)
            remote_command="${arg_value}"
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

        if [[ $shift_once -eq 0 ]] ; then
            shift # past argument or value
        fi

    done
}

###############################################
# INVOKED EXTERNALLY
###############################################
persist_settings_for_cron()
{
# persist the settings
    bash -c "cat <<EOF >${settings_file}
backend_server_list=\"$backend_server_list\"
target_user=$target_user
paths_to_copy_list=\"$paths_to_copy_list\"
destination_path=$destination_path
remote_command=$remote_command
remote_arguments=\"$@\"
EOF"

    # this file contains important information (like db info). Secure it
    chmod 600 $settings_file
}
create_or_update_cron_job()
{
    # create the cron job
    cron_installer_script="${script_file}.cron"
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
    log "Completed job that tests for and partially mitigates low remaining disk space"
}

###############################################
# START CORE EXECUTION
###############################################

# Update working directory
pushd $current_script_path

# Source utilities. Exit on failure.
source_utilities || exit 1

# Script self-idenfitication
print_script_header

# pass existing command line arguments
parse_args "$@"

# Restore working directory
popd
