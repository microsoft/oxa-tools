#!/bin/bash

# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

# General Variables (common to both db backup and todo:restore scripts)
ENV_FILE=
AZURE_STORAGE_ACCOUNT=
AZURE_STORAGE_ACCESS_KEY=
CONTAINER_NAME=
TIME_STAMPED=
COMPRESSED_FILE=
BACKUP_FILE=
DESTINATION_FOLDER="/var/tmp"

source_utilities_functions()
{
    # Working directory should be oxa-tools repo root.
    UTILITIES_FILE=templates/stamp/utilities.sh
    if [ -f $UTILITIES_FILE ]
    then
        # source our utilities for logging and other base functions
        source $UTILITIES_FILE
    else
        echo "Cannot find common utilities file at $UTILITIES_FILE"
        echo "Ensure working directory is Working oxa-tools repo root prior to running script."
        exit 1
    fi

    log "Common utility functions successfully imported."
}

help()
{
    SCRIPT_NAME=`basename "$0"`

    log "This script $SCRIPT_NAME will backup the database"
    log "Options:"log "     -e|--environment-file    Path to settings that are enviornment-specific"
}

# Parse script parameters
parse_args()
{
    while [[ "$#" -gt 0 ]]
        do

         # Log input parameters to facilitate troubleshooting
        log "Option $1 set with value $2"

        case "$1" in
            -e|--environment-file)
                ENV_FILE=$2
                shift # past argument
                ;;
            -h|--help) # Helpful hints
                help
                exit 2
                ;;
            *) # unknown option
                log "ERROR. Option -${BOLD}$2${NORM} not allowed."
                help
                exit 2
                ;;
        esac

        shift # past argument or value
    done
}

source_env_values()
{
    DB_TYPE=$1 #mongo|mysql

    # populate the environment variables
    if [ -f $ENV_FILE ]
    then
        # source environment variables.
        source $ENV_FILE
        log "Successfully sourced environment-specific settings"
    else
        log "Cannot find environment settings file at $ENV_FILE"
        log "exiting script"
        exit 1
    fi

    # These variable aren't currently available outside of this scope.
    # We therefore assign them to General Variables at a broader scope.

    # Exporting for Azure CLI
    export AZURE_STORAGE_ACCOUNT=$AZURE_ACCOUNT_NAME
    export AZURE_STORAGE_ACCESS_KEY=$AZURE_ACCOUNT_KEY

    # Container names cannot contain underscores or uppercase characters
    CONTAINER_NAME="${DB_TYPE}-backup"
    TIME_STAMPED=${CONTAINER_NAME}_$(date +"%Y-%m-%d_%Hh-%Mm-%Ss")
    COMPRESSED_FILE="$TIME_STAMPED.tar.gz"

    if [ "$DB_TYPE" == "mysql" ]
    then
        BACKUP_FILE="$TIME_STAMPED.sql"

        # Mysql Credentials
        MYSQL_ADMIN=$MYSQL_ADMIN_USER
        MYSQL_PASS=$MYSQL_ADMIN_PASSWORD

    elif [ "$DB_TYPE" == "mongo" ]
    then
        BACKUP_FILE="$TIME_STAMPED"

        # Mongo Credentials
        MONGO_ADMIN=$MONGO_USER
        MONGO_PASS=$MONGO_PASSWORD

    fi
}

create_compressed_db_dump()
{
    DB_TYPE=$1 #mongo|mysql

    pushd $DESTINATION_FOLDER

    log "Copying entire $DB_TYPE database to local file system"
    if [ "$DB_TYPE" == "mysql" ]
    then
        mysqldump -u $MYSQL_ADMIN -p$MYSQL_PASS -h $MYSQL_ADDRESS --all-databases --single-transaction > $BACKUP_FILE

    elif [ "$DB_TYPE" == "mongo" ]
    then
        mongodump -u $MONGO_ADMIN -p$MONGO_PASS --host $MONGO_ADDRESS -o $BACKUP_FILE

    fi

    log "Compressing entire $DB_TYPE database"
    tar -zcvf $COMPRESSED_FILE $BACKUP_FILE

    popd
}

copy_db_to_azure_storage()
{
    DB_TYPE=$1 #mongo|mysql

    log "Upload the backup $DB_TYPE file to azure blob storage"

    # AZURE_STORAGE_ACCOUNT and AZURE_STORAGE_ACCESS_KEY are already exported for azure cli's use.
    # FYI, we could use AZURE_STORAGE_CONNECTION_STRING instead.

    sc=$(azure storage container show $CONTAINER_NAME --json)
    if [[ -z $sc ]]; then
        log "Creating the container... $CONTAINER_NAME"
        azure storage container create $CONTAINER_NAME
    fi

    pushd DESTINATION_FOLDER

    RESULT=$(azure storage blob upload $COMPRESSED_FILE $CONTAINER_NAME $COMPRESSED_FILE --json | jq '.blob')
    if [ "$RESULT"!="" ]; then
        log "$RESULT blob file uploaded successfully"
    else
        log "Upload blob file failed"
    fi

    popd
}

cleanup_local()
{
    DB_TYPE=$1 #mongo|mysql

    pushd $DESTINATION_FOLDER

    log "Deleting local copies of $DB_TYPE database"
    rm -f $COMPRESSED_FILE
    rm -f $BACKUP_FILE

    popd
}
