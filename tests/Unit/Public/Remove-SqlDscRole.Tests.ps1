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

    $env:SqlServerDscCI = $true

    # Do not use -Force. Doing so, or unloading the module in AfterAll, causes
    # PowerShell class types to get new identities, breaking type comparisons.
    Import-Module -Name $script:moduleName -ErrorAction 'Stop'

    # Loading mocked classes
    Add-Type -Path (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '../Stubs') -ChildPath 'SMO.cs')

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

Describe 'Remove-SqlDscRole' -Tag 'Public' {
    Context 'When removing a server role using ServerObject parameter set' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force

            # Create mock role that can be removed using the actual SMO type
            $mockRole = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerRole' -ArgumentList @($mockServerObject, 'CustomRole')
            $mockRole | Add-Member -MemberType 'NoteProperty' -Name 'IsFixedRole' -Value $false -Force
            $mockRole | Add-Member -MemberType 'NoteProperty' -Name 'Parent' -Value $mockServerObject -Force
            $mockRole | Add-Member -MemberType 'ScriptMethod' -Name 'Drop' -Value {
                # Mock implementation
            } -Force

            # Create mock roles collection
            $mockServerObject | Add-Member -MemberType 'ScriptProperty' -Name 'Roles' -Value {
                return @{
                    'CustomRole' = $mockRole
                } | Add-Member -MemberType 'ScriptMethod' -Name 'Refresh' -Value {
                    # Mock implementation
                } -PassThru -Force
            } -Force
        }

        It 'Should remove the server role successfully' {
            Mock -CommandName 'Write-Verbose'

            $null = Remove-SqlDscRole -ServerObject $mockServerObject -Name 'CustomRole' -Force
        }

        It 'Should call Refresh when Refresh parameter is specified' {
            Mock -CommandName 'Write-Verbose'

            # Create a fresh mock server with refresh tracking
            $script:refreshCalled = $false
            $mockServerWithRefresh = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerWithRefresh | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force

            # Create mock role that can be removed
            $mockRoleWithRefresh = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerRole' -ArgumentList @($mockServerWithRefresh, 'CustomRole')
            $mockRoleWithRefresh | Add-Member -MemberType 'NoteProperty' -Name 'IsFixedRole' -Value $false -Force
            $mockRoleWithRefresh | Add-Member -MemberType 'NoteProperty' -Name 'Parent' -Value $mockServerWithRefresh -Force
            $mockRoleWithRefresh | Add-Member -MemberType 'ScriptMethod' -Name 'Drop' -Value {
                # Mock implementation
            } -Force

            $mockServerWithRefresh | Add-Member -MemberType 'ScriptProperty' -Name 'Roles' -Value {
                return @{
                    'CustomRole' = $mockRoleWithRefresh
                } | Add-Member -MemberType 'ScriptMethod' -Name 'Refresh' -Value {
                    $script:refreshCalled = $true
                } -PassThru -Force
            } -Force

            Remove-SqlDscRole -ServerObject $mockServerWithRefresh -Name 'CustomRole' -Refresh -Force

            $script:refreshCalled | Should -BeTrue
        }

        It 'Should throw an error when role does not exist' {
            Mock -CommandName 'Write-Verbose'

            { Remove-SqlDscRole -ServerObject $mockServerObject -Name 'NonExistentRole' -Force } |
                Should -Throw '*was not found*'
        }
    }

    Context 'When removing a server role using RoleObject parameter set' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force

            # Create mock role that can be removed using the actual SMO type
            $mockRole = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerRole' -ArgumentList @($mockServerObject, 'CustomRole')
            $mockRole | Add-Member -MemberType 'NoteProperty' -Name 'IsFixedRole' -Value $false -Force
            $mockRole | Add-Member -MemberType 'NoteProperty' -Name 'Parent' -Value $mockServerObject -Force
            $mockRole | Add-Member -MemberType 'ScriptMethod' -Name 'Drop' -Value {
                # Mock implementation
            } -Force
        }

        It 'Should remove the server role successfully' {
            Mock -CommandName 'Write-Verbose'

            $null = Remove-SqlDscRole -RoleObject $mockRole -Force
        }
    }

    Context 'When trying to remove a built-in role' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force

            # Create mock built-in role using the actual SMO type
            $mockBuiltInRole = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerRole' -ArgumentList @($mockServerObject, 'sysadmin')
            $mockBuiltInRole | Add-Member -MemberType 'NoteProperty' -Name 'IsFixedRole' -Value $true -Force
            $mockBuiltInRole | Add-Member -MemberType 'NoteProperty' -Name 'Parent' -Value $mockServerObject -Force

            # Create mock roles collection
            $mockServerObject | Add-Member -MemberType 'ScriptProperty' -Name 'Roles' -Value {
                return @{
                    'sysadmin' = $mockBuiltInRole
                } | Add-Member -MemberType 'ScriptMethod' -Name 'Refresh' -Value {
                    # Mock implementation
                } -PassThru -Force
            } -Force
        }

        It 'Should throw an error when trying to remove a built-in role using ServerObject' {
            Mock -CommandName 'Write-Verbose'

            { Remove-SqlDscRole -ServerObject $mockServerObject -Name 'sysadmin' -Force } |
                Should -Throw '*Cannot remove built-in*'
        }

        It 'Should throw an error when trying to remove a built-in role using RoleObject' {
            Mock -CommandName 'Write-Verbose'

            { Remove-SqlDscRole -RoleObject $mockBuiltInRole -Force } |
                Should -Throw '*Cannot remove built-in*'
        }
    }

    Context 'When role removal fails' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force

            # Create mock role that fails to be removed using the actual SMO type
            $mockRole = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerRole' -ArgumentList @($mockServerObject, 'CustomRole')
            $mockRole | Add-Member -MemberType 'NoteProperty' -Name 'IsFixedRole' -Value $false -Force
            $mockRole | Add-Member -MemberType 'NoteProperty' -Name 'Parent' -Value $mockServerObject -Force
            $mockRole | Add-Member -MemberType 'ScriptMethod' -Name 'Drop' -Value {
                throw 'Removal failed'
            } -Force

            # Create mock roles collection
            $mockServerObject | Add-Member -MemberType 'ScriptProperty' -Name 'Roles' -Value {
                return @{
                    'CustomRole' = $mockRole
                } | Add-Member -MemberType 'ScriptMethod' -Name 'Refresh' -Value {
                    # Mock implementation
                } -PassThru -Force
            } -Force
        }

        It 'Should throw an error when role removal fails' {
            Mock -CommandName 'Write-Verbose'

            { Remove-SqlDscRole -ServerObject $mockServerObject -Name 'CustomRole' -Force } |
                Should -Throw '*Failed to remove*'
        }
    }

    Context 'Parameter validation' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = 'ServerObject'
                ExpectedParameters = '-ServerObject <Server> -Name <string> [-Force] [-Refresh] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
            @{
                ExpectedParameterSetName = 'RoleObject'
                ExpectedParameters = '-RoleObject <ServerRole> [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Remove-SqlDscRole').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }

        It 'Should have ServerObject as a mandatory parameter in ServerObject parameter set' {
            $parameterInfo = (Get-Command -Name 'Remove-SqlDscRole').Parameters['ServerObject']
            $serverObjectParameterSet = $parameterInfo.ParameterSets['ServerObject']
            $serverObjectParameterSet.IsMandatory | Should -BeTrue
        }

        It 'Should have Name as a mandatory parameter in ServerObject parameter set' {
            $parameterInfo = (Get-Command -Name 'Remove-SqlDscRole').Parameters['Name']
            $nameParameterSet = $parameterInfo.ParameterSets['ServerObject']
            $nameParameterSet.IsMandatory | Should -BeTrue
        }

        It 'Should have RoleObject as a mandatory parameter in RoleObject parameter set' {
            $parameterInfo = (Get-Command -Name 'Remove-SqlDscRole').Parameters['RoleObject']
            $roleObjectParameterSet = $parameterInfo.ParameterSets['RoleObject']
            $roleObjectParameterSet.IsMandatory | Should -BeTrue
        }

        It 'Should have Force as a non-mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Remove-SqlDscRole').Parameters['Force']
            $parameterInfo.Attributes.Mandatory | Should -BeFalse
        }

        It 'Should have Refresh as a non-mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Remove-SqlDscRole').Parameters['Refresh']
            $parameterInfo.Attributes.Mandatory | Should -BeFalse
        }
    }
}
