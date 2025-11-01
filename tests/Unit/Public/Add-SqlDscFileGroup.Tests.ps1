<#
    .SYNOPSIS
        Unit tests for Add-SqlDscFileGroup.

    .DESCRIPTION
        Unit tests for Add-SqlDscFileGroup.
#>

[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies has been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies has not been resolved, this will throw an error.
            Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
        }
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
    }
}

BeforeAll {
    $script:dscModuleName = 'SqlServerDsc'

    $env:SqlServerDscCI = $true

    Import-Module -Name $script:dscModuleName

    # Loading SMO stub classes
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

Describe 'Add-SqlDscFileGroup' -Tag 'Public' {
    Context 'When adding FileGroups to a Database' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database' -ArgumentList @($mockServerObject, 'MyDatabase')
            $mockFileGroupObject1 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.FileGroup' -ArgumentList @($mockDatabaseObject, 'FG1')
            $mockFileGroupObject2 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.FileGroup' -ArgumentList @($mockDatabaseObject, 'FG2')
        }

        It 'Should add a single FileGroup to the Database without returning output' {
            { Add-SqlDscFileGroup -Database $mockDatabaseObject -FileGroup $mockFileGroupObject1 } | Should -Not -Throw

            $mockDatabaseObject.FileGroups.Count | Should -Be 1
            $mockDatabaseObject.FileGroups[0].Name | Should -Be 'FG1'
        }

        It 'Should add a FileGroup and return it when PassThru is specified' {
            $mockDatabaseObject2 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database' -ArgumentList @($mockServerObject, 'MyDatabase2')
            $mockFileGroupObject3 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.FileGroup' -ArgumentList @($mockDatabaseObject2, 'FG3')

            $result = Add-SqlDscFileGroup -Database $mockDatabaseObject2 -FileGroup $mockFileGroupObject3 -PassThru

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.FileGroup'
            $result.Name | Should -Be 'FG3'
            $mockDatabaseObject2.FileGroups.Count | Should -Be 1
        }

        It 'Should add multiple FileGroups from an array' {
            $mockDatabaseObject3 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database' -ArgumentList @($mockServerObject, 'MyDatabase3')
            $mockFileGroupObject4 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.FileGroup' -ArgumentList @($mockDatabaseObject3, 'FG4')
            $mockFileGroupObject5 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.FileGroup' -ArgumentList @($mockDatabaseObject3, 'FG5')
            $fileGroupArray = @($mockFileGroupObject4, $mockFileGroupObject5)

            { Add-SqlDscFileGroup -Database $mockDatabaseObject3 -FileGroup $fileGroupArray } | Should -Not -Throw

            $mockDatabaseObject3.FileGroups.Count | Should -Be 2
            $mockDatabaseObject3.FileGroups[0].Name | Should -Be 'FG4'
            $mockDatabaseObject3.FileGroups[1].Name | Should -Be 'FG5'
        }

        It 'Should accept FileGroups from pipeline' {
            $mockDatabaseObject4 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database' -ArgumentList @($mockServerObject, 'MyDatabase4')
            $mockFileGroupObject6 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.FileGroup' -ArgumentList @($mockDatabaseObject4, 'FG6')
            $mockFileGroupObject7 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.FileGroup' -ArgumentList @($mockDatabaseObject4, 'FG7')

            { @($mockFileGroupObject6, $mockFileGroupObject7) | Add-SqlDscFileGroup -Database $mockDatabaseObject4 } | Should -Not -Throw

            $mockDatabaseObject4.FileGroups.Count | Should -Be 2
            $mockDatabaseObject4.FileGroups[0].Name | Should -Be 'FG6'
            $mockDatabaseObject4.FileGroups[1].Name | Should -Be 'FG7'
        }

        It 'Should accept FileGroups from pipeline with PassThru' {
            $mockDatabaseObject5 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database' -ArgumentList @($mockServerObject, 'MyDatabase5')
            $mockFileGroupObject8 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.FileGroup' -ArgumentList @($mockDatabaseObject5, 'FG8')
            $mockFileGroupObject9 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.FileGroup' -ArgumentList @($mockDatabaseObject5, 'FG9')

            $result = @($mockFileGroupObject8, $mockFileGroupObject9) | Add-SqlDscFileGroup -Database $mockDatabaseObject5 -PassThru

            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2
            $result[0].Name | Should -Be 'FG8'
            $result[1].Name | Should -Be 'FG9'
            $mockDatabaseObject5.FileGroups.Count | Should -Be 2
        }
    }

    Context 'Parameter validation' {
        It 'Should have Database as a mandatory parameter' {
            (Get-Command -Name 'Add-SqlDscFileGroup').Parameters['Database'].Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have FileGroup as a mandatory parameter' {
            (Get-Command -Name 'Add-SqlDscFileGroup').Parameters['FileGroup'].Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have PassThru as an optional parameter' {
            (Get-Command -Name 'Add-SqlDscFileGroup').Parameters['PassThru'].Attributes.Mandatory | Should -BeFalse
        }

        It 'Should have FileGroup parameter accept pipeline input' {
            (Get-Command -Name 'Add-SqlDscFileGroup').Parameters['FileGroup'].Attributes.ValueFromPipeline | Should -BeTrue
        }

        It 'Should have FileGroup parameter accept array input' {
            (Get-Command -Name 'Add-SqlDscFileGroup').Parameters['FileGroup'].ParameterType.Name | Should -Be 'FileGroup[]'
        }
    }
}
