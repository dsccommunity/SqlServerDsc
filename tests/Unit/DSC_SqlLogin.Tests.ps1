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
        Import-Module -Name DscResource.Test -Force -ErrorAction 'Stop'
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
    }
}

BeforeAll {
    $script:dscModuleName = 'SqlServerDsc'
    $script:dscResourceName = 'DSC_SqlLogin'

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

Describe 'SqlLogin\Get-TargetResource' -Tag 'Get' {
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
        Context 'When the login should be present' {
            Context 'When login is of type <MockLoginType>' -ForEach @(
                @{
                    MockLoginType = 'WindowsUser'
                    MockLoginName = 'Windows\User1'
                }
                @{
                    MockLoginType = 'SqlLogin'
                    MockLoginName = 'SqlLogin1'
                }
                @{
                    MockLoginType = 'WindowsGroup'
                    MockLoginName = 'Windows\Group1'
                }
            ) {
                BeforeEach {
                    $mockConnectSQL = {
                        return New-Object -TypeName Object |
                            Add-Member -MemberType ScriptProperty -Name 'Logins' -Value {
                                $mockLoginObject = New-Object -TypeName Object |
                                    Add-Member -MemberType NoteProperty -Name 'Name' -Value $MockLoginName -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'LoginType' -Value $MockLoginType -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'DefaultDatabase' -Value 'master' -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'IsDisabled' -Value $true -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'MustChangePassword' -Value $true -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'PasswordExpirationEnabled' -Value $true -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'PasswordPolicyEnforced' -Value $true -PassThru -Force

                                return @{
                                    $MockLoginName = $mockLoginObject
                                }
                            } -PassThru -Force
                    }

                    Mock -CommandName Connect-SQL -MockWith $mockConnectSQL
                }

                It 'Should return the correct value for each property' {
                    InModuleScope -Parameters $_ -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $mockGetTargetResourceParameters.Name = $MockLoginName

                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.Ensure | Should -Be 'Present'
                        $result.ServerName | Should -Be $mockGetTargetResourceParameters.ServerName
                        $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                        $result.Name | Should -Be $mockGetTargetResourceParameters.Name
                        $result.LoginType | Should -Be $MockLoginType
                        $result.Disabled | Should -BeTrue
                        $result.DefaultDatabase | Should -Be 'master'

                        if ($MockLoginType -eq 'SqlLogin')
                        {
                            $result.LoginMustChangePassword | Should -BeTrue
                            $result.LoginPasswordExpirationEnabled | Should -BeTrue
                            $result.LoginPasswordPolicyEnforced | Should -BeTrue
                        }
                        else
                        {
                            <#
                                This is a bug in the code, these should always be returned
                                in the hashtable. This is put here so the tests wil be fixed
                                when the code is fixed.
                            #>
                            $result | Should -Not -Contain 'LoginMustChangePassword'
                            $result | Should -Not -Contain 'LoginPasswordExpirationEnabled'
                            $result | Should -Not -Contain 'LoginPasswordPolicyEnforced'
                        }
                    }
                }
            }
        }

        Context 'When the login should be absent' {
            Context 'When login is of type <MockLoginType>' -ForEach @(
                @{
                    MockLoginType = 'WindowsUser'
                    MockLoginName = 'Windows\MissingUser'
                }
                @{
                    MockLoginType = 'SqlLogin'
                    MockLoginName = 'MissingSqlLogin'
                }
                @{
                    MockLoginType = 'WindowsGroup'
                    MockLoginName = 'Windows\MissingGroup'
                }
            ) {
                BeforeAll {
                    $mockConnectSQL = {
                        <#
                            Mock at least one login exist, the tests should not return
                            this. If just an empty array was mocked we wouldn't know
                            if the evaluation works that looks up the correct (in this
                            case, the missing) login name.
                        #>
                        return New-Object -TypeName Object |
                            Add-Member -MemberType ScriptProperty -Name 'Logins' -Value {
                                $mockLoginObject = New-Object -TypeName Object |
                                    Add-Member -MemberType NoteProperty -Name 'Name' -Value 'Login1' -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'LoginType' -Value 'SqlLogin' -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'DefaultDatabase' -Value 'master' -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'IsDisabled' -Value $true -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'MustChangePassword' -Value $true -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'PasswordExpirationEnabled' -Value $true -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'PasswordPolicyEnforced' -Value $true -PassThru -Force

                                return @{
                                    'Login1' = $mockLoginObject
                                }
                            } -PassThru -Force
                    }

                    Mock -CommandName Connect-SQL -MockWith $mockConnectSQL
                }

                It 'Should return the correct value for each property' {
                    InModuleScope -Parameters $_ -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $mockGetTargetResourceParameters.Name = $MockLoginName

                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.Ensure | Should -Be 'Absent'
                        $result.ServerName | Should -Be $mockGetTargetResourceParameters.ServerName
                        $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                        $result.Name | Should -Be $mockGetTargetResourceParameters.Name
                        $result.LoginType | Should -BeNullOrEmpty
                        $result.Disabled | Should -BeFalse
                        $result.DefaultDatabase | Should -BeNullOrEmpty

                        if ($MockLoginType -eq 'SqlLogin')
                        {
                            $result.LoginMustChangePassword | Should -BeFalse
                            $result.LoginPasswordExpirationEnabled | Should -BeFalse
                            $result.LoginPasswordPolicyEnforced | Should -BeFalse
                        }
                        else
                        {
                            <#
                                This is a bug in the code, these should always be returned
                                in the hashtable. This is put here so the tests wil be fixed
                                when the code is fixed.
                            #>
                            $result | Should -Not -Contain 'LoginMustChangePassword'
                            $result | Should -Not -Contain 'LoginPasswordExpirationEnabled'
                            $result | Should -Not -Contain 'LoginPasswordPolicyEnforced'
                        }
                    }
                }
            }
        }
    }
}

Describe 'SqlLogin\Test-TargetResource' -Tag 'Test' {
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
        Context 'When the login should be present' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Ensure = 'Present'
                    }
                }
            }

            It 'Should return $true' {
                InModuleScope -Parameters $_ -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.Name = 'Windows\Login1'

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeTrue
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the login should be absent' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Ensure = 'Absent'
                    }
                }
            }

            It 'Should return $true' {
                InModuleScope -Parameters $_ -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.Ensure = 'Absent'
                    $mockTestTargetResourceParameters.Name = 'Windows\Login1'

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeTrue
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When the system is not in the desired state' {
        Context 'When the login should be present' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Ensure = 'Absent'
                    }
                }
            }

            It 'Should return $false' {
                InModuleScope -Parameters $_ -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.Name = 'Windows\Login1'

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeFalse
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the login should be absent' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Ensure = 'Present'
                    }
                }
            }

            It 'Should return $false' {
                InModuleScope -Parameters $_ -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.Ensure = 'Absent'
                    $mockTestTargetResourceParameters.Name = 'Windows\Login1'

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeFalse
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the property <MockPropertyName> is not in desired state' -ForEach @(
            @{
                MockPropertyName = 'LoginType'
                MockPropertyValue = 'WindowsGroup'
            }
            @{
                MockPropertyName = 'Disabled'
                MockPropertyValue = $true
            }
            @{
                MockPropertyName = 'DefaultDatabase'
                MockPropertyValue = 'database1'
            }
        ) {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Ensure = 'Present'
                        Disabled = $false
                        DefaultDatabase = 'master'
                    }
                }
            }

            It 'Should return $false' {
                InModuleScope -Parameters $_ -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.Name = 'Login1'
                    $mockTestTargetResourceParameters.$MockPropertyName = $MockPropertyValue

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeFalse
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }
    }
}

# try
# {
#     InModuleScope $script:dscResourceName {
#         # Create PSCredential object for SQL Logins
#         $mockSqlLoginUser = 'dba'
#         $mockSqlLoginPassword = 'P@ssw0rd-12P@ssw0rd-12' | ConvertTo-SecureString -AsPlainText -Force
#         $mockSqlLoginCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @($mockSqlLoginUser, $mockSqlLoginPassword)

#         $mockSqlLoginBadPassword = 'pw' | ConvertTo-SecureString -AsPlainText -Force
#         $mockSqlLoginCredentialBadPassword = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @($mockSqlLoginUser, $mockSqlLoginBadPassword)

#         $mockSqlLoginReusedPassword = 'reused' | ConvertTo-SecureString -AsPlainText -Force
#         $mockSqlLoginCredentialReusedPassword = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @($mockSqlLoginUser, $mockSqlLoginReusedPassword)

#         $mockSqlLoginOtherPassword = 'other' | ConvertTo-SecureString -AsPlainText -Force
#         $mockSqlLoginCredentialOtherPassword = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($mockSqlLoginUser, $mockSqlLoginOtherPassword)

#         $instanceParameters = @{
#             InstanceName = 'MSSQLSERVER'
#             ServerName   = 'Server1'
#         }

#         $getTargetResource_UnknownSqlLogin = $instanceParameters.Clone()
#         $getTargetResource_UnknownSqlLogin[ 'Name' ] = 'UnknownSqlLogin'

#         $getTargetResource_UnknownWindows = $instanceParameters.Clone()
#         $getTargetResource_UnknownWindows[ 'Name' ] = 'Windows\UserOrGroup'

#         $getTargetResource_KnownSqlLogin = $instanceParameters.Clone()
#         $getTargetResource_KnownSqlLogin[ 'Name' ] = 'SqlLogin1'

#         $getTargetResource_KnownWindowsUser = $instanceParameters.Clone()
#         $getTargetResource_KnownWindowsUser[ 'Name' ] = 'Windows\User1'

#         $getTargetResource_KnownWindowsGroup = $instanceParameters.Clone()
#         $getTargetResource_KnownWindowsGroup[ 'Name' ] = 'Windows\Group1'

#         $testTargetResource_WindowsUserAbsent = $instanceParameters.Clone()
#         $testTargetResource_WindowsUserAbsent[ 'Name' ] = 'Windows\UserAbsent'
#         $testTargetResource_WindowsUserAbsent[ 'LoginType' ] = 'WindowsUser'

#         $testTargetResource_WindowsGroupAbsent = $instanceParameters.Clone()
#         $testTargetResource_WindowsGroupAbsent[ 'Name' ] = 'Windows\GroupAbsent'
#         $testTargetResource_WindowsGroupAbsent[ 'LoginType' ] = 'WindowsGroup'

#         $testTargetResource_SqlLoginAbsent = $instanceParameters.Clone()
#         $testTargetResource_SqlLoginAbsent[ 'Name' ] = 'SqlLoginAbsent'
#         $testTargetResource_SqlLoginAbsent[ 'LoginType' ] = 'SqlLogin'

#         $testTargetResource_WindowsUserPresent = $instanceParameters.Clone()
#         $testTargetResource_WindowsUserPresent[ 'Name' ] = 'Windows\User1'
#         $testTargetResource_WindowsUserPresent[ 'LoginType' ] = 'WindowsUser'

#         $testTargetResource_WindowsGroupPresent = $instanceParameters.Clone()
#         $testTargetResource_WindowsGroupPresent[ 'Name' ] = 'Windows\Group1'
#         $testTargetResource_WindowsGroupPresent[ 'LoginType' ] = 'WindowsGroup'

#         $testTargetResource_SqlLoginPresentWithDefaultValues = $instanceParameters.Clone()
#         $testTargetResource_SqlLoginPresentWithDefaultValues[ 'Name' ] = 'SqlLogin1'
#         $testTargetResource_SqlLoginPresentWithDefaultValues[ 'LoginType' ] = 'SqlLogin'

#         $setTargetResource_CertificateAbsent = $instanceParameters.Clone()
#         $setTargetResource_CertificateAbsent[ 'Name' ] = 'Certificate'
#         $setTargetResource_CertificateAbsent[ 'LoginType' ] = 'Certificate'

#         $setTargetResource_WindowsUserAbsent = $instanceParameters.Clone()
#         $setTargetResource_WindowsUserAbsent[ 'Name' ] = 'Windows\UserAbsent'
#         $setTargetResource_WindowsUserAbsent[ 'LoginType' ] = 'WindowsUser'

#         $setTargetResource_WindowsGroupAbsent = $instanceParameters.Clone()
#         $setTargetResource_WindowsGroupAbsent[ 'Name' ] = 'Windows\GroupAbsent'
#         $setTargetResource_WindowsGroupAbsent[ 'LoginType' ] = 'WindowsGroup'

#         $setTargetResource_SqlLoginAbsent = $instanceParameters.Clone()
#         $setTargetResource_SqlLoginAbsent[ 'Name' ] = 'SqlLoginAbsent'
#         $setTargetResource_SqlLoginAbsent[ 'LoginType' ] = 'SqlLogin'

#         $setTargetResource_SqlLoginAbsentExisting = $instanceParameters.Clone()
#         $setTargetResource_SqlLoginAbsentExisting[ 'Name' ] = 'Existing'
#         $setTargetResource_SqlLoginAbsentExisting[ 'LoginType' ] = 'SqlLogin'

#         $setTargetResource_SqlLoginAbsentUnknown = $instanceParameters.Clone()
#         $setTargetResource_SqlLoginAbsentUnknown[ 'Name' ] = 'Unknown'
#         $setTargetResource_SqlLoginAbsentUnknown[ 'LoginType' ] = 'SqlLogin'

#         $setTargetResource_WindowsUserPresent = $instanceParameters.Clone()
#         $setTargetResource_WindowsUserPresent[ 'Name' ] = 'Windows\User1'
#         $setTargetResource_WindowsUserPresent[ 'LoginType' ] = 'WindowsUser'

#         $setTargetResource_CertificateAbsent = $instanceParameters.Clone()
#         $setTargetResource_CertificateAbsent[ 'Name' ] = 'Certificate'
#         $setTargetResource_CertificateAbsent[ 'LoginType' ] = 'Certificate'

#         $setTargetResource_WindowsUserAbsent = $instanceParameters.Clone()
#         $setTargetResource_WindowsUserAbsent[ 'Name' ] = 'Windows\UserAbsent'
#         $setTargetResource_WindowsUserAbsent[ 'LoginType' ] = 'WindowsUser'

#         $setTargetResource_WindowsGroupAbsent = $instanceParameters.Clone()
#         $setTargetResource_WindowsGroupAbsent[ 'Name' ] = 'Windows\GroupAbsent'
#         $setTargetResource_WindowsGroupAbsent[ 'LoginType' ] = 'WindowsGroup'

#         $setTargetResource_SqlLoginAbsent = $instanceParameters.Clone()
#         $setTargetResource_SqlLoginAbsent[ 'Name' ] = 'SqlLoginAbsent'
#         $setTargetResource_SqlLoginAbsent[ 'LoginType' ] = 'SqlLogin'

#         $setTargetResource_SqlLoginAbsentExisting = $instanceParameters.Clone()
#         $setTargetResource_SqlLoginAbsentExisting[ 'Name' ] = 'Existing'
#         $setTargetResource_SqlLoginAbsentExisting[ 'LoginType' ] = 'SqlLogin'

#         $setTargetResource_SqlLoginAbsentUnknown = $instanceParameters.Clone()
#         $setTargetResource_SqlLoginAbsentUnknown[ 'Name' ] = 'Unknown'
#         $setTargetResource_SqlLoginAbsentUnknown[ 'LoginType' ] = 'SqlLogin'

#         $setTargetResource_WindowsUserPresent = $instanceParameters.Clone()
#         $setTargetResource_WindowsUserPresent[ 'Name' ] = 'Windows\User1'
#         $setTargetResource_WindowsUserPresent[ 'LoginType' ] = 'WindowsUser'

#         $setTargetResource_WindowsGroupPresent = $instanceParameters.Clone()
#         $setTargetResource_WindowsGroupPresent[ 'Name' ] = 'Windows\Group1'
#         $setTargetResource_WindowsGroupPresent[ 'LoginType' ] = 'WindowsGroup'

#         $setTargetResource_SqlLoginPresent = $instanceParameters.Clone()
#         $setTargetResource_SqlLoginPresent[ 'Name' ] = 'SqlLogin1'
#         $setTargetResource_SqlLoginPresent[ 'LoginType' ] = 'SqlLogin'

#         <#
#             These are set when the mocked methods Enable() and Disabled() are called.
#             Can be used to verify that the method was actually called or not called.
#         #>
#         $script:mockWasLoginClassMethodEnableCalled = $false
#         $script:mockWasLoginClassMethodDisabledCalled = $false

#         $mockConnectSQL = {
#             $windowsUser = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Login' -ArgumentList @('Server', 'Windows\User1')
#             $windowsUser.LoginType = 'WindowsUser'
#             $windowsUser = $windowsUser | Add-Member -Name 'Disable' -MemberType ScriptMethod -Value {
#                 $script:mockWasLoginClassMethodDisabledCalled = $true
#             } -PassThru -Force
#             $windowsUser.DefaultDatabase = 'master'

#             $windowsGroup = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Login' -ArgumentList ('Server', 'Windows\Group1')
#             $windowsGroup.LoginType = 'windowsGroup'
#             $windowsGroup.DefaultDatabase = 'master'

#             $sqlLogin = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Login' -ArgumentList @('Server', 'SqlLogin1')
#             $sqlLogin.LoginType = 'SqlLogin'
#             $sqlLogin.MustChangePassword = $false
#             $sqlLogin.DefaultDatabase = 'master'
#             $sqlLogin.PasswordPolicyEnforced = $true
#             $sqlLogin.PasswordExpirationEnabled = $true

#             $sqlLoginDisabled = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Login' -ArgumentList @('Server', 'Windows\UserDisabled')
#             $sqlLoginDisabled.LoginType = 'WindowsUser'
#             $sqlLoginDisabled.DefaultDatabase = 'master'
#             $sqlLoginDisabled.IsDisabled = $true
#             $sqlLoginDisabled = $sqlLoginDisabled | Add-Member -Name 'Enable' -MemberType ScriptMethod -Value {
#                 $script:mockWasLoginClassMethodEnableCalled = $true
#             } -PassThru -Force

#             $mock = New-Object -TypeName PSObject -Property @{
#                 LoginMode = 'Mixed'
#                 Logins = @{
#                     $windowsUser.Name = $windowsUser
#                     $windowsGroup.Name = $windowsGroup
#                     $sqlLogin.Name = $sqlLogin
#                     $sqlLoginDisabled.Name = $sqlLoginDisabled
#                 }
#             }

#             return $mock
#         }

#         $mockConnectSQL_LoginMode = {
#             return New-Object -TypeName Object |
#                 Add-Member -MemberType ScriptProperty -Name 'Logins' -Value {
#                     return @{
#                         'Windows\User1' = ( New-Object -TypeName Object |
#                                 Add-Member -MemberType NoteProperty -Name 'Name' -Value 'Windows\User1' -PassThru |
#                                 Add-Member -MemberType NoteProperty -Name 'LoginType' -Value 'WindowsUser' -PassThru |
#                                 Add-Member -MemberType NoteProperty -Name 'DefaultDatabase' -Value 'master' -PassThru |
#                                 Add-Member -MemberType ScriptMethod -Name Alter -Value {} -PassThru |
#                                 Add-Member -MemberType ScriptMethod -Name Drop -Value {} -PassThru -Force
#                         )
#                         'SqlLogin1' = ( New-Object -TypeName Object |
#                                 Add-Member -MemberType NoteProperty -Name 'Name' -Value 'SqlLogin1' -PassThru |
#                                 Add-Member -MemberType NoteProperty -Name 'LoginType' -Value 'SqlLogin' -PassThru |
#                                 Add-Member -MemberType NoteProperty -Name 'DefaultDatabase' -Value 'master' -PassThru |
#                                 Add-Member -MemberType NoteProperty -Name 'MustChangePassword' -Value $false -PassThru |
#                                 Add-Member -MemberType NoteProperty -Name 'PasswordExpirationEnabled' -Value $true -PassThru |
#                                 Add-Member -MemberType NoteProperty -Name 'PasswordPolicyEnforced' -Value $true -PassThru |
#                                 Add-Member -MemberType ScriptMethod -Name Alter -Value {} -PassThru |
#                                 Add-Member -MemberType ScriptMethod -Name Drop -Value {} -PassThru -Force
#                         )
#                         'Windows\Group1' = ( New-Object -TypeName Object |
#                                 Add-Member -MemberType NoteProperty -Name 'Name' -Value 'Windows\Group1' -PassThru |
#                                 Add-Member -MemberType NoteProperty -Name 'LoginType' -Value 'WindowsGroup' -PassThru |
#                                 Add-Member -MemberType NoteProperty -Name 'DefaultDatabase' -Value 'master' -PassThru |
#                                 Add-Member -MemberType ScriptMethod -Name Alter -Value {} -PassThru |
#                                 Add-Member -MemberType ScriptMethod -Name Drop -Value {} -PassThru -Force
#                         )
#                     }
#                 } -PassThru |
#                     Add-Member -MemberType NoteProperty -Name LoginMode -Value $mockLoginMode -PassThru -Force
#         }




#         #endregion Pester Test Initialization


#         Describe 'DSC_SqlLogin\Test-TargetResource' {
#             Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

#             Context 'When the desired state is Absent' {
#                 It 'Should return $true when the specified Windows user is Absent' {
#                     $testTargetResource_WindowsUserAbsent_EnsureAbsent = $testTargetResource_WindowsUserAbsent.Clone()
#                     $testTargetResource_WindowsUserAbsent_EnsureAbsent[ 'Ensure' ] = 'Absent'

#                     ( Test-TargetResource @testTargetResource_WindowsUserAbsent_EnsureAbsent ) | Should -Be $true

#                     Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
#                 }

#                 It 'Should return $true when the specified Windows group is Absent' {
#                     $testTargetResource_WindowsGroupAbsent_EnsureAbsent = $testTargetResource_WindowsGroupAbsent.Clone()
#                     $testTargetResource_WindowsGroupAbsent_EnsureAbsent[ 'Ensure' ] = 'Absent'

#                     ( Test-TargetResource @testTargetResource_WindowsGroupAbsent_EnsureAbsent ) | Should -Be $true

#                     Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
#                 }

#                 It 'Should return $true when the specified SQL Login is Absent' {
#                     $testTargetResource_SqlLoginAbsent_EnsureAbsent = $testTargetResource_SqlLoginAbsent.Clone()
#                     $testTargetResource_SqlLoginAbsent_EnsureAbsent[ 'Ensure' ] = 'Absent'

#                     ( Test-TargetResource @testTargetResource_SqlLoginAbsent_EnsureAbsent ) | Should -Be $true

#                     Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
#                 }

#                 It 'Should return $false when the specified Windows user is Present' {
#                     $testTargetResource_WindowsUserPresent_EnsureAbsent = $testTargetResource_WindowsUserPresent.Clone()
#                     $testTargetResource_WindowsUserPresent_EnsureAbsent[ 'Ensure' ] = 'Absent'

#                     ( Test-TargetResource @testTargetResource_WindowsUserPresent_EnsureAbsent ) | Should -Be $false

#                     Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
#                 }

#                 It 'Should return $false when the specified Windows group is Present' {
#                     $testTargetResource_WindowsGroupPresent_EnsureAbsent = $testTargetResource_WindowsGroupPresent.Clone()
#                     $testTargetResource_WindowsGroupPresent_EnsureAbsent[ 'Ensure' ] = 'Absent'

#                     ( Test-TargetResource @testTargetResource_WindowsGroupPresent_EnsureAbsent ) | Should -Be $false

#                     Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
#                 }

#                 It 'Should return $false when the specified SQL Login is Present' {
#                     $testTargetResource_SqlLoginPresentWithDefaultValues_EnsureAbsent = $testTargetResource_SqlLoginPresentWithDefaultValues.Clone()
#                     $testTargetResource_SqlLoginPresentWithDefaultValues_EnsureAbsent[ 'Ensure' ] = 'Absent'

#                     ( Test-TargetResource @testTargetResource_SqlLoginPresentWithDefaultValues_EnsureAbsent ) | Should -Be $false

#                     Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
#                 }

#                 It 'Should be return $false when a login should be disabled but are enabled' {
#                     $mockTestTargetResourceParameters = $instanceParameters.Clone()
#                     $mockTestTargetResourceParameters[ 'Ensure' ] = 'Present'
#                     $mockTestTargetResourceParameters[ 'Name' ] = 'Windows\User1'
#                     $mockTestTargetResourceParameters[ 'Disabled' ] = $true

#                     $result = Test-TargetResource @mockTestTargetResourceParameters
#                     $result | Should -Be $false

#                     Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
#                 }

#                 It 'Should be return $false when a login should be enabled but are disabled' {
#                     $mockTestTargetResourceParameters = $instanceParameters.Clone()
#                     $mockTestTargetResourceParameters[ 'Ensure' ] = 'Present'
#                     $mockTestTargetResourceParameters[ 'Name' ] = 'Windows\UserDisabled'
#                     $mockTestTargetResourceParameters[ 'Disabled' ] = $false

#                     $result = Test-TargetResource @mockTestTargetResourceParameters
#                     $result | Should -Be $false

#                     Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
#                 }

#                 It 'Should be return $true when a login should be present but disabled' {
#                     $mockTestTargetResourceParameters = $getTargetResource_KnownSqlLogin.Clone()
#                     $mockTestTargetResourceParameters[ 'Ensure' ] = 'Present'
#                     $mockTestTargetResourceParameters[ 'Disabled' ] = $true
#                     $mockTestTargetResourceParameters[ 'LoginType' ] = 'SqlLogin'
#                     $mockTestTargetResourceParameters[ 'LoginCredential' ] = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @($mockTestTargetResourceParameters.Name, $mockSqlLoginPassword)

#                     # Override mock declaration
#                     Mock -CommandName Connect-SQL -MockWith {
#                         $mockAccountDisabledException = New-Object System.Exception 'Account disabled'
#                         $mockAccountDisabledException | Add-Member -Name 'Number' -Value 18470 -MemberType NoteProperty

#                         throw $mockAccountDisabledException
#                     }

#                     # Override Get-TargetResource
#                     Mock -CommandName Get-TargetResource {return New-Object PSObject -Property @{
#                         Ensure          = 'Present'
#                         Name            = $mockTestTargetResourceParameters.Name
#                         LoginType       = $mockTestTargetResourceParameters.LoginType
#                         ServerName      = 'Server1'
#                         InstanceName    = 'MSSQLERVER'
#                         Disabled        = $true
#                         DefaultDatabase = 'master'
#                         LoginMustChangePassword = $false
#                         LoginPasswordPolicyEnforced = $true
#                         LoginPasswordExpirationEnabled = $true
#                       }
#                     }

#                     # Call the test target
#                     $result = Test-TargetResource @mockTestTargetResourceParameters

#                     Assert-MockCalled -CommandName Get-TargetResource -Scope It -Times 1 -Exactly
#                     Assert-MockCAlled -CommandName Connect-SQL -Scope It -Times 1 -Exactly

#                     # Should be true
#                     $result | Should -Be $true
#                 }

#                 It 'Should be return $false when a login should be present but disabled and password incorrect' {
#                     $mockTestTargetResourceParameters = $getTargetResource_KnownSqlLogin.Clone()
#                     $mockTestTargetResourceParameters[ 'Ensure' ] = 'Present'
#                     $mockTestTargetResourceParameters[ 'Disabled' ] = $true
#                     $mockTestTargetResourceParameters[ 'LoginType' ] = 'SqlLogin'
#                     $mockTestTargetResourceParameters[ 'LoginCredential' ] = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @($mockTestTargetResourceParameters.Name, $mockSqlLoginPassword)

#                     # Override mock declaration
#                     Mock -CommandName Connect-SQL -MockWith {
#                         $mockLoginFailedException = New-Object System.Exception 'Login failed'
#                         $mockLoginFailedException | Add-Member -Name 'Number' -Value 18456 -MemberType NoteProperty

#                         throw $mockLoginFailedException
#                     }

#                     # Override Get-TargetResource
#                     Mock -CommandName Get-TargetResource {return New-Object PSObject -Property @{
#                         Ensure          = 'Present'
#                         Name            = $mockTestTargetResourceParameters.Name
#                         LoginType       = $mockTestTargetResourceParameters.LoginType
#                         ServerName      = 'Server1'
#                         InstanceName    = 'MSSQLERVER'
#                         Disabled        = $true
#                         DefaultDatabase = 'master'
#                         LoginMustChangePassword = $false
#                         LoginPasswordPolicyEnforced = $true
#                         LoginPasswordExpirationEnabled = $true
#                       }
#                     }

#                     # Call the test target
#                     $result = Test-TargetResource @mockTestTargetResourceParameters

#                     Assert-MockCalled -CommandName Get-TargetResource -Scope It -Times 1 -Exactly
#                     Assert-MockCAlled -CommandName Connect-SQL -Scope It -Times 1 -Exactly

#                     # Should be true
#                     $result | Should -Be $false
#                 }

#                 It 'Should throw exception when unknown error occurred and account is disabled' {
#                     $mockTestTargetResourceParameters = $getTargetResource_KnownSqlLogin.Clone()
#                     $mockTestTargetResourceParameters[ 'Ensure' ] = 'Present'
#                     $mockTestTargetResourceParameters[ 'Disabled' ] = $true
#                     $mockTestTargetResourceParameters[ 'LoginType' ] = 'SqlLogin'
#                     $mockTestTargetResourceParameters[ 'LoginCredential' ] = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @($mockTestTargetResourceParameters.Name, $mockSqlLoginPassword)

#                     # Override mock declaration
#                     Mock -CommandName Connect-SQL -MockWith {
#                         $mockException = New-Object System.Exception 'Something went wrong'
#                         $mockException | Add-Member -Name 'Number' -Value 1 -MemberType NoteProperty

#                         throw $mockException
#                     }

#                     # Override Get-TargetResource
#                     Mock -CommandName Get-TargetResource {return New-Object PSObject -Property @{
#                         Ensure          = 'Present'
#                         Name            = $mockTestTargetResourceParameters.Name
#                         LoginType       = $mockTestTargetResourceParameters.LoginType
#                         ServerName      = 'Server1'
#                         InstanceName    = 'MSSQLERVER'
#                         Disabled        = $true
#                         DefaultDatabase = 'master'
#                         LoginMustChangePassword = $false
#                         LoginPasswordPolicyEnforced = $true
#                         LoginPasswordExpirationEnabled = $true
#                       }
#                     }

#                     # Call the test target
#                     $errorMessage = $script:localizedData.PasswordValidationError
#                     { Test-TargetResource @mockTestTargetResourceParameters } | Should -Throw $errorMessage

#                     Assert-MockCalled -CommandName Get-TargetResource -Scope It -Times 1 -Exactly
#                     Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
#                 }
#             }

#             Context 'When the desired state is Present' {
#                 It 'Should return $false when the specified Windows user is Absent' {
#                     $testTargetResource_WindowsUserAbsent_EnsurePresent = $testTargetResource_WindowsUserAbsent.Clone()
#                     $testTargetResource_WindowsUserAbsent_EnsurePresent[ 'Ensure' ] = 'Present'

#                     ( Test-TargetResource @testTargetResource_WindowsUserAbsent_EnsurePresent ) | Should -Be $false

#                     Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
#                 }

#                 It 'Should not be checking login properties when Windows user is Absent' {
#                     Mock -CommandName Write-Verbose -ParameterFilter {$message.contains('rather than WindowsUser')}

#                     $testTargetResource_WindowsUserAbsent_EnsurePresent = $testTargetResource_WindowsUserAbsent.Clone()
#                     $testTargetResource_WindowsUserAbsent_EnsurePresent[ 'Ensure' ] = 'Present'

#                     ( Test-TargetResource @testTargetResource_WindowsUserAbsent_EnsurePresent ) | Should -Be $false

#                     Assert-MockCalled -CommandName Write-Verbose -Scope It -Times 0 -Exactly
#                 }

#                 It 'Should return $false when the specified Windows group is Absent' {
#                     $testTargetResource_WindowsGroupAbsent_EnsurePresent = $testTargetResource_WindowsGroupAbsent.Clone()
#                     $testTargetResource_WindowsGroupAbsent_EnsurePresent[ 'Ensure' ] = 'Present'

#                     ( Test-TargetResource @testTargetResource_WindowsGroupAbsent_EnsurePresent ) | Should -Be $false

#                     Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
#                 }

#                 It 'Should not be checking login properties when Windows group is Absent' {
#                     Mock -CommandName Write-Verbose -ParameterFilter {$message.contains('rather than WindowsGroup')}

#                     $testTargetResource_WindowsGroupAbsent_EnsurePresent = $testTargetResource_WindowsGroupAbsent.Clone()
#                     $testTargetResource_WindowsGroupAbsent_EnsurePresent[ 'Ensure' ] = 'Present'

#                     ( Test-TargetResource @testTargetResource_WindowsGroupAbsent_EnsurePresent ) | Should -Be $false

#                     Assert-MockCalled -CommandName Write-Verbose -Scope It -Times 0 -Exactly
#                 }

#                 It 'Should return $false when the specified SQL Login is Absent' {
#                     $testTargetResource_SqlLoginAbsent_EnsurePresent = $testTargetResource_SqlLoginAbsent.Clone()
#                     $testTargetResource_SqlLoginAbsent_EnsurePresent[ 'Ensure' ] = 'Present'

#                     ( Test-TargetResource @testTargetResource_SqlLoginAbsent_EnsurePresent ) | Should -Be $false

#                     Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
#                 }

#                 It 'Should not be checking login properties when SQL Login is Absent' {
#                     Mock -CommandName Write-Verbose -ParameterFilter {$message.contains('rather than SqlLogin')}

#                     $testTargetResource_SqlLoginAbsent_EnsurePresent = $testTargetResource_SqlLoginAbsent.Clone()
#                     $testTargetResource_SqlLoginAbsent_EnsurePresent[ 'Ensure' ] = 'Present'

#                     ( Test-TargetResource @testTargetResource_SqlLoginAbsent_EnsurePresent ) | Should -Be $false

#                     Assert-MockCalled -CommandName Write-Verbose -Scope It -Times 0 -Exactly
#                 }

#                 It 'Should return $true when the specified Windows user is Present' {
#                     $testTargetResource_WindowsUserPresent_EnsurePresent = $testTargetResource_WindowsUserPresent.Clone()
#                     $testTargetResource_WindowsUserPresent_EnsurePresent[ 'Ensure' ] = 'Present'

#                     ( Test-TargetResource @testTargetResource_WindowsUserPresent_EnsurePresent ) | Should -Be $true

#                     Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
#                 }

#                 It 'Should return $true when the specified Windows group is Present' {
#                     $testTargetResource_WindowsGroupPresent_EnsurePresent = $testTargetResource_WindowsGroupPresent.Clone()
#                     $testTargetResource_WindowsGroupPresent_EnsurePresent[ 'Ensure' ] = 'Present'

#                     ( Test-TargetResource @testTargetResource_WindowsGroupPresent_EnsurePresent ) | Should -Be $true

#                     Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
#                 }

#                 It 'Should return $true when the specified SQL Login is Present using default parameter values' {
#                     $testTargetResource_SqlLoginPresentWithDefaultValues_EnsurePresent = $testTargetResource_SqlLoginPresentWithDefaultValues.Clone()
#                     $testTargetResource_SqlLoginPresentWithDefaultValues_EnsurePresent[ 'Ensure' ] = 'Present'

#                     ( Test-TargetResource @testTargetResource_SqlLoginPresentWithDefaultValues_EnsurePresent ) | Should -Be $true

#                     Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
#                 }

#                 It 'Should return $true when the specified SQL Login is Present and DefaultDatabase is "master"' {
#                     $testTargetResource_SqlLoginPresentWithDefaultDatabaseMaster_EnsurePresent = $testTargetResource_SqlLoginPresentWithDefaultValues.Clone()
#                     $testTargetResource_SqlLoginPresentWithDefaultDatabaseMaster_EnsurePresent[ 'Ensure' ] = 'Present'
#                     $testTargetResource_SqlLoginPresentWithDefaultDatabaseMaster_EnsurePresent[ 'DefaultDatabase' ] = 'master'

#                     ( Test-TargetResource @testTargetResource_SqlLoginPresentWithDefaultDatabaseMaster_EnsurePresent ) | Should -Be $true

#                     Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
#                 }

#                 It 'Should return $false when the specified SQL Login is Present and DefaultDatabase is not "master"' {
#                     $testTargetResource_SqlLoginPresentWithDefaultDatabaseNotMaster_EnsurePresent = $testTargetResource_SqlLoginPresentWithDefaultValues.Clone()
#                     $testTargetResource_SqlLoginPresentWithDefaultDatabaseNotMaster_EnsurePresent[ 'Ensure' ] = 'Present'
#                     $testTargetResource_SqlLoginPresentWithDefaultDatabaseNotMaster_EnsurePresent[ 'DefaultDatabase' ] = 'notmaster'

#                     ( Test-TargetResource @testTargetResource_SqlLoginPresentWithDefaultDatabaseNotMaster_EnsurePresent ) | Should -Be $false

#                     Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
#                 }

#                 It 'Should return $true when the specified SQL Login is Present and PasswordExpirationEnabled is $true' {
#                     $testTargetResource_SqlLoginPresentWithPasswordExpirationEnabledTrue_EnsurePresent = $testTargetResource_SqlLoginPresentWithDefaultValues.Clone()
#                     $testTargetResource_SqlLoginPresentWithPasswordExpirationEnabledTrue_EnsurePresent[ 'Ensure' ] = 'Present'
#                     $testTargetResource_SqlLoginPresentWithPasswordExpirationEnabledTrue_EnsurePresent[ 'LoginPasswordExpirationEnabled' ] = $true

#                     ( Test-TargetResource @testTargetResource_SqlLoginPresentWithPasswordExpirationEnabledTrue_EnsurePresent ) | Should -Be $true

#                     Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
#                 }

#                 It 'Should return $false when the specified SQL Login is Present and PasswordExpirationEnabled is $false' {
#                     $testTargetResource_SqlLoginPresentWithPasswordExpirationEnabledFalse_EnsurePresent = $testTargetResource_SqlLoginPresentWithDefaultValues.Clone()
#                     $testTargetResource_SqlLoginPresentWithPasswordExpirationEnabledFalse_EnsurePresent[ 'Ensure' ] = 'Present'
#                     $testTargetResource_SqlLoginPresentWithPasswordExpirationEnabledFalse_EnsurePresent[ 'LoginPasswordExpirationEnabled' ] = $false

#                     ( Test-TargetResource @testTargetResource_SqlLoginPresentWithPasswordExpirationEnabledFalse_EnsurePresent ) | Should -Be $false

#                     Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
#                 }

#                 It 'Should return $true when the specified SQL Login is Present and PasswordPolicyEnforced is $true' {
#                     $testTargetResource_SqlLoginPresentWithPasswordPolicyEnforcedTrue_EnsurePresent = $testTargetResource_SqlLoginPresentWithDefaultValues.Clone()
#                     $testTargetResource_SqlLoginPresentWithPasswordPolicyEnforcedTrue_EnsurePresent[ 'Ensure' ] = 'Present'
#                     $testTargetResource_SqlLoginPresentWithPasswordPolicyEnforcedTrue_EnsurePresent[ 'LoginPasswordPolicyEnforced' ] = $true

#                     ( Test-TargetResource @testTargetResource_SqlLoginPresentWithPasswordPolicyEnforcedTrue_EnsurePresent ) | Should -Be $true

#                     Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
#                 }

#                 It 'Should return $false when the specified SQL Login is Present and PasswordPolicyEnforced is $false' {
#                     $testTargetResource_SqlLoginPresentWithPasswordPolicyEnforcedFalse_EnsurePresent = $testTargetResource_SqlLoginPresentWithDefaultValues.Clone()
#                     $testTargetResource_SqlLoginPresentWithPasswordPolicyEnforcedFalse_EnsurePresent[ 'Ensure' ] = 'Present'
#                     $testTargetResource_SqlLoginPresentWithPasswordPolicyEnforcedFalse_EnsurePresent[ 'LoginPasswordPolicyEnforced' ] = $false

#                     ( Test-TargetResource @testTargetResource_SqlLoginPresentWithPasswordPolicyEnforcedFalse_EnsurePresent ) | Should -Be $false

#                     Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
#                 }

#                 It 'Should return $true when the specified SQL Login is Present using default parameter values and the password is properly configured.' {
#                     $testTargetResource_SqlLoginPresentWithDefaultValuesGoodPw_EnsurePresent = $testTargetResource_SqlLoginPresentWithDefaultValues.Clone()
#                     $testTargetResource_SqlLoginPresentWithDefaultValuesGoodPw_EnsurePresent[ 'Ensure' ] = 'Present'
#                     $testTargetResource_SqlLoginPresentWithDefaultValuesGoodPw_EnsurePresent[ 'LoginCredential' ] = $mockSqlLoginCredential

#                     ( Test-TargetResource @testTargetResource_SqlLoginPresentWithDefaultValuesGoodPw_EnsurePresent ) | Should -Be $true

#                     Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 2 -Exactly
#                 }

#                 It 'Should return $false when the specified SQL Login is Present using default parameter values and the password is not properly configured.' {
#                     Mock -CommandName Connect-SQL -MockWith { throw } -Verifiable -ParameterFilter { $SetupCredential }

#                     $testTargetResource_SqlLoginPresentWithDefaultValuesBadPw_EnsurePresent = $testTargetResource_SqlLoginPresentWithDefaultValues.Clone()
#                     $testTargetResource_SqlLoginPresentWithDefaultValuesBadPw_EnsurePresent[ 'Ensure' ] = 'Present'
#                     $testTargetResource_SqlLoginPresentWithDefaultValuesBadPw_EnsurePresent[ 'LoginCredential' ] = $mockSqlLoginCredentialBadPassword

#                     ( Test-TargetResource @testTargetResource_SqlLoginPresentWithDefaultValuesBadPw_EnsurePresent ) | Should -Be $false

#                     Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 2 -Exactly
#                 }

#                 It 'Should be return $true when a login is enabled' {
#                     $mockTestTargetResourceParameters = $instanceParameters.Clone()
#                     $mockTestTargetResourceParameters[ 'Ensure' ] = 'Present'
#                     $mockTestTargetResourceParameters[ 'Name' ] = 'Windows\User1'
#                     $mockTestTargetResourceParameters[ 'Disabled' ] = $false

#                     $result = Test-TargetResource @mockTestTargetResourceParameters
#                     $result | Should -Be $true

#                     Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
#                 }

#                 It 'Should be return $true when a login is disabled' {
#                     $mockTestTargetResourceParameters = $instanceParameters.Clone()
#                     $mockTestTargetResourceParameters[ 'Ensure' ] = 'Present'
#                     $mockTestTargetResourceParameters[ 'Name' ] = 'Windows\UserDisabled'
#                     $mockTestTargetResourceParameters[ 'Disabled' ] = $true

#                     $result = Test-TargetResource @mockTestTargetResourceParameters
#                     $result | Should -Be $true

#                     Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
#                 }

#                 It 'Should be return $false when a login has the wrong login type' {
#                     $mockTestTargetResourceParameters = $instanceParameters.Clone()
#                     $mockTestTargetResourceParameters[ 'Ensure' ] = 'Present'
#                     <#
#                         Use WindowsLogin format here to be able to test the
#                         specific property LoginType.
#                     #>
#                     $mockTestTargetResourceParameters[ 'Name' ] = 'Windows\UserDisabled'
#                     $mockTestTargetResourceParameters[ 'LoginType' ] = 'SqlLogin'
#                     $mockTestTargetResourceParameters[ 'Disabled' ] = $true

#                     $result = Test-TargetResource @mockTestTargetResourceParameters
#                     $result | Should -Be $false

#                     Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
#                 }
#             }
#         }

#         Describe 'DSC_SqlLogin\Set-TargetResource' {
#             Mock -CommandName Update-SQLServerLogin -ModuleName $script:dscResourceName
#             Mock -CommandName New-SQLServerLogin -ModuleName $script:dscResourceName
#             Mock -CommandName Remove-SQLServerLogin -ModuleName $script:dscResourceName
#             Mock -CommandName Set-SQLServerLoginPassword -ModuleName $script:dscResourceName

#             Context 'When the desired state is Absent' {
#                 BeforeEach {
#                     $script:mockWasLoginClassMethodEnableCalled = $false
#                     $script:mockWasLoginClassMethodDisabledCalled = $false
#                 }

#                 It 'Should drop the specified Windows User when it is Present' {
#                     Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

#                     $setTargetResource_WindowsUserPresent_EnsureAbsent = $setTargetResource_WindowsUserPresent.Clone()
#                     $setTargetResource_WindowsUserPresent_EnsureAbsent[ 'Ensure' ] = 'Absent'

#                     Set-TargetResource @setTargetResource_WindowsUserPresent_EnsureAbsent

#                     Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
#                     Assert-MockCalled -CommandName Update-SQLServerLogin  -Scope It -Times 0 -Exactly
#                     Assert-MockCalled -CommandName New-SQLServerLogin  -Scope It -Times 0 -Exactly
#                     Assert-MockCalled -CommandName Remove-SQLServerLogin  -Scope It -Times 1 -Exactly
#                     Assert-MockCalled -CommandName Set-SQLServerLoginPassword  -Scope It -Times 0 -Exactly
#                 }

#                 It 'Should enable the specified Windows User when it is disabled' {
#                     Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

#                     $mockSetTargetResourceParameters = $instanceParameters.Clone()
#                     $mockSetTargetResourceParameters[ 'Ensure' ] = 'Present'
#                     $mockSetTargetResourceParameters[ 'Name' ] = 'Windows\UserDisabled'
#                     $mockSetTargetResourceParameters[ 'Disabled' ] = $false

#                     Set-TargetResource @mockSetTargetResourceParameters
#                     $script:mockWasLoginClassMethodEnableCalled | Should -Be $true
#                     $script:mockWasLoginClassMethodDisabledCalled | Should -Be $false

#                     Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
#                     Assert-MockCalled -CommandName Update-SQLServerLogin  -Scope It -Times 0 -Exactly
#                     Assert-MockCalled -CommandName New-SQLServerLogin  -Scope It -Times 0 -Exactly
#                     Assert-MockCalled -CommandName Remove-SQLServerLogin  -Scope It -Times 0 -Exactly
#                     Assert-MockCalled -CommandName Set-SQLServerLoginPassword  -Scope It -Times 0 -Exactly
#                 }

#                 It 'Should disable the specified Windows User when it is enabled' {
#                     Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

#                     $mockSetTargetResourceParameters = $instanceParameters.Clone()
#                     $mockSetTargetResourceParameters[ 'Ensure' ] = 'Present'
#                     $mockSetTargetResourceParameters[ 'Name' ] = 'Windows\User1'
#                     $mockSetTargetResourceParameters[ 'Disabled' ] = $true

#                     Set-TargetResource @mockSetTargetResourceParameters
#                     $script:mockWasLoginClassMethodEnableCalled | Should -Be $false
#                     $script:mockWasLoginClassMethodDisabledCalled | Should -Be $true

#                     Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
#                     Assert-MockCalled -CommandName Update-SQLServerLogin  -Scope It -Times 0 -Exactly
#                     Assert-MockCalled -CommandName New-SQLServerLogin  -Scope It -Times 0 -Exactly
#                     Assert-MockCalled -CommandName Remove-SQLServerLogin  -Scope It -Times 0 -Exactly
#                     Assert-MockCalled -CommandName Set-SQLServerLoginPassword  -Scope It -Times 0 -Exactly
#                 }

#                 It 'Should drop the specified Windows Group when it is Present' {
#                     Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

#                     $setTargetResource_WindowsGroupPresent_EnsureAbsent = $setTargetResource_WindowsGroupPresent.Clone()
#                     $setTargetResource_WindowsGroupPresent_EnsureAbsent[ 'Ensure' ] = 'Absent'

#                     Set-TargetResource @setTargetResource_WindowsGroupPresent_EnsureAbsent

#                     Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
#                     Assert-MockCalled -CommandName Update-SQLServerLogin  -Scope It -Times 0 -Exactly
#                     Assert-MockCalled -CommandName New-SQLServerLogin  -Scope It -Times 0 -Exactly
#                     Assert-MockCalled -CommandName Remove-SQLServerLogin  -Scope It -Times 1 -Exactly
#                     Assert-MockCalled -CommandName Set-SQLServerLoginPassword  -Scope It -Times 0 -Exactly
#                 }

#                 It 'Should drop the specified SQL Login when it is Present' {
#                     Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

#                     $setTargetResource_SqlLoginPresent_EnsureAbsent = $setTargetResource_SqlLoginPresent.Clone()
#                     $setTargetResource_SqlLoginPresent_EnsureAbsent[ 'Ensure' ] = 'Absent'

#                     Set-TargetResource @setTargetResource_SqlLoginPresent_EnsureAbsent

#                     Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
#                     Assert-MockCalled -CommandName Update-SQLServerLogin  -Scope It -Times 0 -Exactly
#                     Assert-MockCalled -CommandName New-SQLServerLogin  -Scope It -Times 0 -Exactly
#                     Assert-MockCalled -CommandName Remove-SQLServerLogin  -Scope It -Times 1 -Exactly
#                     Assert-MockCalled -CommandName Set-SQLServerLoginPassword  -Scope It -Times 0 -Exactly
#                 }

#                 It 'Should do nothing when the specified Windows User is Absent' {
#                     Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

#                     $setTargetResource_WindowsUserAbsent_EnsureAbsent = $setTargetResource_WindowsUserAbsent.Clone()
#                     $setTargetResource_WindowsUserAbsent_EnsureAbsent[ 'Ensure' ] = 'Absent'

#                     Set-TargetResource @setTargetResource_WindowsUserAbsent_EnsureAbsent

#                     Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
#                     Assert-MockCalled -CommandName Update-SQLServerLogin  -Scope It -Times 0 -Exactly
#                     Assert-MockCalled -CommandName New-SQLServerLogin  -Scope It -Times 0 -Exactly
#                     Assert-MockCalled -CommandName Remove-SQLServerLogin  -Scope It -Times 0 -Exactly
#                     Assert-MockCalled -CommandName Set-SQLServerLoginPassword  -Scope It -Times 0 -Exactly
#                 }

#                 It 'Should do nothing when the specified Windows Group is Absent' {
#                     Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

#                     $setTargetResource_WindowsGroupAbsent_EnsureAbsent = $setTargetResource_WindowsGroupAbsent.Clone()
#                     $setTargetResource_WindowsGroupAbsent_EnsureAbsent[ 'Ensure' ] = 'Absent'

#                     Set-TargetResource @setTargetResource_WindowsGroupAbsent_EnsureAbsent

#                     Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
#                     Assert-MockCalled -CommandName Update-SQLServerLogin  -Scope It -Times 0 -Exactly
#                     Assert-MockCalled -CommandName New-SQLServerLogin  -Scope It -Times 0 -Exactly
#                     Assert-MockCalled -CommandName Remove-SQLServerLogin  -Scope It -Times 0 -Exactly
#                     Assert-MockCalled -CommandName Set-SQLServerLoginPassword  -Scope It -Times 0 -Exactly
#                 }

#                 It 'Should do nothing when the specified SQL Login is Absent' {
#                     Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

#                     $setTargetResource_SqlLoginAbsent_EnsureAbsent = $setTargetResource_SqlLoginAbsent.Clone()
#                     $setTargetResource_SqlLoginAbsent_EnsureAbsent[ 'Ensure' ] = 'Absent'

#                     Set-TargetResource @setTargetResource_SqlLoginAbsent_EnsureAbsent

#                     Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
#                     Assert-MockCalled -CommandName Update-SQLServerLogin  -Scope It -Times 0 -Exactly
#                     Assert-MockCalled -CommandName New-SQLServerLogin  -Scope It -Times 0 -Exactly
#                     Assert-MockCalled -CommandName Remove-SQLServerLogin  -Scope It -Times 0 -Exactly
#                     Assert-MockCalled -CommandName Set-SQLServerLoginPassword  -Scope It -Times 0 -Exactly
#                 }
#             }

#             Context 'When the desired state is Present' {
#                 BeforeEach {
#                     $script:mockWasLoginClassMethodEnableCalled = $false
#                     $script:mockWasLoginClassMethodDisabledCalled = $false
#                 }

#                 It 'Should add the specified Windows User when it is Absent' {
#                     Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

#                     $setTargetResource_WindowsUserAbsent_EnsurePresent = $setTargetResource_WindowsUserAbsent.Clone()
#                     $setTargetResource_WindowsUserAbsent_EnsurePresent[ 'Ensure' ] = 'Present'

#                     Set-TargetResource @setTargetResource_WindowsUserAbsent_EnsurePresent

#                     Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
#                     Assert-MockCalled -CommandName Update-SQLServerLogin  -Scope It -Times 0 -Exactly
#                     Assert-MockCalled -CommandName New-SQLServerLogin  -Scope It -Times 1 -Exactly
#                     Assert-MockCalled -CommandName Remove-SQLServerLogin  -Scope It -Times 0 -Exactly
#                     Assert-MockCalled -CommandName Set-SQLServerLoginPassword  -Scope It -Times 0 -Exactly
#                 }

#                 It 'Should add the specified Windows User as disabled when it is Absent' {
#                     Mock -CommandName Connect-SQL -MockWith {
#                         return New-Object -TypeName PSObject -Property @{
#                             Logins = @{}
#                         }
#                     }-Verifiable

#                     Mock -CommandName New-Object -MockWith {
#                         $windowsUser = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Login' -ArgumentList @('Server', 'Windows\User1')
#                         $windowsUser = $windowsUser | Add-Member -Name 'Disable' -MemberType ScriptMethod -Value {
#                             $script:mockWasLoginClassMethodDisabledCalled = $true
#                         } -PassThru -Force

#                         return $windowsUser
#                     } -ParameterFilter {
#                         $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Login' -and $ArgumentList[1] -eq 'Windows\UserAbsent'
#                     }-Verifiable

#                     $mockSetTargetResourceParameters = $instanceParameters.Clone()
#                     $mockSetTargetResourceParameters[ 'Ensure' ] = 'Present'
#                     $mockSetTargetResourceParameters[ 'Name' ] = 'Windows\UserAbsent'
#                     $mockSetTargetResourceParameters[ 'Disabled' ] = $true

#                     Set-TargetResource @mockSetTargetResourceParameters
#                     $script:mockWasLoginClassMethodDisabledCalled | Should -Be $true

#                     Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
#                     Assert-MockCalled -CommandName Update-SQLServerLogin  -Scope It -Times 0 -Exactly
#                     Assert-MockCalled -CommandName New-SQLServerLogin  -Scope It -Times 1 -Exactly
#                     Assert-MockCalled -CommandName Remove-SQLServerLogin  -Scope It -Times 0 -Exactly
#                     Assert-MockCalled -CommandName Set-SQLServerLoginPassword  -Scope It -Times 0 -Exactly
#                 }

#                 It 'Should add the specified Windows Group when it is Absent' {
#                     Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

#                     $setTargetResource_WindowsGroupAbsent_EnsurePresent = $setTargetResource_WindowsGroupAbsent.Clone()
#                     $setTargetResource_WindowsGroupAbsent_EnsurePresent[ 'Ensure' ] = 'Present'

#                     Set-TargetResource @setTargetResource_WindowsGroupAbsent_EnsurePresent

#                     Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
#                     Assert-MockCalled -CommandName Update-SQLServerLogin  -Scope It -Times 0 -Exactly
#                     Assert-MockCalled -CommandName New-SQLServerLogin  -Scope It -Times 1 -Exactly
#                     Assert-MockCalled -CommandName Remove-SQLServerLogin  -Scope It -Times 0 -Exactly
#                     Assert-MockCalled -CommandName Set-SQLServerLoginPassword  -Scope It -Times 0 -Exactly
#                 }

#                 It 'Should add the specified SQL Login when it is Absent' {
#                     Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

#                     $setTargetResource_SqlLoginAbsent_EnsurePresent = $setTargetResource_SqlLoginAbsent.Clone()
#                     $setTargetResource_SqlLoginAbsent_EnsurePresent[ 'Ensure' ] = 'Present'
#                     $setTargetResource_SqlLoginAbsent_EnsurePresent[ 'LoginCredential' ] = $mockSqlLoginCredential

#                     Set-TargetResource @setTargetResource_SqlLoginAbsent_EnsurePresent

#                     Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
#                     Assert-MockCalled -CommandName Update-SQLServerLogin  -Scope It -Times 0 -Exactly
#                     Assert-MockCalled -CommandName New-SQLServerLogin  -Scope It -Times 1 -Exactly
#                     Assert-MockCalled -CommandName Remove-SQLServerLogin  -Scope It -Times 0 -Exactly
#                     Assert-MockCalled -CommandName Set-SQLServerLoginPassword  -Scope It -Times 0 -Exactly
#                 }

#                 It 'Should add the specified SQL Login when it is Absent and MustChangePassword is $false' {
#                     Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

#                     $setTargetResource_SqlLoginAbsent_EnsurePresent = $setTargetResource_SqlLoginAbsent.Clone()
#                     $setTargetResource_SqlLoginAbsent_EnsurePresent[ 'Ensure' ] = 'Present'
#                     $setTargetResource_SqlLoginAbsent_EnsurePresent[ 'LoginCredential' ] = $mockSqlLoginCredential
#                     $setTargetResource_SqlLoginAbsent_EnsurePresent[ 'LoginMustChangePassword' ] = $false

#                     Set-TargetResource @setTargetResource_SqlLoginAbsent_EnsurePresent

#                     Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
#                     Assert-MockCalled -CommandName Update-SQLServerLogin  -Scope It -Times 0 -Exactly
#                     Assert-MockCalled -CommandName New-SQLServerLogin  -Scope It -Times 1 -Exactly
#                     Assert-MockCalled -CommandName Remove-SQLServerLogin  -Scope It -Times 0 -Exactly
#                     Assert-MockCalled -CommandName Set-SQLServerLoginPassword  -Scope It -Times 0 -Exactly
#                 }

#                 It 'Should throw the correct error when adding an unsupported login type' {
#                     Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

#                     $setTargetResource_CertificateAbsent_EnsurePresent = $setTargetResource_CertificateAbsent.Clone()
#                     $setTargetResource_CertificateAbsent_EnsurePresent[ 'Ensure' ] = 'Present'

#                     $errorMessage = $script:localizedData.LoginTypeNotImplemented -f $setTargetResource_CertificateAbsent_EnsurePresent.LoginType
#                     { Set-TargetResource @setTargetResource_CertificateAbsent_EnsurePresent } | Should -Throw $errorMessage

#                     Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
#                     Assert-MockCalled -CommandName Update-SQLServerLogin  -Scope It -Times 0 -Exactly
#                     Assert-MockCalled -CommandName New-SQLServerLogin  -Scope It -Times 0 -Exactly
#                     Assert-MockCalled -CommandName Remove-SQLServerLogin  -Scope It -Times 0 -Exactly
#                     Assert-MockCalled -CommandName Set-SQLServerLoginPassword  -Scope It -Times 0 -Exactly
#                 }

#                 It 'Should throw the correct error when adding the specified SQL Login when it is Absent and is missing the LoginCredential parameter' {
#                     Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

#                     $setTargetResource_SqlLoginAbsent_EnsurePresent_NoCred = $setTargetResource_SqlLoginAbsent.Clone()
#                     $setTargetResource_SqlLoginAbsent_EnsurePresent_NoCred[ 'Ensure' ] = 'Present'

#                     $errorMessage = $script:localizedData.LoginCredentialNotFound -f $setTargetResource_SqlLoginAbsent_EnsurePresent_NoCred.Name
#                     { Set-TargetResource @setTargetResource_SqlLoginAbsent_EnsurePresent_NoCred } | Should -Throw $errorMessage

#                     Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
#                     Assert-MockCalled -CommandName Update-SQLServerLogin  -Scope It -Times 0 -Exactly
#                     Assert-MockCalled -CommandName New-SQLServerLogin  -Scope It -Times 0 -Exactly
#                     Assert-MockCalled -CommandName Remove-SQLServerLogin  -Scope It -Times 0 -Exactly
#                     Assert-MockCalled -CommandName Set-SQLServerLoginPassword  -Scope It -Times 0 -Exactly
#                 }

#                 It 'Should do nothing if the specified Windows User is Present' {
#                     Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

#                     $setTargetResource_WindowsUserPresent_EnsurePresent = $setTargetResource_WindowsUserPresent.Clone()
#                     $setTargetResource_WindowsUserPresent_EnsurePresent[ 'Ensure' ] = 'Present'

#                     Set-TargetResource @setTargetResource_WindowsUserPresent_EnsurePresent

#                     Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
#                     Assert-MockCalled -CommandName Update-SQLServerLogin  -Scope It -Times 0 -Exactly
#                     Assert-MockCalled -CommandName New-SQLServerLogin  -Scope It -Times 0 -Exactly
#                     Assert-MockCalled -CommandName Remove-SQLServerLogin  -Scope It -Times 0 -Exactly
#                     Assert-MockCalled -CommandName Set-SQLServerLoginPassword  -Scope It -Times 0 -Exactly
#                 }

#                 It 'Should do nothing if the specified Windows Group is Present' {
#                     Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

#                     $setTargetResource_WindowsGroupPresent_EnsurePresent = $setTargetResource_WindowsGroupPresent.Clone()
#                     $setTargetResource_WindowsGroupPresent_EnsurePresent[ 'Ensure' ] = 'Present'

#                     Set-TargetResource @setTargetResource_WindowsGroupPresent_EnsurePresent

#                     Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
#                     Assert-MockCalled -CommandName Update-SQLServerLogin  -Scope It -Times 0 -Exactly
#                     Assert-MockCalled -CommandName New-SQLServerLogin  -Scope It -Times 0 -Exactly
#                     Assert-MockCalled -CommandName Remove-SQLServerLogin  -Scope It -Times 0 -Exactly
#                     Assert-MockCalled -CommandName Set-SQLServerLoginPassword  -Scope It -Times 0 -Exactly
#                 }

#                 It 'Should update the password of the specified SQL Login if it is Present and all parameters match' {
#                     Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

#                     $setTargetResource_SqlLoginPresent_EnsurePresent = $setTargetResource_SqlLoginPresent.Clone()
#                     $setTargetResource_SqlLoginPresent_EnsurePresent[ 'Ensure' ] = 'Present'
#                     $setTargetResource_SqlLoginPresent_EnsurePresent[ 'LoginCredential' ] = $mockSqlLoginCredential
#                     $setTargetResource_SqlLoginPresent_EnsurePresent[ 'LoginMustChangePassword' ] = $false  # Stays the same

#                     Set-TargetResource @setTargetResource_SqlLoginPresent_EnsurePresent

#                     Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
#                     Assert-MockCalled -CommandName Update-SQLServerLogin  -Scope It -Times 0 -Exactly
#                     Assert-MockCalled -CommandName New-SQLServerLogin  -Scope It -Times 0 -Exactly
#                     Assert-MockCalled -CommandName Remove-SQLServerLogin  -Scope It -Times 0 -Exactly
#                     Assert-MockCalled -CommandName Set-SQLServerLoginPassword  -Scope It -Times 1 -Exactly
#                 }

#                 It 'Should set DefaultDatabase on the specified SQL Login if it does not match the DefaultDatabase parameter' {
#                     Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

#                     $setTargetResource_SqlLoginPresent_EnsurePresent_LoginDefaultDatabase = $setTargetResource_SqlLoginPresent.Clone()
#                     $setTargetResource_SqlLoginPresent_EnsurePresent_LoginDefaultDatabase[ 'Ensure' ] = 'Present'
#                     $setTargetResource_SqlLoginPresent_EnsurePresent_LoginDefaultDatabase[ 'LoginCredential' ] = $mockSqlLoginCredential
#                     $setTargetResource_SqlLoginPresent_EnsurePresent_LoginDefaultDatabase[ 'LoginMustChangePassword' ] = $false  # Stays the same
#                     $setTargetResource_SqlLoginPresent_EnsurePresent_LoginDefaultDatabase[ 'DefaultDatabase' ] = 'notmaster'

#                     Set-TargetResource @setTargetResource_SqlLoginPresent_EnsurePresent_LoginDefaultDatabase

#                     Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
#                     Assert-MockCalled -CommandName Update-SQLServerLogin  -Scope It -Times 1 -Exactly
#                 }

#                 It 'Should set PasswordExpirationEnabled on the specified SQL Login if it does not match the LoginPasswordExpirationEnabled parameter' {
#                     Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

#                     $setTargetResource_SqlLoginPresent_EnsurePresent_LoginPasswordExpirationEnabled = $setTargetResource_SqlLoginPresent.Clone()
#                     $setTargetResource_SqlLoginPresent_EnsurePresent_LoginPasswordExpirationEnabled[ 'Ensure' ] = 'Present'
#                     $setTargetResource_SqlLoginPresent_EnsurePresent_LoginPasswordExpirationEnabled[ 'LoginCredential' ] = $mockSqlLoginCredential
#                     $setTargetResource_SqlLoginPresent_EnsurePresent_LoginPasswordExpirationEnabled[ 'LoginMustChangePassword' ] = $false # Stays the same
#                     $setTargetResource_SqlLoginPresent_EnsurePresent_LoginPasswordExpirationEnabled[ 'LoginPasswordExpirationEnabled' ] = $false

#                     Set-TargetResource @setTargetResource_SqlLoginPresent_EnsurePresent_LoginPasswordExpirationEnabled

#                     Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
#                     Assert-MockCalled -CommandName Update-SQLServerLogin  -Scope It -Times 1 -Exactly
#                     Assert-MockCalled -CommandName New-SQLServerLogin  -Scope It -Times 0 -Exactly
#                     Assert-MockCalled -CommandName Remove-SQLServerLogin  -Scope It -Times 0 -Exactly
#                     Assert-MockCalled -CommandName Set-SQLServerLoginPassword  -Scope It -Times 1 -Exactly
#                 }

#                 It 'Should set PasswordPolicyEnforced on the specified SQL Login if it does not match the LoginPasswordPolicyEnforced parameter' {
#                     Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

#                     $setTargetResource_SqlLoginPresent_EnsurePresent_LoginPasswordPolicyEnforced = $setTargetResource_SqlLoginPresent.Clone()
#                     $setTargetResource_SqlLoginPresent_EnsurePresent_LoginPasswordPolicyEnforced[ 'Ensure' ] = 'Present'
#                     $setTargetResource_SqlLoginPresent_EnsurePresent_LoginPasswordPolicyEnforced[ 'LoginCredential' ] = $mockSqlLoginCredential
#                     $setTargetResource_SqlLoginPresent_EnsurePresent_LoginPasswordPolicyEnforced[ 'LoginMustChangePassword' ] = $false # Stays the same
#                     $setTargetResource_SqlLoginPresent_EnsurePresent_LoginPasswordPolicyEnforced[ 'LoginPasswordPolicyEnforced' ] = $false

#                     Set-TargetResource @setTargetResource_SqlLoginPresent_EnsurePresent_LoginPasswordPolicyEnforced

#                     Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
#                     Assert-MockCalled -CommandName Update-SQLServerLogin  -Scope It -Times 1 -Exactly
#                     Assert-MockCalled -CommandName New-SQLServerLogin  -Scope It -Times 0 -Exactly
#                     Assert-MockCalled -CommandName Remove-SQLServerLogin  -Scope It -Times 0 -Exactly
#                     Assert-MockCalled -CommandName Set-SQLServerLoginPassword  -Scope It -Times 1 -Exactly
#                 }

#                 It 'Should throw the correct error when creating a SQL Login if the LoginMode is ''Integrated''' {
#                     $mockLoginMode = 'Integrated'

#                     Mock -CommandName Connect-SQL -MockWith $mockConnectSQL_LoginMode -Verifiable

#                     $setTargetResource_SqlLoginAbsent_EnsurePresent = $setTargetResource_SqlLoginAbsent.Clone()
#                     $setTargetResource_SqlLoginAbsent_EnsurePresent[ 'Ensure' ] = 'Present'
#                     $setTargetResource_SqlLoginAbsent_EnsurePresent[ 'LoginCredential' ] = $mockSqlLoginCredential

#                     $errorMessage = $script:localizedData.IncorrectLoginMode -f
#                         $setTargetResource_SqlLoginAbsent_EnsurePresent.ServerName,
#                         $setTargetResource_SqlLoginAbsent_EnsurePresent.InstanceName,
#                         $mockLoginMode

#                     { Set-TargetResource @setTargetResource_SqlLoginAbsent_EnsurePresent } | Should -Throw $errorMessage

#                     Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
#                     Assert-MockCalled -CommandName Update-SQLServerLogin  -Scope It -Times 0 -Exactly
#                     Assert-MockCalled -CommandName New-SQLServerLogin  -Scope It -Times 0 -Exactly
#                     Assert-MockCalled -CommandName Remove-SQLServerLogin  -Scope It -Times 0 -Exactly
#                     Assert-MockCalled -CommandName Set-SQLServerLoginPassword  -Scope It -Times 0 -Exactly
#                 }

#                 It 'Should throw the correct error when updating a SQL Login if MustChangePassword is different' {
#                     Mock -CommandName Connect-SQL -MockWith $mockConnectSQL_LoginMode -Verifiable

#                     $setTargetResource_SqlLoginPresent_EnsurePresent = $setTargetResource_SqlLoginPresent.Clone()
#                     $setTargetResource_SqlLoginPresent_EnsurePresent[ 'Ensure' ] = 'Present'
#                     $setTargetResource_SqlLoginPresent_EnsurePresent[ 'LoginCredential' ] = $mockSqlLoginCredential
#                     $setTargetResource_SqlLoginPresent_EnsurePresent[ 'LoginMustChangePassword' ] = $true

#                     $errorMessage = $script:localizedData.MustChangePasswordCannotBeChanged

#                     { Set-TargetResource @setTargetResource_SqlLoginPresent_EnsurePresent } | Should -Throw $errorMessage

#                     Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
#                     Assert-MockCalled -CommandName Update-SQLServerLogin  -Scope It -Times 0 -Exactly
#                     Assert-MockCalled -CommandName New-SQLServerLogin  -Scope It -Times 0 -Exactly
#                     Assert-MockCalled -CommandName Remove-SQLServerLogin  -Scope It -Times 0 -Exactly
#                     Assert-MockCalled -CommandName Set-SQLServerLoginPassword  -Scope It -Times 0 -Exactly
#                 }
#             }

#             It 'Should not throw an error when creating a SQL Login and the LoginMode is set to ''Normal''' {
#                 $mockLoginMode = 'Normal'

#                 Mock -CommandName Connect-SQL -MockWith $mockConnectSQL_LoginMode -Verifiable

#                 $setTargetResource_SqlLoginAbsent_EnsurePresent = $setTargetResource_SqlLoginAbsent.Clone()
#                 $setTargetResource_SqlLoginAbsent_EnsurePresent[ 'Ensure' ] = 'Present'
#                 $setTargetResource_SqlLoginAbsent_EnsurePresent[ 'LoginCredential' ] = $mockSqlLoginCredential

#                 { Set-TargetResource @setTargetResource_SqlLoginAbsent_EnsurePresent } | Should -Not -Throw

#                 Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
#                 Assert-MockCalled -CommandName Update-SQLServerLogin  -Scope It -Times 0 -Exactly
#                 Assert-MockCalled -CommandName New-SQLServerLogin  -Scope It -Times 1 -Exactly
#                 Assert-MockCalled -CommandName Remove-SQLServerLogin  -Scope It -Times 0 -Exactly
#                 Assert-MockCalled -CommandName Set-SQLServerLoginPassword  -Scope It -Times 0 -Exactly
#             }

#             It 'Should not throw an error when creating a SQL Login and the LoginMode is set to ''Mixed''' {
#                 $mockLoginMode = 'Mixed'

#                 Mock -CommandName Connect-SQL -MockWith $mockConnectSQL_LoginMode -Verifiable

#                 $setTargetResource_SqlLoginAbsent_EnsurePresent = $setTargetResource_SqlLoginAbsent.Clone()
#                 $setTargetResource_SqlLoginAbsent_EnsurePresent[ 'Ensure' ] = 'Present'
#                 $setTargetResource_SqlLoginAbsent_EnsurePresent[ 'LoginCredential' ] = $mockSqlLoginCredential

#                 { Set-TargetResource @setTargetResource_SqlLoginAbsent_EnsurePresent } | Should -Not -Throw

#                 Assert-MockCalled -CommandName Connect-SQL -Scope It -Times 1 -Exactly
#                 Assert-MockCalled -CommandName Update-SQLServerLogin  -Scope It -Times 0 -Exactly
#                 Assert-MockCalled -CommandName New-SQLServerLogin  -Scope It -Times 1 -Exactly
#                 Assert-MockCalled -CommandName Remove-SQLServerLogin  -Scope It -Times 0 -Exactly
#                 Assert-MockCalled -CommandName Set-SQLServerLoginPassword  -Scope It -Times 0 -Exactly
#             }
#         }

Describe 'SqlLogin\Update-SQLServerLogin' {
    Context 'When the Login is altered' {
        BeforeEach {
            InModuleScope -ScriptBlock {
                $script:mockMethodAlterWasRun = 0
            }
        }

        It 'Should silently alter the login' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockLogin = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Login' -ArgumentList @('Server', 'Domain\User')

                $mockLogin | Add-Member -MemberType 'ScriptMethod' -Name 'Alter' -Value {
                    $script:mockMethodAlterWasRun += 1
                } -PassThru -Force

                $mockLogin.LoginType = 'WindowsUser'

                { Update-SQLServerLogin -Login $mockLogin } | Should -Not -Throw

                $script:mockMethodAlterWasRun | Should -Be 1
            }
        }

        It 'Should throw the correct error when altering the login fails' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockLogin = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Login' -ArgumentList @('Server', 'Domain\User')
                $mockLogin.LoginType = 'WindowsUser'

                $mockLogin | Add-Member -MemberType 'ScriptMethod' -Name 'Alter' -Value {
                    $script:mockMethodAlterWasRun += 1

                    throw 'Mock method Alter() throw the mocked exception.'
                } -PassThru -Force

                $mockErrorMessage = $script:localizedData.AlterLoginFailed -f $mockLogin.Name

                { Update-SQLServerLogin -Login $mockLogin } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage + '*')

                $script:mockMethodAlterWasRun | Should -Be 1
            }
        }
    }
}

Describe 'SqlLogin\New-SQLServerLogin' {
    Context 'When the Login is created' {
        BeforeEach {
            InModuleScope -ScriptBlock {
                $script:mockMethodCreateWasRun = 0
            }
        }

        It 'Should silently create a Windows login' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockLogin = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Login' -ArgumentList @('Server', 'Domain\User')

                $mockLogin | Add-Member -MemberType 'ScriptMethod' -Name 'Create' -Value {
                    $script:mockMethodCreateWasRun += 1
                } -PassThru -Force

                $mockLogin.LoginType = 'WindowsUser'

                { New-SQLServerLogin -Login $mockLogin } | Should -Not -Throw

                $script:mockMethodCreateWasRun | Should -Be 1
            }
        }

        It 'Should silently create a SQL login' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockLogin = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Login' -ArgumentList @('Server', 'dba')

                $mockLogin | Add-Member -MemberType 'ScriptMethod' -Name 'Create' -Value {
                    $script:mockMethodCreateWasRun += 1
                } -PassThru -Force

                $mockLogin.LoginType = 'SqlLogin'

                $createLoginParameters = @{
                    Login = $mockLogin
                    SecureString = ConvertTo-SecureString -String 'P@ssw0rd-12P@ssw0rd-12' -AsPlainText -Force
                    LoginCreateOptions = 'None'
                }

                { New-SQLServerLogin @createLoginParameters } | Should -Not -Throw

                $script:mockMethodCreateWasRun | Should -Be 1
            }
        }

        It 'Should throw the correct error when login creation fails' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockLogin = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Login' -ArgumentList @('Server', 'Domain\User')

                $mockLogin | Add-Member -MemberType 'ScriptMethod' -Name 'Create' -Value {
                    $script:mockMethodCreateWasRun += 1

                    throw 'Mock method Create() throw the mocked exception.'
                } -PassThru -Force

                $mockLogin.LoginType = 'WindowsUser'

                $mockErrorMessage = $script:localizedData.CreateLoginFailed -f $mockLogin.Name

                { New-SQLServerLogin -Login $mockLogin } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage + '*')

                $script:mockMethodCreateWasRun | Should -Be 1
            }
        }

        <#
            This test i dependent on the stub class Microsoft.SqlServer.Management.Smo.Login
            that is mocked in the stub file SMO.cs. It uses the code in the mocked method
            Create() to throw the correct exceptions (4 levels).
        #>
        It 'Should throw the correct error when password validation fails when creating a SQL Login' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockLogin = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Login' -ArgumentList @('Server', 'dba')

                $mockLogin.LoginType = 'SqlLogin'

                $createLoginParameters = @{
                    Login = $mockLogin
                    SecureString = ConvertTo-SecureString -String 'pw' -AsPlainText -Force
                    LoginCreateOptions = 'None'
                }

                $mockErrorMessage = $script:localizedData.CreateLoginFailedOnPassword -f $mockLogin.Name

                { New-SQLServerLogin @createLoginParameters } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage + '*')
            }
        }

        It 'Should throw the correct error when creating a SQL Login fails' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockLogin = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Login' -ArgumentList @('Server', 'Existing')

                $mockLogin | Add-Member -MemberType 'ScriptMethod' -Name 'Create' -Value {
                    $script:mockMethodCreateWasRun += 1

                    throw 'Mock method Create() throw the mocked exception.'
                } -PassThru -Force

                $mockLogin.LoginType = 'SqlLogin'

                $createLoginParameters = @{
                    Login = $mockLogin
                    SecureString = ConvertTo-SecureString -String 'P@ssw0rd-12P@ssw0rd-12' -AsPlainText -Force
                    LoginCreateOptions = 'None'
                }

                $mockErrorMessage = $script:localizedData.CreateLoginFailed -f $mockLogin.Name

                { New-SQLServerLogin @createLoginParameters } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage + '*')

                $script:mockMethodCreateWasRun | Should -Be 1
            }
        }

        <#
            This test i dependent on the stub class Microsoft.SqlServer.Management.Smo.Login
            that is mocked in the stub file SMO.cs. It uses the code in the mocked method
            Create() to throw the correct exception.
        #>
        It 'Should throw the correct error when creating a SQL Login fails with an unhandled exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockLogin = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Login' -ArgumentList @('Server', 'Unknown')

                $mockLogin.Name = 'Existing'
                $mockLogin.LoginType = 'SqlLogin'

                $createLoginParameters = @{
                    Login = $mockLogin
                    SecureString = ConvertTo-SecureString -String 'P@ssw0rd-12P@ssw0rd-12' -AsPlainText -Force
                    LoginCreateOptions = 'None'
                }

                $mockErrorMessage = $script:localizedData.CreateLoginFailed -f $mockLogin.Name

                { New-SQLServerLogin @createLoginParameters } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage + '*')
            }
        }
    }
}

Describe 'SqlLogin\Remove-SQLServerLogin' {
    Context 'When the Login is dropped' {
        BeforeEach {
            InModuleScope -ScriptBlock {
                $script:mockMethodDropWasRun = 0
            }
        }

        It 'Should silently drop the login' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockLogin = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Login' -ArgumentList @('Server', 'Domain\User')

                $mockLogin | Add-Member -MemberType 'ScriptMethod' -Name 'Drop' -Value {
                    $script:mockMethodDropWasRun += 1
                } -PassThru -Force

                $mockLogin.LoginType = 'WindowsUser'

                { Remove-SQLServerLogin -Login $mockLogin } | Should -Not -Throw

                $script:mockMethodDropWasRun | Should -Be 1
            }
        }

        It 'Should throw the correct error when dropping the login fails' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockLogin = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Login' -ArgumentList @('Server', 'Domain\User')

                $mockLogin | Add-Member -MemberType 'ScriptMethod' -Name 'Drop' -Value {
                    $script:mockMethodDropWasRun += 1

                    throw 'Mock method Drop() throw the mocked exception.'
                } -PassThru -Force

                $mockLogin.LoginType = 'WindowsUser'
                $mockLogin.MockLoginType = 'SqlLogin'

                $mockErrorMessage = $script:localizedData.DropLoginFailed -f $mockLogin.Name

                { Remove-SQLServerLogin -Login $mockLogin } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage + '*')

                $script:mockMethodDropWasRun | Should -Be 1
            }
        }
    }
}

Describe 'SqlLogin\Set-SQLServerLoginPassword' {
    Context 'When the password is set on an existing login' {
        BeforeEach {
            InModuleScope -ScriptBlock {
                $script:mockMethodChangePasswordWasRun = 0
            }
        }

        It 'Should silently set the password' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockLogin = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Login' -ArgumentList @('Server', 'dba')

                $mockLogin | Add-Member -MemberType 'ScriptMethod' -Name 'ChangePassword' -Value {
                    $script:mockMethodChangePasswordWasRun += 1
                } -PassThru -Force

                $setPasswordParameters = @{
                    Login = $mockLogin
                    SecureString = ConvertTo-SecureString -String 'P@ssw0rd-12P@ssw0rd-12' -AsPlainText -Force
                }

                { Set-SQLServerLoginPassword @setPasswordParameters } | Should -Not -Throw

                $mockMethodChangePasswordWasRun | Should -Be 1
            }
        }

        <#
            This test i dependent on the stub class Microsoft.SqlServer.Management.Smo.Login
            that is mocked in the stub file SMO.cs. It uses the code in the mocked method
            ChangePassword() to throw the correct exceptions (4 levels).
        #>
        It 'Should throw the correct error when password validation fails' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setPasswordParameters = @{
                    Login = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Login' -ArgumentList @('Server', 'dba')
                    SecureString = ConvertTo-SecureString -String 'pw' -AsPlainText -Force
                }

                $mockErrorMessage = $script:localizedData.SetPasswordValidationFailed -f $setPasswordParameters.Login.Name

                { Set-SQLServerLoginPassword @setPasswordParameters } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage + '*')
            }
        }

        <#
            This test i dependent on the stub class Microsoft.SqlServer.Management.Smo.Login
            that is mocked in the stub file SMO.cs. It uses the code in the mocked method
            ChangePassword() to throw the correct exception.
        #>
        It 'Should throw the correct error when changing the password fails' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setPasswordParameters = @{
                    Login = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Login' -ArgumentList @('Server', 'dba')
                    SecureString = ConvertTo-SecureString -String 'reused' -AsPlainText -Force
                }

                $mockErrorMessage = $script:localizedData.SetPasswordFailed -f $setPasswordParameters.Login.Name

                { Set-SQLServerLoginPassword @setPasswordParameters } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage + '*')
            }
        }

        <#
            This test i dependent on the stub class Microsoft.SqlServer.Management.Smo.Login
            that is mocked in the stub file SMO.cs. It uses the code in the mocked method
            ChangePassword() to throw the correct exception.
        #>
        It 'Should throw the correct error when changing the password fails' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setPasswordParameters = @{
                    Login = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Login' -ArgumentList @('Server', 'dba')
                    SecureString = ConvertTo-SecureString -String 'other' -AsPlainText -Force
                }

                $mockErrorMessage = $script:localizedData.SetPasswordFailed -f $setPasswordParameters.Login.Name

                { Set-SQLServerLoginPassword @setPasswordParameters } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage + '*')
            }
        }
    }
}

# }
# finally
# {
#     Invoke-TestCleanup
# }
