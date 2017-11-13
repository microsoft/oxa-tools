#!/bin/bash
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

# argument defaults
DEPLOYMENT_ENV="dev"
OXA_TOOLS_VERSION_OVERRIDE="master"
MACHINE_ROLE=""
BOOTSTRAP_PHASE=0
TARGET_FILE=/var/log/bootstrap-Phase0.log

# Keyvault related parameters
KEYVAULT_NAME=""
AAD_WEBCLIENT_ID=""
AAD_WEBCLIENT_APPKEY=""
AAD_TENANT_ID=""
AZURE_SUBSCRIPTION_ID=""

# SMTP / Mailer parameters
CLUSTER_ADMIN_EMAIL=""
MAIL_SUBJECT="OXA Bootstrap"
CLUSTER_NAME=""
NOTIFICATION_MESSAGE=""
SECONDARY_LOG="/var/log/bootstrap.log"
PRIMARY_LOG="/var/log/bootstrap.csx.log"

display_usage() {
    echo "Usage: $0 [-e|--environment {dev|bvt|prod}] [--phase {0 1}] --keyvault-name {azure keyvault name} --aad-webclient-id {AAD web application client id} --aad-webclient-appkey {AAD web application client key} --aad-tenant-id {AAD Tenant to authenticate against} --azure-subscription-id {Azure subscription Id}"
    exit 1
}

is_valid_arg() {
  local list="$1"
  local arg="$2"

  if [[ $list =~ (^|[[:space:]])"$arg"($|[[:space:]]) ]] ; then
    result=0
  else
    result=1
  fi

  return $result
}

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
        echo "Option '$1' set with value '${arg_value}'"

        case "$1" in
          -e|--environment)
            DEPLOYMENT_ENV="${arg_value,,}" # convert to lowercase
            is_valid=$(is_valid_arg "dev bvt prod" $DEPLOYMENT_ENV)
            if [[ $is_valid -eq 1 ]] ; then
              echo "Invalid environment specified\n"
              display_usage
            fi
            ;;
            --phase)
                if is_valid_arg "0 1" "${arg_value}"; then
                    BOOTSTRAP_PHASE="${arg_value}"
                else
                    log "Invalid Bootstrap Phase specified - ${arg_value}" $ERROR_MESSAGE
                    help
                    exit 2
                fi
            ;;
          --tools-version-override)
            OXA_TOOLS_VERSION_OVERRIDE="${arg_value}"
            ;;
          --keyvault-name)
            KEYVAULT_NAME="${arg_value}"
            ;;
          --aad-webclient-id)
            AAD_WEBCLIENT_ID="${arg_value}"
            ;;
          --aad-webclient-appkey)
            AAD_WEBCLIENT_APPKEY="${arg_value}"
            ;;
          --aad-tenant-id)
            AAD_TENANT_ID="${arg_value}"
            ;;
          --azure-subscription-id)
            AZURE_SUBSCRIPTION_ID="${arg_value}"
            ;;
          --cluster-admin-email)
            CLUSTER_ADMIN_EMAIL="${arg_value}"
            ;;
          --cluster-name)
            CLUSTER_NAME="${arg_value}"
            MAIL_SUBJECT="${MAIL_SUBJECT} - ${arg_value,,}"
            ;;
          *) # Unknown option encountered
            display_usage
            ;;
        esac

        shift # past argument or value

        if [ $shift_once -eq 0 ]; 
        then
            shift # past argument or value
        fi
    done
}

exec_mongo() {
    HOST=$1
    NODE_COUNT=$2
    EXTRA_ARGS=$3

    # Setup Monitoring
    # setup_monitoring $HOST

    # Setup Mongo
    scp -o "StrictHostKeyChecking=no" -r $OXA_TOOLS_PATH/templates/stamp $ADMIN_USER@$HOST:~

    MONGO_PASSWORD_TEMP=`echo $MONGO_PASSWORD | base64`

    # if repository path is not specified, default it to the user's home directory'
    if [ -z $EXTRA_ARGS ]
    then
        ssh -o "StrictHostKeyChecking=no" $ADMIN_USER@$HOST "cd ~/stamp && chmod 755 ~/stamp/$MONGO_INSTALLER_SCRIPT && sudo ~/stamp/$MONGO_INSTALLER_SCRIPT -i $MONGO_INSTALLER_BASE_URL -b $MONGO_INSTALLER_PACKAGE_NAME -r $MONGO_REPLICASET_NAME -k $MONGO_REPLICASET_KEY -u $MONGO_USER -p $MONGO_PASSWORD_TEMP -x $MONGO_SERVER_IP_PREFIX -n $NODE_COUNT -o $MONGO_SERVER_IP_OFFSET"
    else
        ssh -o "StrictHostKeyChecking=no" $ADMIN_USER@$HOST "cd ~/stamp && chmod 755 ~/stamp/$MONGO_INSTALLER_SCRIPT && sudo ~/stamp/$MONGO_INSTALLER_SCRIPT -i $MONGO_INSTALLER_BASE_URL -b $MONGO_INSTALLER_PACKAGE_NAME -r $MONGO_REPLICASET_NAME -k $MONGO_REPLICASET_KEY -u $MONGO_USER -p $MONGO_PASSWORD_TEMP -x $MONGO_SERVER_IP_PREFIX -n $NODE_COUNT -o $MONGO_SERVER_IP_OFFSET -l"
    fi 

    exit_on_error "Mongo installation failed for $HOST" 1 "${MAIL_SUBJECT} Failed" $CLUSTER_ADMIN_EMAIL $PRIMARY_LOG $SECONDARY_LOG
}

exec_mysql() {
    HOST=$1
    NODE_ID=$2

    # Setup Monitoring
    #setup_monitoring $HOST

    # Setup Mysql
    scp -o "StrictHostKeyChecking=no" -r $OXA_TOOLS_PATH/templates/stamp $ADMIN_USER@$HOST:~

    MYSQL_REPL_USER_PASSWORD_TEMP=`echo $MYSQL_REPL_USER_PASSWORD | base64`
    MYSQL_REPL_USER_PASSWORD_TEMP=`echo $MYSQL_REPL_USER_PASSWORD | base64`
    MYSQL_ADMIN_PASSWORD_TEMP=`echo $MYSQL_ADMIN_PASSWORD | base64`

    ssh -o "StrictHostKeyChecking=no" $ADMIN_USER@$HOST "cd ~/stamp && chmod 755 ~/stamp/$MYSQL_INSTALLER_SCRIPT  && sudo ~/stamp/$MYSQL_INSTALLER_SCRIPT -r $MYSQL_REPL_USER -k $MYSQL_REPL_USER_PASSWORD_TEMP -u $MYSQL_ADMIN_USER -p $MYSQL_ADMIN_PASSWORD_TEMP -v $MYSQL_PACKAGE_VERSION -m $MYSQL_MASTER_IP -n $NODE_ID"

    exit_on_error "MySQL installation failed for $HOST" 1 "${MAIL_SUBJECT} Failed" $CLUSTER_ADMIN_EMAIL $PRIMARY_LOG $SECONDARY_LOG
}

##
## Role-independent OXA environment bootstrap
##
setup() 
{
    # populate the deployment environment
    source $OXA_ENV_FILE
    setup_overrides

    export $(sed -e 's/#.*$//' $OXA_ENV_FILE | cut -d= -f1)
    export ANSIBLE_REPO=CONFIGURATION_REPO
    export ANSIBLE_VERSION=CONFIGURATION_VERSION
  
    # deployment environment overrides for debugging
    OXA_ENV_OVERRIDE_FILE="$BOOTSTRAP_HOME/overrides.sh"
    echo "Checking ${OXA_ENV_OVERRIDE_FILE} for overrides"

    if [[ -d $OXA_ENV_OVERRIDE_FILE ]]; then
        source $OXA_ENV_OVERRIDE_FILE
        setup_overrides
    fi

    # sync public repositories
    sync_repo $OXA_TOOLS_REPO $OXA_TOOLS_VERSION $OXA_TOOLS_PATH
  
    # fix OXA environment ownership
    sudo chown -R $ADMIN_USER:$ADMIN_USER $OXA_PATH

    wget -q https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/shared_scripts/ubuntu/vm-disk-utils-0.1.sh -O $OXA_TOOLS_PATH/templates/stamp/vm-disk-utils-0.1.sh

    if [ "$MACHINE_ROLE" == "jumpbox" ] && [ "$BOOTSTRAP_PHASE" == "0" ] ;
    then
        # check if this is already done
        
        if [ ! -e $TARGET_FILE ];
        then
            # Setup each mongo server
            count=1
            mongo_servers=(`echo $MONGO_SERVER_LIST | tr , ' ' `)
            for ip in "${mongo_servers[@]}"; do
                last=
                if [[ $count == ${#mongo_servers[@]} ]]; then
                    last="-l"
                fi

                exec_mongo $ip $count $last
                ((count++))
            done
 
            # Setup each mysql server
            count=1
            mysql_servers=(`echo $MYSQL_SERVER_LIST | tr , ' ' `)
            for ip in "${mysql_servers[@]}"; do
                exec_mysql $ip $count
                ((count++))
            done

            # Secure the mysql installation after replication has been setup (only run against the Mysql Master)
            # Specifically: remove anonymous users, remove root network login (only local host allowed), remove test db
            # This step was previously executed during the replication configuration but it may be contributing to breaking replication immediately following setup
            log "Securing Mysql Installation: removing anonymous users, removing root network login, removing test databases"

            # generate the query
            temp_query_file="tmp.query.secure.sql"
            tee ./$temp_query_file > /dev/null <<EOF
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
EOF

            # execute the query
            mysql -h $MYSQL_MASTER_IP -u root -p$MYSQL_ADMIN_PASSWORD< ./$temp_query_file

            # remove the temp file (security reasons)
            rm $temp_query_file
        else
            log "Skipping the 'Infrastructure Bootstrap - Server Application Installation' since this is already done"
        fi
    else
        log "Skipping the 'Infrastructure Bootstrap - Server Application Installation'"
    fi
}

setup_overrides()
{
    # apply input parameter-based overrides
    if [ "$OXA_TOOLS_VERSION_OVERRIDE" != "$OXA_TOOLS_VERSION" ];
    then
        echo "Applying OXA Tools Version override: '$OXA_TOOLS_VERSION' to '$OXA_TOOLS_VERSION_OVERRIDE'"
        OXA_TOOLS_VERSION=$OXA_TOOLS_VERSION_OVERRIDE
    fi
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

# Script self-idenfitication
print_script_header

parse_args $@ # pass existing command line arguments

##
## Execute role-independent OXA environment bootstrap
##
BOOTSTRAP_HOME=$(dirname $0)
OXA_PATH=/oxa
OXA_TOOLS_REPO="https://github.com/microsoft/oxa-tools.git"
OXA_TOOLS_PATH=$OXA_PATH/oxa-tools
OXA_TOOLS_CONFIG_PATH=$OXA_PATH/oxa-tools-config
CONFIGURATION_PATH=$OXA_PATH/configuration
OXA_ENV_PATH=$OXA_TOOLS_CONFIG_PATH/env/$DEPLOYMENT_ENV
OXA_ENV_FILE=$OXA_ENV_PATH/$DEPLOYMENT_ENV.sh
OXA_PLAYBOOK_CONFIG=$OXA_PATH/oxa.yml

MACHINE_ROLE=$(get_machine_role)
log "${HOSTNAME} has been identified as a member of the '${MACHINE_ROLE}' role"

setup

##
## Execute role-based automation (edX and OXA playbooks)
## stamp note: assumes DB installations and SSH keys are already in place
##
OXA_SSH_ARGS="-u $OXA_ADMIN_USER --private-key=/home/$OXA_ADMIN_USER/.ssh/id_rsa"

# Fixes error: RPC failed; result=56, HTTP code = 0'
# fatal: The remote end hung up unexpectedly
git config --global http.postBuffer 1048576000

# Set conditional output message
if [ "$MACHINE_ROLE" == "jumpbox" ] && [ "$BOOTSTRAP_PHASE" == "0" ];
then
    log "OXA bootstrap complete"

    # log a closing message and leave expected bread crumb for status tracking
    NOTIFICATION_MESSAGE="Installation & configuration of the backend database applications (Mongo & Mysql) completed successfully."
    log "${NOTIFICATION_MESSAGE}"
    send_notification "${NOTIFICATION_MESSAGE}" "${MAIL_SUBJECT}" "${CLUSTER_ADMIN_EMAIL}"
    echo $NOTIFICATION_MESSAGE >> $TARGET_FILE
elif [ "$MACHINE_ROLE" == "vmss" ] ;
then
    log "Continuing to VMSS-specific OXA bootstrap..."
fi

