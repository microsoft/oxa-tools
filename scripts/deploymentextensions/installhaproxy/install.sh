#!/bin/bash
#
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

#
# This script installs and configures HAProxy for Mysql Load Balancing and supporting seamless failover.
# It also installs the xinetd service for providing a custom status check on the mysql backends to ensure
# that HAProxy only communicates with the Mysql Master (since we have a master-slave setup)
#

# Oxa Tools
# Settings for the OXA-Tools public repository 
oxa_tools_public_github_account="Microsoft"
oxa_tools_public_github_projectname="oxa-tools"
oxa_tools_public_github_projectbranch="oxa/master.fic"
oxa_tools_public_github_branchtag=""
oxa_tools_repository_path="/oxa/oxa-tools"

# Email Notifications
notification_email_subject="HA Proxy Installer"
cluster_admin_email=""

# this is the user account that will be used for ssh
target_user=""

# operation mode: 0=local, 1=remote via ssh
remote_mode=0

# debug mode: 0=set +x, 1=set -x
debug_mode=0

# Initialize required parameters
package_name="installhaproxy"

# this is the server & port on which HA Proxy will run
haproxy_server="10.0.0.16"
haproxy_server_probe_port=12010

# this is a space-separated list (originally base64-encoded) of mysql servers in the replicated topology. The master is listed first followed by 2 slaves
encoded_server_list=""
backend_server_list=""
mysql_master_server_ip=""
mysql_slave1_server_ip=""
mysql_slave2_server_ip=""
mysql_server_port="3306"

# credentials for mysql server
mysql_admin_username=""
mysql_admin_password=""

# haproxy settings
haproxy_port="3308"
haproxy_username="haproxy_check"
haproxy_initscript="/etc/default/haproxy"
haproxy_configuration_file="/etc/haproxy/haproxy.cfg"
haproxy_configuration_template_file="${oxa_tools_repository_path}/scripts/deploymentextensions/${package_name}/haproxy.template.cfg"
haproxy_probe_interval_sec="1800"

# probe Settings
network_services_file="/etc/services"

xinet_service_name="mysqlmastercheck"
xinet_service_description="# Mysql Master Probe"
xinet_service_port_regex="${haproxy_server_probe_port}\/tcp"
xinet_service_line_regex="^${xinet_service_name}.*${xinet_service_port_regex}.*"
xinet_service_line="${xinet_service_name} \t ${haproxy_server_probe_port}/tcp \t\t ${xinet_service_description}"

probe_source_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
probe_service_configuration_template="${oxa_tools_repository_path}/scripts/deploymentextensions/${package_name}/service_configuration.template"
probe_script_source="${oxa_tools_repository_path}/scripts/deploymentextensions/${package_name}/${xinet_service_name}.sh"
probe_script_installation_directory="/opt"
probe_script="${probe_script_installation_directory}/${xinet_service_name}"

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
          --haproxy-server)
            haproxy_server="${arg_value}"
            ;;
          --haproxy-server-port)
            haproxy_port="${arg_value}"
            ;;
          --haproxy-server-probe-port)
            haproxy_server_probe_port="${arg_value}"
            ;;
          --haproxy-probe-interval-sec)
            haproxy_probe_interval_sec="${arg_value}"
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
          --component)
            component="${arg_value}"
            ;;
          --backend-server-list)
            backend_server_list=(`echo ${arg_value} | base64 --decode`)
            encoded_server_list="${arg_value}"
            ;;
          --target-user)
            target_user="${arg_value}"
            ;;
          --remote)
            remote_mode=1
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

    # target user
    if [[ -z $target_user ]]; 
    then
        log "You must specify a user account to use for SSH to remote servers"
        exit $ERROR_HAPROXY_INSTALLER_FAILED
    fi

    # cluster admin email (for notification purposes)
    if [[ -z $cluster_admin_email ]]; 
    then
        log "You must specify the cluster admininstrator email address for notification purposes"
        exit $ERROR_HAPROXY_INSTALLER_FAILED
    fi

    # Mysql validation
    if [[ -z $mysql_admin_username ]] || [[ -z $mysql_admin_password ]] ;
    then
        log "You must specify the admin credentials for mysql server"
        exit $ERROR_HAPROXY_INSTALLER_FAILED
    fi

    # Backend server list
    if [[ -z $backend_server_list ]] ;
    then
        log "You must specify the list of backend servers on which to configure the proxy"
        exit $ERROR_HAPROXY_INSTALLER_FAILED
    fi

    log "Completed argument validation successfully"
}

execute_remote_command()
{
    remote_execution_server_target="${1}"
    remote_execution_target_user="${2}"
    
    # build the command for remote execution (basically: pass through all existing parameters)
    repository_parameters="--oxatools-public-github-accountname ${oxa_tools_public_github_account} --oxatools-public-github-projectname ${oxa_tools_public_github_projectname} --oxatools-public-github-projectbranch ${oxa_tools_public_github_projectbranch} --oxatools-public-github-branchtag ${oxa_tools_public_github_branchtag} --oxatools-repository-path ${oxa_tools_repository_path}"
    mysql_parameters="--mysql-server-port ${mysql_server_port} --mysql-admin-username ${mysql_admin_username} --mysql-admin-password ${mysql_admin_password} --haproxy-server-port ${haproxy_port} --backend-server-list ${encoded_server_list}"
    misc_parameters="--cluster-admin-email ${cluster_admin_email} --haproxy-server ${haproxy_server} --haproxy-probe-interval-sec ${haproxy_probe_interval_sec} --haproxy-server-probe-port ${haproxy_server_probe_port} --target-user ${target_user} --component ${component} --remote"

    if [[ $debug_mode == 1 ]];
    then
        misc_parameters="${misc_parameters} --debug"
    fi

    remote_command="sudo bash ~/install.sh ${repository_parameters} ${mysql_parameters} ${misc_parameters}"

    # run the remote command
    ssh "${remote_execution_target_user}@${remote_execution_server_target}" $remote_command
    exit_on_error "Could not execute the haproxy installer on the remote target: ${remote_execution_server_target} from '${HOSTNAME}' !" "${ERROR_HAPROXY_INSTALLER_FAILED}" "${notification_email_subject}" "${cluster_admin_email}"
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
print_script_header "${notification_email_subject}"

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

####################################
# Main Operations
####################################

if [[ $remote_mode == 0 ]];
then
    # at this point, we are on the jumpbox attempting to execute the installer on the remote target 

    # 1. Install Xinetd
    # As a supporting requirement, install & configure xinetd on all mysql servers specified (the members of the replication topology)
    # this is triggered from the JB but executed remotely on each mysql server specified
    if [[ "${component,,}" != "xinetd" ]]; 
    then

        log "Initiating installation of xinetd"

        # turn on component deployment
        component="xinetd"

        for server in "${backend_server_list[@]}"
        do
            log "Installing xinetd on ${server}"

            # copy the bits
            copy_bits "${server}" "${target_user}" "${current_path}" "${ERROR_HAPROXY_INSTALLER_FAILED}" "${notification_email_subject}" "${cluster_admin_email}"

            # execute the component deployment
            execute_remote_command "${server}" "${target_user}"
        done

        # turn off component deployment
        component=""

        log "Completed xinetd installation"
    fi

    # 2. Install HAProxy
    log "Initiating remote installation of haproxy on ${haproxy_server}"

    # copy the installer & the utilities files to the target server & ssh/execute the Operations
    copy_bits "${haproxy_server}" "${target_user}" "${current_path}" "${ERROR_HAPROXY_INSTALLER_FAILED}" "${notification_email_subject}" "${cluster_admin_email}"

    # execute the component deployment
    execute_remote_command "${haproxy_server}" "${target_user}"

    log "Completed Remote installation of xinetd  & haproxy successfully"
	exit
fi

# check for component installation mode
if [[ "${component,,}" == "xinetd" ]]; 
then

    # 1. install the service
    log "Installing & Configuring xinetd"

    install-xinetd
    exit_on_error "Could not install xinetd on ${HOSTNAME} }' !" "${ERROR_XINETD_INSTALLER_FAILED}" "${notification_email_subject}" "${cluster_admin_email}"

    # 2. Copy custom probe script to /opt & update the permissions
    log "Copying the probe script and updating its permissions"

    cp  $probe_script_source $probe_script
    exit_on_error "Could not copy the probe script '${probe_script_source}' to the target directory '${probe_script_installation_directory}' xinetd on ${HOSTNAME}' !" "${ERROR_XINETD_INSTALLER_FAILED}" "${notification_email_subject}" "${cluster_admin_email}"

    chmod 700 $probe_script
    exit_on_error "Could not update permissions for the probe script '${probe_script}' on '${HOSTNAME}' !" "${ERROR_XINETD_INSTALLER_FAILED}" "${notification_email_subject}" "${cluster_admin_email}"

    chown $target_user:$target_user $probe_script
    exit_on_error "Could not update ownership for the probe script '${probe_script}' on '${HOSTNAME}' !" "${ERROR_XINETD_INSTALLER_FAILED}" "${notification_email_subject}" "${cluster_admin_email}"

    # inject the parameter overrides
    server_list=`echo ${encoded_server_list} | base64 --decode`

    sed -i "s/^mysql_user=.*/mysql_user=\"${mysql_admin_username}\"/I" $probe_script
    sed -i "s/^mysql_user_password=.*/mysql_user_password=\"${mysql_admin_password}\"/I" $probe_script
    sed -i "s/^replication_serverlist.*/replication_serverlist=\"${server_list}\"/I" $probe_script

    # 3. Add probe port to /etc/services
    log "Adding the probe service to network service configuration"

    # backup the services file
    cp "${network_services_file}"{,.backup}
    exit_on_error "Could not backup the network service file at '${network_services_file}' on ${HOSTNAME}' !" "${ERROR_XINETD_INSTALLER_FAILED}" "${notification_email_subject}" "${cluster_admin_email}"

    # check if the port is used, if it is, test if it is used for our service, if so, remove the existing line and add the new one
    existing_service_line=`grep "${xinet_service_port_regex}" "${network_services_file}"`
    if [[ -z $existing_service_line ]] || ( [[ ! -z $existing_service_line ]] && [[ `echo ${existing_service_line} | grep ${xinet_service_line_regex}` ]] );
    then
        if [[ ! -z $existing_service_line ]]; 
        then
            # this is a previous version of the mysql probe, remove it
            sed -i "/${xinet_service_line_regex}/ d" $network_services_file
        fi

        # append a new line to the file
        echo -e $xinet_service_line >> $network_services_file
        exit_on_error "Could not append network service configuration for the probe.' !" "${ERROR_XINETD_INSTALLER_FAILED}" "${notification_email_subject}" "${cluster_admin_email}"
    else
        # some other service is using the port
        log "${haproxy_server_probe_port} is in use by another service: ${existing_service_line}"
        exit $ERROR_XINETD_INSTALLER_FAILED
    fi

    # 4. Setup xinetd config for the probe service
    log "Setting up probe service configuration"

    xinetd_service_configuration_file="/etc/xinetd.d/${xinet_service_name}"
    cp "${probe_service_configuration_template}" $xinetd_service_configuration_file
    exit_on_error "Could not copy the service configuration to '${xinetd_service_configuration_file}' on ${HOSTNAME}' !" "${ERROR_HAPROXY_INSTALLER_FAILED}" "${notification_email_subject}" "${cluster_admin_email}"

    sed -i "s#{service_port}#${haproxy_server_probe_port}#I" $xinetd_service_configuration_file
    sed -i "s#{service_user}#${target_user}#I" $xinetd_service_configuration_file
    sed -i "s#{script_path}#${probe_script}#I" $xinetd_service_configuration_file

    # 5. Restart xinetd
    log "Restarting xinetd"

    restart_xinetd
    exit_on_error "Could not restart xinet after updating the service configuration on ${HOSTNAME}' !" "${ERROR_HAPROXY_INSTALLER_FAILED}" "${notification_email_subject}" "${cluster_admin_email}"

    log "Completed Remote execution successfully"
    exit
fi


log "Starting HAProxy installation on ${HOSTNAME}"

# setup the server references
mysql_master_server_ip=${backend_server_list[0]}
mysql_slave1_server_ip=${backend_server_list[1]}
mysql_slave2_server_ip=${backend_server_list[2]}

# 1. Create the HA Proxy Mysql account on the master mysql server
mysql -u ${mysql_admin_username} -p${mysql_admin_password} -h ${mysql_master_server_ip} -e "INSERT INTO mysql.user (Host,User) values ('${haproxy_server}','${haproxy_username}') ON DUPLICATE KEY UPDATE Host='${haproxy_server}', User='${haproxy_username}'; FLUSH PRIVILEGES;"
exit_on_error "Unable to create HA Proxy Mysql account on '${HOSTNAME}' !" "${ERROR_HAPROXY_INSTALLER_FAILED}" "${notification_email_subject}" "${cluster_admin_email}"

# Validate user access
database_list=`mysql -u ${haproxy_username} -N -h ${mysql_master_server_ip} -e "SHOW DATABASES"`
exit_on_error "Unable to access the target server using ${haproxy_username}@${mysql_master_server_ip} without password from '${HOSTNAME}' !" "${ERROR_HAPROXY_INSTALLER_FAILED}" "${notification_email_subject}" "${cluster_admin_email}"

# 2. Install HA Proxy
stop_haproxy
install_haproxy

# 3. Configure HA Proxy

# 3.1 Enable HA Proxy to be initialized from startup script
enabled_regex="^ENABLED=.*"

if grep -Gxq $enabled_regex $haproxy_initscript;
then
    # Existing Alias: Override it
    sed -i "s/${enabled_regex}/ENABLED=1/I" $haproxy_initscript
else
    # Alias doesn't exist: Append It
    cat "ENABLED=1" >> $haproxy_initscript
fi

# 3.2 Update the HA Proxy configuration
if [ -f "${haproxy_configuration_file}" ];
then
    mv "${haproxy_configuration_file}"{,.bak}
    exit_on_error "Unable to backup the HA Proxy configuration file at ${haproxy_configuration_file} !" "${ERROR_HAPROXY_INSTALLER_FAILED}" "${notification_email_subject}" "${cluster_admin_email}"
fi

cp  "${haproxy_configuration_template_file}" "${haproxy_configuration_file}"
exit_on_error "Unable to copy the HA Proxy configuration template from  the target server using ${haproxy_username}@${mysql_master_server_ip} without password from '${HOSTNAME}' !" "${ERROR_HAPROXY_INSTALLER_FAILED}" "${notification_email_subject}" "${cluster_admin_email}"

log "Replacing template variables"

# we are doing the installation locally on the haproxy target server. Limit access to the proxy to the local network
haproxy_server_ip=`ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p'`

sed -i "s/{HAProxyIpAddress}/${haproxy_server_ip}/I" "${haproxy_configuration_file}"
sed -i "s/{HAProxyPort}/${haproxy_port}/I" "${haproxy_configuration_file}"
sed -i "s/{ProbePort}/${haproxy_server_probe_port}/I" "${haproxy_configuration_file}"
sed -i "s/{MysqlServerPort}/${mysql_server_port}/I" "${haproxy_configuration_file}"
sed -i "s/{MysqlMasterServerIP}/${mysql_master_server_ip}/I" "${haproxy_configuration_file}"
sed -i "s/{MysqlSlave1ServerIP}/${mysql_slave1_server_ip}/I" "${haproxy_configuration_file}"
sed -i "s/{MysqlSlave2ServerIP}/${mysql_slave2_server_ip}/I" "${haproxy_configuration_file}"
sed -i "s/{ProbeInterval}/${haproxy_probe_interval_sec}/I" "${haproxy_configuration_file}"

# 3.3 Start HA Proxy & validate
start_haproxy "${mysql_admin_username}" "${mysql_admin_password}" "${haproxy_server}" "${haproxy_port}"
exit_on_error "Unable to start HA Proxy on '${HOSTNAME}' !" "${ERROR_HAPROXY_INSTALLER_FAILED}" "${notification_email_subject}" "${cluster_admin_email}" "${main_logfile}"

log "Completed HA Proxy installation for ${HOSTNAME}"