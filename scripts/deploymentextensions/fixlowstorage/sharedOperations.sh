#!/bin/bash
#
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

# Cron Job Setup/Execution
    script_file=""
    settings_file=""

# Settings file.
    target_user=""

    low_storage_log=""              # Log file for storage job
    low_storage_frequency=""        # Backup Frequency
    usage_threshold_percent=""      # Threshold for alerting

current_script_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source_wrapper()
{
    if [[ -f "$1" ]]
    then
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
          --settings-file)
              settings_file="${arg_value}"
              ;;
          --script-file)
              script_file="${arg_value}"
              ;;
          --target-user)
            target_user="${arg_value}"
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

        if [[ $shift_once -eq 0 ]]; 
        then
            shift # past argument or value
        fi

    done
}

write_args()
{
    #todo
}

persist_settings_for_cron()
{
# persist the settings
    bash -c "cat <<EOF >${settings_file}
DESTINATION_MACHINES_LIST=
target_user=$target_user
PATHS_TO_COPY_LIST=
DESTINATION_DIRECTORY=
REMOTE_COMMAND=
REMOTE_ARGUMENTS=\"`write_args`\"
EOF"

    # this file contains secrets (like storage account key). Secure it
    chmod 600 $settings_file

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
parse_args $@
# validate_args todo:

# Restore working directory
popd
