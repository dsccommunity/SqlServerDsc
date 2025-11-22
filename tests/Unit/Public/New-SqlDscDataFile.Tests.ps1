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

    Import-Module -Name $script:dscModuleName -Force -ErrorAction 'Stop'

    # Loading mocked classes
    Add-Type -Path (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '../Stubs') -ChildPath 'SMO.cs')

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

Describe 'New-SqlDscDataFile' -Tag 'Public' {
    Context 'When creating a new DataFile' {
        BeforeAll {
            $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
            $mockDatabaseObject.Name = 'TestDatabase'

            $mockFileGroupObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.FileGroup' -ArgumentList $mockDatabaseObject, 'PRIMARY'
        }

        It 'Should create a DataFile and add it to the FileGroup' {
            InModuleScope -Parameters @{
                mockFileGroupObject = $mockFileGroupObject
            } -ScriptBlock {
                param ($mockFileGroupObject)

                $initialFileCount = $mockFileGroupObject.Files.Count

                New-SqlDscDataFile -FileGroup $mockFileGroupObject -Name 'MyDataFile' -FileName 'C:\Data\MyDataFile.mdf' -Confirm:$false

                $mockFileGroupObject.Files.Count | Should -Be ($initialFileCount + 1)
                $addedFile = $mockFileGroupObject.Files | Where-Object -FilterScript { $_.Name -eq 'MyDataFile' }
                $addedFile | Should -Not -BeNullOrEmpty
                $addedFile.FileName | Should -Be 'C:\Data\MyDataFile.mdf'
            }
        }

        It 'Should return the created DataFile when PassThru is specified' {
            InModuleScope -Parameters @{
                mockFileGroupObject = $mockFileGroupObject
            } -ScriptBlock {
                param ($mockFileGroupObject)

                $result = New-SqlDscDataFile -FileGroup $mockFileGroupObject -Name 'PassThruDataFile' -FileName 'C:\Data\PassThruDataFile.mdf' -PassThru -Confirm:$false

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.DataFile'
                $result.Name | Should -Be 'PassThruDataFile'
                $result.FileName | Should -Be 'C:\Data\PassThruDataFile.mdf'
                $result.Parent | Should -Be $mockFileGroupObject
            }
        }

        It 'Should not return anything when PassThru is not specified' {
            InModuleScope -Parameters @{
                mockFileGroupObject = $mockFileGroupObject
            } -ScriptBlock {
                param ($mockFileGroupObject)

                $result = New-SqlDscDataFile -FileGroup $mockFileGroupObject -Name 'NoPassThruDataFile' -FileName 'C:\Data\NoPassThruDataFile.mdf' -Confirm:$false

                $result | Should -BeNullOrEmpty
            }
        }

        It 'Should create a sparse file for database snapshot' {
            InModuleScope -Parameters @{
                mockFileGroupObject = $mockFileGroupObject
            } -ScriptBlock {
                param ($mockFileGroupObject)

                $initialFileCount = $mockFileGroupObject.Files.Count

                $result = New-SqlDscDataFile -FileGroup $mockFileGroupObject -Name 'MySnapshot_Data' -FileName 'C:\Snapshots\MySnapshot_Data.ss' -PassThru -Confirm:$false

                $result | Should -Not -BeNullOrEmpty
                $result.Name | Should -Be 'MySnapshot_Data'
                $result.FileName | Should -Be 'C:\Snapshots\MySnapshot_Data.ss'
                $result.Parent | Should -Be $mockFileGroupObject
                $mockFileGroupObject.Files.Count | Should -Be ($initialFileCount + 1)
            }
        }

        It 'Should support Force parameter to bypass confirmation' {
            InModuleScope -Parameters @{
                mockFileGroupObject = $mockFileGroupObject
            } -ScriptBlock {
                param ($mockFileGroupObject)

                $initialFileCount = $mockFileGroupObject.Files.Count

                $result = New-SqlDscDataFile -FileGroup $mockFileGroupObject -Name 'ForcedDataFile' -FileName 'C:\Data\ForcedDataFile.mdf' -PassThru -Force

                $result | Should -Not -BeNullOrEmpty
                $result.Name | Should -Be 'ForcedDataFile'
                $result.FileName | Should -Be 'C:\Data\ForcedDataFile.mdf'
                $result.Parent | Should -Be $mockFileGroupObject
                $mockFileGroupObject.Files.Count | Should -Be ($initialFileCount + 1)
            }
        }

        It 'Should not add file when WhatIf is specified' {
            InModuleScope -Parameters @{
                mockFileGroupObject = $mockFileGroupObject
            } -ScriptBlock {
                param ($mockFileGroupObject)

                $initialFileCount = $mockFileGroupObject.Files.Count

                $result = New-SqlDscDataFile -FileGroup $mockFileGroupObject -Name 'WhatIfDataFile' -FileName 'C:\Data\WhatIfDataFile.mdf' -WhatIf

                $result | Should -BeNullOrEmpty
                $mockFileGroupObject.Files.Count | Should -Be $initialFileCount
            }
        }
    }

    Context 'Parameter validation' {
        BeforeAll {
            $commandInfo = Get-Command -Name 'New-SqlDscDataFile'
        }

        It 'Should have three parameter sets (Standard, FromSpec, AsSpec)' {
            $commandInfo.ParameterSets.Count | Should -Be 3
            $commandInfo.ParameterSets.Name | Should -Contain 'Standard'
            $commandInfo.ParameterSets.Name | Should -Contain 'FromSpec'
            $commandInfo.ParameterSets.Name | Should -Contain 'AsSpec'
        }

        It 'Should have FileGroup as a mandatory parameter' {
            $parameterInfo = $commandInfo.Parameters['FileGroup']
            $parameterInfo.Attributes.Mandatory | Should -Contain $true
        }

        It 'Should have Name as a mandatory parameter' {
            $parameterInfo = $commandInfo.Parameters['Name']
            $parameterInfo.Attributes.Mandatory | Should -Contain $true
        }

        It 'Should have FileName as a mandatory parameter' {
            $parameterInfo = $commandInfo.Parameters['FileName']
            $parameterInfo.Attributes.Mandatory | Should -Contain $true
        }

        It 'Should have PassThru parameter' {
            $parameterInfo = $commandInfo.Parameters['PassThru']
            $parameterInfo | Should -Not -BeNullOrEmpty
            $parameterInfo.ParameterType.Name | Should -Be 'SwitchParameter'
        }

        It 'Should support ShouldProcess' {
            $commandInfo.Parameters.ContainsKey('WhatIf') | Should -BeTrue
            $commandInfo.Parameters.ContainsKey('Confirm') | Should -BeTrue
        }

        It 'Should have Force parameter' {
            $parameterInfo = $commandInfo.Parameters['Force']
            $parameterInfo | Should -Not -BeNullOrEmpty
        }

        It 'Should have ConfirmImpact set to High' {
            $commandInfo.ScriptBlock.Attributes | Where-Object { $_.TypeId.Name -eq 'CmdletBindingAttribute' } |
                ForEach-Object { $_.ConfirmImpact } | Should -Be 'High'
        }
    }

    Context 'When creating a DataFile with AsSpec parameter set' {
        It 'Should return a DatabaseFileSpec object' {
            InModuleScope -ScriptBlock {
                $result = New-SqlDscDataFile -Name 'MyDB_Primary' -FileName 'D:\SQLData\MyDB.mdf' -AsSpec

                $result | Should -Not -BeNullOrEmpty
                $result.GetType().Name | Should -Be 'DatabaseFileSpec'
                $result.Name | Should -Be 'MyDB_Primary'
                $result.FileName | Should -Be 'D:\SQLData\MyDB.mdf'
            }
        }

        It 'Should set IsPrimaryFile when specified' {
            InModuleScope -ScriptBlock {
                $result = New-SqlDscDataFile -Name 'MyDB_Primary' -FileName 'D:\SQLData\MyDB.mdf' -IsPrimaryFile -AsSpec

                $result | Should -Not -BeNullOrEmpty
                $result.IsPrimaryFile | Should -BeTrue
            }
        }

        It 'Should set Size, MaxSize, Growth, and GrowthType when specified' {
            InModuleScope -ScriptBlock {
                $result = New-SqlDscDataFile -Name 'MyDB_Primary' -FileName 'D:\SQLData\MyDB.mdf' -Size 102400 -MaxSize 5242880 -Growth 10240 -GrowthType 'KB' -AsSpec

                $result | Should -Not -BeNullOrEmpty
                $result.Size | Should -Be 102400
                $result.MaxSize | Should -Be 5242880
                $result.Growth | Should -Be 10240
                $result.GrowthType | Should -Be 'KB'
            }
        }
    }

    Context 'When creating a DataFile from a DatabaseFileSpec' {
        BeforeAll {
            $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
            $mockDatabaseObject.Name = 'TestDatabase'
        }

        It 'Should create a DataFile from a DatabaseFileSpec in the PRIMARY filegroup' {
            InModuleScope -Parameters @{
                mockDatabaseObject = $mockDatabaseObject
            } -ScriptBlock {
                param ($mockDatabaseObject)

                $mockFileGroupObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.FileGroup' -ArgumentList $mockDatabaseObject, 'PRIMARY'

                $fileSpec = New-SqlDscDataFile -Name 'MyDB_Primary' -FileName 'D:\SQLData\MyDB.mdf' -IsPrimaryFile -AsSpec

                $initialFileCount = $mockFileGroupObject.Files.Count

                $result = New-SqlDscDataFile -FileGroup $mockFileGroupObject -DataFileSpec $fileSpec -PassThru -Force

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.DataFile'
                $mockFileGroupObject.Files.Count | Should -Be ($initialFileCount + 1)
            }
        }

        It 'Should throw an error when IsPrimaryFile is specified but filegroup is not PRIMARY' {
            InModuleScope -Parameters @{
                mockDatabaseObject = $mockDatabaseObject
            } -ScriptBlock {
                param ($mockDatabaseObject)

                $mockFileGroupObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.FileGroup' -ArgumentList $mockDatabaseObject, 'SECONDARY'

                $fileSpec = New-SqlDscDataFile -Name 'MyDB_Primary' -FileName 'D:\SQLData\MyDB.mdf' -IsPrimaryFile -AsSpec

                { New-SqlDscDataFile -FileGroup $mockFileGroupObject -DataFileSpec $fileSpec -Force -ErrorAction Stop } |
                    Should -Throw -ExpectedMessage '*The primary file must reside in the PRIMARY filegroup*'
            }
        }

        It 'Should create a DataFile from a DatabaseFileSpec without IsPrimaryFile in a non-PRIMARY filegroup' {
            InModuleScope -Parameters @{
                mockDatabaseObject = $mockDatabaseObject
            } -ScriptBlock {
                param ($mockDatabaseObject)

                $mockFileGroupObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.FileGroup' -ArgumentList $mockDatabaseObject, 'SECONDARY'

                $fileSpec = New-SqlDscDataFile -Name 'MyDB_Secondary' -FileName 'D:\SQLData\MyDB_Secondary.ndf' -AsSpec

                $initialFileCount = $mockFileGroupObject.Files.Count

                $result = New-SqlDscDataFile -FileGroup $mockFileGroupObject -DataFileSpec $fileSpec -PassThru -Force

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.DataFile'
                $mockFileGroupObject.Files.Count | Should -Be ($initialFileCount + 1)
            }
        }
    }
}
