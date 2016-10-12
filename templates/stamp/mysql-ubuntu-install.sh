#!/bin/bash

# general parameters
PACKAGE_VERSION=5.7
PACKAGE_NAME=mysql-server
MYSQL_SERVER_PACKAGE_NAME="${PACKAGE_NAME}-${PACKAGE_VERSION}"

MYSQL_REPLICATION_NODEID=
NODE_ADDRESS=`ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'`

NETWORK_PREFIX="10.0.0"
MASTER_NODE_IPADDRESS=
MYSQL_REPLICATION_USER=lexoxamysqlrepluser
MYSQL_REPLICATION_PASSWORD=f@ncyP@ssW0rd!
MYSQL_ADMIN_USER=lexoxamysqladmin
MYSQL_ADMIN_PASSWORD=f@ncyP@ssW0rd!
MYSQL_PORT=3306

DATA_DISKS="/datadisks"
DATA_MOUNTPOINT="$DATA_DISKS/disk1"
MYSQL_DATA="$DATA_MOUNTPOINT/mysql"

help()
{
	echo "This script installs Mysql on the Ubuntu virtual machine image"
	echo "Options:"
	echo "		-n Mysql replica node id"
	echo "		-m ip address of the Mysql master node"
	echo "		-v Mysql package version"
	echo "		-r Mysql replication user name"
	echo "		-k Mysql replication password"
	echo "		-u Mysql administrator user name"
	echo "		-p Mysql administrator user password"	
}


log "Begin execution of Mysql installation script extension on ${HOSTNAME}"

if [ "${UID}" -ne 0 ];
then
    log "Script executed without root permissions"
    echo "You must be root to run this program." >&2
    exit 3
fi


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
	v) Mysql package version
		PACKAGE_VERSION=${OPTARG}
		;;
	r) # Mysql replication user name
		MYSQL_REPLICATION_USER=${OPTARG}
		;;	
	k) # Mysql replication password
		MYSQL_REPLICATION_PASSWORD=${OPTARG}
		;;	
	u) # Mysql administrator user name
		MYSQL_ADMIN_USER=${OPTARG}
		;;		
	p) # Mysql administrator user password
		MYSQL_ADMIN_PASSWORD=${OPTARG}
		;;
    h)  # Helpful hints
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

#############################################################################
log()
{
	# If you want to enable this logging add a un-comment the line below and add your account key 
	#curl -X POST -H "content-type:text/plain" --data-binary "$(date) | ${HOSTNAME} | $1" https://logs-01.loggly.com/inputs/${LOGGING_KEY}/tag/redis-extension,${HOSTNAME}
    TIMESTAMP=`date +"%D %T"`
	echo "${TIMESTAMP} :: $1"
}


#############################################################################
configure_datadisks()
{
	# Stripe all of the data 
	log "Formatting and configuring the data disks"
	
	bash ./vm-disk-utils-0.1.sh -b $DATA_DISKS -s
}


#############################################################################
tune_memory()
{
    log "Tuning System - Memory"

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

tune_system()
{
    log "Tuning System - Networking"

	# Add local machine name to the hosts file to facilitate IP address resolution
	if grep -q "${HOSTNAME}" /etc/hosts
	then
	  echo "${HOSTNAME} was found in /etc/hosts"
	else
	  echo "${HOSTNAME} was not found in and will be added to /etc/hosts"
	  # Append it to the hsots file if not there
	  echo "127.0.0.1 $(hostname)" >> /etc/hosts
	  log "Hostname ${HOSTNAME} added to /etc/hosts"
	fi	
}

#############################################################################
start_mysql()
{
	log "Starting Mysql Server"
	systemctl start mysqld

	# Wait for Mysql daemon to start and initialize for the first time (this may take up to a minute or so)
	while ! timeout 1 bash -c "echo > /dev/tcp/localhost/$MYSQL_PORT"; do sleep 10; done

	log "${MYSQL_SERVER_PACKAGE_NAME} has been started"

    # enable mysqld on startup
    systemctl enable mysqld
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

	apt-get -y update

	echo $MYSQL_SERVER_PACKAGE_NAME mysql-server/root_password password $MYSQL_ADMIN_PASSWORD | debconf-set-selections
	echo MYSQL_SERVER_PACKAGE_NAME mysql-server/root_password_again password $MYSQL_ADMIN_PASSWORD | debconf-set-selections
	apt-get install -y $MYSQL_SERVER_PACKAGE_NAME

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
	systemctl daemon-reload
}


# create the mysql replication configuration file
create_config_file()
{
	MYCNF_PATH="/etc/my.cnf"
	MYCNF_TEMPLATE_PATH="./mysqld.template.cnf"
	TEMP_MYCNF_PATH="./mysqld.custom.cnf"
	TARGET_MYCNF_DIR="/etc/mysql/conf.d"
	TARGET_MYCNF_PATH="${TARGET_MYCNF_DIR}/mysqld.cnf"

	REPL_EXPIRE_LOG_DAYS=10
	REPL_MAX_BINLOG_SIZE=100M
	REPL_RELAY_LOG_SPACE_LIMIT=20GB

	# we expect the configuration template to be already downloaded and locally available
	cp $MYCNF_TEMPLATE_PATH $TEMP_MYCNF_PATH

	# update the generic settings
	#sed -i "s/^bind-address=.*/bind-address=${NODE_ADDRESS}/I" $TEMP_MYCNF_PATH
    sed -i "s/^server-id=.*/server-id=${MYSQL_REPLICATION_NODEID}/I" $TEMP_MYCNF_PATH
	

	# 1. perform necessary settings replacements
	if [ ${MYSQL_REPLICATION_NODEID} -eq 1 ];
	then
		log "Mysql Replication Master Node detected. Creating *.cnf for the MasterNode on ${HOSTNAME}"
		
		sed -i "s/^#log_bin=.*/log_bin=\/var\/log\/mysql\/mysql-bin-${HOSTNAME}.log/I" $TEMP_MYCNF_PATH
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
		log "Existing configuration detected at ${TARGET_MYCNF_PATH} and will be backed up to ${TARGET_MYCNF_DIR}/mysqld.backup_${TIMESTAMP}"
		mv $TARGET_MYCNF_PATH "${TARGET_MYCNF_DIR}/mysqld.backup_${TIMESTAMP}"
	else
		log "No existing mysql server configuration found at ${TARGET_MYCNF_PATH}"
	fi

	# 3. move the custom file to the proper location & update permissions
	cp $TEMP_MYCNF_PATH "${TARGET_MYCNF_DIR}/mysqld.cnf"
	chmod 544 "${TARGET_MYCNF_DIR}/mysqld.cnf"

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
CREATE USER IF NOT EXISTS '{MYSQL_ADMIN_USER}'@'{NETWORK_PREFIX}.%' IDENTIFIED BY '{MYSQL_ADMIN_PASSWORD}';	
GRANT ALL PRIVILEGES ON *.* TO '{MYSQL_ADMIN_USER}'@'{NETWORK_PREFIX}.%';
GRANT REPLICATION SLAVE ON *.* TO '{MYSQL_ADMIN_USER}'@'{NETWORK_PREFIX}.%';
GRANT REPLICATION CLIENT ON *.* TO '{MYSQL_ADMIN_USER}'@'{NETWORK_PREFIX}.%';
CREATE USER IF NOT EXISTS '{MYSQL_REPLICATION_USER}'@'%' IDENTIFIED BY '{MYSQL_REPLICATION_PASSWORD}';
GRANT REPLICATION SLAVE ON *.* TO '{MYSQL_REPLICATION_USER}'@'%' ; 
FLUSH PRIVILEGES;
EOF

	else
		log "Mysql Replication Slave Node detected. Setting up Slave Replication on ${HOSTNAME} with master at ${MASTER_NODE_IPADDRESS}"

		tee ./$TMP_QUERY_FILE > /dev/null <<EOF
CREATE USER IF NOT EXISTS '{MYSQL_ADMIN_USER}'@'{NETWORK_PREFIX}.%' IDENTIFIED BY '{MYSQL_ADMIN_PASSWORD}';	
GRANT ALL PRIVILEGES ON *.* TO '{MYSQL_ADMIN_USER}'@'{NETWORK_PREFIX}.%';
GRANT REPLICATION SLAVE ON *.* TO '{MYSQL_ADMIN_USER}'@'{NETWORK_PREFIX}.%';
GRANT REPLICATION CLIENT ON *.* TO '{MYSQL_ADMIN_USER}'@'{NETWORK_PREFIX}.%';
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

	# remove the temp file (security reasons)
	#rm ./$TMP_QUERY_FILE

}

#############################################################################
secure_mysql_installation()
{
	log "Running Mysql secure installation script"
	/usr/bin/mysql_secure_installation -p$MYSQL_ADMIN_PASSWORD <<<'
n
y
y
y
y
y'

}


# Step 1: Configuring Disks"
configure_datadisks

# Step 2 : Tuning System"
tune_memory
tune_system

# Step 3: Install Mysql Server & Initial Configuration"
install_mysql_server
create_config_file
restart_mysql

# Step 4 - Configurations
secure_mysql_installation
configure_mysql_replication

# Exit (proudly)
exit 0