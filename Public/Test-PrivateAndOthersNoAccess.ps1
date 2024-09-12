function Test-PrivateAndOthersNoAccess {
    param (
        [int]$permissionCount,
        [hashtable]$accessLog
    )

    if ($permissionCount -lt 2 -and $accessLog["actorCount"] -gt 1) {
        return $false
    }
    return $true
}
