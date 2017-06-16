#!/bin/bash
#
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

#
# This script rotates the SSH key for the target user on the jumpbox.
#

# Oxa Tools
# Settings for the OXA-Tools public repository 
oxa_tools_public_github_account="Microsoft"
oxa_tools_public_github_projectname="oxa-tools"
oxa_tools_public_github_projectbranch="oxa/master.fic"
oxa_tools_public_github_branchtag=""
oxa_tools_repository_path="/oxa/oxa-tools"

# Email Notifications
notification_email_subject="Rotate SSH Key Installer"
cluster_admin_email=""

# this is the user account that will be used for ssh
target_user=""

# the updated private key for the target user
private_key=""

# the updated public key for the target user
public_key=""

# authorized keys path for the target user
authorized_keys_path=""

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
          --cluster-admin-email)
            cluster_admin_email="${arg_value}"
            ;;
          --target-user)
            target_user="${arg_value}"
            ;;
          --private-key)
            private_key=`echo ${arg_value} | base64 --decode`
            ;;
          --public-key)
            public_key=`echo ${arg_value} | base64 --decode`
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

    # target user
    if [[ -z $target_user ]]; 
    then
        log "You must specify a user account to use for SSH to remote servers"
        exit $ERROR_SSHKEYROTATION_INSTALLER_FAILED
    fi

    # check the authorized keys for the user

    # only add the new public key as the only authorized key for the specific user
    authorized_keys_path="/home/${target_user}/.ssh/authorized_keys"

    if [[ ! -f $authorized_keys_path ]];
    then
        log "The target user's authorized keys doesn't already exist."
        exit $ERROR_SSHKEYROTATION_INSTALLER_FAILED
    fi

    # public key for the target user
    if [[ -z $public_key ]]; 
    then
        log "You must specify valid public key"
        exit $ERROR_SSHKEYROTATION_INSTALLER_FAILED
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

echo $public_key > $authorized_keys_path
exit_on_error "Unable to add specified public key as the authorized key for ${target_user}:  ${authorized_keys_path}" $ERROR_SSHKEYROTATION_INSTALLER_FAILED, $notification_email_subject $cluster_admin_email

# Setup permissions for public/private key
chmod 600 $authorized_keys_path
exit_on_error "Unable set permissions for the authorized keys file at ${authorized_keys_path}" $ERROR_SSHKEYROTATION_INSTALLER_FAILED, $notification_email_subject $cluster_admin_email

# TODO: add support for a deep clean mode where we update the actual public/private keys for the JB and all other servers within the cluster
# To do this, make sure the sequence is respected: update the authorized key for other servers first, and update the public/private key for the jumpbox
log "Completed Key Rotation for ${target_user}"