[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Suppressing this rule because Script Analyzer does not understand Pester syntax.')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies have been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies have not been resolved, this will throw an error.
            Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
        }
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks noop" first.'
    }
}

BeforeAll {
    $script:dscModuleName = 'SqlServerDsc'

    $env:SqlServerDscCI = $true

    # Loading mocked classes BEFORE importing the module (required for classes that reference SMO types)
    Add-Type -Path (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '../Stubs') -ChildPath 'SMO.cs')

    Import-Module -Name $script:dscModuleName -Force -ErrorAction 'Stop'

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscModuleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force

    Remove-Item -Path 'env:SqlServerDscCI'
}

Describe 'ConvertTo-SqlDscFileGroup' -Tag 'Public' {
    Context 'When converting a DatabaseFileGroupSpec to SMO FileGroup' {
        BeforeAll {
            # Create mock Database
            $mockDatabase = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
            $mockDatabase | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestDatabase' -Force
        }

        It 'Should convert a basic file group spec with only required properties' {
            InModuleScope -Parameters @{
                mockDatabase = $mockDatabase
            } -ScriptBlock {
                param ($mockDatabase)

                $fileGroupSpec = New-SqlDscFileGroup -Name 'PRIMARY' -AsSpec

                $result = ConvertTo-SqlDscFileGroup -DatabaseObject $mockDatabase -FileGroupSpec $fileGroupSpec

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.FileGroup'
                $result.Name | Should -Be 'PRIMARY'
            }
        }

        It 'Should convert a file group spec with ReadOnly property' {
            InModuleScope -Parameters @{
                mockDatabase = $mockDatabase
            } -ScriptBlock {
                param ($mockDatabase)

                $fileGroupSpec = New-SqlDscFileGroup -Name 'READONLY_FG' -ReadOnly -AsSpec

                $result = ConvertTo-SqlDscFileGroup -DatabaseObject $mockDatabase -FileGroupSpec $fileGroupSpec

                $result.Name | Should -Be 'READONLY_FG'
                $result.ReadOnly | Should -Be $true
            }
        }

        It 'Should convert a file group spec with IsDefault property' {
            InModuleScope -Parameters @{
                mockDatabase = $mockDatabase
            } -ScriptBlock {
                param ($mockDatabase)

                $fileGroupSpec = New-SqlDscFileGroup -Name 'PRIMARY' -IsDefault -AsSpec

                $result = ConvertTo-SqlDscFileGroup -DatabaseObject $mockDatabase -FileGroupSpec $fileGroupSpec

                $result.Name | Should -Be 'PRIMARY'
                $result.IsDefault | Should -Be $true
            }
        }

        It 'Should convert a file group spec with a single data file' {
            InModuleScope -Parameters @{
                mockDatabase = $mockDatabase
            } -ScriptBlock {
                param ($mockDatabase)

                $fileSpec = New-SqlDscDataFile -Name 'TestFile' -FileName 'C:\SQLData\TestFile.mdf' -AsSpec
                $fileGroupSpec = New-SqlDscFileGroup -Name 'PRIMARY' -Files @($fileSpec) -AsSpec

                $result = ConvertTo-SqlDscFileGroup -DatabaseObject $mockDatabase -FileGroupSpec $fileGroupSpec

                $result.Name | Should -Be 'PRIMARY'
                $result.Files.Count | Should -Be 1
                $result.Files[0].Name | Should -Be 'TestFile'
                $result.Files[0].FileName | Should -Be 'C:\SQLData\TestFile.mdf'
            }
        }

        It 'Should convert a file group spec with multiple data files' {
            InModuleScope -Parameters @{
                mockDatabase = $mockDatabase
            } -ScriptBlock {
                param ($mockDatabase)

                $fileSpec1 = New-SqlDscDataFile -Name 'TestFile1' -FileName 'C:\SQLData\TestFile1.ndf' -Size 102400 -AsSpec
                $fileSpec2 = New-SqlDscDataFile -Name 'TestFile2' -FileName 'C:\SQLData\TestFile2.ndf' -Size 204800 -AsSpec
                $fileGroupSpec = New-SqlDscFileGroup -Name 'SECONDARY' -Files @($fileSpec1, $fileSpec2) -AsSpec

                $result = ConvertTo-SqlDscFileGroup -DatabaseObject $mockDatabase -FileGroupSpec $fileGroupSpec

                $result.Name | Should -Be 'SECONDARY'
                $result.Files.Count | Should -Be 2
                $result.Files[0].Name | Should -Be 'TestFile1'
                $result.Files[0].Size | Should -Be 102400
                $result.Files[1].Name | Should -Be 'TestFile2'
                $result.Files[1].Size | Should -Be 204800
            }
        }

        It 'Should convert a file group spec with all properties and multiple files' {
            InModuleScope -Parameters @{
                mockDatabase = $mockDatabase
            } -ScriptBlock {
                param ($mockDatabase)

                $primaryFile = New-SqlDscDataFile -Name 'PrimaryFile' -FileName 'C:\SQLData\Primary.mdf' `
                    -Size 102400 -MaxSize 512000 -Growth 10240 -GrowthType 'KB' -IsPrimaryFile -AsSpec

                $secondaryFile = New-SqlDscDataFile -Name 'SecondaryFile' -FileName 'C:\SQLData\Secondary.ndf' `
                    -Size 204800 -MaxSize 1024000 -Growth 20480 -GrowthType 'KB' -AsSpec

                $fileGroupSpec = New-SqlDscFileGroup -Name 'PRIMARY' -Files @($primaryFile, $secondaryFile) `
                    -IsDefault -AsSpec

                $result = ConvertTo-SqlDscFileGroup -DatabaseObject $mockDatabase -FileGroupSpec $fileGroupSpec

                $result.Name | Should -Be 'PRIMARY'
                $result.IsDefault | Should -Be $true
                $result.Files.Count | Should -Be 2
                $result.Files[0].Name | Should -Be 'PrimaryFile'
                $result.Files[0].IsPrimaryFile | Should -Be $true
                $result.Files[1].Name | Should -Be 'SecondaryFile'
            }
        }

        It 'Should convert a file group spec without files (empty Files array)' {
            InModuleScope -Parameters @{
                mockDatabase = $mockDatabase
            } -ScriptBlock {
                param ($mockDatabase)

                $fileGroupSpec = New-SqlDscFileGroup -Name 'EMPTY_FG' -AsSpec

                $result = ConvertTo-SqlDscFileGroup -DatabaseObject $mockDatabase -FileGroupSpec $fileGroupSpec

                $result.Name | Should -Be 'EMPTY_FG'
                $result.Files.Count | Should -Be 0
            }
        }
    }

    Context 'Parameter validation' {
        BeforeAll {
            $commandInfo = Get-Command -Name 'ConvertTo-SqlDscFileGroup'
        }

        It 'Should have DatabaseObject as a mandatory parameter' {
            $parameterInfo = $commandInfo.Parameters['DatabaseObject']
            $parameterInfo.Attributes.Mandatory | Should -Contain $true
        }

        It 'Should have FileGroupSpec as a mandatory parameter' {
            $parameterInfo = $commandInfo.Parameters['FileGroupSpec']
            $parameterInfo.Attributes.Mandatory | Should -Contain $true
        }

        It 'Should have OutputType set to Microsoft.SqlServer.Management.Smo.FileGroup' {
            $commandInfo.OutputType.Name | Should -Contain 'Microsoft.SqlServer.Management.Smo.FileGroup'
        }
    }
}
