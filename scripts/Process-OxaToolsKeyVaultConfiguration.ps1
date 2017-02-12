<#
.SYNOPSIS
Process OXA Tools Configuration Keyvault transactions (Upload, Download, List and Delete)

.DESCRIPTION
This script provides options for uploading new or updating existing OXA tools configurations to an 
existing Azure KeyVault instance. It also provides options for listing, downloading and saving to file 
(Hydrate from Keyvault) as well as deleting all secrets.

This script assumes you have already have an AzureRM authenticated session

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

.PARAMETER AadWebClientAppKey
The azure active directory tenant id for authentication

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
        [Parameter(Mandatory=$true)][string]$AzureSubscriptionId
     )


##  Function: LogMessage
##
##  Purpose: Write a message to a log file
##
##  Input: 
##      Message          - string - message to write
##      LogType          - string - message type
##      Foregroundcolor  - string - color of the output for Log-Messageonly
##
##  Ouput: null
function Log-Message
{
    param(
            [Parameter(Mandatory=$false)][object]$Message,
            [Parameter(Mandatory=$false)][ValidateSet("Verbose","Output", "Host", "Error", "Warning")][string]$LogType="Host",
            [Parameter(Mandatory=$false)][string]$Foregroundcolor = "White",
            [Parameter(Mandatory=$false)][string]$Context = "",
            [Parameter(Mandatory=$false)][switch]$NoNewLine,
            [Parameter(Mandatory=$false)][switch]$ClearLine,
            [Parameter(Mandatory=$false)][switch]$SkipTimestamp
         )

    
    # append header to identify where the call came from for debugging purposes
    if ($Context -ne "")
    {
        $Message = "$Context - $Message";
    }

    # if necessary, prepend a blank line
    if ($ClearLine -eq $true)
    {
        $logTime = [System.Environment]::NewLine
    }

    # prepend log time
    $logTime += "[$(get-date -format u)]";

    if($NoNewLine -eq $false -and $SkipTimestamp -eq $false)
    {
        $logLine = "$logTime :: $Message";
    }
    else
    {
        $logLine = $Message;
    }

    switch($LogType)
    {
        "Verbose" {  Write-Verbose $logLine; }
        "Output"  {  Write-Output $logLine ; }
        "Host"    {  Write-Host $logLine -ForegroundColor $ForegroundColor -NoNewline:$NoNewLine; }
        "Error"   {  Write-Error $logLine; }
        "Warning" {  Write-Warning $logLine ; }
        default   {  Write-Host $logLine -ForegroundColor $ForegroundColor -NoNewline:$NoNewLine; }
    }
}

##  Function: Parse-Json
##
##  Purpose: Parse a json string and return its json object
##
##  Input: 
##      JsonString     - the json string
##
##  Ouput: the corresponding json object
##
function Parse-Json
{
    param(
            [Parameter(Mandatory=$true)][string]$jsonString
         )

    $jsonObject = $null;

    try
    {
        $jsonObject = ConvertFrom-Json -InputObject $jsonString;
    }
    catch
    {
        [string]$exception = $error[0].ToString()
        if (!$exception.contains("Conversion from JSON failed with error"))
        {
            # this is not a case where no data is returned or the json string is not valid
            throw
        }
    }

    return $jsonObject
}

##  Function: Process-SecretName
##
##  Purpose: Encode or Decode a keyvault secret name
##
##  Input: 
##      SecretName     - the secret name
##      Prefix         - the secret name prefix
##      Operation      - the operation to perform (Encode or Decode)
##      ProcessPrefix  - indicator for processing or not processing the prefix
##
##  Ouput: the secret name
function Process-SecretName
{
    param(
            [Parameter(Mandatory=$true)][string]$SecretName,
            [Parameter(Mandatory=$false)][string]$Prefix="",
            [Parameter(Mandatory=$true)][ValidateSet("Decode","Encode")][string]$Operation,
            [Parameter(Mandatory=$false)][switch]$ProcessPrefix
         )

    
    # Keyvault secret names are limited to alpha numeric values only
    # therefore, we have to perform some string replacements to ensure that we can setup the required secrets/keys
    [hashtable]$replacements = @{ "_" = "zzz";  "." = "yyy";}

    if ($Operation -eq "Encode")
    { 
        # perform the string replacements
        foreach ($key in $replacements.Keys)
        {
            $secretName = $secretName.replace($key, $replacements[$key]);
        }

        # add the configuration name prefix
        if ($ProcessPrefix -eq $true)
        {
            $secretName = "$($Prefix)$($secretName)"
        }
    }
    elseif ($Operation -eq "Decode")
    {
        # remove the configuration name prefix
        if ($ProcessPrefix -eq $false)
        {
            $secretName = $secretName.Replace($Prefix, "");
        }

        # reverse the string replacements
        foreach($key in $replacements.Keys)
        {
            $secretName = $secretName.replace($replacements[$key], $key);
        }
    }

    return $secretName;
}

## Function: Set-AzureSubscriptionContext
##
## Purpose: 
##   Set the cli context to the appropriate azure subscription after login
##
## Input: 
##   $AzureSubscriptionId     the azure subscription id to set as current
##
## Output:
##   nothing
##
function Set-AzureSubscriptionContext
{
    param(
            [Parameter(Mandatory=$true)][string]$AzureSubscriptionId
         )

    Log-Message "Setting execution context to the '$($AzureSubscriptionId)' azure subscription"

    $results = azure account set  $AzureSubscriptionId  -vv --json | Out-String

    if (!$results.Contains("account set command OK"))
    {
        throw "Could not set execution context to the '$($AzureSubscriptionId)' azure subscription"
    }
}

## Function: Authenticate-AzureRmUser
##
## Purpose: 
##    Authenticate the AAD user that will interact with KeyVault
##
## Input: 
##   AadWebClientId           the azure active directory web application client id
##   AadWebClientAppKey       the azure active directory web application key
##   AadTenantId              the azure active directory tenant id
##
## Output:
##   nothing
##
function Authenticate-AzureRmUser
{
    param(
            [Parameter(Mandatory=$true)][string]$AadWebClientId,
            [Parameter(Mandatory=$true)][string]$AadWebClientAppKey,
            [Parameter(Mandatory=$true)][string]$AadTenantId
         )

    Log-Message "Logging in as service principal for '$($AadTenantId)'"
    $results = azure login -u $AadWebClientId --service-principal --tenant $AadTenantId -p $AadWebClientAppKey -vv --json | Out-String

    if (!$results.Contains("login command OK"))
    {
        throw "Login failed"
    }
}

## Function: Get-DirectorySeparator
##
## Purpose: 
##    Get the directory separator appropriate for the OS
##
## Input: 
##
## Output:
##   OS-specific directory separator
##
function Get-DirectorySeparator
{
    $separator = "/";
    if ($env:ComSpec)
    {
        $separator = "\"
    }

    return $separator
}

## Function: Capture-ErrorStack
##
## Purpose: 
##    Capture an exception error stack and return a formatted output 
##
## Input: 
##   ForceStop       stop script execution on error
##   GetOutput       indicator of whether or not to return the error output or print it to console
##
## Output:
##   formatted output
##
function Capture-ErrorStack
{
    param(
            [Parameter(Mandatory=$false)][switch]$ForceStop,
            [Parameter(Mandatory=$false)][switch]$GetOutput
         )

    if ($global:Error.Count -eq 0)
    {
        return
    }

    [int]$decoratorLength = 75;
    [string]$message1 = "";
    [string]$message2 = "";


    $lastErrors = @($global:Error[0])
    
    foreach ($lastError in $lastErrors)
    {
        $message1 = "Error: $($lastError.Exception.Message)`r`n";
        $message1 += $lastError.InvocationInfo | Format-List * | Out-String;
        
        foreach($exception in $lastError.Exception)
        {
            $message2 = $exception | Format-List * -Force | Out-String;
        }
    }

    $errorMessage = "`r`n`r`n";
    $errorMessage += "#" * $decoratorLength;
    $errorMessage += "`r`nERROR ENCOUNTERED`r`n";
    $errorMessage += "#" * $decoratorLength;
    $errorMessage += "`r`n$($message1)";

    if ($message2 -ne "")
    {
        $errorMessage += "#" * $decoratorLength;
        $errorMessage += "`r`n$($message2)";
    }

    if ($ForceStop)
    {
        Log-Message -Message $errorMessage -LogType Error;
    }
    else
    {
         Log-Message -Message $errorMessage;
    }

    if ($GetOutput)
    {
        return $errorMessage;
    }
}

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

# Login First & set context
Authenticate-AzureRmUser -AadWebClientId $AadWebClientId -AadWebClientAppKey $AadWebClientAppKey -AadTenantId $AadTenantId;
Set-AzureSubscriptionContext -AzureSubscriptionId $AzureSubscriptionId

# Get the directory separator
$directorySeparator = Get-DirectorySeparator;

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
        $response = azure keyvault secret set --json --vault-name "$VaultName" -s "$secretName" --file "$($configItem.FullName)" --encode-binary "base64" | Out-String

        $responseJson = Parse-Json -jsonString $response

        if ($responseJson -and $responseJson[0] -and $responseJson[0].value -and $responseJson[0].value.length -gt 0)
        {
            Log-Message -Message " [OK]"  -SkipTimestamp -Foregroundcolor Green;
        }
        else
        {
            Log-Message -Message " [FAILED]" -SkipTimestamp -Foregroundcolor Red;
            Log-Message -Message $response
            throw "Failed uploading secret '$secretName'"
        }
    }

    Log-Message "Uploading secrets completed successfully" -Context "Secrets $($Operation)"
}

# Download & Re-consistitute
if ($Operation -ieq "Download")
{
    Log-Message "Downloading secrets" -Context "Secrets $($Operation)"

    # check for target path
    if ($TargetPath.Trim().Length -eq 0)
    {
        throw "A target path must be specified for downloading secrets"
    }

    # fetch the keyvault secrets
    $results = azure keyvault secret list $VaultName --json | Out-string
    $secrets = Parse-Json -jsonString $results

    [array]$secretList = @();
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
        # In the interim, the approach is: download the file & base64-decode it in place.
        
        # download
        Log-Message -Message "Downloading secret: '$secretName' to '$settingFilePath'"
        azure keyvault secret get -u $VaultName -s $secretName --file $settingFilePath | Out-Null

        # decode
        $content = gc $settingFilePath -Encoding UTF8 -Raw
        $content =[Convert]::FromBase64String($content)
        $content = [System.Text.Encoding]::UTF8.GetString($content)
        [IO.File]::WriteAllText($settingFilePath, $content)
    }
}

# Clean up
if ($Operation -ieq "Purge" -or $Operation -ieq "List")
{
    Log-Message "Getting Vault Secrets"  -Context "Secrets $($Operation)"

    Log-Message "azure keyvault secret list $VaultName"
    $results = azure keyvault secret list $VaultName --json | Out-string
    $secrets = @();

    $secrets = Parse-Json -jsonString $results;

    [array]$secretList = @();
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
            $response = azure keyvault secret delete --vault-name "$VaultName" --secret-name "$secret" -q | Out-String
            if ($response.Contains("error"))
            {
                Log-Message -Message $response -LogType Error;
                throw "Failed deleting '$VaultName'"
            }
            else
            {
                Log-Message -Message "Removed secret: '$secret'" -Context "Secrets $($Operation)"
            }
        }
    }
}