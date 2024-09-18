function New-Report {
    param (
        [string]$fileName,
        [int]$passPrivateAndNoAccessTest,
        [int]$passSharedByOthersTest,
        [int]$passConfidentialAndNoOrgScopeTest,
        [int]$passUnusedWithPermissionsTest
    )

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

    $reasons = @()
    $recommendations = @()
    $results = @()

    # Logic to check tests and set reasons, recommendations, results
    foreach ($item in $recommendation_list) {
        switch ($item.id) {
            "1" {
                if ($passPrivateAndNoAccessTest -eq 1) {
                    $reasons += ($item.reason + " - " + $item.result)
                    $recommendations += $item.recommendation
                    $results += $item.result
                }
            }
            "2" {
                if ($passPrivateAndNoAccessTest -eq 0) {
                    $reasons += ($item.reason + " - " + $item.result)
                    $recommendations += $item.recommendation
                    $results += $item.result
                }
            }
            "3" {
                if ($passSharedByOthersTest -eq 0) {
                    $reasons += ($item.reason + " - " + $item.result)
                    $recommendations += $item.recommendation
                    $results += $item.result
                }
            }
            "4" {
                if ($passConfidentialAndNoOrgScopeTest -eq 0) {
                    $reasons += ($item.reason + " - " + $item.result)
                    $recommendations += $item.recommendation
                    $results += $item.result
                }
            }
            "5" {
                if ($passUnusedWithPermissionsTest -eq 0) {
                    $reasons += ($item.reason + " - " + $item.result)
                    $recommendations += $item.recommendation
                    $results += $item.result
                }
            }
        }
    }

    # Aggregate results by priority
    $finalResult = "Secure"
    if ($results.Contains("High Risk")) {
        $finalResult = "High Risk"
    } elseif ($results.Contains("Low Risk")) {
        $finalResult = "Low Risk"
    }

    # Combine reasons and recommendations
    $finalReason = $reasons -join "`n"
    $finalRecommendation = $recommendations -join "`n"

    # Prepare final CSV object
    $csvData = [PSCustomObject]@{
        Path          = $fileName
        Result        = $finalResult
        Reason        = $finalReason
        Recommendation = $finalRecommendation
    }

    return $csvData
}
