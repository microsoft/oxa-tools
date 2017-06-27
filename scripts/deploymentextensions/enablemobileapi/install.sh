#!/bin/bash
#
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

#
# This script enables Mobile Rest Api for LMS as well as OAUTH2 on a stamp cluster. These changes enable deep integration for Microsoft Professional Program (MPP).
#

# Oxa Tools
# Settings for the OXA-Tools public repository 
oxa_tools_public_github_account="Microsoft"
oxa_tools_public_github_projectname="oxa-tools"
oxa_tools_public_github_projectbranch="oxa/master.fic"
oxa_tools_public_github_branchtag=""
oxa_tools_repository_path="/oxa/oxa-tools"

# Azure Subscription 
aad_webclient_id=""
aad_webclient_appkey=""
aad_tenant_id=""
azure_subscription_id=""
azure_resource_group=""

# Email Notifications
notification_email_subject="Enable Mobile Rest Api"
cluster_admin_email=""

# this is the user account that will be used for ssh
target_user=""

# operation mode: 0=local, 1=remote via ssh
remote_mode=0

# debug mode: 0=set +x, 1=set -x
debug_mode=0

# error code associated with this deployment extension
error_mobilerestapi_update_failed=20001

# wait period between recycling of instances
wait_interval_seconds=10

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
          --aad-webclient-id)
            aad_webclient_id="${arg_value}"
            ;;
          --aad-webclient-appkey)
            aad_webclient_appkey="${arg_value}"
            ;;
          --aad-tenant-id)
            aad_tenant_id="${arg_value}"
            ;;
          --azure-subscription-id)
            azure_subscription_id="${arg_value}"
            ;;
          --azure-resource-group)
            azure_resource_group="${arg_value}"
            ;;
          --wait-interval-seconds)
            wait_interval_seconds="${arg_value}"
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

execute_remote_command()
{
    remote_execution_server_target=$1
    remote_execution_target_user=$2

    # build the command for remote execution (basically: pass through all existing parameters)
    repository_parameters="--oxatools-public-github-accountname ""${oxa_tools_public_github_account}"" --oxatools-public-github-projectname ""${oxa_tools_public_github_projectname}"" --oxatools-public-github-projectbranch ""${oxa_tools_public_github_projectbranch}"" --oxatools-public-github-branchtag ""${oxa_tools_public_github_branchtag}"" --oxatools-repository-path ""${oxa_tools_repository_path}"""
    aad_parameters="--aad-webclient-id ""${aad_webclient_id}"" --aad-webclient-appkey ""${aad_webclient_appkey}"" --aad-tenant-id ""${aad_tenant_id}"""
    azure_subscription_parameters="--azure-subscription-id ""${azure_subscription_id}"" --azure-resource-group ""${azure_resource_group}"""
    misc_parameters="--cluster-admin-email ""${cluster_admin_email}"" --target-user ""${target_user}"" --remote"

    # conditionally enable debug mode over the remote session
    if [[ $debug_mode == 1 ]];
    then
        misc_parameters+=" --debug"
    fi

    remote_command="sudo bash ~/install.sh ${repository_parameters} ${aad_parameters} ${azure_subscription_parameters} ${misc_parameters}"

    # run the remote command
    ssh "${remote_execution_target_user}@${remote_execution_server_target}" $remote_command
    exit_on_error "Could not execute the tools installer on the remote target: ${remote_execution_server_target} from '${HOSTNAME}' !" "${error_mobilerestapi_update_failed}" "${notification_email_subject}" "${cluster_admin_email}"
}

authenticate-azureuser()
{
    # requires azure cli2
    # login
    results=`az login -u $aad_webclient_id --service-principal --tenant $aad_tenant_id -p $aad_webclient_appkey --output json`
    exit_on_error "Could not login to azure with the provided service principal credential from '${HOSTNAME}' !" "${error_mobilerestapi_update_failed}" "${notification_email_subject}" "${cluster_admin_email}"

    # select the appropriate subscription
    az account set --subscription "${azure_subscription_id}"
    exit_on_error "Could not set the azure subscription context to ${azure_subscription_id} from '${HOSTNAME}' !" "${error_mobilerestapi_update_failed}" "${notification_email_subject}" "${cluster_admin_email}"
}

validate_args()
{
    log "Validating arguments"

    # target user
    if [[ -z $target_user ]]; 
    then
        log "You must specify a user account to use for SSH to remote servers"
        exit $error_mobilerestapi_update_failed
    fi

    if [[ -z $aad_webclient_id ]] || [[ -z $aad_webclient_appkey ]] || [[ -z $aad_tenant_id ]]; 
    then
        log "You must specify a valid credential for your azure subscription authentication. You need the AAD Webclient Id, Webclient Key and AAD tenant id"
        exit $error_mobilerestapi_update_failed
    fi

    if [[ -z $azure_subscription_id ]] || [[ -z $azure_resource_group ]]; 
    then
        log "You must specify a valid Azure Subscription Id and Resource group representing the stamp cluster."
        exit $error_mobilerestapi_update_failed
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

if [[ $remote_mode == 1 ]];
then
    # this phase ONLY executes on the remote target

    # make sure we have jq installed 
    install-json-processor

    # update the target file (setting to true if false or creating a new feature that is enabled)
    target_file="/edx/app/edxapp/lms.env.json"

    # backup the existing config file
    log "Backing up the configuration file: ${target_file}"
    cp $target_file{,.backup}

    # get an temporary copy & apply modifications
    temp_file=`mktemp "/tmp/lms.env.json.XXXXXXXXXX"`

    log "Enabling OAUTH2 & Mobile Rest Api"
    cat "${target_file}" | jq -r ".FEATURES.ENABLE_OAUTH2_PROVIDER |= true | .FEATURES.ENABLE_MOBILE_REST_API |= true" --indent 4 > $temp_file
    exit_on_error "Could not enable oauth2 & mobile rest api on ${HOSTNAME}!" "${error_mobilerestapi_update_failed}" "${notification_email_subject}" "${cluster_admin_email}"

    # move the temporary copy as the new target file
    log "Moving the updated configuration file from '${temp_file}' to '${target_file}'"
    cp $temp_file $target_file

    # make sure the permissions remain in tact
    chown edxapp:www-data "${target_file}"
    chmod 644 "${target_file}"

    # restart the services
    log "Restarting services on ${HOSTNAME}"
    /edx/bin/supervisorctl restart all
    exit_on_error "Could not restart all services on ${HOSTNAME}!" "${error_mobilerestapi_update_failed}" "${notification_email_subject}" "${cluster_admin_email}"

    sleep "${wait_interval_seconds}s"

    log "Updated ${HOSTNAME} successfully"
    exit
fi

# login
authenticate-azureuser

# list of all vmss in cluster
# TODO: limit this to the one actively serving traffic
log "Getting the list of VMSS in the '${azure_resource_group}' resource group"
vmssIds=`az vmss list --resource-group ${azure_resource_group} | jq ".[] | .id" -r`
exit_on_error "Could not get a list of the VMSSs in the '${azure_resource_group}' resource group from '${HOSTNAME}' !" "${error_mobilerestapi_update_failed}" "${notification_email_subject}" "${cluster_admin_email}"

# TODO: validate against cluster with multiple VMSSs
log "Listing all vmss instances in the identified VMSSs"
vmssNics=`az vmss list-instances --resource-group ${azure_resource_group} --ids ${vmssIds} | jq ".[] .networkProfile.networkInterfaces[] .id" -r`
exit_on_error "Could not get a list of the VMs in the identified VMSSs' !" "${error_mobilerestapi_update_failed}" "${notification_email_subject}" "${cluster_admin_email}"

# for the next step, we only need one NIC reference to the VMSS to get all. We are using the first one here.
vmssNicsArray=($vmssNics)

# Get the IPs
log "Getting all VMSS nics, keying off the first nic: ${vmssNicsArray[0]}"
vmssIps=`az vmss nic list --ids "${vmssNicsArray[0]}" | jq ".[] .ipConfigurations[] .privateIpAddress" -r`
exit_on_error "Could not get a list of the IPs for the identified VMSSs' !" "${error_mobilerestapi_update_failed}" "${notification_email_subject}" "${cluster_admin_email}"

vmssIpsArray=($vmssIps)
log "${#vmssIpsArray[@]} IP(s) identified. Iterating each instance to enable the Mobile Rest Api"

# Iterate the vmss intances and enable mobile rest api
for vmssInstanceIp in "${vmssIpsArray[@]}"
do
    # Update the configs, recycle the services, pause (optional:1min)
    log "Updating ${vmssInstanceIp}"

    # copy the bits
    copy_bits $vmssInstanceIp $target_user $current_path "${error_mobilerestapi_update_failed}" "${notification_email_subject}" "${cluster_admin_email}"

    # execute the component deployment
    execute_remote_command $vmssInstanceIp $target_user
done

log "Completed the enabling of Mobile Rest Api ${target_user}"