#!/bin/bash
#
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

# This scripts installs the OMS or DataDog Agent on the target Ubuntu VM

OMS_WORKSPACEID=""
PRIMARY_KEY=""
AGENT_TYPE=""

MAIL_SUBJECT="OXA Monitoring -"
PRIMARY_LOG="/var/log/bootstrap.csx.log"

help()
{
    echo "This script sets up SSH, installs MDSD and runs the DB bootstrap"
    echo "Options:"
    echo "        --oms-workspaceid         OMS Workspace ID (see https://docs.microsoft.com/en-us/azure/log-analytics/log-analytics-linux-agents for details)"
    echo "        --primary-key             OMS/Datadog Primary API key (see https://docs.microsoft.com/en-us/azure/log-analytics/log-analytics-linux-agents for details on OMS or https://app.datadoghq.com/account/settings#api for data dog)"
    echo "        --agent-type              oms|datadog"
    echo "        --cluster-admin-email     Email address of the administrator where system and other notifications will be sent"
    echo "        --log                     path to installation log file (if necessary, this file will be emailed to the admin for debugging purposes"
    exit 1
}

# Parse script parameters
parse_args()
{
    while [[ "$#" -gt 0 ]]
        do

         # Log input parameters to facilitate troubleshooting
        echo "Option '$1' set with value '$2'"

        case "$1" in
            --oms-workspaceid)
                OMS_WORKSPACEID=$2
                ;;
            --primary-key)
                PRIMARY_KEY=$2
                ;;
            --agent-type)
                AGENT_TYPE="${2,,}" # convert to lowercase
                if ! is_valid_arg "oms datadog" $AGENT_TYPE; then
                  echo "Invalid agent type specified\n"
                  help
                fi
                ;;
            --cluster-admin-email)
                CLUSTER_ADMIN_EMAIL="$2"
                ;;
            --log)
                PRIMARY_LOG=$2
                ;;
            -h|--help)  # Helpful hints
                help
                exit 2
                ;;
            *) # unknown option
                echo "Option '${BOLD}$1${NORM} $2' not allowed."
                help
                exit 2
                ;;
        esac

        shift # past argument or value
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

# parse script arguments
parse_args $@ 

# Validate parameters
if [ "$AGENT_TYPE" == "" ] || [ "$PRIMARY_KEY" == "" ] ;
then
    log "Agent type and primary key must be specified"
    exit 3
fi

if [ "$AGENT_TYPE" == "oms" ] && [ "$OMS_WORKSPACEID" == "" ] ;
then
    log "You must specify the OMS Workspace ID"
    exit 3
fi


# Script self-idenfitication
print_script_header

###############################################
# START CORE EXECUTION
###############################################

NOTIFICATION_MESSAGE="Installation of '${AGENT_TYPE^^}' Agent on '${HOSTNAME}'"

case "$AGENT_TYPE" in
  oms)
    wget https://raw.githubusercontent.com/Microsoft/OMS-Agent-for-Linux/master/installer/scripts/onboard_agent.sh && sh onboard_agent.sh -w $OMS_WORKSPACEID -s $PRIMARY_KEY
    ;;
  datadog)
    DD_API_KEY=$PRIMARY_KEY bash -c "$(curl -L https://raw.githubusercontent.com/DataDog/dd-agent/master/packaging/datadog-agent/source/install_agent.sh)"
    ;;
esac

# check status of the deployment
exit_on_error "${NOTIFICATION_MESSAGE} failed!" 1 "${MAIL_SUBJECT}" "${CLUSTER_ADMIN_EMAIL}" "${PRIMARY_LOG}"

# at this point, the installation has suceeded
log "${NOTIFICATION_MESSAGE} completed successfully."
send_notification "${NOTIFICATION_MESSAGE}" "${MAIL_SUBJECT}" "${CLUSTER_ADMIN_EMAIL}"