#!/bin/bash

# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

#todo: overhaul file top-to-bottom
#todo: source file as param
#todo: install missing programs 
#       like in https://github.com/Microsoft/oxa-tools/pull/65/files
#todo: address relevant feedback ^ (above)

set -x

# Path to settings file provided as an argument to this script.
SETTINGS=

#todo:use the new names
#todo: ensure required values before execution

# From SETTINGS file
DATABASE_TYPE= # mongo|mysql

# Reading from machines
MONGO_REPLICASET_CONNECTIONSTRING= # old was l="10.0.0.12"
MYSQL_SERVER_LIST= # old was MYSQL_ADDRESS="10.0.0.17"

# Writing to storage
AZURE_STORAGE_ACCOUNT=
AZURE_STORAGE_ACCESS_KEY=

# Derived from DATABASE_TYPE
CONTAINER_NAME=
COMPRESSED_FILE=
BACKUP_PATH=

# Temporary paths and files.
DESTINATION_FOLDER="/var/tmp"
TMP_QUERY_ADD="query.add.sql"
TMP_QUERY_REMOVE="query.remove.sql"

todo()
{
    # required
    #todo: confirm names w/ elton
    DB_USER=
    DB_PASSWORD=

    #todo: enforce retention policy in a (separate pull request)
    MONGO_BACKUP_RETENTIONDAYS={MONGO_BACKUP_RETENTIONDAYS}
    MYSQL_BACKUP_RETENTIONDAYS={MYSQL_BACKUP_RETENTIONDAYS}

    # probably don't need to be concerned with cron freuency here.
    # UNLESS we want the first run of this script to setup the cron job.
    MONGO_BACKUP_FREQUENCY={MONGO_BACKUP_FREQUENCY}
    MYSQL_BACKUP_FREQUENCY={MYSQL_BACKUP_FREQUENCY}
}

help()
{
    SCRIPT_NAME=`basename "$0"`

    echo "This script $SCRIPT_NAME will backup the database"
    echo "Options:"
    echo "  -s|--settings-file  Path to settings"
}

# Parse script parameters
parse_args()
{
    while [[ "$#" -gt 0 ]]
        do

        # Output parameters to facilitate troubleshooting
        echo "Option $1 set with value $2"

        case "$1" in
            -s|--settings-file)
                SETTINGS=$2
                shift # argument
                ;;
            -h|--help)
                help
                exit 2
                ;;
            *) # unknown option
                echo "ERROR. Option -${BOLD}$2${NORM} not allowed."
                help
                exit 2
                ;;
        esac

        shift # argument
    done
}

source_utilities_functions()
{
    CURRENT_SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    UTILITIES_FILE=$CURRENT_SCRIPT_PATH/../templates/stamp/utilities.sh

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

validate_db_type()
{
    # validate argument
    if [ "$DATABASE_TYPE" != "mongo" ] && [ "$DATABASE_TYPE" != "mysql" ];
    then
        log "BAD ARGUMENT. Databse type must be mongo or mysql"
        help
        log "exiting script"
        exit 3
    fi

    log "Begin execution of $DATABASE_TYPE backup script using ${DATABASE_TYPE}dump"
}

use_env_values()
{
    # Exporting for Azure CLI
    export AZURE_STORAGE_ACCOUNT=$BACKUP_STORAGEACCOUNT_NAME # in <env>.sh AZURE_ACCOUNT_NAME
    export AZURE_STORAGE_ACCESS_KEY=$BACKUP_STORAGEACCOUNT_KEY # in <env>.sh AZURE_ACCOUNT_KEY

    # Container names cannot contain underscores or uppercase characters
    CONTAINER_NAME="${DATABASE_TYPE}-backup"
    TIME_STAMPED=${CONTAINER_NAME}_$(date +"%Y-%m-%d_%Hh-%Mm-%Ss")
    COMPRESSED_FILE="$TIME_STAMPED.tar.gz"

    if [ "$DATABASE_TYPE" == "mysql" ]
    then
        BACKUP_PATH="$TIME_STAMPED.sql"

        # Mysql Credentials
        DB_USER=$MYSQL_ADMIN_USER
        DB_PASSWORD=$MYSQL_ADMIN_PASSWORD

    elif [ "$DATABASE_TYPE" == "mongo" ]
    then
        BACKUP_PATH="$TIME_STAMPED"

        # Mongo Credentials
        DB_USER=$MONGO_USER
        DB_PASSWORD=$MONGO_PASSWORD

    fi
}

add_temp_mysql_user()
{
    log "Adding ${MYSQL_TEMP_USER} to db"
    touch $TMP_QUERY_ADD
    chmod 700 $TMP_QUERY_ADD

    tee ./$TMP_QUERY_ADD > /dev/null <<EOF
GRANT ALL PRIVILEGES ON *.* TO '{MYSQL_TEMP_USER}'@'%' IDENTIFIED BY '{MYSQL_TEMP_PASSWORD}' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

    sed -i "s/{MYSQL_TEMP_USER}/${MYSQL_TEMP_USER}/I" $TMP_QUERY_ADD
    sed -i "s/{MYSQL_TEMP_PASSWORD}/${MYSQL_TEMP_PASSWORD}/I" $TMP_QUERY_ADD

    mysql -u $DB_USER -p$DB_PASSWORD -h $MYSQL_ADDRESS < $TMP_QUERY_ADD
}

remove_temp_mysql_user()
{
    log "Removing ${MYSQL_TEMP_USER} from db"

    touch $TMP_QUERY_REMOVE
    chmod 700 $TMP_QUERY_REMOVE

    tee ./$TMP_QUERY_REMOVE > /dev/null <<EOF
DELETE FROM mysql.user WHERE User='{MYSQL_TEMP_USER}';
FLUSH PRIVILEGES;
EOF

    sed -i "s/{MYSQL_TEMP_USER}/${MYSQL_TEMP_USER}/I" $TMP_QUERY_REMOVE

    mysql -u $DB_USER -p$DB_PASSWORD -h $MYSQL_ADDRESS < $TMP_QUERY_REMOVE
}

create_compressed_db_dump()
{
    pushd $DESTINATION_FOLDER

    log "Copying entire $DATABASE_TYPE database to local file system"
    if [ "$DATABASE_TYPE" == "mysql" ]
    then
        add_temp_mysql_user
        mysqldump -u $DB_USER -p$DB_PASSWORD -h $MYSQL_ADDRESS --all-databases --single-transaction > $BACKUP_PATH
        remove_temp_mysql_user

    elif [ "$DATABASE_TYPE" == "mongo" ]
    then
        mongodump -u $DB_USER -p $DB_PASSWORD --host $MONGO_ADDRESS --db edxapp --authenticationDatabase master -o $BACKUP_PATH

    fi

    exit_on_error "Failed to connect to database OR failed to create backup file."

    log "Compressing entire $DATABASE_TYPE database"
    tar -zcvf $COMPRESSED_FILE $BACKUP_PATH

    popd
}

copy_db_to_azure_storage()
{
    log "Upload the backup $DATABASE_TYPE file to azure blob storage"

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

    log "Deleting local copies of $DATABASE_TYPE database"
    rm -rf $COMPRESSED_FILE
    rm -rf $BACKUP_PATH

    rm -rf $TMP_QUERY_ADD
    rm -rf $TMP_QUERY_REMOVE

    popd
}

# Parse script argument(s)
parse_args $@

# Log and other functions
source_utilities_functions

# Script self-idenfitication
print_script_header

source_environment_values $SETTINGS

# Pre-conditionals
exit_if_limited_user
validate_db_type
#todo: other valdiations
use_env_values

create_compressed_db_dump

copy_db_to_azure_storage

cleanup_local_copies
