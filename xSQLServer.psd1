@{
# Version number of this module.
ModuleVersion = '8.0.0.0'

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
        LicenseUri = 'https://github.com/PowerShell/xSQLServer/blob/master/LICENSE'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/PowerShell/xSQLServer'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        ReleaseNotes = '- BREAKING CHANGE: The module now requires WMF 5.
  - This is required for class-based resources
- Added new resource
  - xSQLServerAlwaysOnAvailabilityGroupDatabaseMembership
  - Added localization support for all strings.
  - Refactored as a MOF based resource due to challenges with Pester and testing
    in Powershell 5.
- Changes to xSQLServer
  - BREAKING CHANGE: xSQLServer does no longer try to support WMF 4.0 (PowerShell
    4.0) (issue 574). Minimum supported version of WMF is now 5.0 (PowerShell 5.0).
  - BREAKING CHANGE: Removed deprecated resource xSQLAOGroupJoin (issue 457).
  - BREAKING CHANGE: Removed deprecated resource xSQLAOGroupEnsure (issue 456).
  - BREAKING CHANGE: Removed deprecated resource xSQLServerFailoverClusterSetup
    (issue 336).
  - Updated PULL\_REQUEST\_TEMPLATE adding comment block around text. Also
    rearranged and updated texts (issue 572).
  - Added common helper functions for HQRM localization, and added tests for the
    helper functions.
    - Get-LocalizedData
    - New-InvalidResultException
    - New-ObjectNotFoundException
    - New-InvalidOperationException
    - New-InvalidArgumentException
  - Updated CONTRIBUTING.md describing the new localization helper functions.
  - Fixed typos in xSQLServer.strings.psd1
  - Fixed CodeCov badge links in README.md so that they point to the correct branch.
  - Added VS Code workspace settings file with formatting settings matching the
    Style Guideline (issue 645). That will make it possible inside VS Code to press
    SHIFT+ALT+F, or press F1 and choose "Format document" in the list. The
    PowerShell code will then be formatted according to the Style Guideline
    (although maybe not complete, but would help a long way).
      - Removed powershell.codeFormatting.alignPropertyValuePairs setting since
        it does not align with the style guideline.
      - Added powershell.codeFormatting.preset with a value of "Custom" so that
        workspace formatting settings are honored (issue 665).
  - Fixed lint error MD013 and MD036 in README.md.
  - Updated .markdownlint.json to enable rule MD013 and MD036 to enforce those
    lint markdown rules in the common tests.
  - Fixed lint error MD013 in CHANGELOG.md.
  - Fixed lint error MD013 in CONTRIBUTING.md.
  - Added code block around types in README.md.
  - Updated copyright information in xSQLServer.psd1.
  - Opt-in for markdown common tests (issue 668).
    - The old markdown tests has been removed.
- Changes to xSQLServerHelper
  - Removed helper function Grant-ServerPerms because the deprecated resource that
    was using it was removed.
  - Removed helper function Grant-CNOPerms because the deprecated resource that
    was using it was removed.
  - Removed helper function New-ListenerADObject because the deprecated resource
    that was using it was removed.
  - Added tests for those helper functions that did not have tests.
  - Test-SQLDscParameterState helper function can now correctly pass a CimInstance
    as DesiredValue.
  - Test-SQLDscParameterState helper function will now output a warning message
    if the value type of a desired value is not supported.
  - Added localization to helper functions (issue 641).
    - Resolved the issue when using Write-Verbose in helper functions discussed
      in 641 where Write-Verbose wouldn"t write out verbose messages unless using
      parameter Verbose.
    - Moved localization strings from xSQLServer.strings.psd1 to
      xSQLServerHelper.strings.psd1.
- Changes to xSQLServerSetup
  - BREAKING CHANGE: Replaced StartWin32Process helper function with the cmdlet
    Start-Process (issue 41, 93 and 126).
  - BREAKING CHANGE: The parameter SetupCredential has been removed since it is
    no longer needed. This is because the resource now support the built-in
    PsDscRunAsCredential.
  - BREAKING CHANGE: Now the resource supports using built-in PsDscRunAsCredential.
    If PsDscRunAsCredential is set, that username will be used as the first system
    administrator.
  - BREAKING CHANGE: If the parameter PsDscRunAsCredential are not assigned any
    credentials then the resource will start the setup process as the SYSTEM account.
    When installing as the SYSTEM account, then parameter SQLSysAdminAccounts and
    ASSysAdminAccounts must be specified when installing feature Database Engine
    and Analysis Services respectively.
  - When setup exits with the exit code 3010 a warning message is written to console
    telling that setup finished successfully, but a reboot is required (partly fixes
    issue 565).
  - When setup exits with an exit code other than 0 or 3010 a warning message is
    written to console telling that setup finished with an error (partly fixes
    issue 580).
  - Added a new parameter SetupProcessTimeout which defaults to 7200 seconds (2
    hours). If the setup process has not finished before the timeout value in
    SetupProcessTimeout an error will be thrown (issue 566).
  - Updated all examples to match the removal of SetupCredential.
  - Updated (removed) severe known issues in README.md for resource xSQLServerSetup.
  - Now all major version uses the same identifier to evaluate InstallSharedDir
    and InstallSharedWOWDir (issue 420).
  - Now setup arguments that contain no value will be ignored, for example when
    InstallSharedDir and
    InstallSharedWOWDir path is already present on the target node, because of a
    previous installation (issue 639).
  - Updated Get-TargetResource to correctly detect BOL, Conn, BC and other tools
    when they are installed without SQLENGINE (issue 591).
  - Now it can detect Documentation Components correctly after the change in
    issue 591 (issue 628)
  - Fixed bug that prevented Get-DscConfiguration from running without error. The
    return hash table fails if the $clusteredSqlIpAddress variable is not used.
    The schema expects a string array but it is initialized as just a null string,
    causing it to fail on Get-DscConfiguration (issue 393).
  - Added localization support for all strings.
  - Added a test to test some error handling for cluster installations.
  - Added support for MDS feature install (issue 486)
    - Fixed localization support for MDS feature (issue 671).
- Changes to xSQLServerRSConfig
  - BREAKING CHANGE: Removed `$SQLAdminCredential` parameter. Use common parameter
    `PsDscRunAsCredential` (WMF 5.0+) to run the resource under different credentials.
    `PsDscRunAsCredential` Windows account must be a sysadmin on SQL Server (issue
    568).
  - In addition, the resource no longer uses `Invoke-Command` cmdlet that was used
    to impersonate the Windows user specified by `$SQLAdminCredential`. The call
    also needed CredSSP authentication to be enabled and configured on the target
    node, which complicated deployments in non-domain scenarios. Using
    `PsDscRunAsCredential` solves this problems for us.
  - Fixed virtual directory creation for SQL Server 2016 (issue 569).
  - Added unit tests (issue 295).
- Changes to xSQLServerDatabase
  - Changed the readme, SQLInstance should have been SQLInstanceName.
- Changes to xSQLServerScript
  - Fixed bug with schema and variable mismatch for the Credential/Username parameter
    in the return statement (issue 661).
  - Optional QueryTimeout parameter to specify sql script query execution timeout.
    Fixes issue 597
- Changes to xSQLServerAlwaysOnService
  - Fixed typos in localization strings and in tests.
- Changes to xSQLServerAlwaysOnAvailabilityGroup
  - Now it utilize the value of "FailoverMode" to set the "FailoverMode" property
    of the Availability Group instead of wrongly using the "AvailabilityMode"
    property of the Availability Group.

'

    } # End of PSData hashtable

} # End of PrivateData hashtable
}








