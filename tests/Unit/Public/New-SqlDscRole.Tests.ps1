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

Describe 'New-SqlDscRole' -Tag 'Public' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            # Default parameters that are used for the It-blocks.
            $script:mockDefaultParameters = @{
                ServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                Name = 'TestRole'
            }
        }
    }

    Context 'When creating a new server role' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force

            # Create mock roles collection that returns null for new role
            $mockRoleCollection = @{}

            $mockServerObject | Add-Member -MemberType 'ScriptProperty' -Name 'Roles' -Value {
                return [PSCustomObject]@{
                    PSTypeName = 'MockRoleCollection'
                } | Add-Member -MemberType 'ScriptMethod' -Name 'get_Item' -Value {
                    param($roleName)
                    return $mockRoleCollection[$roleName]
                } -PassThru | Add-Member -MemberType 'ScriptMethod' -Name 'Refresh' -Value {
                    # Mock implementation
                } -PassThru
            } -Force
        }

        It 'Should create a new server role successfully' {
            Mock -CommandName 'Write-Verbose'
            
            # Create a mock role object that can be returned
            $mockNewRole = New-Object -TypeName Object
            $mockNewRole | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestRole' -Force
            $mockNewRole | Add-Member -MemberType 'ScriptMethod' -Name 'Create' -Value {
                # Mock implementation
            } -Force

            # Mock the New-Object call to return our mock role
            Mock -CommandName 'New-Object' -ParameterFilter {
                $TypeName -eq 'Microsoft.SqlServer.Management.Smo.ServerRole'
            } -MockWith {
                return $mockNewRole
            }

            $result = New-SqlDscRole -ServerObject $mockServerObject -Name 'TestRole' -Force

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'TestRole'
            
            Should -Invoke -CommandName 'New-Object' -ParameterFilter {
                $TypeName -eq 'Microsoft.SqlServer.Management.Smo.ServerRole'
            } -Exactly -Times 1
        }

        It 'Should set the owner when Owner parameter is specified' {
            Mock -CommandName 'Write-Verbose'
            
            # Create a mock role object that can be returned
            $mockNewRole = New-Object -TypeName Object
            $mockNewRole | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestRole' -Force
            $mockNewRole | Add-Member -MemberType 'NoteProperty' -Name 'Owner' -Value $null -Force
            $mockNewRole | Add-Member -MemberType 'ScriptMethod' -Name 'Create' -Value {
                # Mock implementation
            } -Force

            # Mock the New-Object call to return our mock role
            Mock -CommandName 'New-Object' -ParameterFilter {
                $TypeName -eq 'Microsoft.SqlServer.Management.Smo.ServerRole'
            } -MockWith {
                return $mockNewRole
            }

            $result = New-SqlDscRole -ServerObject $mockServerObject -Name 'TestRole' -Owner 'TestOwner' -Force

            $result.Owner | Should -Be 'TestOwner'
        }

        It 'Should call Refresh when Refresh parameter is specified' {
            Mock -CommandName 'Write-Verbose'
            
            # Create a mock role object that can be returned
            $mockNewRole = New-Object -TypeName Object
            $mockNewRole | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestRole' -Force
            $mockNewRole | Add-Member -MemberType 'ScriptMethod' -Name 'Create' -Value {
                # Mock implementation
            } -Force

            # Mock the New-Object call to return our mock role
            Mock -CommandName 'New-Object' -ParameterFilter {
                $TypeName -eq 'Microsoft.SqlServer.Management.Smo.ServerRole'
            } -MockWith {
                return $mockNewRole
            }

            # Track Refresh call
            $script:refreshCalled = $false
            $mockServerObject.Roles | Add-Member -MemberType 'ScriptMethod' -Name 'Refresh' -Value {
                $script:refreshCalled = $true
            } -Force

            New-SqlDscRole -ServerObject $mockServerObject -Name 'TestRole' -Refresh -Force

            $script:refreshCalled | Should -BeTrue
        }
    }

    Context 'When the server role already exists' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force

            # Create mock roles collection that returns an existing role
            $mockExistingRole = New-Object -TypeName Object
            $mockExistingRole | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'ExistingRole' -Force
            
            $mockRoleCollection = @{
                'ExistingRole' = $mockExistingRole
            }

            $mockServerObject | Add-Member -MemberType 'ScriptProperty' -Name 'Roles' -Value {
                return [PSCustomObject]@{
                    PSTypeName = 'MockRoleCollection'
                } | Add-Member -MemberType 'ScriptMethod' -Name 'get_Item' -Value {
                    param($roleName)
                    return $mockRoleCollection[$roleName]
                } -PassThru | Add-Member -MemberType 'ScriptMethod' -Name 'Refresh' -Value {
                    # Mock implementation
                } -PassThru
            } -Force
        }

        It 'Should throw an error when role already exists' {
            Mock -CommandName 'Write-Verbose'

            { New-SqlDscRole -ServerObject $mockServerObject -Name 'ExistingRole' -Force } |
                Should -Throw -ExpectedMessage '*already exists*'
        }
    }

    Context 'When role creation fails' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force

            # Create mock roles collection that returns null for new role
            $mockRoleCollection = @{}

            $mockServerObject | Add-Member -MemberType 'ScriptProperty' -Name 'Roles' -Value {
                return [PSCustomObject]@{
                    PSTypeName = 'MockRoleCollection'
                } | Add-Member -MemberType 'ScriptMethod' -Name 'get_Item' -Value {
                    param($roleName)
                    return $mockRoleCollection[$roleName]
                } -PassThru | Add-Member -MemberType 'ScriptMethod' -Name 'Refresh' -Value {
                    # Mock implementation
                } -PassThru
            } -Force
        }

        It 'Should throw an error when role creation fails' {
            Mock -CommandName 'Write-Verbose'
            
            # Create a mock role object that fails to create
            $mockNewRole = New-Object -TypeName Object
            $mockNewRole | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestRole' -Force
            $mockNewRole | Add-Member -MemberType 'ScriptMethod' -Name 'Create' -Value {
                throw 'Creation failed'
            } -Force

            # Mock the New-Object call to return our failing mock role
            Mock -CommandName 'New-Object' -ParameterFilter {
                $TypeName -eq 'Microsoft.SqlServer.Management.Smo.ServerRole'
            } -MockWith {
                return $mockNewRole
            }

            { New-SqlDscRole -ServerObject $mockServerObject -Name 'TestRole' -Force } |
                Should -Throw -ExpectedMessage '*Failed to create*'
        }
    }

    Context 'Parameter validation' {
        It 'Should have the correct parameters in parameter set __AllParameterSets' -ForEach @(
            @{
                ExpectedParameterSetName = '__AllParameterSets'
                ExpectedParameters = '[-ServerObject] <Server> [-Name] <String> [[-Owner] <String>] [-Force] [-Refresh] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'New-SqlDscRole').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }

        It 'Should have ServerObject as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'New-SqlDscRole').Parameters['ServerObject']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have Name as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'New-SqlDscRole').Parameters['Name']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have Owner as a non-mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'New-SqlDscRole').Parameters['Owner']
            $parameterInfo.Attributes.Mandatory | Should -BeFalse
        }

        It 'Should have Force as a non-mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'New-SqlDscRole').Parameters['Force']
            $parameterInfo.Attributes.Mandatory | Should -BeFalse
        }

        It 'Should have Refresh as a non-mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'New-SqlDscRole').Parameters['Refresh']
            $parameterInfo.Attributes.Mandatory | Should -BeFalse
        }
    }
}