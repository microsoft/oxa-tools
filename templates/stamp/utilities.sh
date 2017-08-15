#!/bin/bash

# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

# ERROR CODES: 
# TODO: move to common script
ERROR_CRONTAB_FAILED=4101
ERROR_GITINSTALL_FAILED=5101
ERROR_MONGOCLIENTINSTALL_FAILED=5201
ERROR_MYSQLCLIENTINSTALL_FAILED=5301
ERROR_MYSQLUTILITIESINSTALL_FAILED=5302
ERROR_POWERSHELLINSTALL_FAILED=5401
ERROR_HYDRATECONFIG_FAILED=5410
ERROR_BCINSTALL_FAILED=5402
ERROR_NODEINSTALL_FAILED=6101
ERROR_AZURECLI_FAILED=6201
ERROR_AZURECLI_SCRIPT_DOWNLOAD_FAILED=6202
ERROR_AZURECLI2_INSTALLATION_FAILED=6203
ERROR_AZURECLI_INVALID_OSVERSION=6204

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
    logger "$1"
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
    echo "postfix postfix/main_mailer_type select No configuration" | debconf-set-selections
    apt-get install -y postfix

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
# Install Get Text 
#############################################################################

install-gettext()
{
    # Ensure that gettext (which includes envsubst) is installed
    if [ $(dpkg-query -W -f='${Status}' gettext 2>/dev/null | grep -c "ok installed") -eq 0 ];
    then
        log "Installing Get Text"
        apt-get install -y gettext;
        exit_on_error "Failed to install the GetText package on ${HOSTNAME} !"
    else
        log "Get Text is already installed"
    fi

    log "Get Text installed"
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

        if (( $(echo "$SHORT_RELEASE_NUMBER > 16" | bc -l) ))
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
# Install Mongo Dump and Restore
#############################################################################

install-mongodb-tools()
{
    install-mongodb-shell

    if type mongodump >/dev/null 2>&1 && type mongorestore >/dev/null 2>&1; then
        log "mongodump and mongorestore are already installed"
    else
        log "Installing Mongo Tools (mongodump and mongorestore)"
        apt-get install -y mongodb-org-tools
        exit_on_error "Failed to install the Mongo dump/restore on ${HOSTNAME} !" $ERROR_MONGOCLIENTINSTALL_FAILED
    fi

    log "Mongo Tools installed"
}


#############################################################################
# Install BC
#############################################################################

install-bc()
{
    if type bc >/dev/null 2>&1; then
        log "BC is already installed"
    else
        log "Installing BC"
        apt-get install -y bc
        exit_on_error "Failed to install BC on ${HOSTNAME} !" $ERROR_BCINSTALL_FAILED
    fi

    log "BC utility installed"
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
        apt-get update -y -qq

        log "Installing Mysql Client"
        RELEASE_DESCRIPTION=`lsb_release -sd`

        if [[ $RELEASE_DESCRIPTION =~ "14.04" ]]; then
          log "Installing Mysql Client 5.5 for '$RELEASE_DESCRIPTION'"
          apt-get install -y mysql-client-core-5.5
        else
          log "Installing Mysql Client Core * for '$RELEASE_DESCRIPTION'"
          apt-get install -y mysql-client-core*
        fi

        exit_on_error "Failed to install the Mysql client on ${HOSTNAME} !" $ERROR_MYSQLCLIENTINSTALL_FAILED
    fi

    log "Mysql client installed"
}

#############################################################################
# Install Mysql Dump
#############################################################################

install-mysql-dump()
{
    if type mysqldump >/dev/null 2>&1; then
        log "Mysql Dump is already installed"
    else
        log "Updating Repository"
        apt-get update -y -qq

        log "Installing Mysql Dump"
        apt-get install -y mysql-client
        exit_on_error "Failed to install the Mysql dump on ${HOSTNAME} !" $ERROR_MYSQLCLIENTINSTALL_FAILED
    fi

    log "Mysql dump installed"
}

#############################################################################
# Install Mysql Utilities
#############################################################################

install-mysql-utilities()
{
    if type mysqlfailover >/dev/null 2>&1; then
        log "Mysql Utilities is already installed"
    else
        log "Updating Repository"
        apt-get update -y -qq

        log "Installing Mysql Utilities"
        apt-get install -y mysql-utilities
        exit_on_error "Failed to install the Mysql utilities on ${HOSTNAME} !" $ERROR_MYSQLUTILITIESINSTALL_FAILED
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
    exit_on_error "Setting up SSH for 'ROOT' Failed on $HOST"

    chmod 600 ~/.ssh/id_rsa
    chmod 644 ~/.ssh/id_rsa.pub

    # setup the admin user
    if [[ -e /home/$ADMIN_USER ]]; then  
        log "Setting up SSH for '${ADMIN_USER}'"
        cp $CERTS_PATH/id_rsa* /home/$ADMIN_USER/.ssh
        exit_on_error "Setting up SSH for '{ADMIN_USER}' Failed on $HOST"

        chmod 600 /home/$ADMIN_USER/.ssh/id_rsa
        chmod 644 /home/$ADMIN_USER/.ssh/id_rsa.pub
        chown $ADMIN_USER:$ADMIN_USER /home/$ADMIN_USER/.ssh/id_rsa*
    fi
}

#todo: replace all instances of 'github.com' with this function
#############################################################################
# Get GitHub Url. Examples:
#   1) CONFIGURATION=`get_github_url "$CONFIGURATION_ORG" "$CONFIGURATION_FOLDER"`
#   2) SECRET_REPO=`get_github_url "$ORG" "$REPO" "$TOKEN"`
#############################################################################

get_github_url()
{
    if [ -z $3 ]; then
        echo "https://github.com/$1/$2.git"
    else
        echo "https://$3@github.com/$1/$2.git"
    fi
}

#############################################################################
# Clone GitHub Repository (will scorch existing directory)
#############################################################################

clone_repository()
{
    # Required params
    ACCOUNT_NAME=$1; PROJECT_NAME=$2; BRANCH=$3

    # Optional args
    ACCESS_TOKEN=$4; REPO_PATH=$5

    # Validate parameters
    if [ -z $ACCOUNT_NAME ] || [ -z $PROJECT_NAME ] || [ -z $BRANCH ] ;
    then
        log "You must specify the GitHub account name, project name and branch " "ERROR"
        exit 3
    fi

    # If repository path is not specified then use home directory
    if [ -z $REPO_PATH ]
    then
        REPO_PATH=~/$PROJECT_NAME
    fi 

    # Clean up any residue of the repository. (scorch)
    clean_repository $REPO_PATH

    #todo: We don't provide the token here because sync_repo() will try adding it again. See todo in sync_repo().
    REPO_URL=`get_github_url "$ACCOUNT_NAME" "$PROJECT_NAME"`

    sync_repo $REPO_URL $BRANCH $REPO_PATH $ACCESS_TOKEN
}

#############################################################################
# Clean GitHub Repository - delete only (scorch)
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
# Clone or Sync Repo (as the name implies: this will not scorch an existing enlistment, but sync it)
#############################################################################

sync_repo()
{
    REPO_URL=$1; REPO_VERSION=$2; REPO_PATH=$3
    REPO_TOKEN=$4 # optional

    if [ "$#" -lt 3 ]; then
        echo "sync_repo: invalid number of arguments" && exit 1
    fi
  
    if [[ ! -d $REPO_PATH ]]; then
        sudo mkdir -p $REPO_PATH
        # todo: we should prevent adding REPO_TOKEN more than once. One option is to use get_github_url()
        #   to create the url "just-in-time" instead of taking a url as a parameter.
        sudo git clone --recursive ${REPO_URL/github/$REPO_TOKEN@github} $REPO_PATH
        exit_on_error "Failed cloning repository $REPO_URL to $REPO_PATH"
    else
        pushd $REPO_PATH
        sudo git pull --all
        exit_on_error "Failed syncing repository $REPO_URL to $REPO_PATH"
        popd
    fi

    pushd $REPO_PATH
    sudo git checkout ${REPO_VERSION:-master}
    exit_on_error "Failed checking out branch $REPO_VERSION from repository $REPO_URL in $REPO_PATH"
    popd
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
# Send mail notification
#############################################################################

send_notification()
{
    MESSAGE=$1; SUBJECT=$2; TO=$3; 
    MAIN_LOGFILE=$4; SECONDARY_LOGFILE=$5
    
    # if for some reason, mail isn't already installed, just go quietly
    if ! type "mail" > /dev/null 2>&1; then
        log "Mail not installed"
        exit 0;
    fi

    if [ "$#" -ge 3 ]; 
    then
        # we have sufficient inputs to send mail
        if [[ -f $SECONDARY_LOGFILE ]] && [[ -f $MAIN_LOGFILE ]]; then
            echo "$MESSAGE" | mail -s "$SUBJECT" "$TO" -A "$MAIN_LOGFILE" -A "$SECONDARY_LOGFILE"
        elif [[ -f $MAIN_LOGFILE ]]; then
            echo "$MESSAGE" | mail -s "$SUBJECT" "$TO" -A "$MAIN_LOGFILE"
        elif [[ -f $SECONDARY_LOGFILE ]]; then
            echo "$MESSAGE" | mail -s "$SUBJECT" "$TO" -A "$SECONDARY_LOGFILE"
        else
            echo "$MESSAGE" | mail -s "$SUBJECT" "$TO"
        fi
    else
        log "Insufficient parameters specified for sending mail"
    fi
}

#############################################################################
# Exit if not root user
#############################################################################

exit_if_limited_user() 
{
    if [ "${UID}" -ne 0 ];
    then
        log "Script executed without root permissions"
        echo "You must be root to run this program." >&2
        exit 3
    fi
}

#############################################################################
# Exit on  Error
#############################################################################
exit_on_error()
{
    if [[ $? -ne 0 ]]; then
        log "${1}" 1

        if [ "$#" -gt 3 ]; 
        then
            # send a notification (if possible)
            MESSAGE="${1}"; SUBJECT="${3}"; TO="${4}"; MAIN_LOGFILE="${5}"; SECONDARY_LOGFILE="${6}"
            send_notification "${MESSAGE}" "${SUBJECT}" "${TO}" "${MAIN_LOGFILE}" "${SECONDARY_LOGFILE}"
        fi

        # exit with a custom error code (if one is specified)
        if [ ! -z $2 ]; then
            exit 1
        else
            exit $2
        fi
    fi
}

#############################################################################
# Install Powershell
#############################################################################

install-powershell()
{
    log "Installing Powershell"

    wget https://raw.githubusercontent.com/PowerShell/PowerShell/v6.0.0-alpha.15/tools/download.sh  -O ~/powershell_installer.sh

    # make sure we have the downloaded file
    if [ -f ~/powershell_installer.sh ]; then
        exit_on_error "The powershell installation script could not be downloaded" $ERROR_POWERSHELLINSTALL_FAILED
    fi

    # the installer script requires a prompt/confirmation to install the powershell package.
    # this needs to be disabled for automation purposes
    sed -i "s/sudo apt-get install -f.*/sudo apt-get install -y -f/I" ~/powershell_installer.sh

    # execute the installer
    bash ~/powershell_installer.sh

    # validate powershell is installed
    if [ -f /usr/bin/powershell ]; then
        exit_on_error "Powershell installation failed ${HOSTNAME} !" $ERROR_POWERSHELLINSTALL_FAILED
    fi
}

install-azurepowershellcmdlets()
{
    log "Installing Azure Powershell Cmdlets"

    # set the PSGallery as a trusted
    log "Trusting PSGallery"
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

    log "Installing Azure RM cmdlets"
    Install-Module AzureRM

    log "Installing Azure cmdlets"
    Install-Module Azure
}

#############################################################################
# Hydrate Configurations (fetch configs from keyvault)
#############################################################################

hydrate-configurations()
{
    # get a reference to the oxa-tools repository root
    OXA_TOOLS_REPO_PATH=$1;
    if [[ ! -d OXA_TOOLS_REPO_PATH ]]; then
        exit_on_error "OXA Tools repository path specified at '${OXA_TOOLS_REPO_PATH}' doesn't exist!" $ERROR_HYDRATECONFIG_FAILED
    fi

    # now check for the powershell script itself
    HYDRATION_SCRIPT="${HYDRATION_SCRIPT}/scripts/Process-OxaToolsKeyVaultConfiguration.ps1"

    if [ -f "${HYDRATION_SCRIPT}" ]; then
        exit_on_error "Keyvault Hydration script was not found at ${HYDRATION_SCRIPT}!" $ERROR_HYDRATECONFIG_FAILED
    fi

    # call the powershell keyvault configuration script in hydration mode
    /usr/bin/powershell $HYDRATION_SCRIPT -
}


#############################################################################
# Install Azure CLI
#############################################################################

install-azure-cli()
{
    if type azure >/dev/null 2>&1; then
        log "Azure CLI is already installed"
    else
        log "Updating Repository"
        apt-get -y -qq update

        # Note: nodejs-legacy is required for Ubuntu14 and above.
        short_release_number=`lsb_release -sr`
        if [[ "$short_release_number" > 13 ]]; then
            log "Installing nodejs-legacy"
            apt-get install -y nodejs-legacy
            exit_on_error "Failed to install nodejs-legacy on ${HOSTNAME} !" $ERROR_NODEINSTALL_FAILED
        fi

        if type npm >/dev/null 2>&1; then
            log "npm is already installed"
        else
            log "Installing npm"
            # aptitude install npm -y
            apt-get install -y npm
            exit_on_error "Failed to install npm on ${HOSTNAME} !" $ERROR_NODEINSTALL_FAILED
        fi

        log "Installing azure cli"
        npm install -g azure-cli
        exit_on_error "Failed to install azure cli on ${HOSTNAME} !" $ERROR_AZURECLI_FAILED

        log "Suppressing telemetry collection"
        azure telemetry --disable
    fi

    log "Azure CLI installed"
}

install-azure-cli-2()
{
    # Instructions: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli#apt-get

    if type az >/dev/null 2>&1; then
        log "Azure CLI 2.0 is already installed"
    else

        log "Install Azure CLI 2.0"
        log "Adding Azure Cli 2.0 Repository for package installation"
        echo "deb [arch=amd64] https://apt-mo.trafficmanager.net/repos/azure-cli/ wheezy main" | tee /etc/apt/sources.list.d/azure-cli.list
        apt-key adv --keyserver apt-mo.trafficmanager.net --recv-keys 417A0893
    
        log "Updating Repository"
        apt-get update -y -qq

        short_release_number=`lsb_release -sr`

        log "Installing Azure CLI 2.0 pre-requisites"
        apt-get -y install apt-transport-http

        if [[ $(echo "$short_release_number > 15" | bc -l) ]]; then
            sudo apt-get install -y libssl-dev libffi-dev python-dev build-essential

        elif [[ $(echo "$short_release_number > 12" | bc -l) ]]; then
            sudo apt-get install -y libssl-dev libffi-dev python-dev

        else
            exit $ERROR_AZURECLI_INVALID_OSVERSION
        fi

        log "Installing Azure CLI 2.0"
        apt-get -y install azure-cli
        exit_on_error "Failed installing azure cli 2.0 on ${HOSTNAME} !" $ERROR_AZURECLI2_INSTALLATION_FAILED
    fi
}

#############################################################################
# Install jq - Command-line JSON processor
#############################################################################

install-json-processor()
{
    if type jq >/dev/null 2>&1; then
        log "JSON Processor is already installed"
    else
        log "Updating Repository"
        apt-get -y -qq update

        log "Installing jq - Command-line JSON processor"
        apt-get install -y jq
        exit_on_error "Failed to install jq"
    fi

    log "JSON Processor installed"
}

#############################################################################
# Install GIT client
#############################################################################

install-mailer()
{
    SMTP_SERVER=$1; SMTP_SERVER_PORT=$2; SMTP_AUTH_USER=$3; SMTP_AUTH_USER_PASSWORD=$4; CLUSTER_ADMIN_EMAIL=$5;

    # support forwarding emails sent to the OS admin user to the cluster admin email address
    os_admin_username=$6

    if [ "$#" -lt 5 ]; then
        echo "Install Mailer: invalid number of arguments" && exit 1
    fi

    log "Installing Mail Utilities"

    log "Updating Repository"
    apt-get update

    log "Install packages in non-interactive mode"
    debconf-set-selections <<< "postfix postfix/main_mailer_type string 'No Configuration'"

    apt-get install -y mailutils ssmtp
    exit_on_error "Failed to install the GIT clienton ${HOSTNAME} !" $ERROR_GITINSTALL_FAILED

    log "Mail Utilities installed"

    # Configure SMTP
    log "Configuring mailer"
    SMTP_CONFIG_FILE="/etc/ssmtp/ssmtp.conf"

    if [[ -f $SMTP_CONFIG_FILE ]]; then
        log "Removing existing SMTP configuration"
        rm $SMTP_CONFIG_FILE
    fi

    log "Creating new SMTP configuration template"
    tee $SMTP_CONFIG_FILE > /dev/null <<EOF
root={CLUSTER_ADMIN_EMAIL}
mailhub={SMTP_SERVER}:{SMTP_SERVER_PORT}
AuthUser={SMTP_AUTH_USER}
AuthPass={SMTP_AUTH_USER_PASSWORD}
TLS_CA_File=/etc/ssl/certs/ca-certificates.crt
UseTLS=YES
UseSTARTTLS=YES
hostname=localhost
EOF

    # replace the place holders
    log "Populating SMTP configuration with appropriate values"
    sed -i "s/{CLUSTER_ADMIN_EMAIL}/${CLUSTER_ADMIN_EMAIL}/I" $SMTP_CONFIG_FILE
    sed -i "s/{SMTP_SERVER}/${SMTP_SERVER}/I" $SMTP_CONFIG_FILE
    sed -i "s/{SMTP_SERVER_PORT}/${SMTP_SERVER_PORT}/I" $SMTP_CONFIG_FILE
    sed -i "s/{SMTP_AUTH_USER}/${SMTP_AUTH_USER}/I" $SMTP_CONFIG_FILE
    sed -i "s/{SMTP_AUTH_USER_PASSWORD}/${SMTP_AUTH_USER_PASSWORD}/I" $SMTP_CONFIG_FILE

    # Configure ALIASES
    ALIAS_CONFIG_FILE="/etc/ssmtp/revaliases"

    if [[ -f $ALIAS_CONFIG_FILE ]]; then
        log "Removing existing ALIAS configuration"
        rm $ALIAS_CONFIG_FILE
    fi

    log "Creating new ALIAS configuration file"
    tee $ALIAS_CONFIG_FILE > /dev/null <<EOF
root:{CLUSTER_ADMIN_EMAIL}:{SMTP_SERVER}:{SMTP_SERVER_PORT}
postmaster:{CLUSTER_ADMIN_EMAIL}:{SMTP_SERVER}:{SMTP_SERVER_PORT}
{OS_ADMIN_USERNAME}:{CLUSTER_ADMIN_EMAIL}:{SMTP_SERVER}:{SMTP_SERVER_PORT}
EOF
    # replace the place holders
    log "Populating Aliases with appropriate values"
    sed -i "s/{CLUSTER_ADMIN_EMAIL}/${CLUSTER_ADMIN_EMAIL}/I" $ALIAS_CONFIG_FILE
    sed -i "s/{SMTP_SERVER}/${SMTP_SERVER}/I" $ALIAS_CONFIG_FILE
    sed -i "s/{SMTP_SERVER_PORT}/${SMTP_SERVER_PORT}/I" $ALIAS_CONFIG_FILE
    sed -i "s/{OS_ADMIN_USERNAME}/${os_admin_username}/I" $ALIAS_CONFIG_FILE

    log "Completed configuring the mailer"
}

#############################################################################
# Setup Overrides
#############################################################################

setup_deployment_overrides()
{
    # collect the parameters
    OVERRIDES_FILE_PATH="${1}";

    OXA_TOOLS_VERSION="${2}";                                 # Tools
    CONFIGURATION_REPO="${3}"; CONFIGURATION_VERSION="${4}";  # Configuration
    PLATFORM_REPO="${5}"; PLATFORM_VERSION="${6}";            # Platform
    THEME_REPO="${7}"; THEME_VERSION="${8}";                  # Themeing
    EDX_VERSION="${9}"; FORUM_VERSION="${10}";                # MISC
    ANSIBLE_REPO="${11}"; ANSIBLE_VERSION="${12}";            # Ansible

    log "Creating new deployment configuration overrides"

    # For simplicity, we require all parameters are set
    if [ "$#" -lt 12 ]; then
        echo "Not all required deployment overrides have been set. Skipping due to an invalid number of arguments"
        exit 0;
    fi

    # the values being over-written are already established in settings files as values used in various playbooks
    # this function use overrides existing settings and doesn't introduce new ones
    # these settings must batch values present in the cloud configuration files (ie: bvt.sh)
    
    tee "${OVERRIDES_FILE_PATH}" > /dev/null <<EOF
OXA_TOOLS_VERSION={OXA_TOOLS_VERSION}
CONFIGURATION_REPO={CONFIGURATION_REPO}
CONFIGURATION_VERSION={CONFIGURATION_VERSION}
PLATFORM_REPO={PLATFORM_REPO}
PLATFORM_VERSION={PLATFORM_VERSION}
THEME_REPO={THEME_REPO}
THEME_VERSION={THEME_VERSION}
EDX_VERSION={EDX_VERSION}
FORUM_VERSION={FORUM_VERSION}
ANSIBLE_REPO={ANSIBLE_REPO}
ANSIBLE_VERSION=${ANSIBLE_VERSION}
EOF

    # replace the place holders (using # since the repo path will have forward slashes)
    log "Populating overrides with appropriate values"
    sed -i "s#{OXA_TOOLS_VERSION}#${OXA_TOOLS_VERSION}#I" $OVERRIDES_FILE_PATH
    sed -i "s#{CONFIGURATION_REPO}#${CONFIGURATION_REPO}#I" $OVERRIDES_FILE_PATH
    sed -i "s#{CONFIGURATION_VERSION}#${CONFIGURATION_VERSION}#I" $OVERRIDES_FILE_PATH
    sed -i "s#{PLATFORM_REPO}#${PLATFORM_REPO}#I" $OVERRIDES_FILE_PATH
    sed -i "s#{PLATFORM_VERSION}#${PLATFORM_VERSION}#I" $OVERRIDES_FILE_PATH
    sed -i "s#{THEME_REPO}#${THEME_REPO}#I" $OVERRIDES_FILE_PATH
    sed -i "s#{THEME_VERSION}#${THEME_VERSION}#I" $OVERRIDES_FILE_PATH
    sed -i "s#{EDX_VERSION}#${EDX_VERSION}#I" $OVERRIDES_FILE_PATH
    sed -i "s#{FORUM_VERSION}#${FORUM_VERSION}#I" $OVERRIDES_FILE_PATH
    sed -i "s#{ANSIBLE_REPO}#${ANSIBLE_REPO}#I" $OVERRIDES_FILE_PATH
    sed -i "s#{ANSIBLE_VERSION}#${ANSIBLE_VERSION}#I" $OVERRIDES_FILE_PATH

    log "Deployment configuration overrides file has been created at '${OVERRIDES_FILE_PATH}'"
}

#############################################################################
# Setup Backup Parameters
#############################################################################

setup_backup()
{
    # collect the parameters
    backup_configuration="${1}";                            # Backup settings file
    backup_script="${2}";                                   # Backup script (actually take the backup)
    backup_log="${3}";                                      # Log file for backup job

    account_name="${4}"; account_key="${5}";                # Storage Account 
    backupFrequency="${6}";                                 # Backup Frequency
    backupRententionDays="${7}";                            # Backup Retention
    mongoReplicaSetConnectionString="${8}";                 # Mongo replica set connection string
    mysqlServerList="${9}";                                 # Mysql Server List
    databaseType="${10}";                                   # Database Type : mysql|mongo

    databaseUser="${11}"; databasePassword="${12}";         # Credentials for accessing the database for backup purposes
    backupLocalPath="${13}";                                # Database Type : mysql|mongo
    # Optional.
    tempDatabaseUser="${14}"; tempDatabasePassword="${15}"; # Temporary credentials for accessing the backup (optional)

    log "Setting up database backup for '${databaseType}' database(s)"

    # For simplicity, we require all required parameters are set
    if [ "$#" -lt 13 ]; then
        echo "Some required backup configuration parameters are missing"
        exit 1;
    fi

    # persist the settings
    bash -c "cat <<EOF >${backup_configuration}
BACKUP_STORAGEACCOUNT_NAME=${account_name}
BACKUP_STORAGEACCOUNT_KEY=${account_key}
BACKUP_RETENTIONDAYS=${backupRententionDays}
MONGO_REPLICASET_CONNECTIONSTRING=${mongoReplicaSetConnectionString}
MYSQL_SERVER_LIST=${mysqlServerList}
DATABASE_USER=${databaseUser}
DATABASE_PASSWORD=${databasePassword}
TEMP_DATABASE_USER=${tempDatabaseUser}
TEMP_DATABASE_PASSWORD=${tempDatabasePassword}
DATABASE_TYPE=${databaseType}
BACKUP_LOCAL_PATH=${backupLocalPath}
EOF"

    # this file contains secrets (like storage account key). Secure it
    chmod 600 $backup_configuration

    # create the cron job
    cron_installer_script="${backup_script}.${databaseType}"
    lock_file="${cron_installer_script}.lock"
    install_command="sudo flock -n ${lock_file} bash ${backup_script} -s ${backup_configuration} >> ${backup_log} 2>&1"
    echo $install_command > $cron_installer_script

    # secure the file and make it executable
    chmod 700 $cron_installer_script

    # Remove the task if it is already setup
    log "Uninstalling existing backup job for the '${databaseType}' database(s)"
    crontab -l | grep -v "sudo bash ${cron_installer_script}" | crontab -

    # Setup the background job
    log "Installing backup job for the '${databaseType}' database(s)"
    crontab -l | { cat; echo "${backupFrequency} sudo bash ${cron_installer_script}"; } | crontab -
    exit_on_error "Failed setting up '${databaseType}' backups." $ERROR_CRONTAB_FAILED

    # setup the cron job
    log "Completed setting up database backup for '${databaseType}' database(s)"
    # exit 0;
}

#############################################################################
# Set server Time Zone
#############################################################################

set_timezone()
{
    timezone="America/Los_Angeles"

    if [ "$#" -ge 1 ]; then
        $timezone="${1}"
    fi

    log "Setting the timezone for '${HOSTNAME}' to '${timezone}'"
    timedatectl set-timezone $timezone
}