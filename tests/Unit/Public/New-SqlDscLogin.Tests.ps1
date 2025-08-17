[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Parameter is used in test mocks.')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies have been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies have not been resolved, this will throw an error.
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

    $env:SqlServerDscCI = $true

    Import-Module -Name $script:dscModuleName -Force

    # Loading mocked classes
    Add-Type -Path (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '../Stubs') -ChildPath 'SMO.cs')

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscModuleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force

    Remove-Item -Path 'env:SqlServerDscCI'
}

Describe 'New-SqlDscLogin' -Tag 'Public' {
    Context 'When using parameter Confirm with value $false' {
        BeforeAll {
            Mock -CommandName Test-SqlDscIsLogin -MockWith {
                return $false
            }

            $script:mockServerObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server
            $script:mockServerObject.InstanceName = 'TestInstance'
        }

        Context 'When creating a SQL Server login' {
            BeforeAll {
                $script:mockSecurePassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force
            }

            It 'Should create a SQL Server login without throwing' {
                { New-SqlDscLogin -ServerObject $script:mockServerObject -Name 'TestLogin' -SqlLogin -SecurePassword $script:mockSecurePassword -Confirm:$false } | Should -Not -Throw

                Should -Invoke -CommandName Test-SqlDscIsLogin -Exactly -Times 1 -Scope It
            }

            It 'Should call Create method on login object' {
                New-SqlDscLogin -ServerObject $script:mockServerObject -Name 'TestLogin' -SqlLogin -SecurePassword $script:mockSecurePassword -Confirm:$false
            }
        }

        Context 'When creating a Windows user login' {
            It 'Should create a Windows user login without throwing' {
                { New-SqlDscLogin -ServerObject $script:mockServerObject -Name 'DOMAIN\TestUser' -WindowsUser -Confirm:$false } | Should -Not -Throw

                Should -Invoke -CommandName Test-SqlDscIsLogin -Exactly -Times 1 -Scope It
            }
        }

        Context 'When login already exists' {
            BeforeAll {
                Mock -CommandName Test-SqlDscIsLogin -MockWith {
                    return $true
                }

                $script:mockSecurePassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force
            }

            It 'Should throw an error when login already exists' {
                { New-SqlDscLogin -ServerObject $script:mockServerObject -Name 'ExistingLogin' -SqlLogin -SecurePassword $script:mockSecurePassword -Confirm:$false } | Should -Throw -ExpectedMessage '*already exists*'

                Should -Invoke -CommandName Test-SqlDscIsLogin -Exactly -Times 1 -Scope It
            }
        }

        Context 'When using PassThru parameter' {
            BeforeAll {
                $script:mockSecurePassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force
            }

            It 'Should return the login object when PassThru is specified' {
                $result = New-SqlDscLogin -ServerObject $script:mockServerObject -Name 'TestLogin' -SqlLogin -SecurePassword $script:mockSecurePassword -PassThru -Confirm:$false

                $result | Should -Not -BeNullOrEmpty
            }
        }

        Context 'When creating certificate-based login' {
            It 'Should create a certificate login without throwing' {
                { New-SqlDscLogin -ServerObject $script:mockServerObject -Name 'CertLogin' -Certificate -CertificateName 'MyCert' -Confirm:$false } | Should -Not -Throw
            }
        }

        Context 'When creating asymmetric key-based login' {
            It 'Should create an asymmetric key login without throwing' {
                { New-SqlDscLogin -ServerObject $script:mockServerObject -Name 'KeyLogin' -AsymmetricKey -AsymmetricKeyName 'MyKey' -Confirm:$false } | Should -Not -Throw
            }
        }

        Context 'When creating Windows group login' {
            It 'Should create a Windows group login without throwing' {
                { New-SqlDscLogin -ServerObject $script:mockServerObject -Name 'NT AUTHORITY\SYSTEM' -WindowsGroup -Confirm:$false } | Should -Not -Throw

                Should -Invoke -CommandName Test-SqlDscIsLogin -Exactly -Times 1 -Scope It
            }
        }

        Context 'When using Force parameter without Confirm' {
            BeforeAll {
                $script:mockSecurePassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force
            }

            It 'Should set ConfirmPreference to None when Force is used' {
                { New-SqlDscLogin -ServerObject $script:mockServerObject -Name 'ForceLogin' -SqlLogin -SecurePassword $script:mockSecurePassword -Force } | Should -Not -Throw

                Should -Invoke -CommandName Test-SqlDscIsLogin -Exactly -Times 1 -Scope It
            }
        }

        Context 'When using custom DefaultLanguage parameter' {
            BeforeAll {
                $script:mockSecurePassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force
            }

            It 'Should set custom language on login object' {
                { New-SqlDscLogin -ServerObject $script:mockServerObject -Name 'LangLogin' -SqlLogin -SecurePassword $script:mockSecurePassword -DefaultLanguage 'Swedish' -Confirm:$false } | Should -Not -Throw

                Should -Invoke -CommandName Test-SqlDscIsLogin -Exactly -Times 1 -Scope It
            }
        }

        Context 'When using MustChangePassword parameter' {
            BeforeAll {
                $script:mockSecurePassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force
            }

            It 'Should set MustChange login create option' {
                { New-SqlDscLogin -ServerObject $script:mockServerObject -Name 'MustChangeLogin' -SqlLogin -SecurePassword $script:mockSecurePassword -MustChangePassword -Confirm:$false } | Should -Not -Throw

                Should -Invoke -CommandName Test-SqlDscIsLogin -Exactly -Times 1 -Scope It
            }
        }

        Context 'When using IsHashed parameter' {
            BeforeAll {
                $script:mockSecurePassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force
            }

            It 'Should set IsHashed login create option' {
                { New-SqlDscLogin -ServerObject $script:mockServerObject -Name 'HashedLogin' -SqlLogin -SecurePassword $script:mockSecurePassword -IsHashed -Confirm:$false } | Should -Not -Throw

                Should -Invoke -CommandName Test-SqlDscIsLogin -Exactly -Times 1 -Scope It
            }
        }

        Context 'When using Disabled parameter' {
            BeforeAll {
                $script:mockSecurePassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force
            }

            It 'Should call Disable method on login object' {
                { New-SqlDscLogin -ServerObject $script:mockServerObject -Name 'DisabledLogin' -SqlLogin -SecurePassword $script:mockSecurePassword -Disabled -Confirm:$false } | Should -Not -Throw

                Should -Invoke -CommandName Test-SqlDscIsLogin -Exactly -Times 1 -Scope It
            }
        }

        Context 'When combining multiple SQL login options' {
            BeforeAll {
                $script:mockSecurePassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force
            }

            It 'Should handle multiple options together' {
                { New-SqlDscLogin -ServerObject $script:mockServerObject -Name 'ComplexLogin' -SqlLogin -SecurePassword $script:mockSecurePassword -MustChangePassword -IsHashed -Disabled -DefaultLanguage 'English' -DefaultDatabase 'tempdb' -PasswordExpirationEnabled -PasswordPolicyEnforced -Confirm:$false } | Should -Not -Throw

                Should -Invoke -CommandName Test-SqlDscIsLogin -Exactly -Times 1 -Scope It
            }
        }

        Context 'When creating a SQL Server login with specific password options' {
            BeforeAll {
                Mock -CommandName Test-SqlDscIsLogin -MockWith {
                    return $false
                }

                $mockServerObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server
                $mockServerObject.InstanceName = 'TestInstance'
                $mockSecurePassword = ConvertTo-SecureString -String 'MyStr0ngP@ssw0rd' -AsPlainText -Force

                $mockTestSqlDscIsLoginParameterFilter = {
                    $ServerObject -eq $mockServerObject -and $Name -eq 'NewLogin'
                }
            }

            It 'Should create login with MustChangePassword option' {
                { New-SqlDscLogin -ServerObject $mockServerObject -Name 'NewLogin' -SqlLogin -SecurePassword $mockSecurePassword -MustChangePassword } | Should -Not -Throw

                Should -Invoke -CommandName Test-SqlDscIsLogin -ParameterFilter $mockTestSqlDscIsLoginParameterFilter -Exactly -Times 1 -Scope It
            }

            It 'Should create login with IsHashed option' {
                { New-SqlDscLogin -ServerObject $mockServerObject -Name 'NewLogin' -SqlLogin -SecurePassword $mockSecurePassword -IsHashed } | Should -Not -Throw

                Should -Invoke -CommandName Test-SqlDscIsLogin -ParameterFilter $mockTestSqlDscIsLoginParameterFilter -Exactly -Times 1 -Scope It
            }

            It 'Should create disabled login' {
                { New-SqlDscLogin -ServerObject $mockServerObject -Name 'NewLogin' -SqlLogin -SecurePassword $mockSecurePassword -Disabled } | Should -Not -Throw

                Should -Invoke -CommandName Test-SqlDscIsLogin -ParameterFilter $mockTestSqlDscIsLoginParameterFilter -Exactly -Times 1 -Scope It
            }
        }
    }
}
