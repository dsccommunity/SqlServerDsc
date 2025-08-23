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

Describe 'Test-SqlDscIsLoginEnabled' -Tag 'Public' {
    It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
        @{
            ExpectedParameterSetName = 'ServerObject'
            ExpectedParameters = '-ServerObject <Server> -Name <string> [-Refresh] [<CommonParameters>]'
        },
        @{
            ExpectedParameterSetName = 'LoginObject'
            ExpectedParameters = '-LoginObject <Login> [<CommonParameters>]'
        }
    ) {
        $result = (Get-Command -Name 'Test-SqlDscIsLoginEnabled').ParameterSets |
            Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
            Select-Object -Property @(
                @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
            )

        $result.ParameterSetName | Should -Be $ExpectedParameterSetName
        $result.ParameterListAsString | Should -Be $ExpectedParameters
    }

    It 'Should have ServerObject parameter as mandatory in ServerObject parameter set' {
        $parameterInfo = (Get-Command -Name 'Test-SqlDscIsLoginEnabled').Parameters['ServerObject']
        $parameterInfo.Attributes.Mandatory | Should -BeTrue
    }

    It 'Should have Name parameter as mandatory in ServerObject parameter set' {
        $parameterInfo = (Get-Command -Name 'Test-SqlDscIsLoginEnabled').Parameters['Name']
        $parameterInfo.Attributes.Mandatory | Should -BeTrue
    }

    It 'Should have LoginObject parameter as mandatory in LoginObject parameter set' {
        $parameterInfo = (Get-Command -Name 'Test-SqlDscIsLoginEnabled').Parameters['LoginObject']
        $parameterInfo.Attributes.Mandatory | Should -BeTrue
    }

    It 'Should have ServerObject parameter accept pipeline input' {
        $parameterInfo = (Get-Command -Name 'Test-SqlDscIsLoginEnabled').Parameters['ServerObject']
        ($parameterInfo.Attributes.ValueFromPipeline -or $parameterInfo.Attributes.ValueFromPipelineByPropertyName) | Should -BeTrue
    }

    It 'Should have LoginObject parameter accept pipeline input' {
        $parameterInfo = (Get-Command -Name 'Test-SqlDscIsLoginEnabled').Parameters['LoginObject']
        ($parameterInfo.Attributes.ValueFromPipeline -or $parameterInfo.Attributes.ValueFromPipelineByPropertyName) | Should -BeTrue
    }

    Context 'When using parameter set ServerObject' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'TestInstance'
        }

        Context 'When the login is enabled' {
            BeforeAll {
                $mockLoginObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Login' -ArgumentList @('TestLogin')
                $mockLoginObject.IsDisabled = $false

                Mock -CommandName Get-SqlDscLogin -MockWith {
                    return $mockLoginObject
                }
            }

            It 'Should return $true' {
                $result = Test-SqlDscIsLoginEnabled -ServerObject $mockServerObject -Name 'TestLogin'

                $result | Should -BeTrue

                Should -Invoke -CommandName Get-SqlDscLogin -ParameterFilter {
                    $ServerObject -eq $mockServerObject -and $Name -eq 'TestLogin'
                } -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the login is disabled' {
            BeforeAll {
                $mockLoginObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Login' -ArgumentList @('TestLogin')
                $mockLoginObject.IsDisabled = $true

                Mock -CommandName Get-SqlDscLogin -MockWith {
                    return $mockLoginObject
                }
            }

            It 'Should return $false' {
                $result = Test-SqlDscIsLoginEnabled -ServerObject $mockServerObject -Name 'TestLogin'

                $result | Should -BeFalse

                Should -Invoke -CommandName Get-SqlDscLogin -ParameterFilter {
                    $ServerObject -eq $mockServerObject -and $Name -eq 'TestLogin'
                } -Exactly -Times 1 -Scope It
            }
        }

        Context 'When using Refresh parameter' {
            BeforeAll {
                $mockLoginObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Login' -ArgumentList @('TestLogin')
                $mockLoginObject.IsDisabled = $false

                Mock -CommandName Get-SqlDscLogin -MockWith {
                    return $mockLoginObject
                }
            }

            It 'Should pass Refresh parameter to Get-SqlDscLogin' {
                $result = Test-SqlDscIsLoginEnabled -ServerObject $mockServerObject -Name 'TestLogin' -Refresh

                $result | Should -BeTrue

                Should -Invoke -CommandName Get-SqlDscLogin -ParameterFilter {
                    $ServerObject -eq $mockServerObject -and $Name -eq 'TestLogin' -and $Refresh -eq $true
                } -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When using parameter set LoginObject' {
        Context 'When the login is enabled' {
            BeforeAll {
                $mockLoginObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Login' -ArgumentList @('TestLogin')
                $mockLoginObject.IsDisabled = $false
            }

            It 'Should return $true' {
                $result = Test-SqlDscIsLoginEnabled -LoginObject $mockLoginObject

                $result | Should -BeTrue
            }
        }

        Context 'When the login is disabled' {
            BeforeAll {
                $mockLoginObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Login' -ArgumentList @('TestLogin')
                $mockLoginObject.IsDisabled = $true
            }

            It 'Should return $false' {
                $result = Test-SqlDscIsLoginEnabled -LoginObject $mockLoginObject

                $result | Should -BeFalse
            }
        }
    }
}
