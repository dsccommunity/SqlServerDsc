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

            # The following will be set dynamically during tests
            $mockAvailabilityGroupName = ''
            $mockAvailabilityReplicaEndpointProtocol = ''
            $mockAvailabilityReplicaEndpointPort = 0
            $mockDatabaseMirroringEndpointProtocol = ''
            $mockDatabaseMirroringEndpointPort = 0

            $mockAvailabilityGroupAbsentName = 'AbsentAvailabilityGroup'
            $mockAvailabilityGroupCreateErrorName = 'ErrorCreateAvailabilityGroup'
            $mockAvailabilityGroupPresentName = 'NewAvailabilityGroup'
            $mockAvailabilityGroupRemoveErrorName = 'ErrorRemoveAvailabilityGroup'
            $mockAvailabilityGroupReplicaAbsentName = $mockServer2Name
            $mockAvailabilityGroupReplicaPresentName = $mockServer1Name

            $mockAvailabilityGroup1Name = 'AvailabilityGroup1'
            $mockAvailabilityGroup1BasicAvailabilityGroup = $false
            $mockAvailabilityGroup1DatabaseHealthTrigger = $false
            $mockAvailabilityGroup1DtcSupportEnabled = $false
            $mockAvailabilityGroup1AutomatedBackupPreference = 'Secondary'
            $mockAvailabilityGroup1FailureConditionLevel = 'OnCriticalServerErrors'
            $mockAvailabilityGroup1HealthCheckTimeout = 30000
            $mockAvailabilityGroup1PrimaryReplicaServerName = $mockServer1Name

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

            $mockAvailabilityReplica2Name = $mockServer2Name
            $mockAvailabilityReplica2AvailabilityMode = 'AsynchronousCommit'
            $mockAvailabilityReplica2BackupPriority = 50
            $mockAvailabilityReplica2ConnectionModeInPrimaryRole = 'AllowAllConnections'
            $mockAvailabilityReplica2ConnectionModeInSecondaryRole = 'AllowNoConnections'
            $mockAvailabilityReplica2EndpointHostName = $mockServer2Name
            $mockAvailabilityReplica2EndpointProtocol = 'TCP'
            $mockAvailabilityReplica2EndpointPort = 5022
            $mockAvailabilityReplica2FailoverMode = 'Manual'
            $mockAvailabilityReplica2Role = 'Primary'

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
            $mockAvailabilityGroup1Object.Name = $mockAvailabilityGroupName
            $mockAvailabilityGroup1Object.PrimaryReplicaServerName = $mockAvailabilityGroup1PrimaryReplicaServerName
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
            $mockAvailabilityReplica1Object.BackupPriority = $mockAvailabilityReplica2BackupPriority
            $mockAvailabilityReplica1Object.ConnectionModeInPrimaryRole = $mockAvailabilityReplica1ConnectionModeInPrimaryRole
            $mockAvailabilityReplica1Object.ConnectionModeInSecondaryRole = $mockAvailabilityReplica1ConnectionModeInSecondaryRole
            $mockAvailabilityReplica1Object.EndpointUrl = "$($mockAvailabilityReplicaEndpointProtocol)://$($mockAvailabilityReplica1EndpointHostName):$($mockAvailabilityReplicaEndpointPort)"
            $mockAvailabilityReplica1Object.FailoverMode = $mockAvailabilityReplica1FailoverMode
            $mockAvailabilityReplica1Object.Role = $mockAvailabilityReplica1Role

            # Define the availability replica 2 object
            $mockAvailabilityReplica2Object = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityReplica
            $mockAvailabilityReplica2Object.Name = $mockAvailabilityReplica2Name
            $mockAvailabilityReplica2Object.AvailabilityMode = $mockAvailabilityReplica2AvailabilityMode
            $mockAvailabilityReplica2Object.BackupPriority = $mockAvailabilityReplica1BackupPriority
            $mockAvailabilityReplica2Object.ConnectionModeInPrimaryRole = $mockAvailabilityReplica2ConnectionModeInPrimaryRole
            $mockAvailabilityReplica2Object.ConnectionModeInSecondaryRole = $mockAvailabilityReplica2ConnectionModeInSecondaryRole
            $mockAvailabilityReplica2Object.EndpointUrl = "$($mockAvailabilityReplica2EndpointProtocol)://$($mockAvailabilityReplica2EndpointHostName):$($mockAvailabilityReplica2EndpointPort)"
            $mockAvailabilityReplica2Object.FailoverMode = $mockAvailabilityReplica2FailoverMode
            $mockAvailabilityReplica2Object.Role = $mockAvailabilityReplica2Role

            # Add the availability group to the server object
            $mockAvailabilityGroup1Object.AvailabilityReplicas.Add($mockAvailabilityReplica1Object)
            $mockAvailabilityGroup1Object.AvailabilityReplicas.Add($mockAvailabilityReplica2Object)
            $mockServerObject.AvailabilityGroups.Add($mockAvailabilityGroup1Object)

            # Define the database mirroring endpoint object
            if ( $mockDatabaseMirroringEndpointPresent )
            {
                $mockDatabaseMirroringEndpoint = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Endpoint
                $mockDatabaseMirroringEndpoint.EndpointType = 'DatabaseMirroring'
                $mockDatabaseMirroringEndpoint.Protocol = @{
                    $mockDatabaseMirroringEndpointProtocol = @{
                        ListenerPort = $mockDatabaseMirroringEndpointPort
                    }
                }
                $mockServerObject.Endpoints.Add($mockDatabaseMirroringEndpoint)
            }

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

            # Define the server object
            $mockServerObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server
            $mockServerObject.IsHadrEnabled = $mockIsHadrEnabled
            $mockServerObject.Name = $mockServer2Name
            $mockServerObject.NetName = $mockServer2Name
            $mockServerObject.ServiceName = $mockServer2ServiceName
            $mockServerObject.Version = @{
                Major = $Version
            }

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

            # Define the availability group 1 object
            $mockAvailabilityGroup1Object = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityGroup
            $mockAvailabilityGroup1Object.AutomatedBackupPreference = $mockAvailabilityGroup1AutomatedBackupPreference
            $mockAvailabilityGroup1Object.FailureConditionLevel = $mockAvailabilityGroup1FailureConditionLevel
            $mockAvailabilityGroup1Object.HealthCheckTimeout = $mockAvailabilityGroup1HealthCheckTimeout
            $mockAvailabilityGroup1Object.Name = $mockAvailabilityGroupName
            $mockAvailabilityGroup1Object.LocalReplicaRole = 'Secondary'
            $mockAvailabilityGroup1Object.PrimaryReplicaServerName = $mockAvailabilityGroup1PrimaryReplicaServerName
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
            $mockAvailabilityReplica1Object.EndpointUrl = "$($mockAvailabilityReplicaEndpointProtocol)://$($mockAvailabilityReplica1EndpointHostName):$($mockAvailabilityReplica1EndpointPort)"
            $mockAvailabilityReplica1Object.FailoverMode = $mockAvailabilityReplica1FailoverMode
            $mockAvailabilityReplica1Object.Role = $mockAvailabilityReplica1Role

            # Add the availability group to the server object
            $mockAvailabilityGroup1Object.AvailabilityReplicas.Add($mockAvailabilityReplica1Object)
            $mockServerObject.AvailabilityGroups.Add($mockAvailabilityGroup1Object)

            return $mockServerObject
        }

        $mockNewSqlAvailabilityReplica = {
            $mock = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityReplica
            $mock.Name = $mockAvailabilityReplica1Name
            $mock.AvailabilityMode = $mockAvailabilityReplica1AvailabilityMode
            $mock.BackupPriority = $mockAvailabilityReplica1BackupPriority
            $mock.ConnectionModeInPrimaryRole = $mockAvailabilityReplica1ConnectionModeInPrimaryRole
            $mock.ConnectionModeInSecondaryRole = $mockAvailabilityReplica1ConnectionModeInSecondaryRole
            $mock.EndpointUrl = "$($mockAvailabilityReplicaEndpointProtocol)://$($mockAvailabilityReplica1EndpointHostName):$($mockAvailabilityReplicaEndpointPort)"
            $mock.FailoverMode = $mockAvailabilityReplica1FailoverMode
            $mock.Role = $mockAvailabilityReplica1Role

            return $mock
        }

        # Mock the Update-AvailabilityGroup function to ensure the specified property was set correctly
        $mockUpdateAvailabiltyGroup = {
            param
            (
                [Parameter()]
                [Microsoft.SqlServer.Management.Smo.AvailabilityGroup]
                $AvailabilityGroup
            )

            # If the current value of the property that was set is not equal to the desired value
            if ( $ParameterValue -ne $AvailabilityGroup.$Parameter )
            {
                $AvailabilityGroup | Get-Member -MemberType Property | Select-Object -ExpandProperty Name | ForEach-Object -Process {
                    $currentProperty = $_

                    Write-Verbose -Message "The property '$($currentProperty)' value is '$($AvailabilityGroup.$Parameter)' but should be '$($ParameterValue)'." -Verbose
                }

                throw "Update-AvailabilityGroup should be setting the property '$($Parameter)' to '$($ParameterValue)'."
            }
        }

        # Mock the Update-AvailabilityGroupReplica function to ensure the specified property was set correctly
        $mockUpdateAvailabiltyGroupReplica = {
            param
            (
                [Parameter()]
                [Microsoft.SqlServer.Management.Smo.AvailabilityReplica]
                $AvailabilityGroupReplica
            )

            if ( [string]::IsNullOrEmpty($Parameter) -and [string]::IsNullOrEmpty($ParameterValue) )
            {
                return
            }

            # Some parameters don't align directly with a property
            switch ( $Parameter )
            {
                EndpointHostName
                {
                    $validatedParameter = 'EndpointUrl'
                    $validatedParameterValue = "$($mockAvailabilityReplicaEndpointProtocol)://$($ParameterValue):$($mockAvailabilityReplicaEndpointPort)"
                }

                default
                {
                    $validatedParameter = $Parameter
                    $validatedParameterValue = $ParameterValue
                }
            }

            # If the current value of the property that was set is not equal to the desired value
            if ( $validatedParameterValue -ne $AvailabilityGroupReplica.$validatedParameter )
            {
                $AvailabilityGroupReplica | Get-Member -MemberType Property | Select-Object -ExpandProperty Name | ForEach-Object -Process {
                    $currentProperty = $_

                    Write-Verbose -Message "The property '$($currentProperty)' value is '$($AvailabilityGroupReplica.$validatedParameter)' but should be '$($validatedParameterValue)'." -Verbose
                }

                throw "Update-AvailabilityGroupReplica should be setting the property '$($validatedParameter)' to '$($validatedParameterValue)'."
            }
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
                FailoverMode = $mockAvailabilityReplica1FailoverMode
                HealthCheckTimeout = $mockAvailabilityGroup1HealthCheckTimeout
            }
        #endregion configuration parameters

        Describe 'xSQLServerAlwaysOnAvailabilityGroup\Get-TargetResource' {
            BeforeAll {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlServer1 -Verifiable -ParameterFilter { $SQLServer -eq $mockServer1Name }
                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlServer2 -Verifiable -ParameterFilter { $SQLServer -eq $mockServer2Name }

                $mockAvailabilityGroupName = $mockAvailabilityGroup1Name
                $mockAvailabilityReplicaEndpointPort = 5022
                $mockAvailabilityReplicaEndpointProtocol = $mockAvailabilityReplica1EndpointProtocol
                $mockDatabaseMirroringEndpointPresent = $true
                $mockDatabaseMirroringEndpointProtocol = 'TCP'
                $mockDatabaseMirroringEndpointPort = 5022

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
            BeforeAll {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlServer1 -Verifiable -ParameterFilter { $SQLServer -eq $mockServer1Name }
                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlServer2 -Verifiable -ParameterFilter { $SQLServer -eq $mockServer2Name }
                Mock -CommandName Invoke-Query -MockWith {} -Verifiable
                Mock -CommandName Import-SQLPSModule -MockWith {} -Verifiable
                Mock -CommandName New-SqlAvailabilityGroup {} -Verifiable -ParameterFilter { $Name -eq $mockAvailabilityGroupPresentName }
                Mock -CommandName New-SqlAvailabilityGroup { throw 'CreateAvailabilityGroupFailed' } -Verifiable -ParameterFilter { $Name -eq $mockAvailabilityGroupCreateErrorName }
                Mock -CommandName New-SqlAvailabilityReplica -MockWith $mockNewSqlAvailabilityReplica -Verifiable -ParameterFilter { $Name -eq $mockAvailabilityGroupReplicaPresentName }
                Mock -CommandName New-SqlAvailabilityReplica -MockWith { throw 'CreateAvailabilityGroupReplicaFailed' } -Verifiable -ParameterFilter { $Name -eq $mockAvailabilityGroupReplicaAbsentName }
                Mock -CommandName New-TerminatingError -MockWith { $ErrorType } -Verifiable
                Mock -CommandName Remove-SqlAvailabilityGroup -MockWith {} -Verifiable -ParameterFilter { $InputObject.Name -eq $mockAvailabilityGroup1Name }
                Mock -CommandName Remove-SqlAvailabilityGroup -MockWith { throw 'RemoveAvailabilityGroupFailed' } -Verifiable -ParameterFilter { $InputObject.Name -eq $mockAvailabilityGroupRemoveErrorName }
                Mock -CommandName Test-ClusterPermissions -MockWith { $mockClusterPermissionsExist } -Verifiable
                Mock -CommandName Update-AvailabilityGroup -MockWith $mockUpdateAvailabiltyGroup -Verifiable
                Mock -CommandName Update-AvailabilityGroupReplica -MockWith $mockUpdateAvailabiltyGroupReplica -Verifiable

                #region test cases
                    $versionsToTest = @(12,13)

                    $createAvailabilityGroupTestCases = $versionsToTest | ForEach-Object -Process {
                        $versionToTest = $_

                        return @{
                            Name = $mockAvailabilityGroupPresentName
                            Version = $versionToTest
                        }
                    }

                    $removeAvailabilityGroupTestCases = $versionsToTest | ForEach-Object -Process {
                        $versionToTest = $_

                        return @{
                            Version = $versionToTest
                        }
                    }

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
                                    Parameter = $currentParameter
                                    ParameterValue = $testCaseParameterValue
                                    Version = $versionToTest
                                }
                            }
                        }

                        # One-off test for when the endpoint host name is not specified
                        return @{
                            Ensure = 'Present'
                            Parameter = 'EndpointHostName'
                            ParameterValue = ''
                            Version = $versionToTest
                        }
                    }

                    # Build a few test cases specifically for the EndpointUrl components
                    [array]$presentEndpointUrlTestCases = $versionsToTest | ForEach-Object -Process {
                        $versionToTest = $_

                        return @(
                             @{
                                Ensure = 'Present'
                                MockVariableName = 'mockAvailabilityReplicaEndpointProtocol'
                                MockVariableValue = 'UDP'
                                Version = $versionToTest
                            },
                            @{
                                Ensure = 'Present'
                                MockVariableName = 'mockAvailabilityReplicaEndpointPort'
                                MockVariableValue = 1234
                                Version = $versionToTest
                            }
                        )
                    }
                #endregion test cases
            }

            BeforeEach{
                $mockAvailabilityReplicaEndpointPort = 5022
                $mockAvailabilityReplicaEndpointProtocol = $mockAvailabilityReplica1EndpointProtocol
                $mockClusterPermissionsExist = $true
                $mockDatabaseMirroringEndpointPresent = $true
                $mockDatabaseMirroringEndpointProtocol = 'TCP'
                $mockDatabaseMirroringEndpointPort = 5022
                $mockIsHadrEnabled = $true
            }

            Context 'When the Availability Group is Absent' {
                BeforeAll {
                    $mockAvailabilityGroupName = $mockAvailabilityGroup1Name
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
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly -ParameterFilter { $Name -eq $mockAvailabilityGroupReplicaAbsentName }
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 1 -Exactly -ParameterFilter { $Name -eq $mockAvailabilityGroupReplicaPresentName }
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 1 -Exactly -ParameterFilter { $Name -eq $mockAvailabilityGroupPresentName }
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly -ParameterFilter { $Name -eq $mockAvailabilityGroupCreateErrorName }
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ClusterPermissions -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }

                It 'Should throw the correct error "HadrNotEnabled" when Ensure is set to Present, but HADR is not enabled' {

                    $mockIsHadrEnabled = $false

                    { Set-TargetResource @mockResourceParameters } | Should Throw 'HadrNotEnabled'

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $SQLServer -eq $mockServer1Name }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 0 -Exactly -ParameterFilter { $SQLServer -eq $mockServer2Name }
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly -ParameterFilter { $Name -eq $mockAvailabilityGroupReplicaAbsentName }
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly -ParameterFilter { $Name -eq $mockAvailabilityGroupReplicaPresentName }
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly -ParameterFilter { $Name -eq $mockAvailabilityGroupPresentName }
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly -ParameterFilter { $Name -eq $mockAvailabilityGroupCreateErrorName }
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ClusterPermissions -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }

                It 'Should throw the correct error "DatabaseMirroringEndpointNotFound" when Ensure is set to Present, but no DatabaseMirroring endpoints are present' {

                    $mockDatabaseMirroringEndpointPresent = $false

                    { Set-TargetResource @mockResourceParameters } | Should Throw 'DatabaseMirroringEndpointNotFound'

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $SQLServer -eq $mockServer1Name }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 0 -Exactly -ParameterFilter { $SQLServer -eq $mockServer2Name }
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly -ParameterFilter { $Name -eq $mockAvailabilityGroupReplicaAbsentName }
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly -ParameterFilter { $Name -eq $mockAvailabilityGroupReplicaPresentName }
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly -ParameterFilter { $Name -eq $mockAvailabilityGroupPresentName }
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly -ParameterFilter { $Name -eq $mockAvailabilityGroupCreateErrorName }
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ClusterPermissions -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }

                It 'Should throw the correct error, CreateAvailabilityGroupReplicaFailed, when Ensure is set to Present, but the Availability Group Replica failed to create and the SQL version is <Version>'  -TestCases $createAvailabilityGroupTestCases {
                    param
                    (
                        $Name,
                        $Version
                    )

                    $currentTestParameters = $mockResourceParameters.Clone()
                    $currentTestParameters.Name = $Name
                    $currentTestParameters.SQLServer = $mockServer2Name

                    { Set-TargetResource @currentTestParameters } | Should Throw 'CreateAvailabilityGroupReplicaFailed'

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 0 -Exactly -ParameterFilter { $SQLServer -eq $mockServer1Name }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $SQLServer -eq $mockServer2Name }
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 1 -Exactly -ParameterFilter { $Name -eq $mockAvailabilityGroupReplicaAbsentName }
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly -ParameterFilter { $Name -eq $mockAvailabilityGroupReplicaPresentName }
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly -ParameterFilter { $Name -eq $mockAvailabilityGroupPresentName }
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly -ParameterFilter { $Name -eq $mockAvailabilityGroupCreateErrorName }
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Test-ClusterPermissions -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }

                It 'Should throw the correct error "CreateAvailabilityGroupFailed" when Ensure is set to Present, but the Availability Group failed to create and the SQL version is <Version>' -TestCases $createAvailabilityGroupTestCases {
                    param
                    (
                        $Name,
                        $Version
                    )

                    $currentTestParameters = $mockResourceParameters.Clone()
                    $currentTestParameters.Name = $mockAvailabilityGroupCreateErrorName

                    { Set-TargetResource @currentTestParameters } | Should Throw 'CreateAvailabilityGroupFailed'

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $SQLServer -eq $mockServer1Name }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 0 -Exactly -ParameterFilter { $SQLServer -eq $mockServer2Name }
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly -ParameterFilter { $Name -eq $mockAvailabilityGroupReplicaAbsentName }
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 1 -Exactly -ParameterFilter { $Name -eq $mockAvailabilityGroupReplicaPresentName }
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly -ParameterFilter { $Name -eq $mockAvailabilityGroupPresentName }
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 1 -Exactly -ParameterFilter { $Name -eq $mockAvailabilityGroupCreateErrorName }
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.Name -eq $mockAvailabilityGroup1Name }
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.Name -eq $mockAvailabilityGroupRemoveErrorName }
                    Assert-MockCalled -CommandName Test-ClusterPermissions -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }
            }

            Context 'When the Availability Group is Present' {
                BeforeEach {
                    $mockAvailabilityGroupName = $mockAvailabilityGroup1Name
                    $mockAvailabilityGroup1PrimaryReplicaServerName = $mockServer1Name
                }

                It 'Should remove the Availability Group when Ensure is set to Absent and the SQL version is <Version>' -TestCases $removeAvailabilityGroupTestCases {
                    param
                    (
                        $Version
                    )

                    $currentTestParameters = $mockResourceParameters.Clone()
                    $currentTestParameters.Ensure = 'Absent'

                    { Set-TargetResource @currentTestParameters } | Should Not Throw

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $SQLServer -eq $mockServer1Name }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 0 -Exactly -ParameterFilter { $SQLServer -eq $mockServer2Name }
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly -ParameterFilter { $Name -eq $mockAvailabilityGroupReplicaAbsentName }
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly -ParameterFilter { $Name -eq $mockAvailabilityGroupReplicaPresentName }
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly -ParameterFilter { $Name -eq $mockAvailabilityGroupPresentName }
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly -ParameterFilter { $Name -eq $mockAvailabilityGroupCreateErrorName }
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 1 -Exactly -ParameterFilter { $InputObject.Name -eq $mockAvailabilityGroup1Name }
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.Name -eq $mockAvailabilityGroupRemoveErrorName }
                    Assert-MockCalled -CommandName Test-ClusterPermissions -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }

                It 'Should throw the correct error message "InstanceNotPrimaryReplica" when Ensure is "Absent", the primary replica is not on the current instance, and the SQL Version is <Version>' -TestCases $removeAvailabilityGroupTestCases {
                    param
                    (
                        $Version
                    )

                    $mockAvailabilityGroup1PrimaryReplicaServerName = $mockServer2Name

                    $currentTestParameters = $mockResourceParameters.Clone()
                    $currentTestParameters.Ensure = 'Absent'

                    { Set-TargetResource @currentTestParameters } | Should Throw 'InstanceNotPrimaryReplica'

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $SQLServer -eq $mockServer1Name }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 0 -Exactly -ParameterFilter { $SQLServer -eq $mockServer2Name }
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly -ParameterFilter { $Name -eq $mockAvailabilityGroupReplicaAbsentName }
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly -ParameterFilter { $Name -eq $mockAvailabilityGroupReplicaPresentName }
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly -ParameterFilter { $Name -eq $mockAvailabilityGroupPresentName }
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly -ParameterFilter { $Name -eq $mockAvailabilityGroupCreateErrorName }
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.Name -eq $mockAvailabilityGroup1Name }
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.Name -eq $mockAvailabilityGroupRemoveErrorName }
                    Assert-MockCalled -CommandName Test-ClusterPermissions -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }

                It 'Should throw the correct error message when Ensure is "Absent", the Availability Group remove fails, and the SQL version is <Version>' -TestCases $removeAvailabilityGroupTestCases {
                    param
                    (
                        $Version
                    )

                    $mockAvailabilityGroupName = $mockAvailabilityGroupRemoveErrorName

                    $currentTestParameters = $mockResourceParameters.Clone()
                    $currentTestParameters.Ensure = 'Absent'
                    $currentTestParameters.Name = $mockAvailabilityGroupRemoveErrorName

                    { Set-TargetResource @currentTestParameters } | Should Throw 'RemoveAvailabilityGroupFailed'

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $SQLServer -eq $mockServer1Name }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 0 -Exactly -ParameterFilter { $SQLServer -eq $mockServer2Name }
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly -ParameterFilter { $Name -eq $mockAvailabilityGroupReplicaAbsentName }
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly -ParameterFilter { $Name -eq $mockAvailabilityGroupReplicaPresentName }
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly -ParameterFilter { $Name -eq $mockAvailabilityGroupPresentName }
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly -ParameterFilter { $Name -eq $mockAvailabilityGroupCreateErrorName }
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.Name -eq $mockAvailabilityGroup1Name }
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 1 -Exactly -ParameterFilter { $InputObject.Name -eq $mockAvailabilityGroupRemoveErrorName }
                    Assert-MockCalled -CommandName Test-ClusterPermissions -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
                }

                It 'Should connect to the instance hosting the primary replica when the LocalReplicaRole is not Primary and the SQL version is <Version>' -TestCases $removeAvailabilityGroupTestCases {
                    param
                    (
                        $Version
                    )

                    $currentTestParameters = $mockResourceParameters.Clone()
                    $currentTestParameters.SQLServer = $mockServer2Name

                    { Set-TargetResource @currentTestParameters } | Should Not Throw

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $SQLServer -eq $mockServer1Name }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $SQLServer -eq $mockServer2Name }
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly -ParameterFilter { $Name -eq $mockAvailabilityGroupReplicaAbsentName }
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly -ParameterFilter { $Name -eq $mockAvailabilityGroupReplicaPresentName }
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly -ParameterFilter { $Name -eq $mockAvailabilityGroupPresentName }
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly -ParameterFilter { $Name -eq $mockAvailabilityGroupCreateErrorName }
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.Name -eq $mockAvailabilityGroup1Name }
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.Name -eq $mockAvailabilityGroupRemoveErrorName }
                    Assert-MockCalled -CommandName Test-ClusterPermissions -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 1 -Exactly
                }

                It 'Should set the property "<Parameter>" to the desired state "<ParameterValue>" when the version is "<Version>"' -TestCases $presentParameterTestCases {
                    param
                    (
                        $Ensure,
                        $Parameter,
                        $ParameterValue,
                        $Version
                    )

                    $currentTestParameters = $mockResourceParameters.Clone()
                    $currentTestParameters.$Parameter = $ParameterValue

                    { Set-TargetResource @currentTestParameters } | Should Not Throw

                    #Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $SQLServer -eq $mockServer1Name }
                    #Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 0 -Exactly -ParameterFilter { $SQLServer -eq $mockServer2Name }
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly -ParameterFilter { $Name -eq $mockAvailabilityGroupReplicaAbsentName }
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly -ParameterFilter { $Name -eq $mockAvailabilityGroupReplicaPresentName }
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly -ParameterFilter { $Name -eq $mockAvailabilityGroupPresentName }
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly -ParameterFilter { $Name -eq $mockAvailabilityGroupCreateErrorName }
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    #Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.Name -eq $mockAvailabilityGroup1Name }
                    #Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.Name -eq $mockAvailabilityGroupRemoveErrorName }
                    #Assert-MockCalled -CommandName Test-ClusterPermissions -Scope It -Times 1 -Exactly
                    #Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    #Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 1 -Exactly
                }

                It 'Should set the property "EndpointUrl" to the desired state when the mock "<MockVariableName>" is "<MockVariableValue>" and the version is "<Version>"' -TestCases $presentEndpointUrlTestCases {
                    param
                    (
                        $Ensure,
                        $MockVariableName,
                        $MockVariableValue,
                        $Version
                    )

                    Set-Variable -Name $MockVariableName -Value $MockVariableValue

                    { Set-TargetResource @mockResourceParameters } | Should Not Throw

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 2 -Exactly -ParameterFilter { $SQLServer -eq $mockServer1Name }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 0 -Exactly -ParameterFilter { $SQLServer -eq $mockServer2Name }
                    Assert-MockCalled -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly -ParameterFilter { $Name -eq $mockAvailabilityGroupReplicaAbsentName }
                    Assert-MockCalled -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly -ParameterFilter { $Name -eq $mockAvailabilityGroupReplicaPresentName }
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly -ParameterFilter { $Name -eq $mockAvailabilityGroupPresentName }
                    Assert-MockCalled -CommandName New-SqlAvailabilityGroup -Scope It -Times 0 -Exactly -ParameterFilter { $Name -eq $mockAvailabilityGroupCreateErrorName }
                    Assert-MockCalled -CommandName New-TerminatingError -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.Name -eq $mockAvailabilityGroup1Name }
                    Assert-MockCalled -CommandName Remove-SqlAvailabilityGroup -Scope It -Times 0 -Exactly -ParameterFilter { $InputObject.Name -eq $mockAvailabilityGroupRemoveErrorName }
                    Assert-MockCalled -CommandName Test-ClusterPermissions -Scope It -Times 1 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroup -Scope It -Times 0 -Exactly
                    Assert-MockCalled -CommandName Update-AvailabilityGroupReplica -Scope It -Times 1 -Exactly
                }
            }
        }

        Describe "xSQLServerAlwaysOnAvailabilityGroup\Test-TargetResource" {
            BeforeAll {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlServer1 -Verifiable -ParameterFilter { $SQLServer -eq $mockServer1Name }
                Mock -CommandName Connect-SQL -MockWith $mockConnectSqlServer2 -Verifiable -ParameterFilter { $SQLServer -eq $mockServer2Name }

                $mockAvailabilityGroupName = $mockAvailabilityGroup1Name
                $mockAvailabilityReplicaEndpointPort = 5022
                $mockAvailabilityReplicaEndpointProtocol = $mockAvailabilityReplica1EndpointProtocol
                $mockDatabaseMirroringEndpointPresent = $true
                $mockDatabaseMirroringEndpointProtocol = 'TCP'
                $mockDatabaseMirroringEndpointPort = 5022

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

                        # One-off test for when the endpoint host name is not specified
                        return @{
                            Ensure = 'Present'
                            Result = $true
                            Parameter = 'EndpointHostName'
                            ParameterValue = ''
                            Version = $versionToTest
                        }
                    }

                    # Build a few test cases specifically for the EndpointUrl components
                    [array]$presentEndpointUrlTestCases = $versionsToTest | ForEach-Object -Process {
                        $versionToTest = $_

                        return @(
                             @{
                                Ensure = 'Present'
                                Result = $false
                                MockVariableName = 'mockAvailabilityReplicaEndpointProtocol'
                                MockVariableValue = 'UDP'
                                Version = $versionToTest
                            },
                            @{
                                Ensure = 'Present'
                                Result = $false
                                MockVariableName = 'mockAvailabilityReplicaEndpointPort'
                                MockVariableValue = 1234
                                Version = $versionToTest
                            }
                        )
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

                It 'Should be "<Result>" when the desired state is "<Ensure>", the mock "<MockVariableName>" is "<ParameterValue>", and the SQL version is "<Version>"' -TestCases $presentEndpointUrlTestCases {
                    param
                    (
                        $Ensure,
                        $Result,
                        $MockVariableName,
                        $MockVariableValue,
                        $Version
                    )

                    Set-Variable -Name $MockVariableName -Value $MockVariableValue

                    Test-TargetResource @mockResourceParameters | Should Be $Result

                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly -ParameterFilter { $SQLServer -eq $mockServer1Name }
                    Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 0 -Exactly -ParameterFilter { $SQLServer -eq $mockServer2Name }
                }

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
