<#
    .SYNOPSIS
        Unit test for DSC_SqlAGListener DSC resource.
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
    $script:dscResourceName = 'DSC_SqlAGListener'

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

Describe 'SqlAGListener\Get-TargetResource' -Tag 'Get' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            # Default parameters that are used for the It-blocks.
            $script:mockDefaultParameters = @{
                InstanceName      = 'MSSQLSERVER'
                ServerName        = 'localhost'
                Name              = 'AGListener'
                AvailabilityGroup = 'AG01'
            }
        }
    }

    BeforeEach {
        InModuleScope -ScriptBlock {
            $script:mockGetTargetResourceParameters = $script:mockDefaultParameters.Clone()
        }
    }


    Context 'When the system is in the desired state' {
        Context 'When the listener is absent' {
            BeforeAll {
                Mock -CommandName Connect-SQL -MockWith {
                    return New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server
                }

                Mock -CommandName Test-ActiveNode -MockWith {
                    return $false
                }

                Mock -CommandName Get-SQLAlwaysOnAvailabilityGroupListener
            }

            It 'Should return the desired state as absent' {
                InModuleScope -ScriptBlock {
                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.Ensure | Should -Be 'Absent'
                }
            }

            It 'Should return the same values as passed as parameters' {
                InModuleScope -ScriptBlock {
                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.ServerName | Should -Be $mockGetTargetResourceParameters.ServerName
                    $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                    $result.Name | Should -Be $mockGetTargetResourceParameters.Name
                    $result.AvailabilityGroup | Should -Be $mockGetTargetResourceParameters.AvailabilityGroup
                }
            }

            It 'Should not return any IP addresses' {
                InModuleScope -ScriptBlock {
                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.IpAddress | Should -BeNullOrEmpty
                }
            }

            It 'Should not return port' {
                InModuleScope -ScriptBlock {
                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.Port | Should -Be 0
                }
            }

            It 'Should return that DHCP is not used' {
                InModuleScope -ScriptBlock {
                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.DHCP | Should -BeFalse
                }
            }

            It 'Should call the mock function Get-SQLAlwaysOnAvailabilityGroupListener' {
                InModuleScope -ScriptBlock {
                    { Get-TargetResource @mockGetTargetResourceParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Get-SQLAlwaysOnAvailabilityGroupListener -Exactly -Times 1 -Scope It
            }
        }

        Context 'When listener is present and not using DHCP' {
            BeforeAll {
                Mock -CommandName Connect-SQL -MockWith {
                    return New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server
                }

                Mock -CommandName Test-ActiveNode -MockWith {
                    return $false
                }

                Mock -CommandName Get-SQLAlwaysOnAvailabilityGroupListener -MockWith {
                    return @{
                        PortNumber                           = 5031
                        AvailabilityGroupListenerIPAddresses = @{
                            IsDHCP     = $false
                            IPAddress  = '192.168.0.1'
                            SubnetMask = '255.255.255.0'
                        }
                    }
                }
            }

            It 'Should return the desired state as present' {
                InModuleScope -ScriptBlock {
                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.Ensure | Should -Be 'Present'
                }
            }

            It 'Should return the same values as passed as parameters' {
                InModuleScope -ScriptBlock {
                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.ServerName | Should -Be $mockGetTargetResourceParameters.ServerName
                    $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                    $result.Name | Should -Be $mockGetTargetResourceParameters.Name
                    $result.AvailabilityGroup | Should -Be $mockGetTargetResourceParameters.AvailabilityGroup
                }
            }

            It 'Should return correct IP address' {
                InModuleScope -ScriptBlock {
                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.IpAddress | Should -Be '192.168.0.1/255.255.255.0'
                }
            }

            It 'Should return correct port' {
                InModuleScope -ScriptBlock {
                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.Port | Should -Be 5031
                }
            }

            It 'Should return that DHCP is not used' {
                $mockDynamicIsDhcp = $false

                InModuleScope -ScriptBlock {
                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.DHCP | Should -BeFalse
                }
            }

            It 'Should return that it is not the active node' {
                InModuleScope -ScriptBlock {
                    $mockGetTargetResourceParameters.ProcessOnlyOnActiveNode = $true

                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.ProcessOnlyOnActiveNode | Should -BeTrue
                    $result.IsActiveNode | Should -BeFalse
                }
            }

            It 'Should call the mock function Get-SQLAlwaysOnAvailabilityGroupListener' {
                InModuleScope -ScriptBlock {
                    { Get-TargetResource @mockGetTargetResourceParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Get-SQLAlwaysOnAvailabilityGroupListener -Exactly -Times 1 -Scope It
            }
        }

        Context 'When listener is present and using DHCP' {
            BeforeAll {
                Mock -CommandName Connect-SQL -MockWith {
                    return New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server
                }

                Mock -CommandName Test-ActiveNode -MockWith {
                    return $false
                }

                Mock -CommandName Get-SQLAlwaysOnAvailabilityGroupListener -MockWith {
                    return @{
                        PortNumber                           = 5031
                        AvailabilityGroupListenerIPAddresses = @{
                            IsDHCP     = $true
                            IPAddress  = '192.168.0.1'
                            SubnetMask = '255.255.255.0'
                        }
                    }
                }
            }

            It 'Should return the desired state as present' {
                InModuleScope -ScriptBlock {
                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.Ensure | Should -Be 'Present'
                }
            }

            It 'Should return the same values as passed as parameters' {
                InModuleScope -ScriptBlock {
                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.ServerName | Should -Be $mockGetTargetResourceParameters.ServerName
                    $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                    $result.Name | Should -Be $mockGetTargetResourceParameters.Name
                    $result.AvailabilityGroup | Should -Be $mockGetTargetResourceParameters.AvailabilityGroup
                }
            }

            It 'Should return correct IP address' {
                InModuleScope -ScriptBlock {
                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.IpAddress | Should -Be '192.168.0.1/255.255.255.0'
                }
            }

            It 'Should return correct port' {
                InModuleScope -ScriptBlock {
                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.Port | Should -Be 5031
                }
            }

            It 'Should return that DHCP is not used' {
                InModuleScope -ScriptBlock {
                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.DHCP | Should -BeTrue
                }
            }

            It 'Should call the mock function Get-SQLAlwaysOnAvailabilityGroupListener' {
                InModuleScope -ScriptBlock {
                    { Get-TargetResource @mockGetTargetResourceParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Get-SQLAlwaysOnAvailabilityGroupListener -Exactly -Times 1 -Scope It
            }
        }

        Context 'When listener does not have subnet mask' {
            BeforeAll {
                Mock -CommandName Connect-SQL -MockWith {
                    return New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server
                }

                Mock -CommandName Test-ActiveNode -MockWith {
                    return $false
                }

                Mock -CommandName Get-SQLAlwaysOnAvailabilityGroupListener -MockWith {
                    return @{
                        PortNumber                           = 5031
                        AvailabilityGroupListenerIPAddresses = @{
                            IsDHCP     = $false
                            IPAddress  = '192.168.0.1'
                            SubnetMask = ''
                        }
                    }
                }
            }

            It 'Should return the desired state as present' {
                InModuleScope -ScriptBlock {
                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.Ensure | Should -Be 'Present'
                }
            }

            It 'Should return the same values as passed as parameters' {
                InModuleScope -ScriptBlock {
                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.ServerName | Should -Be $mockGetTargetResourceParameters.ServerName
                    $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                    $result.Name | Should -Be $mockGetTargetResourceParameters.Name
                    $result.AvailabilityGroup | Should -Be $mockGetTargetResourceParameters.AvailabilityGroup
                }
            }

            It 'Should return correct IP address' {
                InModuleScope -ScriptBlock {
                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.IpAddress | Should -Be '192.168.0.1'
                }
            }

            It 'Should return correct port' {
                InModuleScope -ScriptBlock {
                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.Port | Should -Be 5031
                }
            }

            It 'Should return that DHCP is not used' {
                InModuleScope -ScriptBlock {
                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.DHCP | Should -BeFalse
                }
            }

            It 'Should call the mock function Get-SQLAlwaysOnAvailabilityGroupListener' {
                InModuleScope -ScriptBlock {
                    { Get-TargetResource @mockGetTargetResourceParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Get-SQLAlwaysOnAvailabilityGroupListener -Exactly -Times 1 -Scope It
            }
        }
    }
}

Describe 'SqlAGListener\Test-TargetResource' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            # Default parameters that are used for the It-blocks.
            $script:mockDefaultParameters = @{
                InstanceName      = 'MSSQLSERVER'
                ServerName        = 'localhost'
                Name              = 'AGListener'
                AvailabilityGroup = 'AG01'
            }
        }
    }

    BeforeEach {
        InModuleScope -ScriptBlock {
            $script:mockTestTargetResourceParameters = $script:mockDefaultParameters.Clone()
        }
    }

    Context 'When the system is in the desired state' {
        Context 'When the listener does not exist' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Ensure = 'Absent'
                    }
                }
            }

            It 'Should return $true' {
                InModuleScope -ScriptBlock {
                    $mockTestTargetResourceParameters.Ensure = 'Absent'

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeTrue
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the listener does exist' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Ensure = 'Present'
                    }
                }
            }

            It 'Should return $true' {
                InModuleScope -ScriptBlock {
                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeTrue
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the property <MockPropertyName> is in desired state' -ForEach @(
            @{
                MockPropertyName  = 'IpAddress'
                MockExpectedValue = '192.168.10.45/255.255.252.0'
                MockActualValue   = '192.168.10.45/255.255.252.0'
            }
            @{
                MockPropertyName  = 'Port'
                MockExpectedValue = '5031'
                MockActualValue   = '5031'
            }
            @{
                MockPropertyName  = 'DHCP'
                MockExpectedValue = $false
                MockActualValue   = $false
            }
            @{
                MockPropertyName  = 'DHCP'
                MockExpectedValue = $true
                MockActualValue   = $true
            }
        ) {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Ensure            = 'Present'
                        $MockPropertyName = $MockActualValue
                    }
                }
            }

            It 'Should return $true' {
                InModuleScope -Parameters $_ -ScriptBlock {
                    $mockTestTargetResourceParameters.$MockPropertyName = $MockExpectedValue

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeTrue
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When the system is not in the desired state' {
        Context 'When the listener does not exist' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Ensure = 'Absent'
                    }
                }
            }

            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeFalse
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the listener does exist' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Ensure = 'Present'
                    }
                }
            }

            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    $mockTestTargetResourceParameters.Ensure = 'Absent'

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeFalse
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }

        Context 'When using static IP address' {
            Context 'When the property <MockPropertyName> is not in desired state' -ForEach @(
                @{
                    MockPropertyName  = 'IpAddress'
                    MockExpectedValue = '192.168.10.45/255.255.252.0'
                    MockActualValue   = '192.168.10.45/255.255.255.0'
                }
                @{
                    MockPropertyName  = 'Port'
                    MockExpectedValue = '5031'
                    MockActualValue   = '5030'
                }
                @{
                    MockPropertyName  = 'DHCP'
                    MockExpectedValue = $false
                    MockActualValue   = $true
                }
            ) {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure            = 'Present'
                            $MockPropertyName = $MockActualValue
                        }
                    }
                }

                It 'Should return $false' {
                    InModuleScope -Parameters $_ -ScriptBlock {
                        $mockTestTargetResourceParameters.$MockPropertyName = $MockExpectedValue

                        $result = Test-TargetResource @mockTestTargetResourceParameters

                        $result | Should -BeFalse
                    }

                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                }
            }

            Context 'When static IP address is desired but current state is using DHCP' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure    = 'Present'
                            IpAddress = '192.168.0.1'
                            DHCP      = $true
                        }
                    }
                }

                Context 'When using default value for DHCP' {
                    It 'Should return $false' {
                        InModuleScope -ScriptBlock {
                            $mockTestTargetResourceParameters.IpAddress = '192.168.0.1'

                            $result = Test-TargetResource @mockTestTargetResourceParameters

                            $result | Should -BeFalse
                        }

                        Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                    }
                }

                Context 'When specifying a value for DHCP' {
                    It 'Should return $false' {
                        InModuleScope -ScriptBlock {
                            $mockTestTargetResourceParameters.IpAddress = '192.168.0.1'
                            $mockTestTargetResourceParameters.DHCP = $false

                            $result = Test-TargetResource @mockTestTargetResourceParameters

                            $result | Should -BeFalse
                        }

                        Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                    }
                }
            }
        }

        Context 'When using DHCP' {
            Context 'When the property <MockPropertyName> is not in desired state' -ForEach @(
                @{
                    MockPropertyName  = 'DHCP'
                    MockExpectedValue = $true
                    MockActualValue   = $false
                }
            ) {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure            = 'Present'
                            $MockPropertyName = $MockActualValue
                        }
                    }
                }

                It 'Should return $false' {
                    InModuleScope -Parameters $_ -ScriptBlock {
                        $mockTestTargetResourceParameters.$MockPropertyName = $MockExpectedValue

                        $result = Test-TargetResource @mockTestTargetResourceParameters

                        $result | Should -BeFalse
                    }

                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                }
            }

            Context 'When DHCP is desired but current state is using static IP address' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure    = 'Present'
                            IpAddress = '192.168.0.1'
                            DHCP      = $false
                        }
                    }
                }

                It 'Should return $false' {
                    InModuleScope -ScriptBlock {
                        $mockTestTargetResourceParameters.DHCP = $true

                        $result = Test-TargetResource @mockTestTargetResourceParameters

                        $result | Should -BeFalse
                    }

                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                }
            }
        }

        Context 'When enforcing the state shall happen only when the node is the active node' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    @{
                        Ensure       = 'Present'
                        IpAddress    = '192.168.0.1'
                        DHCP         = $false
                        IsActiveNode = $false
                    }
                }
            }

            It 'Should return $true' {
                InModuleScope -ScriptBlock {
                    $mockTestTargetResourceParameters.DHCP = $true
                    $mockTestTargetResourceParameters.ProcessOnlyOnActiveNode = $true

                    Test-TargetResource @mockTestTargetResourceParameters | Should -BeTrue
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }
    }
}

Describe 'SqlAGListener\Set-TargetResource' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            # Default parameters that are used for the It-blocks.
            $script:mockDefaultParameters = @{
                InstanceName      = 'MSSQLSERVER'
                ServerName        = 'localhost'
                Name              = 'AGListener'
                AvailabilityGroup = 'AG01'
            }
        }
    }

    BeforeEach {
        InModuleScope -ScriptBlock {
            $script:mockSetTargetResourceParameters = $script:mockDefaultParameters.Clone()
        }
    }

    Context 'When the system is in the desired state' {
        Context 'When the listener does not exist' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Ensure = 'Absent'
                    }
                }
            }

            It 'Should not throw and call the correct mocks' {
                InModuleScope -ScriptBlock {
                    $mockSetTargetResourceParameters.Ensure = 'Absent'

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the listener does exist' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Ensure = 'Present'
                    }
                }

                Mock -CommandName Connect-SQL -MockWith {
                    return New-Object -TypeName Object |
                        Add-Member -MemberType 'ScriptProperty' -Name 'AvailabilityGroups' -Value {
                            return @(
                                @{
                                    'AG01' = New-Object -TypeName Object |
                                        Add-Member -MemberType 'ScriptProperty' -Name 'AvailabilityGroupListeners' -Value {
                                            @(
                                                @{
                                                    AGListener = New-Object -TypeName Object |
                                                        Add-Member -MemberType 'NoteProperty' -Name 'PortNumber' -Value 5031 -PassThru |
                                                        Add-Member -MemberType 'ScriptProperty' -Name 'AvailabilityGroupListenerIPAddresses' -Value {
                                                            return @(
                                                                # TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroupListenerIPAddressCollection
                                                        (New-Object -TypeName Object | # TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroupListenerIPAddress
                                                                    Add-Member -MemberType 'NoteProperty' -Name 'IsDHCP' -Value $true -PassThru |
                                                                    Add-Member -MemberType 'NoteProperty' -Name 'IPAddress' -Value '192.168.0.1' -PassThru |
                                                                    Add-Member -MemberType 'NoteProperty' -Name 'SubnetMask' -Value '255.255.255.0' -PassThru
                                                        )
                                                                )
                                                            } -PassThru -Force
                                                        }
                                                    )
                                                } -PassThru -Force
                                            }
                                        )
                                    } -PassThru -Force
                }
            }

            It 'Should not throw and call the correct mocks' {
                InModuleScope -ScriptBlock {
                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the property <MockPropertyName> is in desired state' -ForEach @(
            @{
                MockPropertyName  = 'IpAddress'
                MockExpectedValue = '192.168.10.45/255.255.252.0'
            }
            @{
                MockPropertyName  = 'Port'
                MockExpectedValue = '5031'
            }
            @{
                MockPropertyName  = 'DHCP'
                MockExpectedValue = $false
            }
            @{
                MockPropertyName  = 'DHCP'
                MockExpectedValue = $true
            }
        ) {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Ensure            = 'Present'
                        $MockPropertyName = $MockExpectedValue
                    }
                }

                Mock -CommandName Connect-SQL -MockWith {
                    if ($MockPropertyName -eq 'DHCP')
                    {
                        $MockDynamicDhcpValue = $MockExpectedValue
                    }
                    else
                    {
                        $MockDynamicDhcpValue = $false
                    }

                    return New-Object -TypeName Object |
                        Add-Member -MemberType 'ScriptProperty' -Name 'AvailabilityGroups' -Value {
                            return @(
                                @{
                                    AG01 = New-Object -TypeName Object |
                                        Add-Member -MemberType 'ScriptProperty' -Name 'AvailabilityGroupListeners' -Value {
                                            @(
                                                @{
                                                    AGListener = New-Object -TypeName Object |
                                                        Add-Member -MemberType 'NoteProperty' -Name 'PortNumber' -Value 5031 -PassThru |
                                                        Add-Member -MemberType 'ScriptProperty' -Name 'AvailabilityGroupListenerIPAddresses' -Value {
                                                            # TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroupListenerIPAddressCollection
                                                            return @(
                                                        (New-Object -TypeName Object | # TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroupListenerIPAddress
                                                                    Add-Member -MemberType 'NoteProperty' -Name 'IsDHCP' -Value $MockDynamicDhcpValue -PassThru |
                                                                    Add-Member -MemberType 'NoteProperty' -Name 'IPAddress' -Value '192.168.0.1' -PassThru |
                                                                    Add-Member -MemberType 'NoteProperty' -Name 'SubnetMask' -Value '255.255.252.0' -PassThru
                                                        )
                                                                )
                                                            } -PassThru -Force
                                                        }
                                                    )
                                                } -PassThru -Force
                                            }
                                        )
                                    } -PassThru -Force
                }
            }

            It 'Should return $true' {
                InModuleScope -Parameters $_ -ScriptBlock {
                    $mockSetTargetResourceParameters.$MockPropertyName = $MockExpectedValue

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When the system is not in the desired state' {
        Context 'When Connect-SQL does not return the correct availability group' {
            Context 'When adding a new listener' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure = 'Absent'
                        }
                    }

                    Mock -CommandName Connect-SQL -MockWith {
                        return New-Object -TypeName Object |
                            Add-Member -MemberType 'ScriptProperty' -Name 'AvailabilityGroups' -Value {
                                return @(
                                    @{
                                        AG01 = New-Object -TypeName Object
                                    }
                                )
                            } -PassThru -Force
                    }
                }

                It 'Should throw the correct error message' {
                    InModuleScope -ScriptBlock {
                        $mockSetTargetResourceParameters.AvailabilityGroup = 'UnknownAG'

                        $mockErrorMessage = $script:localizedData.AvailabilityGroupNotFound -f 'UnknownAG', 'MSSQLSERVER'

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage)
                    }

                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When modifying an existing listener' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure = 'Present'
                        }
                    }

                    Mock -CommandName Connect-SQL -MockWith {
                        return New-Object -TypeName Object |
                            Add-Member -MemberType 'ScriptProperty' -Name 'AvailabilityGroups' -Value {
                                return @(
                                    @{
                                        AG01 = New-Object -TypeName Object
                                    }
                                )
                            } -PassThru -Force
                    }
                }

                It 'Should throw the correct error message' {
                    InModuleScope -ScriptBlock {
                        $mockSetTargetResourceParameters.AvailabilityGroup = 'UnknownAG'

                        $mockErrorMessage = $script:localizedData.AvailabilityGroupNotFound -f 'UnknownAG', 'MSSQLSERVER'

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage)
                    }

                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When removing an existing listener' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure = 'Present'
                        }
                    }

                    Mock -CommandName Connect-SQL -MockWith {
                        return New-Object -TypeName Object |
                            Add-Member -MemberType 'ScriptProperty' -Name 'AvailabilityGroups' -Value {
                                return @(
                                    @{
                                        AG01 = New-Object -TypeName Object
                                    }
                                )
                            } -PassThru -Force
                    }
                }

                It 'Should throw the correct error message' {
                    InModuleScope -ScriptBlock {
                        $mockSetTargetResourceParameters.Ensure = 'Absent'
                        $mockSetTargetResourceParameters.AvailabilityGroup = 'UnknownAG'

                        $mockErrorMessage = $script:localizedData.AvailabilityGroupNotFound -f 'UnknownAG', 'MSSQLSERVER'

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage)
                    }

                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }
        }

        Context 'When Connect-SQL does not return the correct listener' {
            Context 'When modifying an existing listener' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure = 'Present'
                        }
                    }

                    Mock -CommandName Connect-SQL -MockWith {
                        return New-Object -TypeName Object |
                            Add-Member -MemberType 'ScriptProperty' -Name 'AvailabilityGroups' -Value {
                                return @(
                                    @{
                                        AG01 = New-Object -TypeName Object |
                                            Add-Member -MemberType 'ScriptProperty' -Name 'AvailabilityGroupListeners' -Value {
                                                return @(
                                                    @{
                                                        AGListener = New-Object -TypeName Object
                                                    }
                                                )
                                            } -PassThru -Force
                                        }
                                    )
                                } -PassThru -Force
                    }
                }

                It 'Should throw the correct error message' {
                    InModuleScope -ScriptBlock {
                        $mockSetTargetResourceParameters.Name = 'UnknownListener'

                        $mockErrorMessage = $script:localizedData.AvailabilityGroupListenerNotFound -f 'UnknownListener', 'AG01'

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage)
                    }

                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When removing an existing listener' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure = 'Present'
                        }
                    }

                    Mock -CommandName Connect-SQL -MockWith {
                        return New-Object -TypeName Object |
                            Add-Member -MemberType 'ScriptProperty' -Name 'AvailabilityGroups' -Value {
                                return @(
                                    @{
                                        AG01 = New-Object -TypeName Object |
                                            Add-Member -MemberType 'ScriptProperty' -Name 'AvailabilityGroupListeners' -Value {
                                                return @(
                                                    @{
                                                        AGListener = New-Object -TypeName Object
                                                    }
                                                )
                                            } -PassThru -Force
                                        }
                                    )
                                } -PassThru -Force
                    }
                }

                It 'Should throw the correct error message' {
                    InModuleScope -ScriptBlock {
                        $mockSetTargetResourceParameters.Ensure = 'Absent'
                        $mockSetTargetResourceParameters.Name = 'UnknownListener'

                        $mockErrorMessage = $script:localizedData.AvailabilityGroupListenerNotFound -f 'UnknownListener', 'AG01'

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage)
                    }

                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }
        }

        Context 'When the listener does not exist' {
            Context 'When only using mandatory parameters' {
                BeforeAll {
                    Mock -CommandName New-SqlAvailabilityGroupListener
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure = 'Absent'
                        }
                    }

                    Mock -CommandName Connect-SQL -MockWith {
                        return New-Object -TypeName Object |
                            Add-Member -MemberType 'ScriptProperty' -Name 'AvailabilityGroups' -Value {
                                return @(
                                    @{
                                        AG01 = New-Object -TypeName Object |
                                            Add-Member -MemberType 'ScriptProperty' -Name 'AvailabilityGroupListeners' -Value {
                                                return @(
                                                    @{
                                                        AGListener = New-Object -TypeName Object
                                                    }
                                                )
                                            } -PassThru -Force
                                        }
                                    )
                                } -PassThru -Force
                    }
                }

                It 'Should not throw and call the correct mocks' {
                    InModuleScope -ScriptBlock {
                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                    }

                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName New-SqlAvailabilityGroupListener -Exactly -Times 1 -Scope It
                }
            }

            Context 'When using DHCP' {
                BeforeAll {
                    Mock -CommandName New-SqlAvailabilityGroupListener
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure = 'Absent'
                        }
                    }

                    Mock -CommandName Connect-SQL -MockWith {
                        return New-Object -TypeName Object |
                            Add-Member -MemberType 'ScriptProperty' -Name 'AvailabilityGroups' -Value {
                                return @(
                                    @{
                                        AG01 = New-Object -TypeName Object
                                    }
                                )
                            } -PassThru -Force
                    }
                }

                It 'Should not throw and call the correct mocks' {
                    InModuleScope -ScriptBlock {
                        $mockSetTargetResourceParameters.DHCP = $true
                        $mockSetTargetResourceParameters.IpAddress = '192.168.10.45/255.255.252.0'

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                    }

                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName New-SqlAvailabilityGroupListener -ParameterFilter {
                        $DhcpSubnet -eq '192.168.10.45/255.255.252.0'
                    } -Exactly -Times 1 -Scope It
                }
            }

            Context 'When passing property Port' {
                BeforeAll {
                    Mock -CommandName New-SqlAvailabilityGroupListener
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure = 'Absent'
                        }
                    }

                    Mock -CommandName Connect-SQL -MockWith {
                        return New-Object -TypeName Object |
                            Add-Member -MemberType 'ScriptProperty' -Name 'AvailabilityGroups' -Value {
                                return @(
                                    @{
                                        AG01 = New-Object -TypeName Object
                                    }
                                )
                            } -PassThru -Force
                    }
                }

                It 'Should not throw and call the correct mocks' {
                    InModuleScope -ScriptBlock {
                        $mockSetTargetResourceParameters.Port = 5031

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                    }

                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName New-SqlAvailabilityGroupListener -ParameterFilter {
                        $Port -eq 5031
                    } -Exactly -Times 1 -Scope It
                }
            }

            Context 'When passing property IpAddress' {
                BeforeAll {
                    Mock -CommandName New-SqlAvailabilityGroupListener
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure = 'Absent'
                        }
                    }

                    Mock -CommandName Connect-SQL -MockWith {
                        return New-Object -TypeName Object |
                            Add-Member -MemberType 'ScriptProperty' -Name 'AvailabilityGroups' -Value {
                                return @(
                                    @{
                                        AG01 = New-Object -TypeName Object
                                    }
                                )
                            } -PassThru -Force
                    }
                }

                It 'Should not throw and call the correct mocks' {
                    InModuleScope -ScriptBlock {
                        $mockSetTargetResourceParameters.IpAddress = '192.168.10.45/255.255.252.0'

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                    }

                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName New-SqlAvailabilityGroupListener -ParameterFilter {
                        $StaticIp -eq '192.168.10.45/255.255.252.0'
                    } -Exactly -Times 1 -Scope It
                }
            }
        }

        Context 'When the listener does exist' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Ensure = 'Present'
                    }
                }

                Mock -CommandName Connect-SQL -MockWith {
                    return New-Object -TypeName Object |
                        Add-Member -MemberType 'ScriptProperty' -Name 'AvailabilityGroups' -Value {
                            return @(
                                @{
                                    AG01 = New-Object -TypeName Object |
                                        Add-Member -MemberType 'ScriptProperty' -Name 'AvailabilityGroupListeners' -Value {
                                            # TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroupListenerIPAddressCollection
                                            return @{
                                                AGListener = New-Object -TypeName Object |
                                                    Add-Member -MemberType 'ScriptMethod' -Name 'Drop' -Value {
                                                        InModuleScope -ScriptBlock {
                                                            $script:mockMethodDropWasRunCount += 1
                                                        }
                                                    } -PassThru -Force
                                                }
                                            } -PassThru -Force
                                        }
                                    )
                                } -PassThru -Force
                }
            }

            BeforeEach {
                InModuleScope -ScriptBlock {
                    $script:mockMethodDropWasRunCount = 0
                }
            }

            It 'Should not throw and call the correct mocks and mocked method' {
                InModuleScope -ScriptBlock {
                    $mockSetTargetResourceParameters.Ensure = 'Absent'

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                    $mockMethodDropWasRunCount | Should -Be 1
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the property Port is not in desired state' {
            BeforeAll {
                Mock -CommandName Set-SqlAvailabilityGroupListener
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Ensure = 'Present'
                        Port   = 5031
                    }
                }

                Mock -CommandName Connect-SQL -MockWith {
                    return New-Object -TypeName Object |
                        Add-Member -MemberType 'ScriptProperty' -Name 'AvailabilityGroups' -Value {
                            return @(
                                @{
                                    AG01 = New-Object -TypeName Object |
                                        Add-Member -MemberType 'ScriptProperty' -Name 'AvailabilityGroupListeners' -Value {
                                            @(
                                                @{
                                                    AGListener = New-Object -TypeName Object |
                                                        Add-Member -MemberType 'NoteProperty' -Name 'PortNumber' -Value 5031 -PassThru -Force
                                                    }
                                                )
                                            } -PassThru -Force
                                        }
                                    )
                                } -PassThru -Force
                }
            }

            It 'Should not throw and call the correct mocks' {
                InModuleScope -ScriptBlock {
                    $mockSetTargetResourceParameters.Port = 5030

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Set-SqlAvailabilityGroupListener -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the property IpAddress is not in desired state' {
            Context 'When there is a single IpAddress in the collection, and that is not in desired state' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure    = 'Present'
                            IpAddress = '192.168.0.1/255.255.252.0'
                        }
                    }
                }

                It 'Should throw the correct error message' {
                    InModuleScope -ScriptBlock {
                        $mockSetTargetResourceParameters.IpAddress = '192.168.10.45/255.255.255.0'

                        $mockErrorMessage = $script:localizedData.AvailabilityGroupListenerIPChangeError -f '192.168.10.45/255.255.255.0', '192.168.0.1/255.255.252.0'

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage)
                    }

                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                }
            }

            Context 'When there two IpAddress in the collection, and one is not in desired state' {
                BeforeAll {
                    Mock -CommandName Add-SqlAvailabilityGroupListenerStaticIp
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure    = 'Present'
                            IpAddress = @(
                                '192.168.0.1/255.255.252.0'
                            )
                        }
                    }

                    Mock -CommandName Connect-SQL -MockWith {
                        return New-Object -TypeName Object |
                            Add-Member -MemberType 'ScriptProperty' -Name 'AvailabilityGroups' -Value {
                                return @(
                                    @{
                                        AG01 = New-Object -TypeName Object |
                                            Add-Member -MemberType 'ScriptProperty' -Name 'AvailabilityGroupListeners' -Value {
                                                @(
                                                    @{
                                                        AGListener = New-Object -TypeName Object |
                                                            Add-Member -MemberType 'NoteProperty' -Name 'PortNumber' -Value 5031 -PassThru |
                                                            Add-Member -MemberType 'ScriptProperty' -Name 'AvailabilityGroupListenerIPAddresses' -Value {
                                                                # TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroupListenerIPAddressCollection
                                                                return @(
                                                            (New-Object -TypeName Object | # TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroupListenerIPAddress
                                                                        Add-Member -MemberType 'NoteProperty' -Name 'IPAddress' -Value '192.168.0.1' -PassThru |
                                                                        Add-Member -MemberType 'NoteProperty' -Name 'SubnetMask' -Value '255.255.252.0' -PassThru -Force
                                                            )
                                                                    )
                                                                } -PassThru -Force
                                                            }
                                                        )
                                                    } -PassThru -Force
                                                }
                                            )
                                        } -PassThru -Force
                    }
                }

                It 'Should not throw and call the correct mocks' {
                    InModuleScope -ScriptBlock {
                        $mockSetTargetResourceParameters.IpAddress = @(
                            '192.168.10.45/255.255.255.0'
                            '192.168.0.1/255.255.252.0'
                        )

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                    }

                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName Add-SqlAvailabilityGroupListenerStaticIp -Exactly -Times 1 -Scope It
                }
            }
        }

        Context 'When the property DHCP is not in desired state' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Ensure = 'Present'
                        DHCP   = $false
                    }
                }
            }

            It 'Should return $true' {
                InModuleScope -ScriptBlock {
                    $mockSetTargetResourceParameters.DHCP = $true

                    $mockErrorMessage = $script:localizedData.AvailabilityGroupListenerDHCPChangeError -f $true, $false

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage)
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }
    }
}

Describe 'SqlAGListener\Get-SQLAlwaysOnAvailabilityGroupListener' -Skip:($IsLinux -or $IsMacOS) {
    BeforeAll {
        Mock -CommandName Connect-SQL -MockWith {
            return New-Object -TypeName Object |
                Add-Member -MemberType 'ScriptProperty' -Name 'AvailabilityGroups' -Value {
                    return @(
                        @{
                            AG01 = New-Object -TypeName Object |
                                Add-Member -MemberType 'ScriptProperty' -Name 'AvailabilityGroupListeners' -Value {
                                    @(
                                        @{
                                            AGListener = New-Object -TypeName Object |
                                                Add-Member -MemberType 'NoteProperty' -Name 'PortNumber' -Value 5031 -PassThru |
                                                Add-Member -MemberType 'ScriptProperty' -Name 'AvailabilityGroupListenerIPAddresses' -Value {
                                                    return @(
                                                        # TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroupListenerIPAddressCollection
                                                (New-Object -TypeName Object | # TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroupListenerIPAddress
                                                            Add-Member -MemberType 'NoteProperty' -Name 'IsDHCP' -Value $true -PassThru |
                                                            Add-Member -MemberType 'NoteProperty' -Name 'IPAddress' -Value '192.168.0.1' -PassThru |
                                                            Add-Member -MemberType 'NoteProperty' -Name 'SubnetMask' -Value '255.255.255.0' -PassThru
                                                )
                                                        )
                                                    } -PassThru -Force
                                                }
                                            )
                                        } -PassThru -Force
                                    }
                                )
                            } -PassThru -Force
        }
    }

    Context 'When the Availability Group exist' {
        It 'Should return the correct values for each property' {
            InModuleScope -ScriptBlock {
                $mockGetSQLAlwaysOnAvailabilityGroupListenerParameters = @{
                    Name              = 'AGListener'
                    AvailabilityGroup = 'AG01'
                    InstanceName      = 'MSSQLSERVER'
                    ServerName        = 'localhost'
                }

                $result = Get-SQLAlwaysOnAvailabilityGroupListener @mockGetSQLAlwaysOnAvailabilityGroupListenerParameters

                $result.PortNumber | Should -Be 5031
                $result.AvailabilityGroupListenerIPAddresses.IsDHCP | Should -BeTrue
                $result.AvailabilityGroupListenerIPAddresses.IPAddress | Should -Be '192.168.0.1'
                $result.AvailabilityGroupListenerIPAddresses.SubnetMask | Should -Be '255.255.255.0'
            }
        }
    }

    Context 'When the Availability Group Listener does not exist' {
        It 'Should return the correct values for each property' {
            InModuleScope -ScriptBlock {
                $mockGetSQLAlwaysOnAvailabilityGroupListenerParameters = @{
                    Name              = 'UnknownListener'
                    AvailabilityGroup = 'AG01'
                    InstanceName      = 'MSSQLSERVER'
                    ServerName        = 'localhost'
                }

                $result = Get-SQLAlwaysOnAvailabilityGroupListener @mockGetSQLAlwaysOnAvailabilityGroupListenerParameters

                $result | Should -BeNullOrEmpty
            }
        }
    }

    Context 'When the Availability Group does not exist' {
        It 'Should throw the correct error message' {
            InModuleScope -ScriptBlock {
                $mockGetSQLAlwaysOnAvailabilityGroupListenerParameters = @{
                    Name              = 'AGListener'
                    AvailabilityGroup = 'UnknownAG'
                    InstanceName      = 'MSSQLSERVER'
                    ServerName        = 'localhost'
                }

                $mockErrorMessage = $script:localizedData.AvailabilityGroupNotFound -f 'UnknownAG', 'MSSQLSERVER'

                { $result = Get-SQLAlwaysOnAvailabilityGroupListener @mockGetSQLAlwaysOnAvailabilityGroupListenerParameters } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage)
            }
        }
    }
}
