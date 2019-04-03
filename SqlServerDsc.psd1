@{
  # Version number of this module.
  moduleVersion = '12.4.0.0'

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
  - Added new resources.
    - SqlRSSetup
  - Added helper module DscResource.Common from the repository
    DscResource.Template.
    - Moved all helper functions from SqlServerDscHelper.psm1 to DscResource.Common.
    - Renamed Test-SqlDscParameterState to Test-DscParameterState.
    - New-TerminatingError error text for a missing localized message now matches
      the output even if the "missing localized message" localized message is
      also missing.
  - Added helper module DscResource.LocalizationHelper from the repository
    DscResource.Template, this replaces the helper module CommonResourceHelper.psm1.
  - Cleaned up unit tests, mostly around loading cmdlet stubs and loading
    classes stubs, but also some tests that were using some odd variants.
  - Fix all integration tests according to issue [PowerShell/DscResource.Template14](https://github.com/PowerShell/DscResource.Template/issues/14).
- Changes to SqlServerMemory
  - Updated Cim Class to Win32_ComputerSystem (instead of Win32_PhysicalMemory)
    because the correct memory size was not being detected correctly on Azure VMs
    ([issue 914](https://github.com/PowerShell/SqlServerDsc/issues/914)).
- Changes to SqlSetup
  - Split integration tests into two jobs, one for running integration tests
    for SQL Server 2016 and another for running integration test for
    SQL Server 2017 ([issue 858](https://github.com/PowerShell/SqlServerDsc/issues/858)).
  - Localized messages for Master Data Services no longer start and end with
    single quote.
  - When installing features a verbose message is written if a feature is found
    to already be installed. It no longer quietly removes the feature from the
    `/FEATURES` argument.
  - Cleaned up a bit in the tests, removed excessive piping.
  - Fixed minor typo in examples.
  - A new optional parameter `FeatureFlag` parameter was added to control
    breaking changes. Functionality added under a feature flag can be
    toggled on or off, and could be changed later to be the default.
    This way we can also make more of the new functionalities the default
    in the same breaking change release ([issue 1105](https://github.com/PowerShell/SqlServerDsc/issues/1105)).
  - Added a new way of detecting if the shared feature CONN (Client Tools
    Connectivity, and SQL Client Connectivity SDK), BC (Client Tools
    Backwards Compatibility), and SDK (Client Tools SDK) is installed or
    not. The new functionality is used when the parameter `FeatureFlag`
    is set to `"DetectionSharedFeatures"` ([issue 1105](https://github.com/PowerShell/SqlServerDsc/issues/1105)).
  - Added a new helper function `Get-InstalledSharedFeatures` to move out
    some of the code from the `Get-TargetResource` to make unit testing
    easier and faster.
  - Changed the logic of "Build the argument string to be passed to setup" to
    not quote the value if root directory is specified
    ([issue 1254](https://github.com/PowerShell/SqlServerDsc/issues/1254)).
  - Moved some resource specific helper functions to the new helper module
    DscResource.Common so they can be shared with the new resource SqlRSSetup.
  - Improved verbose messages in Test-TargetResource function to more
    clearly tell if features are already installed or not.
  - Refactored unit tests for the functions Test-TargetResource and
    Set-TargetResource to improve testing speed.
  - Modified the Test-TargetResource and Set-TargetResource to not be
    case-sensitive when comparing feature names. *This was handled
    correctly in real-world scenarios, but failed when running the unit
    tests (and testing casing).*
- Changes to SqlAGDatabase
  - Fix MatchDatabaseOwner to check for CONTROL SERVER, IMPERSONATE LOGIN, or
    CONTROL LOGIN permission in addition to IMPERSONATE ANY LOGIN.
  - Update and fix MatchDatabaseOwner help text.
- Changes to SqlAG
  - Updated documentation on the behaviour of defaults as they only apply when
    creating a group.
- Changes to SqlAGReplica
  - AvailabilityMode, BackupPriority, and FailoverMode defaults only apply when
    creating a replica not when making changes to an existing replica. Explicit
    parameters will still change existing replicas ([issue 1244](https://github.com/PowerShell/SqlServerDsc/issues/1244)).
  - ReadOnlyRoutingList now gets updated without throwing an error on the first
    run ([issue 518](https://github.com/PowerShell/SqlServerDsc/issues/518)).
  - Test-Resource fixed to report whether ReadOnlyRoutingList desired state
    has been reached correctly ([issue 1305](https://github.com/PowerShell/SqlServerDsc/issues/1305)).
- Changes to SqlDatabaseDefaultLocation
  - No longer does the Test-TargetResource fail on the second test run
    when the backup file path was changed, and the path was ending with
    a backslash ([issue 1307](https://github.com/PowerShell/SqlServerDsc/issues/1307)).

'

      } # End of PSData hashtable

  } # End of PrivateData hashtable
  }





















