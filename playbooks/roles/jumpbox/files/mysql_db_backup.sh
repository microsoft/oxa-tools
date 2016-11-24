#!/bin/bash

# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

# General Variables (mysql)
MYSQL_ADDRESS="10.0.0.17"
MYSQL_ADMIN=
MYSQL_PASS=

source_shared_functions()
{
    CURRENT_SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    SHARED_FUNCTIONS_FILE=$CURRENT_SCRIPT_PATH/shared_db_functions.sh
    if [ -f $SHARED_FUNCTIONS_FILE ]
    then
        # source shared functions both backup scripts use.
        source $SHARED_FUNCTIONS_FILE
    else
        echo "Cannot find shared functions file at $SHARED_FUNCTIONS_FILE"
        echo "exiting script"
        exit 1
    fi

    source_utilities_functions
}

source_shared_functions

# Script self-idenfitication
print_script_header

log "Begin execution of MySql backup script using mysqldump"

exit_if_limited_user

# parse script arguments
parse_args $@

source_env_values mysql

create_compressed_db_dump mysql

copy_db_to_azure_storage mysql

cleanup_local mysql
