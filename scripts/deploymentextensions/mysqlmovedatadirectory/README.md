# MOVE MYSQL DATA DIRECTORY

**Function**
This deployment extension moves the data directory for the target mysql instance from its currently location to a user-specified location. It does the following:
1. stops the target server (_make sure the target server is not a master server_)
2. copies the data files for the target server to the new user-specified location
3. updates the configuration for the target server to use the updated data file path
4. restarts the target server

**Parameters**
1. _cluster-admin-email_: the email address of the cluster administrator that will be used for all deployment notifications
2. _target-datadirectory-path_: full path to the new location for the mysql data files
3. _mysql-server-port_: port on the mysql server used for communication
4. _mysql-admin-username_: user name of the mysql user with administrative priviledges
5. _mysql-admin-password_: password for the mysql user with administrative priviledges
6. _target-server-ip_: IP address of the target mysql server
7. _target-user_: operating system user account used to execute the updates

**Usage Example**
From a powershell session, execute the following commands:
1. `[array]$upgradeParameters = @( @{"name"="cluster-admin-email"; "value"="[Your Email Address]"}, @{"name"="target-datadirectory-path"; "value"="[Data Directory Path]"}, @{"name"="mysql-server-port"; "value"="[Mysql Server Port]"}, @{"name"="mysql-admin-username"; "value"="[Mysql Admininistrator User Name]"}, @{"name"="mysql-admin-password"; "value"="[Mysql Admininistrator User Password]"}, @{"name"="target-server-ip"; "value"="[Mysql Server IP Address]"}, @{"name"="target-user"; "value"="[OS User Account]"})`


2. `[Enlistment Root]\scripts\Deploy-CustomScriptsExtension-v2.ps1 -AzureSubscriptionName [Subscription Name] -ResourceGroupName [Cluster Name] -AadWebClientId "[AAD web client ID]" -AadWebClientAppKey "[AAD web client app key]" -AadTenantId "[AAD tenant id]" -TemplateFile "[Enlistment Root]\templates\stamp\stamp-v2-backend-upgrade.json" -TemplateParameterFile "[Enlistment Root]\templates\stamp\stamp-v2-backend-upgrade-parameters.json" -ClusterAdmininistratorEmailAddress [Your Email Address]  -InstallerPackageName "mysqlmovedatadirectory" -UpgradeParameters $upgradeParameters`	

**where**:
1. [Data Directory Path]: new data directory path (defaults to /datadisk/disk1/mysql)
2. [Mysql Server Port]: the communication port on the HA Proxy Server to use (defaults to 3306)
3. [Mysql Admininistrator User Name]: the user name of the mysql user with administrative priviledges
4. [Mysql Admininistrator User Password]: the password for the mysql user with administrative priviledges
5. [Mysql Server IP Address]: IP address of a target mysql server within the cluster
6. [OS User Account]: the existing operating system user account with access to install & configure HA Proxy and its dependencies
7. [Your Email Address] = email address to which deployment notifications will be sent
8. [Subscription Name] = name of your azure subscription
9. [Cluster Name] = name of the existing azure STAMP cluster/ resource group you intend to update
10. [AAD web client ID] - your AAD Web Client Id
11. [AAD web client app key] - your AAD Web Client Id
12. [AAD tenant id] - tenant Id of the AAD entity in which you have the web client