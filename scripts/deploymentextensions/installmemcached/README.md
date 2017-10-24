# INSTALL MEMCACHE

**Function**
This deployment extension installs an additional memcache server for use during deployments. STAMP supports two deployment endpoints and each one is expected to use a separate memcache server. Before enabling upgrade deployments, this deployment extension must be run.

**Parameters**
1. _target-user_: operating system user account used to execute the updates

**Usage Example**
From a powershell session, execute the following commands:
1. `[array]$upgradeParameters = @( @{"name"="cluster-admin-email"; "value"="[Your Email Address]"}, @{"name"="target-user"; "value"="[OS User Account]"})`

2. `[Enlistment Root]\scripts\Deploy-CustomScriptsExtension-v2.ps1 -AzureSubscriptionName [Subscription Name] -ResourceGroupName [Cluster Name] -AadWebClientId "[AAD web client ID]" -AadWebClientAppKey "[AAD web client app key]" -AadTenantId "[AAD tenant id]" -TemplateFile "[Enlistment Root]\templates\stamp\stamp-v2-backend-upgrade.json" -TemplateParameterFile "[Enlistment Root]\templates\stamp\stamp-v2-backend-upgrade-parameters.json" -ClusterAdmininistratorEmailAddress [Your Email Address]  -InstallerPackageName "installmemcached" -UpgradeParameters $upgradeParameters`	

**where**:
1. [Your Email Address] - Your/Admin email address
1. [OS User Account]: the existing operating system user account whose authorized key you want to rotate 
1. [Enlistment Root]: location where the oxa-tools repository was cloned
1. [Subscription Name] = Name of your azure subscription
1. [Cluster Name] = name of the existing azure STAMP cluster/ resource group you intend to update
1. [AAD web client ID] - Your AAD Web Client Id
1. [AAD web client app key] - Your AAD Web Client Id
1. [AAD tenant id] - Tenant Id of the AAD entity in which you have the web client