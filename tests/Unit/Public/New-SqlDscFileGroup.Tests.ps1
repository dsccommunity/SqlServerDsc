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

Describe 'New-SqlDscFileGroup' -Tag 'Public' {
    Context 'When creating a new FileGroup with a Database' {
        BeforeAll {
            $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
            $mockDatabaseObject.Name = 'TestDatabase'
        }

        It 'Should create a FileGroup successfully' {
            InModuleScope -Parameters @{
                mockDatabaseObject = $mockDatabaseObject
            } -ScriptBlock {
                param ($mockDatabaseObject)

                $result = New-SqlDscFileGroup -Database $mockDatabaseObject -Name 'MyFileGroup'

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.FileGroup'
                $result.Name | Should -Be 'MyFileGroup'
                $result.Parent | Should -Be $mockDatabaseObject
            }
        }

        It 'Should create a PRIMARY FileGroup successfully' {
            InModuleScope -Parameters @{
                mockDatabaseObject = $mockDatabaseObject
            } -ScriptBlock {
                param ($mockDatabaseObject)

                $result = New-SqlDscFileGroup -Database $mockDatabaseObject -Name 'PRIMARY'

                $result | Should -Not -BeNullOrEmpty
                $result.Name | Should -Be 'PRIMARY'
                $result.Parent | Should -Be $mockDatabaseObject
            }
        }

        It 'Should accept Database parameter from pipeline' {
            InModuleScope -Parameters @{
                mockDatabaseObject = $mockDatabaseObject
            } -ScriptBlock {
                param ($mockDatabaseObject)

                $result = $mockDatabaseObject | New-SqlDscFileGroup -Name 'PipelineFileGroup'

                $result | Should -Not -BeNullOrEmpty
                $result.Name | Should -Be 'PipelineFileGroup'
                $result.Parent | Should -Be $mockDatabaseObject
            }
        }
    }

    Context 'When creating a standalone FileGroup' {
        It 'Should create a standalone FileGroup without a Database' {
            InModuleScope -ScriptBlock {
                $result = New-SqlDscFileGroup -Name 'StandaloneFileGroup'

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.FileGroup'
                $result.Name | Should -Be 'StandaloneFileGroup'
                $result.Parent | Should -BeNullOrEmpty
            }
        }

        It 'Should create a standalone PRIMARY FileGroup' {
            InModuleScope -ScriptBlock {
                $result = New-SqlDscFileGroup -Name 'PRIMARY'

                $result | Should -Not -BeNullOrEmpty
                $result.Name | Should -Be 'PRIMARY'
                $result.Parent | Should -BeNullOrEmpty
            }
        }
    }

    Context 'Parameter validation' {
        It 'Should have Database as a mandatory parameter in WithDatabase parameter set' {
            $parameterInfo = (Get-Command -Name 'New-SqlDscFileGroup').Parameters['Database']
            $parameterSetInfo = $parameterInfo.ParameterSets['WithDatabase']
            $parameterSetInfo.IsMandatory | Should -BeTrue
        }

        It 'Should have Database parameter not be in Standalone parameter set' {
            $parameterInfo = (Get-Command -Name 'New-SqlDscFileGroup').Parameters['Database']
            $parameterInfo.ParameterSets.Keys | Should -Not -Contain 'Standalone'
        }

        It 'Should have Name as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'New-SqlDscFileGroup').Parameters['Name']
            $parameterInfo.Attributes.Mandatory | Should -Contain $true
        }

        It 'Should have Database parameter accept pipeline input' {
            $parameterInfo = (Get-Command -Name 'New-SqlDscFileGroup').Parameters['Database']
            $parameterInfo.Attributes.ValueFromPipeline | Should -Contain $true
        }

        It 'Should have two parameter sets' {
            $command = Get-Command -Name 'New-SqlDscFileGroup'
            $command.ParameterSets.Count | Should -Be 2
            $command.ParameterSets.Name | Should -Contain 'WithDatabase'
            $command.ParameterSets.Name | Should -Contain 'Standalone'
        }

        It 'Should have Standalone as the default parameter set' {
            $command = Get-Command -Name 'New-SqlDscFileGroup'
            $command.DefaultParameterSet | Should -Be 'Standalone'
        }
    }
}
