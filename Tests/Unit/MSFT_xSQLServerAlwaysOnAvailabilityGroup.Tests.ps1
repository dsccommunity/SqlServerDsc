$script:DSCModuleName      = 'xSQLServer'
$script:DSCResourceName    = 'MSFT_xSQLServerAlwaysOnAvailabilityGroup'

# Unit Test Template Version: 1.1.0
[String] $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit

# Loading stub cmdlets
Import-Module -Name ( Join-Path -Path ( Join-Path -Path $PSScriptRoot -ChildPath Stubs ) -ChildPath SQLPSStub.psm1 ) -Force -Global
Add-Type -Path ( Join-Path -Path ( Join-Path -Path $PSScriptRoot -ChildPath Stubs ) -ChildPath SMO.cs )



# Begin Testing
try
{
    InModuleScope $script:DSCResourceName {

        #region mock server object variables

            $mockServer1Name = 'Server1'
            $mockServer1ServiceName = 'MSSQLSERVER'

            $mockServer2Name = 'Server2'
            $mockServer2ServiceName = 'MSSQLSERVER'

        #endregion mock server object variables

        #region mock availability group variables

            # Define the properties that are SQL 2016 and newer
            $sql13AvailabilityGroupProperties = @(
                'BasicAvailabilityGroup'
                'DatabaseHealthTrigger'
                'DtcSupportEnabled'
            )

            $mockAvailabilityGroupAbsentName = 'AbsentAvailabilityGroup'
            $mockAvailabilityGroupPresentName = 'NewAvailabilityGroup'

            $mockAvailabilityGroup1Name = 'AvailabilityGroup1'
            $mockAvailabilityGroup1BasicAvailabilityGroup = $false
            $mockAvailabilityGroup1DatabaseHealthTrigger = $false
            $mockAvailabilityGroup1DtcSupportEnabled = $false
            $mockAvailabilityGroup1AutomatedBackupPreference = 'Secondary'
            $mockAvailabilityGroup1FailureConditionLevel = 'OnCriticalServerErrors'
            $mockAvailabilityGroup1HealthCheckTimeout = 30000

            $mockAvailabilityReplica1Name = $mockServer1Name
            $mockAvailabilityReplica1AvailabilityMode = 'AsynchronousCommit'
            $mockAvailabilityReplica1BackupPriority = 50
            $mockAvailabilityReplica1ConnectionModeInPrimaryRole = 'AllowAllConnections'
            $mockAvailabilityReplica1ConnectionModeInSecondaryRole = 'AllowNoConnections'
            $mockAvailabilityReplica1EndpointHostName = $mockServer1Name
            $mockAvailabilityReplica1EndpointProtocol = 'TCP'
            $mockAvailabilityReplica1EndpointPort = 5022
            $mockAvailabilityReplica1FailoverMode = 'Manual'
            $mockAvailabilityReplica1Role = 'Primary'

        #endregion mock availability group variables

        $mockConnectSqlServer1 = {
            Param
            (
                [Parameter()]
                [string]
                $SQLServer,

                [Parameter()]
                [string]
                $SQLInstanceName
            )

            # Define the server object
            $mockServerObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server
            $mockServerObject.IsHadrEnabled = $mockIsHadrEnabled
            $mockServerObject.Name = $mockServer1Name
            $mockServerObject.NetName = $mockServer1Name
            $mockServerObject.ServiceName = $mockServer1ServiceName
            $mockServerObject.Version = @{
                Major = $Version
            }

            # Define the availability group 1 object
            $mockAvailabilityGroup1Object = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityGroup
            $mockAvailabilityGroup1Object.AutomatedBackupPreference = $mockAvailabilityGroup1AutomatedBackupPreference
            $mockAvailabilityGroup1Object.FailureConditionLevel = $mockAvailabilityGroup1FailureConditionLevel
            $mockAvailabilityGroup1Object.HealthCheckTimeout = $mockAvailabilityGroup1HealthCheckTimeout
            $mockAvailabilityGroup1Object.Name = $mockAvailabilityGroup1Name
            if ( $Version -ge 13 )
            {
                $mockAvailabilityGroup1Object.BasicAvailabilityGroup = $mockAvailabilityGroup1BasicAvailabilityGroup
                $mockAvailabilityGroup1Object.DatabaseHealthTrigger = $mockAvailabilityGroup1DatabaseHealthTrigger
                $mockAvailabilityGroup1Object.DtcSupportEnabled = $mockAvailabilityGroup1DtcSupportEnabled
            }

            # Define the availability replica 1 object
            $mockAvailabilityReplica1Object = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityReplica
            $mockAvailabilityReplica1Object.Name = $mockAvailabilityReplica1Name
            $mockAvailabilityReplica1Object.AvailabilityMode = $mockAvailabilityReplica1AvailabilityMode
            $mockAvailabilityReplica1Object.BackupPriority = $mockAvailabilityReplica1BackupPriority
            $mockAvailabilityReplica1Object.ConnectionModeInPrimaryRole = $mockAvailabilityReplica1ConnectionModeInPrimaryRole
            $mockAvailabilityReplica1Object.ConnectionModeInSecondaryRole = $mockAvailabilityReplica1ConnectionModeInSecondaryRole
            $mockAvailabilityReplica1Object.EndpointUrl = "$($mockAvailabilityReplica1EndpointProtocol)://$($mockAvailabilityReplica1EndpointHostName):$($mockAvailabilityReplica1EndpointPort)"
            $mockAvailabilityReplica1Object.FailoverMode = $mockAvailabilityReplica1FailoverMode
            $mockAvailabilityReplica1Object.Role = $mockAvailabilityReplica1Role

            # Add the availability group to the server object
            $mockAvailabilityGroup1Object.AvailabilityReplicas.Add($mockAvailabilityReplica1Object)
            $mockServerObject.AvailabilityGroups.Add($mockAvailabilityGroup1Object)

            # Add the master database
            <#
            $mockMasterDatabase = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Database
            $mockMasterDatabase.Name = 'master'
            $mockServerObject.Databases.Add($mockMasterDatabase)
            #>

            # Define the database mirroring endpoint object
            if ( $mockDatabaseMirroringEndpointPresent )
            {
                $mockDatabaseMirroringEndpoint = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Endpoint
                $mockDatabaseMirroringEndpoint.EndpointType = 'DatabaseMirroring'
                $mockDatabaseMirroringEndpoint.Protocol = @{
                    TCP = @{
                        ListenerPort = $mockAvailabilityReplica1EndpointPort
                    }
                }
                $mockServerObject.Endpoints.Add($mockDatabaseMirroringEndpoint)
            }

            # Add the login the cluster will use to authenticate to SQL Server
            <#
            $mockClusterLoginObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Login($mockClusterLoginName)
            $mockServerObject.Logins.Add($mockClusterLoginName,$mockClusterLoginObject)
            #>

            return $mockServerObject
        }

        $mockConnectSqlServer2 = {
            Param
            (
                [Parameter()]
                [string]
                $SQLServer,

                [Parameter()]
                [string]
                $SQLInstanceName
            )
        }

        $mockNewSqlAvailabilityReplica = {
            $mock = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityReplica
            $mock.Name = $mockAvailabilityReplica1Name
            $mock.AvailabilityMode = $mockAvailabilityReplica1AvailabilityMode
            $mock.BackupPriority = $mockAvailabilityReplica1BackupPriority
            $mock.ConnectionModeInPrimaryRole = $mockAvailabilityReplica1ConnectionModeInPrimaryRole
            $mock.ConnectionModeInSecondaryRole = $mockAvailabilityReplica1ConnectionModeInSecondaryRole
            $mock.EndpointUrl = "$($mockAvailabilityReplica1EndpointProtocol)://$($mockAvailabilityReplica1EndpointHostName):$($mockAvailabilityReplica1EndpointPort)"
            $mock.FailoverMode = $mockAvailabilityReplica1FailoverMode
            $mock.Role = $mockAvailabilityReplica1Role

            return $mock
        }

        #region configuration parameters
            $getTargetResourceParameters = @{
                SQLServer = $mockServer1Name
                SQLInstanceName = $mockServer1ServiceName
            }

            $mockResourceParameters = @{
                Name = $mockAvailabilityGroup1Name
                SQLServer = $mockServer1Name
                SQLInstanceName = $mockServer1ServiceName
                AutomatedBackupPreference = $mockAvailabilityGroup1AutomatedBackupPreference
                AvailabilityMode = $mockAvailabilityReplica1AvailabilityMode
                BackupPriority = $mockAvailabilityReplica1BackupPriority
                BasicAvailabilityGroup = $mockAvailabilityGroup1BasicAvailabilityGroup
                DatabaseHealthTrigger = $mockAvailabilityGroup1DatabaseHealthTrigger
                DtcSupportEnabled = $mockAvailabilityGroup1DtcSupportEnabled
                EndpointHostName = $mockServer1Name
                Ensure = 'Present'
                ConnectionModeInPrimaryRole = $mockAvailabilityReplica1ConnectionModeInPrimaryRole
                ConnectionModeInSecondaryRole = $mockAvailabilityReplica1ConnectionModeInSecondaryRole
                FailureConditionLevel = $mockAvailabilityGroup1FailureConditionLevel
                HealthCheckTimeout = $mockAvailabilityGroup1HealthCheckTimeout
            }
        #endregion configuration parameters

        Describe 'xSQLServerAlwaysOnAvailabilityGroup\Get-TargetResource' {
            BeforeAll {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlServer1 -Verifiable -ParameterFilter { $SQLServer -eq $mockServer1Name }
                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlServer2 -Verifiable -ParameterFilter { $SQLServer -eq $mockServer2Name }

                $mockDatabaseMirroringEndpointPresent = $true

                #region test cases
                    $absentTestCases = @(
                        @{
                            Name =$mockAvailabilityGroupAbsentName
                            Version = 12
                        },
                        @{
                            Name =$mockAvailabilityGroupAbsentName
                            Version = 13
                        }
                    )

                    $presentTestCases = @(
                        @{
                            Ensure = 'Present'
                            Name =$mockAvailabilityGroup1Name
                            Version = 12
                        },
                        @{
                            Ensure = 'Present'
                            Name =$mockAvailabilityGroup1Name
                            Version = 13
                        },
                        @{
                            Ensure = 'Absent'
                            Name =$mockAvailabilityGroup1Name
                            Version = 12
                        },
                        @{
                            Ensure = 'Absent'
                            Name =$mockAvailabilityGroup1Name
                            Version = 13
                        }
                    )
                #endregion test cases
            }

            Context 'When the Availability Group is Absent'{

                It 'Should not return an Availability Group when Ensure is set to Present and the SQL version is <Version>' -TestCases $absentTestCases {
                    param
                    (
                        $Name,
                        $Version
                    )

                    $result = Get-TargetResource @getTargetResourceParameters -Name $Name
                    $result.Ensure | Should Be 'Absent'

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $SQLServer -eq $mockServer1Name }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 0 -Exactly -ParameterFilter { $SQLServer -eq $mockServer2Name }
                }
            }

            Context 'When the Availability Group is Present'{
                It 'Should return the correct Availability Group properties when Ensure is set to <Ensure> and the SQL version is <Version>' -TestCases $presentTestCases {
                    param
                    (
                        $Ensure,
                        $Name,
                        $Version
                    )

                    $result = Get-TargetResource @getTargetResourceParameters -Name $Name

                    $result.Name | Should Be $mockAvailabilityGroup1Name
                    $result.SQLServer | Should Be $getTargetResourceParameters.SQLServer
                    $result.SQLInstanceName | Should Be $getTargetResourceParameters.SQLInstanceName
                    $result.Ensure | Should Be 'Present'
                    $result.AutomatedBackupPreference | Should Be $mockAvailabilityGroup1AutomatedBackupPreference
                    $result.AvailabilityMode | Should Be $mockAvailabilityReplica1AvailabilityMode
                    $result.BackupPriority | Should Be $mockAvailabilityReplica1BackupPriority
                    $result.ConnectionModeInPrimaryRole | Should Be $mockAvailabilityReplica1ConnectionModeInPrimaryRole
                    $result.ConnectionModeInSecondaryRole | Should Be $mockAvailabilityReplica1ConnectionModeInSecondaryRole
                    #result.EndpointURL #### Need this as well!
                    $result.FailureConditionLevel | Should Be $mockAvailabilityGroup1FailureConditionLevel
                    $result.FailoverMode | Should Be $mockAvailabilityReplica1FailoverMode
                    $result.HealthCheckTimeout | Should Be $mockAvailabilityGroup1HealthCheckTimeout

                    if ( $Version -ge 13 )
                    {
                        $result.BasicAvailabilityGroup | Should Be $mockAvailabilityGroup1BasicAvailabilityGroup
                        $result.DatabaseHealthTrigger | Should Be $mockAvailabilityGroup1DatabaseHealthTrigger
                        $result.DtcSupportEnabled | Should Be $mockAvailabilityGroup1DtcSupportEnabled
                    }
                    else
                    {
                        $result.BasicAvailabilityGroup | Should BeNullOrEmpty
                        $result.DatabaseHealthTrigger | Should BeNullOrEmpty
                        $result.DtcSupportEnabled | Should BeNullOrEmpty
                    }

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }
            }
        }

        Describe 'xSQLServerAlwaysOnAvailabilityGroup\Set-TargetResource' {

            Context 'When the Availability Group is Absent' {
                BeforeAll {
                    Mock -CommandName Connect-SQL -MockWith $mockConnectSqlServer1 -Verifiable -ParameterFilter { $SQLServer -eq $mockServer1Name }
                    Mock -CommandName Connect-SQL -MockWith $mockConnectSqlServer2 -Verifiable -ParameterFilter { $SQLServer -eq $mockServer2Name }
                    Mock -CommandName Invoke-Query -MockWith {} -Verifiable
                    Mock -CommandName Import-SQLPSModule -MockWith {} -Verifiable
                    Mock -CommandName New-SqlAvailabilityGroup {} -Verifiable -ParameterFilter { $Name -eq $mockAvailabilityGroupPresentName }
                    Mock -CommandName New-SqlAvailabilityReplica -MockWith $mockNewSqlAvailabilityReplica -Verifiable
                    Mock -CommandName New-TerminatingError -MockWith { $ErrorType } -Verifiable
                    Mock -CommandName Remove-SqlAvailabilityGroup -MockWith {} -Verifiable
                    Mock -CommandName Test-ClusterPermissions -MockWith { $mockClusterPermissionsExist } -Verifiable
                    Mock -CommandName Update-AvailabilityGroup -MockWith {} -Verifiable
                    Mock -CommandName Update-AvailabilityGroupReplica -MockWith {} -Verifiable

                    #region test cases
                        $versionsToTest = @(12,13)
                        $loginsToTest = @('NT SERVICE\ClusSvc','NT AUTHORITY\System')

                        $createAvailabilityGroupTestCases = $versionsToTest | ForEach-Object -Process {
                            $versionToTest = $_

                            return @{
                                Name = $mockAvailabilityGroupPresentName
                                Version = $versionToTest
                            }
                        }
                    #endregion test cases
                }

                BeforeEach{
                    $mockClusterPermissionsExist = $true
                    $mockDatabaseMirroringEndpointPresent = $true
                    $mockIsHadrEnabled = $true
                }

                It 'Should create the Availability Group when Ensure is set to Present and the SQL version is "<Version>"' -TestCases $createAvailabilityGroupTestCases {
                    param
                    (
                        $Name,
                        $Version
                    )

                    $currentTestParameters = $mockResourceParameters.Clone()
                    $currentTestParameters.Name = $Name

                    { Set-TargetResource @currentTestParameters } | Should Not Throw

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $SQLServer -eq $mockServer1Name }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 0 -Exactly -ParameterFilter { $SQLServer -eq $mockServer2Name }
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 1 -Exactly -ParameterFilter { $Name -eq $mockAvailabilityGroupPresentName }
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ClusterPermissions -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }

                It 'Should throw the correct error "HadrNotEnabled" when Ensure is set to Present, but Always On is not enabled' {

                    $mockIsHadrEnabled = $false

                    { Set-TargetResource @mockResourceParameters } | Should Throw 'HadrNotEnabled'

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly -ParameterFilter { $Name -eq $mockAvailabilityGroupPresentName }
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ClusterPermissions -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }

                It 'Should throw the correct error "DatabaseMirroringEndpointNotFound" when Ensure is set to Present, but no DatabaseMirroring endpoints are present' {

                    $mockDatabaseMirroringEndpointPresent = $false

                    { Set-TargetResource @mockResourceParameters } | Should Throw 'DatabaseMirroringEndpointNotFound'

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly -ParameterFilter { $Name -eq $mockAvailabilityGroupPresentName }
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ClusterPermissions -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }



                It 'Should throw the correct error, CreateAvailabilityGroupReplicaFailed, when Ensure is set to Present, but the Availability Group Replica failed to create and the SQL version is 12' {

                    { Set-TargetResource @defaultAbsentParameters } | Should Throw 'CreateAvailabilityGroupReplicaFailed'

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly -ParameterFilter { $Name -eq $mockAvailabilityGroupPresentName }
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ClusterPermissions -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }

                It 'Should throw the correct error, CreateAvailabilityGroupReplicaFailed, when Ensure is set to Present, but the Availability Group Replica failed to create and the SQL version is 13' {

                    { Set-TargetResource @defaultAbsentParameters } | Should Throw 'CreateAvailabilityGroupReplicaFailed'

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ClusterPermissions -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }



                It 'Should throw the correct error "CreateAvailabilityGroupFailed" when Ensure is set to Present, but the Availability Group failed to create and the SQL version is 12' {

                    { Set-TargetResource @defaultAbsentParameters } | Should Throw 'CreateAvailabilityGroupFailed'

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ClusterPermissions -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }

                It 'Should throw the correct error "CreateAvailabilityGroupFailed" when Ensure is set to Present, but the Availability Group failed to create and the SQL version is 13' {

                    { Set-TargetResource @defaultAbsentParameters } | Should Throw 'CreateAvailabilityGroupFailed'

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ClusterPermissions -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }
            }

            Context 'When the Availability Group is Present' {

                It 'Should remove the Availability Group when Ensure is set to Absent and the SQL version is 12' {

                    { Set-TargetResource @defaultPresentParameters } | Should Not Throw

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Test-ClusterPermissions -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }

                It 'Should remove the Availability Group when Ensure is set to Absent and the SQL version is 13' {

                    { Set-TargetResource @defaultPresentParameters } | Should Not Throw

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Invoke-Query -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Test-ClusterPermissions -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }

                It 'Should throw the correct error message, InstanceNotPrimaryReplica, when Ensure is set to Absent and the primary replica is not on the current instance' {

                    { Set-TargetResource @defaultPresentParameters } | Should Throw 'InstanceNotPrimaryReplica'

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ClusterPermissions -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }

                It 'Should throw the correct error message when Ensure is set to Absent but the Availability Group remove fails, and the SQL version is 12' {

                    { Set-TargetResource @defaultPresentParameters } | Should Throw 'RemoveAvailabilityGroupFailed'

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Test-ClusterPermissions -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }

                It 'Should throw the correct error message when Ensure is set to Absent but the Availability Group remove fails, and the SQL version is 13' {

                    { Set-TargetResource @defaultPresentParameters } | Should Throw 'RemoveAvailabilityGroupFailed'

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Test-ClusterPermissions -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }

                It 'Should connect to the instance hosting the primary replica when the LocalReplicaRole is not Primary' {

                    { Set-TargetResource @defaultPresentParametersIncorrectProperties } | Should Not Throw

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $SQLServer -eq 'Server2' }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 0 -Exactly -ParameterFilter { $Query -match 'NT SERVICE\\ClusSvc' }
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ClusterPermissions -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 1 -Exactly
                }

                It 'Should set the AutomatedBackupPreference to the desired state' {

                    { Set-TargetResource @defaultPresentParametersIncorrectProperties } | Should Not Throw

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ClusterPermissions -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly

                    $mockConnectSqlVersion12ServerObject.AvailabilityGroups['PresentAG'].AutomatedBackupPreference = $defaultPresentParameters.AutomatedBackupPreference
                }

                It 'Should set the AvailabilityMode to the desired state' {

                    { Set-TargetResource @defaultPresentParametersIncorrectProperties } | Should Not Throw

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ClusterPermissions -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 1 -Exactly

                    $mockConnectSqlVersion12ServerObject.AvailabilityGroups['PresentAG'].AvailabilityReplicas['Server1'].AvailabilityMode = $defaultPresentParameters.AvailabilityMode
                }

                It 'Should set the BackupPriority to the desired state' {

                    { Set-TargetResource @defaultPresentParametersIncorrectProperties } | Should Not Throw

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ClusterPermissions -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 1 -Exactly

                    $mockConnectSqlVersion12ServerObject.AvailabilityGroups['PresentAG'].AvailabilityReplicas['Server1'].BackupPriority = $defaultPresentParameters.BackupPriority
                }

                It 'Should set the BasicAvailabilityGroup to the desired state' {

                    { Set-TargetResource @defaultPresentParametersIncorrectProperties } | Should Not Throw

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ClusterPermissions -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly

                    $mockConnectSqlVersion13ServerObject.AvailabilityGroups['PresentAG'].BasicAvailabilityGroup = $defaultPresentParameters.BasicAvailabilityGroup
                }

                It 'Should set the DatabaseHealthTrigger to the desired state' {

                    { Set-TargetResource @defaultPresentParametersIncorrectProperties } | Should Not Throw

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ClusterPermissions -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly

                    $mockConnectSqlVersion13ServerObject.AvailabilityGroups['PresentAG'].DatabaseHealthTrigger = $defaultPresentParameters.DatabaseHealthTrigger
                }

                It 'Should not set the DtcSupportEnabled to the desired state' {

                    { Set-TargetResource @defaultPresentParametersIncorrectProperties } | Should Not Throw

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ClusterPermissions -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly

                    $mockConnectSqlVersion13ServerObject.AvailabilityGroups['PresentAG'].DtcSupportEnabled = $defaultPresentParameters.DtcSupportEnabled
                }

                It 'Should set the ConnectionModeInPrimaryRole to the desired state' {

                    { Set-TargetResource @defaultPresentParametersIncorrectProperties } | Should Not Throw

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ClusterPermissions -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 1 -Exactly

                    $mockConnectSqlVersion12ServerObject.AvailabilityGroups['PresentAG'].AvailabilityReplicas['Server1'].ConnectionModeInPrimaryRole = $defaultPresentParameters.ConnectionModeInPrimaryRole
                    $mockConnectSqlVersion13ServerObject.AvailabilityGroups['PresentAG'].AvailabilityReplicas['Server1'].ConnectionModeInPrimaryRole = $defaultPresentParameters.ConnectionModeInPrimaryRole
                }

                It 'Should set the ConnectionModeInSecondaryRole to the desired state' {

                    { Set-TargetResource @defaultPresentParametersIncorrectProperties } | Should Not Throw

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ClusterPermissions -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 1 -Exactly

                    $mockConnectSqlVersion12ServerObject.AvailabilityGroups['PresentAG'].AvailabilityReplicas['Server1'].ConnectionModeInSecondaryRole = $defaultPresentParameters.ConnectionModeInSecondaryRole
                }

                It 'Should set the EndpointUrl to the desired state when the endpoint port is changed' {

                    { Set-TargetResource @defaultPresentParametersIncorrectProperties } | Should Not Throw

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ClusterPermissions -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 1 -Exactly
                }

                It 'Should set the EndpointUrl to the desired state when the EndpointHostName is specified' {

                    { Set-TargetResource @defaultPresentParametersIncorrectProperties } | Should Not Throw

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ClusterPermissions -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 1 -Exactly
                }

                It 'Should set the EndpointUrl to the desired state when the EndpointHostName is not specified' {

                    { Set-TargetResource @defaultPresentParametersIncorrectProperties } | Should Not Throw

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ClusterPermissions -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 1 -Exactly
                }

                It 'Should set the EndpointUrl to the desired state when the endpoint protocol is changed' {

                    { Set-TargetResource @defaultPresentParametersIncorrectProperties } | Should Not Throw

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ClusterPermissions -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 1 -Exactly
                }

                It 'Should set the FailureConditionLevel to the desired state' {

                    { Set-TargetResource @defaultPresentParametersIncorrectProperties } | Should Not Throw

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ClusterPermissions -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }

                It 'Should set the FailoverMode to the desired state' {

                    { Set-TargetResource @defaultPresentParametersIncorrectProperties } | Should Not Throw

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ClusterPermissions -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 1 -Exactly
                }

                It 'Should set the HealthCheckTimeout to the desired state' {

                    { Set-TargetResource @defaultPresentParametersIncorrectProperties } | Should Not Throw

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ClusterPermissions -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }
            }
        }

        Describe "xSQLServerAlwaysOnAvailabilityGroup\Test-TargetResource" {
            BeforeAll {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlServer1 -Verifiable -ParameterFilter { $SQLServer -eq $mockServer1Name }
                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlServer2 -Verifiable -ParameterFilter { $SQLServer -eq $mockServer2Name }

                $mockDatabaseMirroringEndpointPresent = $true

                #region test cases
                    $versionsToTest = @(12,13)
                    $absentTestCases = @(
                        @{
                            Ensure = 'Present'
                            Name = $mockAvailabilityGroupAbsentName
                            Result = $false
                            Version = 12
                        },
                        @{
                            Ensure = 'Present'
                            Name = $mockAvailabilityGroupAbsentName
                            Result = $false
                            Version = 13
                        },
                        @{
                            Ensure = 'Absent'
                            Name = $mockAvailabilityGroupAbsentName
                            Result = $true
                            Version = 12
                        },
                        @{
                            Ensure = 'Absent'
                            Name = $mockAvailabilityGroupAbsentName
                            Result = $true
                            Version = 13
                        }
                    )

                    $presentTestCases = @(
                        @{
                            Ensure = 'Present'
                            Name =$mockAvailabilityGroup1Name
                            Result = $true
                            Version = 12
                        },
                        @{
                            Ensure = 'Present'
                            Name =$mockAvailabilityGroup1Name
                            Result = $true
                            Version = 13
                        },
                        @{
                            Ensure = 'Absent'
                            Name =$mockAvailabilityGroup1Name
                            Result = $false
                            Version = 12
                        },
                        @{
                            Ensure = 'Absent'
                            Name =$mockAvailabilityGroup1Name
                            Result = $false
                            Version = 13
                        }
                    )

                    [array]$presentParameterTestCases = $versionsToTest | ForEach-Object -Process {
                        $versionToTest = $_

                        $mockResourceParameters.GetEnumerator() | ForEach-Object -Process {
                            if ( @('Name','SQLServer','SQLInstanceName','DtcSupportEnabled') -notcontains $_.Key )
                            {
                                $currentParameter = $_.Key

                                # Move on if we're testing a version less than 13 and it's a property that was only introduced in 13
                                if ( ( $sql13AvailabilityGroupProperties -contains $currentParameter ) -and ( $versionToTest -lt 13 ) )
                                {
                                    # Move to the next parameter
                                    return
                                }

                                # Get the current parameter object
                                $currentParameterObject = ( Get-Command Test-TargetResource ).Parameters.$currentParameter

                                switch ( $currentParameterObject.ParameterType.ToString() )
                                {
                                    'System.Boolean'
                                    {
                                        # Get the opposite value of what is supplied
                                        $testCaseParameterValue = -not $mockResourceParameters.$currentParameter
                                    }

                                    'System.UInt32'
                                    {
                                        # Change the supplied number to something else. Absolute value is to protect against zero minus 1
                                        $testCaseParameterValue = [System.Math]::Abs( ( $mockResourceParameters.$currentParameter -1 ) )
                                    }

                                    'System.String'
                                    {
                                        # Get the valid values for the current parameter
                                        $currentParameterValidValues = $currentParameterObject.Attributes.ValidValues

                                        # Select a value other than what is defined in the mocks
                                        $testCaseParameterValue = $currentParameterValidValues | Where-Object -FilterScript { $_ -ne $mockResourceParameters.$currentParameter } | Select-Object -First 1

                                        # If the value is null or empty, set it to something
                                        if ( [string]::IsNullOrEmpty($testCaseParameterValue) )
                                        {
                                            $testCaseParameterValue = 'IncorrectValue'
                                        }
                                    }

                                    default
                                    {
                                        $testCaseParameterValue = $null
                                    }
                                }

                                return @{
                                    Ensure = 'Present'
                                    Result = $false
                                    Parameter = $currentParameter
                                    ParameterValue = $testCaseParameterValue
                                    Version = $versionToTest
                                }
                            }
                        }
                    }
                #endregion test cases
            }

            Context 'When the Availability Group is Absent' {

                It 'Should be "<Result>" when the desired state is "<Ensure>" and the SQL version is "<Version>"' -TestCases $absentTestCases {
                    param
                    (
                        $Ensure,
                        $Name,
                        $Result,
                        $Version
                    )

                    $currentTestParameters = $mockResourceParameters.Clone()
                    $currentTestParameters.Ensure = $Ensure
                    $currentTestParameters.Name = $Name

                    Test-TargetResource @currentTestParameters | Should Be $Result

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $SQLServer -eq $mockServer1Name }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 0 -Exactly -ParameterFilter { $SQLServer -eq $mockServer2Name }
                }
            }

            Context 'When the Availability Group is Present' {

                It 'Should be "<Result>" when the desired state is "<Ensure>" and the SQL version is "<Version>"' -TestCases $presentTestCases {
                    param
                    (
                        $Ensure,
                        $Name,
                        $Result,
                        $Version
                    )

                    $currentTestParameters = $mockResourceParameters.Clone()
                    $currentTestParameters.Ensure = $Ensure
                    $currentTestParameters.Name = $Name

                    Test-TargetResource @currentTestParameters | Should Be $Result

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $SQLServer -eq $mockServer1Name }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 0 -Exactly -ParameterFilter { $SQLServer -eq $mockServer2Name }
                }

                It 'Should be "<Result>" when the desired state is "<Ensure>", the parameter "<Parameter>" is not "<ParameterValue>", and the SQL version is "<Version>"' -TestCases $presentParameterTestCases {
                    param
                    (
                        $Ensure,
                        $Result,
                        $Parameter,
                        $ParameterValue,
                        $Version
                    )

                    $currentTestParameters = $mockResourceParameters.Clone()
                    $currentTestParameters.$Parameter = $ParameterValue

                    Test-TargetResource @currentTestParameters | Should Be $Result

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $SQLServer -eq $mockServer1Name }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 0 -Exactly -ParameterFilter { $SQLServer -eq $mockServer2Name }
                }

                <#It 'Should be $true when the desired state is Present and the Endpoint Host Name is not specified' {

                    $currentTestParameters = $mockResourceParameters.Clone()
                    $currentTestParameters.Remove('EndpointHostName')

                    Test-TargetResource @currentTestParameters | Should Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $SQLServer -eq $mockServer1Name }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 0 -Exactly -ParameterFilter { $SQLServer -eq $mockServer2Name }
                }

                It 'Should be $false when the desired state is Present and the Endpoint Hostname is incorrectly configured' {

                    Test-TargetResource @defaultPresentParametersIncorrectParameter | Should Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }

                It 'Should be $false when the desired state is Present and the Endpoint Protocol is incorrectly configured' {

                    Test-TargetResource @defaultPresentParametersIncorrectParameter | Should Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }

                It 'Should be $false when the desired state is Present and the Endpoint Port is incorrectly configured' {

                    Test-TargetResource @defaultPresentParametersIncorrectParameter | Should Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }#>
            }
        }

        Describe "xSQLServerAlwaysOnAvailabilityGroup\Update-AvailabilityGroup" {
            BeforeAll {
                Mock -CommandName New-TerminatingError -MockWith { $ErrorType }

                $mockAvailabilityGroup = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityGroup
            }

            Context 'When the Availability Group is altered' {
                It 'Should silently alter the Availability Group' {

                    { Update-AvailabilityGroup -AvailabilityGroup $mockAvailabilityGroup } | Should Not Throw

                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                }

                It 'Should throw the correct error, AlterAvailabilityGroupFailed, when altering the Availaiblity Group fails' {

                    $mockAvailabilityGroup.Name = 'AlterFailed'

                    { Update-AvailabilityGroup -AvailabilityGroup $mockAvailabilityGroup } | Should Throw 'AlterAvailabilityGroupFailed'

                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                }
            }
        }
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}
