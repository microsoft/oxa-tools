#!/bin/bash

# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

#todo:
# General Variables
NOW=$(date +"%Y-%m-%d-%H%M%S")
export file_to_upload="mongobackup_$NOW.tar.gz"
export AZURE_STORAGE_ACCOUNT=$StorageAccountName
export AZURE_STORAGE_ACCESS_KEY=$StorageAccountKey1
export container_name=mongobackup
export mongo_backup="mongobackup_$NOW"
export blob_name="mongobackup_$NOW.tar.gz"

mongo_admin_pwd="R3x0p3n3dx!"

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

source_shared_functions

# Script self-idenfitication
print_script_header

log "Begin execution of Mongo backup script using mongodump"

exit_if_limited_user

# parse script arguments
parse_args $@

source_env_values

#todo: grab db dump, compress, copy, cleanup

cd $(dirname ${BASH_SOURCE[0]})

mongodump -u admin -p$mongo_admin_pwd -o $mongo_backup
tar -zcvf $file_to_upload $mongo_backup

echo "Upload the backup file to azure blob storage"

sc=$(azure storage container show $container_name --json)
if [[ -z $sc ]]; then
    echo "Creating the container..." + $container_name
    azure storage container create $container_name
fi

res=$(azure storage blob upload $file_to_upload $container_name $blob_name --json | jq '.blob')
if [ "$res"!="" ]; then
    echo "$res blob file uploaded successfully"
else
    echo "Upload blob file failed"
fi

rm -f $file_to_upload
rm -r $mongo_backup

#todo: look at utilities, db installers, bootstrap for other helpful funcitons
