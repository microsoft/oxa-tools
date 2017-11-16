#!/bin/bash
#
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

# This is our private bootstrap script for OXA Stamp
# This script will be run from the Jumpbox and will handle the following tasks
# 1. Setup SSH
# 2. Run Bootstrap for Mongo & MySql

ERROR_MESSAGE=1
GITHUB_PROJECTBRANCH="master"
CLOUD_NAME=""
MONITORING_CLUSTER_NAME=""
OS_ADMIN_USERNAME=""
REPO_ROOT="/oxa" 
CONFIG_PATH=""
BOOTSTRAP_PHASE=0
AZURE_SUBSCRIPTION_ID=""

# Git Hub Configurations
OXA_TOOLS_PUBLIC_GITHUB_ACCOUNTNAME=""
OXA_TOOLS_PUBLIC_GITHUB_PROJECTNAME=""
OXA_TOOLS_PUBLIC_GITHUB_PROJECTBRANCH=""
EDX_CONFIGURATION_PUBLIC_GITHUB_ACCOUNTNAME=""
EDX_CONFIGURATION_PUBLIC_GITHUB_PROJECTNAME=""
EDX_CONFIGURATION_PUBLIC_GITHUB_PROJECTBRANCH=""

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

#TODO: complete plumbing this variable as a user input
CRONTAB_INTERVAL_MINUTES=5

# ERROR CODES: 
# TODO: move to common script
ERROR_CRONTAB_FAILED=4101
ERROR_PHASE0_FAILED=6001

# SMTP / Mailer parameters
CLUSTER_ADMIN_EMAIL=""
MAIL_SUBJECT="OXA Bootstrap"
NOTIFICATION_MESSAGE=""
SECONDARY_LOG="/var/log/bootstrap.csx.log"
PRIMARY_LOG="/var/log/bootstrap.log"

# servicebus notification parameters
servicebus_namespace=""
servicebus_queue_name=""
servicebus_shared_access_key_name="RootManageSharedAccessKey"
servicebus_shared_access_key=""

help()
{
    echo "This script sets up SSH, installs MDSD and runs the DB bootstrap"
    echo "Options:"
    echo "        --repo-root                Root path for the oxa tools & configuration"
    echo "        --config-path              oxa configuration path"
    echo "        --cloud                    Cloud Name"
    echo "        --admin-user               OS Admin User Name"
    echo "        --monitoring-cluster       Monitoring Cluster Name"
    echo "        --phase                    Bootstrap Phase (0=Servers, 1=OpenEdx App)"
    echo "        --crontab-interval         Crontab Interval minutes"
    echo "        --keyvault-name            Name of the key vault"
    echo "        --aad-webclient-id         Id of AAD web client (service principal)"
    echo "        --aad-webclient-appkey     Application key for the AAD web client"
    echo "        --aad-tenant-id            AAD Tenant Id"
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
    echo "        --azure-subscription-id    Azure subscription id"
    echo "        --cluster-admin-email Email address of the administrator where system and other notifications will be sent"
    echo "        --cluster-name Name of the cluster being bootstrapped"
    echo "        --servicebus-namespace Name of servicebus namespace to use for notification communications"
    echo "        --servicebus-queue-name Name of servicebus queue to use for notification communications"
    echo "        --servicebus-shared-access-key-name Name of the servicebus shared access policy to use for service bus authentication"
    echo "        --servicebus-shared-access-key Key for the servicebus shared access policy to use for service bus authentication"
}

# Parse script parameters
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
            --repo-root)
                REPO_ROOT="${arg_value}"
                ;;
            --config-path)
                CONFIG_PATH="${arg_value}"
                ;;
            --cloud)
                CLOUD_NAME="${arg_value}"
                ;;
            -u|--admin-user)
                OS_ADMIN_USERNAME="${arg_value}"
                ;;
            --monitoring-cluster)
                MONITORING_CLUSTER_NAME="${arg_value}"
                ;;
            --phase)
                if is_valid_arg "0 1" "${arg_value}"; then
                    BOOTSTRAP_PHASE="${arg_value}"
                else
                    log "Invalid Bootstrap Phase specified - ${arg_value}" $ERROR_MESSAGE
                    help
                    exit 2
                fi
                ;;
            --crontab-interval)
                CRONTAB_INTERVAL_MINUTES="${arg_value}"
                ;;
            --keyvault-name)
                KEYVAULT_NAME="${arg_value}"
                ;;
            --aad-webclient-id)
                AAD_WEBCLIENT_ID="${arg_value}"
                ;;
            --aad-webclient-appkey)
                AAD_WEBCLIENT_APPKEY="${arg_value}"
                ;;
            --aad-tenant-id)
                AAD_TENANT_ID="${arg_value}"
                ;;
            --azure-subscription-id)
                AZURE_SUBSCRIPTION_ID="${arg_value}"
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
            --cluster-admin-email)
                CLUSTER_ADMIN_EMAIL="${arg_value}"
                ;;
            --cluster-name)
                CLUSTER_NAME="${arg_value}"
                MAIL_SUBJECT="${MAIL_SUBJECT} - ${arg_value,,}"
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

        shift # past argument or value

        if [ $shift_once -eq 0 ]; 
        then
            shift # past argument or value
        fi
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

# parse script arguments
parse_args $@ 

# Script self-idenfitication
print_script_header

# validate key arguments
if [ "$GITHUB_PROJECTBRANCH" == "" ] || [ "$CLOUD_NAME" == "" ] ;
then
    log "Incomplete Github configuration: Github Account Name,  Project Name & Branch Name are required." $ERROR_MESSAGE
    exit 3
fi

###############################################
# START CORE EXECUTION
###############################################

log "Begin bootstrapping of the OXA Stamp from '${HOSTNAME}'"

MACHINE_ROLE=$(get_machine_role)
log "${HOSTNAME} has been identified as a member of the '${MACHINE_ROLE}' role"

# 1. Setup SSH (this presumes the requisite files have already been staged) -[Jumpbox Only for Phase 0]
if [ "$MACHINE_ROLE" == "jumpbox" ] && [ "$BOOTSTRAP_PHASE" == "0" ] ;
then
    setup-ssh $CONFIG_PATH $CLOUD_NAME $OS_ADMIN_USERNAME
else
    log "Skipping SSH Setup"
fi

# 2. Run Bootstrap for Mongo & MySql [Jumpbox Only]
# Infrastracture Bootstrap - Install & Configure 3-node Replicated Mysql Server cluster & 3-node Mongo Server ReplicaSet
# This execution is now generic and will account for machine roles
# TODO: break out shared functionalities to utilities so that they can be called independently
bash $CURRENT_PATH/bootstrap-db.sh -e $CLOUD_NAME --phase $BOOTSTRAP_PHASE --tools-version-override $OXA_TOOLS_PUBLIC_GITHUB_PROJECTBRANCH --keyvault-name $KEYVAULT_NAME --aad-webclient-id $AAD_WEBCLIENT_ID --aad-webclient-appkey $AAD_WEBCLIENT_APPKEY --aad-tenant-id $AAD_TENANT_ID --azure-subscription-id $AZURE_SUBSCRIPTION_ID --cluster-admin-email $CLUSTER_ADMIN_EMAIL --cluster-name $CLUSTER_NAME
exit_on_error "Phase 0 Bootstrap for Mongo & Mysql failed for $HOST" 1 "${MAIL_SUBJECT} Failed" "$CLUSTER_ADMIN_EMAIL" "$PRIMARY_LOG" "$SECONDARY_LOG"

# OpenEdX Bootstrap (EdX Database - Mysql & EdX App - VMSS)
# Due to custom script extension execution timeout limitations (40mins/90mins), we need to move Phase 1 bootstrap (AppTier Bootstrap) to a 
# cron job. This ensures that after the Phase 0 bootstrap (Infrastructure Bootstrap), Phase 1 will be run but not block the ARM deployment
# from provisioning the VMSS. It is expected that Phase 1 will deposit crumbs that the VMSS instances will look for (if necessary)
# to ensure bootstrap sequencing (Phase 0 -> Phase 1 -> VMSS)

if [ "$MACHINE_ROLE" == "jumpbox" ];
then
    # 1. EDXDB Bootstrap - Deploy OpenEdx Schema to MySql
    # there is an implicit assumption that /oxa/oxa-tools has already been cloned
    SHORT_ROLE_NAME="jb"
    TASK="Phase 1 (EDXDB) Bootstrap on ${HOSTNAME} for execution via cron @ ${CRONTAB_INTERVAL_MINUTES} minute interval"
    NOTIFICATION_MESSAGE="Installation of the EDX Database has been scheduled."
fi

# 2. OpenEdX Application-Tier Bootstrap - Deploy OpenEdx FrontEnds to VMSS
if [ "$MACHINE_ROLE" == "vmss" ];
then
    # 2. EDXAPP Bootstrap - Deploy OpenEdx Application to VMSS instance
    # there is an implicit assumption that /oxa/oxa-tools has already been cloned
    SHORT_ROLE_NAME="vmss"
    TASK="VMSS Bootstrap on ${HOSTNAME} for execution via cron @ ${CRONTAB_INTERVAL_MINUTES} minute interval"
    NOTIFICATION_MESSAGE="Installation of the EDX Application (VMSS) has been scheduled."
fi

# PROCESS the bootstrap work load for Jumpbox or Vmss
if [ "$MACHINE_ROLE" == "jumpbox" ] || [ "$MACHINE_ROLE" == "vmss" ];
then
    log "Starting $TASK"

    # setup the temporary cron installer script
    CRON_INSTALLER_SCRIPT="$CURRENT_PATH/background-installer.sh"

    # setup the repo parameters individually
    OXA_TOOLS_GITHUB_PARAMS="--oxatools-public-github-accountname $OXA_TOOLS_PUBLIC_GITHUB_ACCOUNTNAME --oxatools-public-github-projectname $OXA_TOOLS_PUBLIC_GITHUB_PROJECTNAME --oxatools-public-github-projectbranch $OXA_TOOLS_PUBLIC_GITHUB_PROJECTBRANCH"
    EDX_CONFIGURATION_GITHUB_PARAMS="--edxconfiguration-public-github-accountname $EDX_CONFIGURATION_PUBLIC_GITHUB_ACCOUNTNAME --edxconfiguration-public-github-projectname $EDX_CONFIGURATION_PUBLIC_GITHUB_PROJECTNAME --edxconfiguration-public-github-projectbranch $EDX_CONFIGURATION_PUBLIC_GITHUB_PROJECTBRANCH"
    EDX_PLATFORM_GITHUB_PARAMS="--edxplatform-public-github-accountname $EDX_PLATFORM_PUBLIC_GITHUB_ACCOUNTNAME --edxplatform-public-github-projectname $EDX_PLATFORM_PUBLIC_GITHUB_PROJECTNAME --edxplatform-public-github-projectbranch $EDX_PLATFORM_PUBLIC_GITHUB_PROJECTBRANCH"
    EDX_THEME_GITHUB_PARAMS="--edxtheme-public-github-accountname $EDX_THEME_PUBLIC_GITHUB_ACCOUNTNAME --edxtheme-public-github-projectname $EDX_THEME_PUBLIC_GITHUB_PROJECTNAME --edxtheme-public-github-projectbranch $EDX_THEME_PUBLIC_GITHUB_PROJECTBRANCH"
    ANSIBLE_GITHUB_PARAMS="--ansible-public-github-accountname $ANSIBLE_PUBLIC_GITHUB_ACCOUNTNAME --ansible-public-github-projectname $ANSIBLE_PUBLIC_GITHUB_PROJECTNAME --ansible-public-github-projectbranch $ANSIBLE_PUBLIC_GITHUB_PROJECTBRANCH"

    # servicebus notification parameters
    SERVICEBUS_PARAMS="--servicebus-namespace '${servicebus_namespace}' --servicebus-queue-name '${servicebus_queue_name}' --servicebus-shared-access-key-name '${servicebus_shared_access_key_name}' --servicebus-shared-access-key '${servicebus_shared_access_key}'"
    
    INSTALL_COMMAND="sudo flock -n /var/log/bootstrap.lock bash $REPO_ROOT/$OXA_TOOLS_PUBLIC_GITHUB_PROJECTNAME/scripts/bootstrap.sh -e $CLOUD_NAME --role $SHORT_ROLE_NAME --installer-script-path $CRON_INSTALLER_SCRIPT --cluster-admin-email $CLUSTER_ADMIN_EMAIL --cluster-name $CLUSTER_NAME ${OXA_TOOLS_GITHUB_PARAMS} ${EDX_CONFIGURATION_GITHUB_PARAMS} ${EDX_PLATFORM_GITHUB_PARAMS} ${EDX_THEME_GITHUB_PARAMS} ${ANSIBLE_GITHUB_PARAMS} ${SERVICEBUS_PARAMS} --edxversion $EDX_VERSION --forumversion $FORUM_VERSION --cron >> /var/log/bootstrap.log 2>&1"
    echo $INSTALL_COMMAND > $CRON_INSTALLER_SCRIPT

    # Remove the task if it is already setup
    log "Uninstalling background installer cron job"
    crontab -l | grep -v "sudo bash $CRON_INSTALLER_SCRIPT" | crontab -

    # Setup the background job
    log "Installing background installer cron job"
    crontab -l | { cat; echo "*/${CRONTAB_INTERVAL_MINUTES} * * * *  sudo bash $CRON_INSTALLER_SCRIPT"; } | crontab -
    exit_on_error "Crontab setup for '${TASK}' on '${HOSTNAME}' failed!" $ERROR_CRONTAB_FAILED "${MAIL_SUBJECT}" "${CLUSTER_ADMIN_EMAIL}" "${PRIMARY_LOG}" "${SECONDARY_LOG}"

    log "Crontab setup is done"
else
    log "Skipping Jumpbox and VMSS Bootstrap"
fi

exit_on_error "OXA Installation failed" 1 "${MAIL_SUBJECT}" "${CLUSTER_ADMIN_EMAIL}" "${PRIMARY_LOG}" "${SECONDARY_LOG}"

if [ "$MACHINE_ROLE" == "jumpbox" ];
then

    # In order to support upgrade scenario, a secondary memcache server is required.
    # Install & configure it using the existing deployment extension script

    log "Installing secondary memcached."

    temp_utilities="${REPO_ROOT}/${OXA_TOOLS_PUBLIC_GITHUB_PROJECTNAME}/scripts/deploymentextensions/installmemcached/utilities.sh"

    # create link to temporary utilities file
    ln -s "${UTILITIES_PATH}" "${temp_utilities}"

    bash "${REPO_ROOT}/${OXA_TOOLS_PUBLIC_GITHUB_PROJECTNAME}/scripts/deploymentextensions/installmemcached/install.sh" \
        --oxatools-public-github-accountname "${OXA_TOOLS_PUBLIC_GITHUB_ACCOUNTNAME}" \
        --oxatools-public-github-projectname "${OXA_TOOLS_PUBLIC_GITHUB_PROJECTNAME}" \
        --oxatools-public-github-projectbranch "${OXA_TOOLS_PUBLIC_GITHUB_PROJECTBRANCH}" \
        --oxatools-repository-path "${REPO_ROOT}/${OXA_TOOLS_PUBLIC_GITHUB_PROJECTNAME}" \
        --cluster-admin-email "${CLUSTER_ADMIN_EMAIL}" \
        --target-user "${OS_ADMIN_USERNAME}"

    exit_on_error "Unable to install secondary memcache server." 1 "${MAIL_SUBJECT}" "${CLUSTER_ADMIN_EMAIL}" "${PRIMARY_LOG}" "${SECONDARY_LOG}"

    # clean up the temporary utilities file
    rm "${temp_utilities}"

    log "Completed installation of secondary memcached."
fi

# at this point, we have succeeded
log "${NOTIFICATION_MESSAGE}"
send_notification "${NOTIFICATION_MESSAGE}" "${MAIL_SUBJECT}" "${CLUSTER_ADMIN_EMAIL}"
exit 0