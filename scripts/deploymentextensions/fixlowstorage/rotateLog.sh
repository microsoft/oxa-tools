#!/bin/bash

# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

# Rotates big logs

set -x

# Settings
    file_size_threshold=700000000     # Default to 700 megabytes
    mysql_user=root
    mysql_pass=
    large_partition=/datadisks/disk1
# Paths and file names.
    current_script_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

mysql_command()
{
    command=$1

    echo "`mysql -u $mysql_user -p$mysql_pass -se "$command"`"
}
invalid_mysql_settings()
{
    [[ -z $file_size_threshold ]] && return
    [[ -z $mysql_user ]] && return
    [[ -z $mysql_pass ]] && return
    [[ -z $large_partition ]] && return

    false
}
rotate_mysql_slow_log()
{
    if invalid_mysql_settings ; then
        log "Missing mysql settings"
        return;
    fi

    # Is slow log enabled?
    # This will also prevent execution on machines without mysql
    isLoggingSlow=`mysql_command "select @@slow_query_log" | tail -1`
    if [[ $isLoggingSlow == 1 ]] ; then
        # Get path mysql is writing the slow log to
        slowLogPath=`mysql_command "select @@slow_query_log_file" | tail -1`

        # Get size of slow log
        slowLogSizeInBytes=`du $slowLogPath | tr '\t' '\n' | head -1`

        if [[ -n $slowLogSizeInBytes ]] && (( $slowLogSizeInBytes > $file_size_threshold )) ; then
            # Disable slow logs before rotation.
            mysql_command "set global slow_query_log=off"

            # Flush slow logs before rotation.
            mysql_command "flush slow logs"

            # Compress
            file_suffix=$(date +"%Y-%m-%d_%Hh-%Mm-%Ss").tar.gz
            sudo tar -zcvf "$large_partition/$slowLogPath.$file_suffix" "$slowLogPath"

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

if [[ -z $mysql_pass ]] ; then
    # Parse commandline argument, source utilities. Exit on failure.
    source sharedOperations.sh || exit 1
fi

# Pre-conditionals
exit_if_limited_user

rotate_mysql_slow_log

# Restore working directory
popd
