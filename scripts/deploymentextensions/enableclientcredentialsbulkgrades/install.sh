#!/bin/bash
#
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

#
# The Script enables client credentials & Bulk Grades on Ficus for existing clusters.
# These changes enable Microsoft to get additional learner data for reporting purposes.
# 
# Important:
# Before running the deployment extension, please confirm the following:
# You have deployed Open edX using Microsoft STAMP ARM template; which is running Ficus X.X version of Open edX avaliable from http://github.com/microsoft/edx-platform oxa/master.fic branch
# 
# Please do not run this extension, if you NOT using Microsoft STAMP ARM Template.

# Oxa Tools
# Settings for the OXA-Tools public repository
oxa_tools_public_github_account="Microsoft"
oxa_tools_public_github_projectname="oxa-tools"
oxa_tools_public_github_projectbranch="oxa/master.fic"
oxa_tools_public_github_branchtag=""
oxa_tools_repository_path="/oxa/oxa-tools"

# settings for the edx-platform public repository 
edx_platform_public_github_accountname="Microsoft"
edx_platform_public_github_projectname="edx-platform"
edx_platform_public_github_projectbranch="oxa/master.fic"
edx_platform_public_github_branchtag=""
edx_platform_temp_repository_path="/tmp/edx-platform"

# location of the current application code files
local_edx_platform_base_path="/edx/app/edxapp/edx-platform"

# Azure Subscription 
aad_webclient_id=""
aad_webclient_appkey=""
aad_tenant_id=""
azure_subscription_id=""
azure_resource_group=""

# Email Notifications
notification_email_subject="Enable Client Credentials & Bulk Grades"
cluster_admin_email=""

# this is the user account that will be used for ssh
target_user=""

# operation mode: 0=local, 1=remote via ssh
remote_mode=0

# debug mode: 0=set +x, 1=set -x
debug_mode=0

# error code associated with this deployment extension
error_ccbg_update_failed=30001

# wait period between recycling of instances
wait_interval_seconds=10

# allow the user to specify which vmss instances to update. the expected value is the VMSS deployment id
vmss_deployment_id=""

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

          --edxplatform-public-github-accountname)
            edx_platform_public_github_accountname="${arg_value}"
            ;;
          --edxplatform-public-github-projectname)
            edx_platform_public_github_projectname="${arg_value}"
            ;;
          --edxplatform-public-github-projectbranch)
            edx_platform_public_github_projectbranch="${arg_value}"
            ;;
          --edxplatform-public-github-branchtag)
            edx_platform_public_github_branchtag="${arg_value}"
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
          --vmss-deployment-id)
            vmss_deployment_id="${arg_value}"
            ;;
          --remote)
            remote_mode=1
            ;;
          --debug)
            debug_mode=1
            ;;
        esac

        shift # past argument or value

        if [[ $shift_once -eq 0 ]]; 
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

    # edx-platform repo parameters
    edx_platform_repository_parameters="--edxplatform-public-github-accountname ""${edx_platform_public_github_accountname}"""
    edx_platform_repository_parameters+=" --edxplatform-public-github-projectname ""${edx_platform_public_github_projectname}"""
    edx_platform_repository_parameters+=" --edxplatform-public-github-projectbranch ""${edx_platform_public_github_projectbranch}"""
    edx_platform_repository_parameters+=" --edxplatform-public-github-branchtag ""${edx_platform_public_github_branchtag}"""

    # conditionally enable debug mode over the remote session
    if [[ $debug_mode == 1 ]];
    then
        misc_parameters+=" --debug"
    fi

    remote_command="sudo bash ~/install.sh ${repository_parameters} ${edx_platform_repository_parameters} ${aad_parameters} ${azure_subscription_parameters} ${misc_parameters}"

    # run the remote command
    ssh "${remote_execution_target_user}@${remote_execution_server_target}" $remote_command
    exit_on_error "Could not execute the tools installer on the remote target: ${remote_execution_server_target} from '${HOSTNAME}' !" "${error_ccbg_update_failed}" "${notification_email_subject}" "${cluster_admin_email}"
}

validate_args()
{
    log "Validating arguments"

    # target user
    if [[ -z $target_user ]]; 
    then
        log "You must specify a user account to use for SSH to remote servers"
        exit $error_ccbg_update_failed
    fi

    if [[ -z $aad_webclient_id ]] || [[ -z $aad_webclient_appkey ]] || [[ -z $aad_tenant_id ]]; 
    then
        log "You must specify a valid credential for your azure subscription authentication. You need the AAD Webclient Id, Webclient Key and AAD tenant id"
        exit $error_ccbg_update_failed
    fi

    if [[ -z $azure_subscription_id ]] || [[ -z $azure_resource_group ]]; 
    then
        log "You must specify a valid Azure Subscription Id and Resource group representing the stamp cluster."
        exit $error_ccbg_update_failed
    fi

    log "Completed argument validation successfully"
}

copy_files()
{
    source_file="${1}"
    destination_file="${2}"

    log "Copying '${source_file}' to '${destination_file}'"
    cp -R "${source_file}" "${destination_file}"
    exit_on_error "Could not copy '${source_file}' to '${destination_file}' on ${HOSTNAME}!" "${error_ccbg_update_failed}" "${notification_email_subject}" "${cluster_admin_email}"
}

update_permissions()
{
    file_path="${1}"
    add_execute_permission="${2}"

    # setting permission for edxapp usage
    if [[ -z "${add_execute_permission}" ]]; then
        chmod -R 644 "${file_path}"
    else
        chmod 755 "${file_path}"
    fi

    exit_on_error "Could not change permissions on '${file_path}' on ${HOSTNAME}!" "${error_ccbg_update_failed}" "${notification_email_subject}" "${cluster_admin_email}"

    chown -R edxapp:edxapp "${file_path}"
    exit_on_error "Could not change ownership to 'edxapp:edxapp' on '${file_path}' on ${HOSTNAME}!" "${error_ccbg_update_failed}" "${notification_email_subject}" "${cluster_admin_email}"
}

check_service_runtime()
{
    # Check a service runtime
    
    # input parameter
    target_service="${1:-edxapp:lms}"

    uptime=0
    service_status_file="/tmp/service_status.log"
    sudo /edx/bin/supervisorctl status > $service_status_file   

    while read program_status_line; do

        # All services are starting at the same time
        # The uptime of one service should suffice for them all.

        # Switch to array for procesing
        program_status_data=($program_status_line)

        # there is a known pattern to the service status
        program_name="${program_status_data[0]}"
        program_status="${program_status_data[1]}"
        program_uptime="${program_status_data[5]}"

        IFS=: read hours minutes seconds <<< "${program_uptime}"
        uptime=$(( 10#$hours * 3600 + 10#$minutes * 60 + 10#$seconds ))

        # one record should suffice (picking lms by default)
        if [[ "${program_name,,}" == "${target_service,,}" ]]; then
            
            # the collected uptime is only useful if the service is running
            if [[ "${program_status,,}" != "running" ]]; then
                # reset the uptime (defensive)
                uptime=0
            fi

            break
        fi

    done < "${service_status_file}"

    echo $uptime
}

###############################################
# START CORE EXECUTION
###############################################

# Source our utilities for logging and other base functions (we need this staged with the installer script)
# The file needs to be first downloaded from the public repository
current_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
utilities_path=$current_path/utilities.sh

# check if the utilities file exists. If not, bail out.
if [[ ! -e $utilities_path ]]; 
then  
    echo :"Utilities not present"
    exit 3
fi

# Source the utilities
source $utilities_path

# Script self-identification
print_script_header "${notification_email_subject}"

# Parse existing command line arguments & run quick validation
parse_args $@
validate_args

# Enable debug mode (if requested)
if [[ $debug_mode == 1 ]];
then
    set -x
fi

# Sync the oxa-tools repository (with tag support)
repo_url=`get_github_url "$oxa_tools_public_github_account" "$oxa_tools_public_github_projectname"`
sync_repo $repo_url $oxa_tools_public_github_projectbranch $oxa_tools_repository_path $access_token $oxa_tools_public_github_branchtag
log "Repository sync is complete" " " 2

####################################
# Main Operations
####################################

if [[ $remote_mode == 1 ]];
then

    # make sure BC is available
    install-bc

    # This phase ONLY executes on the remote target

    ################################
    # Action
    # 1. clone the edx-platform repo
    # 2. copy the relevant files from the cloned edx-platform source to the local edx-platform path (/edx/app/edxapp/edx-platform):
    #       lms/djangoapps/grades/api/v1 (folder and all files)
    #       common/djangoapps/enrollment/data.py
    #       common/djangoapps/enrollment/tests/test_data.py  
    #       lms/djangoapps/courseware/exceptions.py
    #       openedx/core/djangoapps/oauth_dispatch/dot_overrides.py
    #       openedx/core/djangoapps/oauth_dispatch/tests/test_dot_adapter.py
    #       openedx/core/djangoapps/oauth_dispatch/tests/test_views.py
    # 3. restart the services & check status

    # Conditionally remove any existing folder reference
    if [[ -d "${edx_platform_temp_repository_path}" ]]; then
        log "Removing existing temp folder at ${edx_platform_temp_repository_path}..."
        rm -rf ${edx_platform_temp_repository_path}
    fi

    # 1. clone the edx-platform repo
    repo_url=`get_github_url "$edx_platform_public_github_accountname" "$edx_platform_public_github_projectname"`
    sync_repo "${repo_url}" "${edx_platform_public_github_projectbranch}" "${edx_platform_temp_repository_path}" "${access_token}" "${edx_platform_public_github_branchtag}"
    log "Repository sync is complete" " " 2

    # 2. Copy the relevant files
    log "Copying files to application at '${local_edx_platform_base_path}'"

    # Copy: Grades v1 files
    source_relative_path="lms/djangoapps/grades/api"
    source_file="${edx_platform_temp_repository_path}/${source_relative_path}/v1"
    destination_file="${local_edx_platform_base_path}/${source_relative_path}"

    log "Copying grades v1 files"
    copy_files "${source_file}" "${destination_file}"
    update_permissions "${local_edx_platform_base_path}/${source_relative_path}/v1" "1"
    update_permissions "${local_edx_platform_base_path}/${source_relative_path}/v1/tests" "1"
    
    # Copy: Supporting files
    support_files="lms/djangoapps/grades/api/urls.py common/djangoapps/enrollment/data.py common/djangoapps/enrollment/tests/test_data.py"
    support_files="${support_files} lms/djangoapps/courseware/exceptions.py openedx/core/djangoapps/oauth_dispatch/dot_overrides.py"
    support_files="${support_files} openedx/core/djangoapps/oauth_dispatch/tests/test_dot_adapter.py openedx/core/djangoapps/oauth_dispatch/tests/test_views.py"

    supporting_files_list=($support_files)
    for supporting_file in "${supporting_files_list[@]}";
    do
        source_file="${edx_platform_temp_repository_path}/${supporting_file}"
        destination_file="${local_edx_platform_base_path}/${supporting_file}"

        copy_files "${source_file}" "${destination_file}"
        update_permissions "${destination_file}"
    done
    
    # 3. Restart services & check status
    log "Restarting services on ${HOSTNAME}"
    /edx/bin/supervisorctl restart all
    exit_on_error "Could not restart all services on ${HOSTNAME}!" "${error_ccbg_update_failed}" "${notification_email_subject}" "${cluster_admin_email}"

    log "Sleeping ${wait_interval_seconds} seconds before moving to update the next server"
    sleep "${wait_interval_seconds}s"

    # Perform sanity check
    # Check the service status and make sure the uptime is incrementing (suggesting service stability)
    target_service="edxapp:lms"
    service_uptime_1=`check_service_runtime "${target_service}"`
    log "Iteration 1: Service uptime for '${target_service}' is ${service_uptime_1}secs. Sleeping for ${wait_interval_seconds}secs..."

    sleep "${wait_interval_seconds}s"
    service_uptime_2=`check_service_runtime "${target_service}"`
    log "Iteration 2: Service uptime for '${target_service}' is ${service_uptime_2}secs"
    
    uptime_increased=`echo "($service_uptime_2 - $service_uptime_1) > 0" | bc`
    if [[ $uptime_increased ]]; then
        log "It appears the uptime for '${target_service}' is increasing."
    else
        log "It appears the uptime for '${target_service}' is not increasing."
        exit 1
    fi

    log "Updated ${HOSTNAME} successfully"

    # Cleanup
    log "Cleaning up the temporary files"
    rm -rf ${edx_platform_temp_repository_path}
    exit
fi

# login
authenticate-azureuser "${aad_webclient_id}" "${aad_tenant_id}" "${aad_webclient_appkey}" "${cluster_admin_email}" "${azure_subscription_id}"

# List the VMSSs in the target cluster. 
# If the user specifies a VMSS filter (the deploymentId), list only that VMSS. Otherwise, list all VMSSs.
log "Getting the list of VMSS in the '${azure_resource_group}' resource group"
vmss_instances_ips=$(get-cluster-vmss-instances-ips "${azure_resource_group}" "${vmss_deployment_id}" "${cluster_admin_email}")
exit_on_error "Could not get a list of the VMSSs in the '${azure_resource_group}' resource group from '${HOSTNAME}' !" "${error_ccbg_update_failed}" "${notification_email_subject}" "${cluster_admin_email}"

vmss_instances_ips_array=($vmss_instances_ips)

# Iterate the vmss instances and enable mobile rest api
for vmss_instance_ip in "${vmss_instances_ips_array[@]}";
do
    # Update the configs, recycle the services, pause (optional:1min)
    log "Updating ${vmss_instance_ip}"

    # Copy the bits
    copy_bits $vmss_instance_ip $target_user $current_path "${error_ccbg_update_failed}" "${notification_email_subject}" "${cluster_admin_email}"

    # Execute the component deployment
    execute_remote_command $vmss_instance_ip $target_user
done

log "Completed the enabling of Client Credentials & Bulk Grades Api for ${azure_resource_group}"