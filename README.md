# oxa-tools

Deploying and maintaining Open edX on Azure

## Deploying single machine instance (for development and test)

Execute `onebox.sh` on any Ubuntu 16 machine.

Common parameter argument options: pick a cell from each column. The first row is what happens when no additional parameter arguments are provided.

`--role` or `-r` or <br/> `--stack` or `-s` | `--branches` or `-b` | credential parameter arguments | `--msft-oauth`
--- | --- | --- | ---
`fullstack` (default) | `edge` (default) <br/> (oxa/dev.fic branches) | randomly generated (default) | off (default)
`devstack` | `ginkgo` <br/> (edx repositories and <br/> open-release/ginkgo.1 tag) | `--default-password` or `-d` <br/> `anyString` <br/> (set all passwords to anyString) | `prod` <br/> (uses login.live)
 &nbsp; | `release` <br/> (oxa/release.fic branches)  | &nbsp; | &nbsp; 
 &nbsp; | `stable` <br/> (oxa/master.fic branches) | &nbsp; | &nbsp; 
 &nbsp; | `ficus` <br/> (edx repositories and <br/> open-release/ficus.1 tag) | &nbsp; | &nbsp; 
 &nbsp; | edit onebox.sh to specify custom <br/> remote urls and branches directly | edit onebox.sh to specify custom <br/> usernames and passwords directly | &nbsp; 

For example:
`sudo onebox.sh` OR
`sudo bash onebox.sh -r devstack -b stable -d hokiePokiePass11 --msft-oauth prod`

What's been tested: server edition on azure, desktop edition in virtualbox VM, docker containers with systemd. Please open an "issue" in Github if you encounter any problems.

## Deploying high availability instance (for production-like environments)

(pdf) https://assets.microsoft.com/en-us/openedx-on-azure-ficus-stamp-deployment.pdf

## todo:
 * 100628 more documentation for onebox (fullstack and devstack) deployments like
   *  more details on the various way of provisioning the OS
   *  hyperlinks to edx documentation for using fullstack and devstack deployments
   
## Open edX on Azure Deployment Guide
 ### 1. Deployment Guide Overview
 This guide is for Open edX on Azure Deployment for the Learning as a Service (LaaS) program. There
are three basic steps to onboard into the LaaS program:
1. Acceptance into the LaaS program
2. Deploying your Open edX on Azure and
3. Getting the Microsoft Certificates ready for users.
This Deployment Guide covers getting your Open edX on Azure instance running (Step 2)

When you complete the step in this guide, your Content Management System (CMS, also called Studio)
and your Learning Management System (LMS) will be operational.
The deployment covered in this guide has the architecture shown below. This architecture is designed
to be a scalable and highly available Open edX solution.

To do the Open edX Deployment, you’ll create and then run a PowerShell script. The script will
provision the required Azure Virtual Machines and setup the right configurations and deploy them on Azure. 
The whole process can take several hours. The format of the PowerShell script is shown below.
This guide covers how to gather the various parameters used in the script.

Note: After retrieving the parameters and creating your deployment script, you will run the PowerShell
script in Administrator mode.

````
[Enlistment Root]\oxa-tools\scripts\Deploy-OxaStamp.ps1 -ResourceGroupName [Cluster
Name] -Location "[Location]" -TargetPath "[Enlistment Root]\oxatools\config\stamp\default" -AadWebClientId “<AADWebClientId>” -AadWebClientAppKey
“<AADWebClientAppKey>” -AadTenantId “<AADTenantId>” -AzureSubscriptionName
“[Subscription Name]” -KeyVaultDeploymentArmTemplateFile "[Enlistment Root]\oxatools\templates\stamp\stamp-keyvault.json" -FullDeploymentParametersFile "[Enlistment
Root]\oxa-tools\config\stamp\default\parameters.json" -FullDeploymentArmTemplateFile
"[Enlistment Root]\oxa-tools\templates\stamp\stamp-v2.json" -
ClusterAdministratorEmailAddress [ClusterAdministratorEmailAddress] -SmtpServer “<SMTP
Server Name>” -SmtpServerPort <SMTP Server Port> -SmtpAuthenticationUser “<SMTP Auth
User>” -SmtpAuthenticationUserPassword “<SMTP Auth User password>” -
ServiceAccountPassword “<Service Account Password>” -EnableMobileRestApi -
AzureCliVersion 2 -PlatformName “<Name of the Open edX Site>” -PlatformEmailAddress
“<PlatformEmailAddress>”
````

 ### 2. Prepare for Collecting Parameters
 You will do several steps to get tools, commandlets, and settings to collect your parameters.
 #### 2.1. Azure Subscription
 #### 2.2. Install Azure Command Line Interface
 #### 2.3. Install Azure PowerShell Cmdlets
 #### 2.4. Install Bash
 #### 2.5. Sync Configuration Files 
 #### 2.6. Get SSL Certificate and prepare for use in deployment
 ##### 2.6.1. Convert SSL Certificate to obtain public and private keys
 ````
    1. Export the private key:
    openssl pkcs12 -in [ PATH-TO-PFX ] -nocerts -out ~/key.pem -nodes
    2. Export the certificate:
    openssl pkcs12 -in [ PATH-TO-PFX ] -nokeys -out ~cert.crt
    3. Remove the passphrase from the private key:
    openssl rsa -in ~/key.pem -out ~/cert.key
    4. Copy the cert.crt and cert.key to the folder:
    [Enlistment Root]/oxa-tools/config/stamp/default
 ```` 
 ### 3. Modifying Deployment Scripts
 To prepare your cluster configuration, familiarize yourself with the LaaS architecture.
In this step, you’ll be modifying files that you downloaded from GitHub (example: c:/laas/oxatools/config/stamp/default).
#### 3.1 Determine deployment environment
You may choose to have multiple instances running, one for Production, another for Testing, and
another for Build-Verify-Test (bvt). For this documentation, the examples reference a bvt environment.
 #### 3.2. Name the deployment environment
 Navigate to the configuration files you downloaded (example: c:/laas/oxa-tools/config/stamp/default).
Keep bvt.sh file for now. Soon we will release updated document with guidance on maintaining different
environment files (for test, intermediate and production). Stay tuned. Make sure the bvt.sh file has unix
line endings.
#### 3.3. Generate SSH Keys
Private and Public SSH Keys are needed for access to JumpBox. We have provided sample keys.
However, you must create your own public and private SSH keys.
Navigate to the configuration files you downloaded (example: c:/laas/oxa-tools/config/stamp/default).
You will be replacing the SSH keys in the files id_rsa and id_rsa.pub. 
##### 3.3.1. Create SSH Keys
From Git Bash command prompt, run the following command
````
ssh-keygen -b 4096 -t rsa -f [Enlistment Root]/oxa-tools/config/stamp/default/id_rsa
````
Enter ‘y” in response to the overwrite prompt. Do not specify any passphrase for the keys.
Your files id_rsa and id_rsa.pub will be updated.
Run the following command to set the correct permissions on your SSH private key.
````
chmod 600 [Enlistment Root]/oxa-tools/config/stamp/default/id_rsa
````
The SSH private key is required to access the JumpBox. The Administrator identified in the deployment
script will also be the Administrator of JumpBox.
#### 3.4. Modify parameters.json file

Open parameters.json file. This file contains the LaaS configuration parameters; and each parameter is
defined in the file. You can choose to change parameters such as VM size. You must modify the
Administrator Public Key and the LMS and CMS domains.
##### 3.4.1. Confirm Azure Resources
You may want to change the SKU of the VMs to accommodate the cost and scale you’ve planned for this
deployment. In the parameters.json file, these are listed under “mongoVmSize”, “mysqlVmSize” and
“frontendVmSize” parameters. For more information on Azure Linux VM pricing, please visit
https://azure.microsoft.com/en-us/pricing/details/virtual-machines/linux/. 

##### 3.4.2. Modify Administrator Public Key
There are several default values in this file. It is very important to change “adminPublicKey” parameter.
Replace the content of “value” parameter with entire contents of id_rsa.pub file generated earlier.
````
"adminPublicKey": {
"value": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCj0GHnhX8L8cPtCFhNPTClvD
/b7Nm/eUIr/WYfYESlft1M1h25Lvu6QgFyqJlwdXSPCiIYbR6nK6WI2Zz6cA… == admin@contoso.com"
````
##### 3.4.3. Modify LMS and CMS Domains
Since you’ll have custom domains for your Learning Management System and Content Management
System, you need make few changes to two configuration files: parameters.json and bvt.sh.
For example, if you want to use the following custom domains for LMS, CMS and preview
* LMS URL – www.contosoacademy.com
* CMS URL – www.studio.contosoacademy.com
* Preview URL – www.preview.contosoacademy.com
be sure to get the SSL certificate from the certificate authority for base url of contosoacademy.com with
Subject alternate name for *.contosoacademy.com

From [Enlistment Root]\oxa-tools\config\stamp\default, open parameters.json file and look for
“baseDomain” property. Change the default value to “” 

````
"baseDomain": {
 "value": ""
}
````

This will enable the domain parameters to be specified from the bvt.sh file.
From [Enlistment Root]\oxa-tools\config\stamp\default, open bvt.sh file and change the following. 

````
BASE_URL=contosoacademy.com
LMS_URL=$BASE_URL
CMS_URL=studio.$BASE_URL
PREVIEW_URL=preview.$BASE_URL
````

##### 3.4.4. Change the cloud environment
Skip this step if you have not changed the cloud environment in step 3.2. If you changed the
environment type from step 3.2 to “prod” (If you keep bvt as your environment, skip this step), change
the cloud parameter value to “prod”

 ### 4. Deployment Parameters

 ### 5. Deployment
 
 ### 6. Post Deployment
 ### 7. FAQs
 