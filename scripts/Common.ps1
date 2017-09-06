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

## Function: Update-RuntimeParameters
##
## Purpose: 
##    Update the runtime parameters
##
## Input: 
##   ParametersFile                   path to the file holding the deployment parameters (the parameters.json file)
##   ReplacementHash                  hash table of replacement key and value pairs
##
## Output:
##   updated arm deployment parameter file
##
function Update-RuntimeParameters
{
    param(
            [Parameter(Mandatory=$true)][string]$ParametersFile,
            [Parameter(Mandatory=$true)][hashtable]$ReplacementHash
         )

    # check if the file exists and resolve it's path
    $ParametersFile = Resolve-Path -Path $ParametersFile -ErrorAction Stop
    
    # create a temp file and perform the necessary template replacements
    $tempParametersFile = [System.IO.Path]::GetTempFileName();
    if ((Test-Path -Path $tempParametersFile) -eq $false)
    {
        throw "Could not create a temporary file"
    }

    Log-Message "Parameters File: $($ParametersFile)"
    $parametersContent = gc $ParametersFile -Encoding UTF8
    foreach($key in $ReplacementHash.Keys)
    {
        # todo: track cases where search key is not found and provide notification that replacement was skipped
        Log-Message "Replacing '{$key}' with '$($ReplacementHash[ $key ])'"
        $parametersContent = $parametersContent -ireplace "{$key}", $ReplacementHash[ $key ];
    }

    # save the output
    [IO.File]::WriteAllText($tempParametersFile, $parametersContent);

    return $tempParametersFile
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
##   AzureSubscriptionId      the azure subscription id to set as current
##   IsCli2                   indicator of whether or not azure cli 2.0 is used
##
## Output:
##   nothing
##
function Set-AzureSubscriptionContext
{
    param(
            [Parameter(Mandatory=$true)][string]$AzureSubscriptionId,
            [Parameter(Mandatory=$false)][boolean]$IsCli2=$false
         )

    Log-Message "Setting execution context to the '$($AzureSubscriptionId)' azure subscription"

    if ($IsCli2)
    {
        $results = az account set --subscription $AzureSubscriptionId --output json | out-string
        if ($results.Length -gt 0)
        {
            throw "Could not set execution context to the '$($AzureSubscriptionId)' azure subscription"
        }
    }
    else
    {
        $results = azure account set  $AzureSubscriptionId  -vv --json | Out-String
        if (!$results.Contains("account set command OK"))
        {
            throw "Could not set execution context to the '$($AzureSubscriptionId)' azure subscription"
        }
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
##   IsCli2                   indicator of whether or not azure cli 2.0 is used
##
## Output:
##   nothing
##
function Authenticate-AzureRmUser
{
    param(
            [Parameter(Mandatory=$true)][string]$AadWebClientId,
            [Parameter(Mandatory=$true)][string]$AadWebClientAppKey,
            [Parameter(Mandatory=$true)][string]$AadTenantId,
            [Parameter(Mandatory=$false)][boolean]$IsCli2=$false
         )

    Log-Message "Logging in as service principal for '$($AadTenantId)'"
    if ($IsCli2)
    {
        $results = az login -u $AadWebClientId --service-principal --tenant $AadTenantId -p $AadWebClientAppKey --output json | Out-String
        if ($results.Contains("error"))
        {
            throw "Login failed"
        }
    }
    else
    {
        $results = azure login -u $AadWebClientId --service-principal --tenant $AadTenantId -p $AadWebClientAppKey -vv --json | Out-String
        if (!$results.Contains("login command OK"))
        {
            throw "Login failed"
        }
    }
}

## Function: Create-StorageContainer
##
## Purpose: 
##    Create a container in the specified storage account
##
## Input: 
##   StorageAccountName       name of the storage account
##   StorageAccountKey        access key for the specified storage account
##   StorageContainerName     name of the container to create within the specified storage account
##
## Output:
##   nothing
##
function Create-StorageContainer
{
    param(
            [Parameter(Mandatory=$true)][string]$StorageAccountName,
            [Parameter(Mandatory=$true)][string]$StorageAccountKey,
            [Parameter(Mandatory=$true)][string]$StorageContainerName
         )

    # get a storage context
    $storageContext = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey
    New-AzureStorageContainer -Name $StorageContainerName -Context $storageContext
}

## Function: Set-ScriptDefault
##
## Purpose: 
##    Validate parameter exists and log a message saying the default was set.
##
## Input: 
##   ScriptParamVal      supplied value of script parameter override if it is null or an empty string
##   ScriptParamName     name of script parameter being set to default value
##   DefaultValue        default value provided
##
## Output:
##   The DefaultValue parameter
##
function Set-ScriptDefault
{
    param(
            [Parameter(Mandatory=$true)][AllowEmptyString()][string]$ScriptParamVal,
            [Parameter(Mandatory=$true)][string]$ScriptParamName,
            [Parameter(Mandatory=$true)][string]$DefaultValue
         )

    if ($ScriptParamVal.Trim().Length -eq 0 -or $ScriptParamVal -eq $null)
    {        
        Log-Message "Falling back to default value: $($DefaultValue) for parameter $($ScriptParamName) since no value was provided"
    }

    return $DefaultValue
}
