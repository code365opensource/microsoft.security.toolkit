# The unofficial Microsoft Security Toolkit PowerShell Module

[![PowerShell Gallery Version](https://img.shields.io/powershellgallery/v/microsoft.security.toolkit?label=microsoft.security.toolkit)](https://www.powershellgallery.com/packages/microsoft.security.toolkit) [![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/microsoft.security.toolkit)](https://www.powershellgallery.com/packages/microsoft.security.toolkit) [![](https://img.shields.io/badge/change-logs-blue)](CHANGELOG.md) ![https://img.shields.io/powershellgallery/p/microsoft.security.toolkit.svg](https://img.shields.io/powershellgallery/p/microsoft.security.toolkit.svg)


## Install the module

```powershell
Install-Module -Name microsoft.security.toolkit -Scope CurrentUser

# or if you want to install the preview version
Install-Module -Name microsoft.security.toolkit -Scope CurrentUser -AllowPrerelease
```

## How to use the toolkit

```markdown
NAME
    New-SecurityScan

ALIAS
    amisecure
    
SYNOPSIS
    This function will scan the files in the OneDrive folder for any security issues.
    
    
SYNTAX
    New-SecurityScan [-pathOfOneDrive] <String> [[-accessToken] <String>] [<CommonParameters>]
    
    
DESCRIPTION
    This function will scan the files in the OneDrive folder for any security issues.
    

PARAMETERS
    -pathOfOneDrive <String>
        The path of the OneDrive folder. This is a relative path to the user's OneDrive folder, don't provide the full path here.
        
        Required?                    true
        Position?                    1
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -accessToken <String>
        The access token to access the OneDrive folder. This is optional, if not provided, the function will prompt for the access token, please make sure your token includes two scopes - "Files.Read.All", "InformationProtectionPolicy.Read".
        Follow the doc (https://github.com/code365opensource/microsoft.security.toolkit/blob/master/FollowMe.md) to get started.
        
        Required?                    false
        Position?                    2
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see
        about_CommonParameters (https://go.microsoft.com/fwlink/?LinkID=113216). 
        
OUTPUTS
    This function will generate a report of the security issues found in the OneDrive folder, and can be export to csv.
```


## Update the module

```powershell
Update-Module -Name microsoft.security.toolkit -Scope CurrentUser
```

## Uninstall the module

```powershell
Uninstall-Module -Name microsoft.security.toolkit -Scope CurrentUser
```
