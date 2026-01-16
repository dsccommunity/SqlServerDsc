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

    Import-Module -Name $script:moduleName -ErrorAction 'Stop'

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

Describe 'Stop-SqlDscRSWindowsService' {
    Context 'When validating parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = '__AllParameterSets'
                ExpectedParameters = '[-Configuration] <Object> [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Stop-SqlDscRSWindowsService').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }
    }

    Context 'When stopping Windows service successfully' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName            = 'SSRS'
                IsWindowsServiceEnabled = $true
                IsWebServiceEnabled     = $true
            }

            Mock -CommandName Invoke-RsCimMethod -MockWith {
                return [PSCustomObject] @{
                    HRESULT = 0
                }
            }

            Mock -CommandName Get-RSServiceState -MockWith {
                return @{
                    EnableWindowsService = $false
                    EnableWebService     = $true
                    EnableReportManager  = $true
                }
            }
        }

        It 'Should stop Windows service without errors' {
            { $mockCimInstance | Stop-SqlDscRSWindowsService -Confirm:$false } | Should -Not -Throw

            Should -Invoke -CommandName Get-RSServiceState -ParameterFilter {
                $DisableWindowsService -eq $true
            } -Exactly -Times 1

            Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                $MethodName -eq 'SetServiceState' -and
                $Arguments.EnableWindowsService -eq $false
            } -Exactly -Times 1
        }

        It 'Should not return anything' {
            $result = $mockCimInstance | Stop-SqlDscRSWindowsService -Confirm:$false

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'When stopping Windows service with Force' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName            = 'SSRS'
                IsWindowsServiceEnabled = $true
                IsWebServiceEnabled     = $true
            }

            Mock -CommandName Invoke-RsCimMethod -MockWith {
                return [PSCustomObject] @{
                    HRESULT = 0
                }
            }

            Mock -CommandName Get-RSServiceState -MockWith {
                return @{
                    EnableWindowsService = $false
                    EnableWebService     = $true
                    EnableReportManager  = $true
                }
            }
        }

        It 'Should stop Windows service without confirmation' {
            { $mockCimInstance | Stop-SqlDscRSWindowsService -Force } | Should -Not -Throw

            Should -Invoke -CommandName Invoke-RsCimMethod -Exactly -Times 1
        }
    }

    Context 'When using WhatIf' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName            = 'SSRS'
                IsWindowsServiceEnabled = $true
                IsWebServiceEnabled     = $true
            }

            Mock -CommandName Invoke-RsCimMethod
            Mock -CommandName Get-RSServiceState
        }

        It 'Should not call Invoke-RsCimMethod' {
            $mockCimInstance | Stop-SqlDscRSWindowsService -WhatIf

            Should -Invoke -CommandName Invoke-RsCimMethod -Exactly -Times 0
            Should -Invoke -CommandName Get-RSServiceState -Exactly -Times 0
        }
    }

    Context 'When passing configuration as parameter' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName            = 'SSRS'
                IsWindowsServiceEnabled = $true
                IsWebServiceEnabled     = $true
            }

            Mock -CommandName Invoke-RsCimMethod -MockWith {
                return [PSCustomObject] @{
                    HRESULT = 0
                }
            }

            Mock -CommandName Get-RSServiceState -MockWith {
                return @{
                    EnableWindowsService = $false
                    EnableWebService     = $true
                    EnableReportManager  = $true
                }
            }
        }

        It 'Should stop Windows service' {
            { Stop-SqlDscRSWindowsService -Configuration $mockCimInstance -Confirm:$false } | Should -Not -Throw

            Should -Invoke -CommandName Invoke-RsCimMethod -Exactly -Times 1
        }
    }
}
