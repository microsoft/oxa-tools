#!/bin/bash
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

# general parameters
PACKAGE_VERSION=5.6
PACKAGE_NAME=mysql-server

# Support Packages that OXA needs
MYSQL_PYTHON_PACKAGE=MySQL-python==1.2.5

MYSQL_REPLICATION_NODEID=
NODE_ADDRESS=`ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'`

NETWORK_PREFIX="10.0.0"
MASTER_NODE_IPADDRESS=
MYSQL_REPLICATION_USER=lexoxamysqlrepluser
MYSQL_REPLICATION_PASSWORD=
MYSQL_ADMIN_USER=lexoxamysqladmin
MYSQL_ADMIN_PASSWORD=
MYSQL_PORT=3306

#todo: bug95044 make this configurable. lots of invocations to cleanup though grep -i -I -r "mysql.*install.*\(script\|sh\)"
DATA_DISKS="/datadisks"
DATA_MOUNTPOINT="$DATA_DISKS/disk1"

MYSQL_DATA="$DATA_MOUNTPOINT/mysql"

OS_VER=$(lsb_release -rs)

help()
{
    echo "This script installs Mysql on the Ubuntu virtual machine image"
    echo "Options:"
    echo "        -n Mysql replica node id"
    echo "        -m ip address of the Mysql master node"
    echo "        -v Mysql package version"
    echo "        -r Mysql replication user name"
    echo "        -k Mysql replication password"
    echo "        -u Mysql administrator user name"
    echo "        -p Mysql administrator user password"    
}

# source our utilities for logging and other base functions
source ./utilities.sh

# Script self-idenfitication
print_script_header

log "Begin execution of Mysql installation script extension on ${HOSTNAME}"

exit_if_limited_user

# Parse script parameters
while getopts :n:m:v:k:r:u:p:h optname; do

    # Log input parameters (except the admin password) to facilitate troubleshooting
    if [ ! "$optname" == "p" ] && [ ! "$optname" == "k" ]; then
        log "Option $optname set with value ${OPTARG}"
    fi
  
    case $optname in
    n) # Mysql replica node id
        MYSQL_REPLICATION_NODEID=${OPTARG}
        ;;
    m) # Ip address of the Mysql master node
        MASTER_NODE_IPADDRESS=${OPTARG}
        ;;
    v) # Mysql package version
        PACKAGE_VERSION=${OPTARG}
        ;;
    r) # Mysql replication user name
        MYSQL_REPLICATION_USER=${OPTARG}
        ;;    
    k) # Mysql replication password
        MYSQL_REPLICATION_PASSWORD=`echo ${OPTARG} | base64 --decode`
        ;;    
    u) # Mysql administrator user name
        MYSQL_ADMIN_USER=${OPTARG}
        ;;        
    p) # Mysql administrator user password
        MYSQL_ADMIN_PASSWORD=`echo ${OPTARG} | base64 --decode`
        ;;
    h) # Helpful hints
        help
        exit 2
        ;;
    \?) # Unrecognized option - show help
        echo -e \\n"Option -${BOLD}$OPTARG${NORM} not allowed."
        help
        exit 2
        ;;
  esac
done

# Validate parameters
if [ "$MYSQL_REPLICATION_NODEID" == "" ] || [ "$MYSQL_ADMIN_USER" == "" ] || [ "$MYSQL_ADMIN_PASSWORD" == "" ] || [ "$MYSQL_REPLICATION_USER" == "" ] || [ "$MYSQL_REPLICATION_PASSWORD" == "" ] ;
then
    log "Script executed without admin credentials or node ID specified"
    echo "You must provide a name and password for the mysql  administrator user and the mysql replication user in addition to specifing the id associated with the current node." >&2
    exit 3
fi

MYSQL_SERVER_PACKAGE_NAME="${PACKAGE_NAME}-${PACKAGE_VERSION}"

#############################################################################
start_mysql()
{
    log "Starting Mysql Server"

    if (( $(echo "$OS_VER > 16" | bc -l) ))
    then
        systemctl start mysqld
        # enable mysqld on startup
        systemctl enable mysqld
    else
        service mysql start
    fi

    # Wait for Mysql daemon to start and initialize for the first time (this may take up to a minute or so)
    while ! timeout 1 bash -c "echo > /dev/tcp/localhost/$MYSQL_PORT"; do sleep 10; done

    log "${MYSQL_SERVER_PACKAGE_NAME} has been started"
}

stop_mysql()
{
    # Find out what PID the Mysql instance is running as (if any)
    MYSQLPID=`ps -ef | grep '/usr/sbin/mysqld' | grep -v grep | awk '{print $2}'`
    
    if [ ! -z "$MYSQLPID" ]; then
        log "Stopping Mysql Server (PID $MYSQLPID)"
        
        kill -15 $MYSQLPID

        # Important not to attempt to start the daemon immediately after it was stopped as unclean shutdown may be wrongly perceived
        sleep 15s
    fi
}

# restart mysql server (stop and start)
restart_mysql()
{
    stop_mysql
    start_mysql
}

#############################################################################
install_mysql_server()
{
    log "Installing Mysql packages: $MYSQL_SERVER_PACKAGE_NAME"
    
    create_mysql_unitfile

    export DEBIAN_FRONTEND=noninteractive

    package=$MYSQL_SERVER_PACKAGE_NAME

    # Special cases.
    if (( $(echo "$OS_VER < 16" | bc -l) )) && [ $PACKAGE_VERSION == "5.7" ]
    then
        # Allow sql 5.7 on ubuntu 14 and below.
        package=${PACKAGE_NAME}

        debFileName=mysql-apt-config_0.8.0-1_all
        wget -q http://dev.mysql.com/get/$debFileName.deb -O $debFileName.deb
        echo mysql-apt-config mysql-apt-config/select-product select Ok | debconf-set-selections
        dpkg -i $debFileName.deb
        rm $debFileName*
    elif (( $(echo "$OS_VER > 16" | bc -l) )) && (( $(echo "$PACKAGE_VERSION < 5.7" | bc -l) ))
    then
        # Allows sql 5.6 on ubuntu 16
        add-apt-repository 'deb http://archive.ubuntu.com/ubuntu trusty universe'
    fi

    apt-get -y -qq update

    echo $package mysql-server/root_password password $MYSQL_ADMIN_PASSWORD | debconf-set-selections
    echo $package mysql-server/root_password_again password $MYSQL_ADMIN_PASSWORD | debconf-set-selections
    apt-get install -y -qq $package 

    # Install additional dependencies
    log "Installing additional dependencies: Python-Pip, Python-Dev, MysqlClient Dev Lib"
    apt-get install -y -qq python-pip python-dev libmysqlclient-dev

    log "Pip installing $MYSQL_PYTHON_PACKAGE"
    pip install $MYSQL_PYTHON_PACKAGE

    log "Installing Mysql packages: Completed"
}

create_mysql_unitfile()
{
    log "Creating the Mysql Unit File"

    tee /etc/systemd/system/mysqld.service > /dev/null <<EOF
[Unit]
Description=MySQL Community Server
After=syslog.target network.target

[Service]
Type=simple
PermissionsStartOnly=true
ExecStartPre=/bin/mkdir -p /var/run/mysqld
ExecStartPre=/bin/chown mysql:mysql -R /var/run/mysqld
ExecStart=/usr/sbin/mysqld --defaults-file=/etc/mysql/conf.d/mysqld.cnf --basedir=/usr --datadir=/var/lib/mysql --plugin-dir=/usr/lib/mysql/plugin --log-error=/var/log/mysql/error.log --pid-file=/var/run/mysqld/mysqld.pid --socket=/var/run/mysqld/mysqld.sock --port=default_port
TimeoutSec=300
PrivateTmp=true
User=mysql
Group=mysql
WorkingDirectory=/usr

[Install]
WantedBy=multi-user.target
EOF

    sed -i "s/--port=default_port/--port=${MYSQL_PORT}/I" /etc/systemd/system/mysqld.service

    # reload the unit
    if (( $(echo "$OS_VER > 16" | bc -l) ))
    then
        # Ubuntu 16 and above
        systemctl daemon-reload
    #else
        # Ubuntu 14 and below doesn't support systemctl
        # todo: determine if there is an equivalent command to "daemon-reload" using: service, update-rc.d, or sysv-rc-conf
        # note: chkconfig can't be used on any version 12 and above
    fi
}


# create the mysql replication configuration file
create_config_file()
{
    # set the output file name and path
    MYCNF_FILENAME="my.cnf"
    TARGET_MYCNF_DIR="/etc/mysql"

    if [ $(echo "$PACKAGE_VERSION == 5.7" | bc -l)  ];
    then
        TARGET_MYCNF_DIR="/etc/mysql/conf.d"
        MYCNF_FILENAME="mysqld.cnf"
    fi

    # establish the configuration template to use
    MYCNF_TEMPLATE_PATH="./mysqld.template-${PACKAGE_VERSION}.cnf"
    TEMP_MYCNF_PATH="./mysqld.custom.cnf"
    TARGET_MYCNF_PATH="${TARGET_MYCNF_DIR}/${MYCNF_FILENAME}"

    log "${PACKAGE_VERSION} detected. Mysql configuration will be dropped at '${TARGET_MYCNF_PATH}'"

    #TODO: Move this to configuration
    REPL_EXPIRE_LOG_DAYS=10
    REPL_MAX_BINLOG_SIZE=100M
    REPL_BINLOG_FORMAT="row"
    REPL_RELAY_LOG_SPACE_LIMIT=20GB
    
    # we expect the configuration template to be already downloaded and locally available
    cp $MYCNF_TEMPLATE_PATH $TEMP_MYCNF_PATH

    # update the generic settings
    #sed -i "s/^bind-address=.*/bind-address=${NODE_ADDRESS}/I" $TEMP_MYCNF_PATH
    sed -i "s/^server-id=.*/server-id=${MYSQL_REPLICATION_NODEID}/I" $TEMP_MYCNF_PATH
    sed -i "s/^#log_bin=.*/log_bin=\/var\/log\/mysql\/mysql-bin-${HOSTNAME}.log/I" $TEMP_MYCNF_PATH
    sed -i "s/^#binlog_format=.*/binlog_format=${REPL_BINLOG_FORMAT}/I" $TEMP_MYCNF_PATH

    # 1. perform necessary settings replacements
    if [ ${MYSQL_REPLICATION_NODEID} -eq 1 ];
    then
        log "Mysql Replication Master Node detected. Creating cnf for the MasterNode on ${HOSTNAME}"
        sed -i "s/^#expire_logs_days=.*/expire_logs_days=${REPL_EXPIRE_LOG_DAYS}/I" $TEMP_MYCNF_PATH
        sed -i "s/^#max_binlog_size=.*/max_binlog_size=${REPL_MAX_BINLOG_SIZE}/I" $TEMP_MYCNF_PATH
    else
        log "Mysql Replication Slave Node detected. Creating *.cnf for the SlaveNode on ${HOSTNAME}"

        sed -i "s/^\#relay-log=.*/relay-log=\/var\/log\/mysql\/mysql-relay-bin-${HOSTNAME}.log/I" $TEMP_MYCNF_PATH
        sed -i "s/^\#relay-log-space-limit=.*/expire_logs_days=${REPL_RELAY_LOG_SPACE_LIMIT}/I" $TEMP_MYCNF_PATH
        sed -i "s/^\#read-only=.*/read-only=1/I" $TEMP_MYCNF_PATH
    fi
    
    # 2. backup any existing configuration
    TIMESTAMP=`date +"%s"`
    if [ -e "$TARGET_MYCNF_PATH" ]
    then
        BACKUP_FILE_PATH="${TARGET_MYCNF_DIR}/mysqld.backup_${TIMESTAMP}"
        log "Existing configuration detected at ${TARGET_MYCNF_PATH} and will be backed up to ${BACKUP_FILE_PATH}"
        mv $TARGET_MYCNF_PATH $BACKUP_FILE_PATH
    else
        log "No existing mysql server configuration found at ${TARGET_MYCNF_PATH}"
    fi

    # 3. move the custom file to the proper location & update permissions
    cp $TEMP_MYCNF_PATH $TARGET_MYCNF_PATH
    chmod 544 $TARGET_MYCNF_PATH

    rm $TEMP_MYCNF_PATH
}

#############################################################################
configure_mysql_replication() 
{
    log "Configuring Mysql Replication"

    TMP_QUERY_FILE="tmp.query.repl.sql"
    touch $TMP_QUERY_FILE
    chmod 700 $TMP_QUERY_FILE


    if [ ${MYSQL_REPLICATION_NODEID} -eq 1 ];
    then
        log "Mysql Replication Master Node detected. Setting up Master Replication on ${HOSTNAME}"
 

        tee ./$TMP_QUERY_FILE > /dev/null <<EOF
-- CREATE USER IF NOT EXISTS '{MYSQL_ADMIN_USER}'@'%' IDENTIFIED BY '{MYSQL_ADMIN_PASSWORD}';
GRANT ALL PRIVILEGES ON *.* TO '{MYSQL_ADMIN_USER}'@'%' IDENTIFIED BY '{MYSQL_ADMIN_PASSWORD}' WITH GRANT OPTION;
GRANT REPLICATION SLAVE ON *.* TO '{MYSQL_ADMIN_USER}'@'%';
GRANT REPLICATION CLIENT ON *.* TO '{MYSQL_ADMIN_USER}'@'%';
-- CREATE USER IF NOT EXISTS '{MYSQL_REPLICATION_USER}'@'%' IDENTIFIED BY '{MYSQL_REPLICATION_PASSWORD}';
GRANT REPLICATION SLAVE ON *.* TO '{MYSQL_REPLICATION_USER}'@'%' IDENTIFIED BY '{MYSQL_REPLICATION_PASSWORD}'; 
FLUSH PRIVILEGES;
EOF

    else
        log "Mysql Replication Slave Node detected. Setting up Slave Replication on ${HOSTNAME} with master at ${MASTER_NODE_IPADDRESS}"


        tee ./$TMP_QUERY_FILE > /dev/null <<EOF
-- CREATE USER IF NOT EXISTS '{MYSQL_ADMIN_USER}'@'%' IDENTIFIED BY '{MYSQL_ADMIN_PASSWORD}';
GRANT ALL PRIVILEGES ON *.* TO '{MYSQL_ADMIN_USER}'@'%' IDENTIFIED BY '{MYSQL_ADMIN_PASSWORD}' WITH GRANT OPTION;
GRANT REPLICATION SLAVE ON *.* TO '{MYSQL_ADMIN_USER}'@'%';
GRANT REPLICATION CLIENT ON *.* TO '{MYSQL_ADMIN_USER}'@'%';
change master to master_host='{MASTER_NODE_IPADDRESS}', master_port={MYSQL_PORT}, master_user='{MYSQL_REPLICATION_USER}', master_password='{MYSQL_REPLICATION_PASSWORD}', master_auto_position=1; 
START slave;
EOF

    fi

    # replace the place holders
    sed -i "s/{NETWORK_PREFIX}/${NETWORK_PREFIX}/I" $TMP_QUERY_FILE
    sed -i "s/{MYSQL_ADMIN_USER}/${MYSQL_ADMIN_USER}/I" $TMP_QUERY_FILE
    sed -i "s/{MYSQL_ADMIN_PASSWORD}/${MYSQL_ADMIN_PASSWORD}/I" $TMP_QUERY_FILE
    sed -i "s/{MYSQL_REPLICATION_USER}/${MYSQL_REPLICATION_USER}/I" $TMP_QUERY_FILE
    sed -i "s/{MYSQL_REPLICATION_PASSWORD}/${MYSQL_REPLICATION_PASSWORD}/I" $TMP_QUERY_FILE
    sed -i "s/{MASTER_NODE_IPADDRESS}/${MASTER_NODE_IPADDRESS}/I" $TMP_QUERY_FILE
    sed -i "s/{MYSQL_PORT}/${MYSQL_PORT}/I" $TMP_QUERY_FILE

    #execute the queries
    mysql -u root -p$MYSQL_ADMIN_PASSWORD < ./$TMP_QUERY_FILE
    exit_on_error "Mysql configuration failed on '$HOST'"

    # remove the temp file (security reasons)
    rm ./$TMP_QUERY_FILE
}

#############################################################################
secure_mysql_installation()
{
    log "Updating Mysql Root Password"

    # This query matches most of what is available in the secure installation bash script:
    # 1. reset root password

    TMP_QUERY_FILE="tmp.query.secure.sql"


    tee ./$TMP_QUERY_FILE > /dev/null <<EOF
UPDATE mysql.user SET Password=PASSWORD('{ROOT_PASSWORD}') WHERE User='root';
FLUSH PRIVILEGES;
EOF

    # replace the place holders
    sed -i "s/{ROOT_PASSWORD}/${MYSQL_ADMIN_PASSWORD}/I" $TMP_QUERY_FILE

    # reset root password
    mysql -u root -p$MYSQL_ADMIN_PASSWORD< ./$TMP_QUERY_FILE

    # remove the temp file (security reasons)
    rm $TMP_QUERY_FILE
}

# Step 1: Configuring Disks"
configure_datadisks

# Step 2 : Tuning System"
tune_memory
tune_system

# Step 3: Install Mysql Server & Initial Configuration"
install-bc
install_mysql_server
create_config_file
restart_mysql

# Step 4 - Configurations
secure_mysql_installation
configure_mysql_replication

# Exit (proudly)
exit 0
