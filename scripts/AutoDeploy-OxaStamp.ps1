<#
.SYNOPSIS
Handle automatic, continuous deployments for OXA Stamp environments

#>

Param(    
    [Parameter(Mandatory=$true)][string]$AadWebClientId,
    [Parameter(Mandatory=$true)][string]$AadWebClientAppKey,
    [Parameter(Mandatory=$true)][string]$AadTenantId,
    [Parameter(Mandatory=$true)][string]$TargetPath,

    [Parameter(Mandatory=$false)][string]$AzureSubscriptionName,
    [Parameter(Mandatory=$false)][string]$ResourceGroupName,
    [Parameter(Mandatory=$false)][string]$KeyVaultName,

    [Parameter(Mandatory=$false)][string]$Location="south central us",
    
    [Parameter(Mandatory=$false)][string]$BranchName="oxa/devfic",
    [Parameter(Mandatory=$false)][ValidateSet("bootstrap", "upgrade", "swap")][string]$DeploymentType="upgrade",    
    [Parameter(Mandatory=$false)][ValidateSet("prod", "int", "bvt")][string]$Cloud="bvt"
)

#################################
# ENTRY POINT
#################################

$invocation = (Get-Variable MyInvocation).Value 
$currentPath = Split-Path $invocation.MyCommand.Path 
Import-Module "$($currentPath)/Common.ps1" -Force

Log-Message "Collecting all script parameters..."
$CurrentParameters = @{}
foreach($h in $MyInvocation.MyCommand.Parameters.GetEnumerator()) {
    try {
        $key = $h.Key
        $val = Get-Variable -Name $key -ErrorAction Stop | Select-Object -ExpandProperty Value -ErrorAction Stop
        if (([String]::IsNullOrEmpty($val) -and (!$PSBoundParameters.ContainsKey($key)))) {
            throw "A blank value that wasn't supplied by the user."
        }
        Log-Message "$key => '$val'"
        $CurrentParameters[$key] = $val
    } catch {}
}


Log-Message "Setting AzureSubscriptionName and ResourceGroupName from Cloud..."
switch ($cloud) {
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
        $ResourceGroupName = "lexoxabvtc13"
    }
}

Log-Message "AzureSubscriptionName => $($AzureSubscriptionName)"
Log-Message "ResourceGroupName => $($ResourceGroupName)"

$KeyVaultName = 'BVTKeyVault'
#  Set-ScriptDefault -ScriptParamName "KeyVaultName" `
#                 -ScriptParamVal $KeyVaultName `
#                 -DefaultValue "$($ResourceGroupName)-kv"

# Login
$clientSecret = ConvertTo-SecureString -String $AadWebClientAppKey -AsPlainText -Force
$aadCredential = New-Object System.Management.Automation.PSCredential($AadWebClientId, $clientSecret)
Login-AzureRmAccount -SubscriptionName $AzureSubscriptionName #-ServicePrincipal -TenantId $AadTenantId -SubscriptionName $AzureSubscriptionName -Credential $aadCredential -ErrorAction Stop
# Login-AzureRmAccount -CertificateThumbprint
Set-AzureSubscription -SubscriptionName $AzureSubscriptionName | Out-Null

# $json = Get-Content -Raw "$($currentPath)/params.json" | Out-String | ConvertFrom-Json

# $json.psobject.properties | ForEach-Object { 
#     # Create a new secret
#     $secretvalue = ConvertTo-SecureString $_.Value -AsPlainText -Force

#     # Store the secret in Azure Key Vault
#     Set-AzureKeyVaultSecret -VaultName $keyVaultName -Name $_.Name -SecretValue $secretvalue
    
#     Write-Host $_.Name
# }

# $json.psobject.properties | ForEach-Object { 
#     # Get the secret text
#     $secretVal = Get-AzureKeyVaultSecret -VaultName $keyVaultName -Name $_.Name
#     # Write-Host 'Secret is: ' $secretVal.SecretValueText

# }


# ====================================================

#New-SelfSignedCertificate -CertStoreLocation cert:\localmachine\my -Provider "Microsoft Enhanced RSA and AES Cryptographic Provider" `
#                          -Subject "cn=mydemokvcert" -KeyDescription "Used to access Key Vault" `
#                          -NotBefore (Get-Date).AddDays(-1) -NotAfter (Get-Date).AddYears(2)

#   PSParentPath: Microsoft.PowerShell.Security\Certificate::LocalMachine\my
#
#Thumbprint                                Subject
#----------                                -------
# C6XXXXXX53E8DXXXX2B217F6CD0A4A0F9E5390A5  CN=mydemokvcert
#

$pwd = ConvertTo-SecureString -String "pwd" -Force -AsPlainText

# Export cert to PFX - uploaded to Azure App Service

#Export-PfxCertificate -cert cert:\localMachine\my\83EFCBA831FB859268201B39F24BAB33E21A8AE8 `
#                      -FilePath keyvaultaccess03.pfx -Password $pwd

#    Directory: C:\WINDOWS\system32
#
#Mode                LastWriteTime         Length Name
#----                -------------         ------ ----
#-a----       14/11/2016     16:06           2565 keyvaultaccess03.pfx
#

# Export Certificate to import into the Service Principal
#Export-Certificate -Cert cert:\localMachine\my\83EFCBA831FB859268201B39F24BAB33E21A8AE8 `
#                   -FilePath keyvaultaccess03.crt


#####
# Prepare Cert for use with Service Principal
#####

Log-Message "Creating Certificate ============================================="

$x509 = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
$x509.Import("C:\Users\KAKH\Documents\WindowsPowershell\Scripts\keyvaultaccess03.crt")
$credValue = [System.Convert]::ToBase64String($x509.GetRawCertData())
# should match our certificate entries above.
$validFrom = [System.DateTime]::Now.AddDays(-1)
$validTo = [System.DateTime]::Now.AddYears(2)


Log-Message "Certificate Created Successfully ============================================="

# $credValue comes from the previous script and contains the X509 cert we wish to use.
# $validFrom comes from the previous script and is the validity start date for the cert.
# $validTo comes from the previous script and is the validity end data for the cert.
Log-Message "CERTIFICATE VALUE: $($credValue)"

$adapp = New-AzureRmADApplication -DisplayName "OxaKeyVaultTestApp2" -HomePage "https://openedx.microsoft.com" `
            -IdentifierUris "https://openedx.t.microsoft.com" -CertValue $credValue -Debug


# $adapp = New-AzureRmADAppCredential -ApplicationId "a025b047-15bf-43fc-bc90-55c44ab1763b" -CertValue $credValue -Debug


Write-Host $adapp

$principal = New-AzureRmADServicePrincipal -ApplicationId $adapp.ApplicationId

Set-AzureRmKeyVaultAccessPolicy -VaultName $KeyVaultName `
    -ServicePrincipalName $adapp.ApplicationId.Guid -PermissionsToSecrets all `
    -ResourceGroupName $ResourceGroupName

Log-Message "Finished Cert Management ============================================="
# ====================================================

$KeyVaultKeys = @(
    "ClusterAdministratorEmailAddress",
    "SmtpServer",
    "SmtpServerPort",
    "SmtpAuthenticationUser",
    "SmtpAuthenticationUserPassword",
    "EdxAppSuperUserName",
    "EdxAppSuperUserPassword",
    "EdxAppSuperUserEmail",
    "PlatformName",
    "PlatformEmailAddress"
)

$DeployScriptPath = "$($currentPath)/Deploy-OxaStamp.ps1"
$KeyVaultParameters = @{}

foreach ($key in $KeyVaultKeys)
{
    $secretVal = Get-AzureKeyVaultSecret -VaultName $KeyVaultName -Name $key
    $KeyVaultParameters[$key] = $secretVal.SecretValueText
}

$KeyVaultParameters["AzureSubscriptionName"] = $AzureSubscriptionName
$KeyVaultParameters["ResourceGroupName"] = $ResourceGroupName

Write-Host $DeployScriptPath
Write-Host @KeyVaultParameters

Write-Host @CurrentParameters

# & $DeployScriptPath @CurrentParameters @KeyVaultParameters