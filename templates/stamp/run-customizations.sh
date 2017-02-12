#!/bin/bash
#
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

ERROR_MESSAGE=1
CLOUDNAME=""
GITHUB_PROJECTNAME=""
GITHUB_ACCOUNTNAME=""
GITHUB_PERSONAL_ACCESS_TOKEN=""
GITHUB_PROJECTBRANCH="master"
OS_ADMIN_USERNAME=""
CUSTOM_INSTALLER_RELATIVEPATH=""
MONITORING_CLUSTER_NAME=""
BOOTSTRAP_PHASE=0
REPO_ROOT="/oxa" 
PUBLIC_GITHUB_PROJECTNAME="oxa-tools"
PUBLIC_GITHUB_ACCOUNTNAME="Microsoft"
PUBLIC_GITHUB_PROJECTBRANCH="master"

help()
{
    echo "This script bootstraps the OXA Stamp"
    echo "Options:"
    echo "        -c Cloud name"
    echo "        -p GitHub Personal Access Token"
    echo "        -a GitHub Account Name"
    echo "        -n GitHub Project Name"
    echo "        -b GitHub Project Branch"
    echo "        -u OS Admin User Name"
    echo "        -i Custom script relative path"
    echo "        -u OS Admin User Name"
    echo "        -m Monitoring cluster name"
    echo "        -s Bootstrap Phase (0=Servers, 1=OpenEdx App)"
    echo "        --keyvault-name Name of the key vault"
    echo "        --aad-webclient-id Id of AAD web client (service principal)"
    echo "        --aad-webclient-appkey Application key for the AAD web client"
    echo "        --aad-tenant-id AAD Tenant Id"
    echo "        --public-github-accountname Name of the GitHub account that owns the public OXA repository"
    echo "        --public-github-projectname Name of the public GitHub repository for OXA"
    echo "        --public-github-projectbranch Branch of the public GitHub repository for OXA to use"
    echo "        --azure-subscription-id  Azure subscription id"
}

# Parse script parameters
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
            -p) # GitHub Personal Access Token
                GITHUB_PERSONAL_ACCESS_TOKEN=$2
                ;;
            -a) # GitHub Account Name
                GITHUB_ACCOUNTNAME=$2
                ;;
            -n) # GitHub Project Name
                GITHUB_PROJECTNAME=$2
                ;;
            -b) # GitHub Project Branch
                GITHUB_PROJECTBRANCH=$2
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
            -s) # Bootstrap Phase (0=Servers, 1=OpenEdx App)
                if is_valid_arg "0 1" $2; then
                    BOOTSTRAP_PHASE=$2
                else
                    log "Invalid Bootstrap Phase specified - $2" $ERROR_MESSAGE
                    help
                    exit 2
                fi
                ;;
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
              --public-github-accountname)
                PUBLIC_GITHUB_ACCOUNTNAME="$2"
                ;;
              --public-github-projectname)
                PUBLIC_GITHUB_PROJECTNAME="$2"
                ;;
              --public-github-projectbranch)
                PUBLIC_GITHUB_PROJECTBRANCH="$2"
                ;;
              --azure-subscription-id)
                AZURE_SUBSCRIPTION_ID="$2"
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
if [ "$GITHUB_PERSONAL_ACCESS_TOKEN" == "" ] || [ "$GITHUB_ACCOUNTNAME" == "" ] || [ "$GITHUB_PROJECTNAME" == "" ] || [ "$GITHUB_PROJECTBRANCH" == "" ] || [ "$CLOUDNAME" == "" ] ;
then
    log "Incomplete Github configuration: Github Personal Access Token, Account Name,  Project Name & Branch Name are required." $ERROR_MESSAGE
    exit 3
fi

log "Begin customization from '${HOSTNAME}' for the OXA Stamp"

MACHINE_ROLE=$(get_machine_role)
log "${HOSTNAME} has been identified as a member of the '${MACHINE_ROLE}' role"

# 1. Setup Tools
install-git

if [ "$MACHINE_ROLE" == "jumpbox" ] || [ "$MACHINE_ROLE" == "vmss" ];
then
    install-mongodb-shell
    install-mysql-client

    install-powershell
    install-azure-cli
fi

# 2. Install & Configure the infrastructure & EdX applications
clone_repository $PUBLIC_GITHUB_ACCOUNTNAME $PUBLIC_GITHUB_PROJECTNAME $PUBLIC_GITHUB_PROJECTBRANCH ''  "${REPO_ROOT}/${PUBLIC_GITHUB_PROJECTNAME}"

# setup the installer path
INSTALLER_BASEPATH="${REPO_ROOT}/${PUBLIC_GITHUB_PROJECTNAME}/scripts"
INSTALLER_PATH="${INSTALLER_BASEPATH}/install.sh"

# copy utilities to the installer path
cp $UTILITIES_PATH "${INSTALLER_BASEPATH}"

# execute the installer if present
log "Launching the installer at '$INSTALLER_PATH'"
bash $INSTALLER_PATH --repo-path ~/$GITHUB_PROJECTNAME --cloud $CLOUDNAME --admin-user $OS_ADMIN_USERNAME --monitoring-cluster $MONITORING_CLUSTER_NAME --access-token $GITHUB_PERSONAL_ACCESS_TOKEN --branch $GITHUB_PROJECTBRANCH --phase $BOOTSTRAP_PHASE --keyvault-name $KEYVAULT_NAME --aad-webclient-id $AAD_WEBCLIENT_ID --aad-webclient-appkey $AAD_WEBCLIENT_APPKEY --aad-tenant-id $AAD_TENANT_ID --azure-subscription-id $AZURE_SUBSCRIPTION_ID


# 3. Clone the GitHub repository & setup the utilities
# All configuration will be transitioned to Azure KeyVault
# If a customer still choses to use a private repository, we still support it
#clone_repository $GITHUB_ACCOUNTNAME $GITHUB_PROJECTNAME $GITHUB_PROJECTBRANCH $GITHUB_PERSONAL_ACCESS_TOKEN ~/$GITHUB_PROJECTNAME
#cp $UTILITIES_PATH ~/$GITHUB_PROJECTNAME/scripts/

# 3. Launch custom installer
#CUSTOM_INSTALLER_PATH=~/$GITHUB_PROJECTNAME/$CUSTOM_INSTALLER_RELATIVEPATH

#if [[ -e $CUSTOM_INSTALLER_PATH ]]; then  
#    log "Launching the custom installer at '$CUSTOM_INSTALLER_PATH'"
#    bash $CUSTOM_INSTALLER_PATH --repo-path ~/$GITHUB_PROJECTNAME --cloud $CLOUDNAME --admin-user $OS_ADMIN_USERNAME --monitoring-cluster $MONITORING_CLUSTER_NAME --access-token $GITHUB_PERSONAL_ACCESS_TOKEN --branch $GITHUB_PROJECTBRANCH --phase $BOOTSTRAP_PHASE 
#else
#    log "$CUSTOM_INSTALLER_PATH does not exist"
#fi

# Exit (proudly)
log "Completed execution of OXA stamp customization Exiting cleanly."
exit 0