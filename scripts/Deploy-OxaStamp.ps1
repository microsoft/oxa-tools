<#
.SYNOPSIS
Deploy the OXA Stamp - Enterprise-Grade OpenEdx on Azure infrastructure that supports High Availability and Scalability

.DESCRIPTION
This script deploys the OXA Stamp. It supports a clean infrastructure bootstrap and incremental updates

This script assumes you have already have an AzureRM authenticated session

.PARAMETER AzureSubscriptionName
Name of the azure subscription to use

.PARAMETER ResourceGroupName
Name of the azure resource group name

.PARAMETER Location
Location of the resource group. See https://azure.microsoft.com/en-us/regions/ for details

.PARAMETER TargetPath
Directory path holding the secrets for populating keyvault. Only files in this directory will be uploaded as secrets. Recursion is not supported

.PARAMETER ConfigurationPrefix
Prefix prepended to the secret names for categorization purposes

.PARAMETER AadWebClientId
The azure active directory web application Id for authentication

.PARAMETER AadWebClientAppKey
The azure active directory web application key for authentication

.PARAMETER AadTenantId
The azure active directory tenant id for authentication

.PARAMETER KeyVaultUserObjectId
Object id of the user to be granted full keyvault access. If no value is specified, the service principal (AadWebClientId) object id will be used

.PARAMETER KeyVaultDeploymentArmTemplateFile
Path to the arm template for bootstrapping keyvault

.PARAMETER KeyVaultDeploymentParametersFile
Path to the deployment parameters file for the keyvault arm deployment

.PARAMETER ClusterAdministratorEmailAddress
E-mail address of the cluster administrator. Notification email during bootstrap will be sent here. OS notifications will also be sent to this address

.PARAMETER FullDeploymentArmTemplateFile
Path to the arm template for bootstrapping keyvault

.PARAMETER FullDeploymentArmTemplateFile
Path to the deployment parameters file for the keyvault arm deployment

.PARAMETER SmtpServer
SMTP Server to use for deployment and other notifications (it is assumed the server supports TLS)

.PARAMETER SmtpServerPort
SMTP Server port used for connection

.PARAMETER SmtpAuthenticationUser
SMTP Server user name to authenticate with

.PARAMETER SmtpAuthenticationUserPassword
Password for the SMTP Server user to authenticate with

.PARAMETER ServiceAccountPassword
Password to use for creating backend service accounts (Mysql, Mongo admin users)

.PARAMETER PlatformName
Name used to identify the application

.PARAMETER PlatformEmailAddress
Email address associated with the application

.PARAMETER AzureCliVersion
Version of Azure CLI to use

.PARAMETER MemcacheServer
IP Address of the Memcache Server the application servers will use. It is assumed Memcache is configured and is running on the default port of 11211

.PARAMETER DeploymentVersionId
A timestamp or other identifier to associate with the VMSS being deployed.

.PARAMETER EnableMobileRestApi
An switch to indicate whether or not mobile rest api is turned on

.INPUTS
None. You cannot pipe objects to Deploy-OxaStamp.ps1

.OUTPUTS
None

.EXAMPLE
.\Deploy-OxaStamp.ps1 -AzureSubscriptionName SomeSubscription -ResourceGroupName OxaMasterNode -Location "west us" -TargetPath "E:\env\bvt" -AadWebClientId "1178d667e54c" -AadWebClientAppKey "BDtkq10kdGxI6QgtyNI=" -AadTenantId "1db47" -KeyVaultDeploymentArmTemplateFile "E:\stampKeyVault.json" -KeyVaultDeploymentParametersFile "E:\env\bvt\parameters.json" -FullDeploymentParametersFile "E:\env\bvt\parameters.json" -FullDeploymentArmTemplateFile "E:\stamp-v2.json" -DeployKeyVault -DeployStamp:$false

#>
Param( 
        [Parameter(Mandatory=$true)][string]$AzureSubscriptionName,
        [Parameter(Mandatory=$true)][string]$ResourceGroupName,
        [Parameter(Mandatory=$true)][string]$Location,

        [Parameter(Mandatory=$true)][string]$TargetPath,
        [Parameter(Mandatory=$false)][string]$ConfigurationPrefix = "OxaToolsConfigxxx",
        [Parameter(Mandatory=$true)][string]$AadWebClientId,
        [Parameter(Mandatory=$true)][string]$AadWebClientAppKey,
        [Parameter(Mandatory=$true)][string]$AadTenantId,
        [Parameter(Mandatory=$false)][string]$KeyVaultUserObjectId="",

        [Parameter(Mandatory=$false)][string]$KeyVaultDeploymentArmTemplateFile="",
        [Parameter(Mandatory=$false)][string]$KeyVaultDeploymentParametersFile="",
        [Parameter(Mandatory=$false)][string]$FullDeploymentArmTemplateFile="",
        [Parameter(Mandatory=$false)][string]$FullDeploymentParametersFile="",

        [Parameter(Mandatory=$true)][string]$ClusterAdministratorEmailAddress,

        [Parameter(Mandatory=$false)][switch]$DeployKeyVault=$true,
        [Parameter(Mandatory=$false)][switch]$DeployStamp=$true,

        [Parameter(Mandatory=$false)][string]$SmtpServer="",
        [Parameter(Mandatory=$false)][string]$SmtpServerPort="",
        [Parameter(Mandatory=$false)][string]$SmtpAuthenticationUser="",
        [Parameter(Mandatory=$false)][string]$SmtpAuthenticationUserPassword="",

        [Parameter(Mandatory=$false)][string]$ServiceAccountPassword="5QFrMCIKJaVazBWisd0fMJR",

        [Parameter(Mandatory=$false)][string]$PlatformName="Contoso Learning",
        [Parameter(Mandatory=$false)][string]$PlatformEmailAddress="",

        [Parameter(Mandatory=$false)][string]$EdxAppSuperUserName="edxappadmin",
        [Parameter(Mandatory=$false)][string]$EdxAppSuperUserPassword="",
        [Parameter(Mandatory=$false)][string]$EdxAppSuperUserEmail="",

        [Parameter(Mandatory=$false)][string][ValidateSet("1","2")]$AzureCliVersion="1",
        [Parameter(Mandatory=$false)][string]$MemcacheServer="10.0.0.16",

        [Parameter(Mandatory=$false)][string]$DeploymentVersionId="",

        [Parameter(Mandatory=$false)][switch]$EnableMobileRestApi=$false
     )

#################################
# ENTRY POINT
#################################

$invocation = (Get-Variable MyInvocation).Value 
$currentPath = Split-Path $invocation.MyCommand.Path 
$rootPath = (get-item $currentPath).parent.FullName
Import-Module "$($currentPath)/Common.ps1" -Force

$FullDeploymentArmTemplateFile = Set-ScriptDefault -ScriptParamName "FullDeploymentArmTemplateFile" `
                                    -ScriptParamVal $FullDeploymentArmTemplateFile `
                                    -DefaultValue "$($rootPath)/templates/stamp/stamp-v2.json"
$FullDeploymentParametersFile = Set-ScriptDefault -ScriptParamName "FullDeploymentArmTemplateFile" `
                                    -ScriptParamVal $FullDeploymentParametersFile `
                                    -DefaultValue "$($rootPath)/config/stamp/default/parameters.json"
$KeyVaultDeploymentArmTemplateFile = Set-ScriptDefault -ScriptParamName "FullDeploymentArmTemplateFile" `
                                    -ScriptParamVal $KeyVaultDeploymentArmTemplateFile `
                                    -DefaultValue "$($rootPath)/templates/stamp/stamp-keyvault.json"
$KeyVaultDeploymentParametersFile = Set-ScriptDefault -ScriptParamName "FullDeploymentArmTemplateFile" `
                                    -ScriptParamVal $KeyVaultDeploymentParametersFile `
                                    -DefaultValue $FullDeploymentParametersFile

# Login
$clientSecret = ConvertTo-SecureString -String $AadWebClientAppKey -AsPlainText -Force
$aadCredential = New-Object System.Management.Automation.PSCredential($AadWebClientId, $clientSecret)
Login-AzureRmAccount -ServicePrincipal -TenantId $AadTenantId -SubscriptionName $AzureSubscriptionName -Credential $aadCredential -ErrorAction Stop
Set-AzureSubscription -SubscriptionName $AzureSubscriptionName | Out-Null

# create the resource group
New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location -Force

######################################################
# Setup parameters for dynamic arm template creation
######################################################

# todo: move this to a supporting function 
# Set default value for the Platform Email address
if (!$PlatformEmailAddress)
{
    Log-Message "Falling back to '$ClusterAdministratorEmailAddress' since a platform email address was not specified."
    $PlatformEmailAddress = $ClusterAdministratorEmailAddress
}

# Set defaults for Edx Super User (if necessary)
if (!$EdxAppSuperUserPassword)
{
    Log-Message "Falling back to '$ServiceAccountPassword' since a password for the Edx App Super User was was not specified."
    $EdxAppSuperUserPassword = $ServiceAccountPassword
}

if (!$EdxAppSuperUserEmail)
{
    Log-Message "Falling back to '$ClusterAdministratorEmailAddress' since a password for the Edx App Super User Email was was not specified."
    $EdxAppSuperUserEmail = $ClusterAdministratorEmailAddress
}

# Add the user for keyvault access
if (!$KeyVaultUserObjectId)
{
    Log-Message "Falling back to service principal '$AadWebClientId' to derive the keyvault admin user object Id since it was not specified."
    $principal = Get-AzureRMADServicePrincipal -ServicePrincipalName $AadWebClientId
    $KeyVaultUserObjectId = $principal.Id
}

# check for the DeploymentVersionId
if ($DeploymentVersionId -eq "")
{
    $DeploymentVersionId=$(get-date -f "yyyyMMddHms")
}

# Prep the variables we want to use for replacement
$replacements = @{ 
                    "CLUSTERNAME"=$ResourceGroupName;  
                    "ADMINEMAILADDRESS"=$ClusterAdministratorEmailAddress; 
                    "AADWEBCLIENTID"=$AadWebClientId; 
                    "AADWEBCLIENTAPPKEY"=$AadWebClientAppKey; 
                    "AADTENANTID"=$AadTenantId;
                    "SERVICEACCOUNTPASSWORD"=$ServiceAccountPassword;
                    "EDXAPPPLATFORMNAME"=$PlatformName;
                    "EDXAPPPLATFORMEMAIL"=$PlatformEmailAddress;
                    "KEYVAULTUSEROBJECTID"=$KeyVaultUserObjectId;
                    "EDXAPPSUPERUSERNAME"=$EdxAppSuperUserName;
                    "EDXAPPSUPERUSERPASSWORD"=$EdxAppSuperUserPassword;
                    "EDXAPPSUPERUSEREMAIL"=$EdxAppSuperUserEmail;
                    "MEMCACHESERVER"=$MemcacheServer;
                    "AZURECLIVERSION"=$AzureCliVersion;
                    "DEPLOYMENTVERSIONID"=$DeploymentVersionId
                }

# Assumption: if the SMTP server is specified, the rest of its configuration will be specified
if ($smtpServer)
{
    $replacements["SMTPSERVER"]=$smtpServer
    $replacements["SMTPSERVERPORT"]=$smtpServerPort
    $replacements["SMTPAUTHENTICATIONUSER"]=$smtpAuthenticationUser
    $replacements["SMTPAUTHENTICATIONUSERPASSWORD"]=$smtpAuthenticationUserPassword
}

# Enabling Mobile API
$replacements["ENABLEMOBILERESTAPI"]="false"
if ($EnableMobileRestApi -eq $true)
{
    $replacements["ENABLEMOBILERESTAPI"]="true"
}

# Update the deployment parameters
$tempParametersFile = Update-RuntimeParameters -ParametersFile $KeyVaultDeploymentParametersFile -ReplacementHash $replacements;

try
{
    if ($DeployKeyVault)
    {
        # provision the keyvault
        # we may need to replace the default resource group name in the parameters file
        Log-Message "Cluster: $ResourceGroupName | Template: $KeyVaultDeploymentArmTemplateFile | Parameters file: $($tempParametersFile)"
        $provisioningOperation = New-AzureRmResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateFile $KeyVaultDeploymentArmTemplateFile -TemplateParameterFile $tempParametersFile -Force -Verbose  
    
        if ($provisioningOperation.ProvisioningState -ine "Succeeded")
        {
            $provisioningOperation
            throw "Unable to provision the resource group $($ResourceGroupName)"
        }

        # pre-populate the keyvault
        $scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
        $separator = Get-DirectorySeparator
        Log-Message "Populating keyvault using script at $($scriptPath)$($separator)Process-OxaToolsKeyVaultConfiguration.ps1"
        &"$($scriptPath)$($separator)Process-OxaToolsKeyVaultConfiguration.ps1" -Operation Upload -VaultName "$($ResourceGroupName)-kv" -AadWebClientId $AadWebClientId -AadWebClientAppKey $AadWebClientAppKey -AadTenantId $AadTenantId -AzureSubscriptionId $AzureSubscriptionName -TargetPath $TargetPath -AzureCliVersion $AzureCliVersion
    }

    if ($DeployStamp)
    {
        # kick off full deployment
        # we may need to replace the default resource group name in the parameters file
        New-AzureRmResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateFile $FullDeploymentArmTemplateFile -TemplateParameterFile $tempParametersFile -Force -Verbose  
    }
}
catch
{
    Log-Message $_.Exception.Message
    throw
}
finally
{
    Log-Message "Cleaning up temporary parameter file"
    Remove-Item -Path $tempParametersFile;
}