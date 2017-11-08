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

.PARAMETER StorageContainerNames
Name(s) of the storage container(s) to create. Use a comma-separated list to specify multiple containers

.PARAMETER PublicStorageContainerNames
Name(s) of the storage container(s) to create. Use a comma-separated list to specify multiple containers

.PARAMETER AzureCliVersion
Version of Azure CLI to use

.PARAMETER AzureStorageConnectionString
Azure storage connection string (in support of custom storage endpoints)

.INPUTS
None. You cannot pipe objects to Create-StorageContainer.ps1

.OUTPUTS
None

.EXAMPLE
To create the 'uploads' storage container:
.\Create-StorageContainer.ps1 -AadWebClientId 121 -AadWebClientAppKey key -AadTenantId 345 -AzureSubscriptionId 438484 -StorageAccountName djdjd -StorageContainerName uploads

#>
Param( 
        [Parameter(Mandatory=$false)][string]$AadWebClientId,
        [Parameter(Mandatory=$false)][string]$AadWebClientAppKey,
        [Parameter(Mandatory=$false)][string]$AadTenantId,
        [Parameter(Mandatory=$false)][string]$AzureSubscriptionId,
        [Parameter(Mandatory=$true)][string]$StorageAccountName,
        [Parameter(Mandatory=$true)][string]$StorageAccountKey,
        [Parameter(Mandatory=$true)][string]$StorageContainerNames,
        [Parameter(Mandatory=$true)][string]$PublicStorageContainerNames,
        [Parameter(Mandatory=$false)][string][ValidateSet("1","2")]$AzureCliVersion="2",
        [Parameter(Mandatory=$false)][string]$AzureStorageConnectionString=""
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

#todo: re-enable after tests

#$invocation = (Get-Variable MyInvocation).Value 
#$currentPath = Split-Path $invocation.MyCommand.Path 
Import-Module "$($currentPath)/Common.ps1" -Force

# Login First & set context
#Authenticate-AzureRmUser -AadWebClientId $AadWebClientId -AadWebClientAppKey $AadWebClientAppKey -AadTenantId $AadTenantId;
#Set-AzureSubscriptionContext -AzureSubscriptionId $AzureSubscriptionId

New-Containers -ContainerNames $StorageContainerNames

Set-ContainersPermissions -ContainerNames $PublicStorageContainerNames -AccessPolicy "blob"

#todo: move above entry point
function New-Containers
{
    param(
            [Parameter(Mandatory=$true)][string]$ContainerNames
         )
    # Create the container
    [array]$storageContainerList = $ContainerNames.Split(",");

    foreach($storageContainerName in $storageContainerList)
    {
        # todo: add retries for better resiliency
        Log-Message "Creating Storage Container (Cli: $AzureCliVersion): $($storageContainerName)" -Context "Create Storage Containers"

        # Check if container already exists
        $status = Get-ContainerExists -Container $storageContainerName

        if (!$status)
        {
            # todo: fall back to azure cli since there are existing issues with installation of azure powershell cmdlets for linux
            # cli doesn't provide clean object returns (json responses are helpful). Therefore, transition as soon as possible
            if ($AzureCliVersion -eq "1" )
            {
                # Azure Cli 1.0

                # create the container now
                $response = azure storage container create --account-name $StorageAccountName --account-key $StorageAccountKey --container $storageContainerName --json
                $status = ((($response | jq --raw-output '.name') -ieq $storageContainerName) -and (($response | jq --raw-output '.lease.state') -ieq 'available'))
            }
            else 
            {
                # Azure Cli 2.0

                # create the container now
                if ($AzureStorageConnectionString)
                {
                    Log-Message "Using connection string: $AzureStorageConnectionString" -Context "Create Storage Containers" -NoNewLine
        
                    $response = az storage container create --account-name $StorageAccountName --account-key $StorageAccountKey --name $storageContainerName --connection-string $AzureStorageConnectionString -o json
                }
                else 
                {
                    $response = az storage container create --account-name $StorageAccountName --account-key $StorageAccountKey --name $storageContainerName -o json
                }

                # parse the status (.created=true is the expected status)
                $status = (($response | jq --raw-output '.created') -ieq "true")
            }
        }

        # we expect the following: true=container created, If there is an error, status=[Blank]
        if (!$status)
        {
            # creation failed
            Log-Message "Unable to create the specified storage container: $storageContainerName" -Context "Create Storage Containers"
            exit 1
        }
    }
}

function Get-ContainerExists
{
    param(
            [Parameter(Mandatory=$true)][string]$ContainerName
         )

    # Check if the container exists
    $status=$false
    $response=""

    # todo: fall back to azure cli since there are existing issues with installation of azure powershell cmdlets for linux
    # cli doesn't provide clean object returns (json responses are helpful). Therefore, transition as soon as possible
    if ($AzureCliVersion -eq "1" )
    {
        # Azure Cli 1.0
        $response = azure storage container list --account-name $StorageAccountName --account-key $StorageAccountKey --prefix $storageContainerName --json
    }
    else 
    {
        # Azure Cli 2.0
        if ($AzureStorageConnectionString)
        {
            $response = az storage container list --account-name $StorageAccountName --account-key $StorageAccountKey --prefix $storageContainerName --connection-string $AzureStorageConnectionString -o json
        }
        else 
        {
            $response = az storage container list --account-name $StorageAccountName --account-key $StorageAccountKey --prefix $storageContainerName -o json
        }
    }

    $status = (-Not ( ($response | jq --raw-output ".[] | select(.name==\`"$storageContainerName\`") | .name") -ine $storageContainerName) )
    if ($status)
    {
        Log-Message "'$storageContainerName' already exists."
    }
    else
    {
        Log-Message "'$storageContainerName' doesn't exist."
    }

    return $status
}

function Set-ContainersPermissions
{
    param(
            [Parameter(Mandatory=$true)][string]$ContainerNames,
            [Parameter(Mandatory=$true)][ValidateSet("off","blob","container")][string]$AccessPolicy
         )

    # Update the container permissions (create if missing)
    [array]$storageContainerList = $ContainerNames.Split(",");

    foreach($storageContainerName in $storageContainerList)
    {
        Log-Message "Creating Storage Container (Cli: $AzureCliVersion): $($storageContainerName)" -Context "Create Storage Containers"

        # Check if container already exists
        $status = Get-ContainerExists -ContainerName $storageContainerName

        if (!$status)
        {
            # Create if missing
            New-Containers -ContainerNames storageContainerName
        }
    
        # todo: update status

        # Update the container permissions
        # todo: fall back to azure cli since there are existing issues with installation of azure powershell cmdlets for linux
        # cli doesn't provide clean object returns (json responses are helpful). Therefore, transition as soon as possible
        if ($AzureCliVersion -eq "1" )
        {
            # Azure Cli 1.0

            $response = azure storage container set-permission --account-name $StorageAccountName --account-key $StorageAccountKey --container $storageContainerName --public-access $AccessPolicy --json
        }
        else 
        {
            # Azure Cli 2.0

                # Update the container permissions
                if ($AzureStorageConnectionString)
                {
                    Log-Message "Using connection string: $AzureStorageConnectionString" -Context "Create Storage Containers" -NoNewLine
        
                    $response = az storage container set-permission --account-name $StorageAccountName --account-key $StorageAccountKey --name $storageContainerName --public-access $AccessPolicy --connection-string $AzureStorageConnectionString -o json
                }
                else
                {
                    $response = az storage container set-permission --account-name $StorageAccountName --account-key $StorageAccountKey --name $storageContainerName --public-access $AccessPolicy -o json
                }
        }

        # we expect the following: true=container created, If there is an error, status=[Blank]
        if (!$status)
        {
            # creation failed
            Log-Message "Unable to create the specified storage container: $storageContainerName" -Context "Create Storage Containers"
            exit 1
        }
    }
}
