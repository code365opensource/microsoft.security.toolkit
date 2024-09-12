# Description: This script is used to get the permissions of a file.
function Get-Permission {
    param (
        $entry,
        [ref]$user_name,
        $scope,
        [ref]$owner
    )
    if ($entry.ContainsKey('grantedToIdentitiesV2')) {
        $identities = $entry.grantedToIdentitiesV2
        $linkType = $entry.link.type
        $linkScope = $entry.link.scope

        if (-not $scope.ContainsKey($linkScope)) {
            $scope[$linkScope] = $linkType
        } else {
            $scope[$linkScope] = if ($scope[$linkScope] -eq 'edit') { $scope[$linkScope] } else { $linkType }
        }
    } 
    elseif ($entry.ContainsKey("grantedToV2")) {$identities = @($entry.grantedToV2)} 
    else {
        return
    }

    if($entry.roles -Contains "owner") {
        $owner.Value = $identities[0].user.email
    }

    foreach ($identity in $identities) {
        if ($identity.ContainsKey("user")) {
            $user = $identity.user
            $display_name = $user.displayName
            if ($display_name -ne "N/A") {
                $null = $user_name.Value.Add($display_name)
            }
        } elseif ($identity.ContainsKey("group")) {
            $group = $identity.group
            $group_id = $group.id
            if ($group_id -ne "N/A") {
                $response = Invoke-MgRestMethod -Uri "https://graph.microsoft.com/v1.0/groups/$group_id/members?select=displayName" -Method GET
                foreach ($item in $response.value) {
                    $null = $user_name.Value.Add($item.displayName)
                }
            }
        }
    }
}