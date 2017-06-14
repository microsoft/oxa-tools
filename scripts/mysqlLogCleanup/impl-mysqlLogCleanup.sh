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

PATH_SUFFIX=$(date +"%Y-%m-%d_%Hh-%Mm-%Ss").tar.gz

mysql_command()
{
    command=$1

    echo "`mysql -u $DATABASE_USER -p$DATABASE_PASSWORD -se "$command"`"
}

# is slow log
isLoggingSlow=`mysql_command "select @@slow_query_log" | tail -1`
slowLogPath=`mysql_command "select @@slow_query_log_file" | tail -1`
#todo: this requires admin so verify before exectuion.
slowLogSizeInBytes=`du $slowLogPath | tr '\t' '\n' | head -1`

if (( $isLoggingSlow )) || (( 1 )); then
    if [[ -n $slowLogSizeInBytes ]] && (( $slowLogSizeInBytes > $SIZE_THRESHOLD )) || (( 1 )); then
        # Disable slow logs before rotation.
        mysql_command "set global slow_query_log=off"

        # Flush slow logs before rotation.
        mysql_command "flush slow logs"

        # Compress
        #todo: this also requires admin.
        sudo tar -zcvf "$PATH_PREFIX/$slowLogPath.$PATH_SUFFIX" "$slowLogPath"

        # Truncate log
        echo -n > $slowLogPath

        # Enable slow logs after rotation.
        mysql_command "set global slow_query_log=on"
    else
        echo "Nothing to do. Slow query logs are not large enough to rotate out yet."
    fi
else
    echo "Nothing to do. Slow query logs are not enabled."
fi