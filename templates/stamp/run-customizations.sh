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

# Attached Storage Mount
data_disk_mount_point="/datadisks"

# Database Backup Parameters
BACKUP_STORAGEACCOUNT_NAME=""
BACKUP_STORAGEACCOUNT_KEY=""
MONGO_BACKUP_FREQUENCY="0 0 * * *"      # At every 00:00 (midnight)
MYSQL_BACKUP_FREQUENCY="11 */4 * * *"   # At minute 11 past every 4th hour.
MONGO_BACKUP_RETENTIONDAYS="30"
MYSQL_BACKUP_RETENTIONDAYS="30"
BACKUP_LOCAL_PATH="${data_disk_mount_point}/disk1/var/tmp"

# Microsoft Sample course
EDXAPP_IMPORT_KITCHENSINK_COURSE=false;

# Comprehensive Theming
EDXAPP_ENABLE_COMPREHENSIVE_THEMING=false
EDXAPP_COMPREHENSIVE_THEME_DIR=""
EDXAPP_DEFAULT_SITE_THEME=""

# Third Party Authentication (ie: AAD)
EDXAPP_ENABLE_THIRD_PARTY_AUTH=false
EDXAPP_AAD_CLIENT_ID=""
EDXAPP_AAD_SECURITY_KEY=""
EDXAPP_AAD_BUTTON_NAME=""

# traffic manager
DOMAIN_OVERRIDE=""
DOMAIN_SEPARATOR=""

# Memcache server
MEMCACHE_SERVER=""

# Azure Cli Version
AZURE_CLI_VERSION="2"

# Mobile rest api 
EDXAPP_ENABLE_MOBILE_REST_API="false"

# detect request to bootstrap a new jumpbox
BOOTSTRAP_JUMPBOX=0

# servicebus notification parameters
servicebus_namespace=""
servicebus_queue_name=""
servicebus_shared_access_key_name="RootManageSharedAccessKey"
servicebus_shared_access_key=""

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
    echo "        --import-kitchensink-course Indicator of whether not not to import the Microsoft Kitchen Sink sample course."
    echo "        --enable-comprehensive-theming Indicator of whether not not to enable comprehensive themeing. If this value is set to 'true', make sure to set the themeing directory & default theme name accordingly."
    echo "        --comprehensive-theming-directory Root path to the directory containing the comprehensive themes."
    echo "        --comprehensive-theming-name Name of the comprehensive available under the 'comprehensiveThemingDirectory' that will be used."
    echo "        --enable-thirdparty-auth Indicator of whether or not third-party authentication will be enabled (ie: AAD, or other OAuth provider)."
    echo "        --aad-loginbutton-text Text for the authentication button."
    echo "        --base-domain-override base domain for the stamp"
    echo "        --domain-separator domain separator character"
    echo "        --azurecli-version azure cli version to use"
    echo "        --memcache-server the memcache server to use"
    echo "        --enable-mobile-rest-api indicator of whether or not the mobile rest api will be enabled"
    echo "        --bootstrap-jumpbox indicator of whether or not initiate a bootstrap for just the jumpbox"
    echo "        --servicebus-namespace Name of servicebus namespace to use for notification communications"
    echo "        --servicebus-queue-name Name of servicebus queue to use for notification communications"
    echo "        --servicebus-shared-access-key-name Name of the servicebus shared access policy to use for service bus authentication"
    echo "        --servicebus-shared-access-key Key for the servicebus shared access policy to use for service bus authentication"
}

# Parse script parameters
# When adding parameters, make sure to pass the same variables during the cron mode setup
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
        echo "Option '${1}' set with value '"${arg_value}"'"

        case "$1" in
            -c) # Cloud Name
                CLOUDNAME="${arg_value}"
                ;;
            -u| --admin-user) # OS Admin User Name
                OS_ADMIN_USERNAME="${arg_value}"
                ;;
            -i) # Custom script relative path
                CUSTOM_INSTALLER_RELATIVEPATH="${arg_value}"
                ;;
            -m) # Monitoring cluster name
                MONITORING_CLUSTER_NAME="${arg_value}"
                ;;
            -s|--phase) # Bootstrap Phase (0=Servers, 1=OpenEdx App)
                if is_valid_arg "0 1" "${arg_value}"; then
                    BOOTSTRAP_PHASE="${arg_value}"
                else
                    log "Invalid Bootstrap Phase specified - ${arg_value}" $ERROR_MESSAGE
                    help
                    exit 2
                fi
                ;;
            --monitoring-cluster)
                MONITORING_CLUSTER_NAME="${arg_value}"
                ;;
            --crontab-interval)
                CRONTAB_INTERVAL_MINUTES="${arg_value}"
                ;;
            --keyvault-name)
                KEYVAULT_NAME="${arg_value}"
                ;;
            --aad-webclient-id)
                AAD_WEBCLIENT_ID="${arg_value}"
                EDXAPP_AAD_CLIENT_ID="${arg_value}"
                ;;
            --aad-webclient-appkey)
                AAD_WEBCLIENT_APPKEY="${arg_value}"
                EDXAPP_AAD_SECURITY_KEY="${arg_value}"
                ;;
            --aad-tenant-id)
                AAD_TENANT_ID="${arg_value}"
                ;;
            --oxatools-public-github-accountname)
                OXA_TOOLS_PUBLIC_GITHUB_ACCOUNTNAME="${arg_value}"
                ;;
            --oxatools-public-github-projectname)
                OXA_TOOLS_PUBLIC_GITHUB_PROJECTNAME="${arg_value}"
                ;;
            --oxatools-public-github-projectbranch)
                OXA_TOOLS_PUBLIC_GITHUB_PROJECTBRANCH="${arg_value}"
                ;;
            --edxconfiguration-public-github-accountname)
                EDX_CONFIGURATION_PUBLIC_GITHUB_ACCOUNTNAME="${arg_value}"
                ;;
            --edxconfiguration-public-github-projectname)
                EDX_CONFIGURATION_PUBLIC_GITHUB_PROJECTNAME="${arg_value}"
                ;;
            --edxconfiguration-public-github-projectbranch)
                EDX_CONFIGURATION_PUBLIC_GITHUB_PROJECTBRANCH="${arg_value}"
                ;;
            --edxplatform-public-github-accountname)
                EDX_PLATFORM_PUBLIC_GITHUB_ACCOUNTNAME="${arg_value}"
                ;;
            --edxplatform-public-github-projectname)
                EDX_PLATFORM_PUBLIC_GITHUB_PROJECTNAME="${arg_value}"
                ;;
            --edxplatform-public-github-projectbranch)
                EDX_PLATFORM_PUBLIC_GITHUB_PROJECTBRANCH="${arg_value}"
                ;;
            --edxtheme-public-github-accountname)
                EDX_THEME_PUBLIC_GITHUB_ACCOUNTNAME="${arg_value}"
                ;;
            --edxtheme-public-github-projectname)
                EDX_THEME_PUBLIC_GITHUB_PROJECTNAME="${arg_value}"
                ;;
            --edxtheme-public-github-projectbranch)
                EDX_THEME_PUBLIC_GITHUB_PROJECTBRANCH="${arg_value}"
                ;;
            --ansible-public-github-accountname)
                ANSIBLE_PUBLIC_GITHUB_ACCOUNTNAME="${arg_value}"
                ;;
            --ansible-public-github-projectname)
                ANSIBLE_PUBLIC_GITHUB_PROJECTNAME="${arg_value}"
                ;;
            --ansible-public-github-projectbranch)
                ANSIBLE_PUBLIC_GITHUB_PROJECTBRANCH="${arg_value}"
                ;;
            --edxversion)
                EDX_VERSION="${arg_value}"
                ;;
            --forumversion)
                FORUM_VERSION="${arg_value}"
                ;;
            --azure-subscription-id)
                AZURE_SUBSCRIPTION_ID="${arg_value}"
                ;;
            --smtp-server)
                SMTP_SERVER="${arg_value}"
                ;;
            --smtp-server-port)
                SMTP_SERVER_PORT="${arg_value}"
                ;;
            --smtp-auth-user)
                SMTP_AUTH_USER="${arg_value}"
                ;;
            --smtp-auth-user-password)
                SMTP_AUTH_USER_PASSWORD="${arg_value}"
                ;;
            --cluster-admin-email)
                CLUSTER_ADMIN_EMAIL="${arg_value}"
                ;;
            --cluster-name)
                CLUSTER_NAME="${arg_value}"
                MAIL_SUBJECT="${MAIL_SUBJECT} - ${arg_value,,}"
                ;;
            --cron)
                CRON_MODE=1
                ;;
            --storage-account-name)
                BACKUP_STORAGEACCOUNT_NAME="${arg_value}"
                ;;
            --storage-account-key)
                BACKUP_STORAGEACCOUNT_KEY="${arg_value}"
                ;;
            --mongo-backup-frequency)
                MONGO_BACKUP_FREQUENCY="${arg_value//_/ }"
                echo "Option '${1}' reset to '$MONGO_BACKUP_FREQUENCY'"
                ;;
            --mysql-backup-frequency)
                MYSQL_BACKUP_FREQUENCY="${arg_value//_/ }"
                echo "Option '${1}' reset to '$MYSQL_BACKUP_FREQUENCY'"
                ;;
            --mongo-backup-retention-days)
                MONGO_BACKUP_RETENTIONDAYS="${arg_value}"
                ;;
            --mysql-backup-retention-days)
                MYSQL_BACKUP_RETENTIONDAYS="${arg_value}"
                ;;
            --import-kitchensink-course)
                EDXAPP_IMPORT_KITCHENSINK_COURSE="${arg_value}"
                ;;
            --enable-comprehensive-theming)
                EDXAPP_ENABLE_COMPREHENSIVE_THEMING="${arg_value,,}"
                ;;
            --comprehensive-theming-directory)
                EDXAPP_COMPREHENSIVE_THEME_DIR="${arg_value}"
                ;;
            --comprehensive-theming-name)
                EDXAPP_DEFAULT_SITE_THEME="${arg_value}"
                ;;
            --enable-thirdparty-auth)
                EDXAPP_ENABLE_THIRD_PARTY_AUTH="${arg_value,,}"
                ;;
            --aad-loginbutton-text)
                EDXAPP_AAD_BUTTON_NAME="${arg_value//_/ }"
                echo "Option '${1}' reset to '$EDXAPP_AAD_BUTTON_NAME'"
                ;;
            --base-domain-override)
                DOMAIN_OVERRIDE="${arg_value,,}"
                ;;
            --domain-separator)
                DOMAIN_SEPARATOR="${arg_value,,}"
                ;;
            --mongo-adminuser)
                MONGO_USER="${arg_value}"
                ;;
            --mongo-adminuserpassword)
                MONGO_PASSWORD="${arg_value}"
                ;;
            --mongo-replicasetkey)
                MONGO_REPLICASET_KEY="${arg_value}"
                ;;
            --mysql-adminuser)
                MYSQL_ADMIN_USER="${arg_value}"
                ;;
            --mysql-adminuserpassword)
                MYSQL_ADMIN_PASSWORD="${arg_value}"
                ;;
            --mysql-repluser)
                MYSQL_REPL_USER="${arg_value}"
                ;;
            --mysql-repluserpassword)
                MYSQL_REPL_USER_PASSWORD="${arg_value}"
                ;;
            --mysql-backupuser)
                MYSQL_BACKUP_USER="${arg_value}"
                ;;
            --mysql-backupuserpassword)
                MYSQL_BACKUP_USER_PASSWORD="${arg_value}"
                ;;
            --edxapp-superuser)
                EDXAPP_SU_USERNAME="${arg_value}"
                ;;
            --edxapp-superuserpassword)
                EDXAPP_SU_PASSWORD="${arg_value}"
                ;;
            --edxapp-superuseremail)
                EDXAPP_SU_EMAIL="${arg_value}"
                ;;
            --import-kitchensink-course)
                EDXAPP_IMPORT_KITCHENSINK_COURSE="${arg_value}"
                ;;
            --enable-comprehensive-theming)
                EDXAPP_ENABLE_COMPREHENSIVE_THEMING="${arg_value,,}"
                ;;
            --comprehensive-theming-directory)
                EDXAPP_COMPREHENSIVE_THEME_DIR="${arg_value}"
                ;;
            --comprehensive-theming-name)
                EDXAPP_DEFAULT_SITE_THEME="${arg_value}"
                ;;
            --enable-thirdparty-auth)
                EDXAPP_ENABLE_THIRD_PARTY_AUTH="${arg_value,,}"
                ;;
            --aad-loginbutton-text)
                EDXAPP_AAD_BUTTON_NAME="${arg_value//_/ }"
                echo "Option '${1}' reset to '$EDXAPP_AAD_BUTTON_NAME'"
                ;;
            --base-domain-override)
                DOMAIN_OVERRIDE="${arg_value,,}"
                ;;
            --domain-separator)
                DOMAIN_SEPARATOR="${arg_value}"
                ;;
            --platform-name)
                PLATFORM_NAME=`echo ${arg_value} | base64 --decode`
                ;;
            --platform-email)
                PLATFORM_EMAIL="${arg_value}"
                ;;
            --memcache-server)
                MEMCACHE_SERVER=`echo ${arg_value} | base64 --decode`
                ;;
            --azurecli-version)
                AZURE_CLI_VERSION="${arg_value}"
                ;;
            --enable-mobile-rest-api)
                EDXAPP_ENABLE_MOBILE_REST_API="${arg_value,,}"
                if ( ! is_valid_arg "true false" $EDXAPP_ENABLE_MOBILE_REST_API ) ; 
                then
                  echo "Invalid state specified for mobile rest api"
                  help
                  exit 2
                fi
                ;;
            --bootstrap-jumpbox)
                BOOTSTRAP_JUMPBOX="${arg_value}"
                ;;
            --servicebus-namespace)
                servicebus_namespace="${arg_value}"
                ;;
            --servicebus-queue-name)
                servicebus_queue_name="${arg_value}"
                ;;
            --servicebus-shared-access-key-name)
                servicebus_shared_access_key_name="${arg_value}"
                ;;
            --servicebus-shared-access-key)
                servicebus_shared_access_key="${arg_value}"
                ;;
            -h|--help)  # Helpful hints
                help
                exit 2
                ;;
            *) # unknown option
                echo "Option '${BOLD}$1${NORM} ${arg_value}' not allowed."
                help
                exit 2
                ;;
        esac
        
        # note: when adding a new parameter, make sure to plumb it for the cron session as well:
        # See [ "$CRON_MODE" == "0" ]; section below

        shift # past argument

        if [ $shift_once -eq 0 ]; 
        then
            shift # past argument or value
        fi

    done
}

#############################################################################
# Persist Deployment-Time Values
# This allows parameters passed at deployment-time to override existing 
# values
#############################################################################

persist_deployment_time_values()
{
    config_file="${OXA_ENV_PATH}/${DEPLOYMENT_ENV}.sh"

    log "Overriding cloud configurations with deploy-time parameters"

    # Overrides with placeholders
    sed -i "s#{AZURE_ACCOUNT_NAME}#${BACKUP_STORAGEACCOUNT_NAME}#I" $config_file
    sed -i "s#{AZURE_ACCOUNT_KEY}#${BACKUP_STORAGEACCOUNT_KEY}#I" $config_file
    sed -i "s#{CLUSTERNAME}#${CLUSTER_NAME}#I" $config_file
    sed -i "s#{MONGO_REPLICASET_NAME}#${CLUSTER_NAME}rs#I" $config_file
    sed -i "s#{EDXAPP_ENABLE_THIRD_PARTY_AUTH}#${EDXAPP_ENABLE_THIRD_PARTY_AUTH}#I" $config_file
    sed -i "s#{EDXAPP_AAD_CLIENT_ID}#${EDXAPP_AAD_CLIENT_ID}#I" $config_file
    sed -i "s#{EDXAPP_AAD_SECURITY_KEY}#${EDXAPP_AAD_SECURITY_KEY}#I" $config_file
    sed -i "s#{EDXAPP_AAD_BUTTON_NAME}#${EDXAPP_AAD_BUTTON_NAME}#I" $config_file
    sed -i "s#{EDXAPP_ENABLE_COMPREHENSIVE_THEMING}#${EDXAPP_ENABLE_COMPREHENSIVE_THEMING}#I" $config_file
    sed -i "s#{EDXAPP_COMPREHENSIVE_THEME_DIRECTORY}#${EDXAPP_COMPREHENSIVE_THEME_DIR}#I" $config_file
    sed -i "s#{EDXAPP_DEFAULT_SITE_THEME}#${EDXAPP_DEFAULT_SITE_THEME}#I" $config_file
    sed -i "s#{EDXAPP_IMPORT_KITCHENSINK_COURSE}#${EDXAPP_IMPORT_KITCHENSINK_COURSE}#I" $config_file

    # Overrides without placeholders
    
    # Application settings
    sed -i "s#^ADMIN_USER=.*#ADMIN_USER=${OS_ADMIN_USERNAME}#I" $config_file
    sed -i "s#^PLATFORM_NAME=.*#PLATFORM_NAME=\"${PLATFORM_NAME}\"#I" $config_file
    sed -i "s#^PLATFORM_EMAIL=.*#PLATFORM_EMAIL=${PLATFORM_EMAIL}#I" $config_file
    
    sed -i "s#^EDXAPP_EMAIL_HOST=.*#EDXAPP_EMAIL_HOST=${SMTP_SERVER}#I" $config_file
    sed -i "s#^EDXAPP_EMAIL_HOST_USER=.*#EDXAPP_EMAIL_HOST_USER=${SMTP_AUTH_USER}#I" $config_file
    sed -i "s#^EDXAPP_EMAIL_HOST_PASSWORD=.*#EDXAPP_EMAIL_HOST_PASSWORD=${SMTP_AUTH_USER_PASSWORD}#I" $config_file
    sed -i "s#^EDXAPP_EMAIL_PORT=.*#EDXAPP_EMAIL_PORT=${SMTP_SERVER_PORT}#I" $config_file

    sed -i "s#^EDXAPP_SU_PASSWORD=.*#EDXAPP_SU_PASSWORD=${EDXAPP_SU_PASSWORD}#I" $config_file
    sed -i "s#^EDXAPP_SU_EMAIL=.*#EDXAPP_SU_EMAIL=${EDXAPP_SU_EMAIL}#I" $config_file
    sed -i "s#^EDXAPP_SU_USERNAME=.*#EDXAPP_SU_USERNAME=${EDXAPP_SU_USERNAME}#I" $config_file

    # Mongo Credentials
    sed -i "s#^MONGO_USER=.*#MONGO_USER=${MONGO_USER}#I" $config_file
    sed -i "s#^MONGO_PASSWORD=.*#MONGO_PASSWORD=${MONGO_PASSWORD}#I" $config_file
    sed -i "s#^MONGO_REPLICASET_KEY=.*#MONGO_REPLICASET_KEY=${MONGO_REPLICASET_KEY}#I" $config_file
    
    # Mysql Credentials
    sed -i "s#^MYSQL_ADMIN_USER=.*#MYSQL_ADMIN_USER=${MYSQL_ADMIN_USER}#I" $config_file
    sed -i "s#^MYSQL_ADMIN_PASSWORD=.*#MYSQL_ADMIN_PASSWORD=${MYSQL_ADMIN_PASSWORD}#I" $config_file

    sed -i "s#^MYSQL_TEMP_USER=.*#MYSQL_TEMP_USER=${MYSQL_BACKUP_USER}#I" $config_file
    sed -i "s#^MYSQL_TEMP_PASSWORD=.*#MYSQL_TEMP_PASSWORD=${MYSQL_BACKUP_USER_PASSWORD}#I" $config_file

    sed -i "s#^MYSQL_USER=.*#MYSQL_USER=${MYSQL_REPL_USER}#I" $config_file
    sed -i "s#^MYSQL_PASSWORD=.*#MYSQL_PASSWORD=${MYSQL_REPL_USER_PASSWORD}#I" $config_file
    sed -i "s#^MYSQL_REPL_USER=.*#MYSQL_REPL_USER=${MYSQL_REPL_USER}#I" $config_file
    sed -i "s#^MYSQL_REPL_USER_PASSWORD=.*#MYSQL_REPL_USER_PASSWORD=${MYSQL_REPL_USER_PASSWORD}#I" $config_file

    if [ ! -z ${DOMAIN_OVERRIDE} ]; 
    then
        log "Overriding the base url"
        sed -i "s#^BASE_URL=.*#BASE_URL=${DOMAIN_OVERRIDE}#I" $config_file
        sed -i "s#^LMS_URL=.*#LMS_URL=lms${DOMAIN_SEPARATOR}${DOMAIN_OVERRIDE}#I" $config_file
        sed -i "s#^CMS_URL=.*#CMS_URL=cms${DOMAIN_SEPARATOR}${DOMAIN_OVERRIDE}#I" $config_file
        sed -i "s#^PREVIEW_URL=.*#PREVIEW_URL=preview${DOMAIN_SEPARATOR}${DOMAIN_OVERRIDE}#I" $config_file
    else
        log "Domain override not specified"
    fi

    # check for MemCache Server Override
    if [[ ! -z ${MEMCACHE_SERVER} ]];
    then
        log "Overriding 'MEMCACHE_SERVER_IP'"
        sed -i "s#^MEMCACHE_SERVER_IP=.*#MEMCACHE_SERVER_IP=${MEMCACHE_SERVER}#I" $config_file
    else
        log "Memcache Server override not specified"
    fi

    # check for Mobile Rest Api override
    if [[ ! -z ${EDXAPP_ENABLE_MOBILE_REST_API} ]];
    then
        # if EDXAPP_ENABLE_MOBILE_REST_API & EDXAPP_ENABLE_OAUTH2_PROVIDER must have the same value (dependency)
        log "Overriding 'EDXAPP_ENABLE_MOBILE_REST_API'"
        sed -i "s#^EDXAPP_ENABLE_MOBILE_REST_API=.*#EDXAPP_ENABLE_MOBILE_REST_API=${EDXAPP_ENABLE_MOBILE_REST_API}#I" $config_file
        sed -i "s#^EDXAPP_ENABLE_OAUTH2_PROVIDER=.*#EDXAPP_ENABLE_OAUTH2_PROVIDER=${EDXAPP_ENABLE_MOBILE_REST_API}#I" $config_file
        sed -i "s#^OAUTH_ENFORCE_SECURE=.*#OAUTH_ENFORCE_SECURE=${EDXAPP_ENABLE_MOBILE_REST_API}#I" $config_file
    else
        log "Mobile Rest API override not specified"
    fi

    # Re-source the cloud configurations
    source $config_file
    exit_on_error "Failed sourcing the environment configuration file after transform" 1 "${MAIL_SUBJECT} Failed" $CLUSTER_ADMIN_EMAIL $PRIMARY_LOG $SECONDARY_LOG
}

###############################################
# Start Execution
###############################################

# Source our utilities for logging and other base functions (we need this staged with the installer script).
# The file needs to be first downloaded from the public repository and this download happens as part of the custom script extension
CURRENT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
UTILITIES_PATH=$CURRENT_PATH/utilities.sh

# Check if the utilities file exists. If not, bail out.
if [[ ! -e $UTILITIES_PATH ]]; 
then  
    echo :"Utilities not present"
    exit 3
fi

# Source the utilities now
source $UTILITIES_PATH

# Script self-idenfitication
print_script_header

parse_args $@ # pass existing command line arguments

# Validate parameters
if [ -z "$OXA_TOOLS_PUBLIC_GITHUB_ACCOUNTNAME" ] || [ -z "$OXA_TOOLS_PUBLIC_GITHUB_PROJECTNAME" ] || [ -z "$OXA_TOOLS_PUBLIC_GITHUB_PROJECTBRANCH" ] || [ -z "$CLOUDNAME" ] ;
then
    log "Incomplete OXA Tools Github repository configuration: Github Account Name,  Project Name & Branch Name are required." $ERROR_MESSAGE
    exit 3
fi

if [ "$EDX_CONFIGURATION_PUBLIC_GITHUB_ACCOUNTNAME" == "" ] || [ "$EDX_CONFIGURATION_PUBLIC_GITHUB_PROJECTNAME" == "" ] || [ "$EDX_CONFIGURATION_PUBLIC_GITHUB_PROJECTBRANCH" == "" ] ;
then
    log "Incomplete EDX Configuration Github repository configuration: Github Account Name,  Project Name & Branch Name are required." $ERROR_MESSAGE
    exit 3
fi

# To support resiliency, we need to enable retries. Towards that end, this script will support 2 modes: Cron (background execution) or Non-Cron (Custom Script Extension-CSX/direct execution)
CRON_INSTALLER_SCRIPT="$CURRENT_PATH/background-run-customization.sh"

if [ "$CRON_MODE" == "0" ];
then
    log "Setting up cron job for executing customization from '${HOSTNAME}' for the OXA Stamp"

    # todo: switch to bulk referencing all parameters and passing along
    # todo: add encoding/decoding for other parameters that support blank spaces in their value
    # decode the input now that we need to use the variable
    PLATFORM_NAME=`echo ${PLATFORM_NAME} | base64`
    MEMCACHE_SERVER=`echo ${MEMCACHE_SERVER} | base64`

    # Setup the repo parameters individually
    OXA_TOOLS_GITHUB_PARAMS="--oxatools-public-github-accountname \"${OXA_TOOLS_PUBLIC_GITHUB_ACCOUNTNAME}\" --oxatools-public-github-projectname \"${OXA_TOOLS_PUBLIC_GITHUB_PROJECTNAME}\" --oxatools-public-github-projectbranch \"${OXA_TOOLS_PUBLIC_GITHUB_PROJECTBRANCH}\""
    EDX_CONFIGURATION_GITHUB_PARAMS="--edxconfiguration-public-github-accountname \"${EDX_CONFIGURATION_PUBLIC_GITHUB_ACCOUNTNAME}\" --edxconfiguration-public-github-projectname \"${EDX_CONFIGURATION_PUBLIC_GITHUB_PROJECTNAME}\" --edxconfiguration-public-github-projectbranch \"${EDX_CONFIGURATION_PUBLIC_GITHUB_PROJECTBRANCH}\""
    EDX_PLATFORM_GITHUB_PARAMS="--edxplatform-public-github-accountname \"${EDX_PLATFORM_PUBLIC_GITHUB_ACCOUNTNAME}\" --edxplatform-public-github-projectname \"${EDX_PLATFORM_PUBLIC_GITHUB_PROJECTNAME}\" --edxplatform-public-github-projectbranch \"${EDX_PLATFORM_PUBLIC_GITHUB_PROJECTBRANCH}\""
    EDX_THEME_GITHUB_PARAMS="--edxtheme-public-github-accountname \"${EDX_THEME_PUBLIC_GITHUB_ACCOUNTNAME}\" --edxtheme-public-github-projectname \"${EDX_THEME_PUBLIC_GITHUB_PROJECTNAME}\" --edxtheme-public-github-projectbranch \"${EDX_THEME_PUBLIC_GITHUB_PROJECTBRANCH}\""
    ANSIBLE_GITHUB_PARAMS="--ansible-public-github-accountname \"${ANSIBLE_PUBLIC_GITHUB_ACCOUNTNAME}\" --ansible-public-github-projectname \"${ANSIBLE_PUBLIC_GITHUB_PROJECTNAME}\" --ansible-public-github-projectbranch \"${ANSIBLE_PUBLIC_GITHUB_PROJECTBRANCH}\""
    SAMPLE_COURSE_PARAMS="--import-kitchensink-course \"${EDXAPP_IMPORT_KITCHENSINK_COURSE}\""
    COMPREHENSIVE_THEMING_PARAMS="--enable-comprehensive-theming \"${EDXAPP_ENABLE_COMPREHENSIVE_THEMING}\" --comprehensive-theming-directory \"${EDXAPP_COMPREHENSIVE_THEME_DIR}\" --comprehensive-theming-name \"${EDXAPP_DEFAULT_SITE_THEME}\""
    AUTHENTICATION_PARAMS="--enable-thirdparty-auth \"${EDXAPP_ENABLE_THIRD_PARTY_AUTH}\" --aad-loginbutton-text \"${EDXAPP_AAD_BUTTON_NAME// /_}\""
    DOMAIN_PARAMS="--base-domain-override \"${DOMAIN_OVERRIDE}\" --domain-separator \"${DOMAIN_SEPARATOR}\""
    EDXAPP_PARAMS="--edxapp-superuser \"${EDXAPP_SU_USERNAME}\" --edxapp-superuserpassword \"${EDXAPP_SU_PASSWORD}\" --edxapp-superuseremail \"${EDXAPP_SU_EMAIL}\""
    DATABASE_PARAMS="--platform-email \"${PLATFORM_EMAIL}\" --platform-name \"${PLATFORM_NAME}\" --mysql-backupuser \"${MYSQL_BACKUP_USER}\" --mysql-backupuserpassword \"${MYSQL_BACKUP_USER_PASSWORD}\" --mysql-repluser \"${MYSQL_REPL_USER}\" --mysql-repluserpassword \"${MYSQL_REPL_USER_PASSWORD}\" --mysql-adminuser \"${MYSQL_ADMIN_USER}\" --mysql-adminuserpassword \"${MYSQL_ADMIN_PASSWORD}\" --mongo-adminuser \"${MONGO_USER}\" --mongo-adminuserpassword \"${MONGO_PASSWORD}\" --mongo-replicasetkey \"${MONGO_REPLICASET_KEY}\""
    MEMCACHE_PARAMS="--memcache-server \"${MEMCACHE_SERVER}\""
    AZURE_CLI_VERSION="--azurecli-version \"${AZURE_CLI_VERSION}\""

    # Mobile rest api parameter
    MOBILE_REST_API_PARAMS="--enable-mobile-rest-api \"${EDXAPP_ENABLE_MOBILE_REST_API}\""

    # Jumpbox Bootstrap-Only mode indicator
    JUMPBOX_BOOTSTRAP_PARAMS="--bootstrap-jumpbox \"${JUMPBOX_BOOTSTRAP}\""

    # Strip out the spaces for passing it along
    MONGO_BACKUP_FREQUENCY="${MONGO_BACKUP_FREQUENCY// /_}"
    MYSQL_BACKUP_FREQUENCY="${MYSQL_BACKUP_FREQUENCY// /_}"

    BACKUP_PARAMS="--storage-account-name \"${BACKUP_STORAGEACCOUNT_NAME}\" --storage-account-key \"${BACKUP_STORAGEACCOUNT_KEY}\" --mongo-backup-frequency \"${MONGO_BACKUP_FREQUENCY}\" --mysql-backup-frequency \"${MYSQL_BACKUP_FREQUENCY}\" --mongo-backup-retention-days \"${MONGO_BACKUP_RETENTIONDAYS}\" --mysql-backup-retention-days \"${MYSQL_BACKUP_RETENTIONDAYS}\""

    # servicebus notification parameters
    SERVICEBUS_PARAMS="--servicebus-namespace '${servicebus_namespace}' --servicebus-queue-name '${servicebus_queue_name}' --servicebus-shared-access-key-name '${servicebus_shared_access_key_name}' --servicebus-shared-access-key '${servicebus_shared_access_key}'"
    
    # Create the cron job & exit
    INSTALL_COMMAND="sudo flock -n /var/log/bootstrap-run-customization.lock bash $CURRENT_PATH/run-customizations.sh -c $CLOUDNAME -u $OS_ADMIN_USERNAME -i $CUSTOM_INSTALLER_RELATIVEPATH -m $MONITORING_CLUSTER_NAME -s $BOOTSTRAP_PHASE -u $OS_ADMIN_USERNAME --monitoring-cluster $MONITORING_CLUSTER_NAME --crontab-interval $CRONTAB_INTERVAL_MINUTES --keyvault-name $KEYVAULT_NAME --aad-webclient-id $AAD_WEBCLIENT_ID --aad-webclient-appkey $AAD_WEBCLIENT_APPKEY --aad-tenant-id $AAD_TENANT_ID --azure-subscription-id $AZURE_SUBSCRIPTION_ID --smtp-server $SMTP_SERVER --smtp-server-port $SMTP_SERVER_PORT --smtp-auth-user $SMTP_AUTH_USER --smtp-auth-user-password $SMTP_AUTH_USER_PASSWORD --cluster-admin-email $CLUSTER_ADMIN_EMAIL --cluster-name $CLUSTER_NAME ${OXA_TOOLS_GITHUB_PARAMS} ${EDX_CONFIGURATION_GITHUB_PARAMS} ${EDX_PLATFORM_GITHUB_PARAMS} ${EDX_THEME_GITHUB_PARAMS} ${ANSIBLE_GITHUB_PARAMS} ${BACKUP_PARAMS} ${SAMPLE_COURSE_PARAMS} ${COMPREHENSIVE_THEMING_PARAMS} ${AUTHENTICATION_PARAMS} ${DOMAIN_PARAMS} ${EDXAPP_PARAMS} --edxversion ${EDX_VERSION} --forumversion ${FORUM_VERSION} ${DATABASE_PARAMS} ${MEMCACHE_PARAMS} ${AZURE_CLI_VERSION} ${MOBILE_REST_API_PARAMS} ${JUMPBOX_BOOTSTRAP_PARAMS} ${SERVICEBUS_PARAMS} --cron >> $SECONDARY_LOG 2>&1"
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

# Pre-Requisite: Setup Attached Storage (Jumpbox only for now)
if [[ "$MACHINE_ROLE" == "jumpbox" ]];
then
    # configure any attached storage
    configure_datadisks "${data_disk_mount_point}"
fi

# Pre-Requisite: Setup Mailer (this is necessary for notification)
install-mailer $SMTP_SERVER $SMTP_SERVER_PORT $SMTP_AUTH_USER $SMTP_AUTH_USER_PASSWORD $CLUSTER_ADMIN_EMAIL $OS_ADMIN_USERNAME
exit_on_error "Configuring the mailer failed"

# 1. Setup Tools
install-tools

if [[ "$MACHINE_ROLE" == "jumpbox" ]] || [[ "$MACHINE_ROLE" == "vmss" ]] ; then
    make_theme_dir "$EDXAPP_COMPREHENSIVE_THEME_DIR" "$EDX_PLATFORM_PUBLIC_GITHUB_PROJECTNAME"
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

# download configs from keyvault
powershell -file $INSTALLER_BASEPATH/Process-OxaToolsKeyVaultConfiguration.ps1 -Operation Download -VaultName $KEYVAULT_NAME -AadWebClientId $AAD_WEBCLIENT_ID -AadWebClientAppKey $AAD_WEBCLIENT_APPKEY -AadTenantId $AAD_TENANT_ID -TargetPath $OXA_ENV_PATH -AzureSubscriptionId $AZURE_SUBSCRIPTION_ID -AzureCliVersion $AZURE_CLI_VERSION
exit_on_error "Failed downloading configurations from keyvault" 1 "${MAIL_SUBJECT} Failed" $CLUSTER_ADMIN_EMAIL $PRIMARY_LOG $SECONDARY_LOG

# TODO: downgrade this to position keyvault as the authorititive source 
# that should remove dependency on deployment-time overrides
# apply deployment-time parameter overrides. After these updates, the appropriate 
# override values will be present in AZURE_ACCOUNT_KEY, AZURE_ACCOUNT_NAME
persist_deployment_time_values

# Generate a storage connection string (primarily to support custom storage endpoints)
# At this point, we have sourced the cloud configuration file.
# We expect the storage account suffix (AZURE_STORAGE_ENDPOINT_SUFFIX) to either:
# 1. have a value (custom storage endpoint)
# 2. not have a value (default to global azure)
encoded_azure_storage_endpoint_suffix=`echo ${AZURE_STORAGE_ENDPOINT_SUFFIX} | base64`
storageAccountEndpointSuffix=`get_azure_storage_endpoint_suffix ${encoded_azure_storage_endpoint_suffix}`
storage_connection_string=`generate_azure_storage_connection_string "${AZURE_ACCOUNT_NAME}" "${AZURE_ACCOUNT_KEY}" "${storageAccountEndpointSuffix}"`

# create storage container for edxapp:migrate & other reporting features (containers for the database backup will be created dynamically)
powershell -file $INSTALLER_BASEPATH/Create-StorageContainer.ps1 -AadWebClientId $AAD_WEBCLIENT_ID -AadWebClientAppKey $AAD_WEBCLIENT_APPKEY -AadTenantId $AAD_TENANT_ID -AzureSubscriptionId $AZURE_SUBSCRIPTION_ID -StorageAccountName "${AZURE_ACCOUNT_NAME}" -StorageAccountKey "${AZURE_ACCOUNT_KEY}" -StorageContainerNames "uploads,reports,tracking" -AzureCliVersion $AZURE_CLI_VERSION -AzureStorageConnectionString "${storage_connection_string}"
exit_on_error "Failed creating container(s) for edxapp:migrate (uploads,reports,tracking) in '${AZURE_ACCOUNT_NAME}'" 1 "${MAIL_SUBJECT} Failed" $CLUSTER_ADMIN_EMAIL $PRIMARY_LOG $SECONDARY_LOG

# Create a link to the utilities.sh library to be used by the other installer scripts
ln -s $UTILITIES_PATH "${INSTALLER_BASEPATH}/utilities.sh"

#####################################
# Setup Backups
#####################################

if [[ "$MACHINE_ROLE" == "jumpbox" ]];
then
    # configure backup
    log "Starting backup configuration on '${HOSTNAME}' as a member in the '${MACHINE_ROLE}' role"

    # These are fixed values
    MONGO_REPLICASET_CONNECTIONSTRING="${MONGO_REPLICASET_NAME}/${MONGO_SERVER_LIST}"
    DATABASE_BACKUP_SCRIPT="${INSTALLER_BASEPATH}/db_backup.sh"

    if [[ -z $MYSQL_MASTER_PORT ]]; 
    then
        # defensive
        # if for some reason this value isn't specified, default it to a known mysql port
        MYSQL_MASTER_PORT=3306
    fi

    # Setup mysql backup
    DATABASE_TYPE_TO_BACKUP="mysql"
    DATABASE_BACKUP_LOG="/var/log/db_backup_${DATABASE_TYPE_TO_BACKUP}.log"
    setup_backup "${INSTALLER_BASEPATH}/backup_configuration_${DATABASE_TYPE_TO_BACKUP}.sh" "${DATABASE_BACKUP_SCRIPT}" "${DATABASE_BACKUP_LOG}" \
                "${BACKUP_STORAGEACCOUNT_NAME}" "${BACKUP_STORAGEACCOUNT_KEY}" "${MYSQL_BACKUP_FREQUENCY}" "${MYSQL_BACKUP_RETENTIONDAYS}" \
                "${MONGO_REPLICASET_CONNECTIONSTRING}" "${MYSQL_MASTER_IP}" "${DATABASE_TYPE_TO_BACKUP}" "${MYSQL_ADMIN_USER}" "${MYSQL_ADMIN_PASSWORD}" \
                "${BACKUP_LOCAL_PATH}" "${MYSQL_MASTER_PORT}" "${CLUSTER_ADMIN_EMAIL}" "${AZURE_CLI_VERSION}" "${encoded_azure_storage_endpoint_suffix}" \
                "${MYSQL_TEMP_USER}" "${MYSQL_TEMP_PASSWORD}"
    
    exit_on_error "Failed setting up the Mysql Database backup" 1 "${MAIL_SUBJECT} Failed" $CLUSTER_ADMIN_EMAIL $PRIMARY_LOG $SECONDARY_LOG

    # Setup mongo backup
    DATABASE_TYPE_TO_BACKUP="mongo"
    DATABASE_BACKUP_LOG="/var/log/db_backup_${DATABASE_TYPE_TO_BACKUP}.log"
    setup_backup "${INSTALLER_BASEPATH}/backup_configuration_${DATABASE_TYPE_TO_BACKUP}.sh" "${DATABASE_BACKUP_SCRIPT}" "${DATABASE_BACKUP_LOG}" \
                "${BACKUP_STORAGEACCOUNT_NAME}" "${BACKUP_STORAGEACCOUNT_KEY}" "${MONGO_BACKUP_FREQUENCY}" "${MONGO_BACKUP_RETENTIONDAYS}" \
                "${MONGO_REPLICASET_CONNECTIONSTRING}" "${MYSQL_MASTER_IP}" "${DATABASE_TYPE_TO_BACKUP}" "${MONGO_USER}" "${MONGO_PASSWORD}" \
                "${BACKUP_LOCAL_PATH}" "${MYSQL_MASTER_PORT}" "${CLUSTER_ADMIN_EMAIL}" "${AZURE_CLI_VERSION}" "${encoded_azure_storage_endpoint_suffix}" \
                "${MONGO_USER}" "${MONGO_PASSWORD}"

    exit_on_error "Failed setting up the Mongo Database backup" 1 "${MAIL_SUBJECT} Failed" $CLUSTER_ADMIN_EMAIL $PRIMARY_LOG $SECONDARY_LOG
fi

#####################################
# Launch Installer
#####################################

# execute the installer if present
if [[ $BOOTSTRAP_JUMPBOX == 1 ]];
then
    # we are bootstrapping a new jumpbox. The only relevant action left is to setup ssh
    log "Setting up SSH"
    setup-ssh "${REPO_ROOT}/oxa-tools-config" $CLOUDNAME $OS_ADMIN_USERNAME
    exit_on_error "Failed setting up SSH on ${HOSTNAME}" 1 "${MAIL_SUBJECT} Failed" $CLUSTER_ADMIN_EMAIL $PRIMARY_LOG $SECONDARY_LOG
else
    log "Launching the installer at '$INSTALLER_PATH'"
    bash $INSTALLER_PATH  \
        --repo-root "${REPO_ROOT}"  \
        --config-path "${REPO_ROOT}/oxa-tools-config" \
        --cloud "${CLOUDNAME}" \
        --admin-user "${OS_ADMIN_USERNAME}" \
        --monitoring-cluster "${MONITORING_CLUSTER_NAME}" \
        --phase "${BOOTSTRAP_PHASE}" \
        --keyvault-name "${KEYVAULT_NAME}" \
        --aad-webclient-id "${AAD_WEBCLIENT_ID}" \
        --aad-webclient-appkey "${AAD_WEBCLIENT_APPKEY}" \
        --aad-tenant-id "${AAD_TENANT_ID}" \
        --azure-subscription-id "${AZURE_SUBSCRIPTION_ID}" \
        --edxconfiguration-public-github-accountname "${EDX_CONFIGURATION_PUBLIC_GITHUB_ACCOUNTNAME}" \
        --edxconfiguration-public-github-projectname "${EDX_CONFIGURATION_PUBLIC_GITHUB_PROJECTNAME}" \
        --edxconfiguration-public-github-projectbranch "${EDX_CONFIGURATION_PUBLIC_GITHUB_PROJECTBRANCH}" \
        --oxatools-public-github-accountname "${OXA_TOOLS_PUBLIC_GITHUB_ACCOUNTNAME}" \
        --oxatools-public-github-projectname "${OXA_TOOLS_PUBLIC_GITHUB_PROJECTNAME}" \
        --oxatools-public-github-projectbranch "${OXA_TOOLS_PUBLIC_GITHUB_PROJECTBRANCH}" \ \
        --edxplatform-public-github-accountname "${EDX_PLATFORM_PUBLIC_GITHUB_ACCOUNTNAME}" \
        --edxplatform-public-github-projectname "${EDX_PLATFORM_PUBLIC_GITHUB_PROJECTNAME}" \
        --edxplatform-public-github-projectbranch "${EDX_PLATFORM_PUBLIC_GITHUB_PROJECTBRANCH}" \
        --edxtheme-public-github-accountname "${EDX_THEME_PUBLIC_GITHUB_ACCOUNTNAME}" \
        --edxtheme-public-github-projectname "${EDX_THEME_PUBLIC_GITHUB_PROJECTNAME}" \
        --edxtheme-public-github-projectbranch "${EDX_THEME_PUBLIC_GITHUB_PROJECTBRANCH}" \
        --ansible-public-github-accountname "${ANSIBLE_PUBLIC_GITHUB_ACCOUNTNAME}" \
        --ansible-public-github-projectname "${ANSIBLE_PUBLIC_GITHUB_PROJECTNAME}" \
        --ansible-public-github-projectbranch "${ANSIBLE_PUBLIC_GITHUB_PROJECTBRANCH}" \
        --edxversion "${EDX_VERSION}" \
        --forumversion "${FORUM_VERSION}" \
        --cluster-admin-email "${CLUSTER_ADMIN_EMAIL}" \
        --cluster-name "${CLUSTER_NAME}" \
        --servicebus-namespace "${servicebus_namespace}" \
        --servicebus-queue-name "${servicebus_queue_name}" \
        --servicebus-shared-access-key-name "${servicebus_shared_access_key_name}" \
        --servicebus-shared-access-key "${servicebus_shared_access_key}"

    exit_on_error "OXA stamp customization (${INSTALLER_PATH}) failed" 1 "${MAIL_SUBJECT} Failed" $CLUSTER_ADMIN_EMAIL $PRIMARY_LOG $SECONDARY_LOG
fi

# Remove the task if it is already setup
log "Uninstalling run-customization background installer cron job"
crontab -l | grep -v "sudo bash $CRON_INSTALLER_SCRIPT" | crontab -
