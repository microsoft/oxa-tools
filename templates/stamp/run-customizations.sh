#!/bin/bash
#
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

NOTIFICATION_MESSAGE=""
SECONDARY_LOG="/var/log/bootstrap.csx.log"
PRIMARY_LOG="/var/log/bootstrap.log"

ERROR_MESSAGE=1
CLOUDNAME=""
OS_ADMIN_USERNAME=""
CUSTOM_INSTALLER_RELATIVEPATH=""
MONITORING_CLUSTER_NAME=""
BOOTSTRAP_PHASE=0
REPO_ROOT="/oxa"
CRONTAB_INTERVAL_MINUTES=5

# Oxa Tools Github configs
OXA_TOOLS_PUBLIC_GITHUB_PROJECTNAME="oxa-tools"
OXA_TOOLS_PUBLIC_GITHUB_ACCOUNTNAME="Microsoft"
OXA_TOOLS_PUBLIC_GITHUB_PROJECTBRANCH="master"

# Edx Configuration Github configs
EDX_CONFIGURATION_PUBLIC_GITHUB_PROJECTNAME="edx-configuration"
EDX_CONFIGURATION_PUBLIC_GITHUB_ACCOUNTNAME="Microsoft"
EDX_CONFIGURATION_PUBLIC_GITHUB_PROJECTBRANCH="oxa/master"

# EdX Platform
# There are cases where we want to override the edx-platform repository itself
EDX_PLATFORM_PUBLIC_GITHUB_ACCOUNTNAME="Microsoft"
EDX_PLATFORM_PUBLIC_GITHUB_PROJECTNAME="edx-platform"
EDX_PLATFORM_PUBLIC_GITHUB_PROJECTBRANCH="oxa/master"

# EdX Theme
# There are cases where we want to override the edx-platform repository itself
EDX_THEME_PUBLIC_GITHUB_ACCOUNTNAME="Microsoft"
EDX_THEME_PUBLIC_GITHUB_PROJECTNAME="edx-theme"
EDX_THEME_PUBLIC_GITHUB_PROJECTBRANCH="pilot"

# EdX Ansible
# There are cases where we want to override the edx\ansible repository itself
ANSIBLE_PUBLIC_GITHUB_ACCOUNTNAME="edx"
ANSIBLE_PUBLIC_GITHUB_PROJECTNAME="ansible"
ANSIBLE_PUBLIC_GITHUB_PROJECTBRANCH="master"

# MISC
EDX_VERSION="named-release/dogwood.rc"
FORUM_VERSION="mongoid5-release"

# operational mode
CRON_MODE=0

# SMTP / Mailer parameters
SMTP_SERVER=""
SMTP_SERVER_PORT=""
SMTP_AUTH_USER=""
SMTP_AUTH_USER_PASSWORD=""
CLUSTER_ADMIN_EMAIL=""
MAIL_SUBJECT="OXA Bootstrap"
NOTIFICATION_MESSAGE=""
SECONDARY_LOG="/var/log/bootstrap.csx.log"
PRIMARY_LOG="/var/log/bootstrap.log"

# Database Backup Parameters
BACKUP_STORAGEACCOUNT_NAME=""
BACKUP_STORAGEACCOUNT_KEY=""
MONGO_BACKUP_FREQUENCY="0 0 * * *"  # backup once daily
MYSQL_BACKUP_FREQUENCY="0 */4 * * *" # backup every 4 hours
MONGO_BACKUP_RETENTIONDAYS="7"
MYSQL_BACKUP_RETENTIONDAYS="7"

help()
{
    echo "This script bootstraps the OXA Stamp"
    echo "Options:"
    echo "        -c Cloud name"
    echo "        -u OS Admin User Name"
    echo "        -i Custom script relative path"
    echo "        -u OS Admin User Name"
    echo "        -m Monitoring cluster name"
    echo "        -s Bootstrap Phase (0=Servers, 1=OpenEdx App)"
    echo "        --keyvault-name Name of the key vault"
    echo "        --aad-webclient-id Id of AAD web client (service principal)"
    echo "        --aad-webclient-appkey Application key for the AAD web client"
    echo "        --aad-tenant-id AAD Tenant Id"
    echo "        --oxatools-public-github-accountname Name of the account that owns the oxa-tools GitHub repository"
    echo "        --oxatools-public-github-projectname Name of the oxa-tools GitHub repository"
    echo "        --oxatools-public-github-projectbranch Branch of the oxa-tools GitHub repository"
    echo "        --edxconfiguration-public-github-accountname Name of the account that owns the edx configuration repository"
    echo "        --edxconfiguration-public-github-projectname Name of the edx configuration GitHub repository"
    echo "        --edxconfiguration-public-github-projectbranch Branch of edx configuration GitHub repository"
    echo "        --edxplatform-public-github-accountname Name of the account that owns the edx platform repository"
    echo "        --edxplatform-public-github-projectname Name of the edx platform GitHub repository"
    echo "        --edxplatform-public-github-projectbranch Branch of edx platform GitHub repository"
    echo "        --edxtheme-public-github-accountname Name of the account that owns the edx theme repository"
    echo "        --edxtheme-public-github-projectname Name of the edx theme GitHub repository"
    echo "        --edxtheme-public-github-projectbranch Branch of edx theme GitHub repository"
    echo "        --ansible-public-github-accountname Name of the account that owns the edx ansible repository"
    echo "        --ansible-public-github-projectname Name of the edx ansible GitHub repository"
    echo "        --ansible-public-github-projectbranch Branch of edx ansible GitHub repository"
    echo "        --edxversion EdX Named-Release to use for this deployment"
    echo "        --forumversion EdX Named Release to use for the FORUMS component"
    echo "        --cron Operation mode for the script"
    echo "        --azure-subscription-id  Azure subscription id"
    echo "        --smtp-server FQDN of SMTP server used for relaying deployment and other system notifications"
    echo "        --smtp-server-port Port of SMTP server used for relaying deployment and other system notifications"
    echo "        --smtp-auth-user User name for authenticating against the SMTP server used for relaying deployment and other system notifications"
    echo "        --smtp-auth-user-password Password for authenticating against the SMTP server used for relaying deployment and other system notifications"
    echo "        --cluster-admin-email Email address of the administrator where system and other notifications will be sent"
    echo "        --storage-account-name Name of the storage account used in backups"
    echo "        --storage-account-key Key for the storage account used in backups"
    echo "        --mongo-backup-frequency Cron frequency for running a full backup of the mysql database. The expected format is parameter|value as supported by Ansible."
    echo "        --mysql-backup-frequency Cron frequency for running a full backup of the mysql database. The expected format is parameter|value as supported by Ansible."
    echo "        --mongo-backup-retention-days Number of days to keep old Mongo database backups. Backups older than this number of days will be deleted"
    echo "        --mysql-backup-retention-days Number of days to keep old Mysql database backups. Backups older than this number of days will be deleted"
}

# Parse script parameters
# When adding parameters, make sure to pass the same variables during the cron mode setup
parse_args()
{
    while [[ "$#" -gt 0 ]]
        do

         # Log input parameters to facilitate troubleshooting
        echo "Option '$1' set with value '$2'"

        case "$1" in
            -c) # Cloud Name
                CLOUDNAME=$2
                ;;
            -u) # OS Admin User Name
                OS_ADMIN_USERNAME=$2
                ;;
            -i) # Custom script relative path
                CUSTOM_INSTALLER_RELATIVEPATH=$2
                ;;
            -m) # Monitoring cluster name
                MONITORING_CLUSTER_NAME=$2
                ;;
            -s|--phase) # Bootstrap Phase (0=Servers, 1=OpenEdx App)
                if is_valid_arg "0 1" $2; then
                    BOOTSTRAP_PHASE=$2
                else
                    log "Invalid Bootstrap Phase specified - $2" $ERROR_MESSAGE
                    help
                    exit 2
                fi
                ;;
            -u|--admin-user)
                OS_ADMIN_USERNAME=$2
                ;;
            --monitoring-cluster)
                MONITORING_CLUSTER_NAME=$2
                ;;
            --crontab-interval)
                CRONTAB_INTERVAL_MINUTES=$2
                ;;
            --keyvault-name)
                KEYVAULT_NAME="$2"
                ;;
            --aad-webclient-id)
                AAD_WEBCLIENT_ID="$2"
                ;;
            --aad-webclient-appkey)
                AAD_WEBCLIENT_APPKEY="$2"
                ;;
            --aad-tenant-id)
                AAD_TENANT_ID="$2"
                ;;
            --oxatools-public-github-accountname)
                OXA_TOOLS_PUBLIC_GITHUB_ACCOUNTNAME="$2"
                ;;
            --oxatools-public-github-projectname)
                OXA_TOOLS_PUBLIC_GITHUB_PROJECTNAME="$2"
                ;;
            --oxatools-public-github-projectbranch)
                OXA_TOOLS_PUBLIC_GITHUB_PROJECTBRANCH="$2"
                ;;
            --edxconfiguration-public-github-accountname)
                EDX_CONFIGURATION_PUBLIC_GITHUB_ACCOUNTNAME="$2"
                ;;
            --edxconfiguration-public-github-projectname)
                EDX_CONFIGURATION_PUBLIC_GITHUB_PROJECTNAME="$2"
                ;;
            --edxconfiguration-public-github-projectbranch)
                EDX_CONFIGURATION_PUBLIC_GITHUB_PROJECTBRANCH="$2"
                ;;
            --edxplatform-public-github-accountname)
                EDX_PLATFORM_PUBLIC_GITHUB_ACCOUNTNAME="$2"
                ;;
            --edxplatform-public-github-projectname)
                EDX_PLATFORM_PUBLIC_GITHUB_PROJECTNAME="$2"
                ;;
            --edxplatform-public-github-projectbranch)
                EDX_PLATFORM_PUBLIC_GITHUB_PROJECTBRANCH="$2"
                ;;
            --edxtheme-public-github-accountname)
                EDX_THEME_PUBLIC_GITHUB_ACCOUNTNAME="$2"
                ;;
            --edxtheme-public-github-projectname)
                EDX_THEME_PUBLIC_GITHUB_PROJECTNAME="$2"
                ;;
            --edxtheme-public-github-projectbranch)
                EDX_THEME_PUBLIC_GITHUB_PROJECTBRANCH="$2"
                ;;
            --ansible-public-github-accountname)
                ANSIBLE_PUBLIC_GITHUB_ACCOUNTNAME="$2"
                ;;
            --ansible-public-github-projectname)
                ANSIBLE_PUBLIC_GITHUB_PROJECTNAME="$2"
                ;;
            --ansible-public-github-projectbranch)
                ANSIBLE_PUBLIC_GITHUB_PROJECTBRANCH="$2"
                ;;
            --edxversion)
                EDX_VERSION="$2"
                ;;
            --forumversion)
                FORUM_VERSION="$2"
                ;;
            --azure-subscription-id)
                AZURE_SUBSCRIPTION_ID="$2"
                ;;
            --smtp-server)
                SMTP_SERVER="$2"
                ;;
            --smtp-server-port)
                SMTP_SERVER_PORT="$2"
                ;;
            --smtp-auth-user)
                SMTP_AUTH_USER="$2"
                ;;
            --smtp-auth-user-password)
                SMTP_AUTH_USER_PASSWORD="$2"
                ;;
            --cluster-admin-email)
                CLUSTER_ADMIN_EMAIL="$2"
                ;;
            --cluster-name)
                CLUSTER_NAME="$2"
                MAIL_SUBJECT="${MAIL_SUBJECT} - ${2,,}"
                ;;
            --cron)
                CRON_MODE=1
                ;;
            --storage-account-name)
                BACKUP_STORAGEACCOUNT_NAME="$2"
                ;;
             --storage-account-key)
                BACKUP_STORAGEACCOUNT_KEY="$2"
                ;;
              --mongo-backup-frequency)
                MONGO_BACKUP_FREQUENCY="${2//_/ }"
                echo "Option '${1}' reset to '$MONGO_BACKUP_FREQUENCY'"
                ;;
              --mysql-backup-frequency)
                MYSQL_BACKUP_FREQUENCY="${2//_/ }"
                echo "Option '${1}' reset to '$MYSQL_BACKUP_FREQUENCY'"
                ;;
              --mongo-backup-retention-days)
                MONGO_BACKUP_RETENTIONDAYS="$2"
                ;;
              --mysql-backup-retention-days)
                MYSQL_BACKUP_RETENTIONDAYS="$2"
                ;;
            -h|--help)  # Helpful hints
                help
                exit 2
                ;;
            *) # unknown option
                echo "Option '${BOLD}$1${NORM} $2' not allowed."
                help
                exit 2
                ;;
        esac
        
        shift # past argument
        shift # past argument or value
    done
}

###############################################
# Start Execution
###############################################

# source our utilities for logging and other base functions (we need this staged with the installer script)
# the file needs to be first downloaded from the public repository
CURRENT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
UTILITIES_PATH=$CURRENT_PATH/utilities.sh

# check if the utilities file exists. If not, bail out.
if [[ ! -e $UTILITIES_PATH ]]; 
then  
    echo :"Utilities not present"
    exit 3
fi

# source the utilities now
source $UTILITIES_PATH

# Script self-idenfitication
print_script_header

parse_args $@ # pass existing command line arguments

# Validate parameters
if [ "$OXA_TOOLS_PUBLIC_GITHUB_ACCOUNTNAME" == "" ] || [ "$OXA_TOOLS_PUBLIC_GITHUB_PROJECTNAME" == "" ] || [ "$OXA_TOOLS_PUBLIC_GITHUB_PROJECTBRANCH" == "" ] || [ "$CLOUDNAME" == "" ] ;
then
    log "Incomplete OXA Tools Github repository configuration: Github Personal Access Token, Account Name,  Project Name & Branch Name are required." $ERROR_MESSAGE
    exit 3
fi

if [ "$EDX_CONFIGURATION_PUBLIC_GITHUB_ACCOUNTNAME" == "" ] || [ "$EDX_CONFIGURATION_PUBLIC_GITHUB_PROJECTNAME" == "" ] || [ "$EDX_CONFIGURATION_PUBLIC_GITHUB_PROJECTBRANCH" == "" ] ;
then
    log "Incomplete EDX Configuration Github repository configuration: Github Personal Access Token, Account Name,  Project Name & Branch Name are required." $ERROR_MESSAGE
    exit 3
fi

# to support resiliency, we need to enable retries. Towards that end, this script will support 2 modes: Cron (background execution) or Non-Cron (Custom Script Extension-CSX/direct execution)
CRON_INSTALLER_SCRIPT="$CURRENT_PATH/background-run-customization.sh"

if [ "$CRON_MODE" == "0" ];
then
    log "Setting up cron job for executing customization from '${HOSTNAME}' for the OXA Stamp"

    # setup the repo parameters individually
    OXA_TOOLS_GITHUB_PARAMS="--oxatools-public-github-accountname \"${OXA_TOOLS_PUBLIC_GITHUB_ACCOUNTNAME}\" --oxatools-public-github-projectname \"${OXA_TOOLS_PUBLIC_GITHUB_PROJECTNAME}\" --oxatools-public-github-projectbranch \"${OXA_TOOLS_PUBLIC_GITHUB_PROJECTBRANCH}\""
    EDX_CONFIGURATION_GITHUB_PARAMS="--edxconfiguration-public-github-accountname \"${EDX_CONFIGURATION_PUBLIC_GITHUB_ACCOUNTNAME}\" --edxconfiguration-public-github-projectname \"${EDX_CONFIGURATION_PUBLIC_GITHUB_PROJECTNAME}\" --edxconfiguration-public-github-projectbranch \"${EDX_CONFIGURATION_PUBLIC_GITHUB_PROJECTBRANCH}\""
    EDX_PLATFORM_GITHUB_PARAMS="--edxplatform-public-github-accountname \"${EDX_PLATFORM_PUBLIC_GITHUB_ACCOUNTNAME}\" --edxplatform-public-github-projectname \"${EDX_PLATFORM_PUBLIC_GITHUB_PROJECTNAME}\" --edxplatform-public-github-projectbranch \"${EDX_PLATFORM_PUBLIC_GITHUB_PROJECTBRANCH}\""
    EDX_THEME_GITHUB_PARAMS="--edxtheme-public-github-accountname \"${EDX_THEME_PUBLIC_GITHUB_ACCOUNTNAME}\" --edxtheme-public-github-projectname \"${EDX_THEME_PUBLIC_GITHUB_PROJECTNAME}\" --edxtheme-public-github-projectbranch \"${EDX_THEME_PUBLIC_GITHUB_PROJECTBRANCH}\""
    ANSIBLE_GITHUB_PARAMS="--ansible-public-github-accountname \"${ANSIBLE_PUBLIC_GITHUB_ACCOUNTNAME}\" --ansible-public-github-projectname \"${ANSIBLE_PUBLIC_GITHUB_PROJECTNAME}\" --ansible-public-github-projectbranch \"${ANSIBLE_PUBLIC_GITHUB_PROJECTBRANCH}\""

    # strip out the spaces for passing it along
    MONGO_BACKUP_FREQUENCY="${MONGO_BACKUP_FREQUENCY// /_}"
    MYSQL_BACKUP_FREQUENCY="${MYSQL_BACKUP_FREQUENCY// /_}"

    BACKUP_PARAMS="--storage-account-name \"${BACKUP_STORAGEACCOUNT_NAME}\" --storage-account-key \"${BACKUP_STORAGEACCOUNT_KEY}\" --mongo-backup-frequency \"${MONGO_BACKUP_FREQUENCY}\" --mysql-backup-frequency \"${MYSQL_BACKUP_FREQUENCY}\" --mongo-backup-retention-days \"${MONGO_BACKUP_RETENTIONDAYS}\" --mysql-backup-retention-days \"${MYSQL_BACKUP_RETENTIONDAYS}\""

    # create the cron job & exit
    INSTALL_COMMAND="sudo flock -n /var/log/bootstrap-run-customization.lock bash $CURRENT_PATH/run-customizations.sh -c $CLOUDNAME -u $OS_ADMIN_USERNAME -i $CUSTOM_INSTALLER_RELATIVEPATH -m $MONITORING_CLUSTER_NAME -s $BOOTSTRAP_PHASE -u $OS_ADMIN_USERNAME --monitoring-cluster $MONITORING_CLUSTER_NAME --crontab-interval $CRONTAB_INTERVAL_MINUTES --keyvault-name $KEYVAULT_NAME --aad-webclient-id $AAD_WEBCLIENT_ID --aad-webclient-appkey $AAD_WEBCLIENT_APPKEY --aad-tenant-id $AAD_TENANT_ID --azure-subscription-id $AZURE_SUBSCRIPTION_ID --smtp-server $SMTP_SERVER --smtp-server-port $SMTP_SERVER_PORT --smtp-auth-user $SMTP_AUTH_USER --smtp-auth-user-password $SMTP_AUTH_USER_PASSWORD --cluster-admin-email $CLUSTER_ADMIN_EMAIL --cluster-name $CLUSTER_NAME ${OXA_TOOLS_GITHUB_PARAMS} ${EDX_CONFIGURATION_GITHUB_PARAMS} ${EDX_PLATFORM_GITHUB_PARAMS} ${EDX_THEME_GITHUB_PARAMS} ${ANSIBLE_GITHUB_PARAMS} ${BACKUP_PARAMS} --edxversion $EDX_VERSION --forumversion $FORUM_VERSION --cron >> $SECONDARY_LOG 2>&1"
    echo $INSTALL_COMMAND > $CRON_INSTALLER_SCRIPT

    # Remove the task if it is already setup
    log "Uninstalling run-customization background installer cron job"
    crontab -l | grep -v "sudo bash $CRON_INSTALLER_SCRIPT" | crontab -

    # Setup the background job
    log "Installing run-customization background installer cron job"
    crontab -l | { cat; echo "*/${CRONTAB_INTERVAL_MINUTES} * * * *  sudo bash $CRON_INSTALLER_SCRIPT"; } | crontab -
    exit_on_error "OXA stamp customization ($INSTALLER_PATH) failed" $ERROR_CRONTAB_FAILED

    log "Crontab setup is done"
    exit 0
fi

log "Begin customization from '${HOSTNAME}' for the OXA Stamp"

MACHINE_ROLE=$(get_machine_role)
log "${HOSTNAME} has been identified as a member of the '${MACHINE_ROLE}' role"

# Pre-Requisite: Setup Mailer (this is necessary for notification)
install-mailer $SMTP_SERVER $SMTP_SERVER_PORT $SMTP_AUTH_USER $SMTP_AUTH_USER_PASSWORD $CLUSTER_ADMIN_EMAIL
exit_on_error "Configuring the mailer failed"

# 1. Setup Tools
install-git
install-gettext
set_timezone

if [ "$MACHINE_ROLE" == "jumpbox" ] || [ "$MACHINE_ROLE" == "vmss" ];
then
    install-mongodb-shell
    install-mysql-client

    install-powershell
    install-azure-cli
fi

# 2. Install & Configure the infrastructure & EdX applications
log "Cloning the public OXA Tools Repository"
clone_repository $OXA_TOOLS_PUBLIC_GITHUB_ACCOUNTNAME $OXA_TOOLS_PUBLIC_GITHUB_PROJECTNAME $OXA_TOOLS_PUBLIC_GITHUB_PROJECTBRANCH ''  "${REPO_ROOT}/${OXA_TOOLS_PUBLIC_GITHUB_PROJECTNAME}"

# setup the installer path & key variables
INSTALLER_BASEPATH="${REPO_ROOT}/${OXA_TOOLS_PUBLIC_GITHUB_PROJECTNAME}/scripts"
INSTALLER_PATH="${INSTALLER_BASEPATH}/install.sh"
DEPLOYMENT_ENV="${CLOUDNAME,,}" 
OXA_ENV_PATH="${REPO_ROOT}/oxa-tools-config/env/${DEPLOYMENT_ENV}"

# drop the environment configurations
log "Download configurations from keyvault"
export HOME=$(dirname ~/.)

if [[ -d $OXA_ENV_PATH ]]; then
    log "Removing the existing configuration from '${OXA_ENV_PATH}'"
    rm -rf $OXA_ENV_PATH
fi

powershell -file $INSTALLER_BASEPATH/Process-OxaToolsKeyVaultConfiguration.ps1 -Operation Download -VaultName $KEYVAULT_NAME -AadWebClientId $AAD_WEBCLIENT_ID -AadWebClientAppKey $AAD_WEBCLIENT_APPKEY -AadTenantId $AAD_TENANT_ID -TargetPath $OXA_ENV_PATH -AzureSubscriptionId $AZURE_SUBSCRIPTION_ID
exit_on_error "Failed downloading configurations from keyvault" 1 "${MAIL_SUBJECT} Failed" $CLUSTER_ADMIN_EMAIL $PRIMARY_LOG $SECONDARY_LOG

# copy utilities to the installer path
cp $UTILITIES_PATH "${INSTALLER_BASEPATH}"

#####################################
# Setup Backups
#####################################

if [ "$MACHINE_ROLE" == "jumpbox" ];
then
    log "Starting backup configuration on '${HOSTNAME}' as a member in the '${MACHINE_ROLE}' role"

    # setup the configuration file for database backups
    source "${OXA_ENV_PATH}/${DEPLOYMENT_ENV}.sh"
    exit_on_error "Failed sourcing the environment configuration file from keyvault" 1 "${MAIL_SUBJECT} Failed" $CLUSTER_ADMIN_EMAIL $PRIMARY_LOG $SECONDARY_LOG

    # these are fixed values
    MONGO_REPLICASET_CONNECTIONSTRING="${MONGO_REPLICASET_NAME}/${MONGO_SERVER_LIST}"
    DATABASE_BACKUP_SCRIPT="${INSTALLER_BASEPATH}/db_backup.sh"

    # setup mysql backup
    DATABASE_TYPE_TO_BACKUP="mysql"
    DATABASE_BACKUP_LOG="/var/log/db_backup_${DATABASE_TYPE_TO_BACKUP}.log"
    setup_backup "${INSTALLER_BASEPATH}/backup_configuration_${DATABASE_TYPE_TO_BACKUP}.sh" "${DATABASE_BACKUP_SCRIPT}" "${DATABASE_BACKUP_LOG}" "${BACKUP_STORAGEACCOUNT_NAME}" "${BACKUP_STORAGEACCOUNT_KEY}" "${MYSQL_BACKUP_FREQUENCY}" "${MYSQL_BACKUP_RETENTIONDAYS}" "${MONGO_REPLICASET_CONNECTIONSTRING}" "${MYSQL_SERVER_LIST}" "${DATABASE_TYPE_TO_BACKUP}" "${MYSQL_ADMIN_USER}" "${MYSQL_ADMIN_PASSWORD}" "${MYSQL_TEMP_USER}" "${MYSQL_TEMP_PASSWORD}"
    exit_on_error "Failed setting up the Mysql Database backup" 1 "${MAIL_SUBJECT} Failed" $CLUSTER_ADMIN_EMAIL $PRIMARY_LOG $SECONDARY_LOG

    # setup mongo backup
    DATABASE_TYPE_TO_BACKUP="mongo"
    DATABASE_BACKUP_LOG="/var/log/db_backup_${DATABASE_TYPE_TO_BACKUP}.log"
    setup_backup "${INSTALLER_BASEPATH}/backup_configuration_${DATABASE_TYPE_TO_BACKUP}.sh" "${DATABASE_BACKUP_SCRIPT}" "${DATABASE_BACKUP_LOG}" "${BACKUP_STORAGEACCOUNT_NAME}" "${BACKUP_STORAGEACCOUNT_KEY}" "${MONGO_BACKUP_FREQUENCY}" "${MONGO_BACKUP_RETENTIONDAYS}" "${MONGO_REPLICASET_CONNECTIONSTRING}" "${MYSQL_SERVER_LIST}" "${DATABASE_TYPE_TO_BACKUP}" "${MONGO_USER}" "${MONGO_PASSWORD}" "${MONGO_USER}" "${MONGO_PASSWORD}"
    exit_on_error "Failed setting up the Mongo Database backup" 1 "${MAIL_SUBJECT} Failed" $CLUSTER_ADMIN_EMAIL $PRIMARY_LOG $SECONDARY_LOG
fi

#####################################
# Launch Installer
#####################################

# execute the installer if present
log "Launching the installer at '$INSTALLER_PATH'"
bash $INSTALLER_PATH --repo-root $REPO_ROOT --config-path "${REPO_ROOT}/oxa-tools-config" --cloud $CLOUDNAME --admin-user $OS_ADMIN_USERNAME --monitoring-cluster $MONITORING_CLUSTER_NAME --phase $BOOTSTRAP_PHASE --keyvault-name $KEYVAULT_NAME --aad-webclient-id $AAD_WEBCLIENT_ID --aad-webclient-appkey $AAD_WEBCLIENT_APPKEY --aad-tenant-id $AAD_TENANT_ID --azure-subscription-id $AZURE_SUBSCRIPTION_ID --edxconfiguration-public-github-accountname $EDX_CONFIGURATION_PUBLIC_GITHUB_ACCOUNTNAME --edxconfiguration-public-github-projectname $EDX_CONFIGURATION_PUBLIC_GITHUB_PROJECTNAME --edxconfiguration-public-github-projectbranch $EDX_CONFIGURATION_PUBLIC_GITHUB_PROJECTBRANCH --oxatools-public-github-accountname $OXA_TOOLS_PUBLIC_GITHUB_ACCOUNTNAME --oxatools-public-github-projectname $OXA_TOOLS_PUBLIC_GITHUB_PROJECTNAME --oxatools-public-github-projectbranch $OXA_TOOLS_PUBLIC_GITHUB_PROJECTBRANCH --edxplatform-public-github-accountname $EDX_PLATFORM_PUBLIC_GITHUB_ACCOUNTNAME --edxplatform-public-github-projectname $EDX_PLATFORM_PUBLIC_GITHUB_PROJECTNAME --edxplatform-public-github-projectbranch $EDX_PLATFORM_PUBLIC_GITHUB_PROJECTBRANCH --edxtheme-public-github-accountname $EDX_THEME_PUBLIC_GITHUB_ACCOUNTNAME --edxtheme-public-github-projectname $EDX_THEME_PUBLIC_GITHUB_PROJECTNAME --edxtheme-public-github-projectbranch $EDX_THEME_PUBLIC_GITHUB_PROJECTBRANCH --ansible-public-github-accountname $ANSIBLE_PUBLIC_GITHUB_ACCOUNTNAME --ansible-public-github-projectname $ANSIBLE_PUBLIC_GITHUB_PROJECTNAME --ansible-public-github-projectbranch $ANSIBLE_PUBLIC_GITHUB_PROJECTBRANCH --edxversion $EDX_VERSION --forumversion $FORUM_VERSION --cluster-admin-email $CLUSTER_ADMIN_EMAIL --cluster-name $CLUSTER_NAME 
exit_on_error "OXA stamp customization ($INSTALLER_PATH) failed" 1 "${MAIL_SUBJECT} Failed" $CLUSTER_ADMIN_EMAIL $PRIMARY_LOG $SECONDARY_LOG

# Remove the task if it is already setup
log "Uninstalling run-customization background installer cron job"
crontab -l | grep -v "sudo bash $CRON_INSTALLER_SCRIPT" | crontab -