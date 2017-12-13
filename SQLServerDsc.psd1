@{
  # Version number of this module.
  ModuleVersion = '10.0.0.0'

  # ID used to uniquely identify this module
  GUID = '74e9ddb5-4cbc-4fa2-a222-2bcfb533fd66'

  # Author of this module
  Author = 'Microsoft Corporation'

  # Company or vendor of this module
  CompanyName = 'Microsoft Corporation'

  # Copyright statement for this module
  Copyright = '(c) 2017 Microsoft Corporation. All rights reserved.'

  # Description of the functionality provided by this module
  Description = 'Module with DSC Resources for deployment and configuration of Microsoft SQL Server.'

  # Minimum version of the Windows PowerShell engine required by this module
  PowerShellVersion = '5.0'

  # Minimum version of the common language runtime (CLR) required by this module
  CLRVersion = '4.0'

  # Functions to export from this module
  FunctionsToExport = '*'

  # Cmdlets to export from this module
  CmdletsToExport = '*'

  RequiredAssemblies = @()

  # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
  PrivateData = @{

      PSData = @{

          # Tags applied to this module. These help with module discovery in online galleries.
          Tags = @('DesiredStateConfiguration', 'DSC', 'DSCResourceKit', 'DSCResource')

          # A URL to the license for this module.
          LicenseUri = 'https://github.com/PowerShell/SqlServerDsc/blob/master/LICENSE'

          # A URL to the main website for this project.
          ProjectUri = 'https://github.com/PowerShell/SqlServerDsc'

          # A URL to an icon representing this module.
          # IconUri = ''

          # ReleaseNotes of this module
        ReleaseNotes = '- BREAKING CHANGE: Resource module has been renamed to SqlServerDsc
  ([issue 916](https://github.com/PowerShell/SqlServerDsc/issues/916)).
- BREAKING CHANGE: Significant rename to reduce length of resource names
  - See [issue 851](https://github.com/PowerShell/SqlServerDsc/issues/851) for a
    complete table mapping rename changes.
  - Impact to all resources.
- Changes to CONTRIBUTING.md
  - Added details to the naming convention used in SqlServerDsc.
- Changes to SqlServerDsc
  - The examples in the root of the Examples folder are obsolete. A note was
    added to the comment-based help in each example stating it is obsolete.
    This is a temporary measure until they are replaced
    ([issue 904](https://github.com/PowerShell/SqlServerDsc/issues/904)).
  - Added new common test (regression test) for validating the long path
    issue for compiling resources in Azure Automation.
  - Fix resources in alphabetical order in README.md ([issue 908](https://github.com/PowerShell/SqlServerDsc/issues/908)).
- Changes to SqlAG
  - BREAKING CHANGE: Parameters SQLServer and SQLInstanceName has been renamed
    to ServerName and InstanceName respectively
    ([issue 308](https://github.com/PowerShell/SqlServerDsc/issues/308)).
  - BREAKING CHANGE: The read-only property SQLServerNetName was removed in favor
    of EndpointHostName ([issue 924](https://github.com/PowerShell/SqlServerDsc/issues/924)).
    Get-TargetResource will now return the value of property [NetName](https://technet.microsoft.com/en-us/library/microsoft.sqlserver.management.smo.server.netname(v=sql.105).aspx)
    for the property EndpointHostName.
- Changes to SqlAGDatabase
  - BREAKING CHANGE: Parameters SQLServer and SQLInstanceName has been renamed
    to ServerName and InstanceName respectively
    ([issue 308](https://github.com/PowerShell/SqlServerDsc/issues/308)).
  - Changed the Get-MatchingDatabaseNames function to be case insensitive when
    matching database names ([issue 912](https://github.com/PowerShell/SqlServerDsc/issues/912)).
- Changes to SqlAGListener
  - BREAKING CHANGE: Parameter NodeName has been renamed to ServerName
    ([issue 308](https://github.com/PowerShell/SqlServerDsc/issues/308)).
- Changes to SqlAGReplica
  - BREAKING CHANGE: Parameters SQLServer and SQLInstanceName has been renamed
    to ServerName and InstanceName respectively
    ([issue 308](https://github.com/PowerShell/SqlServerDsc/issues/308)).
  - BREAKING CHANGE: Parameters PrimaryReplicaSQLServer and PrimaryReplicaSQLInstanceName
    has been renamed to PrimaryReplicaServerName and PrimaryReplicaInstanceName
    respectively ([issue 922](https://github.com/PowerShell/SqlServerDsc/issues/922)).
  - BREAKING CHANGE: The read-only property SQLServerNetName was removed in favor
    of EndpointHostName ([issue 924](https://github.com/PowerShell/SqlServerDsc/issues/924)).
    Get-TargetResource will now return the value of property [NetName](https://technet.microsoft.com/en-us/library/microsoft.sqlserver.management.smo.server.netname(v=sql.105).aspx)
    for the property EndpointHostName.
- Changes to SqlAlwaysOnService
  - BREAKING CHANGE: Parameters SQLServer and SQLInstanceName has been renamed
    to ServerName and InstanceName respectively
    ([issue 308](https://github.com/PowerShell/SqlServerDsc/issues/308)).
- Changes to SqlDatabase
  - BREAKING CHANGE: Parameters SQLServer and SQLInstanceName has been renamed
    to ServerName and InstanceName respectively
    ([issue 308](https://github.com/PowerShell/SqlServerDsc/issues/308)).
- Changes SqlDatabaseDefaultLocation
  - BREAKING CHANGE: Parameters SQLServer and SQLInstanceName has been renamed
    to ServerName and InstanceName respectively
    ([issue 308](https://github.com/PowerShell/SqlServerDsc/issues/308)).
- Changes to SqlDatabaseOwner
  - BREAKING CHANGE: Parameters SQLServer and SQLInstanceName has been renamed
    to ServerName and InstanceName respectively
    ([issue 308](https://github.com/PowerShell/SqlServerDsc/issues/308)).
- Changes to SqlDatabasePermission
  - BREAKING CHANGE: Parameters SQLServer and SQLInstanceName has been renamed
    to ServerName and InstanceName respectively
    ([issue 308](https://github.com/PowerShell/SqlServerDsc/issues/308)).
- Changes to SqlDatabaseRecoveryModel
  - BREAKING CHANGE: Parameters SQLServer and SQLInstanceName has been renamed
    to ServerName and InstanceName respectively
    ([issue 308](https://github.com/PowerShell/SqlServerDsc/issues/308)).
- Changes to SqlDatabaseRole
  - BREAKING CHANGE: Parameters SQLServer and SQLInstanceName has been renamed
    to ServerName and InstanceName respectively
    ([issue 308](https://github.com/PowerShell/SqlServerDsc/issues/308)).
- Changes to SqlRS
  - BREAKING CHANGE: Parameters RSSQLServer and RSSQLInstanceName has been renamed
    to DatabaseServerName and DatabaseInstanceName respectively
    ([issue 923](https://github.com/PowerShell/SqlServerDsc/issues/923)).
- Changes to SqlServerConfiguration
  - BREAKING CHANGE: Parameters SQLServer and SQLInstanceName has been renamed
    to ServerName and InstanceName respectively
    ([issue 308](https://github.com/PowerShell/SqlServerDsc/issues/308)).
- Changes to SqlServerEndpoint
  - BREAKING CHANGE: Parameters SQLServer and SQLInstanceName has been renamed
    to ServerName and InstanceName respectively
    ([issue 308](https://github.com/PowerShell/SqlServerDsc/issues/308)).
- Changes to SqlServerEndpointPermission
  - BREAKING CHANGE: Parameter NodeName has been renamed to ServerName
    ([issue 308](https://github.com/PowerShell/SqlServerDsc/issues/308)).
  - Now the examples files have a shorter name so that resources will not fail
    to compile in Azure Automation ([issue 934](https://github.com/PowerShell/SqlServerDsc/issues/934)).
- Changes to SqlServerEndpointState
  - BREAKING CHANGE: Parameter NodeName has been renamed to ServerName
    ([issue 308](https://github.com/PowerShell/SqlServerDsc/issues/308)).
- Changes to SqlServerLogin
  - BREAKING CHANGE: Parameters SQLServer and SQLInstanceName has been renamed
    to ServerName and InstanceName respectively
    ([issue 308](https://github.com/PowerShell/SqlServerDsc/issues/308)).
- Changes to SqlServerMaxDop
  - BREAKING CHANGE: Parameters SQLServer and SQLInstanceName has been renamed
    to ServerName and InstanceName respectively
    ([issue 308](https://github.com/PowerShell/SqlServerDsc/issues/308)).
- Changes to SqlServerMemory
  - BREAKING CHANGE: Parameters SQLServer and SQLInstanceName has been renamed
    to ServerName and InstanceName respectively
    ([issue 308](https://github.com/PowerShell/SqlServerDsc/issues/308)).
- Changes to SqlServerNetwork
  - BREAKING CHANGE: Parameters SQLServer has been renamed to ServerName
    ([issue 308](https://github.com/PowerShell/SqlServerDsc/issues/308)).
- Changes to SqlServerPermission
  - BREAKING CHANGE: Parameter NodeName has been renamed to ServerName
    ([issue 308](https://github.com/PowerShell/SqlServerDsc/issues/308)).
- Changes to SqlServerRole
  - BREAKING CHANGE: Parameters SQLServer and SQLInstanceName has been renamed
    to ServerName and InstanceName respectively
    ([issue 308](https://github.com/PowerShell/SqlServerDsc/issues/308)).
- Changes to SqlServerServiceAccount
  - BREAKING CHANGE: Parameters SQLServer and SQLInstanceName has been renamed
    to ServerName and InstanceName respectively
    ([issue 308](https://github.com/PowerShell/SqlServerDsc/issues/308)).

'

      } # End of PSData hashtable

  } # End of PrivateData hashtable
  }











