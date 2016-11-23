#!/bin/bash

# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

# General Variables
MONGO_ADDRESS="10.0.0.12"
MONGO_ADMIN=
MONGO_PASS=

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
    mongodump -u $MONGO_ADMIN -p$MONGO_PASS -o $BACKUP_FILE
    tar -zcvf $COMPRESSED_FILE $BACKUP_FILE
}

source_shared_functions

# Script self-idenfitication
print_script_header

log "Begin execution of Mongo backup script using mongodump"

exit_if_limited_user

# parse script arguments
parse_args $@

source_env_values mongo

#todo: grab db dump, compress, copy, cleanup

echo "Upload the backup file to azure blob storage"

sc=$(azure storage container show $CONTAINER_NAME --json)
if [[ -z $sc ]]; then
    echo "Creating the container..." + $CONTAINER_NAME
    azure storage container create $CONTAINER_NAME
fi

res=$(azure storage blob upload $COMPRESSED_FILE $CONTAINER_NAME $COMPRESSED_FILE --json | jq '.blob')
if [ "$res"!="" ]; then
    echo "$res blob file uploaded successfully"
else
    echo "Upload blob file failed"
fi

rm -f $COMPRESSED_FILE
rm -r $BACKUP_FILE

#todo: look at utilities, db installers, bootstrap for other helpful funcitons
