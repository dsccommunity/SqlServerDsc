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

Describe 'Get-SqlDscRSLogPath' {
    Context 'When parameter validation' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = 'ByInstanceName'
                ExpectedParameters = '-InstanceName <string> [<CommonParameters>]'
            }
            @{
                ExpectedParameterSetName = 'ByConfiguration'
                ExpectedParameters = '-Configuration <Object> [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Get-SqlDscRSLogPath').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }

        It 'Should have InstanceName as a mandatory parameter in the ByInstanceName parameter set' {
            $parameterInfo = (Get-Command -Name 'Get-SqlDscRSLogPath').Parameters['InstanceName']

            $parameterInfo.Attributes.Where({$_.ParameterSetName -eq 'ByInstanceName'}).Mandatory | Should -BeTrue
        }

        It 'Should have Configuration as a mandatory parameter in the ByConfiguration parameter set' {
            $parameterInfo = (Get-Command -Name 'Get-SqlDscRSLogPath').Parameters['Configuration']

            $parameterInfo.Attributes.Where({$_.ParameterSetName -eq 'ByConfiguration'}).Mandatory | Should -BeTrue
        }

        It 'Should accept Configuration parameter from pipeline' {
            $parameterInfo = (Get-Command -Name 'Get-SqlDscRSLogPath').Parameters['Configuration']

            $parameterInfo.Attributes.ValueFromPipeline | Should -Contain $true
        }
    }

    Context 'When the Reporting Services instance is found' {
        BeforeAll {
            $mockLogPath = 'C:\Program Files\SSRS\SSRS\LogFiles'

            Mock -CommandName Get-SqlDscRSSetupConfiguration -MockWith {
                return [PSCustomObject]@{
                    InstanceName       = 'SSRS'
                    InstallFolder      = 'C:\Program Files\SSRS'
                    ErrorDumpDirectory = $mockLogPath
                    ServiceName        = 'SQLServerReportingServices'
                }
            }
        }

        It 'Should return the log file path' {
            $result = Get-SqlDscRSLogPath -InstanceName 'SSRS'

            $result | Should -Be $mockLogPath

            Should -Invoke -CommandName Get-SqlDscRSSetupConfiguration -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the Reporting Services instance is not found' {
        BeforeAll {
            Mock -CommandName Get-SqlDscRSSetupConfiguration -MockWith {
                return $null
            }
        }

        It 'Should throw a terminating error' {
            { Get-SqlDscRSLogPath -InstanceName 'NonExistent' } | Should -Throw -ErrorId 'GSRSLP0001*'

            Should -Invoke -CommandName Get-SqlDscRSSetupConfiguration -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the ErrorDumpDirectory is empty' {
        BeforeAll {
            Mock -CommandName Get-SqlDscRSSetupConfiguration -MockWith {
                return [PSCustomObject]@{
                    InstanceName       = 'SSRS'
                    InstallFolder      = 'C:\Program Files\SSRS'
                    ErrorDumpDirectory = $null
                    ServiceName        = 'SQLServerReportingServices'
                }
            }
        }

        It 'Should throw a terminating error' {
            { Get-SqlDscRSLogPath -InstanceName 'SSRS' } | Should -Throw -ErrorId 'GSRSLP0002*'

            Should -Invoke -CommandName Get-SqlDscRSSetupConfiguration -Exactly -Times 1 -Scope It
        }
    }

    Context 'When getting log path for Power BI Report Server' {
        # cSpell: ignore PBIRS
        BeforeAll {
            $mockLogPath = 'C:\Program Files\PBIRS\PBIRS\LogFiles'

            Mock -CommandName Get-SqlDscRSSetupConfiguration -MockWith {
                return [PSCustomObject]@{
                    InstanceName       = 'PBIRS'
                    InstallFolder      = 'C:\Program Files\PBIRS'
                    ErrorDumpDirectory = $mockLogPath
                    ServiceName        = 'PowerBIReportServer'
                }
            }
        }

        It 'Should return the log file path for PBIRS' {
            $result = Get-SqlDscRSLogPath -InstanceName 'PBIRS'

            $result | Should -Be $mockLogPath

            Should -Invoke -CommandName Get-SqlDscRSSetupConfiguration -Exactly -Times 1 -Scope It
        }
    }

    Context 'When passing configuration via pipeline' {
        BeforeAll {
            $mockLogPath = 'C:\Program Files\SSRS\SSRS\LogFiles'

            $mockConfiguration = [PSCustomObject]@{
                InstanceName       = 'SSRS'
                InstallFolder      = 'C:\Program Files\SSRS'
                ErrorDumpDirectory = $mockLogPath
                ServiceName        = 'SQLServerReportingServices'
            }

            Mock -CommandName Get-SqlDscRSSetupConfiguration -MockWith {
                return [PSCustomObject]@{
                    InstanceName       = 'SSRS'
                    InstallFolder      = 'C:\Program Files\SSRS'
                    ErrorDumpDirectory = $mockLogPath
                    ServiceName        = 'SQLServerReportingServices'
                }
            }
        }

        It 'Should return the log file path when piping configuration' {
            $result = $mockConfiguration | Get-SqlDscRSLogPath

            $result | Should -Be $mockLogPath

            Should -Invoke -CommandName Get-SqlDscRSSetupConfiguration -Exactly -Times 1 -Scope It
        }

        It 'Should work with Configuration parameter passed directly' {
            $result = Get-SqlDscRSLogPath -Configuration $mockConfiguration

            $result | Should -Be $mockLogPath

            Should -Invoke -CommandName Get-SqlDscRSSetupConfiguration -Exactly -Times 1 -Scope It
        }
    }
}
