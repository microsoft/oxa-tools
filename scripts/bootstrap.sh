#!/bin/bash
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

set -x



# argument defaults
EDX_ROLE=""
DEPLOYMENT_ENV="dev"
CRON_MODE=0
TARGET_FILE=""
PROGRESS_FILE=""

# Settings for the OXA-Tools public repository 
OXA_TOOLS_PUBLIC_GITHUB_ACCOUNTNAME="Microsoft"
OXA_TOOLS_PUBLIC_GITHUB_PROJECTNAME="oxa-tools"
OXA_TOOLS_PUBLIC_GITHUB_PROJECTBRANCH="master"

# this is the operational branch for the OXA_TOOLS public git project
OXA_TOOLS_VERSION=""

# there are cases where we want to override the edx-configuration repository itself
EDX_CONFIGURATION_PUBLIC_GITHUB_ACCOUNTNAME="Microsoft"
EDX_CONFIGURATION_PUBLIC_GITHUB_PROJECTNAME="edx-configuration"
EDX_CONFIGURATION_PUBLIC_GITHUB_PROJECTBRANCH="oxa/master"

# this is the operational branch for the EDX_CONFIGURATION public git project
CONFIGURATION_VERSION=""

# script used for triggering background installation (setup in cron)
CRON_INSTALLER_SCRIPT=""

# SMTP / Mailer parameters
CLUSTER_ADMIN_EMAIL=""
MAIL_SUBJECT="OXA Bootstrap - Ansible Playbooks Installer"
NOTIFICATION_MESSAGE=""
SECONDARY_LOG="/var/log/bootstrap.csx.log"
PRIMARY_LOG="/var/log/bootstrap.log"

display_usage() {
  echo "Usage: $0 -a|--access_token {access token} -v|--version {oxa-tools-config version} [-r|--role {jb|vmss|mongo|mysql|edxapp|fullstack}] [-e|--environment {dev|bvt|int|prod}] [--cron] --keyvault-name {azure keyvault name} --aad-webclient-id {AAD web application client id} --aad-webclient-appkey {AAD web application client key} --aad-tenant-id {AAD Tenant to authenticate against} --azure-subscription-id {Azure subscription Id}"
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
    case "$1" in
      -r|--role)
        EDX_ROLE="${2,,}" # convert to lowercase
        if ! is_valid_arg "jb vmss mongo mysql edxapp fullstack" $EDX_ROLE; then
          echo "Invalid role specified\n"
          display_usage
        fi
        ;;
      -e|--environment)
        DEPLOYMENT_ENV="${2,,}" # convert to lowercase
        if ! is_valid_arg "dev bvt int prod" $DEPLOYMENT_ENV; then
          echo "Invalid environment specified\n"
          display_usage
        fi
        ;;
      --cron)
        CRON_MODE=1
        ;;
        --oxatools_public-github-accountname)
        OXA_TOOLS_PUBLIC_GITHUB_ACCOUNTNAME="$2"
        ;;
        --oxatools_public-github-projectname)
          OXA_TOOLS_PUBLIC_GITHUB_PROJECTNAME="$2"
        ;;
        --oxatools_public-github-projectbranch)
          OXA_TOOLS_PUBLIC_GITHUB_PROJECTBRANCH="$2"
        ;;        
        --oxatools_public-github-projectbranch)
          OXA_TOOLS_PUBLIC_GITHUB_PROJECTBRANCH="$2"
        ;;
        --oxatools_public-github-accountname)
        OXA_TOOLS_PUBLIC_GITHUB_ACCOUNTNAME="$2"
        ;;
        --edxconfiguration_public-github-projectname)
          EDX_CONFIGURATION_PUBLIC_GITHUB_ACCOUNTNAME="$2"
        ;;
        --edxconfiguration_public-github-projectbranch)
          EDX_CONFIGURATION_PUBLIC_GITHUB_PROJECTBRANCH="$2"
        ;;        
        --edxconfiguration_public-github-projectbranch)
          EDX_CONFIGURATION_PUBLIC_GITHUB_PROJECTBRANCH="$2"
        ;;
        --installer-script-path)
          CRON_INSTALLER_SCRIPT="$2"
        ;;
        --cluster-admin-email)
          CLUSTER_ADMIN_EMAIL="$2"
        ;;
      *)
        # Unknown option encountered
        display_usage
        ;;
    esac

    shift # past argument or value
    shift # past argument or value
  done
}

sync_repo() {
  REPO_URL=$1; REPO_VERSION=$2; REPO_PATH=$3
  REPO_TOKEN=$4 # optional

  if [ "$#" -lt 3 ]; then
    echo "sync_repo: invalid number of arguments" && exit 1
  fi
  
  # todo: scorch support?
  
  if [[ ! -d $REPO_PATH ]]; then
    mkdir -p $REPO_PATH
    git clone ${REPO_URL/github/$REPO_TOKEN@github} $REPO_PATH

    exit_on_error "Failed syncing repository $REPO_URL | $REPO_VERSION"
  fi
  pushd $REPO_PATH && git checkout ${REPO_VERSION:-master} && popd
}

##
## Check if bootstrap needs to be run for the specified role
##
get_bootstrap_status()
{
    # this determination is role-dependent
    #TODO: setup a more elaborate crumb system

    # we will perform a presence test for a /var/log/bootstrap-$EDX_ROLE.log
    # the expectation is that when the bootstrap script completes successfully, this file will be created

    # 0 - Proceed with setup
    # 1 - Wait on backend
    # 2 - Bootstrap done
    # 3 - Bootstrap in progress

    # by default we assume, bootstrap is needed
    PRESENCE=0

    # check if the bootstrap is finished
    if [ -e $TARGET_FILE ];
    then
        # The crumb exists:: bootstrap is done
        PRESENCE=2
    else
        # check if there is an ongoing execution
        if [ -e $PROGRESS_FILE ];
        then
            # execution is in progress
            PRESENCE=3
        elif [ "$EDX_ROLE" == "vmss" ];
        then
            # Source the settings
            # Moving source here reduces the noise in the logs
            source $OXA_ENV_FILE
            setup_overrides 1

            # The crumb doesn't exist:: we need to execute boostrap
            # For VMSS role, we have to wait on the backend Mysql bootstrap operation
            # The Mysql master is known. This is the one we really care about. If it is up, we will call backend bootstrap done
            # It is expected that the client tools are already installed
            #echo "Testing connection to edxapp database on '${MYSQL_MASTER_IP}'"
            AUTH_USER_COUNT=`mysql -u $MYSQL_ADMIN_USER -p$MYSQL_ADMIN_PASSWORD -h $MYSQL_MASTER_IP -s -N -e "use edxapp; select count(*) from auth_user;"`
            if [[ $? -ne 0 ]]; 
            then
                #echo "Connection test failed. Keeping holding pattern for VMSS bootstrap"
                # The crumb doesn't exist:: we need to execute boostrap, but we have unmet dependency (wait)
                PRESENCE=1
            fi
        fi
    fi
    echo $PRESENCE
}

setup_overrides()
{
    QUIETMODE=$1

    # apply input parameter-based overrides
    if [ "$OXA_TOOLS_PUBLIC_GITHUB_PROJECTBRANCH" != "$OXA_TOOLS_VERSION" ];
    then
        if [ "$QUIETMODE" != "1" ];
        then
            echo "Applying OXA Tools Version override: '$OXA_TOOLS_VERSION' to '$OXA_TOOLS_PUBLIC_GITHUB_PROJECTBRANCH'"
        fi

        OXA_TOOLS_VERSION=$OXA_TOOLS_PUBLIC_GITHUB_PROJECTBRANCH
    fi

    # apply input parameter-based overrides
    if [ "$EDX_CONFIGURATION_PUBLIC_GITHUB_PROJECTBRANCH" != "$CONFIGURATION_VERSION" ];
    then
        if [ "$QUIETMODE" != "1" ];
        then
            echo "Applying OXA Tools Version override: '$CONFIGURATION_VERSION' to '$EDX_CONFIGURATION_PUBLIC_GITHUB_PROJECTBRANCH'"
        fi

        CONFIGURATION_VERSION=$EDX_CONFIGURATION_PUBLIC_GITHUB_PROJECTBRANCH
    fi
}

##
## Role-independent OXA environment bootstrap
##
setup() 
{
    # There is an implicit pre-requisite for the GIT client to be installed. 
    # This is already handled in the calling script

    # populate the deployment environment
    source $OXA_ENV_FILE
    setup_overrides

    export $(sed -e 's/#.*$//' $OXA_ENV_FILE | cut -d= -f1)
  
    # deployment environment overrides for debugging
    OXA_ENV_OVERRIDE_FILE="$BOOTSTRAP_HOME/overrides.sh"
    if [[ -f $OXA_ENV_OVERRIDE_FILE ]]; then
        source $OXA_ENV_OVERRIDE_FILE
        setup_overrides
    fi

    export $(sed -e 's/#.*$//' $OXA_ENV_OVERRIDE_FILE | cut -d= -f1)
    export ANSIBLE_REPO=$CONFIGURATION_REPO
    export ANSIBLE_VERSION=$CONFIGURATION_VERSION
  
    # sync public repositories
    sync_repo $OXA_TOOLS_REPO $OXA_TOOLS_VERSION $OXA_TOOLS_PATH
    sync_repo $CONFIGURATION_REPO $CONFIGURATION_VERSION $CONFIGURATION_PATH
  
    # run edx bootstrap and install requirements
    cd $CONFIGURATION_PATH
    ANSIBLE_BOOTSTRAP_SCRIPT=util/install/ansible-bootstrap.sh

    # in order to support retries, we need to clean the temporary folder where the ansible bootstrap script clones the repository
    TEMP_CONFIGURATION_PATH=/tmp/configuration
    if [[ -d $TEMP_CONFIGURATION_PATH ]]; then
        echo "Removing the temporary configuration path at $TEMP_CONFIGURATION_PATH"
        rm -rf $TEMP_CONFIGURATION_PATH
    else
        echo "Skipping clean up of $TEMP_CONFIGURATION_PATH"
    fi

    bash $ANSIBLE_BOOTSTRAP_SCRIPT
    exit_on_error "Failed executing $ANSIBLE_BOOTSTRAP_SCRIPT"

    pip install -r requirements.txt
    exit_on_error "Failed pip-installing EdX requirements"
  
    # fix OXA environment ownership
    chown -R $ADMIN_USER:$ADMIN_USER $OXA_PATH
  
    # aggregate edx configuration with deployment environment expansion
    # warning: beware of yaml variable dependencies due to order of aggregation
    echo "---" > $OXA_PLAYBOOK_CONFIG
    for config in $OXA_TOOLS_PATH/config/$TEMPLATE_TYPE/*.yml $OXA_TOOLS_PATH/config/*.yml; do
        sed -e "s/%%\([^%]*\)%%/$\{\\1\}/g" -e "s/^---.*$//g" $config | envsubst >> $OXA_PLAYBOOK_CONFIG
    done
}

##
## Role-based ansible command lines
##

exit_on_error()
{
    if [[ "$?" -ne "0" ]];
    then
        echo $1

        # in case there is an error, remove the progress crumb
        remove_progress_file

        exit 1
    fi
}

update_stamp_jb() 
{
    SUBJECT="${MAIL_SUBJECT} - JB DB Customization Failed"

    # edx playbooks - mysql and memcached
    $ANSIBLE_PLAYBOOK -i 10.0.0.16, $OXA_SSH_ARGS -e@$OXA_PLAYBOOK_CONFIG edx_mysql.yml
    
    exit_on_error "Execution of edX MySQL playbook failed (Stamp JB)" 1 $SUBJECT $CLUSTER_ADMIN_EMAIL $PRIMARY_LOG $SECONDARY_LOG

    # minimize tags? "install:base,install:system-requirements,install:configuration,install:app-requirements,install:code"
    $ANSIBLE_PLAYBOOK -i localhost, -c local -e@$OXA_PLAYBOOK_CONFIG edx_sandbox.yml -e "migrate_db=yes" --tags "edxapp-sandbox,install,migrate"
    exit_on_error "Execution of edX MySQL migrations failed" 1 $SUBJECT $CLUSTER_ADMIN_EMAIL $PRIMARY_LOG $SECONDARY_LOG
  
    # oxa playbooks - mongo (enable when customized) and mysql
    #$ANSIBLE_PLAYBOOK -i ${CLUSTERNAME}mongo1, $OXA_SSH_ARGS -e@$OXA_PLAYBOOK_CONFIG $OXA_PLAYBOOK_ARGS $OXA_PLAYBOOK --tags "mongo"
    #exit_on_error "Execution of OXA Mongo playbook failed"

    $ANSIBLE_PLAYBOOK -i localhost, -c local -e@$OXA_PLAYBOOK_CONFIG $OXA_PLAYBOOK_ARGS $OXA_PLAYBOOK --tags "mysql"
    exit_on_error "Execution of OXA MySQL playbook failed" 1 $SUBJECT $CLUSTER_ADMIN_EMAIL $PRIMARY_LOG $SECONDARY_LOG
}

update_stamp_vmss() 
{
    $SUBJECT="${MAIL_SUBJECT} - VMSS Setup Failed"
    # edx playbooks - sandbox with remote mongo/mysql
    $ANSIBLE_PLAYBOOK -i localhost, -c local -e@$OXA_PLAYBOOK_CONFIG edx_sandbox.yml -e "migrate_db=no" --skip-tags=demo_course
    exit_on_error "Execution of edX sandbox playbook failed" 1 $SUBJECT $CLUSTER_ADMIN_EMAIL $PRIMARY_LOG $SECONDARY_LOG
  
    # oxa playbooks
    $ANSIBLE_PLAYBOOK -i localhost, -c local -e@$OXA_PLAYBOOK_CONFIG $OXA_PLAYBOOK_ARGS $OXA_PLAYBOOK --tags "edxapp"
    exit_on_error "Execution of OXA edxapp playbook failed" 1 $SUBJECT $CLUSTER_ADMIN_EMAIL $PRIMARY_LOG $SECONDARY_LOG
}

update_scalable_mongo() {
  # edx playbooks - mongo
  $ANSIBLE_PLAYBOOK -i localhost, -c local -e@$OXA_PLAYBOOK_CONFIG edx_mongo.yml
  exit_on_error "Execution of edX Mongo playbook failed"
  
  # oxa playbooks - mongo (enable when customized)
  #$ANSIBLE_PLAYBOOK -i localhost, -c local -e@$OXA_PLAYBOOK_CONFIG $OXA_PLAYBOOK_ARGS $OXA_PLAYBOOK --tags "mongo"
  #exit_on_error "Execution of OXA Mongo playbook failed"
}

update_scalable_mysql() {
  # edx playbooks - mysql and memcached
  $ANSIBLE_PLAYBOOK -i localhost, -c local -e@$OXA_PLAYBOOK_CONFIG edx_mysql.yml
  exit_on_error "Execution of edX MySQL playbook failed"  
  # minimize tags? "install:base,install:system-requirements,install:configuration,install:app-requirements,install:code"
  $ANSIBLE_PLAYBOOK -i localhost, -c local -e@$OXA_PLAYBOOK_CONFIG edx_sandbox.yml -e "migrate_db=yes" --tags "edxapp-sandbox,install,migrate"
  exit_on_error "Execution of edX MySQL migrations failed"
  
  # oxa playbooks - mysql
  $ANSIBLE_PLAYBOOK -i localhost, -c local -e@$OXA_PLAYBOOK_CONFIG $OXA_PLAYBOOK_ARGS $OXA_PLAYBOOK --tags "mysql"
  exit_on_error "Execution of OXA MySQL playbook failed"
}

update_fullstack() {
  # edx playbooks - fullstack (single VM)
  $ANSIBLE_PLAYBOOK -i localhost, -c local -e@$OXA_PLAYBOOK_CONFIG vagrant-fullstack.yml
  exit_on_error "Execution of edX fullstack playbook failed"

  # oxa playbooks - all (single VM)
  $ANSIBLE_PLAYBOOK -i localhost, -c local -e@$OXA_PLAYBOOK_CONFIG $OXA_PLAYBOOK_ARGS $OXA_PLAYBOOK
  exit_on_error "Execution of OXA playbook failed"
}

remove_progress_file()
{
    echo "Removing progress file at ${PROGRESS_FILE}"
    if [ -e $PROGRESS_FILE ];
    then
        rm $PROGRESS_FILE
    fi

}
###############################################
# START CORE EXECUTION
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

parse_args $@ # pass existing command line arguments

##
## Execute role-independent OXA environment bootstrap
##
BOOTSTRAP_HOME=$(readlink -f $(dirname $0))
OXA_PATH="/oxa"

# OXA Tools
OXA_TOOLS_REPO="https://github.com/${OXA_TOOLS_PUBLIC_GITHUB_ACCOUNTNAME}/${OXA_TOOLS_PUBLIC_GITHUB_PROJECTNAME}.git"
OXA_TOOLS_PATH=$OXA_PATH/$OXA_TOOLS_PUBLIC_GITHUB_PROJECTNAME

# OXA Tools Config
OXA_TOOLS_CONFIG_PATH=$OXA_PATH/oxa-tools-config
OXA_ENV_PATH=$OXA_TOOLS_CONFIG_PATH/env/$DEPLOYMENT_ENV
OXA_ENV_FILE=$OXA_ENV_PATH/$DEPLOYMENT_ENV.sh

# OXA Configuration
CONFIGURATION_PATH=$OXA_PATH/configuration
OXA_PLAYBOOK_CONFIG=$OXA_PATH/oxa.yml

# setup the installer path & key variables
INSTALLER_BASEPATH="${OXA_TOOLS_PATH}/scripts"

##
## CRON CheckPoint
## We now have support for cron execution at x interval
## Given the possible execution frequency, we want to do the bare minimum
##

# setup crumbs for tracking purposes
TARGET_FILE=/var/log/bootstrap-$EDX_ROLE.log
PROGRESS_FILE=/var/log/bootstrap-$EDX_ROLE.progress

if [ "$CRON_MODE" == "1" ];
then
    echo "Cron execution for ${EDX_ROLE} on ${HOSTNAME} detected."

    # check if we need to run the setup
    RUN_BOOTSTRAP=$(get_bootstrap_status)
    TIMESTAMP=`date +"%D %T"`

    case "$RUN_BOOTSTRAP" in
        "0")
            echo "${TIMESTAMP} : Bootstrap is not complete. Proceeding with setup..."
            ;;
        "1")
            echo "${TIMESTAMP} : Bootstrap is not complete. Waiting on backend bootstrap..."
            exit
            ;;
        "2")
            echo "${TIMESTAMP} : Bootstrap is complete."
            exit
            ;;
        "3")
            echo "${TIMESTAMP} : Bootstrap is in progress."
            exit
            ;;
    esac

    # setup the lock to indicate setup is in progress
    touch $PROGRESS_FILE
fi

# Note when we started
TIMESTAMP=`date +"%D %T"`
STATUS_MESSAGE="${TIMESTAMP} :: Starting bootstrap of ${EDX_ROLE} on ${HOSTNAME}"
echo $STATUS_MESSAGE

setup

##
## Execute role-based automation (edX and OXA playbooks)
## stamp note: assumes DB installations and SSH keys are already in place
##
PATH=$PATH:/edx/bin
ANSIBLE_PLAYBOOK=ansible-playbook
OXA_PLAYBOOK=$OXA_TOOLS_PATH/playbooks/oxa_configuration.yml
OXA_PLAYBOOK_ARGS="-e oxa_tools_path=$OXA_TOOLS_PATH -e oxa_tools_config_path=$OXA_TOOLS_CONFIG_PATH"
OXA_SSH_ARGS="-u $ADMIN_USER --private-key=/home/$ADMIN_USER/.ssh/id_rsa"

# Fixes error: RPC failed; result=56, HTTP code = 0'
# fatal: The remote end hung up unexpectedly
git config --global http.postBuffer 1048576000

cd $CONFIGURATION_PATH/playbooks
case "$EDX_ROLE" in
  jb)
    update_stamp_jb
    ;;
  vmss)
    update_stamp_vmss
    ;;
  edxapp)
    # scalable and stamp vmss are equivalent; can combine vmss and edxapp once stamp is ready
    update_stamp_vmss
    ;;
  mongo)
    update_scalable_mongo
    ;;
  mysql)
    update_scalable_mysql
    ;;
  fullstack)
    update_fullstack
    ;;
  *)
    display_usage
    ;;
esac

# check for the progress files & clean it up
remove_progress_file

# Note when we ended
# log a closing message and leave expected bread crumb for status tracking
TIMESTAMP=`date +"%D %T"`
STATUS_MESSAGE="${TIMESTAMP} :: Completed bootstrap of ${EDX_ROLE} on ${HOSTNAME}"
echo $STATUS_MESSAGE

echo "Creating Phase 1 Crumb at '$TARGET_FILE''"
touch $TARGET_FILE

# remove the cron install job
if [[ -e $CRON_INSTALLER_SCRIPT ]]; 
then  
    log "Uninstalling cron job: Background Installer Script"
    crontab -l | grep -v "sudo bash $CRON_INSTALLER_SCRIPT" | crontab -

    rm $CRON_INSTALLER_SCRIPT
fi