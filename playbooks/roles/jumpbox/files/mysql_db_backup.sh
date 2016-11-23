#!/bin/bash

# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

# General Variables
MYSQL_ADDRESS="10.0.0.17"
MYSQL_ADMIN=
MYSQL_PASS=

source_shared_functions()
{
    CURRENT_SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    SHARED_FUNCTIONS_FILE=$CURRENT_SCRIPT_PATH/shared_db_functions.sh
    if [ -f $SHARED_FUNCTIONS_FILE ];
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

create_compressed_db_dump()
{
    #todo: use /var/tmp called destination_folder, remote, combine+conditional
    mysqldump -u $MYSQL_ADMIN -p$MYSQL_PASS --all-databases --single-transaction > $BACKUP_FILE
    tar -zcvf $COMPRESSED_FILE $BACKUP_FILE
}

source_shared_functions

# Script self-idenfitication
print_script_header

log "Begin execution of MySql backup script using mysqldump"

exit_if_limited_user

# parse script arguments
parse_args $@

source_env_values mysql

#todo: grab db dump, compress, copy, cleanup

sc=$(azure storage container show $CONTAINER_NAME --json)
if [[ -z $sc ]]; then
    echo "Creating the container..." + $CONTAINER_NAME
    azure storage container create $CONTAINER_NAME
fi

echo "Uploading the backup file..."
res=$(azure storage blob upload $COMPRESSED_FILE $CONTAINER_NAME $COMPRESSED_FILE --json | jq '.blob')
if [ "$res"!="" ]; then
    echo "$res blob file uploaded successfully"
else
    echo "Upload blob file failed"   
fi

rm -f $COMPRESSED_FILE
rm -f $BACKUP_FILE

#todo: look at utilities, db installers, bootstrap for other helpful funcitons
