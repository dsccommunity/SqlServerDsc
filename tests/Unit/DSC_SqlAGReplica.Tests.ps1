<#
    .SYNOPSIS
        Unit test for DSC_SqlAGReplica DSC resource.
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

    $env:SqlServerDscCI = $true

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

    Remove-Item -Path 'env:SqlServerDscCI'
}

Describe 'SqlAGReplica\Get-TargetResource' {
    BeforeAll {
        $mockConnectSqlServer1 = {
            # Mock the server object
            $mockServerObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server
            $mockServerObject.Name = 'Server1'
            $mockServerObject.NetName = 'Server1'
            $mockServerObject.IsHadrEnabled = $true
            $mockServerObject.ServiceName = 'MSSQLSERVER'
            $mockServerObject.Version = @{
                Major = 13
            }

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
            $mockAvailabilityGroupReplica1.SeedingMode = 'Manual'

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
            $mockAvailabilityGroupReplica2.SeedingMode = 'Manual'

            $mockAvailabilityGroupReplica3 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityReplica
            $mockAvailabilityGroupReplica3.AvailabilityMode = 'AsynchronousCommit'
            $mockAvailabilityGroupReplica3.BackupPriority = 50
            $mockAvailabilityGroupReplica3.ConnectionModeInPrimaryRole = 'AllowAllConnections'
            $mockAvailabilityGroupReplica3.ConnectionModeInSecondaryRole = 'AllowNoConnections'
            $mockAvailabilityGroupReplica3.EndpointUrl = 'TCP://Server3:5022'
            $mockAvailabilityGroupReplica3.FailoverMode = 'Manual'
            $mockAvailabilityGroupReplica3.Name = 'Server3'
            $mockAvailabilityGroupReplica3.ReadOnlyRoutingConnectionUrl = 'TCP://Server3.domain.com:1433'
            $mockAvailabilityGroupReplica3.ReadOnlyRoutingList = @('Server1', 'Server2')
            $mockAvailabilityGroupReplica3.SeedingMode = 'Manual'

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
        Mock -CommandName New-SqlAvailabilityReplica
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

                $getTargetResourceResult.AvailabilityGroupName | Should -Be 'AbsentAG'
                $getTargetResourceResult.AvailabilityMode | Should -BeNullOrEmpty
                $getTargetResourceResult.BackupPriority | Should -BeNullOrEmpty
                $getTargetResourceResult.ConnectionModeInPrimaryRole | Should -BeNullOrEmpty
                $getTargetResourceResult.ConnectionModeInSecondaryRole | Should -BeNullOrEmpty
                $getTargetResourceResult.EndpointUrl | Should -BeNullOrEmpty
                $getTargetResourceResult.EndpointPort | Should -Be 5022
                $getTargetResourceResult.Ensure | Should -Be 'Absent'
                $getTargetResourceResult.FailoverMode | Should -BeNullOrEmpty
                $getTargetResourceResult.Name | Should -Be 'Server1'
                $getTargetResourceResult.ReadOnlyRoutingConnectionUrl | Should -BeNullOrEmpty
                $getTargetResourceResult.ReadOnlyRoutingList | Should -BeNullOrEmpty
                $getTargetResourceResult.ServerName | Should -Be 'Server1'
                $getTargetResourceResult.InstanceName | Should -Be 'MSSQLSERVER'
                $getTargetResourceResult.EndpointHostName | Should -Be 'Server1'
                $getTargetResourceResult.SeedingMode | Should -BeNullOrEmpty
            }

            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
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
                $getTargetResourceResult.SeedingMode | Should -Be 'Manual'
            }

            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }
    }
}

Describe 'SqlAGReplica\Set-TargetResource' {
    BeforeAll {
        $mockConnectSqlServer1 = {
            # Mock the server object
            $mockServerObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server
            $mockServerObject.Name = 'Server1'
            $mockServerObject.NetName = 'Server1'
            $mockServerObject.IsHadrEnabled = $true
            $mockServerObject.ServiceName = 'MSSQLSERVER'
            $mockServerObject.Version = @{
                Major = 13
            }

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
            $mockAvailabilityGroupReplica1.SeedingMode = 'Manual'

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
            $mockAvailabilityGroupReplica2.SeedingMode = 'Manual'

            $mockAvailabilityGroupReplica3 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityReplica
            $mockAvailabilityGroupReplica3.AvailabilityMode = 'AsynchronousCommit'
            $mockAvailabilityGroupReplica3.BackupPriority = 50
            $mockAvailabilityGroupReplica3.ConnectionModeInPrimaryRole = 'AllowAllConnections'
            $mockAvailabilityGroupReplica3.ConnectionModeInSecondaryRole = 'AllowNoConnections'
            $mockAvailabilityGroupReplica3.EndpointUrl = 'TCP://Server3:5022'
            $mockAvailabilityGroupReplica3.FailoverMode = 'Manual'
            $mockAvailabilityGroupReplica3.Name = 'Server3'
            $mockAvailabilityGroupReplica3.ReadOnlyRoutingConnectionUrl = 'TCP://Server3.domain.com:1433'
            $mockAvailabilityGroupReplica3.ReadOnlyRoutingList = @('Server1', 'Server2')
            $mockAvailabilityGroupReplica3.SeedingMode = 'Manual'

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

        $mockConnectSqlServer2 = {
            # Mock the server object
            $mockServerObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server
            $mockServerObject.Name = 'Server2'
            $mockServerObject.NetName = 'Server2'
            $mockServerObject.IsHadrEnabled = $true
            $mockServerObject.ServiceName = 'MSSQLSERVER'
            $mockServerObject.Version = @{
                Major = 13
            }

            #region Mock the availability group replicas
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
            $mockAvailabilityGroupReplica1.SeedingMode = 'Manual'

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
            $mockAvailabilityGroupReplica2.SeedingMode = 'Manual'

            $mockAvailabilityGroupReplica3 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityReplica
            $mockAvailabilityGroupReplica3.AvailabilityMode = 'AsynchronousCommit'
            $mockAvailabilityGroupReplica3.BackupPriority = 50
            $mockAvailabilityGroupReplica3.ConnectionModeInPrimaryRole = 'AllowAllConnections'
            $mockAvailabilityGroupReplica3.ConnectionModeInSecondaryRole = 'AllowNoConnections'
            $mockAvailabilityGroupReplica3.EndpointUrl = 'TCP://Server3:5022'
            $mockAvailabilityGroupReplica3.FailoverMode = 'Manual'
            $mockAvailabilityGroupReplica3.Name = 'Server3'
            $mockAvailabilityGroupReplica3.ReadOnlyRoutingConnectionUrl = 'TCP://Server3.domain.com:1433'
            $mockAvailabilityGroupReplica3.ReadOnlyRoutingList = @('Server1', 'Server2')
            $mockAvailabilityGroupReplica3.SeedingMode = 'Manual'
            #endregion Mock the availability group replicas

            # Mock the availability groups
            $mockAvailabilityGroup1 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityGroup
            $mockAvailabilityGroup1.Name = 'AG_AllServers'
            $mockAvailabilityGroup1.PrimaryReplicaServerName = 'Server2'
            $mockAvailabilityGroup1.LocalReplicaRole = 'Primary'
            $mockAvailabilityGroup1.AvailabilityReplicas.Add($mockAvailabilityGroupReplica1)
            $mockAvailabilityGroup1.AvailabilityReplicas.Add($mockAvailabilityGroupReplica2)
            $mockAvailabilityGroup1.AvailabilityReplicas.Add($mockAvailabilityGroupReplica3)
            $mockServerObject.AvailabilityGroups.Add($mockAvailabilityGroup1)

            $mockAvailabilityGroup2 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityGroup
            $mockAvailabilityGroup2.Name = 'AG_PrimaryOnServer2'
            $mockAvailabilityGroup2.PrimaryReplicaServerName = 'Server2'
            $mockAvailabilityGroup2.LocalReplicaRole = 'Primary'
            $mockAvailabilityGroup2.AvailabilityReplicas.Add($mockAvailabilityGroupReplica2)
            $mockAvailabilityGroup2.AvailabilityReplicas.Add($mockAvailabilityGroupReplica3)
            $mockServerObject.AvailabilityGroups.Add($mockAvailabilityGroup2)

            $mockAvailabilityGroup3 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityGroup
            $mockAvailabilityGroup3.Name = 'AG_PrimaryOnServer3'
            $mockAvailabilityGroup3.PrimaryReplicaServerName = 'Server3'
            $mockAvailabilityGroup3.LocalReplicaRole = 'Secondary'
            $mockAvailabilityGroup3.AvailabilityReplicas.Add($mockAvailabilityGroupReplica2)
            $mockAvailabilityGroup3.AvailabilityReplicas.Add($mockAvailabilityGroupReplica3)
            $mockServerObject.AvailabilityGroups.Add($mockAvailabilityGroup3)

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

        $mockConnectSqlServer3 = {
            # Mock the server object
            $mockServerObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server
            $mockServerObject.Name = 'Server3'
            $mockServerObject.NetName = 'Server3'
            $mockServerObject.IsHadrEnabled = $true
            $mockServerObject.ServiceName = 'MSSQLSERVER'
            $mockServerObject.Version = @{
                Major = 13
            }

            #region Mock the availability group replicas
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
            $mockAvailabilityGroupReplica1.SeedingMode = 'Manual'

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
            $mockAvailabilityGroupReplica2.SeedingMode = 'Manual'

            $mockAvailabilityGroupReplica3 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityReplica
            $mockAvailabilityGroupReplica3.AvailabilityMode = 'AsynchronousCommit'
            $mockAvailabilityGroupReplica3.BackupPriority = 50
            $mockAvailabilityGroupReplica3.ConnectionModeInPrimaryRole = 'AllowAllConnections'
            $mockAvailabilityGroupReplica3.ConnectionModeInSecondaryRole = 'AllowNoConnections'
            $mockAvailabilityGroupReplica3.EndpointUrl = 'TCP://Server3:5022'
            $mockAvailabilityGroupReplica3.FailoverMode = 'Manual'
            $mockAvailabilityGroupReplica3.Name = 'Server3'
            $mockAvailabilityGroupReplica3.ReadOnlyRoutingConnectionUrl = 'TCP://Server3.domain.com:1433'
            $mockAvailabilityGroupReplica3.ReadOnlyRoutingList = @('Server1', 'Server2')
            $mockAvailabilityGroupReplica3.SeedingMode = 'Manual'
            #endregion Mock the availability group replicas

            # Mock the availability groups
            $mockAvailabilityGroup1 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityGroup
            $mockAvailabilityGroup1.Name = 'AG_AllServers'
            $mockAvailabilityGroup1.PrimaryReplicaServerName = 'Server2'
            $mockAvailabilityGroup1.LocalReplicaRole = 'Secondary'
            $mockAvailabilityGroup1.AvailabilityReplicas.Add($mockAvailabilityGroupReplica1)
            $mockAvailabilityGroup1.AvailabilityReplicas.Add($mockAvailabilityGroupReplica2)
            $mockAvailabilityGroup1.AvailabilityReplicas.Add($mockAvailabilityGroupReplica3)
            $mockServerObject.AvailabilityGroups.Add($mockAvailabilityGroup1)

            $mockAvailabilityGroup2 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityGroup
            $mockAvailabilityGroup2.Name = 'AG_PrimaryOnServer2'
            $mockAvailabilityGroup2.PrimaryReplicaServerName = 'Server2'
            $mockAvailabilityGroup2.LocalReplicaRole = 'Secondary'
            $mockAvailabilityGroup2.AvailabilityReplicas.Add($mockAvailabilityGroupReplica2)
            $mockAvailabilityGroup2.AvailabilityReplicas.Add($mockAvailabilityGroupReplica3)
            $mockServerObject.AvailabilityGroups.Add($mockAvailabilityGroup2)

            $mockAvailabilityGroup3 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityGroup
            $mockAvailabilityGroup3.Name = 'AG_PrimaryOnServer3'
            $mockAvailabilityGroup3.PrimaryReplicaServerName = 'Server3'
            $mockAvailabilityGroup3.LocalReplicaRole = 'Primary'
            $mockAvailabilityGroup3.AvailabilityReplicas.Add($mockAvailabilityGroupReplica2)
            $mockAvailabilityGroup3.AvailabilityReplicas.Add($mockAvailabilityGroupReplica3)
            $mockServerObject.AvailabilityGroups.Add($mockAvailabilityGroup3)

            # Mock the mirroring endpoint if required
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

        Mock -CommandName Import-SqlDscPreferredModule

        Mock -CommandName Connect-SQL -MockWith $mockConnectSqlServer1 -ParameterFilter {
            $ServerName -eq 'Server1'
        }

        Mock -CommandName Connect-SQL -MockWith $mockConnectSqlServer2 -ParameterFilter {
            $ServerName -eq 'Server2'
        }

        Mock -CommandName Connect-SQL -MockWith $mockConnectSqlServer3 -ParameterFilter {
            $ServerName -eq 'Server3'
        }

        Mock -CommandName Get-PrimaryReplicaServerObject -MockWith $mockConnectSqlServer1 -ParameterFilter {
            $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1'
        }

        Mock -CommandName Get-PrimaryReplicaServerObject -MockWith $mockConnectSqlServer2 -ParameterFilter {
            $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2'
        }

        Mock -CommandName Get-PrimaryReplicaServerObject -MockWith $mockConnectSqlServer3 -ParameterFilter {
            $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server3'
        }

        Mock -CommandName Join-SqlAvailabilityGroup
        Mock -CommandName New-SqlAvailabilityReplica
        Mock -CommandName Test-ClusterPermissions
    }

    Context 'When the desired state is absent' {
        Context 'When the availability group exist' {
            BeforeAll {
                Mock -CommandName Update-AvailabilityGroupReplica
                Mock -CommandName Remove-SqlAvailabilityReplica
            }

            It 'Should silently remove the availability group replica' {
                InModuleScope -ScriptBlock {
                    $setTargetResourceParameters = @{
                        Name                  = 'Server1'
                        AvailabilityGroupName = 'AG_AllServers'
                        ServerName            = 'Server1'
                        InstanceName          = 'MSSQLSERVER'
                        Ensure                = 'Absent'
                    }

                    { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
                    $ServerName -eq 'Server1'
                } -Times 1 -Exactly

                Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
                    $ServerName -eq 'Server2'
                } -Times 0 -Exactly

                Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
                    $ServerName -eq 'Server3'
                } -Times 0 -Exactly

                Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
                    $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1'
                }

                Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 1 -Exactly -ParameterFilter {
                    $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2'
                }

                Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
                    $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server3'
                }

                Should -Invoke -CommandName Import-SqlDscPreferredModule -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Join-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Should -Invoke -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                Should -Invoke -CommandName Remove-SqlAvailabilityReplica -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Test-ClusterPermissions -Scope It -Times 0 -Exactly
                Should -Invoke -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
            }
        }

        Context 'When the removal of the availability group replica fails' {
            BeforeAll {
                Mock -CommandName Update-AvailabilityGroupReplica
                Mock -CommandName Remove-SqlAvailabilityReplica -MockWith {
                    throw 'RemoveAvailabilityGroupReplicaFailed'
                }
            }

            It 'Should throw the correct error (RemoveAvailabilityGroupReplicaFailed)' {
                InModuleScope -ScriptBlock {
                    $setTargetResourceParameters = @{
                        Name                  = 'Server1'
                        AvailabilityGroupName = 'AG_AllServers'
                        ServerName            = 'Server1'
                        InstanceName          = 'MSSQLSERVER'
                        Ensure                = 'Absent'
                    }

                    $mockErrorMessage = Get-InvalidOperationRecord -Message (
                        ($script:localizedData.FailedRemoveAvailabilityGroupReplica -f $setTargetResourceParameters.Name, $setTargetResourceParameters.AvailabilityGroupName, $setTargetResourceParameters.InstanceName) + "*"
                    )
                    { Set-TargetResource @setTargetResourceParameters } | Should -Throw -ExpectedMessage $mockErrorMessage
                }

                Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
                    $ServerName -eq 'Server1'
                } -Times 1 -Exactly

                Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
                    $ServerName -eq 'Server2'
                } -Times 0 -Exactly

                Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
                    $ServerName -eq 'Server3'
                } -Times 0 -Exactly

                Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
                    $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1'
                }

                Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 1 -Exactly -ParameterFilter {
                    $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2'
                }

                Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
                    $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server3'
                }

                Should -Invoke -CommandName Import-SqlDscPreferredModule -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Join-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Should -Invoke -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                Should -Invoke -CommandName Remove-SqlAvailabilityReplica -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Test-ClusterPermissions -Scope It -Times 0 -Exactly
                Should -Invoke -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
            }
        }
    }

    Context 'When HADR is not enabled' { # cSpell: disable-line
        BeforeAll {
            $mockServerObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server
            $mockServerObject.Name = 'ServerNotEnabled'
            $mockServerObject.NetName = 'ServerNotEnabled'
            $mockServerObject.IsHadrEnabled = $false
            $mockServerObject.ServiceName = 'MSSQLSERVER'

            Mock -CommandName Connect-SQL -MockWith {
                return $mockServerObject
            } -ParameterFilter {
                $ServerName -eq 'ServerNotEnabled'
            }
        }

        It 'Should throw the correct error' { # cSpell: disable-line
            InModuleScope -ScriptBlock {
                $setTargetResourceParameters = @{
                    Name                  = 'ServerNotEnabled'
                    AvailabilityGroupName = 'AG_PrimaryOnServer2'
                    ServerName            = 'ServerNotEnabled'
                    InstanceName          = 'MSSQLSERVER'
                }

                $mockErrorRecord = Get-InvalidOperationRecord -Message (
                    $script:localizedData.HadrNotEnabled # cSpell: disable-line
                )

                { Set-TargetResource @setTargetResourceParameters } | Should -Throw -ExpectedMessage $mockErrorRecord
            }

            Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
                $ServerName -eq 'ServerNotEnabled'
            } -Times 1 -Exactly

            Should -Invoke -CommandName Import-SqlDscPreferredModule -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the database mirroring endpoint is absent' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server
            $mockServerObject.Name = 'ServerWithoutEndpoint'
            $mockServerObject.NetName = 'ServerWithoutEndpoint'
            $mockServerObject.IsHadrEnabled = $true
            $mockServerObject.ServiceName = 'MSSQLSERVER'

            Mock -CommandName Connect-SQL -MockWith {
                return $mockServerObject
            } -ParameterFilter {
                $ServerName -eq 'ServerWithoutEndpoint'
            }
        }

        It 'Should throw the correct error' { # cSpell: disable-line
            InModuleScope -ScriptBlock {
                $setTargetResourceParameters = @{
                    Name                  = 'ServerWithoutEndpoint'
                    AvailabilityGroupName = 'AG_PrimaryOnServer2'
                    ServerName            = 'ServerWithoutEndpoint'
                    InstanceName          = 'MSSQLSERVER'
                }

                $mockErrorRecord = Get-ObjectNotFoundRecord -Message (
                    $script:localizedData.DatabaseMirroringEndpointNotFound -f 'ServerWithoutEndpoint\MSSQLSERVER'
                )

                { Set-TargetResource @setTargetResourceParameters } | Should -Throw -ExpectedMessage $mockErrorRecord
            }

            Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
                $ServerName -eq 'ServerWithoutEndpoint'
            } -Times 1 -Exactly

            Should -Invoke -CommandName Import-SqlDscPreferredModule -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the desired state is present and the availability group is absent' {
        BeforeAll {
            Mock -CommandName Remove-SqlAvailabilityReplica
            Mock -CommandName Update-AvailabilityGroupReplica
        }

        It 'Should create the availability group replica' {
            InModuleScope -ScriptBlock {
                $setTargetResourceParameters = @{
                    Name                          = 'Server1'
                    AvailabilityGroupName         = 'AG_PrimaryOnServer2'
                    ServerName                    = 'Server1'
                    InstanceName                  = 'MSSQLSERVER'
                    PrimaryReplicaServerName      = 'Server2'
                    PrimaryReplicaInstanceName    = 'MSSQLSERVER'
                    Ensure                        = 'Present'
                    AvailabilityMode              = 'AsynchronousCommit'
                    BackupPriority                = 50
                    ConnectionModeInPrimaryRole   = 'AllowAllConnections'
                    ConnectionModeInSecondaryRole = 'AllowNoConnections'
                    EndpointHostName              = 'Server1'
                    FailoverMode                  = 'Manual'
                    ReadOnlyRoutingConnectionUrl  = 'TCP://Server1.domain.com:1433'
                    ReadOnlyRoutingList           = @('Server1', 'Server2')
                    SeedingMode                   = 'Manual'
                }

                { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
            }

            Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
                $ServerName -eq 'Server1'
            } -Times 1 -Exactly

            Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
                $ServerName -eq 'Server2'
            } -Times 1 -Exactly

            Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
                $ServerName -eq 'Server3'
            } -Times 0 -Exactly

            Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
                $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1'
            }

            Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 1 -Exactly -ParameterFilter {
                $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2'
            }

            Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
                $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server3'
            }

            Should -Invoke -CommandName Import-SqlDscPreferredModule -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Join-SqlAvailabilityGroup -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName New-SqlAvailabilityReplica -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Remove-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
            Should -Invoke -CommandName Test-ClusterPermissions -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
        }

        Context 'When the endpoint hostname is not defined' {
            It 'Should create the availability group replica' {
                InModuleScope -ScriptBlock {
                    $setTargetResourceParameters = @{
                        Name                          = 'Server1'
                        AvailabilityGroupName         = 'AG_PrimaryOnServer2'
                        ServerName                    = 'Server1'
                        InstanceName                  = 'MSSQLSERVER'
                        PrimaryReplicaServerName      = 'Server2'
                        PrimaryReplicaInstanceName    = 'MSSQLSERVER'
                        Ensure                        = 'Present'
                        AvailabilityMode              = 'AsynchronousCommit'
                        BackupPriority                = 50
                        ConnectionModeInPrimaryRole   = 'AllowAllConnections'
                        ConnectionModeInSecondaryRole = 'AllowNoConnections'
                        EndpointHostName              = ''
                        FailoverMode                  = 'Manual'
                        ReadOnlyRoutingConnectionUrl  = 'TCP://Server1.domain.com:1433'
                        ReadOnlyRoutingList           = @('Server1', 'Server2')
                        SeedingMode                   = 'Manual'
                    }

                    { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
                    $ServerName -eq 'Server1'
                } -Times 1 -Exactly

                Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
                    $ServerName -eq 'Server2'
                } -Times 1 -Exactly

                Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
                    $ServerName -eq 'Server3'
                } -Times 0 -Exactly

                Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
                    $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1'
                }

                Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 1 -Exactly -ParameterFilter {
                    $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2'
                }

                Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
                    $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server3'
                }

                Should -Invoke -CommandName Import-SqlDscPreferredModule -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Join-SqlAvailabilityGroup -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName New-SqlAvailabilityReplica -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Remove-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                Should -Invoke -CommandName Test-ClusterPermissions -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
            }
        }

        Context 'When primary replica server is incorrectly supplied and the availability group exists' {
            It 'Should create the availability group replica' {
                InModuleScope -ScriptBlock {
                    $setTargetResourceParameters = @{
                        Name                          = 'Server1'
                        AvailabilityGroupName         = 'AG_PrimaryOnServer2'
                        ServerName                    = 'Server1'
                        InstanceName                  = 'MSSQLSERVER'
                        PrimaryReplicaServerName      = 'Server3'
                        PrimaryReplicaInstanceName    = 'MSSQLSERVER'
                        Ensure                        = 'Present'
                        AvailabilityMode              = 'AsynchronousCommit'
                        BackupPriority                = 50
                        ConnectionModeInPrimaryRole   = 'AllowAllConnections'
                        ConnectionModeInSecondaryRole = 'AllowNoConnections'
                        EndpointHostName              = ''
                        FailoverMode                  = 'Manual'
                        ReadOnlyRoutingConnectionUrl  = 'TCP://Server1.domain.com:1433'
                        ReadOnlyRoutingList           = @('Server1', 'Server2')
                        SeedingMode                   = 'Manual'
                    }

                    { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
                    $ServerName -eq 'Server1'
                } -Times 1 -Exactly

                Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
                    $ServerName -eq 'Server2'
                } -Times 0 -Exactly

                Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
                    $ServerName -eq 'Server3'
                } -Times 1 -Exactly

                Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
                    $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1'
                }

                Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 1 -Exactly -ParameterFilter {
                    $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2'
                }

                Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
                    $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server3'
                }

                Should -Invoke -CommandName Import-SqlDscPreferredModule -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Join-SqlAvailabilityGroup -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName New-SqlAvailabilityReplica -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Remove-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                Should -Invoke -CommandName Test-ClusterPermissions -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
            }
        }

        Context 'When the availability group replica fails to create' {
            BeforeAll {
                Mock -CommandName New-SqlAvailabilityReplica {
                    throw 'Mocked error'
                }
            }

            It 'Should throw the correct error' {
                InModuleScope -ScriptBlock {
                    $setTargetResourceParameters = @{
                        Name                          = 'Server1'
                        AvailabilityGroupName         = 'AG_PrimaryOnServer2'
                        ServerName                    = 'Server1'
                        InstanceName                  = 'MSSQLSERVER'
                        PrimaryReplicaServerName      = 'Server2'
                        PrimaryReplicaInstanceName    = 'MSSQLSERVER'
                        Ensure                        = 'Present'
                        AvailabilityMode              = 'AsynchronousCommit'
                        BackupPriority                = 50
                        ConnectionModeInPrimaryRole   = 'AllowAllConnections'
                        ConnectionModeInSecondaryRole = 'AllowNoConnections'
                        EndpointHostName              = ''
                        FailoverMode                  = 'Manual'
                        ReadOnlyRoutingConnectionUrl  = 'TCP://Server1.domain.com:1433'
                        ReadOnlyRoutingList           = @('Server1', 'Server2')
                        SeedingMode                   = 'Manual'
                    }

                    $mockErrorRecord = Get-InvalidOperationRecord -Message (
                        # Adding wildcard at the end of string so Pester ignores additional messages in the error message (e.g. the string 'Mocked error')
                        ($script:localizedData.FailedCreateAvailabilityGroupReplica -f 'Server1', 'AG_PrimaryOnServer2', 'MSSQLSERVER') + '*'
                    )

                    { Set-TargetResource @setTargetResourceParameters } | Should -Throw -ExpectedMessage $mockErrorRecord
                }

                Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
                    $ServerName -eq 'Server1'
                } -Times 1 -Exactly

                Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
                    $ServerName -eq 'Server2'
                } -Times 1 -Exactly

                Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
                    $ServerName -eq 'Server3'
                } -Times 0 -Exactly

                Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
                    $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1'
                }

                Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 1 -Exactly -ParameterFilter {
                    $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2'
                }

                Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
                    $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server3'
                }

                Should -Invoke -CommandName Import-SqlDscPreferredModule -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Join-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Should -Invoke -CommandName New-SqlAvailabilityReplica -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Remove-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                Should -Invoke -CommandName Test-ClusterPermissions -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
            }
        }

        Context 'When the availability group replica fails to join the availability group' {
            BeforeAll {
                Mock -CommandName Join-SqlAvailabilityGroup {
                    throw 'Mocked error'
                }
            }

            It 'Should throw the correct error' {
                InModuleScope -ScriptBlock {
                    $setTargetResourceParameters = @{
                        Name                          = 'Server1'
                        AvailabilityGroupName         = 'AG_PrimaryOnServer2'
                        ServerName                    = 'Server1'
                        InstanceName                  = 'MSSQLSERVER'
                        PrimaryReplicaServerName      = 'Server2'
                        PrimaryReplicaInstanceName    = 'MSSQLSERVER'
                        Ensure                        = 'Present'
                        AvailabilityMode              = 'AsynchronousCommit'
                        BackupPriority                = 50
                        ConnectionModeInPrimaryRole   = 'AllowAllConnections'
                        ConnectionModeInSecondaryRole = 'AllowNoConnections'
                        EndpointHostName              = ''
                        FailoverMode                  = 'Manual'
                        ReadOnlyRoutingConnectionUrl  = 'TCP://Server1.domain.com:1433'
                        ReadOnlyRoutingList           = @('Server1', 'Server2')
                        SeedingMode                   = 'Manual'
                    }

                    $mockErrorRecord = Get-InvalidOperationRecord -Message (
                        # Adding wildcard at the end of string so Pester ignores additional messages in the error message (e.g. the string 'Mocked error')
                        ($script:localizedData.FailedJoinAvailabilityGroup -f 'Server1', 'AG_PrimaryOnServer2', 'MSSQLSERVER') + '*'
                    )

                    { Set-TargetResource @setTargetResourceParameters } | Should -Throw -ExpectedMessage $mockErrorRecord
                }

                Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
                    $ServerName -eq 'Server1'
                } -Times 1 -Exactly

                Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
                    $ServerName -eq 'Server2'
                } -Times 1 -Exactly

                Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
                    $ServerName -eq 'Server3'
                } -Times 0 -Exactly

                Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
                    $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1'
                }

                Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 1 -Exactly -ParameterFilter {
                    $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2'
                }

                Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
                    $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server3'
                }

                Should -Invoke -CommandName Import-SqlDscPreferredModule -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Join-SqlAvailabilityGroup -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName New-SqlAvailabilityReplica -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Remove-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                Should -Invoke -CommandName Test-ClusterPermissions -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
            }
        }

        Context 'When the availability group does not exist on the primary replica' {
            It 'Should throw the correct error' {
                InModuleScope -ScriptBlock {
                    $setTargetResourceParameters = @{
                        Name                          = 'Server1'
                        AvailabilityGroupName         = 'DoesNotExist'
                        ServerName                    = 'Server1'
                        InstanceName                  = 'MSSQLSERVER'
                        PrimaryReplicaServerName      = 'Server2'
                        PrimaryReplicaInstanceName    = 'MSSQLSERVER'
                        Ensure                        = 'Present'
                        AvailabilityMode              = 'AsynchronousCommit'
                        BackupPriority                = 50
                        ConnectionModeInPrimaryRole   = 'AllowAllConnections'
                        ConnectionModeInSecondaryRole = 'AllowNoConnections'
                        EndpointHostName              = ''
                        FailoverMode                  = 'Manual'
                        ReadOnlyRoutingConnectionUrl  = 'TCP://Server1.domain.com:1433'
                        ReadOnlyRoutingList           = @('Server1', 'Server2')
                        SeedingMode                   = 'Manual'
                    }

                    $mockErrorRecord = Get-ObjectNotFoundRecord -Message (
                        # Adding wildcard at the end of string so Pester ignores additional messages in the error message (e.g. the string 'Mocked error')
                        ($script:localizedData.AvailabilityGroupNotFound -f 'DoesNotExist', 'MSSQLSERVER') + '*'
                    )

                    { Set-TargetResource @setTargetResourceParameters } | Should -Throw -ExpectedMessage $mockErrorRecord
                }

                Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
                    $ServerName -eq 'Server1'
                } -Times 1 -Exactly

                Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
                    $ServerName -eq 'Server2'
                } -Times 1 -Exactly

                Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
                    $ServerName -eq 'Server3'
                } -Times 0 -Exactly

                Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
                    $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1'
                }

                Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
                    $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2'
                }

                Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
                    $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server3'
                }

                Should -Invoke -CommandName Import-SqlDscPreferredModule -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Join-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Should -Invoke -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                Should -Invoke -CommandName Remove-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                Should -Invoke -CommandName Test-ClusterPermissions -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Update-AvailabilityGroupReplica -Scope It -Times 0 -Exactly
            }
        }
    }

    Context 'When the desired state is present and the availability group is present' {
        Context 'When the availability group replica does not exist' {
            It 'Should throw the correct error' {
                InModuleScope -ScriptBlock {
                    $setTargetResourceParameters = @{
                        Name                          = 'ReplicaNotFound'
                        AvailabilityGroupName         = 'AG_AllServers'
                        ServerName                    = 'Server1'
                        InstanceName                  = 'MSSQLSERVER'
                        PrimaryReplicaServerName      = 'Server2'
                        PrimaryReplicaInstanceName    = 'MSSQLSERVER'
                        Ensure                        = 'Present'
                        AvailabilityMode              = 'AsynchronousCommit'
                        BackupPriority                = 50
                        ConnectionModeInPrimaryRole   = 'AllowAllConnections'
                        ConnectionModeInSecondaryRole = 'AllowNoConnections'
                        EndpointHostName              = 'ReplicaNotFound'
                        FailoverMode                  = 'Manual'
                        ReadOnlyRoutingConnectionUrl  = 'TCP://Server1.domain.com:1433'
                        ReadOnlyRoutingList           = @('Server1', 'Server2')
                        SeedingMode                   = 'Manual'
                    }

                    $mockErrorRecord = Get-ObjectNotFoundRecord -Message (
                        # Adding wildcard at the end of string so Pester ignores additional messages in the error message (e.g. the string 'Mocked error')
                        ($script:localizedData.ReplicaNotFound -f 'ReplicaNotFound', 'AG_AllServers', 'MSSQLSERVER') + '*'
                    )

                    { Set-TargetResource @setTargetResourceParameters } | Should -Throw -ExpectedMessage $mockErrorRecord
                }

                Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
                    $ServerName -eq 'Server1'
                } -Times 1 -Exactly

                Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
                    $ServerName -eq 'Server2'
                } -Times 0 -Exactly

                Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
                    $ServerName -eq 'Server3'
                } -Times 0 -Exactly

                Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
                    $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1'
                }

                Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 1 -Exactly -ParameterFilter {
                    $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2'
                }

                Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
                    $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server3'
                }

                Should -Invoke -CommandName Import-SqlDscPreferredModule -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Join-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Should -Invoke -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                Should -Invoke -CommandName Test-ClusterPermissions -Exactly -Times 1 -Scope It
            }
        }

        Context 'When property <MockPropertyName> is not in desired state' -ForEach @(
            @{
                MockPropertyName  = 'AvailabilityMode'
                MockPropertyValue = 'SynchronousCommit'
            }
            @{
                MockPropertyName  = 'BackupPriority'
                MockPropertyValue = 60
            }
            @{
                MockPropertyName  = 'ConnectionModeInPrimaryRole'
                MockPropertyValue = 'AllowReadWriteConnections'
            }
            @{
                MockPropertyName  = 'ConnectionModeInSecondaryRole'
                MockPropertyValue = 'AllowReadIntentConnectionsOnly'
            }
            @{
                MockPropertyName  = 'FailoverMode'
                MockPropertyValue = 'Automatic'
            }
            @{
                MockPropertyName  = 'ReadOnlyRoutingConnectionUrl'
                MockPropertyValue = 'TCP://TestHost.domain.com:1433'
            }
            @{
                MockPropertyName  = 'ReadOnlyRoutingList'
                MockPropertyValue = @('Server2', 'Server1')
            }
            @{
                MockPropertyName  = 'EndpointHostName'
                MockPropertyValue = 'AnotherEndpointHostName'
            }
            @{
                MockPropertyName  = 'SeedingMode'
                MockPropertyValue = 'Automatic'
            }
        ) {
            BeforeAll {
                Mock -CommandName Remove-SqlAvailabilityReplica
                Mock -CommandName Update-AvailabilityGroupReplica
            }

            It 'Should set the property to the desired state' {
                InModuleScope -Parameters $_ -ScriptBlock {
                    $setTargetResourceParameters = @{
                        Name                          = 'Server1'
                        AvailabilityGroupName         = 'AG_AllServers'
                        ServerName                    = 'Server1'
                        InstanceName                  = 'MSSQLSERVER'
                        PrimaryReplicaServerName      = 'Server2'
                        PrimaryReplicaInstanceName    = 'MSSQLSERVER'
                        Ensure                        = 'Present'
                        AvailabilityMode              = 'AsynchronousCommit'
                        BackupPriority                = 50
                        ConnectionModeInPrimaryRole   = 'AllowAllConnections'
                        ConnectionModeInSecondaryRole = 'AllowNoConnections'
                        EndpointHostName              = 'Server1'
                        FailoverMode                  = 'Manual'
                        ReadOnlyRoutingConnectionUrl  = 'TCP://Server1.domain.com:1433'
                        ReadOnlyRoutingList           = @('Server1', 'Server2')
                        SeedingMode                   = 'Manual'
                    }

                    $setTargetResourceParameters.$MockPropertyName = $MockPropertyValue

                    { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
                    $ServerName -eq 'Server1'
                } -Times 1 -Exactly

                Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
                    $ServerName -eq 'Server2'
                } -Times 0 -Exactly

                Should -Invoke -CommandName Connect-SQL -Scope It -ParameterFilter {
                    $ServerName -eq 'Server3'
                } -Times 0 -Exactly

                Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
                    $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server1'
                }

                Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 1 -Exactly -ParameterFilter {
                    $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server2'
                }

                Should -Invoke -CommandName Get-PrimaryReplicaServerObject -Scope It -Time 0 -Exactly -ParameterFilter {
                    $AvailabilityGroup.PrimaryReplicaServerName -eq 'Server3'
                }

                Should -Invoke -CommandName Import-SqlDscPreferredModule -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Join-SqlAvailabilityGroup -Scope It -Times 0 -Exactly
                Should -Invoke -CommandName New-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                Should -Invoke -CommandName Remove-SqlAvailabilityReplica -Scope It -Times 0 -Exactly
                Should -Invoke -CommandName Test-ClusterPermissions -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Update-AvailabilityGroupReplica -ParameterFilter {
                    switch ($MockPropertyName)
                    {
                        # ReadOnlyRoutingList is an array, so we have to evaluate it differently.
                        'ReadOnlyRoutingList'
                        {
                            # Verifies the command passes the array in the correct order.
                            $AvailabilityGroupReplica.$MockPropertyName.Count -eq 2 -and
                            $AvailabilityGroupReplica.$MockPropertyName[0] -eq 'Server2' -and
                            $AvailabilityGroupReplica.$MockPropertyName[1] -eq 'Server1'

                            break
                        }

                        # EndpointHostName changes a different property name.
                        'EndpointHostName'
                        {
                            # Verifies the command passes the array in the correct order.
                            $AvailabilityGroupReplica.EndpointUrl -eq 'TCP://AnotherEndpointHostName:5022'

                            break
                        }

                        default
                        {
                            $AvailabilityGroupReplica.$MockPropertyName -eq $MockPropertyValue
                        }
                    }
                } -Exactly -Times 1 -Scope It
            }
        }

        Context 'When multiple properties are not in desired state' {
            BeforeAll {
                Mock -CommandName Update-AvailabilityGroupReplica
            }

            It 'Should set all properties with one update' {
                InModuleScope -Parameters $_ -ScriptBlock {
                    $setTargetResourceParameters = @{
                        Name                          = 'Server1'
                        AvailabilityGroupName         = 'AG_AllServers'
                        ServerName                    = 'Server1'
                        InstanceName                  = 'MSSQLSERVER'
                        PrimaryReplicaServerName      = 'Server2'
                        PrimaryReplicaInstanceName    = 'MSSQLSERVER'
                        Ensure                        = 'Present'
                        AvailabilityMode              = 'SynchronousCommit'
                        BackupPriority                = 60
                        ConnectionModeInPrimaryRole   = 'AllowReadWriteConnections'
                        ConnectionModeInSecondaryRole = 'AllowReadIntentConnectionsOnly'
                        EndpointHostName              = 'AnotherEndpointHostName'
                        FailoverMode                  = 'Automatic'
                        ReadOnlyRoutingConnectionUrl  = 'TCP://Server1.domain.com:1433'
                        ReadOnlyRoutingList           = @('Server2', 'Server1')
                        SeedingMode                   = 'Manual'
                    }

                    { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Update-AvailabilityGroupReplica -Exactly -Times 1 -Scope It
            }
        }

        Context 'When AvailabilityMode and FailoverMode properties are not in desired state' {
            BeforeAll {
                Mock -CommandName Update-AvailabilityGroupReplica
            }

            It 'Should set both properties with one update' {
                InModuleScope -Parameters $_ -ScriptBlock {
                    $setTargetResourceParameters = @{
                        Name                          = 'Server1'
                        AvailabilityGroupName         = 'AG_AllServers'
                        ServerName                    = 'Server1'
                        InstanceName                  = 'MSSQLSERVER'
                        PrimaryReplicaServerName      = 'Server2'
                        PrimaryReplicaInstanceName    = 'MSSQLSERVER'
                        Ensure                        = 'Present'
                        AvailabilityMode              = 'SynchronousCommit'
                        BackupPriority                = 50
                        ConnectionModeInPrimaryRole   = 'AllowAllConnections'
                        ConnectionModeInSecondaryRole = 'AllowNoConnections'
                        EndpointHostName              = 'Server1'
                        FailoverMode                  = 'Automatic'
                        ReadOnlyRoutingConnectionUrl  = 'TCP://Server1.domain.com:1433'
                        ReadOnlyRoutingList           = @('Server1', 'Server2')
                        SeedingMode                   = 'Manual'
                    }

                    { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Update-AvailabilityGroupReplica -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the endpoint port differ from the port in the replica''s endpoint URL' {
            BeforeAll {
                Mock -CommandName Update-AvailabilityGroupReplica

                Mock -CommandName Connect-Sql -ParameterFilter {
                    $ServerName -eq 'Server10'
                } -MockWith {
                    # Mock the server object
                    $mockServerObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server
                    $mockServerObject.Name = 'Server10'
                    $mockServerObject.NetName = 'Server10'
                    $mockServerObject.IsHadrEnabled = $true
                    $mockServerObject.ServiceName = 'MSSQLSERVER'

                    # Mock the availability group replicas
                    $mockAvailabilityGroupReplica1 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityReplica
                    $mockAvailabilityGroupReplica1.EndpointUrl = 'TCP://Server10:1234'
                    $mockAvailabilityGroupReplica1.Name = 'Server10'

                    # Mock the availability groups
                    $mockAvailabilityGroup1 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityGroup
                    $mockAvailabilityGroup1.Name = 'AG_AllServers'
                    $mockAvailabilityGroup1.PrimaryReplicaServerName = 'Server1'
                    $mockAvailabilityGroup1.LocalReplicaRole = 'Primary'
                    $mockAvailabilityGroup1.AvailabilityReplicas.Add($mockAvailabilityGroupReplica1)
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
            }

            It 'Should set the replica''s endpoint URL to use the same port as the endpoint' {
                InModuleScope -Parameters $_ -ScriptBlock {
                    $setTargetResourceParameters = @{
                        Name                  = 'Server10'
                        AvailabilityGroupName = 'AG_AllServers'
                        ServerName            = 'Server10'
                        InstanceName          = 'MSSQLSERVER'
                        Ensure                = 'Present'
                        EndpointHostName      = 'Server10'
                    }

                    { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Update-AvailabilityGroupReplica -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the endpoint protocol differ from the protocol in the replica''s endpoint URL' {
            BeforeAll {
                Mock -CommandName Update-AvailabilityGroupReplica

                Mock -CommandName Connect-Sql -ParameterFilter {
                    $ServerName -eq 'Server10'
                } -MockWith {
                    # Mock the server object
                    $mockServerObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server
                    $mockServerObject.Name = 'Server10'
                    $mockServerObject.NetName = 'Server10'
                    $mockServerObject.IsHadrEnabled = $true
                    $mockServerObject.ServiceName = 'MSSQLSERVER'

                    # Mock the availability group replicas
                    $mockAvailabilityGroupReplica1 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityReplica
                    $mockAvailabilityGroupReplica1.EndpointUrl = 'UDP://Server10:5022'
                    $mockAvailabilityGroupReplica1.Name = 'Server10'

                    # Mock the availability groups
                    $mockAvailabilityGroup1 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityGroup
                    $mockAvailabilityGroup1.Name = 'AG_AllServers'
                    $mockAvailabilityGroup1.PrimaryReplicaServerName = 'Server1'
                    $mockAvailabilityGroup1.LocalReplicaRole = 'Primary'
                    $mockAvailabilityGroup1.AvailabilityReplicas.Add($mockAvailabilityGroupReplica1)
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
            }

            It 'Should set the replica''s endpoint URL to use the same port as the endpoint' {
                InModuleScope -Parameters $_ -ScriptBlock {
                    $setTargetResourceParameters = @{
                        Name                  = 'Server10'
                        AvailabilityGroupName = 'AG_AllServers'
                        ServerName            = 'Server10'
                        InstanceName          = 'MSSQLSERVER'
                        Ensure                = 'Present'
                        EndpointHostName      = 'Server10'
                    }

                    { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Update-AvailabilityGroupReplica -Exactly -Times 1 -Scope It
            }
        }
    }
}

Describe 'SqlAGReplica\Test-TargetResource' {
    Context 'When the system is in the desired state' {
        Context 'When the Availability Replica should be absent' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    @{
                        Name                  = 'Server1'
                        AvailabilityGroupName = 'AG_AllServers'
                        ServerName            = 'Server1'
                        InstanceName          = 'MSSQLSERVER'
                        Ensure                = 'Absent'
                    }
                }
            }

            It 'Should return $true' {
                InModuleScope -ScriptBlock {
                    $mockTestTargetResourceParameters = @{
                        Ensure                = 'Absent'
                        Name                  = 'Server1'
                        AvailabilityGroupName = 'AG_AllServers'
                        ServerName            = 'Server1'
                        InstanceName          = 'MSSQLSERVER'
                    }

                    Test-TargetResource @mockTestTargetResourceParameters | Should -BeTrue
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the Availability Replica should be present' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    @{
                        Name                  = 'Server1'
                        AvailabilityGroupName = 'AG_AllServers'
                        ServerName            = 'Server1'
                        InstanceName          = 'MSSQLSERVER'
                        Ensure                = 'Present'
                        EndpointPort          = '5022'
                        EndpointUrl           = 'TCP://Server1:5022'
                    }
                }
            }

            It 'Should return $true' {
                InModuleScope -ScriptBlock {
                    $mockTestTargetResourceParameters = @{
                        Name                  = 'Server1'
                        AvailabilityGroupName = 'AG_AllServers'
                        ServerName            = 'Server1'
                        InstanceName          = 'MSSQLSERVER'
                    }

                    Test-TargetResource @mockTestTargetResourceParameters | Should -BeTrue
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When the system is not in the desired state' {
        Context 'When the Availability Replica should be absent' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    @{
                        Name                  = 'Server1'
                        AvailabilityGroupName = 'AG_AllServers'
                        ServerName            = 'Server1'
                        InstanceName          = 'MSSQLSERVER'
                        Ensure                = 'Present'
                        EndpointPort          = '5022'
                        EndpointUrl           = 'TCP://Server1:5022'
                    }
                }
            }

            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    $mockTestTargetResourceParameters = @{
                        Ensure                = 'Absent'
                        Name                  = 'Server1'
                        AvailabilityGroupName = 'AG_AllServers'
                        ServerName            = 'Server1'
                        InstanceName          = 'MSSQLSERVER'
                    }

                    Test-TargetResource @mockTestTargetResourceParameters | Should -BeFalse
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the Availability Replica should be present' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    @{
                        Name                  = 'Server1'
                        AvailabilityGroupName = 'AG_AllServers'
                        ServerName            = 'Server1'
                        InstanceName          = 'MSSQLSERVER'
                        Ensure                = 'Absent'
                    }
                }
            }

            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    $mockTestTargetResourceParameters = @{
                        Name                  = 'Server1'
                        AvailabilityGroupName = 'AG_AllServers'
                        ServerName            = 'Server1'
                        InstanceName          = 'MSSQLSERVER'
                    }

                    Test-TargetResource @mockTestTargetResourceParameters | Should -BeFalse
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }

        Context 'When enforcing the state shall happen only when the node is the active node' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    @{
                        Name                  = 'Server1'
                        AvailabilityGroupName = 'AG_AllServers'
                        ServerName            = 'Server1'
                        InstanceName          = 'MSSQLSERVER'
                        Ensure                = 'Present'
                        EndpointPort          = '5022'
                        EndpointUrl           = 'TCP://Server1:5022'
                        IsActiveNode          = $false
                    }
                }
            }

            It 'Should return $true' {
                InModuleScope -ScriptBlock {
                    $mockTestTargetResourceParameters = @{
                        Ensure                  = 'Absent'
                        Name                    = 'Server1'
                        AvailabilityGroupName   = 'AG_AllServers'
                        ServerName              = 'Server1'
                        InstanceName            = 'MSSQLSERVER'
                        ProcessOnlyOnActiveNode = $true
                    }

                    Test-TargetResource @mockTestTargetResourceParameters | Should -BeTrue
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }

        Context 'When property <MockPropertyName> is not in desired state' -ForEach @(
            @{
                MockPropertyName  = 'EndpointHostName'
                MockPropertyValue = 'Server2'
            }
            @{
                MockPropertyName  = 'AvailabilityMode'
                MockPropertyValue = 'SynchronousCommit'
            }
            @{
                MockPropertyName  = 'BackupPriority'
                MockPropertyValue = 60
            }
            @{
                MockPropertyName  = 'ConnectionModeInPrimaryRole'
                MockPropertyValue = 'AllowReadWriteConnections'
            }
            @{
                MockPropertyName  = 'ConnectionModeInSecondaryRole'
                MockPropertyValue = 'AllowReadIntentConnectionsOnly'
            }
            @{
                MockPropertyName  = 'FailoverMode'
                MockPropertyValue = 'Automatic'
            }
            @{
                MockPropertyName  = 'ReadOnlyRoutingConnectionUrl'
                MockPropertyValue = 'TCP://WrongHostname.domain.com:1433'
            }
            @{
                MockPropertyName  = 'ReadOnlyRoutingList'
                MockPropertyValue = @('Server2', 'Server1')
            }
            @{
                MockPropertyName  = 'SeedingMode'
                MockPropertyValue = 'Automatic'
            }
        ) {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    @{
                        Name                          = 'Server1'
                        AvailabilityGroupName         = 'AG_AllServers'
                        ServerName                    = 'Server1'
                        InstanceName                  = 'MSSQLSERVER'
                        Ensure                        = 'Present'
                        PrimaryReplicaServerName      = 'Server2'
                        PrimaryReplicaInstanceName    = 'MSSQLSERVER'
                        AvailabilityMode              = 'AsynchronousCommit'
                        BackupPriority                = 50
                        ConnectionModeInPrimaryRole   = 'AllowAllConnections'
                        ConnectionModeInSecondaryRole = 'AllowNoConnections'
                        EndpointHostName              = 'Server1'
                        FailoverMode                  = 'Manual'
                        ReadOnlyRoutingConnectionUrl  = 'TCP://Server1.domain.com:1433'
                        ReadOnlyRoutingList           = @('Server1', 'Server2')
                        SeedingMode                   = 'Manual'

                        # Read properties
                        EndpointPort                  = '5022'
                        EndpointUrl                   = 'TCP://Server1:5022'
                        IsActiveNode                  = $true
                    }
                }
            }

            It 'Should return $false' {
                InModuleScope -Parameters $_ -ScriptBlock {
                    $mockTestTargetResourceParameters = @{
                        Name                    = 'Server1'
                        AvailabilityGroupName   = 'AG_AllServers'
                        ServerName              = 'Server1'
                        InstanceName            = 'MSSQLSERVER'
                        ProcessOnlyOnActiveNode = $true
                    }

                    $mockTestTargetResourceParameters.$MockPropertyName = $MockPropertyValue

                    Test-TargetResource @mockTestTargetResourceParameters | Should -BeFalse
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }

        Context 'When endpoint port differ from the endpoint URL port' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    @{
                        Name                  = 'Server1'
                        AvailabilityGroupName = 'AG_AllServers'
                        ServerName            = 'Server1'
                        InstanceName          = 'MSSQLSERVER'
                        Ensure                = 'Present'

                        # Read properties
                        EndpointPort          = '5022'
                        EndpointUrl           = 'TCP://Server1:1433'
                        IsActiveNode          = $true
                    }
                }
            }

            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    $mockTestTargetResourceParameters = @{
                        Name                    = 'Server1'
                        AvailabilityGroupName   = 'AG_AllServers'
                        ServerName              = 'Server1'
                        InstanceName            = 'MSSQLSERVER'
                        ProcessOnlyOnActiveNode = $true
                    }

                    Test-TargetResource @mockTestTargetResourceParameters | Should -BeFalse
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }

        Context 'When endpoint protocol differ from the endpoint URL protocol' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    @{
                        Name                  = 'Server1'
                        AvailabilityGroupName = 'AG_AllServers'
                        ServerName            = 'Server1'
                        InstanceName          = 'MSSQLSERVER'
                        Ensure                = 'Present'

                        # Read properties
                        EndpointPort          = '5022'
                        EndpointUrl           = 'UDP://Server1:5022'
                        IsActiveNode          = $true
                    }
                }
            }

            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    $mockTestTargetResourceParameters = @{
                        Name                    = 'Server1'
                        AvailabilityGroupName   = 'AG_AllServers'
                        ServerName              = 'Server1'
                        InstanceName            = 'MSSQLSERVER'
                        ProcessOnlyOnActiveNode = $true
                    }

                    Test-TargetResource @mockTestTargetResourceParameters | Should -BeFalse
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }
    }
}
