@{
  # Version number of this module.
  ModuleVersion = '11.0.0.0'

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
  - BREAKING CHANGE: Resource SqlRSSecureConnectionLevel was remove
    ([issue 990](https://github.com/PowerShell/SqlServerDsc/issues/990)).
    The parameter that was set using that resource has been merged into resource
    SqlRS as the parameter UseSsl. The UseSsl parameter is of type boolean. This
    change was made because from SQL Server 2008 R2 this value is made an on/off
    switch. Read more in the article [ConfigurationSetting Method - SetSecureConnectionLevel](https://docs.microsoft.com/en-us/sql/reporting-services/wmi-provider-library-reference/configurationsetting-method-setsecureconnectionlevel).
  - Updated so that named parameters are used for New-Object cmdlet. This was
    done to follow the style guideline.
  - Updated manifest and license to reflect the new year
    ([issue 965](https://github.com/PowerShell/SqlServerDsc/issues/965)).
  - Added a README.md under Tests\Integration to help contributors to write
    integration tests.
  - Added "Integration tests" section in the CONTRIBUTING.md.
  - The complete examples were removed. They were no longer accurate and some
    referenced resources that no longer exist. Accurate examples can be found
    in each specific resource example folder. Examples for installing Failover Cluster
    can be found in the resource examples folders in the xFailOverCluster
    resource module ([issue 462](https://github.com/PowerShell/SqlServerDsc/issues/462)).
  - A README.md was created under the Examples folder to be used as reference how
    to install certain scenarios ([issue 462](https://github.com/PowerShell/SqlServerDsc/issues/462)).
  - Removed the local specific common test for compiling examples in this repository
    and instead opted-in for the common test in the "DscResource.Tests" repository
    ([issue 669](https://github.com/PowerShell/SqlServerDsc/issues/669)).
  - Added new resource SqlServerDatabaseMail for configuring SQL Server
    Database Mail ([issue 155](https://github.com/PowerShell/SqlServerDsc/issues/155)).
  - Updated the helper function Test-SQLDscParameterState to handle the
    data type UInt16.
  - Fixed typo in SqlServerDscCommon.Tests.
  - Updated README.md with known issue section for each resource.
  - Resources that did not have a description in the README.md now has one.
  - Resources that missed links to the examples in the README.md now has those
    links.
  - Style changes in all examples, removing type [System.Management.Automation.Credential()]
    from credential parameters ([issue 1003](https://github.com/PowerShell/SqlServerDsc/issues/1003)),
    and renamed the credential parameter so it is not using abbreviation.
  - Updated the security token for AppVeyor status badge in README.md. When we
    renamed the repository the security token was changed
    ([issue 1012](https://github.com/PowerShell/SqlServerDsc/issues/1012)).
  - Now the helper function Restart-SqlService, after restarting the SQL Server
    service, does not return until it can connect to the SQL Server instance, and
    the instance returns status "Online" ([issue 1008](https://github.com/PowerShell/SqlServerDsc/issues/1008)).
    If it fails to connect within the timeout period (defaults to 120 seconds) it
    throws an error.
  - Fixed typo in comment-base help for helper function Test-AvailabilityReplicaSeedingModeAutomatic.
  - Style cleanup in helper functions and tests.
- Changes to SqlAG
  - Fixed typos in tests.
  - Style cleanup in code and tests.
- Changes to SqlAGDatabase
  - Style cleanup in code and tests.
- Changes to SqlAGListener
  - Fixed typo in comment-based help.
  - Style cleanup in code and tests.
- Changes to SqlAGReplica
  - Minor code style cleanup. Removed unused variable and instead piped the cmdlet
    Join-SqlAvailabilityGroup to Out-Null.
  - Fixed minor typos in comment-based help.
  - Fixed minor typos in comment.
  - Style cleanup in code and tests.
  - Updated description for parameter Name in README.md and in comment-based help
    ([issue 1034](https://github.com/PowerShell/SqlServerDsc/issues/1034)).
- Changes to SqlAlias
  - Fixed issue where exception was thrown if reg keys did not exist
    ([issue 949](https://github.com/PowerShell/SqlServerDsc/issues/949)).
  - Style cleanup in tests.
- Changes to SqlAlwaysOnService
  - Refactor integration tests slightly to improve run time performance
    ([issue 1001](https://github.com/PowerShell/SqlServerDsc/issues/1001)).
  - Style cleanup in code and tests.
- Changes to SqlDatabase
  - Fix minor Script Analyzer warning.
- Changes to SqlDatabaseDefaultLocation
  - Refactor integration tests slightly to improve run time performance
    ([issue 1001](https://github.com/PowerShell/SqlServerDsc/issues/1001)).
  - Minor style cleanup of code in tests.
- Changes to SqlDatabaseRole
  - Style cleanup in tests.
- Changes to SqlRS
  - Replaced Get-WmiObject with Get-CimInstance to fix Script Analyzer warnings
    ([issue 264](https://github.com/PowerShell/SqlServerDsc/issues/264)).
  - Refactored the resource to use Invoke-CimMethod.
  - Added parameter UseSsl which when set to $true forces connections to the
    Reporting Services to use SSL when connecting ([issue 990](https://github.com/PowerShell/SqlServerDsc/issues/990)).
  - Added complete example for SqlRS (based on the integration tests)
    ([issue 634](https://github.com/PowerShell/SqlServerDsc/issues/634)).
  - Refactor integration tests slightly to improve run time performance
    ([issue 1001](https://github.com/PowerShell/SqlServerDsc/issues/1001)).
  - Style cleanup in code and tests.
- Changes to SqlScript
  - Style cleanup in tests.
  - Updated examples.
  - Added integration tests.
  - Fixed minor typos in comment-based help.
  - Added new example based on integration test.
- Changes to SqlServerConfiguration
  - Fixed minor typos in comment-based help.
  - Now the verbose message say what option is changing and to what value
    ([issue 1014](https://github.com/PowerShell/SqlServerDsc/issues/1014)).
  - Changed the RestartTimeout parameter from type SInt32 to type UInt32.
  - Added localization ([issue 605](https://github.com/PowerShell/SqlServerDsc/issues/605)).
  - Style cleanup in code and tests.
- Changes to SqlServerEndpoint
  - Updated README.md with links to the examples
    ([issue 504](https://github.com/PowerShell/SqlServerDsc/issues/504)).
  - Style cleanup in tests.
- Changes to SqlServerLogin
  - Added integration tests ([issue 748](https://github.com/PowerShell/SqlServerDsc/issues/748)).
  - Minor code style cleanup.
  - Removed unused variable and instead piped the helper function Connect-SQL to
    Out-Null.
  - Style cleanup in tests.
- Changes to SqlServerMaxDop
  - Minor style changes in the helper function Get-SqlDscDynamicMaxDop.
- Changes to SqlServerMemory
  - Style cleanup in code and tests.
- Changes to SqlServerPermission
  - Fixed minor typos in comment-based help.
  - Style cleanup in code.
- Changes to SqlServerReplication
  - Fixed minor typos in verbose messages.
  - Style cleanup in tests.
- Changes to SqlServerNetwork
  - Added sysadmin account parameter usage to the examples.
- Changes to SqlServerReplication
  - Fix Script Analyzer warning ([issue 263](https://github.com/PowerShell/SqlServerDsc/issues/263)).
- Changes to SqlServerRole
  - Added localization ([issue 621](https://github.com/PowerShell/SqlServerDsc/issues/621)).
  - Added integration tests ([issue 756](https://github.com/PowerShell/SqlServerDsc/issues/756)).
  - Updated example to add two server roles in the same configuration.
  - Style cleanup in tests.
- Changes to SqlServiceAccount
  - Default services are now properly detected
    ([issue 930](https://github.com/PowerShell/SqlServerDsc/issues/930)).
  - Made the description of parameter RestartService more descriptive
    ([issue 960](https://github.com/PowerShell/SqlServerDsc/issues/960)).
  - Added a read-only parameter ServiceAccountName so that the service account
    name is correctly returned as a string ([issue 982](https://github.com/PowerShell/SqlServerDsc/issues/982)).
  - Added integration tests ([issue 980](https://github.com/PowerShell/SqlServerDsc/issues/980)).
  - The timing issue that the resource returned before SQL Server service was
    actually restarted has been solved by a change in the helper function
    Restart-SqlService ([issue 1008](https://github.com/PowerShell/SqlServerDsc/issues/1008)).
    Now Restart-SqlService waits for the instance to return status "Online" or
    throws an error saying it failed to connect within the timeout period.
  - Style cleanup in code and tests.
- Changes to SqlSetup
  - Added parameter `ASServerMode` to support installing Analysis Services in
    Multidimensional mode, Tabular mode and PowerPivot mode
    ([issue 388](https://github.com/PowerShell/SqlServerDsc/issues/388)).
  - Added integration tests for testing Analysis Services Multidimensional mode
    and Tabular mode.
  - Cleaned up integration tests.
  - Added integration tests for installing a default instance of Database Engine.
  - Refactor integration tests slightly to improve run time performance
    ([issue 1001](https://github.com/PowerShell/SqlServerDsc/issues/1001)).
  - Added PSSA rule "PSUseDeclaredVarsMoreThanAssignments" override in the
    function Set-TargetResource for the variable $global:DSCMachineStatus.
  - Style cleanup in code and tests.
- Changes to SqlWaitForAG
  - Style cleanup in code.
- Changes to SqlWindowsFirewall
  - Fixed minor typos in comment-based help.
  - Style cleanup in code.

'

      } # End of PSData hashtable

  } # End of PrivateData hashtable
  }












