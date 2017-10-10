#!/bin/bash
#
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

#
# This script enables Mobile Rest Api for LMS as well as OAUTH2 on a stamp cluster. These changes enable deep integration principally for Microsoft Professional Program (MPP).
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

# allow the user to specify which vmss instances to update. the expected value is the VMSS deployment id
vmss_deployment_id=""

# cloud being deployed
cloud="bvt"

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
          --vmss-deployment-id)
            vmss_deployment_id="${arg_value}"
            ;;
          --cloud)
            cloud="${arg_value}"
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
    # this call requires azure cli2

    # login
    results=`az login -u $aad_webclient_id --service-principal --tenant $aad_tenant_id -p $aad_webclient_appkey --output json`
    exit_on_error "Could not login to azure with the provided service principal credential from '${HOSTNAME}' !" "${error_mobilerestapi_update_failed}" "${notification_email_subject}" "${cluster_admin_email}"

    # select the appropriate subscription to set the execution context
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

    if [[ -z $cloud ]]; 
    then
        log "You must specify a target cloud for this deployment to ensure it cloud configuration gets updated"
        exit $error_mobilerestapi_update_failed
    fi

    log "Completed argument validation successfully"
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
    # This phase ONLY executes on the remote target

    # Conditionally install jq
    install-json-processor

    # Update the target lms environment file (setting to true if false or creating a new feature that is enabled)
    target_file="/edx/app/edxapp/lms.env.json"

    # backup the existing config file
    log "Backing up the configuration file: ${target_file}"
    cp $target_file{,.backup}

    # get an temporary copy & apply modifications
    temp_file=`mktemp "/tmp/lms.env.json.XXXXXXXXXX"`

    log "Enabling OAUTH2 & Mobile Rest Api"
    cat "${target_file}" | jq -r '.FEATURES.ENABLE_OAUTH2_PROVIDER |= true | .FEATURES.OAUTH_ENFORCE_SECURE |= true | .FEATURES.ENABLE_MOBILE_REST_API |= true' --indent 4 > $temp_file
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

    log "Sleeping ${wait_interval_seconds} seconds before moving to update the next server"
    sleep "${wait_interval_seconds}s"

    log "Updated ${HOSTNAME} successfully"
    exit
fi

# login
authenticate-azureuser

# List the VMSSs in the target cluster. 
# If the user specifies a VMSS filter (the deploymentId), list only that VMSS. Otherwise, list all VMSSs.
log "Getting the list of VMSS in the '${azure_resource_group}' resource group"
vmssIdsArray=(`az vmss list --resource-group ${azure_resource_group} | jq -r '.[] | .id'`)
exit_on_error "Could not get a list of the VMSSs in the '${azure_resource_group}' resource group from '${HOSTNAME}' !" "${error_mobilerestapi_update_failed}" "${notification_email_subject}" "${cluster_admin_email}"

vmssIdsList=""
for vmssId in "${vmssIdsArray[@]}";
do
    if [[ -z $vmss_deployment_id ]] || ( [[ -n $vmss_deployment_id ]] && [[ $vmssId == *"vmss-$vmss_deployment_id" ]] );
    then
        log "Adding ${vmssId}"

        # the user has specified a filter, apply it
        vmssIdsList="${vmssId} ${vmssIdsList}"
    fi
done

# Convert the list into an array for further processing
filteredVmssIdsArray=($vmssIdsList)

# Provide quick summary
log "${#vmssIdsArray[@]} VMSS(s) identified for processing. After optional filtering, ${#filteredVmssIdsArray[@]} VMSS(s) will be targeted for update"

# The structure of the response differ when multiple VMSSs are involved. Therefore, we have to account for that.
log "Listing all VM instances in the targeted VMSS(s)"
vmssInstanceList=`az vmss list-instances --resource-group ${azure_resource_group} --ids ${vmssIdsList}`
exit_on_error "Could not get a list of the VMs in the identified VMSSs' !" "${error_mobilerestapi_update_failed}" "${notification_email_subject}" "${cluster_admin_email}"

if [[ ${#filteredVmssIdsArray[@]} -gt 1 ]];
then
    vmssNicsArray=(`echo $vmssInstanceList | jq -r '.[][] .networkProfile.networkInterfaces[] .id'`)
else
    vmssNicsArray=(`echo $vmssInstanceList | jq -r '.[] .networkProfile.networkInterfaces[] .id'`)
fi
exit_on_error "Could not process the vmss instance list!" "${error_mobilerestapi_update_failed}" "${notification_email_subject}" "${cluster_admin_email}"

# The final list of Ip addresses associated with the VMs in the targeted VMSS(s).
vmssIpsMasterList=""

# Iterate all NICs only add unique value to the array
log "Getting all relevant VMSS nics"

for vmssNic in "${vmssNicsArray[@]}";
do
    vmssIpsList=`az vmss nic list --ids "${vmssNic}" | jq -r '.[] .ipConfigurations[] .privateIpAddress'`
    exit_on_error "Could not get a list of the IPs for the identified VMSSs' !" "${error_mobilerestapi_update_failed}" "${notification_email_subject}" "${cluster_admin_email}"

    # add to the master list
    vmssIpsMasterList="${vmssIpsMasterList} ${vmssIpsList}"
done

# The master list will have duplicates. Prune it.
vmssIpsArray=(`echo $vmssIpsMasterList | tr ' ' '\n' | sort -u`)
log "${#vmssIpsArray[@]} IP(s) discovered. Iterating each instance to enable the Mobile Rest Api."

# Iterate the vmss instances and enable mobile rest api
for vmssInstanceIp in "${vmssIpsArray[@]}";
do
    # Update the configs, recycle the services, pause (optional:1min)
    log "Updating ${vmssInstanceIp}"

    # Copy the bits
    copy_bits $vmssInstanceIp $target_user $current_path "${error_mobilerestapi_update_failed}" "${notification_email_subject}" "${cluster_admin_email}"

    # Execute the component deployment
    execute_remote_command $vmssInstanceIp $target_user
done

# Finally, persist the setting in keyvault
# We need to push the correctly updated cloud config back to keyvault
log "The targeted VMs have been updated successfully. Now updating keyvault settings"
cloud_config_basepath="/oxa/oxa-tools-config/env/${cloud}"
cloud_config_filepath="${cloud_config_basepath}/${cloud}.sh"

# check if the relevant settings are available or not and update them appropriately
mobile_rest_api_settings=(`echo "EDXAPP_ENABLE_OAUTH2_PROVIDER EDXAPP_ENABLE_MOBILE_REST_API OAUTH_ENFORCE_SECURE"`)
for setting in "${mobile_rest_api_settings[@]}";
do
    log "Processing '${setting}' setting"

    setting_regex="^${setting}=.*"
    setting_replacement="${setting}=true"

    setting_exists=`grep "${setting_regex}" "${cloud_config_filepath}"`

    if [[ -z $setting_exists ]];
    then
        # Setting doesn't exist. Add it
        log "Injecting new '${setting}' setting"
        echo "${setting_replacement}" >> $cloud_config_filepath
    else
        # Setting exists. Update it
        log "Updating existing value for '${setting}' setting"
        sed -i "s#${setting_regex}#${setting_replacement}#I" $cloud_config_filepath
    fi
done

log "Pushing the current settings to keyvault"
keyvault_name="${azure_resource_group}-kv"

# set the home path 
export HOME=~/

powershell -file "${oxa_tools_repository_path}/scripts/Process-OxaToolsKeyVaultConfiguration.ps1" -Operation "Upload" -VaultName "${keyvault_name}" -AadWebClientId "${aad_webclient_id}" -AadWebClientAppKey "${aad_webclient_appkey}" -AadTenantId "${aad_tenant_id}" -TargetPath "${cloud_config_basepath}" -AzureSubscriptionId "${azure_subscription_id}" -AzureCliVersion 2
exit_on_error "Failed downloading configurations from keyvault" 1 "${MAIL_SUBJECT} Failed" $CLUSTER_ADMIN_EMAIL $PRIMARY_LOG $SECONDARY_LOG

log "Completed the enabling of Mobile Rest Api ${target_user}"