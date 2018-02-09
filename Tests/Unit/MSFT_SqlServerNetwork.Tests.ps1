$script:DSCModuleName      = 'SqlServerDsc'
$script:DSCResourceName    = 'MSFT_SqlServerNetwork'

#region HEADER

# Unit Test Template Version: 1.2.0
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
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

#endregion HEADER

function Invoke-TestSetup {
}

function Invoke-TestCleanup {
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

# Begin Testing
try
{
    Invoke-TestSetup

    InModuleScope $script:DSCResourceName {
        $mockInstanceName = 'TEST'
        $mockTcpProtocolName = 'Tcp'
        $mockIPAddressIPAll = 'IPAll'
        $mockIPAddressCustom = '10.0.1.11'
        $mockNamedPipesProtocolName = 'NP'
        $mockTcpDynamicPortNumber = '24680'

        $script:WasMethodAlterCalled = $false

        $mockFunction_NewObject_ManagedComputer = {
                return New-Object -TypeName Object |
                    Add-Member -MemberType ScriptProperty -Name 'ServerInstances' -Value {
                        return @{
                            $mockInstanceName = New-Object -TypeName Object |
                                Add-Member -MemberType ScriptProperty -Name 'ServerProtocols' -Value {
                                    return @{
                                        $mockDynamicValue_TcpProtocolName = New-Object -TypeName Object |
                                            Add-Member -MemberType NoteProperty -Name 'IsEnabled' -Value $mockDynamicValue_IsEnabled -PassThru |
                                            Add-Member -MemberType ScriptProperty -Name 'ProtocolProperties' -Value {
                                                return @{
                                                    'ListenOnAllIPs' = New-Object -TypeName Object |
                                                        Add-Member -MemberType NoteProperty -Name 'Value' -Value $mockDynamicValue_ListenAll -PassThru -Force
                                                }
                                            } -PassThru |
                                            Add-Member -MemberType ScriptProperty -Name 'IPAddresses' -Value {
                                                return @{
                                                    'IPAll' = New-Object -TypeName Object |
                                                        Add-Member -MemberType ScriptProperty -Name 'IPAddressProperties' -Value {
                                                            return @{
                                                                'TcpDynamicPorts' = New-Object -TypeName Object |
                                                                    Add-Member -MemberType NoteProperty -Name 'Value' -Value $mockDynamicValue_TcpDynamicPort -PassThru -Force
                                                                'TcpPort' = New-Object -TypeName Object |
                                                                    Add-Member -MemberType NoteProperty -Name 'Value' -Value $mockDynamicValue_TcpPort -PassThru -Force
                                                            }
                                                        } -PassThru -Force
                                                    'IP1' = New-Object -TypeName Object |
                                                        Add-Member -MemberType ScriptProperty -Name 'IPAddressProperties' -Value {
                                                            return @{
                                                                'Enabled' = New-Object -TypeName Object |
                                                                    Add-Member -MemberType NoteProperty -Name 'Value' -Value $mockDynamicValue_IsEnabled -PassThru -Force
                                                                'TcpDynamicPorts' = New-Object -TypeName Object |
                                                                    Add-Member -MemberType NoteProperty -Name 'Value' -Value $mockDynamicValue_TcpDynamicPort -PassThru -Force
                                                                'TcpPort' = New-Object -TypeName Object |
                                                                    Add-Member -MemberType NoteProperty -Name 'Value' -Value $mockDynamicValue_TcpPort -PassThru -Force
                                                            }
                                                        } -PassThru -Force
                                                }
                                            } -PassThru |
                                            Add-Member -MemberType ScriptMethod -Name 'Alter' -Value {
                                                <#
                                                    It is not possible to verify that the correct value was set here for TcpDynamicPorts and
                                                    TcpPort with the current implementation.
                                                    If `$this.IPAddresses['IPAll'].IPAddressProperties['TcpDynamicPorts'].Value` would be
                                                    called it would just return the same value over an over again, not the value that was
                                                    set in the function Set-TargetResource.
                                                    To be able to do this check for TcpDynamicPorts and TcpPort, then the class must be mocked
                                                    in SMO.cs.
                                                #>
                                                switch ($mockExpectedValue_IPAddressKey)
                                                {
                                                    'IPAll'
                                                    {
                                                        if ($this.IsEnabled -ne $mockExpectedValue_IsEnabled)
                                                        {
                                                            throw ('Mock method Alter() was called with an unexpected value for IsEnabled. Expected ''{0}'', but was ''{1}''' -f $mockExpectedValue_IsEnabled, $this.IsEnabled)
                                                        }
                                                    }
                                                    default
                                                    {
                                                        <#
                                                            It is not possible to verify that the correct value was set here for TcpDynamicPorts and
                                                            TcpPort with the current implementation. See comment above.
                                                        #>
                                                    }
                                                }

                                                # This can be used to verify so that alter method was actually called.
                                                $script:WasMethodAlterCalled = $true
                                            } -PassThru -Force
                                    }
                                } -PassThru -Force
                        }
                    } -PassThru -Force
        }

        $mockFunction_NewObject_ManagedComputer_ParameterFilter = {
            $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer'
        }

        $mockFunction_RegisterSqlWmiManagement = {
            return [System.AppDomain]::CreateDomain('DummyTestApplicationDomain')
        }

        $mockIPAllParameters = @{
            InstanceName = $mockInstanceName
            ProtocolName = $mockTcpProtocolName
            IPAddress    = $mockIPAddressIPAll
        }

        $mockCustomParameters = @{
            InstanceName = $mockInstanceName
            ProtocolName = $mockTcpProtocolName
            IPAddress    = $mockIPAddressCustom
        }

        Describe "MSFT_SqlServerNetwork\Get-TargetResource" -Tag 'Get' {

            BeforeEach {
                Mock -CommandName Register-SqlWmiManagement `
                    -MockWith $mockFunction_RegisterSqlWmiManagement `
                    -Verifiable

                Mock -CommandName New-Object `
                    -MockWith $mockFunction_NewObject_ManagedComputer `
                    -ParameterFilter $mockFunction_NewObject_ManagedComputer_ParameterFilter -Verifiable
            }

            Context 'When Get-TargetResource is called' {

                Context "IPAddress: $mockIPAddressIPAll" {

                    BeforeEach {
                        $testIPAllParameters = $mockIPAllParameters.Clone()

                        $mockDynamicValue_TcpProtocolName = $mockTcpProtocolName
                        $mockDynamicValue_IsEnabled       = $true
                        $mockDynamicValue_ListenAll       = $true
                        $mockDynamicValue_TcpDynamicPort  = ''
                        $mockDynamicValue_TcpPort         = '4509'
                    }

                    It 'Should return the correct values' {

                        # Act
                        $result = Get-TargetResource @testIPAllParameters

                        # Assert
                        $result.IsEnabled      | Should -Be $mockDynamicValue_IsEnabled
                        $result.ListenAll      | Should -Be $mockDynamicValue_ListenAll
                        $result.TcpDynamicPort | Should -Be $false
                        $result.TcpPort        | Should -Be $mockDynamicValue_TcpPort

                        Assert-MockCalled -CommandName Register-SqlWmiManagement -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName New-Object -Exactly -Times 1 -Scope It `
                            -ParameterFilter $mockFunction_NewObject_ManagedComputer_ParameterFilter
                    }

                    It 'Should return the same values as passed as parameters' {

                        # Act
                        $result = Get-TargetResource @testIPAllParameters

                        # Assert
                        $result.InstanceName | Should -Be $testIPAllParameters.InstanceName
                        $result.ProtocolName | Should -Be $testIPAllParameters.ProtocolName
                        $result.IPAddress    | Should -Be $testIPAllParameters.IPAddress
                    }
                }

                Context "IPAddress: $mockIPAddressCustom" {

                    BeforeEach {
                        $testCustomParameters = $mockCustomParameters.Clone()

                        $mockDynamicValue_TcpProtocolName = $mockTcpProtocolName
                        $mockDynamicValue_IsEnabled       = $true
                        $mockDynamicValue_ListenAll       = $null
                        $mockDynamicValue_TcpDynamicPort  = ''
                        $mockDynamicValue_TcpPort         = '4509'
                    }

                    Mock -CommandName 'Resolve-SqlProtocolIPAddress' -MockWith { 'IP1' }

                    It 'Should return the correct values' {

                        # Act
                        $result = Get-TargetResource @testCustomParameters

                        # Assert
                        $result.IsEnabled      | Should -Be $mockDynamicValue_IsEnabled
                        $result.ListenAll      | Should -Be $mockDynamicValue_ListenAll
                        $result.TcpDynamicPort | Should -Be $false
                        $result.TcpPort        | Should -Be $mockDynamicValue_TcpPort

                        Assert-MockCalled -CommandName Register-SqlWmiManagement -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName New-Object -Exactly -Times 1 -Scope It `
                            -ParameterFilter $mockFunction_NewObject_ManagedComputer_ParameterFilter
                    }

                    It 'Should return the same values as passed as parameters' {

                        # Act
                        $result = Get-TargetResource @testCustomParameters

                        # Assert
                        $result.InstanceName | Should -Be $testCustomParameters.InstanceName
                        $result.ProtocolName | Should -Be $testCustomParameters.ProtocolName
                        $result.IPAddress    | Should -Be $testCustomParameters.IPAddress
                    }
                }
            }

            Assert-VerifiableMock
        }

        Describe "MSFT_SqlServerNetwork\Test-TargetResource" -Tag 'Test' {

            BeforeEach {
                Mock -CommandName Register-SqlWmiManagement `
                    -MockWith $mockFunction_RegisterSqlWmiManagement `
                    -Verifiable

                Mock -CommandName New-Object `
                    -MockWith $mockFunction_NewObject_ManagedComputer `
                    -ParameterFilter $mockFunction_NewObject_ManagedComputer_ParameterFilter -Verifiable
            }

            Context "IPAddress: $mockIPAddressIPAll" {

                BeforeEach {
                    $testParameters = $mockIPAllParameters.Clone()
                }

                Context 'When the system is not in the desired state' {
                    BeforeEach {
                        $mockDynamicValue_TcpProtocolName = $mockTcpProtocolName
                        $mockDynamicValue_IsEnabled       = $true
                        $mockDynamicValue_ListenAll       = $true
                        $mockDynamicValue_TcpDynamicPort  = ''
                        $mockDynamicValue_TcpPort         = '4509'
                    }

                    <#
                        This test does not work until support for more than one protocol
                        is added. See issue #14.
                    #>
                    <#
                    Context 'When Protocol is not in desired state' {
                        BeforeEach {
                            $testParameters += @{
                                IsEnabled = $true
                                TcpDynamicPort = $false
                                TcpPort = '4509'
                            }

                            $testParameters.ProtocolName = $mockNamedPipesProtocolName
                        }

                        It 'Should return $false' {
                            $result = Test-TargetResource @testParameters
                            $result | Should Be $false
                        }
                    }
                    #>

                    Context 'When IsEnabled is not in desired state' {
                        BeforeEach {
                            $testParameters += @{
                                IsEnabled = $false
                                ListenAll = $true
                                TcpDynamicPort = $false
                                TcpPort = '4509'
                            }
                        }

                        It 'Should return $false' {
                            $result = Test-TargetResource @testParameters
                            $result | Should -Be $false
                        }
                    }

                    Context 'When current state is using static tcp port' {
                        Context 'When TcpDynamicPort is not in desired state' {
                            BeforeEach {
                                $testParameters += @{
                                    TcpDynamicPort = $true
                                    IsEnabled = $false
                                    ListenAll = $true
                                }
                            }

                            It 'Should return $false' {
                                $result = Test-TargetResource @testParameters
                                $result | Should -Be $false
                            }
                        }

                        Context 'When TcpPort is not in desired state' {
                            BeforeEach {
                                $testParameters += @{
                                    TcpPort = '1433'
                                    IsEnabled = $true
                                    ListenAll = $true
                                }
                            }

                            It 'Should return $false' {
                                $result = Test-TargetResource @testParameters
                                $result | Should -Be $false
                            }
                        }
                    }

                    Context 'When current state is using dynamic tcp port' {
                        BeforeEach {
                            $mockDynamicValue_TcpProtocolName = $mockTcpProtocolName
                            $mockDynamicValue_IsEnabled = $true
                            $mockDynamicValue_ListenAll = $true
                            $mockDynamicValue_TcpDynamicPort = $mockTcpDynamicPortNumber
                            $mockDynamicValue_TcpPort = ''
                        }

                        Context 'When TcpPort is not in desired state' {
                            BeforeEach {
                                $testParameters += @{
                                    TcpPort = '1433'
                                    IsEnabled = $true
                                    ListenAll = $true
                                }
                            }

                            It 'Should return $false' {
                                $result = Test-TargetResource @testParameters
                                $result | Should -Be $false
                            }
                        }
                    }

                    Context 'When both TcpDynamicPort and TcpPort are being set' {
                        BeforeEach {
                            $testParameters += @{
                                TcpDynamicPort = $true
                                TcpPort = '1433'
                                IsEnabled = $false
                                ListenAll = $true
                            }
                        }

                        It 'Should throw the correct error message' {
                            $testErrorMessage = $script:localizedData.ErrorDynamicAndStaticPortSpecified
                            { Test-TargetResource @testParameters } | Should -Throw $testErrorMessage
                        }
                    }
                }

                Context 'When the system is in the desired state' {
                    BeforeEach {
                        $mockDynamicValue_TcpProtocolName = $mockTcpProtocolName
                        $mockDynamicValue_IsEnabled = $true
                        $mockDynamicValue_ListenAll = $true
                        $mockDynamicValue_TcpDynamicPort = $mockTcpDynamicPortNumber
                        $mockDynamicValue_TcpPort = '1433'
                    }

                    Context 'When TcpPort is in desired state' {
                        BeforeEach {
                            $testParameters += @{
                                TcpPort = '1433'
                                IsEnabled = $true
                                ListenAll = $true
                            }
                        }

                        It 'Should return $true' {
                            $result = Test-TargetResource @testParameters
                            $result | Should -Be $true
                        }
                    }

                    Context 'When TcpDynamicPort is in desired state' {
                        BeforeEach {
                            $testParameters += @{
                                TcpDynamicPort = $true
                                IsEnabled = $true
                                ListenAll = $true
                            }
                        }

                        It 'Should return $true' {
                            $result = Test-TargetResource @testParameters
                            $result | Should -Be $true
                        }
                    }
                }
            }

            Context "IPAddress: $mockIPAddressCustom" {

                BeforeEach {
                    $testParameters = $mockCustomParameters.Clone()
                }

                Mock -CommandName 'Resolve-SqlProtocolIPAddress' -MockWith { 'IP1' }

                Context 'When the system is not in the desired state' {
                    BeforeEach {
                        $mockDynamicValue_TcpProtocolName = $mockTcpProtocolName
                        $mockDynamicValue_IsEnabled       = $true
                        $mockDynamicValue_ListenAll       = $null
                        $mockDynamicValue_TcpDynamicPort  = ''
                        $mockDynamicValue_TcpPort         = '4509'
                    }

                    <#
                        This test does not work until support for more than one protocol
                        is added. See issue #14.
                    #>
                    <#
                    Context 'When Protocol is not in desired state' {
                        BeforeEach {
                            $testParameters += @{
                                IsEnabled = $true
                                TcpDynamicPort = $false
                                TcpPort = '4509'
                            }

                            $testParameters.ProtocolName = $mockNamedPipesProtocolName
                        }

                        It 'Should return $false' {
                            $result = Test-TargetResource @testParameters
                            $result | Should Be $false
                        }
                    }
                    #>

                    Context 'When IsEnabled is not in desired state' {
                        BeforeEach {
                            $testParameters += @{
                                IsEnabled = $false
                                ListenAll = $true
                                TcpDynamicPort = $false
                                TcpPort = '4509'
                            }
                        }

                        It 'Should return $false' {
                            $result = Test-TargetResource @testParameters
                            $result | Should -Be $false
                        }
                    }

                    Context 'When current state is using static tcp port' {
                        Context 'When TcpDynamicPort is not in desired state' {
                            BeforeEach {
                                $testParameters += @{
                                    TcpDynamicPort = $true
                                    IsEnabled = $false
                                    ListenAll = $true
                                }
                            }

                            It 'Should return $false' {
                                $result = Test-TargetResource @testParameters
                                $result | Should -Be $false
                            }
                        }

                        Context 'When TcpPort is not in desired state' {
                            BeforeEach {
                                $testParameters += @{
                                    TcpPort = '1433'
                                    IsEnabled = $true
                                    ListenAll = $true
                                }
                            }

                            It 'Should return $false' {
                                $result = Test-TargetResource @testParameters
                                $result | Should -Be $false
                            }
                        }
                    }

                    Context 'When current state is using dynamic tcp port' {
                        BeforeEach {
                            $mockDynamicValue_TcpProtocolName = $mockTcpProtocolName
                            $mockDynamicValue_IsEnabled = $true
                            $mockDynamicValue_ListenAll = $true
                            $mockDynamicValue_TcpDynamicPort = $mockTcpDynamicPortNumber
                            $mockDynamicValue_TcpPort = ''
                        }

                        Context 'When TcpPort is not in desired state' {
                            BeforeEach {
                                $testParameters += @{
                                    TcpPort = '1433'
                                    IsEnabled = $true
                                    ListenAll = $true
                                }
                            }

                            It 'Should return $false' {
                                $result = Test-TargetResource @testParameters
                                $result | Should -Be $false
                            }
                        }
                    }

                    Context 'When both TcpDynamicPort and TcpPort are being set' {
                        BeforeEach {
                            $testParameters += @{
                                TcpDynamicPort = $true
                                TcpPort = '1433'
                                IsEnabled = $false
                                ListenAll = $true
                            }
                        }

                        It 'Should throw the correct error message' {
                            $testErrorMessage = $script:localizedData.ErrorDynamicAndStaticPortSpecified
                            { Test-TargetResource @testParameters } | Should -Throw $testErrorMessage
                        }
                    }
                }

                Context 'When the system is in the desired state' {
                    BeforeEach {
                        $mockDynamicValue_TcpProtocolName = $mockTcpProtocolName
                        $mockDynamicValue_IsEnabled = $true
                        $mockDynamicValue_ListenAll = $true
                        $mockDynamicValue_TcpDynamicPort = $mockTcpDynamicPortNumber
                        $mockDynamicValue_TcpPort = '1433'
                    }

                    Context 'When TcpPort is in desired state' {
                        BeforeEach {
                            $testParameters += @{
                                TcpPort = '1433'
                                IsEnabled = $true
                                ListenAll = $true
                            }
                        }

                        It 'Should return $true' {
                            $result = Test-TargetResource @testParameters
                            $result | Should -Be $true
                        }
                    }

                    Context 'When TcpDynamicPort is in desired state' {
                        BeforeEach {
                            $testParameters += @{
                                TcpDynamicPort = $true
                                IsEnabled = $true
                                ListenAll = $true
                            }
                        }

                        It 'Should return $true' {
                            $result = Test-TargetResource @testParameters
                            $result | Should -Be $true
                        }
                    }
                }
            }

            Assert-VerifiableMock
        }

        Describe "MSFT_SqlServerNetwork\Set-TargetResource" -Tag 'Set' {

            BeforeEach {
                Mock -CommandName Restart-SqlService -Verifiable
                Mock -CommandName Register-SqlWmiManagement `
                    -MockWith $mockFunction_RegisterSqlWmiManagement `
                    -Verifiable

                Mock -CommandName New-Object `
                    -MockWith $mockFunction_NewObject_ManagedComputer `
                    -ParameterFilter $mockFunction_NewObject_ManagedComputer_ParameterFilter -Verifiable

                # This is used to evaluate if mocked Alter() method was called.
                $script:WasMethodAlterCalled = $false
            }

            Context "IPAddress: $mockIPAddressIPAll" {

                BeforeEach {
                    $testParameters = $mockIPAllParameters.Clone()
                }

                Context 'When the system is not in the desired state' {
                    BeforeEach {
                        # This is the values the mock will return
                        $mockDynamicValue_TcpProtocolName = $mockTcpProtocolName
                        $mockDynamicValue_IsEnabled = $true
                        $mockDynamicValue_ListenAll = $true
                        $mockDynamicValue_TcpDynamicPort = ''
                        $mockDynamicValue_TcpPort = '4509'

                        <#
                            This is the values we expect to be set when Alter() method is called.
                            These values will set here to same as the values the mock will return,
                            but before each test the these will be set to the correct value that is
                            expected to be returned for that particular test.
                        #>
                        $mockExpectedValue_IPAddressKey = 'IPAll'
                        $mockExpectedValue_IsEnabled = $mockDynamicValue_IsEnabled
                    }

                    Context 'When IsEnabled is not in desired state' {
                        BeforeEach {
                            $testParameters += @{
                                IsEnabled = $false
                                ListenAll = $true
                                TcpDynamicPort = $false
                                TcpPort = '4509'
                                RestartService = $true
                            }

                            $mockExpectedValue_IPAddressKey = 'IPAll'
                            $mockExpectedValue_IsEnabled = $false
                        }

                        It 'Should call Set-TargetResource without throwing and should call Alter()' {
                            { Set-TargetResource @testParameters } | Should -Not -Throw
                            $script:WasMethodAlterCalled | Should -Be $true

                            Assert-MockCalled -CommandName Restart-SqlService -Exactly -Times 1 -Scope It
                        }
                    }

                    Context 'When current state is using static tcp port' {
                        Context 'When TcpDynamicPort is not in desired state' {
                            BeforeEach {
                                $testParameters += @{
                                    IsEnabled = $true
                                    ListenAll = $true
                                    TcpDynamicPort = $true
                                }
                            }

                            It 'Should call Set-TargetResource without throwing and should call Alter()' {
                                { Set-TargetResource @testParameters } | Should -Not -Throw
                                $script:WasMethodAlterCalled | Should -Be $true

                                Assert-MockCalled -CommandName Restart-SqlService -Exactly -Times 0 -Scope It
                            }
                        }

                        Context 'When TcpPort is not in desired state' {
                            BeforeEach {
                                $testParameters += @{
                                    IsEnabled = $true
                                    ListenAll = $true
                                    TcpDynamicPort = $false
                                    TcpPort = '4508'
                                }
                            }

                            It 'Should call Set-TargetResource without throwing and should call Alter()' {
                                { Set-TargetResource @testParameters } | Should -Not -Throw
                                $script:WasMethodAlterCalled | Should -Be $true

                                Assert-MockCalled -CommandName Restart-SqlService -Exactly -Times 0 -Scope It
                            }
                        }
                    }

                    Context 'When current state is using dynamic tcp port ' {
                        BeforeEach {
                            # This is the values the mock will return
                            $mockDynamicValue_TcpProtocolName = $mockTcpProtocolName
                            $mockDynamicValue_IsEnabled = $true
                            $mockDynamicValue_ListenAll = $true
                            $mockDynamicValue_TcpDynamicPort = $mockTcpDynamicPortNumber
                            $mockDynamicValue_TcpPort = ''

                            <#
                                This is the values we expect to be set when Alter() method is called.
                                These values will set here to same as the values the mock will return,
                                but before each test the these will be set to the correct value that is
                                expected to be returned for that particular test.
                            #>
                            $mockExpectedValue_IPAddressKey = 'IPAll'
                            $mockExpectedValue_IsEnabled = $mockDynamicValue_IsEnabled
                        }

                        Context 'When TcpPort is not in desired state' {
                            BeforeEach {
                                $testParameters += @{
                                    IsEnabled = $true
                                    ListenAll = $true
                                    TcpDynamicPort = $false
                                    TcpPort = '4508'
                                }
                            }

                            It 'Should call Set-TargetResource without throwing and should call Alter()' {
                                { Set-TargetResource @testParameters } | Should -Not -Throw
                                $script:WasMethodAlterCalled | Should -Be $true

                                Assert-MockCalled -CommandName Restart-SqlService -Exactly -Times 0 -Scope It
                            }
                        }
                    }

                    Context 'When both TcpDynamicPort and TcpPort are being set' {
                        BeforeEach {
                            $testParameters += @{
                                TcpDynamicPort = $true
                                TcpPort = '1433'
                                IsEnabled = $false
                                ListenAll = $true
                            }
                        }

                        It 'Should throw the correct error message' {
                            $testErrorMessage = ($script:localizedData.ErrorDynamicAndStaticPortSpecified)
                            { Set-TargetResource @testParameters } | Should -Throw $testErrorMessage
                        }
                    }
                }

                Context 'When the system is in the desired state' {
                    BeforeEach {
                        # This is the values the mock will return
                        $mockDynamicValue_TcpProtocolName = $mockTcpProtocolName
                        $mockDynamicValue_IsEnabled = $true
                        $mockDynamicValue_ListenAll = $true
                        $mockDynamicValue_TcpDynamicPort = ''
                        $mockDynamicValue_TcpPort = '4509'

                        <#
                            We do not expect Alter() method to be called. So we set this to $null so
                            if it is, then it will throw an error.
                        #>
                        $mockExpectedValue_IPAddressKey = 'IPAll'
                        $mockExpectedValue_IsEnabled = $null

                        $testParameters += @{
                            IsEnabled = $true
                            ListenAll = $true
                            TcpDynamicPort = $false
                            TcpPort = '4509'
                        }
                    }

                    It 'Should call Set-TargetResource without throwing and should not call Alter()' {
                        { Set-TargetResource @testParameters } | Should -Not -Throw
                        $script:WasMethodAlterCalled | Should -Be $false

                        Assert-MockCalled -CommandName Restart-SqlService -Exactly -Times 0 -Scope It
                    }
                }
            }

            Context "IPAddress: $mockIPAddressCustom" {

                BeforeEach {
                    $testParameters = $mockCustomParameters.Clone()
                }

                Mock -CommandName 'Resolve-SqlProtocolIPAddress' -MockWith { 'IP1' }

                Context 'When the system is not in the desired state' {
                    BeforeEach {
                        # This is the values the mock will return
                        $mockDynamicValue_TcpProtocolName = $mockTcpProtocolName
                        $mockDynamicValue_IsEnabled = $true
                        $mockDynamicValue_ListenAll = $true
                        $mockDynamicValue_TcpDynamicPort = ''
                        $mockDynamicValue_TcpPort = '4509'

                        <#
                            This is the values we expect to be set when Alter() method is called.
                            These values will set here to same as the values the mock will return,
                            but before each test the these will be set to the correct value that is
                            expected to be returned for that particular test.
                        #>
                        $mockExpectedValue_IPAddressKey = 'IP1'
                        $mockExpectedValue_IsEnabled = $mockDynamicValue_IsEnabled
                    }

                    Context 'When IsEnabled is not in desired state' {
                        BeforeEach {
                            $testParameters += @{
                                IsEnabled = $false
                                ListenAll = $true
                                TcpDynamicPort = $false
                                TcpPort = '4509'
                                RestartService = $true
                            }

                            $mockExpectedValue_IPAddressKey = 'IP1'
                            $mockExpectedValue_IsEnabled = $false
                        }

                        It 'Should call Set-TargetResource without throwing and should call Alter()' {
                            { Set-TargetResource @testParameters } | Should -Not -Throw
                            $script:WasMethodAlterCalled | Should -Be $true

                            Assert-MockCalled -CommandName Restart-SqlService -Exactly -Times 1 -Scope It
                        }
                    }

                    Context 'When current state is using static tcp port' {
                        Context 'When TcpDynamicPort is not in desired state' {
                            BeforeEach {
                                $testParameters += @{
                                    IsEnabled = $true
                                    ListenAll = $true
                                    TcpDynamicPort = $true
                                }
                            }

                            It 'Should call Set-TargetResource without throwing and should call Alter()' {
                                { Set-TargetResource @testParameters } | Should -Not -Throw
                                $script:WasMethodAlterCalled | Should -Be $true

                                Assert-MockCalled -CommandName Restart-SqlService -Exactly -Times 0 -Scope It
                            }
                        }

                        Context 'When TcpPort is not in desired state' {
                            BeforeEach {
                                $testParameters += @{
                                    IsEnabled = $true
                                    ListenAll = $true
                                    TcpDynamicPort = $false
                                    TcpPort = '4508'
                                }
                            }

                            It 'Should call Set-TargetResource without throwing and should call Alter()' {
                                { Set-TargetResource @testParameters } | Should -Not -Throw
                                $script:WasMethodAlterCalled | Should -Be $true

                                Assert-MockCalled -CommandName Restart-SqlService -Exactly -Times 0 -Scope It
                            }
                        }
                    }

                    Context 'When current state is using dynamic tcp port ' {
                        BeforeEach {
                            # This is the values the mock will return
                            $mockDynamicValue_TcpProtocolName = $mockTcpProtocolName
                            $mockDynamicValue_IsEnabled = $true
                            $mockDynamicValue_ListenAll = $true
                            $mockDynamicValue_TcpDynamicPort = $mockTcpDynamicPortNumber
                            $mockDynamicValue_TcpPort = ''

                            <#
                                This is the values we expect to be set when Alter() method is called.
                                These values will set here to same as the values the mock will return,
                                but before each test the these will be set to the correct value that is
                                expected to be returned for that particular test.
                            #>
                            $mockExpectedValue_IPAddressKey = 'IP1'
                            $mockExpectedValue_IsEnabled = $mockDynamicValue_IsEnabled
                        }

                        Context 'When TcpPort is not in desired state' {
                            BeforeEach {
                                $testParameters += @{
                                    IsEnabled = $true
                                    ListenAll = $true
                                    TcpDynamicPort = $false
                                    TcpPort = '4508'
                                }
                            }

                            It 'Should call Set-TargetResource without throwing and should call Alter()' {
                                { Set-TargetResource @testParameters } | Should -Not -Throw
                                $script:WasMethodAlterCalled | Should -Be $true

                                Assert-MockCalled -CommandName Restart-SqlService -Exactly -Times 0 -Scope It
                            }
                        }
                    }

                    Context 'When both TcpDynamicPort and TcpPort are being set' {
                        BeforeEach {
                            $testParameters += @{
                                TcpDynamicPort = $true
                                TcpPort = '1433'
                                IsEnabled = $false
                                ListenAll = $true
                            }
                        }

                        It 'Should throw the correct error message' {
                            $testErrorMessage = ($script:localizedData.ErrorDynamicAndStaticPortSpecified)
                            { Set-TargetResource @testParameters } | Should -Throw $testErrorMessage
                        }
                    }
                }

                Context 'When the system is in the desired state' {
                    BeforeEach {
                        # This is the values the mock will return
                        $mockDynamicValue_TcpProtocolName = $mockTcpProtocolName
                        $mockDynamicValue_IsEnabled = $true
                        $mockDynamicValue_ListenAll = $true
                        $mockDynamicValue_TcpDynamicPort = ''
                        $mockDynamicValue_TcpPort = '4509'

                        <#
                            We do not expect Alter() method to be called. So we set this to $null so
                            if it is, then it will throw an error.
                        #>
                        $mockExpectedValue_IPAddressKey = 'IP1'
                        $mockExpectedValue_IsEnabled = $null

                        $testParameters += @{
                            IsEnabled = $true
                            ListenAll = $true
                            TcpDynamicPort = $false
                            TcpPort = '4509'
                        }
                    }

                    It 'Should call Set-TargetResource without throwing and should not call Alter()' {
                        { Set-TargetResource @testParameters } | Should -Not -Throw
                        $script:WasMethodAlterCalled | Should -Be $false

                        Assert-MockCalled -CommandName Restart-SqlService -Exactly -Times 0 -Scope It
                    }
                }
            }

            Assert-VerifiableMock
        }
    }
}
finally
{
    Invoke-TestCleanup
}
