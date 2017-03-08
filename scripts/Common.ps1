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
        Log-Message "Replacing '{$key}' with '$($ReplacementHash[ $key ])'"
        $parametersContent = $parametersContent -ireplace "{$key}", $ReplacementHash[ $key ];
    }

    # save the output
    Log-Message "W"
    [IO.File]::WriteAllText($tempParametersFile, $parametersContent);

    return $tempParametersFile
}