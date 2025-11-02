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

Describe 'Add-SqlDscDataFile' -Tag 'Public' {
    Context 'When adding a DataFile to a FileGroup' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database' -ArgumentList @($mockServerObject, 'MyDatabase')
            $mockFileGroupObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.FileGroup' -ArgumentList @($mockDatabaseObject, 'PRIMARY')
            $mockDataFileObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DataFile' -ArgumentList @($mockFileGroupObject, 'MyDataFile', 'C:\Data\MyDataFile.mdf')
        }

        It 'Should add the DataFile to the FileGroup without returning output' {
            { Add-SqlDscDataFile -FileGroup $mockFileGroupObject -DataFile $mockDataFileObject } | Should -Not -Throw

            $mockFileGroupObject.Files.Count | Should -Be 1
            $mockFileGroupObject.Files[0].Name | Should -Be 'MyDataFile'
            $mockFileGroupObject.Files[0].FileName | Should -Be 'C:\Data\MyDataFile.mdf'
        }

        It 'Should add the DataFile to the FileGroup and return the DataFile when PassThru is specified' {
            $mockFileGroupObject2 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.FileGroup' -ArgumentList @($mockDatabaseObject, 'SECONDARY')
            $mockDataFileObject2 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DataFile' -ArgumentList @($mockFileGroupObject2, 'MyDataFile2', 'C:\Data\MyDataFile2.ndf')

            $result = Add-SqlDscDataFile -FileGroup $mockFileGroupObject2 -DataFile $mockDataFileObject2 -PassThru

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.DataFile'
            $result.Name | Should -Be 'MyDataFile2'
            $result.FileName | Should -Be 'C:\Data\MyDataFile2.ndf'
            $mockFileGroupObject2.Files.Count | Should -Be 1
        }

        It 'Should accept DataFile from pipeline' {
            $mockFileGroupObject3 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.FileGroup' -ArgumentList @($mockDatabaseObject, 'TERTIARY')
            $mockDataFileObject3 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DataFile' -ArgumentList @($mockFileGroupObject3, 'MyDataFile3', 'C:\Data\MyDataFile3.ndf')

            { $mockDataFileObject3 | Add-SqlDscDataFile -FileGroup $mockFileGroupObject3 } | Should -Not -Throw

            $mockFileGroupObject3.Files.Count | Should -Be 1
            $mockFileGroupObject3.Files[0].Name | Should -Be 'MyDataFile3'
        }

        It 'Should add multiple DataFiles to FileGroup' {
            $mockFileGroupObject4 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.FileGroup' -ArgumentList @($mockDatabaseObject, 'QUATERNARY')
            $mockDataFileObject4a = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DataFile' -ArgumentList @($mockFileGroupObject4, 'MyDataFile4a', 'C:\Data\MyDataFile4a.ndf')
            $mockDataFileObject4b = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DataFile' -ArgumentList @($mockFileGroupObject4, 'MyDataFile4b', 'C:\Data\MyDataFile4b.ndf')

            { Add-SqlDscDataFile -FileGroup $mockFileGroupObject4 -DataFile @($mockDataFileObject4a, $mockDataFileObject4b) } | Should -Not -Throw

            $mockFileGroupObject4.Files.Count | Should -Be 2
            $mockFileGroupObject4.Files[0].Name | Should -Be 'MyDataFile4a'
            $mockFileGroupObject4.Files[1].Name | Should -Be 'MyDataFile4b'
        }

        It 'Should add multiple DataFiles via pipeline and return them with PassThru' {
            $mockFileGroupObject5 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.FileGroup' -ArgumentList @($mockDatabaseObject, 'QUINARY')
            $mockDataFileObject5a = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DataFile' -ArgumentList @($mockFileGroupObject5, 'MyDataFile5a', 'C:\Data\MyDataFile5a.ndf')
            $mockDataFileObject5b = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DataFile' -ArgumentList @($mockFileGroupObject5, 'MyDataFile5b', 'C:\Data\MyDataFile5b.ndf')

            $result = @($mockDataFileObject5a, $mockDataFileObject5b) | Add-SqlDscDataFile -FileGroup $mockFileGroupObject5 -PassThru

            $result | Should -HaveCount 2
            $result[0].Name | Should -Be 'MyDataFile5a'
            $result[1].Name | Should -Be 'MyDataFile5b'
            $mockFileGroupObject5.Files.Count | Should -Be 2
        }
    }

    Context 'Parameter validation' {
        BeforeAll {
            $commandInfo = Get-Command -Name 'Add-SqlDscDataFile'
        }

        It 'Should have FileGroup as a mandatory parameter' {
            $parameterInfo = $commandInfo.Parameters['FileGroup']
            $parameterInfo.Attributes.Mandatory | Should -Contain $true
        }

        It 'Should have DataFile as a mandatory parameter' {
            $parameterInfo = $commandInfo.Parameters['DataFile']
            $parameterInfo.Attributes.Mandatory | Should -Contain $true
        }

        It 'Should have PassThru as an optional parameter' {
            $parameterInfo = $commandInfo.Parameters['PassThru']
            $parameterInfo.Attributes.Mandatory | Should -Not -Contain $true
        }

        It 'Should have DataFile parameter accept pipeline input' {
            $parameterInfo = $commandInfo.Parameters['DataFile']
            $parameterInfo.Attributes.ValueFromPipeline | Should -Contain $true
        }

        It 'Should have DataFile parameter accept array input' {
            $parameterInfo = $commandInfo.Parameters['DataFile']
            $parameterInfo.ParameterType.Name | Should -Be 'DataFile[]'
        }
    }
}
