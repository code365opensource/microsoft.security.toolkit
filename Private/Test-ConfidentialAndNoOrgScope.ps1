function Test-ConfidentialAndNoOrgScope {
    param (
        [int]$scope,
        [String]$sensitivity
    )

    if ($sensitivity.ToLower().Contains('confidential') -and $scope -gt 0) {
        return $false
    }
    
    return $true
}
