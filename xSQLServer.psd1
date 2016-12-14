@{
# Version number of this module.
ModuleVersion = '4.0.0.0'

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
        ReleaseNotes = '- Fixes in xSQLServerConfiguration
  - Added support for clustered SQL instances
  - BREAKING CHANGE: Updated parameters to align with other resources (SQLServer / SQLInstanceName)
  - Updated code to utilize CIM rather than WMI
- Added tests for resources
  - xSQLServerConfiguration
  - xSQLServerSetup
  - xSQLServerDatabaseRole
  - xSQLAOGroupJoin
  - xSQLServerHelper and moved the existing tests for Restart-SqlService to it.
  - xSQLServerAlwaysOnService
- Fixes in xSQLAOGroupJoin
  - Availability Group name now appears in the error message for a failed Availability Group join attempt.
  - Get-TargetResource now works with Get-DscConfiguration
- Fixes in xSQLServerRole
  - Updated Ensure parameter to "Present" default value
  - Renamed helper functions *-SqlServerRole to *-SqlServerRoleMember
- Changes to xSQLAlias
  - Add UseDynamicTcpPort parameter for option "Dynamically determine port"
  - Change Get-WmiObject to Get-CimInstance in Resource and associated pester file
- Added CHANGELOG.md file
- Added issue template file (ISSUE_TEMPLATE.md) for "New Issue" and pull request template file (PULL_REQUEST_TEMPLATE.md) for "New Pull Request"
- Add Contributing.md file
- Changes to xSQLServerSetup
  - Now `Features` parameter is case-insensitive.
- BREAKING CHANGE: Removed xSQLServerPowerPlan from this module. The resource has been moved to [xComputerManagement](https://github.com/PowerShell/xComputerManagement) and is now called xPowerPlan.
- Changes and enhancements in xSQLServerDatabaseRole
  - BREAKING CHANGE: Fixed so the same user can now be added to a role in one or more databases, and/or one or more instances. Now the parameters `SQLServer` and `SQLInstanceName` are mandatory.
  - Enhanced so the same user can now be added to more than one role
- BREAKING CHANGE: Renamed xSQLAlias to xSQLServerAlias to align wíth naming convention.
- Changes to xSQLServerAlwaysOnService
  - Added RestartTimeout parameter
  - Fixed bug where the SQL Agent service did not get restarted after the IsHadrEnabled property was set.
  - BREAKING CHANGE: The mandatory parameters now include Ensure, SQLServer, and SQLInstanceName. SQLServer and SQLInstanceName are keys which will be used to uniquely identify the resource which allows AlwaysOn to be enabled on multiple instances on the same machine.
- Moved Restart-SqlService from MSFT_xSQLServerConfiguration.psm1 to xSQLServerHelper.psm1.
'

    } # End of PSData hashtable

} # End of PrivateData hashtable
}



