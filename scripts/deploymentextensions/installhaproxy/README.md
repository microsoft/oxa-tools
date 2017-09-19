# INSTALL HA Proxy

**Function**
This deployment extension installs [HA Proxy](http://www.haproxy.org/) on the target server. This installation enables seamless mysql master failover with minimal application impact.

**Parameters**
1. _cluster-admin-email_: the email address of the cluster administrator that will be used for all deployment notifications
2. _haproxy-server_: the ip address of the backend server that will be used as proxy (all application servers will use this server for backend mysql calls)
3. _haproxy-server-port_: port on the haproxy server used for backend proxy communication
4. _haproxy-server-probe-port_: port on the backend mysql servers that the proxy server will used to determine mysql master server availability
5. _haproxy-probe-interval-sec_: interval (in seconds) for the haproxy probe to query all backend mysql servers to determine mysql master server availability
6. _mysql-admin-username_: user name of the mysql user with administrative priviledges
7. _mysql-admin-password_: password for the mysql user with administrative priviledges
8. _backend-server-list_: space-separated list of IP addresses for other backend servers on which to install tools
9. _target-user_: operating system user account used to execute the updates

**Usage Example**
From a powershell session, execute the following commands:
1. `[array]$upgradeParameters = @( @{"name"="haproxy-server"; "value"="[HA Proxy Server]"}, @{"name"="haproxy-server-port"; "value"="[HA Proxy Server Port]"}, @{"name"="haproxy-server-probe-port"; "value"="[HA Proxy Server Probe Port]"}, @{"name"="haproxy-probe-interval-sec"; "value"="[HA Proxy Server Probe Interval]"},  @{"name"="mysql-admin-username"; "value"="[Mysql Admininistrator User Name]"}, @{"name"="mysql-admin-password"; "value"="[Mysql Admininistrator User Password]"}, @{"name"="backend-server-list"; "value"="[Ip Addresses]"; "valueType"="Base64"}, @{"name"="target-user"; "value"="[OS User Account]"}, @{"name"="cluster-admin-email"; "value"="[Your Email Address]"})`

2. `[Enlistment Root]\scripts\Deploy-CustomScriptsExtension-v2.ps1 -AzureSubscriptionName [Subscription Name] -ResourceGroupName [Cluster Name] -AadWebClientId "[AAD web client ID]" -AadWebClientAppKey "[AAD web client app key]" -AadTenantId "[AAD tenant id]" -TemplateFile "[Enlistment Root]\templates\stamp\stamp-v2-backend-upgrade.json" -TemplateParameterFile "[Enlistment Root]\templates\stamp\stamp-v2-backend-upgrade-parameters.json" -ClusterAdmininistratorEmailAddress [Your Email Address]  -InstallerPackageName "installhaproxy" -UpgradeParameters $upgradeParameters`	

**where**:
1. [HA Proxy Server]: IP address of the backend server that will be used as proxy
2. [HA Proxy Server Port]: the communication port on the HA Proxy Server to use
3. [HA Proxy Server Probe Port]: the communication port on the backend mysql servers that the proxy server will used to determine mysql master server availability
4. [HA Proxy Server Probe Interval]: interval (in seconds) for the haproxy probe to query all backend mysql servers to determine mysql master server availability
5. [Mysql Admininistrator User Name]: the user name of the mysql user with administrative priviledges
6. [Mysql Admininistrator User Password]: the password for the mysql user with administrative priviledges
5. [Ip Addresses]: a comma-separated list of IP addresses associated with the target mysql backend servers
7. [OS User Account]: the existing operating system user account with access to install & configure HA Proxy and its dependencies
8. [Your Email Address] = email address to which deployment notifications will be sent
9. [Subscription Name] = name of your azure subscription
10. [Cluster Name] = name of the existing azure STAMP cluster/ resource group you intend to update
11. [AAD web client ID] - your AAD Web Client Id
12. [AAD web client app key] - your AAD Web Client Id
13. [AAD tenant id] - tenant Id of the AAD entity in which you have the web client