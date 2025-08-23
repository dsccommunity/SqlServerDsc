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

    # Script-scoped variables for tracking method calls
    $script:mockMethodDisableWasRun = 0
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

    It 'Should have ServerObject parameter as mandatory in ServerObject parameter set' {
        $parameterInfo = (Get-Command -Name 'Disable-SqlDscLogin').Parameters['ServerObject']
        $parameterInfo.Attributes.Mandatory | Should -BeTrue
    }

    It 'Should have Name parameter as mandatory in ServerObject parameter set' {
        $parameterInfo = (Get-Command -Name 'Disable-SqlDscLogin').Parameters['Name']
        $parameterInfo.Attributes.Mandatory | Should -BeTrue
    }

    It 'Should have LoginObject parameter as mandatory in LoginObject parameter set' {
        $parameterInfo = (Get-Command -Name 'Disable-SqlDscLogin').Parameters['LoginObject']
        $parameterInfo.Attributes.Mandatory | Should -BeTrue
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
                $script:mockMethodDisableWasRun = 0

                $mockLoginObject | Add-Member -MemberType 'ScriptMethod' -Name 'Disable' -Value {
                    $script:mockMethodDisableWasRun += 1
                } -Force

                # Add parent property
                $mockLoginObject | Add-Member -MemberType 'NoteProperty' -Name 'Parent' -Value $mockServerObject -Force
            }

            It 'Should call the correct methods' {
                Disable-SqlDscLogin -ServerObject $mockServerObject -Name 'TestLogin' -Force

                Should -Invoke -CommandName Get-SqlDscLogin -ParameterFilter {
                    $ServerObject -eq $mockServerObject -and $Name -eq 'TestLogin'
                } -Exactly -Times 1 -Scope It

                $script:mockMethodDisableWasRun | Should -Be 1
            }

            It 'Should not call Disable method when using WhatIf' {
                $script:mockMethodDisableWasRun = 0

                Disable-SqlDscLogin -ServerObject $mockServerObject -Name 'TestLogin' -WhatIf

                $script:mockMethodDisableWasRun | Should -Be 0
            }
        }

        Context 'When the login does not exist' {
            BeforeAll {
                Mock -CommandName Get-SqlDscLogin -MockWith {
                    return @()
                }
            }

            It 'Should throw a terminating error when login is not found' {
                { Disable-SqlDscLogin -ServerObject $mockServerObject -Name 'NonExistent' -Force } | Should -Throw

                Should -Invoke -CommandName Get-SqlDscLogin -ParameterFilter {
                    $ServerObject -eq $mockServerObject -and $Name -eq 'NonExistent'
                } -Exactly -Times 1 -Scope It
            }
        }

        Context 'When using Refresh parameter' {
            It 'Should pass Refresh parameter to Get-SqlDscLogin' {
                Disable-SqlDscLogin -ServerObject $mockServerObject -Name 'TestLogin' -Refresh -Force

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

            $script:mockMethodDisableWasRun = 0

            $mockLoginObject | Add-Member -MemberType 'ScriptMethod' -Name 'Disable' -Value {
                $script:mockMethodDisableWasRun += 1
            } -Force
        }

        It 'Should call the correct methods' {
            Disable-SqlDscLogin -LoginObject $mockLoginObject -Force

            $script:mockMethodDisableWasRun | Should -Be 1
        }

        It 'Should not call Disable method when using WhatIf' {
            $script:mockMethodDisableWasRun = 0

            Disable-SqlDscLogin -LoginObject $mockLoginObject -WhatIf

            $script:mockMethodDisableWasRun | Should -Be 0
        }
    }
}
