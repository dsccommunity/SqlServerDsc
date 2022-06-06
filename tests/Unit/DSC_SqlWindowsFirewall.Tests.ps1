<#
    .SYNOPSIS
        Automated unit test for DSC_SqlWindowsFirewall DSC resource.

#>
return

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

$script:dscModuleName      = 'SqlServerDsc'
$script:dscResourceName    = 'DSC_SqlWindowsFirewall'

function Invoke-TestSetup
{
    try
    {
        Import-Module -Name DscResource.Test -Force -ErrorAction 'Stop'
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
    }

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Invoke-TestSetup

try
{
    InModuleScope $script:dscResourceName {
        <#
            Testing two major versions to verify Integration Services differences (i.e service name).
            No point in testing each supported SQL Server version, since there are no difference
            between the other major versions.
        #>
        $testProductVersion = @(
            11, # SQL Server 2012
            10  # SQL Server 2008 and 2008 R2
        )

        $mockSqlDatabaseEngineName = 'MSSQL'
        $mockSqlAgentName = 'SQLAgent'
        $mockSqlFullTextName = 'MSSQLFDLauncher'
        $mockSqlReportingName = 'ReportServer'
        $mockSqlIntegrationName = 'MsDtsServer{0}0' # {0} will be replaced by SQL major version in runtime
        $mockSqlAnalysisName = 'MSOLAP'

        $mockSqlDatabaseEngineInstanceIdName = $mockSqlDatabaseEngineName
        $mockSqlAnalysisServicesInstanceIdName = 'MSAS'

        $mockSetupExecutableName = 'setup.exe'
        $mockDatabaseEngineExecutableName  = 'sqlservr.exe'
        $mockIntegrationServicesExecutableName = 'MsDtsSrvr.exe'

        $mockFirewallRulePort_ReportingServicesNoSslProtocol = 'tcp'
        $mockFirewallRulePort_ReportingServicesNoSslLocalPort = 80
        $mockFirewallRulePort_ReportingServicesSslProtocol = 'tcp'
        $mockFirewallRulePort_ReportingServicesSslLocalPort = 443
        $mockFirewallRulePort_IntegrationServicesProtocol = 'tcp'
        $mockFirewallRulePort_IntegrationServicesLocalPort = 135

        $mockDefaultInstance_InstanceName = 'MSSQLSERVER'

        $mockSQLBrowserServiceName = 'SQLBrowser'

        $mockDefaultInstance_InstanceName = 'MSSQLSERVER'
        $mockDefaultInstance_DatabaseServiceName = $mockDefaultInstance_InstanceName
        $mockDefaultInstance_AgentServiceName = 'SQLSERVERAGENT'
        $mockDefaultInstance_FullTextServiceName = $mockSqlFullTextName
        $mockDefaultInstance_ReportingServiceName = $mockSqlReportingName
        $mockDefaultInstance_IntegrationServiceName = $mockSqlIntegrationName
        $mockDefaultInstance_AnalysisServiceName = 'MSSQLServerOLAPService'

        $mockNamedInstance_InstanceName = 'TEST'
        $mockNamedInstance_DatabaseServiceName = "$($mockSqlDatabaseEngineName)`$$($mockNamedInstance_InstanceName)"
        $mockNamedInstance_AgentServiceName = "$($mockSqlAgentName)`$$($mockNamedInstance_InstanceName)"
        $mockNamedInstance_FullTextServiceName = "$($mockSqlFullTextName)`$$($mockNamedInstance_InstanceName)"
        $mockNamedInstance_ReportingServiceName = "$($mockSqlReportingName)`$$($mockNamedInstance_InstanceName)"
        $mockNamedInstance_IntegrationServiceName = $mockSqlIntegrationName
        $mockNamedInstance_AnalysisServiceName = "$($mockSqlAnalysisName)`$$($mockNamedInstance_InstanceName)"

        $mockSourceCredentialUserName = "COMPANY\sqladmin"
        $mockSourceCredentialPassword = "dummyPassw0rd" | ConvertTo-SecureString -asPlainText -Force
        $mockSourceCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @($mockSourceCredentialUserName, $mockSourceCredentialPassword)

        $mockFqdnSourceCredentialUserName = "sqladmin@company.local"
        $mockFqdnSourceCredentialPassword = "dummyPassw0rd" | ConvertTo-SecureString -asPlainText -Force
        $mockFqdnSourceCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @($mockFqdnSourceCredentialUserName, $mockFqdnSourceCredentialPassword)

        $mockDynamicSQLEngineFirewallRulePresent = $true
        $mockDynamicSQLBrowserFirewallRulePresent = $true
        $mockDynamicSQLIntegrationServicesRulePresent = $true
        $mockDynamicSQLAnalysisServicesFirewallRulePresent = $true

        #region Function mocks
        $mockEmptyHashtable = {
            return @()
        }

        $mockGetService_DefaultInstance = {
            return @(
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockDefaultInstance_DatabaseServiceName -PassThru -Force
                ),
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockDefaultInstance_AgentServiceName -PassThru -Force
                ),
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockDefaultInstance_FullTextServiceName -PassThru -Force
                ),
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockDefaultInstance_ReportingServiceName -PassThru -Force
                ),
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value ($mockDefaultInstance_IntegrationServiceName -f $mockCurrentSqlMajorVersion) -PassThru -Force
                ),
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockDefaultInstance_AnalysisServiceName -PassThru -Force
                )
            )
        }


        $mockGetService_NamedInstance = {
            return @(
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockNamedInstance_DatabaseServiceName -PassThru -Force
                ),
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockNamedInstance_AgentServiceName -PassThru -Force
                ),
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockNamedInstance_FullTextServiceName -PassThru -Force
                ),
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockNamedInstance_ReportingServiceName -PassThru -Force
                ),
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value ($mockNamedInstance_IntegrationServiceName -f $mockCurrentSqlMajorVersion) -PassThru -Force
                ),
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockNamedInstance_AnalysisServiceName -PassThru -Force
                )
            )
        }

        $mockGetItemProperty_CallingWithWrongParameters = {
            throw 'Mock Get-ItemProperty was called with wrong parameters'
        }

        $mockRegistryPathSqlInstanceId = 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL'
        $mockRegistryPathAnalysisServicesInstanceId = 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\OLAP'
        $mockGetItemProperty_SqlInstanceId = {
            return @(
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name $mockCurrentInstanceName -Value $mockCurrentDatabaseEngineInstanceId -PassThru -Force
                )
            )
        }

        $mockGetItemProperty_SqlInstanceId_ParameterFilter = {
            $Path -eq $mockRegistryPathSqlInstanceId -and
            $Name -eq $mockCurrentInstanceName
        }

        $mockGetItemProperty_AnalysisServicesInstanceId = {
            return @(
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name $mockCurrentInstanceName -Value $mockCurrentAnalysisServiceInstanceId -PassThru -Force
                )
            )
        }

        $mockGetItemProperty_AnalysisServicesInstanceId_ParameterFilter = {
            $Path -eq $mockRegistryPathAnalysisServicesInstanceId -and
            $Name -eq $mockCurrentInstanceName
        }

        $mockGetItemProperty_DatabaseEngineSqlBinRoot = {
            return @(
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'SQLBinRoot' -Value $mockCurrentDatabaseEngineSqlBinDirectory -PassThru -Force
                )
            )
        }

        $mockGetItemProperty_DatabaseEngineSqlBinRoot_ParameterFilter = {
            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockCurrentDatabaseEngineInstanceId\setup" -and
            $Name -eq 'SQLBinRoot'
        }

        $mockGetItemProperty_AnalysisServicesSqlBinRoot = {
            return @(
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'SQLBinRoot' -Value $mockCurrentAnalysisServicesSqlBinDirectory -PassThru -Force
                )
            )
        }

        $mockGetItemProperty_AnalysisServicesSqlBinRoot_ParameterFilter = {
            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockCurrentAnalysisServiceInstanceId\setup" -and
            $Name -eq 'SQLBinRoot'
        }

        $mockGetItemProperty_IntegrationsServicesSqlPath = {
            return @(
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'SQLPath' -Value $mockCurrentIntegrationServicesSqlPathDirectory -PassThru -Force
                )
            )
        }

        $mockGetItemProperty_IntegrationsServicesSqlPath_ParameterFilter = {
            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$($mockCurrentSqlMajorVersion)0\DTS\setup" -and
            $Name -eq 'SQLPath'
        }

        $mockGetNetFirewallRule = {
            return @(
                (
                    New-CimInstance -ClassName 'MSFT_NetFirewallRule' -Property @{
                        'DisplayName' = $DisplayName
                        'Enabled' = $true
                        'Profile' = 'Any'
                        'Direction' = 1 # 1 = Inbound, 2 = Outbound
                    } -Namespace 'root/standardcimv2' -ClientOnly
                )
            )
        }

        $mockGetNetFirewallRule_EmptyDisplayName_ParameterFilter = {
            $null -eq $DisplayName
        }

        $mockGetNetFirewallRule_EmptyDisplayName = {
            return @(
                (
                    New-CimInstance -ClassName 'MSFT_NetFirewallRule' -Property @{
                        'DisplayName' = "SQL Server Database Engine instance $mockCurrentInstanceName"
                        'Enabled' = $true
                        'Profile' = 'Any'
                        'Direction' = 1 # 1 = Inbound, 2 = Outbound
                    } -Namespace 'root/standardcimv2' -ClientOnly
                )
            )
        }

        $mockGetNetFirewallApplicationFilter = {
            if ($mockDynamicSQLEngineFirewallRulePresent -and $AssociatedNetFirewallRule.DisplayName -eq "SQL Server Database Engine instance $mockCurrentInstanceName")
            {
                return @(
                    (
                        New-Object -TypeName Object |
                            Add-Member -MemberType NoteProperty -Name 'Program' -Value (Join-Path $mockCurrentDatabaseEngineSqlBinDirectory -ChildPath $mockDatabaseEngineExecutableName) -PassThru -Force
                    )
                )
            }
            elseif ($mockDynamicSQLIntegrationServicesRulePresent -and $AssociatedNetFirewallRule.DisplayName -eq 'SQL Server Integration Services Application')
            {
                return @(
                    (
                        New-Object -TypeName Object |
                            Add-Member -MemberType NoteProperty -Name 'Program' -Value (Join-Path -Path (Join-Path $mockCurrentIntegrationServicesSqlPathDirectory -ChildPath 'Binn') -ChildPath $mockIntegrationServicesExecutableName) -PassThru -Force
                    )
                )
            }
            # Only throw if the rules should be present.
            elseif ($mockDynamicSQLEngineFirewallRulePresent -and $mockDynamicSQLIntegrationServicesRulePresent)
            {
                throw "Mock Get-NetFirewallApplicationFilter was called with a rule containing an unknown display name; $($AssociatedNetFirewallRule.DisplayName)"
            }
        }

        $mockGetNetFirewallServiceFilter = {
            if ($mockDynamicSQLAnalysisServicesFirewallRulePresent -and $AssociatedNetFirewallRule.DisplayName -eq "SQL Server Analysis Services instance $mockCurrentInstanceName")
            {
                return @(
                    (
                        New-Object -TypeName Object |
                            Add-Member -MemberType NoteProperty -Name 'Service' -Value $mockCurrentSqlAnalysisServiceName -PassThru -Force
                    )
                )
            }
            elseif ($mockDynamicSQLBrowserFirewallRulePresent -and $AssociatedNetFirewallRule.DisplayName -eq 'SQL Server Browser')
            {
                return @(
                    (
                        New-Object -TypeName Object |
                            Add-Member -MemberType NoteProperty -Name 'Service' -Value $mockSQLBrowserServiceName -PassThru -Force
                    )
                )
            }
            elseif ($mockDynamicSQLBrowserFirewallRulePresent -and $mockDynamicSQLAnalysisServicesFirewallRulePresent)
            {
                throw "Mock Get-NetFirewallServiceFilter was called with a rule containing an unknown display name; $($AssociatedNetFirewallRule.DisplayName)"
            }
        }

        $mockGetNetFirewallPortFilter = {
            if ($AssociatedNetFirewallRule.DisplayName -eq 'SQL Server Reporting Services 80')
            {
                return @(
                    (
                        New-Object -TypeName Object |
                            Add-Member -MemberType NoteProperty -Name 'Protocol' -Value $mockFirewallRulePort_ReportingServicesNoSslProtocol -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'LocalPort' -Value $mockFirewallRulePort_ReportingServicesNoSslLocalPort -PassThru -Force
                    )
                )
            }
            elseif ($AssociatedNetFirewallRule.DisplayName -eq 'SQL Server Reporting Services 443')
            {
                return @(
                    (
                        New-Object -TypeName Object |
                            Add-Member -MemberType NoteProperty -Name 'Protocol' -Value $mockFirewallRulePort_ReportingServicesSslProtocol -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'LocalPort' -Value $mockFirewallRulePort_ReportingServicesSslLocalPort -PassThru -Force
                    )
                )
            }
            elseif ($AssociatedNetFirewallRule.DisplayName -eq 'SQL Server Integration Services Port')
            {
                return @(
                    (
                        New-Object -TypeName Object |
                            Add-Member -MemberType NoteProperty -Name 'Protocol' -Value $mockFirewallRulePort_IntegrationServicesProtocol -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'LocalPort' -Value $mockFirewallRulePort_IntegrationServicesLocalPort -PassThru -Force
                    )
                )
            }
            else
            {
                throw "Mock Get-NetFirewallPortFilter was called with a rule containing an unknown display name; $($AssociatedNetFirewallRule.DisplayName)"
            }
        }

        $mockNewNetFirewallRule = {
            if (
                (
                    $DisplayName -eq "SQL Server Database Engine instance $mockCurrentInstanceName" -and
                    $Program -eq (Join-Path $mockCurrentDatabaseEngineSqlBinDirectory -ChildPath $mockDatabaseEngineExecutableName)
                ) -or
                (
                    $DisplayName -eq 'SQL Server Browser' -and
                    $Service -eq $mockSQLBrowserServiceName
                ) -or
                (
                    $DisplayName -eq "SQL Server Analysis Services instance $mockCurrentInstanceName" -and
                    $Service -eq $mockCurrentSqlAnalysisServiceName
                ) -or
                (
                    $DisplayName -eq "SQL Server Reporting Services 80" -and
                    $Protocol -eq $mockFirewallRulePort_ReportingServicesNoSslProtocol -and
                    $LocalPort -eq $mockFirewallRulePort_ReportingServicesNoSslLocalPort
                ) -or
                (
                    $DisplayName -eq "SQL Server Reporting Services 443" -and
                    $Protocol -eq $mockFirewallRulePort_ReportingServicesSslProtocol -and
                    $LocalPort -eq $mockFirewallRulePort_ReportingServicesSslLocalPort
                ) -or
                (
                    $DisplayName -eq "SQL Server Integration Services Application" -and
                    $Program -eq (Join-Path -Path (Join-Path $mockCurrentIntegrationServicesSqlPathDirectory -ChildPath 'Binn') -ChildPath $mockIntegrationServicesExecutableName)
                ) -or
                (
                    $DisplayName -eq "SQL Server Integration Services Port" -and
                    $Protocol -eq $mockFirewallRulePort_IntegrationServicesProtocol -and
                    $LocalPort -eq $mockFirewallRulePort_IntegrationServicesLocalPort
                )
            )
            {
                return
            }

            throw "`nMock Get-NewFirewallRule was called with an unexpected rule configuration`n" + `
                    "Display Name: $DisplayName`n" + `
                    "Application: $Program`n" + `
                    "Service: $Service`n" + `
                    "Protocol: $Protocol`n" + `
                    "Local port: $LocalPort`n"
        }
        $mockSetNetFirewallRule = $mockNewNetFirewallRule

        $mockGetSqlMajorVersion = {
            return $mockCurrentSqlMajorVersion
        }
        #endregion Function mocks

        # Default parameters that are used for the It-blocks
        $mockDefaultParameters = @{
            # These are written with both lower-case and upper-case to make sure we support that.
            Features = 'SQLEngine,Rs,As,Is'
            SourceCredential = $mockSourceCredential
        }

        Describe "SqlWindowsFirewall\Get-TargetResource" -Tag 'Get' {
            # Local path to TestDrive:\
            $mockSourcePath = $TestDrive.FullName

            BeforeEach {
                # General mocks
                Mock -CommandName Get-FilePathMajorVersion -MockWith $mockGetSqlMajorVersion -Verifiable

                # Mock SQL Server Database Engine registry for Instance ID.
                Mock -CommandName Get-ItemProperty `
                    -ParameterFilter $mockGetItemProperty_SqlInstanceId_ParameterFilter `
                    -MockWith $mockGetItemProperty_SqlInstanceId -Verifiable

                # Mock SQL Server Analysis Services registry for Instance ID.
                Mock -CommandName Get-ItemProperty `
                    -ParameterFilter $mockGetItemProperty_AnalysisServicesInstanceId_ParameterFilter `
                    -MockWith $mockGetItemProperty_AnalysisServicesInstanceId -Verifiable

                # Mocking SQL Server Database Engine registry for path to binaries root.
                Mock -CommandName Get-ItemProperty `
                    -ParameterFilter $mockGetItemProperty_DatabaseEngineSqlBinRoot_ParameterFilter `
                    -MockWith $mockGetItemProperty_DatabaseEngineSqlBinRoot -Verifiable

                # Mocking SQL Server Database Engine registry for path to binaries root.
                Mock -CommandName Get-ItemProperty `
                    -ParameterFilter $mockGetItemProperty_AnalysisServicesSqlBinRoot_ParameterFilter `
                    -MockWith $mockGetItemProperty_AnalysisServicesSqlBinRoot -Verifiable

                # Mock SQL Server Integration Services Registry for path to binaries root.
                Mock -CommandName Get-ItemProperty `
                    -ParameterFilter $mockGetItemProperty_IntegrationsServicesSqlPath_ParameterFilter `
                    -MockWith $mockGetItemProperty_IntegrationsServicesSqlPath -Verifiable

                Mock -CommandName Get-ItemProperty -MockWith $mockGetItemProperty_CallingWithWrongParameters -Verifiable
                Mock -CommandName New-SmbMapping -Verifiable
                Mock -CommandName Remove-SmbMapping -Verifiable
            }

            $testProductVersion | ForEach-Object -Process {
                $mockCurrentSqlMajorVersion = $_

                $mockCurrentPathToSetupExecutable = Join-Path -Path $mockSourcePath -ChildPath $mockSetupExecutableName

                $mockCurrentInstanceName = $mockDefaultInstance_InstanceName
                $mockCurrentDatabaseEngineInstanceId = "$($mockSqlDatabaseEngineInstanceIdName)$($mockCurrentSqlMajorVersion).$($mockCurrentInstanceName)"
                $mockCurrentAnalysisServiceInstanceId = "$($mockSqlAnalysisServicesInstanceIdName)$($mockCurrentSqlMajorVersion).$($mockCurrentInstanceName)"

                $mockCurrentSqlAnalysisServiceName = $mockDefaultInstance_AnalysisServiceName

                $mockCurrentDatabaseEngineSqlBinDirectory = "C:\Program Files\Microsoft SQL Server\$mockCurrentDatabaseEngineInstanceId\MSSQL\Binn"
                $mockCurrentAnalysisServicesSqlBinDirectory = "C:\Program Files\Microsoft SQL Server\$mockCurrentDatabaseEngineInstanceId\OLAP\Binn"
                $mockCurrentIntegrationServicesSqlPathDirectory = "C:\Program Files\Microsoft SQL Server\$($mockCurrentSqlMajorVersion)0\DTS\"


                $mockSqlInstallPath = "C:\Program Files\Microsoft SQL Server\$($mockDefaultInstance_InstanceId)\MSSQL"
                $mockSqlBackupPath = "C:\Program Files\Microsoft SQL Server\$($mockDefaultInstance_InstanceId)\MSSQL\Backup"
                $mockSqlTempDatabasePath = ''
                $mockSqlTempDatabaseLogPath = ''
                $mockSqlDefaultDatabaseFilePath = "C:\Program Files\Microsoft SQL Server\$($mockDefaultInstance_InstanceId)\MSSQL\DATA\"
                $mockSqlDefaultDatabaseLogPath = "C:\Program Files\Microsoft SQL Server\$($mockDefaultInstance_InstanceId)\MSSQL\DATA\"

                Context "When SQL Server version is $mockCurrentSqlMajorVersion. Testing helper function Get-SqlRootPath" {
                    It 'Should return the the correct path for Database Engine' {
                        $result = Get-SQLPath -Feature 'SQLEngine' -InstanceName $mockDefaultInstance_InstanceName
                        $result | Should -Be $mockCurrentDatabaseEngineSqlBinDirectory

                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_SqlInstanceId_ParameterFilter -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_AnalysisServicesInstanceId_ParameterFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_DatabaseEngineSqlBinRoot_ParameterFilter -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_AnalysisServicesSqlBinRoot_ParameterFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_IntegrationsServicesSqlPath_ParameterFilter -Exactly -Times 0 -Scope It
                    }

                    It 'Should return the the correct path for Analysis Services' {
                        $result = Get-SQLPath -Feature 'As' -InstanceName $mockDefaultInstance_InstanceName
                        $result | Should -Be $mockCurrentAnalysisServicesSqlBinDirectory

                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_SqlInstanceId_ParameterFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_AnalysisServicesInstanceId_ParameterFilter -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_DatabaseEngineSqlBinRoot_ParameterFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_AnalysisServicesSqlBinRoot_ParameterFilter -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_IntegrationsServicesSqlPath_ParameterFilter -Exactly -Times 0 -Scope It
                    }

                    It 'Should return the the correct path for Integration Services' {
                        $result = Get-SQLPath -Feature 'Is' -InstanceName $mockDefaultInstance_InstanceName -SQLVersion $mockCurrentSqlMajorVersion
                        $result | Should -Be $mockCurrentIntegrationServicesSqlPathDirectory

                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_SqlInstanceId_ParameterFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_AnalysisServicesInstanceId_ParameterFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_DatabaseEngineSqlBinRoot_ParameterFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_AnalysisServicesSqlBinRoot_ParameterFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_IntegrationsServicesSqlPath_ParameterFilter -Exactly -Times 1 -Scope It
                    }
                }

                Context "When SQL Server version is $mockCurrentSqlMajorVersion and there are no components installed" {
                    BeforeAll {
                        $testParameters = $mockDefaultParameters.Clone()
                        $testParameters += @{
                            InstanceName = $mockCurrentInstanceName
                            SourcePath = $mockSourcePath
                        }

                        Mock -CommandName Get-Service -MockWith $mockEmptyHashtable -Verifiable
                        Mock -CommandName Test-IsFirewallRuleInDesiredState -Verifiable
                        Mock -CommandName New-NetFirewallRule -Verifiable
                        Mock -CommandName Set-NetFirewallRule -Verifiable
                    }

                    It 'Should return the same values as passed as parameters' {
                        $result = Get-TargetResource @testParameters
                        $result.InstanceName | Should -Be $testParameters.InstanceName
                        $result.SourcePath | Should -Be $testParameters.SourcePath
                    }

                    It 'Should not return any values in the read parameters' {
                        $result = Get-TargetResource @testParameters
                        $result.DatabaseEngineFirewall | Should -BeNullOrEmpty
                        $result.BrowserFirewall | Should -BeNullOrEmpty
                        $result.ReportingServicesFirewall | Should -BeNullOrEmpty
                        $result.AnalysisServicesFirewall | Should -BeNullOrEmpty
                        $result.IntegrationServicesFirewall | Should -BeNullOrEmpty
                    }

                    It 'Should return state as absent' {
                        $result = Get-TargetResource @testParameters
                        $result.Ensure | Should -Be 'Absent'
                        $result.Features | Should -BeNullOrEmpty
                    }

                    Context 'When authenticating using NetBIOS domain' {
                        It 'Should call the correct functions exact number of times' {
                            $result = Get-TargetResource @testParameters

                            Assert-MockCalled -CommandName Remove-SmbMapping -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName Test-IsFirewallRuleInDesiredState -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName New-NetFirewallRule -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Set-NetFirewallRule -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_SqlInstanceId_ParameterFilter -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_AnalysisServicesInstanceId_ParameterFilter -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_DatabaseEngineSqlBinRoot_ParameterFilter -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_AnalysisServicesSqlBinRoot_ParameterFilter -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_IntegrationsServicesSqlPath_ParameterFilter -Exactly -Times 0 -Scope It

                            Assert-MockCalled -CommandName New-SmbMapping -ParameterFilter {
                                $UserName -eq $mockSourceCredentialUserName
                            } -Exactly -Times 1 -Scope It
                        }
                    }

                    Context 'When authenticating using Fully Qualified Domain Name (FQDN)' {
                        BeforeAll {
                            $testParameters['SourceCredential'] = $mockFqdnSourceCredential
                        }

                        It 'Should call the correct functions exact number of times' {
                            $result = Get-TargetResource @testParameters

                            Assert-MockCalled -CommandName Remove-SmbMapping -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName Test-IsFirewallRuleInDesiredState -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName New-NetFirewallRule -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Set-NetFirewallRule -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_SqlInstanceId_ParameterFilter -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_AnalysisServicesInstanceId_ParameterFilter -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_DatabaseEngineSqlBinRoot_ParameterFilter -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_AnalysisServicesSqlBinRoot_ParameterFilter -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_IntegrationsServicesSqlPath_ParameterFilter -Exactly -Times 0 -Scope It

                            Assert-MockCalled -CommandName New-SmbMapping -ParameterFilter {
                                $UserName -eq $mockFqdnSourceCredentialUserName
                            } -Exactly -Times 1 -Scope It
                        }
                    }
                }

                Context "When SQL Server version is $mockCurrentSqlMajorVersion and the system is not in the desired state for default instance" {
                    BeforeEach {
                        $testParameters = $mockDefaultParameters.Clone()
                        $testParameters += @{
                            InstanceName = $mockCurrentInstanceName
                            SourcePath = $mockSourcePath
                        }

                        Mock -CommandName Get-NetFirewallRule -Verifiable
                        Mock -CommandName Get-NetFirewallApplicationFilter -Verifiable
                        Mock -CommandName Get-NetFirewallServiceFilter -Verifiable
                        Mock -CommandName Get-NetFirewallPortFilter -Verifiable
                        Mock -CommandName New-NetFirewallRule -Verifiable
                        Mock -CommandName Set-NetFirewallRule -Verifiable
                        Mock -CommandName Get-Service -MockWith $mockGetService_DefaultInstance -Verifiable
                    }

                    It 'Should return the same values as passed as parameters' {
                        $result = Get-TargetResource @testParameters
                        $result.InstanceName | Should -Be $testParameters.InstanceName
                        $result.SourcePath | Should -Be $testParameters.SourcePath
                        $result.Features | Should -Be $testParameters.Features
                    }

                    It 'Should return $false for the read parameter DatabaseEngineFirewall' {
                        $result = Get-TargetResource @testParameters
                        $result.DatabaseEngineFirewall | Should -Be $false
                    }

                    It 'Should return $false for the read parameter BrowserFirewall' {
                        $result = Get-TargetResource @testParameters
                        $result.BrowserFirewall | Should -Be $false
                    }

                    It 'Should return $false for the read parameter ReportingServicesFirewall' {
                        $result = Get-TargetResource @testParameters
                        $result.ReportingServicesFirewall | Should -Be $false
                    }

                    It 'Should return $false for the read parameter AnalysisServicesFirewall' {
                        $result = Get-TargetResource @testParameters
                        $result.AnalysisServicesFirewall | Should -Be $false
                    }

                    It 'Should return $false for the read parameter IntegrationServicesFirewall' {
                        $result = Get-TargetResource @testParameters
                        $result.IntegrationServicesFirewall | Should -Be $false
                    }

                    It 'Should return state as absent' {
                        $result = Get-TargetResource @testParameters
                        $result.Ensure | Should -Be 'Absent'
                    }

                    It 'Should call the correct functions exact number of times' {
                        $result = Get-TargetResource @testParameters
                        Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallRule -Exactly -Times 6 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallApplicationFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallServiceFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallPortFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName New-NetFirewallRule -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Set-NetFirewallRule -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_SqlInstanceId_ParameterFilter -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_AnalysisServicesInstanceId_ParameterFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_DatabaseEngineSqlBinRoot_ParameterFilter -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_AnalysisServicesSqlBinRoot_ParameterFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_IntegrationsServicesSqlPath_ParameterFilter -Exactly -Times 1 -Scope It
                    }
                }

                Context "When SQL Server version is $mockCurrentSqlMajorVersion and the system is in the desired state for default instance" {
                    BeforeEach {
                        $testParameters = $mockDefaultParameters.Clone()
                        $testParameters += @{
                            InstanceName = $mockCurrentInstanceName
                            SourcePath = $mockSourcePath
                        }

                        Mock -CommandName Get-NetFirewallRule -MockWith $mockGetNetFirewallRule -Verifiable
                        Mock -CommandName Get-NetFirewallApplicationFilter -MockWith $mockGetNetFirewallApplicationFilter -Verifiable
                        Mock -CommandName Get-NetFirewallServiceFilter -MockWith $mockGetNetFirewallServiceFilter -Verifiable
                        Mock -CommandName Get-NetFirewallPortFilter -MockWith $mockGetNetFirewallPortFilter -Verifiable
                        Mock -CommandName New-NetFirewallRule -Verifiable
                        Mock -CommandName Set-NetFirewallRule -Verifiable
                        Mock -CommandName Get-Service -MockWith $mockGetService_DefaultInstance -Verifiable
                    }

                    It 'Should return the same values as passed as parameters' {
                        $result = Get-TargetResource @testParameters
                        $result.InstanceName | Should -Be $testParameters.InstanceName
                        $result.SourcePath | Should -Be $testParameters.SourcePath
                    }

                    It 'Should return $true for the read parameter DatabaseEngineFirewall' {
                        $result = Get-TargetResource @testParameters
                        $result.DatabaseEngineFirewall | Should -Be $true
                    }

                    It 'Should return $true for the read parameter BrowserFirewall' {
                        $result = Get-TargetResource @testParameters
                        $result.BrowserFirewall | Should -Be $true
                    }

                    It 'Should return $true for the read parameter ReportingServicesFirewall' {
                        $result = Get-TargetResource @testParameters
                        $result.ReportingServicesFirewall | Should -Be $true
                    }

                    It 'Should return $true for the read parameter AnalysisServicesFirewall' {
                        $result = Get-TargetResource @testParameters
                        $result.AnalysisServicesFirewall | Should -Be $true
                    }

                    It 'Should return $true for the read parameter IntegrationServicesFirewall' {
                        $result = Get-TargetResource @testParameters
                        $result.IntegrationServicesFirewall | Should -Be $true
                    }

                    It 'Should return state as absent' {
                        $result = Get-TargetResource @testParameters
                        $result.Ensure | Should -Be 'Present'
                        $result.Features | Should -Be $testParameters.Features
                    }

                    It 'Should call the correct functions exact number of times' {
                        $result = Get-TargetResource @testParameters
                        Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallRule -Exactly -Times 8 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallApplicationFilter -Exactly -Times 2 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallServiceFilter -Exactly -Times 3 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallPortFilter -Exactly -Times 3 -Scope It
                        Assert-MockCalled -CommandName New-NetFirewallRule -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Set-NetFirewallRule -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_SqlInstanceId_ParameterFilter -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_AnalysisServicesInstanceId_ParameterFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_DatabaseEngineSqlBinRoot_ParameterFilter -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_AnalysisServicesSqlBinRoot_ParameterFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_IntegrationsServicesSqlPath_ParameterFilter -Exactly -Times 1 -Scope It
                    }
                }

                $mockCurrentInstanceName = $mockNamedInstance_InstanceName
                $mockCurrentDatabaseEngineInstanceId = "$($mockSqlDatabaseEngineInstanceIdName)$($mockCurrentSqlMajorVersion).$($mockCurrentInstanceName)"
                $mockCurrentAnalysisServiceInstanceId = "$($mockSqlAnalysisServicesInstanceIdName)$($mockCurrentSqlMajorVersion).$($mockCurrentInstanceName)"

                $mockCurrentSqlAnalysisServiceName = $mockNamedInstance_AnalysisServiceName

                $mockCurrentDatabaseEngineSqlBinDirectory = "C:\Program Files\Microsoft SQL Server\$mockCurrentDatabaseEngineInstanceId\MSSQL\Binn"
                $mockCurrentAnalysisServicesSqlBinDirectory = "C:\Program Files\Microsoft SQL Server\$mockCurrentDatabaseEngineInstanceId\OLAP\Binn"
                $mockCurrentIntegrationServicesSqlPathDirectory = "C:\Program Files\Microsoft SQL Server\$($mockCurrentSqlMajorVersion)0\DTS\"

                Context "When SQL Server version is $mockCurrentSqlMajorVersion and the system is not in the desired state for named instance" {
                    BeforeEach {
                        $testParameters = $mockDefaultParameters.Clone()
                        $testParameters += @{
                            InstanceName = $mockCurrentInstanceName
                            SourcePath = $mockSourcePath
                        }

                        Mock -CommandName Get-NetFirewallRule -Verifiable
                        Mock -CommandName Get-NetFirewallApplicationFilter -Verifiable
                        Mock -CommandName Get-NetFirewallServiceFilter -Verifiable
                        Mock -CommandName Get-NetFirewallPortFilter -Verifiable
                        Mock -CommandName New-NetFirewallRule -Verifiable
                        Mock -CommandName Set-NetFirewallRule -Verifiable
                        Mock -CommandName Get-Service -MockWith $mockGetService_NamedInstance -Verifiable
                    }

                    It 'Should return the same values as passed as parameters' {
                        $result = Get-TargetResource @testParameters
                        $result.InstanceName | Should -Be $testParameters.InstanceName
                        $result.SourcePath | Should -Be $testParameters.SourcePath
                        $result.Features | Should -Be $testParameters.Features
                    }

                    It 'Should return $false for the read parameter DatabaseEngineFirewall' {
                        $result = Get-TargetResource @testParameters
                        $result.DatabaseEngineFirewall | Should -Be $false
                    }

                    It 'Should return $false for the read parameter BrowserFirewall' {
                        $result = Get-TargetResource @testParameters
                        $result.BrowserFirewall | Should -Be $false
                    }

                    It 'Should return $false for the read parameter ReportingServicesFirewall' {
                        $result = Get-TargetResource @testParameters
                        $result.ReportingServicesFirewall | Should -Be $false
                    }

                    It 'Should return $false for the read parameter AnalysisServicesFirewall' {
                        $result = Get-TargetResource @testParameters
                        $result.AnalysisServicesFirewall | Should -Be $false
                    }

                    It 'Should return $false for the read parameter IntegrationServicesFirewall' {
                        $result = Get-TargetResource @testParameters
                        $result.IntegrationServicesFirewall | Should -Be $false
                    }

                    It 'Should return state as absent' {
                        $result = Get-TargetResource @testParameters
                        $result.Ensure | Should -Be 'Absent'
                    }

                    It 'Should call the correct functions exact number of times' {
                        $result = Get-TargetResource @testParameters
                        Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallRule -Exactly -Times 6 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallApplicationFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallServiceFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallPortFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName New-NetFirewallRule -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Set-NetFirewallRule -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_SqlInstanceId_ParameterFilter -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_AnalysisServicesInstanceId_ParameterFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_DatabaseEngineSqlBinRoot_ParameterFilter -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_AnalysisServicesSqlBinRoot_ParameterFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_IntegrationsServicesSqlPath_ParameterFilter -Exactly -Times 1 -Scope It
                    }
                }

                Context "When SQL Server version is $mockCurrentSqlMajorVersion and the system is not in the desired state for named instance" {
                    BeforeEach {
                        $testParameters = $mockDefaultParameters.Clone()
                        $testParameters += @{
                            InstanceName = $mockCurrentInstanceName
                            SourcePath = $mockSourcePath
                        }

                        Mock -CommandName Get-NetFirewallRule -MockWith $mockGetNetFirewallRule -Verifiable
                        Mock -CommandName Get-NetFirewallApplicationFilter -MockWith $mockGetNetFirewallApplicationFilter -Verifiable
                        Mock -CommandName Get-NetFirewallServiceFilter -MockWith $mockGetNetFirewallServiceFilter -Verifiable
                        Mock -CommandName Get-NetFirewallPortFilter -MockWith $mockGetNetFirewallPortFilter -Verifiable
                        Mock -CommandName New-NetFirewallRule -Verifiable
                        Mock -CommandName Set-NetFirewallRule -Verifiable
                        Mock -CommandName Get-Service -MockWith $mockGetService_NamedInstance -Verifiable
                    }

                    # Change the mock to not return a rule for DB Engine
                    $mockDynamicSQLBrowserFirewallRulePresent = $true
                    $mockDynamicSQLIntegrationServicesRulePresent = $true
                    $mockDynamicSQLEngineFirewallRulePresent = $false
                    $mockDynamicSQLAnalysisServicesFirewallRulePresent = $true

                    Context 'SQLBrowser rule is present, but missing SQLEngine rule' {
                        It 'Should return the same values as passed as parameters' {
                            $result = Get-TargetResource @testParameters
                            $result.InstanceName | Should -Be $testParameters.InstanceName
                            $result.SourcePath | Should -Be $testParameters.SourcePath
                        }

                        It 'Should return $false for the read parameter DatabaseEngineFirewall' {
                            $result = Get-TargetResource @testParameters
                            $result.DatabaseEngineFirewall | Should -Be $false
                        }

                        It 'Should return $true for the read parameter BrowserFirewall' {
                            $result = Get-TargetResource @testParameters
                            $result.BrowserFirewall | Should -Be $true
                        }

                        It 'Should return state as absent' {
                            $result = Get-TargetResource @testParameters
                            $result.Ensure | Should -Be 'Absent'
                            $result.Features | Should -Be $testParameters.Features
                        }

                        It 'Should call the correct functions exact number of times' {
                            $result = Get-TargetResource @testParameters
                            Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName Get-NetFirewallRule -Exactly -Times 8 -Scope It
                            Assert-MockCalled -CommandName Get-NetFirewallApplicationFilter -Exactly -Times 2 -Scope It
                            Assert-MockCalled -CommandName Get-NetFirewallServiceFilter -Exactly -Times 3 -Scope It
                            Assert-MockCalled -CommandName Get-NetFirewallPortFilter -Exactly -Times 3 -Scope It
                            Assert-MockCalled -CommandName New-NetFirewallRule -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Set-NetFirewallRule -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_SqlInstanceId_ParameterFilter -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_AnalysisServicesInstanceId_ParameterFilter -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_DatabaseEngineSqlBinRoot_ParameterFilter -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_AnalysisServicesSqlBinRoot_ParameterFilter -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_IntegrationsServicesSqlPath_ParameterFilter -Exactly -Times 1 -Scope It
                        }
                    }

                    # Change the mock to not return a rule for Analysis Services
                    $mockDynamicSQLBrowserFirewallRulePresent = $true
                    $mockDynamicSQLIntegrationServicesRulePresent = $true
                    $mockDynamicSQLEngineFirewallRulePresent = $true
                    $mockDynamicSQLAnalysisServicesFirewallRulePresent = $false

                    Context 'SQLBrowser rule is present, but missing Analysis Services rule' {
                        It 'Should return the same values as passed as parameters' {
                            $result = Get-TargetResource @testParameters
                            $result.InstanceName | Should -Be $testParameters.InstanceName
                            $result.SourcePath | Should -Be $testParameters.SourcePath
                        }

                        It 'Should return $false for the read parameter AnalysisServicesFirewall' {
                            $result = Get-TargetResource @testParameters
                            $result.AnalysisServicesFirewall | Should -Be $false
                        }

                        It 'Should return $true for the read parameter BrowserFirewall' {
                            $result = Get-TargetResource @testParameters
                            $result.BrowserFirewall | Should -Be $true
                        }

                        It 'Should return state as absent' {
                            $result = Get-TargetResource @testParameters
                            $result.Ensure | Should -Be 'Absent'
                            $result.Features | Should -Be $testParameters.Features
                        }

                        It 'Should call the correct functions exact number of times' {
                            $result = Get-TargetResource @testParameters
                            Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName Get-NetFirewallRule -Exactly -Times 8 -Scope It
                            Assert-MockCalled -CommandName Get-NetFirewallApplicationFilter -Exactly -Times 2 -Scope It
                            Assert-MockCalled -CommandName Get-NetFirewallServiceFilter -Exactly -Times 3 -Scope It
                            Assert-MockCalled -CommandName Get-NetFirewallPortFilter -Exactly -Times 3 -Scope It
                            Assert-MockCalled -CommandName New-NetFirewallRule -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Set-NetFirewallRule -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_SqlInstanceId_ParameterFilter -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_AnalysisServicesInstanceId_ParameterFilter -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_DatabaseEngineSqlBinRoot_ParameterFilter -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_AnalysisServicesSqlBinRoot_ParameterFilter -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_IntegrationsServicesSqlPath_ParameterFilter -Exactly -Times 1 -Scope It
                        }
                    }
                }

                # Set mock to return all rules.
                $mockDynamicSQLBrowserFirewallRulePresent = $true
                $mockDynamicSQLIntegrationServicesRulePresent = $true
                $mockDynamicSQLEngineFirewallRulePresent = $true
                $mockDynamicSQLAnalysisServicesFirewallRulePresent = $true

                Context "When SQL Server version is $mockCurrentSqlMajorVersion and the system is in the desired state for named instance" {
                    BeforeEach {
                        $testParameters = $mockDefaultParameters.Clone()
                        $testParameters += @{
                            InstanceName = $mockCurrentInstanceName
                            SourcePath = $mockSourcePath
                        }

                        Mock -CommandName Get-NetFirewallRule -MockWith $mockGetNetFirewallRule -Verifiable
                        Mock -CommandName Get-NetFirewallApplicationFilter -MockWith $mockGetNetFirewallApplicationFilter -Verifiable
                        Mock -CommandName Get-NetFirewallServiceFilter -MockWith $mockGetNetFirewallServiceFilter -Verifiable
                        Mock -CommandName Get-NetFirewallPortFilter -MockWith $mockGetNetFirewallPortFilter -Verifiable
                        Mock -CommandName New-NetFirewallRule -Verifiable
                        Mock -CommandName Set-NetFirewallRule -Verifiable
                        Mock -CommandName Get-Service -MockWith $mockGetService_NamedInstance -Verifiable
                    }

                    It 'Should return the same values as passed as parameters' {
                        $result = Get-TargetResource @testParameters
                        $result.InstanceName | Should -Be $testParameters.InstanceName
                        $result.SourcePath | Should -Be $testParameters.SourcePath
                    }

                    It 'Should return $true for the read parameter DatabaseEngineFirewall' {
                        $result = Get-TargetResource @testParameters
                        $result.DatabaseEngineFirewall | Should -Be $true
                    }

                    It 'Should return $true for the read parameter BrowserFirewall' {
                        $result = Get-TargetResource @testParameters
                        $result.BrowserFirewall | Should -Be $true
                    }

                    It 'Should return $true for the read parameter ReportingServicesFirewall' {
                        $result = Get-TargetResource @testParameters
                        $result.ReportingServicesFirewall | Should -Be $true
                    }

                    It 'Should return $true for the read parameter AnalysisServicesFirewall' {
                        $result = Get-TargetResource @testParameters
                        $result.AnalysisServicesFirewall | Should -Be $true
                    }

                    It 'Should return $true for the read parameter IntegrationServicesFirewall' {
                        $result = Get-TargetResource @testParameters
                        $result.IntegrationServicesFirewall | Should -Be $true
                    }

                    It 'Should return state as absent' {
                        $result = Get-TargetResource @testParameters
                        $result.Ensure | Should -Be 'Present'
                        $result.Features | Should -Be $testParameters.Features
                    }

                    It 'Should call the correct functions exact number of times' {
                        $result = Get-TargetResource @testParameters
                        Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallRule -Exactly -Times 8 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallApplicationFilter -Exactly -Times 2 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallServiceFilter -Exactly -Times 3 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallPortFilter -Exactly -Times 3 -Scope It
                        Assert-MockCalled -CommandName New-NetFirewallRule -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Set-NetFirewallRule -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_SqlInstanceId_ParameterFilter -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_AnalysisServicesInstanceId_ParameterFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_DatabaseEngineSqlBinRoot_ParameterFilter -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_AnalysisServicesSqlBinRoot_ParameterFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_IntegrationsServicesSqlPath_ParameterFilter -Exactly -Times 1 -Scope It
                    }
                }
            }
        }

        Describe "SqlWindowsFirewall\Set-TargetResource" -Tag 'Set' {
            # Local path to TestDrive:\
            $mockSourcePath = $TestDrive.FullName

            BeforeEach {
                # General mocks
                Mock -CommandName Get-FilePathMajorVersion -MockWith $mockGetSqlMajorVersion -Verifiable

                # Mock SQL Server Database Engine registry for Instance ID.
                Mock -CommandName Get-ItemProperty `
                    -ParameterFilter $mockGetItemProperty_SqlInstanceId_ParameterFilter `
                    -MockWith $mockGetItemProperty_SqlInstanceId -Verifiable

                # Mock SQL Server Analysis Services registry for Instance ID.
                Mock -CommandName Get-ItemProperty `
                    -ParameterFilter $mockGetItemProperty_AnalysisServicesInstanceId_ParameterFilter `
                    -MockWith $mockGetItemProperty_AnalysisServicesInstanceId -Verifiable

                # Mocking SQL Server Database Engine registry for path to binaries root.
                Mock -CommandName Get-ItemProperty `
                    -ParameterFilter $mockGetItemProperty_DatabaseEngineSqlBinRoot_ParameterFilter `
                    -MockWith $mockGetItemProperty_DatabaseEngineSqlBinRoot -Verifiable

                # Mocking SQL Server Database Engine registry for path to binaries root.
                Mock -CommandName Get-ItemProperty `
                    -ParameterFilter $mockGetItemProperty_AnalysisServicesSqlBinRoot_ParameterFilter `
                    -MockWith $mockGetItemProperty_AnalysisServicesSqlBinRoot -Verifiable

                # Mock SQL Server Integration Services Registry for path to binaries root.
                Mock -CommandName Get-ItemProperty `
                    -ParameterFilter $mockGetItemProperty_IntegrationsServicesSqlPath_ParameterFilter `
                    -MockWith $mockGetItemProperty_IntegrationsServicesSqlPath -Verifiable

                Mock -CommandName Get-ItemProperty -MockWith $mockGetItemProperty_CallingWithWrongParameters -Verifiable
                Mock -CommandName New-NetFirewallRule -MockWith $mockNewNetFirewallRule -Verifiable
                Mock -CommandName Set-NetFirewallRule -MockWith $mockSetNetFirewallRule -Verifiable
                Mock -CommandName New-SmbMapping -Verifiable
                Mock -CommandName Remove-SmbMapping -Verifiable
            }

            $testProductVersion | ForEach-Object -Process {
                $mockCurrentSqlMajorVersion = $_

                $mockCurrentPathToSetupExecutable = Join-Path -Path $mockSourcePath -ChildPath $mockSetupExecutableName

                $mockCurrentInstanceName = $mockDefaultInstance_InstanceName
                $mockCurrentDatabaseEngineInstanceId = "$($mockSqlDatabaseEngineInstanceIdName)$($mockCurrentSqlMajorVersion).$($mockCurrentInstanceName)"
                $mockCurrentAnalysisServiceInstanceId = "$($mockSqlAnalysisServicesInstanceIdName)$($mockCurrentSqlMajorVersion).$($mockCurrentInstanceName)"

                $mockCurrentSqlAnalysisServiceName = $mockDefaultInstance_AnalysisServiceName

                $mockCurrentDatabaseEngineSqlBinDirectory = "C:\Program Files\Microsoft SQL Server\$mockCurrentDatabaseEngineInstanceId\MSSQL\Binn"
                $mockCurrentAnalysisServicesSqlBinDirectory = "C:\Program Files\Microsoft SQL Server\$mockCurrentDatabaseEngineInstanceId\OLAP\Binn"
                $mockCurrentIntegrationServicesSqlPathDirectory = "C:\Program Files\Microsoft SQL Server\$($mockCurrentSqlMajorVersion)0\DTS\"


                $mockSqlInstallPath = "C:\Program Files\Microsoft SQL Server\$($mockDefaultInstance_InstanceId)\MSSQL"
                $mockSqlBackupPath = "C:\Program Files\Microsoft SQL Server\$($mockDefaultInstance_InstanceId)\MSSQL\Backup"
                $mockSqlTempDatabasePath = ''
                $mockSqlTempDatabaseLogPath = ''
                $mockSqlDefaultDatabaseFilePath = "C:\Program Files\Microsoft SQL Server\$($mockDefaultInstance_InstanceId)\MSSQL\DATA\"
                $mockSqlDefaultDatabaseLogPath = "C:\Program Files\Microsoft SQL Server\$($mockDefaultInstance_InstanceId)\MSSQL\DATA\"

                # Mock this here because only the first test uses it.
                Mock -CommandName Test-TargetResource -MockWith { return $false }

                Context "When SQL Server version is $mockCurrentSqlMajorVersion and there are no components installed" {
                    BeforeAll {
                        $testParameters = $mockDefaultParameters.Clone()
                        $testParameters += @{
                            InstanceName = $mockCurrentInstanceName
                            SourcePath = $mockSourcePath
                        }

                        Mock -CommandName New-SmbMapping -Verifiable
                        Mock -CommandName Remove-SmbMapping -Verifiable
                        Mock -CommandName Get-Service -MockWith $mockEmptyHashtable -Verifiable
                        Mock -CommandName Test-IsFirewallRuleInDesiredState -Verifiable
                        Mock -CommandName New-NetFirewallRule -Verifiable
                        Mock -CommandName Set-NetFirewallRule -Verifiable
                    }

                    Context 'When authenticating using NetBIOS domain' {
                        It 'Should throw the correct error when Set-TargetResource verifies result with Test-TargetResource' {
                            { Set-TargetResource @testParameters } | Should -Throw $script:localizedData.TestFailedAfterSet

                            Assert-MockCalled -CommandName Remove-SmbMapping -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName Test-IsFirewallRuleInDesiredState -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName New-NetFirewallRule -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Set-NetFirewallRule -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_SqlInstanceId_ParameterFilter -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_AnalysisServicesInstanceId_ParameterFilter -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_DatabaseEngineSqlBinRoot_ParameterFilter -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_AnalysisServicesSqlBinRoot_ParameterFilter -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_IntegrationsServicesSqlPath_ParameterFilter -Exactly -Times 0 -Scope It

                            Assert-MockCalled -CommandName New-SmbMapping -ParameterFilter {
                                $UserName -eq $mockSourceCredentialUserName
                            } -Exactly -Times 1 -Scope It
                        }
                    }

                    Context 'When authenticating using Fully Qualified Domain Name (FQDN)' {
                        BeforeAll {
                            $testParameters['SourceCredential'] = $mockFqdnSourceCredential
                        }

                        It 'Should throw the correct error when Set-TargetResource verifies result with Test-TargetResource' {
                            { Set-TargetResource @testParameters } | Should -Throw $script:localizedData.TestFailedAfterSet

                            Assert-MockCalled -CommandName Remove-SmbMapping -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName Test-IsFirewallRuleInDesiredState -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName New-NetFirewallRule -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Set-NetFirewallRule -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_SqlInstanceId_ParameterFilter -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_AnalysisServicesInstanceId_ParameterFilter -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_DatabaseEngineSqlBinRoot_ParameterFilter -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_AnalysisServicesSqlBinRoot_ParameterFilter -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_IntegrationsServicesSqlPath_ParameterFilter -Exactly -Times 0 -Scope It

                            Assert-MockCalled -CommandName New-SmbMapping -ParameterFilter {
                                $UserName -eq $mockFqdnSourceCredentialUserName
                            } -Exactly -Times 1 -Scope It
                        }
                    }
                }

                # Mock this here so the rest of the test uses it.
                Mock -CommandName Test-TargetResource -MockWith { return $true }

                Context "When SQL Server version is $mockCurrentSqlMajorVersion and the system is not in the desired state for default instance" {
                    BeforeEach {
                        $testParameters = $mockDefaultParameters.Clone()
                        $testParameters += @{
                            InstanceName = $mockCurrentInstanceName
                            SourcePath = $mockSourcePath
                        }

                        Mock -CommandName Get-NetFirewallRule -Verifiable
                        Mock -CommandName Get-NetFirewallApplicationFilter -Verifiable
                        Mock -CommandName Get-NetFirewallServiceFilter -Verifiable
                        Mock -CommandName Get-NetFirewallPortFilter -Verifiable
                        Mock -CommandName Get-Service -MockWith $mockGetService_DefaultInstance -Verifiable
                    }

                    It 'Should create all firewall rules without throwing' {
                        { Set-TargetResource @testParameters } | Should -Not -Throw

                        Assert-MockCalled -CommandName New-NetFirewallRule -Exactly -Times 8 -Scope It
                        Assert-MockCalled -CommandName Set-NetFirewallRule -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallRule -Exactly -Times 15 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallApplicationFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallServiceFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallPortFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_SqlInstanceId_ParameterFilter -Exactly -Times 2 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_AnalysisServicesInstanceId_ParameterFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_DatabaseEngineSqlBinRoot_ParameterFilter -Exactly -Times 2 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_AnalysisServicesSqlBinRoot_ParameterFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_IntegrationsServicesSqlPath_ParameterFilter -Exactly -Times 2 -Scope It
                    }

                    It 'Should update the database engine firewall rule without throwing' {
                        Mock -CommandName Get-NetFirewallRule -ParameterFilter $mockGetNetFirewallRule_EmptyDisplayName_ParameterFilter -MockWith $mockGetNetFirewallRule_EmptyDisplayName -Verifiable

                        { Set-TargetResource @testParameters } | Should -Not -Throw

                        Assert-MockCalled -CommandName New-NetFirewallRule -Exactly -Times 7 -Scope It
                        Assert-MockCalled -CommandName Set-NetFirewallRule -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallRule -Exactly -Times 15 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallApplicationFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallServiceFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallPortFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_SqlInstanceId_ParameterFilter -Exactly -Times 2 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_AnalysisServicesInstanceId_ParameterFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_DatabaseEngineSqlBinRoot_ParameterFilter -Exactly -Times 2 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_AnalysisServicesSqlBinRoot_ParameterFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_IntegrationsServicesSqlPath_ParameterFilter -Exactly -Times 2 -Scope It
                    }
                }

                Context "When SQL Server version is $mockCurrentSqlMajorVersion and the system is in the desired state for default instance" {
                    BeforeEach {
                        $testParameters = $mockDefaultParameters.Clone()
                        $testParameters += @{
                            InstanceName = $mockCurrentInstanceName
                            SourcePath = $mockSourcePath
                        }

                        Mock -CommandName Get-NetFirewallRule -MockWith $mockGetNetFirewallRule -Verifiable
                        Mock -CommandName Get-NetFirewallApplicationFilter -MockWith $mockGetNetFirewallApplicationFilter -Verifiable
                        Mock -CommandName Get-NetFirewallServiceFilter -MockWith $mockGetNetFirewallServiceFilter -Verifiable
                        Mock -CommandName Get-NetFirewallPortFilter -MockWith $mockGetNetFirewallPortFilter -Verifiable
                        Mock -CommandName Get-Service -MockWith $mockGetService_DefaultInstance -Verifiable
                    }

                    It 'Should not call mock New-NetFirewallRule or Set-NetFirewallRule' {
                        { Set-TargetResource @testParameters } | Should -Not -Throw

                        Assert-MockCalled -CommandName New-NetFirewallRule -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Set-NetFirewallRule -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallRule -Exactly -Times 8 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallApplicationFilter -Exactly -Times 2 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallServiceFilter -Exactly -Times 3 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallPortFilter -Exactly -Times 3 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_SqlInstanceId_ParameterFilter -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_AnalysisServicesInstanceId_ParameterFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_DatabaseEngineSqlBinRoot_ParameterFilter -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_AnalysisServicesSqlBinRoot_ParameterFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_IntegrationsServicesSqlPath_ParameterFilter -Exactly -Times 1 -Scope It
                    }
                }

                $mockCurrentInstanceName = $mockNamedInstance_InstanceName
                $mockCurrentDatabaseEngineInstanceId = "$($mockSqlDatabaseEngineInstanceIdName)$($mockCurrentSqlMajorVersion).$($mockCurrentInstanceName)"
                $mockCurrentAnalysisServiceInstanceId = "$($mockSqlAnalysisServicesInstanceIdName)$($mockCurrentSqlMajorVersion).$($mockCurrentInstanceName)"

                $mockCurrentSqlAnalysisServiceName = $mockNamedInstance_AnalysisServiceName

                $mockCurrentDatabaseEngineSqlBinDirectory = "C:\Program Files\Microsoft SQL Server\$mockCurrentDatabaseEngineInstanceId\MSSQL\Binn"
                $mockCurrentAnalysisServicesSqlBinDirectory = "C:\Program Files\Microsoft SQL Server\$mockCurrentDatabaseEngineInstanceId\OLAP\Binn"
                $mockCurrentIntegrationServicesSqlPathDirectory = "C:\Program Files\Microsoft SQL Server\$($mockCurrentSqlMajorVersion)0\DTS\"

                Context "When SQL Server version is $mockCurrentSqlMajorVersion and the system is not in the desired state for named instance" {
                    BeforeEach {
                        $testParameters = $mockDefaultParameters.Clone()
                        $testParameters += @{
                            InstanceName = $mockCurrentInstanceName
                            SourcePath = $mockSourcePath
                        }

                        Mock -CommandName Get-NetFirewallRule -Verifiable
                        Mock -CommandName Get-NetFirewallApplicationFilter -Verifiable
                        Mock -CommandName Get-NetFirewallServiceFilter -Verifiable
                        Mock -CommandName Get-NetFirewallPortFilter -Verifiable
                        Mock -CommandName Get-Service -MockWith $mockGetService_NamedInstance -Verifiable
                    }

                    It 'Should create all firewall rules without throwing' {
                        { Set-TargetResource @testParameters } | Should -Not -Throw

                        Assert-MockCalled -CommandName New-NetFirewallRule -Exactly -Times 8 -Scope It
                        Assert-MockCalled -CommandName Set-NetFirewallRule -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallRule -Exactly -Times 15 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallApplicationFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallServiceFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallPortFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_SqlInstanceId_ParameterFilter -Exactly -Times 2 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_AnalysisServicesInstanceId_ParameterFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_DatabaseEngineSqlBinRoot_ParameterFilter -Exactly -Times 2 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_AnalysisServicesSqlBinRoot_ParameterFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_IntegrationsServicesSqlPath_ParameterFilter -Exactly -Times 2 -Scope It
                    }
                }

                Context "When SQL Server version is $mockCurrentSqlMajorVersion and the system is in the desired state for named instance" {
                    BeforeEach {
                        $testParameters = $mockDefaultParameters.Clone()
                        $testParameters += @{
                            InstanceName = $mockCurrentInstanceName
                            SourcePath = $mockSourcePath
                        }

                        Mock -CommandName Get-NetFirewallRule -MockWith $mockGetNetFirewallRule -Verifiable
                        Mock -CommandName Get-NetFirewallApplicationFilter -MockWith $mockGetNetFirewallApplicationFilter -Verifiable
                        Mock -CommandName Get-NetFirewallServiceFilter -MockWith $mockGetNetFirewallServiceFilter -Verifiable
                        Mock -CommandName Get-NetFirewallPortFilter -MockWith $mockGetNetFirewallPortFilter -Verifiable
                        Mock -CommandName Get-Service -MockWith $mockGetService_NamedInstance -Verifiable
                    }

                    It 'Should not call mock New-NetFirewallRule or Set-NetFirewallRule' {
                        { Set-TargetResource @testParameters } | Should -Not -Throw

                        Assert-MockCalled -CommandName New-NetFirewallRule -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Set-NetFirewallRule -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-Service -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallRule -Exactly -Times 8 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallApplicationFilter -Exactly -Times 2 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallServiceFilter -Exactly -Times 3 -Scope It
                        Assert-MockCalled -CommandName Get-NetFirewallPortFilter -Exactly -Times 3 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_SqlInstanceId_ParameterFilter -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_AnalysisServicesInstanceId_ParameterFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_DatabaseEngineSqlBinRoot_ParameterFilter -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_AnalysisServicesSqlBinRoot_ParameterFilter -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Get-ItemProperty -ParameterFilter $mockGetItemProperty_IntegrationsServicesSqlPath_ParameterFilter -Exactly -Times 1 -Scope It
                    }
                }
            }
        }

        Describe "SqlWindowsFirewall\Test-TargetResource" -Tag 'Test' {
            # Local path to TestDrive:\
            $mockSourcePath = $TestDrive.FullName

            BeforeEach {
                # General mocks
                Mock -CommandName Get-FilePathMajorVersion -MockWith $mockGetSqlMajorVersion -Verifiable

                # Mock SQL Server Database Engine registry for Instance ID.
                Mock -CommandName Get-ItemProperty `
                    -ParameterFilter $mockGetItemProperty_SqlInstanceId_ParameterFilter `
                    -MockWith $mockGetItemProperty_SqlInstanceId -Verifiable

                # Mock SQL Server Analysis Services registry for Instance ID.
                Mock -CommandName Get-ItemProperty `
                    -ParameterFilter $mockGetItemProperty_AnalysisServicesInstanceId_ParameterFilter `
                    -MockWith $mockGetItemProperty_AnalysisServicesInstanceId -Verifiable

                # Mocking SQL Server Database Engine registry for path to binaries root.
                Mock -CommandName Get-ItemProperty `
                    -ParameterFilter $mockGetItemProperty_DatabaseEngineSqlBinRoot_ParameterFilter `
                    -MockWith $mockGetItemProperty_DatabaseEngineSqlBinRoot -Verifiable

                # Mocking SQL Server Database Engine registry for path to binaries root.
                Mock -CommandName Get-ItemProperty `
                    -ParameterFilter $mockGetItemProperty_AnalysisServicesSqlBinRoot_ParameterFilter `
                    -MockWith $mockGetItemProperty_AnalysisServicesSqlBinRoot -Verifiable

                # Mock SQL Server Integration Services Registry for path to binaries root.
                Mock -CommandName Get-ItemProperty `
                    -ParameterFilter $mockGetItemProperty_IntegrationsServicesSqlPath_ParameterFilter `
                    -MockWith $mockGetItemProperty_IntegrationsServicesSqlPath -Verifiable

                Mock -CommandName Get-ItemProperty -MockWith $mockGetItemProperty_CallingWithWrongParameters -Verifiable
                Mock -CommandName New-SmbMapping -Verifiable
                Mock -CommandName Remove-SmbMapping -Verifiable
            }

            $mockCurrentSqlMajorVersion = $_

            $mockCurrentPathToSetupExecutable = Join-Path -Path $mockSourcePath -ChildPath $mockSetupExecutableName

            $mockCurrentInstanceName = $mockDefaultInstance_InstanceName
            $mockCurrentDatabaseEngineInstanceId = "$($mockSqlDatabaseEngineInstanceIdName)$($mockCurrentSqlMajorVersion).$($mockCurrentInstanceName)"
            $mockCurrentAnalysisServiceInstanceId = "$($mockSqlAnalysisServicesInstanceIdName)$($mockCurrentSqlMajorVersion).$($mockCurrentInstanceName)"

            $mockCurrentSqlAnalysisServiceName = $mockDefaultInstance_AnalysisServiceName

            $mockCurrentDatabaseEngineSqlBinDirectory = "C:\Program Files\Microsoft SQL Server\$mockCurrentDatabaseEngineInstanceId\MSSQL\Binn"
            $mockCurrentAnalysisServicesSqlBinDirectory = "C:\Program Files\Microsoft SQL Server\$mockCurrentDatabaseEngineInstanceId\OLAP\Binn"
            $mockCurrentIntegrationServicesSqlPathDirectory = "C:\Program Files\Microsoft SQL Server\$($mockCurrentSqlMajorVersion)0\DTS\"


            $mockSqlInstallPath = "C:\Program Files\Microsoft SQL Server\$($mockDefaultInstance_InstanceId)\MSSQL"
            $mockSqlBackupPath = "C:\Program Files\Microsoft SQL Server\$($mockDefaultInstance_InstanceId)\MSSQL\Backup"
            $mockSqlTempDatabasePath = ''
            $mockSqlTempDatabaseLogPath = ''
            $mockSqlDefaultDatabaseFilePath = "C:\Program Files\Microsoft SQL Server\$($mockDefaultInstance_InstanceId)\MSSQL\DATA\"
            $mockSqlDefaultDatabaseLogPath = "C:\Program Files\Microsoft SQL Server\$($mockDefaultInstance_InstanceId)\MSSQL\DATA\"

            Context "When the system is not in the desired state" {
                BeforeEach {
                    $testParameters = $mockDefaultParameters.Clone()
                    $testParameters += @{
                        InstanceName = $mockCurrentInstanceName
                        SourcePath = $mockSourcePath
                    }

                    Mock -CommandName Get-NetFirewallRule -Verifiable
                    Mock -CommandName Get-NetFirewallApplicationFilter -Verifiable
                    Mock -CommandName Get-NetFirewallServiceFilter -Verifiable
                    Mock -CommandName Get-NetFirewallPortFilter -Verifiable
                    Mock -CommandName Get-Service -MockWith $mockGetService_DefaultInstance -Verifiable
                }

                It 'Should return $false from Test-TargetResource' {
                    $resultTestTargetResource = Test-TargetResource @testParameters
                    $resultTestTargetResource | Should -Be $false
                }
            }

            Context "When the system is in the desired state" {
                BeforeEach {
                    $testParameters = $mockDefaultParameters.Clone()
                    $testParameters += @{
                        InstanceName = $mockCurrentInstanceName
                        SourcePath = $mockSourcePath
                    }

                    Mock -CommandName Get-NetFirewallRule -MockWith $mockGetNetFirewallRule -Verifiable
                    Mock -CommandName Get-NetFirewallApplicationFilter -MockWith $mockGetNetFirewallApplicationFilter -Verifiable
                    Mock -CommandName Get-NetFirewallServiceFilter -MockWith $mockGetNetFirewallServiceFilter -Verifiable
                    Mock -CommandName Get-NetFirewallPortFilter -MockWith $mockGetNetFirewallPortFilter -Verifiable
                    Mock -CommandName Get-Service -MockWith $mockGetService_DefaultInstance -Verifiable
                }

                It 'Should return $true from Test-TargetResource' {
                    $resultTestTargetResource = Test-TargetResource @testParameters
                    $resultTestTargetResource | Should -Be $true
                }
            }
        }
   }
}
finally
{
    Invoke-TestCleanup
}
