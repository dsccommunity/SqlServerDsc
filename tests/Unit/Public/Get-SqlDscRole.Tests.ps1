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
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
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

Describe 'Get-SqlDscRole' -Tag 'Public' {
    Context 'When getting all server roles' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
            $mockServerObject | Add-Member -MemberType 'ScriptProperty' -Name 'Roles' -Value {
                $roleCollection = @(
                    (New-Object -TypeName Object | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'sysadmin' -PassThru -Force),
                    (New-Object -TypeName Object | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'CustomRole1' -PassThru -Force)
                )
                return $roleCollection | Add-Member -MemberType 'ScriptMethod' -Name 'Refresh' -Value {
                    # Mock implementation
                } -PassThru -Force
            } -Force
        }

        It 'Should return all roles when no Name parameter is specified' {
            Mock -CommandName 'Write-Verbose'

            $result = Get-SqlDscRole -ServerObject $mockServerObject

            $result | Should -HaveCount 2
            $result[0].Name | Should -Be 'sysadmin'
            $result[1].Name | Should -Be 'CustomRole1'
        }

        It 'Should call Refresh when Refresh parameter is specified' {
            Mock -CommandName 'Write-Verbose'
            
            $script:refreshCalled = $false
            $mockServerObjectWithRefresh = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObjectWithRefresh | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
            $mockServerObjectWithRefresh | Add-Member -MemberType 'ScriptProperty' -Name 'Roles' -Value {
                $roleCollection = @(
                    (New-Object -TypeName Object | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'sysadmin' -PassThru -Force)
                )
                return $roleCollection | Add-Member -MemberType 'ScriptMethod' -Name 'Refresh' -Value {
                    $script:refreshCalled = $true
                } -PassThru -Force
            } -Force

            $result = Get-SqlDscRole -ServerObject $mockServerObjectWithRefresh -Refresh

            $result | Should -HaveCount 1
            $script:refreshCalled | Should -BeTrue
        }
    }

    Context 'When getting a specific server role' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
            $mockServerObject | Add-Member -MemberType 'ScriptProperty' -Name 'Roles' -Value {
                return @{
                    'sysadmin' = New-Object -TypeName Object |
                        Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'sysadmin' -PassThru -Force
                    'CustomRole1' = New-Object -TypeName Object |
                        Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'CustomRole1' -PassThru -Force
                } | Add-Member -MemberType 'ScriptMethod' -Name 'Refresh' -Value {
                    # Mock implementation
                } -PassThru -Force
            } -Force
        }

        It 'Should return the specified role when it exists' {
            Mock -CommandName 'Write-Verbose'

            $result = Get-SqlDscRole -ServerObject $mockServerObject -Name 'sysadmin'

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'sysadmin'
        }

        It 'Should return null when the specified role does not exist' {
            Mock -CommandName 'Write-Verbose'

            $result = Get-SqlDscRole -ServerObject $mockServerObject -Name 'NonExistentRole'

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Parameter validation' {
        It 'Should have the correct parameters in parameter set __AllParameterSets' -ForEach @(
            @{
                ExpectedParameterSetName = '__AllParameterSets'
                ExpectedParameters = '[-ServerObject] <Server> [[-Name] <String>] [-Refresh] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Get-SqlDscRole').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }

        It 'Should have ServerObject as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Get-SqlDscRole').Parameters['ServerObject']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have Name as a non-mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Get-SqlDscRole').Parameters['Name']
            $parameterInfo.Attributes.Mandatory | Should -BeFalse
        }

        It 'Should have Refresh as a non-mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Get-SqlDscRole').Parameters['Refresh']
            $parameterInfo.Attributes.Mandatory | Should -BeFalse
        }
    }
}
