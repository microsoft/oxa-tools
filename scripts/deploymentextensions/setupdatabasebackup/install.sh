#!/bin/bash
#
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

#
# This script runs setup for database backups on the jumpbox.
#

# Oxa Tools
# Settings for the OXA-Tools public repository 
oxa_tools_public_github_account="Microsoft"
oxa_tools_public_github_projectname="oxa-tools"
oxa_tools_public_github_projectbranch="oxa/master.fic"
oxa_tools_public_github_branchtag=""
oxa_tools_repository_path="/oxa/oxa-tools"

# Email Notifications
notification_email_subject="Database Backup Setup"
cluster_admin_email=""
cluster_name=""

main_logfile="/var/log/bootstrap.csx.log"

# core variables
encoded_mongo_server_list=`echo "10.0.0.11 10.0.0.12 10.0.0.13" | base64`
encoded_mysql_server=`echo "10.0.0.16" | base64`
mysql_server_port=3306
mongo_replicaset_name=""

# backup settings
backup_storageaccount_name="${cluster_name}securesa"
backup_storageaccount_key=""
backup_local_path="/datadisks/disk1"
backup_storageaccount_endpoint_suffix="core.windows.net"

# mysql backup settings
mysql_backup_frequency="11 */4 * * *"   # At minute 11 past every 4th hour.
mysql_backup_retentiondays=7
mysql_admin_username=""
mysql_admin_password=""
mysql_backup_username=""
mysql_backup_password=""

# mongo backup settings
mongo_backup_frequency="0 0 * * *"      # At every 00:00 (midnight)
mongo_backup_retentiondays=7
mongo_admin_username=""
mongo_admin_password=""
mongo_backup_username=""
mongo_backup_password=""

# Azure cli version (default to 1.0)
azure_cli_version=1

#############################################################################
# parse the command line arguments

parse_args() 
{
    while [[ "$#" -gt 0 ]]
    do
        arg_value="${2}"
        shift_once=0

        if [[ "${arg_value}" =~ "--" ]]; 
        then
            arg_value=""
            shift_once=1
        fi

         # Log input parameters to facilitate troubleshooting
        log "Option '${1}' set with value '"${arg_value}"'"

        case "$1" in
            --oxatools-public-github-accountname)
                oxa_tools_public_github_account="${arg_value}"
                ;;
            --oxatools-public-github-projectname)
                oxa_tools_public_github_projectname="${arg_value}"
                ;;
            --oxatools-public-github-projectbranch)
                oxa_tools_public_github_projectbranch="${arg_value}"
                ;;
            --oxatools-public-github-branchtag)
                oxa_tools_public_github_branchtag="${arg_value}"
                ;;
            --oxatools-repository-path)
                oxa_tools_repository_path="${arg_value}"
                ;;
            --azure-resource-group)
                cluster_name="${arg_value}"
                backup_storageaccount_name="${cluster_name}securesa"
                ;;
            --cluster-admin-email)
                cluster_admin_email="${arg_value}"
                ;;
            --mongo-replicaset-name)
                mongo_replicaset_name="${arg_value}"
                ;;
            --mongo-server-list)
                encoded_mongo_server_list="${arg_value}"
                ;;
            --mysql-server)
                encoded_mysql_server="${arg_value}"
                ;;
            --mysql-server-port)
                mysql_server_port="${arg_value}"
                ;;
            --backup-storageaccount-name)
                backup_storageaccount_name="${arg_value}"
                ;;
            --backup-storageaccount-key)
                backup_storageaccount_key="${arg_value}"
                ;;
            --backup-storageaccount-endpointsuffix)
                backup_storageaccount_endpoint_suffix="${arg_value}"
                ;;
            --backup-local-path)
                backup_local_path="${arg_value}"
                ;;
            # mysql backup settings
            --mysql-backup-frequency)
                mysql_backup_frequency=`echo ${arg_value} | base64 --decode`
                ;;
            --mysql-backup-retentiondays)
                mysql_backup_retentiondays="${arg_value}"
                ;;
            --mysql-admin-username)
                mysql_admin_username="${arg_value}"
                ;;
            --mysql-admin-password)
                mysql_admin_password="${arg_value}"
                ;;
            --mysql-backup-username)
                mysql_backup_username="${arg_value}"
                ;;
            --mysql-backup-password)
                mysql_backup_password="${arg_value}"
                ;;
            # mongo backup settings
            --mongo-backup-frequency)
                mongo_backup_frequency=`echo ${arg_value} | base64 --decode`
                ;;
            --mongo-backup-retentiondays)
                mongo_backup_retentiondays="${arg_value}"
                ;;
            --mongo-admin-username)
                mongo_admin_username="${arg_value}"
                ;;
            --mongo-admin-password)
                mongo_admin_password="${arg_value}"
                ;;
            --mongo-backup-username)
                mongo_backup_username="${arg_value}"
                ;;
            --mongo-backup-password)
                mongo_backup_password="${arg_value}"
                ;;            
            --azure-cli-version)
                azure_cli_version=$2
                if ! is_valid_arg "1 2" $azure_cli_version; then
                    echo "Invalid azure cli specified. Only versions 1 & 2 are supported\n"
                    exit 2
                fi
                ;;
            --debug)
                debug_mode=1
                ;;
        esac

        shift # past argument or value

        if [ $shift_once -eq 0 ]; 
        then
            shift # past argument or value
        fi

    done
}

validate_args()
{
    log "Validating arguments"

    # notification email address
    if [[ -z $cluster_admin_email ]]; 
    then
        log "You must specify an email address for deployment notification"
        exit $ERROR_DB_BACKUPSETUP_FAILED
    fi

    # server lists (encoded)
    if [[ -z $encoded_mongo_server_list ]] || [[ -z $encoded_mysql_server ]]; 
    then
        log "You must specify an encoded mongo & mysql server list"
        exit $ERROR_DB_BACKUPSETUP_FAILED
    fi

    # backup storage account
    if [[ -z $backup_storageaccount_name ]] || [[ -z $backup_storageaccount_key ]]; 
    then
        log "You must specify both a storage account name and key"
        exit $ERROR_DB_BACKUPSETUP_FAILED
    fi
    
    # backup path
    if [[ ! -d $backup_local_path ]]; 
    then
        log "The backup local path specified doesn't exist"
        exit $ERROR_DB_BACKUPSETUP_FAILED
    fi

    # mysql credentials (user name/password)
    if [[ -z $mysql_admin_username ]] || [[ -z $mysql_admin_password ]]; 
    then
        log "Invalid mysql credentials specified. You must provide both a user name and password for mysql"
        exit $ERROR_DB_BACKUPSETUP_FAILED
    fi

    # mysql credentials (user name/password)
    if [[ -z $mongo_admin_username ]] || [[ -z $mongo_admin_password ]]; 
    then
        log "Invalid mongo credentials specified. You must provide both a user name and password for mongo"
        exit $ERROR_DB_BACKUPSETUP_FAILED
    fi

    # set defaults
    if [[ -z $mysql_backup_username ]];
    then
        log "Defaulting mysql backup user credentials to the main credential specified"
        mysql_backup_username="${mysql_admin_username}"
        mysql_backup_password="${mysql_admin_password}"
    fi

    if [[ -z $mongo_backup_username ]];
    then
        log "Defaulting mongo backup user credentials to the main credential specified"
        mongo_backup_username="${mongo_admin_username}"
        mongo_backup_password="${mongo_admin_password}"
    fi

    log "Completed argument validation successfully"
}

###############################################
# START CORE EXECUTION
###############################################

# Source our utilities for logging and other base functions (we need this staged with the installer script)
# the file needs to be first downloaded from the public repository
current_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
utilities_path=$current_path/utilities.sh

# check if the utilities file exists. If not, bail out.
if [[ ! -e $utilities_path ]]; 
then  
    echo :"Utilities not present"
    exit 3
fi

# source the utilities now
source $utilities_path

# Script self-identification
print_script_header $notification_email_subject

# pass existing command line arguments
parse_args $@
validate_args

# debug mode support
if [[ $debug_mode == 1 ]];
then
    set -x
fi

# sync the oxa-tools repository
repo_url=`get_github_url "$oxa_tools_public_github_account" "$oxa_tools_public_github_projectname"`
sync_repo $repo_url $oxa_tools_public_github_projectbranch $oxa_tools_repository_path $access_token $oxa_tools_public_github_branchtag
log "Repository sync is complete" " " 2

####################################
# Main Operations
####################################

log "Starting database backup configuration on '${HOSTNAME}'"

# Initialize fixed variables
installer_basepath="${oxa_tools_repository_path}/scripts"
mysql_server=`echo ${encoded_mysql_server} | base64 --decode`
mongo_server_list=`echo ${encoded_mongo_server_list} | base64 --decode`
mongo_replicaset_connectionstring="${mongo_replicaset_name}/${mongo_server_list}"
database_backup_script="${installer_basepath}/db_backup.sh"

# storage account endpoint suffix
encoded_backup_storageaccount_endpoint_suffix=`echo ${backup_storageaccount_endpoint_suffix} | base64`

# Setup mysql backup
log "Setting up mysql backup"
database_type="mysql"
database_backup_log="/var/log/db_backup_${database_type}.log"
setup_backup "${installer_basepath}/backup_configuration_${database_type}.sh" "${database_backup_script}" "${database_backup_log}" "${backup_storageaccount_name}" \
    "${backup_storageaccount_key}" "${mysql_backup_frequency}" "${mysql_backup_retentiondays}" "${mongo_replicaset_connectionstring}" "${mysql_server}" \
    "${database_type}" "${mysql_admin_username}" "${mysql_admin_password}" "${backup_local_path}" "${mysql_server_port}" "${cluster_admin_email}" "${azure_cli_version}" \
    "${encoded_backup_storageaccount_endpoint_suffix}" "${mysql_backup_username}" "${mysql_backup_password}"

exit_on_error "Failed setting up the Mysql Database backup" 1 "${notification_email_subject} Failed" $cluster_admin_email $main_logfile

# Setup mongo backup
log "Setting up mongo backup"
database_type="mongo"
database_backup_log="/var/log/db_backup_${database_type}.log"
setup_backup "${installer_basepath}/backup_configuration_${database_type}.sh" "${database_backup_script}" "${database_backup_log}" "${backup_storageaccount_name}" \
    "${backup_storageaccount_key}" "${mongo_backup_frequency}" "${mongo_backup_retentiondays}" "${mongo_replicaset_connectionstring}" "${mysql_server}" \
    "${database_type}" "${mongo_admin_username}" "${mongo_admin_password}" "${backup_local_path}" "${mysql_server_port}" "${cluster_admin_email}" "${azure_cli_version}" \
    "${encoded_backup_storageaccount_endpoint_suffix}" "${mongo_backup_username}" "${mongo_backup_password}"

exit_on_error "Failed setting up the Mongo Database backup" 1 "${notification_email_subject} Failed" $cluster_admin_email $main_logfile

log "Completed database backup configuration"