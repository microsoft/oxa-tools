# INSTALL TOOLS

**Function**
This deployment extension updates the dependent tools on Jumpbox. Optionally, other backend servers can be updated. The tools installed are: _git, gittext, bc, mysql client & utilities, mongo shell, powershell, azure cli 1 & 2, mailutils, ssmtp_. Additionally, the server timezone is updated & the mailer is configured.

**Parameters**
1. _smtp-server_: name of your SMTP server
2. _smtp-server-port_: port on your SMTP server used for communications
3. _smtp-auth-user_: user account used for authenticating against your smtp server
4. _smtp-auth-user-password_: password for the user account used for authenticating against your smtp server
5. _cluster-admin-email_: the email address of the cluster administrator that will be used for all deployment notifications
6. _backend-server-list_: space-separated list of IP addresses for other backend servers on which to install tools (**optional**)
7. _target-user_: operating system user account used to execute the updates

**Usage Example**
From a powershell session, execute the following commands:
1. `[array]$upgradeParameters = @( @{"name"="smtp-server"; "value"="[Smtp Server Name]"}, @{"name"="smtp-server-port"; "value"="[Smtp Server Port]"}, @{"name"="smtp-auth-user"; "value"="[Smtp Auth User]"}, @{"name"="smtp-auth-user-password"; "value"="[Smtp Auth User Password]"}, @{"name"="cluster-admin-email"; "value"="[Your Email Address]"}, @{"name"="backend-server-list"; "value"="[Ip Addresses]"; "valueType"="Base64"} @{"name"="target-user"; "value"="[OS User Account]"})`

2. `[Enlistment Root]\scripts\Deploy-CustomScriptsExtension-v2.ps1 -AzureSubscriptionName [Subscription Name] -ResourceGroupName [Cluster Name] -AadWebClientId "[AAD web client ID]" -AadWebClientAppKey "[AAD web client app key]" -AadTenantId "[AAD tenant id]" -TemplateFile "[Enlistment Root]\templates\stamp\stamp-v2-backend-upgrade.json" -TemplateParameterFile "[Enlistment Root]\templates\stamp\stamp-v2-backend-upgrade-parameters.json" -ClusterAdmininistratorEmailAddress [Your Email Address]  -InstallerPackageName "installtools" -UpgradeParameters $upgradeParameters`	

**where**:
1. [Smtp Server Name]: the FQDN name of the SMTP server that will be used for sending all emails
2. [Smtp Server Port]: the communication port on the SMTP server to use
3. [Smtp Auth User]: the user account used in authenticating against the SMTP server
4. [Smtp Auth User Password]: the password for the Smtp Auth User
5. [Your Email Address] - Your/Admin email address
6. [Ip Addresses]: a space-separated list of Ip Address of the backend servers for which tools will be installed/updated
5. [OS User Account]: the existing operating system user account whose authorized key you want to rotate 
7. [Enlistment Root]: location where the oxa-tools repository was cloned
8. [Subscription Name] = Name of your azure subscription
9. [Cluster Name] = name of the existing azure STAMP cluster/ resource group you intend to update
10. [AAD web client ID] - Your AAD Web Client Id
11. [AAD web client app key] - Your AAD Web Client Id
12. [AAD tenant id] - Tenant Id of the AAD entity in which you have the web client