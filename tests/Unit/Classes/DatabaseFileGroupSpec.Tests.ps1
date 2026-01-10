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
    $script:moduleName = 'SqlServerDsc'

    # Do not use -Force. Doing so, or unloading the module in AfterAll, causes
    # PowerShell class types to get new identities, breaking type comparisons.
    Import-Module -Name $script:moduleName -ErrorAction 'Stop'

    $env:SqlServerDscCI = $true

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:moduleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Remove-Item -Path 'env:SqlServerDscCI'
}

Describe 'DatabaseFileGroupSpec' -Tag 'DatabaseFileGroupSpec' {
    Context 'When instantiating the class' {
        It 'Should create an instance with default constructor' {
            $instance = InModuleScope -ScriptBlock {
                [DatabaseFileGroupSpec]::new()
            }

            $instance | Should -Not -BeNullOrEmpty
            $instance.GetType().Name | Should -Be 'DatabaseFileGroupSpec'
        }

        It 'Should create an instance with Name only' {
            $instance = InModuleScope -ScriptBlock {
                [DatabaseFileGroupSpec]::new('PRIMARY')
            }

            $instance | Should -Not -BeNullOrEmpty
            $instance.GetType().Name | Should -Be 'DatabaseFileGroupSpec'
            $instance.Name | Should -Be 'PRIMARY'
        }

        It 'Should create an instance with Name and Files array' {
            $instance = InModuleScope -ScriptBlock {
                $files = @(
                    [DatabaseFileSpec]::new('File1', 'C:\Data\File1.mdf')
                )
                [DatabaseFileGroupSpec]::new('PRIMARY', $files)
            }

            $instance | Should -Not -BeNullOrEmpty
            $instance.GetType().Name | Should -Be 'DatabaseFileGroupSpec'
            $instance.Name | Should -Be 'PRIMARY'
            $instance.Files | Should -HaveCount 1
            $instance.Files[0].Name | Should -Be 'File1'
            $instance.Files[0].FileName | Should -Be 'C:\Data\File1.mdf'
        }
    }

    Context 'When setting properties using the parameterized constructor with Name only' {
        It 'Should set Name property and initialize empty Files array' {
            InModuleScope -ScriptBlock {
                $instance = [DatabaseFileGroupSpec]::new('MyFileGroup')

                $instance.Name | Should -Be 'MyFileGroup'
                $instance.Files | Should -BeNullOrEmpty
            }
        }
    }

    Context 'When setting properties using the parameterized constructor with Name and Files' {
        It 'Should set Name and Files properties' {
            InModuleScope -ScriptBlock {
                $files = @(
                    [DatabaseFileSpec]::new('File1', 'C:\Data\File1.mdf'),
                    [DatabaseFileSpec]::new('File2', 'C:\Data\File2.ndf')
                )
                $instance = [DatabaseFileGroupSpec]::new('SecondaryFG', $files)

                $instance.Name | Should -Be 'SecondaryFG'
                $instance.Files | Should -HaveCount 2
                $instance.Files[0].Name | Should -Be 'File1'
                $instance.Files[1].Name | Should -Be 'File2'
            }
        }
    }

    Context 'When setting properties individually' {
        It 'Should allow setting all properties' {
            InModuleScope -ScriptBlock {
                $instance = [DatabaseFileGroupSpec]::new()
                $instance.Name = 'TestFileGroup'
                $instance.Files = @(
                    [DatabaseFileSpec]@{ Name = 'TestFile'; FileName = 'D:\Data\TestFile.ndf' }
                )
                $instance.ReadOnly = $true
                $instance.IsDefault = $true

                $instance.Name | Should -Be 'TestFileGroup'
                $instance.Files | Should -HaveCount 1
                $instance.Files[0].Name | Should -Be 'TestFile'
                $instance.ReadOnly | Should -BeTrue
                $instance.IsDefault | Should -BeTrue
            }
        }
    }

    Context 'When using default property values' {
        It 'Should have null or false default values' {
            InModuleScope -ScriptBlock {
                $instance = [DatabaseFileGroupSpec]::new()

                $instance.Name | Should -BeNullOrEmpty
                $instance.Files | Should -BeNullOrEmpty
                $instance.ReadOnly | Should -BeFalse
                $instance.IsDefault | Should -BeFalse
            }
        }
    }

    Context 'When using hashtable syntax for instantiation' {
        It 'Should create instance with properties from hashtable' {
            InModuleScope -ScriptBlock {
                $instance = [DatabaseFileGroupSpec]@{
                    Name = 'DataFileGroup'
                    Files = @(
                        [DatabaseFileSpec]@{
                            Name = 'DataFile1'
                            FileName = 'E:\Data\DataFile1.ndf'
                            Size = 100.0
                            Growth = 10.0
                            GrowthType = 'MB'
                        }
                    )
                    ReadOnly = $false
                    IsDefault = $false
                }

                $instance.Name | Should -Be 'DataFileGroup'
                $instance.Files | Should -HaveCount 1
                $instance.Files[0].Name | Should -Be 'DataFile1'
                $instance.Files[0].FileName | Should -Be 'E:\Data\DataFile1.ndf'
                $instance.ReadOnly | Should -BeFalse
                $instance.IsDefault | Should -BeFalse
            }
        }
    }

    Context 'When creating PRIMARY file group' {
        It 'Should set IsDefault to true for PRIMARY file group' {
            InModuleScope -ScriptBlock {
                $instance = [DatabaseFileGroupSpec]@{
                    Name = 'PRIMARY'
                    Files = @(
                        [DatabaseFileSpec]@{
                            Name = 'MyDB'
                            FileName = 'C:\Data\MyDB.mdf'
                            IsPrimaryFile = $true
                        }
                    )
                    IsDefault = $true
                }

                $instance.Name | Should -Be 'PRIMARY'
                $instance.Files[0].IsPrimaryFile | Should -BeTrue
                $instance.IsDefault | Should -BeTrue
            }
        }
    }

    Context 'When creating read-only file group' {
        It 'Should set ReadOnly property' {
            InModuleScope -ScriptBlock {
                $instance = [DatabaseFileGroupSpec]@{
                    Name = 'ReadOnlyFG'
                    ReadOnly = $true
                }

                $instance.Name | Should -Be 'ReadOnlyFG'
                $instance.ReadOnly | Should -BeTrue
            }
        }
    }

    Context 'When adding multiple files to a file group' {
        It 'Should accept array of DatabaseFileSpec objects' {
            InModuleScope -ScriptBlock {
                $files = @(
                    [DatabaseFileSpec]@{ Name = 'File1'; FileName = 'C:\Data\File1.ndf'; Size = 50.0 }
                    [DatabaseFileSpec]@{ Name = 'File2'; FileName = 'C:\Data\File2.ndf'; Size = 100.0 }
                    [DatabaseFileSpec]@{ Name = 'File3'; FileName = 'D:\Data\File3.ndf'; Size = 150.0 }
                )

                $instance = [DatabaseFileGroupSpec]@{
                    Name = 'MultiFileFG'
                    Files = $files
                }

                $instance.Files | Should -HaveCount 3
                $instance.Files[0].Name | Should -Be 'File1'
                $instance.Files[1].Name | Should -Be 'File2'
                $instance.Files[2].Name | Should -Be 'File3'
                $instance.Files[0].Size | Should -Be 50.0
                $instance.Files[1].Size | Should -Be 100.0
                $instance.Files[2].Size | Should -Be 150.0
            }
        }
    }

    Context 'When creating a file group without files' {
        It 'Should allow empty Files array' {
            InModuleScope -ScriptBlock {
                $instance = [DatabaseFileGroupSpec]@{
                    Name = 'EmptyFG'
                }

                $instance.Name | Should -Be 'EmptyFG'
                $instance.Files | Should -BeNullOrEmpty
            }
        }
    }

    Context 'When Files property contains DatabaseFileSpec with all properties set' {
        It 'Should preserve all DatabaseFileSpec properties' {
            InModuleScope -ScriptBlock {
                $instance = [DatabaseFileGroupSpec]@{
                    Name = 'DetailedFG'
                    Files = @(
                        [DatabaseFileSpec]@{
                            Name = 'DetailedFile'
                            FileName = 'F:\Data\DetailedFile.ndf'
                            Size = 200.0
                            MaxSize = 2000.0
                            Growth = 20.0
                            GrowthType = 'Percent'
                            IsPrimaryFile = $false
                        }
                    )
                }

                $file = $instance.Files[0]
                $file.Name | Should -Be 'DetailedFile'
                $file.FileName | Should -Be 'F:\Data\DetailedFile.ndf'
                $file.Size | Should -Be 200.0
                $file.MaxSize | Should -Be 2000.0
                $file.Growth | Should -Be 20.0
                $file.GrowthType | Should -Be 'Percent'
                $file.IsPrimaryFile | Should -BeFalse
            }
        }
    }
}
