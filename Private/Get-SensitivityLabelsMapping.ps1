# Description: This script returns a hashtable that maps sensitivity label ids to their display names.
function Get-SensitivityLabelsMapping {
    $data_list = @(
        @{ "id" = "87ba5c36-b7cf-4793-bbc2-bd5b3a9f95ca"; "name" = "Personal"; "displayName" = "Non-Business" },
        @{ "id" = "87867195-f2b8-4ac2-b0b6-6bb73cb33afc"; "name" = "Not Restricted"; "displayName" = "Public" },
        @{ "id" = "f42aa342-8706-4288-bd11-ebb85995028c"; "name" = "Internal"; "displayName" = "General" },
        # Confidential label and sublabels
        @{ "id" = "074e257c-5848-4582-9a6f-34a182080e71"; "name" = "Confidential"; "displayName" = "Confidential" },
        @{ "id" = "1a19d03a-48bc-4359-8038-5b5f6d5847c3"; "name" = "Any User (No Protection)_1"; "displayName" = "Any User (No Protection), Confidential" },
        @{ "id" = "9fbde396-1a24-4c79-8edf-9254a0f35055"; "name" = "Microsoft All Employees_1"; "displayName" = "Microsoft Extended, Confidential" },
        @{ "id" = "d9f23ae3-a239-45ea-bf23-f515f824c57b"; "name" = "Microsoft FTE Only_1"; "displayName" = "Microsoft FTE, Confidential" },
        @{ "id" = "fec751d2-ff79-4176-b06f-8a50d675b290"; "name" = "Recipients Only_0"; "displayName" = "Recipients Only, Confidential" },
        # Highly Confidential label and sublabels
        @{ "id" = "f5dc2dea-db0f-47cd-8b20-a52e1590fb64"; "name" = "Secret"; "displayName" = "Highly Confidential" },
        @{ "id" = "b7b9f8f9-3cae-48b6-8b79-2f3f184fa0ea"; "name" = "Any User (No Protection)_0"; "displayName" = "Any User (No Protection), Highly Confidential" },
        @{ "id" = "c179f820-d535-4b2f-b252-8a9c4ac14ec6"; "name" = "Microsoft All Employees_0"; "displayName" = "Microsoft Extended, Highly Confidential" },
        @{ "id" = "f74878b7-c0ff-44a4-82ff-8ce29f7fccb5"; "name" = "Microsoft FTE Only_0"; "displayName" = "Microsoft FTE, Highly Confidential" },
        @{ "id" = "a4239ae8-df55-4508-b037-a46ec1e6b836"; "name" = "Recipients Only_1"; "displayName" = "Recipients Only, Highly Confidential" }
    )

    # Create a hashtable to map the id to the display name
    $id_to_display_name = @{}
    foreach ($item in $data_list) {
        $id_to_display_name[$item.id] = $item.displayName
    }

    return $id_to_display_name
}
