function Test-ConfidentialAndNoOrgScope {
    param (
        [int]$scope,
        [String]$sensitivity
    )
    if ( $scope -lt 0 ) {
        return 2
    }

    if (-not (
        $sensitivity.ToLower().Contains('personal') -or 
        $sensitivity.ToLower().Contains('not restricted') -or 
        $sensitivity.ToLower().Contains('general')
    )) {
        if($scope -gt 0) {
            return 0
        } else {
            return 1
        }
    }
    
    return 1
}
