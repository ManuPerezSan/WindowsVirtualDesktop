Param(
    [Parameter(Mandatory=$true,Position=0)][String]$AzureTenantId,
    [Parameter(Mandatory=$true,Position=1)][String]$SubscriptionId,
    [Parameter(Mandatory=$true,Position=1)][String]$ClientId,
    [Parameter(Mandatory=$true,Position=1)][String]$ClientSecret
)

# TO DO


# [ ] Mostrar el origen de la imagen usada (source) y (name) en caso de image o SKU en caso de gallery
# [ ] Adding style powershell html report: https://petri.com/adding-style-powershell-html-reports

$totalSessions = 0
$totalSessionHosts = 0

function New-AzureRmAuthToken
{
 
<#
 
.SYNOPSIS
Creates a new authentication token for use against Azure RM REST API operations.
 
.DESCRIPTION
Creates a new authentication token for use against Azure RM REST API operations. This uses client/secret auth (not certificate auth).
The returned output contains the OAuth bearer token and it's properties.

.PARAMETER AadClientAppId
The AAD client application ID.
 
.PARAMETER AadClientAppSecret
The AAD client application secret
 
.PARAMETER AadTenantId
The AAD tenant ID.
 
.EXAMPLE
New-AzureRmAuthToken -AadClientAppId '<app id>' -AadClientAppSecret '<app secret>' -AadTenantId '<tenant id>'

.URL
https://keithbabinec.com/2018/10/11/how-to-call-the-azure-rest-api-from-powershell/

#>
 
[CmdletBinding()]Param(
    [Parameter(Mandatory=$true, HelpMessage='Please provide the AAD client application ID.')][System.String]$AadClientAppId,
    [Parameter(Mandatory=$true, HelpMessage='Please provide the AAD client application secret.')][System.String]$AadClientAppSecret,
    [Parameter(Mandatory=$true, HelpMessage='Please provide the AAD tenant ID.')][System.String]$AadTenantId
)
 
    Process 
    {
 
        # auth URIs
        $aadUri = 'https://login.microsoftonline.com/{0}/oauth2/token'
        $resource = 'https://management.core.windows.net'
 
        # load the web assembly and encode parameters
        $null = [Reflection.Assembly]::LoadWithPartialName('System.Web')
        $encodedClientAppSecret = [System.Web.HttpUtility]::UrlEncode($AadClientAppSecret)
        $encodedResource = [System.Web.HttpUtility]::UrlEncode($Resource)
 
        # construct and send the request
        $tenantAuthUri = $aadUri -f $AadTenantId
 
        $headers = @{
            'Content-Type' = 'application/x-www-form-urlencoded';
        }
 
        $bodyParams = @(
 
            "grant_type=client_credentials",
            "client_id=$AadClientAppId",
            "client_secret=$encodedClientAppSecret",
            "resource=$encodedResource"
 
        )
 
        $body = [System.String]::Join("&", $bodyParams)
 
        return (Invoke-RestMethod -Uri $tenantAuthUri -Method POST -Headers $headers -Body $body)

 
    }    
 
}

# Obtener bearer token
$access = New-AzureRmAuthToken -AadClientAppId $clientId -AadClientAppSecret $clientsecret -AadTenantId $AzureTenantId -Verbose
$token = $access.access_token

# Create headers
$headers = @{
    'Host' = 'management.azure.com'
    'Content-Type' = 'application/json';
    'Authorization' = "Bearer $token";
}

# API WVD: https://docs.microsoft.com/en-Us/rest/api/desktopvirtualization/sessionhosts/list

$connectedUsers = @()
$hostpoolExport = @()
$sessionhostsExport = @()
$appsExport = @()
$hostpoolTemplatesExport = @()

# Get Workspaces
$workspaces = (Invoke-RestMethod -Uri "https://management.azure.com/subscriptions/$subscriptionId/providers/Microsoft.DesktopVirtualization/workspaces?api-version=2019-12-10-preview" -Method GET -Headers $headers).value

foreach($wspace in $workspaces){
    write-host ""
    write-host "Workspace: $($wspace.Name)" -ForegroundColor Magenta
    write-host "`tLocation: $($wspace.location)"
    write-host "`tApplication groups" -ForegroundColor Yellow
    foreach($appGroup in $($wspace.properties.applicationGroupReferences)){
        $appGroupName = $($appGroup.Split('/')[-1])
        $resourceGroupName = $appGroup.Split('/')[4]
        write-host "`t`t $($appGroup.Split('/')[-1])"

        $uri = 'https://management.azure.com' + $appGroup + '?api-version=2019-12-10-preview'
        $appGroupData = (Invoke-RestMethod -Uri $Uri -Method GET -Headers $headers)
        $hostPoolName = $appGroupData.properties.hostPoolArmPath.split('/')[-1]
        # (Invoke-RestMethod -Uri "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.DesktopVirtualization/applicationGroups/$appGroupName?api-version=2019-12-10-preview" -Method GET -Headers $headers).value
        #(Invoke-RestMethod -Uri "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/EGR-Desktops/providers/Microsoft.DesktopVirtualization/applicationGroups/{applicationGroupName}?api-version=2019-12-10-preview

        $uri = 'https://management.azure.com' + $appGroup + '/applications?api-version=2019-12-10-preview'
        $applications = (Invoke-RestMethod -Uri $Uri -Method GET -Headers $headers).Value

        if ($applications){
            foreach($app in $applications){

                $icon = "<img src='data:image/png;base64,$($app.Properties.IconContent)' alt='My Image' width=32 weigth=32 />"
                
                $ObjectApps = New-Object PSObject
                $ObjectApps | add-member Noteproperty ApplicationGroup $app.Name.Split('/')[0]
                $ObjectApps | add-member Noteproperty HostPool $hostPoolName
                $ObjectApps | add-member Noteproperty Icon $icon
                $ObjectApps | add-member Noteproperty AppName $app.Name.Split('/')[1]
                $ObjectApps | add-member Noteproperty FriendlyName $app.Properties.FriendlyName
                $ObjectApps | add-member Noteproperty Type 'RemoteApp'
                $ObjectApps | add-member Noteproperty FilePath $app.Properties.FilePath
                $ObjectApps | add-member Noteproperty ShowInPortal $app.Properties.showInPortal

                $appsExport += $ObjectApps
            }
        }

        $uri = 'https://management.azure.com' + $appGroup + '/desktops?api-version=2019-12-10-preview'
        $applications = (Invoke-RestMethod -Uri $Uri -Method GET -Headers $headers).Value
        if ($applications){
            foreach($app in $applications){

                $icon = "<img src='data:image/png;base64,$($app.Properties.IconContent)' alt='My Image' width=32 weigth=32 />"
                
                $ObjectApps = New-Object PSObject
                $ObjectApps | add-member Noteproperty ApplicationGroup $app.Name.Split('/')[0]
                $ObjectApps | add-member Noteproperty HostPool $hostPoolName
                $ObjectApps | add-member Noteproperty Icon $icon
                $ObjectApps | add-member Noteproperty AppName $app.Name.Split('/')[1]
                $ObjectApps | add-member Noteproperty FriendlyName $app.Properties.FriendlyName
                $ObjectApps | add-member Noteproperty Type 'Desktop'

                $appsExport += $ObjectApps
            }
        }
    }
}


# List host pools
$hostpools = (Invoke-RestMethod -Uri "https://management.azure.com/subscriptions/$subscriptionId/providers/Microsoft.DesktopVirtualization/hostPools?api-version=2019-12-10-preview" -Method GET -Headers $headers).value

foreach ($hp in $hostpools){
    write-host ""
    $hostPoolName = $hp.Name
    $splittedUrl = $hp.id.split('/')
    $resourceGroupName = $splittedUrl[$splittedUrl.indexof('resourcegroups')+1]

    write-host ""
    Write-host "`tHostPool: $hostPoolName" -ForegroundColor Yellow -NoNewline
    Write-host "`tResourceGroup: $resourceGroupName" -ForegroundColor Cyan

    $hostpoolSessions =  (Invoke-RestMethod -Uri "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.DesktopVirtualization/hostPools/$hostPoolName/userSessions?api-version=2019-12-10-preview" -Method GET -Headers $headers).Value
    

    $vmTemplate = $hp.properties.vmTemplate | ConvertFrom-json

    $Object = New-Object PSObject
    $Object | add-member Noteproperty HostPoolName $hostPoolName
    $Object | add-member Noteproperty ResourceGroupName $resourceGroupName
    $Object | add-member Noteproperty Location $hp.location
    $Object | add-member Noteproperty hostPoolType $hp.properties.hostPoolType
    $Object | add-member Noteproperty personalDesktopAssignmentType $hp.properties.personalDesktopAssignmentType
    $Object | add-member Noteproperty customRdpProperty $hp.properties.customRdpProperty
    $Object | add-member Noteproperty maxSessionLimit $hp.properties.maxSessionLimit
    $Object | add-member Noteproperty BreadthFirst $hp.properties.loadBalancerType
    $Object | add-member Noteproperty validationEnvironment $hp.properties.validationEnvironment
    $Object | add-member Noteproperty VmTemplateDomain $vmTemplate.domain
    $Object | add-member Noteproperty Sessions $hostpoolSessions.count

    $totalSessions += $hostpoolSessions.count
    $hostpoolExport += $Object

    $Object = New-Object PSObject
    $Object | add-member Noteproperty HostPoolName $hostPoolName
    $Object | add-member Noteproperty ResourceGroupName $resourceGroupName
    $Object | add-member Noteproperty imageType $vmTemplate.imageType
    $Object | add-member Noteproperty customImageId $(if ($vmTemplate.customImageId -ne $null){ $vmTemplate.customImageId.split('/')[-1] }else{ })
    $Object | add-member Noteproperty galleryImageOffer $vmTemplate.galleryImageOffer
    $Object | add-member Noteproperty galleryImagePublisher $vmTemplate.galleryImagePublisher
    $Object | add-member Noteproperty galleryImageSKU $vmTemplate.galleryImageSKU
    $Object | add-member Noteproperty imageUri $vmTemplate.imageUri
    $Object | add-member Noteproperty namePrefix $vmTemplate.namePrefix
    $Object | add-member Noteproperty osDiskType $vmTemplate.osDiskType
    $Object | add-member Noteproperty useManagedDisks $vmTemplate.useManagedDisks
    $Object | add-member Noteproperty vmSize $vmTemplate.vmSize.id
    $Object | add-member Noteproperty galleryItemId $vmTemplate.galleryItemId

    $hostpoolTemplatesExport += $Object

    $sessionHosts = (Invoke-RestMethod -Uri "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.DesktopVirtualization/hostPools/$hostPoolName/sessionHosts?api-version=2019-12-10-preview" -Method GET -Headers $headers).Value
    
     foreach ($server in $sessionHosts){
        
        $totalSessionHosts++
        $sessionHost = $server.name.Split('/')[1]
        write-host "`t`tSessionHost: $($sessionHost)" -ForegroundColor Magenta
        try{
            $shost = (Invoke-RestMethod -Uri "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.DesktopVirtualization/hostPools/$hostPoolName/sessionHosts/$($sessionHost)?api-version=2019-12-10-preview" -Method Get -Headers $headers).Properties
            write-host "`t`t`tHeart beat: $($shost.lastHeartBeat)"
            write-host "`t`t`tAgent version: $($shost.agentVersion)"
            write-host "`t`t`tSessions: $($shost.sessions)"
            write-host "`t`t`tStatus: " -NoNewline
            if ($shost.status -eq 'Available'){ write-host "$($shost.status)" -ForegroundColor Green }else{ write-host "$($shost.status)" -ForegroundColor Yellow }
             
            write-host "`t`t`tallowNewSession: " -NoNewline
            if ($shost.allowNewSession -eq $true){ write-host "True" -ForegroundColor Green }else{ write-host "False" -ForegroundColor Yellow}
            write-host "`t`t`tOS verion: $($shost.osVersion)"
            write-host "`t`t`tMachien Id: $($shost.virtualMachineId)"
            

            write-host "`t`t`tHealth check" -ForegroundColor Yellow
            
            $Object2 = New-Object PSObject
            $Object2 | add-member Noteproperty sessionHost $sessionHost
            $Object2 | add-member Noteproperty Status $shost.status
            $Object2 | add-member Noteproperty AllowNewSession $shost.allowNewSession
            $Object2 | add-member Noteproperty Sessions $shost.sessions
            $Object2 | add-member Noteproperty HeartBeat $shost.lastHeartBeat
            $Object2 | add-member Noteproperty Agent $shost.agentVersion
            $Object2 | add-member Noteproperty Assignments $shost.assignedUser
            

            $shostData = ConvertFrom-Json $shost.sessionHostHealthCheckResult
            foreach ($item in $shostData){
                write-host "`t`t`t$($item.HealthCheckName) " -NoNewline
                if ($item.additionalFailureDetails.ErrorCode -eq 0){
                    write-host "Success" -ForegroundColor Green
                    $result = 'Success'
                }else{
                    write-host "Failed" -ForegroundColor Red
                    $result = 'Failed'
                }
                $Object2 | add-member Noteproperty $item.HealthCheckName $result

            }
            
            if ($shostData.count -eq 0) { write-host "`t`t`t(null)" }

            

            $sessionhostsExport += $Object2

            # write-host "`t`tSession host data: $($shost)"
        }catch{
            write-host "No data about $sessionHost"
        }

        
        $sessionHostSessions = (Invoke-RestMethod -Uri "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.DesktopVirtualization/hostPools/$hostPoolName/sessionHosts/$sessionHost/userSessions?api-version=2019-12-10-preview" -Method Get -Headers $headers).Value
        # write-host "Sessions: $($sessionHostSessions.count)"
        
        $connectedUsers += $sessionHostSessions.Properties
    }

    $sessions = (Invoke-RestMethod -Uri "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.DesktopVirtualization/hostPools/$hostPoolName/userSessions?api-version=2019-12-10-preview" -Method Get -Headers $headers).Value

    write-host ""
    Write-host "`tTotal Sessions: $($sessions.count)" -ForegroundColor Yellow
}

# Session list
write-host ""
write-host "Sessions:" -ForegroundColor Green

# Report https://petri.com/adding-style-powershell-html-reports
$connectedUsers | Select userPrincipalName,sessionState,applicationType,createTime

#PostContent = "<p class='footer'>$(get-date)</p>"
$convertParams = @{ 
 PreContent = "<H1>Windows Virtual Desktop</H1><p>Subscription: $subscriptionId</p><p>Total sessions: $totalSessions</p><p>Total session hosts: $totalSessionHosts </p><p class='footer'>$(get-date)</p>" 
 head = @"
 <Title>Windows Virtual Desktop Report</Title>
<style>
body { background-color:#FFFFFF;
       font-family:Monospace;
       font-size:10pt; }
td, th { border:0px solid black; 
         border-collapse:collapse;
         white-space:pre; }
th { color:white;
     background-color:black; }
table, tr, td, th { padding: 2px; margin: 0px ;white-space:pre; }
tr:nth-child(odd) {background-color: lightgray}
table { width:95%;margin-left:5px; margin-bottom:20px;}
h2 {
 font-family:Tahoma;
 color:#6D7B8D;
}
.footer 
{ color:green; 
  margin-left:10px; 
  font-family:Tahoma;
  font-size:8pt;
  font-style:italic;
}
</style>
"@
}


$hostpoolExport | ConvertTo-Html @convertParams | Out-file -FilePath .\WVDTool.html -Encoding ascii
$hostpoolTemplatesExport  | ConvertTo-Html  | Out-file -FilePath .\WVDTool.html -Append -Encoding ascii
$appsExport | ConvertTo-Html  | Out-file -FilePath .\WVDTool.html -Append -Encoding ascii
$sessionhostsExport | ConvertTo-Html | Out-file -FilePath .\WVDTool.html -Append -Encoding ascii
$connectedUsers | ConvertTo-Html  | Out-file -FilePath .\WVDTool.html -Append -Encoding ascii

# Decode HTML to show base64 images correctly
$a = Get-Content .\WVDTool.html

Add-Type -AssemblyName System.Web
[System.Web.HttpUtility]::HtmlDecode($a) | Out-File .\WVDTool.html
