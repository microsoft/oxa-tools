<#
.SYNOPSIS
This script retrieves access key for the specified storage account.

.DESCRIPTION
This script retrieves access key for the specified storage account.

.PARAMETER AadWebClientId
The azure active directory web application client id for authentication

.PARAMETER AadWebClientAppKey
The azure active directory web application key for authentication

.PARAMETER AadTenantId
The azure active directory tenant id for authentication

.PARAMETER AzureSubscriptionId
The Id of the Azure subscription

.PARAMETER StorageAccountName
The name of the storage account for key retrieval

.PARAMETER ResourceGroupName
The name of the resource group containing the storage account for key retrieval

.PARAMETER OutputFile
The output file where the key value will be written

.PARAMETER AzureCliVersion
Version of Azure CLI to use

.INPUTS
None. You cannot pipe objects to Get-StorageAccountKey.ps1

.OUTPUTS
None

.EXAMPLE
Get the storage account key for zzz account
.\Get-StorageAccountKey.ps1 -AadWebClientId 121 -AadWebClientAppKey key -AadTenantId 345 -AzureSubscriptionId 438484 -StorageAccountName zzz -ResourceGroupName MyGroup -OutputFile e:\key.txt

#>
Param( 
        [Parameter(Mandatory=$true)][string]$AadWebClientId,
        [Parameter(Mandatory=$true)][string]$AadWebClientAppKey,
        [Parameter(Mandatory=$true)][string]$AadTenantId,
        [Parameter(Mandatory=$true)][string]$AzureSubscriptionId,
        [Parameter(Mandatory=$true)][string]$StorageAccountName,
        [Parameter(Mandatory=$true)][string]$ResourceGroupName,
        [Parameter(Mandatory=$true)][string]$OutputFile,
        [Parameter(Mandatory=$false)][string][ValidateSet("1","2")]$AzureCliVersion="1"
     )

###########################################
#
# Error Trapper
# Gracefully handle all errors here
#
###########################################

trap [Exception]
{
    Log-Message -Message $_

    Capture-ErrorStack -ForceStop

    # we expect a calling script to be listening to what we are doing here. 
    # therefore, we will throw a fit here as a signal to them.
    # this should trigger and catch and resume
    throw "Script execution failed: $($_)"
}

#########################
#
# ENTRY POINT
#
#########################

$invocation = (Get-Variable MyInvocation).Value 
$currentPath = Split-Path $invocation.MyCommand.Path 
Import-Module "$($currentPath)/Common.ps1" -Force

# track version of cli to use
[bool]$isCli2 = ($AzureCliVersion -eq "2")

# Login First & set context
Authenticate-AzureRmUser -AadWebClientId $AadWebClientId -AadWebClientAppKey $AadWebClientAppKey -AadTenantId $AadTenantId -IsCli2 $isCli2
Set-AzureSubscriptionContext -AzureSubscriptionId $AzureSubscriptionId -IsCli2 $isCli2 

Log-Message -Message "Fetching storage account keys for '$($storageAccountName)' within '$($resourceGroupName)' resource group"
if ($isCli2)
{
    $response = az storage account keys list --account-name $storageAccountName --resource-group $resourceGroupName --output json  | Out-String
}
else
{
    $response = azure storage account keys list --json --resource-group $resourceGroupName --subscription $AzureSubscriptionId $storageAccountName  | Out-String
}

if ($response.Length -gt 0)
{
    $accountKeys = @()
    $accountKeys = Parse-Json -jsonString $response
    $key = $accountKeys | select -First 1

    Log-Message -Message "Writing the key to $($OutputFile)"
    $key.value | Out-File $OutputFile -Encoding ascii
}
else
{
    throw "No response received or an error was encountered"
}
