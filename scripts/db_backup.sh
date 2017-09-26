#!/bin/bash

# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

# Path to settings file provided as an argument to this script.
SETTINGS_FILE=

# From settings file (these variables will be populated with values from the sourced settings file)
    DATABASE_TYPE= # mongo|mysql

    # Reading from database machines
    MONGO_REPLICASET_CONNECTIONSTRING=
    MYSQL_SERVER_IP=
    MYSQL_SERVER_PORT=3306
    DATABASE_USER=
    DATABASE_PASSWORD=

    # Optional values. If provided, will add another set of credentials to msyql backup
    TEMP_DATABASE_USER=
    TEMP_DATABASE_PASSWORD=

    # Writing to storage
    AZURE_STORAGE_ACCOUNT=    # from BACKUP_STORAGEACCOUNT_NAME
    AZURE_STORAGE_ACCESS_KEY= # from BACKUP_STORAGEACCOUNT_KEY

    BACKUP_RETENTIONDAYS=

    # email address for all backup notifications
    CLUSTER_ADMIN_EMAIL=""

# Paths and file names.
    BACKUP_LOCAL_PATH=
    TMP_QUERY_ADD="query.add.sql"
    TMP_QUERY_REMOVE="query.remove.sql"
    CURRENT_SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    UTILITIES_FILE=$CURRENT_SCRIPT_PATH/../templates/stamp/utilities.sh

    # Derived from DATABASE_TYPE
    CONTAINER_NAME=
    COMPRESSED_FILE=
    BACKUP_PATH=

    # this is the file for logging all backup operations
    main_logfile=""

    # emailsubject for all backup notifications
    notification_email_subject=""

    # debug mode: 0=set +x, 1=set -x
    debug_mode=0

help()
{
    SCRIPT_NAME=`basename "$0"`
    echo
    echo "This script $SCRIPT_NAME will backup the database"
    echo "Options:"
    echo "  -s|--settings-file  Path to settings"
    echo
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
            --debug)
                debug_mode=1
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
    if [ -f "$1" ]
    then
        echo "Sourcing file $1"
        source "$1"
    else
        echo "Cannot find file at $1"
        help
        exit 1
    fi
}

validate_db_type()
{
    # validate argument
    if [ "$DATABASE_TYPE" != "mongo" ] && [ "$DATABASE_TYPE" != "mysql" ];
    then
        log "$DATABASE_TYPE is not supported"
        log "Databse type must be mongo or mysql"
        help
        exit 3
    fi
}

validate_remote_storage()
{
    # Exporting for Azure CLI
    export AZURE_STORAGE_ACCOUNT=$BACKUP_STORAGEACCOUNT_NAME   # in <env>.sh AZURE_ACCOUNT_NAME
    export AZURE_STORAGE_ACCESS_KEY=$BACKUP_STORAGEACCOUNT_KEY # in <env>.sh AZURE_ACCOUNT_KEY
    if [ -z $AZURE_STORAGE_ACCOUNT ] || [ -z $AZURE_STORAGE_ACCESS_KEY ]; then
        log "Azure storage credentials are required"
        help
        exit 4
    fi

    # Container names cannot contain underscores or uppercase characters
    CONTAINER_NAME="${DATABASE_TYPE}-backup"
}

validate_settings()
{
    validate_db_type
    validate_remote_storage

    if [[ ! -d "$BACKUP_LOCAL_PATH" ]]; then
        mkdir -p "$BACKUP_LOCAL_PATH"
    fi
}

set_path_names()
{
    TIME_STAMPED=${CONTAINER_NAME}_$(date +"%Y-%m-%d_%Hh-%Mm-%Ss")
    COMPRESSED_FILE="$TIME_STAMPED.tar.gz"

    if [ "$DATABASE_TYPE" == "mysql" ]
    then
        # File
        BACKUP_PATH="$TIME_STAMPED.sql"
    elif [ "$DATABASE_TYPE" == "mongo" ]
    then
        # Directory
        BACKUP_PATH="$TIME_STAMPED"
    fi
}

add_temp_mysql_user()
{
    if [ -z $TEMP_DATABASE_USER ] || [ -z $TEMP_DATABASE_PASSWORD ]; then
        log "We aren't ADDING additional credentials to ${DATABASE_TYPE} db because none were provided."
    else
        log "ADDING ${TEMP_DATABASE_USER} user to ${DATABASE_TYPE} db"
        touch $TMP_QUERY_ADD
        chmod 700 $TMP_QUERY_ADD

        tee ./$TMP_QUERY_ADD > /dev/null <<EOF
GRANT ALL PRIVILEGES ON *.* TO '{TEMP_DATABASE_USER}'@'%' IDENTIFIED BY '{TEMP_DATABASE_PASSWORD}' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

        sed -i "s/{TEMP_DATABASE_USER}/${TEMP_DATABASE_USER}/I" $TMP_QUERY_ADD
        sed -i "s/{TEMP_DATABASE_PASSWORD}/${TEMP_DATABASE_PASSWORD}/I" $TMP_QUERY_ADD

        mysql -u $DATABASE_USER -p$DATABASE_PASSWORD -h $1 < $TMP_QUERY_ADD
    fi
}

remove_temp_mysql_user()
{
    if [ -z $TEMP_DATABASE_USER ] || [ -z $TEMP_DATABASE_PASSWORD ]; then
        log "We aren't REMOVING additional credentials to ${DATABASE_TYPE} db because none were provided."
    else
        log "REMOVING ${TEMP_DATABASE_USER} user from ${DATABASE_TYPE} db"

        touch $TMP_QUERY_REMOVE
        chmod 700 $TMP_QUERY_REMOVE

        tee ./$TMP_QUERY_REMOVE > /dev/null <<EOF
DELETE FROM mysql.user WHERE User='{TEMP_DATABASE_USER}';
FLUSH PRIVILEGES;
EOF

        sed -i "s/{TEMP_DATABASE_USER}/${TEMP_DATABASE_USER}/I" $TMP_QUERY_REMOVE

        mysql -u $DATABASE_USER -p$DATABASE_PASSWORD -h $1 < $TMP_QUERY_REMOVE
    fi
}

create_compressed_db_dump()
{
    # this is the actual backup operation
    log "Backing up '$DATABASE_TYPE' database to local file system"
    
    pushd $BACKUP_LOCAL_PATH
    
    # set the log file & notification
    main_logfile="/var/log/db_backup_${DATABASE_TYPE}.log"
    notification_email_subject="OXA Backup - ${DATABASE_TYPE} Databases"

    # 1. Execute the backup
    if [[ "$DATABASE_TYPE" == "mysql" ]];
    then
        add_temp_mysql_user $MYSQL_SERVER

        # execute dump of all databases
        mysqldump -u $DATABASE_USER -p$DATABASE_PASSWORD -h $MYSQL_SERVER -P $MYSQL_SERVER_PORT --all-databases --single-transaction --set-gtid-purged=OFF --triggers --routines --events > $BACKUP_PATH
        exit_on_error "Unable to backup ${DATABASE_TYPE}!" "${ERROR_DB_BACKUP_FAILED}" "${notification_email_subject}" "${CLUSTER_ADMIN_EMAIL}" "${main_logfile}"

        remove_temp_mysql_user $MYSQL_SERVER

    elif [[ "$DATABASE_TYPE" == "mongo" ]];
    then
        mongodump -u $DATABASE_USER -p $DATABASE_PASSWORD --host $MONGO_REPLICASET_CONNECTIONSTRING --db edxapp --authenticationDatabase master -o $BACKUP_PATH
        exit_on_error "Unable to backup ${DATABASE_TYPE}!" "${ERROR_DB_BACKUP_FAILED}" "${notification_email_subject}" "${CLUSTER_ADMIN_EMAIL}" "${main_logfile}"
    fi

    # 2. Compress the backup
    # log the file size for future tracking
    log "Compressing the backup"

    preCompressFileSize=`stat --printf="%s" $BACKUP_PATH`
    tar -zcvf $COMPRESSED_FILE $BACKUP_PATH
    postCompressFileSize=`stat --printf="%s" $COMPRESSED_FILE`

    log "Uncompressed '$DATABASE_TYPE' database = $preCompressFileSize bytes. Compressed = $postCompressFileSize bytes"
    popd
}

copy_db_to_azure_storage()
{
    pushd $BACKUP_LOCAL_PATH

    log "Upload the backup $DATABASE_TYPE file to azure blob storage"

    # AZURE_STORAGE_ACCOUNT and AZURE_STORAGE_ACCESS_KEY are already exported for azure cli's use.
    # FYI, we could use AZURE_STORAGE_CONNECTION_STRING instead.

    sc=$(azure storage container show  $CONTAINER_NAME --json)
    if [[ -z $sc ]]; then
        log "Creating the container... $CONTAINER_NAME"
        azure storage container create $CONTAINER_NAME
    else
        log "The container $CONTAINER_NAME already exists."
    fi

    log "Uploading file... Please wait..."
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
    pushd $BACKUP_LOCAL_PATH

    log "Deleting local copies of $DATABASE_TYPE database"
    rm -rf $COMPRESSED_FILE
    rm -rf $BACKUP_PATH

    # And any other backups.
    rm -rf *${CONTAINER_NAME}*

    rm -rf $TMP_QUERY_ADD
    rm -rf $TMP_QUERY_REMOVE

    popd
}

cleanup_old_remote_files()
{
    if [-z $BACKUP_RETENTIONDAYS ]; then
        log "No database retention length provided."
        return
    fi

    # This is very noisy. We'll use log to communicate status.
    set +x

    log "Getting list of files and extracting their age"
    log "files older than $BACKUP_RETENTIONDAYS days will be removed"

    # Calculate cutoff time.
    currentSeconds=$(date --date="`date`" +%s)
    retentionPeriod=$(( $BACKUP_RETENTIONDAYS * 24 * 60 * 60 ))
    cutoffInSeconds=$(( $currentSeconds - $retentionPeriod ))

    # Get file list with lots of meta-data. We'll use this to extract dates.
    verboseDetails=`azure storage blob list $CONTAINER_NAME --json`

    # List of files (generally formatted like this: mysql-backup_2017-04-20_03h-00m-01s.tar.gz)
    terminator="\"" # quote
    fileNames=`echo "$verboseDetails" | jq 'map(.name)' | grep -oE "$terminator.*$terminator" | tr -d $terminator`
    # FYI, another approach is to use the file's timestamp which /bin/date can handle natively
    #fileStamp=`echo "$verboseDetails" | jq 'map(.lastModified)'`

    while read fileName; do
        # Parse time from file. Something like  2017-04-20_03h-00m-01s
        #   and convert it to somethign like    2017-04-20 03:00:01
        terminator="s\." # s.
        fileDateString=`echo "$fileName" | grep -o "[0-9].*$terminator" | sed "s/$terminator//g" | sed "s/h-\|m-/:/g" | tr '_' ' '`
        fileDateInSeconds=`date --date="$fileDateString" +%s`

        if [ $cutoffInSeconds -ge $fileDateInSeconds ]; then
            log "deleting $fileName"
            azure storage blob delete -q $CONTAINER_NAME $fileName
        else
            log "keeping $fileName"
        fi
    done <<< "$fileNames"

    set -x
}

# Parse script argument(s)
parse_args $@

# debug mode support
if [[ $debug_mode == 1 ]];
then
    set -x
fi

# log() and other functions
source_wrapper $UTILITIES_FILE

# Script self-idenfitication
print_script_header

log "Begin execution of $DATABASE_TYPE backup script using '${DATABASE_TYPE}' dump command."

# Settings
source_wrapper $SETTINGS_FILE

# Pre-conditionals
exit_if_limited_user
validate_settings

set_path_names

# install requisite tools (if necessary)
log "Conditionally installing requisite tools for backup operations"
install-mysql-client
install-mysql-dump
install-mongodb-tools
install-azure-cli
install-json-processor

# Cleanup previous runs.
cleanup_local_copies

create_compressed_db_dump

copy_db_to_azure_storage

# Cleanup residue from this run.
cleanup_local_copies

# Cleanup old remote files
cleanup_old_remote_files

log "Backup complete!"