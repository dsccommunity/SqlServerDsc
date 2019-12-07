# Minimum steps to convert a module to automatic release

1. Run the following to get a base files that we use to covert the module.
   Change the destination path to something suitable. Make sure to choose
   the full template. The folder that is created will be referenced as
   the base folder.
   ```powershell
   install-Module sampler -Scope CurrentUser
   $sampler = Import-Module -Name Sampler -PassThru
   Invoke-Plaster -TemplatePath (Join-Path $Sampler.ModuleBase 'Templates/Sampler') -Destination C:\Temp\SqlServerDsc
   ```
1. Copy the following files from the base folder to the root of the repository.
   - `build.ps1`
   - `build.yaml`
   - `Resolve-Dependency.ps1`
   - `Resolve-Dependency.psd1`
   - `RequiredModules.psd1`
   - `GitVersion.yml`
   - `azure-pipelines.yml`
   - `Deploy.PSDeploy.ps1`
1. In the file `build.yml` add that the folder `DSCResource` should be
   copied.
   ```yaml
   CopyDirectories:
    - DSCResources
    - en-US
   ```
1. Remove and entry of `DscResource.Tests` and `node_modules` from the
   file `.gitignore`
1. Add `output/*` to the .gitignore file.
1. Create a folder in the root of the repo with the same name as the
   module name, e.g. `SqlServerDsc` (it can also be named `src` or `source`).
   This new folder will from now be referenced to as the source folder.
1. Move the following folders into the source folder.
   - DSCResources
   - Examples
   - Modules
1. Move the module manifest, e.g. `SqlServerDsc.ps1` into the source
   folder.
1. Copy the following file from the base folder `./Sampler/Build.psd1`
   into the source folder. *This file will not be needed once the
   ModuleBuilder module resolves a pending issue.*
1. Copy the following folder from the base folder `.Sampler/en-US`
   into the source folder.
1. Rename the file `about_Sampler.help.txt` to have the correct module name,
   e.g. `about_SqlServerDsc.help.txt`.
1. Update the contents of the newly renamed file to describe the module.
   E.g.
    ```plaintext
    TOPIC
        about_SqlServerDsc

    SHORT DESCRIPTION
        DSC resources for deployment and configuration of SQL Server.

    LONG DESCRIPTION
        This module contains DSC resources for deployment and configuration of SQL Server.

    EXAMPLES
        PS C:\> Get-DscResource -Module SqlServerDsc

    NOTE:
        Thank you to the DSC Community contributors who contributed to this module by
        writing code, sharing opinions, and provided feedback.

    TROUBLESHOOTING NOTE:
        Look in Github repository for read about issues and submit a new issue.
        https://github.com/dsccommunity/SqlServerDsc/issues

    SEE ALSO
    - https://github.com/dsccommunity/SqlServerDsc

    KEYWORDS
        DSC, DscResource, SqlServer
    ```
1. If there are any helper modules then update the section `NestedModule`
   as required in the file `build.yaml`.
   ```yaml
   NestedModule:
    HelperSubmodule:
      Path: ./SqlServerDsc/Modules/SqlServerDsc.Common/SqlServerDsc.Common.psd1
      OutputDirectory: ./output/SqlServerDsc/$ModuleVersionFolder/Modules/SqlServerDsc.Common
      VersionedOutputDirectory: false
   ```
   1. Any helper module is required to have a module manifest.
      Create one using ``New-ModuleManifest`, e.g.
      ```
      New-ModuleManifest -Path .\SqlServerDsc\Modules\SqlServerDsc.Common\SqlServerDsc.Common.psd1`.
      ```
      Change the manifest to look similar to this.
      ```powershell
      @{
          # Version number of this module.
          ModuleVersion = '1.0'

          # ID used to uniquely identify this module
          GUID = 'b8e5084a-07a8-4135-8a26-00614e56ba71'

          # Author of this module
          Author = 'DSC Community'

          # Company or vendor of this module
          CompanyName = 'DSC Community'

          # Copyright statement for this module
          Copyright = 'Copyright the DSC Community contributors. All rights reserved.'

          # Description of the functionality provided by this module
          Description = 'Functions used by the DSC resources in SqlServerDsc.'

          # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
          FunctionsToExport = @()

          # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
          CmdletsToExport = @()

          # Variables to export from this module
          VariablesToExport = @()

          # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
          AliasesToExport = @()

          # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
          PrivateData = @{

              PSData = @{
              } # End of PSData hashtable

          } # End of PrivateData hashtable
      }
      ```
   1. The file `Build.psd1` that was copied into the source folder. Copy the
      same file into the helper modules folder, e.g the file `.\SqlServerDsc\Build.ps1`
      to folder `.\SqlServerDsc\Modules\SqlServerDsc.Common`. *This file
      will not be needed once the ModuleBuilder module resolves a pending
      issue.*
1. From all unit test and integration tests remove the header that was part
   of the previous test framework. Everything between and including
   `#region HEADER` and `#endregion HEADER`. Replace it with the following
   code, add the code inside the function `Invoke-TestSetup`. Also update
   the function `Invoke-TestCleanup`.
   ```powershell
   function Invoke-TestSetup
   {
       Import-Module -Name DscResource.Test -Force

       $script:testEnvironment = Initialize-TestEnvironment `
           -DSCModuleName $script:dscModuleName `
           -DSCResourceName $script:dscResourceName `
           -ResourceType 'Mof' `
           -TestType Unit
   }

   function Invoke-TestCleanup
   {
       Restore-TestEnvironment -TestEnvironment $script:testEnvironment
   }
   ```
1. For any helper modules, add this to each unit test (and remove any
   other code that imported the helper module previously).
   ```powershell
   #region HEADER
   $ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
   $ProjectName = (Get-ChildItem $ProjectPath\*\*.psd1 | Where-Object {
           ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
           $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop }catch{$false}) }
       ).BaseName

   $script:ParentModule = Get-Module $ProjectName -ListAvailable | Select-Object -First 1
   $script:SubModulesFolder = Join-Path -Path $script:ParentModule.ModuleBase -ChildPath 'Modules'
   Remove-Module $script:ParentModule -Force -ErrorAction SilentlyContinue

   $script:SubModuleName = (Split-Path $PSCommandPath -Leaf) -replace '\.Tests.ps1'
   $script:SubmoduleFile = Join-Path $script:SubModulesFolder "$($script:SubModuleName)/$($script:SubModuleName).psm1"

   #endregion HEADER

   Import-Module $script:SubmoduleFile -Force -ErrorAction Stop

   InModuleScope $script:SubModuleName {
       # The unit tests
   }
    ```
1. Create a folder in to root of the repository called `WikiSource`
1. In the `WikiSource` folder create a file named HISTORIC_CHANGELOG.md
   and then move all of the change log history (except the Unreleased section)
   to this new file. *This will be used when publishing the Wiki content.*
   **There is an alternative to this, and that is to add each of the**
   **release notes to the respectively GitHub release.**
   ```markdown
   # Historic change log for SqlServerDsc

   ## 13.2.0.0

   - Changes to SqlServerDsc
   - Fix keywords to lower-case to align with guideline.
   - Fix keywords to have space before a parenthesis to align with guideline.
   - Fix typo in SqlSetup strings ([issue #1419](https://github.com/PowerShell/SqlServerDsc/issues/1419)).
   ```
1. Update the CHANGELOG.md to use the new format by copying the CHANGELOG.md
   from the base folder. *This is below somewhat changed from the CHANGELOG.md*
   *in base folder*
   ```markdown
   # Change log for SqlServerDsc

   The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
   and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

   ## [Unreleased]

   ### Added

   - SqlServerDsc
     - Added automatic release with a new CI pipeline.

   ### Changed

   - SqlServerDsc
     - Add .gitattributes file to checkout file correctly with CRLF.
     - Updated .vscode/analyzersettings.psd1 file to correct use PSSA rules
       and custom rules in VS Code.
     - Fix hashtables to align with style guideline ([issue #1437](https://github.com/PowerShell/SqlServerDsc/issues/1437)).
   - SqlServerMaxDop
     - Fix line endings in code which did not use the correct format.

   ### Deprecated

   - None

   ### Removed

   - None

   ### Fixed

   - None

   ### Security

   - None
   ```
1. You should now be able to run `.\build.ps1 -ResolveDependency -Tasks noop`
   to get all the dependencies.
1. Then you can do `.\build.ps1 -Tasks build` to build the module.
1. And finally you can do `.\build.ps1 -Tasks test` to run all the tests
   in the module. **Note: This will run integration tests too!** Unless
   there is code that prevents them from running, like checking for
   `$env:CI -eq $true`.
1. TODO: Install `choco install GitVersion.Portable`
1. TODO: updating the "next-version" string in the gitversion.yaml
1. TODO: Remove the file `appveyor.yml`.
1. TODO: (Optional) Remove the AppVeyor project for the _forked_ repository
   at https://ci.appveyor.com/projects.
1. TODO: (Optional) Attach Azure DevOps to the fork of repository. *This
   is to be able to run the tests prior to sending in a PR.*
1. DscResource.Common (use the module as NestedMidule)
