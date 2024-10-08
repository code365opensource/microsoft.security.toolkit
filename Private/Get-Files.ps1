# Description: This script recursively retrieves all files from a specified OneDrive folder, including files within subfolders, and returns a hashtable mapping file IDs to their relative paths. 
function Get-Files {
    param (
        [string]$folderPath
    )
    $global:fileInfo = @{}
    Get-SubFolderFiles -folderPath $folderPath -baseFolderPath $folderPath
    return $fileInfo
}


function Get-SubFolderFiles {
    param (
        [string]$folderPath,
        [string]$baseFolderPath
    )
    $graph_url = "https://graph.microsoft.com/v1.0/me/drive/root:/${folderPath}:/children?select=name,id,folder"
    $response = Invoke-MgRestMethod -Uri $graph_url -Method GET -ErrorAction Stop

    foreach ($item in $response.value) {
        if ($item.folder) {
            Get-SubFolderFiles -folderPath "$folderPath/$($item.name)" -baseFolderPath $baseFolderPath
        } else {
            $relativePath = $folderPath -replace "^$([regex]::Escape($baseFolderPath))/?", ""
            $fullPath = if ($relativePath) { "$relativePath/$($item.name)" } else { $item.name }
            $global:fileInfo[$item.id] = $fullPath
        }
    }
}




