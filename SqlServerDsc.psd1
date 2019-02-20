@{
  # Version number of this module.
  moduleVersion = '12.3.0.0'

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
  - Reverting the change that was made as part of the
    [issue 1260](https://github.com/PowerShell/SqlServerDsc/issues/1260)
    in the previous release, as it only mitigated the issue, it did not
    solve the issue.
  - Removed the container testing since that broke the integration tests,
    possible due to using excessive amount of memory on the AppVeyor build
    worker. This will make the unit tests to take a bit longer to run
    ([issue 1260](https://github.com/PowerShell/SqlServerDsc/issues/1260)).
  - The unit tests and the integration tests are now run in two separate
    build workers in AppVeyor. One build worker runs the integration tests,
    while a second build worker runs the unit tests. The build workers runs
    in parallel on paid accounts, but sequentially on free accounts
    ([issue 1260](https://github.com/PowerShell/SqlServerDsc/issues/1260)).
  - Clean up error handling in some of the integration tests that was
    part of a workaround for a bug in Pester. The bug is resolved, and
    the error handling is not again built into Pester.
  - Speeding up the AppVeyor tests by splitting the common tests in a
    separate build job.
  - Updated the appveyor.yml to have the correct build step, and also
    correct run the build step only in one of the jobs.
  - Update integration tests to use the new integration test template.
  - Added SqlAgentOperator resource.
- Changes to SqlServiceAccount
  - Fixed Get-ServiceObject when searching for Integration Services service.
    Unlike the rest of SQL Server services, the Integration Services service
    cannot be instanced, however you can have multiple versions installed.
    Get-Service object would return the correct service name that you
    are looking for, but it appends the version number at the end. Added
    parameter VersionNumber so the search would return the correct
    service name.
  - Added code to allow for using Managed Service Accounts.
  - Now the correct service type string value is returned by the function
    `Get-TargetResource`. Previously one value was passed in as a parameter
    (e.g. `DatabaseEngine`), but a different string value as returned
    (e.g. `SqlServer`). Now `Get-TargetResource` return the same values
    that can be passed as values in the parameter `ServiceType`
    ([issue 981](https://github.com/PowerShell/SqlServerDsc/issues/981)).
- Changes to SqlServerLogin
  - Fixed issue in Test-TargetResource to valid password on disabled accounts
    ([issue 915](https://github.com/PowerShell/SqlServerDsc/issues/915)).
  - Now when adding a login of type SqlLogin, and the SQL Server login mode
    is set to `"Integrated"`, an error is correctly thrown
    ([issue 1179](https://github.com/PowerShell/SqlServerDsc/issues/1179)).
- Changes to SqlSetup
  - Updated the integration test to stop the named instance while installing
    the other instances to mitigate
    [issue 1260](https://github.com/PowerShell/SqlServerDsc/issues/1260).
  - Add parameters to configure the Tempdb files during the installation of
    the instance. The new parameters are SqlTempdbFileCount, SqlTempdbFileSize,
    SqlTempdbFileGrowth, SqlTempdbLogFileSize and SqlTempdbLogFileGrowth
    ([issue 1167](https://github.com/PowerShell/SqlServerDsc/issues/1167)).
- Changes to SqlServerEndpoint
  - Add the optional parameter Owner. The default owner remains the login used
    for the creation of the endpoint
    ([issue 1251](https://github.com/PowerShell/SqlServerDsc/issues/1251)).
    [Maxime Daniou (@mdaniou)](https://github.com/mdaniou)
  - Add integration tests
    ([issue 744](https://github.com/PowerShell/SqlServerDsc/issues/744)).
    [Maxime Daniou (@mdaniou)](https://github.com/mdaniou)

'

      } # End of PSData hashtable

  } # End of PrivateData hashtable
  }




















