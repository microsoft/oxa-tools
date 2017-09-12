# MYSQL FAILOVER

**Function**
This deployment extension executes the failover/switchover from the current Mysql Master to a new server within the cluster. This deployment supports two modes:
1. **query** - queries the status of the mysql replication cluster, showing the current master and its slaves
2. **execute** - actually executes the failover/switchover to a new mysql master

**Parameters**
1. _cluster-admin-email_: the email address of the cluster administrator that will be used for all deployment notifications
2. _mysql-server-port_: port on the mysql server used for communication
3. _haproxy-server-port_: port on the haproxy server used for backend proxy communication
4. _mysql-admin-username_: user name of the mysql user with administrative priviledges
5. _mysql-admin-password_: password for the mysql user with administrative priviledges
6. _new-master-server-ip_: IP address of the new mysql master server
7. _current-master-server-ip_: IP address of the current mysql master server
8. _backend-server-list_: space-separated list of IP addresses for other backend servers on which to install tools
9. _operation_: the operation mode for the script: query or execute
10. _force_: indicator of whether or not to force a failover despite detection of errant transactions on slaves. Expected values: 1 or 0 **optional**

**Usage Example**
From a powershell session, execute the following commands to **query the status of mysql cluster**:
1. `[array]$upgradeParameters = @( @{"name"="cluster-admin-email"; "value"="[Your Email Address]"}, @{"name"="mysql-server-port"; "value"="[Mysql Server Port]"}, @{"name"="haproxy-server-port"; "value"="[HA Proxy Server Port]"}, @{"name"="mysql-admin-username"; "value"="[Mysql Admininistrator User Name]"}, @{"name"="mysql-admin-password"; "value"="[Mysql Admininistrator User Password]"}, @{"name"="new-master-server-ip"; "value"="[IP Address - New Master]"}, @{"name"="current-master-server-ip"; "value"="[IP Address - Current Master]"}, @{"name"="backend-server-list"; "value"="[Ip Addresses]"; "valueType"="Base64"}, @{"name"="operation"; "value"="[Failover Operation Type]"})`

2. `[Enlistment Root]\scripts\Deploy-CustomScriptsExtension-v2.ps1 -AzureSubscriptionName [Subscription Name] -ResourceGroupName [Cluster Name] -AadWebClientId "[AAD web client ID]" -AadWebClientAppKey "[AAD web client app key]" -AadTenantId "[AAD tenant id]" -TemplateFile "[Enlistment Root]\templates\stamp\stamp-v2-backend-upgrade.json" -TemplateParameterFile "[Enlistment Root]\templates\stamp\stamp-v2-backend-upgrade-parameters.json" -ClusterAdmininistratorEmailAddress [Your Email Address]  -InstallerPackageName "mysqlfailover" -UpgradeParameters $upgradeParameters`	

From a powershell session, execute the following commands to **initiate actual failover of mysql master**:
1. `[array]$upgradeParameters = @( @{"name"="cluster-admin-email"; "value"="[Your Email Address]"}, @{"name"="mysql-server-port"; "value"="[Mysql Server Port]"}, @{"name"="haproxy-server-port"; "value"="[HA Proxy Server Port]"}, @{"name"="mysql-admin-username"; "value"="[Mysql Admininistrator User Name]"}, @{"name"="mysql-admin-password"; "value"="[Mysql Admininistrator User Password]"}, @{"name"="new-master-server-ip"; "value"="[IP Address - New Master]"}, @{"name"="current-master-server-ip"; "value"="[IP Address - Current Master]"}, @{"name"="backend-server-list"; "value"="[Ip Addresses]"; "valueType"="Base64"}, @{"name"="operation"; "value"="query"})`

2. `[Enlistment Root]\scripts\Deploy-CustomScriptsExtension-v2.ps1 -AzureSubscriptionName [Subscription Name] -ResourceGroupName [Cluster Name] -AadWebClientId "[AAD web client ID]" -AadWebClientAppKey "[AAD web client app key]" -AadTenantId "[AAD tenant id]" -TemplateFile "[Enlistment Root]\templates\stamp\stamp-v2-backend-upgrade.json" -TemplateParameterFile "[Enlistment Root]\templates\stamp\stamp-v2-backend-upgrade-parameters.json" -ClusterAdmininistratorEmailAddress [Your Email Address]  -InstallerPackageName "mysqlfailover" -UpgradeParameters $upgradeParameters`

> **Note**:
In case an **execute** operation returns with a failure due to errant transactions, you will need to investigate what those errant transactions are and deal with them (beyond the scope of this document). If you decide to ignore the error, you must set **force=1** in the upgrade parameters array to override the default behavior.

**where**:
1. [Mysql Server Port]: the communication port on the HA Proxy Server to use (defaults to 3306)
2. [HA Proxy Server Port]: the communication port on the HA Proxy Server to use
3. [Mysql Admininistrator User Name]: the user name of the mysql user with administrative priviledges
4. [Mysql Admininistrator User Password]: the password for the mysql user with administrative priviledges
5. [IP Address - New Master]: IP address of a target mysql server within the cluster to be used as the new Master
6. [IP Address - Current Master]: IP address of a target mysql server within the cluster to be used as the new Master
7. [Ip Addresses]: a space-separated list of Ip Address of the backend servers for which tools will be installed/updated
8. [Failover Operation Type]: type of failover operation: query or execute
8. [Failover Operation Override]: type of failover operation: query or execute
9. [Your Email Address] = email address to which deployment notifications will be sent
10. [Subscription Name] = name of your azure subscription
11. [Cluster Name] = name of the existing azure STAMP cluster/ resource group you intend to update
12. [AAD web client ID] - your AAD Web Client Id
13. [AAD web client app key] - your AAD Web Client Id
14. [AAD tenant id] - tenant Id of the AAD entity in which you have the web client