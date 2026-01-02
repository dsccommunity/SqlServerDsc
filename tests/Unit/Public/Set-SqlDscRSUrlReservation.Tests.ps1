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

    Import-Module -Name $script:moduleName

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:moduleName
}

AfterAll {
    Remove-Item -Path 'env:SqlServerDscCI' -Force -ErrorAction 'SilentlyContinue'

    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')
}

Describe 'Set-SqlDscRSUrlReservation' -Tag 'Public' {
    Context 'When validating parameter sets' {
        BeforeAll {
            $command = Get-Command -Name 'Set-SqlDscRSUrlReservation'
        }

        It 'Should have the correct parameters in parameter set __AllParameterSets' {
            $ExpectedParameters = '[-Configuration] <Object> [-Application] <string> [-UrlString] <string[]> [[-Lcid] <int>] [-PassThru] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'

            $result = $command.ParameterSets |
                Where-Object -FilterScript { $_.Name -eq '__AllParameterSets' } |
                Select-Object -Property @{
                    Name       = 'ParameterListAsString'
                    Expression = { $_.ToString() }
                }

            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }
    }

    Context 'When setting URL reservations with no changes needed' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Get-SqlDscRSUrlReservation -MockWith {
                return [PSCustomObject] @{
                    HRESULT     = 0
                    Application = @('ReportServerWebService', 'ReportServerWebService')
                    UrlString   = @('http://+:80', 'https://+:443')
                }
            }

            Mock -CommandName Add-SqlDscRSUrlReservation
            Mock -CommandName Remove-SqlDscRSUrlReservation
        }

        It 'Should not add or remove any URLs when current matches desired' {
            $mockCimInstance | Set-SqlDscRSUrlReservation -Application 'ReportServerWebService' -UrlString 'http://+:80', 'https://+:443' -Force

            Should -Invoke -CommandName Get-SqlDscRSUrlReservation -Exactly -Times 1
            Should -Invoke -CommandName Add-SqlDscRSUrlReservation -Exactly -Times 0
            Should -Invoke -CommandName Remove-SqlDscRSUrlReservation -Exactly -Times 0
        }
    }

    Context 'When adding new URL reservations' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Get-SqlDscRSUrlReservation -MockWith {
                return [PSCustomObject] @{
                    HRESULT     = 0
                    Application = @('ReportServerWebService')
                    UrlString   = @('http://+:80')
                }
            }

            Mock -CommandName Add-SqlDscRSUrlReservation
            Mock -CommandName Remove-SqlDscRSUrlReservation
        }

        It 'Should add the new URL' {
            $mockCimInstance | Set-SqlDscRSUrlReservation -Application 'ReportServerWebService' -UrlString 'http://+:80', 'https://+:443' -Force

            Should -Invoke -CommandName Add-SqlDscRSUrlReservation -ParameterFilter {
                $UrlString -eq 'https://+:443'
            } -Exactly -Times 1

            Should -Invoke -CommandName Remove-SqlDscRSUrlReservation -Exactly -Times 0
        }
    }

    Context 'When removing existing URL reservations' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Get-SqlDscRSUrlReservation -MockWith {
                return [PSCustomObject] @{
                    HRESULT     = 0
                    Application = @('ReportServerWebService', 'ReportServerWebService')
                    UrlString   = @('http://+:80', 'https://+:443')
                }
            }

            Mock -CommandName Add-SqlDscRSUrlReservation
            Mock -CommandName Remove-SqlDscRSUrlReservation
        }

        It 'Should remove the URL not in the desired list' {
            $mockCimInstance | Set-SqlDscRSUrlReservation -Application 'ReportServerWebService' -UrlString 'http://+:80' -Force

            Should -Invoke -CommandName Remove-SqlDscRSUrlReservation -ParameterFilter {
                $UrlString -eq 'https://+:443'
            } -Exactly -Times 1

            Should -Invoke -CommandName Add-SqlDscRSUrlReservation -Exactly -Times 0
        }
    }

    Context 'When both adding and removing URL reservations' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Get-SqlDscRSUrlReservation -MockWith {
                return [PSCustomObject] @{
                    HRESULT     = 0
                    Application = @('ReportServerWebService', 'ReportServerWebService')
                    UrlString   = @('http://+:80', 'http://+:8080')
                }
            }

            Mock -CommandName Add-SqlDscRSUrlReservation
            Mock -CommandName Remove-SqlDscRSUrlReservation
        }

        It 'Should add new and remove old URLs' {
            $mockCimInstance | Set-SqlDscRSUrlReservation -Application 'ReportServerWebService' -UrlString 'http://+:80', 'https://+:443' -Force

            Should -Invoke -CommandName Add-SqlDscRSUrlReservation -ParameterFilter {
                $UrlString -eq 'https://+:443'
            } -Exactly -Times 1

            Should -Invoke -CommandName Remove-SqlDscRSUrlReservation -ParameterFilter {
                $UrlString -eq 'http://+:8080'
            } -Exactly -Times 1
        }
    }

    Context 'When using PassThru' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Get-SqlDscRSUrlReservation -MockWith {
                return [PSCustomObject] @{
                    HRESULT     = 0
                    Application = @()
                    UrlString   = @()
                }
            }

            Mock -CommandName Add-SqlDscRSUrlReservation
            Mock -CommandName Remove-SqlDscRSUrlReservation
        }

        It 'Should return the configuration CIM instance' {
            $result = $mockCimInstance | Set-SqlDscRSUrlReservation -Application 'ReportServerWebService' -UrlString 'http://+:80' -Force -PassThru

            $result | Should -Not -BeNullOrEmpty
            $result.InstanceName | Should -Be 'SSRS'
        }
    }

    Context 'When using custom Lcid' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Get-SqlDscRSUrlReservation -MockWith {
                return [PSCustomObject] @{
                    HRESULT     = 0
                    Application = @()
                    UrlString   = @()
                }
            }

            Mock -CommandName Add-SqlDscRSUrlReservation
            Mock -CommandName Remove-SqlDscRSUrlReservation
        }

        It 'Should pass Lcid to Add-SqlDscRSUrlReservation' {
            $mockCimInstance | Set-SqlDscRSUrlReservation -Application 'ReportServerWebService' -UrlString 'http://+:80' -Lcid 1031 -Force

            Should -Invoke -CommandName Add-SqlDscRSUrlReservation -ParameterFilter {
                $Lcid -eq 1031
            } -Exactly -Times 1
        }
    }

    Context 'When using WhatIf' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Get-SqlDscRSUrlReservation
            Mock -CommandName Add-SqlDscRSUrlReservation
            Mock -CommandName Remove-SqlDscRSUrlReservation
        }

        It 'Should not call any modification commands' {
            $mockCimInstance | Set-SqlDscRSUrlReservation -Application 'ReportServerWebService' -UrlString 'http://+:80' -WhatIf

            Should -Invoke -CommandName Get-SqlDscRSUrlReservation -Exactly -Times 0
            Should -Invoke -CommandName Add-SqlDscRSUrlReservation -Exactly -Times 0
            Should -Invoke -CommandName Remove-SqlDscRSUrlReservation -Exactly -Times 0
        }
    }

    Context 'When passing configuration as parameter' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Get-SqlDscRSUrlReservation -MockWith {
                return [PSCustomObject] @{
                    HRESULT     = 0
                    Application = @()
                    UrlString   = @()
                }
            }

            Mock -CommandName Add-SqlDscRSUrlReservation
            Mock -CommandName Remove-SqlDscRSUrlReservation
        }

        It 'Should set URL reservations' {
            { Set-SqlDscRSUrlReservation -Configuration $mockCimInstance -Application 'ReportServerWebService' -UrlString 'http://+:80' -Force } | Should -Not -Throw

            Should -Invoke -CommandName Get-SqlDscRSUrlReservation -Exactly -Times 1
        }
    }

    Context 'When no current reservations exist for application' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Get-SqlDscRSUrlReservation -MockWith {
                return [PSCustomObject] @{
                    HRESULT     = 0
                    Application = @('ReportServerWebApp')
                    UrlString   = @('http://+:80')
                }
            }

            Mock -CommandName Add-SqlDscRSUrlReservation
            Mock -CommandName Remove-SqlDscRSUrlReservation
        }

        It 'Should add all specified URLs' {
            $mockCimInstance | Set-SqlDscRSUrlReservation -Application 'ReportServerWebService' -UrlString 'http://+:80', 'https://+:443' -Force

            Should -Invoke -CommandName Add-SqlDscRSUrlReservation -Exactly -Times 2
            Should -Invoke -CommandName Remove-SqlDscRSUrlReservation -Exactly -Times 0
        }
    }

    Context 'When current reservations is null' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Get-SqlDscRSUrlReservation -MockWith {
                return [PSCustomObject] @{
                    HRESULT     = 0
                    Application = $null
                    UrlString   = $null
                }
            }

            Mock -CommandName Add-SqlDscRSUrlReservation
            Mock -CommandName Remove-SqlDscRSUrlReservation
        }

        It 'Should add all specified URLs' {
            $mockCimInstance | Set-SqlDscRSUrlReservation -Application 'ReportServerWebService' -UrlString 'http://+:80' -Force

            Should -Invoke -CommandName Add-SqlDscRSUrlReservation -Exactly -Times 1
            Should -Invoke -CommandName Remove-SqlDscRSUrlReservation -Exactly -Times 0
        }
    }
}
