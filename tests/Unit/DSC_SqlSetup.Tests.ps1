<#
    .SYNOPSIS
        Unit test for DSC_SqlSetup DSC resource.
#>

# Suppressing this rule because Script Analyzer does not understand Pester's syntax.
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
# Suppressing this rule because tests are mocking passwords in clear text.
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
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
                & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies has not been resolved, this will throw an error.
            Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
        }
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
    }

    # Testing each supported SQL Server version
    $testProductVersion = @(
        @{
            MockSqlMajorVersion = 15 # SQL Server 2019
        }
        @{
            MockSqlMajorVersion = 14 # SQL Server 2017
        }
        @{
            MockSqlMajorVersion = 13 # SQL Server 2016
        }
        @{
            MockSqlMajorVersion = 12 # SQL Server 2014
        }
        @{
            MockSqlMajorVersion = 11 # SQL Server 2012
        }
        @{
            MockSqlMajorVersion = 10  # SQL Server 2008 and 2008 R2
        }
    )
}

BeforeAll {
    $script:dscModuleName = 'SqlServerDsc'
    $script:dscResourceName = 'DSC_SqlSetup'

    $env:SqlServerDscCI = $true

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscResourceName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscResourceName -All | Remove-Module -Force

    # Remove module common test helper.
    Get-Module -Name 'CommonTestHelper' -All | Remove-Module -Force

    Remove-Item -Path 'env:SqlServerDscCI'
}

Describe 'SqlSetup\Get-TargetResource' -Tag 'Get' {
    BeforeAll {
        <#
            These mocks is meant to make sure the commands are actually mocked in a
            Context-block below.

            If these are not mocked it can slow down testing. If a Context-block
            does not mock a command, it will be tested against the default mock which
            will be these ones and they will throw an error reminding to create
            a mock.
        #>
        Mock -CommandName Get-InstalledSharedFeatures -MockWith {
            throw 'The command ''Get-InstalledSharedFeatures'' needs to be mocked in the Context-block'
        }

        Mock -CommandName Connect-UncPath -MockWith {
            throw 'The command ''Connect-UncPath'' needs to be mocked in the Context-block'
        }

        Mock -CommandName Disconnect-UncPath -MockWith {
            throw 'The command ''Disconnect-UncPath'' needs to be mocked in the Context-block'
        }

        Mock -CommandName Get-Service -MockWith {
            throw 'The command ''Get-Service'' needs to be mocked in the Context-block'
        }

        Mock -CommandName Get-SqlEngineProperties -MockWith {
            throw 'The command ''Get-SqlEngineProperties'' needs to be mocked in the Context-block'
        }

        Mock -CommandName Test-IsReplicationFeatureInstalled -MockWith {
            throw 'The command ''Test-IsReplicationFeatureInstalled'' needs to be mocked in the Context-block'
        }

        Mock -CommandName Test-IsDQComponentInstalled -MockWith {
            throw 'The command ''Test-IsDQComponentInstalled'' needs to be mocked in the Context-block'
        }

        Mock -CommandName Get-InstanceProgramPath -MockWith {
            throw 'The command ''Get-InstanceProgramPath'' needs to be mocked in the Context-block'
        }

        Mock -CommandName Get-TempDbProperties -MockWith {
            throw 'The command ''Get-TempDbProperties'' needs to be mocked in the Context-block'
        }

        Mock -CommandName Get-SqlRoleMembers -MockWith {
            throw 'The command ''Get-SqlRoleMembers'' needs to be mocked in the Context-block'
        }

        Mock -CommandName Get-SqlClusterProperties -MockWith {
            throw 'The command ''Get-SqlClusterProperties'' needs to be mocked in the Context-block'
        }

        Mock -CommandName Get-ServiceProperties -MockWith {
            throw 'The command ''Get-ServiceProperties'' needs to be mocked in the Context-block'
        }

        Mock -CommandName Test-IsSsmsInstalled -MockWith {
            throw 'The command ''Test-IsSsmsInstalled'' needs to be mocked in the Context-block'
        }

        Mock -CommandName Test-IsSsmsAdvancedInstalled -MockWith {
            throw 'The command ''Test-IsSsmsAdvancedInstalled'' needs to be mocked in the Context-block'
        }

        $mockGetService_NoServices = {
            return @()
        }

        $mockGetService_DefaultInstance = {
            return @(
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value 'MSSQLSERVER' -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value 'COMPANY\SqlAccount' -PassThru -Force |
                        Add-Member -MemberType NoteProperty -Name 'StartMode' -Value 'Auto' -PassThru -Force
                ),
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value 'SQLSERVERAGENT' -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value 'COMPANY\AgentAccount' -PassThru -Force |
                        Add-Member -MemberType NoteProperty -Name 'StartMode' -Value 'Auto' -PassThru -Force
                ),
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value 'MSSQLFDLauncher' -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value 'COMPANY\SqlAccount' -PassThru -Force
                ),
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value 'ReportServer' -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value 'COMPANY\SqlAccount' -PassThru -Force |
                        Add-Member -MemberType NoteProperty -Name 'StartMode' -Value 'Auto' -PassThru -Force
                ),
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value ('MsDtsServer{0}0' -f $MockSqlMajorVersion) -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value 'COMPANY\SqlAccount' -PassThru -Force |
                        Add-Member -MemberType NoteProperty -Name 'StartMode' -Value 'Auto' -PassThru -Force
                ),
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value 'MSSQLServerOLAPService' -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value 'COMPANY\SqlAccount' -PassThru -Force |
                        Add-Member -MemberType NoteProperty -Name 'StartMode' -Value 'Auto' -PassThru -Force
                )
            )
        }

        $mockConnectSQLAnalysis = {
            return @(
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType ScriptProperty -Name ServerProperties -Value {
                            return @{
                                'CollationName' = @( New-Object -TypeName Object | Add-Member -MemberType NoteProperty -Name 'Value' -Value 'Finnish_Swedish_CI_AS' -PassThru -Force )
                                'DataDir'       = @( New-Object -TypeName Object | Add-Member -MemberType NoteProperty -Name 'Value' -Value 'C:\Program Files\Microsoft SQL Server\OLAP\Data' -PassThru -Force )
                                'TempDir'       = @( New-Object -TypeName Object | Add-Member -MemberType NoteProperty -Name 'Value' -Value 'C:\Program Files\Microsoft SQL Server\OLAP\Temp' -PassThru -Force )
                                'LogDir'        = @( New-Object -TypeName Object | Add-Member -MemberType NoteProperty -Name 'Value' -Value 'C:\Program Files\Microsoft SQL Server\OLAP\Log' -PassThru -Force )
                                'BackupDir'     = @( New-Object -TypeName Object | Add-Member -MemberType NoteProperty -Name 'Value' -Value 'C:\Program Files\Microsoft SQL Server\OLAP\Backup' -PassThru -Force )
                            }
                        } -PassThru |
                        Add-Member -MemberType ScriptProperty -Name Roles -Value {
                            return @{
                                'Administrators' = @( New-Object -TypeName Object |
                                        Add-Member -MemberType ScriptProperty -Name Members -Value {
                                            return New-Object -TypeName Object |
                                                Add-Member -MemberType ScriptProperty -Name Name -Value {
                                                    return $mockDynamicSqlAnalysisAdmins
                                                } -PassThru -Force
                                            } -PassThru -Force
                                        )
                                    }
                                } -PassThru |
                                Add-Member -MemberType NoteProperty -Name 'ServerMode' -Value $mockDynamicAnalysisServerMode -PassThru -Force
                )
            )
        }

        $mockGetSqlMajorVersion = {
            return $MockSqlMajorVersion
        }

        # General mocks
        Mock -CommandName Get-PSDrive
        Mock -CommandName Get-FilePathMajorVersion -MockWith $mockGetSqlMajorVersion

        Mock -CommandName Get-RegistryPropertyValue -ParameterFilter {
            $Name -eq 'ImagePath'
        } -MockWith {
            <#
                Example for a named instance for SQL Server 2017 and 2019:
                '"C:\Program Files\Microsoft SQL Server\MSAS14.INSTANCE\OLAP\bin\msmdsrv.exe" -s "C:\Program Files\Microsoft SQL Server\MSAS14.INSTANCE\OLAP\Config"'
            #>
            return '"C:\Program Files\Microsoft SQL Server\OLAP\bin\msmdsrv.exe" -s "C:\Program Files\Microsoft SQL Server\OLAP\Config"'
        }

        # Mocking SharedDirectory and SharedWowDirectory
        Mock -CommandName Get-SqlSharedPaths -MockWith {
            return @{
                InstallSharedDir    = 'C:\Program Files\Microsoft SQL Server'
                InstallSharedWOWDir = 'C:\Program Files (x86)\Microsoft SQL Server'
            }
        }

        Mock -CommandName Get-FullInstanceId -ParameterFilter {
            $InstanceName -eq 'MSSQLSERVER'
        } -MockWith {
            return "MSSQL$($MockSqlMajorVersion).MSSQLSERVER"
        }

        Mock -CommandName Get-FullInstanceId -ParameterFilter {
            $InstanceName -eq 'TEST'
        } -MockWith {
            return "MSSQL$($MockSqlMajorVersion).TEST"
        }

        Mock -CommandName Connect-SQLAnalysis -MockWith $mockConnectSQLAnalysis

        <#
            This make sure the mock for Connect-SQLAnalysis get the correct
            value for ServerMode property for the tests. It's dynamically
            changed in other tests for testing different server modes.
        #>
        $mockDynamicAnalysisServerMode = 'MULTIDIMENSIONAL'

        # This sets administrators dynamically in the mock Connect-SQLAnalysis.
        $mockDynamicSqlAnalysisAdmins = @('COMPANY\Stacy', 'COMPANY\SSAS Administrators')
    }

    Context 'When setup action is Upgrade and parameter SqlVersion is passed' {
        It 'Should throw the correct exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockErrorMessage = Get-InvalidOperationRecord -Message (
                    $script:localizedData.ParameterSqlVersionNotAllowedForSetupActionUpgrade
                )

                $script:mockGetTargetResourceParameters = @{
                    Action           = 'Upgrade'
                    InstanceName     = 'MSSQLSERVER'
                    SourceCredential = $null
                    SourcePath       = $TestDrive
                    Feature          = 'NewFeature' # Test enabling a code-feature.
                    ServerName       = 'host.company.local'
                    SqlVersion       = '14.0'
                }

                { Get-TargetResource @mockGetTargetResourceParameters } | Should -Throw -ExpectedMessage $mockErrorMessage
            }
        }
    }

    Context 'When SQL Server version is <MockSqlMajorVersion> and the system is not in the desired state for default instance' -ForEach $testProductVersion {
        BeforeAll {
            Mock -CommandName Test-IsSsmsInstalled -MockWith {
                return $false
            }

            Mock -CommandName Test-IsSsmsAdvancedInstalled -MockWith {
                return $false
            }

            Mock -CommandName Connect-UncPath
            Mock -CommandName Disconnect-UncPath
            Mock -CommandName Get-Service -MockWith $mockGetService_NoServices

            Mock -CommandName Test-IsDQComponentInstalled -MockWith {
                return $false
            }

            Mock -CommandName Get-InstanceProgramPath -MockWith {
                return 'C:\Program Files\Microsoft SQL Server'
            }

            Mock -CommandName Get-InstalledSharedFeatures -MockWith {
                return @()
            }

            InModuleScope -ScriptBlock {
                $script:mockGetTargetResourceParameters = @{
                    InstanceName     = 'MSSQLSERVER'
                    SourceCredential = $null
                    SourcePath       = $TestDrive
                    Feature          = 'NewFeature' # Test enabling a code-feature.
                    ServerName       = 'host.company.local'
                }
            }
        }

        It 'Should return the same values as passed as parameters' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockGetTargetResourceParameters

                $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
            }

            Should -Invoke -CommandName Connect-UncPath -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Disconnect-UncPath -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-PSDrive -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Service -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-InstanceProgramPath -Exactly -Times 0 -Scope It

            Should -Invoke -CommandName Test-IsSsmsInstalled -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Test-IsSsmsAdvancedInstalled -Exactly -Times 1 -Scope It
        }

        It 'Should not return any names of installed features' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockGetTargetResourceParameters

                $result.Features | Should -Be ''
            }
        }

        It 'Should return the correct values in the hash table' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockGetTargetResourceParameters

                $result.SourcePath | Should -Be $TestDrive
                $result.InstanceName | Should -Be 'MSSQLSERVER'
                $result.InstanceID | Should -BeNullOrEmpty
                $result.InstallSharedDir | Should -BeNullOrEmpty
                $result.InstallSharedWOWDir | Should -BeNullOrEmpty
                $result.SQLSvcAccountUsername | Should -BeNullOrEmpty
                $result.AgtSvcAccountUsername | Should -BeNullOrEmpty
                $result.SqlCollation | Should -BeNullOrEmpty
                $result.SQLSysAdminAccounts | Should -BeNullOrEmpty
                $result.SecurityMode | Should -BeNullOrEmpty
                $result.InstallSQLDataDir | Should -BeNullOrEmpty
                $result.SQLUserDBDir | Should -BeNullOrEmpty
                $result.SQLUserDBLogDir | Should -BeNullOrEmpty
                $result.SQLBackupDir | Should -BeNullOrEmpty
                $result.FTSvcAccountUsername | Should -BeNullOrEmpty
                $result.RSSvcAccountUsername | Should -BeNullOrEmpty
                $result.ASSvcAccountUsername | Should -BeNullOrEmpty
                $result.ASCollation | Should -BeNullOrEmpty
                $result.ASSysAdminAccounts | Should -BeNullOrEmpty
                $result.ASDataDir | Should -BeNullOrEmpty
                $result.ASLogDir | Should -BeNullOrEmpty
                $result.ASBackupDir | Should -BeNullOrEmpty
                $result.ASTempDir | Should -BeNullOrEmpty
                $result.ASConfigDir | Should -BeNullOrEmpty
                $result.ASServerMode | Should -BeNullOrEmpty
                $result.ISSvcAccountUsername | Should -BeNullOrEmpty
                $result.ServerName | Should -Be 'host.company.local'
            }
        }
    }

    Context 'When SQL Server version is <MockSqlMajorVersion> and the system is in the desired state for default instance' -ForEach @(
        # Only runs for SQL Server 2017 for now.
        @{
            MockSqlMajorVersion = 14
        }
    ) {
        BeforeAll {
            Mock -CommandName Get-InstalledSharedFeatures -MockWith {
                return @(
                    'DQC'
                    'BOL'
                    'CONN'
                    'BC'
                    'SDK'
                    'MDS'
                )
            }

            Mock -CommandName Connect-UncPath
            Mock -CommandName Disconnect-UncPath
            Mock -CommandName Get-Service -MockWith $mockGetService_DefaultInstance

            Mock -CommandName Test-IsSsmsInstalled -MockWith {
                return $false
            }

            Mock -CommandName Test-IsSsmsAdvancedInstalled -MockWith {
                return $false
            }

            Mock -CommandName Get-SqlEngineProperties -MockWith {
                return @{
                    SQLSvcAccountUsername = 'COMPANY\SqlAccount'
                    AgtSvcAccountUsername = 'COMPANY\AgentAccount'
                    SqlSvcStartupType     = 'Auto'
                    AgtSvcStartupType     = 'Auto'
                    SQLCollation          = 'Finnish_Swedish_CI_AS'
                    IsClustered           = $false
                    InstallSQLDataDir     = "C:\Program Files\Microsoft SQL Server\MSSQL$($MockSqlMajorVersion).MSSQLSERVER\MSSQL"
                    SQLUserDBDir          = "C:\Program Files\Microsoft SQL Server\MSSQL$($MockSqlMajorVersion).MSSQLSERVER\MSSQL\DATA\"
                    SQLUserDBLogDir       = "C:\Program Files\Microsoft SQL Server\MSSQL$($MockSqlMajorVersion).MSSQLSERVER\MSSQL\DATA\"
                    SQLBackupDir          = "C:\Program Files\Microsoft SQL Server\MSSQL$($MockSqlMajorVersion).MSSQLSERVER\MSSQL\Backup"
                    SecurityMode          = 'Windows'
                }
            }

            Mock -CommandName Get-ServiceProperties -MockWith {
                return @{
                    UserName    = 'COMPANY\SqlAccount'
                    StartupType = 'Auto'
                }
            }

            Mock -CommandName Test-IsReplicationFeatureInstalled -MockWith {
                return $true
            }

            # If Get-CimInstance is used in any other way than those mocks with a ParameterFilter, then throw and error
            Mock -CommandName Get-CimInstance -MockWith {
                throw "Mock Get-CimInstance without a parameter filter should not be calle. It was called with unexpected parameters; ClassName=$ClassName, Filter=$Filter"
            }
            #endregion Mock Get-CimInstance

            Mock -CommandName Test-IsDQComponentInstalled -MockWith {
                return $true
            }

            Mock -CommandName Get-InstanceProgramPath -MockWith {
                return 'C:\Program Files\Microsoft SQL Server'
            }

            Mock -CommandName Get-TempDbProperties -MockWith {
                return @{
                    SQLTempDBDir           = 'M:\MSSQL\TempDb\Data'
                    SqlTempdbFileCount     = 1
                    SqlTempdbFileSize      = 200
                    SqlTempdbFileGrowth    = 10
                    SqlTempdbLogFileSize   = 20
                    SqlTempdbLogFileGrowth = 10
                }
            }

            Mock -CommandName Get-SqlRoleMembers -MockWith {
                return @('COMPANY\Stacy')
            }

            InModuleScope -ScriptBlock {
                $script:mockGetTargetResourceParameters = @{
                    InstanceName     = 'MSSQLSERVER'
                    SourceCredential = $null
                    SourcePath       = $TestDrive
                    FeatureFlag      = @()
                }
            }
        }

        It 'Should return the same values as passed as parameters' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockGetTargetResourceParameters

                $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
            }

            Should -Invoke -CommandName Connect-UncPath -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Disconnect-UncPath -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-PSDrive -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Service -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Test-IsReplicationFeatureInstalled -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-InstanceProgramPath -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Test-IsSsmsInstalled -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Test-IsSsmsAdvancedInstalled -Exactly -Times 1 -Scope It
        }

        It 'Should return correct names of installed features' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockGetTargetResourceParameters

                $result.Features | Should -Be 'SQLENGINE,REPLICATION,DQ,FULLTEXT,RS,AS,IS,DQC,BOL,CONN,BC,SDK,MDS'
            }
        }

        It 'Should return the correct values in the hash table' {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockGetTargetResourceParameters

                $result.SourcePath | Should -Be $TestDrive
                $result.InstanceName | Should -Be 'MSSQLSERVER'
                $result.InstanceID | Should -Be 'MSSQLSERVER'
                $result.InstallSharedDir | Should -Be 'C:\Program Files\Microsoft SQL Server'
                $result.InstallSharedWOWDir | Should -Be 'C:\Program Files (x86)\Microsoft SQL Server'
                $result.SQLSvcAccountUsername | Should -Be 'COMPANY\SqlAccount'
                $result.AgtSvcAccountUsername | Should -Be 'COMPANY\AgentAccount'
                $result.SqlCollation | Should -Be 'Finnish_Swedish_CI_AS'
                $result.SQLSysAdminAccounts | Should -Be 'COMPANY\Stacy'
                $result.SecurityMode | Should -Be 'Windows'
                $result.InstallSQLDataDir | Should -Be "C:\Program Files\Microsoft SQL Server\MSSQL$($MockSqlMajorVersion).MSSQLSERVER\MSSQL"
                $result.SQLUserDBDir | Should -Be "C:\Program Files\Microsoft SQL Server\MSSQL$($MockSqlMajorVersion).MSSQLSERVER\MSSQL\DATA\"
                $result.SQLUserDBLogDir | Should -Be "C:\Program Files\Microsoft SQL Server\MSSQL$($MockSqlMajorVersion).MSSQLSERVER\MSSQL\DATA\"
                $result.SQLBackupDir | Should -Be "C:\Program Files\Microsoft SQL Server\MSSQL$($MockSqlMajorVersion).MSSQLSERVER\MSSQL\Backup"
                $result.FTSvcAccountUsername | Should -Be 'COMPANY\SqlAccount'
                $result.RSSvcAccountUsername | Should -Be 'COMPANY\SqlAccount'
                $result.ASSvcAccountUsername | Should -Be 'COMPANY\SqlAccount'
                $result.ASCollation | Should -Be 'Finnish_Swedish_CI_AS'
                $result.ASSysAdminAccounts | Should -Be @('COMPANY\Stacy', 'COMPANY\SSAS Administrators')
                $result.ASDataDir | Should -Be 'C:\Program Files\Microsoft SQL Server\OLAP\Data'
                $result.ASLogDir | Should -Be 'C:\Program Files\Microsoft SQL Server\OLAP\Log'
                $result.ASBackupDir | Should -Be 'C:\Program Files\Microsoft SQL Server\OLAP\Backup'
                $result.ASTempDir | Should -Be 'C:\Program Files\Microsoft SQL Server\OLAP\Temp'
                $result.ASConfigDir | Should -Be 'C:\Program Files\Microsoft SQL Server\OLAP\Config'
                $result.ASServerMode | Should -Be 'MULTIDIMENSIONAL'
                $result.ISSvcAccountUsername | Should -Be 'COMPANY\SqlAccount'
                $result.SQLTempDBDir | Should -Be 'M:\MSSQL\TempDb\Data'
                $result.SqlTempdbFileCount | Should -Be 1
                $result.SqlTempdbFileSize | Should -Be 200
                $result.SqlTempdbFileGrowth | Should -Be 10
                $result.SqlTempdbLogFileSize | Should -Be 20
                $result.SqlTempdbLogFileGrowth | Should -Be 10
            }
        }

        It 'Should return the correct values when Analysis Services mode is POWERPIVOT' {
            $mockDynamicAnalysisServerMode = 'POWERPIVOT'

            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockGetTargetResourceParameters

                $result.ASServerMode | Should -Be 'POWERPIVOT'
            }
        }

        It 'Should return the correct values when Analysis Services mode is TABULAR' {
            $mockDynamicAnalysisServerMode = 'TABULAR'

            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockGetTargetResourceParameters

                $result.ASServerMode | Should -Be 'TABULAR'
            }

            # Return the state to the default for all other tests.
            $mockDynamicAnalysisServerMode = 'MULTIDIMENSIONAL'
        }

        It 'Should return the correct type and value for property ASSysAdminAccounts' {
            <#
                This is a regression test for issue #691.
                This sets administrators to only one for mock Connect-SQLAnalysis.
            #>
            $mockDynamicSqlAnalysisAdmins = 'COMPANY\AnalysisAdmin'

            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockGetTargetResourceParameters

                Write-Output -InputObject $result.ASSysAdminAccounts -NoEnumerate | Should -BeOfType [System.String[]]
                $result.ASSysAdminAccounts | Should -Be 'COMPANY\AnalysisAdmin'
            }

            # Setting back the default administrators for mock Connect-SQLAnalysis.
            $mockDynamicSqlAnalysisAdmins = @('COMPANY\Stacy', 'COMPANY\SSAS Administrators')
        }
    }

    Context 'When using SourceCredential parameter and SQL Server version is <MockSqlMajorVersion> and the system is not in the desired state for default instance' -ForEach $testProductVersion {
        BeforeAll {
            Mock -CommandName Get-TempDbProperties -MockWith {
                return @{
                    SQLTempDBDir           = 'M:\MSSQL\TempDb\Data'
                    SqlTempdbFileCount     = 1
                    SqlTempdbFileSize      = 200
                    SqlTempdbFileGrowth    = 10
                    SqlTempdbLogFileSize   = 20
                    SqlTempdbLogFileGrowth = 10
                }
            }

            Mock -CommandName Test-IsSsmsInstalled -MockWith {
                return $false
            }

            Mock -CommandName Test-IsSsmsAdvancedInstalled -MockWith {
                return $false
            }

            Mock -CommandName Connect-UncPath
            Mock -CommandName Disconnect-UncPath
            Mock -CommandName Get-Service -MockWith $mockGetService_NoServices
            Mock -CommandName Get-InstanceProgramPath -MockWith {
                return 'C:\Program Files\Microsoft SQL Server'
            }

            Mock -CommandName Get-InstalledSharedFeatures -MockWith {
                return @()
            }

            InModuleScope -Parameters $_ -ScriptBlock {
                $testDrive_DriveShare = (Split-Path -Path $TestDrive -Qualifier) -replace ':', '$'
                $script:mockSourcePathUNC = Join-Path -Path "\\localhost\$testDrive_DriveShare" -ChildPath (Split-Path -Path $TestDrive -NoQualifier)

                $script:mockGetTargetResourceParameters = @{
                    InstanceName     = 'MSSQLSERVER'
                    SourceCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @('COMPANY\sqladmin', ('dummyPassw0rd' | ConvertTo-SecureString -asPlainText -Force))
                    SourcePath       = $mockSourcePathUNC
                    SqlVersion       = ('{0}.0' -f $MockSqlMajorVersion)
                }
            }
        }

        It 'Should return the same values as passed as parameters' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockGetTargetResourceParameters

                $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
            }

            Should -Invoke -CommandName Connect-UncPath -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Disconnect-UncPath -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-PSDrive -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Service -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-InstanceProgramPath -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Test-IsSsmsInstalled -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Test-IsSsmsAdvancedInstalled -Exactly -Times 1 -Scope It
        }

        It 'Should not return any names of installed features' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockGetTargetResourceParameters

                $result.Features | Should -Be ''
            }
        }

        It 'Should return the correct values in the hash table' {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockGetTargetResourceParameters

                $result.SourcePath | Should -Be $mockSourcePathUNC
                $result.InstanceName | Should -Be 'MSSQLSERVER'
                $result.InstanceID | Should -BeNullOrEmpty
                $result.InstallSharedDir | Should -BeNullOrEmpty
                $result.InstallSharedWOWDir | Should -BeNullOrEmpty
                $result.SQLSvcAccountUsername | Should -BeNullOrEmpty
                $result.AgtSvcAccountUsername | Should -BeNullOrEmpty
                $result.SqlCollation | Should -BeNullOrEmpty
                $result.SQLSysAdminAccounts | Should -BeNullOrEmpty
                $result.SecurityMode | Should -BeNullOrEmpty
                $result.InstallSQLDataDir | Should -BeNullOrEmpty
                $result.SQLUserDBDir | Should -BeNullOrEmpty
                $result.SQLUserDBLogDir | Should -BeNullOrEmpty
                $result.SQLBackupDir | Should -BeNullOrEmpty
                $result.FTSvcAccountUsername | Should -BeNullOrEmpty
                $result.RSSvcAccountUsername | Should -BeNullOrEmpty
                $result.ASSvcAccountUsername | Should -BeNullOrEmpty
                $result.ASCollation | Should -BeNullOrEmpty
                $result.ASSysAdminAccounts | Should -BeNullOrEmpty
                $result.ASDataDir | Should -BeNullOrEmpty
                $result.ASLogDir | Should -BeNullOrEmpty
                $result.ASBackupDir | Should -BeNullOrEmpty
                $result.ASTempDir | Should -BeNullOrEmpty
                $result.ASConfigDir | Should -BeNullOrEmpty
                $result.ISSvcAccountUsername | Should -BeNullOrEmpty
                $result.SqlVersion | Should -Be $MockSqlMajorVersion
            }
        }
    }

    Context 'When SQL Server version is <MockSqlMajorVersion> and the system is not in the desired state for features ''CONN'', ''SDK'' and ''BC''' -ForEach $testProductVersion {
        BeforeAll {
            Mock -CommandName Get-TempDbProperties -MockWith {
                return @{
                    SQLTempDBDir           = 'M:\MSSQL\TempDb\Data'
                    SqlTempdbFileCount     = 1
                    SqlTempdbFileSize      = 200
                    SqlTempdbFileGrowth    = 10
                    SqlTempdbLogFileSize   = 20
                    SqlTempdbLogFileGrowth = 10
                }
            }

            Mock -CommandName Get-SqlRoleMembers -MockWith {
                return @('COMPANY\Stacy')
            }

            Mock -CommandName Test-IsSsmsInstalled -MockWith {
                return $true
            }

            Mock -CommandName Test-IsSsmsAdvancedInstalled -MockWith {
                return $true
            }

            Mock -CommandName Connect-UncPath
            Mock -CommandName Disconnect-UncPath
            Mock -CommandName Get-Service -MockWith $mockGetService_DefaultInstance

            Mock -CommandName Get-SqlEngineProperties -MockWith {
                return @{
                    SQLSvcAccountUsername = 'COMPANY\SqlAccount'
                    AgtSvcAccountUsername = 'COMPANY\AgentAccount'
                    SqlSvcStartupType     = 'Auto'
                    AgtSvcStartupType     = 'Auto'
                    SQLCollation          = 'Finnish_Swedish_CI_AS'
                    SecurityMode          = 'Windows'
                }
            }

            Mock -CommandName Get-ServiceProperties -MockWith {
                return @{
                    UserName    = 'COMPANY\SqlAccount'
                    StartupType = 'Auto'
                }
            }

            Mock -CommandName Test-IsReplicationFeatureInstalled -MockWith {
                return $true
            }

            Mock -CommandName Test-IsDQComponentInstalled -MockWith {
                return $true
            }

            Mock -CommandName Get-InstalledSharedFeatures -MockWith {
                return @(
                    'DQC'
                    'BOL'
                    'CONN'
                    'BC'
                    'SDK'
                    'MDS'
                )
            }

            Mock -CommandName Get-InstanceProgramPath -MockWith {
                return 'C:\Program Files\Microsoft SQL Server'
            }

            InModuleScope -ScriptBlock {
                $script:mockGetTargetResourceParameters = @{
                    InstanceName     = 'MSSQLSERVER'
                    SourceCredential = $null
                    SourcePath       = $TestDrive
                }
            }
        }

        It 'Should return correct names of installed features' {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockGetTargetResourceParameters

                if ($MockSqlMajorVersion -in ('13', '14', '15'))
                {
                    $result.Features | Should -Match 'SQLENGINE\b'
                    $result.Features | Should -Match 'REPLICATION\b'
                    $result.Features | Should -Match 'DQ\b'
                    $result.Features | Should -Match 'DQC\b'
                    $result.Features | Should -Match 'FULLTEXT\b'
                    $result.Features | Should -Match 'RS\b'
                    $result.Features | Should -Match 'AS\b'
                    $result.Features | Should -Match 'IS\b'
                    $result.Features | Should -Match 'BOL\b'
                    $result.Features | Should -Match 'MDS\b'
                }
                else
                {
                    $result.Features | Should -Match 'SQLENGINE\b'
                    $result.Features | Should -Match 'REPLICATION\b'
                    $result.Features | Should -Match 'DQ\b'
                    $result.Features | Should -Match 'DQC\b'
                    $result.Features | Should -Match 'FULLTEXT\b'
                    $result.Features | Should -Match 'RS\b'
                    $result.Features | Should -Match 'AS\b'
                    $result.Features | Should -Match 'IS\b'
                    $result.Features | Should -Match 'BOL\b'
                    $result.Features | Should -Match 'MDS\b'
                    $result.Features | Should -Match 'SSMS\b'
                    $result.Features | Should -Match 'ADV_SSMS\b'
                }
            }
        }
    }

    Context 'When SQL Server version is <MockSqlMajorVersion> and the system is in the desired state for default instance' -ForEach $testProductVersion {
        BeforeAll {
            Mock -CommandName Get-TempDbProperties -MockWith {
                return @{
                    SQLTempDBDir           = 'M:\MSSQL\TempDb\Data'
                    SqlTempdbFileCount     = 1
                    SqlTempdbFileSize      = 200
                    SqlTempdbFileGrowth    = 10
                    SqlTempdbLogFileSize   = 20
                    SqlTempdbLogFileGrowth = 10
                }
            }

            Mock -CommandName Test-IsSsmsInstalled -MockWith {
                return $true
            }

            Mock -CommandName Test-IsSsmsAdvancedInstalled -MockWith {
                return $true
            }

            Mock -CommandName Connect-UncPath
            Mock -CommandName Disconnect-UncPath
            Mock -CommandName Get-Service -MockWith $mockGetService_DefaultInstance

            Mock -CommandName Get-SqlEngineProperties -MockWith {
                return @{
                    SQLSvcAccountUsername = 'COMPANY\SqlAccount'
                    AgtSvcAccountUsername = 'COMPANY\AgentAccount'
                    SqlSvcStartupType     = 'Auto'
                    AgtSvcStartupType     = 'Auto'
                    SQLCollation          = 'Finnish_Swedish_CI_AS'
                    IsClustered           = $false
                    InstallSQLDataDir     = "C:\Program Files\Microsoft SQL Server\MSSQL$($MockSqlMajorVersion).MSSQLSERVER\MSSQL"
                    SQLUserDBDir          = "C:\Program Files\Microsoft SQL Server\MSSQL$($MockSqlMajorVersion).MSSQLSERVER\MSSQL\DATA\"
                    SQLUserDBLogDir       = "C:\Program Files\Microsoft SQL Server\MSSQL$($MockSqlMajorVersion).MSSQLSERVER\MSSQL\DATA\"
                    SQLBackupDir          = "C:\Program Files\Microsoft SQL Server\MSSQL$($MockSqlMajorVersion).MSSQLSERVER\MSSQL\Backup"
                    SecurityMode          = 'Windows'
                }
            }

            Mock -CommandName Get-ServiceProperties -MockWith {
                return @{
                    UserName    = 'COMPANY\SqlAccount'
                    StartupType = 'Auto'
                }
            }

            Mock -CommandName Test-IsReplicationFeatureInstalled -MockWith {
                return $true
            }

            Mock -CommandName Test-IsDQComponentInstalled -MockWith {
                return $true
            }

            Mock -CommandName Get-InstanceProgramPath -MockWith {
                return 'C:\Program Files\Microsoft SQL Server'
            }

            Mock -CommandName Get-InstalledSharedFeatures -MockWith {
                return @(
                    'DQC'
                    'BOL'
                    'CONN'
                    'BC'
                    'SDK'
                    'MDS'
                )
            }

            Mock -CommandName Get-SqlRoleMembers -MockWith {
                return @('COMPANY\Stacy')
            }

            InModuleScope -ScriptBlock {
                $script:mockGetTargetResourceParameters = @{
                    InstanceName     = 'MSSQLSERVER'
                    SourceCredential = $null
                    SourcePath       = $TestDrive
                }
            }
        }

        It 'Should return the same values as passed as parameters' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockGetTargetResourceParameters

                $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
            }

            Should -Invoke -CommandName Connect-UncPath -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Disconnect-UncPath -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-PSDrive -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Service -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Test-IsReplicationFeatureInstalled -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-InstanceProgramPath -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Test-IsSsmsInstalled -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Test-IsSsmsAdvancedInstalled -Exactly -Times 1 -Scope It
        }

        It 'Should return correct names of installed features' {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockGetTargetResourceParameters

                if ($MockSqlMajorVersion -in ('13', '14', '15'))
                {
                    $result.Features | Should -Match 'SQLENGINE\b'
                    $result.Features | Should -Match 'REPLICATION\b'
                    $result.Features | Should -Match 'DQ\b'
                    $result.Features | Should -Match 'DQC\b'
                    $result.Features | Should -Match 'FULLTEXT\b'
                    $result.Features | Should -Match 'RS\b'
                    $result.Features | Should -Match 'AS\b'
                    $result.Features | Should -Match 'IS\b'
                    $result.Features | Should -Match 'BOL\b'
                    $result.Features | Should -Match 'MDS\b'
                    $result.Features | Should -Match 'CONN\b'
                    $result.Features | Should -Match 'BC\b'
                    $result.Features | Should -Match 'SDK\b'
                }
                else
                {
                    $result.Features | Should -Match 'SQLENGINE\b'
                    $result.Features | Should -Match 'REPLICATION\b'
                    $result.Features | Should -Match 'DQ\b'
                    $result.Features | Should -Match 'DQC\b'
                    $result.Features | Should -Match 'FULLTEXT\b'
                    $result.Features | Should -Match 'RS\b'
                    $result.Features | Should -Match 'AS\b'
                    $result.Features | Should -Match 'IS\b'
                    $result.Features | Should -Match 'BOL\b'
                    $result.Features | Should -Match 'MDS\b'
                    $result.Features | Should -Match 'CONN\b'
                    $result.Features | Should -Match 'BC\b'
                    $result.Features | Should -Match 'SDK\b'
                    $result.Features | Should -Match 'SSMS\b'
                    $result.Features | Should -Match 'ADV_SSMS\b'
                }
            }
        }

        It 'Should return the correct values in the hash table' {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockGetTargetResourceParameters

                $result.SourcePath | Should -Be $TestDrive
                $result.InstanceName | Should -Be 'MSSQLSERVER'
                $result.InstanceID | Should -Be 'MSSQLSERVER'
                $result.InstallSharedDir | Should -Be 'C:\Program Files\Microsoft SQL Server'
                $result.InstallSharedWOWDir | Should -Be 'C:\Program Files (x86)\Microsoft SQL Server'
                $result.SQLSvcAccountUsername | Should -Be 'COMPANY\SqlAccount'
                $result.AgtSvcAccountUsername | Should -Be 'COMPANY\AgentAccount'
                $result.SqlCollation | Should -Be 'Finnish_Swedish_CI_AS'
                $result.SQLSysAdminAccounts | Should -Be 'COMPANY\Stacy'
                $result.SecurityMode | Should -Be 'Windows'
                $result.InstallSQLDataDir | Should -Be "C:\Program Files\Microsoft SQL Server\MSSQL$($MockSqlMajorVersion).MSSQLSERVER\MSSQL"
                $result.SQLUserDBDir | Should -Be "C:\Program Files\Microsoft SQL Server\MSSQL$($MockSqlMajorVersion).MSSQLSERVER\MSSQL\DATA\"
                $result.SQLUserDBLogDir | Should -Be "C:\Program Files\Microsoft SQL Server\MSSQL$($MockSqlMajorVersion).MSSQLSERVER\MSSQL\DATA\"
                $result.SQLBackupDir | Should -Be "C:\Program Files\Microsoft SQL Server\MSSQL$($MockSqlMajorVersion).MSSQLSERVER\MSSQL\Backup"
                $result.FTSvcAccountUsername | Should -Be 'COMPANY\SqlAccount'
                $result.RSSvcAccountUsername | Should -Be 'COMPANY\SqlAccount'
                $result.ASSvcAccountUsername | Should -Be 'COMPANY\SqlAccount'
                $result.ASCollation | Should -Be 'Finnish_Swedish_CI_AS'
                $result.ASSysAdminAccounts | Should -Be @('COMPANY\Stacy', 'COMPANY\SSAS Administrators')
                $result.ASDataDir | Should -Be 'C:\Program Files\Microsoft SQL Server\OLAP\Data'
                $result.ASLogDir | Should -Be 'C:\Program Files\Microsoft SQL Server\OLAP\Log'
                $result.ASBackupDir | Should -Be 'C:\Program Files\Microsoft SQL Server\OLAP\Backup'
                $result.ASTempDir | Should -Be 'C:\Program Files\Microsoft SQL Server\OLAP\Temp'
                $result.ASConfigDir | Should -Be 'C:\Program Files\Microsoft SQL Server\OLAP\Config'
                $result.ASServerMode | Should -Be 'MULTIDIMENSIONAL'
                $result.ISSvcAccountUsername | Should -Be 'COMPANY\SqlAccount'
            }
        }

        It 'Should return the correct values in the hash table' {
            $mockDynamicAnalysisServerMode = 'POWERPIVOT'

            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockGetTargetResourceParameters

                $result.ASServerMode | Should -Be 'POWERPIVOT'
            }
        }

        It 'Should return the correct values in the hash table' {
            $mockDynamicAnalysisServerMode = 'TABULAR'

            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockGetTargetResourceParameters

                $result.ASServerMode | Should -Be 'TABULAR'
            }

            # Return the state to the default for all other tests.
            $mockDynamicAnalysisServerMode = 'MULTIDIMENSIONAL'
        }

        <#
            This is a regression test for issue #691.
            This sets administrators to only one for mock Connect-SQLAnalysis.
        #>

        It 'Should return the correct type and value for property ASSysAdminAccounts' {
            $mockDynamicSqlAnalysisAdmins = 'COMPANY\AnalysisAdmin'

            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockGetTargetResourceParameters

                Write-Output -NoEnumerate $result.ASSysAdminAccounts | Should -BeOfType [System.String[]]
                $result.ASSysAdminAccounts | Should -Be 'COMPANY\AnalysisAdmin'
            }

            # Setting back the default administrators for mock Connect-SQLAnalysis.
            $mockDynamicSqlAnalysisAdmins = @('COMPANY\Stacy', 'COMPANY\SSAS Administrators')
        }
    }

    Context 'When using SourceCredential parameter and SQL Server version is <MockSqlMajorVersion> and the system is in the desired state for default instance' -ForEach $testProductVersion {
        BeforeAll {
            Mock -CommandName Get-TempDbProperties -MockWith {
                return @{
                    SQLTempDBDir           = 'M:\MSSQL\TempDb\Data'
                    SqlTempdbFileCount     = 1
                    SqlTempdbFileSize      = 200
                    SqlTempdbFileGrowth    = 10
                    SqlTempdbLogFileSize   = 20
                    SqlTempdbLogFileGrowth = 10
                }
            }

            Mock -CommandName Test-IsSsmsInstalled -MockWith {
                return $true
            }

            Mock -CommandName Test-IsSsmsAdvancedInstalled -MockWith {
                return $true
            }

            Mock -CommandName Connect-UncPath
            Mock -CommandName Disconnect-UncPath
            Mock -CommandName Get-Service -MockWith $mockGetService_DefaultInstance

            Mock -CommandName Get-SqlEngineProperties -MockWith {
                return @{
                    SQLSvcAccountUsername = 'COMPANY\SqlAccount'
                    AgtSvcAccountUsername = 'COMPANY\AgentAccount'
                    SqlSvcStartupType     = 'Auto'
                    AgtSvcStartupType     = 'Auto'
                    SQLCollation          = 'Finnish_Swedish_CI_AS'
                    IsClustered           = $false
                    InstallSQLDataDir     = "C:\Program Files\Microsoft SQL Server\MSSQL$($MockSqlMajorVersion).MSSQLSERVER\MSSQL"
                    SQLUserDBDir          = "C:\Program Files\Microsoft SQL Server\MSSQL$($MockSqlMajorVersion).MSSQLSERVER\MSSQL\DATA\"
                    SQLUserDBLogDir       = "C:\Program Files\Microsoft SQL Server\MSSQL$($MockSqlMajorVersion).MSSQLSERVER\MSSQL\DATA\"
                    SQLBackupDir          = "C:\Program Files\Microsoft SQL Server\MSSQL$($MockSqlMajorVersion).MSSQLSERVER\MSSQL\Backup"
                    SecurityMode          = 'Windows'
                }
            }

            Mock -CommandName Get-ServiceProperties -MockWith {
                return @{
                    UserName    = 'COMPANY\SqlAccount'
                    StartupType = 'Auto'
                }
            }

            Mock -CommandName Test-IsReplicationFeatureInstalled -MockWith {
                return $true
            }

            Mock -CommandName Test-IsDQComponentInstalled -MockWith {
                return $true
            }

            Mock -CommandName Get-InstanceProgramPath -MockWith {
                return 'C:\Program Files\Microsoft SQL Server'
            }

            Mock -CommandName Get-InstalledSharedFeatures -MockWith {
                return @(
                    'DQC'
                    'BOL'
                    'CONN'
                    'BC'
                    'SDK'
                    'MDS'
                )
            }

            Mock -CommandName Get-SqlRoleMembers -MockWith {
                return @('COMPANY\Stacy')
            }

            InModuleScope -ScriptBlock {
                $testDrive_DriveShare = (Split-Path -Path $TestDrive -Qualifier) -replace ':', '$'
                $mockSourcePathUNC = Join-Path -Path "\\localhost\$testDrive_DriveShare" -ChildPath (Split-Path -Path $TestDrive -NoQualifier)

                $script:mockGetTargetResourceParameters = @{
                    InstanceName     = 'MSSQLSERVER'
                    SourceCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @('COMPANY\sqladmin', ('dummyPassw0rd' | ConvertTo-SecureString -asPlainText -Force))
                    SourcePath       = $mockSourcePathUNC
                }
            }
        }

        It 'Should return the same values as passed as parameters' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockGetTargetResourceParameters

                $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
            }

            Should -Invoke -CommandName Connect-UncPath -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Disconnect-UncPath -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-PSDrive -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Service -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Test-IsReplicationFeatureInstalled -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-InstanceProgramPath -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Test-IsSsmsInstalled -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Test-IsSsmsAdvancedInstalled -Exactly -Times 1 -Scope It
        }

        It 'Should return correct names of installed features' {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockGetTargetResourceParameters

                if ($MockSqlMajorVersion -in ('13', '14', '15'))
                {
                    $result.Features | Should -Match 'SQLENGINE\b'
                    $result.Features | Should -Match 'REPLICATION\b'
                    $result.Features | Should -Match 'DQ\b'
                    $result.Features | Should -Match 'DQC\b'
                    $result.Features | Should -Match 'FULLTEXT\b'
                    $result.Features | Should -Match 'RS\b'
                    $result.Features | Should -Match 'AS\b'
                    $result.Features | Should -Match 'IS\b'
                    $result.Features | Should -Match 'BOL\b'
                    $result.Features | Should -Match 'MDS\b'
                    $result.Features | Should -Match 'CONN\b'
                    $result.Features | Should -Match 'BC\b'
                    $result.Features | Should -Match 'SDK\b'
                }
                else
                {
                    $result.Features | Should -Match 'SQLENGINE\b'
                    $result.Features | Should -Match 'REPLICATION\b'
                    $result.Features | Should -Match 'DQ\b'
                    $result.Features | Should -Match 'DQC\b'
                    $result.Features | Should -Match 'FULLTEXT\b'
                    $result.Features | Should -Match 'RS\b'
                    $result.Features | Should -Match 'AS\b'
                    $result.Features | Should -Match 'IS\b'
                    $result.Features | Should -Match 'BOL\b'
                    $result.Features | Should -Match 'MDS\b'
                    $result.Features | Should -Match 'CONN\b'
                    $result.Features | Should -Match 'BC\b'
                    $result.Features | Should -Match 'SDK\b'
                    $result.Features | Should -Match 'SSMS\b'
                    $result.Features | Should -Match 'ADV_SSMS\b'
                }
            }
        }

        It 'Should return the correct values in the hash table' {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockGetTargetResourceParameters

                $result.SourcePath | Should -Be $mockSourcePathUNC
                $result.InstanceName | Should -Be 'MSSQLSERVER'
                $result.InstanceID | Should -Be 'MSSQLSERVER'
                $result.InstallSharedDir | Should -Be 'C:\Program Files\Microsoft SQL Server'
                $result.InstallSharedWOWDir | Should -Be 'C:\Program Files (x86)\Microsoft SQL Server'
                $result.SQLSvcAccountUsername | Should -Be 'COMPANY\SqlAccount'
                $result.AgtSvcAccountUsername | Should -Be 'COMPANY\AgentAccount'
                $result.SqlCollation | Should -Be 'Finnish_Swedish_CI_AS'
                $result.SQLSysAdminAccounts | Should -Be 'COMPANY\Stacy'
                $result.SecurityMode | Should -Be 'Windows'
                $result.InstallSQLDataDir | Should -Be "C:\Program Files\Microsoft SQL Server\MSSQL$($MockSqlMajorVersion).MSSQLSERVER\MSSQL"
                $result.SQLUserDBDir | Should -Be "C:\Program Files\Microsoft SQL Server\MSSQL$($MockSqlMajorVersion).MSSQLSERVER\MSSQL\DATA\"
                $result.SQLUserDBLogDir | Should -Be "C:\Program Files\Microsoft SQL Server\MSSQL$($MockSqlMajorVersion).MSSQLSERVER\MSSQL\DATA\"
                $result.SQLBackupDir | Should -Be "C:\Program Files\Microsoft SQL Server\MSSQL$($MockSqlMajorVersion).MSSQLSERVER\MSSQL\Backup"
                $result.FTSvcAccountUsername | Should -Be 'COMPANY\SqlAccount'
                $result.RSSvcAccountUsername | Should -Be 'COMPANY\SqlAccount'
                $result.ASSvcAccountUsername | Should -Be 'COMPANY\SqlAccount'
                $result.ASCollation | Should -Be 'Finnish_Swedish_CI_AS'
                $result.ASSysAdminAccounts | Should -Be @('COMPANY\Stacy', 'COMPANY\SSAS Administrators')
                $result.ASDataDir | Should -Be 'C:\Program Files\Microsoft SQL Server\OLAP\Data'
                $result.ASLogDir | Should -Be 'C:\Program Files\Microsoft SQL Server\OLAP\Log'
                $result.ASBackupDir | Should -Be 'C:\Program Files\Microsoft SQL Server\OLAP\Backup'
                $result.ASTempDir | Should -Be 'C:\Program Files\Microsoft SQL Server\OLAP\Temp'
                $result.ASConfigDir | Should -Be 'C:\Program Files\Microsoft SQL Server\OLAP\Config'
                $result.ISSvcAccountUsername | Should -Be 'COMPANY\SqlAccount'
            }
        }
    }

    Context 'When SQL Server version is <MockSqlMajorVersion> and the system is not in the desired state for named instance' -ForEach $testProductVersion {
        BeforeAll {
            Mock -CommandName Test-IsSsmsInstalled -MockWith {
                return $false
            }

            Mock -CommandName Test-IsSsmsAdvancedInstalled -MockWith {
                return $false
            }

            Mock -CommandName Get-Service -MockWith $mockGetService_NoServices
            Mock -CommandName Test-IsDQComponentInstalled -MockWith {
                return $false
            }

            Mock -CommandName Get-InstanceProgramPath -MockWith {
                return 'C:\Program Files\Microsoft SQL Server'
            }

            Mock -CommandName Get-InstalledSharedFeatures -MockWith {
                return @()
            }

            InModuleScope -ScriptBlock {
                $script:mockGetTargetResourceParameters = @{
                    InstanceName     = 'TEST'
                    SourceCredential = $null
                    SourcePath       = $TestDrive
                }
            }
        }

        It 'Should return the same values as passed as parameters' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockGetTargetResourceParameters

                $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
            }

            Should -Invoke -CommandName Get-PSDrive -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Service -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-InstanceProgramPath -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Test-IsSsmsInstalled -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Test-IsSsmsAdvancedInstalled -Exactly -Times 1 -Scope It
        }

        It 'Should not return any names of installed features' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockGetTargetResourceParameters

                $result.Features | Should -Be ''
            }
        }

        It 'Should return the correct values in the hash table' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockGetTargetResourceParameters

                $result.SourcePath | Should -Be $TestDrive
                $result.InstanceName | Should -Be 'TEST'
                $result.InstanceID | Should -BeNullOrEmpty
                $result.InstallSharedDir | Should -BeNullOrEmpty
                $result.InstallSharedWOWDir | Should -BeNullOrEmpty
                $result.SQLSvcAccountUsername | Should -BeNullOrEmpty
                $result.AgtSvcAccountUsername | Should -BeNullOrEmpty
                $result.SqlCollation | Should -BeNullOrEmpty
                $result.SQLSysAdminAccounts | Should -BeNullOrEmpty
                $result.SecurityMode | Should -BeNullOrEmpty
                $result.InstallSQLDataDir | Should -BeNullOrEmpty
                $result.SQLUserDBDir | Should -BeNullOrEmpty
                $result.SQLUserDBLogDir | Should -BeNullOrEmpty
                $result.SQLBackupDir | Should -BeNullOrEmpty
                $result.FTSvcAccountUsername | Should -BeNullOrEmpty
                $result.RSSvcAccountUsername | Should -BeNullOrEmpty
                $result.ASSvcAccountUsername | Should -BeNullOrEmpty
                $result.ASCollation | Should -BeNullOrEmpty
                $result.ASSysAdminAccounts | Should -BeNullOrEmpty
                $result.ASDataDir | Should -BeNullOrEmpty
                $result.ASLogDir | Should -BeNullOrEmpty
                $result.ASBackupDir | Should -BeNullOrEmpty
                $result.ASTempDir | Should -BeNullOrEmpty
                $result.ASConfigDir | Should -BeNullOrEmpty
                $result.ISSvcAccountUsername | Should -BeNullOrEmpty
            }
        }
    }

    Context 'When SQL Server version is <MockSqlMajorVersion> and the system is in the desired state for named instance' -ForEach $testProductVersion {
        BeforeAll {
            $mockGetService_NamedInstance = {
                return @(
                    (
                        New-Object -TypeName Object |
                            Add-Member -MemberType NoteProperty -Name 'Name' -Value 'MSSQL$TEST' -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'StartName' -Value 'COMPANY\SqlAccount' -PassThru -Force |
                            Add-Member -MemberType NoteProperty -Name 'StartMode' -Value 'Auto' -PassThru -Force
                    ),
                    (
                        New-Object -TypeName Object |
                            Add-Member -MemberType NoteProperty -Name 'Name' -Value 'SQLAgent$TEST' -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'StartName' -Value 'COMPANY\AgentAccount' -PassThru -Force |
                            Add-Member -MemberType NoteProperty -Name 'StartMode' -Value 'Auto' -PassThru -Force
                    ),
                    (
                        New-Object -TypeName Object |
                            Add-Member -MemberType NoteProperty -Name 'Name' -Value 'MSSQLFDLauncher$TEST' -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'StartName' -Value 'COMPANY\SqlAccount' -PassThru -Force
                    ),
                    (
                        New-Object -TypeName Object |
                            Add-Member -MemberType NoteProperty -Name 'Name' -Value 'ReportServer$TEST' -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'StartName' -Value 'COMPANY\SqlAccount' -PassThru -Force |
                            Add-Member -MemberType NoteProperty -Name 'StartMode' -Value 'Auto' -PassThru -Force
                    ),
                    (
                        New-Object -TypeName Object |
                            Add-Member -MemberType NoteProperty -Name 'Name' -Value ('MsDtsServer{0}0' -f $MockSqlMajorVersion) -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'StartName' -Value 'COMPANY\SqlAccount' -PassThru -Force |
                            Add-Member -MemberType NoteProperty -Name 'StartMode' -Value 'Auto' -PassThru -Force
                    ),
                    (
                        New-Object -TypeName Object |
                            Add-Member -MemberType NoteProperty -Name 'Name' -Value 'MSOLAP$TEST' -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'StartName' -Value 'COMPANY\SqlAccount' -PassThru -Force |
                            Add-Member -MemberType NoteProperty -Name 'StartMode' -Value 'Auto' -PassThru -Force
                    )
                )
            }

            Mock -CommandName Get-Service -MockWith $mockGetService_NamedInstance
            Mock -CommandName Get-TempDbProperties -MockWith {
                return @{
                    SQLTempDBDir           = 'M:\MSSQL\TempDb\Data'
                    SqlTempdbFileCount     = 1
                    SqlTempdbFileSize      = 200
                    SqlTempdbFileGrowth    = 10
                    SqlTempdbLogFileSize   = 20
                    SqlTempdbLogFileGrowth = 10
                }
            }

            Mock -CommandName Test-IsSsmsInstalled -MockWith {
                return $true
            }

            Mock -CommandName Test-IsSsmsAdvancedInstalled -MockWith {
                return $true
            }

            Mock -CommandName Get-SqlEngineProperties -MockWith {
                return @{
                    SQLSvcAccountUsername = 'COMPANY\SqlAccount'
                    AgtSvcAccountUsername = 'COMPANY\AgentAccount'
                    SqlSvcStartupType     = 'Auto'
                    AgtSvcStartupType     = 'Auto'
                    SQLCollation          = 'Finnish_Swedish_CI_AS'
                    IsClustered           = $false
                    InstallSQLDataDir     = "C:\Program Files\Microsoft SQL Server\MSSQL$($MockSqlMajorVersion).TEST\MSSQL"
                    SQLUserDBDir          = "C:\Program Files\Microsoft SQL Server\MSSQL$($MockSqlMajorVersion).TEST\MSSQL\DATA\"
                    SQLUserDBLogDir       = "C:\Program Files\Microsoft SQL Server\MSSQL$($MockSqlMajorVersion).TEST\MSSQL\DATA\"
                    SQLBackupDir          = "C:\Program Files\Microsoft SQL Server\MSSQL$($MockSqlMajorVersion).TEST\MSSQL\Backup"
                    SecurityMode          = 'Windows'
                }
            }

            Mock -CommandName Get-ServiceProperties -MockWith {
                return @{
                    UserName    = 'COMPANY\SqlAccount'
                    StartupType = 'Auto'
                }
            }

            Mock -CommandName Test-IsReplicationFeatureInstalled -MockWith {
                return $true
            }

            Mock -CommandName Test-IsDQComponentInstalled -MockWith {
                return $true
            }

            Mock -CommandName Get-InstanceProgramPath -MockWith {
                return 'C:\Program Files\Microsoft SQL Server'
            }

            Mock -CommandName Get-InstalledSharedFeatures -MockWith {
                return @(
                    'DQC'
                    'BOL'
                    'CONN'
                    'BC'
                    'SDK'
                    'MDS'
                )
            }

            Mock -CommandName Get-SqlRoleMembers -MockWith {
                return @('COMPANY\Stacy')
            }

            InModuleScope -ScriptBlock {
                $script:mockGetTargetResourceParameters = @{
                    InstanceName     = 'TEST'
                    SourceCredential = $null
                    SourcePath       = $TestDrive
                }
            }
        }

        It 'Should return the same values as passed as parameters' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockGetTargetResourceParameters

                $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
            }

            Should -Invoke -CommandName Get-PSDrive -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Service -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Test-IsReplicationFeatureInstalled -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-InstanceProgramPath -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Test-IsSsmsInstalled -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Test-IsSsmsAdvancedInstalled -Exactly -Times 1 -Scope It
        }

        It 'Should return correct names of installed features' {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockGetTargetResourceParameters

                if ($MockSqlMajorVersion -in ('13', '14', '15'))
                {
                    $result.Features | Should -Match 'SQLENGINE\b'
                    $result.Features | Should -Match 'REPLICATION\b'
                    $result.Features | Should -Match 'DQ\b'
                    $result.Features | Should -Match 'DQC\b'
                    $result.Features | Should -Match 'FULLTEXT\b'
                    $result.Features | Should -Match 'RS\b'
                    $result.Features | Should -Match 'AS\b'
                    $result.Features | Should -Match 'IS\b'
                    $result.Features | Should -Match 'BOL\b'
                    $result.Features | Should -Match 'MDS\b'
                    $result.Features | Should -Match 'CONN\b'
                    $result.Features | Should -Match 'BC\b'
                    $result.Features | Should -Match 'SDK\b'
                }
                else
                {
                    $result.Features | Should -Match 'SQLENGINE\b'
                    $result.Features | Should -Match 'REPLICATION\b'
                    $result.Features | Should -Match 'DQ\b'
                    $result.Features | Should -Match 'DQC\b'
                    $result.Features | Should -Match 'FULLTEXT\b'
                    $result.Features | Should -Match 'RS\b'
                    $result.Features | Should -Match 'AS\b'
                    $result.Features | Should -Match 'IS\b'
                    $result.Features | Should -Match 'BOL\b'
                    $result.Features | Should -Match 'MDS\b'
                    $result.Features | Should -Match 'CONN\b'
                    $result.Features | Should -Match 'BC\b'
                    $result.Features | Should -Match 'SDK\b'
                    $result.Features | Should -Match 'SSMS\b'
                    $result.Features | Should -Match 'ADV_SSMS\b'
                }
            }
        }

        It 'Should return the correct values in the hash table' {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockGetTargetResourceParameters

                $result.SourcePath | Should -Be $TestDrive
                $result.InstanceName | Should -Be 'TEST'
                $result.InstanceID | Should -Be 'TEST'
                $result.InstallSharedDir | Should -Be 'C:\Program Files\Microsoft SQL Server'
                $result.InstallSharedWOWDir | Should -Be 'C:\Program Files (x86)\Microsoft SQL Server'
                $result.SQLSvcAccountUsername | Should -Be 'COMPANY\SqlAccount'
                $result.AgtSvcAccountUsername | Should -Be 'COMPANY\AgentAccount'
                $result.SqlCollation | Should -Be 'Finnish_Swedish_CI_AS'
                $result.SQLSysAdminAccounts | Should -Be 'COMPANY\Stacy'
                $result.SecurityMode | Should -Be 'Windows'
                $result.InstallSQLDataDir | Should -Be "C:\Program Files\Microsoft SQL Server\MSSQL$($MockSqlMajorVersion).TEST\MSSQL"
                $result.SQLUserDBDir | Should -Be "C:\Program Files\Microsoft SQL Server\MSSQL$($MockSqlMajorVersion).TEST\MSSQL\DATA\"
                $result.SQLUserDBLogDir | Should -Be "C:\Program Files\Microsoft SQL Server\MSSQL$($MockSqlMajorVersion).TEST\MSSQL\DATA\"
                $result.SQLBackupDir | Should -Be "C:\Program Files\Microsoft SQL Server\MSSQL$($MockSqlMajorVersion).TEST\MSSQL\Backup"
                $result.FTSvcAccountUsername | Should -Be 'COMPANY\SqlAccount'
                $result.RSSvcAccountUsername | Should -Be 'COMPANY\SqlAccount'
                $result.ASSvcAccountUsername | Should -Be 'COMPANY\SqlAccount'
                $result.ASCollation | Should -Be 'Finnish_Swedish_CI_AS'
                $result.ASSysAdminAccounts | Should -Be @('COMPANY\Stacy', 'COMPANY\SSAS Administrators')
                $result.ASDataDir | Should -Be 'C:\Program Files\Microsoft SQL Server\OLAP\Data'
                $result.ASLogDir | Should -Be 'C:\Program Files\Microsoft SQL Server\OLAP\Log'
                $result.ASBackupDir | Should -Be 'C:\Program Files\Microsoft SQL Server\OLAP\Backup'
                $result.ASTempDir | Should -Be 'C:\Program Files\Microsoft SQL Server\OLAP\Temp'
                $result.ASConfigDir | Should -Be 'C:\Program Files\Microsoft SQL Server\OLAP\Config'
                $result.ISSvcAccountUsername | Should -Be 'COMPANY\SqlAccount'
            }
        }
    }

    Context 'When SQL Server version is <MockSqlMajorVersion> and the system is not in the desired state for a clustered default instance' -ForEach $testProductVersion {
        BeforeAll {
            Mock -CommandName Get-TempDbProperties -MockWith {
                return @{
                    SQLTempDBDir           = 'M:\MSSQL\TempDb\Data'
                    SqlTempdbFileCount     = 1
                    SqlTempdbFileSize      = 200
                    SqlTempdbFileGrowth    = 10
                    SqlTempdbLogFileSize   = 20
                    SqlTempdbLogFileGrowth = 10
                }
            }

            Mock -CommandName Get-SqlRoleMembers -MockWith {
                return @('COMPANY\Stacy')
            }

            Mock -CommandName Get-CimInstance
            Mock -CommandName Get-InstanceProgramPath -MockWith {
                return 'C:\Program Files\Microsoft SQL Server'
            }

            Mock -CommandName Get-Service -MockWith $mockGetService_NoServices

            Mock -CommandName Get-InstalledSharedFeatures -MockWith {
                return @()
            }

            Mock -CommandName Test-IsSsmsInstalled -MockWith {
                return $true
            }

            Mock -CommandName Test-IsSsmsAdvancedInstalled -MockWith {
                return $true
            }

            InModuleScope -ScriptBlock {
                $script:mockGetTargetResourceParameters = @{
                    InstanceName     = 'MSSQLSERVER'
                    SourceCredential = $null
                    SourcePath       = $TestDrive
                }
            }
        }

        It 'Should not attempt to collect cluster information for a standalone instance' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $currentState = Get-TargetResource @mockGetTargetResourceParameters

                $currentState.FailoverClusterGroupName | Should -BeNullOrEmpty
                $currentState.FailoverClusterNetworkName | Should -BeNullOrEmpty
                $currentState.FailoverClusterIPAddress | Should -BeNullOrEmpty
            }
        }
    }

    Context 'When SQL Server version is <MockSqlMajorVersion> and the system is in the desired state for a clustered default instance' -ForEach $testProductVersion {
        BeforeAll {
            Mock -CommandName Get-Service -MockWith $mockGetService_DefaultInstance


            Mock -CommandName Test-IsSsmsInstalled -MockWith {
                return $true
            }

            Mock -CommandName Test-IsSsmsAdvancedInstalled -MockWith {
                return $true
            }

            Mock -CommandName Test-IsReplicationFeatureInstalled -MockWith {
                return $true
            }

            Mock -CommandName Test-IsDQComponentInstalled -MockWith {
                return $true
            }

            Mock -CommandName Get-TempDbProperties -MockWith {
                return @{
                    SQLTempDBDir           = 'M:\MSSQL\TempDb\Data'
                    SqlTempdbFileCount     = 1
                    SqlTempdbFileSize      = 200
                    SqlTempdbFileGrowth    = 10
                    SqlTempdbLogFileSize   = 20
                    SqlTempdbLogFileGrowth = 10
                }
            }

            Mock -CommandName Get-SqlRoleMembers -MockWith {
                return @('COMPANY\Stacy')
            }

            Mock -CommandName Get-SqlClusterProperties -MockWith {
                return @{
                    FailoverClusterNetworkName = 'TestDefaultCluster'
                    FailoverClusterGroupName   = 'SQL Server (MSSQLSERVER)'
                    FailoverClusterIPAddress   = '10.0.0.10'
                }
            }

            Mock -CommandName Get-InstanceProgramPath -MockWith {
                return 'C:\Program Files\Microsoft SQL Server'
            }

            Mock -CommandName Get-SqlEngineProperties -MockWith {
                return @{
                    IsClustered = $true
                }
            }

            Mock -CommandName Get-ServiceProperties -MockWith {
                return @{
                    UserName    = 'COMPANY\SqlAccount'
                    StartupType = 'Auto'
                }
            }

            Mock -CommandName Get-InstalledSharedFeatures -MockWith {
                return @(
                    'DQC'
                    'BOL'
                    'CONN'
                    'BC'
                    'SDK'
                    'MDS'
                )
            }

            InModuleScope -ScriptBlock {
                $script:mockGetTargetResourceParameters = @{
                    Action                     = 'InstallFailoverCluster'
                    InstanceName               = 'MSSQLSERVER'
                    SourceCredential           = $null
                    SourcePath                 = $TestDrive
                    FailoverClusterNetworkName = 'TestDefaultCluster'
                }
            }
        }

        It 'Should return correct cluster information' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $currentState = Get-TargetResource @mockGetTargetResourceParameters

                $currentState.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                $currentState.FailoverClusterGroupName | Should -Be 'SQL Server (MSSQLSERVER)'
                $currentState.FailoverClusterIPAddress | Should -Be '10.0.0.10'
                $currentSTate.FailoverClusterNetworkName | Should -Be 'TestDefaultCluster'
            }
        }
    }
}

Describe 'SqlSetup\Test-TargetResource' -Tag 'Test' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            # Default parameters that are used for the It-blocks
            $script:mockDefaultParameters = @{
                <#
                    These are written with both lower-case and upper-case to make sure we support that.
                    The feature list must be written in the order it is returned by the function Get-TargetResource.
                #>
                Features = 'SQLEngine,Replication,Dq,Dqc,FullText,Rs,As,Is,Bol,Conn,Bc,Sdk,Mds,Ssms,Adv_Ssms'
            }
        }
    }

    BeforeEach {
        InModuleScope -ScriptBlock {
            $script:mockTestTargetResourceParameters = $script:mockDefaultParameters.Clone()
        }
    }

    Context 'When setup action is Upgrade and parameter SqlVersion is passed' {
        It 'Should throw the correct exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestTargetResourceParameters.Action = 'Upgrade'
                $mockTestTargetResourceParameters.SqlVersion = '14.0'
                $mockTestTargetResourceParameters.InstanceName = 'MSSQLSERVER'
                $mockTestTargetResourceParameters.SourceCredential = $null
                $mockTestTargetResourceParameters.SourcePath = $TestDrive
                $mockTestTargetResourceParameters.ServerName = 'host.company.local'

                $mockErrorMessage = Get-InvalidOperationRecord -Message (
                    $script:localizedData.ParameterSqlVersionNotAllowedForSetupActionUpgrade
                )

                { Test-TargetResource @mockTestTargetResourceParameters } | Should -Throw -ExpectedMessage $mockErrorMessage
            }

        }
    }

    Context 'When the system is not in the desired state' {
        Context 'When no features are installed' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Features = ''
                    }
                }
            }

            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.InstanceName = 'MSSQLSERVER'
                    $mockTestTargetResourceParameters.SourceCredential = $null
                    $mockTestTargetResourceParameters.SourcePath = $TestDrive
                    $mockTestTargetResourceParameters.ServerName = 'host.company.local'

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeFalse
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }

            Context 'When using parameter SqlVersion' {
                It 'Should return $false' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $mockTestTargetResourceParameters.InstanceName = 'MSSQLSERVER'
                        $mockTestTargetResourceParameters.SourceCredential = $null
                        $mockTestTargetResourceParameters.SourcePath = $TestDrive
                        $mockTestTargetResourceParameters.ServerName = 'host.company.local'
                        $mockTestTargetResourceParameters.SqlVersion = '14.0'

                        $result = Test-TargetResource @mockTestTargetResourceParameters

                        $result | Should -BeFalse
                    }

                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                }
            }
        }

        Context 'When a clustered instance cannot be found' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Features                   = ''
                        FailoverClusterGroupName   = $null
                        FailoverClusterNetworkName = $null
                        FailoverClusterIPAddress   = $null
                    }
                }
            }

            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.InstanceName = 'MSSQLSERVER'
                    $mockTestTargetResourceParameters.SourceCredential = $null
                    $mockTestTargetResourceParameters.SourcePath = $TestDrive
                    $mockTestTargetResourceParameters.FailoverClusterGroupName = 'SQL Server (MSSQLSERVER)'
                    $mockTestTargetResourceParameters.FailoverClusterIPAddress = '10.0.0.10'
                    $mockTestTargetResourceParameters.FailoverClusterNetworkName = 'TestDefaultCluster'

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeFalse
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }

        Context 'When a SQL Server failover cluster is missing features' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Features                   = 'SQLENGINE' # Must be upper-case since Get-TargetResource returns upper-case.
                        FailoverClusterGroupName   = 'SQL Server (MSSQLSERVER)'
                        FailoverClusterIPAddress   = '10.0.0.10'
                        FailoverClusterNetworkName = 'TestDefaultCluster'
                    }
                }
            }

            # This is a test for regression testing of issue #432
            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.Features = 'SQLEngine,AS'
                    $mockTestTargetResourceParameters.InstanceName = 'MSSQLSERVER'
                    $mockTestTargetResourceParameters.SourceCredential = $null
                    $mockTestTargetResourceParameters.SourcePath = $TestDrive
                    $mockTestTargetResourceParameters.FailoverClusterGroupName = 'SQL Server (MSSQLSERVER)'
                    $mockTestTargetResourceParameters.FailoverClusterIPAddress = '10.0.0.10'
                    $mockTestTargetResourceParameters.FailoverClusterNetworkName = 'TestDefaultCluster'

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeFalse
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }

        Context 'When Action is set to ''Upgrade'' and current major version is not the expected' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Features = 'SQLEngine,Replication,Dq,Dqc,FullText,Rs,As,Is,Bol,Conn,Bc,Sdk,Mds,Ssms,Adv_Ssms'
                    }
                }

                Mock -CommandName Get-FilePathMajorVersion -MockWith {
                    return '15'
                }

                Mock -CommandName Get-SQLInstanceMajorVersion -MockWith {
                    return '14'
                }
            }

            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.Action = 'Upgrade'
                    $mockTestTargetResourceParameters.InstanceName = 'MSSQLSERVER'
                    $mockTestTargetResourceParameters.SourceCredential = $null
                    $mockTestTargetResourceParameters.SourcePath = $TestDrive

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeFalse
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When the system is in the desired state' {
        Context 'When all features are installed' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Features = 'SQLEngine,Replication,Dq,Dqc,FullText,Rs,As,Is,Bol,Conn,Bc,Sdk,Mds,Ssms,Adv_Ssms'
                    }
                }
            }

            It 'Should return $true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.InstanceName = 'MSSQLSERVER'
                    $mockTestTargetResourceParameters.SourceCredential = $null
                    $mockTestTargetResourceParameters.SourcePath = $TestDrive

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeTrue
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the correct clustered instance was found' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Features                   = 'SQLEngine,Replication,Dq,Dqc,FullText,Rs,As,Is,Bol,Conn,Bc,Sdk,Mds,Ssms,Adv_Ssms'
                        FailoverClusterGroupName   = 'SQL Server (MSSQLSERVER)'
                        FailoverClusterIPAddress   = '10.0.0.10'
                        FailoverClusterNetworkName = 'TestDefaultCluster'
                    }
                }
            }

            BeforeEach {
                InModuleScope -ScriptBlock {
                    $mockTestTargetResourceParameters.InstanceName = 'MSSQLSERVER'
                    $mockTestTargetResourceParameters.SourceCredential = $null
                    $mockTestTargetResourceParameters.SourcePath = $TestDrive
                    $mockTestTargetResourceParameters.FailoverClusterGroupName = 'SQL Server (MSSQLSERVER)'
                    $mockTestTargetResourceParameters.FailoverClusterIPAddress = '10.0.0.10'
                    $mockTestTargetResourceParameters.FailoverClusterNetworkName = 'TestDefaultCluster'
                }
            }

            It 'Should return $true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeTrue
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }

            # Regression test when the variables were detected differently.
            It 'Should not return false after a clustered install due to the presence of a variable called "FailoverClusterDisks"' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    # This is used when calling (& $mockClusterDiskMap).
                    $mockClusterDiskMap = {
                        @{
                            SysData    = Split-Path -Path 'E:\MSSQL\Data' -Qualifier
                            UserData   = Split-Path -Path 'K:\MSSQL\Data' -Qualifier
                            UserLogs   = Split-Path -Path 'L:\MSSQL\Logs' -Qualifier
                            TempDbData = Split-Path -Path 'M:\MSSQL\TempDb\Data' -Qualifier
                            TempDbLogs = Split-Path -Path 'N:\MSSQL\TempDb\Logs' -Qualifier
                            Backup     = Split-Path -Path 'O:\MSSQL\Backup' -Qualifier
                        }
                    }

                    New-Variable -Name 'FailoverClusterDisks' -Value (& $mockClusterDiskMap)['UserData']

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeTrue
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }

        # This is a test for regression testing of issue #432.
        Context 'When the SQL Server failover cluster has all features and is in desired state' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Features                   = 'SQLEngine,AS'
                        FailoverClusterGroupName   = 'SQL Server (MSSQLSERVER)'
                        FailoverClusterIPAddress   = '10.0.0.10'
                        FailoverClusterNetworkName = 'TestDefaultCluster'
                    }
                }
            }

            It 'Should return $true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.Features = 'SQLENGINE,AS'
                    $mockTestTargetResourceParameters.InstanceName = 'MSSQLSERVER'
                    $mockTestTargetResourceParameters.SourceCredential = $null
                    $mockTestTargetResourceParameters.SourcePath = $TestDrive
                    $mockTestTargetResourceParameters.FailoverClusterGroupName = 'SQL Server (MSSQLSERVER)'
                    $mockTestTargetResourceParameters.FailoverClusterIPAddress = '10.0.0.10'
                    $mockTestTargetResourceParameters.FailoverClusterNetworkName = 'TestDefaultCluster'

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeTrue
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }
    }
}

Describe 'SqlSetup\Set-TargetResource' -Tag 'Set' {
    BeforeAll {
        <#
            These mocks is meant to make sure the commands are actually mocked in a
            Context-block below.

            If these are not mocked it can slow down testing. If a Context-block
            does not mock a command, it will be tested against the default mock which
            will be these ones and they will throw an error reminding to create
            a mock.
        #>
        Mock -CommandName Get-TargetResource -MockWith {
            throw 'The command ''Get-TargetResource'' needs to be mocked in the Context-block'
        }

        Mock -CommandName Invoke-InstallationMediaCopy -MockWith {
            throw 'The command ''Invoke-InstallationMediaCopy'' needs to be mocked in the Context-block'
        }

        Mock -CommandName Get-CimInstance -MockWith {
            throw 'The command ''Get-CimInstance'' needs to be mocked in the Context-block'
        }

        Mock -CommandName Get-CimAssociatedInstance -MockWith {
            throw 'The command ''Get-CimAssociatedInstance'' needs to be mocked in the Context-block'
        }

        Mock -CommandName Test-IPAddress -MockWith {
            throw 'The command ''Test-IPAddress'' needs to be mocked in the Context-block'
        }

        #region Setting up TestDrive:\

        <#
            Mocking folder structure. This takes the leaf from the $TestDrive (the Guid in this case) and
            uses that to create a mock folder to mimic the temp folder that would be created in, for example,
            temp folder 'C:\Windows\Temp'.
            This folder is used when SourcePath is called with a leaf, for example '\\server\share\folder'.
        #>
        $mediaTempSourcePathWithLeaf = (Join-Path -Path $TestDrive -ChildPath (Split-Path -Path $TestDrive -Leaf))
        if (-not (Test-Path $mediaTempSourcePathWithLeaf))
        {
            New-Item -Path $mediaTempSourcePathWithLeaf -ItemType Directory
        }

        <#
            Mocking folder structure to mimic the temp folder that would be created in, for example,
            temp folder 'C:\Windows\Temp'.
            This folder is used when SourcePath is called without a leaf, for example '\\server\share'.
        #>
        $mediaTempSourcePathWithoutLeaf = (Join-Path -Path $TestDrive -ChildPath 'cc719562-0f46-4a16-8605-9f8a47c70402')
        if (-not (Test-Path $mediaTempSourcePathWithoutLeaf))
        {
            New-Item -Path $mediaTempSourcePathWithoutLeaf -ItemType Directory
        }

        # Mocking executable setup.exe which will be used for tests without parameter SourceCredential
        Set-Content (Join-Path -Path $TestDrive -ChildPath 'setup.exe') -Value 'Mock exe file'

        # Mocking executable setup.exe which will be used for tests with parameter SourceCredential and an UNC path with leaf
        Set-Content (Join-Path -Path $mediaTempSourcePathWithLeaf -ChildPath 'setup.exe') -Value 'Mock exe file'

        # Mocking executable setup.exe which will be used for tests with parameter SourceCredential and an UNC path without leaf
        Set-Content (Join-Path -Path $mediaTempSourcePathWithoutLeaf -ChildPath 'setup.exe') -Value 'Mock exe file'

        #endregion Setting up TestDrive:\

        $mockNewTemporaryFolder = {
            $testDrive_DriveShare = (Split-Path -Path $TestDrive -Qualifier) -replace ':', '$'
            $mockSourcePathUNC = Join-Path -Path "\\localhost\$testDrive_DriveShare" -ChildPath (Split-Path -Path $TestDrive -NoQualifier)

            return $mockSourcePathUNC
        }

        $mockGetCimAssociatedInstance_MSCluster_ResourceToPossibleOwner = {
            return @(
                (
                    @($env:COMPUTERNAME, 'SQL01', 'SQL02') | ForEach-Object -Process {
                        $node = $_
                        New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance 'MSCluster_Node', 'root/MSCluster' |
                            Add-Member -MemberType NoteProperty -Name 'Name' -Value $node -PassThru -Force
                        }
                    )
                )
            }

            $mockGetCimInstance_MSClusterResourceGroup_AvailableStorage = {
                return @(
                    (
                        New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance 'MSCluster_ResourceGroup', 'root/MSCluster' |
                            Add-Member -MemberType NoteProperty -Name 'Name' -Value 'Available Storage' -PassThru -Force
                )
            )
        }

        $mockGetCimInstance_MSClusterNetwork = {
            return @(
                (
                    $mockDynamicClusterSites | ForEach-Object -Process {
                        $network = $_

                        New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance 'MSCluster_Network', 'root/MSCluster' |
                            Add-Member -MemberType NoteProperty -Name 'Name' -Value "$($network.Name)_Prod" -PassThru -Force |
                            Add-Member -MemberType NoteProperty -Name 'Role' -Value 2 -PassThru -Force |
                            Add-Member -MemberType NoteProperty -Name 'Address' -Value $network.Address -PassThru -Force |
                            Add-Member -MemberType NoteProperty -Name 'AddressMask' -Value $network.Mask -PassThru -Force
                        }
                    )
                )
            }

            # Mock to return physical disks that are part of the "Available Storage" cluster role
            $mockGetCimAssociatedInstance_MSCluster_ResourceGroupToResource = {
                return @(
                    (
                        # $mockClusterDiskMap contains variables that are assigned dynamically (during runtime) before each test.
                    (& $mockClusterDiskMap).Keys | ForEach-Object -Process {
                            $diskName = $_
                            New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance 'MSCluster_Resource', 'root/MSCluster' |
                                Add-Member -MemberType NoteProperty -Name 'Name' -Value $diskName -PassThru -Force |
                                Add-Member -MemberType NoteProperty -Name 'State' -Value 2 -PassThru -Force |
                                Add-Member -MemberType NoteProperty -Name 'Type' -Value 'Physical Disk' -PassThru -Force
                            }
                        )
                    )
                }

                $mockGetCimAssociatedInstance_MSCluster_DiskPartition = {
                    $clusterDiskName = $InputObject.Name

                    # $mockClusterDiskMap contains variables that are assigned dynamically (during runtime) before each test.
                    $clusterDiskPath = (& $mockClusterDiskMap).$clusterDiskName

                    return @(
                        (
                            New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance 'MSCluster_DiskPartition', 'root/MSCluster' |
                                Add-Member -MemberType NoteProperty -Name 'Path' -Value $clusterDiskPath -PassThru -Force
                )
            )
        }

        $mockClusterDiskMap = {
            @{
                SysData    = Split-Path -Path $mockDynamicSqlDataDirectoryPath -Qualifier
                UserData   = Split-Path -Path $mockDynamicSqlUserDatabasePath -Qualifier
                UserLogs   = Split-Path -Path $mockDynamicSqlUserDatabaseLogPath -Qualifier
                TempDbData = Split-Path -Path $mockDynamicSqlTempDatabasePath -Qualifier
                TempDbLogs = Split-Path -Path $mockDynamicSqlTempDatabaseLogPath -Qualifier
                Backup     = Split-Path -Path $mockDynamicSqlBackupPath -Qualifier
            }
        }

        <#
            Needed a way to see into the Set-method for the arguments the Set-method
            is building and sending to 'setup.exe', and fail the test if the arguments
            is different from the expected arguments. Solved this by dynamically set
            the expected arguments before each It-block. If the arguments differs the
            mock of Start-SqlSetupProcess throws an error message, similar to what
            Pester would have reported (expected -> but was).
        #>
        $mockStartSqlSetupProcessExpectedArgument = @{}

        $mockStartSqlSetupProcess = {
            Test-SetupArgument -Argument $ArgumentList -ExpectedArgument $mockStartSqlSetupProcessExpectedArgument

            return 0
        }

        $mockGetSqlMajorVersion = {
            return $MockSqlMajorVersion
        }

        # General mocks
        Mock -CommandName Get-PSDrive
        Mock -CommandName Import-SqlDscPreferredModule
        Mock -CommandName Get-FilePathMajorVersion -MockWith $mockGetSqlMajorVersion

        # Mocking SharedDirectory and SharedWowDirectory (when not previously installed)
        Mock -CommandName Get-ItemProperty

        Mock -CommandName Start-SqlSetupProcess -MockWith $mockStartSqlSetupProcess
        Mock -CommandName Test-TargetResource -MockWith {
            return $true
        }

        Mock -CommandName Test-PendingRestart -MockWith {
            return $false
        }

        InModuleScope -ScriptBlock {
            # Mock PsDscRunAsCredential context.
            $script:PsDscContext = @{
                RunAsUser = 'COMPANY\sqladmin'
            }
        }
    }

    Context 'When setup action is Upgrade and parameter SqlVersion is passed' {
        It 'Should throw the correct exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockErrorMessage = Get-InvalidOperationRecord -Message (
                    $script:localizedData.ParameterSqlVersionNotAllowedForSetupActionUpgrade
                )

                $script:mockSetTargetResourceParameters = @{
                    Action           = 'Upgrade'
                    InstanceName     = 'MSSQLSERVER'
                    SourceCredential = $null
                    SourcePath       = $TestDrive
                    ServerName       = 'host.company.local'
                    SqlVersion       = '14.0'
                }

                { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw -ExpectedMessage $mockErrorMessage
            }
        }
    }


    Context 'When the system is not in the desired state' {
        Context 'When installing a default instance for major version <MockSqlMajorVersion>' -ForEach $testProductVersion {
            Context 'When installing all features' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Features = ''
                        }
                    }
                }

                It 'Should set the system in the desired state when feature is SQLENGINE' {
                    $mockStartSqlSetupProcessExpectedArgument = @{
                        Quiet                        = 'True'
                        IAcceptSQLServerLicenseTerms = 'True'
                        Action                       = 'Install'
                        InstanceName                 = 'MSSQLSERVER'
                        Features                     = 'SQLENGINE,REPLICATION,DQ,DQC,FULLTEXT,RS,AS,IS,BOL,CONN,BC,SDK,MDS,SSMS,ADV_SSMS'
                        SQLSysAdminAccounts          = 'COMPANY\sqladmin COMPANY\SQLAdmins COMPANY\User1'
                        ASSysAdminAccounts           = 'COMPANY\sqladmin COMPANY\SQLAdmins COMPANY\User1'
                        PID                          = '1FAKE-2FAKE-3FAKE-4FAKE-5FAKE'
                        InstanceDir                  = 'D:\'
                        InstallSQLDataDir            = 'E:\'
                        InstallSharedDir             = 'C:\Program Files\Microsoft SQL Server'
                        InstallSharedWOWDir          = 'C:\Program Files (x86)\Microsoft SQL Server'
                        UpdateEnabled                = 'True'
                        UpdateSource                 = 'C:\Updates' # Regression test for issue #720
                        ASServerMode                 = 'TABULAR'
                        SqlSvcStartupType            = 'Automatic'
                        AgtSvcStartupType            = 'Automatic'
                        AsSvcStartupType             = 'Automatic'
                        IsSvcStartupType             = 'Automatic'
                        SqlTempDbFileCount           = 2
                        SqlTempDbFileSize            = 128
                        SqlTempDbFileGrowth          = 128
                        SqlTempDbLogFileSize         = 128
                        SqlTempDbLogFileGrowth       = 128
                        BrowserSvcStartupType        = 'Automatic'
                    }

                    if ($MockSqlMajorVersion -in ('13'))
                    {
                        $mockStartSqlSetupProcessExpectedArgument.Features = 'SQLENGINE,REPLICATION,DQ,DQC,FULLTEXT,RS,AS,IS,BOL,CONN,BC,SDK,MDS'
                        $mockStartSqlSetupProcessExpectedArgument.RSInstallMode = 'DefaultNativeMode'
                        $mockStartSqlSetupProcessExpectedArgument.RsSvcStartupType = 'Automatic'
                    }
                    elseif ($MockSqlMajorVersion -in ('14', '15'))
                    {
                        $mockStartSqlSetupProcessExpectedArgument.Features = 'SQLENGINE,REPLICATION,DQ,DQC,FULLTEXT,AS,IS,BOL,CONN,BC,SDK,MDS'
                    }
                    else
                    {
                        $mockStartSqlSetupProcessExpectedArgument.Features = 'SQLENGINE,REPLICATION,DQ,DQC,FULLTEXT,RS,AS,IS,BOL,CONN,BC,SDK,MDS,SSMS,ADV_SSMS'
                    }

                    InModuleScope -Parameters $_ -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        # This is also used to regression test issue #1254, SqlSetup fails when root directory is specified.
                        $mockSetTargetResourceParameters = @{
                            Features               = 'SQLEngine,Replication,Dq,Dqc,FullText,Rs,As,Is,Bol,Conn,Bc,Sdk,Mds,Ssms,Adv_Ssms'
                            SQLSysAdminAccounts    = 'COMPANY\User1', 'COMPANY\SQLAdmins'
                            ASSysAdminAccounts     = 'COMPANY\User1', 'COMPANY\SQLAdmins'
                            InstanceName           = 'MSSQLSERVER'
                            SourceCredential       = $null
                            SourcePath             = $TestDrive
                            ProductKey             = '1FAKE-2FAKE-3FAKE-4FAKE-5FAKE'
                            InstanceDir            = 'D:'
                            InstallSQLDataDir      = 'E:'
                            InstallSharedDir       = 'C:\Program Files\Microsoft SQL Server'
                            InstallSharedWOWDir    = 'C:\Program Files (x86)\Microsoft SQL Server'
                            UpdateEnabled          = 'True'
                            UpdateSource           = 'C:\Updates\' # Regression test for issue #720
                            ASServerMode           = 'TABULAR'
                            SqlSvcStartupType      = 'Automatic'
                            AgtSvcStartupType      = 'Automatic'
                            AsSvcStartupType       = 'Automatic'
                            IsSvcStartupType       = 'Automatic'
                            SqlTempDbFileCount     = 2
                            SqlTempDbFileSize      = 128
                            SqlTempDbFileGrowth    = 128
                            SqlTempDbLogFileSize   = 128
                            SqlTempDbLogFileGrowth = 128
                            BrowserSvcStartupType  = 'Automatic'
                        }

                        if ($MockSqlMajorVersion -in ('13', '14', '15'))
                        {
                            $mockSetTargetResourceParameters.Features = $mockSetTargetResourceParameters.Features -replace ',SSMS,ADV_SSMS', ''
                        }

                        if ($MockSqlMajorVersion -in ('13'))
                        {
                            $mockSetTargetResourceParameters.RSInstallMode = 'DefaultNativeMode'
                            $mockSetTargetResourceParameters.RsSvcStartupType = 'Automatic'
                        }
                        elseif ($MockSqlMajorVersion -in ('14', '15'))
                        {
                            $mockSetTargetResourceParameters.Features = $mockSetTargetResourceParameters.Features -replace ',RS', ''
                        }

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                    }

                    Should -Invoke -CommandName Get-PSDrive -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName Start-SqlSetupProcess -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName Test-TargetResource -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName Import-SqlDscPreferredModule -Exactly -Times 1 -Scope It
                }
            }

            Context 'When installing the database engine and enabling the Named Pipes protocol' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Features = ''
                        }
                    }
                }

                It 'Should set the system in the desired state when feature is SQLENGINE' {
                    $mockStartSqlSetupProcessExpectedArgument = @{
                        Quiet                        = 'True'
                        IAcceptSQLServerLicenseTerms = 'True'
                        Action                       = 'Install'
                        InstanceName                 = 'MSSQLSERVER'
                        Features                     = 'SQLENGINE'
                        SQLSysAdminAccounts          = 'COMPANY\sqladmin COMPANY\SQLAdmins COMPANY\User1'
                        PID                          = '1FAKE-2FAKE-3FAKE-4FAKE-5FAKE'
                        NpEnabled                    = 1
                    }

                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $mockSetTargetResourceParameters = @{
                            Features            = 'SQLENGINE'
                            SQLSysAdminAccounts = 'COMPANY\User1', 'COMPANY\SQLAdmins'
                            InstanceName        = 'MSSQLSERVER'
                            SourceCredential    = $null
                            SourcePath          = $TestDrive
                            ProductKey          = '1FAKE-2FAKE-3FAKE-4FAKE-5FAKE'
                            NpEnabled           = $true
                            ServerName          = 'host.company.local'
                        }

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                    }

                    Should -Invoke -CommandName Start-SqlSetupProcess -Exactly -Times 1 -Scope It
                }
            }

            Context 'When installing the database engine and enabling the TCP protocol' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Features = ''
                        }
                    }
                }

                It 'Should set the system in the desired state when feature is SQLENGINE' {
                    $mockStartSqlSetupProcessExpectedArgument = @{
                        Quiet                        = 'True'
                        IAcceptSQLServerLicenseTerms = 'True'
                        Action                       = 'Install'
                        InstanceName                 = 'MSSQLSERVER'
                        Features                     = 'SQLENGINE'
                        SQLSysAdminAccounts          = 'COMPANY\sqladmin COMPANY\SQLAdmins COMPANY\User1'
                        PID                          = '1FAKE-2FAKE-3FAKE-4FAKE-5FAKE'
                        TcpEnabled                   = 1
                    }

                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $mockSetTargetResourceParameters = @{
                            Features            = 'SQLENGINE'
                            SQLSysAdminAccounts = 'COMPANY\User1', 'COMPANY\SQLAdmins'
                            InstanceName        = 'MSSQLSERVER'
                            SourceCredential    = $null
                            SourcePath          = $TestDrive
                            ProductKey          = '1FAKE-2FAKE-3FAKE-4FAKE-5FAKE'
                            TcpEnabled          = $true
                        }

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                    }

                    Should -Invoke -CommandName Start-SqlSetupProcess -Exactly -Times 1 -Scope It
                }
            }

            Context 'When using SourceCredential parameter, and using a UNC path with a leaf' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Features = ''
                        }
                    }

                    Mock -CommandName Invoke-InstallationMediaCopy -MockWith $mockNewTemporaryFolder
                }

                It 'Should set the system in the desired state when feature is SQLENGINE' {
                    $mockStartSqlSetupProcessExpectedArgument = @{
                        Quiet                        = 'True'
                        IAcceptSQLServerLicenseTerms = 'True'
                        Action                       = 'Install'
                        InstanceName                 = 'MSSQLSERVER'
                        Features                     = 'SQLENGINE'
                        SQLSysAdminAccounts          = 'COMPANY\sqladmin COMPANY\SQLAdmins COMPANY\User1'
                    }

                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $testDrive_DriveShare = (Split-Path -Path $TestDrive -Qualifier) -replace ':', '$'
                        $mockSourcePathUNC = Join-Path -Path "\\localhost\$testDrive_DriveShare" -ChildPath (Split-Path -Path $TestDrive -NoQualifier)

                        $mockSetTargetResourceParameters = @{
                            InstanceName        = 'MSSQLSERVER'
                            Features            = 'SQLENGINE'
                            SQLSysAdminAccounts = 'COMPANY\User1', 'COMPANY\SQLAdmins'
                            SourceCredential    = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @('COMPANY\sqladmin', ('dummyPassw0rd' | ConvertTo-SecureString -asPlainText -Force))
                            SourcePath          = $mockSourcePathUNC
                        }

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                    }

                    Should -Invoke -CommandName Get-PSDrive -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName Invoke-InstallationMediaCopy -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName Start-SqlSetupProcess -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName Test-TargetResource -Exactly -Times 1 -Scope It
                }
            }

            Context 'When using SourceCredential parameter, and using a UNC path without a leaf' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Features = ''
                        }
                    }

                    Mock -CommandName Invoke-InstallationMediaCopy -MockWith $mockNewTemporaryFolder
                }

                It 'Should set the system in the desired state when feature is SQLENGINE' {
                    $mockStartSqlSetupProcessExpectedArgument = @{
                        Quiet                        = 'True'
                        IAcceptSQLServerLicenseTerms = 'True'
                        Action                       = 'Install'
                        InstanceName                 = 'MSSQLSERVER'
                        Features                     = 'SQLENGINE'
                        SQLSysAdminAccounts          = 'COMPANY\sqladmin COMPANY\SQLAdmins COMPANY\User1'
                    }

                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $mockSetTargetResourceParameters = @{
                            InstanceName        = 'MSSQLSERVER'
                            Features            = 'SQLENGINE'
                            SQLSysAdminAccounts = 'COMPANY\User1', 'COMPANY\SQLAdmins'
                            SourceCredential    = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @('COMPANY\sqladmin', ('dummyPassw0rd' | ConvertTo-SecureString -asPlainText -Force))
                            SourcePath          = '\\server\share'
                            ForceReboot         = $true
                            SuppressReboot      = $true
                        }

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                    }

                    Should -Invoke -CommandName Get-PSDrive -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName Invoke-InstallationMediaCopy -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName Start-SqlSetupProcess -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName Test-TargetResource -Exactly -Times 1 -Scope It
                }
            }
        }

        Context 'When installing a named instance for major version <MockSqlMajorVersion>' -ForEach $testProductVersion {
            Context 'When installing all features' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Features = ''
                        }
                    }
                }

                It 'Should set the system in the desired state when feature is SQLENGINE' {
                    $mockStartSqlSetupProcessExpectedArgument = @{
                        Quiet                        = 'True'
                        IAcceptSQLServerLicenseTerms = 'True'
                        Action                       = 'Install'
                        InstanceName                 = 'TEST'
                        Features                     = 'SQLENGINE,REPLICATION,DQ,DQC,FULLTEXT,RS,AS,IS,BOL,CONN,BC,SDK,MDS,SSMS,ADV_SSMS'
                        SQLSysAdminAccounts          = 'COMPANY\sqladmin COMPANY\SQLAdmins COMPANY\User1'
                        ASSysAdminAccounts           = 'COMPANY\sqladmin COMPANY\SQLAdmins COMPANY\User1'
                        PID                          = '1FAKE-2FAKE-3FAKE-4FAKE-5FAKE'
                        InstanceDir                  = 'D:\'
                        InstallSQLDataDir            = 'E:\'
                        InstallSharedDir             = 'C:\Program Files\Microsoft SQL Server'
                        InstallSharedWOWDir          = 'C:\Program Files (x86)\Microsoft SQL Server'
                        UpdateEnabled                = 'True'
                        UpdateSource                 = 'C:\Updates' # Regression test for issue #720
                        ASServerMode                 = 'TABULAR'
                        SqlSvcStartupType            = 'Automatic'
                        AgtSvcStartupType            = 'Automatic'
                        AsSvcStartupType             = 'Automatic'
                        IsSvcStartupType             = 'Automatic'
                        SqlTempDbFileCount           = 2
                        SqlTempDbFileSize            = 128
                        SqlTempDbFileGrowth          = 128
                        SqlTempDbLogFileSize         = 128
                        SqlTempDbLogFileGrowth       = 128
                        BrowserSvcStartupType        = 'Automatic'
                    }

                    if ($MockSqlMajorVersion -in ('13'))
                    {
                        $mockStartSqlSetupProcessExpectedArgument.Features = 'SQLENGINE,REPLICATION,DQ,DQC,FULLTEXT,RS,AS,IS,BOL,CONN,BC,SDK,MDS'
                        $mockStartSqlSetupProcessExpectedArgument.RSInstallMode = 'DefaultNativeMode'
                        $mockStartSqlSetupProcessExpectedArgument.RsSvcStartupType = 'Automatic'
                    }
                    elseif ($MockSqlMajorVersion -in ('14', '15'))
                    {
                        $mockStartSqlSetupProcessExpectedArgument.Features = 'SQLENGINE,REPLICATION,DQ,DQC,FULLTEXT,AS,IS,BOL,CONN,BC,SDK,MDS'
                    }
                    else
                    {
                        $mockStartSqlSetupProcessExpectedArgument.Features = 'SQLENGINE,REPLICATION,DQ,DQC,FULLTEXT,RS,AS,IS,BOL,CONN,BC,SDK,MDS,SSMS,ADV_SSMS'
                    }

                    InModuleScope -Parameters $_ -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        # This is also used to regression test issue #1254, SqlSetup fails when root directory is specified.
                        $mockSetTargetResourceParameters = @{
                            Features               = 'SQLEngine,Replication,Dq,Dqc,FullText,Rs,As,Is,Bol,Conn,Bc,Sdk,Mds,Ssms,Adv_Ssms'
                            SQLSysAdminAccounts    = 'COMPANY\User1', 'COMPANY\SQLAdmins'
                            ASSysAdminAccounts     = 'COMPANY\User1', 'COMPANY\SQLAdmins'
                            InstanceName           = 'TEST'
                            SourceCredential       = $null
                            SourcePath             = $TestDrive
                            ProductKey             = '1FAKE-2FAKE-3FAKE-4FAKE-5FAKE'
                            InstanceDir            = 'D:'
                            InstallSQLDataDir      = 'E:'
                            InstallSharedDir       = 'C:\Program Files\Microsoft SQL Server'
                            InstallSharedWOWDir    = 'C:\Program Files (x86)\Microsoft SQL Server'
                            UpdateEnabled          = 'True'
                            UpdateSource           = 'C:\Updates\' # Regression test for issue #720
                            ASServerMode           = 'TABULAR'
                            SqlSvcStartupType      = 'Automatic'
                            AgtSvcStartupType      = 'Automatic'
                            AsSvcStartupType       = 'Automatic'
                            IsSvcStartupType       = 'Automatic'
                            SqlTempDbFileCount     = 2
                            SqlTempDbFileSize      = 128
                            SqlTempDbFileGrowth    = 128
                            SqlTempDbLogFileSize   = 128
                            SqlTempDbLogFileGrowth = 128
                            BrowserSvcStartupType  = 'Automatic'
                            ForceReboot            = $true
                            SqlVersion             = ('{0}.0' -f $MockSqlMajorVersion)
                        }

                        if ($MockSqlMajorVersion -in ('13', '14', '15'))
                        {
                            $mockSetTargetResourceParameters.Features = $mockSetTargetResourceParameters.Features -replace ',SSMS,ADV_SSMS', ''
                        }

                        if ($MockSqlMajorVersion -in ('13'))
                        {
                            $mockSetTargetResourceParameters.RSInstallMode = 'DefaultNativeMode'
                            $mockSetTargetResourceParameters.RsSvcStartupType = 'Automatic'
                        }
                        elseif ($MockSqlMajorVersion -in ('14', '15'))
                        {
                            $mockSetTargetResourceParameters.Features = $mockSetTargetResourceParameters.Features -replace ',RS', ''
                        }

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                    }

                    Should -Invoke -CommandName Get-PSDrive -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName Start-SqlSetupProcess -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName Test-TargetResource -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName Import-SqlDscPreferredModule -Exactly -Times 0 -Scope It
                }
            }
        }

        Context 'When installing the database engine and disabling the Named Pipes protocol' {
            BeforeAll {
                Mock -CommandName Get-FilePathMajorVersion -MockWith {
                    return 15
                }

                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Features = ''
                    }
                }
            }

            It 'Should set the system in the desired state when feature is SQLENGINE' {
                $mockStartSqlSetupProcessExpectedArgument = @{
                    Quiet                        = 'True'
                    IAcceptSQLServerLicenseTerms = 'True'
                    Action                       = 'Install'
                    InstanceName                 = 'MSSQLSERVER'
                    Features                     = 'SQLENGINE'
                    SQLSysAdminAccounts          = 'COMPANY\sqladmin COMPANY\SQLAdmins COMPANY\User1'
                    PID                          = '1FAKE-2FAKE-3FAKE-4FAKE-5FAKE'
                    NpEnabled                    = 0
                }

                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters = @{
                        Features            = 'SQLENGINE'
                        SQLSysAdminAccounts = 'COMPANY\User1', 'COMPANY\SQLAdmins'
                        InstanceName        = 'MSSQLSERVER'
                        SourceCredential    = $null
                        SourcePath          = $TestDrive
                        ProductKey          = '1FAKE-2FAKE-3FAKE-4FAKE-5FAKE'
                        NpEnabled           = $false
                    }

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Start-SqlSetupProcess -Exactly -Times 1 -Scope It
            }
        }

        Context 'When installing the database engine and disabling the TCP protocol' {
            BeforeAll {
                Mock -CommandName Get-FilePathMajorVersion -MockWith {
                    return 15
                }

                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Features = ''
                    }
                }
            }

            It 'Should set the system in the desired state when feature is SQLENGINE' {
                $mockStartSqlSetupProcessExpectedArgument = @{
                    Quiet                        = 'True'
                    IAcceptSQLServerLicenseTerms = 'True'
                    Action                       = 'Install'
                    InstanceName                 = 'MSSQLSERVER'
                    Features                     = 'SQLENGINE'
                    SQLSysAdminAccounts          = 'COMPANY\sqladmin COMPANY\SQLAdmins COMPANY\User1'
                    PID                          = '1FAKE-2FAKE-3FAKE-4FAKE-5FAKE'
                    TcpEnabled                   = 0
                }

                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters = @{
                        Features            = 'SQLENGINE'
                        SQLSysAdminAccounts = 'COMPANY\User1', 'COMPANY\SQLAdmins'
                        InstanceName        = 'MSSQLSERVER'
                        SourceCredential    = $null
                        SourcePath          = $TestDrive
                        ProductKey          = '1FAKE-2FAKE-3FAKE-4FAKE-5FAKE'
                        TcpEnabled          = $false
                    }

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Start-SqlSetupProcess -Exactly -Times 1 -Scope It
            }
        }

        Context 'When installing the database engine forcing to use english language in media' {
            BeforeAll {
                Mock -CommandName Get-FilePathMajorVersion -MockWith {
                    return 15
                }

                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Features = ''
                    }
                }
            }

            It 'Should set the system in the desired state when feature is SQLENGINE' {
                $mockStartSqlSetupProcessExpectedArgument = @{
                    Quiet                        = 'True'
                    IAcceptSQLServerLicenseTerms = 'True'
                    Action                       = 'Install'
                    InstanceName                 = 'MSSQLSERVER'
                    Features                     = 'SQLENGINE'
                    SQLSysAdminAccounts          = 'COMPANY\sqladmin COMPANY\SQLAdmins COMPANY\User1'
                    PID                          = '1FAKE-2FAKE-3FAKE-4FAKE-5FAKE'
                    Enu                          = '' # The argument does not have a value
                }

                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters = @{
                        Features            = 'SQLENGINE'
                        SQLSysAdminAccounts = 'COMPANY\User1', 'COMPANY\SQLAdmins'
                        InstanceName        = 'MSSQLSERVER'
                        SourceCredential    = $null
                        SourcePath          = $TestDrive
                        ProductKey          = '1FAKE-2FAKE-3FAKE-4FAKE-5FAKE'
                        UseEnglish          = $true
                    }

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Start-SqlSetupProcess -Exactly -Times 1 -Scope It
            }
        }

        Context 'When installing using a skip rule' {
            BeforeAll {
                Mock -CommandName Get-FilePathMajorVersion -MockWith {
                    return 15
                }

                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Features = ''
                    }
                }
            }

            It 'Should call setup.exe with the correct skip rules as arguments' {
                $mockStartSqlSetupProcessExpectedArgument = @{
                    Quiet                        = 'True'
                    IAcceptSQLServerLicenseTerms = 'True'
                    Action                       = 'Install'
                    InstanceName                 = 'MSSQLSERVER'
                    Features                     = 'SQLENGINE'
                    SQLSysAdminAccounts          = 'COMPANY\sqladmin COMPANY\SQLAdmins COMPANY\User1'
                    PID                          = '1FAKE-2FAKE-3FAKE-4FAKE-5FAKE'
                    SkipRules                    = '"Cluster_VerifyForErrors"'
                }

                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters = @{
                        Features            = 'SQLENGINE'
                        SQLSysAdminAccounts = 'COMPANY\User1', 'COMPANY\SQLAdmins'
                        InstanceName        = 'MSSQLSERVER'
                        SourceCredential    = $null
                        SourcePath          = $TestDrive
                        ProductKey          = '1FAKE-2FAKE-3FAKE-4FAKE-5FAKE'
                        SkipRule            = 'Cluster_VerifyForErrors'
                    }

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Start-SqlSetupProcess -Exactly -Times 1 -Scope It
            }
        }

        Context 'When installing using multiple skip rules' {
            BeforeAll {
                Mock -CommandName Get-FilePathMajorVersion -MockWith {
                    return 15
                }

                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Features = ''
                    }
                }
            }

            It 'Should call setup.exe with the correct skip rules as arguments' {
                $mockStartSqlSetupProcessExpectedArgument = @{
                    Quiet                        = 'True'
                    IAcceptSQLServerLicenseTerms = 'True'
                    Action                       = 'Install'
                    InstanceName                 = 'MSSQLSERVER'
                    Features                     = 'SQLENGINE'
                    SQLSysAdminAccounts          = 'COMPANY\sqladmin COMPANY\SQLAdmins COMPANY\User1'
                    PID                          = '1FAKE-2FAKE-3FAKE-4FAKE-5FAKE'
                    SkipRules                    = '"Cluster_IsWMIServiceOperational" "Cluster_VerifyForErrors" "ServerCoreBlockUnsupportedSxSCheck"'
                }

                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters = @{
                        Features            = 'SQLENGINE'
                        SQLSysAdminAccounts = 'COMPANY\User1', 'COMPANY\SQLAdmins'
                        InstanceName        = 'MSSQLSERVER'
                        SourceCredential    = $null
                        SourcePath          = $TestDrive
                        ProductKey          = '1FAKE-2FAKE-3FAKE-4FAKE-5FAKE'
                        SkipRule            = @(
                            'Cluster_VerifyForErrors'
                            'ServerCoreBlockUnsupportedSxSCheck'
                            'Cluster_IsWMIServiceOperational'
                        )
                    }

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Start-SqlSetupProcess -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When setup process fails with an exit code' {
        BeforeAll {
            Mock -CommandName Get-FilePathMajorVersion -MockWith {
                return 15
            }

            Mock -CommandName Get-TargetResource -MockWith {
                return @{
                    Features = ''
                }
            }
        }

        Context 'When setup exists with exit code 3010' {
            BeforeAll {
                Mock -CommandName Start-SqlSetupProcess -MockWith {
                    return 3010
                }
            }

            AfterEach {
                # The code being test will set this global variable to 1, so we need to reset it.
                $global:DSCMachineStatus = 0
            }

            It 'Should tell LCM that node need to restart' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters = @{
                        Features         = 'SQLENGINE'
                        InstanceName     = 'MSSQLSERVER'
                        SourceCredential = $null
                        SourcePath       = $TestDrive
                    }

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                    $global:DSCMachineStatus | Should -Be 1
                }
            }
        }

        Context 'When setup exists with any other code than 3010 (exit code is set to 1 for the test)' {
            BeforeAll {
                Mock -CommandName Write-Warning
                Mock -CommandName Start-SqlSetupProcess -MockWith {
                    return 1
                }
            }

            It 'Should call the correct mock' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters = @{
                        Features         = 'SQLENGINE'
                        InstanceName     = 'MSSQLSERVER'
                        SourceCredential = $null
                        SourcePath       = $TestDrive
                    }

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Write-Warning -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Import-SqlDscPreferredModule -Exactly -Times 0 -Scope It
            }
        }
    }

    Context 'When passing invalid features for <MockSqlMajorVersion>' -ForEach @(
        @{
            MockSqlMajorVersion = 15 # SQL Server 2019
        }
        @{
            MockSqlMajorVersion = 14 # SQL Server 2017
        }
        @{
            MockSqlMajorVersion = 13 # SQL Server 2016
        }
    ) {
        BeforeAll {
            Mock -CommandName Get-TargetResource -MockWith {
                return @{
                    Features = ''
                }
            }
        }

        It 'Should throw when feature parameter contains ''SSMS'' when installing SQL Server 2016, 2017 or 2019' {
            $mockStartSqlSetupProcessExpectedArgument = @{}

            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockSetTargetResourceParameters = @{
                    Features         = 'SSMS'
                    InstanceName     = 'MSSQLSERVER'
                    SourceCredential = $null
                    SourcePath       = $TestDrive
                }

                { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw "*'SSMS' is not a valid value for setting 'FEATURES'.  Refer to SQL Help for more information."
            }
        }

        It 'Should throw when feature parameter contains ''ADV_SSMS'' when installing SQL Server 2016, 2017 or 2019' {
            $mockStartSqlSetupProcessExpectedArgument = @{}

            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockSetTargetResourceParameters = @{
                    Features         = 'ADV_SSMS'
                    InstanceName     = 'MSSQLSERVER'
                    SourceCredential = $null
                    SourcePath       = $TestDrive
                }

                { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw -ExpectedMessage "*'ADV_SSMS' is not a valid value for setting 'FEATURES'.  Refer to SQL Help for more information."
            }
        }
    }

    Context 'When passing invalid features for <MockSqlMajorVersion>' -ForEach @(
        @{
            MockSqlMajorVersion = 12 # SQL Server 2014
        }
        @{
            MockSqlMajorVersion = 11 # SQL Server 2012
        }
        @{
            MockSqlMajorVersion = 10  # SQL Server 2008 and 2008 R2
        }
    ) {
        BeforeAll {
            Mock -CommandName Get-TargetResource -MockWith {
                return @{
                    Features = ''
                }
            }
        }

        It 'Should set the system in the desired state when feature is SSMS' {
            $mockStartSqlSetupProcessExpectedArgument = @{
                Quiet                        = 'True'
                IAcceptSQLServerLicenseTerms = 'True'
                Action                       = 'Install'
                InstanceName                 = 'MSSQLSERVER'
                Features                     = 'SSMS'
            }

            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockSetTargetResourceParameters = @{
                    Features         = 'SSMS'
                    InstanceName     = 'MSSQLSERVER'
                    SourceCredential = $null
                    SourcePath       = $TestDrive
                }

                { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
            }

            Should -Invoke -CommandName Get-PSDrive -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Start-SqlSetupProcess -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Test-TargetResource -Exactly -Times 1 -Scope It
        }

        It 'Should set the system in the desired state when feature is ADV_SSMS' {
            $mockStartSqlSetupProcessExpectedArgument = @{
                Quiet                        = 'True'
                IAcceptSQLServerLicenseTerms = 'True'
                Action                       = 'Install'
                InstanceName                 = 'MSSQLSERVER'
                Features                     = 'ADV_SSMS'
            }

            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockSetTargetResourceParameters = @{
                    Features         = 'ADV_SSMS'
                    InstanceName     = 'MSSQLSERVER'
                    SourceCredential = $null
                    SourcePath       = $TestDrive
                }

                { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
            }

            Should -Invoke -CommandName Get-PSDrive -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Start-SqlSetupProcess -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Test-TargetResource -Exactly -Times 1 -Scope It
        }
    }

    # For testing AddNode action
    Context 'When action is set to ''AddNode''' {
        BeforeAll {
            Mock -CommandName Get-FilePathMajorVersion -MockWith {
                return 15
            }

            Mock -CommandName Get-TargetResource -MockWith {
                return @{
                    Features = ''
                }
            }
        }

        It 'Should pass proper parameters to setup' {
            $mockStartSqlSetupProcessExpectedArgument = @{
                IAcceptSQLServerLicenseTerms = 'True'
                Quiet                        = 'True'
                Action                       = 'AddNode'
                InstanceName                 = 'MSSQLSERVER'
                AgtSvcAccount                = 'COMPANY\AgentAccount'
                AgtSvcPassword               = 'Ag3ntP@ssw0rd'
                SqlSvcAccount                = 'COMPANY\SqlAccount'
                SqlSvcPassword               = 'SqlS3v!c3P@ssw0rd'
                AsSvcAccount                 = 'COMPANY\AnalysisAccount'
                AsSvcPassword                = 'AnalysisS3v!c3P@ssw0rd'
            }

            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockSetTargetResourceParameters = @{
                    Action                     = 'AddNode'
                    # Feature support is tested elsewhere, so just include the minimum.
                    Features                   = 'SQLENGINE,AS'
                    InstanceName               = 'MSSQLSERVER'
                    SourcePath                 = $TestDrive
                    AgtSvcAccount              = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @('COMPANY\AgentAccount', ('Ag3ntP@ssw0rd' | ConvertTo-SecureString -AsPlainText -Force))
                    SqlSvcAccount              = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @('COMPANY\SqlAccount', ('SqlS3v!c3P@ssw0rd' | ConvertTo-SecureString -AsPlainText -Force))
                    ASSvcAccount               = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @('COMPANY\AnalysisAccount', ('AnalysisS3v!c3P@ssw0rd' | ConvertTo-SecureString -AsPlainText -Force))
                    FailoverClusterNetworkName = 'TestDefaultCluster'
                    SQLSysAdminAccounts        = 'COMPANY\User1', 'COMPANY\SQLAdmins'
                }

                { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
            }
        }
    }

    Context 'When action is set to ''InstallFailoverCluster''' {
        BeforeAll {
            Mock -CommandName Get-FilePathMajorVersion -MockWith {
                return 15
            }

            # Cluster shared volumes will be tested and mocked later on.
            Mock -CommandName Get-CimInstance -MockWith {
                return $null
            } -ParameterFilter {
                $ClassName -eq 'MSCluster_ClusterSharedVolume'
            }

            Mock -CommandName Get-TargetResource -MockWith {
                return @{
                    Features = ''
                }
            }

            $mockDynamicSqlDataDirectoryPath = 'E:\MSSQL\Data'
            $mockDynamicSqlUserDatabasePath = 'K:\MSSQL\Data'
            $mockDynamicSqlUserDatabaseLogPath = 'L:\MSSQL\Logs'
            $mockDynamicSqlTempDatabasePath = 'M:\MSSQL\TempDb\Data'
            $mockDynamicSqlTempDatabaseLogPath = 'N:\MSSQL\TempDb\Logs'
            $mockDynamicSqlBackupPath = 'O:\MSSQL\Backup'

            Mock -CommandName Get-CimInstance -MockWith $mockGetCimInstance_MSClusterResourceGroup_AvailableStorage -ParameterFilter {
                $Filter -eq "Name = 'Available Storage'"
            }

            Mock -CommandName Get-CimAssociatedInstance -MockWith $mockGetCimAssociatedInstance_MSCluster_ResourceGroupToResource -ParameterFilter {
                ($Association -eq 'MSCluster_ResourceGroupToResource') -and ($ResultClassName -eq 'MSCluster_Resource')
            }

            Mock -CommandName Get-CimAssociatedInstance -MockWith $mockGetCimAssociatedInstance_MSCluster_ResourceToPossibleOwner -ParameterFilter {
                $Association -eq 'MSCluster_ResourceToPossibleOwner'
            }

            Mock -CommandName Get-CimAssociatedInstance -MockWith $mockGetCimAssociatedInstance_MSCluster_DiskPartition -ParameterFilter {
                $ResultClassName -eq 'MSCluster_DiskPartition'
            }

            $mockDynamicClusterSites = @(
                @{
                    Name    = 'SiteA'
                    Address = '10.0.0.10' # First site IP address
                    Mask    = '255.255.255.0'
                }
            )

            Mock -CommandName Get-CimInstance -MockWith $mockGetCimInstance_MSClusterNetwork -ParameterFilter {
                ($Namespace -eq 'root/MSCluster') -and ($ClassName -eq 'MSCluster_Network') -and ($Filter -eq 'Role >= 2')
            }

            Mock -CommandName Test-IPAddress -MockWith {
                return $true
            }
        }

        It 'Should pass proper parameters to setup' {
            $mockStartSqlSetupProcessExpectedArgument = @{
                Action                       = 'InstallFailoverCluster'
                FailoverClusterDisks         = 'Backup; SysData; TempDbData; TempDbLogs; UserData; UserLogs'
                FailoverClusterIPAddresses   = 'IPV4;10.0.0.10;SiteA_Prod;255.255.255.0'
                FailoverClusterNetworkName   = 'TestDefaultCluster'
                InstallSQLDataDir            = 'E:\MSSQL\Data'
                SQLUserDBDir                 = 'K:\MSSQL\Data'
                SQLUserDBLogDir              = 'L:\MSSQL\Logs'
                SQLTempDBDir                 = 'M:\MSSQL\TempDb\Data'
                SQLTempDBLogDir              = 'N:\MSSQL\TempDb\Logs'
                SQLBackupDir                 = 'O:\MSSQL\Backup'
                IAcceptSQLServerLicenseTerms = 'True'
                Quiet                        = 'True'
                InstanceName                 = 'MSSQLSERVER'
                Features                     = 'SQLENGINE'
                SQLSysAdminAccounts          = 'COMPANY\sqladmin COMPANY\SQLAdmins COMPANY\User1'
                FailoverClusterGroup         = 'SQL Server (MSSQLSERVER)'
            }

            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockSetTargetResourceParameters = @{
                    SQLSysAdminAccounts        = 'COMPANY\User1', 'COMPANY\SQLAdmins'

                    # Feature support is tested elsewhere, so just include the minimum.
                    Features                   = 'SQLEngine'

                    InstanceName               = 'MSSQLSERVER'
                    SourcePath                 = $TestDrive
                    Action                     = 'InstallFailoverCluster'
                    FailoverClusterGroupName   = 'SQL Server (MSSQLSERVER)'
                    FailoverClusterNetworkName = 'TestDefaultCluster'
                    FailoverClusterIPAddress   = '10.0.0.10'

                    # Ensure we use "clustered" disks for our paths
                    InstallSQLDataDir          = 'E:\MSSQL\Data'
                    SQLUserDBDir               = 'K:\MSSQL\Data'
                    SQLUserDBLogDir            = 'L:\MSSQL\Logs'
                    SQLTempDbDir               = 'M:\MSSQL\TempDb\Data'
                    SQLTempDbLogDir            = 'N:\MSSQL\TempDb\Logs'
                    SQLBackupDir               = 'O:\MSSQL\Backup'
                }

                { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
            }
        }

        It 'Should pass proper parameters to setup when only InstallSQLDataDir is assigned a path' {
            $mockStartSqlSetupProcessExpectedArgument = @{
                Action                       = 'InstallFailoverCluster'
                FailoverClusterDisks         = 'SysData'
                FailoverClusterIPAddresses   = 'IPV4;10.0.0.10;SiteA_Prod;255.255.255.0'
                FailoverClusterNetworkName   = 'TestDefaultCluster'
                InstallSQLDataDir            = 'E:\MSSQL\Data'
                IAcceptSQLServerLicenseTerms = 'True'
                Quiet                        = 'True'
                InstanceName                 = 'MSSQLSERVER'
                Features                     = 'SQLENGINE'
                SQLSysAdminAccounts          = 'COMPANY\sqladmin COMPANY\SQLAdmins COMPANY\User1'
                FailoverClusterGroup         = 'SQL Server (MSSQLSERVER)'
            }

            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockSetTargetResourceParameters = @{
                    SQLSysAdminAccounts        = 'COMPANY\User1', 'COMPANY\SQLAdmins'

                    # Feature support is tested elsewhere, so just include the minimum.
                    Features                   = 'SQLEngine'

                    InstanceName               = 'MSSQLSERVER'
                    SourcePath                 = $TestDrive
                    Action                     = 'InstallFailoverCluster'
                    FailoverClusterGroupName   = 'SQL Server (MSSQLSERVER)'
                    FailoverClusterNetworkName = 'TestDefaultCluster'
                    FailoverClusterIPAddress   = '10.0.0.10'

                    # Ensure we use "clustered" disks for our paths
                    InstallSQLDataDir          = 'E:\MSSQL\Data'
                }

                { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
            }
        }

        It 'Should pass proper parameters to setup when three variables are assigned the same drive, but different paths' {
            $mockStartSqlSetupProcessExpectedArgument = @{
                Action                       = 'InstallFailoverCluster'
                FailoverClusterDisks         = 'SysData'
                FailoverClusterIPAddresses   = 'IPV4;10.0.0.10;SiteA_Prod;255.255.255.0'
                FailoverClusterNetworkName   = 'TestDefaultCluster'
                InstallSQLDataDir            = 'E:\SQLData'
                SQLUserDBDir                 = 'E:\SQLData\UserDb'
                SQLUserDBLogDir              = 'E:\SQLData\UserDbLogs'
                IAcceptSQLServerLicenseTerms = 'True'
                Quiet                        = 'True'
                InstanceName                 = 'MSSQLSERVER'
                Features                     = 'SQLENGINE'
                SQLSysAdminAccounts          = 'COMPANY\sqladmin COMPANY\SQLAdmins COMPANY\User1'
                FailoverClusterGroup         = 'SQL Server (MSSQLSERVER)'
            }

            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockSetTargetResourceParameters = @{
                    SQLSysAdminAccounts        = 'COMPANY\User1', 'COMPANY\SQLAdmins'

                    # Feature support is tested elsewhere, so just include the minimum.
                    Features                   = 'SQLEngine'

                    InstanceName               = 'MSSQLSERVER'
                    SourcePath                 = $TestDrive
                    Action                     = 'InstallFailoverCluster'
                    FailoverClusterGroupName   = 'SQL Server (MSSQLSERVER)'
                    FailoverClusterNetworkName = 'TestDefaultCluster'
                    FailoverClusterIPAddress   = '10.0.0.10'

                    # Ensure we use "clustered" disks for our paths
                    InstallSQLDataDir          = 'E:\SQLData\' # This ends with \ to test removal of paths ending with \
                    SQLUserDBDir               = 'E:\SQLData\UserDb'
                    SQLUserDBLogDir            = 'E:\SQLData\UserDbLogs'
                }

                { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
            }
        }

        It 'Should throw an error when one or more paths are not resolved to clustered storage' {
            $mockStartSqlSetupProcessExpectedArgument = @{}

            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockSetTargetResourceParameters = @{
                    SQLSysAdminAccounts        = 'COMPANY\User1', 'COMPANY\SQLAdmins'

                    # Feature support is tested elsewhere, so just include the minimum.
                    Features                   = 'SQLEngine'

                    InstanceName               = 'MSSQLSERVER'
                    SourcePath                 = $TestDrive
                    Action                     = 'InstallFailoverCluster'
                    FailoverClusterGroupName   = 'SQL Server (MSSQLSERVER)'
                    FailoverClusterNetworkName = 'TestDefaultCluster'
                    FailoverClusterIPAddress   = '10.0.0.10'

                    InstallSQLDataDir          = 'E:\MSSQL\Data'
                    SQLUserDBLogDir            = 'L:\MSSQL\Logs'
                    SQLTempDbDir               = 'M:\MSSQL\TempDb\Data'
                    SQLTempDbLogDir            = 'N:\MSSQL\TempDb\Logs'
                    SQLBackupDir               = 'O:\MSSQL\Backup'

                    SQLUserDBDir               = 'C:\MSSQL\' # Pass in a bad path
                }

                { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw -ExpectedMessage '*Unable to map the specified paths to valid cluster storage. Drives mapped: Backup; SysData; TempDbData; TempDbLogs; UserLogs.'
            }
        }

        It 'Should build a DEFAULT address string when no network is specified in parameter FailoverClusterIPAddress' {
            $mockStartSqlSetupProcessExpectedArgument = @{
                Action                       = 'InstallFailoverCluster'
                FailoverClusterIPAddresses   = 'DEFAULT'
                FailoverClusterNetworkName   = 'TestDefaultCluster'
                InstallSQLDataDir            = $mockDynamicSqlDataDirectoryPath
                SQLUserDBDir                 = $mockDynamicSqlUserDatabasePath
                SQLUserDBLogDir              = $mockDynamicSqlUserDatabaseLogPath
                SQLTempDBDir                 = $mockDynamicSqlTempDatabasePath
                SQLTempDBLogDir              = $mockDynamicSqlTempDatabaseLogPath
                SQLBackupDir                 = $mockDynamicSqlBackupPath
                FailoverClusterDisks         = 'Backup; SysData; TempDbData; TempDbLogs; UserData; UserLogs'
                IAcceptSQLServerLicenseTerms = 'True'
                Quiet                        = 'True'
                InstanceName                 = 'MSSQLSERVER'
                Features                     = 'SQLENGINE'
                SQLSysAdminAccounts          = 'COMPANY\sqladmin COMPANY\SQLAdmins COMPANY\User1'
                FailoverClusterGroup         = 'SQL Server (MSSQLSERVER)'
            }

            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockSetTargetResourceParameters = @{
                    SQLSysAdminAccounts        = 'COMPANY\User1', 'COMPANY\SQLAdmins'

                    # Feature support is tested elsewhere, so just include the minimum.
                    Features                   = 'SQLEngine'

                    InstanceName               = 'MSSQLSERVER'
                    SourcePath                 = $TestDrive
                    Action                     = 'InstallFailoverCluster'
                    FailoverClusterGroupName   = 'SQL Server (MSSQLSERVER)'
                    FailoverClusterNetworkName = 'TestDefaultCluster'

                    # Ensure we use "clustered" disks for our paths
                    InstallSQLDataDir          = 'E:\MSSQL\Data'
                    SQLUserDBDir               = 'K:\MSSQL\Data'
                    SQLUserDBLogDir            = 'L:\MSSQL\Logs'
                    SQLTempDbDir               = 'M:\MSSQL\TempDb\Data'
                    SQLTempDbLogDir            = 'N:\MSSQL\TempDb\Logs'
                    SQLBackupDir               = 'O:\MSSQL\Backup'
                }

                { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
            }
        }

        Context 'When an invalid IP Address is specified' {
            BeforeAll {
                <#
                    The default mock (higher up in the test code) will mock $true
                    for Test-IPAddress. This mock will override the default mock
                    so that Test-IPAddress returns $false.
                #>
                Mock -CommandName Test-IPAddress -MockWith {
                    return $false
                }
            }

            It 'Should throw an error when an invalid IP Address is specified' {
                $mockStartSqlSetupProcessExpectedArgument = @{}

                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters = @{
                        SQLSysAdminAccounts        = 'COMPANY\User1', 'COMPANY\SQLAdmins'

                        # Feature support is tested elsewhere, so just include the minimum.
                        Features                   = 'SQLEngine'

                        InstanceName               = 'MSSQLSERVER'
                        SourcePath                 = $TestDrive
                        Action                     = 'InstallFailoverCluster'
                        FailoverClusterGroupName   = 'SQL Server (MSSQLSERVER)'
                        FailoverClusterNetworkName = 'TestDefaultCluster'
                        FailoverClusterIPAddress   = '192.168.0.100'

                        # Ensure we use "clustered" disks for our paths
                        InstallSQLDataDir          = 'E:\MSSQL\Data'
                        SQLUserDBDir               = 'K:\MSSQL\Data'
                        SQLUserDBLogDir            = 'L:\MSSQL\Logs'
                        SQLTempDbDir               = 'M:\MSSQL\TempDb\Data'
                        SQLTempDbLogDir            = 'N:\MSSQL\TempDb\Logs'
                        SQLBackupDir               = 'O:\MSSQL\Backup'
                    }

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw -ExpectedMessage '*Unable to map the specified IP Address(es) to valid cluster networks.'
                }
            }
        }

        Context 'When an invalid IP Address is specified for a multi-subnet instance' {
            BeforeAll {
                <#
                    The default mock (higher up in the test code) will mock $true
                    for Test-IPAddress. This mock will override the default mock
                    so that one IP address ('10.0.0.100') returns $false from
                    Test-IPAddress.
                #>
                Mock -CommandName Test-IPAddress -MockWith {
                    return $false
                } -ParameterFilter {
                    $IPAddress -eq '10.0.0.100'
                }
            }

            It 'Should throw an error ' {
                $mockStartSqlSetupProcessExpectedArgument = @{}

                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters = @{
                        SQLSysAdminAccounts        = 'COMPANY\User1', 'COMPANY\SQLAdmins'

                        # Feature support is tested elsewhere, so just include the minimum.
                        Features                   = 'SQLEngine'

                        InstanceName               = 'MSSQLSERVER'
                        SourcePath                 = $TestDrive
                        Action                     = 'InstallFailoverCluster'
                        FailoverClusterGroupName   = 'SQL Server (MSSQLSERVER)'
                        FailoverClusterNetworkName = 'TestDefaultCluster'
                        FailoverClusterIPAddress   = @('10.0.0.100', '192.168.0.100')

                        # Ensure we use "clustered" disks for our paths
                        InstallSQLDataDir          = 'E:\MSSQL\Data'
                        SQLUserDBDir               = 'K:\MSSQL\Data'
                        SQLUserDBLogDir            = 'L:\MSSQL\Logs'
                        SQLTempDbDir               = 'M:\MSSQL\TempDb\Data'
                        SQLTempDbLogDir            = 'N:\MSSQL\TempDb\Logs'
                        SQLBackupDir               = 'O:\MSSQL\Backup'
                    }

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw -ExpectedMessage '*Unable to map the specified IP Address(es) to valid cluster networks.'
                }
            }
        }

        Context 'When an invalid IP Address is specified for a multi-subnet instance' {
            BeforeAll {
                <#
                    The default mock (higher up in the test code) will mock $true
                    for Test-IPAddress. These mocks will override the default mock
                    so that Test-IPAddress returns $false, and $true when IP address
                    has the correct subnet.
                #>
                Mock -CommandName Test-IPAddress -MockWith {
                    return $false
                }

                Mock -CommandName Test-IPAddress -MockWith {
                    return $true
                } -ParameterFilter {
                    $IPAddress -eq '10.0.0.10' -and $NetworkID -eq '10.0.0.10'
                }

                Mock -CommandName Test-IPAddress -MockWith {
                    return $true
                } -ParameterFilter {
                    $IPAddress -eq '10.0.10.100' -and $NetworkID -eq '10.0.10.100'
                }
            }

            It 'Should build a valid IP address string for a multi-subnet cluster' {
                # Setting up the mock to return multiple sites.
                $mockDynamicClusterSites = @(
                    @{
                        Name    = 'SiteA'
                        Address = '10.0.0.10' # First site IP address
                        Mask    = '255.255.255.0'
                    },
                    @{
                        Name    = 'SiteB'
                        Address = '10.0.10.100' # Second site IP address
                        Mask    = '255.255.255.0'
                    }
                )

                $mockStartSqlSetupProcessExpectedArgument += @{
                    FailoverClusterIPAddresses   = 'IPv4;10.0.0.10;SiteA_Prod;255.255.255.0; IPv4;10.0.10.100;SiteB_Prod;255.255.255.0'
                    FailoverClusterNetworkName   = 'TestDefaultCluster'
                    InstallSQLDataDir            = $mockDynamicSqlDataDirectoryPath
                    SQLUserDBDir                 = $mockDynamicSqlUserDatabasePath
                    SQLUserDBLogDir              = $mockDynamicSqlUserDatabaseLogPath
                    SQLTempDBDir                 = $mockDynamicSqlTempDatabasePath
                    SQLTempDBLogDir              = $mockDynamicSqlTempDatabaseLogPath
                    SQLBackupDir                 = $mockDynamicSqlBackupPath
                    FailoverClusterDisks         = 'Backup; SysData; TempDbData; TempDbLogs; UserData; UserLogs'
                    Action                       = 'InstallFailoverCluster'
                    IAcceptSQLServerLicenseTerms = 'True'
                    Quiet                        = 'True'
                    InstanceName                 = 'MSSQLSERVER'
                    Features                     = 'SQLENGINE'
                    SQLSysAdminAccounts          = 'COMPANY\sqladmin COMPANY\SQLAdmins COMPANY\User1'
                    FailoverClusterGroup         = 'SQL Server (MSSQLSERVER)'
                }

                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters = @{
                        SQLSysAdminAccounts        = 'COMPANY\User1', 'COMPANY\SQLAdmins'

                        # Feature support is tested elsewhere, so just include the minimum.
                        Features                   = 'SQLEngine'

                        InstanceName               = 'MSSQLSERVER'
                        SourcePath                 = $TestDrive
                        Action                     = 'InstallFailoverCluster'
                        FailoverClusterGroupName   = 'SQL Server (MSSQLSERVER)'
                        FailoverClusterNetworkName = 'TestDefaultCluster'
                        FailoverClusterIPAddress   = @('10.0.0.10', '10.0.10.100')

                        # Ensure we use "clustered" disks for our paths
                        InstallSQLDataDir          = 'E:\MSSQL\Data'
                        SQLUserDBDir               = 'K:\MSSQL\Data'
                        SQLUserDBLogDir            = 'L:\MSSQL\Logs'
                        SQLTempDbDir               = 'M:\MSSQL\TempDb\Data'
                        SQLTempDbLogDir            = 'N:\MSSQL\TempDb\Logs'
                        SQLBackupDir               = 'O:\MSSQL\Backup'
                    }

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                }

                # Reverting the mock to return a single site.
                $mockDynamicClusterSites = @(
                    @{
                        Name    = 'SiteA'
                        Address = '10.0.0.10' # First site IP address
                        Mask    = '255.255.255.0'
                    }
                )
            }
        }

        Context 'When Cluster Shared volumes are specified' {
            BeforeAll {
                $mockGetCIMInstance_MSCluster_ClusterSharedVolume = {
                    return @(
                        (
                            New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance 'MSCluster_ClusterSharedVolume', 'root/MSCluster' |
                                Add-Member -MemberType NoteProperty -Name 'Name' -Value 'C:\ClusterStorage\SysData' -PassThru -Force
                        ),
                        (
                            New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance 'MSCluster_ClusterSharedVolume', 'root/MSCluster' |
                                Add-Member -MemberType NoteProperty -Name 'Name' -Value 'C:\ClusterStorage\SQLData' -PassThru -Force
                        ),
                        (
                            New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance 'MSCluster_ClusterSharedVolume', 'root/MSCluster' |
                                Add-Member -MemberType NoteProperty -Name 'Name' -Value 'C:\ClusterStorage\SQLLogs' -PassThru -Force
                        ),
                        (
                            New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance 'MSCluster_ClusterSharedVolume', 'root/MSCluster' |
                                Add-Member -MemberType NoteProperty -Name 'Name' -Value 'C:\ClusterStorage\TempDBData' -PassThru -Force
                        ),
                        (
                            New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance 'MSCluster_ClusterSharedVolume', 'root/MSCluster' |
                                Add-Member -MemberType NoteProperty -Name 'Name' -Value 'C:\ClusterStorage\TempDBLogs' -PassThru -Force
                        ),
                        (
                            New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance 'MSCluster_ClusterSharedVolume', 'root/MSCluster' |
                                Add-Member -MemberType NoteProperty -Name 'Name' -Value 'C:\ClusterStorage\SQLBackup' -PassThru -Force
                        )
                    )
                }

                $mockGetCIMInstance_MSCluster_ClusterSharedVolumeToResource = {
                    return @(
                        (
                            New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance 'MSCluster_ClusterSharedVolume', 'root/MSCluster' |
                                Add-Member -MemberType NoteProperty -Name GroupComponent -Value (New-Object -TypeName PSObject -Property @{ Name = 'C:\ClusterStorage\SysData' }) -PassThru -Force |
                                Add-Member -MemberType NoteProperty -Name PartComponent -Value (New-Object -TypeName PSObject -Property @{ Name = 'Cluster Virtual Disk (SQL System Data Disk)' }) -PassThru -Force
                        ),
                        (
                            New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance 'MSCluster_ClusterSharedVolume', 'root/MSCluster' |
                                Add-Member -MemberType NoteProperty -Name GroupComponent -Value (New-Object -TypeName PSObject -Property @{ Name = 'C:\ClusterStorage\SQLData' }) -PassThru -Force |
                                Add-Member -MemberType NoteProperty -Name PartComponent -Value (New-Object -TypeName PSObject -Property @{ Name = 'Cluster Virtual Disk (SQL Data Disk)' }) -PassThru -Force
                        ),
                        (
                            New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance 'MSCluster_ClusterSharedVolume', 'root/MSCluster' |
                                Add-Member -MemberType NoteProperty -Name GroupComponent -Value (New-Object -TypeName PSObject -Property @{ Name = 'C:\ClusterStorage\SQLLogs' }) -PassThru -Force |
                                Add-Member -MemberType NoteProperty -Name PartComponent -Value (New-Object -TypeName PSObject -Property @{ Name = 'Cluster Virtual Disk (SQL Log Disk)' }) -PassThru -Force
                        ),
                        (
                            New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance 'MSCluster_ClusterSharedVolume', 'root/MSCluster' |
                                Add-Member -MemberType NoteProperty -Name GroupComponent -Value (New-Object -TypeName PSObject -Property @{ Name = 'C:\ClusterStorage\TempDBData' }) -PassThru -Force |
                                Add-Member -MemberType NoteProperty -Name PartComponent -Value (New-Object -TypeName PSObject -Property @{ Name = 'Cluster Virtual Disk (SQL TempDBData Disk)' }) -PassThru -Force
                        ),
                        (
                            New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance 'MSCluster_ClusterSharedVolume', 'root/MSCluster' |
                                Add-Member -MemberType NoteProperty -Name GroupComponent -Value (New-Object -TypeName PSObject -Property @{ Name = 'C:\ClusterStorage\TempDBLogs' }) -PassThru -Force |
                                Add-Member -MemberType NoteProperty -Name PartComponent -Value (New-Object -TypeName PSObject -Property @{ Name = 'Cluster Virtual Disk (SQL TempDBLog Disk)' }) -PassThru -Force
                        ),
                        (
                            New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance 'MSCluster_ClusterSharedVolume', 'root/MSCluster' |
                                Add-Member -MemberType NoteProperty -Name GroupComponent -Value (New-Object -TypeName PSObject -Property @{ Name = 'C:\ClusterStorage\SQLBackup' }) -PassThru -Force |
                                Add-Member -MemberType NoteProperty -Name PartComponent -Value (New-Object -TypeName PSObject -Property @{ Name = 'Cluster Virtual Disk (SQL Backup Disk)' }) -PassThru -Force
                        )
                    )
                }

                Mock -CommandName Get-CimInstance -MockWith $mockGetCIMInstance_MSCluster_ClusterSharedVolume -ParameterFilter {
                    $ClassName -eq 'MSCluster_ClusterSharedVolume'
                }

                Mock -CommandName Get-CimInstance -MockWith $mockGetCIMInstance_MSCluster_ClusterSharedVolumeToResource -ParameterFilter {
                    $ClassName -eq 'MSCluster_ClusterSharedVolumeToResource'
                }
            }

            It 'Should pass proper parameters to setup' {
                $mockStartSqlSetupProcessExpectedArgument = @{
                    Action                       = 'InstallFailoverCluster'
                    FailoverClusterDisks         = 'Cluster Virtual Disk (SQL Backup Disk); Cluster Virtual Disk (SQL Data Disk); Cluster Virtual Disk (SQL Log Disk); Cluster Virtual Disk (SQL System Data Disk); Cluster Virtual Disk (SQL TempDBData Disk); Cluster Virtual Disk (SQL TempDBLog Disk)'
                    FailoverClusterIPAddresses   = 'IPV4;10.0.0.10;SiteA_Prod;255.255.255.0'
                    FailoverClusterNetworkName   = 'TestDefaultCluster'
                    InstallSQLDataDir            = 'C:\ClusterStorage\SysData'
                    SQLUserDBDir                 = 'C:\ClusterStorage\SQLData'
                    SQLUserDBLogDir              = 'C:\ClusterStorage\SQLLogs'
                    SQLTempDBDir                 = 'C:\ClusterStorage\TempDBData'
                    SQLTempDBLogDir              = 'C:\ClusterStorage\TempDBLogs'
                    SQLBackupDir                 = 'C:\ClusterStorage\SQLBackup'
                    IAcceptSQLServerLicenseTerms = 'True'
                    Quiet                        = 'True'
                    InstanceName                 = 'MSSQLSERVER'
                    Features                     = 'SQLENGINE'
                    SQLSysAdminAccounts          = 'COMPANY\sqladmin COMPANY\SQLAdmins COMPANY\User1'
                    FailoverClusterGroup         = 'SQL Server (MSSQLSERVER)'
                }

                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters = @{
                        SQLSysAdminAccounts        = 'COMPANY\User1', 'COMPANY\SQLAdmins'

                        # Feature support is tested elsewhere, so just include the minimum.
                        Features                   = 'SQLEngine'

                        InstanceName               = 'MSSQLSERVER'
                        SourcePath                 = $TestDrive
                        Action                     = 'InstallFailoverCluster'
                        FailoverClusterGroupName   = 'SQL Server (MSSQLSERVER)'
                        FailoverClusterNetworkName = 'TestDefaultCluster'
                        FailoverClusterIPAddress   = '10.0.0.10'

                        # Ensure we use "clustered" disks for our paths
                        InstallSQLDataDir          = 'C:\ClusterStorage\SysData'
                        SQLUserDBDir               = 'C:\ClusterStorage\SQLData'
                        SQLUserDBLogDir            = 'C:\ClusterStorage\SQLLogs'
                        SQLTempDbDir               = 'C:\ClusterStorage\TempDBData'
                        SQLTempDbLogDir            = 'C:\ClusterStorage\TempDBLogs'
                        SQLBackupDir               = 'C:\ClusterStorage\SQLBackup'
                    }

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                }
            }

            Context 'When Cluster Shared volumes are the same for one or more parameters' {
                It 'Should pass proper parameters to setup' {
                    $mockStartSqlSetupProcessExpectedArgument = @{
                        Action                       = 'InstallFailoverCluster'
                        FailoverClusterDisks         = 'Cluster Virtual Disk (SQL Backup Disk); Cluster Virtual Disk (SQL Data Disk)'
                        FailoverClusterIPAddresses   = 'IPV4;10.0.0.10;SiteA_Prod;255.255.255.0'
                        FailoverClusterNetworkName   = 'TestDefaultCluster'
                        InstallSQLDataDir            = 'C:\ClusterStorage\SQLData\Data'
                        SQLUserDBDir                 = 'C:\ClusterStorage\SQLData\Data'
                        SQLUserDBLogDir              = 'C:\ClusterStorage\SQLData\Logs'
                        SQLTempDBDir                 = 'C:\ClusterStorage\SQLData\TEMPDB'
                        SQLTempDBLogDir              = 'C:\ClusterStorage\SQLData\TEMPDBLOG'
                        SQLBackupDir                 = 'C:\ClusterStorage\SQLBackup\Backup'
                        IAcceptSQLServerLicenseTerms = 'True'
                        Quiet                        = 'True'
                        InstanceName                 = 'MSSQLSERVER'
                        Features                     = 'SQLENGINE'
                        SQLSysAdminAccounts          = 'COMPANY\sqladmin COMPANY\SQLAdmins COMPANY\User1'
                        FailoverClusterGroup         = 'SQL Server (MSSQLSERVER)'
                    }

                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $mockSetTargetResourceParameters = @{
                            SQLSysAdminAccounts        = 'COMPANY\User1', 'COMPANY\SQLAdmins'

                            # Feature support is tested elsewhere, so just include the minimum.
                            Features                   = 'SQLEngine'

                            InstanceName               = 'MSSQLSERVER'
                            SourcePath                 = $TestDrive
                            Action                     = 'InstallFailoverCluster'
                            FailoverClusterGroupName   = 'SQL Server (MSSQLSERVER)'
                            FailoverClusterNetworkName = 'TestDefaultCluster'
                            FailoverClusterIPAddress   = '10.0.0.10'

                            # Ensure we use "clustered" disks for our paths
                            InstallSQLDataDir          = 'C:\ClusterStorage\SQLData\Data'
                            SQLUserDBDir               = 'C:\ClusterStorage\SQLData\Data'
                            SQLUserDBLogDir            = 'C:\ClusterStorage\SQLData\Logs'
                            SQLTempDbDir               = 'C:\ClusterStorage\SQLData\TEMPDB'
                            SQLTempDbLogDir            = 'C:\ClusterStorage\SQLData\TEMPDBLOG'
                            SQLBackupDir               = 'C:\ClusterStorage\SQLBackup\Backup'
                        }

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                    }
                }
            }
        }
    }

    Context 'When action is set to ''PrepareFailoverCluster''' {
        BeforeAll {
            Mock -CommandName Get-FilePathMajorVersion -MockWith {
                return 15
            }

            Mock -CommandName Get-TargetResource -MockWith {
                return @{
                    Features = ''
                }
            }

            Mock -CommandName Invoke-InstallationMediaCopy -MockWith $mockNewTemporaryFolder

            Mock -CommandName Get-CimInstance -ParameterFilter {
                ($Namespace -eq 'root/MSCluster') -and ($ClassName -eq 'MSCluster_ResourceGroup') -and ($Filter -eq "Name = 'Available Storage'")
            }

            Mock -CommandName Get-CimAssociatedInstance -ParameterFilter {
                ($Association -eq 'MSCluster_ResourceGroupToResource') -and ($ResultClassName -eq 'MSCluster_Resource')
            }

            Mock -CommandName Get-CimAssociatedInstance -ParameterFilter {
                $Association -eq 'MSCluster_ResourceToPossibleOwner'
            }

            Mock -CommandName Get-CimAssociatedInstance -ParameterFilter {
                $ResultClass -eq 'MSCluster_DiskPartition'
            }

            Mock -CommandName Get-CimInstance -ParameterFilter {
                ($Namespace -eq 'root/MSCluster') -and ($ClassName -eq 'MSCluster_Network') -and ($Filter -eq 'Role >= 2')
            }
        }

        It 'Should pass correct arguments to the setup process' {
            $mockStartSqlSetupProcessExpectedArgument = @{
                Action                       = 'PrepareFailoverCluster'
                IAcceptSQLServerLicenseTerms = 'True'
                Quiet                        = 'True'
                InstanceName                 = 'MSSQLSERVER'
                Features                     = 'SQLENGINE'
            }

            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockSetTargetResourceParameters = @{
                    # Feature support is tested elsewhere, so just include the minimum.
                    Features     = 'SQLEngine'

                    InstanceName = 'MSSQLSERVER'
                    SourcePath   = $TestDrive
                    Action       = 'PrepareFailoverCluster'
                }

                { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
            }

            Should -Invoke -CommandName Get-PSDrive -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Start-SqlSetupProcess -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Test-TargetResource -Exactly -Times 1 -Scope It

            Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                ($Namespace -eq 'root/MSCluster') -and ($ClassName -eq 'MSCluster_ResourceGroup') -and ($Filter -eq "Name = 'Available Storage'")
            } -Exactly -Times 0 -Scope It

            Should -Invoke -CommandName Get-CimAssociatedInstance -ParameterFilter {
                ($Association -eq 'MSCluster_ResourceGroupToResource') -and ($ResultClassName -eq 'MSCluster_Resource')
            } -Exactly -Times 0 -Scope It

            Should -Invoke -CommandName Get-CimAssociatedInstance -ParameterFilter {
                $Association -eq 'MSCluster_ResourceToPossibleOwner'
            } -Exactly -Times 0 -Scope It

            Should -Invoke -CommandName Get-CimAssociatedInstance -ParameterFilter {
                $ResultClass -eq 'MSCluster_DiskPartition'
            } -Exactly -Times 0 -Scope It

            Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                ($Namespace -eq 'root/MSCluster') -and ($ClassName -eq 'MSCluster_Network') -and ($Filter -eq 'Role >= 2')
            } -Exactly -Times 0 -Scope It
        }
    }

    Context 'When action is set to ''CompleteFailoverCluster''' {
        BeforeAll {
            Mock -CommandName Get-FilePathMajorVersion -MockWith {
                return 15
            }

            # Cluster shared volumes will be tested and mocked later on.
            Mock -CommandName Get-CimInstance -MockWith {
                return $null
            } -ParameterFilter {
                $ClassName -eq 'MSCluster_ClusterSharedVolume'
            }

            Mock -CommandName Get-TargetResource -MockWith {
                return @{
                    Features = ''
                }
            }

            $mockDynamicSqlDataDirectoryPath = 'E:\MSSQL\Data'
            $mockDynamicSqlUserDatabasePath = 'K:\MSSQL\Data'
            $mockDynamicSqlUserDatabaseLogPath = 'L:\MSSQL\Logs'
            $mockDynamicSqlTempDatabasePath = 'M:\MSSQL\TempDb\Data'
            $mockDynamicSqlTempDatabaseLogPath = 'N:\MSSQL\TempDb\Logs'
            $mockDynamicSqlBackupPath = 'O:\MSSQL\Backup'

            Mock -CommandName Get-CimInstance -MockWith $mockGetCimInstance_MSClusterResourceGroup_AvailableStorage -ParameterFilter {
                $Filter -eq "Name = 'Available Storage'"
            }

            Mock -CommandName Get-CimAssociatedInstance -MockWith $mockGetCimAssociatedInstance_MSCluster_ResourceGroupToResource -ParameterFilter {
                ($Association -eq 'MSCluster_ResourceGroupToResource') -and ($ResultClassName -eq 'MSCluster_Resource')
            }

            Mock -CommandName Get-CimAssociatedInstance -MockWith $mockGetCimAssociatedInstance_MSCluster_ResourceToPossibleOwner -ParameterFilter {
                $Association -eq 'MSCluster_ResourceToPossibleOwner'
            }

            Mock -CommandName Get-CimAssociatedInstance -MockWith $mockGetCimAssociatedInstance_MSCluster_DiskPartition -ParameterFilter {
                $ResultClassName -eq 'MSCluster_DiskPartition'
            }

            $mockDynamicClusterSites = @(
                @{
                    Name    = 'SiteA'
                    Address = '10.0.0.10' # First site IP address
                    Mask    = '255.255.255.0'
                }
            )

            Mock -CommandName Get-CimInstance -MockWith $mockGetCimInstance_MSClusterNetwork -ParameterFilter {
                ($Namespace -eq 'root/MSCluster') -and ($ClassName -eq 'MSCluster_Network') -and ($Filter -eq 'Role >= 2')
            }

            Mock -CommandName Test-IPAddress -MockWith {
                return $true
            }
        }

        It 'Should pass proper parameters to setup' {
            $mockStartSqlSetupProcessExpectedArgument = @{
                Action                       = 'CompleteFailoverCluster'
                FailoverClusterDisks         = 'Backup; SysData; TempDbData; TempDbLogs; UserData; UserLogs'
                FailoverClusterIPAddresses   = 'IPV4;10.0.0.10;SiteA_Prod;255.255.255.0'
                FailoverClusterNetworkName   = 'TestDefaultCluster'
                InstallSQLDataDir            = 'E:\MSSQL\Data'
                SQLUserDBDir                 = 'K:\MSSQL\Data'
                SQLUserDBLogDir              = 'L:\MSSQL\Logs'
                SQLTempDBDir                 = 'M:\MSSQL\TempDb\Data'
                SQLTempDBLogDir              = 'N:\MSSQL\TempDb\Logs'
                SQLBackupDir                 = 'O:\MSSQL\Backup'
                IAcceptSQLServerLicenseTerms = 'True'
                Quiet                        = 'True'
                InstanceName                 = 'MSSQLSERVER'
                Features                     = 'SQLENGINE'
                SQLSysAdminAccounts          = 'COMPANY\sqladmin COMPANY\SQLAdmins COMPANY\User1'
                FailoverClusterGroup         = 'SQL Server (MSSQLSERVER)'
            }

            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockSetTargetResourceParameters = @{
                    SQLSysAdminAccounts        = 'COMPANY\User1', 'COMPANY\SQLAdmins'

                    # Feature support is tested elsewhere, so just include the minimum.
                    Features                   = 'SQLEngine'

                    InstanceName               = 'MSSQLSERVER'
                    SourcePath                 = $TestDrive
                    Action                     = 'CompleteFailoverCluster'
                    FailoverClusterGroupName   = 'SQL Server (MSSQLSERVER)'
                    FailoverClusterNetworkName = 'TestDefaultCluster'
                    FailoverClusterIPAddress   = '10.0.0.10'

                    # Ensure we use "clustered" disks for our paths
                    InstallSQLDataDir          = 'E:\MSSQL\Data'
                    SQLUserDBDir               = 'K:\MSSQL\Data'
                    SQLUserDBLogDir            = 'L:\MSSQL\Logs'
                    SQLTempDbDir               = 'M:\MSSQL\TempDb\Data'
                    SQLTempDbLogDir            = 'N:\MSSQL\TempDb\Logs'
                    SQLBackupDir               = 'O:\MSSQL\Backup'
                }

                { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
            }
        }

        It 'Should pass proper parameters to setup when only InstallSQLDataDir is assigned a path' {
            $mockStartSqlSetupProcessExpectedArgument = @{
                Action                       = 'CompleteFailoverCluster'
                FailoverClusterDisks         = 'SysData'
                FailoverClusterIPAddresses   = 'IPV4;10.0.0.10;SiteA_Prod;255.255.255.0'
                FailoverClusterNetworkName   = 'TestDefaultCluster'
                InstallSQLDataDir            = 'E:\MSSQL\Data'
                IAcceptSQLServerLicenseTerms = 'True'
                Quiet                        = 'True'
                InstanceName                 = 'MSSQLSERVER'
                Features                     = 'SQLENGINE'
                SQLSysAdminAccounts          = 'COMPANY\sqladmin COMPANY\SQLAdmins COMPANY\User1'
                FailoverClusterGroup         = 'SQL Server (MSSQLSERVER)'
            }

            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockSetTargetResourceParameters = @{
                    SQLSysAdminAccounts        = 'COMPANY\User1', 'COMPANY\SQLAdmins'

                    # Feature support is tested elsewhere, so just include the minimum.
                    Features                   = 'SQLEngine'

                    InstanceName               = 'MSSQLSERVER'
                    SourcePath                 = $TestDrive
                    Action                     = 'CompleteFailoverCluster'
                    FailoverClusterGroupName   = 'SQL Server (MSSQLSERVER)'
                    FailoverClusterNetworkName = 'TestDefaultCluster'
                    FailoverClusterIPAddress   = '10.0.0.10'

                    # Ensure we use "clustered" disks for our paths
                    InstallSQLDataDir          = 'E:\MSSQL\Data'
                }

                { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
            }
        }

        It 'Should pass proper parameters to setup when three variables are assigned the same drive, but different paths' {
            $mockStartSqlSetupProcessExpectedArgument = @{
                Action                       = 'CompleteFailoverCluster'
                FailoverClusterDisks         = 'SysData'
                FailoverClusterIPAddresses   = 'IPV4;10.0.0.10;SiteA_Prod;255.255.255.0'
                FailoverClusterNetworkName   = 'TestDefaultCluster'
                InstallSQLDataDir            = 'E:\SQLData'
                SQLUserDBDir                 = 'E:\SQLData\UserDb'
                SQLUserDBLogDir              = 'E:\SQLData\UserDbLogs'
                IAcceptSQLServerLicenseTerms = 'True'
                Quiet                        = 'True'
                InstanceName                 = 'MSSQLSERVER'
                Features                     = 'SQLENGINE'
                SQLSysAdminAccounts          = 'COMPANY\sqladmin COMPANY\SQLAdmins COMPANY\User1'
                FailoverClusterGroup         = 'SQL Server (MSSQLSERVER)'
            }

            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockSetTargetResourceParameters = @{
                    SQLSysAdminAccounts        = 'COMPANY\User1', 'COMPANY\SQLAdmins'

                    # Feature support is tested elsewhere, so just include the minimum.
                    Features                   = 'SQLEngine'

                    InstanceName               = 'MSSQLSERVER'
                    SourcePath                 = $TestDrive
                    Action                     = 'CompleteFailoverCluster'
                    FailoverClusterGroupName   = 'SQL Server (MSSQLSERVER)'
                    FailoverClusterNetworkName = 'TestDefaultCluster'
                    FailoverClusterIPAddress   = '10.0.0.10'

                    # Ensure we use "clustered" disks for our paths
                    InstallSQLDataDir          = 'E:\SQLData\' # This ends with \ to test removal of paths ending with \
                    SQLUserDBDir               = 'E:\SQLData\UserDb'
                    SQLUserDBLogDir            = 'E:\SQLData\UserDbLogs'
                }

                { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
            }
        }

        It 'Should throw an error when one or more paths are not resolved to clustered storage' {
            $mockStartSqlSetupProcessExpectedArgument = @{}

            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockSetTargetResourceParameters = @{
                    SQLSysAdminAccounts        = 'COMPANY\User1', 'COMPANY\SQLAdmins'

                    # Feature support is tested elsewhere, so just include the minimum.
                    Features                   = 'SQLEngine'

                    InstanceName               = 'MSSQLSERVER'
                    SourcePath                 = $TestDrive
                    Action                     = 'CompleteFailoverCluster'
                    FailoverClusterGroupName   = 'SQL Server (MSSQLSERVER)'
                    FailoverClusterNetworkName = 'TestDefaultCluster'
                    FailoverClusterIPAddress   = '10.0.0.10'

                    InstallSQLDataDir          = 'E:\MSSQL\Data'
                    SQLUserDBLogDir            = 'L:\MSSQL\Logs'
                    SQLTempDbDir               = 'M:\MSSQL\TempDb\Data'
                    SQLTempDbLogDir            = 'N:\MSSQL\TempDb\Logs'
                    SQLBackupDir               = 'O:\MSSQL\Backup'

                    SQLUserDBDir               = 'C:\MSSQL\' # Pass in a bad path
                }

                { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw -ExpectedMessage '*Unable to map the specified paths to valid cluster storage. Drives mapped: Backup; SysData; TempDbData; TempDbLogs; UserLogs.'
            }
        }

        It 'Should build a DEFAULT address string when no network is specified in parameter FailoverClusterIPAddress' {
            $mockStartSqlSetupProcessExpectedArgument = @{
                Action                       = 'CompleteFailoverCluster'
                FailoverClusterIPAddresses   = 'DEFAULT'
                FailoverClusterNetworkName   = 'TestDefaultCluster'
                InstallSQLDataDir            = $mockDynamicSqlDataDirectoryPath
                SQLUserDBDir                 = $mockDynamicSqlUserDatabasePath
                SQLUserDBLogDir              = $mockDynamicSqlUserDatabaseLogPath
                SQLTempDBDir                 = $mockDynamicSqlTempDatabasePath
                SQLTempDBLogDir              = $mockDynamicSqlTempDatabaseLogPath
                SQLBackupDir                 = $mockDynamicSqlBackupPath
                FailoverClusterDisks         = 'Backup; SysData; TempDbData; TempDbLogs; UserData; UserLogs'
                IAcceptSQLServerLicenseTerms = 'True'
                Quiet                        = 'True'
                InstanceName                 = 'MSSQLSERVER'
                Features                     = 'SQLENGINE'
                SQLSysAdminAccounts          = 'COMPANY\sqladmin COMPANY\SQLAdmins COMPANY\User1'
                FailoverClusterGroup         = 'SQL Server (MSSQLSERVER)'
            }

            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockSetTargetResourceParameters = @{
                    SQLSysAdminAccounts        = 'COMPANY\User1', 'COMPANY\SQLAdmins'

                    # Feature support is tested elsewhere, so just include the minimum.
                    Features                   = 'SQLEngine'

                    InstanceName               = 'MSSQLSERVER'
                    SourcePath                 = $TestDrive
                    Action                     = 'CompleteFailoverCluster'
                    FailoverClusterGroupName   = 'SQL Server (MSSQLSERVER)'
                    FailoverClusterNetworkName = 'TestDefaultCluster'

                    # Ensure we use "clustered" disks for our paths
                    InstallSQLDataDir          = 'E:\MSSQL\Data'
                    SQLUserDBDir               = 'K:\MSSQL\Data'
                    SQLUserDBLogDir            = 'L:\MSSQL\Logs'
                    SQLTempDbDir               = 'M:\MSSQL\TempDb\Data'
                    SQLTempDbLogDir            = 'N:\MSSQL\TempDb\Logs'
                    SQLBackupDir               = 'O:\MSSQL\Backup'
                }

                { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
            }
        }

        Context 'When an invalid IP Address is specified' {
            BeforeAll {
                <#
                    The default mock (higher up in the test code) will mock $true
                    for Test-IPAddress. This mock will override the default mock
                    so that Test-IPAddress returns $false.
                #>
                Mock -CommandName Test-IPAddress -MockWith {
                    return $false
                }
            }

            It 'Should throw an error when an invalid IP Address is specified' {
                $mockStartSqlSetupProcessExpectedArgument = @{}

                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters = @{
                        SQLSysAdminAccounts        = 'COMPANY\User1', 'COMPANY\SQLAdmins'

                        # Feature support is tested elsewhere, so just include the minimum.
                        Features                   = 'SQLEngine'

                        InstanceName               = 'MSSQLSERVER'
                        SourcePath                 = $TestDrive
                        Action                     = 'CompleteFailoverCluster'
                        FailoverClusterGroupName   = 'SQL Server (MSSQLSERVER)'
                        FailoverClusterNetworkName = 'TestDefaultCluster'
                        FailoverClusterIPAddress   = '192.168.0.100'

                        # Ensure we use "clustered" disks for our paths
                        InstallSQLDataDir          = 'E:\MSSQL\Data'
                        SQLUserDBDir               = 'K:\MSSQL\Data'
                        SQLUserDBLogDir            = 'L:\MSSQL\Logs'
                        SQLTempDbDir               = 'M:\MSSQL\TempDb\Data'
                        SQLTempDbLogDir            = 'N:\MSSQL\TempDb\Logs'
                        SQLBackupDir               = 'O:\MSSQL\Backup'
                    }

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw -ExpectedMessage '*Unable to map the specified IP Address(es) to valid cluster networks.'
                }
            }
        }

        Context 'When an invalid IP Address is specified for a multi-subnet instance' {
            BeforeAll {
                <#
                    The default mock (higher up in the test code) will mock $true
                    for Test-IPAddress. This mock will override the default mock
                    so that one IP address ('10.0.0.100') returns $false from
                    Test-IPAddress.
                #>
                Mock -CommandName Test-IPAddress -MockWith {
                    return $false
                } -ParameterFilter {
                    $IPAddress -eq '10.0.0.100'
                }
            }

            It 'Should throw an error ' {
                $mockStartSqlSetupProcessExpectedArgument = @{}

                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters = @{
                        SQLSysAdminAccounts        = 'COMPANY\User1', 'COMPANY\SQLAdmins'

                        # Feature support is tested elsewhere, so just include the minimum.
                        Features                   = 'SQLEngine'

                        InstanceName               = 'MSSQLSERVER'
                        SourcePath                 = $TestDrive
                        Action                     = 'CompleteFailoverCluster'
                        FailoverClusterGroupName   = 'SQL Server (MSSQLSERVER)'
                        FailoverClusterNetworkName = 'TestDefaultCluster'
                        FailoverClusterIPAddress   = @('10.0.0.100', '192.168.0.100')

                        # Ensure we use "clustered" disks for our paths
                        InstallSQLDataDir          = 'E:\MSSQL\Data'
                        SQLUserDBDir               = 'K:\MSSQL\Data'
                        SQLUserDBLogDir            = 'L:\MSSQL\Logs'
                        SQLTempDbDir               = 'M:\MSSQL\TempDb\Data'
                        SQLTempDbLogDir            = 'N:\MSSQL\TempDb\Logs'
                        SQLBackupDir               = 'O:\MSSQL\Backup'
                    }

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw -ExpectedMessage '*Unable to map the specified IP Address(es) to valid cluster networks.'
                }
            }
        }

        Context 'When an invalid IP Address is specified for a multi-subnet instance' {
            BeforeAll {
                <#
                    The default mock (higher up in the test code) will mock $true
                    for Test-IPAddress. These mocks will override the default mock
                    so that Test-IPAddress returns $false, and $true when IP address
                    has the correct subnet.
                #>
                Mock -CommandName Test-IPAddress -MockWith {
                    return $false
                }

                Mock -CommandName Test-IPAddress -MockWith {
                    return $true
                } -ParameterFilter {
                    $IPAddress -eq '10.0.0.10' -and $NetworkID -eq '10.0.0.10'
                }

                Mock -CommandName Test-IPAddress -MockWith {
                    return $true
                } -ParameterFilter {
                    $IPAddress -eq '10.0.10.100' -and $NetworkID -eq '10.0.10.100'
                }
            }

            It 'Should build a valid IP address string for a multi-subnet cluster' {
                # Setting up the mock to return multiple sites.
                $mockDynamicClusterSites = @(
                    @{
                        Name    = 'SiteA'
                        Address = '10.0.0.10' # First site IP address
                        Mask    = '255.255.255.0'
                    },
                    @{
                        Name    = 'SiteB'
                        Address = '10.0.10.100' # Second site IP address
                        Mask    = '255.255.255.0'
                    }
                )

                $mockStartSqlSetupProcessExpectedArgument += @{
                    FailoverClusterIPAddresses   = 'IPv4;10.0.0.10;SiteA_Prod;255.255.255.0; IPv4;10.0.10.100;SiteB_Prod;255.255.255.0'
                    FailoverClusterNetworkName   = 'TestDefaultCluster'
                    InstallSQLDataDir            = $mockDynamicSqlDataDirectoryPath
                    SQLUserDBDir                 = $mockDynamicSqlUserDatabasePath
                    SQLUserDBLogDir              = $mockDynamicSqlUserDatabaseLogPath
                    SQLTempDBDir                 = $mockDynamicSqlTempDatabasePath
                    SQLTempDBLogDir              = $mockDynamicSqlTempDatabaseLogPath
                    SQLBackupDir                 = $mockDynamicSqlBackupPath
                    FailoverClusterDisks         = 'Backup; SysData; TempDbData; TempDbLogs; UserData; UserLogs'
                    Action                       = 'CompleteFailoverCluster'
                    IAcceptSQLServerLicenseTerms = 'True'
                    Quiet                        = 'True'
                    InstanceName                 = 'MSSQLSERVER'
                    Features                     = 'SQLENGINE'
                    SQLSysAdminAccounts          = 'COMPANY\sqladmin COMPANY\SQLAdmins COMPANY\User1'
                    FailoverClusterGroup         = 'SQL Server (MSSQLSERVER)'
                }

                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters = @{
                        SQLSysAdminAccounts        = 'COMPANY\User1', 'COMPANY\SQLAdmins'

                        # Feature support is tested elsewhere, so just include the minimum.
                        Features                   = 'SQLEngine'

                        InstanceName               = 'MSSQLSERVER'
                        SourcePath                 = $TestDrive
                        Action                     = 'CompleteFailoverCluster'
                        FailoverClusterGroupName   = 'SQL Server (MSSQLSERVER)'
                        FailoverClusterNetworkName = 'TestDefaultCluster'
                        FailoverClusterIPAddress   = @('10.0.0.10', '10.0.10.100')

                        # Ensure we use "clustered" disks for our paths
                        InstallSQLDataDir          = 'E:\MSSQL\Data'
                        SQLUserDBDir               = 'K:\MSSQL\Data'
                        SQLUserDBLogDir            = 'L:\MSSQL\Logs'
                        SQLTempDbDir               = 'M:\MSSQL\TempDb\Data'
                        SQLTempDbLogDir            = 'N:\MSSQL\TempDb\Logs'
                        SQLBackupDir               = 'O:\MSSQL\Backup'
                    }

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                }

                # Reverting the mock to return a single site.
                $mockDynamicClusterSites = @(
                    @{
                        Name    = 'SiteA'
                        Address = '10.0.0.10' # First site IP address
                        Mask    = '255.255.255.0'
                    }
                )
            }
        }
    }
}

Describe 'Get-ServiceAccountParameters' -Tag 'Helper' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            $mockServiceAccountPassword = ConvertTo-SecureString 'Password' -AsPlainText -Force

            $script:mockSystemServiceAccount = `
                New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList 'NT AUTHORITY\SYSTEM', $mockServiceAccountPassword

            $script:mockVirtualServiceAccount = `
                New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList 'NT SERVICE\MSSQLSERVER', $mockServiceAccountPassword

            $script:mockManagedServiceAccount = `
                New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList 'COMPANY\ManagedAccount$', $mockServiceAccountPassword

            $script:mockDomainServiceAccount = `
                New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList 'COMPANY\sql.service', $mockServiceAccountPassword

            $script:mockDomainServiceAccountContainingDollarSign = `
                New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList 'COMPANY\$sql.service', $mockServiceAccountPassword
        }
    }

    Context 'When service type is <_>' -ForEach @(
        @{
            MockServiceType = 'SQL'
        }
        @{
            MockServiceType = 'AGT'
        }
        @{
            MockServiceType = 'IS'
        }
        @{
            MockServiceType = 'RS'
        }
        @{
            MockServiceType = 'AS'
        }
        @{
            MockServiceType = 'FT'
        }
    ) {
        BeforeAll {
            InModuleScope -Parameters $_ -ScriptBlock {
                $script:mockAccountArgumentName = '{0}SVCACCOUNT' -f $MockServiceType
                $script:mockPasswordArgumentName = '{0}SVCPASSWORD' -f $MockServiceType
            }
        }

        It 'Should return the correct parameters when the account is a system account' {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-ServiceAccountParameters -ServiceAccount $mockSystemServiceAccount -ServiceType $MockServiceType

                $result.$mockAccountArgumentName | Should -BeExactly $mockSystemServiceAccount.UserName
                $result.ContainsKey($mockPasswordArgumentName) | Should -BeFalse
            }
        }

        It 'Should return the correct parameters when the account is a virtual service account' {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-ServiceAccountParameters -ServiceAccount $mockVirtualServiceAccount -ServiceType $MockServiceType

                $result.$mockAccountArgumentName | Should -BeExactly $mockVirtualServiceAccount.UserName
                $result.ContainsKey($mockPasswordArgumentName) | Should -BeFalse
            }
        }

        It 'Should return the correct parameters when the account is a managed service account' {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-ServiceAccountParameters -ServiceAccount $mockManagedServiceAccount -ServiceType $MockServiceType

                $result.$mockAccountArgumentName | Should -BeExactly $mockManagedServiceAccount.UserName
                $result.ContainsKey($mockPasswordArgumentName) | Should -BeFalse
            }
        }

        It 'Should return the correct parameters when the account is a domain account' {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-ServiceAccountParameters -ServiceAccount $mockDomainServiceAccount -ServiceType $MockServiceType

                $result.$mockAccountArgumentName | Should -BeExactly $mockDomainServiceAccount.UserName
                $result.$mockPasswordArgumentName | Should -BeExactly $mockDomainServiceAccount.GetNetworkCredential().Password
            }
        }

        # Regression test for issue #1055
        It 'Should return the correct parameters when the account is a domain account containing a dollar sign ($)' {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-ServiceAccountParameters -ServiceAccount $mockDomainServiceAccountContainingDollarSign -ServiceType $MockServiceType

                $result.$mockAccountArgumentName | Should -BeExactly $mockDomainServiceAccountContainingDollarSign.UserName
                $result.$mockPasswordArgumentName | Should -BeExactly $mockDomainServiceAccountContainingDollarSign.GetNetworkCredential().Password
            }
        }
    }
}

Describe 'Get-InstalledSharedFeatures' -Tag 'Helper' {
    Context 'When there are no shared features installed' {
        BeforeAll {
            Mock -CommandName Get-ItemProperty -ParameterFilter {
                $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\140\ConfigurationState'
            } -MockWith {
                return @(
                    (
                        New-Object -TypeName Object |
                            Add-Member -MemberType NoteProperty -Name 'UnknownKey' -Value 1 -PassThru -Force
                    )
                )
            }
        }

        It 'Should return an empty array' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $getInstalledSharedFeaturesResult = Get-InstalledSharedFeatures -SqlServerMajorVersion 14

                $getInstalledSharedFeaturesResult | Should -HaveCount 0
            }
        }
    }

    Context 'When there are shared features installed' {
        BeforeAll {
            Mock -CommandName Get-ItemProperty -ParameterFilter {
                $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\140\ConfigurationState'
            } -MockWith {
                return @(
                    (
                        New-Object -TypeName Object |
                            Add-Member -MemberType NoteProperty -Name 'SQL_DQ_CLIENT_Full' -Value 1 -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'SQL_BOL_Components' -Value 1 -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'Connectivity_Full' -Value 1 -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'Tools_Legacy_Full' -Value 1 -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'SDK_Full' -Value 1 -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'MDSCoreFeature' -Value 1 -PassThru -Force
                    )
                )
            }
        }

        It 'Should return the correct array with installed shared features' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $getInstalledSharedFeaturesResult = Get-InstalledSharedFeatures -SqlServerMajorVersion 14

                $getInstalledSharedFeaturesResult | Should -HaveCount 6
                $getInstalledSharedFeaturesResult | Should -Contain 'DQC'
                $getInstalledSharedFeaturesResult | Should -Contain 'BOL'
                $getInstalledSharedFeaturesResult | Should -Contain 'CONN'
                $getInstalledSharedFeaturesResult | Should -Contain 'BC'
                $getInstalledSharedFeaturesResult | Should -Contain 'SDK'
                $getInstalledSharedFeaturesResult | Should -Contain 'MDS'
            }
        }
    }
}

Describe 'Test-FeatureFlag' -Tag 'Helper' {
    Context 'When no feature flags was provided' {
        It 'Should return $false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-FeatureFlag -FeatureFlag $null -TestFlag 'MyFlag' | Should -BeFalse
            }
        }
    }

    Context 'When feature flags was provided' {
        It 'Should return $true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-FeatureFlag -FeatureFlag @('FirstFlag', 'SecondFlag') -TestFlag 'SecondFlag' | Should -BeTrue
            }
        }
    }

    Context 'When feature flags was provided, but missing' {
        It 'Should return $false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-FeatureFlag -FeatureFlag @('MyFlag2') -TestFlag 'MyFlag' | Should -BeFalse
            }
        }
    }
}

Describe 'Get-FullInstanceId' -Tag 'Helper' {
    Context 'When getting the full instance ID from the default instance' {
        BeforeAll {
            Mock -CommandName Get-RegistryPropertyValue -MockWith {
                return 'MSSQL14.MSSQLSERVER'
            }
        }

        It 'Should return the correct full instance id' {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-FullInstanceId -InstanceName 'MSSQLSERVER'

                $result | Should -Be 'MSSQL14.MSSQLSERVER'
            }

            Should -Invoke -CommandName Get-RegistryPropertyValue -ParameterFilter {
                $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL' `
                    -and $Name -eq 'MSSQLSERVER'
            } -Exactly -Times 1 -Scope It
        }
    }

    Context 'When getting the full instance ID for a named instance' {
        BeforeAll {
            Mock -CommandName Get-RegistryPropertyValue -MockWith {
                return 'MSSQL14.NAMED'
            }
        }

        It 'Should return the correct full instance id' {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-FullInstanceId -InstanceName 'NAMED'

                $result | Should -Be 'MSSQL14.NAMED'
            }

            Should -Invoke -CommandName Get-RegistryPropertyValue -ParameterFilter {
                $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL' `
                    -and $Name -eq 'NAMED'
            } -Exactly -Times 1 -Scope It
        }
    }
}

Describe 'Get-SqlEngineProperties' -Tag 'Helper' {
    Context 'When getting properties for a default instance' {
        BeforeAll {
            Mock -CommandName Get-ServiceProperties -ParameterFilter {
                $ServiceName -eq 'MSSQLSERVER'
            } -MockWith {
                return @{
                    UserName    = 'COMPANY\SqlAccount'
                    StartupType = 'Automatic'
                }
            }

            Mock -CommandName Get-ServiceProperties -ParameterFilter {
                $ServiceName -eq 'SQLSERVERAGENT'
            } -MockWith {
                return @{
                    UserName    = 'COMPANY\AgentAccount'
                    StartupType = 'Automatic'
                }
            }

            $mockConnectSQL = {
                return New-Object -TypeName 'Object' |
                    Add-Member -MemberType 'NoteProperty' -Name 'Collation' -Value 'Finnish_Swedish_CI_AS' -PassThru |
                    Add-Member -MemberType 'NoteProperty' -Name 'IsClustered' -Value $true -PassThru |
                    Add-Member -MemberType 'NoteProperty' -Name 'InstallDataDirectory' -Value 'E:\MSSQL\Data' -PassThru |
                    Add-Member -MemberType 'NoteProperty' -Name 'DefaultFile' -Value 'K:\MSSQL\Data' -PassThru |
                    Add-Member -MemberType 'NoteProperty' -Name 'DefaultLog' -Value 'L:\MSSQL\Logs' -PassThru |
                    Add-Member -MemberType 'NoteProperty' -Name 'BackupDirectory' -Value 'O:\MSSQL\Backup' -PassThru |
                    # This value is set dynamically in BeforeEach-blocks.
                    Add-Member -MemberType 'NoteProperty' -Name 'LoginMode' -Value $mockDynamicSqlLoginMode -PassThru -Force
            }

            Mock -CommandName Connect-SQL -MockWith $mockConnectSQL
        }

        It 'Should return the correct property values' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-SqlEngineProperties -ServerName 'localhost' -InstanceName 'MSSQLSERVER'

                $result.SQLSvcAccountUsername | Should -Be 'COMPANY\SqlAccount'
                $result.AgtSvcAccountUsername | Should -Be 'COMPANY\AgentAccount'
                $result.SqlSvcStartupType | Should -Be 'Automatic'
                $result.AgtSvcStartupType | Should -Be 'Automatic'
                $result.SQLCollation | Should -Be 'Finnish_Swedish_CI_AS'
                $result.IsClustered | Should -BeTrue
                $result.InstallSQLDataDir | Should -Be 'E:\MSSQL\Data'
                $result.SQLUserDBDir | Should -Be 'K:\MSSQL\Data'
                $result.SQLUserDBLogDir | Should -Be 'L:\MSSQL\Logs'
                $result.SQLBackupDir | Should -Be 'O:\MSSQL\Backup'
                $result.SecurityMode | Should -Be 'Windows'
            }
        }

        Context 'When the Login mode is set to Integrated mode' {
            BeforeEach {
                $mockDynamicSqlLoginMode = 'Integrated'
            }

            It 'Should return the correct property value' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Get-SqlEngineProperties -ServerName 'localhost' -InstanceName 'MSSQLSERVER'

                    $result.SecurityMode | Should -BeExactly 'Windows'
                }
            }
        }

        Context 'When the Login mode is set to Mixed mode' {
            BeforeEach {
                $mockDynamicSqlLoginMode = 'Mixed'
            }

            It 'Should return the correct property value' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Get-SqlEngineProperties -ServerName 'localhost' -InstanceName 'MSSQLSERVER'

                    $result.SecurityMode | Should -BeExactly 'SQL'
                }
            }
        }
    }

    Context 'When getting properties for a named instance' {
        BeforeAll {
            Mock -CommandName Get-ServiceProperties -ParameterFilter {
                $ServiceName -eq 'MSSQL$TEST'
            } -MockWith {
                return @{
                    UserName    = 'COMPANY\SqlAccount'
                    StartupType = 'Automatic'
                }
            }

            Mock -CommandName Get-ServiceProperties -ParameterFilter {
                $ServiceName -eq 'SQLAgent$TEST'
            } -MockWith {
                return @{
                    UserName    = 'COMPANY\AgentAccount'
                    StartupType = 'Automatic'
                }
            }

            <#
                Just mock without testing any actual values. We already did that
                in the previous test.
            #>
            Mock -CommandName Connect-SQL
        }

        It 'Should return the correct property values' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-SqlEngineProperties -ServerName 'localhost' -InstanceName 'TEST'

                $result.SQLSvcAccountUsername | Should -Be 'COMPANY\SqlAccount'
                $result.AgtSvcAccountUsername | Should -Be 'COMPANY\AgentAccount'
                $result.SqlSvcStartupType | Should -Be 'Automatic'
                $result.AgtSvcStartupType | Should -Be 'Automatic'
            }
        }
    }
}

Describe 'Test-IsReplicationFeatureInstalled' -Tag 'Helper' {
    Context 'When replication feature is installed' {
        BeforeAll {
            Mock -CommandName Get-RegistryPropertyValue -MockWith {
                return 1
            }
        }

        It 'Should return $true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-IsReplicationFeatureInstalled -InstanceName 'MSSQLSERVER' |
                    Should -BeTrue
            }
        }
    }

    Context 'When replication feature is installed' {
        BeforeAll {
            Mock -CommandName Get-RegistryPropertyValue -MockWith {
                return $null
            }
        }

        It 'Should return $false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-IsReplicationFeatureInstalled -InstanceName 'MSSQLSERVER' |
                    Should -BeFalse
            }
        }
    }
}

Describe 'Test-IsDQComponentInstalled' -Tag 'Helper' {
    Context 'When Data Quality Services (DQ) feature is installed' {
        BeforeAll {
            $mockGetItemProperty = {
                return @(
                    (
                        New-Object -TypeName Object |
                            Add-Member -MemberType NoteProperty -Name 'DQ_Components' -Value 1 -PassThru -Force
                    )
                )
            }

            Mock -CommandName Get-ItemProperty -MockWith $mockGetItemProperty
        }

        It 'Should return $true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-IsDQComponentInstalled -InstanceName 'MSSQLSERVER' -SqlServerMajorVersion '14' |
                    Should -BeTrue
            }
        }
    }

    Context 'When replication feature is installed' {
        BeforeAll {
            Mock -CommandName Get-ItemProperty
        }

        It 'Should return $false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-IsDQComponentInstalled -InstanceName 'MSSQLSERVER' -SqlServerMajorVersion '14' |
                    Should -BeFalse
            }
        }
    }
}

Describe 'Get-InstanceProgramPath' -Tag 'Helper' {
    BeforeAll {
        Mock -CommandName Get-RegistryPropertyValue -MockWith {
            # Ending the path on purpose to make sure the function removes it.
            return 'C:\Program Files\Microsoft SQL Server\'
        }
    }

    It 'Should return the correct program path' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            Get-InstanceProgramPath -InstanceName 'MSSQLSERVER' | Should -Be 'C:\Program Files\Microsoft SQL Server'
        }
    }
}

Describe 'Get-ServiceNamesForInstance' -Tag 'Helper' {
    Context 'When the instance is the default instance' {
        It 'Should return the correct service names' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-ServiceNamesForInstance -InstanceName 'MSSQLSERVER' -SqlServerMajorVersion 14

                $result.DatabaseService | Should -Be 'MSSQLSERVER'
                $result.AgentService | Should -Be 'SQLSERVERAGENT'
                $result.FullTextService | Should -Be 'MSSQLFDLauncher'
                $result.ReportService | Should -Be 'ReportServer'
                $result.AnalysisService | Should -Be 'MSSQLServerOLAPService'
                $result.IntegrationService | Should -Be 'MsDtsServer140'
            }
        }
    }

    Context 'When the instance is a named instance' {
        It 'Should return the correct service names' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-ServiceNamesForInstance -InstanceName 'TEST'

                $result.DatabaseService | Should -Be 'MSSQL$TEST'
                $result.AgentService | Should -Be 'SQLAgent$TEST'
                $result.FullTextService | Should -Be 'MSSQLFDLauncher$TEST'
                $result.ReportService | Should -Be 'ReportServer$TEST'
                $result.AnalysisService | Should -Be 'MSOLAP$TEST'
            }
        }
    }

    Context 'When the SqlServerMajorVersion is not passed' {
        It 'Should return $null as the Integration Service service name' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-ServiceNamesForInstance -InstanceName 'MSSQLSERVER'

                $result.IntegrationService | Should -BeNullOrEmpty
            }
        }
    }
}

Describe 'Get-TempDbProperties' -Tag 'Helper' {
    BeforeAll {
        $mockConnectSQL = {
            return New-Object -TypeName 'Object' |
                Add-Member -MemberType 'ScriptProperty' -Name 'Databases' -Value {
                    return @{
                        tempdb = (
                            New-Object -TypeName 'Object' |
                                Add-Member -MemberType 'NoteProperty' -Name 'PrimaryFilePath' -Value 'H:\MSSQL\Temp' -PassThru |
                                Add-Member -MemberType 'ScriptProperty' -Name 'FileGroups' -Value {
                                    return @{
                                        PRIMARY = (
                                            New-Object -TypeName 'Object' |
                                                Add-Member -MemberType 'ScriptProperty' -Name 'Files' -Value {
                                                    <#
                                                            This will return the array that is set in each
                                                            BeforeEach-block prior to the It-block is run.
                                                        #>
                                                    return [PSCustomObject] $mockDynamicDataFiles
                                                } -PassThru -Force
                                            )
                                        }
                                    } -PassThru |
                                    Add-Member -MemberType 'ScriptProperty' -Name 'LogFiles' -Value {
                                        <#
                                            This will return the array that is set in each
                                            BeforeEach-block prior to the It-block is run.
                                        #>
                                        return [PSCustomObject] $mockDynamicLogFiles
                                    } -PassThru -Force
                                )
                            }
                        } -PassThru -Force
        }

        Mock -CommandName Connect-SQL -MockWith $mockConnectSQL
    }

    Context 'When there the PRIMARY filegroup contain one data file and one log file of growth type Percent' {
        BeforeEach {
            $mockDynamicDataFiles = @(
                New-Object -TypeName 'Object' |
                    Add-Member -MemberType 'NoteProperty' -Name 'Growth' -Value 10 -PassThru |
                    Add-Member -MemberType 'NoteProperty' -Name 'GrowthType' -Value 'Percent' -PassThru |
                    Add-Member -MemberType 'NoteProperty' -Name 'Size' -Value 8192 -PassThru -Force
            )

            $mockDynamicLogFiles = @(
                New-Object -TypeName 'Object' |
                    Add-Member -MemberType 'NoteProperty' -Name 'Growth' -Value 10 -PassThru |
                    Add-Member -MemberType 'NoteProperty' -Name 'GrowthType' -Value 'Percent' -PassThru |
                    Add-Member -MemberType 'NoteProperty' -Name 'Size' -Value 8192 -PassThru -Force
            )
        }

        It 'Should return the correct property values' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TempDbProperties -ServerName 'localhost' -InstanceName 'INSTANCE'

                $result.SQLTempDBDir | Should -Be 'H:\MSSQL\Temp'
                $result.SqlTempdbFileCount | Should -Be 1
                $result.SqlTempdbFileSize | Should -Be 8
                $result.SqlTempdbFileGrowth | Should -Be 10
                $result.SqlTempdbLogFileSize | Should -Be 8
                $result.SqlTempdbLogFileGrowth | Should -Be 10
            }
        }
    }

    Context 'When there the PRIMARY filegroup contain one data file and one log file of growth type KB' {
        BeforeEach {
            $mockDynamicDataFiles = @(
                New-Object -TypeName 'Object' |
                    Add-Member -MemberType 'NoteProperty' -Name 'Growth' -Value 102400 -PassThru |
                    Add-Member -MemberType 'NoteProperty' -Name 'GrowthType' -Value 'KB' -PassThru |
                    Add-Member -MemberType 'NoteProperty' -Name 'Size' -Value 8192 -PassThru -Force
            )

            $mockDynamicLogFiles = @(
                New-Object -TypeName 'Object' |
                    Add-Member -MemberType 'NoteProperty' -Name 'Growth' -Value 102400 -PassThru |
                    Add-Member -MemberType 'NoteProperty' -Name 'GrowthType' -Value 'KB' -PassThru |
                    Add-Member -MemberType 'NoteProperty' -Name 'Size' -Value 768 -PassThru -Force
            )
        }

        It 'Should return the correct property values' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TempDbProperties -ServerName 'localhost' -InstanceName 'INSTANCE'

                $result.SQLTempDBDir | Should -Be 'H:\MSSQL\Temp'
                $result.SqlTempdbFileCount | Should -Be 1
                $result.SqlTempdbFileSize | Should -Be 8
                $result.SqlTempdbFileGrowth | Should -Be 100
                $result.SqlTempdbLogFileSize | Should -Be 0.75
                $result.SqlTempdbLogFileGrowth | Should -Be 100
            }
        }
    }

    Context 'When there the PRIMARY filegroup contain two data files with the same file and growth size and type Percent' {
        BeforeEach {
            $mockDynamicDataFiles = @(
                New-Object -TypeName 'Object' |
                    Add-Member -MemberType 'NoteProperty' -Name 'Growth' -Value 10 -PassThru |
                    Add-Member -MemberType 'NoteProperty' -Name 'GrowthType' -Value 'Percent' -PassThru |
                    Add-Member -MemberType 'NoteProperty' -Name 'Size' -Value 8192 -PassThru -Force

                New-Object -TypeName 'Object' |
                    Add-Member -MemberType 'NoteProperty' -Name 'Growth' -Value 10 -PassThru |
                    Add-Member -MemberType 'NoteProperty' -Name 'GrowthType' -Value 'Percent' -PassThru |
                    Add-Member -MemberType 'NoteProperty' -Name 'Size' -Value 8192 -PassThru -Force
            )

            $mockDynamicLogFiles = @(
                New-Object -TypeName 'Object' |
                    Add-Member -MemberType 'NoteProperty' -Name 'Growth' -Value 10 -PassThru |
                    Add-Member -MemberType 'NoteProperty' -Name 'GrowthType' -Value 'Percent' -PassThru |
                    Add-Member -MemberType 'NoteProperty' -Name 'Size' -Value 768 -PassThru -Force

                New-Object -TypeName 'Object' |
                    Add-Member -MemberType 'NoteProperty' -Name 'Growth' -Value 10 -PassThru |
                    Add-Member -MemberType 'NoteProperty' -Name 'GrowthType' -Value 'Percent' -PassThru |
                    Add-Member -MemberType 'NoteProperty' -Name 'Size' -Value 768 -PassThru -Force
            )
        }

        It 'Should return the correct property values' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TempDbProperties -ServerName 'localhost' -InstanceName 'INSTANCE'

                $result.SQLTempDBDir | Should -Be 'H:\MSSQL\Temp'
                $result.SqlTempdbFileCount | Should -Be 2
                $result.SqlTempdbFileSize | Should -Be 8
                $result.SqlTempdbFileGrowth | Should -Be 10
                $result.SqlTempdbLogFileSize | Should -Be 0.75
                $result.SqlTempdbLogFileGrowth | Should -Be 10
            }
        }
    }

    Context 'When there the PRIMARY filegroup contain two data files with the same file and growth size and type KB' {
        BeforeEach {
            $mockDynamicDataFiles = @(
                New-Object -TypeName 'Object' |
                    Add-Member -MemberType 'NoteProperty' -Name 'Growth' -Value 102400 -PassThru |
                    Add-Member -MemberType 'NoteProperty' -Name 'GrowthType' -Value 'KB' -PassThru |
                    Add-Member -MemberType 'NoteProperty' -Name 'Size' -Value 8192 -PassThru -Force

                New-Object -TypeName 'Object' |
                    Add-Member -MemberType 'NoteProperty' -Name 'Growth' -Value 102400 -PassThru |
                    Add-Member -MemberType 'NoteProperty' -Name 'GrowthType' -Value 'KB' -PassThru |
                    Add-Member -MemberType 'NoteProperty' -Name 'Size' -Value 8192 -PassThru -Force
            )

            $mockDynamicLogFiles = @(
                New-Object -TypeName 'Object' |
                    Add-Member -MemberType 'NoteProperty' -Name 'Growth' -Value 102400 -PassThru |
                    Add-Member -MemberType 'NoteProperty' -Name 'GrowthType' -Value 'KB' -PassThru |
                    Add-Member -MemberType 'NoteProperty' -Name 'Size' -Value 768 -PassThru -Force

                New-Object -TypeName 'Object' |
                    Add-Member -MemberType 'NoteProperty' -Name 'Growth' -Value 102400 -PassThru |
                    Add-Member -MemberType 'NoteProperty' -Name 'GrowthType' -Value 'KB' -PassThru |
                    Add-Member -MemberType 'NoteProperty' -Name 'Size' -Value 768 -PassThru -Force
            )
        }

        It 'Should return the correct property values' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TempDbProperties -ServerName 'localhost' -InstanceName 'INSTANCE'

                $result.SQLTempDBDir | Should -Be 'H:\MSSQL\Temp'
                $result.SqlTempdbFileCount | Should -Be 2
                $result.SqlTempdbFileSize | Should -Be 8
                $result.SqlTempdbFileGrowth | Should -Be 100
                $result.SqlTempdbLogFileSize | Should -Be 0.75
                $result.SqlTempdbLogFileGrowth | Should -Be 100
            }
        }
    }

    Context 'When there the PRIMARY filegroup contain two data files with different file and growth sizes with growth type Percent' {
        BeforeEach {
            $mockDynamicDataFiles = @(
                New-Object -TypeName 'Object' |
                    Add-Member -MemberType 'NoteProperty' -Name 'Growth' -Value 10 -PassThru |
                    Add-Member -MemberType 'NoteProperty' -Name 'GrowthType' -Value 'Percent' -PassThru |
                    Add-Member -MemberType 'NoteProperty' -Name 'Size' -Value 32768 -PassThru -Force

                New-Object -TypeName 'Object' |
                    Add-Member -MemberType 'NoteProperty' -Name 'Growth' -Value 25 -PassThru |
                    Add-Member -MemberType 'NoteProperty' -Name 'GrowthType' -Value 'Percent' -PassThru |
                    Add-Member -MemberType 'NoteProperty' -Name 'Size' -Value 8192 -PassThru -Force
            )

            $mockDynamicLogFiles = @(
                New-Object -TypeName 'Object' |
                    Add-Member -MemberType 'NoteProperty' -Name 'Growth' -Value 10 -PassThru |
                    Add-Member -MemberType 'NoteProperty' -Name 'GrowthType' -Value 'Percent' -PassThru |
                    Add-Member -MemberType 'NoteProperty' -Name 'Size' -Value 768 -PassThru -Force

                New-Object -TypeName 'Object' |
                    Add-Member -MemberType 'NoteProperty' -Name 'Growth' -Value 25 -PassThru |
                    Add-Member -MemberType 'NoteProperty' -Name 'GrowthType' -Value 'Percent' -PassThru |
                    Add-Member -MemberType 'NoteProperty' -Name 'Size' -Value 1024 -PassThru -Force
            )
        }

        It 'Should return the correct property values' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TempDbProperties -ServerName 'localhost' -InstanceName 'INSTANCE'

                $result.SQLTempDBDir | Should -Be 'H:\MSSQL\Temp'
                $result.SqlTempdbFileCount | Should -Be 2
                $result.SqlTempdbFileSize | Should -Be 20
                $result.SqlTempdbFileGrowth | Should -Be 17.5
                $result.SqlTempdbLogFileSize | Should -Be 0.875
                $result.SqlTempdbLogFileGrowth | Should -Be 17.5
            }
        }
    }

    Context 'When there the PRIMARY filegroup contain two data files with different file and growth sizes with growth type KB' {
        BeforeEach {
            $mockDynamicDataFiles = @(
                New-Object -TypeName 'Object' |
                    Add-Member -MemberType 'NoteProperty' -Name 'Growth' -Value 1024 -PassThru |
                    Add-Member -MemberType 'NoteProperty' -Name 'GrowthType' -Value 'KB' -PassThru |
                    Add-Member -MemberType 'NoteProperty' -Name 'Size' -Value 32768 -PassThru -Force

                New-Object -TypeName 'Object' |
                    Add-Member -MemberType 'NoteProperty' -Name 'Growth' -Value 2048 -PassThru |
                    Add-Member -MemberType 'NoteProperty' -Name 'GrowthType' -Value 'KB' -PassThru |
                    Add-Member -MemberType 'NoteProperty' -Name 'Size' -Value 8192 -PassThru -Force
            )

            $mockDynamicLogFiles = @(
                New-Object -TypeName 'Object' |
                    Add-Member -MemberType 'NoteProperty' -Name 'Growth' -Value 1024 -PassThru |
                    Add-Member -MemberType 'NoteProperty' -Name 'GrowthType' -Value 'KB' -PassThru |
                    Add-Member -MemberType 'NoteProperty' -Name 'Size' -Value 768 -PassThru -Force

                New-Object -TypeName 'Object' |
                    Add-Member -MemberType 'NoteProperty' -Name 'Growth' -Value 2048 -PassThru |
                    Add-Member -MemberType 'NoteProperty' -Name 'GrowthType' -Value 'KB' -PassThru |
                    Add-Member -MemberType 'NoteProperty' -Name 'Size' -Value 1024 -PassThru -Force
            )
        }

        It 'Should return the correct property values' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TempDbProperties -ServerName 'localhost' -InstanceName 'INSTANCE'

                $result.SQLTempDBDir | Should -Be 'H:\MSSQL\Temp'
                $result.SqlTempdbFileCount | Should -Be 2
                $result.SqlTempdbFileSize | Should -Be 20
                $result.SqlTempdbFileGrowth | Should -Be 1.5
                $result.SqlTempdbLogFileSize | Should -Be 0.875
                $result.SqlTempdbLogFileGrowth | Should -Be 1.5
            }
        }
    }

    Context 'When there the PRIMARY filegroup contain two data files with different growth types' {
        BeforeEach {
            $mockDynamicDataFiles = @(
                New-Object -TypeName 'Object' |
                    Add-Member -MemberType 'NoteProperty' -Name 'Growth' -Value 10 -PassThru |
                    Add-Member -MemberType 'NoteProperty' -Name 'GrowthType' -Value 'Percent' -PassThru |
                    Add-Member -MemberType 'NoteProperty' -Name 'Size' -Value 32768 -PassThru -Force

                New-Object -TypeName 'Object' |
                    Add-Member -MemberType 'NoteProperty' -Name 'Growth' -Value 102400 -PassThru |
                    Add-Member -MemberType 'NoteProperty' -Name 'GrowthType' -Value 'KB' -PassThru |
                    Add-Member -MemberType 'NoteProperty' -Name 'Size' -Value 8192 -PassThru -Force
            )

            $mockDynamicLogFiles = @(
                New-Object -TypeName 'Object' |
                    Add-Member -MemberType 'NoteProperty' -Name 'Growth' -Value 10 -PassThru |
                    Add-Member -MemberType 'NoteProperty' -Name 'GrowthType' -Value 'Percent' -PassThru |
                    Add-Member -MemberType 'NoteProperty' -Name 'Size' -Value 768 -PassThru -Force

                New-Object -TypeName 'Object' |
                    Add-Member -MemberType 'NoteProperty' -Name 'Growth' -Value 2048 -PassThru |
                    Add-Member -MemberType 'NoteProperty' -Name 'GrowthType' -Value 'KB' -PassThru |
                    Add-Member -MemberType 'NoteProperty' -Name 'Size' -Value 1024 -PassThru -Force
            )
        }

        It 'Should return the correct property values' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TempDbProperties -ServerName 'localhost' -InstanceName 'INSTANCE'

                $result.SQLTempDBDir | Should -Be 'H:\MSSQL\Temp'
                $result.SqlTempdbFileCount | Should -Be 2
                $result.SqlTempdbFileSize | Should -Be 20
                $result.SqlTempdbFileGrowth | Should -Be 110
                $result.SqlTempdbLogFileSize | Should -Be 0.875
                $result.SqlTempdbLogFileGrowth | Should -Be 12
            }
        }
    }
}

Describe 'Get-SqlRoleMembers' -Tag 'Helper' {
    BeforeAll {
        $mockConnectSQL = {
            return New-Object -TypeName 'Object' |
                Add-Member -MemberType 'ScriptProperty' -Name 'Roles' -Value {
                    return @{
                        sysadmin = (
                            New-Object -TypeName 'Object' |
                                Add-Member -MemberType 'ScriptMethod' -Name 'EnumMemberNames' -Value {
                                    return $mockDynamicMembers
                                } -PassThru -Force
                            )
                        }
                    } -PassThru -Force
        }

        Mock -CommandName Connect-SQL -MockWith $mockConnectSQL
    }

    Context 'When the there is only one member in the sysadmin role' {
        BeforeEach {
            $mockDynamicMembers = @(
                'sa'
            )
        }

        It 'Should return the correct type and have the correct member' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $getTempDbPropertiesParameters = @{
                    ServerName   = 'localhost'
                    InstanceName = 'INSTANCE'
                    RoleName     = 'sysadmin'
                }

                $result = Get-SqlRoleMembers @getTempDbPropertiesParameters

                $result -is [System.Object[]] | Should -BeTrue
                $result | Should -HaveCount 1
                $result[0] | Should -Be 'sa'
            }
        }
    }

    Context 'When the there is only one member in the sysadmin role' {
        BeforeEach {
            $mockDynamicMembers = @(
                'sa'
                'COMPUTER\SqlInstall'
            )
        }

        It 'Should return the correct type and have the correct member' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $getTempDbPropertiesParameters = @{
                    ServerName   = 'localhost'
                    InstanceName = 'INSTANCE'
                    RoleName     = 'sysadmin'
                }

                $result = Get-SqlRoleMembers @getTempDbPropertiesParameters

                $result -is [System.Object[]] | Should -BeTrue
                $result | Should -HaveCount 2
                $result[0] | Should -Be 'sa'
                $result[1] | Should -Be 'COMPUTER\SqlInstall'
            }
        }
    }
}

Describe 'Get-SqlClusterProperties' -Tag 'Helper' {
    BeforeAll {
        $mockGetCimInstance_MSClusterResource = {
            return @(
                (
                    New-Object -TypeName 'Microsoft.Management.Infrastructure.CimInstance' -ArgumentList @('MSCluster_Resource', 'root/MSCluster') |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value 'SQL Server (TEST)' -PassThru -Force |
                        Add-Member -MemberType NoteProperty -Name 'Type' -Value 'SQL Server' -TypeName 'String' -PassThru -Force |
                        Add-Member -MemberType NoteProperty -Name 'PrivateProperties' -Value @{
                            InstanceName = 'TEST'
                        } -PassThru -Force
                )
            )
        }

        Mock -CommandName Get-CimInstance -MockWith $mockGetCimInstance_MSClusterResource

        $mockGetCimAssociatedInstance_MSClusterResourceGroup = {
            return @(
                (
                    New-Object -TypeName 'Microsoft.Management.Infrastructure.CimInstance' -ArgumentList @('MSCluster_ResourceGroup', 'root/MSCluster') |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value 'TESTCLU01A' -PassThru -Force
                )
            )
        }

        Mock -CommandName Get-CimAssociatedInstance -ParameterFilter {
            $ResultClassName -eq 'MSCluster_ResourceGroup'
        } -MockWith $mockGetCimAssociatedInstance_MSClusterResourceGroup

        $mockGetCimAssociatedInstance_MSClusterResource = {
            return @(
                New-Object -TypeName 'Microsoft.Management.Infrastructure.CimInstance' -ArgumentList @('MSCluster_Resource', 'root/MSCluster') |
                    Add-Member -MemberType 'NoteProperty' -Name 'Type' -Value 'Network Name' -PassThru |
                    Add-Member -MemberType 'NoteProperty' -Name 'PrivateProperties' -Value @{
                        DnsName = 'TESTCLU01A'
                    } -PassThru -Force

                New-Object -TypeName 'Microsoft.Management.Infrastructure.CimInstance' -ArgumentList @('MSCluster_Resource', 'root/MSCluster') |
                    Add-Member -MemberType 'NoteProperty' -Name 'Type' -Value 'IP Address' -PassThru |
                    Add-Member -MemberType 'NoteProperty' -Name 'PrivateProperties' -Value @{
                        Address = '10.0.0.10'
                    } -PassThru -Force
            )
        }

        Mock -CommandName Get-CimAssociatedInstance -ParameterFilter {
            $ResultClassName -eq 'MSCluster_Resource'
        } -MockWith $mockGetCimAssociatedInstance_MSClusterResource
    }

    It 'Should return the correct cluster values' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $result = Get-SqlClusterProperties -InstanceName 'TEST'

            $result.FailoverClusterNetworkName | Should -Be 'TESTCLU01A'
            $result.FailoverClusterGroupName | Should -Be 'TESTCLU01A'
            $result.FailoverClusterIPAddress | Should -Be '10.0.0.10'
        }
    }

    It 'Should throw the correct error when cluster group for SQL instance cannot be found' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $mockErrorMessage = $script:localizedData.FailoverClusterResourceNotFound -f 'MSSQLSERVER'

            { Get-SqlClusterProperties -InstanceName 'MSSQLSERVER' } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage)
        }
    }
}

Describe 'Get-ServiceProperties' -Tag 'Helper' {
    BeforeAll {
        $mockGetCimInstance = {
            return @(
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value 'MSSQL$SQL2014' -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StartName' -Value 'COMPANY\SqlAccount' -PassThru -Force |
                        Add-Member -MemberType NoteProperty -Name 'StartMode' -Value 'Auto' -PassThru -Force
                )
            )
        }

        Mock -CommandName Get-CimInstance -MockWith $mockGetCimInstance
    }

    It 'Should return the correct property values' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $result = Get-ServiceProperties -ServiceName 'MSSQL$SQL2014'

            $result.UserName | Should -Be 'COMPANY\SqlAccount'
            $result.StartupType | Should -Be 'Automatic'
        }
    }
}

Describe 'Test-IsSsmsInstalled' -Tag 'Helper' {
    Context 'When called with an unsupported major version' {
        BeforeAll {
            Mock -CommandName Get-ItemProperty
        }

        It 'Should return $false' {
            Set-StrictMode -Version 1.0

            InModuleScope -ScriptBlock {
                Test-IsSsmsInstalled -SqlServerMajorVersion 99 | Should -BeFalse
            }

            Should -Invoke -CommandName Get-ItemProperty -Exactly -Times 0 -Scope It
        }
    }

    Context 'When SQL Server Management Studio is not installed' {
        BeforeAll {
            Mock -CommandName Get-ItemProperty
        }

        It 'Should return $false' {
            Set-StrictMode -Version 1.0

            InModuleScope -ScriptBlock {
                Test-IsSsmsInstalled -SqlServerMajorVersion 10 | Should -BeFalse
            }

            Should -Invoke -CommandName Get-ItemProperty -Exactly -Times 1 -Scope It
        }
    }

    Context 'When SQL Server Management Studio is installed' {
        BeforeAll {
            $mockSqlServerManagementStudio2008R2_ProductIdentifyingNumber = '{72AB7E6F-BC24-481E-8C45-1AB5B3DD795D}'
            $mockSqlServerManagementStudio2012_ProductIdentifyingNumber = '{A7037EB2-F953-4B12-B843-195F4D988DA1}'
            $mockSqlServerManagementStudio2014_ProductIdentifyingNumber = '{75A54138-3B98-4705-92E4-F619825B121F}'

            $mockRegistryUninstallProductsPath = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall'
        }

        Context 'When SQL Server major version is 10 (2008 or 2008 R2)' {
            BeforeAll {
                Mock -CommandName Get-ItemProperty -MockWith {
                    return @(
                        # Mock product SSMS 2008 and SSMS 2008 R2.
                        $mockSqlServerManagementStudio2008R2_ProductIdentifyingNumber
                    )
                }
            }

            It 'Should return $true' {
                Set-StrictMode -Version 1.0

                InModuleScope -ScriptBlock {
                    Test-IsSsmsInstalled -SqlServerMajorVersion 10 | Should -BeTrue
                }

                Should -Invoke -CommandName Get-ItemProperty -ParameterFilter {
                    $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2008R2_ProductIdentifyingNumber)
                } -Exactly -Times 1 -Scope It
            }
        }

        Context 'When SQL Server major version is 11 (2012)' {
            BeforeAll {
                Mock -CommandName Get-ItemProperty -MockWith {
                    return @(
                        # Mock product SSMS 2012.
                        $mockSqlServerManagementStudio2012_ProductIdentifyingNumber
                    )
                }
            }

            It 'Should return $true' {
                Set-StrictMode -Version 1.0

                InModuleScope -ScriptBlock {
                    Test-IsSsmsInstalled -SqlServerMajorVersion 11 | Should -BeTrue
                }

                Should -Invoke -CommandName Get-ItemProperty -ParameterFilter {
                    $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2012_ProductIdentifyingNumber)
                } -Exactly -Times 1 -Scope It
            }
        }

        Context 'When SQL Server major version is 12 (2014)' {
            BeforeAll {
                Mock -CommandName Get-ItemProperty -MockWith {
                    return @(
                        # Mock product SSMS 2014.
                        $mockSqlServerManagementStudio2014_ProductIdentifyingNumber
                    )
                }
            }

            It 'Should return $true' {
                Set-StrictMode -Version 1.0

                InModuleScope -ScriptBlock {
                    Test-IsSsmsInstalled -SqlServerMajorVersion 12 | Should -BeTrue
                }

                Should -Invoke -CommandName Get-ItemProperty -ParameterFilter {
                    $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudio2014_ProductIdentifyingNumber)
                } -Exactly -Times 1 -Scope It
            }
        }
    }
}

Describe 'Test-IsSsmsAdvancedInstalled' -Tag 'Helper' {
    Context 'When called with an unsupported major version' {
        BeforeAll {
            Mock -CommandName Get-ItemProperty
        }

        It 'Should return $false' {
            Set-StrictMode -Version 1.0

            InModuleScope -ScriptBlock {
                Test-IsSsmsAdvancedInstalled -SqlServerMajorVersion 99 | Should -BeFalse
            }

            Should -Invoke -CommandName Get-ItemProperty -Exactly -Times 0 -Scope It
        }
    }

    Context 'When SQL Server Management Studio Advanced is not installed' {
        BeforeAll {
            Mock -CommandName Get-ItemProperty
        }

        It 'Should return $false' {
            Set-StrictMode -Version 1.0

            InModuleScope -ScriptBlock {
                Test-IsSsmsAdvancedInstalled -SqlServerMajorVersion 10 | Should -BeFalse
            }

            Should -Invoke -CommandName Get-ItemProperty -Exactly -Times 1 -Scope It
        }
    }

    Context 'When SQL Server Management Studio Advanced is installed' {
        BeforeAll {
            $mockSqlServerManagementStudioAdvanced2008R2_ProductIdentifyingNumber = '{B5FE23CC-0151-4595-84C3-F1DE6F44FE9B}'
            $mockSqlServerManagementStudioAdvanced2012_ProductIdentifyingNumber = '{7842C220-6E9A-4D5A-AE70-0E138271F883}'
            $mockSqlServerManagementStudioAdvanced2014_ProductIdentifyingNumber = '{B5ECFA5C-AC4F-45A4-A12E-A76ABDD9CCBA}'

            $mockRegistryUninstallProductsPath = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall'
        }

        Context 'When SQL Server major version is 10 (2008 or 2008 R2)' {
            BeforeAll {
                Mock -CommandName Get-ItemProperty -MockWith {
                    return @(
                        # Mock product SSMS 2008 and SSMS 2008 R2.
                        $mockSqlServerManagementStudioAdvanced2008R2_ProductIdentifyingNumber
                    )
                }
            }

            It 'Should return $true' {
                Set-StrictMode -Version 1.0

                InModuleScope -ScriptBlock {
                    Test-IsSsmsAdvancedInstalled -SqlServerMajorVersion 10 | Should -BeTrue
                }

                Should -Invoke -CommandName Get-ItemProperty -ParameterFilter {
                    $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2008R2_ProductIdentifyingNumber)
                } -Exactly -Times 1 -Scope It
            }
        }

        Context 'When SQL Server major version is 11 (2012)' {
            BeforeAll {
                Mock -CommandName Get-ItemProperty -MockWith {
                    return @(
                        # Mock product SSMS 2012.
                        $mockSqlServerManagementStudioAdvanced2012_ProductIdentifyingNumber
                    )
                }
            }

            It 'Should return $true' {
                Set-StrictMode -Version 1.0

                InModuleScope -ScriptBlock {
                    Test-IsSsmsAdvancedInstalled -SqlServerMajorVersion 11 | Should -BeTrue
                }

                Should -Invoke -CommandName Get-ItemProperty -ParameterFilter {
                    $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2012_ProductIdentifyingNumber)
                } -Exactly -Times 1 -Scope It
            }
        }

        Context 'When SQL Server major version is 12 (2014)' {
            BeforeAll {
                Mock -CommandName Get-ItemProperty -MockWith {
                    return @(
                        # Mock product SSMS 2014.
                        $mockSqlServerManagementStudioAdvanced2014_ProductIdentifyingNumber
                    )
                }
            }

            It 'Should return $true' {
                Set-StrictMode -Version 1.0

                InModuleScope -ScriptBlock {
                    Test-IsSsmsAdvancedInstalled -SqlServerMajorVersion 12 | Should -BeTrue
                }

                Should -Invoke -CommandName Get-ItemProperty -ParameterFilter {
                    $Path -eq (Join-Path -Path $mockRegistryUninstallProductsPath -ChildPath $mockSqlServerManagementStudioAdvanced2014_ProductIdentifyingNumber)
                } -Exactly -Times 1 -Scope It
            }
        }
    }
}

Describe 'Get-SqlSharedPaths' -Tag 'Helper' {
    BeforeAll {
        $mockRegistryKeySharedDir = 'FEE2E540D20152D4597229B6CFBC0A69'
        $mockRegistryKeySharedWOWDir = 'A79497A344129F64CA7D69C56F5DD8B4'

        Mock -CommandName Get-FirstPathValueFromRegistryPath -ParameterFilter {
            $Path -match $mockRegistryKeySharedDir
        } -MockWith {
            return 'C:\Program Files\Microsoft SQL Server'
        }

        Mock -CommandName Get-FirstPathValueFromRegistryPath -ParameterFilter {
            $Path -match $mockRegistryKeySharedWOWDir
        } -MockWith {
            return 'C:\Program Files (x86)\Microsoft SQL Server'
        }
    }

    It 'Should return the correct property values for SQL Server major version <MockSqlServerMajorVersion>' -ForEach @(
        @{
            MockSqlServerMajorVersion = 10
        }

        @{
            MockSqlServerMajorVersion = 11
        }

        @{
            MockSqlServerMajorVersion = 12
        }

        @{
            MockSqlServerMajorVersion = 13
        }

        @{
            MockSqlServerMajorVersion = 14
        }
    ) {
        InModuleScope -Parameters $_ -ScriptBlock {
            Set-StrictMode -Version 1.0

            $result = Get-SqlSharedPaths -SqlServerMajorVersion $MockSqlServerMajorVersion

            $result.InstallSharedDir | Should -Be 'C:\Program Files\Microsoft SQL Server'
            $result.InstallSharedWOWDir | Should -Be 'C:\Program Files (x86)\Microsoft SQL Server'
        }
    }
}

Describe 'Get-FirstPathValueFromRegistryPath' -Tag 'Helper' {
    BeforeAll {
        Mock -CommandName Get-Item -MockWith {
            return [PSCustomObject] @{
                Property = @(
                    'DCB13571726C2A64F9E1C79C020E9EA4'
                    '52A7B04BB8030564B8245E7101DC4D9D'
                    '17195C960C1F3104DB7F109DB81562E3'
                    'F07EA859E694B45439E22B819F70A40F'
                    '3F9A28055EEA9364B97A1C6916AB3713'
                )
            }
        }

        Mock -CommandName Get-ItemProperty -MockWith {
            return @{
                # Have on purpose a backslash at the end of the path to test the trim logic.
                'DCB13571726C2A64F9E1C79C020E9EA4' = 'C:\Program Files\Microsoft SQL Server\'
            }
        }
    }

    It 'Should return the correct registry property value' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            # This path cannot use 'HKLM:\', if it does it slows the test to a crawl.
            $mockRegistryPath = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\FEE2E540D20152D4597229B6CFBC0A69'

            $result = Get-FirstPathValueFromRegistryPath -Path $mockRegistryPath

            $result | Should -Be 'C:\Program Files\Microsoft SQL Server'
        }
    }
}

Describe 'ConvertTo-Decimal' -Tag 'Helper' {
    It 'Should return the correct decimal value' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $result = ConvertTo-Decimal '192.168.10.0'

            $result | Should -BeOfType [System.UInt32]
            $result | Should -Be 3232238080
        }
    }
}

Describe 'Test-IPAddress' -Tag 'Helper' {
    Context 'When specified IP address is a valid IPv4 address for the given network and subnet' {
        It 'Should return $true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Test-IPAddress -IPaddress '192.168.10.4' -NetworkID '192.168.10.0' -SubnetMask '255.255.255.0'

                $result | Should -BeTrue
            }
        }
    }

    Context 'When specified IP address is not valid IPv4 address for the given network and subnet' {
        It 'Should return $false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Test-IPAddress -IPaddress '192.168.10.240' -NetworkID '192.168.10.0' -SubnetMask '255.255.255.128'

                $result | Should -BeFalse
            }
        }
    }
}
