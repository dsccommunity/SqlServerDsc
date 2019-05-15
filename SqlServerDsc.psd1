@{
  # Version number of this module.
  moduleVersion = '12.5.0.0'

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
        ReleaseNotes = '- Changes to SqlServerSecureConnection
  - Updated README and added example for SqlServerSecureConnection,
    instructing users to use the "SYSTEM" service account instead of
    "LocalSystem".
- Changes to SqlScript
  - Correctly passes the `$VerbosePreference` to the helper function
    `Invoke-SqlScript` so that `PRINT` statements is outputted correctly
    when verbose output is requested, e.g
    `Start-DscConfiguration -Verbose`.
  - Added en-US localization ([issue 624](https://github.com/PowerShell/SqlServerDsc/issues/624)).
  - Added additional unit tests for code coverage.
- Changes to SqlScriptQuery
  - Correctly passes the `$VerbosePreference` to the helper function
    `Invoke-SqlScript` so that `PRINT` statements is outputted correctly
    when verbose output is requested, e.g
    `Start-DscConfiguration -Verbose`.
  - Added en-US localization.
  - Added additional unit tests for code coverage.
- Changes to SqlSetup
  - Concatenated Robocopy localization strings ([issue 694](https://github.com/PowerShell/SqlServerDsc/issues/694)).
  - Made the error message more descriptive when the Set-TargetResource
    function calls the Test-TargetResource function to verify the desired
    state.
- Changes to SqlWaitForAG
  - Added en-US localization ([issue 625](https://github.com/PowerShell/SqlServerDsc/issues/625)).
- Changes to SqlServerPermission
  - Added en-US localization ([issue 619](https://github.com/PowerShell/SqlServerDsc/issues/619)).
- Changes to SqlServerMemory
  - Added en-US localization ([issue 617](https://github.com/PowerShell/SqlServerDsc/issues/617)).
  - No longer will the resource set the MinMemory value if it was provided
    in a configuration that also set the `Ensure` parameter to "Absent"
    ([issue 1329](https://github.com/PowerShell/SqlServerDsc/issues/1329)).
  - Refactored unit tests to simplify them add add slightly more code
    coverage.
- Changes to SqlServerMaxDop
  - Added en-US localization ([issue 616](https://github.com/PowerShell/SqlServerDsc/issues/616)).
- Changes to SqlRS
  - Reporting Services are restarted after changing settings, unless
    `$SuppressRestart` parameter is set ([issue 1331](https://github.com/PowerShell/SqlServerDsc/issues/1331)).
    `$SuppressRestart` will also prevent Reporting Services restart after initialization.
  - Fixed one of the error handling to use localization, and made the
    error message more descriptive when the Set-TargetResource function
    calls the Test-TargetResource function to verify the desired
    state. *This was done prior to adding full en-US localization.*
  - Fixed ([issue 1258](https://github.com/PowerShell/SqlServerDsc/issues/1258)).
    When initializing Reporting Services, there is no need to execute `InitializeReportServer`
    CIM method, since executing `SetDatabaseConnection` CIM method initializes
    Reporting Services.
  - [issue 864](https://github.com/PowerShell/SqlServerDsc/issues/864) SqlRs
    can now initialise SSRS 2017 instances
- Changes to SqlServerLogin
  - Added en-US localization ([issue 615](https://github.com/PowerShell/SqlServerDsc/issues/615)).
  - Added unit tests to improved code coverage.
- Changes to SqlWindowsFirewall
  - Added en-US localization ([issue 614](https://github.com/PowerShell/SqlServerDsc/issues/614)).
- Changes to SqlServerEndpoint
  - Added en-US localization ([issue 611](https://github.com/PowerShell/SqlServerDsc/issues/611)).
- Changes to SqlServerEndpointPermission
  - Added en-US localization ([issue 612](https://github.com/PowerShell/SqlServerDsc/issues/612)).
- Changes to SqlServerEndpointState
  - Added en-US localization ([issue 613](https://github.com/PowerShell/SqlServerDsc/issues/613)).
- Changes to SqlDatabaseRole
  - Added en-US localization ([issue 610](https://github.com/PowerShell/SqlServerDsc/issues/610)).
- Changes to SqlDatabaseRecoveryModel
  - Added en-US localization ([issue 609](https://github.com/PowerShell/SqlServerDsc/issues/609)).
- Changes to SqlDatabasePermission
  - Added en-US localization ([issue 608](https://github.com/PowerShell/SqlServerDsc/issues/608)).
- Changes to SqlDatabaseOwner
  - Added en-US localization ([issue 607](https://github.com/PowerShell/SqlServerDsc/issues/607)).
- Changes to SqlDatabase
  - Added en-US localization ([issue 606](https://github.com/PowerShell/SqlServerDsc/issues/606)).
- Changes to SqlAGListener
  - Added en-US localization ([issue 604](https://github.com/PowerShell/SqlServerDsc/issues/604)).
- Changes to SqlAlwaysOnService
  - Added en-US localization ([issue 603](https://github.com/PowerShell/SqlServerDsc/issues/608)).
- Changes to SqlAlias
  - Added en-US localization ([issue 602](https://github.com/PowerShell/SqlServerDsc/issues/602)).
  - Removed ShouldProcess for the code, since it has no purpose in a DSC
    resource ([issue 242](https://github.com/PowerShell/SqlServerDsc/issues/242)).
- Changes to SqlServerReplication
  - Added en-US localization ([issue 620](https://github.com/PowerShell/SqlServerDsc/issues/620)).
  - Refactored Get-TargetResource slightly so it provide better verbose
    messages.

'

      } # End of PSData hashtable

  } # End of PrivateData hashtable
  }






















