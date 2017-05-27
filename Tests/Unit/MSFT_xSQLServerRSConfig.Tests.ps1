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
    #Add-Type -Path (Join-Path -Path (Join-Path -Path (Join-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'Tests') -ChildPath 'Unit') -ChildPath 'Stubs') -ChildPath 'SqlPowerShellSqlExecutionException.cs')
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
                        Add-Member -MemberType NoteProperty -Name 'IsInitialized' -Value $true -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'VirtualDirectoryReportServer' -Value '' -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'VirtualDirectoryReportManager' -Value '' -PassThru |
                        Add-Member -MemberType ScriptMethod -Name SetVirtualDirectory {
                            return $null
                        } -PassThru |
                        Add-Member -MemberType ScriptMethod -Name ReserveURL {
                            return $null
                        } -PassThru |
                        Add-Member -MemberType ScriptMethod -Name GenerateDatabaseCreationScript {
                            return @{
                                Script = 'select * from something'
                            }
                        } -PassThru |
                        Add-Member -MemberType ScriptMethod -Name GenerateDatabaseRightsScript {
                            return @{
                                Script = 'select * from something'
                            }
                        } -PassThru |
                        Add-Member -MemberType ScriptMethod -Name SetDatabaseConnection {
                            return $null
                        } -PassThru |
                        Add-Member -MemberType ScriptMethod -Name InitializeReportServer {
                            return $null
                        } -PassThru -Force
        }

        $mockGetWmiObject_ConfigurationSetting_DefaultInstance = {
            return @{
                DatabaseServerName = $mockReportingServicesDatabaseServerName
                IsInitialized = $false
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

                It 'Should return the same values as passed as parameters' {
                    $resultGetTargetResource = Get-TargetResource @testParameters
                    $resultGetTargetResource.InstanceName | Should Be $mockNamedInstanceName
                    $resultGetTargetResource.RSSQLServer | Should Be $mockReportingServicesDatabaseServerName
                    $resultGetTargetResource.RSSQLInstanceName | Should Be 'MSSQLSERVER'
                    $resultGetTargetResource | Should BeOfType [System.Collections.Hashtable]
                }

                It 'Should return the the state as initialized' {
                    $resultGetTargetResource = Get-TargetResource @testParameters
                    $resultGetTargetResource.IsInitialized | Should Be $false
                }

                Context 'When there is no Reporting Services instance' {
                    BeforeEach {
                        Mock -CommandName Get-ItemProperty
                    }

                    It 'Should return the the state as initialized' {
                        { Get-TargetResource @testParameters } | Should Throw 'SQL Reporting Services instance ''INSTANCE'' does not exist!'
                    }
                }
            }
        }

        Describe "xSQLServerRSConfig\Set-TargetResource" -Tag 'Set' {
            BeforeAll {
                Mock -CommandName Import-SQLPSModule
                Mock -CommandName Invoke-Sqlcmd
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
                    }

                    It 'Should configure Reporting Service without throwing an error' {
                        { Set-TargetResource @testParameters } | Should Not Throw
                    }

                    Context 'When there is no Reporting Services instance' {
                        BeforeEach {
                            Mock -CommandName Get-ItemProperty
                            Mock -CommandName Test-TargetResource
                        }

                        It 'Should return the the state as initialized' {
                            { Set-TargetResource @testParameters } | Should Throw 'Test-TargetResource returned false after calling set.'
                        }
                    }
                }

                Context 'When configuring a default instance' {
                    BeforeAll {
                        $mockDynamic_SqlBuildVersion = '12.0.4100.1'

                        Mock -CommandName Test-TargetResource -MockWith {
                            return $true
                        }

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
                    }
                }
            }
        }

        Describe "xSQLServerRSConfig\Test-TargetResource" -Tag 'Test' {
            Context 'When the system is not in the desired state' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            IsInitialized = $false
                        }
                    }

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
                    }

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
        }
    }
}
finally
{
    Invoke-TestCleanup
}
