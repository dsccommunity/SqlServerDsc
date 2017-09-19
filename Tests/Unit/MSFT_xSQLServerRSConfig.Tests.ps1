$script:DSCModuleName      = 'xSQLServer'
$script:DSCResourceName    = 'MSFT_xSQLServerRSConfig'

#region HEADER

# Unit Test Template Version: 1.2.0
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName   `
    -DSCResourceName $script:DSCResourceName  `
    -TestType Unit

#endregion HEADER

function Invoke-TestSetup {
    Import-Module -Name (Join-Path -Path (Join-Path -Path (Join-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'Tests') -ChildPath 'Unit') -ChildPath 'Stubs') -ChildPath 'SQLPSStub.psm1') -Global -Force
}

function Invoke-TestCleanup {
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

# Begin Testing
try
{
    Invoke-TestSetup

    InModuleScope $script:DSCResourceName {
        $mockNamedInstanceName = 'INSTANCE'
        $mockDefaultInstanceName = 'MSSQLSERVER'
        $mockReportingServicesDatabaseServerName = 'SERVER'
        $mockReportingServicesDatabaseNamedInstanceName = $mockNamedInstanceName
        $mockReportingServicesDatabaseDefaultInstanceName = $mockDefaultInstanceName

        $mockGetItemProperty = {
            return @{
                InstanceName = $mockInstanceName
                Version = $mockDynamic_SqlBuildVersion
            }
        }

        $mockGetWmiObject_ConfigurationSetting_NamedInstance = {
            return New-Object Object |
                        Add-Member -MemberType NoteProperty -Name 'DatabaseServerName' -Value "$mockReportingServicesDatabaseServerName\$mockReportingServicesDatabaseNamedInstanceName" -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'IsInitialized' -Value $mockDynamicIsInitialized -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'VirtualDirectoryReportServer' -Value '' -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'VirtualDirectoryReportManager' -Value '' -PassThru |
                        Add-Member -MemberType ScriptMethod -Name SetVirtualDirectory {
                            $script:mockIsMethodCalled_SetVirtualDirectory = $true

                            return $null
                        } -PassThru |
                        Add-Member -MemberType ScriptMethod -Name ReserveURL {
                            $script:mockIsMethodCalled_ReserveURL = $true

                            return $null
                        } -PassThru |
                        Add-Member -MemberType ScriptMethod -Name GenerateDatabaseCreationScript {
                            $script:mockIsMethodCalled_GenerateDatabaseCreationScript = $true

                            return @{
                                Script = 'select * from something'
                            }
                        } -PassThru |
                        Add-Member -MemberType ScriptMethod -Name GenerateDatabaseRightsScript {
                            $script:mockIsMethodCalled_GenerateDatabaseRightsScript = $true

                            return @{
                                Script = 'select * from something'
                            }
                        } -PassThru |
                        Add-Member -MemberType ScriptMethod -Name SetDatabaseConnection {
                            $script:mockIsMethodCalled_SetDatabaseConnection = $true

                            return $null
                        } -PassThru |
                        Add-Member -MemberType ScriptMethod -Name InitializeReportServer {
                            $script:mockIsMethodCalled_InitializeReportServer = $true

                            return $null
                        } -PassThru -Force
        }

        $mockGetWmiObject_ConfigurationSetting_DefaultInstance = {
            return @{
                DatabaseServerName = $mockReportingServicesDatabaseServerName
                IsInitialized = $mockDynamicIsInitialized
            }
        }

        $mockGetWmiObject_ConfigurationSetting_ParameterFilter = {
            $Class -eq 'MSReportServer_ConfigurationSetting'
        }

        $mockGetWmiObject_Language = {
            return @{
                Language = '1033'
            }
        }

        $mockGetWmiObject_OperatingSystem_ParameterFilter = {
            $Class -eq 'Win32_OperatingSystem'
        }

        Describe "xSQLServerRSConfig\Get-TargetResource" -Tag 'Get' {
            BeforeAll {
                $mockDynamic_SqlBuildVersion = '13.0.4001.0'

                Mock -CommandName Get-ItemProperty -MockWith $mockGetItemProperty -Verifiable

                $testParameters = @{
                    InstanceName = $mockNamedInstanceName
                    RSSQLServer = $mockReportingServicesDatabaseServerName
                    RSSQLInstanceName = $mockReportingServicesDatabaseNamedInstanceName
                }
            }

            Context 'When the system is in the desired state' {
                BeforeEach {
                    Mock -CommandName Get-WmiObject `
                        -MockWith $mockGetWmiObject_ConfigurationSetting_NamedInstance `
                        -ParameterFilter $mockGetWmiObject_ConfigurationSetting_ParameterFilter `
                        -Verifiable
                }

                $mockDynamicIsInitialized = $true

                It 'Should return the same values as passed as parameters' {
                    $resultGetTargetResource = Get-TargetResource @testParameters
                    $resultGetTargetResource.InstanceName | Should Be $mockNamedInstanceName
                    $resultGetTargetResource.RSSQLServer | Should Be $mockReportingServicesDatabaseServerName
                    $resultGetTargetResource.RSSQLInstanceName | Should Be $mockReportingServicesDatabaseNamedInstanceName
                    $resultGetTargetResource | Should BeOfType [System.Collections.Hashtable]
                }

                It 'Should return the the state as initialized' {
                    $resultGetTargetResource = Get-TargetResource @testParameters
                    $resultGetTargetResource.IsInitialized | Should Be $true
                }
            }

            Context 'When the system is not in the desired state' {
                BeforeEach {
                    Mock -CommandName Get-WmiObject `
                        -MockWith $mockGetWmiObject_ConfigurationSetting_DefaultInstance `
                        -ParameterFilter $mockGetWmiObject_ConfigurationSetting_ParameterFilter `
                        -Verifiable
                }

                $mockDynamicIsInitialized = $false

                It 'Should return the same values as passed as parameters' {
                    $resultGetTargetResource = Get-TargetResource @testParameters
                    $resultGetTargetResource.InstanceName | Should Be $mockNamedInstanceName
                    $resultGetTargetResource.RSSQLServer | Should Be $mockReportingServicesDatabaseServerName
                    $resultGetTargetResource.RSSQLInstanceName | Should Be 'MSSQLSERVER'
                    $resultGetTargetResource | Should BeOfType [System.Collections.Hashtable]
                }

                It 'Should return the state as not initialized' {
                    $resultGetTargetResource = Get-TargetResource @testParameters
                    $resultGetTargetResource.IsInitialized | Should Be $false
                }

                # Regression test for issue #822.
                Context 'When Reporting Services has not been initialized (IsInitialized returns $null)' {
                    $mockDynamicIsInitialized = $null

                    It 'Should return the state as not initialized' {
                        $resultGetTargetResource = Get-TargetResource @testParameters
                        $resultGetTargetResource.IsInitialized | Should Be $false
                    }
                }

                # Regression test for issue #822.
                Context 'When Reporting Services has not been initialized (IsInitialized returns empty string)' {
                    $mockDynamicIsInitialized = ''

                    It 'Should return the state as not initialized' {
                        $resultGetTargetResource = Get-TargetResource @testParameters
                        $resultGetTargetResource.IsInitialized | Should Be $false
                    }
                }

                Context 'When there is no Reporting Services instance' {
                    BeforeEach {
                        Mock -CommandName Get-ItemProperty
                    }

                    It 'Should throw the correct error message' {
                        { Get-TargetResource @testParameters } | Should Throw 'SQL Reporting Services instance ''INSTANCE'' does not exist!'
                    }
                }
            }

            Assert-VerifiableMocks
        }

        Describe "xSQLServerRSConfig\Set-TargetResource" -Tag 'Set' {
            BeforeAll {
                Mock -CommandName Import-SQLPSModule -Verifiable
                Mock -CommandName Invoke-Sqlcmd -Verifiable
                Mock -CommandName Get-ItemProperty -MockWith $mockGetItemProperty -Verifiable
            }

            Context 'When the system is not in the desired state' {
                Context 'When configuring a named instance' {
                    BeforeAll {
                        $mockDynamic_SqlBuildVersion = '13.0.4001.0'

                        Mock -CommandName Test-TargetResource -MockWith {
                            return $true
                        }

                        $testParameters = @{
                            InstanceName = $mockNamedInstanceName
                            RSSQLServer = $mockReportingServicesDatabaseServerName
                            RSSQLInstanceName = $mockReportingServicesDatabaseNamedInstanceName
                        }
                    }

                    BeforeEach {
                        Mock -CommandName Get-WmiObject `
                            -MockWith $mockGetWmiObject_ConfigurationSetting_NamedInstance `
                            -ParameterFilter $mockGetWmiObject_ConfigurationSetting_ParameterFilter `
                            -Verifiable

                        Mock -CommandName Get-WmiObject `
                            -MockWith $mockGetWmiObject_Language `
                            -ParameterFilter $mockGetWmiObject_OperatingSystem_ParameterFilter `
                            -Verifiable

                        # Start each test with each method in correct state.
                        $script:mockIsMethodCalled_GenerateDatabaseCreationScript = $false
                        $script:mockIsMethodCalled_GenerateDatabaseRightsScript = $false
                        $script:mockIsMethodCalled_SetVirtualDirectory = $false
                        $script:mockIsMethodCalled_ReserveURL = $false
                        $script:mockIsMethodCalled_SetDatabaseConnection = $false
                        $script:mockIsMethodCalled_InitializeReportServer = $false
                    }

                    It 'Should configure Reporting Service without throwing an error' {
                        { Set-TargetResource @testParameters } | Should Not Throw

                        # Test so each mock of methods was called.
                        $script:mockIsMethodCalled_GenerateDatabaseRightsScript | Should Be $true
                        $script:mockIsMethodCalled_GenerateDatabaseCreationScript | Should Be $true
                        $script:mockIsMethodCalled_SetVirtualDirectory | Should Be $true
                        $script:mockIsMethodCalled_ReserveURL | Should Be $true
                        $script:mockIsMethodCalled_SetDatabaseConnection | Should Be $true
                        $script:mockIsMethodCalled_InitializeReportServer | Should Be $true

                        Assert-MockCalled -CommandName Get-WmiObject -Exactly -Times 2 -Scope It
                        Assert-MockCalled -CommandName Invoke-Sqlcmd -Exactly -Times 2 -Scope It
                    }

                    Context 'When there is no Reporting Services instance after Set-TargetResource has been called' {
                        BeforeEach {
                            Mock -CommandName Get-ItemProperty -Verifiable
                            Mock -CommandName Test-TargetResource -Verifiable
                        }

                        It 'Should throw the correct error message' {
                            { Set-TargetResource @testParameters } | Should Throw 'Test-TargetResource returned false after calling set.'
                        }
                    }
                }

                Context 'When configuring a default instance' {
                    BeforeAll {
                        $mockDynamic_SqlBuildVersion = '12.0.4100.1'

                        Mock -CommandName Test-TargetResource -MockWith {
                            return $true
                        } -Verifiable

                        $testParameters = @{
                            InstanceName = $mockDefaultInstanceName
                            RSSQLServer = $mockReportingServicesDatabaseServerName
                            RSSQLInstanceName = $mockReportingServicesDatabaseDefaultInstanceName
                        }
                    }

                    BeforeEach {
                        Mock -CommandName Get-WmiObject `
                            -MockWith $mockGetWmiObject_ConfigurationSetting_NamedInstance `
                            -ParameterFilter $mockGetWmiObject_ConfigurationSetting_ParameterFilter `
                            -Verifiable

                        Mock -CommandName Get-WmiObject `
                            -MockWith $mockGetWmiObject_Language `
                            -ParameterFilter $mockGetWmiObject_OperatingSystem_ParameterFilter `
                            -Verifiable
                    }

                    It 'Should configure Reporting Service without throwing an error' {
                        { Set-TargetResource @testParameters } | Should Not Throw

                        # Test so each mock of methods was called.
                        $script:mockIsMethodCalled_GenerateDatabaseRightsScript | Should Be $true
                        $script:mockIsMethodCalled_GenerateDatabaseCreationScript | Should Be $true
                        $script:mockIsMethodCalled_SetVirtualDirectory | Should Be $true
                        $script:mockIsMethodCalled_ReserveURL | Should Be $true
                        $script:mockIsMethodCalled_SetDatabaseConnection | Should Be $true
                        $script:mockIsMethodCalled_InitializeReportServer | Should Be $true

                        Assert-MockCalled -CommandName Get-WmiObject -Exactly -Times 2 -Scope It
                        Assert-MockCalled -CommandName Invoke-Sqlcmd -Exactly -Times 2 -Scope It
                    }
                }
            }

            Assert-VerifiableMocks
        }

        Describe "xSQLServerRSConfig\Test-TargetResource" -Tag 'Test' {
            Context 'When the system is not in the desired state' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            IsInitialized = $false
                        }
                    } -Verifiable

                    $testParameters = @{
                        InstanceName = $mockNamedInstanceName
                        RSSQLServer = $mockReportingServicesDatabaseServerName
                        RSSQLInstanceName = $mockReportingServicesDatabaseNamedInstanceName
                    }
                }

                It 'Should return state as not in desired state' {
                    $resultTestTargetResource  = Test-TargetResource @testParameters
                    $resultTestTargetResource | Should Be $false
                }
            }

            Context 'When the system is in the desired state' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            IsInitialized = $true
                        }
                    } -Verifiable

                    $testParameters = @{
                        InstanceName = $mockNamedInstanceName
                        RSSQLServer = $mockReportingServicesDatabaseServerName
                        RSSQLInstanceName = $mockReportingServicesDatabaseNamedInstanceName
                    }
                }

                It 'Should return state as in desired state' {
                    $resultTestTargetResource  = Test-TargetResource @testParameters
                    $resultTestTargetResource | Should Be $true
                }
            }

            Assert-VerifiableMocks
        }
    }
}
finally
{
    Invoke-TestCleanup
}
