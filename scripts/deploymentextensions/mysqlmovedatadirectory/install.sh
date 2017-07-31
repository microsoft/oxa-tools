#!/bin/bash
#
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

#
# This script moves the data partition for a Mysql instance
#

# Oxa Tools
# Settings for the OXA-Tools public repository 
oxa_tools_public_github_account="Microsoft"
oxa_tools_public_github_projectname="oxa-tools"
oxa_tools_public_github_projectbranch="oxa/master.fic"
oxa_tools_public_github_branchtag=""
oxa_tools_repository_path="/oxa/oxa-tools"

# Initialize required parameters

# admin user for OS
os_admin_user=""

# the server being re-configured
target_server_ip=""
mysql_server_port="3306"
mysql_admin_username=""
mysql_admin_password=""

# new location for the mysql data
target_datadirectory_path=/datadirectory/disk1/mysql

# operation mode: 0=local, 1=remote via ssh
remote_mode=0

# Email Notifications
notification_email_subject="Move Mysql Data Directory"
admin_email_address=""

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
        echo "Option '${1}' set with value '"${arg_value}"'"

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
          --admin-email-address)
            admin_email_address="${arg_value}"
            ;;
          --target-datadirectory-path)
            target_datadirectory_path="${arg_value}"
            ;;
          --mysql-server-port)
            mysql_server_port="${arg_value}"
            ;;
          --mysql-admin-username)
            mysql_admin_username="${arg_value}"
            ;;
          --mysql-admin-password)
            mysql_admin_password="${arg_value}"
            ;;
          --target-server-ip)
            target_server_ip="${arg_value}"
            ;;
          --os-admin-user)
            os_admin_user="${arg_value}"
            ;;
          --remote)
            remote_mode=1
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
print_script_header "Move Mysql Data Directory"

# pass existing command line arguments
parse_args $@

# sync the oxa-tools repository
repo_url=`get_github_url "$oxa_tools_public_github_account" "$oxa_tools_public_github_projectname"`
sync_repo $repo_url $oxa_tools_public_github_projectbranch $oxa_tools_repository_path $access_token $oxa_tools_public_github_branchtag

# execute the installer remote
if [[ $remote_mode == 0 ]];
then
    # at this point, we are on the jumpbox attempting to execute the installer on the remote target 
    log "Copying scripts to target server '$target_server_ip'"

    # copy the installer & the utilities files to the target server & ssh/execute the Operations
    scp  -o "StrictHostKeyChecking=no" "${current_path}/install.sh" $os_admin_user@$target_server_ip:~/
    exit_on_error "Unable to copy installer script to '${target_server}' from '${HOSTNAME}' !" $ERROR_HAPROXY_INSTALLER_FAILED, $notification_email_subject $admin_email_address

    scp -o "StrictHostKeyChecking=no" "${current_path}/utilities.sh" $os_admin_user@$target_server_ip:~/
    exit_on_error "Unable to copy utilities to '${target_server}' from '${HOSTNAME}' !" $ERROR_HAPROXY_INSTALLER_FAILED, $notification_email_subject $admin_email_address

    # build the command for remote execution
    $encoded_server_list=`echo ${mysql_server_list} | base64`
    remote_command="su -c ""bash ~/install.sh --oxatools-public-github-accountname $oxa_tools_public_github_account --oxatools-public-github-projectname $oxa_tools_public_github_projectname --oxatools-public-github-projectbranch $oxa_tools_public_github_projectbranch --oxatools-public-github-branchtag $oxa_tools_public_github_branchtag --oxatools-repository-path $oxa_tools_repository_path --admin-email-address $admin_email_address --target-datadirectory-path $target_datadirectory_path --mysql-server-port $mysql_server_port --mysql-admin-username $mysql_admin_username --mysql-admin-password $mysql_admin_password --target-server-ip $target_server_ip  --remote"" root "

    # run the remote command
    log "Executing '${remote_command}' against ${target_server_ip}"

    ssh -o "StrictHostKeyChecking=no" "${os_admin_user}@${target_server_ip}" "${remote_command}"
    exit_on_error "Could not execute the installer on the remote target: ${target_server_ip} from '${HOSTNAME}' !" $ERROR_HAPROXY_INSTALLER_FAILED, $notification_email_subject $admin_email_address

    log "Completed Remote execution successfully"
    exit
fi

#############################################
# Main Operations
# this should run on the target server
#############################################

log "Starting main execution (remote exection mode)"

# run the move operation
move_mysql_datadirectory "${target_datadirectory_path}" "${admin_email_address}" "${mysql_admin_username}" "${mysql_admin_password}" "${target_server_ip}" "${mysql_server_port}"
exit_on_error "Unable move the data directory for '${HOSTNAME}' !" $ERROR_MYSQL_DATADIRECTORY_MOVE_FAILED "${notification_email_subject}" $admin_email_address

log "Completed move of mysql data directory on '${target_server_ip}' successfully."