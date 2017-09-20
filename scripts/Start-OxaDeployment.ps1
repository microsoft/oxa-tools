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
         [Parameter(Mandatory=$false)][string]$enlistmentRootPath = "C:\oxa-tools_autodeploy"
        ,[Parameter(Mandatory=$false)][ValidateSet("prod", "int", "bvt", "")][string]$Cloud="bvt"
        ,[Parameter(Mandatory=$false)][string]$BranchName = "oxa/devfic"
        ,[Parameter(Mandatory=$false)][ValidateSet("bootstrap", "upgrade", "swap", "")][string]$DeploymentType="upgrade"

        # settings override file path
        ,[Parameter(Mandatory=$false)][string]$SettingsOverride
        
        # deployment flow controls
        ,[Parameter(Mandatory=$false)][switch]$AsyncMode 
        ,[Parameter(Mandatory=$false)][string]$Resume
        ,[Parameter(Mandatory=$false)][switch]$DisableTranscripting

          
        #smtp support. TODO: programatically access the SMTP username/password
        ,[Parameter(Mandatory=$false)][string]$SmtpAuthenticationUser
        ,[Parameter(Mandatory=$false)][string]$SmtpAuthenticationUserPassword
        ,[Parameter(Mandatory=$false)][string]$ClusterAdministratorEmailAddress = "v-nandu@microsoft.com"

        # seconds delay between failure attempts/retries
        ,[Parameter(Mandatory=$false)][int]$RetryDelaySeconds = 30
        ,[Parameter(Mandatory=$false)][int]$MaxRetries = 5

        # during debugging, only notify admins
        ,[Parameter(Mandatory=$false)][switch]$NotifyOnlyAdmins

        # adding support alias: Test Team, Leads, FTEs, etc
        ,[Parameter(Mandatory=$false)][string]$SupportCC = ""

     )

# determine current location of the script and make it current
$invocation = (Get-Variable MyInvocation).Value 
$currentPath = Split-Path $invocation.MyCommand.Path 
set-location $currentPath;

# load supporting libraries
import-module "$($enlistmentRootPath)\scripts\Common.ps1" -Force

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

# start the deployment 
while ($attempt -lt $maxRetries)
{
    try
    {
        # get current settings & save it for any downstream dependencies
        $settings = Get-OxaRunnerSettings -Cloud $Cloud -SettingsOverride $SettingsOverride;
        $env:Settings = $settings;
        
        #Get-LatestChanges -BranchName $Settings.BranchName -Cloud $Settings.Cloud;
        $attempt++;
    
        # we are still referencing the existing manifest files at \Azure\Manifests\*
        if ($attempt -gt 1)
        {
            Log-Message -Message "Retrying deployment - Attempt $($attempt) of $($MaxRetries) " -Context "Deployment Root";

        }
        
          &"$($($enlistmentRootPath))\scripts\Deploy-OxaStamp.ps1" -AzureSubscriptionName $Settings.AzureSubscriptionName -ResourceGroupName $Settings.ResourceGroupName -Location $Settings.Location -TargetPath "C:\oxa-tools_autodeploy\config\stamp\default\" `
          -AadWebClientId "a025b047-15bf-43fc-bc90-55c44ab1763b" -AadWebClientAppKey "YOdC6eFXYrehFKSLysTl9KGg8A5/CypY28+gnXv+ib0=" -AadTenantId "72f988bf-86f1-41af-91ab-2d7cd011db47" `
          -KeyVaultDeploymentArmTemplateFile "C:\oxa-tools_autodeploy\templates\stamp\stamp-keyvault.json" -FullDeploymentParametersFile "C:\oxa-tools_autodeploy\config\stamp\default\parameters.json" `
          -FullDeploymentArmTemplateFile "C:\oxa-tools_autodeploy\templates\stamp\stamp-v3.json" -ClusterAdministratorEmailAddress $Settings.ClusterAdministratorEmailAddress -SmtpServer $Settings.SmtpServer  `
          -SmtpServerPort $Settings.SmtpServerPort -SmtpAuthenticationUser $Settings.SmtpUserName -SmtpAuthenticationUserPassword $Settings.SmtpUserPassword -PlatformName $Settings.PlatformName -PlatformEmailAddress $Settings.PlatformEmailAddress `
          -AzureCliVersion $Settings.AzureCliVersion -DeploymentType $DeploymentType -BranchName $Settings.BranchName -Cloud $Settings.Cloud
      
        #We will assume deployment is completed at this step
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
            #Send-Message -recipient $ClusterAdministratorEmailAddress -messageBody $errorDump -subject $messageSubject -smtpUserPassword $SmtpAuthenticationUserPassword -smtpUserName $SmtpAuthenticationUser -NonHtml;
            Send-Message -Recipients $ClusterAdministratorEmailAddress -messageBody $errorDump -subject $messageSubject -smtpUserPassword $Settings.SmtpUserPassword -smtpUserName $Settings.SmtpUserName -NonHtml;
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
Send-Message -Recipients $ClusterAdministratorEmailAddress -messageBody $activityMessage -subject $messageSubject -smtpUserPassword $Settings.SmtpUserPassword -smtpUserName $Settings.SmtpUserName -NonHtml;