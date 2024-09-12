function Test-UnusedWithPermissions {
    param (
        [array]$accessLog90days,
        [int]$permissionCount
    )

    $sumActionCount = 0

    foreach ($log in $accessLog90days) {
        $actionCount = $log.access.Value.actionCount
        $sumActionCount += $actionCount
    }

    if ($sumActionCount -eq 0 -and $permissionCount -gt 1) {
        return $false
    }

    return $true
}
