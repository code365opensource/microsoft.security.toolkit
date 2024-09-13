function Test-SharedByOthers {
    param (
        $sharedWithOthers
    )
    if ($null -eq $sharedWithOthers) {
        return 2
    }
    if ($sharedWithOthers) {
        return 0
    }
    return 1
}
