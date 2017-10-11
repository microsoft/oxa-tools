<#
.SYNOPSIS
Start an OXA Deployment
.DESCRIPTION
Start an OXA Deployment
.PARAMETER EnlistmentRootPath
Absolute path to the root of the enlistment used for deployment on the local server
.PARAMETER ReleaseName
Name for the deployment
.PARAMETER LatestChangesetNumber
Latest changeset to snap to (either a numeric ChangesetId or T for current)
.PARAMETER Cloud
Cloud to deploy bits to
.PARAMETER TargetSlot
Cloud service deployment slot to target in deployment
.PARAMETER Branch
Branch of the source enlistment
.PARAMETER AsyncMode
Indicator of whether or not deployment is kicked off in Asynchronous or Synchronous mode. Setting this switch enables Asynchronous mode.
.PARAMETER Resume
Resume an existing deployment. The value of this parameter (if specified) should be the build number being resumed
.PARAMETER DisableTranscripting
Disable Powershell transcripting to log all outputs to file. Logs are stored at '$EnlistmentRootPath\BuildLogs'
.PARAMETER SwapDeployment
Indicator of whether or not the deployment run is for Swap. Setting this switch enables a deployment swap
.PARAMETER SmtpUserName
User name for account with SMTP access
.PARAMETER SmtpUserPassword
Password for account with SMTP access
.PARAMETER DeployerAdminAlias
Alias(es) that provide support for the deployment. Notification for all activities will be sent here (failures & successes). Use semi-colon separated list to specify multiple aliases
.PARAMETER MaxRetries
Maximum number of retry attempts that will be executed before the script will stop trying
.PARAMETER RetryDelaySeconds
Number of seconds of delay between retry attempts when operations fail
.PARAMETER NotifyOnlyAdmins
Indicator of whether or not ONLY the DeployerAdminAlias will be notified. If this switch is not set, completion notification will be sent to all owners of the changes being deployed
.PARAMETER SupportCC
Additional alias(es) that should be notified upon completion of deployment. Ie: Test Team, Leads, FTEs, etc
.OUTPUTS
None
.EXAMPLE
Start a new deployment getting the latest changes from ReleaseDev\Current targeting the MLXBUILD cloud's production slot:
.\Start-MlxDeployment.ps1 -ReleaseName "Dec 2 Daily Build 1" -Cloud MLXBUILD -TargetSlot Production -Branch ReleaseDev -AsyncMode -RetryDelaySeconds 5 -EnableTranscripting -SmtpUserName "_MLXITE3Email" -SmtpUserPassword = "[some secret password]" -DeployerAdminAlias "mlxdevops" -SupportCC "psgmlxtest;mlxengc"
.EXAMPLE
Resume an existing deployment (with label RDC.20153102.0212)
.\Start-MlxDeployment.ps1 -ReleaseName "Dec 2 Daily Build 1" -Cloud MLXBUILD -TargetSlot Production -Branch ReleaseDev -AsyncMode -RetryDelaySeconds 5 -EnableTranscripting -SmtpUserName "_MLXITE3Email" -SmtpUserPassword = "[some secret password]" -DeployerAdminAlias "mlxdevops" -SupportCC "psgmlxtest;mlxengc" -Resume "RDC.20153102.0212"
.EXAMPLE
Redeploy changes in deployment (with label RDC.20151202.1212) to MLXINT. These changes have already been deployed to MLXBUILD
.\Start-MlxDeployment.ps1 -ReleaseName "Dec 2 Daily Build 1" -Cloud MLXINT -TargetSlot Production -Branch ReleaseDev -AsyncMode -RetryDelaySeconds 5 -EnableTranscripting -SmtpUserName "_MLXITE3Email" -SmtpUserPassword = "[some secret password]" -DeployerAdminAlias "mlxdevops" -SupportCC "psgmlxtest;mlxengc" -Redeploy "RDC.20151202.1212"
.EXAMPLE
Deploy from MLXMA Dev Branch to a cloud
.\Start-MlxDeployment.ps1 -ReleaseName "MLXMA BareBone" -Cloud MLXMADEV -TargetSlot Production -Branch Dev -RetryDelaySeconds 5 -EnlistmentRootPath "D:\mlxma3\dev" -DisableEmails -MaxRetries 2
.EXAMPLE
Build all solutions locally
.\Start-MlxDeployment.ps1 -ReleaseName "MLXMA BareBone" -Cloud MLXMADEV -TargetSlot Production -Branch Dev -RetryDelaySeconds 5 -EnlistmentRootPath "D:\mlxma3\dev" -DisableEmails -MaxRetries 2 -BuildOnly
#>

param( 
        [Parameter(Mandatory=$false)][string]$enlistmentRootPath = "C:\oxa-tools_autodeploy",
        [Parameter(Mandatory=$false)][ValidateSet("prod", "int", "bvt", "")][string]$Cloud="bvt",
        [Parameter(Mandatory=$false)][string]$BranchName = "oxa/devfic",
        [Parameter(Mandatory=$false)][ValidateSet("bootstrap", "upgrade", "swap", "")][string]$DeploymentType="upgrade",

        [Parameter(Mandatory=$true)][string]$AadWebClientId,    
        [Parameter(Mandatory=$true)][string]$AadTenantId,
        [Parameter(Mandatory=$true)][string]$TargetPath,

        [Parameter(Mandatory=$false)][string]$KeyVaultDeploymentArmTemplateFile="",
        [Parameter(Mandatory=$false)][string]$KeyVaultDeploymentParametersFile="",
        [Parameter(Mandatory=$false)][string]$FullDeploymentArmTemplateFile="",
        [Parameter(Mandatory=$false)][string]$FullDeploymentParametersFile="",

        # settings override file path
        [Parameter(Mandatory=$false)][string]$SettingsOverride,
        
        # deployment flow controls
        [Parameter(Mandatory=$false)][switch]$AsyncMode,
        [Parameter(Mandatory=$false)][string]$Resume,
        [Parameter(Mandatory=$false)][switch]$DisableTranscripting,

        # seconds delay between failure attempts/retries
        [Parameter(Mandatory=$false)][int]$RetryDelaySeconds = 30,
        [Parameter(Mandatory=$false)][int]$MaxRetries = 5,

        # during debugging, only notify admins
        [Parameter(Mandatory=$false)][switch]$NotifyOnlyAdmins,

        # adding support alias: Test Team, Leads, FTEs, etc
        [Parameter(Mandatory=$false)][string]$SupportCC = "",
        [Parameter(Mandatory=$false)][ValidateSet("CN=prod-cert", "CN=int-cert", "CN=bvt-cert")][string]$CertSubject = "CN=bvt-cert",
        [Parameter(Mandatory=$false)][string]$AzureSubscriptionName,
        [Parameter(Mandatory=$false)][string]$ResourceGroupName,
        [Parameter(Mandatory=$false)][string]$KeyVaultName,
    
        [Parameter(Mandatory=$false)][string]$Location="south central us"
     )

# determine current location of the script and make it current
$invocation = (Get-Variable MyInvocation).Value 
$currentPath = Split-Path $invocation.MyCommand.Path 
$rootPath = (Get-Item $currentPath).parent.FullName
set-location $currentPath;

# load supporting libraries
import-module "$($currentPath)\Common.ps1" -Force

# track our retry attempts
[int]$attempt = 0;

# we need to setup some environment variables for script-wide access
# save the branch early: we need it for build number generation
$env:Branch = $Branch;
$env:ClusterAdministratorEmailAddress = $ClusterAdministratorEmailAddress;
$env:DeploymentStartTime = Get-Date;
$env:rootPath = $EnlistmentRootPath;
$env:DisableEmails = $DisableEmails;
$env:DeployerAdminAlias = "v-nandu@microsoft.com";

# setup notifications
$env:NotifyOnlyAdmins = 0;
if ($NotifyOnlyAdmins)
{
    $env:NotifyOnlyAdmins = 1;
}

Log-Message "Setting AzureSubscriptionName and ResourceGroupName from Cloud..."
switch ($Cloud) {
    "prod" {
        $AzureSubscriptionName = "OXAPRODENVIRONMENT"
        $ResourceGroupName = "lexoxabvtc13"    
    }
    "int" {
        $AzureSubscriptionName = "OXAINTENVIRONMENT"
        $ResourceGroupName = "lexoxabvtc13"
    }
    "bvt" {
        $AzureSubscriptionName = "MLX DevOps"
        $ResourceGroupName = "oxatest001"        
    }
}

Log-Message "AzureSubscriptionName => $($AzureSubscriptionName)"
Log-Message "ResourceGroupName => $($ResourceGroupName)"

$KeyVaultName = Set-ScriptDefault -ScriptParamName "KeyVaultName" `
    -ScriptParamVal $KeyVaultName `
    -DefaultValue "$($ResourceGroupName)-kv"

$CertSubject = Set-ScriptDefault -ScriptParamName "CertSubject" `
    -ScriptParamVal $CertSubject `
    -DefaultValue "CN=$($Cloud)-cert"

# Login
$CertificateThumbprint = Get-LocalCertificate -CertSubject $CertSubject
Login-AzureRmAccount -ServicePrincipal -CertificateThumbprint $CertificateThumbprint -ApplicationId $AadWebClientId -TenantId $AadTenantId
Set-AzureSubscription -SubscriptionName $AzureSubscriptionName | Out-Null

Log-Message "Getting Deployment Parameters from KeyVault..."
$KeyVaultKeys = Get-KeyVaultKeyNames -TargetPath "$($rootPath)/config/keyvault-params.json"

$DeployScriptPath = "$($currentPath)/Deploy-OxaStamp.ps1"
$KeyVaultParameters = @{}

foreach ($key in $KeyVaultKeys)
{
    $secretVal = Get-AzureKeyVaultSecret -VaultName $KeyVaultName -Name $key
    $KeyVaultParameters[$key] = $secretVal.SecretValueText
}

$ExtraParameters = @{
    "AutoDeploy" = $true;
    "AadWebClientAppKey" = "key";
    "AadWebClientId" = $AadWebClientId;
    "AadTenantId" = $AadTenantId;
    "AzureSubscriptionName" = $AzureSubscriptionName;
    "ResourceGroupName" = $ResourceGroupName;
    "Location" = $Location;
    "TargetPath" = $TargetPath;
    "BranchName" = $BranchName;
    "Cloud" = $Cloud;
    "DeploymentType" = $DeploymentType;    
}

Log-Message "Finished building deployment command: "
Write-Host $DeployScriptPath @ExtraParameters @KeyVaultParameters


Log-Message "Starting Deployment..."
Log-Message "======================"

# start the deployment 
while ($attempt -lt $maxRetries)
{
    try
    {
        # get current settings & save it for any downstream dependencies
        $attempt++;
    
        # we are still referencing the existing manifest files at \Azure\Manifests\*
        if ($attempt -gt 1)
        {
            Log-Message -Message "Retrying deployment - Attempt $($attempt) of $($MaxRetries) " -Context "Deployment Root";
        }

        & $DeployScriptPath @KeyVaultParameters @ExtraParameters        
      
        # We will assume deployment is completed at this step
        break;
     }
    catch
    {
        $errorDump = Capture-ErrorStack -GetOutput;

        $messageSubject = "Deployment completed to '$($Cloud)' Cloud from '$($BranchName)' Branch :: Auto-Retry - Attempt $($attempt)";
        Log-Message -Message $message -Context "Deployment Root";

        # send the failure notification
        if ($env:DisableEmails -eq $false)
        {
            Send-Message -Recipients $KeyVaultParameters.ClusterAdministratorEmailAddress -messageBody $errorDump -subject $messageSubject -smtpUserName $KeyVaultParameters.SmtpAuthenticationUser -smtpUserPassword $KeyVaultParameters.SmtpAuthenticationUserPassword -NonHtml;
        }

        # while we respect the max retries, we still must throw a fit when we exceed this limit
        if($attempt -eq $maxRetries)
        {
            throw "Deployment Failed: $($Error[0].Exception.Message)";
        }
    }
}

$activityMessage = "The cloud has been successfully updated with latest bits from oxa.";
$messageSubject = "Deployment completed to '$($Cloud)' Cloud from '$($BranchName)' Branch :: Auto-Retry - Attempt $($attempt)";
Send-Message -Recipients $KeyVaultParameters.ClusterAdministratorEmailAddress -messageBody $activityMessage -subject $messageSubject -smtpUserName $KeyVaultParameters.SmtpAuthenticationUser -smtpUserPassword $KeyVaultParameters.SmtpAuthenticationUserPassword -NonHtml;
