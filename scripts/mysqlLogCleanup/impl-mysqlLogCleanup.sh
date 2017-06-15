#!/bin/bash

# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

set -x

# Path to settings file provided as an argument to this script.
SETTINGS_FILE=

# From settings file
    SIZE_THRESHOLD=700000000 #todo, 700 megabytes for now.
    DATABASE_USER=root #todo
    DATABASE_PASSWORD=
    PATH_PREFIX=/datadisks/disk1
# Paths and file names.
    CURRENT_SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    UTILITIES_FILE=$CURRENT_SCRIPT_PATH/../../templates/stamp/utilities.sh
    SCRIPT_NAME=`basename "$0"`

help()
{
    echo
    echo "This script $SCRIPT_NAME will rotate mysql\'s slow log"
    echo
    echo "Options:"
    echo "  -s|--settings-file  Path to settings"
    echo
}

# Parse script parameters
parse_args()
{
    while [[ "$#" -gt 0 ]]
        do

        # Output parameters to facilitate troubleshooting
        echo "Option $1 set with value $2"

        case "$1" in
            -s|--settings-file)
                SETTINGS_FILE=$2
                shift # argument
                ;;
            -h|--help)
                help
                exit 2
                ;;
            *) # unknown option
                echo "ERROR. Option -${BOLD}$2${NORM} not allowed."
                help
                exit 2
                ;;
        esac

        shift # argument
    done
}

source_wrapper()
{
    if [ -f "$1" ]
    then
        echo "Sourcing file $1"
        source "$1"
    else
        echo "Cannot find file at $1"
        help
        exit 1
    fi
}

mysql_command()
{
    command=$1

    echo "`mysql -u $DATABASE_USER -p$DATABASE_PASSWORD -se "$command"`"
}

rotate_mysql_slow_log()
{
    # Is slow log enabled?
    isLoggingSlow=`mysql_command "select @@slow_query_log" | tail -1`
    if (( $isLoggingSlow )) ; then
        # Get path mysql is writing the slow log to
        slowLogPath=`mysql_command "select @@slow_query_log_file" | tail -1`

        # Get size of slow log
        slowLogSizeInBytes=`du $slowLogPath | tr '\t' '\n' | head -1`

        if [[ -n $slowLogSizeInBytes ]] && (( $slowLogSizeInBytes > $SIZE_THRESHOLD )) ; then
            # Disable slow logs before rotation.
            mysql_command "set global slow_query_log=off"

            # Flush slow logs before rotation.
            mysql_command "flush slow logs"

            # Compress
            file_suffix=$(date +"%Y-%m-%d_%Hh-%Mm-%Ss").tar.gz
            sudo tar -zcvf "$PATH_PREFIX/$slowLogPath.$file_suffix" "$slowLogPath"

            # Truncate log
            echo -n > $slowLogPath

            # Enable slow logs after rotation.
            mysql_command "set global slow_query_log=on"
        else
            log "Nothing to do. Slow query logs are not large enough to rotate out yet."
        fi
    else
        log "Nothing to do. Slow query logs are not enabled."
    fi
}

# Parse script argument(s)
parse_args $@

# log() and other functions
source_wrapper $UTILITIES_FILE

# Script self-idenfitication
print_script_header

log "Starting mysql slow logs rotation."

# Settings
source_wrapper $SETTINGS_FILE

# Pre-conditionals
exit_if_limited_user

rotate_mysql_slow_log
