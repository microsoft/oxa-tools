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
    [string]$message1 = "";
    [string]$message2 = "";


    $lastErrors = @($global:Error[0])
    
    foreach ($lastError in $lastErrors)
    {
        $message1 = "Error: $($lastError.Exception.Message)`r`n";
        $message1 += $lastError.InvocationInfo | Format-List * | Out-String;
        
        foreach($exception in $lastError.Exception)
        {
            $message2 = $exception | Format-List * -Force | Out-String;
        }
    }

    $errorMessage = "`r`n`r`n";
    $errorMessage += "#" * $decoratorLength;
    $errorMessage += "`r`nERROR ENCOUNTERED`r`n";
    $errorMessage += "#" * $decoratorLength;
    $errorMessage += "`r`n$($message1)";

    if ($message2 -ne "")
    {
        $errorMessage += "#" * $decoratorLength;
        $errorMessage += "`r`n$($message2)";
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

    Log-Message "Parameters File: $($ParametersFile)"
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
##    Authenticate the AAD user that will interact with KeyVault
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

#################################################################
#
# Wrappers for All Azure Cmdlet Calls
#
#################################################################

# Command, Activity, Parameters
function Execute-AzureCommand
{
    param( [Parameter(Mandatory=$true)][hashtable]$InputParameters )

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
            Log-Message "Attempt [$($retryAttempt)|$($MaxRetries)] - $($InputParameters['Activity']) started." -Context $Context;

            # handle the commands appropriately
            switch ($InputParameters['Command']) 
            {

                "Find-AzureRmResource"
                {
                    if ($InputParameters['params'] -ne $null)
                    {
                         $response= Find-AzureRmResource -ResourceGroupNameContains $InputParameters['params'].ResourceGroupNameEquals -ResourceType $InputParameters['params'].ResourceType -Verbose ;  
                    }
                    break;
                }
                
                "Get-AzureRmLoadBalancer"
                {
                    if ($InputParameters['Name'] -ne $null)
                    {
                        $response= Get-AzureRmLoadBalancer -Name $InputParameters['Name'] -ResourceGroupName $InputParameters['ResourceGroup'] -Verbose ;  
                    }
                    break;
                }

                "Get-AzureRmLoadBalancerRuleConfig"
                {
                    if ($InputParameters['Name'] -ne $null)
                    {
                        $response= Get-AzureRmLoadBalancerRuleConfig -LoadBalancer $InputParameters['Name'];
                    }
                    break;
                }

                "Remove-AzureRmLoadBalancerRuleConfig"
                {
                    if ($InputParameters['Name'] -ne $null)
                    {
                        $response= Remove-AzureRmLoadBalancerRuleConfig -Name $InputParameters['Name'] -LoadBalancer $InputParameters['lbName'] -Verbose;
                    }
                    break;
                }

                "Set-AzureRmLoadBalancer"
                {
                    if ($InputParameters['lbName'] -ne $null)
                    {
                        $response= Set-AzureRmLoadBalancer -LoadBalancer $InputParameters['lbName'] -Verbose;
                    }
                    break;
                }

                "Get-AzureRmVmss"
                {
                    if ($InputParameters['ResourceGroup'] -ne $null)
                    {
                        $response= Get-AzureRmVmss -ResourceGroupName $InputParameters['ResourceGroup'] -Verbose;
                    }
                    break;
                }
                
                "Remove-AzureRmVmss"
                {
                    if ($InputParameters['VmssName'] -ne $null)
                    {
                        $response= Remove-AzureRmVmss -ResourceGroupName $InputParameters['ResourceGroup'] -VMScaleSetName $InputParameters['VmssName'] -Verbose -Force;
                    }
                    break;
                }
                 
                "Remove-AzureRmLoadBalancerBackendAddressPoolConfig"
                {
                    if ($InputParameters['Name'] -ne $null)
                    {
                        $response= Remove-AzureRmLoadBalancerBackendAddressPoolConfig -LoadBalancer $InputParameters['LbName'] -Name $InputParameters['Name'] -Verbose;
                    }
                    break;
                }
                                 
                "Remove-AzureRmLoadBalancerFrontendIpConfig"
                {
                    if ($InputParameters['Name'] -ne $null)
                    {
                        $response= Remove-AzureRmLoadBalancerFrontendIpConfig -Name $InputParameters['Name'] -LoadBalancer $InputParameters['LbName'] -Verbose;
                    }
                    break;
                }
                  
                "Remove-AzureRmLoadBalancer"
                {
                    if ($InputParameters['LbName'] -ne $null)
                    {
                        $response= Remove-AzureRmLoadBalancer -ResourceGroupName $InputParameters['ResourceGroup'] -Name $InputParameters['LbName'] -Verbose -Force;
                    }
                    break;
                }

                "Get-AzureRmPublicIpAddress"
                {
                    if ($InputParameters['Name'] -ne $null)
                    {
                        $response= Get-AzureRmPublicIpAddress -Name $InputParameters['Name'] -ResourceGroupName $InputParameters['ResourceGroup'] -Verbose;
                    }
                    break;
                }

                "Remove-AzureRmPublicIpAddress"
                {
                    if ($InputParameters['Name'] -ne $null)
                    {
                        $response= Remove-AzureRmPublicIpAddress -ResourceGroupName $InputParameters['ResourceGroup'] -Name $InputParameters['Name'] -Verbose -Force;
                    }
                    break;
                }
                
                default 
                { 
                    throw "$($InputParameters['Command']) is not a supported call."; 
                    break; 
                }
            }
            
            
            Log-Message "Attempt [$($retryAttempt)|$($MaxRetries)] - $($InputParameters['Activity']) completed." -Context $Context;

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

        Log-Message -Message "Waiting $($retryDelay) seconds between retries" -Context $Context -Foregroundcolor Yellow;
        #Start-Sleep -Seconds $retryDelay;
    }

    return $response;
    
}

#################################
# Wrapped function
#################################
## Function: Get-ResourcesList
##
## Purpose: 
##    To get the resource list using ResourceGroup 
##
## Input: 
##   ResourceGroupName   Name of the Resource group  

## Output:
##   resourceList

function Get-ResourcesList
{
    param(      
            [Parameter(Mandatory=$true)][string]$ResourceGroupName        
         )

      [array]$resourceList =@();
      $resourcesListContext = "Resources";

     
      @(

         'Microsoft.Network/loadBalancers'
         'Microsoft.Network/publicIPAddresses'           
         'Microsoft.Network/trafficManagerProfiles' 
       
      ) | % {
  
                $params = @{'ResourceGroupNameEquals' = $ResourceGroupName }
                            
  
                 if ($_ -ne '*') 
                 {
                     $params.Add('ResourceType', $_)
                 }
                 # get the azure resources based on provuded resourcetypes in the resourcegroup
                 [array]$response = Get-AzureResources -params $params -Context $resourcesListContext;
                 if($response -ne $null)
                 {
                     [array]$resourceList += $response;
                 }
                                
            }
    return $resourceList;

}
function Get-AzureResources
{
    param(
            [Parameter(Mandatory=$true)][object]$params,
            [Parameter(Mandatory=$true)][string]$Context,
            [Parameter(Mandatory=$false)][int]$MaxRetries=3
         )

    # prepare the inputs
    [hashtable]$inputParameters = @{
                                        "params" =$params
                                        "Command" = "Find-AzureRmResource";
                                        "Activity" = "Fetching Azure Resources $($params.ResourceType) from Resource Group '$($ResourceGroupName)'"
                                        "ExecutionContext" = $Context
                                   };

    # this call doesn't require special error handling
    return Execute-AzureCommand -InputParameters $inputParameters;
}

## Function: Select-DisabledSlot
##
## Purpose: 
##   selects the disabled Traffic manager endpoint to determine the slot 
##
## Input: 
##   $resourceList  - Azure RM resources
##   
## Output:
##  $slot name
##
function Get-DisabledSlot($resourceList)
{

    # Assgin the slot names
    [hashtable]$disabledSlot = @{
                                   "EndPoint1" = "endpoint1";
                                   "EndPoint2" = "endpoint2";                                       
                                };

    $slot="";
    foreach($resource in $resourceList)
    {
        if($resource.resourcetype -eq 'Microsoft.Network/trafficManagerProfiles' )
        {
            $profile = Get-AzureRmTrafficManagerProfile -Name $resource.Name -ResourceGroupName $ResourceGroupName
     
            foreach( $endpoint in $profile.Endpoints )
            {
                if ($endpoint.EndpointMonitorStatus -eq "Disabled")
                {
           
                    if($endpoint.Name.Contains($disabledSlot['EndPoint1']))
                    {
                        $slot="slot1";                      
                    }

                    if($endpoint.Name.Contains($disabledSlot['EndPoint2']))
                    {
                         $slot="slot2";                       
                    }

                    if($slot -ne $null)
                    {
                        return $slot;
                    }
        
                }
                
            }
         }
    }         
}
## Function: Select-DisabledSlot
##
## Purpose: 
##   selects the disabled Traffic manager endpoint to determine the slot 
##
## Input: 
##   $resourceList  - Azure RM resources
##   
## Output:
##  $slot name
function Remove-StagingResources()
{
 param(
          [Parameter(Mandatory=$true)][string]$ResourceGroupName
      )

    # Getting Azure resource list from the provided resource group
    $resourcelist=Get-ResourcesList -ResourceGroupName $ResourceGroupName;
    
    # determining the slot by passing Azure resource list from the provided resource group
    $Slot = Get-DisabledSlot -resourceList $resourcelist;
      
    # Filter the resources based on the determined slot
    $targetedResources = $resourceList | Where-Object { $_.ResourceName.Contains($Slot) };
    
     if($targetedResources -ne $null)
     {   
         foreach($resource in $targetedResources)
         { 
              Write-Host "Here is the list of resources targetted to be deleted" ($targetedResources| Format-List | Out-String);
              #continue;

                    
              switch ($resource.resourcetype)
              {  
                 "Microsoft.Network/loadBalancers"
                 {
                    $loadbalancerServiceContext = "Load Balancer";
                    $loadbalancerName = $resource.Name;
                    # fetching the loadbalancer object
                    [object]$loadbalancer = Get-OxaAzureLoadBalancers -Name $loadbalancerName -ResourceGroupName $ResourceGroupName -Context $loadbalancerServiceContext;                                          
                       
                    $lbRulesContext = "Load Balancer Rules";  
                    # fetching the loadbalancer rules                                                          
                    $loadBalancerRules = Get-OxaAzureLoadBalancersRules -Name $loadbalancer -Context  $lbRulesContext;
                    if($loadBalancerRules -ne $null)
                    {
                        foreach($loadBalancerRule in $loadBalancerRules)
                        {
                            $loadbalancerRmContext = "Removing Load Balancer Rules";
                            Remove-OxaAzureLoadBalancersRules -Name $loadBalancerRule.Name -LbName $loadbalancer -Context $loadbalancerRmContext;

                            Write-Host "Proceeding with deleting $($loadBalancerRule.Name)"
                            $lbSaveContext = "Updating Load Balancer settings";
                            # should save the loadbalancer setttings once we remove the rules from the loadbalancer settings
                            Set-OxaAzureLoadBalancers -LbName $loadbalancer -Context $lbSaveContext;
                        }
                     }
                     else
                     {
                         Log-Message -Message  "There are no LoadBalancerRules to delete" -LogType Host
                     } 
 
                     [array]$LoadbalancerPools=$Loadbalancer.BackendAddressPools;

                     # fetching id which has VMSS name from loadbalancer banckendIp configurations
                     #It will be helpful for us to make sure we are deleting targetted VMSS
                     $vmssLoadBalancerID=$LoadbalancerPools.BackendIpConfigurations.ID;
                                          
                     $VmssContext = "Fetching Vmss resources details"; 

                     # fetching the vmss name from loadbalancer frontendpool configurations
                     $vmssList = Get-OxaAzureVMSS -ResourceGroupName $ResourceGroupName -Context $VmssContext;
                   
                     foreach($vmss in $vmssList.Name)
                     {
                         # It will be helpful for us to make sure we are deleting targetted VMSS
                         if($vmssLoadBalancerID -match $vmss) 
                         {
                             $VmssRMContext = "Removing Vmss resources details"; 
                             Write-Host "Proceeding with deleting $($vmss.Name) VMSS"
                             # Deleting the targetted VMSS once the names match with configured vmss under loadbalancer
                             Remove-OxaAzureVmss -ResourceGroupName $ResourceGroupName -VmssName $vmss -Context $VmssRMContext ;
                         }
                         else
                         {
                             Log-Message -Message  "There are no VMSS to delete" -LogType Host
                         }
                     }
                     Log-Message -Message  "I do not fine VMSS in the ResourceGroup $ResourceGroupName" -LogType Host

                    if($LoadbalancerPools.Name -ne $null)
                    {
                        $LbBackEndPoolRMContext = "Removing Load Balancer Backend addresspool configurations"; 
                        Write-Host "Proceeding with deleting LoadBalancerBackendPoolConfigurations $($LoadbalancerPools.Name) "

                        # Deleting the loadbalancerbackend addresspool configurations
                        Remove-OxaAzureLbBackEndAddressPool -Name $LoadbalancerPools.Name -LbName $loadbalancer -Context $LbBackEndPoolRMContext;
                        $lbSaveContext = "Updating Load Balancer settings";
                        # should save the loadbalancer setttings once we remove the rules from the loadbalancer settings
                        Set-OxaAzureLoadBalancers -LbName $loadbalancer -Context $lbSaveContext;
                    }
                         
                    else
                    {
                        Log-Message -Message  "There are no LoadBalancerBackEnd pools configurations to delete" -LogType Host
                    }

                    [array]$lbFronendpools= $Loadbalancer.FrontendIpConfigurations;
                                               
                    foreach($lbFronendpool in $lbFronendpools)
                    {
                        if($lbFronendpool -ne $null -and $lbFronendpool.Name -notmatch "Preview")
                        {
                             $lbFrontEndPoolRMContext = "Removing Load balancer FrontEnd Ip pool configurations";

                             Write-Host "Proceeding with deleting LoadBalancerFrontEndIpConfigurations $($lbFronendpool.Name) "

                             # Deleting the loadbalancerFrontendIP configurations
                             Remove-OxaAzureLbFrontEndIpConfig -Name $lbFronendpool.Name -LbName $loadbalancer -Context $lbFrontEndPoolRMContext;
                                                         
                             $lbSaveContext = "Updating Load Balancer settings";

                             # should save the loadbalancer setttings once we remove the rules from the loadbalancer settings
                             Set-OxaAzureLoadBalancers -LbName $loadbalancer -Context $lbSaveContext;
                        }
                       
                        else
                        {
                             Log-Message -Message  "There are no Frontendip configurations to delete" -LogType Host
                        }
                    }
                     if($loadbalancer -ne $null)
                     {
                            Write-Host "Proceeding with deleting load balancer $($loadbalancer.Name) "
                            $lbRMContext = "Remove Load Balancer ";
                            # Deleting the loadbalancer
                            Remove-OxaAzureLoadBalancer -ResourceGroupName $ResourceGroupName -LbName $loadbalancerName -Context $lbRMContext;
                     }
                     else
                     {
                         Log-Message -Message  "There is load balancer selected to be deleted" -LogType Host
                     } 
                          
           }   
                 
                 "Microsoft.Network/publicIPAddresses"
                 {
                    if($resource.ResourceType -eq "Microsoft.Network/publicIPAddresses")
                    {
                        $PublicIpAddressContext = "PublicIpAddress";                                        
                       
                        if($resource.ResourceType -ne "Microsoft.Network/loadBalancers")
                        {
                             # fetching the the cloud services to be deleted
                             [array]$ipslots = Get-OxaPubicIpAddress -Name $resource.Name -ResourceGroupName $ResourceGroupName -Context $PublicIpAddressContext; 
                        }
                        
                        if($ipslots -ne $null )
                        {                               
                             Remove-OxaPubicIpAddress -Name $ipslots.name -ResourceGroupName $ResourceGroupName -Context $PublicIpAddressContext;                                                           
                                
                        }
                        else
                        {
                             Log-Message -Message  "There are no slots to delete" -LogType Host
                        } 

                     }
                     break;
                                   
                  }              
           
              }
              
          }

             
     }
     Log-Message -Message  "There are no Resources targeted to delete from $($ResourceGroupName)" -LogType Host

}
 function Get-OxaAzureLoadBalancers
{
    param(
            [Parameter(Mandatory=$true)][string]$Name,
            [Parameter(Mandatory=$true)][string]$ResourceGroupName,
            [Parameter(Mandatory=$true)][string]$Context,
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
    return Execute-AzureCommand -InputParameters $inputParameters;
}

 function Get-OxaAzureLoadBalancersRules
{
    param(
            [Parameter(Mandatory=$true)][Object]$Name,
            [Parameter(Mandatory=$true)][string]$Context,
            [Parameter(Mandatory=$false)][int]$MaxRetries=3
         )

    # prepare the inputs
    [hashtable]$inputParameters = @{
                                        "Name" = $Name
                                        "Command" = "Get-AzureRmLoadBalancerRuleConfig";
                                        "Activity" = "Getting azure LoadBalancerRules for '$($Name)'"
                                        "ExecutionContext" = $Context
                                   };

    # this call doesn't require special error handling
    return Execute-AzureCommand -InputParameters $inputParameters;
}

 function Remove-OxaAzureLoadBalancersRules
{
    param(
            [Parameter(Mandatory=$true)][string]$Name,
            [Parameter(Mandatory=$true)][Object]$LbName,
            [Parameter(Mandatory=$true)][string]$Context,
            [Parameter(Mandatory=$false)][int]$MaxRetries=3
         )

    # prepare the inputs
    [hashtable]$inputParameters = @{
                                        "Name" = $Name
                                        "LbName" = $LbName
                                        "Command" = "Remove-AzureRmLoadBalancerRuleConfig";
                                        "Activity" = "Removing azure LoadBalancerRules from '$($LbName)'"
                                        "ExecutionContext" = $Context
                                   };

    # this call doesn't require special error handling
    return Execute-AzureCommand -InputParameters $inputParameters;
}

 function Set-OxaAzureLoadBalancers
{
    param(
            [Parameter(Mandatory=$true)][Object]$LbName,
            [Parameter(Mandatory=$true)][string]$Context,
            [Parameter(Mandatory=$false)][int]$MaxRetries=3
         )

    # prepare the inputs
    [hashtable]$inputParameters = @{
                                        "LbName" = $LbName
                                        "Command" = "Set-AzureRmLoadBalancer";
                                        "Activity" = "Saving LoadBalancerRules for '$($LbName)'"
                                        "ExecutionContext" = $Context
                                   };

    # this call doesn't require special error handling
    return Execute-AzureCommand -InputParameters $inputParameters;
}

function Get-OxaAzureVMSS
{
    param(
            [Parameter(Mandatory=$true)][string]$ResourceGroupName,
            [Parameter(Mandatory=$true)][string]$Context,
            [Parameter(Mandatory=$false)][int]$MaxRetries=3
         )

    # prepare the inputs
    [hashtable]$inputParameters = @{
                                       "ResourceGroup" = $ResourceGroupName
                                        "Command" = "Get-AzureRmVmss";
                                        "Activity" = "Fetching VMSS details from '$($ResourceGroupName)'"
                                        "ExecutionContext" = $Context
                                   };

    # this call doesn't require special error handling
    return Execute-AzureCommand -InputParameters $inputParameters;
}

 function Remove-OxaAzureVmss
{
    param(
            [Parameter(Mandatory=$true)][string]$ResourceGroupName,
            [Parameter(Mandatory=$true)][Object]$VmssName,
            [Parameter(Mandatory=$true)][string]$Context,
            [Parameter(Mandatory=$false)][int]$MaxRetries=3
         )

    # prepare the inputs
    [hashtable]$inputParameters = @{
                                        "ResourceGroup" = $ResourceGroupName
                                        "VmssName" = $VmssName
                                        "Command" = "Remove-AzureRmVmss";
                                        "Activity" = "Removing azure VMSS '$($VmssName)'"
                                        "ExecutionContext" = $Context
                                   };

    # this call doesn't require special error handling
    return Execute-AzureCommand -InputParameters $inputParameters;
}

 function Remove-OxaAzureLbBackEndAddressPool
{
    param(
            [Parameter(Mandatory=$true)][string]$Name,
            [Parameter(Mandatory=$true)][Object]$LbName,
            [Parameter(Mandatory=$true)][string]$Context,
            [Parameter(Mandatory=$false)][int]$MaxRetries=3
         )

    # prepare the inputs
    [hashtable]$inputParameters = @{
                                        "LbName" = $LbName
                                        "Name" = $Name
                                        "Command" = "Remove-AzureRmLoadBalancerBackendAddressPoolConfig";
                                        "Activity" = "Removing azure Load balancer BackEnd Addressspool config '$($Name)'"
                                        "ExecutionContext" = $Context
                                   };

    # this call doesn't require special error handling
    return Execute-AzureCommand -InputParameters $inputParameters;
}

 function Remove-OxaAzureLbFrontEndIpConfig
{
    param(
            [Parameter(Mandatory=$true)][string]$Name,
            [Parameter(Mandatory=$true)][Object]$LbName,
            [Parameter(Mandatory=$true)][string]$Context,
            [Parameter(Mandatory=$false)][int]$MaxRetries=3
         )

    # prepare the inputs
    [hashtable]$inputParameters = @{
                                        "LbName" = $LbName
                                        "Name" = $Name
                                        "Command" = "Remove-AzureRmLoadBalancerFrontendIpConfig";
                                        "Activity" = "Removing azure Load balancer FrontEnd Ip config '$($Name)'"
                                        "ExecutionContext" = $Context
                                   };

    # this call doesn't require special error handling
    return Execute-AzureCommand -InputParameters $inputParameters;
}

 function Remove-OxaAzureLoadBalancer
{
    param(
            [Parameter(Mandatory=$true)][string]$ResourceGroupName,
            [Parameter(Mandatory=$true)][string]$LbName,
            [Parameter(Mandatory=$true)][string]$Context,
            [Parameter(Mandatory=$false)][int]$MaxRetries=3
         )

    # prepare the inputs
    [hashtable]$inputParameters = @{
                                        "LbName" = $LbName
                                        "ResourceGroup" = $ResourceGroupName
                                        "Command" = "Remove-AzureRmLoadBalancer";
                                        "Activity" = "Removing azure Load balancer '$($LbName)' from ResourceGroup $($ResourceGroupName)"
                                        "ExecutionContext" = $Context
                                   };

    # this call doesn't require special error handling
    return Execute-AzureCommand -InputParameters $inputParameters;
}

 function Get-OxaPubicIpAddress
{
    param(
            [Parameter(Mandatory=$true)][string]$ResourceGroupName,
            [Parameter(Mandatory=$true)][string]$Name,
            [Parameter(Mandatory=$true)][string]$Context,
            [Parameter(Mandatory=$false)][int]$MaxRetries=3
         )

    # prepare the inputs
    [hashtable]$inputParameters = @{
                                        "ResourceGroup" = $ResourceGroupName
                                        "Name" = $Name
                                        "Command" = "Get-AzureRmPublicIpAddress";
                                        "Activity" = "Fetching azure PublicIP Addresses from ResourceGroup $($ResourceGroupName)"
                                        "ExecutionContext" = $Context
                                   };

    # this call doesn't require special error handling
    return Execute-AzureCommand -InputParameters $inputParameters;
}

 function Remove-OxaPubicIpAddress
{
    param(
            [Parameter(Mandatory=$true)][string]$ResourceGroupName,
            [Parameter(Mandatory=$true)][string]$Name,
            [Parameter(Mandatory=$true)][string]$Context,
            [Parameter(Mandatory=$false)][int]$MaxRetries=3
         )

    # prepare the inputs
    [hashtable]$inputParameters = @{
                                        "Name" = $Name
                                        "ResourceGroup" = $ResourceGroupName
                                        "Command" = "Remove-AzureRmPublicIpAddress";
                                        "Activity" = "Removing azure PublicIP Address '$($Name)' from ResourceGroup $($ResourceGroupName)"
                                        "ExecutionContext" = $Context
                                   };

    # this call doesn't require special error handling
    return Execute-AzureCommand -InputParameters $inputParameters;
}

## Function: Delete-Resources
##
## Purpose: 
##    To delete the resources by determining the slot status
##
## Input: 
##   DeploymentType          the type of deployment like bootstrap, upgrade, swap
##   Cloud      the type of environment name like bvt, int, prod
##   DeploymentStatus             the status of deployment like succeded or not
##  
## Output:
##   nothing
##
 function Delete-Resources($DeploymentType,$Cloud ,$DeploymentStatus)
{
   
   if(($DeploymentType -eq "upgrade") -or ($DeploymentType -eq "swap" -and $Cloud -eq  "bvt" -and $DeploymentStatus.ProvisioningState -ieq "Succeeded"))
    {
        try
        {
            #cleaning up the resources from the disabled slot
            Remove-StagingResources -ResourceGroupName $ResourceGroupName;
        }
        catch
        {
            Capture-ErrorStack;
            throw "Error in deleting the resources: $($_.Message)";
            exit;  
        }
    }
    else
    {
          Log-Message "Skipping the deleting of resources since deployment type: $($DeploymentType) and cloud $($Cloud) has been selected"
    }
}

## Function: Get-VmssName
##
## Purpose: 
##    To get the VMSS Name in order to swap the instances
##
## Input: 
##   ResourceGroupName          Resource Group Name
##  
## Output:
##   VmssInstanceId
##
function Get-VmssName($ResourceGroupName)
{
    $vmssContext = "Fetching Vmss resources details"; 
    Log-Message "Fetching VMSS details to set deployment versionid for Swap "
    $vmssList = Get-OxaAzureVMSS -ResourceGroupName $ResourceGroupName -Context $VmssContext;
    $vmssName = $vmssList | Sort-Object -Descending | Select-Object -Skip 1
    $vmssInstanceId = $vmssName.Name.Split('-') | Select-Object -Last 1

    # this return the VMSSID to use as deploymentVersion id
    return $VmssInstanceId;
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

    if ($ScriptParamVal.Trim().Length -eq 0 -or $ScriptParamVal -eq $null)
    {        
        Log-Message "Falling back to default value: $($DefaultValue) for parameter $($ScriptParamName) since no value was provided"
    }

    return $DefaultValue
}
