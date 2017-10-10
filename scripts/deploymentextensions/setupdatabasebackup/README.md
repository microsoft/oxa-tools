# SETUP DATABASE BACKUP

**Function**
This deployment extension sets up database backup for the cluster.

**Parameters**
1. _cluster-admin-email_: the email address of the cluster administrator that will be used for all deployment notifications
1. _mysql-server_: IP address of the master mysql server in the cluster (optional) **1**
1. _mysql-server-port_: port on the mysql server used for communication (optional)
1. _backup-storageaccount-name_: the azure storage account used for backups. **2**
1. _backup-storageaccount-key_: access key for the backup storage account.
1. _backup-storageaccount-endpointsuffix_: backup storage account endpoint suffix. (optional and defaults to global azure `core.windows.net`)
1. _backup-local-path_: local path on the target Jumpbox where backups will be temporarily kept before being pushed to the backup azure storage account. Ensure sure there is sufficient space on this partition for a single backup. (optional, defaults to the first disk of attached storage mounted at `/datadisks/disk1`)
1. _mysql-backup-frequency_: mysql backup frequency. Use cron scheduling notation. (optional, defaults to `11 */4 * * *`)
1. _mysql-backup-retentiondays_: maximum age in days for a mysql backup. Backups older than this threshold will be purged
1. _mysql-admin-username_: user name of the mysql user with administrative priviledges
1. _mysql-admin-password_: password for the mysql user with administrative priviledges
1. _mysql-backup-username_: user name of the mysql user that will be granted access to the generated mysql database backup (optional, defaults to _mysql-admin-username_)
1. _mysql-backup-password_: password for the mysql backup user (optional, defaults to _mysql-admin-password_)
1. _mongo-backup-frequency_: mongo backup frequency. Use cron scheduling notation. (optional, defaults to `0 0 * * *`)
1. _mongo-backup-retentiondays_: maximum age in days for a mongo backup. Backups older than this threshold will be purged
1. _mongo-admin-username_: user name of the mongo user with administrative priviledges
1. _mongo-admin-password_: password for the mysql user with administrative priviledges
1. _mongo-backup-username_: user name of the mongo user that will be granted access to the generated mongo database backup (optional, defaults to _mongo-admin-username_)
1. _mongo-backup-password_: password for the mongo backup user (optional, defaults to _mongo-admin-password_)
1. _azure-cli-version_: Azure Cli Version to use (optional, defaults to 1)

**Notes**:
1. See `MYSQL_MASTER_IP` in cloud config for expected value
1. This defaults to `{CLUSTER NAME}securesa`. Check your resource group in the azure portal for this.

**Usage Example**
From a powershell session, execute the following commands:
1. `[array]$upgradeParameters = @( @{"name"="cluster-admin-email"; "value"="[Your Email Address]"}, @{"name"="backup-storageaccount-name"; "value"="[Name of secure storage account for cluster]"}, @{"name"="backup-storageaccount-key"; "value"="[Key for secure storage account]"}, @{"name"="mysql-admin-username"; "value"="[Mysql Admininistrator User Name]"}, @{"name"="mysql-admin-password"; "value"="[Mysql Admininistrator User Password]"}, @{"name"="mongo-admin-username"; "value"="[Mongo Admininistrator User Name]"}, @{"name"="mongo-admin-password"; "value"="[Mongo Admininistrator User Password]"},@{"name"="azure-cli-version"; "value"=2} )`

2. `[Enlistment Root]\scripts\Deploy-CustomScriptsExtension-v2.ps1 -AzureSubscriptionName [Subscription Name] -ResourceGroupName [Cluster Name] -AadWebClientId "[AAD web client ID]" -AadWebClientAppKey "[AAD web client app key]" -AadTenantId "[AAD tenant id]" -TemplateFile "[Enlistment Root]\templates\stamp\stamp-v2-backend-upgrade.json" -TemplateParameterFile "[Enlistment Root]\templates\stamp\stamp-v2-backend-upgrade-parameters.json" -ClusterAdmininistratorEmailAddress [Your Email Address]  -InstallerPackageName "setupdatabasebackup" -UpgradeParameters $upgradeParameters`	

**where**:
1. [Enlistment Root]: location where the oxa-tools repository was cloned
1. [Subscription Name] = Name of your azure subscription
1. [Cluster Name] = name of the existing azure STAMP cluster/ resource group you intend to update
1. [AAD web client ID] - Your AAD Web Client Id
1. [AAD web client app key] - Your AAD Web Client Id
1. [AAD tenant id] - Tenant Id of the AAD entity in which you have the web client
1. [Your Email Address] - Your email address
1. [Mysql Admininistrator User Name]: the user name of the mysql user with administrative priviledges
1. [Mysql Admininistrator User Password]: the password for the mysql user with administrative priviledges
1. [Mongo Admininistrator User Name]: the user name of the mysql user with administrative priviledges
1. [Mongo Admininistrator User Password]: the password for the mysql user with administrative priviledges