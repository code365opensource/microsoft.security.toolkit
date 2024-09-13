function Test-ConfidentialAndNoOrgScope {
    param (
        [hashtable]$scope,
        [String]$sensitivity
    )

    if (-not (
        $sensitivity.ToLower().Contains('personal') -or 
        $sensitivity.ToLower().Contains('not restricted') -or 
        $sensitivity.ToLower().Contains('general')
    )) {
        foreach ($key in $scope.Keys) { 
            if ($key -match "organization" -or $key -match "anonymous") {
                return $false
            }
        }
    }
    
    return $true
}
