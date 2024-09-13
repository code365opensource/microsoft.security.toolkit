# Description: This script returns a hashtable that maps sensitivity label ids to their display names.
function Get-SensitivityLabelsMapping {

    $sensi_label_url = "https://graph.microsoft.com/beta/me/informationProtection/sensitivityLabels"
    $response = Invoke-MgRestMethod -Uri $sensi_label_url -Method GET
    $id_to_display_name = @{}

    foreach ($label in $response.value) {
        $id = $label.id
        $displayName = $label.displayName
        $id_to_display_name[$id] = $displayName;
    
        if ($label.sublabels) {
            foreach ($sublabel in $label.sublabels) {
                $subId = $sublabel.id
                $subDisplayName = $sublabel.displayName
                $id_to_display_name[$subId] = $subDisplayName;
            }
        }
    }
    
    return $id_to_display_name
}
