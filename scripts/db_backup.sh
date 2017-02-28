#!/bin/bash

# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

#todo:last finish testing on Ubunt14Euc and Ubuntu16Fic.
#   (fyi: all new or changed installation helpers in
#    utilities.sh have been verified on ubuntu 14,16)

set -x

# Path to settings file provided as an argument to this script.
SETTINGS_FILE=

# From settings file
    DATABASE_TYPE= # mongo|mysql

    # Reading from database machines
    MONGO_REPLICASET_CONNECTIONSTRING=
    MYSQL_SERVER_LIST= #todo:1 replace old variable MYSQL_ADDRESS
    #todo:2 these four values missing. we'll have to do some plumbing
    DB_USER=
    DB_PASSWORD=
    # Optional values. Will add another set of credentials to msyql backup.
    MYSQL_TEMP_USER=
    MYSQL_TEMP_PASSWORD=

    # Writing to storage
    AZURE_STORAGE_ACCOUNT=
    AZURE_STORAGE_ACCESS_KEY=

    #todo:story enforce retention policy
    #MONGO_BACKUP_RETENTIONDAYS={MONGO_BACKUP_RETENTIONDAYS}
    #MYSQL_BACKUP_RETENTIONDAYS={MYSQL_BACKUP_RETENTIONDAYS}

# Paths and file names.
    DESTINATION_FOLDER="/var/tmp"
    TMP_QUERY_ADD="query.add.sql"
    TMP_QUERY_REMOVE="query.remove.sql"
    CURRENT_SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    UTILITIES_FILE=$CURRENT_SCRIPT_PATH/../templates/stamp/utilities.sh
    # Derived from DATABASE_TYPE
    CONTAINER_NAME=
    COMPRESSED_FILE=
    BACKUP_PATH=

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
                SETTINGS_FILE=$2
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

source_wrapper()
{
    if [ -f $1 ]
    then
        source $1
    else
        echo "Cannot find file at $1"
        exit 1
    fi
}

validate_db_type()
{
    # validate argument
    if [ "$DATABASE_TYPE" != "mongo" ] && [ "$DATABASE_TYPE" != "mysql" ];
    then
        log "Databse type must be mongo or mysql"
        help
        log "exiting script"
        exit 3
    fi
}

validate_all_settings()
{
    validate_db_type
    #todo:2 waiting for db credentials to be plumbed through
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

    #todo:2 waiting for db credentials to be plumbed through
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

    install-mysql-client
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

    install-mysql-client
    mysql -u $DB_USER -p$DB_PASSWORD -h $MYSQL_ADDRESS < $TMP_QUERY_REMOVE
}

create_compressed_db_dump()
{
    pushd $DESTINATION_FOLDER

    log "Copying entire $DATABASE_TYPE database to local file system"
    if [ "$DATABASE_TYPE" == "mysql" ]
    then
        add_temp_mysql_user
        #todo:1 loop over list. check mysql is responding and break when backup succeeds

        install-mysql-dump
        mysqldump -u $DB_USER -p$DB_PASSWORD -h $MYSQL_ADDRESS --all-databases --single-transaction > $BACKUP_PATH

        remove_temp_mysql_user

    elif [ "$DATABASE_TYPE" == "mongo" ]
    then
        install-mongodb-tools
        mongodump -u $DB_USER -p $DB_PASSWORD --host $MONGO_REPLICASET_CONNECTIONSTRING --db edxapp --authenticationDatabase master -o $BACKUP_PATH

    fi

    exit_on_error "Failed to connect to database OR failed to create backup file."

    log "Compressing entire $DATABASE_TYPE database"
    tar -zcvf $COMPRESSED_FILE $BACKUP_PATH

    popd
}

copy_db_to_azure_storage()
{
    install-azure-cli

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

    install-json-processor
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

# log() and other functions
source_wrapper $UTILITIES_FILE

# Script self-idenfitication
print_script_header

log "Begin execution of $DATABASE_TYPE backup script using ${DATABASE_TYPE}dump command."

# Settings
source_wrapper $SETTINGS_FILE

# Pre-conditionals
exit_if_limited_user
validate_all_settings

use_env_values

create_compressed_db_dump

copy_db_to_azure_storage

cleanup_local_copies
