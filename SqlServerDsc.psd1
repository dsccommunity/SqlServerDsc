@{
  # Version number of this module.
  moduleVersion = '11.2.0.0'

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
  - Added new test helper functions in the CommonTestHelpers module. These are used
    by the integration tests.
    - **New-IntegrationLoopbackAdapter:** Installs the PowerShell module
      "LoopbackAdapter" from PowerShell Gallery and creates a new network
      loopback adapter.
    - **Remove-IntegrationLoopbackAdapter:** Removes a new network loopback adapter.
    - **Get-NetIPAddressNetwork:** Returns the IP network address from an IPv4 address
      and prefix length.
  - Enabled PSSA rule violations to fail build in the CI environment.
  - Renamed SqlServerDsc.psd1 to be consistent
    ([issue 1116](https://github.com/PowerShell/SqlServerDsc/issues/1116)).
    [Glenn Sarti (@glennsarti)](https://github.com/glennsarti)
- Changes to Unit Tests
  - Updated
    the following resources unit test template to version 1.2.1
    - SqlWaitForAG ([issue 1088](https://github.com/PowerShell/SqlServerDsc/issues/1088)).
      [Michael Fyffe (@TraGicCode)](https://github.com/TraGicCode)
- Changes to SqlAlwaysOnService
  - Updated the integration tests to use a loopback adapter to be less intrusive
    in the build worker environment.
  - Minor code cleanup in integration test, fixed the scope on variable.
- Changes to SqlSetup
  - Updated the integration tests to stop some services after each integration test.
    This is to save memory on the AppVeyor build worker.
  - Updated the integration tests to use a SQL Server 2016 Service Pack 1.
  - Fixed Script Analyzer rule error.
- Changes to SqlRS
  - Updated the integration tests to stop the Reporting Services service after
    the integration test. This is to save memory on the AppVeyor build worker.
  - The helper function `Restart-ReportingServicesService` should no longer timeout
    when restarting the service ([issue 1114](https://github.com/PowerShell/SqlServerDsc/issues/1114)).
- Changes to SqlServiceAccount
  - Updated the integration tests to stop some services after each integration test.
    This is to save memory on the AppVeyor build worker.
- Changes to SqlServerDatabaseMail
  - Fixed Script Analyzer rule error.

'

      } # End of PSData hashtable

  } # End of PrivateData hashtable
  }














