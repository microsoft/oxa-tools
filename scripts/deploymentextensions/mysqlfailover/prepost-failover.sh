#!/bin/bash
#
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

#
# This script is intended to be executed before & after a mysql server failover (async replication topology)
#
# In the 'prefailover' mode, this script marks all servers participating in the replication network as Read-Only 
# and prevents writing to the wrong master during and after a failover (before the probe detects the new master)
#
# In the 'postfailover' mode, this script marks only the specified master as Read-Write in support of normal
# database transactions.
#
# This script is intended to be executed without specifying parameters to enable usage driven by
# the mysqlrpladmin --exec-before & --exec-after options. Therefore, all core variables are setup for 
# regex replacement, using this script as a template
#

# core variables with values that could be directly injected in this script
encoded_server_list=""
mysql_admin_username=""
mysql_admin_password=""
master_server_ip=""
cluster_admin_email=""

# operation phase: prefailover, postfailover
operation_phase="prefailover"

# debug mode: 0=set +x, 1=set -x
debug_mode=0

# Oxa Tools
# Settings for the OXA-Tools public repository 
oxa_tools_repository_path="/oxa/oxa-tools"

# Email Notifications
notification_email_subject="Mysql Failover - Marking servers Read-Only"
main_logfile="/var/log/bootstrap.csx.log"

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
          --cluster-admin-email)
            cluster_admin_email="${arg_value}"
            ;;
          --mysql-admin-username)
            mysql_admin_username="${arg_value}"
            ;;
          --mysql-admin-password)
            mysql_admin_password="${arg_value}"
            ;;
          --master-server-ip)
            master_server_ip="${arg_value}"
            ;;
          --backend-server-list)
            encoded_server_list="${arg_value}"
            ;;
          --phase)
            operation_phase="${arg_value,,}"
            if ! is_valid_arg "prefailover postfailover" ${operation_phase}; then
                echo "Invalid operation specified: '${operation_phase}' only 'query' & 'execute' are expected"
                exit 1
            fi
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
    #TODO: check for missing parameters
    log "Validating arguments"

    # we have 2 modes and each requires a different set of parameters
    # core variables

    if [[ -z $encoded_server_list ]];
    then
        log "You must specify a list of server in the mysql replication network"
        exit $ERROR_MYSQL_FAILOVER_FAILED
    fi

    # cluster admin email (for notification purposes)
    if [[ -z $cluster_admin_email ]]; 
    then
        log "You must specify the cluster admininstrator email address for notification purposes"
        exit $ERROR_MYSQL_FAILOVER_FAILED
    fi

    # Mysql user account
    if [[ -z $mysql_admin_username ]] || [[ -z $mysql_admin_password ]] ;
    then
        log "You must specify the admin credentials for mysql server"
        exit $ERROR_MYSQL_FAILOVER_FAILED
    fi

    if [[ $operation_phase == "postfailover" ]] ;
    then

        # for postfailover, we need new master IP
        if [[ -z $master_server_ip ]] ;
        then
            log "You must specify the master mysql server ip"
            exit $ERROR_MYSQL_FAILOVER_FAILED
        fi
    fi

    log "Completed argument validation successfully"
}

# mark a mysql server read only
update_mysql_server_readonly_status()
{
    local server="${1}"
    local admin_user="${2}"
    local admin_password="${3}"
    local ro_status="${4}"

    query="FLUSH TABLES; SET GLOBAL read_only = ${ro_status};"

    response=`mysql -u ${admin_user} -p${admin_password} -h ${server} -e "${query}"`
}

###############################################
# START CORE EXECUTION
###############################################

# Source our utilities for logging and other base functions (we need this staged with the installer script)
# the file needs to be first downloaded from the public repository
utilities_path="${oxa_tools_repository_path}/templates/stamp/utilities.sh"

# check if the utilities file exists. If not, bail out.
if [[ ! -e $utilities_path ]]; 
then
    echo :"Utilities not present"
    exit 3
fi

# source the utilities now
source $utilities_path

# Script self-identification
print_script_header "${notification_email_subject}"

# pass existing command line arguments
parse_args $@
validate_args

# debug mode support
if [[ $debug_mode == 1 ]];
then
    set -x
fi

#############################################
# Main Operations
# this should run on the target server
#############################################

# decode right before use to facilite value injection
servers=(`echo ${encoded_server_list} | base64 --decode`)

# the read-only status
read_only_status=0

if [[ $operation_phase == "prefailover" ]] ;
then

    log "Marking all Mysql servers as read-only"

    # pre-failover mode
    read_only_status=1

    # iterate all servers & mark as read-only
    for server in "${servers[@]}"
    do
        log "Marking ${server} as read-only"
        update_mysql_server_readonly_status $server $mysql_admin_username $mysql_admin_password $read_only_status
        exit_on_error "Unable to mark mysql server (${server}) as readonly!" "${ERROR_MYSQL_FAILOVER_MARKREADONLY}" "${notification_email_subject}" "${cluster_admin_email}" "${main_logfile}"
    done

    log "Completed updating the read-only status of the specified servers."
else

    log "Marking the Mysql master as read-write"

    # post-failover mode
    read_only_status=0

    update_mysql_server_readonly_status $master_server_ip $mysql_admin_username $mysql_admin_password $read_only_status
    exit_on_error "Unable to mark mysql server (${master_server_ip}) as read-write!" "${ERROR_MYSQL_FAILOVER_MARKREADONLY}" "${notification_email_subject}" "${cluster_admin_email}" "${main_logfile}"

    log "Completed updating the read-write status of the specified master server."
fi

