<#
.SYNOPSIS
Handle automatic, continuous deployments for OXA Stamp environments

#>

Param(    
    [Parameter(Mandatory=$true)][string]$AadWebClientId,
    [Parameter(Mandatory=$true)][string]$AadWebClientAppKey,
    [Parameter(Mandatory=$true)][string]$AadTenantId,

    [Parameter(Mandatory=$false)][string]$AzureSubscriptionName,
    [Parameter(Mandatory=$false)][string]$ResourceGroupName,
    [Parameter(Mandatory=$false)][string]$Location="south central us",

    [Parameter(Mandatory=$false)][string]$BranchName="oxa/devfic",
    [Parameter(Mandatory=$false)][ValidateSet("bootstrap", "upgrade", "swap")][string]$DeploymentType="upgrade",    
    [Parameter(Mandatory=$false)][ValidateSet("prod", "int", "bvt")][string]$Cloud="bvt"
)

$invocation = (Get-Variable MyInvocation).Value 
$currentPath = Split-Path $invocation.MyCommand.Path 
Import-Module "$($currentPath)/Common.ps1" -Force

# Login
$clientSecret = ConvertTo-SecureString -String $AadWebClientAppKey -AsPlainText -Force
$aadCredential = New-Object System.Management.Automation.PSCredential($AadWebClientId, $clientSecret)
Login-AzureRmAccount #-ServicePrincipal -TenantId $AadTenantId -SubscriptionName $AzureSubscriptionName -Credential $aadCredential -ErrorAction Stop
Set-AzureSubscription -SubscriptionName $AzureSubscriptionName | Out-Null

# # Make the Key Vault provider is available
# Register-AzureRmResourceProvider -ProviderNamespace Microsoft.KeyVault

# # # create the resource group
# New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location -Force

# The name of the Azure subscription to install the Key Vault into
$subscriptionName = 'OXABVTENVIRONMENT'

# The resource group that will contain the Key Vault to create to contain the Key Vault
$resourceGroupName = 'lexoxabvtc13'

# The name of the Key Vault to install
$keyVaultName = 'BVTKeyVault'

# The Azure data center to install the Key Vault to
$location = 'southcentralus'

# # These are the Azure AD users that will have admin permissions to the Key Vault
# $keyVaultAdminUsers = @('Kabir Khan')


# # # Create the Key Vault (enabling it for Disk Encryption, Deployment and Template Deployment)
# New-AzureRmKeyVault -VaultName $keyVaultName -ResourceGroupName $resourceGroupName -Location $location `
#     -EnabledForDiskEncryption -EnabledForDeployment -EnabledForTemplateDeployment

# # # # Add the Administrator policies to the Key Vault
# foreach ($keyVaultAdminUser in $keyVaultAdminUsers) {
#     $UserObjectId = (Get-AzureRmADUser -SearchString $keyVaultAdminUser).Id
#     Set-AzureRmKeyVaultAccessPolicy -VaultName $keyVaultName -ResourceGroupName $resourceGroupName -ObjectId $UserObjectId `
#         -PermissionsToKeys all -PermissionsToSecrets all -PermissionsToCertificates all
# }

# $json = Get-Content -Raw "$($currentPath)/params.json" | Out-String | ConvertFrom-Json

# $json.psobject.properties | ForEach-Object { 
#     # Create a new secret
#     $secretvalue = ConvertTo-SecureString $_.Value -AsPlainText -Force

#     # Store the secret in Azure Key Vault
#     Set-AzureKeyVaultSecret -VaultName $keyVaultName -Name $_.Name -SecretValue $secretvalue
    
#     Write-Host $_.Name
# }

# $json.psobject.properties | ForEach-Object { 
#     # Get the secret text
#     $secretVal = Get-AzureKeyVaultSecret -VaultName $keyVaultName -Name $_.Name
#     # Write-Host 'Secret is: ' $secretVal.SecretValueText

# }

$keyVaultKeys = @(
    "ClusterAdministratorEmailAddress",
    "SmtpServer",
    "SmtpServerPort",
    "SmtpAuthenticationUser",
    "SmtpAuthenticationUserPassword",
    "EdxAppSuperUserName",
    "EdxAppSuperUserPassword",
    "EdxAppSuperUserEmail",
    "PlatformName",
    "PlatformEmailAddress"
)

$DeployScriptPath = "$($currentPath)/Deploy-OxaStamp.ps1"
$DeployScriptParams = @{}

foreach ($key in $keyVaultKeys)
{
    $secretVal = Get-AzureKeyVaultSecret -VaultName $keyVaultName -Name $key
    $DeployScriptParams[$key] = $secretVal.SecretValueText
}

Write-Host $DeployScriptPath
Write-Host @DeployScriptParams

& $DeployScriptPath @PSBoundParameters @DeployScriptParams