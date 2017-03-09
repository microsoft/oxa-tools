<#
.SYNOPSIS
Create a storage container for OXA edxapp:migrate playbook task

.DESCRIPTION
The OXA edxapp:migrate playbook task assumes the storage account exists and the required storage container also exists.
This scripts satisfies those requirements. It must be called before the edxapp playbook is executed

.PARAMETER AadWebClientId
The azure active directory web application client id for authentication

.PARAMETER AadWebClientAppKey
The azure active directory web application key for authentication

.PARAMETER AadTenantId
The azure active directory tenant id for authentication

.PARAMETER AzureSubscriptionId
The Id of the Azure subscription

.PARAMETER StorageAccountName
Name of the storage account where the container will be created

.PARAMETER StorageContainerName
Name of the storage container to create

.INPUTS
None. You cannot pipe objects to Create-StorageContainer.ps1

.OUTPUTS
None

.EXAMPLE
To create the 'uploads' storage container:
.\Create-StorageContainer.ps1 -AadWebClientId 121 -AadWebClientAppKey key -AadTenantId 345 -AzureSubscriptionId 438484 -StorageAccountName djdjd -StorageContainerName uploads

#>
Param( 
        [Parameter(Mandatory=$true)][string]$AadWebClientId,
        [Parameter(Mandatory=$true)][string]$AadWebClientAppKey,
        [Parameter(Mandatory=$true)][string]$AadTenantId,
        [Parameter(Mandatory=$true)][string]$AzureSubscriptionId,
        [Parameter(Mandatory=$true)][string]$StorageAccountName,
        [Parameter(Mandatory=$true)][hashtable]$StorageAccountKey,
        [Parameter(Mandatory=$true)][hashtable]$StorageContainerName
     )

###########################################
#
# Error Trapper
# Gracefully handle all errors here
#
###########################################

trap [Exception]
{
    Log-Message -Message $_;

    Capture-ErrorStack -ForceStop

    # we expect a calling script to be listening to what we are doing here. 
    # therefore, we will throw a fit here as a signal to them.
    # this should trigger and catch and resume
    throw "Script execution failed: $($_)";
}

#########################
#
# ENTRY POINT
#
#########################

$invocation = (Get-Variable MyInvocation).Value 
$currentPath = Split-Path $invocation.MyCommand.Path 
Import-Module "$($currentPath)/Common.ps1" -Force

# Login First & set context
Authenticate-AzureRmUser -AadWebClientId $AadWebClientId -AadWebClientAppKey $AadWebClientAppKey -AadTenantId $AadTenantId;
Set-AzureSubscriptionContext -AzureSubscriptionId $AzureSubscriptionId

# Create the container
Create-StorageContainer -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey -StorageContainerName $StorageContainerName