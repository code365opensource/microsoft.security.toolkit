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
        Connect-Graph -Scopes "Files.Read" -NoWelcome
    }
    else {
        Connect-Graph -AccessToken (ConvertTo-SecureString $accessToken -AsPlainText -Force) -NoWelcome
    }

    # implement the scan and evaluation logic here, You can use Invoke-MgRestMethod for any Microsoft Graph API calls. (LEARN more : Get-Help Invoke-MgRestMethod)

    
    $result = @(
        [PSCustomObject]@{path = "xxxxx"; result = "secure"; reason = "n/a"; recommendation = "n/a" },
        [PSCustomObject]@{path = "xxxxx"; result = "low risk"; reason = "some reason"; recommendation = "the recommendation" },
        [PSCustomObject]@{path = "xxxxx"; result = "high risk"; reason = "some reason"; recommendation = "the recommendation" }
    )
    
    # save the output to a csv file, name it with the current timestamp
    $result | Export-Csv -Path ("security_scan_{0}_{1}.csv" -f $pathOfOneDrive, $(Get-Date -Format 'yyyyMMddHHmmss')) -NoTypeInformation

    # Output the result in Console
    $result

}