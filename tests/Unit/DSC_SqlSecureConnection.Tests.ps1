<#
    .SYNOPSIS
        Unit test for DSC_SqlSecureConnection DSC resource.
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
    $script:dscResourceName = 'DSC_SqlSecureConnection'

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

Describe 'SqlSecureConnection\Get-TargetResource' -Tag 'Get' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            # Default parameters that are used for the It-blocks.
            $script:mockDefaultParameters = @{
                InstanceName = 'INSTANCE'
                Thumbprint      = '2A11AB1AB1A11111A1111AB111111AB11ABCDEFB'
                ServiceAccount  = 'SqlSvc'
                ForceEncryption = $true
            }
        }
    }

    BeforeEach {
        InModuleScope -ScriptBlock {
            $script:mockGetTargetResourceParameters = $script:mockDefaultParameters.Clone()
        }
    }

    Context 'When the system is in the desired state' {
        Context 'When parameter Ensure is set to ''Present''' {
            BeforeEach {
                InModuleScope -ScriptBlock {
                    $script:mockGetTargetResourceParameters.Ensure = 'Present'
                    $script:mockGetTargetResourceParameters.ServerName = 'MyHostName'
                }
            }

            Context 'When force encryption is set to $true in the current state' {
                BeforeAll {
                    Mock -CommandName Get-EncryptedConnectionSetting -MockWith {
                        return @{
                            ForceEncryption = $true
                            Certificate     = '2A11AB1AB1A11111A1111AB111111AB11ABCDEFB'
                        }
                    }

                    Mock -CommandName Test-CertificatePermission -MockWith {
                        return $true
                    }
                }

                It 'Should return the correct value for each property' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $resultGetTargetResource = Get-TargetResource @mockGetTargetResourceParameters

                        $resultGetTargetResource.InstanceName | Should -Be 'INSTANCE'
                        $resultGetTargetResource.Thumbprint | Should -BeExactly '2A11AB1AB1A11111A1111AB111111AB11ABCDEFB'
                        $resultGetTargetResource.ServiceAccount | Should -Be 'SqlSvc'
                        $resultGetTargetResource.ForceEncryption | Should -BeTrue
                        $resultGetTargetResource.Ensure | Should -Be 'Present'
                        $resultGetTargetResource.ServerName | Should -Be 'MyHostName'
                    }

                    Should -Invoke -CommandName Get-EncryptedConnectionSetting -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName Test-CertificatePermission -Exactly -Times 1 -Scope It -ParameterFilter { $Thumbprint -ceq '2A11AB1AB1A11111A1111AB111111AB11ABCDEFB'.ToLower() }
                }
            }
        }

        Context 'When parameter Ensure is set to ''Absent''' {
            BeforeEach {
                InModuleScope -ScriptBlock {
                    $script:mockGetTargetResourceParameters.Ensure = 'Absent'
                }
            }

            Context 'When the system is in the desired state and Ensure is Absent' {
                BeforeAll {
                    Mock -CommandName Get-EncryptedConnectionSetting -MockWith {
                        return @{
                            ForceEncryption = $false
                            Certificate     = ''
                        }
                    }

                    Mock -CommandName Test-CertificatePermission -MockWith {
                        return $true
                    }
                }

                It 'Should return the the state of absent' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $resultGetTargetResource = Get-TargetResource @mockGetTargetResourceParameters

                        $resultGetTargetResource.InstanceName | Should -Be 'INSTANCE'
                        $resultGetTargetResource.Thumbprint | Should -Be 'Empty'
                        $resultGetTargetResource.ServiceAccount | Should -Be 'SqlSvc'
                        $resultGetTargetResource.ForceEncryption | Should -BeFalse
                        $resultGetTargetResource.Ensure | Should -Be 'Absent'
                        $resultGetTargetResource.ServerName | Should -Be 'localhost'
                    }

                    Should -Invoke -CommandName Get-EncryptedConnectionSetting -Exactly -Times 1 -Scope It
                }
            }
        }
    }

    Context 'When the system is not in the desired state' {
        Context 'When parameter Ensure is set to ''Present''' {
            BeforeEach {
                InModuleScope -ScriptBlock {
                    $script:mockGetTargetResourceParameters.Ensure = 'Present'
                }
            }

            Context 'When force encryption is set to $false in the current state' {
                BeforeAll {
                    Mock -CommandName Get-EncryptedConnectionSetting -MockWith {
                        return @{
                            ForceEncryption = $false
                            Certificate     = '2A11AB1AB1A11111A1111AB111111AB11ABCDEFB'
                        }
                    }

                    Mock -CommandName Test-CertificatePermission -MockWith {
                        return $true
                    }
                }

                It 'Should return the correct value for each property' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $resultGetTargetResource = Get-TargetResource @mockGetTargetResourceParameters

                        $resultGetTargetResource.InstanceName | Should -Be 'INSTANCE'
                        $resultGetTargetResource.Thumbprint | Should -Be '2A11AB1AB1A11111A1111AB111111AB11ABCDEFB'
                        $resultGetTargetResource.ServiceAccount | Should -Be 'SqlSvc'
                        $resultGetTargetResource.ForceEncryption | Should -BeFalse
                        $resultGetTargetResource.Ensure | Should -Be 'Absent'
                    }

                    Should -Invoke -CommandName Get-EncryptedConnectionSetting -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the thumbprint is wrong in the current state' {
                BeforeAll {
                    Mock -CommandName Get-EncryptedConnectionSetting -MockWith {
                        return @{
                            ForceEncryption = $true
                            Certificate     = '987654321'
                        }
                    }

                    Mock -CommandName Test-CertificatePermission -MockWith {
                        return $true
                    }
                }

                It 'Should return the correct value for each property' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $resultGetTargetResource = Get-TargetResource @mockGetTargetResourceParameters

                        $resultGetTargetResource.InstanceName | Should -Be 'INSTANCE'
                        $resultGetTargetResource.Thumbprint | Should -Not -Be '2A11AB1AB1A11111A1111AB111111AB11ABCDEFB'
                        $resultGetTargetResource.ServiceAccount | Should -Be 'SqlSvc'
                        $resultGetTargetResource.ForceEncryption | Should -BeTrue
                        $resultGetTargetResource.Ensure | Should -Be 'Absent'
                    }

                    Should -Invoke -CommandName Get-EncryptedConnectionSetting -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the certificate permissions is wrong in the current state' {
                BeforeAll {
                    Mock -CommandName Get-EncryptedConnectionSetting -MockWith {
                        return @{
                            ForceEncryption = $true
                            Certificate     = '2A11AB1AB1A11111A1111AB111111AB11ABCDEFB'
                        }
                    }

                    Mock -CommandName Test-CertificatePermission -MockWith {
                        return $false
                    }
                }

                It 'Should return the correct value for each property' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $resultGetTargetResource = Get-TargetResource @mockGetTargetResourceParameters

                        $resultGetTargetResource.InstanceName | Should -Be 'INSTANCE'
                        $resultGetTargetResource.Thumbprint | Should -Be '2A11AB1AB1A11111A1111AB111111AB11ABCDEFB'
                        $resultGetTargetResource.ServiceAccount | Should -Be 'SqlSvc'
                        $resultGetTargetResource.ForceEncryption | Should -BeTrue
                        $resultGetTargetResource.Ensure | Should -Be 'Absent'
                    }

                    Should -Invoke -CommandName Get-EncryptedConnectionSetting -Exactly -Times 1 -Scope It
                }
            }
        }

        Context 'When parameter Ensure is set to ''Absent''' {
            BeforeEach {
                InModuleScope -ScriptBlock {
                    $script:mockGetTargetResourceParameters.Ensure = 'Absent'
                }
            }

            Context 'When force encryption is set to $true in the current state' {
                BeforeAll {
                    Mock -CommandName Get-EncryptedConnectionSetting -MockWith {
                        return @{
                            ForceEncryption = $true
                            Certificate     = ''
                        }
                    }
                }

                It 'Should return the correct value for each property' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $resultGetTargetResource = Get-TargetResource @mockGetTargetResourceParameters

                        $resultGetTargetResource.InstanceName | Should -Be 'INSTANCE'
                        $resultGetTargetResource.Thumbprint | Should -Be 'Empty'
                        $resultGetTargetResource.ServiceAccount | Should -Be 'SqlSvc'
                        $resultGetTargetResource.ForceEncryption | Should -BeTrue
                        $resultGetTargetResource.Ensure | Should -Be 'Present'
                    }

                    Should -Invoke -CommandName Get-EncryptedConnectionSetting -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the thumbprint is wrong in the current state' {
                BeforeAll {
                    Mock -CommandName Get-EncryptedConnectionSetting -MockWith {
                        return @{
                            ForceEncryption = $false
                            Certificate     = '2A11AB1AB1A11111A1111AB111111AB11ABCDEFB'
                        }
                    }
                }

                It 'Should return the correct value for each property' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $resultGetTargetResource = Get-TargetResource @mockGetTargetResourceParameters

                        $resultGetTargetResource.InstanceName | Should -Be 'INSTANCE'
                        $resultGetTargetResource.Thumbprint | Should -Be '2A11AB1AB1A11111A1111AB111111AB11ABCDEFB'
                        $resultGetTargetResource.ServiceAccount | Should -Be 'SqlSvc'
                        $resultGetTargetResource.ForceEncryption | Should -BeFalse
                        $resultGetTargetResource.Ensure | Should -Be 'Present'
                    }

                    Should -Invoke -CommandName Get-EncryptedConnectionSetting -Exactly -Times 1 -Scope It
                }
            }
        }
    }
}

Describe 'SqlSecureConnection\Set-TargetResource' -Tag 'Set' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            # Default parameters that are used for the It-blocks.
            $script:mockDefaultParameters = @{
                InstanceName = 'INSTANCE'
                Thumbprint      = '2A11AB1AB1A11111A1111AB111111AB11ABCDEFB'
                ServiceAccount  = 'SqlSvc'
                ForceEncryption = $true
                SuppressRestart = $false
                Ensure          = 'Present'
            }
        }
    }

    BeforeEach {
        InModuleScope -ScriptBlock {
            $script:mockSetTargetResourceParameters = $script:mockDefaultParameters.Clone()
        }
    }

    Context 'When the system is not in the desired state' {
        BeforeAll {
            Mock -CommandName Set-EncryptedConnectionSetting
            Mock -CommandName Set-CertificatePermission
            Mock -CommandName Restart-SqlService
        }

        Context 'When Thumbprint contain upper-case' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        InstanceName    = 'INSTANCE'
                        Thumbprint      = '2A11AB1AB1A11111A1111AB111111AB11ABCDEFB'.ToUpper()
                    }
                }
            }

            It 'Should configure with lower-case' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Set-EncryptedConnectionSetting -Exactly -Times 1 -Scope It -ParameterFilter { $Thumbprint -ceq '2A11AB1AB1A11111A1111AB111111AB11ABCDEFB'.ToLower() }
                Should -Invoke -CommandName Set-CertificatePermission -Exactly -Times 1 -Scope It -ParameterFilter { $Thumbprint -ceq '2A11AB1AB1A11111A1111AB111111AB11ABCDEFB'.ToLower() }
                Should -Invoke -CommandName Restart-SqlService -ParameterFilter {
                    $ServerName -eq 'localhost'
                } -Exactly -Times 1 -Scope It
            }
        }

        Context 'When SuppressRestart is true' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        InstanceName    = 'INSTANCE'
                        Thumbprint      = '2A11AB1AB1A11111A1111AB111111AB11ABCDEFB'.ToUpper()
                    }
                }
            }

            It 'Should suppress restarting the SQL service' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters.SuppressRestart = $true

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Set-EncryptedConnectionSetting -Exactly -Times 1 -Scope It -ParameterFilter { $Thumbprint -ceq '2A11AB1AB1A11111A1111AB111111AB11ABCDEFB'.ToLower() }
                Should -Invoke -CommandName Set-CertificatePermission -Exactly -Times 1 -Scope It -ParameterFilter { $Thumbprint -ceq '2A11AB1AB1A11111A1111AB111111AB11ABCDEFB'.ToLower() }
                Should -Invoke -CommandName Restart-SqlService -Exactly -Times 0 -Scope It
            }
        }

        Context 'When only certificate permissions are set' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        InstanceName    = 'INSTANCE'
                        Thumbprint      = '2A11AB1AB1A11111A1111AB111111AB11ABCDEFB'
                        ServiceAccount  = 'SqlSvc'
                        ForceEncryption = $false
                        Ensure          = 'Present'
                    }
                }

                Mock -CommandName Test-CertificatePermission -MockWith {
                    return $true
                }
            }

            It 'Should configure only ForceEncryption and Certificate thumbprint' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    { Set-TargetResource @mockSetTargetResourceParameters -ServerName 'MyHostName'} | Should -Not -Throw
                }

                Should -Invoke -CommandName Set-EncryptedConnectionSetting -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Set-CertificatePermission -Exactly -Times 0 -Scope It
                Should -Invoke -CommandName Restart-SqlService -ParameterFilter {
                    $ServerName -eq 'MyHostName'
                } -Exactly -Times 1 -Scope It
            }
        }

        Context 'When there is no certificate permissions set' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        InstanceName    = 'INSTANCE'
                        Thumbprint      = '2A11AB1AB1A11111A1111AB111111AB11ABCDEFB'
                        ServiceAccount  = 'SqlSvc'
                        ForceEncryption = $true
                        Ensure          = 'Present'
                    }
                }

                Mock -CommandName Test-CertificatePermission -MockWith {
                    return $false
                }
            }

            It 'Should configure only certificate permissions' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Set-EncryptedConnectionSetting -Exactly -Times 0 -Scope It
                Should -Invoke -CommandName Set-CertificatePermission -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Restart-SqlService -Exactly -Times 1 -Scope It
            }
        }

        Context 'When no settings are configured' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        InstanceName    = 'INSTANCE'
                        Thumbprint      = '987654321'
                        ServiceAccount  = 'SqlSvc'
                        ForceEncryption = $false
                        Ensure          = 'Present'
                    }
                }

                Mock -CommandName Test-CertificatePermission -MockWith {
                    return $false
                }
            }

            It 'Should configure Encryption settings and certificate permissions' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Set-EncryptedConnectionSetting -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Set-CertificatePermission -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Restart-SqlService -Exactly -Times 1 -Scope It
            }
        }

        Context 'When ensure is absent' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        InstanceName    = 'INSTANCE'
                        Thumbprint      = '2A11AB1AB1A11111A1111AB111111AB11ABCDEFB'
                        ServiceAccount  = 'SqlSvc'
                        ForceEncryption = $true
                        Ensure          = 'Absent'
                    }
                }

                Mock -CommandName Test-CertificatePermission -MockWith {
                    return $false
                }
            }

            It 'Should configure Encryption settings setting certificate to empty string' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters.Ensure = 'Absent'

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Set-EncryptedConnectionSetting -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Set-CertificatePermission -Exactly -Times 0 -Scope It
                Should -Invoke -CommandName Restart-SqlService -Exactly -Times 1 -Scope It
            }
        }
    }
}

Describe 'SqlSecureConnection\Test-TargetResource' -Tag 'Test' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            # Default parameters that are used for the It-blocks.
            $script:mockDefaultParameters = @{
                InstanceName = 'INSTANCE'
                Thumbprint      = '2A11AB1AB1A11111A1111AB111111AB11ABCDEFB'
                ServiceAccount  = 'SqlSvc'
                ForceEncryption = $true
                SuppressRestart = $false
                Ensure          = 'Present'
            }
        }
    }

    BeforeEach {
        InModuleScope -ScriptBlock {
            $script:mockTestTargetResourceParameters = $script:mockDefaultParameters.Clone()
        }
    }

    Context 'When the system is not in the desired state' {
        Context 'When ForceEncryption is not configured properly' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        InstanceName    = 'INSTANCE'
                        Thumbprint      = '2A11AB1AB1A11111A1111AB111111AB11ABCDEFB'
                        ServiceAccount  = 'SqlSvc'
                        ForceEncryption = $false
                        Ensure          = 'Absent'
                    }
                }
            }

            It 'Should return state as not in desired state' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $resultTestTargetResource = Test-TargetResource @mockTestTargetResourceParameters

                    $resultTestTargetResource | Should -BeFalse
                }
            }
        }

        Context 'When Thumbprint is not configured properly' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        InstanceName    = 'INSTANCE'
                        Thumbprint      = '987654321'
                        ServiceAccount  = 'SqlSvc'
                        ForceEncryption = $true
                        Ensure          = 'Absent'
                    }
                }
            }

            It 'Should return state as not in desired state' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $resultTestTargetResource = Test-TargetResource @mockTestTargetResourceParameters

                    $resultTestTargetResource | Should -BeFalse
                }
            }
        }

        Context 'When certificate permission is not set' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        InstanceName    = 'INSTANCE'
                        Thumbprint      = '2A11AB1AB1A11111A1111AB111111AB11ABCDEFB'
                        ServiceAccount  = 'SqlSvc'
                        ForceEncryption = $true
                        Ensure          = 'Absent'
                    }
                }

                Mock -CommandName Test-CertificatePermission -MockWith {
                    return $false
                }
            }

            It 'Should return state as not in desired state' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $resultTestTargetResource = Test-TargetResource @mockTestTargetResourceParameters

                    $resultTestTargetResource | Should -BeFalse
                }
            }
        }

        Context 'When Ensure is Absent' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        InstanceName    = 'INSTANCE'
                        Thumbprint      = '2A11AB1AB1A11111A1111AB111111AB11ABCDEFB'
                        ServiceAccount  = 'SqlSvc'
                        ForceEncryption = $true
                        Ensure          = 'Absent'
                    }
                }
            }

            It 'Should return state as not in desired state' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $resultTestTargetResource = Test-TargetResource @mockTestTargetResourceParameters

                    $resultTestTargetResource | Should -BeFalse
                }
            }
        }
    }

    Context 'When the system is in the desired state' {
        BeforeAll {
            Mock -CommandName Get-TargetResource -MockWith {
                return @{
                    InstanceName    = 'INSTANCE'
                    Thumbprint      = '2A11AB1AB1A11111A1111AB111111AB11ABCDEFB'
                    ServiceAccount  = 'SqlSvc'
                    ForceEncryption = $true
                    Ensure          = 'Present'
                }
            }

            Mock -CommandName Test-CertificatePermission -MockWith {
                return $true
            }
        }

        It 'Should return state as in desired state' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $resultTestTargetResource = Test-TargetResource @mockTestTargetResourceParameters

                $resultTestTargetResource | Should -BeTrue
            }
        }
    }
}

Describe 'SqlSecureConnection\Get-EncryptedConnectionSetting' -Tag 'Helper' {
    BeforeAll {
        Mock -CommandName 'Get-ItemProperty' -MockWith {
            return @{
                ForceEncryption = '1'
            }
        } -ParameterFilter {
            $Name -eq 'ForceEncryption'
        }

        Mock -CommandName 'Get-ItemProperty' -MockWith {
            return @{
                Certificate = '12345678'
            }
        } -ParameterFilter {
            $Name -eq 'Certificate'
        }
    }


    Context 'When calling a method that execute successfully' {
        BeforeAll {
            class MockedAccessControl
            {
                [hashtable] $Access = @{
                    IdentityReference = 'Everyone'
                    FileSystemRights  = @{
                        value__ = '131209'
                    }
                }

                [void] AddAccessRule([System.Security.AccessControl.FileSystemAccessRule] $object)
                {
                }
            }

            class MockedGetItem
            {
                [string] $Thumbprint = '1a11ab1ab1a11111a1111ab111111ab11abcdefa'
                [string] $PSPath = 'PathToItem'
                [string] $Path = 'PathToItem'
                [MockedAccessControl] $ACL = [MockedAccessControl]::new()
                [hashtable] $PrivateKey = @{
                    CspKeyContainerInfo = @{
                        UniqueKeyContainerName = 'key'
                    }
                }

                [MockedGetItem] GetAccessControl()
                {
                    return $this
                }
            }

            Mock -CommandName 'Get-SqlEncryptionValue' -MockWith {
                return [MockedGetItem]::new()
            }
        }

        It 'Should return hashtable with ForceEncryption and Certificate' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-EncryptedConnectionSetting -InstanceName 'NamedInstance'

                $result.Certificate | Should -Be '12345678'
                $result.ForceEncryption | Should -Be 1
                $result | Should -BeOfType [Hashtable]
            }
        }
    }

    Context 'When calling a method that executes unsuccesfuly' {
        BeforeAll {
            Mock -CommandName 'Get-SqlEncryptionValue' -MockWith {
                return $null
            }
        }

        It 'Should return null' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-EncryptedConnectionSetting -InstanceName 'NamedInstance'

                $result | Should -BeNullOrEmpty
            }
        }
    }
}

Describe 'SqlSecureConnection\Set-EncryptedConnectionSetting' -Tag 'Helper' {
    Context 'When calling a method that execute successfully' {
        BeforeAll {
            class MockedAccessControl
            {
                [hashtable] $Access = @{
                    IdentityReference = 'Everyone'
                    FileSystemRights  = @{
                        value__ = '131209'
                    }
                }

                [void] AddAccessRule([System.Security.AccessControl.FileSystemAccessRule] $object)
                {
                }
            }

            class MockedGetItem
            {
                [string] $Thumbprint = '1a11ab1ab1a11111a1111ab111111ab11abcdefa'
                [string] $PSPath = 'PathToItem'
                [string] $Path = 'PathToItem'
                [MockedAccessControl] $ACL = [MockedAccessControl]::new()
                [hashtable] $PrivateKey = @{
                    CspKeyContainerInfo = @{
                        UniqueKeyContainerName = 'key'
                    }
                }

                [MockedGetItem] GetAccessControl()
                {
                    return $this
                }
            }

            Mock -CommandName 'Set-ItemProperty'
            Mock -CommandName 'Get-SqlEncryptionValue' -MockWith {
                return [MockedGetItem]::new()
            }
        }

        It 'Should not throw' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Set-EncryptedConnectionSetting -InstanceName 'NamedInstance' -Thumbprint '12345678' -ForceEncryption $true } | Should -Not -Throw
            }
        }
    }

    Context 'When calling a method that executes unsuccesfuly' {
        BeforeAll {
            Mock -CommandName 'Set-ItemProperty'
            Mock -CommandName 'Get-SqlEncryptionValue' -MockWith {
                return $null
            }
        }

        It 'Should throw' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Set-EncryptedConnectionSetting -InstanceName 'NamedInstance' -Thumbprint '12345678' -ForceEncryption $true } | Should -Throw

                Should -Invoke -CommandName 'Set-ItemProperty' -Times 0
            }
        }
    }
}

Describe 'SqlSecureConnection\Test-CertificatePermission' -Tag 'Helper' {
    BeforeAll {
        class MockedAccessControl
        {
            [hashtable] $Access = @{
                IdentityReference = 'Everyone'
                FileSystemRights  = @{
                    value__ = '131209'
                }
            }

            [void] AddAccessRule([System.Security.AccessControl.FileSystemAccessRule] $object)
            {
            }
        }

        class MockedGetItem
        {
            [string] $Thumbprint = '1a11ab1ab1a11111a1111ab111111ab11abcdefa'
            [string] $PSPath = 'PathToItem'
            [string] $Path = 'PathToItem'
            [MockedAccessControl] $ACL = [MockedAccessControl]::new()
            [hashtable] $PrivateKey = @{
                CspKeyContainerInfo = @{
                    UniqueKeyContainerName = 'key'
                }
            }

            [MockedGetItem] GetAccessControl()
            {
                return $this
            }
        }
    }

    Context 'When calling a method that execute successfully' {
        BeforeAll {
            Mock -CommandName 'Get-CertificateAcl' -MockWith {
                return [MockedGetItem]::new()
            }
        }

        It 'Should return True' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Test-CertificatePermission -Thumbprint '12345678' -ServiceAccount 'Everyone'

                $result | Should -BeTrue
            }
        }
    }

    Context 'When no permissions were found' {
        BeforeAll {
            Mock -CommandName 'Get-CertificateAcl' -MockWith {
                $mockedItem = [MockedGetItem]::new()
                $mockedItem.ACL = $null
                return $mockedItem
            }
        }

        It 'Should return False' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Test-CertificatePermission -Thumbprint '12345678' -ServiceAccount 'Everyone'

                $result | Should -BeFalse
            }
        }
    }

    Context 'When the wrong permissions are added' {
        BeforeAll {
            Mock -CommandName 'Get-CertificateAcl' -MockWith {
                $mockedItem = [MockedGetItem]::new()
                $mockedItem.ACL.Access.FileSystemRights.Value__ = 1
                return $mockedItem
            }
        }

        It 'Should return False' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Test-CertificatePermission -Thumbprint '12345678' -ServiceAccount 'Everyone'

                $result | Should -BeFalse
            }
        }
    }

    Context 'When not permissions are returned' {
        BeforeAll {
            Mock -CommandName 'Get-CertificateAcl' -MockWith {
                return $null
            }
        }

        It 'Should return False' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Test-CertificatePermission -Thumbprint '12345678' -ServiceAccount 'Everyone'

                $result | Should -BeFalse
            }
        }
    }
}

Describe 'SqlSecureConnection\Set-CertificatePermission' -Tag 'Helper' {
    Context 'When calling a method that execute successfully' {
        BeforeAll {
            class MockedAccessControl
            {
                [hashtable] $Access = @{
                    IdentityReference = 'Everyone'
                    FileSystemRights  = @{
                        value__ = '131209'
                    }
                }

                [void] AddAccessRule([System.Security.AccessControl.FileSystemAccessRule] $object)
                {
                }
            }

            class MockedGetItem
            {
                [string] $Thumbprint = '1a11ab1ab1a11111a1111ab111111ab11abcdefa'
                [string] $PSPath = 'PathToItem'
                [string] $Path = 'PathToItem'
                [MockedAccessControl] $ACL = [MockedAccessControl]::new()
                [hashtable] $PrivateKey = @{
                    CspKeyContainerInfo = @{
                        UniqueKeyContainerName = 'key'
                    }
                }

                [MockedGetItem] GetAccessControl()
                {
                    return $this
                }
            }

            Mock -CommandName 'Set-Acl'
            Mock -CommandName 'Get-CertificateAcl' -MockWith {
                return [MockedGetItem]::new()
            }
        }

        It 'Should not throw' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Set-CertificatePermission -Thumbprint '12345678' -ServiceAccount 'Everyone' } | Should -Not -Throw
            }
        }
    }

    Context 'When calling a method that executes unsuccessfully' {
        BeforeAll {
            Mock -CommandName 'Get-Item' -MockWith {
                return $null
            }

            Mock -CommandName 'Get-ChildItem' -MockWith {
                return $null
            }
        }

        It 'Should throw' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Set-CertificatePermission -Thumbprint '12345678' -ServiceAccount 'Everyone' } | Should -Throw
            }
        }
    }
}

Describe 'SqlSecureConnection\Get-CertificateAcl' -Tag 'Helper' {
    Context 'When calling a method that execute successfully' {
        BeforeAll {
            class MockedAccessControl
            {
                [hashtable] $Access = @{
                    IdentityReference = 'Everyone'
                    FileSystemRights  = @{
                        value__ = '131209'
                    }
                }

                [void] AddAccessRule([System.Security.AccessControl.FileSystemAccessRule] $object)
                {
                }
            }

            class MockedGetItem
            {
                [string] $Thumbprint = '1a11ab1ab1a11111a1111ab111111ab11abcdefa'
                [string] $PSPath = 'PathToItem'
                [string] $Path = 'PathToItem'
                [MockedAccessControl] $ACL = [MockedAccessControl]::new()
                [hashtable] $PrivateKey = @{
                    CspKeyContainerInfo = @{
                        UniqueKeyContainerName = 'key'
                    }
                }

                [MockedGetItem] GetAccessControl()
                {
                    return $this
                }
            }

            Mock -CommandName 'Get-ChildItem' -MockWith {
                return [MockedGetItem]::new()
            }

            Mock -CommandName 'Get-Item' -MockWith {
                return [MockedGetItem]::new()
            }
        }

        It 'Should not throw' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Get-CertificateAcl -Thumbprint '12345678' } | Should -Not -Throw
            }
        }
    }
}

Describe 'SqlSecureConnection\Get-SqlEncryptionValue' -Tag 'Helper' {
    BeforeAll {
        class MockedAccessControl
        {
            [hashtable] $Access = @{
                IdentityReference = 'Everyone'
                FileSystemRights  = @{
                    value__ = '131209'
                }
            }

            [void] AddAccessRule([System.Security.AccessControl.FileSystemAccessRule] $object)
            {
            }
        }

        class MockedGetItem
        {
            [string] $Thumbprint = '1a11ab1ab1a11111a1111ab111111ab11abcdefa'
            [string] $PSPath = 'PathToItem'
            [string] $Path = 'PathToItem'
            [MockedAccessControl] $ACL = [MockedAccessControl]::new()
            [hashtable] $PrivateKey = @{
                CspKeyContainerInfo = @{
                    UniqueKeyContainerName = 'key'
                }
            }

            [MockedGetItem] GetAccessControl()
            {
                return $this
            }
        }
    }

    Context 'When calling a method that execute successfully' {
        BeforeAll {
            Mock -CommandName 'Get-ItemProperty' -MockWith {
                return [MockedGetItem]::new()
            }

            Mock -CommandName 'Get-Item' -MockWith {
                return [MockedGetItem]::new()
            }
        }

        It 'Should not throw' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Get-SqlEncryptionValue -InstanceName 'INSTANCE' } | Should -Not -Throw
            }
        }
    }

    Context 'When calling a method that execute unsuccessfully' {
        BeforeAll {
            Mock -CommandName 'Get-ItemProperty' -MockWith {
                throw 'Error'
            }

            Mock -CommandName 'Get-Item' -MockWith {
                return [MockedGetItem]::new()
            }
        }

        It 'Should throw with expected message' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Get-SqlEncryptionValue -InstanceName 'INSTANCE' } | Should -Throw -ExpectedMessage 'SQL instance ''INSTANCE'' not found on SQL Server.'
            }
        }
    }
}
