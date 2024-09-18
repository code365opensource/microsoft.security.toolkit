function Test-PrivateAndOthersNoAccess {
    param (
        [int]$permissionCount,
        [hashtable]$accessLog
    )

    if ($permissionCount -gt 1 -or $permissionCount -lt 0 -or $accessLog -eq $null) {
        return 2
    }
    if ($accessLog["actorCount"] -lt 2) {
        return 1
    }
    return 0
}
