#!/bin/bash

# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

set -x

# Settings
    SIZE_THRESHOLD=700000000     # Default to 700 megabytes, but updated later on
    DATABASE_USER=root           # Default, but updated later on
    DATABASE_PASSWORD=
    PATH_PREFIX=/datadisks/disk1 # Default, but updated later on
# Paths and file names.
    current_script_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    SCRIPT_NAME=`basename "$0"`

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

###############################################
# START CORE EXECUTION
###############################################

log "Starting mysql slow logs rotation."

# Update working directory
pushd $current_script_path

# Parse commandline argument, source utilities. Exit on failure.
source sharedOperations.sh || exit 1

# Pre-conditionals
exit_if_limited_user

rotate_mysql_slow_log

# Restore working directory
popd
