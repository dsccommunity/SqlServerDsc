@{
# Version number of this module.
ModuleVersion = '1.6.0.0'

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
        ReleaseNotes = '* Resources Added
  - xSQLAOGroupEnsure
  - xSQLAOGroupJoin
  - xWaitForAvailabilityGroup
  - xSQLServerEndPoint
  - xSQLServerAlwaysOnService
* xSQLServerHelper
	- added functions 
		- Connect-SQL
		- New-VerboseMessage
		- Grant-ServerPerms
		- Grant-CNOPerms
		- New-ListenerADObject
* xSQLDatabaseRecoveryModel
	- Updated Verbose statements to use new function New-VerboseMessage
* xSQLServerDatabase
	- Updated Verbose statements to use new function New-VerboseMessage
	- Removed ConnectSQL function and replaced with new Connect-SQL function
* xSQLServerDatabaseOwner
	- Removed ConnectSQL function and replaced with new Connect-SQL function
* xSQLServerDatabasePermissions
	- Removed ConnectSQL function and replaced with new Connect-SQL function
* xSQLServerDatabaseRole
	- Removed ConnectSQL function and replaced with new Connect-SQL function
* xSQLServerLogin
	- Removed ConnectSQL function and replaced with new Connect-SQL function
* xSQLServerMaxDop
	- Updated Verbose statements to use new function New-VerboseMessage
	- Removed ConnectSQL function and replaced with new Connect-SQL function
* xSQLServerMemory
	- Updated Verbose statements to use new function New-VerboseMessage
	- Removed ConnectSQL function and replaced with new Connect-SQL function
* xSQLServerPowerPlan
	- Updated Verbose statements to use new function New-VerboseMessage

'

    } # End of PSData hashtable

} # End of PrivateData hashtable
}
