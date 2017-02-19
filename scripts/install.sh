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

#TODO: complete plumbing this variable as a user input
CRONTAB_INTERVAL_MINUTES=5

# ERROR CODES: 
# TODO: move to common script
ERROR_CRONTAB_FAILED=4101
ERROR_PHASE0_FAILED=6001

# SMTP / Mailer parameters
CLUSTER_ADMIN_EMAIL=""
MAIL_SUBJECT="OXA Bootstrap - Bootstrap Install"
NOTIFICATION_MESSAGE=""
SECONDARY_LOG="/var/log/bootstrap.csx.log"
PRIMARY_LOG="/var/log/bootstrap.log"

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
    echo "        --azure-subscription-id    Azure subscription id"
    echo "        --cluster-admin-email Email address of the administrator where system and other notifications will be sent"
}

# Parse script parameters
parse_args()
{
    while [[ "$#" -gt 0 ]]
        do

         # Log input parameters to facilitate troubleshooting
        echo "Option '$1' set with value '$2'"

        case "$1" in
            --repo-root)
                REPO_ROOT=$2
                ;;
            --config-path)
                CONFIG_PATH=$2
                ;;
            --cloud)
                CLOUD_NAME=$2
                ;;
            -u|--admin-user)
                OS_ADMIN_USERNAME=$2
                ;;
            --monitoring-cluster)
                MONITORING_CLUSTER_NAME=$2
                ;;
            --phase)
                if is_valid_arg "0 1" $2; then
                    BOOTSTRAP_PHASE=$2
                else
                    log "Invalid Bootstrap Phase specified - $2" $ERROR_MESSAGE
                    help
                    exit 2
                fi
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
              --azure-subscription-id)
                AZURE_SUBSCRIPTION_ID="$2"
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
              --cluster-admin-email)
                CLUSTER_ADMIN_EMAIL="$2"
                ;;
            -h|--help)  # Helpful hints
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

# parse script arguments
parse_args $@ 

# Script self-idenfitication
print_script_header

# validate key arguments
if [ "$GITHUB_PROJECTBRANCH" == "" ] || [ "$CLOUD_NAME" == "" ] ;
then
    log "Incomplete Github configuration: Github Personal Access Token, Account Name,  Project Name & Branch Name are required." $ERROR_MESSAGE
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
# TODO: provide option to target different version of repositories
bash $CURRENT_PATH/bootstrap-db.sh -e $CLOUD_NAME --phase $BOOTSTRAP_PHASE --tools-version-override $OXA_TOOLS_PUBLIC_GITHUB_PROJECTBRANCH --keyvault-name $KEYVAULT_NAME --aad-webclient-id $AAD_WEBCLIENT_ID --aad-webclient-appkey $AAD_WEBCLIENT_APPKEY --aad-tenant-id $AAD_TENANT_ID --azure-subscription-id $AZURE_SUBSCRIPTION_ID --cluster-admin-email $CLUSTER_ADMIN_EMAIL
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
fi

# 2. OpenEdX Application-Tier Bootstrap - Deploy OpenEdx FrontEnds to VMSS
if [ "$MACHINE_ROLE" == "vmss" ];
then
    # 2. EDXAPP Bootstrap - Deploy OpenEdx Application to VMSS instance
    # there is an implicit assumption that /oxa/oxa-tools has already been cloned
    # TODO: we need a better way of passing around the 'ITHUB_PERSONAL_ACCESS_TOKEN'
    SHORT_ROLE_NAME="vmss"
    TASK="VMSS Bootstrap on ${HOSTNAME} for execution via cron @ ${CRONTAB_INTERVAL_MINUTES} minute interval"
fi

# PROCESS the bootstrap work load for Jumpbox or Vmss
if [ "$MACHINE_ROLE" == "jumpbox" ] || [ "$MACHINE_ROLE" == "vmss" ];
then
    log "Starting $TASK"

    # setup the temporary cron installer script
    CRON_INSTALLER_SCRIPT="$CURRENT_PATH/background-installer.sh"

    INSTALL_COMMAND="sudo flock -n /var/log/bootstrap.lock bash $REPO_ROOT/$OXA_TOOLS_PUBLIC_GITHUB_PROJECTNAME/scripts/bootstrap.sh -e $CLOUD_NAME --role $SHORT_ROLE_NAME --oxatools_public-github-accountname $OXA_TOOLS_PUBLIC_GITHUB_ACCOUNTNAME --oxatools_public-github-projectname $OXA_TOOLS_PUBLIC_GITHUB_PROJECTNAME --oxatools_public-github-projectbranch $OXA_TOOLS_PUBLIC_GITHUB_PROJECTBRANCH --oxatools_public-github-projectbranch $OXA_TOOLS_PUBLIC_GITHUB_PROJECTBRANCH --oxatools_public-github-accountname $OXA_TOOLS_PUBLIC_GITHUB_ACCOUNTNAME --edxconfiguration_public-github-projectname $EDX_CONFIGURATION_PUBLIC_GITHUB_ACCOUNTNAME --edxconfiguration_public-github-projectbranch $EDX_CONFIGURATION_PUBLIC_GITHUB_PROJECTBRANCH --edxconfiguration_public-github-projectbranch $EDX_CONFIGURATION_PUBLIC_GITHUB_PROJECTBRANCH --installer-script-path $CRON_INSTALLER_SCRIPT --cron >> /var/log/bootstrap.log 2>&1"
    echo $INSTALL_COMMAND > $CRON_INSTALLER_SCRIPT

    # Remove the task if it is already setup
    log "Uninstalling background installer cron job"
    crontab -l | grep -v "sudo bash $CRON_INSTALLER_SCRIPT" | crontab -

    # Setup the background job
    log "Installing background installer cron job"
    crontab -l | { cat; echo "*/${CRONTAB_INTERVAL_MINUTES} * * * *  sudo bash $CRON_INSTALLER_SCRIPT"; } | crontab -
    exit_on_error "Crontab setup for '${TASK}' on '${HOSTNAME}' failed!" $ERROR_CRONTAB_FAILED "${MAIL_SUBJECT} Failed" $CLUSTER_ADMIN_EMAIL $PRIMARY_LOG $SECONDARY_LOG

    log "Crontab setup is done"
else
    log "Skipping Jumpbox and VMSS Bootstrap"
fi

exit_on_error "OXA Installation failed" 1 "${MAIL_SUBJECT} - Installer Failed" $CLUSTER_ADMIN_EMAIL $PRIMARY_LOG $SECONDARY_LOG

# at this point, we have succeeded
NOTIFICATION_MESSAGE="Custom bootstrap for the OXA Stamp (Phase 0) has completed successfully. The application level installer for the '$MACHINE_ROLE' role have been setup to run in the background."
log "${NOTIFICATION_MESSAGE}"
send-notification "${NOTIFICATION_MESSAGE}" "${MAIL_SUBJECT} - Phase 0 Bootstrap" "${CLUSTER_ADMIN_EMAIL}"
exit 0