<#
    .SYNOPSIS
        Unit tests for Resume-SqlDscDatabase.

    .DESCRIPTION
        Unit tests for Resume-SqlDscDatabase.
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

Describe 'Resume-SqlDscDatabase' -Tag 'Public' {
    Context 'When the command has proper parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = 'ServerObjectSet'
                ExpectedParameters = '-ServerObject <Server> -Name <string> [-Refresh] [-Force] [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
            @{
                ExpectedParameterSetName = 'DatabaseObjectSet'
                ExpectedParameters = '-DatabaseObject <Database> [-Force] [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Resume-SqlDscDatabase').ParameterSets |
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
            $command = Get-Command -Name 'Resume-SqlDscDatabase'
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

    Context 'When bringing a database online using ServerObject and Name' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'TestInstance'

            $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database' -ArgumentList @($mockServerObject, 'TestDatabase')
            $mockDatabaseObject.Status = [Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Offline

            Mock -CommandName 'Get-SqlDscDatabase' -MockWith {
                return $mockDatabaseObject
            }
        }

        It 'Should bring the database online and not throw' {
            $null = Resume-SqlDscDatabase -ServerObject $mockServerObject -Name 'TestDatabase' -Force

            $mockDatabaseObject.Status | Should -Be ([Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Normal)

            Should -Invoke -CommandName 'Get-SqlDscDatabase' -Exactly -Times 1 -Scope It
        }

        It 'Should call Get-SqlDscDatabase with Refresh when specified' {
            $mockDatabaseObject.Status = [Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Offline

            $null = Resume-SqlDscDatabase -ServerObject $mockServerObject -Name 'TestDatabase' -Refresh -Force

            Should -Invoke -CommandName 'Get-SqlDscDatabase' -ParameterFilter {
                $Refresh -eq $true
            } -Exactly -Times 1 -Scope It
        }

        It 'Should return the database object when PassThru is specified' {
            $mockDatabaseObject.Status = [Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Offline

            $result = Resume-SqlDscDatabase -ServerObject $mockServerObject -Name 'TestDatabase' -PassThru -Force

            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.Database'
            $result.Name | Should -Be 'TestDatabase'
        }

        It 'Should not bring the database online when database is already online' {
            $mockDatabaseObject.Status = [Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Normal

            $null = Resume-SqlDscDatabase -ServerObject $mockServerObject -Name 'TestDatabase' -Force

            $mockDatabaseObject.Status | Should -Be ([Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Normal)
        }
    }

    Context 'When bringing a database online using DatabaseObject' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'TestInstance'

            $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database' -ArgumentList @($mockServerObject, 'TestDatabase')
            $mockDatabaseObject.Status = [Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Offline
        }

        It 'Should bring the database online using DatabaseObject parameter' {
            $null = Resume-SqlDscDatabase -DatabaseObject $mockDatabaseObject -Force

            $mockDatabaseObject.Status | Should -Be ([Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Normal)
        }

        It 'Should return the database object when PassThru is specified' {
            $mockDatabaseObject.Status = [Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Offline

            $result = Resume-SqlDscDatabase -DatabaseObject $mockDatabaseObject -PassThru -Force

            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.Database'
            $result.Name | Should -Be 'TestDatabase'
        }
    }

    Context 'When bringing a database online via pipeline using ServerObject' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'TestInstance'

            $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database' -ArgumentList @($mockServerObject, 'TestDatabase')
            $mockDatabaseObject.Status = [Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Offline

            Mock -CommandName 'Get-SqlDscDatabase' -MockWith {
                return $mockDatabaseObject
            }
        }

        It 'Should bring the database online via pipeline' {
            $null = $mockServerObject | Resume-SqlDscDatabase -Name 'TestDatabase' -Force

            $mockDatabaseObject.Status | Should -Be ([Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Normal)
        }
    }

    Context 'When bringing a database online via pipeline using DatabaseObject' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'TestInstance'

            $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database' -ArgumentList @($mockServerObject, 'TestDatabase')
            $mockDatabaseObject.Status = [Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Offline
        }

        It 'Should bring the database online via pipeline' {
            $null = $mockDatabaseObject | Resume-SqlDscDatabase -Force

            $mockDatabaseObject.Status | Should -Be ([Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Normal)
        }
    }

    Context 'When WhatIf is used' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'TestInstance'

            $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database' -ArgumentList @($mockServerObject, 'TestDatabase')
            $mockDatabaseObject.Status = [Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Offline

            Mock -CommandName 'Get-SqlDscDatabase' -MockWith {
                return $mockDatabaseObject
            }
        }

        It 'Should not bring the database online when WhatIf is specified' {
            $null = Resume-SqlDscDatabase -ServerObject $mockServerObject -Name 'TestDatabase' -WhatIf

            $mockDatabaseObject.Status | Should -Be ([Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Offline)
        }
    }

    Context 'When an error occurs during the operation' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'TestInstance'

            $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database' -ArgumentList @($mockServerObject, 'TestDatabase')
            $mockDatabaseObject.Status = [Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Offline

            # Override SetOnline to throw an exception
            $mockDatabaseObject | Add-Member -MemberType ScriptMethod -Name SetOnline -Value {
                throw 'Failed to bring database online'
            } -Force

            Mock -CommandName 'Get-SqlDscDatabase' -MockWith {
                return $mockDatabaseObject
            }
        }

        It 'Should throw a terminating error when SetOnline fails' {
            { Resume-SqlDscDatabase -ServerObject $mockServerObject -Name 'TestDatabase' -Force } | Should -Throw -ExpectedMessage '*Failed to bring database*online*'
        }
    }
}
