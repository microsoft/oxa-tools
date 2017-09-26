<#
.SYNOPSIS
Uploads secrets from a json file to Keyvault

.DESCRIPTION
Assumes a valid certificate exists to login to Azure with.
Takes key-value pairs from a json file and uploads them to Keyvault

.PARAMETER AzureSubscriptionName
Name of the azure subscription to use

.PARAMETER TargetPath
Full path to json file with secrets

.PARAMETER AadWebClientId
Azure AD Application Id to manage Service Principal

.PARAMETER AadTenantId
Azure AD Tenant

.PARAMETER KeyVaultName
Name of key vault to provide Service Principal access to

.PARAMETER CertSubject
Certificate subject to use when searching/creating certificate

.PARAMETER Cloud
Cloud to deploy to (prod, int, bvt). Determines certificate subject 
to search for/create in local cert store.

.INPUTS
None. You cannot pipe objects to Set-KeyVaultSecretsFromFile.ps1

.OUTPUTS
None

.EXAMPLE
.\scripts\Create-KeyVaultCertificate.ps1 -ApplicationId {APPLICATION_ID} -Cloud "bvt" -AzureSubscriptionName {SOME_SUBSCRIPTION} -ResourceGroupName {SOME_RESOURCE_GROUP}
#>

Param (
    [Parameter(Mandatory=$false)][String]$TargetPath="",
    [Parameter(Mandatory=$false)][string]$AzureSubscriptionName,    
    [Parameter(Mandatory=$true)][string]$AadWebClientId,    
    [Parameter(Mandatory=$true)][string]$AadTenantId,
    [Parameter(Mandatory=$false)][string]$KeyVaultName,    
    [Parameter(Mandatory=$false)][ValidateSet("CN=prod-cert", "CN=int-cert", "CN=bvt-cert")][string]$CertSubject = "CN=bvt-cert",
    [Parameter(Mandatory=$false)][ValidateSet("prod", "int", "bvt", "")][string]$Cloud="bvt"
)

$invocation = (Get-Variable MyInvocation).Value 
$currentPath = Split-Path $invocation.MyCommand.Path
$rootPath = (Get-Item $currentPath).parent.FullName
Import-Module "$($currentPath)/Common.ps1" -Force

Log-Message "Setting AzureSubscriptionName and ResourceGroupName from Cloud..."
switch ($Cloud) {
    "prod" {
        $AzureSubscriptionName = "OXAPRODENVIRONMENT"
        $ResourceGroupName = "lexoxabvtc13"    
    }
    "int" {
        $AzureSubscriptionName = "OXAINTENVIRONMENT"
        $ResourceGroupName = "lexoxabvtc13"
    }
    "bvt" {
        $AzureSubscriptionName = "OXABVTENVIRONMENT"
        $ResourceGroupName = "lexoxabvtc14"        
    }
}

Log-Message "AzureSubscriptionName => $($AzureSubscriptionName)"
Log-Message "ResourceGroupName => $($ResourceGroupName)"

$KeyVaultName = Set-ScriptDefault -ScriptParamName "KeyVaultName" `
    -ScriptParamVal $KeyVaultName `
    -DefaultValue "$($ResourceGroupName)-kv"

$CertSubject = Set-ScriptDefault -ScriptParamName "CertSubject" `
    -ScriptParamVal $CertSubject `
    -DefaultValue "CN=$($Cloud)-cert"

$TargetPath = Set-ScriptDefault -ScriptParamName "TargetPath" `
    -ScriptParamVal $TargetPath `
    -DefaultValue "$($rootPath)/config/keyvault-params.json"

# Login
$CertificateThumbprint = Get-LocalCertificate -CertSubject $CertSubject
Login-AzureRmAccount -ServicePrincipal -CertificateThumbprint $CertificateThumbprint -ApplicationId $AadWebClientId -TenantId $AadTenantId
Set-AzureSubscription -SubscriptionName $AzureSubscriptionName | Out-Null

$json = Get-Content -Raw $TargetPath | Out-String | ConvertFrom-Json

$json.psobject.properties | ForEach-Object { 
    # Create a new secret
    $secretvalue = ConvertTo-SecureString $_.Value -AsPlainText -Force

    Log-Message "Syncing $($_.Name) to KeyVault: $($KeyVaultName)"

    try
    {
        # Store the secret in Azure Key Vault
        Set-AzureKeyVaultSecret -VaultName $KeyVaultName -Name $_.Name -SecretValue $secretvalue
    }
    catch
    {
        Log-Message "Error Syncing Key: $($_.Name)"
        Capture-ErrorStack;
        throw $($_.Message)
    }
}