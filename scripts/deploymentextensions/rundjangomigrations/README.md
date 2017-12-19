# RUN DJANGO MIGRATION

**Function**
This deployment extension runs django migrations for a specific app in INSTALLED_APPS of edx-platform
It DOES NOT run the django makemigrations. Migrations need to be checked in.

**Parameters**
1. _cluster-admin-email_: the email address of the cluster administrator that will be used for all deployment notifications
2. _target-edx-system_: The edX system to run commands on. Can be one of {lms|cms}
3. _target-django-application_: The edX django application to run migrations for
6. _target-server-ip_: IP address of the target edxapp server
7. _target-user_: operating system user account used to execute the updates

**Usage Example**
From a powershell session, execute the following commands:
1. `[array]$upgradeParameters = @( @{"name"="cluster-admin-email"; "value"="[Your Email Address]"}, @{"name"="target-edx-system"; "value"="[edX System (lms|cms)]"}, @{"name"="target-django-application"; "value"="[Django Application in INSTALLED_APPS of edx-system to run migrations for]"}, @{"name"="target-server-ip"; "value"="[Mysql Server IP Address]"}, @{"name"="target-user"; "value"="[OS User Account]"})`

2. `[Enlistment Root]\scripts\Deploy-CustomScriptsExtension-v2.ps1 -AzureSubscriptionName [Subscription Name] -ResourceGroupName [Cluster Name] -AadWebClientId "[AAD web client ID]" -AadWebClientAppKey "[AAD web client app key]" -AadTenantId "[AAD tenant id]" -TemplateFile "[Enlistment Root]\templates\stamp\stamp-v2-backend-upgrade.json" -TemplateParameterFile "[Enlistment Root]\templates\stamp\stamp-v2-backend-upgrade-parameters.json" -ClusterAdmininistratorEmailAddress [Your Email Address]  -InstallerPackageName "rundjangomigrations" -UpgradeParameters $upgradeParameters`

**where**:
1. [OS User Account]: the existing operating system user account whose authorized key you want to rotate 
2. [Enlistment Root]: location where the oxa-tools repository was cloned
3. [Cluster Name] = name of the existing azure STAMP cluster/ resource group you intend to update
4. [AAD web client ID] - Your AAD Web Client Id
5. [AAD web client app key] - Your AAD Web Client Id
6. [AAD tenant id] - Tenant Id of the AAD entity in which you have the web client
7. [Your Email Address] - Your/Admin email address
8. [Subscription Name] = Name of your azure subscription