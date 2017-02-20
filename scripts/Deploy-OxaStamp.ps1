<#
.SYNOPSIS
Deploy the OXA Stamp - Enterprise-Grade OpenEdx on Azure infrastructure that supports High Availability and Scalability

.DESCRIPTION
This script deploys the OXA Stamp. It supports a clean infrastructure bootstrap and incremental updates

This script assumes you have already have an AzureRM authenticated session

.PARAMETER AzureSubscriptionName
Name of the azure subscription to use

.PARAMETER ResourceGroupName
Name of the azure resource group name

.PARAMETER Location
Location of the resource group. See https://azure.microsoft.com/en-us/regions/ for details

.PARAMETER TargetPath
Directory path holding the secrets for populating keyvault. Only files in this directory will be uploaded as secrets. Recursion is not supported

.PARAMETER ConfigurationPrefix
Prefix prepended to the secret names for categorization purposes

.PARAMETER AadWebClientId
The azure active directory web application Id for authentication

.PARAMETER AadWebClientAppKey
The azure active directory web application key for authentication

.PARAMETER AadTenantId
The azure active directory tenant id for authentication

.PARAMETER KeyVaultDeploymentArmTemplateFile
Path to the arm template for bootstrapping keyvault

.PARAMETER KeyVaultDeploymentParametersFile
Path to the deployment parameters file for the keyvault arm deployment

.PARAMETER FullDeploymentArmTemplateFile
Path to the arm template for bootstrapping keyvault

.PARAMETER FullDeploymentArmTemplateFile
Path to the deployment parameters file for the keyvault arm deployment

.INPUTS
None. You cannot pipe objects to Deploy-OxaStamp.ps1

.OUTPUTS
None


.EXAMPLE
.\Deploy-OxaStamp.ps1 -AzureSubscriptionName SomeSubscription -ResourceGroupName OxaMasterNode -Location "west us" -TargetPath "E:\env\bvt" -AadWebClientId "1178d667e54c" -AadWebClientAppKey "BDtkq10kdGxI6QgtyNI=" -AadTenantId "1db47" -KeyVaultDeploymentArmTemplateFile "E:\stampKeyVault.json" -KeyVaultDeploymentParametersFile "E:\env\bvt\parameters.json" -FullDeploymentParametersFile "E:\env\bvt\parameters.json" -FullDeploymentArmTemplateFile "E:\stamp-v2.json" -DeployKeyVault -DeployStamp:$false

#>
Param( 
        [Parameter(Mandatory=$true)][string]$AzureSubscriptionName,
        [Parameter(Mandatory=$true)][string]$ResourceGroupName,
        [Parameter(Mandatory=$true)][string]$Location,

        [Parameter(Mandatory=$true)][string]$TargetPath,
        [Parameter(Mandatory=$false)][string]$ConfigurationPrefix = "OxaToolsConfigxxx",
        [Parameter(Mandatory=$true)][string]$AadWebClientId,
        [Parameter(Mandatory=$true)][string]$AadWebClientAppKey,
        [Parameter(Mandatory=$true)][string]$AadTenantId,

        [Parameter(Mandatory=$true)][string]$KeyVaultDeploymentArmTemplateFile,
        [Parameter(Mandatory=$true)][string]$KeyVaultDeploymentParametersFile,
        [Parameter(Mandatory=$true)][string]$FullDeploymentArmTemplateFile,
        [Parameter(Mandatory=$true)][string]$FullDeploymentParametersFile,

        [Parameter(Mandatory=$false)][switch]$DeployKeyVault=$true,
        [Parameter(Mandatory=$false)][switch]$DeployStamp=$true
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

## Function: Authenticate-AzureRmUser
##
## Purpose: 
##    Authenticate the AAD user that will interact with KeyVault
##
## Input: 
##   ParametersFile             path to the file holding the deployment parameters (the parameters.json file)
##   ClusterName                the cluster name
##   ClusterNameTemplateValue   the cluster name template value to replace
##
## Output:
##   nothing
##
function Update-ClusterNameParameter
{
    param(
            [Parameter(Mandatory=$true)][string]$ParametersFile,
            [Parameter(Mandatory=$true)][string]$ClusterName,
            [Parameter(Mandatory=$false)][string]$ClusterNameTemplateValue="{CLUSTERNAME}"
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
    $parametersContent = $parametersContent.Replace($ClusterNameTemplateValue, $ClusterName);

    [IO.File]::WriteAllText($tempParametersFile, $parametersContent);

    return $tempParametersFile
}

# Login
$clientSecret = ConvertTo-SecureString -String $AadWebClientAppKey -AsPlainText -Force
$aadCredential = New-Object System.Management.Automation.PSCredential($AadWebClientId, $clientSecret)
Login-AzureRmAccount -ServicePrincipal -TenantId $AadTenantId -SubscriptionName $AzureSubscriptionName -Credential $aadCredential -ErrorAction Stop
Set-AzureSubscription -SubscriptionName $AzureSubscriptionName | Out-Null

# create the resource group
New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location -Force

if ($DeployKeyVault)
{
    # provision the keyvault
    # we may need to replace the default resource group name in the parameters file
    Log-Message "Updating the cluster reference to $($ResourceGroupName)"
    $tempParametersFile = Update-ClusterNameParameter -ParametersFile $KeyVaultDeploymentParametersFile -ClusterName $ResourceGroupName

    $provisioningOperation = New-AzureRmResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateFile $KeyVaultDeploymentArmTemplateFile -TemplateParameterFile $tempParametersFile -Force -Verbose  
    
    if ($provisioningOperation.ProvisioningState -ine "Succeeded")
    {
        $provisioningOperation
        throw "Unable to provision the resource group $($ResourceGroupName)"
    }

    # pre-populate the keyvault
    $scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
    $separator = Get-DirectorySeparator
    Log-Message "Populating keyvault using script at $($scriptPath)$($separator)Process-OxaToolsKeyVaultConfiguration.ps1"
    &"$($scriptPath)$($separator)Process-OxaToolsKeyVaultConfiguration.ps1" -Operation Upload -VaultName "$($ResourceGroupName)-kv" -AadWebClientId $AadWebClientId -AadWebClientAppKey $AadWebClientAppKey -AadTenantId $AadTenantId -AzureSubscriptionId $AzureSubscriptionName -TargetPath $TargetPath
}

if ($DeployStamp)
{
    # kick off full deployment
    # we may need to replace the default resource group name in the parameters file
    Log-Message "Updating the cluster reference to $($ResourceGroupName)"
    $tempParametersFile = Update-ClusterNameParameter -ParametersFile $FullDeploymentParametersFile -ClusterName $ResourceGroupName

    New-AzureRmResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateFile $FullDeploymentArmTemplateFile -TemplateParameterFile $tempParametersFile -Force -Verbose  
}