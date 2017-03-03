<#
.SYNOPSIS
Installs the specified custom script extension

.DESCRIPTION
Azure only supports installing one custom scription extension per handler. Therefore, it is necessary to remove all existing extensions before installing a new one
This script handles both tasks

This script assume you have an existing resource group and that the OXA Stamp is already successfully deployed.

.PARAMETER AzureSubscriptionName
Name of the azure subscription to use

.PARAMETER ResourceGroupName
Name of the azure resource group name

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

.PARAMETER TemplateFile
Path to the deployment template file to use for the arm deployment


.PARAMETER TemplateFile
Path to the deployment template file to use for the arm deployment

.PARAMETER TemplateParameterFile
Path to the deployment parameters file to use for the arm deployment

.INPUTS
None. You cannot pipe objects to Deploy-OxaStamp.ps1

.OUTPUTS
None


.EXAMPLE
.\Deploy-CustomScriptExtension.ps1 -AzureSubscriptionName SomeSubscription -ResourceGroupName OxaMasterNode -AadWebClientId "1178d667e54c" -AadWebClientAppKey "BDtkq10kdGxI6QgtyNI=" -AadTenantId "1db47" -TemplateFile "c:\template.json" -TemplateParameterFile "c:\parameters.json"

#>
Param( 
        [Parameter(Mandatory=$true)][string]$AzureSubscriptionName,
        [Parameter(Mandatory=$true)][string]$ResourceGroupName,
        [Parameter(Mandatory=$true)][string]$AadWebClientId,
        [Parameter(Mandatory=$true)][string]$AadWebClientAppKey,
        [Parameter(Mandatory=$true)][string]$AadTenantId,
        [Parameter(Mandatory=$true)][string]$TemplateFile,
        [Parameter(Mandatory=$true)][string]$TemplateParameterFile,
        [Parameter(Mandatory=$false)][switch]$Upgrade
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

$jobs = @()

# if upgrade is set, we skip deleting the existing extensions
if ($Upgrade -eq $false)
{

    # get all VMs
    Log-Message "Getting all VMs in the '$ResourceGroupName' resource group";
    $vms = Get-AzureRmVM -ResourceGroupName $ResourceGroupName -Verbose


    # iterate each VM and remove any existing custom scription extension
    foreach($vm in $vms)
    {
        foreach($extension in $vm.Extensions)
        {
            # TODO: run this within a job to speed up the removal
            $extensionName = $extension.Id.split("/") | select -Last 1

             $jobs += Start-Job  -Name "Remove-CSX-$($vm.Name)-$($extensionName)" –Scriptblock {
                                                    param($vmName, $extensionName, $ResourceGroupName, $AadWebClientAppKey, $AadWebClientId, $AadTenantId, $AzureSubscriptionName)

                                                    # Login
                                                    $clientSecret = ConvertTo-SecureString -String $AadWebClientAppKey -AsPlainText -Force
                                                    $aadCredential = New-Object System.Management.Automation.PSCredential($AadWebClientId, $clientSecret)
                                                    Login-AzureRmAccount -ServicePrincipal -TenantId $AadTenantId -SubscriptionName $AzureSubscriptionName -Credential $aadCredential -ErrorAction Stop
                                                    Set-AzureSubscription -SubscriptionName $AzureSubscriptionName | Out-Null

                                                    Remove-AzureRmVMCustomScriptExtension -ResourceGroupName $ResourceGroupName -VMName $vmName -Name $extensionName -Force
                                                
                                                
            } -ArgumentList $vm.Name, $extensionName, $ResourceGroupName, $AadWebClientAppKey, $AadWebClientId, $AadTenantId, $AzureSubscriptionName;
        }
    }

    do
    {
        # sleep and check for running jobs again
        start-sleep -Seconds 2;

        Log-Message -Message "." -NoNewLine;

        # get the latest status
        $runningJobs = get-job | Where-Object { $_.State -eq 'Running' -and $_.Name.StartsWith("Remove-CSX-") }
    }
    until ( $runningJobs.Count -eq 0);

    # clean up
    Get-Job | Receive-Job
}
else
{
    Log-Message "Skipping removal of existing extensions"
}

# install the new extension
New-AzureRmResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateFile $templateFile -TemplateParameterFile $templateParameterFile -Force -Verbose

