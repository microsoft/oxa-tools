#!/bin/bash

# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

echo "mongodb backup using mongodump"
source /tmp/transfer/backup/storage_keys.sh

# General Variables
NOW=$(date +"%m-%d-%Y-%H%M%S")
export file_to_upload="mongobackup_$NOW.tar.gz"
export AZURE_STORAGE_ACCOUNT=$StorageAccountName
export AZURE_STORAGE_ACCESS_KEY=$StorageAccountKey1
export container_name=mongobackup
export mongo_backup="mongobackup_$NOW"
export blob_name="mongobackup_$NOW.tar.gz"
mongo_admin_pwd="R3x0p3n3dx!"

source_shared_functions()
{
    UTILITIES_PATH=templates/stamp/utilities.sh
    if [ -f $UTILITIES_PATH ]; then
        # source our utilities for logging, error reporting, and other base functions
        source $UTILITIES_PATH
    #todo:exit on failure
    fi
 
    CURRENT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    #todo:check for 
}

#todo: ensure elevation.

help()
{
    echo "This script will backup the mongo database"
    echo "Options:"
    echo "        --environment-file    Path to settings that are enviornment-specific"
}

# Parse script parameters
parse_args()
{
    while [[ "$#" -gt 0 ]]
        do

         # Log input parameters to facilitate troubleshooting
        echo "Option $1 set with value $2"

        case "$1" in
            -e|--environment-file)
                OS_ADMIN_USERNAME=$2
                shift # past argument
                ;;
            -h|--help)  # Helpful hints
                help
                exit 2
                ;;
            *) # unknown option
                echo "Option -${BOLD}$2${NORM} not allowed."
                help
                exit 2
                ;;
        esac

        shift # past argument or value
    done
}

# parse script arguments
parse_args $@

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
