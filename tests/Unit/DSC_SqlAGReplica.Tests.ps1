<#
    .SYNOPSIS
        Unit test for DSC_SqlLogin DSC resource.
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
}

BeforeAll {
    $script:dscModuleName = 'SqlServerDsc'
    $script:dscResourceName = 'DSC_SqlAGReplica'

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

    # Loading mocked classes
    Add-Type -Path (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Stubs') -ChildPath 'SMO.cs')

    # Load the correct SQL Module stub
    $script:stubModuleName = Import-SQLModuleStub -PassThru

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

    # Unload the stub module.
    Remove-SqlModuleStub -Name $script:stubModuleName

    # Remove module common test helper.
    Get-Module -Name 'CommonTestHelper' -All | Remove-Module -Force
}

Describe 'SqlAGReplica\Get-TargetResource' {
    BeforeAll {
        $mockConnectSqlServer1 = {
            param
            (
                [Parameter()]
                [System.String]
                $ServerName,

                [Parameter()]
                [System.String]
                $InstanceName,

                # The following two parameters are used to mock Get-PrimaryReplicaServerObject
                [Parameter()]
                [Microsoft.SqlServer.Management.Smo.AvailabilityGroup]
                $AvailabilityGroup,

                [Parameter()]
                [Microsoft.SqlServer.Management.Smo.Server]
                $ServerObject
            )

            # Mock the server object
            $mockServerObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server
            $mockServerObject.Name = 'Server1'
            $mockServerObject.NetName = 'Server1'
            $mockServerObject.IsHadrEnabled = $mockServer1IsHadrEnabled
            $mockServerObject.Logins = $mockLogins
            $mockServerObject.ServiceName = 'MSSQLSERVER'

            # Mock the availability group replicas
            $mockAvailabilityGroupReplica1 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityReplica
            $mockAvailabilityGroupReplica1.AvailabilityMode = 'AsynchronousCommit'
            $mockAvailabilityGroupReplica1.BackupPriority = 50
            $mockAvailabilityGroupReplica1.ConnectionModeInPrimaryRole = 'AllowAllConnections'
            $mockAvailabilityGroupReplica1.ConnectionModeInSecondaryRole = 'AllowNoConnections'
            $mockAvailabilityGroupReplica1.EndpointUrl = 'TCP://Server1:5022'
            $mockAvailabilityGroupReplica1.FailoverMode = 'Manual'
            $mockAvailabilityGroupReplica1.Name = 'Server1'
            $mockAvailabilityGroupReplica1.ReadOnlyRoutingConnectionUrl = 'TCP://Server1.domain.com:1433'
            $mockAvailabilityGroupReplica1.ReadOnlyRoutingList = @('Server1', 'Server2')

            $mockAvailabilityGroupReplica2 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityReplica
            $mockAvailabilityGroupReplica2.AvailabilityMode = 'AsynchronousCommit'
            $mockAvailabilityGroupReplica2.BackupPriority = 50
            $mockAvailabilityGroupReplica2.ConnectionModeInPrimaryRole = 'AllowAllConnections'
            $mockAvailabilityGroupReplica2.ConnectionModeInSecondaryRole = 'AllowNoConnections'
            $mockAvailabilityGroupReplica2.EndpointUrl = 'TCP://Server2:5022'
            $mockAvailabilityGroupReplica2.FailoverMode = 'Manual'
            $mockAvailabilityGroupReplica2.Name = 'Server2'
            $mockAvailabilityGroupReplica2.ReadOnlyRoutingConnectionUrl = 'TCP://Server2.domain.com:1433'
            $mockAvailabilityGroupReplica2.ReadOnlyRoutingList = @('Server1', 'Server2')

            $mockAvailabilityGroupReplica3 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityReplica
            $mockAvailabilityGroupReplica3.AvailabilityMode = 'AsynchronousCommit'
            $mockAvailabilityGroupReplica3.BackupPriority = 50
            $mockAvailabilityGroupReplica3.ConnectionModeInPrimaryRole = 'AllowAllConnections'
            $mockAvailabilityGroupReplica3.ConnectionModeInSecondaryRole ='AllowNoConnections'
            $mockAvailabilityGroupReplica3.EndpointUrl = 'TCP://Server3:5022'
            $mockAvailabilityGroupReplica3.FailoverMode = 'Manual'
            $mockAvailabilityGroupReplica3.Name = 'Server3'
            $mockAvailabilityGroupReplica3.ReadOnlyRoutingConnectionUrl = 'TCP://Server3.domain.com:1433'
            $mockAvailabilityGroupReplica3.ReadOnlyRoutingList = @('Server1', 'Server2')

            # Mock the availability groups
            $mockAvailabilityGroup1 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityGroup
            $mockAvailabilityGroup1.Name = 'AG_AllServers'
            $mockAvailabilityGroup1.PrimaryReplicaServerName = 'Server2'
            $mockAvailabilityGroup1.LocalReplicaRole = 'Secondary'
            $mockAvailabilityGroup1.AvailabilityReplicas.Add($mockAvailabilityGroupReplica1)
            $mockAvailabilityGroup1.AvailabilityReplicas.Add($mockAvailabilityGroupReplica2)
            $mockAvailabilityGroup1.AvailabilityReplicas.Add($mockAvailabilityGroupReplica3)

            $mockServerObject.AvailabilityGroups.Add($mockAvailabilityGroup1)

            $mockEndpoint = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Endpoint
            $mockEndpoint.EndpointType = 'DatabaseMirroring'
            $mockEndpoint.Protocol = @{
                TCP = @{
                    ListenerPort = 5022
                }
            }

            $mockServerObject.Endpoints.Add($mockEndpoint)

            return $mockServerObject
        }

        Mock -CommandName Connect-SQL -MockWith $mockConnectSqlServer1
    }

    Context 'When the Availability Group Replica is absent' {
        It 'Should not return an Availability Group Replica' {
            InModuleScope -ScriptBlock {
                $getTargetResourceParameters = @{
                    Name                  = 'Server1'
                    AvailabilityGroupName = 'AbsentAG'
                    ServerName            = 'Server1'
                    InstanceName          = 'MSSQLSERVER'
                }

                $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

                $getTargetResourceResult.AvailabilityGroupName | Should -BeNullOrEmpty
                $getTargetResourceResult.AvailabilityMode | Should -BeNullOrEmpty
                $getTargetResourceResult.BackupPriority | Should -BeNullOrEmpty
                $getTargetResourceResult.ConnectionModeInPrimaryRole | Should -BeNullOrEmpty
                $getTargetResourceResult.ConnectionModeInSecondaryRole | Should -BeNullOrEmpty
                $getTargetResourceResult.EndpointUrl | Should -BeNullOrEmpty
                $getTargetResourceResult.EndpointPort | Should -Be 5022
                $getTargetResourceResult.Ensure | Should -Be 'Absent'
                $getTargetResourceResult.FailoverMode | Should -BeNullOrEmpty
                $getTargetResourceResult.Name | Should -BeNullOrEmpty
                $getTargetResourceResult.ReadOnlyRoutingConnectionUrl | Should -BeNullOrEmpty
                $getTargetResourceResult.ReadOnlyRoutingList | Should -BeNullOrEmpty
                $getTargetResourceResult.ServerName | Should -Be 'Server1'
                $getTargetResourceResult.InstanceName | Should -Be 'MSSQLSERVER'
                $getTargetResourceResult.EndpointHostName | Should -Be 'Server1'
            }

            Should -Invoke -CommandName Connect-SQL -Scope It -Times 1 -Exactly
        }
    }

    Context 'When the Availability Group Replica is present' {
        It 'Should return an Availability Group Replica' {
            InModuleScope -ScriptBlock {
                $getTargetResourceParameters = @{
                    Name                  = 'Server1'
                    AvailabilityGroupName = 'AG_AllServers'
                    ServerName            = 'Server1'
                    InstanceName          = 'MSSQLSERVER'
                }

                $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

                $getTargetResourceResult.AvailabilityGroupName | Should -Be 'AG_AllServers'
                $getTargetResourceResult.AvailabilityMode | Should -Be 'AsynchronousCommit'
                $getTargetResourceResult.BackupPriority | Should -Be 50
                $getTargetResourceResult.ConnectionModeInPrimaryRole | Should -Be 'AllowAllConnections'
                $getTargetResourceResult.ConnectionModeInSecondaryRole | Should -Be 'AllowNoConnections'
                $getTargetResourceResult.EndpointUrl | Should -Be 'TCP://Server1:5022'
                $getTargetResourceResult.EndpointPort | Should -Be 5022
                $getTargetResourceResult.Ensure | Should -Be 'Present'
                $getTargetResourceResult.FailoverMode | Should -Be 'Manual'
                $getTargetResourceResult.Name | Should -Be 'Server1'
                $getTargetResourceResult.ReadOnlyRoutingConnectionUrl | Should -Be 'TCP://Server1.domain.com:1433'
                $getTargetResourceResult.ReadOnlyRoutingList | Should -Be @('Server1', 'Server2')
                $getTargetResourceResult.ServerName | Should -Be 'Server1'
                $getTargetResourceResult.InstanceName | Should -Be 'MSSQLSERVER'
                $getTargetResourceResult.EndpointHostName | Should -Be 'Server1'
            }

            Should -Invoke -CommandName Connect-SQL -Scope It -Times 1 -Exactly
        }
    }
}

# Describe 'SqlAGReplica\Set-TargetResource' {
    # BeforeAll {
    #     #$mockServer1IsHadrEnabled = $true
    #     #$mockAlternateEndpointPort = $false
    #     #$mockAlternateEndpointProtocol = $false

    #     # $mockLogins = @{} # Will be dynamically set during tests

    #     # $mockAllLoginsAbsent = @{}

    #     # $mockNtServiceClusSvcPresent = @{
    #     #     'NT SERVICE\ClusSvc' = ( New-Object -TypeName Microsoft.SqlServer.Management.Smo.Login('Server1', 'NT SERVICE\ClusSvc') )
    #     # }

    #     # $mockNtAuthoritySystemPresent = @{
    #     #     'NT AUTHORITY\SYSTEM' = ( New-Object -TypeName Microsoft.SqlServer.Management.Smo.Login('Server1', 'NT AUTHORITY\SYSTEM') )
    #     # }

    #     # $mockAllLoginsPresent = @{
    #     #     'NT SERVICE\ClusSvc'  = ( New-Object -TypeName Microsoft.SqlServer.Management.Smo.Login('Server1', 'NT SERVICE\ClusSvc') )
    #     #     'NT AUTHORITY\SYSTEM' = ( New-Object -TypeName Microsoft.SqlServer.Management.Smo.Login('Server1', 'NT AUTHORITY\SYSTEM') )
    #     # }

    #     $mockConnectSqlServer1 = {
    #         param
    #         (
    #             [Parameter()]
    #             [System.String]
    #             $ServerName,

    #             [Parameter()]
    #             [System.String]
    #             $InstanceName,

    #             # The following two parameters are used to mock Get-PrimaryReplicaServerObject
    #             [Parameter()]
    #             [Microsoft.SqlServer.Management.Smo.AvailabilityGroup]
    #             $AvailabilityGroup,

    #             [Parameter()]
    #             [Microsoft.SqlServer.Management.Smo.Server]
    #             $ServerObject
    #         )

    #         # Mock the server object
    #         $mockServerObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server
    #         $mockServerObject.Name = 'Server1'
    #         $mockServerObject.NetName = 'Server1'
    #         $mockServerObject.IsHadrEnabled = $mockServer1IsHadrEnabled
    #         $mockServerObject.Logins = $mockLogins
    #         $mockServerObject.ServiceName = 'MSSQLSERVER'

    #         # Mock the availability group replicas
    #         $mockAvailabilityGroupReplica1 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityReplica
    #         $mockAvailabilityGroupReplica1.AvailabilityMode = 'AsynchronousCommit'
    #         $mockAvailabilityGroupReplica1.BackupPriority = 50
    #         $mockAvailabilityGroupReplica1.ConnectionModeInPrimaryRole = 'AllowAllConnections'
    #         $mockAvailabilityGroupReplica1.ConnectionModeInSecondaryRole = 'AllowNoConnections'
    #         $mockAvailabilityGroupReplica1.EndpointUrl = 'TCP://Server1:5022'
    #         $mockAvailabilityGroupReplica1.FailoverMode = 'Manual'
    #         $mockAvailabilityGroupReplica1.Name = 'Server1'
    #         $mockAvailabilityGroupReplica1.ReadOnlyRoutingConnectionUrl = 'TCP://Server1.domain.com:1433'
    #         $mockAvailabilityGroupReplica1.ReadOnlyRoutingList = @('Server1', 'Server2')

    #         $mockAvailabilityGroupReplica2 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityReplica
    #         $mockAvailabilityGroupReplica2.AvailabilityMode = 'AsynchronousCommit'
    #         $mockAvailabilityGroupReplica2.BackupPriority = 50
    #         $mockAvailabilityGroupReplica2.ConnectionModeInPrimaryRole = 'AllowAllConnections'
    #         $mockAvailabilityGroupReplica2.ConnectionModeInSecondaryRole = 'AllowNoConnections'
    #         $mockAvailabilityGroupReplica2.EndpointUrl = 'TCP://Server2:5022'
    #         $mockAvailabilityGroupReplica2.FailoverMode = 'Manual'
    #         $mockAvailabilityGroupReplica2.Name = 'Server2'
    #         $mockAvailabilityGroupReplica2.ReadOnlyRoutingConnectionUrl = 'TCP://Server2.domain.com:1433'
    #         $mockAvailabilityGroupReplica2.ReadOnlyRoutingList = @('Server1', 'Server2')

    #         $mockAvailabilityGroupReplica3 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityReplica
    #         $mockAvailabilityGroupReplica3.AvailabilityMode = 'AsynchronousCommit'
    #         $mockAvailabilityGroupReplica3.BackupPriority = 50
    #         $mockAvailabilityGroupReplica3.ConnectionModeInPrimaryRole = 'AllowAllConnections'
    #         $mockAvailabilityGroupReplica3.ConnectionModeInSecondaryRole ='AllowNoConnections'
    #         $mockAvailabilityGroupReplica3.EndpointUrl = 'TCP://Server3:5022'
    #         $mockAvailabilityGroupReplica3.FailoverMode = 'Manual'
    #         $mockAvailabilityGroupReplica3.Name = 'Server3'
    #         $mockAvailabilityGroupReplica3.ReadOnlyRoutingConnectionUrl = 'TCP://Server3.domain.com:1433'
    #         $mockAvailabilityGroupReplica3.ReadOnlyRoutingList = @('Server1', 'Server2')

    #         if ( $mockAlternateEndpointPort )
    #         {
    #             $mockAvailabilityGroupReplica1.EndpointUrl = 'TCP://Server1:5022'.Replace(5022, '1234')
    #             $mockAvailabilityGroupReplica2.EndpointUrl = 'TCP://Server2:5022'.Replace(5022, '1234')
    #             $mockAvailabilityGroupReplica3.EndpointUrl = 'TCP://Server3:5022'.Replace(5022, '1234')
    #         }

    #         if ( $mockAlternateEndpointProtocol )
    #         {
    #             $mockAvailabilityGroupReplica1.EndpointUrl = 'TCP://Server1:5022'.Replace('TCP', 'UDP')
    #             $mockAvailabilityGroupReplica2.EndpointUrl = 'TCP://Server2:5022'.Replace('TCP', 'UDP')
    #             $mockAvailabilityGroupReplica3.EndpointUrl = 'TCP://Server3:5022'.Replace('TCP', 'UDP')
    #         }

    #         # Mock the availability groups
    #         $mockAvailabilityGroup1 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityGroup
    #         $mockAvailabilityGroup1.Name = 'AG_AllServers'
    #         $mockAvailabilityGroup1.PrimaryReplicaServerName = 'Server2'
    #         $mockAvailabilityGroup1.LocalReplicaRole = 'Secondary'
    #         $mockAvailabilityGroup1.AvailabilityReplicas.Add($mockAvailabilityGroupReplica1)
    #         $mockAvailabilityGroup1.AvailabilityReplicas.Add($mockAvailabilityGroupReplica2)
    #         $mockAvailabilityGroup1.AvailabilityReplicas.Add($mockAvailabilityGroupReplica3)
    #         $mockServerObject.AvailabilityGroups.Add($mockAvailabilityGroup1)

    #         # Mock the mirroring endpoint if required
    #         if ( $mockDatabaseMirroringEndpoint )
    #         {
    #             $mockEndpoint = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Endpoint
    #             $mockEndpoint.EndpointType = 'DatabaseMirroring'
    #             $mockEndpoint.Protocol = @{
    #                 TCP = @{
    #                     ListenerPort = 5022
    #                 }
    #             }
    #             $mockServerObject.Endpoints.Add($mockEndpoint)
    #         }

    #         return $mockServerObject
    #     }

    #     $mockConnectSqlServer2 = {
    #         param
    #         (
    #             [Parameter()]
    #             [System.String]
    #             $ServerName,

    #             [Parameter()]
    #             [System.String]
    #             $InstanceName,

    #             # The following two parameters are used to mock Get-PrimaryReplicaServerObject
    #             [Parameter()]
    #             [Microsoft.SqlServer.Management.Smo.AvailabilityGroup]
    #             $AvailabilityGroup,

    #             [Parameter()]
    #             [Microsoft.SqlServer.Management.Smo.Server]
    #             $ServerObject
    #         )

    #         # Mock the server object
    #         $mockServerObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server
    #         $mockServerObject.Name = 'Server2'
    #         $mockServerObject.NetName = 'Server2'
    #         $mockServerObject.IsHadrEnabled = $true
    #         $mockServerObject.Logins = $mockLogins
    #         $mockServerObject.ServiceName = 'MSSQLSERVER'

    #         #region Mock the availability group replicas
    #         $mockAvailabilityGroupReplica1 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityReplica
    #         $mockAvailabilityGroupReplica1.AvailabilityMode = 'AsynchronousCommit'
    #         $mockAvailabilityGroupReplica1.BackupPriority = 50
    #         $mockAvailabilityGroupReplica1.ConnectionModeInPrimaryRole = 'AllowAllConnections'
    #         $mockAvailabilityGroupReplica1.ConnectionModeInSecondaryRole = 'AllowNoConnections'
    #         $mockAvailabilityGroupReplica1.EndpointUrl = 'TCP://Server1:5022'
    #         $mockAvailabilityGroupReplica1.FailoverMode = 'Manual'
    #         $mockAvailabilityGroupReplica1.Name = 'Server1'
    #         $mockAvailabilityGroupReplica1.ReadOnlyRoutingConnectionUrl = 'TCP://Server1.domain.com:1433'
    #         $mockAvailabilityGroupReplica1.ReadOnlyRoutingList = @('Server1', 'Server2')

    #         $mockAvailabilityGroupReplica2 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityReplica
    #         $mockAvailabilityGroupReplica2.AvailabilityMode = 'AsynchronousCommit'
    #         $mockAvailabilityGroupReplica2.BackupPriority = 50
    #         $mockAvailabilityGroupReplica2.ConnectionModeInPrimaryRole = 'AllowAllConnections'
    #         $mockAvailabilityGroupReplica2.ConnectionModeInSecondaryRole = 'AllowNoConnections'
    #         $mockAvailabilityGroupReplica2.EndpointUrl = 'TCP://Server2:5022'
    #         $mockAvailabilityGroupReplica2.FailoverMode = 'Manual'
    #         $mockAvailabilityGroupReplica2.Name = 'Server2'
    #         $mockAvailabilityGroupReplica2.ReadOnlyRoutingConnectionUrl = 'TCP://Server2.domain.com:1433'
    #         $mockAvailabilityGroupReplica2.ReadOnlyRoutingList = @('Server1', 'Server2')

    #         $mockAvailabilityGroupReplica3 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityReplica
    #         $mockAvailabilityGroupReplica3.AvailabilityMode = 'AsynchronousCommit'
    #         $mockAvailabilityGroupReplica3.BackupPriority = 50
    #         $mockAvailabilityGroupReplica3.ConnectionModeInPrimaryRole = 'AllowAllConnections'
    #         $mockAvailabilityGroupReplica3.ConnectionModeInSecondaryRole ='AllowNoConnections'
    #         $mockAvailabilityGroupReplica3.EndpointUrl = 'TCP://Server3:5022'
    #         $mockAvailabilityGroupReplica3.FailoverMode = 'Manual'
    #         $mockAvailabilityGroupReplica3.Name = 'Server3'
    #         $mockAvailabilityGroupReplica3.ReadOnlyRoutingConnectionUrl = 'TCP://Server3.domain.com:1433'
    #         $mockAvailabilityGroupReplica3.ReadOnlyRoutingList = @('Server1', 'Server2')
    #         #endregion Mock the availability group replicas

    #         if ( $mockAlternateEndpointPort )
    #         {
    #             $mockAvailabilityGroupReplica1.EndpointUrl = 'TCP://Server1:5022'.Replace(5022, '1234')
    #             $mockAvailabilityGroupReplica2.EndpointUrl = 'TCP://Server2:5022'.Replace(5022, '1234')
    #             $mockAvailabilityGroupReplica3.EndpointUrl = 'TCP://Server3:5022'.Replace(5022, '1234')
    #         }

    #         if ( $mockAlternateEndpointProtocol )
    #         {
    #             $mockAvailabilityGroupReplica1.EndpointUrl = 'TCP://Server1:5022'.Replace('TCP', 'UDP')
    #             $mockAvailabilityGroupReplica2.EndpointUrl = 'TCP://Server2:5022'.Replace('TCP', 'UDP')
    #             $mockAvailabilityGroupReplica3.EndpointUrl = 'TCP://Server3:5022'.Replace('TCP', 'UDP')
    #         }

    #         # Mock the availability groups
    #         $mockAvailabilityGroup1 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityGroup
    #         $mockAvailabilityGroup1.Name = 'AG_AllServers'
    #         $mockAvailabilityGroup1.PrimaryReplicaServerName = 'Server2'
    #         $mockAvailabilityGroup1.LocalReplicaRole = 'Primary'
    #         $mockAvailabilityGroup1.AvailabilityReplicas.Add($mockAvailabilityGroupReplica1)
    #         $mockAvailabilityGroup1.AvailabilityReplicas.Add($mockAvailabilityGroupReplica2)
    #         $mockAvailabilityGroup1.AvailabilityReplicas.Add($mockAvailabilityGroupReplica3)
    #         $mockServerObject.AvailabilityGroups.Add($mockAvailabilityGroup1)

    #         $mockAvailabilityGroup2 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityGroup
    #         $mockAvailabilityGroup2.Name = 'AG_PrimaryOnServer2'
    #         $mockAvailabilityGroup2.PrimaryReplicaServerName = 'Server2'
    #         $mockAvailabilityGroup2.LocalReplicaRole = 'Primary'
    #         $mockAvailabilityGroup2.AvailabilityReplicas.Add($mockAvailabilityGroupReplica2)
    #         $mockAvailabilityGroup2.AvailabilityReplicas.Add($mockAvailabilityGroupReplica3)
    #         $mockServerObject.AvailabilityGroups.Add($mockAvailabilityGroup2)

    #         $mockAvailabilityGroup3 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityGroup
    #         $mockAvailabilityGroup3.Name = 'AG_PrimaryOnServer3'
    #         $mockAvailabilityGroup3.PrimaryReplicaServerName = 'Server3'
    #         $mockAvailabilityGroup3.LocalReplicaRole = 'Secondary'
    #         $mockAvailabilityGroup3.AvailabilityReplicas.Add($mockAvailabilityGroupReplica2)
    #         $mockAvailabilityGroup3.AvailabilityReplicas.Add($mockAvailabilityGroupReplica3)
    #         $mockServerObject.AvailabilityGroups.Add($mockAvailabilityGroup3)

    #         # Mock the mirroring endpoint if required
    #         if ( $mockDatabaseMirroringEndpoint )
    #         {
    #             $mockEndpoint = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Endpoint
    #             $mockEndpoint.EndpointType = 'DatabaseMirroring'
    #             $mockEndpoint.Protocol = @{
    #                 TCP = @{
    #                     ListenerPort = 5022
    #                 }
    #             }
    #             $mockServerObject.Endpoints.Add($mockEndpoint)
    #         }

    #         return $mockServerObject
    #     }

    #     $mockConnectSqlServer3 = {
    #         param
    #         (
    #             [Parameter()]
    #             [System.String]
    #             $ServerName,

    #             [Parameter()]
    #             [System.String]
    #             $InstanceName,

    #             # The following two parameters are used to mock Get-PrimaryReplicaServerObject
    #             [Parameter()]
    #             [Microsoft.SqlServer.Management.Smo.AvailabilityGroup]
    #             $AvailabilityGroup,

    #             [Parameter()]
    #             [Microsoft.SqlServer.Management.Smo.Server]
    #             $ServerObject
    #         )

    #         # Mock the server object
    #         $mockServerObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server
    #         $mockServerObject.Name = 'Server3'
    #         $mockServerObject.NetName = 'Server3'
    #         $mockServerObject.IsHadrEnabled = $true
    #         $mockServerObject.Logins = $mockLogins
    #         $mockServerObject.ServiceName = 'MSSQLSERVER'

    #         #region Mock the availability group replicas
    #         $mockAvailabilityGroupReplica1 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityReplica
    #         $mockAvailabilityGroupReplica1.AvailabilityMode = 'AsynchronousCommit'
    #         $mockAvailabilityGroupReplica1.BackupPriority = 50
    #         $mockAvailabilityGroupReplica1.ConnectionModeInPrimaryRole = 'AllowAllConnections'
    #         $mockAvailabilityGroupReplica1.ConnectionModeInSecondaryRole = 'AllowNoConnections'
    #         $mockAvailabilityGroupReplica1.EndpointUrl = 'TCP://Server1:5022'
    #         $mockAvailabilityGroupReplica1.FailoverMode = 'Manual'
    #         $mockAvailabilityGroupReplica1.Name = 'Server1'
    #         $mockAvailabilityGroupReplica1.ReadOnlyRoutingConnectionUrl = 'TCP://Server1.domain.com:1433'
    #         $mockAvailabilityGroupReplica1.ReadOnlyRoutingList = @('Server1', 'Server2')

    #         $mockAvailabilityGroupReplica2 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityReplica
    #         $mockAvailabilityGroupReplica2.AvailabilityMode = 'AsynchronousCommit'
    #         $mockAvailabilityGroupReplica2.BackupPriority = 50
    #         $mockAvailabilityGroupReplica2.ConnectionModeInPrimaryRole = 'AllowAllConnections'
    #         $mockAvailabilityGroupReplica2.ConnectionModeInSecondaryRole = 'AllowNoConnections'
    #         $mockAvailabilityGroupReplica2.EndpointUrl = 'TCP://Server2:5022'
    #         $mockAvailabilityGroupReplica2.FailoverMode = 'Manual'
    #         $mockAvailabilityGroupReplica2.Name = 'Server2'
    #         $mockAvailabilityGroupReplica2.ReadOnlyRoutingConnectionUrl = 'TCP://Server2.domain.com:1433'
    #         $mockAvailabilityGroupReplica2.ReadOnlyRoutingList = @('Server1', 'Server2')

    #         $mockAvailabilityGroupReplica3 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityReplica
    #         $mockAvailabilityGroupReplica3.AvailabilityMode = 'AsynchronousCommit'
    #         $mockAvailabilityGroupReplica3.BackupPriority = 50
    #         $mockAvailabilityGroupReplica3.ConnectionModeInPrimaryRole = 'AllowAllConnections'
    #         $mockAvailabilityGroupReplica3.ConnectionModeInSecondaryRole ='AllowNoConnections'
    #         $mockAvailabilityGroupReplica3.EndpointUrl = 'TCP://Server3:5022'
    #         $mockAvailabilityGroupReplica3.FailoverMode = 'Manual'
    #         $mockAvailabilityGroupReplica3.Name = 'Server3'
    #         $mockAvailabilityGroupReplica3.ReadOnlyRoutingConnectionUrl = 'TCP://Server3.domain.com:1433'
    #         $mockAvailabilityGroupReplica3.ReadOnlyRoutingList = @('Server1', 'Server2')
    #         #endregion Mock the availability group replicas

    #         if ( $mockAlternateEndpointPort )
    #         {
    #             $mockAvailabilityGroupReplica1.EndpointUrl = 'TCP://Server1:5022'.Replace(5022, '1234')
    #             $mockAvailabilityGroupReplica2.EndpointUrl = 'TCP://Server2:5022'.Replace(5022, '1234')
    #             $mockAvailabilityGroupReplica3.EndpointUrl = 'TCP://Server3:5022'.Replace(5022, '1234')
    #         }

    #         if ( $mockAlternateEndpointProtocol )
    #         {
    #             $mockAvailabilityGroupReplica1.EndpointUrl = 'TCP://Server1:5022'.Replace('TCP', 'UDP')
    #             $mockAvailabilityGroupReplica2.EndpointUrl = 'TCP://Server2:5022'.Replace('TCP', 'UDP')
    #             $mockAvailabilityGroupReplica3.EndpointUrl = 'TCP://Server3:5022'.Replace('TCP', 'UDP')
    #         }

    #         # Mock the availability groups
    #         $mockAvailabilityGroup1 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityGroup
    #         $mockAvailabilityGroup1.Name = 'AG_AllServers'
    #         $mockAvailabilityGroup1.PrimaryReplicaServerName = 'Server2'
    #         $mockAvailabilityGroup1.LocalReplicaRole = 'Secondary'
    #         $mockAvailabilityGroup1.AvailabilityReplicas.Add($mockAvailabilityGroupReplica1)
    #         $mockAvailabilityGroup1.AvailabilityReplicas.Add($mockAvailabilityGroupReplica2)
    #         $mockAvailabilityGroup1.AvailabilityReplicas.Add($mockAvailabilityGroupReplica3)
    #         $mockServerObject.AvailabilityGroups.Add($mockAvailabilityGroup1)

    #         $mockAvailabilityGroup2 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityGroup
    #         $mockAvailabilityGroup2.Name = 'AG_PrimaryOnServer2'
    #         $mockAvailabilityGroup2.PrimaryReplicaServerName = 'Server2'
    #         $mockAvailabilityGroup2.LocalReplicaRole = 'Secondary'
    #         $mockAvailabilityGroup2.AvailabilityReplicas.Add($mockAvailabilityGroupReplica2)
    #         $mockAvailabilityGroup2.AvailabilityReplicas.Add($mockAvailabilityGroupReplica3)
    #         $mockServerObject.AvailabilityGroups.Add($mockAvailabilityGroup2)

    #         $mockAvailabilityGroup3 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityGroup
    #         $mockAvailabilityGroup3.Name = 'AG_PrimaryOnServer3'
    #         $mockAvailabilityGroup3.PrimaryReplicaServerName = 'Server3'
    #         $mockAvailabilityGroup3.LocalReplicaRole = 'Primary'
    #         $mockAvailabilityGroup3.AvailabilityReplicas.Add($mockAvailabilityGroupReplica2)
    #         $mockAvailabilityGroup3.AvailabilityReplicas.Add($mockAvailabilityGroupReplica3)
    #         $mockServerObject.AvailabilityGroups.Add($mockAvailabilityGroup3)

    #         # Mock the mirroring endpoint if required
    #         if ( $mockDatabaseMirroringEndpoint )
    #         {
    #             $mockEndpoint = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Endpoint
    #             $mockEndpoint.EndpointType = 'DatabaseMirroring'
    #             $mockEndpoint.Protocol = @{
    #                 TCP = @{
    #                     ListenerPort = 5022
    #                 }
    #             }
    #             $mockServerObject.Endpoints.Add($mockEndpoint)
    #         }

    #         return $mockServerObject
    #     }

    #     $mockAvailabilityGroupReplicaPropertyName = '' # Set dynamically during runtime
    #     $mockAvailabilityGroupReplicaPropertyValue = '' # Set dynamically during runtime

    #     $mockUpdateAvailabilityGroupReplica = {
    #         param
    #         (
    #             [Parameter()]
    #             [Microsoft.SqlServer.Management.Smo.AvailabilityReplica]
    #             $AvailabilityGroupReplica
    #         )

    #         if ( [System.String]::IsNullOrEmpty($mockAvailabilityGroupReplicaPropertyName) -and [System.String]::IsNullOrEmpty($mockAvailabilityGroupReplicaPropertyValue) )
    #         {
    #             return
    #         }

    #         if ( ( $mockAvailabilityGroupReplicaPropertyValue -join ',' ) -ne ( $AvailabilityGroupReplica.$mockAvailabilityGroupReplicaPropertyName -join ',' ) )
    #         {
    #             throw
    #         }
    #     }
#         Mock -CommandName Import-SQLPSModule
#     }

#     BeforeEach {
#         $mockDatabaseMirroringEndpoint = $true
#         $mockLogins = $mockNtServiceClusSvcPresent
#         $mockServer1IsHadrEnabled = $true

#         Mock -CommandName Connect-SQL -MockWith $mockConnectSqlServer1 -ParameterFilter {
#             $ServerName -eq 'Server1'
#         }
#         Mock -CommandName Connect-SQL -MockWith $mockConnectSqlServer2 -ParameterFilter {
#             $ServerName -eq 'Server2'
#         }
#         Mock -CommandName Connect-SQL -MockWith $mockConnectSqlServer3 -ParameterFilter {
#             $ServerName -eq 'Server3'
#         }
#         Mock -CommandName Get-PrimaryReplicaServerObject -MockWith $mockConnectSqlServer1 -ParameterFilter {
#             $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1'
#         }
#         Mock -CommandName Get-PrimaryReplicaServerObject -MockWith $mockConnectSqlServer2 -ParameterFilter {
#             $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2'
#         }
#         Mock -CommandName Get-PrimaryReplicaServerObject -MockWith $mockConnectSqlServer3 -ParameterFilter {
#             $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server3'
#         }
#         Mock -CommandName Join-SqlAvailabilityGroup
#         Mock -CommandName New-SqlAvailabilityReplica
#         Mock -CommandName Test-ClusterPermissions -MockWith {
#             $null
#         }
#     }

#     Context 'When the desired state is absent' {

#         BeforeAll {
#             Mock -CommandName Update-AvailabilityGroupReplica
#         }

#         BeforeEach {
#             $setTargetResourceParameters = @{
#                 Name                  = 'Server1'
#                 AvailabilityGroupName = 'AG_AllServers'
#                 ServerName            = 'Server1'
#                 InstanceName          = 'MSSQLSERVER'
#                 Ensure                = 'Absent'
#             }
#         }

#         It 'Should silently remove the availability group replica' {

#             Mock -CommandName Remove-SqlAvailabilityReplica

#             { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

#             Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
#                 $ServerName -eq 'Server1'
#             } -Times 1 -Exactly
#             Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
#                 $ServerName -eq 'Server2'
#             } -Times 0 -Exactly
#             Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
#                 $ServerName -eq 'Server3'
#             } -Times 0 -Exactly
#             Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
#                 $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1'
#             }
#             Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 1 -Exactly -ParameterFilter {
#                 $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2'
#             }
#             Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
#                 $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server3'
#             }
#             Should -Invoke -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
#             Should -Invoke -CommandName Join-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
#             Should -Invoke -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
#             Should -Invoke -CommandName Remove-SqlAvailabilityReplica -Scope It -Times 1 -Exactly
#             Should -Invoke -CommandName Test-ClusterPermissions -Scope It -Times 0 -Exactly
#             Should -Invoke -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
#         }

#         It 'Should throw the correct error (RemoveAvailabilityGroupReplicaFailed) when removing the availability group replica fails' {

#             Mock -CommandName Remove-SqlAvailabilityReplica -MockWith { throw 'RemoveAvailabilityGroupReplicaFailed' }

#             $mockErrorMessage = $script:localizedData.RemoveAvailabilityGroupReplicaFailed -f $setTargetResourceParameters.Name, $setTargetResourceParameters.AvailabilityGroupName, $setTargetResourceParameters.InstanceName
#             { Set-TargetResource @setTargetResourceParameters } | Should -Throw $mockErrorMessage

#             Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
#                 $ServerName -eq 'Server1'
#             } -Times 1 -Exactly
#             Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
#                 $ServerName -eq 'Server2'
#             } -Times 0 -Exactly
#             Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
#                 $ServerName -eq 'Server3'
#             } -Times 0 -Exactly
#             Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
#                 $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1'
#             }
#             Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 1 -Exactly -ParameterFilter {
#                 $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2'
#             }
#             Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
#                 $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server3'
#             }
#             Should -Invoke -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
#             Should -Invoke -CommandName Join-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
#             Should -Invoke -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
#             Should -Invoke -CommandName Remove-SqlAvailabilityReplica -Scope It -Times 1 -Exactly
#             Should -Invoke -CommandName Test-ClusterPermissions -Scope It -Times 0 -Exactly
#             Should -Invoke -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
#         }
#     }

#     Context 'When the desired state is present and the availability group is absent' {

#         BeforeAll {
#             Mock -CommandName Remove-SqlAvailabilityReplica
#             Mock -CommandName Update-AvailabilityGroupReplica
#         }

#         BeforeEach {
#             $setTargetResourceParameters = @{
#                 Name                          = 'Server1'
#                 AvailabilityGroupName         = 'AG_PrimaryOnServer2'
#                 ServerName                    = 'Server1'
#                 InstanceName                  = 'MSSQLSERVER'
#                 PrimaryReplicaServerName      = 'Server2'
#                 PrimaryReplicaInstanceName    = 'MSSQLSERVER'
#                 Ensure                        = 'Present'
#                 AvailabilityMode              = 'AsynchronousCommit'
#                 BackupPriority                = 50
#                 ConnectionModeInPrimaryRole   = 'AllowAllConnections'
#                 ConnectionModeInSecondaryRole = 'AllowNoConnections'
#                 EndpointHostName              = 'Server1'
#                 FailoverMode                  = 'Manual'
#                 ReadOnlyRoutingConnectionUrl  = 'TCP://Server1.domain.com:1433'
#                 ReadOnlyRoutingList           = @('Server1', 'Server2')
#             }
#         }

#         It 'Should throw the correct error (HadrNotEnabled) when HADR is not enabled' {

#             $mockServer1IsHadrEnabled = $false

#             { Set-TargetResource @setTargetResourceParameters } | Should -Throw $script:localizedData.HadrNotEnabled

#             Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
#                 $ServerName -eq 'Server1'
#             } -Times 1 -Exactly
#             Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
#                 $ServerName -eq 'Server2'
#             } -Times 0 -Exactly
#             Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
#                 $ServerName -eq 'Server3'
#             } -Times 0 -Exactly
#             Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
#                 $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1'
#             }
#             Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
#                 $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2'
#             }
#             Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
#                 $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server3'
#             }
#             Should -Invoke -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
#             Should -Invoke -CommandName Join-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
#             Should -Invoke -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
#             Should -Invoke -CommandName Remove-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
#             Should -Invoke -CommandName Test-ClusterPermissions -Scope It -Times 0 -Exactly
#             Should -Invoke -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
#         }

#         It "Should throw when the logins '$('NT SERVICE\ClusSvc')' or '$('NT AUTHORITY\SYSTEM')' are absent or do not have permissions to manage availability groups" {

#             Mock -CommandName Test-ClusterPermissions -MockWith { throw }

#             $mockLogins = $mockAllLoginsAbsent.Clone()

#             { Set-TargetResource @setTargetResourceParameters } | Should -Throw

#             Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
#                 $ServerName -eq 'Server1'
#             } -Times 1 -Exactly
#             Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
#                 $ServerName -eq 'Server2'
#             } -Times 0 -Exactly
#             Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
#                 $ServerName -eq 'Server3'
#             } -Times 0 -Exactly
#             Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
#                 $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1'
#             }
#             Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
#                 $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2'
#             }
#             Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
#                 $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server3'
#             }
#             Should -Invoke -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
#             Should -Invoke -CommandName Join-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
#             Should -Invoke -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
#             Should -Invoke -CommandName Remove-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
#             Should -Invoke -CommandName Test-ClusterPermissions -Scope It -Times 1 -Exactly
#             Should -Invoke -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
#         }

#         It "Should create the availability group replica when '$('NT SERVICE\ClusSvc')' or '$('NT AUTHORITY\SYSTEM')' is present and has the permissions to manage availability groups" {

#             { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

#             Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
#                 $ServerName -eq 'Server1'
#             } -Times 1 -Exactly
#             Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
#                 $ServerName -eq 'Server2'
#             } -Times 1 -Exactly
#             Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
#                 $ServerName -eq 'Server3'
#             } -Times 0 -Exactly
#             Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
#                 $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1'
#             }
#             Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 1 -Exactly -ParameterFilter {
#                 $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2'
#             }
#             Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
#                 $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server3'
#             }
#             Should -Invoke -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
#             Should -Invoke -CommandName Join-SqlAvailabilityGroup -Scope It -Times 1 -Exactly
#             Should -Invoke -CommandName New-SqlAvailabilityReplica -Scope It -Times 1 -Exactly
#             Should -Invoke -CommandName Remove-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
#             Should -Invoke -CommandName Test-ClusterPermissions -Scope It -Times 1 -Exactly
#             Should -Invoke -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
#         }

#         It 'Should throw the correct error (DatabaseMirroringEndpointNotFound) when the database mirroring endpoint is absent' {

#             $mockDatabaseMirroringEndpoint = $false

#             $mockErrorMessage = $script:localizedData.DatabaseMirroringEndpointNotFound -f ('{0}\{1}' -f $setTargetResourceParameters.ServerName, $setTargetResourceParameters.InstanceName)

#             { Set-TargetResource @setTargetResourceParameters } | Should -Throw $mockErrorMessage

#             Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
#                 $ServerName -eq 'Server1'
#             } -Times 1 -Exactly
#             Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
#                 $ServerName -eq 'Server2'
#             } -Times 0 -Exactly
#             Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
#                 $ServerName -eq 'Server3'
#             } -Times 0 -Exactly
#             Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
#                 $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1'
#             }
#             Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
#                 $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2'
#             }
#             Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
#                 $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server3'
#             }
#             Should -Invoke -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
#             Should -Invoke -CommandName Join-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
#             Should -Invoke -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
#             Should -Invoke -CommandName Remove-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
#             Should -Invoke -CommandName Test-ClusterPermissions -Scope It -Times 1 -Exactly
#             Should -Invoke -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
#         }

#         It 'Should create the availability group replica when the endpoint hostname is not defined' {

#             $setTargetResourceParameters.EndpointHostName = ''

#             { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

#             Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
#                 $ServerName -eq 'Server1'
#             } -Times 1 -Exactly
#             Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
#                 $ServerName -eq 'Server2'
#             } -Times 1 -Exactly
#             Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
#                 $ServerName -eq 'Server3'
#             } -Times 0 -Exactly
#             Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
#                 $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1'
#             }
#             Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 1 -Exactly -ParameterFilter {
#                 $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2'
#             }
#             Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
#                 $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server3'
#             }
#             Should -Invoke -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
#             Should -Invoke -CommandName Join-SqlAvailabilityGroup -Scope It -Times 1 -Exactly
#             Should -Invoke -CommandName New-SqlAvailabilityReplica -Scope It -Times 1 -Exactly
#             Should -Invoke -CommandName Remove-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
#             Should -Invoke -CommandName Test-ClusterPermissions -Scope It -Times 1 -Exactly
#             Should -Invoke -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
#         }

#         It 'Should create the availability group replica when primary replica server is incorrectly supplied and the availability group exists' {

#             $setTargetResourceParameters.PrimaryReplicaServerName = 'Server3'

#             { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

#             Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
#                 $ServerName -eq 'Server1'
#             } -Times 1 -Exactly
#             Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
#                 $ServerName -eq 'Server2'
#             } -Times 0 -Exactly
#             Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
#                 $ServerName -eq 'Server3'
#             } -Times 1 -Exactly
#             Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
#                 $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1'
#             }
#             Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 1 -Exactly -ParameterFilter {
#                 $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2'
#             }
#             Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
#                 $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server3'
#             }
#             Should -Invoke -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
#             Should -Invoke -CommandName Join-SqlAvailabilityGroup -Scope It -Times 1 -Exactly
#             Should -Invoke -CommandName New-SqlAvailabilityReplica -Scope It -Times 1 -Exactly
#             Should -Invoke -CommandName Remove-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
#             Should -Invoke -CommandName Test-ClusterPermissions -Scope It -Times 1 -Exactly
#             Should -Invoke -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
#         }

#         It 'Should throw the correct error when the availability group replica fails to create' {

#             Mock -CommandName New-SqlAvailabilityReplica { throw }

#             $mockErrorMessage = $script:localizedData.FailedCreateAvailabilityGroupReplica -f $setTargetResourceParameters.Name, $setTargetResourceParameters.AvailabilityGroupName, $setTargetResourceParameters.InstanceName

#             { Set-TargetResource @setTargetResourceParameters } | Should -Throw $mockErrorMessage

#             Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
#                 $ServerName -eq 'Server1'
#             } -Times 1 -Exactly
#             Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
#                 $ServerName -eq 'Server2'
#             } -Times 1 -Exactly
#             Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
#                 $ServerName -eq 'Server3'
#             } -Times 0 -Exactly
#             Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
#                 $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1'
#             }
#             Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 1 -Exactly -ParameterFilter {
#                 $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2'
#             }
#             Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
#                 $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server3'
#             }
#             Should -Invoke -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
#             Should -Invoke -CommandName Join-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
#             Should -Invoke -CommandName New-SqlAvailabilityReplica -Scope It -Times 1 -Exactly
#             Should -Invoke -CommandName Remove-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
#             Should -Invoke -CommandName Test-ClusterPermissions -Scope It -Times 1 -Exactly
#             Should -Invoke -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
#         }

#         It 'Should throw the correct error (JoinAvailabilityGroupFailed) when the availability group replica fails to join the availability group' {

#             Mock -CommandName Join-SqlAvailabilityGroup -MockWith { throw }

#             $mockErrorMessage = $script:localizedData.FailedJoinAvailabilityGroup -f $setTargetResourceParameters.Name, $setTargetResourceParameters.AvailabilityGroupName, $setTargetResourceParameters.InstanceName

#             { Set-TargetResource @setTargetResourceParameters } | Should -Throw $mockErrorMessage

#             Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
#                 $ServerName -eq 'Server1'
#             } -Times 1 -Exactly
#             Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
#                 $ServerName -eq 'Server2'
#             } -Times 1 -Exactly
#             Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
#                 $ServerName -eq 'Server3'
#             } -Times 0 -Exactly
#             Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
#                 $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1'
#             }
#             Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 1 -Exactly -ParameterFilter {
#                 $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2'
#             }
#             Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
#                 $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server3'
#             }
#             Should -Invoke -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
#             Should -Invoke -CommandName Join-SqlAvailabilityGroup -Scope It -Times 1 -Exactly
#             Should -Invoke -CommandName New-SqlAvailabilityReplica -Scope It -Times 1 -Exactly
#             Should -Invoke -CommandName Remove-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
#             Should -Invoke -CommandName Test-ClusterPermissions -Scope It -Times 1 -Exactly
#             Should -Invoke -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
#         }

#         It 'Should throw the correct error (AvailabilityGroupNotFound) when the availability group does not exist on the primary replica' {

#             $setTargetResourceParameters.AvailabilityGroupName = 'DoesNotExist'

#             $mockErrorMessage = $script:localizedData.AvailabilityGroupNotFound -f $setTargetResourceParameters.AvailabilityGroupName, $setTargetResourceParameters.InstanceName

#             { Set-TargetResource @setTargetResourceParameters } | Should -Throw $mockErrorMessage

#             Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
#                 $ServerName -eq 'Server1'
#             } -Times 1 -Exactly
#             Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
#                 $ServerName -eq 'Server2'
#             } -Times 1 -Exactly
#             Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
#                 $ServerName -eq 'Server3'
#             } -Times 0 -Exactly
#             Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
#                 $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1'
#             }
#             Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
#                 $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2'
#             }
#             Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
#                 $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server3'
#             }
#             Should -Invoke -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
#             Should -Invoke -CommandName Join-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
#             Should -Invoke -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
#             Should -Invoke -CommandName Remove-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
#             Should -Invoke -CommandName Test-ClusterPermissions -Scope It -Times 1 -Exactly
#             Should -Invoke -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
#         }
#     }

#     Context 'When the desired state is present and the availability group is present' {

#         BeforeAll {
#             Mock -CommandName Remove-SqlAvailabilityReplica
#             Mock -CommandName Update-AvailabilityGroupReplica -MockWith $mockUpdateAvailabilityGroupReplica

#             # Create a hash table to provide test properties and values for the update tests
#             $mockTestProperties = @{
#                 AvailabilityMode              = 'SynchronousCommit'
#                 BackupPriority                = 75
#                 ConnectionModeInPrimaryRole   = 'AllowReadWriteConnections'
#                 ConnectionModeInSecondaryRole = 'AllowReadIntentConnectionsOnly'
#                 FailoverMode                  = 'Automatic'
#                 ReadOnlyRoutingConnectionUrl  = 'TCP://TestHost.domain.com:1433'
#                 ReadOnlyRoutingList           = @('Server2', 'Server1')
#             }
#         }

#         BeforeEach {
#             $mockAlternateEndpointPort = $false
#             $mockAlternateEndpointProtocol = $false

#             $setTargetResourceParameters = @{
#                 Name                          = 'Server1'
#                 AvailabilityGroupName         = 'AG_AllServers'
#                 ServerName                    = 'Server1'
#                 InstanceName                  = 'MSSQLSERVER'
#                 PrimaryReplicaServerName      = 'Server2'
#                 PrimaryReplicaInstanceName    = 'MSSQLSERVER'
#                 Ensure                        = 'Present'
#                 AvailabilityMode              = 'AsynchronousCommit'
#                 BackupPriority                = 50
#                 ConnectionModeInPrimaryRole   = 'AllowAllConnections'
#                 ConnectionModeInSecondaryRole = 'AllowNoConnections'
#                 EndpointHostName              = 'Server1'
#                 FailoverMode                  = 'Manual'
#                 ReadOnlyRoutingConnectionUrl  = 'TCP://Server1.domain.com:1433'
#                 ReadOnlyRoutingList           = @('Server1', 'Server2')
#             }
#         }

#         It 'Should throw the correct error (ReplicaNotFound) when the availability group replica does not exist' {

#             $setTargetResourceParameters.Name = 'ReplicaNotFound'

#             $mockErrorMessage = $script:localizedData.ReplicaNotFound -f $setTargetResourceParameters.Name, $setTargetResourceParameters.AvailabilityGroupName, $setTargetResourceParameters.InstanceName

#             { Set-TargetResource @setTargetResourceParameters } | Should -Throw $mockErrorMessage

#             Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
#                 $ServerName -eq 'Server1'
#             } -Times 1 -Exactly
#             Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
#                 $ServerName -eq 'Server2'
#             } -Times 0 -Exactly
#             Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
#                 $ServerName -eq 'Server3'
#             } -Times 0 -Exactly
#             Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
#                 $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1'
#             }
#             Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 1 -Exactly -ParameterFilter {
#                 $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2'
#             }
#             Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
#                 $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server3'
#             }
#             Should -Invoke -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
#             Should -Invoke -CommandName Join-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
#             Should -Invoke -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
#             Should -Invoke -CommandName Remove-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
#             Should -Invoke -CommandName Test-ClusterPermissions -Scope It -Times 1 -Exactly
#             Should -Invoke -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
#         }

#         foreach ( $mockTestProperty in $mockTestProperties.GetEnumerator() )
#         {
#             It "Should set the property '$($mockTestProperty.Key)' to the desired state" {

#                 $mockAvailabilityGroupReplicaPropertyName = $mockTestProperty.Key
#                 $mockAvailabilityGroupReplicaPropertyValue = $mockTestProperty.Value
#                 $setTargetResourceParameters.$mockAvailabilityGroupReplicaPropertyName = $mockAvailabilityGroupReplicaPropertyValue

#                 { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

#                 Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
#                     $ServerName -eq 'Server1'
#                 } -Times 1 -Exactly
#                 Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
#                     $ServerName -eq 'Server2'
#                 } -Times 0 -Exactly
#                 Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
#                     $ServerName -eq 'Server3'
#                 } -Times 0 -Exactly
#                 Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
#                     $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1'
#                 }
#                 Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 1 -Exactly -ParameterFilter {
#                     $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2'
#                 }
#                 Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
#                     $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server3'
#                 }
#                 Should -Invoke -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
#                 Should -Invoke -CommandName Join-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
#                 Should -Invoke -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
#                 Should -Invoke -CommandName Remove-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
#                 Should -Invoke -CommandName Test-ClusterPermissions -Scope It -Times 1 -Exactly
#                 Should -Invoke -CommandName Update-AvailabilityGroupReplica -Scope It -Times 1 #-Exactly
#             }
#         }

#         It "Should set the Endpoint Hostname to the desired state" {

#             $setTargetResourceParameters.EndpointHostName = 'AnotherEndpointHostName'

#             { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

#             Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
#                 $ServerName -eq 'Server1'
#             } -Times 1 -Exactly
#             Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
#                 $ServerName -eq 'Server2'
#             } -Times 0 -Exactly
#             Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
#                 $ServerName -eq 'Server3'
#             } -Times 0 -Exactly
#             Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
#                 $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1'
#             }
#             Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 1 -Exactly -ParameterFilter {
#                 $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2'
#             }
#             Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
#                 $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server3'
#             }
#             Should -Invoke -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
#             Should -Invoke -CommandName Join-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
#             Should -Invoke -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
#             Should -Invoke -CommandName Remove-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
#             Should -Invoke -CommandName Test-ClusterPermissions -Scope It -Times 1 -Exactly
#             Should -Invoke -CommandName Update-AvailabilityGroupReplica -Scope It -Times 1 -Exactly
#         }

#         It "Should set the Endpoint Port to the desired state" {

#             $mockAvailabilityGroupReplicaPropertyName = 'EndpointUrl'
#             $mockAvailabilityGroupReplicaPropertyValue = 'TCP://Server1:5022'
#             $mockAlternateEndpointPort = $true

#             { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

#             Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
#                 $ServerName -eq 'Server1'
#             } -Times 1 -Exactly
#             Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
#                 $ServerName -eq 'Server2'
#             } -Times 0 -Exactly
#             Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
#                 $ServerName -eq 'Server3'
#             } -Times 0 -Exactly
#             Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
#                 $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1'
#             }
#             Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 1 -Exactly -ParameterFilter {
#                 $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2'
#             }
#             Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
#                 $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server3'
#             }
#             Should -Invoke -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
#             Should -Invoke -CommandName Join-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
#             Should -Invoke -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
#             Should -Invoke -CommandName Remove-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
#             Should -Invoke -CommandName Test-ClusterPermissions -Scope It -Times 1 -Exactly
#             Should -Invoke -CommandName Update-AvailabilityGroupReplica -Scope It -Times 1 -Exactly
#         }

#         It "Should set the Endpoint Protocol to the desired state" {

#             $mockAvailabilityGroupReplicaPropertyName = 'EndpointUrl'
#             $mockAvailabilityGroupReplicaPropertyValue = 'TCP://Server1:5022'
#             $mockAlternateEndpointProtocol = $true

#             { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

#             Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
#                 $ServerName -eq 'Server1'
#             } -Times 1 -Exactly
#             Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
#                 $ServerName -eq 'Server2'
#             } -Times 0 -Exactly
#             Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
#                 $ServerName -eq 'Server3'
#             } -Times 0 -Exactly
#             Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
#                 $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1'
#             }
#             Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 1 -Exactly -ParameterFilter {
#                 $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2'
#             }
#             Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
#                 $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server3'
#             }
#             Should -Invoke -CommandName Import-SQLPSModule -Scope It -Times 1 -Exactly
#             Should -Invoke -CommandName Join-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
#             Should -Invoke -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
#             Should -Invoke -CommandName Remove-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
#             Should -Invoke -CommandName Test-ClusterPermissions -Scope It -Times 1 -Exactly
#             Should -Invoke -CommandName Update-AvailabilityGroupReplica -Scope It -Times 1 -Exactly
#         }
#     }
# }

# Describe 'SqlAGReplica\Test-TargetResource' {

#     BeforeEach {
#         $mockAlternateEndpointPort = $false
#         $mockAlternateEndpointProtocol = $false
#         $mockDatabaseMirroringEndpoint = $true

#         $testTargetResourceParameters = @{
#             Name                          = 'Server1'
#             AvailabilityGroupName         = 'AG_AllServers'
#             ServerName                    = 'Server1'
#             InstanceName                  = 'MSSQLSERVER'
#             PrimaryReplicaServerName      = 'Server2'
#             PrimaryReplicaInstanceName    = 'MSSQLSERVER'
#             Ensure                        = 'Present'
#             AvailabilityMode              = 'AsynchronousCommit'
#             BackupPriority                = 50
#             ConnectionModeInPrimaryRole   = 'AllowAllConnections'
#             ConnectionModeInSecondaryRole = 'AllowNoConnections'
#             EndpointHostName              = 'Server1'
#             FailoverMode                  = 'Manual'
#             ReadOnlyRoutingConnectionUrl  = 'TCP://Server1.domain.com:1433'
#             ReadOnlyRoutingList           = @('Server1', 'Server2')
#             ProcessOnlyOnActiveNode       = $false
#         }

#         Mock -CommandName Connect-SQL -MockWith $mockConnectSqlServer1
#         Mock -CommandName Test-ActiveNode -MockWith {
#             return -not $false
#         }
#     }

#     Context 'When the desired state is absent' {

#         It 'Should return $true when the Availability Replica is absent' {

#             $testTargetResourceParameters.Name = 'Server2'
#             $testTargetResourceParameters.AvailabilityGroupName = 'AG_PrimaryOnServer2'
#             $testTargetResourceParameters.Ensure = 'Absent'

#             Test-TargetResource @testTargetResourceParameters | Should -Be $true

#             Should -Invoke -CommandName Connect-SQL -Scope It -Times 1 -Exactly
#         }

#         It 'Should return $false when the Availability Replica is present' {

#             $testTargetResourceParameters.Ensure = 'Absent'

#             Test-TargetResource @testTargetResourceParameters | Should -Be $false

#             Should -Invoke -CommandName Connect-SQL -Scope It -Times 1 -Exactly
#         }
#     }

#     Context 'When the desired state is present' {

#         BeforeAll {
#             $propertiesToCheck = @{
#                 AvailabilityMode              = 'SynchronousCommit'
#                 BackupPriority                = 42
#                 ConnectionModeInPrimaryRole   = 'AllowReadWriteConnections'
#                 ConnectionModeInSecondaryRole = 'AllowReadIntentConnectionsOnly'
#                 FailoverMode                  = 'Automatic'
#                 ReadOnlyRoutingConnectionUrl  = 'WrongUrl'
#                 ReadOnlyRoutingList           = @('WrongServer')
#             }
#         }

#         It "Should return $true when the Availability Replica is present all properties are in the desired state" {
#             Test-TargetResource @testTargetResourceParameters | Should -Be $true

#             Should -Invoke -CommandName Connect-SQL -Scope It -Times 1 -Exactly
#             Should -Invoke -CommandName Test-ActiveNode -Scope It -Times 1 -Exactly
#         }

#         It 'Should return $false when the Availability Replica is absent' {

#             $testTargetResourceParameters.Name = 'Server2'
#             $testTargetResourceParameters.AvailabilityGroupName = 'AG_PrimaryOnServer2'

#             Test-TargetResource @testTargetResourceParameters | Should -Be $false

#             Should -Invoke -CommandName Connect-SQL -Scope It -Times 1 -Exactly
#             Should -Invoke -CommandName Test-ActiveNode -Scope It -Times 1 -Exactly
#         }

#         It 'Should return $true when the Availability Replica is present' {

#             Test-TargetResource @testTargetResourceParameters | Should -Be $true

#             Should -Invoke -CommandName Connect-SQL -Scope It -Times 1 -Exactly
#             Should -Invoke -CommandName Test-ActiveNode -Scope It -Times 1 -Exactly
#         }

#         foreach ( $propertyToCheck in $propertiesToCheck.GetEnumerator() )
#         {
#             It "Should return $false when the Availability Replica is present and the property '$($propertyToCheck.Key)' is not in the desired state" {
#                 $testTargetResourceParameters.($propertyToCheck.Key) = $propertyToCheck.Value

#                 Test-TargetResource @testTargetResourceParameters | Should -Be $false

#                 Should -Invoke -CommandName Connect-SQL -Scope It -Times 1 -Exactly
#                 Should -Invoke -CommandName Test-ActiveNode -Scope It -Times 1 -Exactly
#             }
#         }

#         It 'Should return $false when the Availability Replica is present and the Availabiltiy Mode is not in the desired state' {

#             $testTargetResourceParameters.AvailabilityMode = 'SynchronousCommit'

#             Test-TargetResource @testTargetResourceParameters | Should -Be $false

#             Should -Invoke -CommandName Connect-SQL -Scope It -Times 1 -Exactly
#             Should -Invoke -CommandName Test-ActiveNode -Scope It -Times 1 -Exactly
#         }

#         It 'Should return $true when the Availability Replica is present and the Endpoint Hostname is not specified' {

#             $testTargetResourceParameters.EndpointHostName = ''

#             Test-TargetResource @testTargetResourceParameters | Should -Be $true

#             Should -Invoke -CommandName Connect-SQL -Scope It -Times 1 -Exactly
#             Should -Invoke -CommandName Test-ActiveNode -Scope It -Times 1 -Exactly
#         }

#         It 'Should return $false when the Availability Replica is present and the Endpoint Hostname is not in the desired state' {

#             $testTargetResourceParameters.EndpointHostName = 'OtherHostName'

#             Test-TargetResource @testTargetResourceParameters | Should -Be $false

#             Should -Invoke -CommandName Connect-SQL -Scope It -Times 1 -Exactly
#             Should -Invoke -CommandName Test-ActiveNode -Scope It -Times 1 -Exactly
#         }

#         It 'Should return $false when the Availability Replica is present and the Endpoint Protocol is not in the desired state' {

#             $mockAlternateEndpointProtocol = $true

#             Test-TargetResource @testTargetResourceParameters | Should -Be $false

#             Should -Invoke -CommandName Connect-SQL -Scope It -Times 1 -Exactly
#             Should -Invoke -CommandName Test-ActiveNode -Scope It -Times 1 -Exactly
#         }

#         It 'Should return $false when the Availability Replica is present and the Endpoint Port is not in the desired state' {

#             $mockAlternateEndpointPort = $true

#             Test-TargetResource @testTargetResourceParameters | Should -Be $false

#             Should -Invoke -CommandName Connect-SQL -Scope It -Times 1 -Exactly
#             Should -Invoke -CommandName Test-ActiveNode -Scope It -Times 1 -Exactly

#             $mockAlternateEndpointPort = $false
#         }

#         It 'Should return $true when ProcessOnlyOnActiveNode is "$true" and the current node is not actively hosting the instance' {
#             $false = $true

#             $testTargetResourceParameters.ProcessOnlyOnActiveNode = $false

#             Test-TargetResource @testTargetResourceParameters | Should -Be $true

#             Should -Invoke -CommandName Connect-SQL -Scope It -Times 1 -Exactly
#             Should -Invoke -CommandName Test-ActiveNode -Scope It -Times 1 -Exactly
#         }
#     }
# }
