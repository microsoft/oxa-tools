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

        if [[ $shift_once -eq 0 ]]; 
        then
            shift # past argument or value
        fi

    done
}

current_script_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
utilities_path=$current_script_path/../../../templates/stamp/utilities.sh

# Script self-idenfitication
print_script_header

# pass existing command line arguments
parse_args $@
# validate_args todo:

