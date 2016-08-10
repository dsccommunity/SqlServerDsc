@{
# Version number of this module.
ModuleVersion = '1.8.0.0'

# ID used to uniquely identify this module
GUID = '74e9ddb5-4cbc-4fa2-a222-2bcfb533fd66'

# Author of this module
Author = 'Microsoft Corporation'

# Company or vendor of this module
CompanyName = 'Microsoft Corporation'

# Copyright statement for this module
Copyright = '(c) 2014 Microsoft Corporation. All rights reserved.'

# Description of the functionality provided by this module
Description = 'Module with DSC Resources for deployment and configuration of Microsoft SQL Server.'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '4.0'

# Minimum version of the common language runtime (CLR) required by this module
CLRVersion = '4.0'

# Functions to export from this module
FunctionsToExport = '*'

# Cmdlets to export from this module
CmdletsToExport = '*'

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = @('DesiredStateConfiguration', 'DSC', 'DSCResourceKit', 'DSCResource')

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/PowerShell/xSQLServer/blob/master/LICENSE'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/PowerShell/xSQLServer'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        ReleaseNotes = '* Converted appveyor.yml to install Pester from PSGallery instead of from Chocolatey.
* Added Support for SQL Server 2016
* xSQLAOGroupEnsure
   - Fixed spelling mistake in AutoBackupPreference property
   - Added BackupPriority property
* Added resources
  - xSQLServerPermission
  - xSQLServerEndpointState
  - xSQLServerEndpointPermission
  - xSQLServerAvailabilityGroupListener
* xSQLServerHelper
	- added functions 
		- Import-SQLPSModule
		- Get-SQLPSInstanceName
		- Get-SQLPSInstance
		- Get-SQLAlwaysOnEndpoint
	- modified functions
		- New-TerminatingError - *added optional parameter `InnerException` to be able to give the user more information in the returned message*

'

    } # End of PSData hashtable

} # End of PrivateData hashtable
}

