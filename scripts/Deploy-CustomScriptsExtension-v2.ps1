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
 		 
.PARAMETER UpgradeServer
Name of the server to run the upgrade from

.INPUTS
None. You cannot pipe objects to Deploy-OxaStamp.ps1

.OUTPUTS
None


.EXAMPLE
.\Deploy-CustomScriptExtension-v2.ps1 -AzureSubscriptionName SomeSubscription -ResourceGroupName OxaMasterNode -AadWebClientId "1178d667e54c" -AadWebClientAppKey "BDtkq10kdGxI6QgtyNI=" -AadTenantId "1db47" -TemplateFile "c:\template.json" -TemplateParameterFile "c:\parameters.json"

#>
Param( 
        [Parameter(Mandatory=$true)][string]$AzureSubscriptionName,
        [Parameter(Mandatory=$true)][string]$ResourceGroupName,
        [Parameter(Mandatory=$true)][string]$AadWebClientId,
        [Parameter(Mandatory=$true)][string]$AadWebClientAppKey,
        [Parameter(Mandatory=$true)][string]$AadTenantId,
        [Parameter(Mandatory=$true)][string]$TemplateFile,
        [Parameter(Mandatory=$true)][string]$TemplateParameterFile,
        [Parameter(Mandatory=$true)][string]$UpgradeServer,

        [Parameter(Mandatory=$true)][string]$ClusterAdmininistratorEmailAddress,
        [Parameter(Mandatory=$false)][string]$OxaToolsGithubAccountName="Microsoft",
        [Parameter(Mandatory=$false)][string]$OxaToolsGithubProjectName="oxa-tools",
        [Parameter(Mandatory=$false)][string]$OxaToolsGithubBranch="oxa/master.fic",
        [Parameter(Mandatory=$false)][string]$OxaToolsGithubBranchTag="",

        [Parameter(Mandatory=$false)][string]$InstallerPackageName,
        [Parameter(Mandatory=$false)][array]$UpgradeParameters=@(),

        [Parameter(Mandatory=$false)][switch]$Upgrade
     )


#################################
# ENTRY POINT
#################################

# Import library
$invocation = (Get-Variable MyInvocation).Value 
$currentPath = Split-Path $invocation.MyCommand.Path 
Import-Module "$($currentPath)/Common.ps1" -Force

# Login
$clientSecret = ConvertTo-SecureString -String $AadWebClientAppKey -AsPlainText -Force
$aadCredential = New-Object System.Management.Automation.PSCredential($AadWebClientId, $clientSecret)
Login-AzureRmAccount -ServicePrincipal -TenantId $AadTenantId -SubscriptionName $AzureSubscriptionName -Credential $aadCredential -ErrorAction Stop
Set-AzureSubscription -SubscriptionName $AzureSubscriptionName | Out-Null

# if upgrade is set, we skip deleting the existing extensions
if ($Upgrade -eq $false)
{
    $jobs = @()

    # get the Jumpbox VM
    Log-Message "Getting the Jumpbox VM in the '$ResourceGroupName' resource group";
    $vms = Get-AzureRmVM -ResourceGroupName $ResourceGroupName -Verbose | Where-Object { $_.Name.Contains("-jb") }

    # iterate each VM and remove any existing custom scription extension
    [array]$targetedVms = @()

    foreach($vm in $vms)
    {
        $targetedVms += $vm.Name;

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

    Log-Message "Completed removal of existing Custom Script Extension for $($targetedVms -join(","))"
    Get-Job | Receive-Job | Out-Null
}
else
{
    Log-Message "Skipping removal of existing extensions"
}

#prep the variables we want to use for replacement
# upgradeParameters is expected to be an array of hashtables where each hashtable has 
# the following keys: name, value, valueType (optional: defaults to string) and their accompanying values
# the only supported valueTypes are: string (default) and FilePath
# for FilePath valueType, the path will be tested, content read and base64 encoded before being passed as the parameter value

# we already have some userful parameters that downstream scripts can leverage
Log-Message "Adding Azure Subscription and AAD related parameters"

$upgradeParameters += @{"name"="azure-resource-group"; "value"=$ResourceGroupName}
$upgradeParameters += @{"name"="aad-webclient-id"; "value"=$AadWebClientId}
$upgradeParameters += @{"name"="aad-webclient-appkey"; "value"=$AadWebClientAppKey}
$upgradeParameters += @{"name"="aad-tenant-id"; "value"=$AadTenantId}
$upgradeParameters += @{"name"="azure-subscription-id"; "value"=$AzureSubscriptionName}

[array]$upgradeParameterList = @()
foreach($parameter in $upgradeParameters)
{
    [hashtable]$parameterHashtable = $parameter
    # parameter is expected to be a hashtable with the following keys: name, value (optional: defaults to blank), valueType (optional: defaults to string)
    if ($parameterHashtable.ContainsKey("name") -eq $false)
    {
        throw "'$($parameter)' is invalid. It is expected to be a hashtable with the following keys: name, value (optional: defaults to blank), valueType (optional: defaults to string)"
    }

    if ($parameterHashtable.ContainsKey("valueType") -and ($parameterHashtable["valueType"] -ieq "File" -or $parameterHashtable["valueType"] -ieq "Base64") )
    {
        # get the file content and base64 encode it
        if ($parameterHashtable["valueType"] -ieq "File")
        {
            # we have a filetype specified. Make sure the "value" is present & that it points to a file
            if ($parameterHashtable.ContainsKey("value") -eq $false)
            {
                throw "No value specified for the FileType parameter: '$($parameterHashtable["name"])'"
            }

            # test the file path
            if ((Test-Path -Path ($parameterHashtable["value"])) -eq $false )
            {
                throw "The file specified '$($parameterHashtable["value"])' doesn't exist!"
            }
        
            $contentToEncode = gc -Path $parameterHashtable["value"]
        }
        else
        {
            Log-Message "Encoding $($parameterHashtable["name"])"
            $contentToEncode = $parameterHashtable["value"]
        }
        
        $contentToEncodeBytes = [System.Text.Encoding]::UTF8.GetBytes($contentToEncode)
        $parameterValue = [Convert]::ToBase64String($contentToEncodeBytes)
    }
    else
    {
        # treat value as string
        $parameterValue=$parameterHashtable["value"]
    }

    # append the parameter to the list
    $upgradeParameterList += "--$($parameterHashtable["name"]) ""$($parameterValue)"""
}

# prepare the upgrade parameters for handling in the scripts
$upgradeParameterListBytes = [System.Text.Encoding]::UTF8.GetBytes($upgradeParameterList -join " ")
$upgradeParameterListEncoded = [Convert]::ToBase64String($upgradeParameterListBytes)

$replacements = @{
                    "ClusterName"=$ResourceGroupName; 
                    "ClusterAdmininistratorEmailAddress"=$ClusterAdmininistratorEmailAddress;
                    "OxaToolsGithubAccountName"=$OxaToolsGithubAccountName;
                    "OxaToolsGithubProjectName"=$OxaToolsGithubProjectName;
                    "OxaToolsGithubBranch"=$OxaToolsGithubBranch;
                    "OxaToolsGithubBranchTag"=$OxaToolsGithubBranchTag;
                    "InstallerPackageName"=$InstallerPackageName;
                    "UpgradeParameters"=$upgradeParameterListEncoded;
                    "TargetJumpboxName"=$UpgradeServer;
                }

$tempParametersFile = Update-RuntimeParameters -ParametersFile $TemplateParameterFile -ReplacementHash $replacements;

# install the new extension
New-AzureRmResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateFile $templateFile -TemplateParameterFile $tempParametersFile -Force -Verbose

# Log-Message "Temp file: $tempParametersFile"
Remove-Item $tempParametersFile