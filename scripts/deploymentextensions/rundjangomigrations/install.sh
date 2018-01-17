#!/bin/bash
#
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

# Whenever we edit a `models.py` class we need to create and run a django migration to 
# sync these model changes to the database.
# This script provides a way to run django migrations one application at a time.
#
# This script DOES NOT create migrations, 
# those need to be created first and checked in to edx-platform. 
# This script will just run the `manage.py migrate` command for the specified target_django_application
#
# Example script that will be run on a VMSS:
#
# python /edx/app/edxapp/edx-platform/manage.py lms migrate courseware --settings=aws --noinput
#
# This will run any new migrations for the courseware app in the LMS


# Oxa Tools
# Settings for the OXA-Tools public repository 
oxa_tools_public_github_account="Microsoft"
oxa_tools_public_github_projectname="oxa-tools"
oxa_tools_public_github_projectbranch="oxa/migrations-extension"
oxa_tools_public_github_branchtag=""
oxa_tools_repository_path="/oxa/oxa-tools"

# admin user for OS
target_user=""
target_server_ip=""

# Email Notifications
notification_email_subject="Running Django Migrations"
cluster_admin_email=""

# Can be (lms|cms)
target_edx_system=""

# The django application to make and run migrations for
# This is the name of the app in INSTALLED_APPS for the target_edx_system
target_django_application=""

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
          --target-server-ip)
            target_server_ip="${arg_value}"
            ;;
          --target-user)
            target_user="${arg_value}"
            ;;          
          --cluster-admin-email)
            cluster_admin_email="${arg_value}"
            ;;
          --target-edx-system)
            target_edx_system="${arg_value}"
            ;;
          --target-django-application)
            target_django_application="${arg_value}"
            ;;
          --remote)
            remote_mode=1
            ;;
          --debug)
            debug_mode=1
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

    # target user (only if local)
    if [[ -z $target_user ]] && [[ $remote_mode == 0 ]];
    then
        log "You must specify a user account to use for SSH to remote servers"
        exit $ERROR_DJANGO_MIGRATIONS_FAILED
    fi

    # Target server
    if [[ -z $target_server_ip ]] ;
    then
        log "You must specify a server whose data directory we want to move"
        exit $ERROR_DJANGO_MIGRATIONS_FAILED
    fi

    # cluster admin email (for notification purposes)
    if [[ -z $cluster_admin_email ]]; 
    then
        log "You must specify the cluster admininstrator email address for notification purposes"
        exit $ERROR_DJANGO_MIGRATIONS_FAILED
    fi

    if [[ -z $target_edx_system ]]; 
    then
        log "You must specify the edx_system as either 'lms' or 'cms'"
        exit $ERROR_DJANGO_MIGRATIONS_FAILED
    fi

    if [[ -z $target_django_application ]]; 
    then
        log "You can only run migrations for a specific application. Specify django_application"
        exit $ERROR_DJANGO_MIGRATIONS_FAILED
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

# execute the installer remote
if [[ $remote_mode == 0 ]];
then
    # at this point, we are on the jumpbox attempting to execute the installer on the remote target 
    log "Copying scripts to target server '$target_server_ip'"

    # copy the installer & the utilities files to the target server & ssh/execute the Operations
    scp  -o "StrictHostKeyChecking=no" "${current_path}/install.sh" $target_user@$target_server_ip:~/
    exit_on_error "Unable to copy installer script to '${target_server}' from '${HOSTNAME}' !" "${ERROR_DJANGO_MIGRATIONS_FAILED}" "${notification_email_subject}" "${cluster_admin_email}"

    scp -o "StrictHostKeyChecking=no" "${current_path}/utilities.sh" $target_user@$target_server_ip:~/
    exit_on_error "Unable to copy utilities to '${target_server}' from '${HOSTNAME}' !" "${ERROR_DJANGO_MIGRATIONS_FAILED}" "${notification_email_subject}" "${cluster_admin_email}"

    # build the command for remote execution (basically: pass through all existing parameters)
    repository_parameters="--oxatools-public-github-accountname ${oxa_tools_public_github_account} --oxatools-public-github-projectname ${oxa_tools_public_github_projectname} --oxatools-public-github-projectbranch ${oxa_tools_public_github_projectbranch} --oxatools-public-github-branchtag ${oxa_tools_public_github_branchtag} --oxatools-repository-path ${oxa_tools_repository_path}"
    misc_parameters="--cluster-admin-email ${cluster_admin_email} --target-edx-system ${target_edx_system} --target-django-application ${target_django_application} --target-server-ip ${target_server_ip} --remote"
    
    if [[ $debug_mode == 1 ]];
    then
        misc_parameters="${misc_parameters} --debug"
    fi

    remote_command="sudo bash ~/install.sh ${repository_parameters} ${misc_parameters}"

    # run the remote command
    log "Executing '${remote_command}' against ${target_server_ip}"

    ssh -o "StrictHostKeyChecking=no" "${target_user}@${target_server_ip}" "${remote_command}"
    exit_on_error "Could not execute the installer on the remote target: ${target_server_ip} from '${HOSTNAME}' !" "${ERROR_DJANGO_MIGRATIONS_FAILED}" "${notification_email_subject}" "${cluster_admin_email}"

    log "Completed Remote execution successfully"
    exit
fi

#############################################
# Main Operations
# this should run on the target server
#############################################

log "Starting main execution (remote exection mode)"

# Run migrations for the target django_application
/edx/app/edxapp/venvs/edxapp/bin/python /edx/app/edxapp/edx-platform/manage.py ${target_edx_system} migrate ${target_django_application} --settings=aws --noinput

# TODO: Pull this out into a utility function/deployment extension that restarts 
#       all VMs in the VMSS frontend 
/edx/bin/supervisorctl restart all
exit_on_error "Unable run migrations '${HOSTNAME}' !" "${ERROR_DJANGO_MIGRATIONS_FAILED}" "${notification_email_subject}" "${cluster_admin_email}"

log "Completed running django migrations for: '${target_django_application}' on server: '${target_server_ip}' successfully."