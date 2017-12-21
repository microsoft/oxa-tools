# RUN DJANGO MIGRATION

**Function**

Whenever we edit a `models.py` class we need to create and run a django migration to 
sync these model changes to the database.

This deployment extension runs django migrations for a specific app in INSTALLED_APPS of edx-platform
It DOES NOT run the django `manage.py makemigrations` command. Migrations need to be checked in before running this extension.

This script will just run the django `manage.py migrate` command for the specified target_django_application

Example script that will be run on a single front end VM
if _target_edx_system_ = 'lms' and _target_django_application_ = 'courseware'

```
$ python /edx/app/edxapp/edx-platform/manage.py lms migrate courseware --settings=aws --noinput
```

This runs new migrations for model changes to the courseware app.

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