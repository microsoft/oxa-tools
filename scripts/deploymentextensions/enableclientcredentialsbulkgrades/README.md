# ENABLE CLIENT CREDENTIALS & BULK GRADES

**Function**
This deployment enables the client credentials & bulk grades on Ficus for existing OXA STAMP clusters. These changes enable Microsoft to get additional learner data for reporting purposes.

**Important**:
Before running the deployment extension, please confirm the following that you have deployed Open edX using _Microsoft STAMP ARM template_; which is running Ficus.1 version of Open edX avaliable from http://github.com/microsoft/edx-platform **oxa/master.fic** branch. Please do not run this extension, if you are **NOT** using _Microsoft STAMP ARM Template_.

If you don't meet these conditions and would still like to apply the changes, please reference the following PRs:
1. https://github.com/Microsoft/edx-platform/pull/228 
1. https://github.com/Microsoft/edx-platform/pull/233 


**Parameters**
1. _target-user_: operating system user account whose authorized key is being updated
2. _cluster-admin-email_: email address to which errors and other notifications will be sent
3. _edxplatform-public-github-projectbranch_: the OXA edx-platform repository branch to use as source reference

**Usage Example**
From a powershell session, execute the following commands:
1. `[array]$upgradeParameters = @( @{"name"="target-user"; "value"="[OS User Account]"}, @{"name"="cluster-admin-email"; "value"="[Your Email Address]"}, @{"name"="edxplatform-public-github-projectbranch"; "value"="[OXA edX Platform Branch]"})`

2. `[Enlistment Root]\scripts\Deploy-CustomScriptsExtension-v2.ps1 -AzureSubscriptionName [Subscription Name] -ResourceGroupName [Cluster Name] -AadWebClientId "[AAD web client ID]" -AadWebClientAppKey "[AAD web client app key]" -AadTenantId "[AAD tenant id]" -TemplateFile "[Enlistment Root]\templates\stamp\stamp-v2-backend-upgrade.json" -TemplateParameterFile "[Enlistment Root]\templates\stamp\stamp-v2-backend-upgrade-parameters.json" -ClusterAdmininistratorEmailAddress [Your Email Address]  -InstallerPackageName "enableclientcredentialsbulkgrades" -UpgradeParameters $upgradeParameters`

**where**:
1. [OS User Account]: the existing operating system user account whose authorized key you want to rotate 
1. [OXA edX Platform Branch]: branch of the OXA edx-platform repository to use as source 
1. [Enlistment Root]: location where the oxa-tools repository was cloned
1. [Subscription Name] = Name of your azure subscription
1. [Cluster Name] = name of the existing azure STAMP cluster/ resource group you intend to update
1. [AAD web client ID] - Your AAD Web Client Id
1. [AAD web client app key] - Your AAD Web Client Id
1. [AAD tenant id] - Tenant Id of the AAD entity in which you have the web client
1. [Your Email Address] - Your/Admin email address