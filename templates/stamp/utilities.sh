#!/bin/bash

# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

# ERROR CODES: 
# TODO: move to common script
ERROR_CRONTAB_FAILED=4101
ERROR_GITINSTALL_FAILED=5101
ERROR_MONGOCLIENTINSTALL_FAILED=5201
ERROR_MYSQLCLIENTINSTALL_FAILED=5301

#############################################################################
# Log a message
#############################################################################

log()
{
    # By default, we'd like logged messages to be sent to syslog. 
    # We also want to enable logging for error messages
    
    # $1 - the message to log
    # $2 - flag for error message = 1 (only presence test)
    
    TIMESTAMP=`date +"%D %T"`
    
    # check if this is an error message
    LOG_MESSAGE="${TIMESTAMP} :: $1"
    
    if [ ! -z $2 ]; then
        # stderr logging
        LOG_MESSAGE="${TIMESTAMP} :: [ERROR] $1"
        echo $LOG_MESSAGE >&2
    else
        echo $LOG_MESSAGE
    fi
    
    # send the message to syslog
    logger $1
}

#############################################################################
# Apply memory configuration for the current server 
#############################################################################

tune_memory()
{
    log "Disabling THP (transparent huge pages)"

    # Disable THP on a running system
    echo never > /sys/kernel/mm/transparent_hugepage/enabled
    echo never > /sys/kernel/mm/transparent_hugepage/defrag

    # Disable THP upon reboot
    cp -p /etc/rc.local /etc/rc.local.`date +%Y%m%d-%H:%M`
    sed -i -e '$i \ if test -f /sys/kernel/mm/transparent_hugepage/enabled; then \
              echo never > /sys/kernel/mm/transparent_hugepage/enabled \
          fi \ \
        if test -f /sys/kernel/mm/transparent_hugepage/defrag; then \
           echo never > /sys/kernel/mm/transparent_hugepage/defrag \
        fi \
        \n' /etc/rc.local
}

#############################################################################
# Apply system tuning for the current server 
#############################################################################

tune_system()
{
    log "Adding local machine for IP address resolution"

    # Add local machine name to the hosts file to facilitate IP address resolution
    if grep -q "${HOSTNAME}" /etc/hosts
    then
      log "${HOSTNAME} was found in /etc/hosts"
    else
      log "${HOSTNAME} was not found in and will be added to /etc/hosts"
      # Append it to the hosts file if not there
      echo "127.0.0.1 ${HOSTNAME}" >> /etc/hosts
      log "Hostname ${HOSTNAME} added to /etc/hosts"
    fi    
}

#############################################################################
# Configure Blob storage attached to current server 
#############################################################################

configure_datadisks()
{
    # Stripe all of the data 
    log "Formatting and configuring the data disks"

    # vm-disk-utils-0.1 can install mdadm which installs postfix. The postfix
    # installation cannot be made silent using the techniques that keep the
    # mdadm installation quiet: a) -y AND b) DEBIAN_FRONTEND=noninteractive.
    # Therefore, we'll install postfix early with the "No configuration" option.
    echo "postfix postfix/main_mailer_type select No configuration" | sudo debconf-set-selections
    sudo apt-get install -y postfix

    bash ./vm-disk-utils-0.1.sh -b $DATA_DISKS -s
}

#############################################################################
# Install GIT client
#############################################################################

install-git()
{
    if type git >/dev/null 2>&1; then
        log "Git already installed"
    else
        log "Installing Git Client"

        log "Updating Repository"
        apt-get update

        apt-get install -y git
        exit_on_error "Failed to install the GIT clienton ${HOSTNAME} !" $ERROR_GITINSTALL_FAILED
    fi

    log "Git client installed"
}

#############################################################################
# Install Mongo Shell
#############################################################################

install-mongodb-shell()
{
    if type mongo >/dev/null 2>&1; then
        log "MongoDB Shell is already installed"
    else
        log "Installing MongoDB Shell"
        
        PACKAGE_URL=http://repo.mongodb.org/apt/ubuntu
        SHORT_RELEASE_NUMBER=`lsb_release -sr`
        SHORT_CODENAME=`lsb_release -sc`

        if (( $(echo "$SHORT_RELEASE_NUMBER > 16" |bc -l) ))
        then
            apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927
            echo "deb ${PACKAGE_URL} "${SHORT_CODENAME}"/mongodb-org/3.2 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-3.2.list
        else
            apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
            echo "deb ${PACKAGE_URL} "${SHORT_CODENAME}"/mongodb-org/3.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-3.0.list
        fi

        log "Updating Repository"
        apt-get update

        log "Installing Mongo Shell"
        apt-get install -y mongodb-org-shell
        exit_on_error "Failed to install the Mongo client on ${HOSTNAME} !" $ERROR_MONGOCLIENTINSTALL_FAILED
    fi

    log "Mongo Shell installed"
}

#############################################################################
# Install Mysql Client
#############################################################################

install-mysql-client()
{
    if type mysql >/dev/null 2>&1; then
        log "Mysql Client is already installed"
    else
        log "Updating Repository"
        apt-get update

        log "Installing Mysql Client"
        apt-get install -y mysql-client-core*
        exit_on_error "Failed to install the Mysql client on ${HOSTNAME} !" $ERROR_MYSQLCLIENTINSTALL_FAILED
    fi

    log "Mysql client installed"
}

#############################################################################
# Setup SSH
#############################################################################

setup-ssh()
{
    log "Setting up SSH"

    # implicit assumptions: private repository with secrets has been cloned and certificates live at /{repository_root}/env/{cloud}/id_rsa*
    REPOSITORY_ROOT=$1;
    CLOUD=$2;
    ADMIN_USER=$3

    CERTS_PATH="${REPOSITORY_ROOT}/env/${CLOUD}"

    # this sets up the ROOT user
    log "Setting up SSH for 'ROOT'"
    cp $CERTS_PATH/id_rsa* ~/.ssh
    chmod 600 ~/.ssh/id_rsa
    chmod 644 ~/.ssh/id_rsa.pub

    # setup the admin user
    if [[ -e /home/$ADMIN_USER ]]; then  
        log "Setting up SSH for '${ADMIN_USER}'"
        cp $CERTS_PATH/id_rsa* /home/$ADMIN_USER/.ssh
        chmod 600 /home/$ADMIN_USER/.ssh/id_rsa
        chmod 644 /home/$ADMIN_USER/.ssh/id_rsa.pub
        chown $ADMIN_USER:$ADMIN_USER /home/$ADMIN_USER/.ssh/id_rsa*
    fi
}

#############################################################################
# Clone GitHub Repository
#############################################################################

clone_repository()
{
    # required params
    ACCOUNT_NAME=$1; PROJECT_NAME=$2; BRANCH=$3

    #optional args
    ACCESS_TOKEN=$4; REPO_PATH=$5

    # Validate parameters
    if [ "$ACCOUNT_NAME" == "" ] || [ "$PROJECT_NAME" == "" ] || [ "$BRANCH" == "" ] ;
    then
        log "You must specify the GitHub account name, project name and branch " "ERROR"
        exit 3
    fi
    
    # setup the access token 
    if [ ! -z $ACCESS_TOKEN ]
    then
        ACCESS_TOKEN_WITH_SEPARATOR="${ACCESS_TOKEN}@github.com"
    else
        ACCESS_TOKEN_WITH_SEPARATOR="github.com"
    fi

    # if repository path is not specified, default it to the user's home directory'
    if [ -z $REPO_PATH ]
    then
        REPO_PATH=~/$PROJECT_NAME
    fi 

    # clean up any residue of the repository
    clean_repository $REPO_PATH

    log "Cloning the project with: https://${ACCESS_TOKEN_WITH_SEPARATOR}/${ACCOUNT_NAME}/${PROJECT_NAME}.git from the '$BRANCH' branch and saved at $REPO_PATH"
    git clone -b $BRANCH https://$ACCESS_TOKEN_WITH_SEPARATOR/$ACCOUNT_NAME/$PROJECT_NAME.git $REPO_PATH
}

#############################################################################
# Clean GitHub Repository - delete only
#############################################################################

clean_repository()
{
    REPO_PATH=$1

    log "Cleaning up the cloned GitHub Repository at '${REPO_PATH}'"
    if [ -d "$REPO_PATH" ]; 
    then
        rm -rf $REPO_PATH
    fi
}

#############################################################################
# Get Machine Role 
#############################################################################

get_machine_role()
{
    # determine the role of the machine based on its name
    if [[ $HOSTNAME =~ ^(.*)jb$ ]]; then
        MACHINE_ROLE="jumpbox"
    elif [[ $HOSTNAME =~ ^(.*)mongo[0-3]{1}$ ]]; then
        MACHINE_ROLE="mongodb"
    elif [[ $HOSTNAME =~ ^(.*)mysql[0-3]{1}$ ]]; then
        MACHINE_ROLE="mysql"
    elif [[ $HOSTNAME =~ ^(.*)vmss(.*)$ ]]; then
        MACHINE_ROLE="vmss"
    else
        #log "Could not determine the role of the '${HOSTNAME}'. Defaulting to 'unknown' role"
        MACHINE_ROLE="unknown"
    fi

    #log "Resolving ${HOSTNAME} to ${MACHINE_ROLE}"

    echo $MACHINE_ROLE
}

#############################################################################
# Print Script Header
#############################################################################

print_script_header()
{
    SCRIPT_NAME=`basename "$0"`

    log "-"
    log "#############################################"
    log "Starting ${SCRIPT_NAME}"
    log "#############################################"
    log "-"
}

#############################################################################
# Sync Repo
# TODO: reconcile duplication with clone_repository
#############################################################################

sync_repo() 
{
    REPO_URL=$1; REPO_VERSION=$2; REPO_PATH=$3
    REPO_TOKEN=$4 # optional
  
    if [ "$#" -lt 3 ]; then
        echo "sync_repo: invalid number of arguments" && exit 1
    fi
  
    # todo: scorch support?
  
    if [[ ! -d $REPO_PATH ]]; then
        sudo mkdir -p $REPO_PATH
        sudo git clone ${REPO_URL/github/$REPO_TOKEN@github} $REPO_PATH
    else
        pushd $REPO_PATH
        sudo git pull
        popd
    fi

    pushd $REPO_PATH && sudo git checkout ${REPO_VERSION:-master} && popd
}

#############################################################################
# Is Args Valid 
#############################################################################

is_valid_arg() 
{
    local list="$1"
    local arg="$2"

    if [[ $list =~ (^|[[:space:]])"$arg"($|[[:space:]]) ]] ; then
        result=0
    else
        result=1
    fi

    return $result
}

#############################################################################
# Exit on  Error
#############################################################################
exit_on_error()
{
    if [[ $? -ne 0 ]]; then
        log $1 1
        if [ ! -z $2 ]; then
            exit 1
        else
            exit $2
        fi
    fi
}