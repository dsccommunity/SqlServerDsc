$script:DSCModuleName = 'SqlServerDsc'
$script:DSCResourceName = 'MSFT_SqlServerSecureConnection'

#region HEADER

# Unit Test Template Version: 1.2.0
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName   `
    -DSCResourceName $script:DSCResourceName  `
    -TestType Unit

#endregion HEADER

function Invoke-TestSetup
{
    Import-Module -Name (Join-Path -Path (Join-Path -Path (Join-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'Tests') -ChildPath 'Unit') -ChildPath 'Stubs') -ChildPath 'SQLPSStub.psm1') -Global -Force
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

# Begin Testing
try
{
    Invoke-TestSetup

    InModuleScope $script:DSCResourceName {
        class MockedAccessControl
        {
            [hashtable]$Access = @{
                IdentityReference = "Everyone"
                FileSystemRights = @{
                    value__ = '131209'
                }
            }

            [void] AddAccessRule([System.Security.AccessControl.FileSystemAccessRule] $object)
            {

            }
        }

        class MockedGetItem
        {
            [string] $Thumbprint = '12345678'
            [string] $PSPath = 'PathToItem'
            [string] $Path = 'PathToItem'
            [MockedAccessControl]$ACL = [MockedAccessControl]::new()
            [hashtable]$PrivateKey = @{
                CspKeyContainerInfo = @{
                    UniqueKeyContainerName = "key"
                }
            }

            [MockedGetItem] GetAccessControl()
            {
                return $this
            }
        }

        $mockNamedInstanceName   = 'INSTANCE'
        $mockDefaultInstanceName = 'MSSQLSERVER'
        $mockThumbprint          = '123456789'
        $mockServiceAccount      = 'SqlSvc'

        Describe "SqlServerSecureConnection\Get-TargetResource" -Tag 'Get' {
            BeforeAll {
                $mockDynamic_SqlBuildVersion = '13.0.4001.0'

                $defaultParameters  = @{
                    InstanceName    = $mockNamedInstanceName
                    Thumbprint      = $mockThumbprint
                    ServiceAccount  = $mockServiceAccount
                    ForceEncryption = $true
                    Ensure          = 'Present'
                }
            }

            Context 'When the system is in the desired state' {
                Mock -CommandName Get-EncryptedConnectionSettings -MockWith {return @{ForceEncryption = $true; Certificate = $mockThumbprint}} -Verifiable
                Mock -CommandName Test-CertificatePermission -MockWith { return $true }

                It 'Should return the the state as initialized' {
                    $resultGetTargetResource = Get-TargetResource @defaultParameters
                    $resultGetTargetResource.InstanceName | Should -Be $mockNamedInstanceName
                    $resultGetTargetResource.Thumbprint | Should -Be $mockThumbprint
                    $resultGetTargetResource.ServiceAccount | Should -Be $mockServiceAccount
                    $resultGetTargetResource.ForceEncryption | Should -Be $true
                    $resultGetTargetResource.Ensure | Should -Be 'Present'

                    Assert-MockCalled -CommandName Get-EncryptedConnectionSettings -Exactly -Times 1 -Scope It
                }

            }

            Context 'When the system is not in the desired state' {
                Mock -CommandName Get-EncryptedConnectionSettings -MockWith {return @{ForceEncryption = $true; Certificate = '987654321'}} -Verifiable
                Mock -CommandName Test-CertificatePermission -MockWith { return $false }

                It 'Should return the state as not initialized' {
                    $resultGetTargetResource = Get-TargetResource @defaultParameters
                    $resultGetTargetResource.InstanceName | Should -Be $mockNamedInstanceName
                    $resultGetTargetResource.Thumbprint | Should -Not -Be $mockThumbprint
                    $resultGetTargetResource.ServiceAccount | Should -Be $mockServiceAccount
                    $resultGetTargetResource.ForceEncryption | Should -Be $true
                    $resultGetTargetResource.Ensure | Should -Be 'Absent'

                    Assert-MockCalled -CommandName Get-EncryptedConnectionSettings -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the system is not in the desired state' {
                Mock -CommandName Get-EncryptedConnectionSettings -MockWith {return @{ForceEncryption = $true; Certificate = '987654321'}} -Verifiable
                Mock -CommandName Test-CertificatePermission -MockWith { return $true }

                It 'Should return the state as not initialized when certificate permissions match but encryption settings dont' {
                    $resultGetTargetResource = Get-TargetResource @defaultParameters
                    $resultGetTargetResource.InstanceName | Should -Be $mockNamedInstanceName
                    $resultGetTargetResource.Thumbprint | Should -Not -Be $mockThumbprint
                    $resultGetTargetResource.ServiceAccount | Should -Be $mockServiceAccount
                    $resultGetTargetResource.ForceEncryption | Should -Be $true
                    $resultGetTargetResource.Ensure | Should -Be 'Absent'

                    Assert-MockCalled -CommandName Get-EncryptedConnectionSettings -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the system is not in the desired state' {
                Mock -CommandName Get-EncryptedConnectionSettings -MockWith {return @{ForceEncryption = $true; Certificate = $mockThumbprint}} -Verifiable
                Mock -CommandName Test-CertificatePermission -MockWith { return $false }

                It 'Should return the state as not initialized when certificate permissions dont match but encryption settings do' {
                    $resultGetTargetResource = Get-TargetResource @defaultParameters
                    $resultGetTargetResource.InstanceName | Should -Be $mockNamedInstanceName
                    $resultGetTargetResource.Thumbprint | Should -Be $mockThumbprint
                    $resultGetTargetResource.ServiceAccount | Should -Be $mockServiceAccount
                    $resultGetTargetResource.ForceEncryption | Should -Be $true
                    $resultGetTargetResource.Ensure | Should -Be 'Absent'

                    Assert-MockCalled -CommandName Get-EncryptedConnectionSettings -Exactly -Times 1 -Scope It
                }
            }
        }

        Describe "SqlServerSecureConnection\Set-TargetResource" -Tag 'Set' {
            BeforeAll {
                $defaultParameters = @{
                    InstanceName    = $mockNamedInstanceName
                    Thumbprint      = $mockThumbprint
                    ServiceAccount  = $mockServiceAccount
                    ForceEncryption = $true
                    Ensure          = 'Present'
                }

                $defaultAbsentParameters = @{
                    InstanceName    = $mockNamedInstanceName
                    Thumbprint      = $mockThumbprint
                    ServiceAccount  = $mockServiceAccount
                    ForceEncryption = $true
                    Ensure          = 'Absent'
                }

                Mock -CommandName Set-EncryptedConnectionSettings -Verifiable
                Mock -CommandName Set-CertificatePermission -Verifiable
                Mock -CommandName Restart-SqlService -Verifiable
            }

            Context 'When the system is not in the desired state' {

                Context 'When only certificate permissions arent set' {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            InstanceName    = $mockNamedInstanceName
                            Thumbprint      = '987654321'
                            ServiceAccount  = $mockServiceAccount
                            ForceEncryption = $false
                            Ensure          = 'Present'
                        }
                    }
                    Mock -CommandName Test-CertificatePermission -MockWith { return $true}

                    It 'Should configure only ForceEncryption and Certificate values' {
                        { Set-TargetResource @defaultParameters } | Should -Not -Throw

                        Assert-MockCalled -CommandName Set-EncryptedConnectionSettings -Exactly -Times 1 -Scope It

                        Assert-MockCalled -CommandName Set-CertificatePermission -Exactly -Times 0 -Scope It

                        Assert-MockCalled -CommandName Restart-SqlService -Exactly -Times 1 -Scope It
                    }
                }

                Context 'When there is no certificate permissions set' {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            InstanceName    = $mockNamedInstanceName
                            Thumbprint      = $mockThumbprint
                            ServiceAccount  = $mockServiceAccount
                            ForceEncryption = $true
                            Ensure          = 'Present'
                        }
                    }
                    Mock -CommandName Test-CertificatePermission -MockWith { return $false}
                    It 'Should configure only certificate permissions' {
                        { Set-TargetResource @defaultParameters } | Should -Not -Throw

                        Assert-MockCalled -CommandName Set-EncryptedConnectionSettings -Exactly -Times 0 -Scope It

                        Assert-MockCalled -CommandName Set-CertificatePermission -Exactly -Times 1 -Scope It

                        Assert-MockCalled -CommandName Restart-SqlService -Exactly -Times 1 -Scope It
                    }
                }

                Context 'When no settings are configured' {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            InstanceName    = $mockNamedInstanceName
                            Thumbprint      = '987654321'
                            ServiceAccount  = $mockServiceAccount
                            ForceEncryption = $false
                            Ensure          = 'Present'
                        }
                    }
                    Mock -CommandName Test-CertificatePermission -MockWith { return $false}

                    It 'Should configure Encryption settings and certificate permissions' {
                        { Set-TargetResource @defaultParameters } | Should -Not -Throw

                        Assert-MockCalled -CommandName Set-EncryptedConnectionSettings -Exactly -Times 1 -Scope It

                        Assert-MockCalled -CommandName Set-CertificatePermission -Exactly -Times 1 -Scope It

                        Assert-MockCalled -CommandName Restart-SqlService -Exactly -Times 1 -Scope It
                    }
                }

                Context 'When ensure is absent' {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            InstanceName    = $mockNamedInstanceName
                            Thumbprint      = $mockThumbprint
                            ServiceAccount  = $mockServiceAccount
                            ForceEncryption = $true
                            Ensure          = 'Absent'
                        }
                    }
                    Mock -CommandName Test-CertificatePermission -MockWith { return $false}

                    It 'Should configure Encryption settings setting certificate to empty string' {
                        { Set-TargetResource @defaultAbsentParameters } | Should -Not -Throw

                        Assert-MockCalled -CommandName Set-EncryptedConnectionSettings -Exactly -Times 1 -Scope It

                        Assert-MockCalled -CommandName Set-CertificatePermission -Exactly -Times 0 -Scope It

                        Assert-MockCalled -CommandName Restart-SqlService -Exactly -Times 1 -Scope It
                    }
                }
            }
        }

        Describe "SqlServerSecureConnection\Test-TargetResource" -Tag 'Test' {
            Context 'When the system is not in the desired state' {
                Context 'When ForceEncryption is not configured properly' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                InstanceName    = $mockNamedInstanceName
                                Thumbprint      = $mockThumbprint
                                ServiceAccount  = $mockServiceAccount
                                ForceEncryption = $false
                                Ensure          = 'Absent'
                            }
                        } -Verifiable

                        $testParameters = @{
                            InstanceName    = $mockNamedInstanceName
                            Thumbprint      = $mockThumbprint
                            ServiceAccount  = $mockServiceAccount
                            ForceEncryption = $true
                            Ensure          = 'Present'
                        }
                    }

                    It 'Should return state as not in desired state' {
                        $resultTestTargetResource = Test-TargetResource @testParameters
                        $resultTestTargetResource | Should -Be $false
                    }
                }

                Context 'When Thumbprint is not configured properly' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                InstanceName    = $mockNamedInstanceName
                                Thumbprint      = '987654321'
                                ServiceAccount  = $mockServiceAccount
                                ForceEncryption = $true
                                Ensure          = 'Absent'
                            }
                        } -Verifiable

                        $testParameters = @{
                            InstanceName    = $mockNamedInstanceName
                            Thumbprint      = $mockThumbprint
                            ServiceAccount  = $mockServiceAccount
                            ForceEncryption = $true
                            Ensure          = 'Present'
                        }
                    }

                    It 'Should return state as not in desired state' {
                        $resultTestTargetResource = Test-TargetResource @testParameters
                        $resultTestTargetResource | Should -Be $false
                    }
                }

                Context 'When certificate permission is not set' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                InstanceName    = $mockNamedInstanceName
                                Thumbprint      = $mockThumbprint
                                ServiceAccount  = $mockServiceAccount
                                ForceEncryption = $true
                                Ensure          = 'Absent'
                            }
                        } -Verifiable

                        Mock -CommandName Test-CertificatePermission -MockWith { return $false }

                        $testParameters = @{
                            InstanceName    = $mockNamedInstanceName
                            Thumbprint      = $mockThumbprint
                            ServiceAccount  = $mockServiceAccount
                            ForceEncryption = $true
                            Ensure          = 'Present'
                        }
                    }

                    It 'Should return state as not in desired state' {
                        $resultTestTargetResource = Test-TargetResource @testParameters
                        $resultTestTargetResource | Should -Be $false
                    }
                }

                Context 'When Ensure is Absent' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                InstanceName    = $mockNamedInstanceName
                                Thumbprint      = $mockThumbprint
                                ServiceAccount  = $mockServiceAccount
                                ForceEncryption = $true
                                Ensure          = 'Absent'
                            }
                        } -Verifiable

                        $testParameters = @{
                            InstanceName    = $mockNamedInstanceName
                            Thumbprint      = $mockThumbprint
                            ServiceAccount  = $mockServiceAccount
                            ForceEncryption = $true
                            Ensure          = 'Present'
                        }
                    }

                    It 'Should return state as not in desired state' {
                        $resultTestTargetResource = Test-TargetResource @testParameters
                        $resultTestTargetResource | Should -Be $false
                    }
                }
            }

            Context 'When the system is in the desired state' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            InstanceName    = $mockNamedInstanceName
                            Thumbprint      = $mockThumbprint
                            ServiceAccount  = $mockServiceAccount
                            ForceEncryption = $true
                            Ensure          = 'Present'
                        }
                    } -Verifiable

                    Mock -CommandName Test-CertificatePermission -MockWith { return $true }

                    $testParameters = @{
                        InstanceName    = $mockNamedInstanceName
                        Thumbprint      = $mockThumbprint
                        ServiceAccount  = $mockServiceAccount
                        ForceEncryption = $true
                        Ensure          = 'Present'
                    }
                }

                It 'Should return state as in desired state' {
                    $resultTestTargetResource = Test-TargetResource @testParameters
                    $resultTestTargetResource | Should -Be $true
                }
            }
        }

        Describe "SqlServerSecureConnection\Get-EncryptedConnectionSettings" -Tag 'Helper' {

            Mock -CommandName 'Get-ItemProperty' -MockWith { return @{ForceEncryption = '1'} } -ParameterFilter { $Name -eq 'ForceEncryption' }
            Mock -CommandName 'Get-ItemProperty' -MockWith { return @{Certificate ='12345678'} } -ParameterFilter { $Name -eq 'Certificate' }

            Context 'When calling a method that execute successfully' {
                BeforeAll {
                    Mock -CommandName "Get-SqlEncryptionValues" -MockWith {
                        return [MockedGetItem]::new()
                    }
                }

                It 'Should return hashtable with ForceEncryption and Certificate' {
                   $result = Get-EncryptedConnectionSettings -InstanceName 'NamedInstance'
                   $result.Certificate | Should -Be '12345678'
                   $result.ForceEncryption | Should -Be 1
                }
            }

            Context 'When calling a method that executes unsuccesfuly' {
                BeforeAll {
                    Mock -CommandName "Get-SqlEncryptionValues" -MockWith {
                        return $null
                    }
                }

                It 'Should return null' {
                   $result = Get-EncryptedConnectionSettings -InstanceName 'NamedInstance'
                   $result | Should -BeNullOrEmpty
                }
            }
        }

        Describe "SqlServerSecureConnection\Set-EncryptedConnectionSettings" -Tag 'Helper' {
            Context 'When calling a method that execute successfully' {
                BeforeAll {
                    Mock -CommandName "Get-SqlEncryptionValues" -MockWith {
                        return [MockedGetItem]::new()
                    }
                    Mock -CommandName 'Set-ItemProperty' -MockWith {}
                }

                It 'Should not throw' {
                   { Set-EncryptedConnectionSettings -InstanceName 'NamedInstance' -Thumbprint '12345678' -ForceEncryption $true } | Should -Not -Throw
                }
            }

            Context 'When calling a method that executes unsuccesfuly' {
                BeforeAll {
                    Mock -CommandName "Get-SqlEncryptionValues" -MockWith {
                        return $null
                    }
                    Mock -CommandName 'Set-ItemProperty' -MockWith {}
                }

                It 'Should not throw' {
                   { Set-EncryptedConnectionSettings -InstanceName 'NamedInstance' -Thumbprint '12345678' -ForceEncryption $true } | Should -Not -Throw
                }
            }
        }

        Describe "SqlServerSecureConnection\Test-CertificatePermission" -Tag 'Helper' {
            Context 'When calling a method that execute successfully' {
                BeforeAll {
                        Mock -CommandName "Get-CertificateAcl" -MockWith {
                            return [MockedGetItem]::new()
                        }
                }

                It 'Should return True' {
                    $result = Test-CertificatePermission -Thumbprint '12345678' -ServiceAccount 'Everyone'
                    $result | Should -be $true
                }
            }

            Context 'When calling a method that executes unsuccesfuly' {
                BeforeAll {
                        Mock -CommandName "Get-CertificateAcl" -MockWith {
                            return $null
                        }
                }

                It 'Should return False' {
                   $result = Test-CertificatePermission -Thumbprint '12345678' -ServiceAccount 'Everyone'
                    $result | Should -be $false
                }
            }
        }

        Describe "SqlServerSecureConnection\Set-CertificatePermission" -Tag 'Helper' {
            Context 'When calling a method that execute successfully' {
                BeforeAll {
                    Mock -CommandName "Get-CertificateAcl" -MockWith {
                        return [MockedGetItem]::new()
                    }

                    Mock -CommandName "Set-Acl" -MockWith {}
                }

                It 'Should not throw' {
                    { Set-CertificatePermission -Thumbprint '12345678' -ServiceAccount 'Everyone' } | Should -Not -Throw
                }
            }

            Context 'When calling a method that executes unsuccesfuly' {
                BeforeAll {
                    Mock -CommandName "Get-Item" -MockWith {
                        return $null
                    }
                    Mock -CommandName "Get-ChildItem" -MockWith {
                        return $null
                    }
                }

                It 'Should throw' {
                   { Set-CertificatePermission -Thumbprint '12345678' -ServiceAccount 'Everyone' } | Should -Throw
                }
            }
        }

        Describe "SqlServerSecureConnection\Get-CertificateAcl" -Tag 'Helper' {
            Context 'When calling a method that execute successfully' {
                BeforeAll {
                    Mock -CommandName "Get-ChildItem" -MockWith {
                        return [MockedGetItem]::new()
                    }

                    Mock -CommandName "Get-Item" -MockWith {
                        return [MockedGetItem]::new()
                    }
                }

                It 'Should not throw' {
                    { Get-CertificateAcl -Thumbprint '12345678' } | Should -Not -Throw
                }
            }
        }

        Describe "SqlServerSecureConnection\Get-SqlEncryptionValues" -Tag 'Helper' {
            Context 'When calling a method that execute successfully' {
                BeforeAll {
                    Mock -CommandName "Get-ItemProperty" -MockWith {
                        return [MockedGetItem]::new()
                    }

                    Mock -CommandName "Get-Item" -MockWith {
                        return [MockedGetItem]::new()
                    }
                }

                It 'Should not throw' {
                    { Get-SqlEncryptionValues -InstanceName $mockNamedInstanceName } | Should -Not -Throw
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
