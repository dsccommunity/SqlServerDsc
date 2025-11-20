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
    $script:dscModuleName = 'SqlServerDsc'

    $env:SqlServerDscCI = $true

    Import-Module -Name $script:dscModuleName -Force -ErrorAction 'Stop'

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
    BeforeAll {
        InModuleScope -ScriptBlock {
            function script:Get-CimInstance
            {
                param
                (
                    [System.String]
                    $ClassName,

                    [System.String]
                    $Namespace
                )

                $PSCmdlet.ThrowTerminatingError(
                    [System.Management.Automation.ErrorRecord]::new(
                        'StubNotImplemented',
                        'StubCalledError',
                        [System.Management.Automation.ErrorCategory]::InvalidOperation,
                        $MyInvocation.MyCommand
                    )
                )

            }
        }
    }

    AfterAll {
        InModuleScope -ScriptBlock {
            Remove-Item -Path 'function:script:Get-CimInstance' -Force
        }
    }

    Context 'When getting all Reporting Services instances' {
        # cSpell: ignore PBIRS rsreportserver
        BeforeAll {
            # Mock instance objects
            $mockSSRSInstance = @{
                InstanceName = 'SSRS'
                InstanceId   = 'SSRS'
                ServiceName  = 'ReportServer'
            }

            # Mock instance objects
            $mockPBIRSInstance = @{
                InstanceName = 'PBIRS'
                InstanceId   = 'PBIRS'
                ServiceName  = 'PowerBIReportServer'
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

            Mock -CommandName Get-RegistryPropertyValue -ParameterFilter {
                (
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\SSRS\Setup' -or
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\PBIRS\Setup'
                ) -and
                $Name -eq 'InstallRootDirectory'
            } -MockWith {
                return $mockInstallFolder
            }

            Mock -CommandName Get-RegistryPropertyValue -ParameterFilter {
                (
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\SSRS\Setup' -or
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\PBIRS\Setup'
                ) -and
                $Name -eq 'ServiceName'
            } -MockWith {
                return $mockServiceName
            }

            Mock -CommandName Get-RegistryPropertyValue -ParameterFilter {
                (
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\SSRS\Setup' -or
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\PBIRS\Setup'
                ) -and
                $Name -eq 'RSVirtualRootServer'
            } -MockWith {
                return $mockVirtualRootServer
            }

            Mock -CommandName Get-RegistryPropertyValue -ParameterFilter {
                (
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\SSRS\Setup' -or
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\PBIRS\Setup'
                ) -and
                $Name -eq 'RsConfigFilePath'
            } -MockWith {
                return $mockConfigFilePath
            }

            Mock -CommandName Get-RegistryPropertyValue -ParameterFilter {
                (
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\SSRS\CPE' -or
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\PBIRS\CPE'
                ) -and
                $Name -eq 'ErrorDumpDir'
            } -MockWith {
                return $mockErrorDumpDirectory
            }

            Mock -CommandName Get-RegistryPropertyValue -ParameterFilter {
                (
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\SSRS\CPE' -or
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\PBIRS\CPE'
                ) -and
                $Name -eq 'CustomerFeedback'
            } -MockWith {
                return $mockCustomerFeedback
            }

            Mock -CommandName Get-RegistryPropertyValue -ParameterFilter {
                (
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\SSRS\CPE' -or
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\PBIRS\CPE'
                ) -and
                $Name -eq 'EnableErrorReporting'
            } -MockWith {
                return $mockEnableErrorReporting
            }

            Mock -CommandName Get-RegistryPropertyValue -ParameterFilter {
                (
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\SSRS\MSSQLServer\CurrentVersion' -or
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\PBIRS\MSSQLServer\CurrentVersion'
                ) -and
                $Name -eq 'CurrentVersion'
            } -MockWith {
                return $mockCurrentVersion
            }

            Mock -CommandName Get-RegistryPropertyValue -ParameterFilter {
                (
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\SSRS\MSSQLServer\CurrentVersion' -or
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\PBIRS\MSSQLServer\CurrentVersion'
                ) -and
                $Name -eq 'ProductVersion'
            } -MockWith {
                return $mockProductVersion
            }

            Mock -CommandName Get-CimInstance -ParameterFilter {
                $Namespace -eq 'root\Microsoft\SqlServer\ReportServer\RS_SSRS\v15'
            } -MockWith {
                return [PSCustomObject] @{
                    EditionID              = 2176971986
                    EditionName            = 'SQL Server Developer'
                    IsSharePointIntegrated = $false
                    InstanceId             = 'SSRS'
                }
            }
            Mock -CommandName Get-CimInstance -ParameterFilter {
                $Namespace -eq 'root\Microsoft\SqlServer\ReportServer\RS_PBIRS\v15'
            } -MockWith {
                return [PSCustomObject] @{
                    EditionID              = 2176971986
                    EditionName            = 'SQL Server Developer'
                    IsSharePointIntegrated = $false
                    InstanceId             = 'PBIRS'
                }
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
            $result[0].EditionID | Should -Be 2176971986
            $result[0].EditionName | Should -Be 'SQL Server Developer'
            $result[0].IsSharePointIntegrated | Should -BeFalse
            $result[0].InstanceId | Should -Be 'SSRS'

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
            $result[1].EditionID | Should -Be 2176971986
            $result[1].EditionName | Should -Be 'SQL Server Developer'
            $result[1].IsSharePointIntegrated | Should -BeFalse
            $result[1].InstanceId | Should -Be 'PBIRS'

            Should -Invoke -CommandName Get-SqlDscInstalledInstance -ParameterFilter {
                $ServiceType -eq 'ReportingServices' -and
                -not $PSBoundParameters.ContainsKey('InstanceName')
            } -Exactly -Times 1

            Should -Invoke -CommandName Get-RegistryPropertyValue -Exactly -Times 18
        }
    }

    Context 'When getting a specific Reporting Services instance' {
        BeforeAll {
            # Mock instance objects
            $mockSSRSInstance = @{
                InstanceName   = 'SSRS'
                InstanceId     = 'SSRS'
                ServiceName    = 'ReportServer'
                CurrentVersion = '15.0.1.0'
            }

            # Mock registry values
            #$mockInstallFolder = 'C:\Program Files\Microsoft SQL Server Reporting Services'

            Mock -CommandName Get-SqlDscInstalledInstance -MockWith {
                return @($mockSSRSInstance)
            }

            Mock -CommandName Get-RegistryPropertyValue
            Mock -CommandName Get-RegistryPropertyValue -ParameterFilter {
                $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\SSRS\MSSQLServer\CurrentVersion' -and
                $Name -eq 'CurrentVersion'
            } -MockWith {
                return '15.0.1.0'
            }

            Mock -CommandName Get-CimInstance -MockWith {
                return [PSCustomObject] @{
                    EditionID              = 2176971986
                    EditionName            = 'SQL Server Developer'
                    IsSharePointIntegrated = $false
                    Version                = '15.0.1.0'
                    InstanceId             = 'SSRS'
                }
            }
        }

        It 'Should return the correct instance' {
            $result = Get-SqlDscRSSetupConfiguration -InstanceName 'SSRS'

            $result.InstanceName | Should -Be 'SSRS'

            Should -Invoke -CommandName Get-SqlDscInstalledInstance -ParameterFilter {
                $ServiceType -eq 'ReportingServices' -and
                $InstanceName -eq 'SSRS'
            } -Exactly -Times 1

            Should -Invoke -CommandName Get-RegistryPropertyValue -Exactly -Times 10
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
                InstanceId   = 'SSRS'
                ServiceName  = 'ReportServer'
            }

            Mock -CommandName Get-SqlDscInstalledInstance -MockWith {
                return @($mockSSRSInstance)
            }

            # Mock a scenario where registry values cannot be retrieved
            Mock -CommandName Get-RegistryPropertyValue -MockWith {
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
            $result.InstanceId | Should -Be 'SSRS'
        }
    }

    Context 'When getting SSRS 2016 instance where InstanceName differs from InstanceId' {
        BeforeAll {
            # Mock SSRS 2016 instance where InstanceName = "MSSQLSERVER" but InstanceId = "MSRS13.MSSQLSERVER"
            $mockSSRS2016Instance = @{
                InstanceName = 'MSSQLSERVER'
                InstanceId   = 'MSRS13.MSSQLSERVER'
                ServiceName  = 'ReportServer'
            }

            # Mock registry values
            $mockSQLPath = 'C:\Program Files\Microsoft SQL Server\MSRS13.MSSQLSERVER\Reporting Services\'
            $mockServiceName = $null
            $mockVirtualRootServer = 'ReportServer'
            $mockConfigFilePath = $null
            $mockErrorDumpDirectory = $null
            $mockProductVersion = $null
            $mockCustomerFeedback = 1
            $mockEnableErrorReporting = 1
            $mockCurrentVersion = '13.0.6404.1'

            Mock -CommandName Get-SqlDscInstalledInstance -MockWith {
                return @($mockSSRS2016Instance)
            }

            Mock -CommandName Get-RegistryPropertyValue -ParameterFilter {
                $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSRS13.MSSQLSERVER\Setup' -and
                $Name -eq 'InstallRootDirectory'
            } -MockWith {
                return $null
            }

            Mock -CommandName Get-RegistryPropertyValue -ParameterFilter {
                $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSRS13.MSSQLSERVER\Setup' -and
                $Name -eq 'SQLPath'
            } -MockWith {
                return $mockSQLPath
            }

            Mock -CommandName Get-RegistryPropertyValue -ParameterFilter {
                $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSRS13.MSSQLSERVER\Setup' -and
                $Name -eq 'ServiceName'
            } -MockWith {
                return $mockServiceName
            }

            Mock -CommandName Get-RegistryPropertyValue -ParameterFilter {
                $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSRS13.MSSQLSERVER\Setup' -and
                $Name -eq 'RSVirtualRootServer'
            } -MockWith {
                return $mockVirtualRootServer
            }

            Mock -CommandName Get-RegistryPropertyValue -ParameterFilter {
                $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSRS13.MSSQLSERVER\Setup' -and
                $Name -eq 'RsConfigFilePath'
            } -MockWith {
                return $mockConfigFilePath
            }

            Mock -CommandName Get-RegistryPropertyValue -ParameterFilter {
                $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSRS13.MSSQLSERVER\CPE' -and
                $Name -eq 'ErrorDumpDir'
            } -MockWith {
                return $mockErrorDumpDirectory
            }

            Mock -CommandName Get-RegistryPropertyValue -ParameterFilter {
                $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSRS13.MSSQLSERVER\CPE' -and
                $Name -eq 'CustomerFeedback'
            } -MockWith {
                return $mockCustomerFeedback
            }

            Mock -CommandName Get-RegistryPropertyValue -ParameterFilter {
                $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSRS13.MSSQLSERVER\CPE' -and
                $Name -eq 'EnableErrorReporting'
            } -MockWith {
                return $mockEnableErrorReporting
            }

            Mock -CommandName Get-RegistryPropertyValue -ParameterFilter {
                $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSRS13.MSSQLSERVER\MSSQLServer\CurrentVersion' -and
                $Name -eq 'CurrentVersion'
            } -MockWith {
                return $mockCurrentVersion
            }

            Mock -CommandName Get-RegistryPropertyValue -ParameterFilter {
                $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSRS13.MSSQLSERVER\MSSQLServer\CurrentVersion' -and
                $Name -eq 'ProductVersion'
            } -MockWith {
                return $mockProductVersion
            }

            Mock -CommandName Get-CimInstance -MockWith {
                return @(
                    [PSCustomObject] @{
                        EditionID              = 610778273
                        EditionName            = 'SQL Server Developer'
                        IsSharePointIntegrated = $false
                        InstanceId             = 'MSRS13.MSSQLSERVER'
                    }
                )
            }
        }

        It 'Should use InstanceId in registry paths and return correct configuration' {
            $result = Get-SqlDscRSSetupConfiguration -InstanceName 'MSSQLSERVER'

            $result | Should -Not -BeNullOrEmpty
            $result.InstanceName | Should -Be 'MSSQLSERVER'
            $result.InstanceId | Should -Be 'MSRS13.MSSQLSERVER'
            $result.InstallFolder | Should -Be $mockSQLPath.TrimEnd('\')
            $result.ServiceName | Should -Be $mockServiceName
            $result.VirtualRootServer | Should -Be $mockVirtualRootServer
            $result.ConfigFilePath | Should -Be $mockConfigFilePath
            $result.ErrorDumpDirectory | Should -Be $mockErrorDumpDirectory
            $result.CustomerFeedback | Should -Be $mockCustomerFeedback
            $result.EnableErrorReporting | Should -Be $mockEnableErrorReporting
            $result.CurrentVersion | Should -Be $mockCurrentVersion
            $result.ProductVersion | Should -Be $mockProductVersion
            $result.EditionID | Should -Be 610778273
            $result.EditionName | Should -Be 'SQL Server Developer'
            $result.IsSharePointIntegrated | Should -BeFalse

            # Verify that registry paths used InstanceId, not InstanceName
            Should -Invoke -CommandName Get-RegistryPropertyValue -ParameterFilter {
                $Path -like 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSRS13.MSSQLSERVER*'
            } -Exactly -Times 10

            Should -Invoke -CommandName Get-RegistryPropertyValue -ParameterFilter {
                $Path -like 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQLSERVER*'
            } -Exactly -Times 0
        }
    }

    Context 'When getting SSRS 2016 instance installed to the drive root' {
        BeforeAll {
            $mockSSRS2016Instance = @{
                InstanceName = 'MSSQLSERVER'
                InstanceId   = 'MSRS13.MSSQLSERVER'
                ServiceName  = 'ReportServer'
            }

            # Mock registry values
            $mockSQLPath = 'C:\'
            $mockServiceName = $null
            $mockVirtualRootServer = 'ReportServer'
            $mockConfigFilePath = $null
            $mockErrorDumpDirectory = $null
            $mockProductVersion = $null
            $mockCustomerFeedback = 1
            $mockEnableErrorReporting = 1
            $mockCurrentVersion = '13.0.6404.1'

            Mock -CommandName Get-SqlDscInstalledInstance -MockWith {
                return @($mockSSRS2016Instance)
            }

            Mock -CommandName Get-RegistryPropertyValue -ParameterFilter {
                $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSRS13.MSSQLSERVER\Setup' -and
                $Name -eq 'InstallRootDirectory'
            } -MockWith {
                return $null
            }

            Mock -CommandName Get-RegistryPropertyValue -ParameterFilter {
                $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSRS13.MSSQLSERVER\Setup' -and
                $Name -eq 'SQLPath'
            } -MockWith {
                return $mockSQLPath
            }

            Mock -CommandName Get-RegistryPropertyValue -ParameterFilter {
                $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSRS13.MSSQLSERVER\Setup' -and
                $Name -eq 'ServiceName'
            } -MockWith {
                return $mockServiceName
            }

            Mock -CommandName Get-RegistryPropertyValue -ParameterFilter {
                $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSRS13.MSSQLSERVER\Setup' -and
                $Name -eq 'RSVirtualRootServer'
            } -MockWith {
                return $mockVirtualRootServer
            }

            Mock -CommandName Get-RegistryPropertyValue -ParameterFilter {
                $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSRS13.MSSQLSERVER\Setup' -and
                $Name -eq 'RsConfigFilePath'
            } -MockWith {
                return $mockConfigFilePath
            }

            Mock -CommandName Get-RegistryPropertyValue -ParameterFilter {
                $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSRS13.MSSQLSERVER\CPE' -and
                $Name -eq 'ErrorDumpDir'
            } -MockWith {
                return $mockErrorDumpDirectory
            }

            Mock -CommandName Get-RegistryPropertyValue -ParameterFilter {
                $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSRS13.MSSQLSERVER\CPE' -and
                $Name -eq 'CustomerFeedback'
            } -MockWith {
                return $mockCustomerFeedback
            }

            Mock -CommandName Get-RegistryPropertyValue -ParameterFilter {
                $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSRS13.MSSQLSERVER\CPE' -and
                $Name -eq 'EnableErrorReporting'
            } -MockWith {
                return $mockEnableErrorReporting
            }

            Mock -CommandName Get-RegistryPropertyValue -ParameterFilter {
                $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSRS13.MSSQLSERVER\MSSQLServer\CurrentVersion' -and
                $Name -eq 'CurrentVersion'
            } -MockWith {
                return $mockCurrentVersion
            }

            Mock -CommandName Get-RegistryPropertyValue -ParameterFilter {
                $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSRS13.MSSQLSERVER\MSSQLServer\CurrentVersion' -and
                $Name -eq 'ProductVersion'
            } -MockWith {
                return $mockProductVersion
            }

            Mock -CommandName Get-CimInstance -MockWith {
                return @(
                    [PSCustomObject] @{
                        EditionID              = 610778273
                        EditionName            = 'SQL Server Developer'
                        IsSharePointIntegrated = $false
                        InstanceId             = 'MSRS13.MSSQLSERVER'
                    }
                )
            }
        }

        It 'Should return correct install folder' {
            $result = Get-SqlDscRSSetupConfiguration -InstanceName 'MSSQLSERVER'

            $result.InstallFolder | Should -Be $mockSQLPath

        }
    }
}
