@{
  # Version number of this module.
  moduleVersion = '13.1.0.0'

  # ID used to uniquely identify this module
  GUID = '693ee082-ed36-45a7-b490-88b07c86b42f'

  # Author of this module
  Author = 'Microsoft Corporation'

  # Company or vendor of this module
  CompanyName = 'Microsoft Corporation'

  # Copyright statement for this module
  Copyright = '(c) 2018 Microsoft Corporation. All rights reserved.'

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
        ReleaseNotes = '- Changes to SqlServerDsc
  - New DSC resource SqlAgentFailsafe
  - New DSC resource SqlDatabaseUser ([issue 846](https://github.com/PowerShell/SqlServerDsc/issues/846)).
    - Adds ability to create database users with more fine-grained control,
      e.g. re-mapping of orphaned logins or a different login. Supports
      creating a user with or without login name, and database users mapped
      to a certificate or asymmetric key.
  - Changes to helper function Invoke-Query
    - Fixes issues in [issue 1355](https://github.com/PowerShell/SqlServerDsc/issues/1355).
    - Works together with Connect-SQL now.
    - Parameters now match that of Connect-SQL ([issue 1392](https://github.com/PowerShell/SqlServerDsc/issues/1392)).
    - Can now pass in credentials.
    - Can now pass in "Microsoft.SqlServer.Management.Smo.Server" object.
    - Can also pipe in "Microsoft.SqlServer.Management.Smo.Server" object.
    - Can pipe Connect-SQL | Invoke-Query.
    - Added default values to Invoke-Query.
    - Now it will output verbose messages of the query that is run, so it
      not as quiet of what it is doing when a user asks for verbose output
      ([issue 1404](https://github.com/PowerShell/SqlServerDsc/issues/1404)).
    - It is possible to redact text in the verbose output by providing
      strings in the new parameter `RedactText`.
  - Minor style fixes in unit tests.
  - Changes to helper function Connect-SQL
    - When impersonating WindowsUser credential use the NetworkCredential UserName.
    - Added additional verbose logging.
    - Connect-SQL now uses parameter sets to more intuitive evaluate that
      the correct parameters are used in different scenarios
      ([issue 1403](https://github.com/PowerShell/SqlServerDsc/issues/1403)).
  - Changes to helper function Connect-SQLAnalysis
    - Parameters now match that of Connect-SQL ([issue 1392](https://github.com/PowerShell/SqlServerDsc/issues/1392)).
  - Changes to helper function Restart-SqlService
    - Parameters now match that of Connect-SQL ([issue 1392](https://github.com/PowerShell/SqlServerDsc/issues/1392)).
  - Changes to helper function Restart-ReportingServicesService
    - Parameters now match that of Connect-SQL ([issue 1392](https://github.com/PowerShell/SqlServerDsc/issues/1392)).
  - Changes to helper function Split-FullSqlInstanceName
    - Parameters and function name changed to use correct casing.
  - Changes to helper function Get-SqlInstanceMajorVersion
    - Parameters now match that of Connect-SQL ([issue 1392](https://github.com/PowerShell/SqlServerDsc/issues/1392)).
  - Changes to helper function Test-LoginEffectivePermissions
    - Parameters now match that of Connect-SQL ([issue 1392](https://github.com/PowerShell/SqlServerDsc/issues/1392)).
  - Changes to helper function Test-AvailabilityReplicaSeedingModeAutomatic
    - Parameters now match that of Connect-SQL ([issue 1392](https://github.com/PowerShell/SqlServerDsc/issues/1392)).
- Changes to SqlServerSecureConnection
  - Forced $Thumbprint to lowercase to fix [issue 1350](https://github.com/PowerShell/SqlServerDsc/issues/1350).
  - Add parameter SuppressRestart with default value false.
    This allows users to suppress restarts after changes have been made.
    Changes will not take effect until the service has been restarted.
- Changes to SqlSetup
  - Correct minor style violation [issue 1387](https://github.com/PowerShell/SqlServerDsc/issues/1387).
- Changes to SqlDatabase
  - Get-TargetResource now correctly return `$null` for the collation property
    when the database does not exist ([issue 1395](https://github.com/PowerShell/SqlServerDsc/issues/1395)).
  - No longer enforces the collation property if the Collation parameter
    is not part of the configuration ([issue 1396](https://github.com/PowerShell/SqlServerDsc/issues/1396)).
  - Updated resource description in README.md
  - Fix examples to use `PsDscRunAsCredential` ([issue 760](https://github.com/PowerShell/SqlServerDsc/issues/760)).
  - Added integration tests ([issue 739](https://github.com/PowerShell/SqlServerDsc/issues/739)).
  - Updated unit tests to the latest template ([issue 1068](https://github.com/PowerShell/SqlServerDsc/issues/1068)).

'

      } # End of PSData hashtable

  } # End of PrivateData hashtable
  }
























