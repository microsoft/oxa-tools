<#
.SYNOPSIS
Deploy the OXA Stamp - Enterprise-Grade OpenEdx on Azure infrastructure that supports High Availability and Scalability

.DESCRIPTION
This script deploys the OXA Stamp. It supports a clean infrastructure bootstrap and incremental updates

This script assumes you have already have an AzureRM authenticated session

.PARAMETER AzureSubscriptionName
Name of the azure subscription to use.

.PARAMETER ResourceGroupName
Name of the azure resource group to deploy.

.PARAMETER DeploymentType
Type of deployment being executed. 

The supported Types are:
1. bootstrap:   a first time installation.
2. upgrade:     any installation following bootstrap
3. swap:        switching live traffic from one installation to an upgraded one
4. cleanup:     deleting all resources associated with an older installation

.PARAMETER Cloud
Name of the cloud being deployed to.

The supported cloud types are:
1. prod:    production environment
2. int:     integration envirionment (test)
3. bvt:     build-verification-test environment (test)

.PARAMETER KeyVaultDeploymentSettingsFile
Path to deployment settings to upload to keyvault

This parameter is optional. When set, the deployment populates keyvault with the specified deployment-related settings/secrets.
The file should be a json file with key:value pairs representing setting name and setting value

.PARAMETER MaxRetries
Maximum number of retries this call makes before failing. This defaults to 3.

.PARAMETER AadWebClientId
The azure active directory web application Id for authentication.

.PARAMETER AadWebClientAppKey
The azure active directory web application key for authentication.

.PARAMETER AadTenantId
The azure active directory tenant id for authentication.

.PARAMETER AutoDeploy
Switch indicating whether or not AutoDeploy mode is enabled
#>
Param( 
        [Parameter(Mandatory=$true)][string]$AzureSubscriptionName,
        [Parameter(Mandatory=$true)][string]$ResourceGroupName,
        [Parameter(Mandatory=$false)][ValidateSet("bootstrap", "upgrade", "swap", "cleanup")][string]$DeploymentType="upgrade",
        [Parameter(Mandatory=$false)][ValidateSet("prod", "int", "bvt")][string]$Cloud="bvt",
        [Parameter(Mandatory=$false)][string]$KeyVaultDeploymentSettingsFile="",
        [Parameter(Mandatory=$false)][int]$MaxRetries=3,

        [Parameter(Mandatory=$true)][string]$AadWebClientId,
        [Parameter(Mandatory=$true)][string]$AadTenantId,
        [Parameter(Mandatory=$false)][string]$AadWebClientAppKey="",

        [Parameter(Mandatory=$false)][switch]$AutoDeploy
     )


$invocation = (Get-Variable MyInvocation).Value 
$currentPath = Split-Path $invocation.MyCommand.Path
Import-Module "$($currentPath)\Common.ps1" -Force

# get a list of required deployment parameter (as specified in the main deployment script)
$mainDeploymentScript = "$($currentPath)\Deploy-OxaStamp.ps1"
[array]$requiredDeploymentParameters = Get-ScriptParameters -ScriptFile $mainDeploymentScript -Required
[array]$deploymentParameters = Get-ScriptParameters -ScriptFile $mainDeploymentScript


# initialize key variables
$keyVaultName = "$($ResourceGroupName)-kv"
$authenticationCertificateSubject = "CN=OpenedX On Azure - $($Cloud.ToUpper()) Deployment Certificate"

#################################################
# 1. Authenticate using web app or certificate
#################################################

Login-OxaAccount -AzureSubscriptionName $AzureSubscriptionName `
                 -AadWebClientId $AadWebClientId `
                 -AadWebClientAppKey $AadWebClientAppKey `
                 -AadTenantId $AadTenantId `
                 -AuthenticationCertificateSubject $authenticationCertificateSubject `
                 -ResourceGroupName $ResourceGroupName `
                 -MaxRetries $MaxRetries

#################################################
# 2. Populate Key Vault Deployment Settings
#################################################
if ($KeyVaultDeploymentSettingsFile)
{
    if ((Test-Path -Path $KeyVaultDeploymentSettingsFile) -eq $false)
    {
        throw "The specified keyvault deployment settings file was not found: $($KeyVaultDeploymentSettingsFile)"
    }

    # process and upload the settings
    Set-KeyVaultSecretsFromFile -ResourceGroupName $ResourceGroupName `
                                -KeyVaultName $keyVaultName `
                                -SettingsFile $KeyVaultDeploymentSettingsFile `
                                -Prefix "DeploymentParamsxxx" `
                                -MaxRetries $MaxRetries
}

#################################################
# 3. Fetch Deployment Settings from KeyVault
#################################################

[hashtable]$keyVaultDeploymentParameters = Get-OxaDeploymentKeyVaultSettings -ResourceGroupName $ResourceGroupName -MaxRetries $MaxRetries

#apply overrides
$keyVaultDeploymentParameters['DeploymentType'] = $DeploymentType
$keyVaultDeploymentParameters['AzureSubscriptionName'] = $AzureSubscriptionName
$keyVaultDeploymentParameters['ResourceGroupName'] = $ResourceGroupName
$keyVaultDeploymentParameters['AuthenticationCertificateSubject'] = $authenticationCertificateSubject
$keyVaultDeploymentParameters['AutoDeploy'] = $AutoDeploy

#################################################
# 4. Invoke Deploy-OxaStamp.ps1 
#################################################

# make sure we at least have the required parameters
if ($keyVaultDeploymentParameters.Keys.Count -lt $requiredDeploymentParameters.Count)
{
    throw "Invalid number of parameters specified. $($mainDeploymentScript) requires $($requiredDeploymentParameters.Count) parameters. $($keyVaultDeploymentParameters.Keys.Count) parameters retrieved from keyvault."
}

$keyVaultDeploymentParameters = Set-DeploymentParameterValues -AvailableParameters $keyVaultDeploymentParameters -ScriptParameters $deploymentParameters

try 
{
    $autoDeployPhases = @{"bootstrap"=0; "upgrade"=1; "swap"=2; "cleanup"=3}

    # seed the deployment type
    $deploymentType = $keyVaultDeploymentParameters['DeploymentType']
    [int]$deploymentPosition = $autoDeployPhases[$deploymentType]
    $terminalDeploymentPosition = 3

    while ($deploymentPosition -le $terminalDeploymentPosition) 
    {
        $deploymentType = $autoDeployPhases.Keys | Where-Object { [int]$autoDeployPhases[ $_ ] -eq $deploymentPosition }
        $keyVaultDeploymentParameters['DeploymentType'] = $deploymentType

        Log-Message "Starting '$($deploymentType)($deploymentPosition)' deployment"

        # trigger the deployment
        & $mainDeploymentScript @keyVaultDeploymentParameters

        if ($deploymentPosition -eq 0 -or !$AutoDeploy)
        {
            # bootstrap is also terminal
            # non-auto deploy is also terminal
            break;
        }

        # progress the deployment
        $deploymentPosition+=1
    }
}
catch 
{
    # TODO
    # The error has already been displayed by the calling script. 
    # If there are special handling based on error thrown, 
    # catch and handle here and manage retries (if applicable)

    Capture-ErrorStack
    exit
}
