@{
  # Version number of this module.
  moduleVersion = '12.0.0.0'

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
        ReleaseNotes = '- Changes to SqlServerDatabaseMail
  - DisplayName is now properly treated as display name
    for the originating email address ([issue 1200](https://github.com/PowerShell/SqlServerDsc/issue/1200)).
    [Nick Reilingh (@NReilingh)](https://github.com/NReilingh)
    - DisplayName property now defaults to email address instead of server name.
    - Minor improvements to documentation.
- Changes to SqlAGDatabase
  - Corrected reference to "PsDscRunAsAccount" in documentation
    ([issue 1199](https://github.com/PowerShell/SqlServerDsc/issues/1199)).
    [Nick Reilingh (@NReilingh)](https://github.com/NReilingh)
- Changes to SqlDatabaseOwner
  - BREAKING CHANGE: Support multiple instances on the same node.
    The parameter InstanceName is now Key and cannot be omitted
    ([issue 1197](https://github.com/PowerShell/SqlServerDsc/issues/1197)).
- Changes to SqlSetup
  - Added new parameters to allow to define the startup types for the Sql Engine
    service, the Agent service, the Analysis service and the Integration Service.
    The new optional parameters are respectively SqlSvcStartupType, AgtSvcStartupType,
    AsSvcStartupType, IsSvcStartupType and RsSvcStartupType ([issue 1165](https://github.com/PowerShell/SqlServerDsc/issues/1165).
    [Maxime Daniou (@mdaniou)](https://github.com/mdaniou)

'

      } # End of PSData hashtable

  } # End of PrivateData hashtable
  }

















