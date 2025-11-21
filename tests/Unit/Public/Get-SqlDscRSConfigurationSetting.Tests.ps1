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

Describe 'Get-SqlDscRSConfigurationSetting' {
    Context 'When validating parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = '__AllParameterSets'
                ExpectedParameters = '[[-InstanceName] <string>] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Get-SqlDscRSConfigurationSetting').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }
    }

    Context 'When getting all Reporting Services instances' {
        BeforeAll {
            # Mock setup configuration objects
            $mockSSRSSetupConfig = [PSCustomObject]@{
                InstanceName       = 'SSRS'
                CurrentVersion     = '15.0.1.0'
                InstallFolder      = 'C:\Program Files\Microsoft SQL Server Reporting Services'
                ServiceName        = 'SQLServerReportingServices'
                ErrorDumpDirectory = 'C:\Program Files\Microsoft SQL Server Reporting Services\SSRS\LogFiles'
            }

            $mockPBIRSSetupConfig = [PSCustomObject]@{
                InstanceName       = 'PBIRS'
                CurrentVersion     = '15.0.1.0'
                InstallFolder      = 'C:\Program Files\Microsoft SQL Server Reporting Services'
                ServiceName        = 'PowerBIReportServer'
                ErrorDumpDirectory = 'C:\Program Files\Microsoft SQL Server Reporting Services\PBIRS\LogFiles'
            }

            # Mock MSReportServer_ConfigurationSetting objects
            $mockSSRSConfiguration = [PSCustomObject]@{
                InstanceName                  = 'SSRS'
                Version                       = '15.0.1.0'
                PathName                      = 'C:\Program Files\Microsoft SQL Server Reporting Services\SSRS'
                InstallationID                = '12345678-1234-1234-1234-123456789012'
                IsInitialized                 = $true
                IsSharePointIntegrated        = $false
                IsWebServiceEnabled           = $true
                IsWindowsServiceEnabled       = $true
                SecureConnectionLevel         = 0
                DatabaseServerName            = 'localhost'
                DatabaseName                  = 'ReportServer'
                DatabaseLogonType             = 2
                DatabaseLogonAccount          = ''
                WindowsServiceIdentityActual  = 'NT SERVICE\ReportServer'
                VirtualDirectoryReportServer  = 'ReportServer'
                VirtualDirectoryReportManager = 'Reports'
            }

            $mockPBIRSConfiguration = [PSCustomObject]@{
                InstanceName                  = 'PBIRS'
                Version                       = '15.0.1.0'
                PathName                      = 'C:\Program Files\Microsoft SQL Server Reporting Services\PBIRS'
                InstallationID                = '87654321-4321-4321-4321-210987654321'
                IsInitialized                 = $true
                IsSharePointIntegrated        = $false
                IsWebServiceEnabled           = $true
                IsWindowsServiceEnabled       = $true
                SecureConnectionLevel         = 0
                DatabaseServerName            = 'localhost'
                DatabaseName                  = 'ReportServer'
                DatabaseLogonType             = 2
                DatabaseLogonAccount          = ''
                WindowsServiceIdentityActual  = 'NT SERVICE\PowerBIReportServer'
                VirtualDirectoryReportServer  = 'ReportServer'
                VirtualDirectoryReportManager = 'Reports'

            }

            Mock -CommandName Get-SqlDscRSSetupConfiguration -MockWith {
                return @($mockSSRSSetupConfig, $mockPBIRSSetupConfig)
            }

            Mock -CommandName Get-CimInstance -ParameterFilter {
                $Filter -eq "InstanceName='SSRS'" -and
                $Namespace -eq 'root\Microsoft\SQLServer\ReportServer\RS_SSRS\v15\Admin' -and
                $ClassName -eq 'MSReportServer_ConfigurationSetting'
            } -MockWith {
                return @($mockSSRSConfiguration)
            }

            Mock -CommandName Get-CimInstance -ParameterFilter {
                $Filter -eq "InstanceName='PBIRS'" -and
                $Namespace -eq 'root\Microsoft\SQLServer\ReportServer\RS_PBIRS\v15\Admin' -and
                $ClassName -eq 'MSReportServer_ConfigurationSetting'
            } -MockWith {
                return @($mockPBIRSConfiguration)
            }
        }

        It 'Should return configuration settings for all instances' {
            $result = Get-SqlDscRSConfigurationSetting

            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2
        }

        It 'Should return correct properties for SSRS instance' {
            $result = Get-SqlDscRSConfigurationSetting
            $ssrsResult = $result | Where-Object -FilterScript { $_.InstanceName -eq 'SSRS' }

            $ssrsResult | Should -Not -BeNullOrEmpty
            $ssrsResult.InstanceName | Should -Be 'SSRS'
            $ssrsResult.Version | Should -Be '15.0.1.0'
            $ssrsResult.PathName | Should -Be 'C:\Program Files\Microsoft SQL Server Reporting Services\SSRS'
            $ssrsResult.IsInitialized | Should -BeTrue
            $ssrsResult.ServiceAccount | Should -Be 'NT SERVICE\ReportServer'
            $ssrsResult.IsTlsConfigured | Should -BeFalse
            $ssrsResult.WebServiceVirtualDirectory | Should -Be 'ReportServer'
            $ssrsResult.WebPortalVirtualDirectory | Should -Be 'Reports'
            $ssrsResult.WebPortalApplicationName | Should -Be 'ReportServerWebApp'
            $ssrsResult.WebServiceApplicationName | Should -Be 'ReportServerWebService'
        }

        It 'Should call Get-SqlDscRSSetupConfiguration without InstanceName' {
            $result = Get-SqlDscRSConfigurationSetting
            Should -Invoke -CommandName Get-SqlDscRSSetupConfiguration -Exactly -Times 1 -Scope It -ParameterFilter {
                -not $PSBoundParameters.ContainsKey('InstanceName')
            }
        }

        It 'Should call Get-CimInstance for each instance' {
            $result = Get-SqlDscRSConfigurationSetting
            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 2 -Scope It
        }
    }

    Context 'When getting a specific Reporting Services instance' {
        BeforeAll {
            $mockSSRSSetupConfig = [PSCustomObject]@{
                InstanceName       = 'SSRS'
                CurrentVersion     = '13.0.7001.0'
                InstallFolder      = 'C:\Program Files\Microsoft SQL Server Reporting Services'
                ServiceName        = 'SQLServerReportingServices'
                ErrorDumpDirectory = 'C:\Program Files\Microsoft SQL Server Reporting Services\SSRS\LogFiles'
            }

            $mockSSRSConfiguration = [PSCustomObject]@{
                InstanceName                  = 'SSRS'
                Version                       = '13.0.7001.0'
                PathName                      = 'C:\Program Files\Microsoft SQL Server Reporting Services\SSRS'
                InstallationID                = '12345678-1234-1234-1234-123456789012'
                IsInitialized                 = $true
                IsSharePointIntegrated        = $false
                IsWebServiceEnabled           = $true
                IsWindowsServiceEnabled       = $true
                SecureConnectionLevel         = 0
                DatabaseServerName            = 'localhost'
                DatabaseName                  = 'ReportServer'
                DatabaseLogonType             = 2
                DatabaseLogonAccount          = ''
                WindowsServiceIdentityActual  = 'NT SERVICE\ReportServer'
                VirtualDirectoryReportServer  = 'ReportServer'
                VirtualDirectoryReportManager = 'Reports'
            }

            Mock -CommandName Get-SqlDscRSSetupConfiguration -ParameterFilter { $InstanceName -eq 'SSRS' } -MockWith {
                return @($mockSSRSSetupConfig)
            }

            Mock -CommandName Get-CimInstance -ParameterFilter { $Filter -eq "InstanceName='SSRS'" } -MockWith {
                return @($mockSSRSConfiguration)
            }
        }

        It 'Should return configuration settings for the specified instance' {
            $result = Get-SqlDscRSConfigurationSetting -InstanceName 'SSRS'

            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 1
            $result[0].InstanceName | Should -Be 'SSRS'
        }

        It 'Should call Get-SqlDscRSSetupConfiguration with InstanceName' {
            $result = Get-SqlDscRSConfigurationSetting -InstanceName 'SSRS'
            Should -Invoke -CommandName Get-SqlDscRSSetupConfiguration -Exactly -Times 1 -Scope It -ParameterFilter {
                $InstanceName -eq 'SSRS'
            }
        }
    }

    Context 'When instance has no CurrentVersion' {
        BeforeAll {
            $mockSSRSSetupConfig = [PSCustomObject]@{
                InstanceName   = 'SSRS'
                CurrentVersion = $null
            }

            Mock -CommandName Get-SqlDscRSSetupConfiguration -MockWith {
                return @($mockSSRSSetupConfig)
            }
        }

        It 'Should throw a terminating error when the currentVersion is null' {
            { Get-SqlDscRSConfigurationSetting } |
                Should -Throw -ErrorId 'GSDCRSCS0001,Get-SqlDscRSConfigurationSetting'
        }
    }

    Context 'When instance has an invalid version' {
        BeforeAll {
            $mockSSRSSetupConfig = [PSCustomObject]@{
                InstanceName   = 'SSRS'
                CurrentVersion = 'InvalidVersion'
            }

            Mock -CommandName Get-SqlDscRSSetupConfiguration -MockWith {
                return @($mockSSRSSetupConfig)
            }
        }

        It 'Should throw a terminating error when the currentVersion is invalid' {
            { Get-SqlDscRSConfigurationSetting } |
                Should -Throw -ErrorId 'GSDCRSCS0002,Get-SqlDscRSConfigurationSetting'
        }
    }

    Context 'When MSReportServer_ConfigurationSetting is not found' {
        BeforeAll {
            $mockSSRSSetupConfig = [PSCustomObject]@{
                InstanceName       = 'SSRS'
                CurrentVersion     = '15.0.1.0'
                InstallFolder      = 'C:\Program Files\Microsoft SQL Server Reporting Services'
                ServiceName        = 'SQLServerReportingServices'
                ErrorDumpDirectory = 'C:\Program Files\Microsoft SQL Server Reporting Services\SSRS\LogFiles'
            }

            Mock -CommandName Get-SqlDscRSSetupConfiguration -MockWith {
                return @($mockSSRSSetupConfig)
            }

            Mock -CommandName Get-CimInstance -MockWith {
                throw [Microsoft.Management.Infrastructure.CimException]::new('Not found')
            }
        }

        It 'Should throw a terminating error when Get-CimInstance throws an error' {
            { Get-SqlDscRSConfigurationSetting } |
                Should -Throw -ErrorId 'GSDCRSCS0003,Get-SqlDscRSConfigurationSetting'
        }
    }

    Context 'When instance is SQL Server 2014 (version 12)' {
        BeforeAll {
            $mockSSRSSetupConfig = [PSCustomObject]@{
                InstanceName       = 'SSRS'
                CurrentVersion     = '12.0.5000.0'
                InstallFolder      = 'C:\Program Files\Microsoft SQL Server Reporting Services'
                ServiceName        = 'SQLServerReportingServices'
                ErrorDumpDirectory = 'C:\Program Files\Microsoft SQL Server Reporting Services\SSRS\LogFiles'
            }

            $mockSSRSConfiguration = [PSCustomObject]@{
                InstanceName                  = 'SSRS'
                Version                       = '12.0.5000.0'
                PathName                      = 'C:\Program Files\Microsoft SQL Server Reporting Services\SSRS'
                InstallationID                = '12345678-1234-1234-1234-123456789012'
                IsInitialized                 = $true
                IsSharePointIntegrated        = $false
                IsWebServiceEnabled           = $true
                IsWindowsServiceEnabled       = $true
                SecureConnectionLevel         = 0
                DatabaseServerName            = 'localhost'
                DatabaseName                  = 'ReportServer'
                DatabaseLogonType             = 2
                DatabaseLogonAccount          = ''
                WindowsServiceIdentityActual  = 'NT SERVICE\ReportServer'
                VirtualDirectoryReportServer  = 'ReportServer'
                VirtualDirectoryReportManager = 'Reports'
            }

            Mock -CommandName Get-SqlDscRSSetupConfiguration -MockWith {
                return @($mockSSRSSetupConfig)
            }

            Mock -CommandName Get-CimInstance -ParameterFilter {
                $Filter -eq "InstanceName='SSRS'"
            } -MockWith {
                return @($mockSSRSConfiguration)
            }
        }

        It 'Should use ReportManager for WebPortalApplicationName' {
            $result = Get-SqlDscRSConfigurationSetting

            $result | Should -Not -BeNullOrEmpty
            $result[0].WebPortalApplicationName | Should -Be 'ReportManager'
            $result[0].WebPortalVirtualDirectory | Should -Be 'Reports'
        }

        It 'Should convert SecureConnectionLevel 0 to IsTlsConfigured false' {
            $result = Get-SqlDscRSConfigurationSetting

            $result | Should -Not -BeNullOrEmpty
            $result[0].IsTlsConfigured | Should -BeFalse
        }
    }

    Context 'When instance is SQL Server 2016 (version 13)' {
        BeforeAll {
            $mockSSRSSetupConfig = [PSCustomObject]@{
                InstanceName       = 'SSRS'
                CurrentVersion     = '13.0.7001.0'
                InstallFolder      = 'C:\Program Files\Microsoft SQL Server Reporting Services'
                ServiceName        = 'SQLServerReportingServices'
                ErrorDumpDirectory = 'C:\Program Files\Microsoft SQL Server Reporting Services\SSRS\LogFiles'
            }

            $mockSSRSConfiguration = [PSCustomObject]@{
                InstanceName                  = 'SSRS'
                Version                       = '13.0.7001.0'
                PathName                      = 'C:\Program Files\Microsoft SQL Server Reporting Services\SSRS'
                InstallationID                = '12345678-1234-1234-1234-123456789012'
                IsInitialized                 = $true
                IsSharePointIntegrated        = $false
                IsWebServiceEnabled           = $true
                IsWindowsServiceEnabled       = $true
                SecureConnectionLevel         = 1
                DatabaseServerName            = 'localhost'
                DatabaseName                  = 'ReportServer'
                DatabaseLogonType             = 2
                DatabaseLogonAccount          = ''
                WindowsServiceIdentityActual  = 'NT SERVICE\ReportServer'
                VirtualDirectoryReportServer  = 'ReportServer'
                VirtualDirectoryReportManager = 'Reports'
            }

            Mock -CommandName Get-SqlDscRSSetupConfiguration -MockWith {
                return @($mockSSRSSetupConfig)
            }

            Mock -CommandName Get-CimInstance -ParameterFilter {
                $Filter -eq "InstanceName='SSRS'"
            } -MockWith {
                return @($mockSSRSConfiguration)
            }
        }

        It 'Should use ReportServerWebApp for WebPortalApplicationName' {
            $result = Get-SqlDscRSConfigurationSetting

            $result | Should -Not -BeNullOrEmpty
            $result[0].WebPortalApplicationName | Should -Be 'ReportServerWebApp'
            $result[0].WebPortalVirtualDirectory | Should -Be 'Reports'
        }

        It 'Should convert SecureConnectionLevel 1 to IsTlsConfigured true' {
            $result = Get-SqlDscRSConfigurationSetting

            $result | Should -Not -BeNullOrEmpty
            $result[0].IsTlsConfigured | Should -BeTrue
        }
    }

    Context 'When no instances are found' {
        BeforeAll {
            Mock -CommandName Get-SqlDscRSSetupConfiguration -MockWith {
                return @()
            }
        }

        It 'Should return empty array when no instances found' {
            $result = Get-SqlDscRSConfigurationSetting

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'When instance name is not found' {
        BeforeAll {
            Mock -CommandName Get-SqlDscRSSetupConfiguration -ParameterFilter {
                $InstanceName -eq 'NonExistent'
            } -MockWith {
                return @()
            }
        }

        It 'Should return empty array when instance name not found' {
            $result = Get-SqlDscRSConfigurationSetting -InstanceName 'NonExistent'

            $result | Should -BeNullOrEmpty
        }
    }
}
