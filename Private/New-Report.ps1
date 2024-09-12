function New-Report {
    param (
        [string]$fileName,
        [bool]$passPrivateAndNoAccessTest,
        [bool]$passSharedByOthersTest,
        [bool]$passConfidentialAndNoOrgScopeTest,
        [bool]$passUnusedWithPermissionsTest
    )

    $csvData = @()

    # Recommendation list as provided
    $recommendation_list = @(
        @{ 
            "id" = "1"; 
            "result" = "Secure"; 
            "reason" = "The file is 'Private' (didn't share to anyone), and didn't have any access logs during all times"; 
            "recommendation" = "N/A" 
        },
        @{ 
            "id" = "2"; 
            "result" = "Low Risk"; 
            "reason" = "The file is 'Private' currently, but has access logs during all times (others accessed the file recently)"; 
            "recommendation" = "Review the doc and evaluate the impact" 
        },
        @{ 
            "id" = "3"; 
            "result" = "Low Risk"; 
            "reason" = "The file has been shared by others, rather than by the owner"; 
            "recommendation" = "Review the permissions" 
        },
        @{ 
            "id" = "4"; 
            "result" = "High Risk"; 
            "reason" = "The file is classified as 'confidential' or 'high confidential', but shared with 'organization' or 'anonymous'"; 
            "recommendation" = "Review the permissions and remove share links" 
        },
        @{ 
            "id" = "5"; 
            "result" = "Low Risk"; 
            "reason" = "The file has not been used in the last 90 days, but still has permission settings"; 
            "recommendation" = "Review the doc and remove the permissions if possible" 
        },
        @{ 
            "id" = "6"; 
            "result" = "Secure"; 
            "reason" = "The file passes all the security tests"; 
            "recommendation" = "N/A" 
        }
    )

    # Condition-based report generation
    if ($passPrivateAndNoAccessTest -and $passSharedByOthersTest -and $passConfidentialAndNoOrgScopeTest -and $passUnusedWithPermissionsTest) {
        # If all checks are true, generate only ID=6 (Secure)
        $entry = $recommendation_list | Where-Object { $_.id -eq "6" }
        $csvData += [PSCustomObject]@{
            Path          = $fileName
            Result        = $entry.result
            Reason        = $entry.reason
            Recommendation = $entry.recommendation
        }
    } else {
        # If passPrivateAndNoAccessTest is true, generate ID=1; otherwise generate ID=2
        if ($passPrivateAndNoAccessTest) {
            $entry = $recommendation_list | Where-Object { $_.id -eq "1" }
        } else {
            $entry = $recommendation_list | Where-Object { $_.id -eq "2" }
        }
        $csvData += [PSCustomObject]@{
            Path          = $fileName
            Result        = $entry.result
            Reason        = $entry.reason
            Recommendation = $entry.recommendation
        }

        # If passSharedByOthersTest is false, generate ID=3
        if (-not $passSharedByOthersTest) {
            $entry = $recommendation_list | Where-Object { $_.id -eq "3" }
            $csvData += [PSCustomObject]@{
                Path          = $fileName
                Result        = $entry.result
                Reason        = $entry.reason
                Recommendation = $entry.recommendation
            }
        }

        # If passConfidentialAndNoOrgScopeTest is false, generate ID=4
        if (-not $passConfidentialAndNoOrgScopeTest) {
            $entry = $recommendation_list | Where-Object { $_.id -eq "4" }
            $csvData += [PSCustomObject]@{
                Path          = $fileName
                Result        = $entry.result
                Reason        = $entry.reason
                Recommendation = $entry.recommendation
            }
        }

        # If passUnusedWithPermissionsTest is false, generate ID=5
        if (-not $passUnusedWithPermissionsTest) {
            $entry = $recommendation_list | Where-Object { $_.id -eq "5" }
            $csvData += [PSCustomObject]@{
                Path          = $fileName
                Result        = $entry.result
                Reason        = $entry.reason
                Recommendation = $entry.recommendation
            }
        }
    }

    return $csvData
}