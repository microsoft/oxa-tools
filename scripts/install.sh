#!/bin/bash
#
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

# This is our private bootstrap script for OXA Stamp
# This script will be run from the Jumpbox and will handle the following tasks
# 1. Setup SSH
# 2. Install MDSD for Monitoring
# 3. Run Bootstrap for Mongo & MySql

ERROR_MESSAGE=1
GITHUB_PERSONAL_ACCESS_TOKEN=""
GITHUB_PROJECTBRANCH="master"
CLOUD_NAME=""
MONITORING_CLUSTER_NAME=""
OS_ADMIN_USERNAME=""
REPO_ROOT_PATH=""
BOOTSTRAP_PHASE=0

#TODO: complete plumbing this variable as a user input
CRONTAB_INTERVAL_MINUTES=5

# ERROR CODES: 
# TODO: move to common script
ERROR_CRONTAB_FAILED=4101
ERROR_PHASE0_FAILED=6001

help()
{
    echo "This script sets up SSH, installs MDSD and runs the DB bootstrap"
    echo "Options:"
    echo "        --repo-path                Repository root path"
    echo "        --cloud                    Cloud Name"
    echo "        --admin-user               OS Admin User Name"
    echo "        --monitoring-cluster       Monitoring Cluster Name"
    echo "        --access-token             GitHub Personal Access Token"
    echo "        --branch                   GitHub Project Name"
    echo "        --phase                    Bootstrap Phase (0=Servers, 1=OpenEdx App)"
    echo "        --crontab-interval         Crontab Interval minutes"
    echo "        --keyvault-name            Name of the key vault"
    echo "        --aad-webclient-id         Id of AAD web client (service principal)"
    echo "        --aad-webclient-appkey     Application key for the AAD web client"
    echo "        --aad-tenant-id            AAD Tenant Id"
}

# Parse script parameters
parse_args()
{
    while [[ "$#" -gt 0 ]]
        do

         # Log input parameters to facilitate troubleshooting
        echo "Option $1 set with value $2"

        case "$1" in
            --repo-path)
                REPO_ROOT_PATH=$2
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
            --access-token)
                GITHUB_PERSONAL_ACCESS_TOKEN=$2
                ;;
            --branch)
                GITHUB_PROJECTBRANCH=$2
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
if [ "$GITHUB_PERSONAL_ACCESS_TOKEN" == "" ] || [ "$GITHUB_PROJECTBRANCH" == "" ] || [ "$CLOUD_NAME" == "" ] ;
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
    setup-ssh $REPO_ROOT_PATH $CLOUD_NAME $OS_ADMIN_USERNAME
else
    log "Skipping SSH Setup"
fi

# 2. Run Bootstrap for Mongo & MySql [Jumpbox Only]
# Infrastracture Bootstrap - Install & Configure 3-node Replicated Mysql Server cluster & 3-node Mongo Server ReplicaSet
# This execution is now generic and will account for machine roles
# TODO: break out shared functionalities to utilities so that they can be called independently
# TODO: provide option to target different version of repositories
bash $CURRENT_PATH/bootstrap-db.sh -e $CLOUD_NAME -a $GITHUB_PERSONAL_ACCESS_TOKEN --tools-config-version $GITHUB_PROJECTBRANCH --phase $BOOTSTRAP_PHASE --tools-version-override $GITHUB_PROJECTBRANCH --keyvault-name $KEYVAULT_NAME --aad-webclient-id $AAD_WEBCLIENT_ID --aad-webclient-appkey $AAD_WEBCLIENT_APPKEY --aad-tenant-id $AAD_TENANT_ID --azure-subscription-name $AAD_TENANT_ID
exit_on_error "Phase 0 Bootstrap for Mongo & Mysql failed for $HOST"

# OpenEdX Bootstrap (EdX Database - Mysql & EdX App - VMSS)
# Due to custom script extension execution timeout limitations (40mins/90mins), we need to move Phase 1 bootstrap (AppTier Bootstrap) to a 
# cron job. This ensures that after the Phase 0 bootstrap (Infrastructure Bootstrap), Phase 1 will be run but not block the ARM deployment
# from provisioning the VMSS. It is expected that Phase 1 will deposit crumbs that the VMSS instances will look for (if necessary)
# to ensure bootstrap sequencing (Phase 0 -> Phase 1 -> VMSS)

if [ "$MACHINE_ROLE" == "jumpbox" ];
then
    # 1. EDXDB Bootstrap - Deploy OpenEdx Schema to MySql
    # there is an implicit assumption that /oxa/oxa-tools has already been cloned
    # TODO: we need a better way of passing around the 'GITHUB_PERSONAL_ACCESS_TOKEN'

    log "Setting up Phase 1 (EDXDB) Bootstrap on ${HOSTNAME} for execution via cron @ ${CRONTAB_INTERVAL_MINUTES} minute interval"
    #TODO: setup smarter uninstaller
    crontab -r
    crontab -l | { cat; echo "*/${CRONTAB_INTERVAL_MINUTES} * * * *  sudo flock -n /var/log/bootstrap.lock bash /oxa/oxa-tools/scripts/bootstrap.sh -e ${CLOUD_NAME} -a ${GITHUB_PERSONAL_ACCESS_TOKEN} -v ${GITHUB_PROJECTBRANCH} --tools-version-override ${GITHUB_PROJECTBRANCH} -r jb --cron >> /var/log/bootstrap.log 2>&1"; } | crontab -

    exit_on_error "Crontab setup for executing Phase 1 bootstrap on ${HOSTNAME} failed!" $ERROR_CRONTAB_FAILED
    log "Crontab setup is done"
else
    log "Skipping the Application-Tier Bootstrap"
fi

# 2. OpenEdX Application-Tier Bootstrap - Deploy OpenEdx FrontEnds to VMSS
if [ "$MACHINE_ROLE" == "vmss" ];
then
    # 2. EDXAPP Bootstrap - Deploy OpenEdx Application to VMSS instance
    # there is an implicit assumption that /oxa/oxa-tools has already been cloned
    # TODO: we need a better way of passing around the 'ITHUB_PERSONAL_ACCESS_TOKEN'

    log "Setting up VMSS Bootstrap on ${HOSTNAME} for execution via cron @ ${CRONTAB_INTERVAL_MINUTES} minute interval"
    #TODO: setup smarter uninstaller
    crontab -r
    crontab -l | { cat; echo "*/${CRONTAB_INTERVAL_MINUTES} * * * *  sudo flock -n /var/log/bootstrap.lock bash /oxa/oxa-tools/scripts/bootstrap.sh -e ${CLOUD_NAME} -a ${GITHUB_PERSONAL_ACCESS_TOKEN} -v ${GITHUB_PROJECTBRANCH} --tools-version-override ${GITHUB_PROJECTBRANCH} -r vmss --cron >> /var/log/bootstrap.log 2>&1"; } | crontab -

    exit_on_error "Crontab setup for executing VMSS bootstrap on ${HOSTNAME} failed!" $ERROR_CRONTAB_FAILED
    log "Crontab setup is done"
else
    log "Skipping the VMSS Bootstrap"
fi

# Exit (proudly)
log "Completed custom bootstrap for the OXA Stamp. Exiting cleanly."
exit 0