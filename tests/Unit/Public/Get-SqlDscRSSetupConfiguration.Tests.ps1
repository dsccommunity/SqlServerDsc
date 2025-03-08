[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies has been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies has not been resolved, this will throw an error.
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

    Import-Module -Name $script:dscModuleName

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

Describe 'Get-SqlDscRSSetupConfiguration' {
    Context 'When getting all Reporting Services instances' {
        # cSpell: ignore PBIRS rsreportserver
        BeforeAll {
            # Mock instance objects
            $mockSSRSInstance = @{
                InstanceName = 'SSRS'
                ServiceName = 'ReportServer'
            }

            # Mock instance objects
            $mockPBIRSInstance = @{
                InstanceName = 'PBIRS'
                ServiceName = 'PowerBIReportServer'
            }

            # Mock registry values
            $mockInstallFolder = 'C:\Program Files\Microsoft SQL Server Reporting Services'
            $mockServiceName = 'SQLServerReportingServices'
            $mockVirtualRootServer = 'ReportServer'
            $mockConfigFilePath = 'C:\Program Files\Microsoft SQL Server Reporting Services\SSRS\ReportServer\rsreportserver.config'
            $mockErrorDumpDirectory = 'C:\Program Files\Microsoft SQL Server Reporting Services\SSRS\LogFiles'
            $mockCustomerFeedback = 0
            $mockEnableErrorReporting = 0
            $mockCurrentVersion = '15.0.1.0'
            $mockProductVersion = '15.0.1.0'

            Mock -CommandName Get-SqlDscInstalledInstance -MockWith {
                return @($mockSSRSInstance, $mockPBIRSInstance)
            }

            Mock -CommandName Get-ItemPropertyValue -ParameterFilter {
                $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\SSRS\Setup' -and
                $Name -eq 'InstallRootDirectory'
            } -MockWith {
                return $mockInstallFolder
            }

            Mock -CommandName Get-ItemPropertyValue -ParameterFilter {
                $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\SSRS\Setup' -and
                $Name -eq 'ServiceName'
            } -MockWith {
                return $mockServiceName
            }

            Mock -CommandName Get-ItemPropertyValue -ParameterFilter {
                $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\SSRS\Setup' -and
                $Name -eq 'RSVirtualRootServer'
            } -MockWith {
                return $mockVirtualRootServer
            }

            Mock -CommandName Get-ItemPropertyValue -ParameterFilter {
                $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\SSRS\Setup' -and
                $Name -eq 'RsConfigFilePath'
            } -MockWith {
                return $mockConfigFilePath
            }

            Mock -CommandName Get-ItemPropertyValue -ParameterFilter {
                $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\SSRS\CPE' -and
                $Name -eq 'ErrorDumpDir'
            } -MockWith {
                return $mockErrorDumpDirectory
            }

            Mock -CommandName Get-ItemPropertyValue -ParameterFilter {
                $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\SSRS\CPE' -and
                $Name -eq 'CustomerFeedback'
            } -MockWith {
                return $mockCustomerFeedback
            }

            Mock -CommandName Get-ItemPropertyValue -ParameterFilter {
                $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\SSRS\CPE' -and
                $Name -eq 'EnableErrorReporting'
            } -MockWith {
                return $mockEnableErrorReporting
            }

            Mock -CommandName Get-ItemPropertyValue -ParameterFilter {
                $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\SSRS\MSSQLServer\CurrentVersion' -and
                $Name -eq 'CurrentVersion'
            } -MockWith {
                return $mockCurrentVersion
            }

            Mock -CommandName Get-ItemPropertyValue -ParameterFilter {
                $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\SSRS\MSSQLServer\CurrentVersion' -and
                $Name -eq 'ProductVersion'
            } -MockWith {
                return $mockProductVersion
            }
        }

        It 'Should return all Reporting Services instances' {
            # Execute the command
            $result = Get-SqlDscRSSetupConfiguration

            $result | Should -HaveCount 2

            $result[0].InstanceName | Should -Be $mockSSRSInstance.InstanceName
            $result[0].InstallFolder | Should -Be $mockInstallFolder
            $result[0].ServiceName | Should -Be $mockServiceName
            $result[0].VirtualRootServer | Should -Be $mockVirtualRootServer
            $result[0].ConfigFilePath | Should -Be $mockConfigFilePath
            $result[0].ErrorDumpDirectory | Should -Be $mockErrorDumpDirectory
            $result[0].CustomerFeedback | Should -Be $mockCustomerFeedback
            $result[0].EnableErrorReporting | Should -Be $mockEnableErrorReporting
            $result[0].CurrentVersion | Should -Be $mockCurrentVersion
            $result[0].ProductVersion | Should -Be $mockProductVersion

            $result[1].InstanceName | Should -Be $mockPBIRSInstance.InstanceName
            $result[1].InstallFolder | Should -Be $mockInstallFolder
            $result[1].ServiceName | Should -Be $mockServiceName
            $result[1].VirtualRootServer | Should -Be $mockVirtualRootServer
            $result[1].ConfigFilePath | Should -Be $mockConfigFilePath
            $result[1].ErrorDumpDirectory | Should -Be $mockErrorDumpDirectory
            $result[1].CustomerFeedback | Should -Be $mockCustomerFeedback
            $result[1].EnableErrorReporting | Should -Be $mockEnableErrorReporting
            $result[1].CurrentVersion | Should -Be $mockCurrentVersion
            $result[1].ProductVersion | Should -Be $mockProductVersion

            Should -Invoke -CommandName Get-SqlDscInstalledInstance -ParameterFilter {
                $ServiceType -eq 'ReportingServices' -and
                -not $PSBoundParameters.ContainsKey('InstanceName')
            } -Exactly -Times 1

            Should -Invoke -CommandName Get-ItemPropertyValue -Exactly -Times 18
        }
    }

    Context 'When getting a specific Reporting Services instance' {
        BeforeAll {
            # Mock instance objects
            $mockSSRSInstance = @{
                InstanceName = 'SSRS'
                ServiceName = 'ReportServer'
            }

            # Mock registry values
            $mockInstallFolder = 'C:\Program Files\Microsoft SQL Server Reporting Services'

            Mock -CommandName Get-SqlDscInstalledInstance -MockWith {
                return @($mockSSRSInstance)
            }

            Mock -CommandName Get-ItemPropertyValue -MockWith {
                return $mockInstallFolder
            }
        }

        It 'Should return the correct instance' {
            $result = Get-SqlDscRSSetupConfiguration -InstanceName 'SSRS'

            $result.InstanceName | Should -Be 'SSRS'

            Should -Invoke -CommandName Get-SqlDscInstalledInstance -ParameterFilter {
                $ServiceType -eq 'ReportingServices' -and
                $InstanceName -eq 'SSRS'
            } -Exactly -Times 1

            Should -Invoke -CommandName Get-ItemPropertyValue -Exactly -Times 9
        }
    }

    Context 'When no instances are found' {
        Context 'When no instance name is specified' {
            BeforeAll {
                Mock -CommandName Get-SqlDscInstalledInstance -MockWith {
                    return @()
                }
            }

            It 'Should return an empty array' {
                $result = Get-SqlDscRSSetupConfiguration

                $result | Should -BeNullOrEmpty
            }
        }

        Context 'When a specific instance name is specified but not found' {
            BeforeAll {
                Mock -CommandName Get-SqlDscInstalledInstance -MockWith {
                    return @()
                }
            }

            It 'Should return an empty array' {
                # Execute the command
                $result = Get-SqlDscRSSetupConfiguration -InstanceName 'NonExistentInstance'

                $result | Should -BeNullOrEmpty
            }
        }
    }

    Context 'When registry values cannot be retrieved' {
        BeforeAll {
            # Mock instance objects
            $mockSSRSInstance = @{
                InstanceName = 'SSRS'
                ServiceName = 'ReportServer'
            }

            Mock -CommandName Get-SqlDscInstalledInstance -MockWith {
                return @($mockSSRSInstance)
            }

            # Mock a scenario where registry values cannot be retrieved
            Mock -CommandName Get-ItemPropertyValue -MockWith {
                return $null
            }
        }

        It 'Should return null for registry values' {
            $result = Get-SqlDscRSSetupConfiguration -InstanceName 'SSRS'

            $result | Should -Not -BeNullOrEmpty
            $result.InstanceName | Should -Be 'SSRS'
            $result.InstallFolder | Should -BeNullOrEmpty
            $result.ServiceName | Should -BeNullOrEmpty
            $result.VirtualRootServer | Should -BeNullOrEmpty
            $result.ConfigFilePath | Should -BeNullOrEmpty
            $result.ErrorDumpDirectory | Should -BeNullOrEmpty
            $result.CustomerFeedback | Should -BeNullOrEmpty
            $result.EnableErrorReporting | Should -BeNullOrEmpty
            $result.CurrentVersion | Should -BeNullOrEmpty
            $result.ProductVersion | Should -BeNullOrEmpty
        }
    }
}
