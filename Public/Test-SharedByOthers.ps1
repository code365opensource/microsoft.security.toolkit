function Test-SharedByOthers {
    param (
        [bool]$sharedWithOthers
    )
    return -not $sharedWithOthers
}
