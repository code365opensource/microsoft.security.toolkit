<#
.SYNOPSIS
    This function will scan the files in the OneDrive folder for any security issues.
.DESCRIPTION
    This function will scan the files in the OneDrive folder for any security issues.
.PARAMETER pathOfOneDrive
    The path of the OneDrive folder. This is a relative path to the user's OneDrive folder, don't provide the full path here.
.PARAMETER accessToken
    The access token to access the OneDrive folder. This is optional, if not provided, the function will prompt for the access token. 
.OUTPUTS
    This function will generate a report of the security issues found in the OneDrive folder, and can be export to csv.
.LINK
    https://github.com/code365opensource/microsoft.security.toolkit
#>
function New-SecurityScan {
    [cmdletbinding()]
    [Alias("amisecure")]
    param (
        [Parameter(Mandatory = $true)]
        [string]$pathOfOneDrive,
        [string]$accessToken
    )

    # connect to Microsoft Graph, if the accessToken is not provided, prompt for the access token, otherwise use the provided access token (parse it to secure string)
    
    if (-not $accessToken) {
        Connect-Graph -Scopes "Files.Read","" -NoWelcome
    }
    else {
        Connect-Graph -AccessToken (ConvertTo-SecureString $accessToken -AsPlainText -Force) -NoWelcome
    }

    # implement the scan and evaluation logic here, You can use Invoke-MgRestMethod for any Microsoft Graph API calls. (LEARN more : Get-Help Invoke-MgRestMethod)

    $graph_url_getItems = "https://graph.microsoft.com/v1.0/me/drive/root:/${pathOfOneDrive}:/children?select=name,id"
    $graph_baseUrl = 'https://graph.microsoft.com/v1.0/me/drive/items'
    
    $data_list = @(
        @{ "id" = "87ba5c36-b7cf-4793-bbc2-bd5b3a9f95ca"; "name" = "Personal"; "displayName" = "Non-Business" },
        @{ "id" = "87867195-f2b8-4ac2-b0b6-6bb73cb33afc"; "name" = "Not Restricted"; "displayName" = "Public" },
        @{ "id" = "f42aa342-8706-4288-bd11-ebb85995028c"; "name" = "Internal"; "displayName" = "General" },
    
        # Confidential label and sublabels
        @{ "id" = "074e257c-5848-4582-9a6f-34a182080e71"; "name" = "Confidential"; "displayName" = "Confidential" },
        @{ "id" = "1a19d03a-48bc-4359-8038-5b5f6d5847c3"; "name" = "Any User (No Protection)_1"; "displayName" = "Any User (No Protection), Confidential" },
        @{ "id" = "9fbde396-1a24-4c79-8edf-9254a0f35055"; "name" = "Microsoft All Employees_1"; "displayName" = "Microsoft Extended, Confidential" },
        @{ "id" = "d9f23ae3-a239-45ea-bf23-f515f824c57b"; "name" = "Microsoft FTE Only_1"; "displayName" = "Microsoft FTE, Confidential" },
        @{ "id" = "fec751d2-ff79-4176-b06f-8a50d675b290"; "name" = "Recipients Only_0"; "displayName" = "Recipients Only, Confidential" },
    
        # Highly Confidential label and sublabels
        @{ "id" = "f5dc2dea-db0f-47cd-8b20-a52e1590fb64"; "name" = "Secret"; "displayName" = "Highly Confidential" },
        @{ "id" = "b7b9f8f9-3cae-48b6-8b79-2f3f184fa0ea"; "name" = "Any User (No Protection)_0"; "displayName" = "Any User (No Protection), Highly Confidential" },
        @{ "id" = "c179f820-d535-4b2f-b252-8a9c4ac14ec6"; "name" = "Microsoft All Employees_0"; "displayName" = "Microsoft Extended, Highly Confidential" },
        @{ "id" = "f74878b7-c0ff-44a4-82ff-8ce29f7fccb5"; "name" = "Microsoft FTE Only_0"; "displayName" = "Microsoft FTE, Highly Confidential" },
        @{ "id" = "a4239ae8-df55-4508-b037-a46ec1e6b836"; "name" = "Recipients Only_1"; "displayName" = "Recipients Only, Highly Confidential" }
    )
    
    $id_to_display_name = @{}
    foreach ($item in $data_list) {
        $id_to_display_name[$item.id] = $item.displayName
    }
    
    # process-permission
    function Get-Permission {
        param (
            $entry,
            [ref]$user_name,
            $scope,
            [ref]$owner
        )
        if ($entry.ContainsKey('grantedToIdentitiesV2')) {
            $identities = $entry.grantedToIdentitiesV2
            $linkType = $entry.link.type
            $linkScope = $entry.link.scope
    
            if (-not $scope.ContainsKey($linkScope)) {
                $scope[$linkScope] = $linkType
            } else {
                $scope[$linkScope] = if ($scope[$linkScope] -eq 'edit') { $scope[$linkScope] } else { $linkType }
            }
        } 
        elseif ($entry.ContainsKey("grantedToV2")) {$identities = @($entry.grantedToV2)} 
        else {
            return
        }
    
        if($entry.roles -Contains "owner") {
            $owner.Value = $identities[0].user.email
        }
    
        foreach ($identity in $identities) {
            if ($identity.ContainsKey("user")) {
                $user = $identity.user
                $display_name = $user.displayName
                if ($display_name -ne "N/A") {
                    $null = $user_name.Value.Add($display_name)
                }
            } elseif ($identity.ContainsKey("group")) {
                $group = $identity.group
                $group_id = $group.id
                if ($group_id -ne "N/A") {
                    $response = Invoke-MgRestMethod -Uri "https://graph.microsoft.com/v1.0/groups/$group_id/members?select=displayName" -Method GET
                    foreach ($item in $response.value) {
                        $null = $user_name.Value.Add($item.displayName)
                    }
                }
            }
        }
    }
    
    function Get-Activity {
        param (
            $entry,
            [ref]$shared
        )
    
        if ($entry.ContainsKey('action')) {
            $action = $entry.action
    
            if ($action.ContainsKey('share')) {
                $email = $entry.actor.user.email
                if ($email -ne $owner) {
                    $shared.Value = $true
                    return
                }
            }
        }
    }
    
    
    $response = Invoke-MgRestMethod -Uri $graph_url_getItems -Method GET
    $data = $response.value
    $file_info = @{}
    
    foreach ($file in $data) {
        $file_info[$file.id] = $file.name
    }
    
    $file_info_sensi = @{}
    $file_info_access = @{}
    $file_info_permission = @{}
    $file_info_scope = @{}
    $file_info_shared = @{}
    $file_info_access_90days = @{}
    
    foreach ($key in $file_info.Keys) {
        # 
        $url_sen = "$graph_baseUrl/$key/extractSensitivityLabels"
        $response = Invoke-MgRestMethod -Uri $url_sen -Method POST
        $data = $response.labels
        $id = $data[0].sensitivityLabelId
        if ($data -and $data[0].sensitivityLabelId) {
            $id = $data[0].sensitivityLabelId
            $file_info_sensi[$file_info[$key]] = 
                if ($id_to_display_name.ContainsKey($id)) 
                    { $id_to_display_name[$id] } 
                else { "Unknown" }
        } else {
            $file_info_sensi[$file_info[$key]] = "Unknown"
        }
    
        # get all time analytics log
        $url_access = "$graph_baseUrl/$key/analytics/alltime?select=access"
        $response = Invoke-MgRestMethod -Uri $url_access -Method GET
        $accessLog = $response.access
        $file_info_access[$file_info[$key]] = $accessLog
    
        # get recent 90 days analytics log
        $startDate = (Get-Date).AddDays(-90).ToString('yyyy-MM-dd')
        $url_access = "$graph_baseUrl/$key/getActivitiesByInterval(startDateTime='$startDate',endDateTime='',interval='month')?select=access"
        $response = Invoke-MgRestMethod -Uri $url_access -Method GET
        $accessLog = $response.value
        $file_info_access_90days[$file_info[$key]] = $accessLog
    
        # get permissions
        $url_permission = "$graph_baseUrl/$key/permissions?select=grantedToIdentitiesV2,grantedToV2,link,roles"
        $response = Invoke-MgRestMethod -Uri $url_permission  -Method GET
        $useName = New-Object 'System.Collections.Generic.HashSet[System.String]'
        $scope = @{}
        $owner = "N/A"
        foreach ($item in $response.value) {
            Get-Permission -entry $item -user_name ([ref]$useName) -scope $scope -owner ([ref]$owner)
        }
        $file_info_permission[$file_info[$key]] = $useName.Count
        $file_info_scope[$file_info[$key]] = $scope
    
        # get activities log
        $url_activities = "$graph_baseUrl/$key/activities?select=action,actor"
        $response = Invoke-MgRestMethod -Uri $url_activities -Method GET
        $shared = $false
        foreach ($item in $response.value) {
            Get-Activity -entry $item -shared ([ref]$shared)
            if($shared) {break}
        }
        $file_info_shared[$file_info[$key]] = $shared
    }
    
    # generate report
    $timestamp = (Get-Date).ToString("yyyy-MM-dd_HH-mm-ss")
    $csvFileName = "scan_report_$timestamp.csv"
    $csvFilePath = Join-Path -Path $PSScriptRoot -ChildPath $csvFileName
    $csvData = @()
    
    
    foreach ($key in $file_info.Keys) {
        $fileName = $file_info[$key]
        $sensitivity = $file_info_sensi[$fileName]
        $accessLog = $file_info_access[$fileName]
        $accessLog90days = $file_info_access_90days[$fileName]
        $permissionCount = $file_info_permission[$fileName]
        $scope = $file_info_scope[$fileName]
        $sharedWithOthers = $file_info_shared[$fileName]
        #  Check if the file is private, and no access logs belongs to others.
        $passPrivateAndNoAccessTest = Test-PrivateAndOthersNoAccess -permissionCount $permissionCount -accessLog $accessLog
        #  Check if the file has been shared by others, rather than by the owner.
        $passSharedByOthersTest = Test-SharedByOthers -sharedWithOthers $sharedWithOthers
        #  Check if the file is classified as 'confidential' or 'high confidential', but shared with 'organization' or 'anonymous'.
        $passConfidentialAndNoOrgScopeTest = Test-ConfidentialAndNoOrgScope -scope $scope -sensitivity $sensitivity
        #  Check if the file has not been used in the last 90 days, but still has permission settings.
        $passUnusedWithPermissionsTest = Test-UnusedWithPermissions -accessLog90days $accessLog90days -permissionCount $permissionCount
        #  Generate report based on check results
        $csvData += New-Report -fileName $fileName `
        -passPrivateAndNoAccessTest $passPrivateAndNoAccessTest `
        -passSharedByOthersTest $passSharedByOthersTest `
        -passConfidentialAndNoOrgScopeTest $passConfidentialAndNoOrgScopeTest `
        -passUnusedWithPermissionsTest $passUnusedWithPermissionsTest
    }
    
    $csvData | Export-Csv -Path $csvFilePath -NoTypeInformation
    
    Write-Host "Scan report saved to: $csvFilePath"

    # Output the result in Console
    $result

}