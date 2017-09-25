#!/bin/bash
#
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

#
# This script installs various tools for the Jumpbox & Backend instances. 
# It also installs a mailer capability to allow the target servers to send emails.
#

# Oxa Tools
# Settings for the OXA-Tools public repository 
oxa_tools_public_github_account="Microsoft"
oxa_tools_public_github_projectname="oxa-tools"
oxa_tools_public_github_projectbranch="oxa/master.fic"
oxa_tools_public_github_branchtag=""
oxa_tools_repository_path="/oxa/oxa-tools"

# Email Notifications
notification_email_subject="Tools Installer"
cluster_admin_email=""

# this is the user account that will be used for ssh
target_user=""

# operation mode: 0=local, 1=remote via ssh
remote_mode=0

# debug mode: 0=set +x, 1=set -x
debug_mode=0

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
          --smtp-server)
            smtp_server="${arg_value}"
            ;;
          --smtp-server-port)
            smtp_server_port="${arg_value}"
            ;;
          --smtp-auth-user)
            smtp_auth_user="${arg_value}"
            ;;
          --smtp-auth-user-password)
            smtp_auth_user_password="${arg_value}"
            ;;
          --backend-server-list)
            backend_server_list=(`echo ${arg_value} | base64 --decode`)
            ;;
          --target-user)
            target_user="${arg_value}"
            ;;
          --remote)
            remote_mode=1
            ;;
          --debug)
            debug_mode=1
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
        exit $ERROR_TOOLS_INSTALLER_FAILED
    fi

    # SMTP validation
    if [[ -z $smtp_server ]] || [[ -z smtp_server_port ]] || [[ -z $smtp_auth_user ]] || [[ -z smtp_auth_user_password ]] || [[ -z cluster_admin_email ]];
    then
        log "Invalid SMTP parameters. You must specify the smtp server, port, authentication user, authentication user password and a cluster administrator email"
        exit $ERROR_TOOLS_INSTALLER_FAILED
    fi

    log "Completed argument validation successfully"
}

execute_remote_command()
{
    remote_execution_server_target=$1
    remote_execution_target_user=$2

    # build the command for remote execution (basically: pass through all existing parameters)
    encoded_server_list=`echo ${backend_server_list} | base64`
    
    repository_parameters="--oxatools-public-github-accountname ""${oxa_tools_public_github_account}"" --oxatools-public-github-projectname ""${oxa_tools_public_github_projectname}"" --oxatools-public-github-projectbranch ""${oxa_tools_public_github_projectbranch}"" --oxatools-public-github-branchtag ""${oxa_tools_public_github_branchtag}"" --oxatools-repository-path ""${oxa_tools_repository_path}"""
    smtp_parameters="--smtp-server ""${smtp_server}"" --smtp-server-port ""${smtp_server_port}"" --smtp-auth-user ""${smtp_auth_user}"" --smtp-auth-user-password ""${smtp_auth_user_password}"""
    misc_parameters="--cluster-admin-email ""${cluster_admin_email}"" --target-user ""${target_user}"" --remote"

    remote_command="sudo bash ~/install.sh ${repository_parameters} ${smtp_parameters} ${misc_parameters}"

    # run the remote command
    ssh "${remote_execution_target_user}@${remote_execution_server_target}" $remote_command
    exit_on_error "Could not execute the tools installer on the remote target: ${remote_execution_server_target} from '${HOSTNAME}' !" $ERROR_TOOLS_INSTALLER_FAILED $notification_email_subject $cluster_admin_email
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

if [[ $remote_mode == 0 ]];
then
    # at this point, we are on the jumpbox attempting to execute the installer on the remote target 

    # iterate all servers in the backend server list
    for server in "${backend_server_list[@]}"
    do
        # copy the bits
        copy_bits $server $target_user $current_path $ERROR_TOOLS_INSTALLER_FAILED $notification_email_subject $cluster_admin_email

        # execute the component deployment
        execute_remote_command $server $target_user
    done
fi

# execute on both local & remote sessions

# install tools
install-tools

# install mailer
install-mailer "${smtp_server}" "${smtp_server_port}" "${smtp_auth_user}" "${smtp_auth_user_password}" "${cluster_admin_email}"

log "Completed tools installation for ${HOSTNAME}" " " 2