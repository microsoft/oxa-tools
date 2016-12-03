#!/bin/bash

# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

# Script arguments
ENV_FILE= # <env>.sh
DB_TYPE=  # mongo|mysql

# Derived from DB_TYPE
CONTAINER_NAME=
COMPRESSED_FILE=
BACKUP_PATH=

# From ENV_FILE
AZURE_STORAGE_ACCOUNT=
AZURE_STORAGE_ACCESS_KEY=
DB_USER=
DB_PASSWORD=

# todo: get IPs from <env>.sh
MONGO_ADDRESS="10.0.0.12"
MYSQL_ADDRESS="10.0.0.17"

# Temporary directory
DESTINATION_FOLDER="/var/tmp"

source_utilities_functions()
{
    CURRENT_SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    OXA_TOOLS_PATH=$CURRENT_SCRIPT_PATH/../../../..
    UTILITIES_FILE=$OXA_TOOLS_PATH/templates/stamp/utilities.sh

    if [ -f $UTILITIES_FILE ]
    then
        # source our utilities for logging and other base functions
        source $UTILITIES_FILE
    else
        echo "Cannot find common utilities file at $UTILITIES_FILE"
        exit 1
    fi

    log "Common utility functions successfully imported."
}

help()
{
    SCRIPT_NAME=`basename "$0"`

    log "This script $SCRIPT_NAME will backup the database"
    log "Options:     -e|--environment-file    Path to settings that are enviornment-specific"
    log "Options:     -d|--database-type       mongo or mysql"
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
            -d|--database-type)
                DB_TYPE=$2
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

validate_db_type()
{
    # validate argument
    if [ "$DB_TYPE" != "mongo" ] && [ "$DB_TYPE" != "mysql" ];
    then
        log "BAD ARGUMENT. Databse type must be mongo or mysql"
        help
        log "exiting script"
        exit 3
    fi

    log "Begin execution of $DB_TYPE backup script using ${DB_TYPE}dump"
}

source_env_values()
{
    # populate the environment variables
    if [ -f $ENV_FILE ]
    then
        # source environment variables.
        source $ENV_FILE
        log "Successfully sourced environment-specific settings"
    else
        log "BAD ARGUMENT. Cannot find environment settings file at $ENV_FILE"
        help
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
        BACKUP_PATH="$TIME_STAMPED.sql"

        # Mysql Credentials
        DB_USER=$MYSQL_ADMIN_USER
        DB_PASSWORD=$MYSQL_ADMIN_PASSWORD

    elif [ "$DB_TYPE" == "mongo" ]
    then
        BACKUP_PATH="$TIME_STAMPED"

        # Mongo Credentials
        DB_USER=$MONGO_USER
        DB_PASSWORD=$MONGO_PASSWORD

    fi
}

create_compressed_db_dump()
{
    pushd $DESTINATION_FOLDER

    log "Copying entire $DB_TYPE database to local file system"
    if [ "$DB_TYPE" == "mysql" ]
    then
        mysqldump -u $DB_USER -p$DB_PASSWORD -h $MYSQL_ADDRESS --all-databases --single-transaction > $BACKUP_PATH

    elif [ "$DB_TYPE" == "mongo" ]
    then
        mongodump -u $DB_USER -p $DB_PASSWORD --host $MONGO_ADDRESS --db edxapp --authenticationDatabase master -o $BACKUP_PATH

    fi

    exit_on_error "Failed to connect to database OR failed to create backup file."

    log "Compressing entire $DB_TYPE database"
    tar -zcvf $COMPRESSED_FILE $BACKUP_PATH

    popd
}

copy_db_to_azure_storage()
{
    log "Upload the backup $DB_TYPE file to azure blob storage"

    # AZURE_STORAGE_ACCOUNT and AZURE_STORAGE_ACCESS_KEY are already exported for azure cli's use.
    # FYI, we could use AZURE_STORAGE_CONNECTION_STRING instead.

    sc=$(azure storage container show $CONTAINER_NAME --json)
    if [[ -z $sc ]]; then
        log "Creating the container... $CONTAINER_NAME"
        azure storage container create $CONTAINER_NAME
    fi

    pushd $DESTINATION_FOLDER

    log "Uploading...Please wait..."
    echo

    result=$(azure storage blob upload $COMPRESSED_FILE $CONTAINER_NAME $COMPRESSED_FILE --json)
    fileName=$(echo $result | jq '.name')
    fileSize=$(echo $result | jq '.transferSummary.totalSize')    
    if [ $fileName != "" ] && [ $fileName != null ]
    then
        log "$fileName blob file uploaded successfully. Size: $fileSize"
    else
        log "Upload blob file failed"
    fi

    popd
}

cleanup_local_copies()
{
    pushd $DESTINATION_FOLDER

    log "Deleting local copies of $DB_TYPE database"
    rm -f $COMPRESSED_FILE
    rm -f $BACKUP_PATH

    popd
}

source_utilities_functions

# Script self-idenfitication
print_script_header

exit_if_limited_user

# parse script arguments
parse_args $@

validate_db_type

#todo:change caller and delete files

source_env_values

create_compressed_db_dump

copy_db_to_azure_storage

cleanup_local_copies
