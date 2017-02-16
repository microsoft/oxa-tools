#!/bin/bash
#
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

ERROR_MESSAGE=1
CLOUDNAME=""
OS_ADMIN_USERNAME=""
CUSTOM_INSTALLER_RELATIVEPATH=""
MONITORING_CLUSTER_NAME=""
BOOTSTRAP_PHASE=0
REPO_ROOT="/oxa" 

# Oxa Tools Github configs
OXA_TOOLS_PUBLIC_GITHUB_PROJECTNAME="oxa-tools"
OXA_TOOLS_PUBLIC_GITHUB_ACCOUNTNAME="Microsoft"
OXA_TOOLS_PUBLIC_GITHUB_PROJECTBRANCH="master"

# Edx Configuration Github configs
EDX_CONFIGURATION_PUBLIC_GITHUB_PROJECTNAME="edx-configuration"
EDX_CONFIGURATION_PUBLIC_GITHUB_ACCOUNTNAME="Microsoft"
EDX_CONFIGURATION_PUBLIC_GITHUB_PROJECTBRANCH="oxa/master"


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
powershell -file $INSTALLER_BASEPATH/Process-OxaToolsKeyVaultConfiguration.ps1 -Operation Download -VaultName $KEYVAULT_NAME -AadWebClientId $AAD_WEBCLIENT_ID -AadWebClientAppKey $AAD_WEBCLIENT_APPKEY -AadTenantId $AAD_TENANT_ID -TargetPath $OXA_ENV_PATH -AzureSubscriptionId $AZURE_SUBSCRIPTION_ID
exit_on_error "Failed downloading configurations from keyvault"

# copy utilities to the installer path
cp $UTILITIES_PATH "${INSTALLER_BASEPATH}"

# execute the installer if present
log "Launching the installer at '$INSTALLER_PATH'"
bash $INSTALLER_PATH --repo-path "${REPO_ROOT}/oxa-tools-config" --cloud $CLOUDNAME --admin-user $OS_ADMIN_USERNAME --monitoring-cluster $MONITORING_CLUSTER_NAME --phase $BOOTSTRAP_PHASE --keyvault-name $KEYVAULT_NAME --aad-webclient-id $AAD_WEBCLIENT_ID --aad-webclient-appkey $AAD_WEBCLIENT_APPKEY --aad-tenant-id $AAD_TENANT_ID --azure-subscription-id $AZURE_SUBSCRIPTION_ID --edxconfiguration-public-github-accountname $EDX_CONFIGURATION_PUBLIC_GITHUB_ACCOUNTNAME --edxconfiguration-public-github-projectname $EDX_CONFIGURATION_PUBLIC_GITHUB_PROJECTNAME --edxconfiguration-public-github-projectbranch $EDX_CONFIGURATION_PUBLIC_GITHUB_PROJECTBRANCH --oxatools-public-github-accountname $OXA_TOOLS_PUBLIC_GITHUB_ACCOUNTNAME --oxatools-public-github-projectname $OXA_TOOLS_PUBLIC_GITHUB_PROJECTNAME --oxatools-public-github-projectbranch $OXA_TOOLS_PUBLIC_GITHUB_PROJECTBRANCH
exit_on_error "OXA stamp customization failed"

# Exit (proudly)
log "Completed execution of OXA stamp customization Exiting cleanly."
exit 
0