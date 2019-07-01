@{
  # Version number of this module.
  moduleVersion = '13.0.0.0'

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
  - Added SqlAgentAlert resource.
  - Opt-in to the common test "Common Test - Validation Localization".
  - Opt-in to the common test "Common Test - Flagged Script Analyzer Rules"
    ([issue 1101](https://github.com/PowerShell/SqlServerDsc/issues/1101)).
  - Removed the helper function `New-TerminatingError`, `New-WarningMessage`
    and `New-VerboseMessage` in favor of the the new
    [localization helper functions](https://github.com/PowerShell/DscResources/blob/master/StyleGuidelines.mdlocalization).
  - Combine DscResource.LocalizationHelper and DscResource.Common into
    SqlServerDsc.Common ([issue 1357](https://github.com/PowerShell/SqlServerDsc/issues/1357)).
  - Update Assert-TestEnvironment.ps1 to not error if strict mode is enabled
    and there are no missing dependencies ([issue 1368](https://github.com/PowerShell/SqlServerDsc/issues/1368)).
- Changes to SqlServerDsc.Common
  - Added StatementTimeout to function "Connect-SQL" with default 600 seconds (10mins).
  - Added StatementTimeout to function "Invoke-Query" with default 600 seconds (10mins)
    ([issue 1358](https://github.com/PowerShell/SqlServerDsc/issues/1358)).
  - Changes to helper function Connect-SQL
    - The function now make it more clear that when using the parameter
      `SetupCredential` is impersonates that user, and by default it does
      not impersonates a user but uses the credential that the resource
      is run as (for example the built-in credential parameter
      `PsDscRunAsCredential`). [@kungfu71186](https://github.com/kungfu71186)
    - Added parameter alias `-DatabaseCredential` for the parameter
      `-SetupCredential`. [@kungfu71186](https://github.com/kungfu71186)
- Changes to SqlAG
  - Added en-US localization.
- Changes to SqlAGReplica
  - Added en-US localization.
  - Improved verbose message output when creating availability group replica,
    removing a availability group replica, and joining the availability
    group replica to the availability group.
- Changes to SqlAlwaysOnService
  - Now outputs the correct verbose message when restarting the service.
- Changes to SqlServerMemory
  - Now outputs the correct verbose messages when calculating the dynamic
    memory, and when limiting maximum memory.
- Changes to SqlServerRole
  - Now outputs the correct verbose message when the members of a role is
    not in desired state.
- Changes to SqlAgentOperator
  - Fix minor issue that when unable to connect to an instance. Instead
    of showing a message saying that connect failed another unrelated
    error message could have been shown, because of an error in the code.
  - Fix typo in test it block.
- Changes to SqlDatabaseRole
  - BREAKING CHANGE: Refactored to enable creation/deletion of the database role
    itself as well as management of the role members. *Note that the resource no
    longer adds database users.* ([issue 845](https://github.com/PowerShell/SqlServerDsc/issues/845),
    [issue 847](https://github.com/PowerShell/SqlServerDsc/issues/847),
    [issue 1252](https://github.com/PowerShell/SqlServerDsc/issues/1252),
    [issue 1339](https://github.com/PowerShell/SqlServerDsc/issues/1339)).
    [Paul Shamus @pshamus](https://github.com/pshamus)
- Changes to SqlSetup
  - Add an Action type of "Upgrade". This will ask setup to do a version
    upgrade where possible ([issue 1368](https://github.com/PowerShell/SqlServerDsc/issues/1368)).
  - Fix an error when testing for DQS installation ([issue 1368](https://github.com/PowerShell/SqlServerDsc/issues/1368)).
  - Changed the logic of how default value of FailoverClusterGroupName is
    set since that was preventing the resource to be able to be debugged
    ([issue 448](https://github.com/PowerShell/SqlServerDsc/issues/448)).
  - Added RSInstallMode parameter ([issue 1163](https://github.com/PowerShell/SqlServerDsc/issues/1163)).
- Changes to SqlWindowsFirewall
  - Where a version upgrade has changed paths for a database engine, the
    existing firewall rule for that instance will be updated rather than
    another one created ([issue 1368](https://github.com/PowerShell/SqlServerDsc/issues/1368)).
    Other firewall rules can be fixed to work in the same way later.
- Changes to SqlAGDatabase
  - Added new parameter "ReplaceExisting" with default false.
    This allows forced restores when a database already exists on secondary.
  - Added StatementTimeout to Invoke-Query to fix Issue1358
  - Fix issue where calling Get would return an error because the database
    name list may have been returned as a string instead of as a string array
    ([issue 1368](https://github.com/PowerShell/SqlServerDsc/issues/1368)).

'

      } # End of PSData hashtable

  } # End of PrivateData hashtable
  }























