#!/bin/bash
#
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

#
# This script executes a mysql failover within a STAMP-established  replication topology
#

# Initialize required parameters

# needed inputs:    server list, current master & target master
# supported modes:  query   (determine the current master, slaves, errant transactions and email result, )
#                   execute (perform the failover )

# needed: server list, current_master, new master, admin user, admin user password, port

# Oxa Tools
# Settings for the OXA-Tools public repository 
oxa_tools_public_github_account="Microsoft"
oxa_tools_public_github_projectname="oxa-tools"
oxa_tools_public_github_projectbranch="oxa/master.fic"
oxa_tools_public_github_branchtag=""
oxa_tools_repository_path="/oxa/oxa-tools"

# core variables
encoded_server_list=""
current_master_server_ip=""
new_master_server_ip=""

haproxy_server_port="12010"
mysql_server_port="3306"
mysql_admin_username=""
mysql_admin_password=""

# add replication user
mysql_repl_username=""
mysql_repl_password=""

# operation mode: query | execute
operation="query"

# debug mode: 0=set +x, 1=set -x
debug_mode=0

# indicator to force failover (ignore errant transactions) or not
force_failover=0

# Email Notifications
notification_email_subject="Mysql Failover"
cluster_admin_email=""

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
          --haproxy-server-port)
            haproxy_server_port="${arg_value}"
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
          --mysql-repl-username)
            mysql_repl_username="${arg_value}"
            ;;
          --mysql-repl-password)
            mysql_repl_password="${arg_value}"
            ;;        
          --new-master-server-ip)
            new_master_server_ip="${arg_value}"
            ;;
          --current-master-server-ip)
            current_master_server_ip="${arg_value}"
            ;;
          --backend-server-list)
            encoded_server_list="${arg_value}"
            ;;
          --operation)
            operation="${arg_value,,}"
            if ! is_valid_arg "query execute" ${operation}; then
                echo "Invalid operation specified: '${operation}' only 'query' & 'execute' are expected"
                exit 1
            fi
            ;;
          --force)
            force_failover=1
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
    if [[ -z $mysql_admin_username ]] || [[ -z $mysql_admin_password ]] || [[ -z $mysql_server_port ]] || [[ -z $haproxy_server_port ]];
    then
        log "You must specify the admin credentials for mysql server, the server and proxy port"
        exit $ERROR_MYSQL_FAILOVER_FAILED
    fi

    if [[ $operation == "execute" ]] ;
    then

        # for execution, we need the current and new master servers
        if [[ -z $current_master_server_ip ]] || [[ -z $new_master_server_ip ]] ;
        then
            log "You must specify current and new master mysql server ips"
            exit $ERROR_MYSQL_FAILOVER_FAILED
        fi  

    fi

    log "Completed argument validation successfully"
}

get_replication_report()
{
    # get a report of the replication network health
    local master_connection="${1}"
    local slave1_connection="${2}"
    local slave2_connection="${3}"
    local master="${4}"
    local slaves="${5}"


    temp_log_filename_template="/tmp/repl_status"
    temp_log_file_1=`mktemp "${temp_log_filename_template}_log.XXXXXXXXXX.log"`
    temp_log_file_2=`mktemp "${temp_log_filename_template}_report.XXXXXXXXXX.log"`

    mysqlrpladmin --master="${master_connection}" --slaves=""${slave1_connection},"${slave2_connection}" health --format=grid --log="${temp_log_file_1}" > $temp_log_file_2
    exit_on_error "Unable to check the status of the mysql replication network with '${master}' as master!" "${ERROR_MYSQL_FAILOVER_FAILED}" "${notification_email_subject}" "${cluster_admin_email}" "${main_logfile}" "${temp_log_file}"

    # augment the query report with detailed master/slave status
    master_status=`mysql -u ${mysql_admin_username} -p${mysql_admin_password} -h ${master} -e "show master status \G"`
    cluster_server_status_title="Detailed Master Replication Status - ${master}"
    cluster_server_status="${cluster_server_status_title}\n${master_status}\n\n"

    IFS=',' read -ra slave_list <<< "$slaves"
    for slave in "${slave_list[@]}"; do
        slave_status=`mysql -u ${mysql_admin_username} -p${mysql_admin_password} -h ${slave} -e "show slave status \G"`
        cluster_server_status_title="Detailed Slave Replication Status - ${slave}"
        cluster_server_status="${cluster_server_status}\n${cluster_server_status_title}\n${slave_status}\n\n"
    done

    # build the report now
    main_title="Replication Server Status"
    server_status=" Master: ${master} \n Slaves: ${slaves}"

    # format the outputs
    replication_status_title="Replication Status (using '${master}' as master)"
    replication_status=`tail -n +4 $temp_log_file_2`

    replication_log_title="Log"
    replication_log=`cat "${temp_log_file_1}"`

    # build the full response (to be emailed)
    response="\n${main_title}\n${server_status}\n\n${replication_status_title}\n\n${replication_status}\n\n${cluster_server_status}${replication_log_title}\n${replication_log}"

    # clean up
    rm "${temp_log_file_1}"
    rm "${temp_log_file_2}"

    echo "${response}"
}

query_cluster_status()
{
    # Query the cluster and return the status of connection strings for failovers
    # it is assumed that the mysql probe is already in place (as part of the installhaproxy $
    # we will use the probe to discover the current master and its slaves

    local servers=(`echo ${1} | base64 --decode`)
    local proxy_port="${2:-12010}"
    local operation_mode="${3}"

    local slave_regex="is a not a valid replication master"
    local master_regex="is a valid replication master"

    local secondary_message=""
    local message=""

    local master=""
    local master_connection_str=""
    local new_master_connection_str=""

    local slaves=""
    local slave1_connection_str=""
    local slave2_connection_str=""

    local response=""

    for server in "${servers[@]}"
    do
        # check the server status
        status_response=`nc $server $proxy_port`
        connection_str=`get_failover_connection_str "${mysql_admin_username}" "${mysql_admin_password}" "${server}" "${mysql_server_port}"`

        if [[ -z "${status_response}" ]] ;
        then

            # the port is dead
            log "The specified proxy port for mysql status check is not responding"
            exit $ERROR_MYSQL_FAILOVER_INVALIDPROXYPORT

        elif [[ "${status_response}" =~ "${master_regex}" ]] ;
        then
            # get the master connection param
            master_connection_str="${connection_str}"
            master="${server}"

        elif [[ "${status_response}" =~ "${slave_regex}" ]] ;
        then
            
            # separately track the connection string for the new master
            if [[ ! -z "${new_master_server_ip}" ]] && [[ "${new_master_server_ip}" == "${server}" ]] ;
            then
                new_master_connection_str="${connection_str}"
            fi

            # we have a response. Secondary detected
            if [[ -z "${slave1_connection_str}" ]] ; 
            then
                slave1_connection_str="${connection_str}"
                slaves="${server}"
            else
                slave2_connection_str="${connection_str}"
                slaves="${slaves}, ${server}"
            fi
        else
            # could not determine the server state from its probe response
            log "Could not determine the state of the ${server}. Response='${status_response}'"
            exit $ERROR_MYSQL_FAILOVER_UNKNOWNRESPONSE
        fi
    done

    # generate the response base on the operation mode
    if [[ $operation_mode == "query" ]] ;
    then

        response=`get_replication_report "${master_connection_str}" "${slave1_connection_str}" "${slave2_connection_str}" "${master}" "${slaves}"`

    else
        
        encoded_master_connection_str=(`echo "${master_connection_str}" | base64`)
        encoded_slave1_connection_str=(`echo "${slave1_connection_str}" | base64`)
        encoded_slave2_connection_str=(`echo "${slave2_connection_str}" | base64`)

        response="${encoded_master_connection_str} ${encoded_slave1_connection_str} ${encoded_slave2_connection_str}"

        if [[ ! -z "${new_master_connection_str}" ]] ;
        then
            encoded_new_master_connection_str=(`echo "${new_master_connection_str}" | base64`)
            response="${response} ${encoded_new_master_connection_str}"
        fi
    fi

    # return a formatted status response
    echo "${response}"
}

get_failover_connection_str()
{
    # build a failover connection for failover
    local username="${1}"
    local password="${2}"
    local server="${3}"
    local port="${4}"

    connection_str="${username}:${password}@${server}:${port}"

    echo "${connection_str}"
}

generate_failover_exec_script()
{
    # establish key variables
    local operation_phase="${1}"
    local src_file="${2}"

    local temp_script_file=`mktemp "/tmp/${operation_phase}.XXXXXXXXXX.sh"`
    local src_file="${oxa_tools_repository_path}/scripts/deploymentextensions/mysqlfailover/prepost-failover.sh"

    # copy the base file to temp_log_file
    cp "${src_file}" "${temp_script_file}"

    # make sed replacements
    sed -i "s/^encoded_server_list=.*/encoded_server_list=\"${encoded_server_list}\"/I" $temp_script_file
    sed -i "s/^mysql_admin_username=.*/mysql_admin_username=\"${mysql_admin_username}\"/I" $temp_script_file
    sed -i "s/^mysql_admin_password.*/mysql_admin_password=\"${mysql_admin_password}\"/I" $temp_script_file
    sed -i "s/^master_server_ip=.*/master_server_ip=\"${new_master_server_ip}\"/I" $temp_script_file
    sed -i "s/^cluster_admin_email.*/cluster_admin_email=\"${cluster_admin_email}\"/I" $temp_script_file
    sed -i "s/^debug_mode.*/debug_mode=${debug_mode}/I" $temp_script_file
    sed -i "s/^operation_phase.*/operation_phase=\"${operation_phase}\"/I" $temp_script_file

    # set the permissions on the file
    chmod +x "${temp_script_file}"

    # return file path
    echo $temp_script_file
}

failover_mysql_master()
{
    log "Failover mysql server master from '${current_master_server_ip}' to '${new_master_server_ip}'"

    local current_master_connection="${1}"
    local new_master_connection="${2}"
    local slaves_connection="${3}"

    local temp_log_filename_template="/tmp/mysql_failover_status"
    local temp_log_file_1=`mktemp "${temp_log_filename_template}.XXXXXXXXXX.log"`
    local temp_log_file_2="${temp_log_filename_template}.log"

    # setup the pre and post failover scripts
    local pre_failover_script=`generate_failover_exec_script "prefailover"`
    local post_failover_script=`generate_failover_exec_script "postfailover"`

    # MySQL Utilities mysqlrpladmin version 1.6.1: 
    # Failover expects --rpl-user or slaves configured with --master-info-repository=TABLE
    repl_user_credential="${mysql_repl_username}:${mysql_repl_password}"

    if [[ $force_failover == 0 ]] ;
    then
        log "Failover is in standard mode"
        mysqlrpladmin --master="${current_master_connection}" --new-master="${new_master_connection}" --demote-master --slaves="${slaves_connection}" --rpl-user="${repl_user_credential}" switchover --log="${temp_log_file_1}" --exec-before="${pre_failover_script}" --exec-after="${post_failover_script}" > $temp_log_file_2
    else
        log "Failover is in --force mode"
        mysqlrpladmin --master="${current_master_connection}" --new-master="${new_master_connection}" --demote-master --slaves="${slaves_connection}" --rpl-user="${repl_user_credential}" switchover --log="${temp_log_file_1}" --exec-before="${pre_failover_script}" --exec-after="${post_failover_script}" --force > $temp_log_file_2
    fi

    exit_on_error "Unable to failover from '${current_master_server_ip}' to '${new_master_server_ip}'!" "${ERROR_MYSQL_FAILOVER_FAILED}" "${notification_email_subject}" "${cluster_admin_email}" "${main_logfile}" "${temp_log_file_2}"

    # send a report of the operation
    failover_log=`cat $temp_log_file_1`
    failover_status=`tail -n +2 $temp_log_file_2`

    report_content=`echo -e "Failover Status:\n\n${failover_status}\n\n\nFailover Log:\n\n${failover_log}"`

    send_notification "${report_content}" "${notification_email_subject}" "${cluster_admin_email}"

    # clean up (general, in case of a prior failure)
    rm ${temp_log_filename_template}.*
    rm ${pre_failover_script}
    rm ${post_failover_script}
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
print_script_header "Mysql Failover"

# pass existing command line arguments
parse_args $@
validate_args

# debug mode support
if [[ $debug_mode == 1 ]];
then
    set -x
fi

# sync the oxa-tools repository
repo_url=`get_github_url "${oxa_tools_public_github_account}" "${oxa_tools_public_github_projectname}"`
sync_repo "${repo_url}" "${oxa_tools_public_github_projectbranch}" "${oxa_tools_repository_path}" "${access_token}" "${oxa_tools_public_github_branchtag}"

# execute the installer remote

#############################################
# Main Operations
# this should run on the target server
#############################################

log "Starting Mysql Failover in '${operation}' mode"

# run the move operation
log "Quering cluster status"
results=`query_cluster_status "${encoded_server_list}" "${haproxy_server_port}" "${operation}"`
exit_on_error "Unable to determine the mysql cluster status!" "${ERROR_MYSQL_FAILOVER_FAILED}" "${notification_email_subject}" "${cluster_admin_email}"

if [[ "${operation}" == "query" ]] ;
then

    # send an email notification of the results
    results="Query Results \n ${results}"
    formatted_response=`echo -e "${results}"`
    send_notification "${formatted_response}" "${notification_email_subject}" "${cluster_admin_email}"

else

    # get current master & slaves connection 
    connections=( $results )

    master_connection_str=`echo "${connections[0]}" | base64 --decode`
    slave1_connection_str=`echo "${connections[1]}" | base64 --decode`
    slave2_connection_str=`echo "${connections[2]}" | base64 --decode`
    new_master_connection_str=`echo "${connections[3]}" | base64 --decode`

    log "Executing actual master failover"
    failover_mysql_master "${master_connection_str}" "${new_master_connection_str}" "${slave1_connection_str},${slave2_connection_str}"
fi


log "Completed mysql failover in '${operation}' mode successfully."