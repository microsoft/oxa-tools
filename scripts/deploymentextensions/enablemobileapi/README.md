# ENABLE OPENEDX MOBILE REST API

**Function**
This deployment enables the Open edX Mobile Rest Api ([reference](http://edx.readthedocs.io/projects/edx-platform-api/en/latest/mobile/index.html)). This api has been deprecated but there isn't a suitable replacement API that provides xxxx - thus necessitating its continued use for enabling deep application integration workflows.

**Parameters**
1. _target-user_: operating system user account whose authorized key is being updated
2. _cluster-admin-email_: email address to which errors and other notifications will be sent

**Usage Example**
From a powershell session, execute the following commands:
1. `[array]$upgradeParameters = @( @{"name"="target-user"; "value"="[OS User Account]"}, @{"name"="cluster-admin-email"; "value"="[Your Email Address]"})`

2. `[Enlistment Root]\scripts\Deploy-CustomScriptsExtension-v2.ps1 -AzureSubscriptionName [Subscription Name] -ResourceGroupName [Cluster Name] -AadWebClientId "[AAD web client ID]" -AadWebClientAppKey "[AAD web client app key]" -AadTenantId "[AAD tenant id]" -TemplateFile "[Enlistment Root]\templates\stamp\stamp-v2-backend-upgrade.json" -TemplateParameterFile "[Enlistment Root]\templates\stamp\stamp-v2-backend-upgrade-parameters.json" -ClusterAdmininistratorEmailAddress [Your Email Address]  -InstallerPackageName "rotatesshkey" -UpgradeParameters $upgradeParameters`

**where**:
1. [OS User Account]: the existing operating system user account whose authorized key you want to rotate 
2. [Path to SSH Public Key]: the full path to the replacement public key
3. [Enlistment Root]: location where the oxa-tools repository was cloned
5. [Subscription Name] = Name of your azure subscription
6. [Cluster Name] = name of the existing azure STAMP cluster/ resource group you intend to update
7. [AAD web client ID] - Your AAD Web Client Id
8. [AAD web client app key] - Your AAD Web Client Id
9. [AAD tenant id] - Tenant Id of the AAD entity in which you have the web client
10. [Your Email Address] - Your/Admin email address