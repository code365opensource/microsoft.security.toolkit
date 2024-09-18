# Description: This script is used to get the activity of a file.
function Get-Activity {
    param (
        $entry,
        $owner,
        [ref]$shared
    )

    if ($entry.ContainsKey('action')) {
        $action = $entry.action

        if ($action.ContainsKey('share')) {
            $email = $entry.actor.user.email
            if ($email -ne $owner -and $null -ne $owner) {
                $shared.Value = $true
                return
            }
        }
    }
}