#!/bin/bash

# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

# ERROR CODES: 
# TODO: move to common script
ERROR_MYSQL_STARTUP_FAILED=2001
ERROR_MYSQL_SHUTDOWN_FAILED=2002

# Backup Related Errors
ERROR_DB_BACKUP_FAILED=2010
ERROR_DB_BACKUPSETUP_FAILED=2011

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
ERROR_MYSQL_DATADIRECTORY_MOVE_FAILED=7001
EROR_REPLICATION_MASTER_MISSING=7201
ERROR_HAPROXY_INSTALLER_FAILED=7202
ERROR_HAPROXY_STARTUP_FAILED=7203
ERROR_MYSQL_MOVE_DATADIRECTORY_INSTALLER_FAILED=7210
ERROR_XINETD_INSTALLER_FAILED=7301
ERROR_TOOLS_INSTALLER_FAILED=7401
ERROR_SSHKEYROTATION_INSTALLER_FAILED=7501
ERROR_MEMCACHED_INSTALLER_FAILED=7601
ERROR_PIP_INSTALLER_FAILED=7701

# Mysql failover related errors
ERROR_MYSQL_FAILOVER_INVALIDPROXYPORT=7601
ERROR_MYSQL_FAILOVER_UNKNOWNRESPONSE=7602
ERROR_MYSQL_FAILOVER_FAILED=7603
ERROR_MYSQL_FAILOVER_MARKREADONLY=7604

#############################################################################
# Log a message
#############################################################################

log()
{
    # By default, we'd like logged messages to be sent to syslog. 
    # We also want to enable logging for error messages
    
    # $1 - the message to log
    # $2 - flag for error message = 1 (only presence test)
    # $3 - extra line
    
    # sometimes it is necessary to prepend an extra line
    if [[ ! -z $3 ]] && ( [[ $3 == 1 ]] || [[ $3 == 3 ]] );
    then
        echo " "
    fi

    TIMESTAMP=`date +"%D %T"`
    
    # check if this is an error message
    LOG_MESSAGE="${TIMESTAMP} :: $1"
    
    if [[ ! -z "${2// }" ]]; then
        # stderr logging
        LOG_MESSAGE="${TIMESTAMP} :: [ERROR] $1"
        echo $LOG_MESSAGE >&2
    else
        echo $LOG_MESSAGE
    fi
    
    # sometimes it is necessary to append an extra line
    if [[ ! -z $3 ]] && ( [[ $3 == 2 ]] || [[ $3 == 3 ]] );
    then
        echo " "
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

    local mount_point=${1:-"/datadisks"}

    # vm-disk-utils-0.1 can install mdadm which installs postfix. The postfix
    # installation cannot be made silent using the techniques that keep the
    # mdadm installation quiet: a) -y AND b) DEBIAN_FRONTEND=noninteractive.
    # Therefore, we'll install postfix early with the "No configuration" option.
    apt-wrapper "update"
    echo "postfix postfix/main_mailer_type select No configuration" | debconf-set-selections
    install-wrapper postfix 2 skipUpdate

    # check if the disk utilities exists
    if [[ ! -f ./vm-disk-utils-0.1.sh ]];
    then
        # download the utility
        pushd /tmp
        wget https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/shared_scripts/ubuntu/vm-disk-utils-0.1.sh

        # execute the setup
        bash ./vm-disk-utils-0.1.sh -b "${mount_point}" -s

        # clean up
        rm ./vm-disk-utils-0.1.sh
        popd
    else
        bash ./vm-disk-utils-0.1.sh -b "${mount_point}" -s
    fi
}

#############################################################################
# Install GIT client
#############################################################################

install-git()
{
    if type git >/dev/null 2>&1 ; then
        log "Git already installed"
    else
        install-wrapper "git" $ERROR_GITINSTALL_FAILED
    fi
}

#############################################################################
# Install Get Text 
#############################################################################

install-gettext()
{
    # Ensure that gettext (which includes envsubst) is installed
    if [[ $(dpkg-query -W -f='${Status}' gettext 2>/dev/null | grep -c "ok installed") -eq 0 ]] ; then
        install-wrapper "gettext"
    else
        log "Get Text is already installed"
    fi
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

        install-wrapper "mongodb-org-shell" $ERROR_MONGOCLIENTINSTALL_FAILED
    fi
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
        install-wrapper "mongodb-org-tools" $ERROR_MONGOCLIENTINSTALL_FAILED
    fi
}


#############################################################################
# Install BC
#############################################################################

install-bc()
{
    if type bc >/dev/null 2>&1; then
        log "BC is already installed"
    else
        install-wrapper "bc" $ERROR_BCINSTALL_FAILED
    fi
}

#############################################################################
# Install Mysql Client
#############################################################################

install-mysql-client()
{
    if type mysql >/dev/null 2>&1; then
        log "Mysql Client is already installed"
    else
        log "Installing Mysql Client"
        RELEASE_DESCRIPTION=`lsb_release -sd`

        if [[ $RELEASE_DESCRIPTION =~ "14.04" ]]; then
          log "Installing Mysql Client 5.5 for '$RELEASE_DESCRIPTION'"
          install-wrapper "mysql-client-core-5.5" $ERROR_MYSQLCLIENTINSTALL_FAILED
        else
          log "Installing Mysql Client Core * for '$RELEASE_DESCRIPTION'"
          install-wrapper "mysql-client-core*" $ERROR_MYSQLCLIENTINSTALL_FAILED
        fi
    fi
}

#############################################################################
# Install Mysql Dump
#############################################################################

install-mysql-dump()
{
    if type mysqldump >/dev/null 2>&1; then
        log "Mysql Dump is already installed"
    else
        install-wrapper "mysql-client" $ERROR_MYSQLCLIENTINSTALL_FAILED
    fi
}

#############################################################################
# Install Mysql Utilities
#############################################################################

install-mysql-utilities()
{
    if type mysqlfailover >/dev/null 2>&1; then
        log "Mysql Utilities is already installed"
    else
        install-wrapper "mysql-utilities" $ERROR_MYSQLUTILITIESINSTALL_FAILED
    fi
}

#############################################################################
# Wrapper functions
#############################################################################

apt-wrapper()
{
    operation="$1"

    log "$operation package(s)..."
    apt-get $operation -y -qq --fix-missing
}

install-wrapper()
{
    package="$1"
    error_code="$2"
    no_update="$3"

    if [[ -z $no_update ]] ; then
        apt-wrapper "update"
    fi

    apt-wrapper "install $package"
    exit_on_error "Installing $package Failed on $HOSTNAME" $error_code

    log "$package installed"
}

retry-command()
{
    local command="$1"
    local retry_count="$2"
    local optionalDescription="$3"
    local fix_packages="$4"

    local tasksOfPrev=
    local alreadyUpgraded=
    for (( a=1; a<=$retry_count; a++ )) ; do
        message="$optionalDescription attempt number: $a"

        # Some failures can be resolved by fixing packages.
        if [[ -n "$fix_packages" ]] ; then
            apt-wrapper "update"
            apt-wrapper "install -f"
            dpkg --configure -a
        fi

        install-unbuffer

        log "STARTING ${message}..."

        set -o pipefail
        local logPath="/var/tmp/${a}.txt"
        unbuffer $command | tee $logPath
        local result=$?
        set +o pipefail

        if [[ $result -eq 0 ]] ; then
            log "SUCCEEDED ${message}!"
            break
        fi

        log "FAILED ${message}"

        # Don't continue if ansible failed at the same play twice in a row.
        # The same error will likely happen for each remaining iteration.
        if [[ $command == *"ansible"* ]] || [[ $command == *"sandbox"* ]] ; then
            local tasksOfCur=`grep -o ",.* total tasks" $logPath | grep -o "[0-9]*"`

            if [[ -n $tasksOfPrev ]] && (( $tasksOfCur == $tasksOfPrev )) ; then
                log "Same failure as previous attempt."

                if [[ -z $alreadyUpgraded ]] && [[ -n "$fix_packages" ]] ; then
                    # See if upgrading apt packages solves the failure.
                    # This technique has resolved some fullstack failures.
                    apt-wrapper "upgrade -f"
                    alreadyUpgraded="true"
                else
                    # Give up.
                    break
                fi
            fi

            tasksOfPrev=$tasksOfCur
        fi
    done

    return $result
}

#############################################################################
# Setup Sudo
#############################################################################

install-sudo()
{
    if type sudo >/dev/null 2>&1 ; then
        log "sudo already installed"
        return
    fi

    install-wrapper "sudo"
}

#############################################################################
# Setup expect-dev (for unbuffer)
#############################################################################

install-unbuffer()
{
    if type unbuffer >/dev/null 2>&1 ; then
        log "unbuffer already installed"
        return
    fi

    install-wrapper "expect-dev"
}

#############################################################################
# Setup SSH
#############################################################################

install-ssh()
{
    if [[ -f "/etc/ssh/sshd_config" ]] ; then
        log "SSH already installed"
        return
    fi

    install-wrapper "ssh"
}

setup-ssh()
{
    install-ssh

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
    account_name=$1; project_name=$2; branch=$3

    # Optional args
    access_token=$4; repo_path=$5; repo_tag=$6

    # Validate parameters
    if [[ -z $account_name ]] || [ -z $project_name ] || [[ -z $branch ]] ;
    then
        log "You must specify the GitHub account name, project name and branch " "ERROR"
        exit 3
    fi

    # If repository path is not specified then use home directory
    if [[ -z $repo_path ]];
    then
        repo_path=~/$project_name
    fi 

    # Clean up any residue of the repository. (scorch)
    clean_repository $repo_path

    #todo: We don't provide the token here because sync_repo() will try adding it again. See todo in sync_repo().
    repo_url=`get_github_url "$account_name" "$project_name"`

    sync_repo $repo_url $branch $repo_path $access_token $repo_tag
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
    if [[ $HOSTNAME =~ ^(.*)jb([1-2]?)$ ]]; then
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
    scriptname_override=$1;

    if [[ -z $scriptname_override ]]; then
        SCRIPT_NAME=`basename "$0"`
    else
        SCRIPT_NAME=$scriptname_override
    fi

    log "-" " " 1
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
    repo_url=$1; repo_version=$2; repo_path=$3
    repo_token=$4 # optional
    repo_tag=$5   # optional

    if [ "$#" -lt 3 ]; then
        echo "sync_repo: invalid number of arguments" && exit 1
    fi
  
    log "Syncing the '${repo_url}' repository (Branch='${repo_version}', Tag='${repo_tag}')"

    if [[ ! -d $repo_path ]]; then
        sudo mkdir -p $repo_path
        # todo: we should prevent adding repo_token more than once. One option is to use get_github_url()
        #   to create the url "just-in-time" instead of taking a url as a parameter.
        sudo git clone --recursive ${repo_url/github/$repo_token@github} $repo_path
        exit_on_error "Failed cloning repository $repo_url to $repo_path"
    else
        pushd $repo_path

        sudo git fetch --all --tags --prune
        exit_on_error "Failed syncing repository $repo_url to $repo_path"

        popd
    fi

    pushd $repo_path

    # checkout latest (or up to tag if specified)
    if [[ -z $repo_tag ]];
    then
        sudo git checkout "${repo_version:-master}"
    else
        sudo git checkout "tags/${repo_tag}" "${repo_version:-master}"
    fi

    exit_on_error "Failed checking out branch $repo_version from repository $repo_url in $repo_path"
    popd
}

cherry_pick_wrapper()
{
    local hash=$1
    local email=$2

    if [[ -n $email ]] && ! git config --global --get user.email > /dev/null 2>&1 ; then
        git config --global user.email "$email"
        exit_on_error "Failed to configure git."
    fi

    git cherry-pick -x --strategy=recursive -X theirs $hash --keep-redundant-commits
    exit_on_error "Failed to cherry pick essential fix"
}

#############################################################################
# Create theme directory before edx playbook
#############################################################################
make_theme_dir()
{
    EDXAPP_COMPREHENSIVE_THEME_DIR="$1"
    EDX_PLATFORM_PUBLIC_GITHUB_PROJECTNAME="$2"

    # When the comprehensive theming dirs is specified, edxapp:migrate task fails with :  ImproperlyConfigured: COMPREHENSIVE_THEME_DIRS
    # As an interim mitigation, create the folder if the path specified is not under the edx-platform directory (where the default themes directory is)
    if [[ -n "${EDXAPP_COMPREHENSIVE_THEME_DIR}" ]] && [[ ! -d "${EDXAPP_COMPREHENSIVE_THEME_DIR}" ]] ; then
        # now check if the path specified is within the default edx-platform/themes directory
        if [[ "${EDXAPP_COMPREHENSIVE_THEME_DIR}" == *"${EDX_PLATFORM_PUBLIC_GITHUB_PROJECTNAME}"* ]] ; then
            log "'${EDXAPP_COMPREHENSIVE_THEME_DIR}' falls under the default theme directory. Skipping creation since the edx-platform clone will create it."
        else
            log "Creating comprehensive themeing directory at ${EDXAPP_COMPREHENSIVE_THEME_DIR}"
            mkdir -p "${EDXAPP_COMPREHENSIVE_THEME_DIR}"
            chown -R edxapp:edxapp "${EDXAPP_COMPREHENSIVE_THEME_DIR}"
        fi
    fi
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
        return
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

        if [[ "$#" -gt 3 ]] ; 
        then
            # send a notification (if possible)
            MESSAGE="${1}"; SUBJECT="${3}"; TO="${4}"; MAIN_LOGFILE="${5}"; SECONDARY_LOGFILE="${6}"
            send_notification "${MESSAGE}" "${SUBJECT}" "${TO}" "${MAIN_LOGFILE}" "${SECONDARY_LOGFILE}"
        fi

        # exit with a custom error code (if one is specified)
        if [[ -n $2 ]] ; then
            exit $2
        else
            exit 1
        fi
    fi
}

#############################################################################
# Install Powershell
#############################################################################

install-powershell()
{
    if [[ -f /usr/bin/powershell ]] ; then
        log "Powershell is already installed"
        return
    fi

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
    exit_on_error "Powershell installation failed ${HOSTNAME} !" $ERROR_POWERSHELLINSTALL_FAILED
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
        # Note: nodejs-legacy is required for Ubuntu14 and above.
        short_release_number=`lsb_release -sr`
        if [[ "$short_release_number" > 13 ]]; then
            install-wrapper "nodejs-legacy" $ERROR_NODEINSTALL_FAILED
        fi

        if type npm >/dev/null 2>&1; then
            log "npm is already installed"
        else
            # aptitude install npm -y
            install-wrapper "npm" $ERROR_NODEINSTALL_FAILED
        fi

        log "Installing azure cli"
        npm install -g azure-cli
        exit_on_error "Failed to install azure cli on ${HOSTNAME} !" $ERROR_AZURECLI_FAILED

        log "Suppressing telemetry collection"
        azure telemetry --disable

        log "Azure CLI installed"
    fi
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

        log "Installing Azure CLI 2.0 pre-requisites"
        install-wrapper "apt-transport-https"

        short_release_number=`lsb_release -sr`

        if [[ $(echo "$short_release_number > 15" | bc -l) ]]; then
            install-wrapper "libssl-dev libffi-dev python-dev build-essential"

        elif [[ $(echo "$short_release_number > 12" | bc -l) ]]; then
            install-wrapper "libssl-dev libffi-dev python-dev"

        else
            exit $ERROR_AZURECLI_INVALID_OSVERSION
        fi

        log "Installing Azure CLI 2.0"
        install-wrapper "azure-cli" $ERROR_AZURECLI2_INSTALLATION_FAILED
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
        install-wrapper "jq"
    fi
}

#############################################################################
# Install Mailer
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
    apt-wrapper "update"

    log "Install packages in non-interactive mode"
    debconf-set-selections <<< "postfix postfix/main_mailer_type string 'No Configuration'"
    install-wrapper "mailutils ssmtp" 3 skipUpdate

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

generate_azure_storage_connection_string()
{
    local account_name="${1}"
    local account_key="${2}"
    local endpoint_suffix="${3}"

    echo "DefaultEndpointsProtocol=https;AccountName=${account_name};AccountKey=${account_key};EndpointSuffix=${storageAccountEndpointSuffix}"
}

get_azure_storage_endpoint_suffix()
{
    local suffix=`echo ${1}| base64 --decode`
    
    # default storage account suffix to core.windows.net if not specified
    if [[ -z "${suffix// }" ]]; then

        suffix="core.windows.net"
    fi

    echo $suffix
}

setup_backup()
{
    # collect the parameters
    local backup_configuration="${1}";                                              # Backup settings file
    local backup_script="${2}";                                                     # Backup script (actually take the backup)
    local backup_log="${3}";                                                        # Log file for backup job

    local account_name="${4}";                                                      # Storage Account credentials
    local account_key="${5}";
    local backupFrequency="${6}";                                                   # Backup Frequency
    local backupRententionDays="${7}";                                              # Backup Retention
    local mongoReplicaSetConnectionString="${8}";                                   # Mongo replica set connection string
    local mysqlServerIp="${9}";                                                     # Mysql Server Ip (or HA Proxy Ip)
    local databaseType="${10}";                                                     # Database Type : mysql|mongo

    local databaseUser="${11}";                                                     # Credentials for accessing the database for backup purposes
    local databasePassword="${12}";                           
    local backupLocalPath="${13}";                                                  # Database Type : mysql|mongo
    local mysqlServerPort="${14:-3306}"                                             # Communication port for mysql server (default 3306)
    local clusterAdminEmail="${15}"                                                 # Email address to which backup notifications will be sent
    local azureCliVersion="${16:-1}"                                                # Azure Cli Version to use for backup operations
	
    # Optional.
    local storageAccountEndpointSuffix=`get_azure_storage_endpoint_suffix ${17}`    # Blob storage suffix (defaults to core.windows.net for global azure)
    tempDatabaseUser="${18}"; tempDatabasePassword="${19}";                         # Temporary credentials for accessing the backup (optional)
    
    # generate a storage connection string
    local storage_connection_string=`generate_azure_storage_connection_string "${account_name}" "${account_key}" "${storageAccountEndpointSuffix}"`

    log "Setting up database backup for '${databaseType}' database(s)"

    # For simplicity, we require all required parameters are set
    if [[ "$#" -lt 15 ]]; then
        echo "Some required backup configuration parameters are missing"
        exit 1;
    fi

    # persist the settings
    bash -c "cat <<EOF >${backup_configuration}
BACKUP_STORAGEACCOUNT_NAME=${account_name}
BACKUP_STORAGEACCOUNT_KEY=${account_key}
BACKUP_RETENTIONDAYS=${backupRententionDays}
MONGO_REPLICASET_CONNECTIONSTRING=${mongoReplicaSetConnectionString}
MYSQL_SERVER_IP=${mysqlServerIp}
MYSQL_SERVER_PORT=${mysqlServerPort}
DATABASE_USER=${databaseUser}
DATABASE_PASSWORD=${databasePassword}
TEMP_DATABASE_USER=${tempDatabaseUser}
TEMP_DATABASE_PASSWORD=${tempDatabasePassword}
DATABASE_TYPE=${databaseType}
BACKUP_LOCAL_PATH=${backupLocalPath}
CLUSTER_ADMIN_EMAIL=${clusterAdminEmail}
AZURE_CLI_VERSION=${azureCliVersion}
AZURE_STORAGEACCOUNT_CONNECTIONSTRING=\"${storage_connection_string}\"
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

set-server-timezone()
{
    timezone="America/Los_Angeles"

    if [[ "$#" -ge 1 ]] ; then
        $timezone="${1}"
    fi

    log "Setting the timezone for '${HOSTNAME}' to '${timezone}'"
    timedatectl set-timezone $timezone
}

#############################################################################
# Install HA Proxy
#############################################################################

install_haproxy()
{
    if type haproxy >/dev/null 2>&1; then
        log "HA Proxy is already installed"
    else
        install-wrapper "haproxy" $ERROR_GITINSTALL_FAILED
    fi
}

start_haproxy()
{
    log "Starting HA Proxy Server"

    # add some resilience
    local mysql_admin_username="${1}"
    local mysql_admin_password="${2}"
    local haproxy_server="${3}"
    local haproxy_port="${4}"

    local server_started=0
    local wait_time_seconds=10
    local max_wait_seconds=$(($wait_time_seconds * 10))
    local total_wait_seconds=0

    while [[ $server_started == 0 ]] ;
    do
        service haproxy start

        # run a basic query against the Proxy
        db_response=`mysql -u ${mysql_admin_username} -p${mysql_admin_password} -h ${haproxy_server} -P ${haproxy_port} -e "SHOW DATABASES;"`

        # trim the response before assessing emptiness: null /zero-length
        if [[ -z "${db_response// }" ]];
        then
            sleep $wait_time_seconds;
            ((total_wait_seconds+=$wait_time_seconds))

            if [[ "$total_wait_seconds" -gt "$max_wait_seconds" ]] ;
            then
                log "Exceeded the expected wait time for starting up the haproxy server: $total_wait_seconds seconds"
                exit $ERROR_HAPROXY_STARTUP_FAILED
            fi
        else
            # the server was successfully started and is returning results
            server_started=1
        fi
    done

    log "HA Proxy has been started"
}

stop_haproxy()
{
    # Find out what PID(s) the HaProxy instance is running as (if any)
    haproxy_pid=`ps -ef | grep 'haproxy' | grep -v grep | awk '{print $2}'`
    
    if [[ ! -z "$haproxy_pid" ]]; 
    then
        log "Stopping HA Proxy Server (PID $haproxy_pid)"
        
        service haproxy stop

        # Important not to attempt to start the daemon immediately after it was stopped as unclean shutdown may be wrongly perceived
        sleep 15s
    fi
}


#############################################################################
# Mysql Utilities
#############################################################################

start_mysql()
{
    log "Starting Mysql Server"

    # the server port: default to 3306
    mysql_port=${1:-3306}

    # track the OS version
    os_version=$(lsb_release -rs)

    # we need some resilience here
    local server_started=0
    local wait_time_seconds=10
    local max_wait_seconds=$(($wait_time_seconds * 10))
    local total_wait_seconds=0

    while [[ $server_started == 0 ]] ;
    do
        if [[ $(echo "$os_version > 16" | bc -l) == 1 ]] ;
        then
            systemctl start mysqld
            exit_on_error "Could not restart mysqld on '${HOSTNAME}' !" "${ERROR_MYSQL_DATADIRECTORY_MOVE_FAILED}" "${subject}" $admin_email_address

            # enable mysqld on startup
            systemctl enable mysqld
            exit_on_error "Could not enable mysqld for startup on '${HOSTNAME}' !" "${ERROR_MYSQL_DATADIRECTORY_MOVE_FAILED}" "${subject}" $admin_email_address
        else
            service mysql start
            exit_on_error "Could not restart mysqld on '${HOSTNAME}' !" "${ERROR_MYSQL_DATADIRECTORY_MOVE_FAILED}" "${subject}" $admin_email_address
        fi

        # Wait for Mysql server to start/initialize for the first time (this may take up to a minute or so)
        (echo >/dev/tcp/localhost/$mysql_port) &>/dev/null && server_started=1 || server_started=0

        # if the server isn't yet started, wait $wait_time_seconds seconds before retry
        if [[ $server_started == 0 ]] ;
        then
            sleep $wait_time_seconds;
            ((total_wait_seconds+=$wait_time_seconds))

            if [[ "$total_wait_seconds" -gt "$max_wait_seconds" ]] ;
            then
                log "Exceeded the expected wait time for starting up the server: $total_wait_seconds seconds"
                exit $ERROR_MYSQL_STARTUP_FAILED
            fi
        fi
    done

    log "Mysql server has been started"
}

stop_mysql()
{

    # we need some resilience here
    local server_stopped=0
    local wait_time_seconds=15
    local max_wait_seconds=$(($wait_time_seconds * 10))
    local total_wait_seconds=0

    while [[ $server_stopped == 0 ]] ;
    do

        # Find out what PID the Mysql instance is running as (if any)
        MYSQLPID=`ps -ef | grep '/usr/sbin/mysqld' | grep -v grep | awk '{print $2}'`
        
        if [[ ! -z "$MYSQLPID" ]]; then
            log "Stopping Mysql Server (PID $MYSQLPID)"
            
            kill -15 $MYSQLPID

            # Important not to attempt to start the daemon immediately after it was stopped as unclean shutdown may be wrongly perceived
            # We expect the sleep to happen below since we are NOT marking the server as stopped until we validate in the 
            # next iteration

        else
            log "All Mysql Server Processes are stopped"
            server_stopped=1
        fi
        
        # if the server isn't yet stopped, wait $wait_time_seconds seconds before retry
        if [[ $server_stopped == 0 ]] ;
        then
            sleep $wait_time_seconds;
            ((total_wait_seconds+=$wait_time_seconds))

            if [[ "$total_wait_seconds" -gt "$max_wait_seconds" ]] ;
            then
                log "Exceeded the expected wait time for stopping the server: $total_wait_seconds seconds"
                exit $ERROR_MYSQL_SHUTDOWN_FAILED
            fi
        fi
    done   
}

# restart mysql server (stop and start)
restart_mysql()
{
    stop_mysql
    start_mysql ${1:-3306}
}

# determine the next position in a list of servers with support for circular reference
get_next_position()
{
    current_position=$1
    maximum_position=$2

    next_position=$((current_position+1))

    if [[ "$next_position" -ge "$maximum_position" ]];
    then
        # loop
        next_position=0
    fi

    echo $next_position
}

# Using a replication status file (generated from mysqlrepladmin), determine if a server is a valid master
# Note: the replication status file shows the health of replication from the perspective of the target server
check_master_status()
{
    # get input parameters
    target_server=$1
    repl_status_csv_file_path=$2

    # initialize other key variables
    rows_processed=-1
    master_identified=0
    servers_ok=0

    ########################################

    # Iterate the rows of the replication status
    # expected header: host,port,role,state,gtid_mode,health
    while IFS=, read host port role state gtid_mode health
    do
        # increment the processed rows 
        ((rows_processed++))

        # the csv file has a header. Skip it
        if [[ $rows_processed == 0 ]];
        then
            continue
        fi

        # assess the server replication status
        # we expect state=up, gtid_mode=on, health=ok for all members & role=master when host==target_server
        if [[ "${state,,}" == "up" ]] && [[ "${gtid_mode,,}" == "on" ]] && [[ "${health,,}"=="ok" ]];
        then
            # track the number of server in a valid state
            ((servers_ok++))
        fi

        # check if the target server is in master mode (expected | defensive)
        if [[ "${host,,}" == $target_server ]] &&  [[ "${role,,}" == "master" ]];
        then
            master_identified=1
        fi

    done < $repl_status_csv_file_path

    # Make assessment whether or not the server is a valid master
    if [[ $servers_ok -eq $rows_processed ]] && [[ $master_identified -eq 1 ]];
    then
        # valid master
        echo 1
    else
        # not currently master
        echo 0
    fi
}

# check if the target server is a valid master
is_master_server()
{
    encoded_replicated_servers_list=$1  # ip address of the servers participating in the replication
    local_server_ip=$2                  # get the server ip
    mysql_admin_user=$3                 # admin mysql user 
    mysql_admin_user_password=$4        # admin mysql user password

    # initialize other key variables
    replicated_servers_list=(`echo ${encoded_replicated_servers_list} | base64 --decode`)
    total_servers=${#replicated_servers_list[@]}
    server_position=0

    for replicated_server in "${replicated_servers_list[@]}"
    do
        if [[ $replicated_server == $local_server_ip ]];
        then
            local_server_replicated_position=$server_position
            break
        fi

        ((server_position++))
    done

    if [[ -z $local_server_replicated_position ]];
    then
        log "Could not locate the IP address of ${HOSTNAME} (${local_server_ip}) in the configured replication topology ${replicated_servers_list}"
        exit $REPLICATION_MASTER_MISSING
    fi

    # identify the positions of the other servers participating in the replication topology
    second_server_position=`get_next_position $server_position $total_servers`
    second_server=${replicated_servers_list[$second_server_position]}

    third_server_position=`get_next_position $second_server_position $total_servers`
    third_server=${replicated_servers_list[$third_server_position]}

    # more defensive: the repladmin will override the file/or create a new file
    replication_status_file="$(mktemp /tmp/replication_status_XXXXXX.csv)"
    remove_replication_file "${replication_status_file}"

    # run the repl admin to check the replication status from the perspective of the target server
    mysqlrpladmin --master=${mysql_admin_user}:${mysql_admin_user_password}@${local_server_ip}:$mysql_server_port --slaves=${mysql_admin_user}:${mysql_admin_user_password}@${second_server}:3306,${mysql_admin_user}:${mysql_admin_user_password}@${third_server}:3306 health --format=csv > $replication_status_file

    # clean up the status file (remove comment lines and warning text)
    sed -i "/^#/ d" $replication_status_file
    sed -i "/^WARNING/ d" $replication_status_file

    # assess the replication status
    is_valid_master=`check_master_status ${local_server_ip} ${replication_status_file}`

    # clean up
    remove_replication_file "${replication_status_file}"

    echo $is_valid_master
}

remove_replication_file()
{
    local status_file="${1}"

    if [[ -f $status_file ]];
    then
        #log "Cleaning up existing replication file"
        rm $status_file
    fi
}

#############################################################################
# Mysql Data Directory Move Operation
#############################################################################

move_mysql_datadirectory()
{
    ###################################
    # 0. Pre-requisites
    # track the input parameters
    local new_datadirectory_path=$1
    local admin_email_address=$2

    # database credentials & version
    local mysql_adminuser_name=$3
    local mysql_adminuser_password=$4
    local mysql_server_ip=$5
    local mysql_server_port=$6

    # subject for email notification
    local subject="Operation: Moving Mysql Data Directory"

    # get the current data directory (as the server sees it)
    local current_datadirectory_path=`mysql -u ${mysql_adminuser_name} -p${mysql_adminuser_password} -N -h ${mysql_server_ip} -e "select @@datadir;"`
    exit_on_error "Could not query the mysql server at on '${mysql_adminuser_name}@${mysql_server_ip}' to determine its current data directory!" "${ERROR_MYSQL_DATADIRECTORY_MOVE_FAILED}" "${subject}" $admin_email_address

    # remove trailing slash (if present)
    current_datadirectory_path=${current_datadirectory_path%/}

    # make sure we have a valid data directory
    if [ -z $current_datadirectory_path ] || [ ! -d $current_datadirectory_path ];
    then
        log "Could not determine the current data directory for '${mysql_adminuser_name}@${mysql_server_ip}'! Current value is: ${current_datadirectory_path}."
        exit "${ERROR_MYSQL_DATADIRECTORY_MOVE_FAILED}"
    fi

    ###################################
    # 1. Stop the server
    # It is assumed that the server is already running as a slave vs a master node
    stop_mysql
    exit_on_error "Could not stop mysql on '${HOSTNAME}'!" "${ERROR_MYSQL_DATADIRECTORY_MOVE_FAILED}" "${subject}" $admin_email_address

    ###################################
    # 2. Copy the server data to the new location and move the server data to backup
    # there are very restrictive permissions on the data directory (we need super user access)

    # The expectation is that the parent directory exists at the target path. Make sure of that
    local new_datadirectory_basepath=`dirname $new_datadirectory_path`
    if [[ ! -d $new_datadirectory_basepath ]]; 
    then
        log "Creating the base path at '${new_datadirectory_basepath}' since it doesn't already exist"
        mkdir -p "${new_datadirectory_basepath}"
    fi

    log "Copying the data directory from '${current_datadirectory_path}' to '${new_datadirectory_path}'"

    rsync -av $current_datadirectory_path $new_datadirectory_basepath
    exit_on_error "Failed copying server data from '${current_datadirectory_path}' to '${new_datadirectory_path}' on '${HOSTNAME}' !" "${ERROR_MYSQL_DATADIRECTORY_MOVE_FAILED}" "${subject}" $admin_email_address

    # Backup the current data directory
    local datadirectory_backup_path="${current_datadirectory_path}-backup"
    log "Backing up the data directory from '${current_datadirectory_path}' to '${datadirectory_backup_path}'"

    mv $current_datadirectory_path $datadirectory_backup_path
    exit_on_error "Could not backup the data directory from '${current_datadirectory_path}' to '${datadirectory_backup_path}' on '${HOSTNAME}' !" "${ERROR_MYSQL_DATADIRECTORY_MOVE_FAILED}" "${subject}" $admin_email_address

    ###################################
    # 3. Update mysql configuration to reference the new path
    # locate the main configuration file
    local mysql_configuration_file="/etc/mysql/conf.d/mysqld.cnf"

    # update the data directory path
    log "Updating Mysql Configuration at ${mysql_configuration_file} : setting datadir=${new_datadirectory_path}"
    if [[ ! -f $mysql_configuration_file ]]; 
    then
        echo "The calculated Mysql Configuration file isn't available!"
        exit "${ERROR_MYSQL_DATADIRECTORY_MOVE_FAILED}"
    fi

    sed -i "s#^datadir=.*#datadir=${new_datadirectory_path}#I" $mysql_configuration_file
    exit_on_error "Could not update the Mysql Configuration file at '${mysql_configuration_file}'!" "${ERROR_MYSQL_DATADIRECTORY_MOVE_FAILED}" "${subject}" $admin_email_address

    # update the systemd service startup configs
    local mysqld_servicefile="/etc/systemd/system/mysqld.service"
    sudo sed -i "s#--datadir=.\\S*#--datadir=${new_datadirectory_path}#I" $mysqld_servicefile
    exit_on_error "Could not update the systemd Mysqld Service configuration file at at '${mysqld_servicefile}'!" "${ERROR_MYSQL_DATADIRECTORY_MOVE_FAILED}" "${subject}" $admin_email_address

    ###################################
    #4. Configure Apparmor
    # Instead of using symlink (which has been problematic), we will leverage apparmor to handle the aliasing of the data directory path

    # Check if there is a reference to the new path already established. If there isn't any reference, append a new line to the apparmor configs
    local apparmor_config_file="/etc/apparmor.d/tunables/alias"
    local alias="alias ${current_datadirectory_path} -> ${new_datadirectory_path}, "
    local alias_regex="^alias ${current_datadirectory_path} ->.*"

    if [ `grep -Gxq "${alias_regex}" "${apparmor_config_file}"` ];
    then
        # Existing Alias: Override it
        log "Existing alias detected in ${apparmor_config_file}. Overriding with new value: ${alias}"
        sed -i "s~${alias_regex}~${alias}~I" $apparmor_config_file
    else
        # Alias doesn't exist: Append It
        log "Adding new alias to ${apparmor_config_file}"
        echo "${alias}" >> $apparmor_config_file
    fi

    # restart apparmor to apply the settings
    os_version=$(lsb_release -rs)
    if [[ $(echo "$os_version > 16" | bc -l) == 1 ]];
    then
        systemctl restart apparmor
    else
        service apparmor restart
    fi

    # check for errors
    exit_on_error "Could not start apparmor after adding the data directory alias on '${HOSTNAME}' !" "${ERROR_MYSQL_DATADIRECTORY_MOVE_FAILED}" "${subject}" $admin_email_address

    # setup blank reference for mysql database directory to circumvent any startup check failures
    mkdir "${current_datadirectory_path}/mysql" -p

    ###################################
    #5. Restart the server

    # incase there are config changes (specific to Ubuntu 16+)
    if [[ $(echo "$os_version > 16" | bc -l) == 1 ]];
    then
        systemctl daemon-reload
        exit_on_error "Could not perform a configuration reload on '${HOSTNAME}' !" "${ERROR_MYSQL_DATADIRECTORY_MOVE_FAILED}" "${subject}" $admin_email_address
    fi

    start_mysql $mysql_server_port
    exit_on_error "Could not start mysql server after moving its data directory on '${HOSTNAME}' !" "${ERROR_MYSQL_DATADIRECTORY_MOVE_FAILED}" "${subject}" $admin_email_address
}

#############################################################################
# Wrapper function for doing role-based tools installation
#############################################################################
install-tools()
{
    machine_role=$(get_machine_role)

    # Most docker containers don't have sudo pre-installed.
    install-sudo

    # "desktop environment" flavors of ubuntu like xubuntu don't come with full ssh, but server edition generaly does"
    install-ssh
    install-git

    # required for envsubst command
    install-gettext
    set-server-timezone
    install-json-processor

    if [[ "$machine_role" == "jumpbox" ]] || [[ "$machine_role" == "vmss" ]] ;
    then
        install-bc
        install-mongodb-shell
        install-mysql-client

        # powershell isn't supported on Ubuntu 12
        short_release_number=`lsb_release -sr`
        if [[ $(echo "$short_release_number > 14" | bc -l) == 1 ]]; 
        then
            log "Ubuntu ${short_release_number} detected. Proceeding with powershell installation"
            install-powershell
        else
            log "Ubuntu ${short_release_number} detected. Skipping powershell installation"
        fi

        install-azure-cli
        install-azure-cli-2
    fi

    # we want this utility installed on the backends & jb
    if [[ "$machine_role" != "vmss" ]] ; 
    then
        log "Installing Mysql Utilities on ${HOSTNAME}"
        install-mysql-utilities
    fi
}

#############################################################################
# Install Xinet (Extended Internet) Service
#############################################################################

install-xinetd()
{
    if type xinetd >/dev/null 2>&1; then
        log "xinet is already installed"
    else
        install-wrapper "xinetd" $ERROR_XINETD_INSTALLER_FAILED
    fi
}

#############################################################################
# Xinet Service Controls
#############################################################################

restart_xinetd()
{
    # restart the service
    /etc/init.d/xinetd restart

    # the server is lightweight. A brief pause may be necessary.
    sleep 5s

    # make sure it is running
    xinetd_pid=`ps -ef | grep '/usr/sbin/xinetd' | grep -v grep | awk '{print $2}'`

    if [[ -z "${xinetd_pid}" ]]; 
    then
        log "Unable to start xinet"
        exit $ERROR_XINETD_INSTALLER_FAILED
    fi
}

#############################################################################
# Deployment Support
#############################################################################

copy_bits()
{
    bitscopy_target_server=$1
    bitscopy_target_user=$2
    script_base_path=$3
    error_code=$4
    copyerror_mail_subject=$5
    copyerror_mail_receiver=$6

    ssh_options="StrictHostKeyChecking=no"

    # clean up existing files (if present)
    ssh -o "${ssh_options}" "${bitscopy_target_user}@${bitscopy_target_server}" "sudo rm ~/install.sh && sudo rm ~/utilities.sh"

    # copy the installer & the utilities files to the target server & ssh/execute the Operations
    scp -o "${ssh_options}" $script_base_path/install.sh "${bitscopy_target_user}@${bitscopy_target_server}":~/
    exit_on_error "Unable to copy installer script to '${bitscopy_target_server}' from '${HOSTNAME}' !" "${error_code}" "${copyerror_mail_subject}" "${copyerror_mail_receiver}"

    scp -o "${ssh_options}" $script_base_path/utilities.sh "${bitscopy_target_user}@${bitscopy_target_server}":~/
    exit_on_error "Unable to copy utilities to '${bitscopy_target_server}' from '${HOSTNAME}' !" "${error_code}" "${copyerror_mail_subject}" "${copyerror_mail_receiver}"

    # set appropriate permissions on the required installer files
    ssh -o "${ssh_options}" "${bitscopy_target_user}@${bitscopy_target_server}" "sudo chmod 600 ~/install.sh && sudo chmod 600 ~/utilities.sh"
    exit_on_error "Unable to update permissions on the installer files copied to '${bitscopy_target_server}'!" "${error_code}" "${copyerror_mail_subject}" "${copyerror_mail_receiver}"
}

#############################################################################
# Memcache
#############################################################################

install-memcached()
{
    if type memcached >/dev/null 2>&1; then
        log "Memcached is already installed"
    else
        log "Installing Memcached"
        install-wrapper "memcached" $ERROR_MEMCACHED_INSTALLER_FAILED
    fi
}

install-pip()
{
    if type pip >/dev/null 2>&1; then
        log "PIP is already installed"
    else
 
        log "Installing Memcached"
        install-wrapper "python-pip python-dev build-essential" $ERROR_PIP_INSTALLER_FAILED
    fi
}

pipinstall-package()
{
    package_name="${1}"
    package_list=`echo ${2} | base64 --decode`

    # make sure pip is already installed
    install-pip

    if [[ -z ${package_list} ]]; then
        package_list="${package_name}"
    fi

    response=`pip show ${package_name}`
    
    if [[ -n "${response}" ]]; then
        log "python '${package_name}' module is already installed."
    else
        # TODO: check if just click install is sufficient
        # install both click and click_log
        pip install ${package_list}
        exit_on_error "Failed to pip install '${package_list}' on ${HOSTNAME} !" $ERROR_PIP_INSTALLER_FAILED
    fi
}

install-servicebus-tools()
{
    log "PIP installing click, click_log & azure packages to support servicebus communication"

    # pip install click
    package_list=`echo "click click_log" | base64`
    pipinstall-package "click" "${package_list}"

    # pip install azure
    pipinstall-package "azure"
}