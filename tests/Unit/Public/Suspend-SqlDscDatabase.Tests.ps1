<#
    .SYNOPSIS
        Unit tests for Suspend-SqlDscDatabase.

    .DESCRIPTION
        Unit tests for Suspend-SqlDscDatabase.
#>

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

Describe 'Suspend-SqlDscDatabase' -Tag 'Public' {
    Context 'When the command has proper parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = 'ServerObjectSet'
                ExpectedParameters = '-ServerObject <Server> -Name <string> [-Force] [-Refresh] [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
            @{
                ExpectedParameterSetName = 'DatabaseObjectSet'
                ExpectedParameters = '-DatabaseObject <Database> [-Force] [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Suspend-SqlDscDatabase').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }
    }

    Context 'When verifying parameter properties' {
        BeforeAll {
            $command = Get-Command -Name 'Suspend-SqlDscDatabase'
        }

        It 'Should have ServerObject as a mandatory parameter in ServerObjectSet' {
            $parameterInfo = $command.Parameters['ServerObject']

            $parameterInfo.ParameterSets['ServerObjectSet'].IsMandatory | Should -BeTrue
        }

        It 'Should have Name as a mandatory parameter in ServerObjectSet' {
            $parameterInfo = $command.Parameters['Name']

            $parameterInfo.ParameterSets['ServerObjectSet'].IsMandatory | Should -BeTrue
        }

        It 'Should have DatabaseObject as a mandatory parameter in DatabaseObjectSet' {
            $parameterInfo = $command.Parameters['DatabaseObject']

            $parameterInfo.ParameterSets['DatabaseObjectSet'].IsMandatory | Should -BeTrue
        }
    }

    Context 'When taking a database offline using ServerObject and Name' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'TestInstance'

            $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database' -ArgumentList @($mockServerObject, 'TestDatabase')
            $mockDatabaseObject.Status = [Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Normal

            Mock -CommandName 'Get-SqlDscDatabase' -MockWith {
                return $mockDatabaseObject
            }
        }

        It 'Should take the database offline and not throw' {
            $null = Suspend-SqlDscDatabase -ServerObject $mockServerObject -Name 'TestDatabase' -Force

            $mockDatabaseObject.Status | Should -Be ([Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Offline)

            Should -Invoke -CommandName 'Get-SqlDscDatabase' -Exactly -Times 1 -Scope It
        }

        It 'Should call Get-SqlDscDatabase with Refresh when specified' {
            $mockDatabaseObject.Status = [Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Normal

            $null = Suspend-SqlDscDatabase -ServerObject $mockServerObject -Name 'TestDatabase' -Refresh -Force

            Should -Invoke -CommandName 'Get-SqlDscDatabase' -ParameterFilter {
                $Refresh -eq $true
            } -Exactly -Times 1 -Scope It
        }

        It 'Should return the database object when PassThru is specified' {
            $mockDatabaseObject.Status = [Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Normal

            $result = Suspend-SqlDscDatabase -ServerObject $mockServerObject -Name 'TestDatabase' -PassThru -Force

            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.Database'
            $result.Name | Should -Be 'TestDatabase'
        }

        It 'Should not take the database offline when database is already offline' {
            $mockDatabaseObject.Status = [Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Offline

            $null = Suspend-SqlDscDatabase -ServerObject $mockServerObject -Name 'TestDatabase' -Force

            $mockDatabaseObject.Status | Should -Be ([Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Offline)
        }
    }

    Context 'When taking a database offline using DatabaseObject' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'TestInstance'

            $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database' -ArgumentList @($mockServerObject, 'TestDatabase')
            $mockDatabaseObject.Status = [Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Normal
        }

        It 'Should take the database offline using DatabaseObject parameter' {
            $null = Suspend-SqlDscDatabase -DatabaseObject $mockDatabaseObject -Force

            $mockDatabaseObject.Status | Should -Be ([Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Offline)
        }

        It 'Should return the database object when PassThru is specified' {
            $mockDatabaseObject.Status = [Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Normal

            $result = Suspend-SqlDscDatabase -DatabaseObject $mockDatabaseObject -PassThru -Force

            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.Database'
            $result.Name | Should -Be 'TestDatabase'
        }
    }

    Context 'When taking a database offline via pipeline using ServerObject' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'TestInstance'

            $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database' -ArgumentList @($mockServerObject, 'TestDatabase')
            $mockDatabaseObject.Status = [Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Normal

            Mock -CommandName 'Get-SqlDscDatabase' -MockWith {
                return $mockDatabaseObject
            }
        }

        It 'Should take the database offline via pipeline' {
            $null = $mockServerObject | Suspend-SqlDscDatabase -Name 'TestDatabase' -Force

            $mockDatabaseObject.Status | Should -Be ([Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Offline)
        }
    }

    Context 'When taking a database offline via pipeline using DatabaseObject' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'TestInstance'

            $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database' -ArgumentList @($mockServerObject, 'TestDatabase')
            $mockDatabaseObject.Status = [Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Normal
        }

        It 'Should take the database offline via pipeline' {
            $null = $mockDatabaseObject | Suspend-SqlDscDatabase -Force

            $mockDatabaseObject.Status | Should -Be ([Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Offline)
        }
    }

    Context 'When using Force parameter to disconnect active users' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'TestInstance'

            $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database' -ArgumentList @($mockServerObject, 'TestDatabase')
            $mockDatabaseObject.Status = [Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Normal

            $script:setOfflineForceValue = $null

            # Override SetOffline to track the Force parameter
            $mockDatabaseObject | Add-Member -MemberType ScriptMethod -Name SetOffline -Value {
                param($ForceDisconnect = $false)

                $script:setOfflineForceValue = $ForceDisconnect
                $this.Status = [Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Offline
            } -Force

            Mock -CommandName 'Get-SqlDscDatabase' -MockWith {
                return $mockDatabaseObject
            }
        }

        It 'Should call SetOffline with Force when Force parameter is specified' {
            Suspend-SqlDscDatabase -ServerObject $mockServerObject -Name 'TestDatabase' -Force -Confirm:$false

            $script:setOfflineForceValue | Should -BeTrue
        }

        It 'Should call SetOffline without Force when Force parameter is not specified' {
            $mockDatabaseObject.Status = [Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Normal

            Suspend-SqlDscDatabase -ServerObject $mockServerObject -Name 'TestDatabase' -Confirm:$false

            $script:setOfflineForceValue | Should -BeFalse
        }
    }

    Context 'When WhatIf is used' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'TestInstance'

            $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database' -ArgumentList @($mockServerObject, 'TestDatabase')
            $mockDatabaseObject.Status = [Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Normal

            Mock -CommandName 'Get-SqlDscDatabase' -MockWith {
                return $mockDatabaseObject
            }
        }

        It 'Should not take the database offline when WhatIf is specified' {
            $null = Suspend-SqlDscDatabase -ServerObject $mockServerObject -Name 'TestDatabase' -WhatIf

            $mockDatabaseObject.Status | Should -Be ([Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Normal)
        }
    }

    Context 'When an error occurs during the operation' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'TestInstance'

            $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database' -ArgumentList @($mockServerObject, 'TestDatabase')
            $mockDatabaseObject.Status = [Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Normal

            # Override SetOffline to throw an exception
            $mockDatabaseObject | Add-Member -MemberType ScriptMethod -Name SetOffline -Value {
                throw 'Failed to take database offline'
            } -Force

            Mock -CommandName 'Get-SqlDscDatabase' -MockWith {
                return $mockDatabaseObject
            }
        }

        It 'Should throw a terminating error when SetOffline fails' {
            { Suspend-SqlDscDatabase -ServerObject $mockServerObject -Name 'TestDatabase' -Force } | Should -Throw -ExpectedMessage '*Failed to take database*offline*'
        }
    }
}
