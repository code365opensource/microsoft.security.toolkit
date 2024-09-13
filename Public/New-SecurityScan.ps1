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
        Connect-Graph -Scopes "Files.Read","Files.Read.All" -NoWelcome
    }
    else {
        Connect-Graph -AccessToken (ConvertTo-SecureString $accessToken -AsPlainText -Force) -NoWelcome
    }
        
    # initialize the result
    $file_info = @{}
    $file_info_sensi = @{}
    $file_info_access = @{}
    $file_info_permission = @{}
    $file_info_scope = @{}
    $file_info_shared = @{}
    $file_info_access_90days = @{}

    # get all files in the folder
    $graph_url_getItems = "https://graph.microsoft.com/v1.0/me/drive/root:/${pathOfOneDrive}:/children?select=name,id"
    $response = Invoke-MgRestMethod -Uri $graph_url_getItems -Method GET
    $data = $response.value
    foreach ($file in $data) {
        $file_info[$file.id] = $file.name
    }
    
    # get the required information for each file
    $graph_baseUrl = 'https://graph.microsoft.com/v1.0/me/drive/items'
    $id_to_display_name = Get-SensitivityLabelsMapping
    foreach ($key in $file_info.Keys) {

        # get sensitivity label
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
    
    $timestamp = (Get-Date).ToString("yyyy-MM-dd_HH-mm-ss")
    $csvFileName = "scan_report_$timestamp.csv"
    $csvFilePath = Join-Path -Path $PSScriptRoot -ChildPath $csvFileName
    $csvData = @()
    
    # generate report for each file
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

    $result
}