##  Function: Log-Message
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
            [Parameter(Mandatory=$false)][switch]$SkipTimestamp,
            [Parameter(Mandatory=$false)][switch]$ClearLineAfter
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

    # if necessary, prepend a blank line
    if ($ClearLineAfter -eq $true)
    {
        $logTime += [System.Environment]::NewLine
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

## Function: Capture-ErrorStack
##
## Purpose: 
##    Capture an exception error stack and return a formatted output 
##
## Input: 
##   ForceStop       stop script execution on error
##   GetOutput       indicator of whether or not to return the error output or print it to console
##
## Output:
##   formatted output
##
function Capture-ErrorStack
{
    param(
            [Parameter(Mandatory=$false)][switch]$ForceStop,
            [Parameter(Mandatory=$false)][switch]$GetOutput
         )

    if ($global:Error.Count -eq 0)
    {
        return
    }


    [int]$decoratorLength = 75;

    $lastError = $global:Error[0];
    $message1 = "`r`nError [$($lastError.Exception.GetType().FullName)]:`r`n`r`n"
    $message1 += "$($lastError.Exception.Message)";

    $message2 = $lastError | Format-List * -Force | Out-String;

    $errorMessage = "`r`n`r`n";
    $errorMessage += "#" * $decoratorLength;
    $errorMessage += "`r`nERROR ENCOUNTERED`r`n";
    $errorMessage += "#" * $decoratorLength;
    $errorMessage += "`r`n$($message1)";

    if ($message2 -ne "")
    {
        $errorMessage += "$($message2)";
    }

    if ($ForceStop)
    {
        Log-Message -Message $errorMessage -LogType Error;
    }
    else
    {
         Log-Message -Message $errorMessage;
    }

    if ($GetOutput)
    {
        return $errorMessage;
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

    Log-Message "Parameters File: $($ParametersFile)" -ClearLine;
    $parametersContent = gc $ParametersFile -Encoding UTF8
    foreach($key in $ReplacementHash.Keys)
    {
        # todo: track cases where search key is not found and provide notification that replacement was skipped
        Log-Message "Replacing '{$key}' with '$($ReplacementHash[ $key ])'"
        $parametersContent = $parametersContent -ireplace "{$key}", $ReplacementHash[ $key ];
    }

    # save the output
    [IO.File]::WriteAllText($tempParametersFile, $parametersContent);

    return $tempParametersFile
}

##  Function: Parse-Json
##
##  Purpose: Parse a json string and return its json object
##
##  Input: 
##      JsonString     - the json string
##
##  Ouput: the corresponding json object
##
function Parse-Json
{
    param(
            [Parameter(Mandatory=$true)][string]$jsonString
         )

    $jsonObject = $null;

    try
    {
        $jsonObject = ConvertFrom-Json -InputObject $jsonString;
    }
    catch
    {
        [string]$exception = $error[0].ToString()
        if (!$exception.contains("Conversion from JSON failed with error"))
        {
            # this is not a case where no data is returned or the json string is not valid
            throw
        }
    }

    return $jsonObject
}

##  Function: Process-SecretName
##
##  Purpose: Encode or Decode a keyvault secret name
##
##  Input: 
##      SecretName     - the secret name
##      Prefix         - the secret name prefix
##      Operation      - the operation to perform (Encode or Decode)
##      ProcessPrefix  - indicator for processing or not processing the prefix
##
##  Ouput: the secret name
function Process-SecretName
{
    param(
            [Parameter(Mandatory=$true)][string]$SecretName,
            [Parameter(Mandatory=$false)][string]$Prefix="",
            [Parameter(Mandatory=$true)][ValidateSet("Decode","Encode")][string]$Operation,
            [Parameter(Mandatory=$false)][switch]$ProcessPrefix
         )

    
    # Keyvault secret names are limited to alpha numeric values only
    # therefore, we have to perform some string replacements to ensure that we can setup the required secrets/keys
    [hashtable]$replacements = @{ "_" = "zzz";  "." = "yyy";}

    if ($Operation -eq "Encode")
    { 
        # perform the string replacements
        foreach ($key in $replacements.Keys)
        {
            $secretName = $secretName.replace($key, $replacements[$key]);
        }

        # add the configuration name prefix
        if ($ProcessPrefix -eq $true)
        {
            $secretName = "$($Prefix)$($secretName)"
        }
    }
    elseif ($Operation -eq "Decode")
    {
        # remove the configuration name prefix
        if ($ProcessPrefix -eq $false)
        {
            $secretName = $secretName.Replace($Prefix, "");
        }

        # reverse the string replacements
        foreach($key in $replacements.Keys)
        {
            $secretName = $secretName.replace($replacements[$key], $key);
        }
    }

    return $secretName;
}

## Function: Set-AzureSubscriptionContext
##
## Purpose: 
##   Set the cli context to the appropriate azure subscription after login
##
## Input: 
##   AzureSubscriptionId      the azure subscription id to set as current
##   IsCli2                   indicator of whether or not azure cli 2.0 is used
##
## Output:
##   nothing
##
function Set-AzureSubscriptionContext
{
    param(
            [Parameter(Mandatory=$true)][string]$AzureSubscriptionId,
            [Parameter(Mandatory=$false)][boolean]$IsCli2=$false
         )

    Log-Message "Setting execution context to the '$($AzureSubscriptionId)' azure subscription"

    if ($IsCli2)
    {
        $results = az account set --subscription $AzureSubscriptionId --output json | out-string
        if ($results.Length -gt 0)
        {
            throw "Could not set execution context to the '$($AzureSubscriptionId)' azure subscription"
        }
    }
    else
    {
        $results = azure account set  $AzureSubscriptionId  -vv --json | Out-String
        if (!$results.Contains("account set command OK"))
        {
            throw "Could not set execution context to the '$($AzureSubscriptionId)' azure subscription"
        }
    }
}

## Function: Authenticate-AzureRmUser
##
## Purpose: 
##    Authenticate the AAD user that will interact with Key Vault
##
## Input: 
##   AadWebClientId           the azure active directory web application client id
##   AadWebClientAppKey       the azure active directory web application key
##   AadTenantId              the azure active directory tenant id
##   IsCli2                   indicator of whether or not azure cli 2.0 is used
##
## Output:
##   nothing
##
function Authenticate-AzureRmUser
{
    param(
            [Parameter(Mandatory=$true)][string]$AadWebClientId,
            [Parameter(Mandatory=$true)][string]$AadWebClientAppKey,
            [Parameter(Mandatory=$true)][string]$AadTenantId,
            [Parameter(Mandatory=$false)][boolean]$IsCli2=$false
         )

    Log-Message "Logging in as service principal for '$($AadTenantId)'"
    if ($IsCli2)
    {
        $results = az login -u $AadWebClientId --service-principal --tenant $AadTenantId -p $AadWebClientAppKey --output json | Out-String
        if ($results.Contains("error"))
        {
            throw "Login failed"
        }
    }
    else
    {
        $results = azure login -u $AadWebClientId --service-principal --tenant $AadTenantId -p $AadWebClientAppKey -vv --json | Out-String
        if (!$results.Contains("login command OK"))
        {
            throw "Login failed"
        }
    }
}

## Function: Create-StorageContainer
##
## Purpose: 
##    Create a container in the specified storage account
##
## Input: 
##   StorageAccountName       name of the storage account
##   StorageAccountKey        access key for the specified storage account
##   StorageContainerName     name of the container to create within the specified storage account
##
## Output:
##   nothing
##
function Create-StorageContainer
{
    param(
            [Parameter(Mandatory=$true)][string]$StorageAccountName,
            [Parameter(Mandatory=$true)][string]$StorageAccountKey,
            [Parameter(Mandatory=$true)][string]$StorageContainerName
         )

    # get a storage context
    $storageContext = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey
    New-AzureStorageContainer -Name $StorageContainerName -Context $storageContext
}

<#
.SYNOPSIS
Executes a wrapped azure command.

.DESCRIPTION
Executes a wrapped azure command.

.PARAMETER InputParameters
Hashtable of parameters for the azure command.

.PARAMETER Quiet
Indicator of whether the underlying azure command will run in quiet mode or not.

.OUTPUTS
Object. Start-AzureCommand returns the response of the azure cmdlet.
#>
function Start-AzureCommand
{
    param( 
            [Parameter(Mandatory=$true)][hashtable]$InputParameters,
            [Parameter(Mandatory=$false)][switch]$Quiet
         )

    # we will make one generic call for every wrapped Azure Cmdlet
    # With that approach, we unify the call pattern, retries & error handling
    # special error handling will still be the responsibility of the caller

    # the object we will return
    $response = $null;

    # we support individual function using custom maximum retries
    # right now, they are not all enabled (but wired to do so)
    [int]$MaxRetries = 3;
    if ($InputParameters.ContainsKey("MaxRetries"))
    {
        try
        {
            $MaxRetries = [int]$InputParameters['MaxRetries'];
        }
        catch{ }
    }

    # check the expected exceptions
    if ($InputParameters.ContainsKey('ExpectedException') -eq $false)
    {
        $InputParameters['ExpectedException'] = "";
    }

    # track the retries
    $retryAttempt = 1;
    while ($retryAttempt -le $MaxRetries)
    {
        try
        {
            if (!$Quiet)
            {
                Log-Message "Attempt [$($retryAttempt)|$($MaxRetries)] - $($InputParameters['Activity']) started." -Context $Context;
            }

            # handle the commands appropriately
            switch ($InputParameters['Command']) 
            {
                "Find-AzureRmResource"
                {
                    $response = Find-AzureRmResource -ResourceGroupNameContains $InputParameters['ResourceGroupName'] -ResourceType $InputParameters['ResourceType'] -Verbose ;  
                }
                
                "Get-AzureRmLoadBalancer"
                {
                    $response = Get-AzureRmLoadBalancer -Name $InputParameters['Name'] -ResourceGroupName $InputParameters['ResourceGroup'] -Verbose ;  
                }

                "Get-AzureRmLoadBalancerRuleConfig"
                {
                    $response = Get-AzureRmLoadBalancerRuleConfig -LoadBalancer $InputParameters['LoadBalancer'] -Verbose;
                }

                "Remove-AzureRmLoadBalancerRuleConfig"
                {
                    $response = Remove-AzureRmLoadBalancerRuleConfig -Name $InputParameters['Name'] -LoadBalancer $InputParameters['LoadBalancer'] -Verbose;
                }

                "Set-AzureRmLoadBalancer"
                {
                    $response = Set-AzureRmLoadBalancer -LoadBalancer $InputParameters['LoadBalancer'] -Verbose;
                }

                "Get-AzureRmVmss"
                {
                    $response = Get-AzureRmVmss -ResourceGroupName $InputParameters['ResourceGroup'] -Verbose;
                }
                
                "Remove-AzureRmVmss"
                {
                    $response = Remove-AzureRmVmss -ResourceGroupName $InputParameters['ResourceGroupName'] -VMScaleSetName $InputParameters['VMScaleSetName'] -Verbose -Force
                }
                 
                "Remove-AzureRmLoadBalancerBackendAddressPoolConfig"
                {
                    $response = Remove-AzureRmLoadBalancerBackendAddressPoolConfig -LoadBalancer $InputParameters['LoadBalancer'] -Name $InputParameters['Name'] -Verbose;
                }
                                 
                "Remove-AzureRmLoadBalancerFrontendIpConfig"
                {
                    $response = Remove-AzureRmLoadBalancerFrontendIpConfig -Name $InputParameters['Name'] -LoadBalancer $InputParameters['LoadBalancer'] -Verbose;
                }
                  
                "Remove-AzureRmLoadBalancer"
                {
                    $response = Remove-AzureRmLoadBalancer -ResourceGroupName $InputParameters['ResourceGroupName'] -Name $InputParameters['Name'] -Verbose -Force;
                }

                "Get-AzureRmPublicIpAddress"
                {
                    $response = Get-AzureRmPublicIpAddress -Name $InputParameters['Name'] -ResourceGroupName $InputParameters['ResourceGroupName'] -Verbose;
                }

                "Remove-AzureRmPublicIpAddress"
                {
                    $response = Remove-AzureRmPublicIpAddress -ResourceGroupName $InputParameters['ResourceGroupName'] -Name $InputParameters['Name'] -Verbose -Force;
                }

                "Get-AzureRmTrafficManagerProfile"
                {
                    $response = Get-AzureRmTrafficManagerProfile -Name $InputParameters['Name'] -ResourceGroupName $InputParameters['ResourceGroupName'] -Verbose ;
                }

                "New-AzureRmResourceGroupDeployment"
                {
                    $response = New-AzureRmResourceGroupDeployment -ResourceGroupName $InputParameters['ResourceGroupName'] -TemplateFile $InputParameters['TemplateFile'] -TemplateParameterFile $InputParameters['TemplateParameterFile'] -Force -Verbose
                }

                "Get-AzureKeyVaultSecret"
                {
                    if ($InputParameters['Name'])
                    {
                        $response = Get-AzureKeyVaultSecret -VaultName $InputParameters['VaultName'] -Name $InputParameters['Name'] -Verbose -ErrorAction Stop
                    }
                    else
                    {
                        $response = Get-AzureKeyVaultSecret -VaultName $InputParameters['VaultName']  -Verbose -ErrorAction Stop
                    }
                }

                "Set-AzureKeyVaultSecret"
                {
                    $response = Set-AzureKeyVaultSecret -VaultName $InputParameters['VaultName'] -Name $InputParameters['Name'] -SecretValue $InputParameters['SecretValue'] -ErrorAction Stop
                }

                "Remove-AzureKeyVaultSecret"
                {
                    $response = Remove-AzureKeyVaultSecret -VaultName $InputParameters['VaultName'] -Name $InputParameters['Name'] -Force:$true -Confirm:$false
                }

                "Get-AzureRmADServicePrincipal"
                {
                    if ($InputParameters['ApplicationId'])
                    {
                        $response = Get-AzureRmADServicePrincipal -ServicePrincipalName $InputParameters['ApplicationId'] -Verbose
                    }
                    elseif ($InputParameters['DisplayName'])
                    {
                        $response = Get-AzureRmADServicePrincipal -SearchString $InputParameters['DisplayName'] -Verbose
                    }
                    else
                    {
                        throw "'Get-AzureRmADServicePrincipal' cmdlet supports searching for service principals by either 'ApplicationId' or 'DisplayName'"    
                    }
                }
                
                "New-AzureRMADServicePrincipal"
                {
                    $response = New-AzureRMADServicePrincipal -DisplayName $InputParameters['DisplayName'] -CertValue $InputParameters['CertValue'] -EndDate $InputParameters['EndDate'] -StartDate $InputParameters['StartDate'] -Verbose -ErrorAction Stop
                }

                "New-AzureRmADSpCredential"
                {
                    $response = New-AzureRmADAppCredential -ApplicationId $InputParameters['ApplicationId'] -CertValue $InputParameters['CertValue'] -EndDate $InputParameters['EndDate'] -StartDate $InputParameters['StartDate'] -Verbose -ErrorAction Stop
                }

                "New-AzureRMRoleAssignment"
                {
                    $response = New-AzureRMRoleAssignment -RoleDefinitionName $InputParameters['RoleDefinitionName'] -ServicePrincipalName $InputParameters['ServicePrincipalName'] -Scope $InputParameters['Scope'] -Verbose -ErrorAction Stop
                }

                "Set-AzureRmKeyVaultAccessPolicy"
                {
                    $response = Set-AzureRmKeyVaultAccessPolicy -VaultName $InputParameters['VaultName'] -ServicePrincipalName $InputParameters['ServicePrincipalName'] -PermissionsToSecrets $InputParameters['PermissionsToSecrets'] -ResourceGroupName $InputParameters['ResourceGroupName'] -Verbose -ErrorAction Stop
                }
                
                "Get-AzureRmServiceBusNamespaceKey"
                {
                    $response = Get-AzureRmServiceBusKey -ResourceGroup $InputParameters['ResourceGroup'] -NamespaceName $InputParameters['NamespaceName'] -AuthorizationRuleName $InputParameters['AuthorizationRuleName'] -Verbose -ErrorAction Stop
                }

                default 
                { 
                    throw "$($InputParameters['Command']) is not a supported call."; 
                    break; 
                }
            }            
            
            if (!$Quiet)
            {
                Log-Message "Attempt [$($retryAttempt)|$($MaxRetries)] - $($InputParameters['Activity']) completed." -Context $Context;
            }

            break;
        }
        catch
        {
            # check for expected exceptions
            if (([string]$InputParameters['ExpectedException']).Trim() -ne "" -and ($_.Exception.Message -imatch $InputParameters['ExpectedException']))
            {
                # at this level, we don't do special handling for exceptions
                # Therefore, rethrowing the exception so the caller can handle it appropriately

                throw $_.Exception;
            }

            Capture-ErrorStack;

            # check if we have exceeded our retry count
            if ($retryAttempt -eq $MaxRetries)
            {
                # we have had 3 tries and failed when an error wasn't expected. throwing a fit.
                $errorMessage = "Azure Call Failure [$($InputParameters['Command'])]: $($InputParameters['Activity']) failed. Error: $($_.Exception.Message)";
                throw $errorMessage;
            }
        }

        $retryAttempt++;

        [int]$retryDelay = $env:RetryDelaySeconds;

        if (!$Quiet)
        {
            Log-Message -Message "Waiting $($retryDelay) seconds between retries" -Context $Context -Foregroundcolor Yellow;
            Start-Sleep -Seconds $retryDelay;
        }
    }

    return $response;    
}

#################################
# Wrapped function
#################################

<#
.SYNOPSIS
Get a list of Oxa network-related resources.

.DESCRIPTION
Get a list of Oxa network-related resources.

.PARAMETER ResourceGroupName
Name of the Azure Resource group containing the network resources.

.PARAMETER MaxRetries
Maximum number of retries this call makes before failing. This defaults to 3.

.OUTPUTS
System.Array. Get-OxaNetworkResources returns an array of discovered azure network-related resource objects
#>
function Get-OxaNetworkResources
{
    param( 
            [Parameter(Mandatory=$true)][string]$ResourceGroupName,
            [Parameter(Mandatory=$false)][int]$MaxRetries=3
         )

    $resourceTypes = @(
                         "Microsoft.Network/loadBalancers", 
                         "Microsoft.Network/publicIPAddresses",
                         "Microsoft.Network/trafficManagerProfiles"
                      );

    [array]$resourceList = $();
    
    foreach ($resourceType in $resourceTypes)
    {
        [hashtable]$parameters = @{'ResourceGroupNameEquals' = $ResourceGroupName; 'ResourceType' = $resourceType }
        
        # get the azure resources based on provided resourcetypes in the resourcegroup
        [array]$response = Find-OxaResource -ResourceGroupName $ResourceGroupName -ResourceType $resourceType -MaxRetries $MaxRetries;

        if($response -ne $null)
        {
            $resourceList += $response;
        }                               
    }

    return $resourceList;
}

#################################
# Wrapped Azure Cmdlets
#################################

<#
.SYNOPSIS
Finds the specfied azure resource.

.DESCRIPTION
Finds the specfied azure resource.

.PARAMETER ResourceGroupName
Name of the azure resource group containing the network resources.

.PARAMETER ResourceType
Specifies the type of azure resource resource

.PARAMETER Context
Logging context that identifies the call

.PARAMETER MaxRetries
Maximum number of retries this call makes before failing. This defaults to 3.

.OUTPUTS
System.Array. Find-OxaResource returns an array of discovered azure resource objects of the specified type
#>
function Find-OxaResource
{
    param(
            [Parameter(Mandatory=$true)][object]$ResourceGroupName,
            [Parameter(Mandatory=$true)][object]$ResourceType,
            [Parameter(Mandatory=$false)][string]$Context="Finding OXA Azure resources",
            [Parameter(Mandatory=$false)][int]$MaxRetries=3
         )

    # prepare the inputs
    [hashtable]$inputParameters = @{
                                        "ResourceGroupName" = $ResourceGroupName;
                                        "ResourceType" = $ResourceType;
                                        "Command" = "Find-AzureRmResource";
                                        "Activity" = "Fetching all azure resources of '$($ResourceType)' type from resource group '$($ResourceGroupName)'"
                                        "ExecutionContext" = $Context;
                                        "MaxRetries" = $MaxRetries;
                                   };

    # this call doesn't require special error handling
    return Start-AzureCommand -InputParameters $inputParameters;
}

<#
.SYNOPSIS
Gets the disabled azure traffic manager endpoint.

.DESCRIPTION
Gets the disabled azure traffic manager endpoint.

.PARAMETER ResourceGroupName
Name of the Azure Resource group containing the network resources.

.PARAMETER ResourceList
Array of of discovered azure network-related resource objects

.PARAMETER TrafficManagerProfileSite
One of three expected traffic manager sites: lms, cms or preview

.PARAMETER MaxRetries
Maximum number of retries this call makes before failing. This defaults to 3.

.OUTPUTS
System.String. Get-OxaDisabledDeploymentSlot returns name of the identified disabled deployment slot (slot1, slot2 or null)
#>
function Get-OxaDisabledDeploymentSlot
{
    param(
            [Parameter(Mandatory=$true)][string]$ResourceGroupName,    
            [Parameter(Mandatory=$false)][array]$ResourceList=@(),
            [Parameter(Mandatory=$false)][ValidateSet("lms", "cms", "preview")][string]$TrafficManagerProfileSite="lms",
            [Parameter(Mandatory=$false)][int]$MaxRetries=3
         )

    # Assign the slot names
    [hashtable]$trafficManagerEndpointNameMap = @{
                                                    "EndPoint1" = "endpoint1";
                                                    "EndPoint2" = "endpoint2";
                                                 };

    # the slot to target
    [string]$targetSlot = $null;

    Log-Message "$($ResourceList.Count) network resources identified." -ClearLineAfter;

    if ( $ResourceList.Count -eq 0 )
    {
        # at this point, no network resource has been provisioned. 
        # This suggests, DeploymentType=bootstrap. Therefore, default to targetSlot=slot1
        Log-Message "Defaulting to 'slot1' since no network resources was identified."
        $targetSlot = "slot1";
    }
    else
    {
        # There are three (3) TM profiles, each mapped to a site: lms, cms, preview.
        # The following are assumed about these profiles:
        #   1. all profiles have the same state (mix-mode is not supported)
        #   2. each profile has two (2) endpoints: endpoint1 & endpoint2 (one of which is live)

        try
        {
            Log-Message "Getting '$($TrafficManagerProfileSite)' traffic manager profile:";

            # Getting LMS traffic manager profile to identify the disabled slot
            $trafficManager = $resourceList -match "Microsoft.Network/trafficManagerProfiles" | Where-Object{ $_ -imatch $TrafficManagerProfileSite };

            if ( !$trafficManager )
            {
                throw "Traffic manager profile for '$($TrafficManagerProfileSite)' site was not found.";
                exit;
            }

            $trafficManagerProfile = Get-OxaTrafficManagerProfile -TrafficManagerProfileName $trafficManager.Name -ResourceGroupName $resourceGroupName -MaxRetries $MaxRetries;

            if ( !$trafficManagerProfile )
            {
                throw "Could not get the traffic manager profile object reference for '$($TrafficManagerProfileSite)'"
                exit;
            }

            # track number of endpoints (we expect 2 endpoints)
            [int]$endpointsCount = $trafficManagerProfile.Endpoints.Count

            if ( $endpointsCount -ne 2)
            {
                throw "The '$($TrafficManagerProfileSite)' traffic manager profile site is expected to have two (2) endpoints. $($endpointsCount) endpoint(s) found.";
                exit;
            }

            # iterate the endpoints
            foreach ( $endpoint in $trafficManagerProfile.Endpoints )
            {
                if ( $endpoint.EndpointMonitorStatus -eq "Disabled" )
                {           
                    if ( $endpoint.Name.Contains($trafficManagerEndpointNameMap['EndPoint1'] ))
                    {
                        $targetSlot="slot1";
                    }

                    if ( $endpoint.Name.Contains($trafficManagerEndpointNameMap['EndPoint2'] ))
                    {
                        $targetSlot="slot2";
                    }
                }
            }

            # if both slots are active
            if ( $endpointsCount -eq 2 -and $targetSlot -eq $null )
            {
                throw "All available slots are active!";
                exit;
            }
        }
        catch   
        {
            Capture-ErrorStack;
            throw "Error in identifying the traffic manager profile: $($_.Message)";
            exit;
        }

        if ( $endpointsCount -eq 2 -and !$targetSlot )
        {
            Log-Message "No disabled slot identified: first deployment to second slot detected. Defaulting to Slot 2!";
            $targetSlot = "slot1";
        }
    }

    return $targetSlot;
}

<#
.SYNOPSIS
Removes all rule configurations for an azure load balancer.

.DESCRIPTION
Removes all rule configurations for an azure load balancer.

.PARAMETER ResourceGroupName
Name of the Azure Resource group containing the network resources.

.PARAMETER LoadBalancer
Name of the load balancer

.PARAMETER Context
Logging context that identifies the call

.PARAMETER MaxRetries
Maximum number of retries this call makes before failing. This defaults to 3.

.OUTPUTS
Microsoft.Azure.Commands.Network.Models.PSLoadBalancer. Remove-OxaLoadBalancerRuleConfigs returns an updated azure load balancer object.
#>
function Remove-OxaLoadBalancerRuleConfigs
{
    param(
            [Parameter(Mandatory=$false)][array]$LoadBalancerRules=@(),
            [Parameter(Mandatory=$true)][object]$LoadBalancer,
            [Parameter(Mandatory=$false)][string]$Context="Load Balancer Rules",
            [Parameter(Mandatory=$false)][int]$MaxRetries=3
         )

    foreach($rule in $loadBalancerRules)
    {
        Log-Message "Removing load balancer rule: $($rule.Name)"
        $LoadBalancer = Remove-OxaLoadBalancerRuleConfig -LoadBalancerRuleConfigName $rule.Name -LoadBalancer $LoadBalancer -Context $context
        
        # TODO: process the process and confirm success
        if (!$LoadBalancer)
        {
            throw "Unable to remove load balancer rule: $($rule.Name)"
        }
    }

    # at this point, all rules have been removed, now save/persist the loadbalancer settings
    # should save the loadbalancer setttings once we remove the rules from the loadbalancer settings
    return Set-OxaAzureLoadBalancer -LoadBalancer $LoadBalancer;
} 

<#
.SYNOPSIS
Get the VMSS name(s) from load balancer's backend address pool.

.DESCRIPTION
Get the VMSS name(s) from load balancer's backend address pool.

.PARAMETER VmssBackendAddressPools
Array of VMSS address pools from an azure load balancer

.OUTPUTS
System.Array. Get-VmssName returns an array of unique VMSS names from teh specified backend address pool.
#>
function Get-VmssName
{
    param( [Parameter(Mandatory=$true)][array]$VmssBackendAddressPools )

    $vmssNames = @();

    foreach( $backendPool in $VmssBackendAddressPools )
    {
        foreach( $backendIpConfiguration in $backendPool.BackendIpConfigurations )
        {
            $backendIpConfigurationParts = $backendIpConfiguration.Id.split("/");

            # the vmss name is at a fixed position in the Id of the backend configuration
            $vmssNames += $backendIpConfigurationParts[8];
        }
    }

    $uniqueVmssNames = $vmssNames | Select-Object -Unique

    return $uniqueVmssNames
}

<#
.SYNOPSIS
Remove an azure load balancer and all associated resources.

.DESCRIPTION
Remove an azure load balancer and all associated resources.

.PARAMETER ResourceGroupName
Name of the Azure Resource group containing the network resources.

.PARAMETER LoadBalancerName
Name of the load balancer to remove

.PARAMETER MaxRetries
Maximum number of retries this call makes before failing. This defaults to 3.

.OUTPUTS
System.Boolean. Remove-OxaDeploymentSlotResources returns a boolean indicator of whether or not the delete operation succeeded.
#>
function Remove-OxaNetworkLoadBalancerResource
{
    param(
            [Parameter(Mandatory=$true)][string]$ResourceGroupName,
            [Parameter(Mandatory=$true)][string]$LoadBalancerName,
            [Parameter(Mandatory=$false)][int]$MaxRetries=3
         )

    # Fetch the specified loadbalancer object
    $loadbalancer = Get-OxaLoadBalancer -Name $LoadBalancerName -ResourceGroupName $ResourceGroupName -MaxRetries $MaxRetries;

    if ( !$loadbalancer )
    {
        Log-Message "Could not get the specified load balancer: $($LoadBalancerName)"
        return
    }

    # Fetch the loadbalancer rules
    $loadBalancerRules = Get-OxaLoadBalancerRuleConfig -LoadBalancer $loadbalancer -MaxRetries $MaxRetries;
    Log-Message "Retrieved $($loadBalancerRules.Count) load balancer rule(s)"

    # 1. Remove the identified load balancer rules
    $loadbalancer = Remove-OxaLoadBalancerRuleConfigs -LoadBalancerRules $loadBalancerRules -LoadBalancer $loadbalancer -MaxRetries $MaxRetries;
    if ( !$loadbalancer )
    {
        throw "Could not removed the $($loadBalancerRules.Count) load balancer rule(s) retrieved."
    }

    # 2. Remove the VMSS in the backend pool of the specified load balancer (filter to the correct VMSS)
    [array]$vmssNamesToRemove = Get-VmssName -VmssBackendAddressPools $loadbalancer.BackendAddressPools;
    Log-Message "$($vmssToRemove.Count) VMSS(s) retrieved.";

    if ( $vmssNamesToRemove.Count -gt 0 )
    {
        $vmssToRemove = Get-OxaVmss -ResourceGroupName $ResourceGroupName -MaxRetries $MaxRetries | Where-Object { $vmssNamesToRemove.Contains($_.Name)};
        if ( $vmssToRemove )
        {
            Remove-OxaVmss -ResourceGroupName $ResourceGroupName -VMScaleSetName $vmssToRemove.Name -MaxRetries $MaxRetries;
        }
    }

    # 3. Remove the LoadBalancer Backend Pool
    Log-Message "$($loadbalancer.BackendAddressPools.Count) backend address pool(s) retrieved for '$($loadbalancer.Name)' loadbalancer.";
    $loadbalancer = Remove-OxaLoadBalancerBackendAddressPoolConfigs -LoadBalancerBackendPools $loadbalancer.BackendAddressPools -LoadBalancer $loadbalancer -MaxRetries $MaxRetries;

    if ( !$loadbalancer )
    {
        throw "Could not removed the $($loadBalancerRules.Count) load balancer backend address pool(s) retrieved.";
    }


    ############################################
    # 4. Remove the LoadBalancer Frontend Pool
    Log-Message "$($loadbalancer.FrontendIpConfigurations.Count) frontend address pool(s) retrieved for '$($loadbalancer.Name)' loadbalancer.";
    $loadbalancer = Remove-OxaLoadBalancerFrontEndIpConfigs -LoadBalancerFrontendIpConfigurations $loadbalancer.FrontendIpConfigurations -LoadBalancer $loadbalancer -MaxRetries $MaxRetries;

    if ( !$loadbalancer )
    {
        throw "Could not remove the $() load balancer frontend address configurations.";
    }
    
    ############################################
    # 5. Remove the LoadBalancer
    Remove-OxaLoadBalancer -ResourceGroupName $ResourceGroupName -Name $loadbalancer.Name  -MaxRetries $MaxRetries;

    return $true;
}


<#
.SYNOPSIS
Remove all frontend ip configurations for a load balancer.

.DESCRIPTION
Remove all frontend ip configurations for a load balancer.

.PARAMETER FrontendIpConfigurations
Array of FrontEnd Ip Configurations.

.PARAMETER LoadBalancer
Name of the load balancer.

.PARAMETER MaxRetries
Maximum number of retries this call makes before failing. This defaults to 3.

.OUTPUTS
System.Boolean. Remove-OxaDeploymentSlotResources returns a boolean indicator of whether or not the delete operation succeeded.
#>
function Remove-OxaLoadBalancerFrontEndIpConfigs
{
    param(
            [Parameter(Mandatory=$true)][array]$LoadBalancerFrontendIpConfigurations,
            [Parameter(Mandatory=$true)][object]$LoadBalancer,
            [Parameter(Mandatory=$false)][int]$MaxRetries=3
         )

    # TODO: exclude preview since it throws an unexpected error while attempting to delete it.
    # Investigate why.
    [array]$filteredFrontendIpConfigurations = $LoadBalancerFrontendIpConfigurations | Where-Object { $_.Name -inotmatch "preview" };
    Log-Message "Removing $($filteredFrontendIpConfigurations.count) frontend ip configurations."

    foreach ( $frontendIpConfiguration in $filteredFrontendIpConfigurations )
    {
        # Deleting the loadbalancerFrontendIP configurations
        $LoadBalancer = Remove-OxaLoadBalancerFrontendIpConfig -Name $frontendIpConfiguration.Name -LoadBalancer $LoadBalancer;
        if ( !$LoadBalancer )
        {
            throw "Unable to remove load balancer frontend ip configuration: $($frontendIpConfiguration.Name)";
        }
    }

    # should save the loadbalancer setttings once we remove the rules from the loadbalancer settings
    return Set-OxaAzureLoadBalancer -LoadBalancer $LoadBalancer;
}

<#
.SYNOPSIS
Remove all resources associated with an Oxa deployment slot.

.DESCRIPTION
Remove all resources associated with an Oxa deployment slot.

.PARAMETER ResourceGroupName
Name of the Azure Resource group containing the network resources.

.PARAMETER TargetDeploymentSlot
Name of the deployment slot to deploy to.

.PARAMETER ResourceList
Array of of discovered azure network-related resource objects.

.PARAMETER MaxRetries
Maximum number of retries this call makes before failing. This defaults to 3.

.OUTPUTS
System.Boolean. Remove-OxaDeploymentSlotResources returns a boolean indicator of whether or not the delete operation succeeded.
#>
function Remove-OxaDeploymentSlotResources
{
    param(
            [Parameter(Mandatory=$true)][string]$ResourceGroupName,
            [Parameter(Mandatory=$true)][ValidateSet("slot1", "slot2")][string]$TargetDeploymentSlot,
            [Parameter(Mandatory=$false)][array]$NetworkResourceList=@(),
            [Parameter(Mandatory=$false)][int]$MaxRetries=3
         )

    $response = $false

    # Filter the resources based on the targeted slot
    if ($NetworkResourceList -and $NetworkResourceList.Count -gt 1)
    {
        # some resources are specified
        [array]$targetedResources = $NetworkResourceList | Where-Object { $_.ResourceName.Contains($TargetDeploymentSlot) };
        Log-Message "$($targetedResources.Count) resources targeted for removal from '$($TargetDeploymentSlot)'" -ClearLine -ClearLineAfter

        if (!$targetedResources -or $targetedResources.Count -eq 0)
        {
            # there is nothing to do: no existing resources for the target slot exists for removal
            $response = $true;
        }

        # iterate the targeted resources
        foreach($resource in $targetedResources)
        {
            switch ( $resource.resourcetype )
            {  
                "Microsoft.Network/loadBalancers"
                {
                    # TODO: handle response 
                    $response = Remove-OxaNetworkLoadBalancerResource -LoadBalancerName $resource.Name -MaxRetries $MaxRetries -ResourceGroupName $ResourceGroupName;
                }

                "Microsoft.Network/publicIPAddresses"
                {
                    # TODO: handle response 
                    $requestResponse = Remove-OxaNetworkIpAddress -Name $resource.Name -ResourceGroupName $ResourceGroupName  -MaxRetries $MaxRetries;

                    if ( $requestResponse )
                    {
                        $response = $true;
                    }
                }
            }

            if ( !$response )
            {
                throw "Unable to remove the specified resource: Name=$($resource.Name), Type=$($resource.resourcetype)";
            }
        }
    }
    else
    {
        # if no resources are specified for removal, return $true
        # equivalent to no-op
        $response = $true; 
    }
    
    return $response
}

<#
.SYNOPSIS
Get a list of Oxa Azure load balancers

.DESCRIPTION
Get a list of Oxa Azure load balancers.

.PARAMETER Name
Name of the load balancer

.PARAMETER ResourceGroupName
Name of the Azure Resource group containing the load balancer

.PARAMETER Context
Logging context that identifies the call

.PARAMETER MaxRetries
Maximum number of retries this call makes before failing. This defaults to 3.

.OUTPUTS
Microsoft.Azure.Commands.Network.Models.PSLoadBalancer. Get-OxaLoadBalancer returns an azure load balancer object.
#>
function Remove-OxaNetworkIpAddress
{       
    param(
            [Parameter(Mandatory=$true)][string]$Name,
            [Parameter(Mandatory=$true)][string]$ResourceGroupName,
            [Parameter(Mandatory=$false)][string]$Context="Load Balancer",
            [Parameter(Mandatory=$false)][int]$MaxRetries=3
        )

    return Remove-OxaPubicIpAddress -Name $Name -ResourceGroupName $ResourceGroupName; 
}

<#
.SYNOPSIS
Get a list of Oxa Azure load balancers

.DESCRIPTION
Get a list of Oxa Azure load balancers.

.PARAMETER Name
Name of the load balancer

.PARAMETER ResourceGroupName
Name of the Azure Resource group containing the load balancer

.PARAMETER Context
Logging context that identifies the call

.PARAMETER MaxRetries
Maximum number of retries this call makes before failing. This defaults to 3.

.OUTPUTS
Microsoft.Azure.Commands.Network.Models.PSLoadBalancer. Get-OxaLoadBalancer returns an azure load balancer object.
#>
 function Get-OxaLoadBalancer
{
    param(
            [Parameter(Mandatory=$true)][string]$Name,
            [Parameter(Mandatory=$true)][string]$ResourceGroupName,
            [Parameter(Mandatory=$false)][string]$Context="Load Balancer",
            [Parameter(Mandatory=$false)][int]$MaxRetries=3
         )

    # prepare the inputs
    [hashtable]$inputParameters = @{
                                        "Name" = $Name
                                        "ResourceGroup" = $ResourceGroupName
                                        "Command" = "Get-AzureRmLoadBalancer";
                                        "Activity" = "Getting azure LoadBalancer '$($Name)'"
                                        "ExecutionContext" = $Context
                                   };

    # this call doesn't require special error handling
    return Start-AzureCommand -InputParameters $inputParameters;
}

<#
.SYNOPSIS
Gets the rule configuration for a load balancer.

.DESCRIPTION
Gets the rule configuration for a load balancer.

.PARAMETER LoadBalancer
Name of the load balancer

.PARAMETER Context
Logging context that identifies the call

.PARAMETER MaxRetries
Maximum number of retries this call makes before failing. This defaults to 3.

.OUTPUTS
Microsoft.Azure.Commands.Network.Models.PSLoadBalancingRule. Get-OxaLoadBalancerRuleConfig returns an array of rules associated with a specified load balancer object.
#>
function Get-OxaLoadBalancerRuleConfig
{
    param(
            [Parameter(Mandatory=$true)][Object]$LoadBalancer,
            [Parameter(Mandatory=$false)][string]$Context="Load Balancer Rules",
            [Parameter(Mandatory=$false)][int]$MaxRetries=3
         )

    # prepare the inputs
    [hashtable]$inputParameters = @{
                                        "LoadBalancer" = $LoadBalancer
                                        "Command" = "Get-AzureRmLoadBalancerRuleConfig";
                                        "Activity" = "Getting azure LoadBalancerRules for '$($LoadBalancer.Name)'";
                                        "ExecutionContext" = $Context;
                                        "MaxRetries" = $MaxRetries;
                                   };

    # this call doesn't require special error handling
    return Start-AzureCommand -InputParameters $inputParameters;
}

<#
.SYNOPSIS
Gets a Traffic Manager profile.

.DESCRIPTION
Gets a Traffic Manager profile.

.PARAMETER ResourceGroupName
Name of the Azure Resource group containing the network resources.

.PARAMETER Context
Logging context that identifies the call

.PARAMETER MaxRetries
Maximum number of retries this call makes before failing. This defaults to 3.

.OUTPUTS
System.Array. Get-OxaNetworkResources returns an array of discovered azure network-related resource objects
#>
function Get-OxaTrafficManagerProfile
{
    param(
            [Parameter(Mandatory=$true)][string]$TrafficManagerProfileName,
            [Parameter(Mandatory=$true)][string]$ResourceGroupName,
            [Parameter(Mandatory=$false)][string]$Context="Traffic Manager Profile",
            [Parameter(Mandatory=$false)][int]$MaxRetries=3
         )

    # prepare the inputs
    [hashtable]$inputParameters = @{
                                        "Name" = $TrafficManagerProfileName;
                                        "ResourceGroupName" = $ResourceGroupName;
                                        "Command" = "Get-AzureRmTrafficManagerProfile";
                                        "Activity" = "Getting azure Traffic Manager profile for '$($TrafficManagerProfileName)' in '$($ResourceGroupName)'"
                                        "ExecutionContext" = $Context
                                        "MaxRetries" = $MaxRetries
                                   };
    # this call doesn't require special error handling
    return Start-AzureCommand -InputParameters $inputParameters;
}

<#
.SYNOPSIS
Removes a rule configuration for a load balancer.

.DESCRIPTION
Removes a rule configuration for a load balancer.

.PARAMETER LoadBalancerRuleConfigName
Name of the load balancer configuration.

.PARAMETER LoadBalancer
Azure load balancer object.

.PARAMETER Context
Logging context that identifies the call

.PARAMETER MaxRetries
Maximum number of retries this call makes before failing. This defaults to 3.

.OUTPUTS
Microsoft.Azure.Commands.Network.Models.PSLoadBalancer. Remove-OxaLoadBalancerRuleConfig returns a load balancer object with updated configuration.
#>
function Remove-OxaLoadBalancerRuleConfig
{
    param(
            [Parameter(Mandatory=$true)][string]$LoadBalancerRuleConfigName,
            [Parameter(Mandatory=$true)][Object]$LoadBalancer,
            [Parameter(Mandatory=$false)][string]$Context="Load Balancer Rules",
            [Parameter(Mandatory=$false)][int]$MaxRetries=3
         )

    # prepare the inputs
    [hashtable]$inputParameters = @{
                                        "Name" = $LoadBalancerRuleConfigName
                                        "LoadBalancer" = $LoadBalancer
                                        "Command" = "Remove-AzureRmLoadBalancerRuleConfig";
                                        "Activity" = "Removing azure LoadBalancerRules from '$($LoadBalancerName)'"
                                        "ExecutionContext" = $Context
                                        "MaxRetries" = $MaxRetries
                                   };

    # this call doesn't require special error handling
    return Start-AzureCommand -InputParameters $inputParameters;
}

<#
.SYNOPSIS
Sets the goal state for a load balancer.

.DESCRIPTION
Sets the goal state for a load balancer.

.PARAMETER LoadBalancer
Azure load balancer object.

.PARAMETER Context
Logging context that identifies the call

.PARAMETER MaxRetries
Maximum number of retries this call makes before failing. This defaults to 3.

.OUTPUTS
Microsoft.Azure.Commands.Network.Models.PSLoadBalancer. Set-OxaLoadBalancer returns a load balancer object with updated configuration.
#>
function Set-OxaAzureLoadBalancer
{
    param(
            [Parameter(Mandatory=$true)][Object]$LoadBalancer,
            [Parameter(Mandatory=$false)][string]$Context="Load Balancer Settings",
            [Parameter(Mandatory=$false)][int]$MaxRetries=3
         )

    # prepare the inputs
    [hashtable]$inputParameters = @{
                                        "LoadBalancer" = $LoadBalancer
                                        "Command" = "Set-AzureRmLoadBalancer";
                                        "Activity" = "Saving LoadBalancerRules for '$($LoadBalancer.Name)'"
                                        "MaxRetries" = $MaxRetries
                                        "ExecutionContext" = $Context
                                   };

    # this call doesn't require special error handling
    return Start-AzureCommand -InputParameters $inputParameters;
}

<#
.SYNOPSIS
Gets the properties of a VMSS.

.DESCRIPTION
Gets the properties of a VMSS.

.PARAMETER LoadBalancer
Azure load balancer object.

.PARAMETER Context
Logging context that identifies the call

.PARAMETER MaxRetries
Maximum number of retries this call makes before failing. This defaults to 3.

.OUTPUTS
System.Object. Get-OxaVmss returns an azure Vmss and its properties.
#>
function Get-OxaVmss
{
    param(
            [Parameter(Mandatory=$true)][string]$ResourceGroupName,
            [Parameter(Mandatory=$false)][string]$Context="VMSS",
            [Parameter(Mandatory=$false)][int]$MaxRetries=3
         )

    # prepare the inputs
    [hashtable]$inputParameters = @{
                                       "ResourceGroup" = $ResourceGroupName
                                        "Command" = "Get-AzureRmVmss";
                                        "Activity" = "Fetching VMSS details from '$($ResourceGroupName)'";
                                        "ExecutionContext" = $Context;
                                        "MaxRetries" = $MaxRetries;
                                   };

    # this call doesn't require special error handling
    return Start-AzureCommand -InputParameters $inputParameters;
}

<#
.SYNOPSIS
Removes the VMSS or a virtual machine that is within the VMSS.

.DESCRIPTION
Removes the VMSS or a virtual machine that is within the VMSS.

.PARAMETER ResourceGroupName
Name of the Azure Resource group containing the network resources.

.PARAMETER VMScaleSetName
Name of the VMSS to remove.

.PARAMETER Context
Logging context that identifies the call

.PARAMETER MaxRetries
Maximum number of retries this call makes before failing. This defaults to 3.

.OUTPUTS
None.
#>
function Remove-OxaVmss
{
    param(
            [Parameter(Mandatory=$true)][string]$ResourceGroupName,
            [Parameter(Mandatory=$true)][Object]$VMScaleSetName,
            [Parameter(Mandatory=$false)][string]$Context="VMSS",
            [Parameter(Mandatory=$false)][int]$MaxRetries=3
         )

    # prepare the inputs
    [hashtable]$inputParameters = @{
                                        "ResourceGroupName" = $ResourceGroupName;
                                        "VMScaleSetName" = $VMScaleSetName;
                                        "Command" = "Remove-AzureRmVmss";
                                        "Activity" = "Removing azure VMSS '$($VMScaleSetName)'";
                                        "ExecutionContext" = $Context;
                                        "MaxRetries" = $MaxRetries;
                                   };

    # this call doesn't require special error handling
    return Start-AzureCommand -InputParameters $inputParameters;
}

<#
.SYNOPSIS
Removes all backend address pool configurations from a load balancer.

.DESCRIPTION
Removes all backend address pool configurations from a load balancer.

.PARAMETER LoadBalancer
Specifies the load balancer that contains the backend address pool to remove.

.PARAMETER LoadBalancerBackendPools
Specifies an array of backend pools to remove.

.PARAMETER Context
Logging context that identifies the call

.PARAMETER MaxRetries
Maximum number of retries this call makes before failing. This defaults to 3.

.OUTPUTS
Microsoft.Azure.Commands.Network.Models.PSLoadBalancer. Remove-OxaLoadBalancerBackendAddressPoolConfig returns an updated azure load balancer object.
#>
function Remove-OxaLoadBalancerBackendAddressPoolConfigs
{
    param(
            [Parameter(Mandatory=$true)][object]$LoadBalancer,
            [Parameter(Mandatory=$true)][array]$LoadBalancerBackendPools,
            [Parameter(Mandatory=$false)][string]$Context="Load Balancer",
            [Parameter(Mandatory=$false)][int]$MaxRetries=3
        )

    foreach( $backendPool in $LoadBalancerBackendPools )
    {
        $LoadBalancer = Remove-OxaLoadBalancerBackendAddressPoolConfig -LoadBalancer $LoadBalancer -Name $backendPool.Name -Context $Context -MaxRetries $MaxRetries;

        if ( !$LoadBalancer )
        {
            throw "Unable to remove load balancer backend address pool configuration: $($backendPool.Name)";
        }
    }

    # at this point, all rules have been removed, now save/persist the loadbalancer settings
    # should save the loadbalancer setttings once we remove the rules from the loadbalancer settings
    return Set-OxaAzureLoadBalancer -LoadBalancer $LoadBalancer;
}

<#
.SYNOPSIS
Removes a backend address pool configuration from a load balancer.

.DESCRIPTION
Removes a backend address pool configuration from a load balancer.

.PARAMETER LoadBalancer
Specifies the load balancer that contains the backend address pool to remove.

.PARAMETER Name
Specifies the name of the backend address pool that this cmdlet removes

.PARAMETER Context
Logging context that identifies the call

.PARAMETER MaxRetries
Maximum number of retries this call makes before failing. This defaults to 3.

.OUTPUTS
Microsoft.Azure.Commands.Network.Models.PSLoadBalancer. Remove-OxaLoadBalancerBackendAddressPoolConfig returns an updated azure load balancer object.
#>
function Remove-OxaLoadBalancerBackendAddressPoolConfig
{
    param(
            [Parameter(Mandatory=$true)][object]$LoadBalancer,
            [Parameter(Mandatory=$true)][string]$Name,
            [Parameter(Mandatory=$false)][string]$Context="Load Balancer",
            [Parameter(Mandatory=$false)][int]$MaxRetries=3
         )

    # prepare the inputs
    [hashtable]$inputParameters = @{
                                        "LoadBalancer" = $LoadBalancer;
                                        "Name" = $Name;
                                        "Command" = "Remove-AzureRmLoadBalancerBackendAddressPoolConfig";
                                        "Activity" = "Removing azure Load balancer BackEnd Addressspool config '$($Name)'";
                                        "ExecutionContext" = $Context;
                                        "MaxRetries" = $MaxRetries;
                                   };

    # this call doesn't require special error handling
    return Start-AzureCommand -InputParameters $inputParameters;
}

<#
.SYNOPSIS
Removes a front-end IP configuration from a load balancer.

.DESCRIPTION
Removes a front-end IP configuration from a load balancer.

.PARAMETER LoadBalancer
Specifies the load balancer that contains the front-end IP configuration to remove.

.PARAMETER Name
Specifies the name of the front-end IP address configuration to remove.

.PARAMETER Context
Logging context that identifies the call.

.PARAMETER MaxRetries
Maximum number of retries this call makes before failing. This defaults to 3.

.OUTPUTS
Microsoft.Azure.Commands.Network.Models.PSLoadBalancer. Remove-OxaLoadBalancerFrontendIpConfig returns an updated azure load balancer object.
#>
function Remove-OxaLoadBalancerFrontendIpConfig
{
    param(
            [Parameter(Mandatory=$true)][string]$Name,
            [Parameter(Mandatory=$true)][Object]$LoadBalancer,
            [Parameter(Mandatory=$false)][string]$Context="Load Balancer Frontend",
            [Parameter(Mandatory=$false)][int]$MaxRetries=3
         )

    # prepare the inputs
    [hashtable]$inputParameters = @{
                                        "LoadBalancer" = $LoadBalancer;
                                        "Name" = $Name;
                                        "Command" = "Remove-AzureRmLoadBalancerFrontendIpConfig";
                                        "Activity" = "Removing azure Load balancer FrontEnd Ip config '$($Name)'";
                                        "ExecutionContext" = $Context;
                                        "MaxRetries" = $MaxRetries;
                                   };

    # this call doesn't require special error handling
    return Start-AzureCommand -InputParameters $inputParameters;
}

<#
.SYNOPSIS
Removes a backend address pool configuration from a load balancer.

.DESCRIPTION
Removes a backend address pool configuration from a load balancer.

.PARAMETER ResourceGroupName
Specifies the name of the resource group that contains the load balancer to remove.

.PARAMETER Name
Specifies the name of the load balancer to remove.

.PARAMETER Context
Logging context that identifies the call.

.PARAMETER MaxRetries
Maximum number of retries this call makes before failing. This defaults to 3.

.OUTPUTS
None.
#>
 function Remove-OxaLoadBalancer
{
    param(
            [Parameter(Mandatory=$true)][string]$ResourceGroupName,
            [Parameter(Mandatory=$true)][string]$Name,
            [Parameter(Mandatory=$false)][string]$Context="Load Balancer",
            [Parameter(Mandatory=$false)][int]$MaxRetries=3
         )

    # prepare the inputs
    [hashtable]$inputParameters = @{
                                        "Name" = $Name;
                                        "ResourceGroupName" = $ResourceGroupName;
                                        "Command" = "Remove-AzureRmLoadBalancer";
                                        "Activity" = "Removing azure Load balancer '$($Name)' from ResourceGroup $($ResourceGroupName)";
                                        "ExecutionContext" = $Context;
                                        "MaxRetries" = $MaxRetries;
                                   };

    # this call doesn't require special error handling
    return Start-AzureCommand -InputParameters $inputParameters;
}

<#
.SYNOPSIS
Gets a public IP address.

.DESCRIPTION
Gets a public IP address.

.PARAMETER ResourceGroupName
Specifies the name of the resource group that contains the public IP address that this cmdlet gets.

.PARAMETER Name
Specifies the name of the public IP address that this cmdlet gets.

.PARAMETER Context
Logging context that identifies the call.

.PARAMETER MaxRetries
Maximum number of retries this call makes before failing. This defaults to 3.

.OUTPUTS
Microsoft.Azure.Commands.Network.Models.PSPublicIpAddress. Get-OxaPubicIpAddress returns details for the specified public ip address azure resource.
#>
function Get-OxaPubicIpAddress
{
    param(
            [Parameter(Mandatory=$true)][string]$ResourceGroupName,
            [Parameter(Mandatory=$true)][string]$Name,
            [Parameter(Mandatory=$false)][string]$Context="Ip Address",
            [Parameter(Mandatory=$false)][int]$MaxRetries=3
         )

    # prepare the inputs
    [hashtable]$inputParameters = @{
                                        "ResourceGroupName" = $ResourceGroupName
                                        "Name" = $Name
                                        "Command" = "Get-AzureRmPublicIpAddress";
                                        "Activity" = "Fetching azure PublicIP Addresses from $($ResourceGroupName)"
                                        "ExecutionContext" = $Context
                                   };

    # this call doesn't require special error handling
    return Start-AzureCommand -InputParameters $inputParameters;
}

<#
.SYNOPSIS
Removes a public IP address.

.DESCRIPTION
Removes a public IP address.

.PARAMETER ResourceGroupName
Specifies the name of the resource group that contains the public IP address that this cmdlet removes.

.PARAMETER Name
Specifies the name of the public IP address that this cmdlet removes.

.PARAMETER Context
Logging context that identifies the call.

.PARAMETER MaxRetries
Maximum number of retries this call makes before failing. This defaults to 3.

.OUTPUTS
None.
#>
function Remove-OxaPubicIpAddress
{
    param(
            [Parameter(Mandatory=$true)][string]$ResourceGroupName,
            [Parameter(Mandatory=$true)][string]$Name,
            [Parameter(Mandatory=$false)][string]$Context="Ip Address",
            [Parameter(Mandatory=$false)][int]$MaxRetries=3
         )

    # prepare the inputs
    [hashtable]$inputParameters = @{
                                        "Name" = $Name;
                                        "ResourceGroupName" = $ResourceGroupName;
                                        "Command" = "Remove-AzureRmPublicIpAddress";
                                        "Activity" = "Removing azure PublicIP Address '$($Name)' from '$($ResourceGroupName)'";
                                        "ExecutionContext" = $Context;
                                        "MaxRetries" = $MaxRetries;
                                   };

    # this call doesn't require special error handling
    return Start-AzureCommand -InputParameters $inputParameters;
}

<#
.SYNOPSIS
Remove an Oxa deployment slot.

.DESCRIPTION
Remove an Oxa deployment slot.

.PARAMETER DeploymentType
A switch to indicate the deployment type (any of bootstrap, upgrade, swap, cleanup).

.PARAMETER ResourceGroupName
Name of the Azure Resource group containing the network resources.

.PARAMETER TargetDeploymentSlot
Name of the deployment slot to deploy to.

.PARAMETER ResourceList
Array of of discovered azure network-related resource objects.

.PARAMETER MaxRetries
Maximum number of retries this call makes before failing. This defaults to 3.

.OUTPUTS
System.Boolean. Remove-OxaDeploymentSlot returns a boolean indicator of whether or not the delete operation succeeded.
#>
function Remove-OxaDeploymentSlot
{
    param(
            [Parameter(Mandatory=$true)][ValidateSet("bootstrap", "upgrade", "swap", "cleanup")][string]$DeploymentType,
            [Parameter(Mandatory=$true)][string]$ResourceGroupName,
            [Parameter(Mandatory=$true)][ValidateSet("slot1", "slot2")][string]$TargetDeploymentSlot,
            [Parameter(Mandatory=$false)][array]$NetworkResourceList=@(),
            [Parameter(Mandatory=$false)][int]$MaxRetries=3
    )

    #cleaning up the resources from the disabled slot (response will be processed by caller)
    return Remove-OxaDeploymentSlotResources -ResourceGroupName $ResourceGroupName -TargetDeploymentSlot $TargetDeploymentSlot -NetworkResourceList $NetworkResourceList -MaxRetries $MaxRetries;
}

<#
.SYNOPSIS
Gets the latest deployment version id from all available VMSS(s).

.DESCRIPTION
Gets the latest deployment version id from all available VMSS(s).

.PARAMETER ResourceGroupName
Name of the Azure Resource group containing the network resources.

.PARAMETER MaxRetries
Maximum number of retries this call makes before failing. This defaults to 3.

.OUTPUTS
System.String. Get-LatestVmssDeploymentVersionId returns a string value representing the latest deployment version id in the resource group.
#>
function Get-LatestVmssDeploymentVersionId
{
    param( 
            [Parameter(Mandatory=$true)][string]$ResourceGroupName,
            [Parameter(Mandatory=$false)][int]$MaxRetries=3
         ) 

    [array]$vmssList = Get-OxaVmss -ResourceGroupName $ResourceGroupName -MaxRetries $MaxRetries;

    # sort in descending order and select the first one (the most recent)
    $vmss = $vmssList | Sort-Object -Descending | Select-Object -First 1;

    # $vmss.Name has the format: {CLUSTER_NAME}-vmss-{DEPLOYMENTVERSIONID}
    # extract the deployment version id
    return $vmss.Name.Split('-') | Select-Object -Last 1;
}

## Function: Get-LatestChanges
##
## Purpose: 
##    Create a container in the specified storage account
##
## Input: 
##   BranchName       name of the branch
##   Tag        name of the Tag
##   enlistmentRootPath     path of the local repo
##   privateRepoGitAccount     github private account url
##
## Output:
##   nothing
function Get-LatestChanges
{
    param(      
             [Parameter(Mandatory=$true)][string]$BranchName,
             [Parameter(Mandatory=$false)][string]$Tag,
             [Parameter(Mandatory=$false)][string]$enlistmentRootPath,
             [Parameter(Mandatory=$false)][string]$privateRepoGitAccount                
          )           
                  
   if ( !(Test-Path -Path $enlistmentRootPath) )
   { 
       cd $enlistmentRootPath -ErrorAction SilentlyContinue;
       # Here we are assuming git is already installed and installed path has been set in environment path variable.
       # SSh key has to be configured with both github & git bash account to authenticate.
       # Clone TFD Git repository
       git clone git@github.com:Microsoft/oxa-tools.git -b $BranchName $enlistmentRootPath -q
   }

   cd $enlistmentRootPath
   
   if ( $tag -eq $null )
   {
       git checkout
       git pull           
   }
   else
   {
       git checkout $tag -q
   }
              
   if ( !(Test-Path -Path $enlistmentRootPath-"config" ))
   { 
       cd $enlistmentRootPath -ErrorAction SilentlyContinue;
       # Clone TFD Git repository
       git clone $privateRepoAccount -b $BranchName $enlistmentRootPath-"config" -q
   }
   cd $enlistmentRootPath-"config"

   if ( $tag -eq $null )
   {
       git checkout
       git pull
   }
    else
   {
       git checkout $tag -q
   }
}

## Function: Set-ScriptDefault
##
## Purpose: 
##    Validate parameter exists and log a message saying the default was set.
##
## Input: 
##   ScriptParamVal      supplied value of script parameter override if it is null or an empty string
##   ScriptParamName     name of script parameter being set to default value
##   DefaultValue        default value provided
##
## Output:
##   The DefaultValue parameter
##
function Set-ScriptDefault
{
    param(
            [Parameter(Mandatory=$true)][AllowEmptyString()][string]$ScriptParamVal,
            [Parameter(Mandatory=$true)][string]$ScriptParamName,
            [Parameter(Mandatory=$true)][string]$DefaultValue
         )

    $response = $ScriptParamVal
    if ($ScriptParamVal.Trim().Length -eq 0 -or $ScriptParamVal -eq $null)
    {        
        Log-Message "Falling back to default value: $($DefaultValue) for parameter $($ScriptParamName) since no value was provided"
        $response = $DefaultValue
    }

    return $response
}

<#
.SYNOPSIS
Creates or updates a secret in a key vault.

.DESCRIPTION
Creates or updates a secret in a key vault.

.PARAMETER VaultName
Specifies the name of the key vault to which this secret belongs.

.PARAMETER Name
Specifies the name of a secret to modify.

.PARAMETER SecretValue
Specifies the value for the secret as a SecureString object

.PARAMETER Context
Logging context that identifies the call

.PARAMETER MaxRetries
Maximum number of retries this call makes before failing. This defaults to 3.

.PARAMETER Quiet
Indicator of whether the underlying azure command will run in quiet mode or not.

.OUTPUTS
Microsoft.Azure.Commands.KeyVault.Models.Secret. Set-OxaKeyVaultSecret returns an azure key vault secret.
#>
function Set-OxaKeyVaultSecret
{
    param(
            [Parameter(Mandatory=$true)][string]$VaultName,
            [Parameter(Mandatory=$true)][string]$Name,
            [Parameter(Mandatory=$true)][SecureString]$SecretValue,
            [Parameter(Mandatory=$false)][string]$Context="Key Vault",
            [Parameter(Mandatory=$false)][int]$MaxRetries=3,
            [Parameter(Mandatory=$false)][switch]$Quiet
         )

    # prepare the inputs
    [hashtable]$inputParameters = @{
                                        "VaultName" = $VaultName;
                                        "Name" = $Name;
                                        "SecretValue" = $SecretValue;
                                        "Command" = "Set-AzureKeyVaultSecret";
                                        "Activity" = "Setting key vault secret: '$($Name)' to '$($VaultName)'"
                                        "ExecutionContext" = $Context;
                                        "MaxRetries" = $MaxRetries;
                                   };

    # this call doesn't require special error handling
    return Start-AzureCommand -InputParameters $inputParameters -Quiet:$Quiet;
}

<#
.SYNOPSIS
Deletes a secret in a key vault.

.DESCRIPTION
Deletes a secret in a key vault.

.PARAMETER VaultName
Specifies the name of the key vault to which this secret belongs.

.PARAMETER Name
Specifies the name of a secret to modify.

.PARAMETER Context
Logging context that identifies the call

.PARAMETER MaxRetries
Maximum number of retries this call makes before failing. This defaults to 3.

.PARAMETER Quiet
Indicator of whether the underlying azure command will run in quiet mode or not.

.OUTPUTS
None.
#>
function Remove-OxaKeyVaultSecret
{
    param(
        [Parameter(Mandatory=$true)][string]$VaultName,
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$false)][string]$Context="Key Vault",
        [Parameter(Mandatory=$false)][int]$MaxRetries=3,
        [Parameter(Mandatory=$false)][switch]$Quiet
     )

    # prepare the inputs
    [hashtable]$inputParameters = @{
                                        "VaultName" = $VaultName;
                                        "Name" = $Name;
                                        "Command" = "Remove-AzureKeyVaultSecret";
                                        "Activity" = "Removing key vault secret: '$($Name)' from '$($VaultName)'"
                                        "ExecutionContext" = $Context;
                                        "MaxRetries" = $MaxRetries;
                                };

    # this call doesn't require special error handling
    return Start-AzureCommand -InputParameters $inputParameters -Quiet:$Quiet;
}

<#
.SYNOPSIS
Find a certificate in the local current user certificate store with the given subject.

.DESCRIPTION
Find a certificate in the local current user certificate store with the given subject.

.PARAMETER CertSubject
Subject to search for in cert store.

.OUTPUTS
System.String. Get-CurrentUserCertificate returns the thumbprint of the specified certificate (if found) or null
#>
function Get-CurrentUserCertificate
{
    param( 
            [Parameter(Mandatory=$true)][string]$CertSubject,
            [Parameter(Mandatory=$false)][switch]$ThumbprintOnly
         )
    
    $response = $null
    $certStorePath = Get-OxaLocalCertificateStore

    # find the certificate
    $cert = (Get-ChildItem "cert:$($certStorePath)" | Where-Object {$_.Subject -match $CertSubject })
    
    if ($cert)
    {   
        if ($cert -is [array])
        {
            $cert = $cert[0]
        }

        $response = $cert
    }

    return $response
}

## Function: Get-JsonKeys
##
## Purpose: 
##    Return all top-level keys from a .json file
##
## Input: 
##   TargetPath  Path to .json file
##
## Output:
##   Array of top-level keys
##
function Get-KeyVaultKeyNames
{
    Param(        
            [Parameter(Mandatory=$true)][String] $TargetPath            
         )
        

    $keys = @()
    $json = Get-Content -Raw $TargetPath | Out-String | ConvertFrom-Json

    $json.psobject.properties | ForEach-Object {    
        $keys += $_.Name
    }    
    return $keys
}

<#
.SYNOPSIS
Gets the latest deployment version id from all available VMSS(s).

.DESCRIPTION
Gets the latest deployment version id from all available VMSS(s).

.PARAMETER DeploymentType
A switch to indicate the deployment type (any of bootstrap, upgrade, swap, cleanup).

.PARAMETER ResourceGroupName
Name of the Azure Resource group containing the network resources.

.PARAMETER DeploymentVersionId
Suggested deployment version id to use. This needs to be a timestamp in the following format: yyyyMMddHms

.PARAMETER MaxRetries
Maximum number of retries this call makes before failing. This defaults to 3.

.OUTPUTS
System.String. Get-DefaultDeploymentVersionId returns the appropriate default deployment version id for the resource group.
#>
function Get-DefaultDeploymentVersionId
{
    param( 
            [Parameter(Mandatory=$true)][ValidateSet("bootstrap", "upgrade", "swap", "cleanup")][string]$DeploymentType,
            [Parameter(Mandatory=$true)][string]$ResourceGroupName,
            [Parameter(Mandatory=$false)][string]$DeploymentVersionId="",
            [Parameter(Mandatory=$false)][int]$MaxRetries=3
         )

    $deploymentVersionIdFormat = "yyyyMMddHms";

    if ( $DeploymentType -ne "swap" )
    {
        # this covers: bootstrap, upgrade & cleanup
        # always default to the current timestamp for bootstrap & upgrade operations
        $DeploymentVersionId=$(get-date -f $deploymentVersionIdFormat);
    }
    else
    {
        # for swap operations, we have two options:
        # 1. if the user specified a DeploymentversionId, use it (do not change)
        # 2. if not, default to the most recently deployed VMSS based on the timestamp in its name
        if ( $DeploymentVersionId -eq "" )
        {
            $DeploymentVersionId = Get-LatestVmssDeploymentVersionId -ResourceGroupName $ResourceGroupName -MaxRetries $MaxRetries;
        }
        else 
        {
            # double check the value of the specified deployment version id (let any error bubble up)
            [datetime]::ParseExact($DeploymentVersionId, $deploymentVersionIdFormat, $null);
        }
    }

    return $DeploymentVersionId;
}

<#
.SYNOPSIS
Adds an Azure deployment to a resource group.

.DESCRIPTION
Adds an Azure deployment to a resource group.

.PARAMETER ResourceGroupName
Name of the azure resource group containing the network resources.

.PARAMETER TemplateFile
Specifies the full path of a JSON template file.

.PARAMETER TemplateParameterFile
Specifies the full path of a JSON file that contains the names and values of the template parameters.

.PARAMETER Context
Logging context that identifies the call

.PARAMETER MaxRetries
Maximum number of retries this call makes before failing. This defaults to 3.

.OUTPUTS
Microsoft.Azure.Commands.ResourceManager.Models.PSResourceGroupDeployment. New-OxaResourceGroupDeployment returns a resource group deployment object reflecting the status of the deployment.
#>
function New-OxaResourceGroupDeployment
{
    param(
            [Parameter(Mandatory=$true)][string]$ResourceGroupName,
            [Parameter(Mandatory=$true)][string]$TemplateFile,
            [Parameter(Mandatory=$true)][string]$TemplateParameterFile,
            [Parameter(Mandatory=$false)][string]$Context="Deploying",
            [Parameter(Mandatory=$false)][int]$MaxRetries=3
         )

    # prepare the inputs
    [hashtable]$inputParameters = @{
                                        "ResourceGroupName" = $ResourceGroupName;
                                        "TemplateFile" = $TemplateFile;
                                        "TemplateParameterFile" = $TemplateParameterFile;
                                        "Command" = "New-AzureRmResourceGroupDeployment";
                                        "Activity" = "Deploying OXA Stamp to '$($ResourceGroupName)'"
                                        "ExecutionContext" = $Context;
                                        "MaxRetries" = $MaxRetries;
                                   };

    # this call doesn't require special error handling
    return Start-AzureCommand -InputParameters $inputParameters;
}

<#
.SYNOPSIS
Gets the deployment completion message from all VMSS instances being deployed.

.DESCRIPTION
Gets the deployment completion message from all VMSS instances being deployed.

.PARAMETER ServiceBusNamespace
Name of the Azure Service bus resource

.PARAMETER ServiceBusQueueName
Name of the Azure Service bus Queue resource

.PARAMETER Saskey
Service bus authorization primary key

.PARAMETER SharedAccessPolicyName
Name of the shared access policy

.OUTPUTS
System.Array. Get-QueueMessages returns an array containing names of VMSS instances that have been successfully deployed.
#>
function Get-QueueMessages
{
    param(
            [Parameter(Mandatory=$true)][string]$ServiceBusNamespace,
            [Parameter(Mandatory=$true)][string]$ServiceBusQueueName,
            [Parameter(Mandatory=$true)][string]$Saskey,
            [Parameter(Mandatory=$false)][string]$SharedAccessPolicyName="RootManageSharedAccessKey"
         )

    # Log-Message "Receiving deployment status from $($ServiceBusNamespace)";
    $messages = @();

    # Rest api url to receive messages from Service bus queue
    # https://docs.microsoft.com/en-us/rest/api/servicebus/receive-and-delete-message-destructive-read
    $servicebusPeekLockRequestUrl = "https://$($ServiceBusNamespace).servicebus.windows.net/$($ServiceBusQueueName)/messages/head";
    
    # Generating SAS token to authenticate Service bus Queue to receive messages
    $authorizedSasToken = Get-SasToken -Saskey $Saskey -RequestUri $servicebusPeekLockRequestUrl -SharedAccessPolicyName $SharedAccessPolicyName;

    if (!$authorizedSasToken)
    {
        throw "Could not generate a SAS Token."
    }

    # Assigning generated SAS token to Service bus rest api headers to authorize
    $headers = @{'Authorization'=$authorizedSasToken};
    
    # keep peeking until there is no message
    $getMessage = $true;

    while($getMessage)
    {
        # invoking service bus queue rest api message url : destructive read
        $messageQueue = Invoke-WebRequest -Method DELETE -Uri $servicebusPeekLockRequestUrl -Headers $Headers;

        if (![string]::IsNullOrEmpty($messageQueue.content))
        {
            $messages += $messageQueue.content;
        }       
        else
        {
            $getMessage = $false;
        }
    }

    # Return all messages retrieved.
    # We expect the message body to contain the name of the server being deployed
    return $messages;
}

<#
.SYNOPSIS
Generates the SAS token with Service bus rest api url.

.DESCRIPTION
Generates the SAS token with Service bus rest api url.

.PARAMETER Saskey
Service bus authorization primary key

.PARAMETER SharedAccessPolicyName
Name of the Azure Service bus authorization rule

.PARAMETER RequestUri
Service bus rest api url to receive messages from the queue.

.OUTPUTS
System.String. Get-SasToken returns SAS token generated for Service bus rest api recieve message url.
#>
function Get-SasToken
{
    param(
            [Parameter(Mandatory=$true)][string]$Saskey,
            [Parameter(Mandatory=$true)][string]$RequestUri,
            [Parameter(Mandatory=$false)][string]$SharedAccessPolicyName="RootManageSharedAccessKey"
        )

    #checking SASKey Value    
    $sasToken = $null;

    #Encoding Service Bus Name space Rest api messaging url
    $encodedResourceUri = [uri]::EscapeUriString($RequestUri)
    
    # Setting expiry (12 hours)
    $sinceEpoch = (Get-Date).ToUniversalTime() - ([datetime]'1/1/1970')
    $durationSeconds = 12 * 60 * 60
    $expiry = [System.Convert]::ToString([int]($sinceEpoch.TotalSeconds) + $durationSeconds)
    $stringToSign = $encodedResourceUri + "`n" + $expiry
    $stringToSignBytes = [System.Text.Encoding]::UTF8.GetBytes($stringToSign)

    #Encoding Service bus SharedAccess Primary key pulled from ARM template
    $keyBytes = [System.Text.Encoding]::UTF8.GetBytes($Saskey)

    #Encoding Signature by HMACSHA256
    $hmac = [System.Security.Cryptography.HMACSHA256]::new($keyBytes)
    $hashOfStringToSign = $hmac.ComputeHash($stringToSignBytes)

    $signature = [System.Convert]::ToBase64String($hashOfStringToSign)

    # add the system web assembly
    Add-Type -AssemblyName System.Web
    $encodedSignature = [System.Web.HttpUtility]::UrlEncode($signature)   

    #Generating SAS token
    $sasToken = "SharedAccessSignature sr=$encodedResourceUri&sig=$encodedSignature&se=$expiry&skn=$($SharedAccessPolicyName)";
    
    return $sasToken;
}

<#
.SYNOPSIS
Get parameters associated with a specified script.

.DESCRIPTION
Get parameters associated with a specified script.

.PARAMETER ScriptFile
Path to the script file to query.

.PARAMETER Required
Switch indicating whether or not only required parameters will be returned.

.OUTPUTS
System.Array. Get-ScriptParameters returns and array of parameters and accompanying details associated with a specified script.
#>
function Get-ScriptParameters
{
    param(
            [Parameter(Mandatory=$true)][string]$ScriptFile,
            [Parameter(Mandatory=$false)][switch]$Required
        )

    $scriptFileHelpResults = Get-Help $ScriptFile -Detailed;

    $scriptParameters = $scriptFileHelpResults.parameters.parameter;

    if ($Required)
    {
        $scriptParameters = $scriptParameters | Where-Object { $_.Required -eq $true }
    }

    return $scriptParameters
}

<#
.SYNOPSIS
Gets all deployment-related settings/secrets in a key vault.

.DESCRIPTION
Gets all deployment-related settings/secrets in a key vault.

.PARAMETER ResourceGroupName
Name of the Azure Resource group containing the network resources.

.PARAMETER Context
Logging context that identifies the call.

.PARAMETER MaxRetries
Maximum number of retries this call makes before failing. This defaults to 3.

.PARAMETER WithoutValues
Indicator of whether secrets will be returned with their values or not.

.OUTPUTS
System.Array. Get-OxaDeploymentKeyVaultSettings returns an array of deployment-related key vault secrets.
#>
function Get-OxaDeploymentKeyVaultSettings
{
    param(
            [Parameter(Mandatory=$true)][string]$ResourceGroupName,
            [Parameter(Mandatory=$false)][int]$MaxRetries=3,
            [Parameter(Mandatory=$false)][string]$DeploymentParameterPrefix="DeploymentParamsxxx",
            [Parameter(Mandatory=$false)][switch]$WithoutValues
        )

    $keyVaultName = "$($ResourceGroupName)-kv"
    $keyVaultSecrets = Get-OxaKeyVaultSecret -VaultName $keyVaultName -MaxRetries $MaxRetries

    $secrets = $keyVaultSecrets | Where-Object { $_.Name -imatch "^$($DeploymentParameterPrefix)"}

    $response = @{}

    if ($WithoutValues)
    {
        $response = $secrets
    }
    elseif ($secrets)
    {
        Log-Message "Fetching value of secrets..."
        foreach($secret in $secrets)
        {
            # get the secret value
            $secretWithValue = Get-OxaKeyVaultSecret -VaultName $keyVaultName -Name $secret.Name -MaxRetries $MaxRetries -Quiet

            # add secret key/value pair to response hashtable
            $response[$secret.Name.replace($DeploymentParameterPrefix, "")] = $secretWithValue.SecretValueText
        }
    }

    return $response
}

<#
.SYNOPSIS
Gets the secrets in a key vault.

.DESCRIPTION
Gets the secrets in a key vault.

.PARAMETER VaultName
Specifies the name of the key vault to which the secret belongs.

.PARAMETER Name
Specifies the name of a secret to fetch.

.PARAMETER Context
Logging context that identifies the call

.PARAMETER MaxRetries
Maximum number of retries this call makes before failing. This defaults to 3.

.PARAMETER Quiet
Indicator of whether the underlying azure command will run in quiet mode or not.

.OUTPUTS
System.Array. Get-OxaKeyVaultSecret returns an array of keyvault secrets.
#>
function Get-OxaKeyVaultSecret
{
    param(
            [Parameter(Mandatory=$true)][string]$VaultName,
            [Parameter(Mandatory=$false)][string]$Name="",
            [Parameter(Mandatory=$false)][string]$Context="Key Vault",
            [Parameter(Mandatory=$false)][int]$MaxRetries=3,
            [Parameter(Mandatory=$false)][switch]$Quiet
         )

    # prepare the inputs
    [hashtable]$inputParameters = @{
                                        "VaultName" = $VaultName;
                                        "Name" = $Name;
                                        "Command" = "Get-AzureKeyVaultSecret";
                                        "Activity" = "Fetching key vault Secrets from '$($VaultName)'"
                                        "ExecutionContext" = $Context;
                                        "MaxRetries" = $MaxRetries;
                                   };

    # this call doesn't require special error handling
    return Start-AzureCommand -InputParameters $inputParameters -Quiet:$Quiet;
}

<#
.SYNOPSIS
Creates a new service principal with certiicate-based credential.

.DESCRIPTION
Creates a new service principal with certiicate-based credential.

.PARAMETER ResourceGroupName
Name of the azure resource group name.

.PARAMETER AadWebClientId
The azure active directory web application Id for authentication.

.PARAMETER AuthenticationCertificateSubject
The subject of the certificate used for authentication. 

.PARAMETER MaxRetries
Maximum number of retries this call makes before failing. This defaults to 3.

.OUTPUTS
None.
#>
function New-OxaCertificateBasedServicePrincipal
{
    Param(
            [Parameter(Mandatory=$true)][String] $ResourceGroupName,
            [Parameter(Mandatory=$true)][String] $AadWebClientId,
            [Parameter(Mandatory=$true)][String] $AuthenticationCertificateSubject,
            [Parameter(Mandatory=$false)][int]$MaxRetries=3
         )

    # get path to the local cert store
    $certStorePath = Get-OxaLocalCertificateStore

    # get the id of the azure subscription in context
    $SubscriptionId = (Get-AzureRmContext).Subscription.SubscriptionId

    ################################################
    # 1. Get or create Self-Signed Certificate
    ################################################
    $certificate = $null
    $certificateValue = $null

    try 
    {
        $certificate = Get-CurrentUserCertificate -CertSubject $AuthenticationCertificateSubject
        if (!$certificate)
        {
            Log-Message "Creating new Self-Signed Certificate..."    
            $certificate = New-SelfSignedCertificate -CertStoreLocation "cert:$($certStorePath)" -Subject $AuthenticationCertificateSubject -KeySpec KeyExchange
        }

        $certificateValue = [System.Convert]::ToBase64String($certificate.GetRawCertData())    
    }
    catch
    {
        Capture-ErrorStack;
        throw "Error obtaining certificate: $($_.Message)";
        exit;
    }
    
    ################################################
    # 2. Add new service principal to subscription
    ################################################

    # Get details for the service principal associated with the specified web application
    [array]$servicePrincipals = Get-OxaADServicePrincipal -ApplicationId $AadWebClientId -MaxRetries $MaxRetries
    
    if ($servicePrincipals -and $servicePrincipals[0].Id)
    {
        # certificate-based service principal exists, re-use it
        $servicePrincipal = $servicePrincipals[0]
        Log-Message "Service Principal - '$($servicePrincipal.DisplayName)' already exists. Re-using it."        
    }
    else
    {
        throw "Could not identify the service principal for the specified web application: $($AadWebClientId)."
    }

    # certificate-based service principal doesn't exist, create it
    Log-Message "Adding certificate-based credential to the service principal '$($servicePrincipal.DisplayName)'"

    $credential = New-OxaADSpCredential -ApplicationId $servicePrincipal.ApplicationId -CertValue $certificateValue -EndDate $certificate.NotAfter -StartDate $certificate.NotBefore -MaxRetries $MaxRetries
    
    if (!$credential)
    {
        throw "Unable to add certificate-based credential to the service principal '$($servicePrincipal.DisplayName)'"
    }
    
    # Following the creation of the service principal, there may be a bit of time lapse before 
    # the service principal application becomes active.
    # Incorporate that wait into the role assignment operation.
    [int]$waitIntervalSeconds = 5
    [int]$waitDurationSeconds = 0
    [int]$maxWaitDurationSeconds = $waitIntervalSeconds * 12
    [bool]$awaitingServicePrincipalRoleAssignment = $true

    while($awaitingServicePrincipalRoleAssignment)
    {
        try 
        {
            $response = New-OxaRoleAssignment -ServicePrincipalName $servicePrincipal.ApplicationId -Scope "/subscriptions/$($SubscriptionId)" -RoleDefinitionName "Contributor" -MaxRetries $MaxRetries

            # operation succeeded
            $awaitingServicePrincipalRoleAssignment = $false
        }
        catch [Hyak.Common.CloudException]
        {
            $expectedException = "The role assignment already exists."

            if ($_.Exception.Message -imatch $expectedException)
            {
                # the role already exists, there's nothing more to do
                Log-Message "'$($servicePrincipal.DisplayName)' already has access to the the subscription."
                $awaitingServicePrincipalRoleAssignment = $false
            }
        }
        catch
        {
            # display the error information
            Capture-ErrorStack

            Log-Message "Waiting $($waitIntervalSeconds) seconds for service principal application to be created"
            Start-Sleep -Seconds $waitIntervalSeconds    
        }
        
        # check if the wait duration has been exceeded
        $waitDurationSeconds += $waitIntervalSeconds

        if ($waitDurationSeconds -gt $maxWaitDurationSeconds)
        {
            throw "Could not complete the role assignment for the service principal"
        }
    }
    
    ################################################
    # 3. Allow Service Principal Key Vault access
    ################################################

    try
    {

        # setup the key vault name associated with the resource group
        $keyVaultName = "$($ResourceGroupName)-kv"
        
        Log-Message "Setting Key Vault Access policy for Key Vault: $($keyVaultName) and Service Principal: $($servicePrincipal.DisplayName)"
        Set-OxaKeyVaultAccessPolicy -VaultName $keyVaultName `
                                    -ServicePrincipalName $servicePrincipal.ApplicationId `
                                    -PermissionsToSecrets get,set,list,delete `
                                    -ResourceGroupName $ResourceGroupName `
                                    -MaxRetries $MaxRetries 

    }
    catch
    {
        Capture-ErrorStack;
        throw "Error adding access policy to allow new Service Principal to use Key Vault - $($keyVaultName): $($_.Message)";
        exit;
    }
}

<#
.SYNOPSIS
Get the path for local certificate store where OXA deployment certificates are located. 

.DESCRIPTION
Get the path for local certificate store where OXA deployment certificates are located. 

.OUTPUTS
System.String. Get-OxaLocalCertificateStore returns certificate store path.
#>
function Get-OxaLocalCertificateStore
{
    return "\CurrentUser\My"
}

<#
.SYNOPSIS
Set Key Vault secrets from a .json file. 

.DESCRIPTION
Set Key Vault secrets from a .json file. 

See /config/stamp/default/keyvault-params.json file for example file. 
This call expects prior successful authentication and access to specified Key Vault.

.PARAMETER ResourceGroupName
Name of the azure resource group where Key Vault is

.PARAMETER KeyVaultName
Name of Key Vault instance to provide populate secrets

.PARAMETER SettingsFile
Path to deployment settings to upload to keyvault

This parameter is optional. When set, the deployment populates keyvault with the specified deployment-related settings/secrets.
The file should be a json file with key:value pairs representing setting name and setting value.

.PARAMETER Prefix
The prefix to use for naming the setting/secret. 

The prefix allows grouping of settings/secrets in keyvault for easy retrieval by group.

.PARAMETER MaxRetries
Maximum number of retries this call makes before failing. This defaults to 3.

.OUTPUTS
System.Array. Get-ScriptParameters returns and array of parameters and accompanying details associated with a specified script.
#>
function Set-KeyVaultSecretsFromFile
{
    Param(
            [Parameter(Mandatory=$true)][String] $ResourceGroupName,
            [Parameter(Mandatory=$true)][String] $KeyVaultName,
            [Parameter(Mandatory=$true)][String] $SettingsFile,
            [Parameter(Mandatory=$true)][string]$Prefix,
            [Parameter(Mandatory=$false)][int]$MaxRetries=3
         )

    if ((Test-Path -Path $SettingsFile) -eq $false)
    {
        throw "The specified keyvault settings file was not found: $($SettingsFile)"
    }
    
    # Remove all existing secrets
    [array]$keyVaultSecrets = Get-OxaDeploymentKeyVaultSettings -ResourceGroupName $ResourceGroupName -MaxRetries $MaxRetries -WithoutValues
    
    Log-Message "Purging existing secrets..."
    foreach($secret in $keyVaultSecrets)
    {
        Remove-OxaKeyVaultSecret -VaultName $KeyVaultName -Name $secret.Name -Quiet
    }

    # Push new secrets to key vault
    $json = Get-Content -Raw $SettingsFile | Out-String | ConvertFrom-Json

    Log-Message "Syncing settings/secrets to key vault: $($KeyVaultName)"

    $json.psobject.properties | ForEach-Object { 

        Log-Message "Syncing $($_.Name) ..." -NoNewLine

        # TODO: why the value check? 
        # Isn't it possible to setup blank values. At least the secret would have been setup
        if ($_.Value)
        {
            # Create a new secret
            $secretvalue = ConvertTo-SecureString $_.Value -AsPlainText -Force
                
            try
            {
                # Store the secret in Azure Key Vault
                # using a prefix for the name allows support for grouping keyvault settings
                $response = Set-OxaKeyVaultSecret -VaultName $KeyVaultName -Name "$($Prefix)$($_.Name)" -SecretValue $secretvalue -MaxRetries $MaxRetries -Quiet
                if (!$response)
                {
                    throw "Could not create the keyvault secret: $($_.Name)."
                }

                Log-Message "[OK]." -Foregroundcolor Green -SkipTimestamp
            }
            catch
            {
                Log-Message "[Failed]." -Foregroundcolor Red -SkipTimestamp
                Capture-ErrorStack;
                throw $($_.Message)
            }
        }
        else
        {
            Log-Message "[Skipped]." -Foregroundcolor Yellow -SkipTimestamp
        }
    }
}

<#
.SYNOPSIS
Filters active directory service principals.

.DESCRIPTION
Filters active directory service principals.

.PARAMETER DisplayName
Display name of the service principal.

.PARAMETER ApplicationId
Application Id of the service principal.

.PARAMETER Context
Logging context that identifies the call

.PARAMETER MaxRetries
Maximum number of retries this call makes before failing. This defaults to 3.

.OUTPUTS
System.Array. Get-OxaADServicePrincipal returns an array of Microsoft.Azure.Graph.RBAC.Version1_6.ActiveDirectory.PSADServicePrincipal objects
#>
function Get-OxaADServicePrincipal
{
    param(
            [Parameter(Mandatory=$false)][string]$DisplayName="",
            [Parameter(Mandatory=$false)][string]$ApplicationId="",
            [Parameter(Mandatory=$false)][string]$Context="Azure Active Directory",
            [Parameter(Mandatory=$false)][int]$MaxRetries=3
         )

    # prepare the inputs
    [hashtable]$inputParameters = @{
                                        "DisplayName" = $DisplayName;
                                        "ApplicationId" = $ApplicationId;
                                        "Command" = "Get-AzureRmADServicePrincipal";
                                        "Activity" = "Getting Service Principal from AAD: DisplayName='$($DisplayName)' or ApplicationId='$($ApplicationId)'"
                                        "ExecutionContext" = $Context;
                                        "MaxRetries" = $MaxRetries;
                                   };

    # this call doesn't require special error handling
    return Start-AzureCommand -InputParameters $inputParameters
}

<#
.SYNOPSIS
Creates a new azure active directory service principal.

.DESCRIPTION
Creates a new azure active directory service principal.

.PARAMETER DisplayName
The unique display name the service principal in a tenant. Once created this property cannot be changed.

.PARAMETER CertValue
The value of the "asymmetric" credential type. It represents the base 64 encoded certificate.

.PARAMETER EndDate
The effective end date of the credential usage. The default end date value is one year from today. For an "asymmetric" type credential, this must be set to on or before the date that the X509 certificate is valid.

.PARAMETER StartDate
The effective start date of the credential usage. The default start date value is today. For an "asymmetric" type credential, this must be set to on or after the date that the X509 certificate is valid from.

.PARAMETER Context
Logging context that identifies the call

.PARAMETER MaxRetries
Maximum number of retries this call makes before failing. This defaults to 3.

.OUTPUTS
Microsoft.Azure.Graph.RBAC.Version1_6.ActiveDirectory.PSADServicePrincipal. New-OxaADServicePrincipal returns an AAD service principal object
#>
function New-OxaADServicePrincipal
{
    param(
            [Parameter(Mandatory=$true)][string]$DisplayName,
            [Parameter(Mandatory=$true)][string]$CertValue,            
            [Parameter(Mandatory=$true)][datetime]$EndDate,
            [Parameter(Mandatory=$true)][datetime]$StartDate,
            [Parameter(Mandatory=$false)][string]$Context="Azure Active Directory",
            [Parameter(Mandatory=$false)][int]$MaxRetries=3
         )

    # prepare the inputs
    [hashtable]$inputParameters = @{
                                        "DisplayName" = $DisplayName;
                                        "CertValue" = $CertValue;
                                        "EndDate" = $EndDate;
                                        "StartDate" = $StartDate;
                                        "Command" = "New-AzureRMADServicePrincipal";
                                        "Activity" = "Creating new service principal for Application: '$($DisplayName)'"
                                        "ExecutionContext" = $Context;
                                        "MaxRetries" = $MaxRetries;
                                   };

    # this call doesn't require special error handling
    return Start-AzureCommand -InputParameters $inputParameters
}

<#
.SYNOPSIS
Adds a credential to an existing service principal.

.DESCRIPTION
Adds a credential to an existing service principal.

.PARAMETER ApplicationId
The id of the application to add the credentials to.

.PARAMETER CertValue
The value of the "asymmetric" credential type. It represents the base 64 encoded certificate.

.PARAMETER EndDate
The effective end date of the credential usage. The default end date value is one year from today. For an "asymmetric" type credential, this must be set to on or before the date that the X509 certificate is valid.

.PARAMETER StartDate
The effective start date of the credential usage. The default start date value is today. For an "asymmetric" type credential, this must be set to on or after the date that the X509 certificate is valid from.

.PARAMETER Context
Logging context that identifies the call

.PARAMETER MaxRetries
Maximum number of retries this call makes before failing. This defaults to 3.

.OUTPUTS
Microsoft.Azure.Graph.RBAC.Version1_6.ActiveDirectory.PSADCredential. New-OxaADSpCredential returns an AAD service principal credential object.
#>
function New-OxaADSpCredential
{
    param(
            [Parameter(Mandatory=$true)][string]$ApplicationId,
            [Parameter(Mandatory=$true)][string]$CertValue,            
            [Parameter(Mandatory=$true)][datetime]$EndDate,
            [Parameter(Mandatory=$true)][datetime]$StartDate,
            [Parameter(Mandatory=$false)][string]$Context="Azure Active Directory",
            [Parameter(Mandatory=$false)][int]$MaxRetries=3
         )

    # prepare the inputs
    [hashtable]$inputParameters = @{
                                        "ApplicationId" = $ApplicationId;
                                        "CertValue" = $CertValue;
                                        "EndDate" = $EndDate;
                                        "StartDate" = $StartDate;
                                        "Command" = "New-AzureRmADSpCredential";
                                        "Activity" = "Creating new service principal credential for Application: '$($ApplicationId)'"
                                        "ExecutionContext" = $Context;
                                        "MaxRetries" = $MaxRetries;
                                   };

    # this call doesn't require special error handling
    return Start-AzureCommand -InputParameters $inputParameters
}

<#
.SYNOPSIS
Creates a new azure active directory service principal.

.DESCRIPTION
Creates a new azure active directory service principal.

.PARAMETER ApplicationId
The unique application id for a service principal in a tenant. Once created this property cannot be changed. If an application id is not specified, one will be generated

.PARAMETER CertValue
The value of the "asymmetric" credential type. It represents the base 64 encoded certificate.

.PARAMETER EndDate
The effective end date of the credential usage. The default end date value is one year from today. For an "asymmetric" type credential, this must be set to on or before the date that the X509 certificate is valid.

.PARAMETER StartDate
The effective start date of the credential usage. The default start date value is today. For an "asymmetric" type credential, this must be set to on or after the date that the X509 certificate is valid from.

.PARAMETER Context
Logging context that identifies the call

.PARAMETER MaxRetries
Maximum number of retries this call makes before failing. This defaults to 3.

.OUTPUTS
Microsoft.Azure.Graph.RBAC.Version1_6.ActiveDirectory.PSADServicePrincipal. New-OxaADServicePrincipal returns an AAD service principal object
#>
function New-OxaRoleAssignment
{
    param(
            [Parameter(Mandatory=$true)][string]$ServicePrincipalName,            
            [Parameter(Mandatory=$true)][string]$Scope,
            [Parameter(Mandatory=$false)][string]$RoleDefinitionName="Contributor",
            [Parameter(Mandatory=$false)][string]$Context="Azure Active Directory",
            [Parameter(Mandatory=$false)][int]$MaxRetries=3
         )

    # prepare the inputs
    [hashtable]$inputParameters = @{
                                        "ServicePrincipalName" = $ServicePrincipalName;
                                        "Scope" = $Scope;
                                        "RoleDefinitionName" = $RoleDefinitionName;
                                        "Command" = "New-AzureRMRoleAssignment";
                                        "Activity" = "Assigning '$($RoleDefinitionName)' role to service principal: '$($ServicePrincipalName)'"
                                        "ExecutionContext" = $Context;
                                        "MaxRetries" = $MaxRetries;
                                        "ExpectedException" = "The role assignment already exists."
                                   };

    # this call doesn't require special error handling
    return Start-AzureCommand -InputParameters $inputParameters
}


<#
.SYNOPSIS
Grants or modifies existing permissions for a user, application, or security group to perform operations with a key vault.

.DESCRIPTION
Grants or modifies existing permissions for a user, application, or security group to perform operations with a key vault.

.PARAMETER VaultName
Specifies the name of a key vault. This cmdlet modifies the access policy for the key vault that this parameter specifies.

.PARAMETER ServicePrincipalName
Specifies the service principal name of the application to which to grant permissions.

.PARAMETER PermissionsToSecrets
Specifies an array of secret operation permissions to grant to a user or service principal.

.PARAMETER ResourceGroupName
Name of the Azure Resource group containing the network resources.

.PARAMETER Context
Logging context that identifies the call

.PARAMETER MaxRetries
Maximum number of retries this call makes before failing. This defaults to 3.

.OUTPUTS
Microsoft.Azure.Commands.KeyVault.Models.PSVault. Set-OxaKeyVaultAccessPolicy returns a key vault object
#>
function Set-OxaKeyVaultAccessPolicy
{
    param(
            [Parameter(Mandatory=$true)][string]$VaultName,            
            [Parameter(Mandatory=$true)][string]$ServicePrincipalName,
            [Parameter(Mandatory=$true)][array]$PermissionsToSecrets,
            [Parameter(Mandatory=$true)][string]$ResourceGroupName,
            [Parameter(Mandatory=$false)][string]$Context="Key Vault",
            [Parameter(Mandatory=$false)][int]$MaxRetries=3
         )

    # prepare the inputs
    [hashtable]$inputParameters = @{
                                        "VaultName" = $VaultName;
                                        "ServicePrincipalName" = $ServicePrincipalName;
                                        "PermissionsToSecrets" = $PermissionsToSecrets;
                                        "ResourceGroupName" = $ResourceGroupName;
                                        "Command" = "Set-AzureRmKeyVaultAccessPolicy";
                                        "Activity" = "Granting service principal '$($ServicePrincipalName)' access to '$($VaultName)'"
                                        "ExecutionContext" = $Context;
                                        "MaxRetries" = $MaxRetries;
                                   };

    # this call doesn't require special error handling
    return Start-AzureCommand -InputParameters $inputParameters
}

<#
.SYNOPSIS
Gets the primary and secondary connection strings for the namespace.

.DESCRIPTION
Gets the primary and secondary connection strings for the namespace.

.PARAMETER AuthorizationRuleName
ServiceBus Namespace AuthorizationRule Name.

.PARAMETER NamespaceName
ServiceBus Namespace Name.

.PARAMETER ResourceGroup
The name of the resource group.

.PARAMETER Context
Logging context that identifies the call

.PARAMETER MaxRetries
Maximum number of retries this call makes before failing. This defaults to 3.

.OUTPUTS
Microsoft.Azure.Management.ServiceBus.Models.ResourceListKeys. Set-OxaServiceBusNamespaceKey returns list of resource keys for the specified service bus resource.
#>
function Get-OxaServiceBusNamespaceKey
{
    param(
            [Parameter(Mandatory=$true)][string]$NamespaceName,
            [Parameter(Mandatory=$true)][string]$ResourceGroup,
            [Parameter(Mandatory=$false)][string]$AuthorizationRuleName="RootManageSharedAccessKey",
            [Parameter(Mandatory=$false)][string]$Context="Service Bus",
            [Parameter(Mandatory=$false)][int]$MaxRetries=3
         )

    # prepare the inputs
    [hashtable]$inputParameters = @{
                                        "ResourceGroup" = $ResourceGroup
                                        "NamespaceName" = $NamespaceName
                                        "AuthorizationRuleName" = $AuthorizationRuleName
                                        "Command" = "Get-AzureRmServiceBusNamespaceKey"
                                        "Activity" = "Getting service bus namespace key: '$($AuthorizationRuleName)' in '$($NamespaceName)'"
                                        "ExecutionContext" = $Context
                                        "MaxRetries" = $MaxRetries
                                   };

    # this call doesn't require special error handling
    return Start-AzureCommand -InputParameters $inputParameters
}


<#
.SYNOPSIS
Log into Azure account using AAD web application or certificate.

.DESCRIPTION
Log into Azure account using AAD web application or certificate.

.PARAMETER AzureSubscriptionName
Name of the azure subscription to use.

.PARAMETER AadWebClientId
The azure active directory web application Id for authentication.

.PARAMETER AadTenantId
The azure active directory tenant id for authentication.

.PARAMETER AuthenticationCertificateSubject
The subject of the certificate used for authentication.

.PARAMETER AadWebClientAppKey
The azure active directory web application key for authentication.

.PARAMETER ResourceGroupName
Name of the Azure Resource group containing the network resources.

.PARAMETER MaxRetries
Maximum number of retries this call makes before failing. This defaults to 3.

.OUTPUTS
None.
#>
function Login-OxaAccount
{
    param(
            [Parameter(Mandatory=$true)][string]$AzureSubscriptionName,
            [Parameter(Mandatory=$true)][string]$AadWebClientId,
            [Parameter(Mandatory=$true)][string]$AadTenantId,
            [Parameter(Mandatory=$false)][string]$AuthenticationCertificateSubject="",
            [Parameter(Mandatory=$false)][string]$AadWebClientAppKey="",
            [Parameter(Mandatory=$false)][string]$ResourceGroupName="",
            [Parameter(Mandatory=$false)][int]$MaxRetries=3
         )

    # track the response code for the login operation: 
    # 0=Login with Required Access
    # 1=Login with Limited Access

    $responseCode = 0

    # make sure we have the right parameters specified
    # Preference is given to certificate based login, followed by key-based login
    if ($AadWebClientAppKey)
    {
        # if both credentials are specified, establish certificate as replacement for AAD web application authentication
        if ($AuthenticationCertificateSubject -and $ResourceGroupName)
        {
            # if we are setting up a new SPN, the web application owner needs to login
            Log-Message "Setting up certificate authentication. Web Application owner needs to login..."

            Log-Message "Logging into azure account..."
            Login-AzureRmAccount -ErrorAction Stop | Out-Null

            Log-Message "Selecting '$($AzureSubscriptionName)' subscription"
            Select-AzureRMSubscription -SubscriptionName $AzureSubscriptionName | Out-Null


            New-OxaCertificateBasedServicePrincipal -AadWebClientId $AadWebClientId `
                                                    -AuthenticationCertificateSubject $AuthenticationCertificateSubject `
                                                    -ResourceGroupName $ResourceGroupName `
                                                    -MaxRetries $MaxRetries

            # This is a user login. 
            # Under this mode, all keyvault interactions will fail with 'Access Denied' error. 
            # Therefore, this login gives limited access
            $responseCode = 1
        }
        else 
        {
            Log-Message "Logging in with Web Client App Key"

            # Credentials for regular Aad Web Application authentication are available.
            $clientSecret = ConvertTo-SecureString -String $AadWebClientAppKey -AsPlainText -Force
            $aadCredential = New-Object System.Management.Automation.PSCredential($AadWebClientId, $clientSecret)
            Login-AzureRmAccount -ServicePrincipal -TenantId $AadTenantId -SubscriptionName $AzureSubscriptionName -Credential $aadCredential -ErrorAction Stop | Out-Null
    
            Log-Message "Selecting '$($AzureSubscriptionName)' subscription"
            Select-AzureRMSubscription -SubscriptionName $AzureSubscriptionName | Out-Null
        }
    }
    elseif ($AuthenticationCertificateSubject)
    {
        Log-Message "Logging in with Authentication Certificate"
        $certificate = Get-CurrentUserCertificate -CertSubject $AuthenticationCertificateSubject

        if (!$certificate)
        {
            throw "$($AuthenticationCertificateSubject) was not found in the current user certificate store"
        }

        Login-AzureRmAccount -ServicePrincipal -CertificateThumbprint $certificate.thumbprint -ApplicationId $AadWebClientId -TenantId $AadTenantId -ErrorAction Stop | Out-Null

        Log-Message "Selecting '$($AzureSubscriptionName)' subscription"
        Select-AzureRMSubscription -SubscriptionName $AzureSubscriptionName | Out-Null
    }
    else 
    {
        throw "Invalid credentials specified"
    }


    if ($responseCode -eq 1)
    {
        if ($AadWebClientAppKey)
        {
            # authenticated with limited access
            # run login again but this time switch to certificate based authentication
            # note: AadWebClientAppKey has been removed. This ensures this path is executed only once
            $responseCode = Login-OxaAccount -AzureSubscriptionName $AzureSubscriptionName `
                                             -AadWebClientId $AadWebClientId `
                                             -AadTenantId $AadTenantId `
                                             -AuthenticationCertificateSubject $authenticationCertificateSubject `
                                             -ResourceGroupName $ResourceGroupName `
                                             -MaxRetries $MaxRetries
        }
        else 
        {
            # certificate based authentication has been attempted and failed
            throw "Unable to authenticate with an account having the requisite permissions to the subscription and all its resources (ie: keyvault)"
        }
    }

    return $responseCode
}

<#
.SYNOPSIS
Apply transforms to relevant variables.

.DESCRIPTION
Apply transforms to relevant variables.

.PARAMETER ScriptParameters
Array of parameters and their properties.

.PARAMETER AvailableParameters
Parameters from key vault and their values.

.OUTPUTS
System.Hashtable. Set-DeploymentParameterValues returns an updated list of available parameters.
#>
function Set-DeploymentParameterValues
{
    param(
            [Parameter(Mandatory=$true)][array]$ScriptParameters,
            [Parameter(Mandatory=$true)][hashtable]$AvailableParameters
        )

    # get a new reference tothe parameters to avoid interupting the enumeration
    $updatedParameters = @{}
    $mainDeploymentScriptParameters = @{}

    foreach($parameterName in $AvailableParameters.keys)
    {
        $paramDetails = $ScriptParameters | Where-Object {$_.Name -ieq $parameterName}

        if ($paramDetails)
        {
            $mainDeploymentScriptParameters[$parameterName] = $AvailableParameters[$parameterName]
        }

        try 
        {
            if ($paramDetails.Type.Name -ieq "SwitchParameter")
            {
                if ($AvailableParameters[$parameterName].GetType().ToString() -ieq "System.Management.Automation.SwitchParameter")
                {
                    $updatedParameters[$parameterName] = $AvailableParameters[$parameterName]
                }
                else
                {
                    $updatedParameters[$parameterName] = [System.Convert]::ToBoolean([int]$AvailableParameters[$parameterName])
                }
            }
            elseif($paramDetails.Type -ieq "Int")
            {
                $updatedParameters[$parameterName] = [System.Convert]::ToInt16($AvailableParameters[$parameterName])
            }    
        }
        catch 
        {
            Capture-ErrorStack    
            exit
        }
    }

    foreach($key in $updatedParameters.Keys)
    {
        $AvailableParameters[$key] = $updatedParameters[$key]

        if ($mainDeploymentScriptParameters.ContainsKey($key))
        {
            $mainDeploymentScriptParameters[$key] = $updatedParameters[$key]
        }
    }

    $response  = @{
                    "UpdatedParameters"=$AvailableParameters
                    "PurgedParameters"=$mainDeploymentScriptParameters
                  }

    return $response
}

<#
.SYNOPSIS
Add one or more message recipients to an email message.

.DESCRIPTION
Add one or more message recipients to an email message.

.PARAMETER Message
Email message object.

.PARAMETER Recipients
Comma-separated list of email addresses

.PARAMETER RecipientType
Type of message recipient to add to the message.

.OUTPUTS
System.Object. Add-MessageRecipient returns an updated message object with recipient(s) added.
#>
function Add-MessageRecipients
{
    param 
    (
        [Parameter(Mandatory=$true)][object]$Message,
        [Parameter(Mandatory=$false)][string]$Recipients,
        [Parameter(Mandatory=$true)][validateset("To", "CC")][string]$Target
    )

    if($Recipients.Trim().Length -gt 0)
    {
        $recipientList = $Recipients.Split(",");
        foreach($recipient in $recipientList)
        {
            # defensive: if the recipient specified is blank, skip it
            if ($recipient.trim().length -eq 0)
            {
                continue;
            }

            Log-Message "Adding recipient : $($recipient)";
            if ($Target -eq "To")
            {
                $Message.To.Add($recipient);
            }
            else
            {
                $Message.CC.Add($recipient);
            }
        }
    }

    return $Message;
}

<#
.SYNOPSIS
Gets the value of a parameter by from from a hashtable of key-value pairs.

.DESCRIPTION
Gets the value of a parameter by from from a hashtable of key-value pairs.

.PARAMETER Parameters
Hashtable of key-value pairs.

.PARAMETER ParameterName
Name of the parameter.

.PARAMETER Required
Indicator of whether or not the specified parameter is required.

If the parameter is required and is not found, an error is thrown.

.OUTPUTS
System.Object. Get-ParameterValue returns $null or the value of the specified parameter.
#>
function Get-ParameterValue
{
    param 
    (
        [Parameter(Mandatory=$true)][hashtable]$Parameters,
        [Parameter(Mandatory=$true)][string]$ParameterName,
        [Parameter(Mandatory=$false)][switch]$Required
    )

    $parameterValue = $null
    if ($Parameters.ContainsKey($ParameterName))
    {
        $parameterValue = $Parameters[$ParameterName]
    }
    elseif ($Required)
    {
        # parameter is required but not present
        throw "$($ParameterName) is not present"
    }

    return $parameterValue
}

<#
.SYNOPSIS
Sends a deployment notification email.

.DESCRIPTION
Sends a deployment notification email.

.PARAMETER Subject
Subject of the email.

.PARAMETER MessageBody
Body of the email.

.PARAMETER Parameters
Hashtable of key-value pairs holding required parameters for sending email.

It is expected that parameters will have key-value pairs for:
1. EmailSenderAddress - address of the email sender
2. DeploymentNotificationRecipients - comma-separated list of email address representing recipients of the email
3. ClusterAdministratorEmailAddress - email address of the cluster administrator
4. SmtpServer - SMTP server used for sending email
5. SmtpServerPort - SMTP server port
6. SmtpAuthenticationUser - User name (credential) used for authenticating against the SMTP server
7. SmtpAuthenticationUserPassword - Password (credential) used for authenticating against the SMTP server

.OUTPUTS
System.Object. Get-ParameterValue returns $null or the value of the specified parameter.
#>
function New-DeploymentNotificationEmail
{
    param 
    (
        [Parameter(Mandatory=$true)][string]$Subject,
        [Parameter(Mandatory=$true)][string]$MessageBody,
        [Parameter(Mandatory=$true)][hashtable]$Parameters
    )

    if ($Parameters['DisableEmails'])
    {
        Log-Message "Skipping email notification since DisableEmails=$($Parameters['DisableEmails'])";
        return;
    }

    # get the relevant parameters
    $fromServiceAccount = Get-ParameterValue -Parameters $Parameters -ParameterName "EmailSenderAddress" -Required
    $deploymentNotificationRecipients = Get-ParameterValue -Parameters $Parameters -ParameterName "DeploymentNotificationRecipients" -Required
    $clusterAdministratorEmailAddress = Get-ParameterValue -Parameters $Parameters -ParameterName "ClusterAdministratorEmailAddress" -Required
    $smtpServer = Get-ParameterValue -Parameters $Parameters -ParameterName "SmtpServer" -Required
    $smtpServerPort = Get-ParameterValue -Parameters $Parameters -ParameterName "SmtpServerPort" -Required
    $smtpAuthenticationUser = Get-ParameterValue -Parameters $Parameters -ParameterName "SmtpAuthenticationUser" -Required
    $smtpAuthenticationUserPassword = Get-ParameterValue -Parameters $Parameters -ParameterName "SmtpAuthenticationUserPassword" -Required

    # create a new message object & update properties
    $message = New-Object System.Net.Mail.MailMessage
    $message.From = $fromServiceAccount

    # send to notification audience
    $message = Add-MessageRecipients -Message $message -Recipients $deploymentNotificationRecipients -Target To

    # always cc the admin
    $message = Add-MessageRecipients -Message $message -Recipients $clusterAdministratorEmailAddress -Target CC

    # setup subject
    $message.Subject = $Subject

    # setup message
    $message.IsBodyHTML = $true
    $message.Body = $MessageBody
    
    Log-Message "Attempting to send message using $($smtpServer)..." -NoNewLine
    $smtpClient = New-Object System.Net.Mail.SmtpClient($smtpServer, $smtpServerPort)
    $smtpClient.EnableSSL = $true
    $smtpClient.Credentials = New-Object System.Net.NetworkCredential($smtpAuthenticationUser, $smtpAuthenticationUserPassword)

    try
    {
        $smtpClient.Send($message)
        Log-Message "[OK]" -Foregroundcolor Green -SkipTimestamp
    }
    catch
    {
        Log-Message "[Failed]" -Foregroundcolor Red -SkipTimestamp
        Log-Message "Failed sending message using $($smtpServer): $($_)"
    }
}

<#
.SYNOPSIS
Starts a windows process executing the command specified.

.DESCRIPTION
Starts a windows process executing the command specified.

.PARAMETER ProcessExecutablePath
Path to the executable.

.PARAMETER ArgumentList
Arguments for the executable.

.PARAMETER Context
Logging context that identifies the call

.PARAMETER MaxRetries
Maximum number of retries this call makes before failing. This defaults to 3.

.PARAMETER Quiet
Indicator of whether or not to print the output of the command executed.

.OUTPUTS
System.Object. Invoke-OxaProcess returns the output of the command executed.
#>
function Invoke-OxaProcess
{
    param(
            [Parameter(Mandatory=$true)][string]$ProcessExecutablePath, 
            [Parameter(Mandatory=$true)][string]$ArgumentList, 
            [Parameter(Mandatory=$false)][string]$Context="Run Process",
            [Parameter(Mandatory=$false)][int]$MaxRetries=3,
            [Parameter(Mandatory=$false)][switch]$Quiet
         )

    $response = $null;
    $retryAttempts = 1;
    while ($retryAttempts -le $MaxRetries)
    {
        try
        {
            [string]$redirectStandardOutput = [IO.Path]::GetTempFileName();
            [string]$redirectErrorOutput = [IO.Path]::GetTempFileName();

            if ($Silent -eq $false)
            {
                Log-Message "Attempt [$($retryAttempts)|$($MaxRetries)] - Running process: $($ProcessExecutablePath) $($ArgumentList) | Output: $($RedirectStandardOutput)" -Context $Context;
            }

            # verify our temp files are available
            if ( !(Test-Path -Path $redirectStandardOutput)) 
            {  
                throw "Could not generate a temp file. Please try again."
            }

            $returnProcess = Start-Process -FilePath $ProcessExecutablePath -ArgumentList $ArgumentList -RedirectStandardOutput $RedirectStandardOutput -RedirectStandardError $redirectErrorOutput -PassThru -Wait -WindowStyle Hidden;
            
            # check if we have to return the response from the command execution
            $stdOutput = get-content -Path $RedirectStandardOutput -Encoding Ascii;
            $stdError = get-content -Path $redirectErrorOutput -Encoding Ascii;
            $response = $stdOutput;
            
            if(($stdError.Length -gt 0 -or $stdOutput.Length -gt 0) -and ($Silent -eq $false))
            {
                Log-Message $response;
                Log-Message $stdError;
            }

            if ($returnProcess.ExitCode -ne 0)
	        {
                Log-Message "Attempt [$($retryAttempt)|$($MaxRetries)] : Process execution failed." -Context $Context;
                throw "Failed executing $($ProcessExecutablePath). Exit Code: $($returnProcess.ExitCode)"
	        }
            else
            {
                Log-Message "Attempt [$($retryAttempts)|$($MaxRetries)] :  Process execution succeeded" -Context $Context;
                $retryAttempts = $MaxRetries;
            }
        }
        catch
        {
            Capture-ErrorStack;
            
            # check if we have exceeded our retry count
            if ($retryAttempts -eq $MaxRetries)
            {
                # we have had 3 tries and failed when an error wasn't expected. throwing a fit.
                throw "Process Execution Failed: Unable to execute $($ProcessExecutablePath) $($ArgumentList). `r`n Error $($_)";
            }
        }
        finally
        {
            # clean after 
            if ($redirectStandardOutput -and (Test-Path $redirectStandardOutput) -eq $true)
            {
                Remove-Item -Path $redirectStandardOutput -Force | Out-Null;
            }

            if ($redirectErrorOutput -and (Test-Path $redirectErrorOutput) -eq $true)
            {
                Remove-Item -Path $redirectErrorOutput -Force | Out-Null;
            }
        }

        $retryAttempts++;
    }

    return $response;
}

<#
.SYNOPSIS
Sync the specified repository.

.DESCRIPTION
Sync the specified repository.

.PARAMETER Branch
Name of the github branch.

.PARAMETER Tag
Name of the github branch Tag.

.PARAMETER RepositoryRoot
Path to the root of the specified repository


.PARAMETER MaxRetries
Maximum number of retries this call makes before failing. This defaults to 3.

.OUTPUTS
None.
#>
function Invoke-RepositorySync
{
    param(      
            [Parameter(Mandatory=$false)][string]$Branch="",
            [Parameter(Mandatory=$false)][string]$Tag="",
            [Parameter(Mandatory=$false)][string]$EnlistmentRootPath,
            [Parameter(Mandatory=$false)][int]$MaxRetries=3
          )           

    # The following assumptions are made:
    # 1. git is already installed and the path to the git executable has been set in system PATH environment variable
    # 2. git authentication has been setup (ie: ssh key configured with appropriate access)

    Log-Message "Syncing git repository at $($EnlistmentRootPath): Branch/Tag=$($BranchOrTag)"

    pushd $EnlistmentRootPath

    # fetch updates
    $response = Invoke-OxaProcess -ProcessExecutablePath "git.exe" -ArgumentList "fetch --all --tags --prune" -Quiet -MaxRetries $MaxRetries

    if ($Tag)
    {
        $response = Invoke-OxaProcess -ProcessExecutablePath "git.exe" -ArgumentList "checkout tags/$Tag" -Quiet -MaxRetries $MaxRetries
        Log-Message $response
    }
    else 
    {
        $response = Invoke-OxaProcess -ProcessExecutablePath "git.exe" -ArgumentList "checkout $Branch" -Quiet -MaxRetries $MaxRetries
        Log-Message $response
    }

    $response = Invoke-OxaProcess -ProcessExecutablePath "git.exe" -ArgumentList "pull" -Quiet -MaxRetries $MaxRetries
    Log-Message $response

   popd
}

<#
.SYNOPSIS
Clear all messages from the service bus namespace for the cluster.

.DESCRIPTION
Clear all messages from the service bus namespace for the cluster.

.PARAMETER ResourceGroupName
Name of the Azure Resource group containing the network resources.

.PARAMETER KeyName
Name of the shared access keyAzure Resource group containing the network resources.

.PARAMETER MaxRetries
Maximum number of retries this call makes before failing. This defaults to 3.

.OUTPUTS
System.Array. Get-OxaNetworkResources returns an array of discovered azure network-related resource objects
#>
function Clear-OxaMessagingQueue
{
    param( 
            [Parameter(Mandatory=$true)][string]$ResourceGroupName,
            [Parameter(Mandatory=$false)][string]$KeyName="RootManageSharedAccessKey",
            [Parameter(Mandatory=$false)][int]$MaxRetries=3
         )

    $serviceBusNamespace = "$($ResourceGroupName)-sbn"
    $serviceBusQueueName = "$($ResourceGroupName)-sbq"

    $servicebusKeys = Get-OxaServiceBusNamespaceKey -AuthorizationRuleName $KeyName -NamespaceName $serviceBusNamespace -ResourceGroup $ResourceGroupName -MaxRetries $MaxRetries
    
    # drain all messages currently in the queue (if any)
    [array]$messages = Get-QueueMessages -ServiceBusNamespace $serviceBusNamespace `
                                         -ServiceBusQueueName $serviceBusQueueName `
                                         -Saskey $servicebusKeys.PrimaryKey


    Log-Message "Removed $($messages.Count) messages from the queue '$($ResourceGroupName)-sbq'"
}