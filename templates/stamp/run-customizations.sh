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

# source our utilities for logging and other base functions (we need this staged with the installer script)
# the file needs to be first downloaded from the public repository
CURRENT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
UTILITIES_PATH=$CURRENT_PATH/utilities.sh
wget -q https://raw.githubusercontent.com/Microsoft/oxa-tools/master/templates/stamp/utilities.sh -O $UTILITIES_PATH
source $UTILITIES_PATH

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

}

# Parse script parameters
while getopts :c:p:a:n:h optname; do

    # Log input parameters to facilitate troubleshooting
    if [ ! "$optname" == "p" ]; then
        log "Option $optname set with value ${OPTARG}"
    fi
    
    case $optname in
    c) # Cloud Name
        CLOUDNAME=${OPTARG}
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
    u) # OS Admin User Name
        OS_ADMIN_USERNAME=${OPTARG}
        ;;
    i) # Custom script relative path
        CUSTOM_INSTALLER_RELATIVEPATH=${OPTARG}
        ;;
    m) # Custom script relative path
        MONITORING_CLUSTER_NAME=${OPTARG}
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
if [ "GITHUB_PERSONAL_ACCESS_TOKEN" == "" ] || [ "GITHUB_ACCOUNTNAME" == "" ] || [ "GITHUB_PROJECTNAME" == "" ] || [ "GITHUB_PROJECTBRANCH" == "" ] || [ "CLOUDNAME" == "" ] ;
then
    log "Incomplete Github configuration: Github Personal Access Token, Account Name,  Project Name & Branch Name are required." $ERROR_MESSAGE
    exit 3
fi

log "Begin customization from '${HOSTNAME}' for the OXA Stamp"

# 1. Setup Tools
install-git
install-mongodb-shell
install-mysql-client

# 2. Clone the GitHub repository
clone_repository $GITHUB_ACCOUNTNAME $GITHUB_PROJECTNAME $GITHUB_PROJECTBRANCH $GITHUB_PERSONAL_ACCESS_TOKEN ~/$GITHUB_PROJECTNAME

# 3. Launch custom installer
CUSTOM_INSTALLER_PATH=~/$GITHUB_PROJECTNAME/$CUSTOM_INSTALLER_RELATIVEPATH

if [[ -e $CUSTOM_INSTALLER_PATH ]]; then  
    log "Launching the custom installer at '$CUSTOM_INSTALLER_PATH'"
    bash $CUSTOM_INSTALLER_PATH --root-path ~/$GITHUB_PROJECTNAME --cloud $CLOUD_NAME --admin-user $OS_ADMIN_USERNAME --monitoring-cluster $MONITORING_CLUSTER_NAME --access-token $GITHUB_PERSONAL_ACCESS_TOKEN
else
    log "$CUSTOM_INSTALLER_PATH does not exist"
fi

# Exit (proudly)
log "Completed execution of OXA stamp customization Exiting cleanly."
exit 0