#!/bin/bash
#
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.
#
# todo: is this dead code or is it invoked through arm template's extension scripts? (aka oxa-tools/templates/stamp/stamp*json files)

GITHUB_PERSONAL_ACCESS_TOKEN=""
GITHUB_ACCOUNTNAME=""
GITHUB_PROJECTNAME=""
GITHUB_PROJECTBRANCH=""
CUSTOM_INSTALLER_RELATIVEPATH=""
CLOUD_NAME=""
MONITORING_CLUSTER_NAME=""
OS_ADMIN_USERNAME=""

# source our utilities for logging and other base functions (we need this staged with the installer script)
CURRENT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $CURRENT_PATH/utilities.sh

help()
{
    echo "This script installs git client, sync the specified git repository and executes the provided custom script from the git repository"
    echo "Options:"
    echo "        -p GitHub Personal Access Token"
    echo "        -a GitHub Account Name"
    echo "        -n GitHub Project Name"
    echo "        -b GitHub Project Branch"
    echo "        -i Custom Installer Relative Path"
    echo "        -c Cloud Name"
    echo "        -m Monitoring Cluster Name"
    echo "        -u OS Admin User Name"
}

# Parse script parameters
while getopts :i:p:a:n:b:c:m:u:h optname; do

    # Log input parameters to facilitate troubleshooting
    if [ ! "$optname" == "p" ]; then
        log "Option $optname set with value ${OPTARG}"
    fi

    case $optname in
    i) # Custom Installer Relative Path
        CUSTOM_INSTALLER_RELATIVEPATH=${OPTARG}
        ;;
    p) # GitHub Personal Access Token
        GITHUB_PERSONAL_ACCESS_TOKEN=${OPTARG}
        ;;
    a) # GitHub Account Name
        GITHUB_ACCOUNTNAME=${OPTARG}
        ;;
    n) # GitHub Project Name
        GITHUB_PROJECTNAME=${OPTARG}
        ;;
    b) # GitHub Project Branch
        GITHUB_PROJECTBRANCH=${OPTARG}
        ;;
    c) # Cloud Name
        CLOUD_NAME=${OPTARG}
        ;;
    m) # Monitoring Cluster Name
        MONITORING_CLUSTER_NAME=${OPTARG}
        ;;
    u) # OS Admin User Name
        OS_ADMIN_USERNAME=${OPTARG}
        ;;
    h)  # Helpful hints
        help
        exit 2
        ;;
    \?) # Unrecognized option - show help
        log "Option -${BOLD}$OPTARG${NORM} not allowed." $ERROR_MESSAGE
        help
        exit 2
        ;;
  esac
done

# Validate parameters
if [ "$GITHUB_PERSONAL_ACCESS_TOKEN" == "" ] || [ "$GITHUB_ACCOUNTNAME" == "" ] || [ "$GITHUB_PROJECTNAME" == "" ] || [ "$GITHUB_PROJECTBRANCH" == "" ] || [ "$CLOUD_NAME" == "" ] ;
then
    log "Incomplete Github configuration: Github Personal Access Token, Account Name,  Project Name & Branch Name are required." $ERROR_MESSAGE
    exit 3
fi

log "Begin installation of the Geneva Monitoring WarmPath Package MDSD on '${HOSTNAME}'"


###############################################
# Start Execution
###############################################

# 0. Install Tools: git client, mongo shell, mysql client
install-git
install-mongodb-shell
install-mysql-client

# 1. Clone the GitHub repository with the secrets and other support files
clone_repository $GITHUB_ACCOUNTNAME $GITHUB_PROJECTNAME $GITHUB_PROJECTBRANCH $GITHUB_PERSONAL_ACCESS_TOKEN
#todo: if this is live code, transform "deployment-time" values

#2. Launch custom installer
# REFACTOR: point to the appropriate file for the cloud-specific deployment or pass parameters
CUSTOM_INSTALLER_PATH=~/$GITHUB_PROJECTNAME/$CUSTOM_INSTALLER_RELATIVEPATH

if [[ -e $CUSTOM_INSTALLER_PATH ]]; then  
    log "Launching the custom installer at '$CUSTOM_INSTALLER_PATH'"

    log "Exporting ConfigRootPath=~/$GITHUB_PROJECTNAME, CloudName=$CLOUD_NAME, MONITORING_CLUSTER_NAME=$MONITORING_CLUSTER_NAME"
    export CONFIG_ROOTPATH=~/$GITHUB_PROJECTNAME
    export CLOUDNAME=$CLOUD_NAME 
    export MONITORING_CLUSTER_NAME=$MONITORING_CLUSTER_NAME

    bash $CUSTOM_INSTALLER_PATH
else
    log "$CUSTOM_INSTALLER_PATH does not exist"
fi

# Setup SSH
setup-ssh ~/$GITHUB_PROJECTNAME $CLOUD_NAME $OS_ADMIN_USERNAME

# 3. Remove the Github repository
clean_repository

# Exit (proudly)
log "Completed Repository cloning, custom install and cleanups. Exiting cleanly."
exit 0