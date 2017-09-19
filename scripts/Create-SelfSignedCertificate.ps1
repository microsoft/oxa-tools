Param (
    
    # Use to set scope to resource group. If no value is provided, scope is set to subscription.
    [Parameter(Mandatory=$false)]
    [String] $ResourceGroup,

    # Use to set subscription. If no value is provided, default subscription is used. 
    [Parameter(Mandatory=$false)]
    [String] $SubscriptionId,

    # ApplicationId of AzureAD App to replace credentials of.
    [Parameter(Mandatory=$true)]
    [String] $ApplicationId
    )

    Login-AzureRmAccount
    Import-Module AzureRM.Resources

    if ($SubscriptionId -eq "") 
    {
        $SubscriptionId = (Get-AzureRmContext).Subscription.Id
    }
    else
    {
        Set-AzureRmContext -SubscriptionId $SubscriptionId
    }

    if ($ResourceGroup -eq "")
    {
        $Scope = "/subscriptions/" + $SubscriptionId
    }
    else
    {
        $Scope = (Get-AzureRmResourceGroup -Name $ResourceGroup -ErrorAction Stop).ResourceId
    }

    $cert = New-SelfSignedCertificate -CertStoreLocation "cert:\CurrentUser\My" -Subject "CN=bvt-cert" -KeySpec KeyExchange
    $keyValue = [System.Convert]::ToBase64String($cert.GetRawCertData())


    # =================================
    # Remove Credentials for ApplicationId
    # Add New Cert credentials for ApplicationId
    # =================================
    

    # $ServicePrincipal = New-AzureRMADServicePrincipal -DisplayName $ApplicationDisplayName -CertValue $keyValue -EndDate $cert.NotAfter -StartDate $cert.NotBefore -Debug
    # Get-AzureRmADServicePrincipal -ObjectId $ServicePrincipal.Id 

    # $NewRole = $null
    # $Retries = 0;
    # While ($NewRole -eq $null -and $Retries -le 6)
    # {
    #     # Sleep here for a few seconds to allow the service principal application to become active (should only take a couple of seconds normally)
    #     Sleep 15
    #     New-AzureRMRoleAssignment -RoleDefinitionName Contributor -ServicePrincipalName $ServicePrincipal.ApplicationId -Scope $Scope | Write-Verbose -ErrorAction SilentlyContinue
    #     $NewRole = Get-AzureRMRoleAssignment -ObjectId $ServicePrincipal.Id -ErrorAction SilentlyContinue
    #     $Retries++;
    # }