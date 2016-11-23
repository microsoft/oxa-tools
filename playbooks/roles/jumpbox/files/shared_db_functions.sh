#!/bin/bash

# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

# General Variables (common to both db backup scripts)
ENV_FILE=
AZURE_STORAGE_ACCOUNT=
AZURE_STORAGE_ACCESS_KEY=
CONTAINER_NAME=
TIME_STAMPED=
COMPRESSED_FILE=
BACKUP_FILE=

source_utilities_functions()
{
    # Working directory should be oxa-tools repo root.
    UTILITIES_FILE=templates/stamp/utilities.sh
    if [ -f $UTILITIES_FILE ];
    then
        # source our utilities for logging, error reporting, and other base functions
        source $UTILITIES_FILE
    else
        echo "Cannot find common utilities file at $UTILITIES_FILE"
        echo "exiting script"
        exit 1
    fi

    log "Sourced functions successfully imported."
}

help()
{
    SCRIPT_NAME=`basename "$0"`

    log "This script $SCRIPT_NAME will backup the database"
    log "Options:"
    log "        --environment-file    Path to settings that are enviornment-specific"
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
                echo "Option -${BOLD}$2${NORM} not allowed."
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
    source $ENV_FILE
    if [ -f $ENV_FILE ];
    then
        # source environment variables.
        source $ENV_FILE
    else
        echo "Cannot find environment variables file at $ENV_FILE"
        echo "exiting script"
        exit 1
    fi

    # These variable aren't currently available outside of this scope.
    # We therefore assign them to General Variables.

    AZURE_STORAGE_ACCOUNT=$AZURE_ACCOUNT_NAME
    AZURE_STORAGE_ACCESS_KEY=$AZURE_ACCOUNT_KEY

    CONTAINER_NAME="${DB_TYPE}Backup"
    TIME_STAMPED=$CONTAINER_NAME$(date +"%Y-%m-%d-%H%M%S")
    COMPRESSED_FILE="$TIME_STAMPED.tar.gz"

    if [ "$DB_TYPE" == "mysql" ]
    then
        BACKUP_FILE="$TIME_STAMPED.sql"

        # Mysql Credentials
        MYSQL_ADMIN=$MYSQL_ADMIN_USER
        MYSQL_PASS=$MYSQL_ADMIN_PASSWORD

        #todo: or do we want these instead?
        # App and Replication accounts
        # MYSQL_ADMIN=$MYSQL_USER
        # MYSQL_PASS=$MYSQL_PASSWORD

        # Mysql Installer Configurations
        MYSQL_REPL_USER=lexoxamysqlrepl
        MYSQL_REPL_USER_PASSWORD=1ezP@55w0rd

    elif [ "$DB_TYPE" == "mongo" ]
    then
        BACKUP_FILE="$TIME_STAMPED"

        # Mongo Credentials
        MONGO_ADMIN=$MONGO_USER
        MONGO_PASS=$MONGO_PASSWORD

        #todo: do need these as weel?
        # Mongo Replicaset Credentials
        #MONGO_REPLICASET_KEY
        #MONGO_REPLICASET_NAME

    fi
}
