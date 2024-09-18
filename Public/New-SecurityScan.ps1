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
        Connect-Graph -Scopes "Files.Read", "Files.Read.All", "InformationProtectionPolicy.Read" -NoWelcome
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

    try {
        # Get all files in the specified folder from OneDrive
        $graph_url_getItems = "https://graph.microsoft.com/v1.0/me/drive/root:/${pathOfOneDrive}:/children?select=name,id"
        $response = Invoke-MgRestMethod -Uri $graph_url_getItems -Method GET -ErrorAction Stop
    
        # Check if the response contains any files
        if ($response.value -and $response.value.Count -gt 0) {
            $data = $response.value
            foreach ($file in $data) {
                # Store file id and name in the dictionary
                $file_info[$file.id] = $file.name
            }
        } else {
            Write-Host "No files found in the specified folder."
            Exit 1
        }
    }
    catch {
        Write-Host "An error occurred while retrieving files: $_"
        Exit 1
    }
    
    # get the required information for each file
    $graph_baseUrl = 'https://graph.microsoft.com/v1.0/me/drive/items'
    $id_to_display_name = Get-SensitivityLabelsMapping
    foreach ($key in $file_info.Keys) {

        # get sensitivity label
        try{
            $url_sen = "$graph_baseUrl/$key/extractSensitivityLabels"
            $response = Invoke-MgRestMethod -Uri $url_sen -Method POST -ErrorAction Stop
            $data = $response.labels
            $id = $data[0].sensitivityLabelId
            if ($data -and $data[0].sensitivityLabelId) {
                $id = $data[0].sensitivityLabelId
                $file_info_sensi[$file_info[$key]] = 
                    if ($id_to_display_name.ContainsKey($id)) 
                        { $id_to_display_name[$id] } 
                    else { "General" }
            } else {
                $file_info_sensi[$file_info[$key]] = "General"
            }
        }
        catch {
            Write-Host "An error occurred while retrieving sensitivity label: $_"
            $file_info_sensi[$file_info[$key]] = "General"
        }

    
        try {
            $url_access = "$graph_baseUrl/$key/analytics/alltime?select=access"
            
            $response = Invoke-MgRestMethod -Uri $url_access -Method GET -ErrorAction Stop
            
            $accessLog = $response.access
            
            if ($null -ne $accessLog) {
                $file_info_access[$file_info[$key]] = $accessLog
            } else {
                $file_info_access[$file_info[$key]] = $null
            }
        } catch {
            Write-Host "An error occurred while retrieving access data: $_"
            $file_info_access[$file_info[$key]] = $null
        }
        
    
        # get recent 90 days analytics log
        try {
            $startDate = (Get-Date).AddDays(-90).ToString('yyyy-MM-dd')
            
            $url_access = "$graph_baseUrl/$key/getActivitiesByInterval(startDateTime='$startDate',endDateTime='',interval='month')?select=access"
            
            $response = Invoke-MgRestMethod -Uri $url_access -Method GET -ErrorAction Stop
            
            $accessLog = $response.value
            
            if ($null -ne $accessLog) {
                $file_info_access_90days[$file_info[$key]] = $accessLog
            } else {
                $file_info_access_90days[$file_info[$key]] = $null
            }
        } catch {
            Write-Host "An error occurred while retrieving access data: $_"
            $file_info_access_90days[$file_info[$key]] = $null
        }
        
    
        # get permissions
        try {
            $url_userNum = "$graph_baseUrl/$key/permissions?count=true&top=0"
            $response_userNum = Invoke-MgRestMethod -Uri $url_userNum -Method GET -ErrorAction Stop
            $userNum = $response_userNum['@odata.count']
            
            $url_linkNum = "$graph_baseUrl/$key/permissions?filter=link/scope eq 'organization' or link/scope eq 'anonymous'&count=true&top=0"
            $response_linkNum = Invoke-MgRestMethod -Uri $url_linkNum -Method GET -ErrorAction Stop
            $linkNum = $response_linkNum['@odata.count']
            
            $url_owner = "$graph_baseUrl/$key/permissions?filter=roles/any(property:property eq 'owner')&select=grantedToV2,roles"
            $response_owner = Invoke-MgRestMethod -Uri $url_owner -Method GET -ErrorAction Stop
            if ($response_owner.value -and $response_owner.value[0] -and $response_owner.value[0].grantedToV2.user.email) {
                $owner = $response_owner.value[0].grantedToV2.user.email
            } else {
                $owner = $null
            }

            $file_info_permission[$file_info[$key]] = $userNum
            $file_info_scope[$file_info[$key]] = $linkNum
        
        } catch {
            Write-Host "An error occurred while retrieving permission data: $_"
            $file_info_permission[$file_info[$key]] = -1
            $file_info_scope[$file_info[$key]] = -1
            $owner = $null
        }
    
        # get activities log
        try {
            $url_activities = "$graph_baseUrl/$key/activities?select=action,actor"
            
            $response = Invoke-MgRestMethod -Uri $url_activities -Method GET -ErrorAction Stop
            
            $shared = $false
            
            foreach ($item in $response.value) {
                Get-Activity -entry $item -owner $owner -shared ([ref]$shared)
                if ($shared) {
                    break
                }
            }
            
            $file_info_shared[$file_info[$key]] = $shared
        
        } catch {
            Write-Host "An error occurred while retrieving activity data: $_"
            $file_info_shared[$file_info[$key]] = $null
        }        
    }
    
    $timestamp = (Get-Date).ToString("yyyy-MM-dd_HH-mm-ss")
    $csvFileName = "scan_report_$timestamp.csv"
    $csvFilePath = (Get-Location).Path + "\$csvfileName"

    $csvData = @()
    
    # generate report for each file
    foreach ($key in $file_info.Keys) {
        $fileName = $file_info[$key]
        $sensitivity = $file_info_sensi[$fileName]
        Write-Host $fileName $sensitivity
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