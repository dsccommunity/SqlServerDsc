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

Describe 'Disable-SqlDscLogin' -Tag 'Public' {
    It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
        @{
            ExpectedParameterSetName = 'ServerObject'
            ExpectedParameters = '-ServerObject <Server> -Name <string> [-Force] [-Refresh] [-WhatIf] [-Confirm] [<CommonParameters>]'
        },
        @{
            ExpectedParameterSetName = 'LoginObject'
            ExpectedParameters = '-LoginObject <Login> [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
    ) {
        $result = (Get-Command -Name 'Disable-SqlDscLogin').ParameterSets |
            Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
            Select-Object -Property @(
                @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
            )

        $result.ParameterSetName | Should -Be $ExpectedParameterSetName
        $result.ParameterListAsString | Should -Be $ExpectedParameters
    }

    Context 'When using parameter set ServerObject' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'TestInstance'

            $mockLoginObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Login' -ArgumentList @('TestLogin')
            $mockLoginObject.IsDisabled = $false

            Mock -CommandName Get-SqlDscLogin -MockWith {
                return @($mockLoginObject)
            }
        }

        Context 'When the login should be disabled' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockMethodDisableWasRun = 0
                }

                $mockLoginObject | Add-Member -MemberType 'ScriptMethod' -Name 'Disable' -Value {
                    InModuleScope -ScriptBlock {
                        $script:mockMethodDisableWasRun += 1
                    }
                } -Force

                # Add parent property
                $mockLoginObject | Add-Member -MemberType 'NoteProperty' -Name 'Parent' -Value $mockServerObject -Force
            }

            It 'Should call the correct methods' {
                { Disable-SqlDscLogin -ServerObject $mockServerObject -Name 'TestLogin' -Force } | Should -Not -Throw

                Should -Invoke -CommandName Get-SqlDscLogin -ParameterFilter {
                    $ServerObject -eq $mockServerObject -and $Name -eq 'TestLogin'
                } -Exactly -Times 1 -Scope It

                InModuleScope -ScriptBlock {
                    $script:mockMethodDisableWasRun | Should -Be 1
                }
            }
        }

        Context 'When using Refresh parameter' {
            It 'Should pass Refresh parameter to Get-SqlDscLogin' {
                { Disable-SqlDscLogin -ServerObject $mockServerObject -Name 'TestLogin' -Refresh -Force } | Should -Not -Throw

                Should -Invoke -CommandName Get-SqlDscLogin -ParameterFilter {
                    $ServerObject -eq $mockServerObject -and $Name -eq 'TestLogin' -and $Refresh -eq $true
                } -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When using parameter set LoginObject' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'TestInstance'

            $mockLoginObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Login' -ArgumentList @('TestLogin')
            $mockLoginObject.IsDisabled = $false
            $mockLoginObject | Add-Member -MemberType 'NoteProperty' -Name 'Parent' -Value $mockServerObject -Force

            InModuleScope -ScriptBlock {
                $script:mockMethodDisableWasRun = 0
            }

            $mockLoginObject | Add-Member -MemberType 'ScriptMethod' -Name 'Disable' -Value {
                InModuleScope -ScriptBlock {
                    $script:mockMethodDisableWasRun += 1
                }
            } -Force
        }

        It 'Should call the correct methods' {
            { Disable-SqlDscLogin -LoginObject $mockLoginObject -Force } | Should -Not -Throw

            InModuleScope -ScriptBlock {
                $script:mockMethodDisableWasRun | Should -Be 1
            }
        }
    }
}
