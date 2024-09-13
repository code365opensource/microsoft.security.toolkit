function Test-UnusedWithPermissions {
    param (
        [array]$accessLog90days,
        [int]$permissionCount
    )

    if ($accessLog90days -eq $null -or $permissionCount -lt 0) {
        return 2
    }

    $sumActionCount = 0

    foreach ($log in $accessLog90days) {
        $actionCount = $log.access.Value.actionCount
        $sumActionCount += $actionCount
    }

    if ($sumActionCount -eq 0 -and $permissionCount -gt 1) {
        return 1
    }

    return 0
}
