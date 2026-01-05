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

Describe 'Restart-SqlDscRSService' {
    Context 'When validating parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = 'ByServiceName'
                ExpectedParameters = '[-ServiceName] <string> [[-WaitTime] <uint16>] [-PassThru] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
            @{
                ExpectedParameterSetName = 'ByConfiguration'
                ExpectedParameters = '[-Configuration] <Object> [[-WaitTime] <uint16>] [-PassThru] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Restart-SqlDscRSService').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }
    }

    Context 'When restarting service using ServiceName parameter' {
        BeforeAll {
            $mockServiceName = 'SQLServerReportingServices'

            Mock -CommandName Get-Service -MockWith {
                return [PSCustomObject] @{
                    Name              = $mockServiceName
                    DisplayName       = 'SQL Server Reporting Services'
                    Status            = 'Running'
                    DependentServices = @()
                }
            }

            Mock -CommandName Stop-Service
            Mock -CommandName Start-Service
            Mock -CommandName Start-Sleep
        }

        It 'Should restart the service without errors' {
            { Restart-SqlDscRSService -ServiceName $mockServiceName -Confirm:$false } | Should -Not -Throw

            Should -Invoke -CommandName Get-Service -ParameterFilter {
                $Name -eq $mockServiceName
            } -Exactly -Times 1

            Should -Invoke -CommandName Stop-Service -Exactly -Times 1
            Should -Invoke -CommandName Start-Service -Exactly -Times 1
        }

        It 'Should not return anything by default' {
            $result = Restart-SqlDscRSService -ServiceName $mockServiceName -Confirm:$false

            $result | Should -BeNullOrEmpty
        }

        It 'Should not wait when WaitTime is 0' {
            Restart-SqlDscRSService -ServiceName $mockServiceName -WaitTime 0 -Confirm:$false

            Should -Invoke -CommandName Start-Sleep -Exactly -Times 0
        }

        It 'Should wait when WaitTime is specified' {
            Restart-SqlDscRSService -ServiceName $mockServiceName -WaitTime 30 -Confirm:$false

            Should -Invoke -CommandName Start-Sleep -ParameterFilter {
                $Seconds -eq 30
            } -Exactly -Times 1
        }
    }

    Context 'When restarting service using Configuration parameter' {
        BeforeAll {
            $mockServiceName = 'SQLServerReportingServices'

            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
                ServiceName  = $mockServiceName
            }

            Mock -CommandName Get-Service -MockWith {
                return [PSCustomObject] @{
                    Name              = $mockServiceName
                    DisplayName       = 'SQL Server Reporting Services'
                    Status            = 'Running'
                    DependentServices = @()
                }
            }

            Mock -CommandName Stop-Service
            Mock -CommandName Start-Service
        }

        It 'Should restart the service using the ServiceName from configuration' {
            { $mockCimInstance | Restart-SqlDscRSService -Confirm:$false } | Should -Not -Throw

            Should -Invoke -CommandName Get-Service -ParameterFilter {
                $Name -eq $mockServiceName
            } -Exactly -Times 1

            Should -Invoke -CommandName Stop-Service -Exactly -Times 1
            Should -Invoke -CommandName Start-Service -Exactly -Times 1
        }

        It 'Should not return anything by default' {
            $result = $mockCimInstance | Restart-SqlDscRSService -Confirm:$false

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'When using PassThru with Configuration parameter' {
        BeforeAll {
            $mockServiceName = 'SQLServerReportingServices'

            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
                ServiceName  = $mockServiceName
            }

            Mock -CommandName Get-Service -MockWith {
                return [PSCustomObject] @{
                    Name              = $mockServiceName
                    DisplayName       = 'SQL Server Reporting Services'
                    Status            = 'Running'
                    DependentServices = @()
                }
            }

            Mock -CommandName Stop-Service
            Mock -CommandName Start-Service
        }

        It 'Should return the configuration CIM instance' {
            $result = $mockCimInstance | Restart-SqlDscRSService -PassThru -Confirm:$false

            $result | Should -Not -BeNullOrEmpty
            $result.InstanceName | Should -Be 'SSRS'
            $result.ServiceName | Should -Be $mockServiceName
        }
    }

    Context 'When using PassThru with ServiceName parameter' {
        BeforeAll {
            $mockServiceName = 'SQLServerReportingServices'

            Mock -CommandName Get-Service -MockWith {
                return [PSCustomObject] @{
                    Name              = $mockServiceName
                    DisplayName       = 'SQL Server Reporting Services'
                    Status            = 'Running'
                    DependentServices = @()
                }
            }

            Mock -CommandName Stop-Service
            Mock -CommandName Start-Service
        }

        It 'Should not return anything when using ServiceName parameter' {
            $result = Restart-SqlDscRSService -ServiceName $mockServiceName -PassThru -Confirm:$false

            # PassThru only works with Configuration parameter
            $result | Should -BeNullOrEmpty
        }
    }

    Context 'When using Force' {
        BeforeAll {
            $mockServiceName = 'SQLServerReportingServices'

            Mock -CommandName Get-Service -MockWith {
                return [PSCustomObject] @{
                    Name              = $mockServiceName
                    DisplayName       = 'SQL Server Reporting Services'
                    Status            = 'Running'
                    DependentServices = @()
                }
            }

            Mock -CommandName Stop-Service
            Mock -CommandName Start-Service
        }

        It 'Should restart service without confirmation' {
            { Restart-SqlDscRSService -ServiceName $mockServiceName -Force } | Should -Not -Throw

            Should -Invoke -CommandName Stop-Service -Exactly -Times 1
            Should -Invoke -CommandName Start-Service -Exactly -Times 1
        }
    }

    Context 'When there are dependent services' {
        BeforeAll {
            $mockServiceName = 'SQLServerReportingServices'

            $mockDependentService = [PSCustomObject] @{
                Name        = 'DependentService'
                DisplayName = 'Dependent Service'
                Status      = 'Running'
            }

            Mock -CommandName Get-Service -MockWith {
                return [PSCustomObject] @{
                    Name              = $mockServiceName
                    DisplayName       = 'SQL Server Reporting Services'
                    Status            = 'Running'
                    DependentServices = @($mockDependentService)
                }
            }

            Mock -CommandName Stop-Service
            Mock -CommandName Start-Service
        }

        It 'Should restart the main service and dependent services' {
            { Restart-SqlDscRSService -ServiceName $mockServiceName -Confirm:$false } | Should -Not -Throw

            # Main service restart + dependent service restart
            Should -Invoke -CommandName Start-Service -Exactly -Times 2
        }
    }

    Context 'When dependent service is not running' {
        BeforeAll {
            $mockServiceName = 'SQLServerReportingServices'

            $mockDependentService = [PSCustomObject] @{
                Name        = 'DependentService'
                DisplayName = 'Dependent Service'
                Status      = 'Stopped'
            }

            Mock -CommandName Get-Service -MockWith {
                return [PSCustomObject] @{
                    Name              = $mockServiceName
                    DisplayName       = 'SQL Server Reporting Services'
                    Status            = 'Running'
                    DependentServices = @($mockDependentService)
                }
            }

            Mock -CommandName Stop-Service
            Mock -CommandName Start-Service
        }

        It 'Should not restart stopped dependent services' {
            { Restart-SqlDscRSService -ServiceName $mockServiceName -Confirm:$false } | Should -Not -Throw

            # Only main service restart, not the stopped dependent service
            Should -Invoke -CommandName Start-Service -Exactly -Times 1
        }
    }

    Context 'When using WhatIf' {
        BeforeAll {
            $mockServiceName = 'SQLServerReportingServices'

            Mock -CommandName Get-Service -MockWith {
                return [PSCustomObject] @{
                    Name              = $mockServiceName
                    DisplayName       = 'SQL Server Reporting Services'
                    Status            = 'Running'
                    DependentServices = @()
                }
            }

            Mock -CommandName Stop-Service
            Mock -CommandName Start-Service
        }

        It 'Should not call Stop-Service or Start-Service' {
            Restart-SqlDscRSService -ServiceName $mockServiceName -WhatIf

            Should -Invoke -CommandName Stop-Service -Exactly -Times 0
            Should -Invoke -CommandName Start-Service -Exactly -Times 0
        }
    }
}
