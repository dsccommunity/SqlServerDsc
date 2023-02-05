<#
    .SYNOPSIS
        Unit test for DSC_SqlEndpoint DSC resource.
#>

# Suppressing this rule because Script Analyzer does not understand Pester's syntax.
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
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
    $script:dscResourceName = 'DSC_SqlEndpoint'

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

Describe 'SqlEndpoint\Get-TargetResource' -Tag 'Get' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            # Default parameters that are used for the It-blocks.
            $script:mockDefaultParameters = @{
                InstanceName = 'MSSQLSERVER'
                ServerName   = 'localhost'
            }
        }
    }

    BeforeEach {
        InModuleScope -ScriptBlock {
            $script:mockGetTargetResourceParameters = $script:mockDefaultParameters.Clone()
        }
    }

    Context 'When the system is in the desired state' {
        Context 'When using a Database Mirroring endpoint' {
            BeforeAll {
                $mockEndpointObject = {
                    # TypeName: Microsoft.SqlServer.Management.Smo.Endpoint
                    return New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value 'DefaultEndpointMirror' -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'EndpointType' -Value 'DatabaseMirroring' -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'EndpointState' -Value 'Started' -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'ProtocolType' -Value $null -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'Owner' -Value 'sa' -PassThru |
                        Add-Member -MemberType ScriptProperty -Name 'Protocol' -Value {
                            return New-Object -TypeName Object |
                                Add-Member -MemberType ScriptProperty -Name 'Tcp' -Value {
                                    return New-Object -TypeName Object |
                                        Add-Member -MemberType NoteProperty -Name 'ListenerPort' -Value 5022 -PassThru |
                                        # 0.0.0.0 means listen on all IP addresses.
                                        Add-Member -MemberType NoteProperty -Name 'ListenerIPAddress' -Value '0.0.0.0' -PassThru -Force
                                } -PassThru -Force
                        } -PassThru |
                        Add-Member -MemberType ScriptProperty -Name 'Payload' -Value {
                            return New-Object -TypeName Object |
                                Add-Member -MemberType ScriptProperty -Name 'DatabaseMirroring' -Value {
                                    return New-Object -TypeName Object |
                                        Add-Member -MemberType NoteProperty -Name 'ServerMirroringRole' -Value $null -PassThru |
                                        Add-Member -MemberType NoteProperty -Name 'EndpointEncryption' -Value $null -PassThru |
                                        Add-Member -MemberType NoteProperty -Name 'EndpointEncryptionAlgorithm' -Value $null -PassThru -Force
                                } -PassThru -Force
                        } -PassThru -Force
                }

                $mockConnectSql = {
                    return New-Object -TypeName Object |
                        Add-Member -MemberType ScriptProperty -Name Endpoints -Value {
                            return @(
                                @{
                                    <#
                                        This executes the script block of $mockEndpointObject and returns
                                        a mocked Microsoft.SqlServer.Management.Smo.Endpoint
                                    #>
                                    'DefaultEndpointMirror' = & $mockEndpointObject
                                }
                            )
                        } -PassThru -Force
                }

                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL
            }

            Context 'When the endpoint should be absent' {
                BeforeEach {
                    InModuleScope -ScriptBlock {
                        $mockGetTargetResourceParameters.EndpointName = 'MissingEndpoint'
                        $mockGetTargetResourceParameters.EndpointType = 'DatabaseMirroring'
                    }
                }

                It 'Should have property Ensure set to absent' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.Ensure | Should -Be 'Absent'
                    }
                }

                It 'Should return the same values as passed as parameters' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.ServerName | Should -Be $mockGetTargetResourceParameters.ServerName
                        $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                        $result.EndpointType | Should -Be $mockGetTargetResourceParameters.EndpointType
                    }
                }

                It 'Should return the correct values in the rest of properties' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.EndpointName | Should -Be ''
                        $result.Port | Should -Be ''
                        $result.IpAddress | Should -Be ''
                        $result.Owner | Should -Be ''
                        $result.State | Should -BeNullOrEmpty
                        $result.IsMessageForwardingEnabled | Should -BeNullOrEmpty
                        $result.MessageForwardingSize | Should -BeNullOrEmpty
                    }
                }

                It 'Should call the mock function Connect-SQL' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        { Get-TargetResource @mockGetTargetResourceParameters } | Should -Not -Throw
                    }

                    Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the endpoint should be present' {
                BeforeEach {
                    InModuleScope -ScriptBlock {
                        $mockGetTargetResourceParameters.EndpointName = 'DefaultEndpointMirror'
                        $mockGetTargetResourceParameters.EndpointType = 'DatabaseMirroring'
                    }
                }

                It 'Should have property Ensure set to present' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.Ensure | Should -Be 'Present'
                    }
                }

                It 'Should return the same values as passed as parameters' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.ServerName | Should -Be $mockGetTargetResourceParameters.ServerName
                        $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                        $result.EndpointType | Should -Be $mockGetTargetResourceParameters.EndpointType
                    }
                }

                It 'Should return the correct values for the rest of the properties' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.EndpointName | Should -Be 'DefaultEndpointMirror'
                        $result.Port | Should -Be 5022
                        $result.IpAddress | Should -Be '0.0.0.0'
                        $result.Owner | Should -Be 'sa'
                        $result.State | Should -Be 'Started'
                        $result.IsMessageForwardingEnabled | Should -BeNullOrEmpty
                        $result.MessageForwardingSize | Should -BeNullOrEmpty
                    }
                }

                It 'Should call the mock function Connect-SQL' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        { Get-TargetResource @mockGetTargetResourceParameters } | Should -Not -Throw
                    }

                    Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When endpoint exist but with wrong endpoint type' {
                BeforeEach {
                    InModuleScope -ScriptBlock {
                        $mockGetTargetResourceParameters.EndpointName = 'DefaultEndpointMirror'
                        $mockGetTargetResourceParameters.EndpointType = 'ServiceBroker'
                    }
                }

                It 'Should throw the correct error' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $mockErrorMessage = $script:localizedData.EndpointFoundButWrongType -f $mockGetTargetResourceParameters.EndpointName, 'DatabaseMirroring', 'ServiceBroker'

                        { Get-TargetResource @mockGetTargetResourceParameters } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage)
                    }
                }
            }
        }

        Context 'When using a Service Broker endpoint' {
            BeforeAll {
                $mockEndpointObject = {
                    # TypeName: Microsoft.SqlServer.Management.Smo.Endpoint
                    return New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value 'SSBR' -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'EndpointType' -Value 'ServiceBroker' -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'EndpointState' -Value 'Started' -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'ProtocolType' -Value $null -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'Owner' -Value 'COMPANY\OtherAcct' -PassThru |
                        Add-Member -MemberType ScriptProperty -Name 'Protocol' -Value {
                            return New-Object -TypeName Object |
                                Add-Member -MemberType ScriptProperty -Name 'Tcp' -Value {
                                    return New-Object -TypeName Object |
                                        Add-Member -MemberType NoteProperty -Name 'ListenerPort' -Value 5023 -PassThru |
                                        # 0.0.0.0 means listen on all IP addresses.
                                        Add-Member -MemberType NoteProperty -Name 'ListenerIPAddress' -Value '192.168.0.20' -PassThru -Force
                                } -PassThru -Force
                        } -PassThru |
                        Add-Member -MemberType ScriptProperty -Name 'Payload' -Value {
                            return New-Object -TypeName Object |
                                Add-Member -MemberType ScriptProperty -Name 'ServiceBroker' -Value {
                                    return New-Object -TypeName Object |
                                        Add-Member -MemberType NoteProperty -Name 'EndpointEncryption' -Value $null -PassThru |
                                        Add-Member -MemberType NoteProperty -Name 'EndpointEncryptionAlgorithm' -Value $null -PassThru |
                                        Add-Member -MemberType NoteProperty -Name 'IsMessageForwardingEnabled' -Value $true -PassThru |
                                        Add-Member -MemberType NoteProperty -Name 'MessageForwardingSize' -Value 2 -PassThru -Force
                                } -PassThru -Force
                        } -PassThru -Force
                }

                $mockConnectSql = {
                    return New-Object -TypeName Object |
                        Add-Member -MemberType ScriptProperty -Name Endpoints -Value {
                            return @(
                                @{
                                    <#
                                        This executes the script block of $mockEndpointObject and returns
                                        a mocked Microsoft.SqlServer.Management.Smo.Endpoint
                                    #>
                                    'SSBR' =  & $mockEndpointObject
                                }
                            )
                        } -PassThru -Force
                }

                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL
            }

            Context 'When the endpoint should be absent' {
                BeforeEach {
                    InModuleScope -ScriptBlock {
                        $mockGetTargetResourceParameters.EndpointName = 'MissingEndpoint'
                        $mockGetTargetResourceParameters.EndpointType = 'ServiceBroker'
                    }
                }

                It 'Should have property Ensure set to absent' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.Ensure | Should -Be 'Absent'
                    }
                }

                It 'Should return the same values as passed as parameters' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.ServerName | Should -Be $mockGetTargetResourceParameters.ServerName
                        $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                        $result.EndpointType | Should -Be $mockGetTargetResourceParameters.EndpointType
                    }
                }

                It 'Should return the correct values in the rest of properties' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.EndpointName | Should -Be ''
                        $result.Port | Should -Be ''
                        $result.IpAddress | Should -Be ''
                        $result.Owner | Should -Be ''
                        $result.State | Should -BeNullOrEmpty
                        $result.IsMessageForwardingEnabled | Should -BeNullOrEmpty
                        $result.MessageForwardingSize | Should -BeNullOrEmpty
                    }
                }

                It 'Should call the mock function Connect-SQL' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        { Get-TargetResource @mockGetTargetResourceParameters } | Should -Not -Throw
                    }

                    Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the endpoint should be present' {
                BeforeEach {
                    InModuleScope -ScriptBlock {
                        $mockGetTargetResourceParameters.EndpointName = 'SSBR'
                        $mockGetTargetResourceParameters.EndpointType = 'ServiceBroker'
                    }
                }

                It 'Should have property Ensure set to present' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.Ensure | Should -Be 'Present'
                    }
                }

                It 'Should return the same values as passed as parameters' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.ServerName | Should -Be $mockGetTargetResourceParameters.ServerName
                        $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                        $result.EndpointType | Should -Be $mockGetTargetResourceParameters.EndpointType
                    }
                }

                It 'Should return the correct values for the rest of the properties' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.EndpointName | Should -Be 'SSBR'
                        $result.Port | Should -Be 5023
                        $result.IpAddress | Should -Be '192.168.0.20'
                        $result.Owner | Should -Be 'COMPANY\OtherAcct'
                        $result.State | Should -Be 'Started'
                        $result.IsMessageForwardingEnabled | Should -BeTrue
                        $result.MessageForwardingSize | Should -Be 2
                    }
                }

                It 'Should call the mock function Connect-SQL' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        { Get-TargetResource @mockGetTargetResourceParameters } | Should -Not -Throw
                    }

                    Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When endpoint exist but with wrong endpoint type' {
                BeforeEach {
                    InModuleScope -ScriptBlock {
                        $mockGetTargetResourceParameters.EndpointName = 'SSBR'
                        $mockGetTargetResourceParameters.EndpointType = 'DatabaseMirroring'
                    }
                }

                It 'Should throw the correct error' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $mockErrorMessage = $script:localizedData.EndpointFoundButWrongType -f $mockGetTargetResourceParameters.EndpointName, 'ServiceBroker', 'DatabaseMirroring'

                        { Get-TargetResource @mockGetTargetResourceParameters } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage)
                    }
                }
            }
        }
    }

    Context 'When Connect-SQL returns nothing' {
        BeforeAll {
            Mock -CommandName Connect-SQL -MockWith {
                return $null
            }
        }

        BeforeEach {
            InModuleScope -ScriptBlock {
                $mockGetTargetResourceParameters.EndpointName = 'DefaultEndpointMirror'
                $mockGetTargetResourceParameters.EndpointType = 'DatabaseMirroring'
            }
        }

        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockErrorMessage = $script:localizedData.NotConnectedToInstance -f $mockGetTargetResourceParameters.ServerName, $mockGetTargetResourceParameters.InstanceName

                { Get-TargetResource @mockGetTargetResourceParameters } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage)
            }
        }
    }
}

Describe 'DSC_SqlEndpoint\Test-TargetResource' -Tag 'Test' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            # Default parameters that are used for the It-blocks.
            $script:mockDefaultParameters = @{
                InstanceName = 'MSSQLSERVER'
                ServerName   = 'localhost'
            }
        }
    }

    BeforeEach {
        InModuleScope -ScriptBlock {
            $script:mockTestTargetResourceParameters = $script:mockDefaultParameters.Clone()
        }
    }

    Context 'When the system is in the desired state' {
        Context 'When using a Database Mirroring endpoint' {
            Context 'When the endpoint should be absent' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            ServerName                 = 'localhost'
                            InstanceName               = 'MSSQLSERVER'
                            EndpointType               = 'DatabaseMirroring'
                            Ensure                     = 'Absent'
                            EndpointName               = ''
                            Port                       = ''
                            IpAddress                  = ''
                            Owner                      = ''
                            State                      = $null
                            IsMessageForwardingEnabled = $null
                            MessageForwardingSize      = $null
                        }
                    }
                }

                It 'Should return $true' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $mockTestTargetResourceParameters.Ensure = 'Absent'
                        $mockTestTargetResourceParameters.EndpointName = 'DefaultEndpointMirror'
                        $mockTestTargetResourceParameters.EndpointType = 'DatabaseMirroring'

                        $result = Test-TargetResource @mockTestTargetResourceParameters

                        $result | Should -BeTrue
                    }
                }
            }

            Context 'When the endpoint should be present' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            ServerName                 = 'localhost'
                            InstanceName               = 'MSSQLSERVER'
                            EndpointType               = 'DatabaseMirroring'
                            Ensure                     = 'Present'
                            EndpointName               = 'DefaultEndpointMirror'
                            Port                       = '5022'
                            IpAddress                  = '0.0.0.0'
                            Owner                      = 'sa'
                            State                      = 'Started'
                            IsMessageForwardingEnabled = $null
                            MessageForwardingSize      = $null
                        }
                    }
                }

                It 'Should return $true' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $mockTestTargetResourceParameters.EndpointName = 'DefaultEndpointMirror'
                        $mockTestTargetResourceParameters.EndpointType = 'DatabaseMirroring'

                        $result = Test-TargetResource @mockTestTargetResourceParameters

                        $result | Should -BeTrue
                    }
                }
            }
        }

        Context 'When using a Service Broker endpoint' {
            Context 'When the endpoint should be absent' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            ServerName                 = 'localhost'
                            InstanceName               = 'MSSQLSERVER'
                            EndpointType               = 'ServiceBroker'
                            Ensure                     = 'Absent'
                            EndpointName               = ''
                            Port                       = ''
                            IpAddress                  = ''
                            Owner                      = ''
                            State                      = $null
                            IsMessageForwardingEnabled = $null
                            MessageForwardingSize      = $null
                        }
                    }
                }

                It 'Should return $true' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $mockTestTargetResourceParameters.Ensure = 'Absent'
                        $mockTestTargetResourceParameters.EndpointName = 'DefaultEndpointMirror'
                        $mockTestTargetResourceParameters.EndpointType = 'ServiceBroker'

                        $result = Test-TargetResource @mockTestTargetResourceParameters

                        $result | Should -BeTrue
                    }
                }
            }

            Context 'When the endpoint should be present' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            ServerName                 = 'localhost'
                            InstanceName               = 'MSSQLSERVER'
                            EndpointType               = 'ServiceBroker'
                            Ensure                     = 'Present'
                            EndpointName               = 'SSBR'
                            Port                       = '5022'
                            IpAddress                  = '0.0.0.0'
                            Owner                      = 'sa'
                            State                      = 'Started'
                            IsMessageForwardingEnabled = $true
                            MessageForwardingSize      = 2
                        }
                    }
                }

                It 'Should return $true' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $mockTestTargetResourceParameters.EndpointName = 'SSBR'
                        $mockTestTargetResourceParameters.EndpointType = 'ServiceBroker'

                        $result = Test-TargetResource @mockTestTargetResourceParameters

                        $result | Should -BeTrue
                    }
                }
            }
        }

        Context 'When endpoint is a <MockEndpointType>' -ForEach @(
            @{
                MockEndpointType = 'DatabaseMirroring'
            }
            @{
                MockEndpointType = 'ServiceBroker'
            }
        ) {
            Context 'When the endpoint type specific parameter <MockParameterName> is in desired state' -ForEach @(
                @{
                    MockParameterName = 'IsMessageForwardingEnabled'
                    MockParameterValue = $true
                }
                @{
                    MockParameterName = 'MessageForwardingSize'
                    MockParameterValue = 2
                }
            ) {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        $mockGetTargetResourceResult = @{
                            ServerName                 = 'localhost'
                            InstanceName               = 'MSSQLSERVER'
                            EndpointType               = $MockEndpointType
                            Ensure                     = 'Present'
                            EndpointName               = 'SSBR'
                            Port                       = '5022'
                            IpAddress                  = '0.0.0.0'
                            Owner                      = 'sa'
                            State                      = 'Started'
                            IsMessageForwardingEnabled = $null
                            MessageForwardingSize      = $null
                        }

                        $mockGetTargetResourceResult[$MockParameterName] = $MockParameterValue

                        return $mockGetTargetResourceResult
                    }
                }

                It 'Should return $true' {
                    $_.MockEndpointType = $MockEndpointType

                    InModuleScope -Parameters $_ -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $mockTestTargetResourceParameters.EndpointName = 'SSBR'
                        $mockTestTargetResourceParameters.$MockParameterName = $MockParameterValue
                        $mockTestTargetResourceParameters.EndpointType = $MockEndpointType

                        $result = Test-TargetResource @mockTestTargetResourceParameters

                        $result | Should -BeTrue
                    }
                }
            }
        }

        Context 'When the parameter <MockParameterName> is in desired state' -ForEach @(
            @{
                MockParameterName = 'Owner'
                MockParameterValue = 'sa'
            }
            @{
                MockParameterName = 'State'
                MockParameterValue = 'Started'
            }
            @{
                MockParameterName = 'Port'
                MockParameterValue = '5022'
            }
            @{
                MockParameterName = 'IpAddress'
                MockParameterValue = '0.0.0.0'
            }
        ) {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        ServerName                 = 'localhost'
                        InstanceName               = 'MSSQLSERVER'
                        EndpointType               = 'DatabaseMirroring'
                        Ensure                     = 'Present'
                        EndpointName               = 'SSBR'
                        Port                       = '5022'
                        IpAddress                  = '0.0.0.0'
                        Owner                      = 'sa'
                        State                      = 'Started'
                        IsMessageForwardingEnabled = $false
                        MessageForwardingSize      = 1
                    }
                }
            }

            It 'Should return $true' {
                InModuleScope -Parameters $_ -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.EndpointName = 'SSBR'
                    $mockTestTargetResourceParameters.EndpointType = 'DatabaseMirroring'
                    $mockTestTargetResourceParameters.$MockParameterName = $MockParameterValue

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeTrue
                }
            }
        }
    }

    Context 'When the system is not in the desired state' {
        Context 'When using a Database Mirroring endpoint' {
            Context 'When the endpoint should be absent but it exist' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            ServerName                 = 'localhost'
                            InstanceName               = 'MSSQLSERVER'
                            EndpointType               = 'DatabaseMirroring'
                            Ensure                     = 'Present'
                            EndpointName               = 'DefaultEndpointMirror'
                            Port                       = '5022'
                            IpAddress                  = '0.0.0.0'
                            Owner                      = 'sa'
                            State                      = 'Started'
                            IsMessageForwardingEnabled = $null
                            MessageForwardingSize      = $null
                        }
                    }
                }

                It 'Should return $false' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $mockTestTargetResourceParameters.Ensure = 'Absent'
                        $mockTestTargetResourceParameters.EndpointName = 'DefaultEndpointMirror'
                        $mockTestTargetResourceParameters.EndpointType = 'DatabaseMirroring'

                        $result = Test-TargetResource @mockTestTargetResourceParameters

                        $result | Should -BeFalse
                    }
                }
            }

            Context 'When the endpoint should be present but it does not exist' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            ServerName                 = 'localhost'
                            InstanceName               = 'MSSQLSERVER'
                            EndpointType               = 'DatabaseMirroring'
                            Ensure                     = 'Absent'
                            EndpointName               = ''
                            Port                       = ''
                            IpAddress                  = ''
                            Owner                      = ''
                            State                      = $null
                            IsMessageForwardingEnabled = $null
                            MessageForwardingSize      = $null
                        }
                    }
                }

                It 'Should return $false' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $mockTestTargetResourceParameters.EndpointName = 'DefaultEndpointMirror'
                        $mockTestTargetResourceParameters.EndpointType = 'DatabaseMirroring'

                        $result = Test-TargetResource @mockTestTargetResourceParameters

                        $result | Should -BeFalse
                    }
                }
            }
        }

        Context 'When using a Service Broker endpoint' {
            Context 'When the endpoint should be absent' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            ServerName                 = 'localhost'
                            InstanceName               = 'MSSQLSERVER'
                            EndpointType               = 'ServiceBroker'
                            Ensure                     = 'Present'
                            EndpointName               = 'SSBR'
                            Port                       = '5022'
                            IpAddress                  = '0.0.0.0'
                            Owner                      = 'sa'
                            State                      = 'Started'
                            IsMessageForwardingEnabled = $true
                            MessageForwardingSize      = 2
                        }
                    }
                }

                It 'Should return $false' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $mockTestTargetResourceParameters.Ensure = 'Absent'
                        $mockTestTargetResourceParameters.EndpointName = 'DefaultEndpointMirror'
                        $mockTestTargetResourceParameters.EndpointType = 'ServiceBroker'

                        $result = Test-TargetResource @mockTestTargetResourceParameters

                        $result | Should -BeFalse
                    }
                }
            }

            Context 'When the endpoint should be present' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            ServerName                 = 'localhost'
                            InstanceName               = 'MSSQLSERVER'
                            EndpointType               = 'ServiceBroker'
                            Ensure                     = 'Absent'
                            EndpointName               = ''
                            Port                       = ''
                            IpAddress                  = ''
                            Owner                      = ''
                            State                      = $null
                            IsMessageForwardingEnabled = $null
                            MessageForwardingSize      = $null
                        }
                    }
                }

                It 'Should return $false' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $mockTestTargetResourceParameters.EndpointName = 'SSBR'
                        $mockTestTargetResourceParameters.EndpointType = 'ServiceBroker'

                        $result = Test-TargetResource @mockTestTargetResourceParameters

                        $result | Should -BeFalse
                    }
                }
            }
        }

        Context 'When endpoint is a <MockEndpointType>' -ForEach @(
            @{
                MockEndpointType = 'DatabaseMirroring'
            }
            @{
                MockEndpointType = 'ServiceBroker'
            }
        ) {
            Context 'When the endpoint type specific parameter <MockParameterName> is not in desired state' -ForEach @(
                @{
                    MockParameterName = 'IsMessageForwardingEnabled'
                    MockParameterValue = $true
                }
                @{
                    MockParameterName = 'MessageForwardingSize'
                    MockParameterValue = 2
                }
            ) {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            ServerName                 = 'localhost'
                            InstanceName               = 'MSSQLSERVER'
                            EndpointType               = $MockEndpointType
                            Ensure                     = 'Present'
                            EndpointName               = 'SSBR'
                            Port                       = '5022'
                            IpAddress                  = '0.0.0.0'
                            Owner                      = 'sa'
                            State                      = 'Started'
                            IsMessageForwardingEnabled = $false
                            MessageForwardingSize      = 1
                        }
                    }
                }

                It 'Should return $false' {
                    $_.MockEndpointType = $MockEndpointType

                    InModuleScope -Parameters $_ -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $mockTestTargetResourceParameters.EndpointName = 'SSBR'
                        $mockTestTargetResourceParameters.$MockParameterName = $MockParameterValue
                        $mockTestTargetResourceParameters.EndpointType = $MockEndpointType

                        $result = Test-TargetResource @mockTestTargetResourceParameters

                        $result | Should -BeFalse
                    }
                }
            }
        }

        Context 'When the parameter <MockParameterName> is not in desired state' -ForEach @(
            @{
                MockParameterName = 'Owner'
                MockParameterValue = 'NewOwner'
            }
            @{
                MockParameterName = 'State'
                MockParameterValue = 'Started'
            }
            @{
                MockParameterName = 'Port'
                MockParameterValue = '5023'
            }
            @{
                MockParameterName = 'IpAddress'
                MockParameterValue = '192.168.10.2'
            }
        ) {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        ServerName                 = 'localhost'
                        InstanceName               = 'MSSQLSERVER'
                        EndpointType               = 'DatabaseMirroring'
                        Ensure                     = 'Present'
                        EndpointName               = 'SSBR'
                        Port                       = '5022'
                        IpAddress                  = '0.0.0.0'
                        Owner                      = 'sa'
                        State                      = 'Stopped'
                        IsMessageForwardingEnabled = $false
                        MessageForwardingSize      = 1
                    }
                }
            }

            It 'Should return $false' {
                InModuleScope -Parameters $_ -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.EndpointName = 'SSBR'
                    $mockTestTargetResourceParameters.EndpointType = 'DatabaseMirroring'
                    $mockTestTargetResourceParameters.$MockParameterName = $MockParameterValue

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeFalse
                }
            }
        }
    }
}


Describe 'SqlEndpoint\Set-TargetResource' -Tag 'Set' {
    BeforeAll {
        $mockEndpointObject = {
            # TypeName: Microsoft.SqlServer.Management.Smo.Endpoint
            return New-Object -TypeName Object |
                Add-Member -MemberType NoteProperty -Name 'Name' -Value 'DefaultEndpointMirror' -PassThru |
                Add-Member -MemberType NoteProperty -Name 'EndpointType' -Value 'DatabaseMirroring' -PassThru |
                <#
                    In reality this would be set to either 'Started', 'Stopped', or 'Disabled', but
                    for the mock we will set it to $null so it can be easily unit tested.
                #>
                Add-Member -MemberType NoteProperty -Name 'EndpointState' -Value $null -PassThru |
                Add-Member -MemberType NoteProperty -Name 'ProtocolType' -Value $null -PassThru |
                Add-Member -MemberType NoteProperty -Name 'Owner' -Value 'sa' -PassThru |
                Add-Member -MemberType ScriptProperty -Name 'Protocol' -Value {
                    return New-Object -TypeName Object |
                        Add-Member -MemberType ScriptProperty -Name 'Tcp' -Value {
                            return New-Object -TypeName Object |
                                Add-Member -MemberType NoteProperty -Name 'ListenerPort' -Value 5022 -PassThru |
                                # 0.0.0.0 means listen on all IP addresses.
                                Add-Member -MemberType NoteProperty -Name 'ListenerIPAddress' -Value '0.0.0.0' -PassThru -Force
                        } -PassThru -Force
                } -PassThru |
                Add-Member -MemberType ScriptProperty -Name 'Payload' -Value {
                    return New-Object -TypeName Object |
                        Add-Member -MemberType ScriptProperty -Name 'DatabaseMirroring' -Value {
                            return New-Object -TypeName Object |
                                Add-Member -MemberType NoteProperty -Name 'ServerMirroringRole' -Value $null -PassThru |
                                Add-Member -MemberType NoteProperty -Name 'EndpointEncryption' -Value $null -PassThru |
                                Add-Member -MemberType NoteProperty -Name 'EndpointEncryptionAlgorithm' -Value $null -PassThru -Force
                        } -PassThru |
                        Add-Member -MemberType ScriptProperty -Name 'ServiceBroker' -Value {
                            return New-Object -TypeName Object |
                                Add-Member -MemberType NoteProperty -Name 'EndpointEncryption' -Value $null -PassThru |
                                Add-Member -MemberType NoteProperty -Name 'EndpointEncryptionAlgorithm' -Value $null -PassThru |
                                Add-Member -MemberType NoteProperty -Name 'IsMessageForwardingEnabled' -Value $null -PassThru |
                                Add-Member -MemberType NoteProperty -Name 'MessageForwardingSize' -Value $null -PassThru
                        } -PassThru -Force
                } -PassThru |
                Add-Member -MemberType ScriptMethod -Name 'Alter' -Value {
                    InModuleScope -ScriptBlock {
                        $script:mockMethodAlterWasRun += 1
                    }

                    if ($this.Name -ne $mockExpectedNameWhenCallingMethod)
                    {
                        throw "Called mocked Alter() method on and endpoint with wrong name. Expected '{0}'. But was '{1}'." `
                                -f $mockExpectedNameWhenCallingMethod, $this.Name
                    }
                } -PassThru |
                Add-Member -MemberType ScriptMethod -Name 'Drop' -Value {
                    InModuleScope -ScriptBlock {
                        $script:mockMethodDropWasRun += 1
                    }

                    if ($this.Name -ne 'DefaultEndpointMirror')
                    {
                        throw "Called mocked Drop() method on and endpoint with wrong name. Expected '{0}'. But was '{1}'." `
                                -f 'DefaultEndpointMirror', $this.Name
                    }
                } -PassThru |
                Add-Member -MemberType ScriptMethod -Name 'Start' -Value {
                    InModuleScope -ScriptBlock {
                        $script:mockMethodStartWasRun += 1
                    }
                } -PassThru |
                Add-Member -MemberType ScriptMethod -Name 'Stop' -Value {
                    InModuleScope -ScriptBlock {
                        $script:mockMethodStopWasRun += 1
                    }
                } -PassThru |
                Add-Member -MemberType ScriptMethod -Name 'Disable' -Value {
                    InModuleScope -ScriptBlock {
                        $script:mockMethodDisableWasRun += 1
                    }
                } -PassThru |
                Add-Member -MemberType ScriptMethod -Name 'Create' -Value {
                    InModuleScope -ScriptBlock {
                        $script:mockMethodCreateWasRun += 1
                    }

                    if ( $this.Name -ne 'NewEndpoint' )
                    {
                        throw "Called mocked Create() method on and endpoint with wrong name. Expected '{0}'. But was '{1}'." `
                                -f 'NewEndpoint', $this.Name
                    }
                } -PassThru -Force
        }

        $mockConnectSql = {
            return New-Object -TypeName Object |
                Add-Member -MemberType ScriptProperty -Name Endpoints -Value {
                    return @(
                        @{
                            <#
                                This executes the script block of $mockEndpointObject and returns
                                a mocked Microsoft.SqlServer.Management.Smo.Endpoint
                            #>
                            'DefaultEndpointMirror' = & $mockEndpointObject
                        }
                    )
                } -PassThru -Force
        }

        Mock -CommandName Connect-SQL -MockWith $mockConnectSQL

        InModuleScope -ScriptBlock {
            # Default parameters that are used for the It-blocks.
            $script:mockDefaultParameters = @{
                InstanceName = 'MSSQLSERVER'
                ServerName   = 'localhost'
            }
        }
    }

    BeforeEach {
        InModuleScope -ScriptBlock {
            $script:mockMethodCreateWasRun = 0
            $script:mockMethodStartWasRun = 0
            $script:mockMethodStopWasRun = 0
            $script:mockMethodAlterWasRun = 0
            $script:mockMethodDropWasRun = 0
            $script:mockMethodDisableWasRun = 0

            $script:mockSetTargetResourceParameters = $script:mockDefaultParameters.Clone()
        }
    }

    Context 'When the system is not in the desired state' {
        Context 'When the endpoint is missing' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Ensure = 'Absent'
                    }
                }
            }

            BeforeEach {
                Mock -CommandName New-Object -MockWith {
                    <#
                        This executes the script block $mockEndpointObject and returns
                        a mocked Microsoft.SqlServer.Management.Smo.Endpoint.
                    #>
                    $newMockedEndpointObject = & $mockEndpointObject

                    # Change the name of the endpoint to the name that is passed by New-Object.
                    $newMockedEndpointObject.Name = $ArgumentList[1]

                    return $newMockedEndpointObject
                } -ParameterFilter {
                    $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Endpoint'
                }
            }

            Context 'When creating a new endpoint of type <MockEndpointType> using default values' -ForEach @(
                @{
                    MockEndpointType = 'DatabaseMirroring'
                }
                @{
                    MockEndpointType = 'ServiceBroker'
                }
            ) {
                It 'Should create the endpoint without throwing and call the mocked methods Create() and Start()' {
                    InModuleScope -Parameters $_ -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $mockSetTargetResourceParameters.EndpointName = 'NewEndpoint'
                        $mockSetTargetResourceParameters.EndpointType = $MockEndpointType

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                        $script:mockMethodCreateWasRun | Should -Be 1
                        $script:mockMethodStartWasRun | Should -Be 1
                        $script:mockMethodStopWasRun | Should -Be 0
                        $script:mockMethodAlterWasRun | Should -Be 0
                        $script:mockMethodDropWasRun | Should -Be 0
                        $script:mockMethodDisableWasRun | Should -Be 0
                    }
                }
            }

            Context 'When creating a new endpoint and passing parameter State with the value ''<MockState>''' -ForEach @(
                @{
                    MockState = 'Stopped'
                }
                @{
                    MockState = 'Started'
                }
                @{
                    MockState = 'Disabled'
                }
            ) {
                It 'Should create the endpoint without throwing and call the mocked method Create() call the correct mocked method related to the state ''<MockState>''' {
                    InModuleScope -Parameters $_ -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $mockSetTargetResourceParameters.EndpointName = 'NewEndpoint'
                        $mockSetTargetResourceParameters.EndpointType = 'DatabaseMirroring'
                        $mockSetTargetResourceParameters.State = $MockState

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                        $script:mockMethodCreateWasRun | Should -Be 1
                        $script:mockMethodAlterWasRun | Should -Be 0
                        $script:mockMethodDropWasRun | Should -Be 0

                        switch ($MockState)
                        {
                            'Disabled'
                            {
                                $script:mockMethodDisableWasRun | Should -Be 1
                                $script:mockMethodStartWasRun | Should -Be 0
                                $script:mockMethodStopWasRun | Should -Be 0
                            }

                            'Started'
                            {
                                $script:mockMethodStartWasRun | Should -Be 1
                                $script:mockMethodDisableWasRun | Should -Be 0
                                $script:mockMethodStopWasRun | Should -Be 0
                            }

                            'Stopped'
                            {
                                $script:mockMethodStopWasRun | Should -Be 1
                                $script:mockMethodStartWasRun | Should -Be 0
                                $script:mockMethodDisableWasRun | Should -Be 0
                            }
                        }
                    }
                }
            }

            Context 'When creating a new Database Mirroring endpoint and passing parameter <MockParameterName>' -ForEach @(
                @{
                    MockParameterName = 'Owner'
                    MockParameterValue = 'NewOwner'
                }
                @{
                    MockParameterName = 'IpAddress'
                    MockParameterValue = '192.168.10.2'
                }
                @{
                    MockParameterName = 'Port'
                    MockParameterValue = '5233'
                }
            ) {
                BeforeAll {
                    $mockExpectedNameWhenCallingMethod = 'NewEndpoint'
                }

                AfterAll {
                    $mockExpectedNameWhenCallingMethod = $null
                }

                It 'Should create the endpoint without throwing and call the mocked methods Create() and Start()' {
                    InModuleScope -Parameters $_ -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $mockSetTargetResourceParameters.EndpointName = 'NewEndpoint'
                        $mockSetTargetResourceParameters.EndpointType = 'DatabaseMirroring'
                        $mockSetTargetResourceParameters.$MockParameterName = $MockParameterValue

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                        $script:mockMethodCreateWasRun | Should -Be 1
                        $script:mockMethodStartWasRun | Should -Be 1
                        $script:mockMethodDropWasRun | Should -Be 0
                        $script:mockMethodDisableWasRun | Should -Be 0
                        $script:mockMethodStopWasRun | Should -Be 0

                        if ($MockParameterName -eq 'Owner')
                        {
                            $script:mockMethodAlterWasRun | Should -Be 0
                        }
                        else
                        {
                            $script:mockMethodAlterWasRun | Should -Be 1
                        }
                    }
                }
            }

            Context 'When creating a new Service Broker endpoint and passing parameter <MockParameterName>' -ForEach @(
                @{
                    MockParameterName = 'Owner'
                    MockParameterValue = 'NewOwner'
                }
                @{
                    MockParameterName = 'IpAddress'
                    MockParameterValue = '192.168.10.2'
                }
                @{
                    MockParameterName = 'Port'
                    MockParameterValue = 5233
                }
                @{
                    MockParameterName = 'IsMessageForwardingEnabled'
                    MockParameterValue = $true
                }
                @{
                    MockParameterName = 'MessageForwardingSize'
                    MockParameterValue = 2
                }
            ) {
                BeforeAll {
                    $mockExpectedNameWhenCallingMethod = 'NewEndpoint'
                }

                AfterAll {
                    $mockExpectedNameWhenCallingMethod = $null
                }

                It 'Should create the endpoint without throwing and call the mocked methods Create() and Start()' {
                    InModuleScope -Parameters $_ -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $mockSetTargetResourceParameters.EndpointName = 'NewEndpoint'
                        $mockSetTargetResourceParameters.EndpointType = 'ServiceBroker'
                        $mockSetTargetResourceParameters.$MockParameterName = $MockParameterValue

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                        $script:mockMethodCreateWasRun | Should -Be 1
                        $script:mockMethodStartWasRun | Should -Be 1
                        $script:mockMethodDropWasRun | Should -Be 0
                        $script:mockMethodDisableWasRun | Should -Be 0
                        $script:mockMethodStopWasRun | Should -Be 0

                        if ($MockParameterName -eq 'Owner')
                        {
                            $script:mockMethodAlterWasRun | Should -Be 0
                        }
                        else
                        {
                            $script:mockMethodAlterWasRun | Should -Be 1
                        }
                    }
                }
            }
        }

        Context 'When the endpoint exist but is not in desired state' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Ensure = 'Present'
                    }
                }
            }

            Context 'When passing parameter <MockParameterName> for a Database Mirroring endpoint' -ForEach @(
                @{
                    MockParameterName = 'Owner'
                    MockParameterValue = 'NewOwner'
                }
                @{
                    MockParameterName = 'IpAddress'
                    MockParameterValue = '192.168.10.2'
                }
                @{
                    MockParameterName = 'Port'
                    MockParameterValue = 5233
                }
                @{
                    MockParameterName = 'State'
                    MockParameterValue = 'Started'
                }
                @{
                    MockParameterName = 'State'
                    MockParameterValue = 'Stopped'
                }
                @{
                    MockParameterName = 'State'
                    MockParameterValue = 'Disabled'
                }
            ) {
                BeforeAll {
                    $mockExpectedNameWhenCallingMethod = 'DefaultEndpointMirror'
                }

                AfterAll {
                    $mockExpectedNameWhenCallingMethod = $null
                }

                It 'Should call the correct mocked method(s)' {
                    InModuleScope -Parameters $_ -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $mockSetTargetResourceParameters.EndpointName = 'DefaultEndpointMirror'
                        $mockSetTargetResourceParameters.EndpointType = 'DatabaseMirroring'
                        $mockSetTargetResourceParameters.$MockParameterName = $MockParameterValue

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                        $script:mockMethodCreateWasRun | Should -Be 0
                        $script:mockMethodDropWasRun | Should -Be 0

                        if ($MockParameterName -eq 'State')
                        {
                            switch ($MockParameterValue)
                            {
                                'Disabled'
                                {
                                    $script:mockMethodDisableWasRun | Should -Be 1
                                    $script:mockMethodStartWasRun | Should -Be 0
                                    $script:mockMethodStopWasRun | Should -Be 0
                                }

                                'Started'
                                {
                                    $script:mockMethodStartWasRun | Should -Be 1
                                    $script:mockMethodDisableWasRun | Should -Be 0
                                    $script:mockMethodStopWasRun | Should -Be 0
                                }

                                'Stopped'
                                {
                                    $script:mockMethodStopWasRun | Should -Be 1
                                    $script:mockMethodStartWasRun | Should -Be 0
                                    $script:mockMethodDisableWasRun | Should -Be 0
                                }
                            }
                        }
                        else
                        {
                            $script:mockMethodAlterWasRun | Should -Be 1
                        }
                    }
                }
            }

            Context 'When passing parameter <MockParameterName> for a Service Broker endpoint' -ForEach @(
                @{
                    MockParameterName = 'Owner'
                    MockParameterValue = 'NewOwner'
                }
                @{
                    MockParameterName = 'IpAddress'
                    MockParameterValue = '192.168.10.2'
                }
                @{
                    MockParameterName = 'Port'
                    MockParameterValue = 5233
                }
                @{
                    MockParameterName = 'State'
                    MockParameterValue = 'Started'
                }
                @{
                    MockParameterName = 'State'
                    MockParameterValue = 'Stopped'
                }
                @{
                    MockParameterName = 'State'
                    MockParameterValue = 'Disabled'
                }
                @{
                    MockParameterName = 'IsMessageForwardingEnabled'
                    MockParameterValue = $true
                }
                @{
                    MockParameterName = 'MessageForwardingSize'
                    MockParameterValue = 2
                }
            ) {
                BeforeAll {
                    $mockExpectedNameWhenCallingMethod = 'DefaultEndpointMirror'
                }

                AfterAll {
                    $mockExpectedNameWhenCallingMethod = $null
                }

                It 'Should call the correct mocked method(s)' {
                    InModuleScope -Parameters $_ -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $mockSetTargetResourceParameters.EndpointName = 'DefaultEndpointMirror'
                        $mockSetTargetResourceParameters.EndpointType = 'ServiceBroker'
                        $mockSetTargetResourceParameters.$MockParameterName = $MockParameterValue

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                        $script:mockMethodCreateWasRun | Should -Be 0
                        $script:mockMethodDropWasRun | Should -Be 0

                        if ($MockParameterName -eq 'State')
                        {
                            switch ($MockParameterValue)
                            {
                                'Disabled'
                                {
                                    $script:mockMethodDisableWasRun | Should -Be 1
                                    $script:mockMethodStartWasRun | Should -Be 0
                                    $script:mockMethodStopWasRun | Should -Be 0
                                }

                                'Started'
                                {
                                    $script:mockMethodStartWasRun | Should -Be 1
                                    $script:mockMethodDisableWasRun | Should -Be 0
                                    $script:mockMethodStopWasRun | Should -Be 0
                                }

                                'Stopped'
                                {
                                    $script:mockMethodStopWasRun | Should -Be 1
                                    $script:mockMethodStartWasRun | Should -Be 0
                                    $script:mockMethodDisableWasRun | Should -Be 0
                                }
                            }
                        }
                        else
                        {
                            $script:mockMethodAlterWasRun | Should -Be 1
                        }
                    }
                }
            }

            It 'Should throw the correct error if the endpoint is not found' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters.EndpointName = 'UnknownEndpointMirror'
                    $mockSetTargetResourceParameters.EndpointType = 'DatabaseMirroring'

                    $mockErrorMessage = $script:localizedData.EndpointNotFound -f 'UnknownEndpointMirror'

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage + '*')

                    $script:mockMethodDropWasRun | Should -Be 0
                    $script:mockMethodCreateWasRun | Should -Be 0
                    $script:mockMethodDisableWasRun | Should -Be 0
                    $script:mockMethodStartWasRun | Should -Be 0
                    $script:mockMethodStopWasRun | Should -Be 0
                    $script:mockMethodAlterWasRun | Should -Be 0
                }
            }
        }

        Context 'When the endpoint should not exist' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Ensure = 'Present'
                    }
                }
            }

            It 'Should call the mocked method Drop()' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0


                    $mockSetTargetResourceParameters.Ensure = 'Absent'
                    $mockSetTargetResourceParameters.EndpointName = 'DefaultEndpointMirror'
                    $mockSetTargetResourceParameters.EndpointType = 'DatabaseMirroring'

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                    $script:mockMethodDropWasRun | Should -Be 1
                    $script:mockMethodCreateWasRun | Should -Be 0
                    $script:mockMethodDisableWasRun | Should -Be 0
                    $script:mockMethodStartWasRun | Should -Be 0
                    $script:mockMethodStopWasRun | Should -Be 0
                    $script:mockMethodAlterWasRun | Should -Be 0
                }
            }

            It 'Should throw the correct error if the endpoint to drop is not found' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0


                    $mockSetTargetResourceParameters.Ensure = 'Absent'
                    $mockSetTargetResourceParameters.EndpointName = 'UnknownEndpointMirror'
                    $mockSetTargetResourceParameters.EndpointType = 'DatabaseMirroring'

                    $mockErrorMessage = $script:localizedData.EndpointNotFound -f 'UnknownEndpointMirror'

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage + '*')

                    $script:mockMethodDropWasRun | Should -Be 0
                    $script:mockMethodCreateWasRun | Should -Be 0
                    $script:mockMethodDisableWasRun | Should -Be 0
                    $script:mockMethodStartWasRun | Should -Be 0
                    $script:mockMethodStopWasRun | Should -Be 0
                    $script:mockMethodAlterWasRun | Should -Be 0
                }
            }
        }
    }

    Context 'When the Connect-SQL returns a $null value' {
        BeforeAll {
            Mock -CommandName Get-TargetResource -MockWith {
                return @{
                    Ensure = 'Present'
                }
            }

            Mock -CommandName Connect-SQL -MockWith {
                return $null
            }
        }

        It 'Should throw the correct error if the endpoint is not found' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockSetTargetResourceParameters.EndpointName = 'DefaultEndpointMirror'
                $mockSetTargetResourceParameters.EndpointType = 'DatabaseMirroring'

                $mockErrorMessage = $script:localizedData.NotConnectedToInstance -f 'localhost', 'MSSQLSERVER'

                { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage)
            }
        }
    }
}
