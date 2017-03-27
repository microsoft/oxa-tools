<#
.SYNOPSIS
Process OXA Tools Configuration Keyvault transactions (Upload, Download, List and Delete)

.DESCRIPTION
This script provides options for uploading new or updating existing OXA tools configurations to an 
existing Azure KeyVault instance. It also provides options for listing, downloading and saving to file 
(Hydrate from Keyvault) as well as deleting all secrets.

.PARAMETER Operation
Operation mode: Download, Upload, Purge or List Keyvault Secrets

.PARAMETER TargetPath
Filesystem path where settings will be read from or saved to

.PARAMETER VaultName
Name of the Azure KeyVault instance to interact with

.PARAMETER ConfigurationPrefix
Prefix to prepend the secret name

.PARAMETER AadWebClientId
The azure active directory web application client id for authentication

.PARAMETER AadWebClientAppKey
The azure active directory web application key for authentication

.PARAMETER AadTenantId
The azure active directory tenant id for authentication

.PARAMETER AzureSubscriptionId
The Id of the Azure subscription

.PARAMETER AzureCliVersion
Version of Azure CLI to use

.INPUTS
None. You cannot pipe objects to Process-OxaToolsKeyVaultConfiguration.ps1

.OUTPUTS
None

.EXAMPLE
To download all existing key vault secrets related to Oxa Tools configuration
.\Process-OxaToolsKeyVaultConfiguration.ps1 -Operation Download -TargetPath c:\bvt -VaultName MyVault -AadWebClientId 121 -AadWebClientAppKey key -AadTenantId 345 -AzureSubscriptionId 438484

#>
Param( 
        [Parameter(Mandatory=$true)][ValidateSet("Download","Upload", "Purge", "List")][string]$Operation ,
        [Parameter(Mandatory=$false)][string]$TargetPath,
        [Parameter(Mandatory=$true)][string]$VaultName,
        [Parameter(Mandatory=$false)][string]$ConfigurationPrefix = "OxaToolsConfigxxx",
        [Parameter(Mandatory=$true)][string]$AadWebClientId,
        [Parameter(Mandatory=$true)][string]$AadWebClientAppKey,
        [Parameter(Mandatory=$true)][string]$AadTenantId,
        [Parameter(Mandatory=$true)][string]$AzureSubscriptionId,
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

# Get the directory separator
$directorySeparator = Get-DirectorySeparator

# Upload
if ($Operation -ieq "Upload")
{
    Log-Message "Uploading secrets" -Context "Secrets $($Operation)"

    # check for target path
    if ($TargetPath.Trim().Length -eq 0)
    {
        throw "A target path must be specified for uploading secrets"
    }

    # check if the target path exists
    if ((Test-Path -Path $TargetPath) -eq $false)
    {
        throw "The specified target path does not exist or is not accessible"
    }

    $configItems = gci -Path "$($TargetPath)$($directorySeparator)*"  | where { ! $_.PSIsContainer }

    foreach($configItem in $configItems)
    {
        # set secret name: make replacements: _=zzz, .=yyy
        $secretName = Process-SecretName -SecretName $configItem.Name -Prefix $ConfigurationPrefix -Operation Encode -ProcessPrefix
        
        Log-Message "Creating secret $($configItem.Name) from $($configItem.FullName)" -Context "Secrets $($Operation)" -NoNewLine
        
        if ($isCli2)
        {
            # Cli 2.0
            $response = az keyvault secret set --output json --vault-name "$VaultName" --name "$secretName" --file "$($configItem.FullName)" --encoding "base64" | Out-String
        }
        else
        {
            # Cli 1.0
            $response = azure keyvault secret set --json --vault-name "$VaultName" -s "$secretName" --file "$($configItem.FullName)" --encode-binary "base64" | Out-String
        }

        $responseJson = Parse-Json -jsonString $response

        if ($responseJson -and $responseJson[0] -and $responseJson[0].value -and $responseJson[0].value.length -gt 0)
        {
            Log-Message -Message " [OK]"  -SkipTimestamp -Foregroundcolor Green
        }
        else
        {
            Log-Message -Message " [FAILED]" -SkipTimestamp -Foregroundcolor Red
            Log-Message -Message $response
            throw "Failed uploading secret '$secretName'"
        }
    }

    Log-Message "Uploading secrets completed successfully" -Context "Secrets $($Operation)"
}

# Download & Re-consistitute
if ($Operation -ieq "Download")
{
    Log-Message "Downloading secrets from '$($VaultName)'" -Context "Secrets $($Operation)"

    # check for target path
    if ($TargetPath.Trim().Length -eq 0)
    {
        throw "A target path must be specified for downloading secrets"
    }

    # fetch the keyvault secrets
    if ($isCli2)
    {
        $results = az keyvault secret list --vault-name $VaultName --output json | Out-string
    }
    else
    {
        $results = azure keyvault secret list $VaultName --json | Out-string
    }

    $secrets = Parse-Json -jsonString $results

    [array]$secretList = @()
    foreach($secret in $secrets)
    {
        $secretList += $rawSecretName = $secret.id.Split("/") | select -Last 1
    }

    if ((Test-Path -Path $TargetPath) -eq $false)
    {
        Log-Message "Creating $($TargetPath)" -Context "Secrets $($Operation)"
        new-item $TargetPath -ItemType Directory -Force | Out-Null
    }
    else
    {
        Log-Message "$($TargetPath) exists" -Context "Secrets $($Operation)"
    }

    # filter the keys (if necessary)
    $oxaToolConfigSecrets = $secretList
    if ($ConfigurationPrefix.Trim().Length -gt 0)
    {
        Log-Message "Filtering to '$($ConfigurationPrefix)' secrets only" -Context "Secrets $($Operation)"
        $oxaToolConfigSecrets = $oxaToolConfigSecrets |  Where-Object { $_.StartsWith($ConfigurationPrefix) }
    }

    # iterate the target secrets and download them
    foreach($secretName in $oxaToolConfigSecrets)
    {
        $fileName = Process-SecretName -SecretName $secretName -Prefix $ConfigurationPrefix -Operation Decode

        # resolve the base path
        [string]$settingFilePath = "$($TargetPath)$($directorySeparator)$($fileName)"

        # make sure the file doesn't currently exist
        if ((Test-Path $settingFilePath) -eq $true)
        {
            Remove-Item $settingFilePath | Out-Null
        }

        # TODO: add --decode-binary and replace explicit base64 decode
        # There is a bug in the azure keyvault secret get api regarding the use of --decode-binary. It results in base64 function not found.
        # Investigation Details: due to a bug in the legacy version of nodejs, the base64 function is broken.
        # In the interim, the approach is: download the file & base64-decode it in place.
        # This only applies to Azure CLI 1 and doesn't extend to Azure Cli 2.
        
        # download
        Log-Message -Message "Downloading secret: '$secretName' to '$settingFilePath'"
        if ($isCli2)
        {
            az keyvault secret download --vault-name $VaultName --name $secretName --file $settingFilePath --encoding base64 | Out-Null
        }
        else
        {
            azure keyvault secret get -u $VaultName -s $secretName --file $settingFilePath | Out-Null

            # decode 
            $content = gc $settingFilePath -Encoding UTF8 -Raw
            $content =[Convert]::FromBase64String($content)
            $content = [System.Text.Encoding]::UTF8.GetString($content)
            [IO.File]::WriteAllText($settingFilePath, $content)
        }
    }
}

# Clean up
if ($Operation -ieq "Purge" -or $Operation -ieq "List")
{
    Log-Message "Getting Vault Secrets"  -Context "Secrets $($Operation)"

    Log-Message "azure keyvault secret list $VaultName"
    if ($isCli2)
    {
        $results = az keyvault secret list --vault-name $VaultName --output json | Out-String
    }
    else
    {
        $results = azure keyvault secret list $VaultName --json | Out-string
    }

    $secrets = @()

    $secrets = Parse-Json -jsonString $results

    [array]$secretList = @()
    foreach($secret in $secrets)
    {
        $secretList += $rawSecretName = $secret.id.Split("/") | select -Last 1
        Log-Message $(Process-SecretName -SecretName $rawSecretName -Prefix $ConfigurationPrefix -Operation Decode )  -Context "Secrets $($Operation)"
    }

    if ($Operation -ieq "Purge")
    {
        Log-Message "Cleaning up vault" -ClearLine -Context "Secrets $($Operation)"
        Log-Message "Found $($secretList.Count) keys and removing them all" -Context "Secrets $($Operation)"

        foreach($secret in $secretList)
        {
            if ($isCli2)
            {
                $response = az keyvault secret delete --vault-name "$VaultName" --name "$secret" | Out-String
            }
            else
            {
                $response = azure keyvault secret delete --vault-name "$VaultName" --secret-name "$secret" -q | Out-String
            }

            if ($response.Contains("error") -or $response.Contains("Secret not found") -or $response.Contains("The vault may not exist"))
            {
                Log-Message -Message $response -LogType Error
                throw "Failed deleting '$VaultName'"
            }
            else
            {
                Log-Message -Message "Removed secret: '$secret'" -Context "Secrets $($Operation)"
            }
        }
    }
}