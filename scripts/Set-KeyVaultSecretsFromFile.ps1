<#
.SYNOPSIS
Create a new Self-Signed Certificate in the local store with a corresponding Service Principal to access KeyVault

.DESCRIPTION
This script will create a self-signed certificate and Service Principal account. 
It will assign the Service Principal to a Contributor role and create a new KeyVault 
access policy for the Service Principal

NOTE: REQUIRES MANUAL INVOCATION AND SUPERVISION

.PARAMETER AzureSubscriptionName
Name of the azure subscription to use

.INPUTS
None. You cannot pipe objects to Set-KeyVaultSecretsFromFile.ps1

.OUTPUTS
None

.EXAMPLE
.\scripts\Create-KeyVaultCertificate.ps1 -ApplicationId {APPLICATION_ID} -Cloud "bvt" -AzureSubscriptionName {SOME_SUBSCRIPTION} -ResourceGroupName {SOME_RESOURCE_GROUP}
#>

Param (        
    [Parameter(Mandatory=$false)][String] $TargetPath=""
)

$invocation = (Get-Variable MyInvocation).Value 
$currentPath = Split-Path $invocation.MyCommand.Path
$rootPath = (Get-Item $currentPath).parent.FullName
Import-Module "$($currentPath)/Common.ps1" -Force

$TargetPath = Set-ScriptDefault -ScriptParamName "TargetPath" `
                                -ScriptParamVal $TargetPath `
                                -DefaultValue "$($rootPath)/config/keyvault-params.json"

$json = Get-Content -Raw $TargetFile | Out-String | ConvertFrom-Json

$json.psobject.properties | ForEach-Object { 
    # Create a new secret
    $secretvalue = ConvertTo-SecureString $_.Value -AsPlainText -Force

    # Store the secret in Azure Key Vault
    Set-AzureKeyVaultSecret -VaultName $keyVaultName -Name $_.Name -SecretValue $secretvalue
    
    Write-Host $_.Name
}