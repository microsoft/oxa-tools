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

.PARAMETER ResourceGroupName
Name of the azure resource group name

.PARAMETER ApplicationId
Azure AD Application Id to manage Service Principal

.PARAMETER KeyVaultName
Name of key vault to provide Service Principal access to

.PARAMETER CertSubject
Certificate subject to use when searching/creating certificate

.PARAMETER Cloud
Cloud to deploy to (prod, int, bvt). Determines certificate subject 
to search for/create in local cert store.

.INPUTS
None. You cannot pipe objects to Create-KeyVaultCertificate.ps1

.OUTPUTS
None

.EXAMPLE
.\scripts\Create-KeyVaultCertificate.ps1 -ApplicationId {APPLICATION_ID} -Cloud "bvt" -AzureSubscriptionName {SOME_SUBSCRIPTION} -ResourceGroupName {SOME_RESOURCE_GROUP}
#>

Param ( 
        [Parameter(Mandatory=$true)][String] $AzureSubscriptionName,        
        [Parameter(Mandatory=$true)][String] $ResourceGroupName,
        [Parameter(Mandatory=$true)][String] $ApplicationId,
        [Parameter(Mandatory=$false)][String] $KeyVaultName="",
        [Parameter(Mandatory=$false)][String] $CertSubject="",
        [Parameter(Mandatory=$false)][ValidateSet("prod", "int", "bvt")][string]$Cloud="bvt"
      )

#################################
# ENTRY POINT
#################################

$invocation = (Get-Variable MyInvocation).Value 
$currentPath = Split-Path $invocation.MyCommand.Path 
Import-Module "$($currentPath)/Common.ps1" -Force

Login-AzureRmAccount
Import-Module AzureRM.Resources

$SubscriptionId = Get-AzureRmSubscription -SubscriptionName $AzureSubscriptionName
$Scope = "/subscriptions/" + $SubscriptionId
Select-AzureRMSubscription -SubscriptionId $SubscriptionId
(Get-AzureRmContext).Subscription

$KeyVaultName = Set-ScriptDefault -ScriptParamName "KeyVaultName" `
                -ScriptParamVal $KeyVaultName `
                -DefaultValue "$($ResourceGroupName)-kv"

$CertSubject = Set-ScriptDefault -ScriptParamName "CertSubject" `
                -ScriptParamVal $CertSubject `
                -DefaultValue "CN=$($cloud)-cert"

# Get Self-Signed Certificate
try 
{
    $cert = (Get-ChildItem cert:\CurrentUser\my\ | Where-Object {$_.Subject -match $CertSubject })
    if (!$cert)
    {
        Log-Message "Creating new Self-Signed Certificate..."
        $cert = New-SelfSignedCertificate -CertStoreLocation "cert:\CurrentUser\My" -Subject $CertSubject -KeySpec KeyExchange
    }
    $certValue = [System.Convert]::ToBase64String($cert.GetRawCertData())    
}
catch
{
    Capture-ErrorStack;
    throw "Error obtaining certificate: $($_.Message)";
    exit;
}

# Replace Service Principal with a new account using the Certificate obtained above
try
{
    $sp = Get-AzureRmADServicePrincipal -ServicePrincipalName $ApplicationId
    
    if ($sp -and $sp.Id)
    {
        Log-Message "Removing old Service Principal..."
        Remove-AzureRmADServicePrincipal -ObjectId $sp.Id
    }    
    
    Log-Message "Creating new Service Principal for Key Vault Access to: $($KeyVaultName)"
    $ServicePrincipal = New-AzureRMADServicePrincipal -ApplicationId $ApplicationId -CertValue $certValue -EndDate $cert.NotAfter -StartDate $cert.NotBefore
    Get-AzureRmADServicePrincipal -ObjectId $ServicePrincipal.Id    
    
    # Sleep here for a few seconds to allow the service principal application to become active 
    # (should only take a couple of seconds normally)
    Sleep 15
    New-AzureRMRoleAssignment -RoleDefinitionName Contributor -ServicePrincipalName $ServicePrincipal.ApplicationId -Scope $Scope | Write-Verbose -ErrorAction Stop
}
catch
{
    Capture-ErrorStack;
    throw "Error in removing old service principal, creating new Service Principal and assigning role in provided subscription: $($_.Message)";
    exit;
}

# Allow new Service Principal KeyVault access
try
{
    Log-Message "Setting Key Vault Access policy for Key Vault: $($KeyVaultName) and Service Principal: $($sp.Id)"
    Set-AzureRmKeyVaultAccessPolicy -VaultName $KeyVaultName `
                                    -ServicePrincipalName $ApplicationId -PermissionsToSecrets get,set,list `
                                    -ResourceGroupName $ResourceGroupName    
}
catch
{
    Capture-ErrorStack;
    throw "Error adding access policy to allow new Service Principal to use Key Vault - $($KeyVaultName): $($_.Message)";
    exit;
}
