<#
.SYNOPSIS
Handle automatic, continuous deployments for OXA Stamp environments

#>

Param(    
    [Parameter(Mandatory=$true)][string]$AadWebClientId,    
    [Parameter(Mandatory=$true)][string]$AadTenantId,
    [Parameter(Mandatory=$true)][string]$TargetPath,

    [Parameter(Mandatory=$false)][string]$AzureSubscriptionName,
    [Parameter(Mandatory=$false)][string]$ResourceGroupName,
    [Parameter(Mandatory=$false)][string]$KeyVaultName,

    [Parameter(Mandatory=$false)][string]$Location="south central us",
    
    [Parameter(Mandatory=$false)][string]$BranchName="oxa/devfic",
    [Parameter(Mandatory=$false)][ValidateSet("bootstrap", "upgrade", "swap")][string]$DeploymentType="upgrade",    
    [Parameter(Mandatory=$false)][ValidateSet("prod", "int", "bvt")][string]$Cloud="bvt",
    [Parameter(Mandatory=$false)][ValidateSet("CN=prod-cert", "CN=int-cert", "CN=bvt-cert")][string]$CertSubject = "CN=bvt-cert"
)

#################################
# ENTRY POINT
#################################

$invocation = (Get-Variable MyInvocation).Value 
$currentPath = Split-Path $invocation.MyCommand.Path
$rootPath = (Get-Item $currentPath).parent.FullName
Import-Module "$($currentPath)/Common.ps1" -Force

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
        $AzureSubscriptionName = "OXABVTENVIRONMENT"
        $ResourceGroupName = "lexoxabvtc14"        
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
Write-Host $CertificateThumbprint
Login-AzureRmAccount -ServicePrincipal -CertificateThumbprint $CertificateThumbprint -ApplicationId $AadWebClientId -TenantId $AadTenantId
Set-AzureSubscription -SubscriptionName $AzureSubscriptionName | Out-Null

$KeyVaultKeys = Get-KeyVaultKeyNames -TargetPath "$($rootPath)/config/keyvault-params.json"

$DeployScriptPath = "$($currentPath)/Deploy-OxaStamp.ps1"
$KeyVaultParameters = @{}

foreach ($key in $KeyVaultKeys)
{
    $secretVal = Get-AzureKeyVaultSecret -VaultName $KeyVaultName -Name $key
    $KeyVaultParameters[$key] = $secretVal.SecretValueText
}

Log-Message "Collecting all script parameters..."
$CurrentParameters = @{}
foreach($h in $MyInvocation.MyCommand.Parameters.GetEnumerator()) {
    try {
        $key = $h.Key
        $val = Get-Variable -Name $key -ErrorAction Stop | Select-Object -ExpandProperty Value -ErrorAction Stop
        if (([String]::IsNullOrEmpty($val) -and (!$PSBoundParameters.ContainsKey($key)))) {
            throw "A blank value that wasn't supplied by the user."
        }
        if (('CertSubject', 'KeyVaultName') -notcontains $key) 
        {
            Log-Message "$key => '$val'"            
            $CurrentParameters[$key] = $val
        }        
    } catch {}
}

$ExtraParameters = @{
    "AutoDeploy" = $true;
    "AadWebClientAppKey" = "key";
}

Write-Host $DeployScriptPath
Write-Host @KeyVaultParameters
Write-Host @CurrentParameters
Write-Host @ExtraParameters

& $DeployScriptPath @CurrentParameters @KeyVaultParameters @ExtraParameters
