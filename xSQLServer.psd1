@{
# Version number of this module.
ModuleVersion = '6.0.0.0'

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
        ReleaseNotes = '- Changes to xSQLServerConfiguration
  - BREAKING CHANGE: The parameter SQLInstanceName is now mandatory.
  - Resource can now be used to define the configuration of two or more different DB instances on the same server.
- Changes to xSQLServerRole
  - xSQLServerRole now correctly reports that the desired state is present when the login is already a member of the server roles.
- Added new resources
  - xSQLServerAlwaysOnAvailabilityGroup
- Changes to xSQLServerSetup
  - Properly checks for use of SQLSysAdminAccounts parameter in $PSBoundParameters. The test now also properly evaluates the setup argument for SQLSysAdminAccounts.
  - xSQLServerSetup should now function correctly for the InstallFailoverCluster action, and also supports cluster shared volumes. Note that the AddNode action is not currently working.
  - It now detects that feature Client Connectivity Tools (CONN) and Client Connectivity Backwards Compatibility Tools (BC) is installed.
  - Now it can correctly determine the right cluster when only parameter InstallSQLDataDir is assigned a path (issue 401).
  - Now the only mandatory path parameter is InstallSQLDataDir when installing Database Engine (issue 400).
  - It now can handle mandatory parameters, and are not using wildcards to find the variables containing paths (issue 394).
  - Changed so that instead of connection to localhost it is using $env:COMPUTERNAME as the host name to which it connects. And for cluster installation it uses the parameter FailoverClusterNetworkName as the host name to which it connects (issue 407).
  - When called with Action = "PrepareFailoverCluster", the SQLSysAdminAccounts and FailoverClusterGroup parameters are no longer passed to the setup process (issues 410 and 411).
  - Solved the problem that InstanceDir and InstallSQLDataDir could not be set to just a qualifier, i.e "E:" (issue 418). All paths (except SourcePath) can now be set to just the qualifier.
- Enables CodeCov.io code coverage reporting.
- Added badge for CodeCov.io to README.md.
- Examples
  - xSQLServerMaxDop
    - 1-SetMaxDopToOne.ps1
    - 2-SetMaxDopToAuto.ps1
    - 3-SetMaxDopToDefault.ps1
  - xSQLServerMemory
    - 1-SetMaxMemoryTo12GB.ps1
    - 2-SetMaxMemoryToAuto.ps1
    - 3-SetMinMaxMemoryToAuto.ps1
    - 4-SetMaxMemoryToDefault.ps1
  - xSQLServerDatabase
    - 1-CreateDatabase.ps1
    - 2-DeleteDatabase.ps1
- Added tests for resources
  - xSQLServerMaxDop
  - xSQLServerMemory
- Changes to xSQLServerMemory
  - BREAKING CHANGE: The mandatory parameter now include SQLInstanceName. The DynamicAlloc parameter is no longer mandatory
- Changes to xSQLServerDatabase
  - When the system is not in desired state the Test-TargetResource will now output verbose messages saying so.
- Changes to xSQLServerDatabaseOwner
  - Fixed code style, added updated parameter descriptions to schema.mof and README.md.

'

    } # End of PSData hashtable

} # End of PrivateData hashtable
}





