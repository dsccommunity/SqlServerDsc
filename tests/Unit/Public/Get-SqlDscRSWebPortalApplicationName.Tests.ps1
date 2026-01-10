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

Describe 'Get-SqlDscRSWebPortalApplicationName' {
    Context 'When validating parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = '__AllParameterSets'
                ExpectedParameters = '[-SetupConfiguration] <Object> [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Get-SqlDscRSWebPortalApplicationName').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }
    }

    Context 'When SQL Server version is 2016 (version 13) or later' {
        BeforeAll {
            Mock -CommandName Get-SqlDscRSVersion
        }

        It 'Should return ReportServerWebApp for SQL Server 2016 (version 13)' {
            Mock -CommandName Get-SqlDscRSVersion -MockWith {
                return [System.Version] '13.0.4001.0'
            }

            $mockSetupConfiguration = @{
                InstanceName = 'SSRS'
            }

            $result = $mockSetupConfiguration | Get-SqlDscRSWebPortalApplicationName

            $result | Should -Be 'ReportServerWebApp'
        }

        It 'Should return ReportServerWebApp for SQL Server 2017 (version 14)' {
            Mock -CommandName Get-SqlDscRSVersion -MockWith {
                return [System.Version] '14.0.600.0'
            }

            $mockSetupConfiguration = @{
                InstanceName = 'SSRS'
            }

            $result = $mockSetupConfiguration | Get-SqlDscRSWebPortalApplicationName

            $result | Should -Be 'ReportServerWebApp'
        }

        It 'Should return ReportServerWebApp for SQL Server 2019 (version 15)' {
            Mock -CommandName Get-SqlDscRSVersion -MockWith {
                return [System.Version] '15.0.1100.0'
            }

            $mockSetupConfiguration = @{
                InstanceName = 'SSRS'
            }

            $result = $mockSetupConfiguration | Get-SqlDscRSWebPortalApplicationName

            $result | Should -Be 'ReportServerWebApp'
        }

        It 'Should return ReportServerWebApp for SQL Server 2022 (version 16)' {
            Mock -CommandName Get-SqlDscRSVersion -MockWith {
                return [System.Version] '16.0.1000.0'
            }

            $mockSetupConfiguration = @{
                InstanceName = 'SSRS'
            }

            $result = $mockSetupConfiguration | Get-SqlDscRSWebPortalApplicationName

            $result | Should -Be 'ReportServerWebApp'
        }
    }

    Context 'When SQL Server version is earlier than 2016 (version 12 and below)' {
        BeforeAll {
            Mock -CommandName Get-SqlDscRSVersion
        }

        It 'Should return ReportManager for SQL Server 2014 (version 12)' {
            Mock -CommandName Get-SqlDscRSVersion -MockWith {
                return [System.Version] '12.0.4100.0'
            }

            $mockSetupConfiguration = @{
                InstanceName = 'SSRS'
            }

            $result = $mockSetupConfiguration | Get-SqlDscRSWebPortalApplicationName

            $result | Should -Be 'ReportManager'
        }

        It 'Should return ReportManager for SQL Server 2012 (version 11)' {
            Mock -CommandName Get-SqlDscRSVersion -MockWith {
                return [System.Version] '11.0.5000.0'
            }

            $mockSetupConfiguration = @{
                InstanceName = 'SSRS'
            }

            $result = $mockSetupConfiguration | Get-SqlDscRSWebPortalApplicationName

            $result | Should -Be 'ReportManager'
        }
    }

    Context 'When Get-SqlDscRSVersion returns null' {
        BeforeAll {
            Mock -CommandName Get-SqlDscRSVersion
        }

        It 'Should return null when Get-SqlDscRSVersion returns null' {
            $mockSetupConfiguration = @{
                InstanceName = 'SSRS'
            }

            $result = $mockSetupConfiguration | Get-SqlDscRSWebPortalApplicationName

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'When using parameter instead of pipeline input' {
        BeforeAll {
            Mock -CommandName Get-SqlDscRSVersion -MockWith {
                return [System.Version] '15.0.1100.0'
            }
        }

        It 'Should return the correct application name when SetupConfiguration is passed as parameter' {
            $mockSetupConfiguration = @{
                InstanceName = 'SSRS'
            }

            $result = Get-SqlDscRSWebPortalApplicationName -SetupConfiguration $mockSetupConfiguration

            $result | Should -Be 'ReportServerWebApp'
        }
    }
}
