function Test-ConfidentialAndNoOrgScope {
    param (
        [hashtable]$scope,
        [String]$sensitivity
    )

    if ($sensitivity.ToLower().Contains('confidential')) {
        foreach ($key in $scope.Keys) { 
            if ($key -match "organization" -or $key -match "anonymous") {
                return $false
            }
        }
    }
    
    return $true
}
