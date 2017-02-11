#!/bin/bash
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

#set -x

# argument defaults
#EDX_ROLE=""
DEPLOYMENT_ENV="dev"
ACCESS_TOKEN=""
OXA_TOOLS_CONFIG_VERSION="master"
OXA_TOOLS_VERSION_OVERRIDE="master"
MACHINE_ROLE=""
BOOTSTRAP_PHASE=0
TARGET_FILE=/var/log/bootstrap-Phase0.log

# Keyvault related parameters
KEYVAULT_NAME=""
AAD_WEBCLIENT_ID=""
AAD_WEBCLIENT_APPKEY=""
AAD_TENANT_ID=""
AZURE_SUBSCRIPTION_NAME=""


display_usage() {
    echo "Usage: $0 -a|--access_token {access token} -v|--version {oxa-tools-config version} [-e|--environment {dev|bvt|int|prod}] [--phase {0 1}]"
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

parse_args() {
  while [[ "$#" -gt 0 ]]
  do
    
    # Log input parameters to facilitate troubleshooting
    echo "Option '$1' set with value '$2'"

    case "$1" in
      -e|--environment)
        DEPLOYMENT_ENV="${2,,}" # convert to lowercase
        is_valid = $(is_valid_arg "dev bvt int prod" $DEPLOYMENT_ENV)
        if [ $is_valid -eq 1 ] ; then
          echo "Invalid environment specified\n"
          display_usage
        fi
        ;;
      -a|--access_token)
        ACCESS_TOKEN="$2"
        if ! [[ ${#ACCESS_TOKEN} -eq 40 ]]; then
          echo "Invalid access token specified\n"
          display_usage
        fi
        ;;
        --phase)
            if is_valid_arg "0 1" $2; then
                BOOTSTRAP_PHASE=$2
            else
                log "Invalid Bootstrap Phase specified - $2" $ERROR_MESSAGE
                help
                exit 2
            fi
        ;;
      -v|--tools-config-version)
        OXA_TOOLS_CONFIG_VERSION="$2"
        ;;
      --tools-version-override)
        OXA_TOOLS_VERSION_OVERRIDE="$2"
        ;;
      --keyvault-name)
        KEYVAULT_NAME="$2"
        ;;
      --aad-webclient-id)
        AAD_WEBCLIENT_ID="$2"
        ;;
      --aad-webclient-appkey)
        AAD_WEBCLIENT_APPKEY="$2"
        ;;
      --aad-tenant-id)
        AAD_TENANT_ID="$2"
        ;;
      --azure-subscription-name)
        AAD_TENANT_ID="$2"
        ;;
      *) # Unknown option encountered
        display_usage
        ;;
    esac

    shift # past argument or value
    shift # past argument or value
  done
}

setup_monitoring()
{
    HOST=$1

    # TODO: interim fix for installing monitoring on the backend
    echo "Setup monitoring on ${HOST}"

    # execute the pre-requisites: install git, clone repositories and stage utilities
    ssh -o "StrictHostKeyChecking=no" $ADMIN_USER@$HOST "sudo rm -rf ${OXA_PATH} && sudo apt-get install -y git && sudo mkdir ${OXA_PATH}  && sudo git clone -b ${OXA_TOOLS_CONFIG_VERSION}  https://${ACCESS_TOKEN}@github.com/Microsoft/oxa-tools-config.git ${OXA_TOOLS_CONFIG_PATH} && sudo git clone -b ${OXA_TOOLS_VERSION}  https://github.com/Microsoft/oxa-tools.git ${OXA_TOOLS_PATH} && sudo cp ${OXA_TOOLS_PATH}/templates/stamp/utilities.sh  ${OXA_TOOLS_CONFIG_PATH}/scripts/"
    exit_on_error "Monitoring setup failed installation of pre-requisites on $HOST"

    # install monitoring
    ssh -o "StrictHostKeyChecking=no" $ADMIN_USER@$HOST "sudo bash ${OXA_TOOLS_CONFIG_PATH}/scripts/install-mdsd.sh -c ${ENVIRONMENT} -r ${OXA_TOOLS_CONFIG_PATH} -m ${CLUSTERNAME}"
    exit_on_error "Monitoring setup failed installation of monitoring solution on $HOST"

    # clean up
    ssh -o "StrictHostKeyChecking=no" $ADMIN_USER@$HOST "sudo rm -rf ${OXA_PATH}"
}

exec_mongo() {
    HOST=$1
    NODE_COUNT=$2
    EXTRA_ARGS=$3

    # Setup Monitoring
    setup_monitoring $HOST

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

    exit_on_error "Mongo installation failed for $HOST"
}

exec_mysql() {
    HOST=$1
    NODE_ID=$2

    # Setup Monitoring
    setup_monitoring $HOST

    # Setup Mysql
    scp -o "StrictHostKeyChecking=no" -r $OXA_TOOLS_PATH/templates/stamp $ADMIN_USER@$HOST:~

    MYSQL_REPL_USER_PASSWORD_TEMP=`echo $MYSQL_REPL_USER_PASSWORD | base64`
    MYSQL_REPL_USER_PASSWORD_TEMP=`echo $MYSQL_REPL_USER_PASSWORD | base64`
    MYSQL_ADMIN_PASSWORD_TEMP=`echo $MYSQL_ADMIN_PASSWORD | base64`

    ssh -o "StrictHostKeyChecking=no" $ADMIN_USER@$HOST "cd ~/stamp && chmod 755 ~/stamp/$MYSQL_INSTALLER_SCRIPT  && sudo ~/stamp/$MYSQL_INSTALLER_SCRIPT -r $MYSQL_REPL_USER -k $MYSQL_REPL_USER_PASSWORD_TEMP -u $MYSQL_ADMIN_USER -p $MYSQL_ADMIN_PASSWORD_TEMP -v $MYSQL_PACKAGE_VERSION -m $MYSQL_MASTER_IP -n $NODE_ID"

    exit_on_error "MySQL installation failed for $HOST"
}

##
## Role-independent OXA environment bootstrap
##
setup() 
{
    #echo "executing apt-get update..."
    #sudo apt-get -y -qq update
    
    # git client is already installed
    # sudo apt-get -y install git
  
    # sync the private repository
    # instead of the repo sync, let's pull the configs from keyvault since that is what was needed
    ## sync_repo $OXA_TOOLS_CONFIG_REPO $OXA_TOOLS_CONFIG_VERSION $OXA_TOOLS_CONFIG_PATH $ACCESS_TOKEN
    log "Download configurations from keyvault"
    powershell -file $CURRENT_PATH/Process-OxaToolsKeyVaultConfiguration.ps1 -Operation Download -VaultName $KEYVAULT_NAME -AadWebClientId $AAD_WEBCLIENT_ID -AadWebClientAppKey $AAD_WEBCLIENT_APPKEY -AadTenantId $AAD_TENANT_ID -TargetPath $OXA_ENV_PATH

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
            exec_mongo 10.0.0.11 1 
            exec_mongo 10.0.0.12 2 
            exec_mongo 10.0.0.13 3 "-l" 
 
            exec_mysql 10.0.0.16 1
            exec_mysql 10.0.0.17 2
            exec_mysql 10.0.0.18 3
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

##
## Role-based ansible command lines
##

exit_on_error() {
  if [[ $? -ne 0 ]]; then
    echo $1 && exit 1
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
elif [ "$MACHINE_ROLE" == "vmss" ] ;
then
    log "Continuing to VMSS-specific OXA bootstrap..."
fi

# log a closing message and leave expected bread crumb for status tracking
TIMESTAMP=`date +"%D %T"`
STATUS_MESSAGE="${TIMESTAMP} :: Completed Phase 0 - OpenEdX Database (Mysql) Bootstrap from ${HOSTNAME}"
echo $STATUS_MESSAGE >> $TARGET_FILE
echo $STATUS_MESSAGE