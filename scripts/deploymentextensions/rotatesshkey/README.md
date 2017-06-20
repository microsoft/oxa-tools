# ROTATE SSH KEY

**Function**
This deployment extension rotates the SSH key that is authorized for an existing user account.

**Parameters**
1. _target-user_: operating system user account whose authorized key is being updated
2. _public-key_ : the encoded public key to set as the only authorized key for the target user account. 
_**Note**: When deploying via powershell, this value is expected to be the path to the public key and you must set the **valueType** metadata for the parameter. The powershell script takes care of reading the file and encoding it._
3. _cluster-admin-email_: email address to which errors and other notifications will be sent

**Usage Example**
From a powershell session, execute the following commands:
1. `[array]$upgradeParameters = @( @{"name"="target-user"; "value"="[OS User Account]"}, @{"name"="public-key"; "value"="[Path to SSH Public Key]"; "valueType"="File"}, @{"name"="cluster-admin-email"; "value"="[Your Email Address]"})`

2. `[Enlistment Root]\scripts\Deploy-CustomScriptsExtension-v2.ps1 -AzureSubscriptionName [Subscription Name] -ResourceGroupName [Cluster Name] -AadWebClientId "[AAD web client ID]" -AadWebClientAppKey "[AAD web client app key]" -AadTenantId "[AAD tenant id]" -TemplateFile "[Enlistment Root]\templates\stamp\stamp-v2-backend-upgrade.json" -TemplateParameterFile "[Enlistment Root]\templates\stamp\stamp-v2-backend-upgrade-parameters.json" -ClusterAdmininistratorEmailAddress [Your Email Address]  -InstallerPackageName "rotatesshkey" -UpgradeParameters $upgradeParameters`	

**where**:
1. [OS User Account]: the existing operating system user account whose authorized key you want to rotate 
2. [Path to SSH Public Key]: the full path to the replacement public key
2. [Enlistment Root]: location where the oxa-tools repository was cloned
2. [Subscription Name] = Name of your azure subscription
3. [Cluster Name] = name of the existing azure STAMP cluster/ resource group you intend to update
4. [AAD web client ID] - Your AAD Web Client Id
5. [AAD web client app key] - Your AAD Web Client Id
6. [AAD tenant id] - Tenant Id of the AAD entity in which you have the web client
7. [Your Email Address] - Your/Admin email address