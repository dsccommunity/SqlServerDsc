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

    $script:moduleUnderTest = Import-Module -Name $script:dscModuleName -PassThru -Force -ErrorAction 'Stop'

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscModuleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force
}

Describe 'DatabaseFileSpec' -Tag 'DatabaseFileSpec' {
    Context 'When instantiating the class' {
        It 'Should not throw when instantiated with default constructor' {
            InModuleScope -ScriptBlock {
                { [DatabaseFileSpec]::new() } | Should -Not -Throw
            }
        }

        It 'Should not throw when instantiated with Name and FileName' {
            InModuleScope -ScriptBlock {
                { [DatabaseFileSpec]::new('TestFile', 'C:\Data\TestFile.mdf') } | Should -Not -Throw
            }
        }
    }

    Context 'When setting properties using the parameterized constructor' {
        It 'Should set Name and FileName properties' {
            InModuleScope -ScriptBlock {
                $instance = [DatabaseFileSpec]::new('MyFile', 'D:\SQLData\MyFile.mdf')

                $instance.Name | Should -Be 'MyFile'
                $instance.FileName | Should -Be 'D:\SQLData\MyFile.mdf'
            }
        }
    }

    Context 'When setting properties individually' {
        It 'Should allow setting all properties' {
            InModuleScope -ScriptBlock {
                $instance = [DatabaseFileSpec]::new()
                $instance.Name = 'DataFile1'
                $instance.FileName = 'C:\Data\DataFile1.ndf'
                $instance.Size = 100.0
                $instance.MaxSize = 1000.0
                $instance.Growth = 10.0
                $instance.GrowthType = 'MB'
                $instance.IsPrimaryFile = $true

                $instance.Name | Should -Be 'DataFile1'
                $instance.FileName | Should -Be 'C:\Data\DataFile1.ndf'
                $instance.Size | Should -Be 100.0
                $instance.MaxSize | Should -Be 1000.0
                $instance.Growth | Should -Be 10.0
                $instance.GrowthType | Should -Be 'MB'
                $instance.IsPrimaryFile | Should -BeTrue
            }
        }
    }

    Context 'When using default property values' {
        It 'Should have null or false default values' {
            InModuleScope -ScriptBlock {
                $instance = [DatabaseFileSpec]::new()

                $instance.Name | Should -BeNullOrEmpty
                $instance.FileName | Should -BeNullOrEmpty
                $instance.Size | Should -BeNullOrEmpty
                $instance.MaxSize | Should -BeNullOrEmpty
                $instance.Growth | Should -BeNullOrEmpty
                $instance.GrowthType | Should -BeNullOrEmpty
                $instance.IsPrimaryFile | Should -BeFalse
            }
        }
    }

    Context 'When using hashtable syntax for instantiation' {
        It 'Should create instance with properties from hashtable' {
            InModuleScope -ScriptBlock {
                $instance = [DatabaseFileSpec]@{
                    Name = 'SecondaryFile'
                    FileName = 'E:\Data\SecondaryFile.ndf'
                    Size = 50.0
                    MaxSize = 500.0
                    Growth = 5.0
                    GrowthType = 'Percent'
                }

                $instance.Name | Should -Be 'SecondaryFile'
                $instance.FileName | Should -Be 'E:\Data\SecondaryFile.ndf'
                $instance.Size | Should -Be 50.0
                $instance.MaxSize | Should -Be 500.0
                $instance.Growth | Should -Be 5.0
                $instance.GrowthType | Should -Be 'Percent'
                $instance.IsPrimaryFile | Should -BeFalse
            }
        }
    }

    Context 'When specifying a primary file' {
        It 'Should set IsPrimaryFile to true' {
            InModuleScope -ScriptBlock {
                $instance = [DatabaseFileSpec]@{
                    Name = 'PrimaryFile'
                    FileName = 'C:\Data\MyDB.mdf'
                    IsPrimaryFile = $true
                }

                $instance.Name | Should -Be 'PrimaryFile'
                $instance.FileName | Should -Be 'C:\Data\MyDB.mdf'
                $instance.IsPrimaryFile | Should -BeTrue
            }
        }
    }

    Context 'When using different growth types' {
        It 'Should accept MB as growth type' {
            InModuleScope -ScriptBlock {
                $instance = [DatabaseFileSpec]::new()
                $instance.GrowthType = 'MB'

                $instance.GrowthType | Should -Be 'MB'
            }
        }

        It 'Should accept Percent as growth type' {
            InModuleScope -ScriptBlock {
                $instance = [DatabaseFileSpec]::new()
                $instance.GrowthType = 'Percent'

                $instance.GrowthType | Should -Be 'Percent'
            }
        }

        It 'Should accept KB as growth type' {
            InModuleScope -ScriptBlock {
                $instance = [DatabaseFileSpec]::new()
                $instance.GrowthType = 'KB'

                $instance.GrowthType | Should -Be 'KB'
            }
        }
    }
}
