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

        [Parameter(Mandatory=$true)][string]$KeyVaultDeploymentArmTemplateFile,
        [Parameter(Mandatory=$false)][string]$KeyVaultDeploymentParametersFile="",
        [Parameter(Mandatory=$true)][string]$FullDeploymentArmTemplateFile,
        [Parameter(Mandatory=$true)][string]$FullDeploymentParametersFile,

        [Parameter(Mandatory=$true)][string]$ClusterAdministratorEmailAddress,

        [Parameter(Mandatory=$false)][switch]$DeployKeyVault=$true,
        [Parameter(Mandatory=$false)][switch]$DeployStamp=$true
     )

#################################
# ENTRY POINT
#################################

$invocation = (Get-Variable MyInvocation).Value 
$currentPath = Split-Path $invocation.MyCommand.Path 
Import-Module "$($currentPath)/Common.ps1" -Force

# set the default keyvault parameter file (if one isn't specified)
if ($KeyVaultDeploymentParametersFile.Trim().Length -eq 0)
{
    Log-Message "Setting KeyVaultDeploymentParametersFile to FullDeploymentParametersFile"
    $KeyVaultDeploymentParametersFile = $FullDeploymentParametersFile;
}

# Login
$clientSecret = ConvertTo-SecureString -String $AadWebClientAppKey -AsPlainText -Force
$aadCredential = New-Object System.Management.Automation.PSCredential($AadWebClientId, $clientSecret)
Login-AzureRmAccount -ServicePrincipal -TenantId $AadTenantId -SubscriptionName $AzureSubscriptionName -Credential $aadCredential -ErrorAction Stop
Set-AzureSubscription -SubscriptionName $AzureSubscriptionName | Out-Null

# create the resource group
New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location -Force

#prep the variables we want to use for replacement
$replacements = @{ "CLUSTERNAME"=$ResourceGroupName;  "ADMINEMAILADDRESS"=$ClusterAdministratorEmailAddress; }
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
        &"$($scriptPath)$($separator)Process-OxaToolsKeyVaultConfiguration.ps1" -Operation Upload -VaultName "$($ResourceGroupName)-kv" -AadWebClientId $AadWebClientId -AadWebClientAppKey $AadWebClientAppKey -AadTenantId $AadTenantId -AzureSubscriptionId $AzureSubscriptionName -TargetPath $TargetPath
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