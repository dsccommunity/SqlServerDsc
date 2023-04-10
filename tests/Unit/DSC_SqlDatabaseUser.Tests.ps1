<#
    .SYNOPSIS
        Unit test for DSC_SqlDatabaseUser DSC resource.
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
    $script:dscResourceName = 'DSC_SqlDatabaseUser'

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

Describe 'SqlDatabaseUser\Get-TargetResource' -Tag 'Get' {
    BeforeAll {
        # Scriptblock for mocked object for mocks of Connect-SQL.
        $mockSqlServerObject = {
            New-Object -TypeName Object |
            Add-Member -MemberType ScriptProperty -Name 'Databases' -Value {
                return @(
                    @{
                        'TestDB' = New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value 'TestDB' -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'IsUpdateable' -Value $true -PassThru |
                        Add-Member -MemberType ScriptProperty -Name 'Users' -Value {
                            return @(
                                @{
                                    'DatabaseUser1' = New-Object -TypeName Object |
                                    Add-Member -MemberType NoteProperty -Name 'Name' -Value 'DatabaseUser1' -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'AsymmetricKey' -Value 'AsymmetricKey1' -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'Certificate' -Value 'Certificate1' -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'AuthenticationType' -Value 'Windows' -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'LoginType' -Value 'WindowsUser' -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'Login' -Value 'CONTOSO\Login1' -PassThru -Force
                                }
                            )
                        } -PassThru -Force
                    }
                )
            } -PassThru -Force
        }

        Mock -CommandName Connect-SQL -MockWith $mockSqlServerObject

        InModuleScope -ScriptBlock {
            # Default parameters that are used for the It-blocks.
            $script:mockDefaultParameters = @{
                Name         = 'DatabaseUser1'
                InstanceName = 'MSSQLSERVER'
                ServerName   = 'localhost'
                DatabaseName = 'TestDB'
            }
        }
    }

    BeforeEach {
        InModuleScope -ScriptBlock {
            $script:mockGetTargetResourceParameters = $script:mockDefaultParameters.Clone()
        }
    }

    AfterEach {
        Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
    }

    Context 'When the system is in the desired state' {
        Context 'When the configuration is absent' {
            BeforeEach {
                InModuleScope -ScriptBlock {
                    $mockGetTargetResourceParameters['Name'] = 'MissingUser1'
                }
            }

            It 'Should return the state as absent' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $getTargetResourceResult = Get-TargetResource @mockGetTargetResourceParameters

                    $getTargetResourceResult.Ensure | Should -Be 'Absent'
                }
            }

            It 'Should return the same values as passed as parameters' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.ServerName | Should -Be $mockGetTargetResourceParameters.ServerName
                    $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                    $result.DatabaseName | Should -Be $mockGetTargetResourceParameters.DatabaseName
                    $result.Name | Should -Be 'MissingUser1'
                }
            }

            It 'Should return $null for the rest of the properties' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $getTargetResourceResult = Get-TargetResource @mockGetTargetResourceParameters

                    $getTargetResourceResult.LoginName | Should -BeNullOrEmpty
                    $getTargetResourceResult.AsymmetricKeyName | Should -BeNullOrEmpty
                    $getTargetResourceResult.CertificateName | Should -BeNullOrEmpty
                    $getTargetResourceResult.AuthenticationType | Should -BeNullOrEmpty
                    $getTargetResourceResult.LoginType | Should -BeNullOrEmpty
                    $getTargetResourceResult.UserType | Should -BeNullOrEmpty
                }
            }

            It 'Should return $true for the property DatabaseIsUpdateable' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $getTargetResourceResult = Get-TargetResource @mockGetTargetResourceParameters

                    $getTargetResourceResult.DatabaseIsUpdateable | Should -BeTrue
                }
            }
        }

        Context 'When the configuration is present' {
            It 'Should return the state as present' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $getTargetResourceResult = Get-TargetResource @mockGetTargetResourceParameters

                    $getTargetResourceResult.Ensure | Should -Be 'Present'
                }
            }

            It 'Should return the same values as passed as parameters' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.ServerName | Should -Be $mockGetTargetResourceParameters.ServerName
                    $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                    $result.DatabaseName | Should -Be $mockGetTargetResourceParameters.DatabaseName
                    $result.Name | Should -Be $mockGetTargetResourceParameters.Name
                }
            }

            It 'Should return the correct values for the rest of the properties' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $getTargetResourceResult = Get-TargetResource @mockGetTargetResourceParameters

                    $getTargetResourceResult.LoginName | Should -Be 'CONTOSO\Login1'
                    $getTargetResourceResult.AsymmetricKeyName | Should -Be 'AsymmetricKey1'
                    $getTargetResourceResult.CertificateName | Should -Be 'Certificate1'
                    $getTargetResourceResult.AuthenticationType | Should -Be 'Windows'
                    $getTargetResourceResult.LoginType | Should -Be 'WindowsUser'
                    $getTargetResourceResult.UserType | Should -Be 'Login'
                }
            }

            It 'Should return $true for the property DatabaseIsUpdateable' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $getTargetResourceResult = Get-TargetResource @mockGetTargetResourceParameters

                    $getTargetResourceResult.DatabaseIsUpdateable | Should -BeTrue
                }
            }
        }
    }

    Context 'When the system is not in the desired state' {
        Context 'When the database name does not exist' {
            BeforeEach {
                InModuleScope -ScriptBlock {
                    $mockGetTargetResourceParameters['DatabaseName'] = 'MissingDatabase1'
                    $mockGetTargetResourceParameters['Name'] = 'MissingUser1'
                }
            }

            It 'Should throw the correct error' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockErrorMessage = $script:localizedData.DatabaseNotFound -f 'MissingDatabase1'

                    {
                        Get-TargetResource @mockGetTargetResourceParameters
                    } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage)
                }
            }
        }
    }
}

Describe 'SqlDatabaseUser\Test-TargetResource' -Tag 'Test' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            # Default parameters that are used for the It-blocks.
            $script:mockDefaultParameters = @{
                Name         = 'DatabaseUser1'
                InstanceName = 'MSSQLSERVER'
                ServerName   = 'localhost'
                DatabaseName = 'TestDB'
            }
        }
    }

    BeforeEach {
        InModuleScope -ScriptBlock {
            $script:mockTestTargetResourceParameters = $script:mockDefaultParameters.Clone()
        }
    }

    Context 'When the system is in the desired state' {
        Context 'When the configuration is absent' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Ensure             = 'Absent'
                        Name               = 'DatabaseUser1'
                        ServerName         = 'localhost'
                        InstanceName       = 'MSSQLSERVER'
                        DatabaseName       = 'TestDB'
                        LoginName          = $null
                        AsymmetricKeyName  = $null
                        CertificateName    = $null
                        UserType           = $null
                        AuthenticationType = $null
                        LoginType          = $null
                    }
                }
            }

            BeforeEach {
                InModuleScope -ScriptBlock {
                    $mockTestTargetResourceParameters['Ensure'] = 'Absent'
                }
            }

            It 'Should return the state as $true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testTargetResourceResult = Test-TargetResource @mockTestTargetResourceParameters

                    $testTargetResourceResult | Should -BeTrue
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the configuration is present' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Ensure             = 'Present'
                        Name               = 'DatabaseUser1'
                        ServerName         = 'localhost'
                        InstanceName       = 'MSSQLSERVER'
                        DatabaseName       = 'TestDB'
                        LoginName          = 'CONTOSO\Login1'
                        AsymmetricKeyName  = $null
                        CertificateName    = $null
                        UserType           = 'Login'
                        AuthenticationType = 'Windows'
                        LoginType          = 'WindowsUser'
                    }
                }
            }

            BeforeEach {
                InModuleScope -ScriptBlock {
                    $mockTestTargetResourceParameters['UserType'] = 'Login'
                    $mockTestTargetResourceParameters['LoginName'] = 'CONTOSO\Login1'
                }
            }

            It 'Should return the state as $true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testTargetResourceResult = Test-TargetResource @mockTestTargetResourceParameters

                    $testTargetResourceResult | Should -BeTrue
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the database is not updatable' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Ensure               = 'Present'
                        Name                 = 'DatabaseUser1'
                        ServerName           = 'localhost'
                        InstanceName         = 'MSSQLSERVER'
                        DatabaseName         = 'TestDB'
                        DatabaseIsUpdateable = $false
                        LoginName            = 'CONTOSO\Login1'
                        AsymmetricKeyName    = $null
                        CertificateName      = $null
                        UserType             = 'Login'
                        AuthenticationType   = 'Windows'
                        LoginType            = 'WindowsUser'
                    }
                }
            }

            BeforeEach {
                InModuleScope -ScriptBlock {
                    $mockTestTargetResourceParameters['UserType'] = 'Login'
                    $mockTestTargetResourceParameters['LoginName'] = 'CONTOSO\Login1'
                }
            }

            It 'Should return the state as $true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testTargetResourceResult = Test-TargetResource @mockTestTargetResourceParameters

                    $testTargetResourceResult | Should -BeTrue
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When the system is not in the desired state' {
        Context 'When the configuration should be absent' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Ensure = 'Present'
                    }
                }
            }

            BeforeEach {
                InModuleScope -ScriptBlock {
                    $mockTestTargetResourceParameters['Ensure'] = 'Absent'
                }
            }

            It 'Should return the state as $false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testTargetResourceResult = Test-TargetResource @mockTestTargetResourceParameters

                    $testTargetResourceResult | Should -BeFalse
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the configuration should be present' {
            Context 'When the property LoginName is not in desired state' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure            = 'Present'
                            LoginName         = 'OtherLogin1'
                            AsymmetricKeyName = $null
                            CertificateName   = $null
                            UserType          = 'Login'
                        }
                    }
                }

                BeforeEach {
                    InModuleScope -ScriptBlock {
                        $mockTestTargetResourceParameters['LoginName'] = 'CONTOSO\Login1'
                        $mockTestTargetResourceParameters['UserType'] = 'Login'
                    }
                }

                It 'Should return the state as $false' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $testTargetResourceResult = Test-TargetResource @mockTestTargetResourceParameters

                        $testTargetResourceResult | Should -BeFalse
                    }

                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the property AsymmetricKeyName is not in desired state' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure            = 'Present'
                            LoginName         = $null
                            AsymmetricKeyName = 'OtherAsymmetricKey1'
                            CertificateName   = $null
                            UserType          = 'AsymmetricKey'
                        }
                    }
                }

                BeforeEach {
                    InModuleScope -ScriptBlock {
                        $mockTestTargetResourceParameters['AsymmetricKeyName'] = 'AsymmetricKey1'
                        $mockTestTargetResourceParameters['UserType'] = 'AsymmetricKey'
                    }
                }

                It 'Should return the state as $false' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $testTargetResourceResult = Test-TargetResource @mockTestTargetResourceParameters
                        $testTargetResourceResult | Should -BeFalse
                    }

                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the property CertificateName is not in desired state' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure            = 'Present'
                            LoginName         = $null
                            AsymmetricKeyName = $null
                            CertificateName   = 'OtherCertificate1'
                            UserType          = 'Certificate'
                        }
                    }
                }

                BeforeEach {
                    InModuleScope -ScriptBlock {
                        $mockTestTargetResourceParameters['CertificateName'] = 'Certificate1'
                        $mockTestTargetResourceParameters['UserType'] = 'Certificate'
                    }
                }

                It 'Should return the state as $false' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $testTargetResourceResult = Test-TargetResource @mockTestTargetResourceParameters

                        $testTargetResourceResult | Should -BeFalse
                    }

                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the property UserType is not in desired state' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure            = 'Present'
                            LoginName         = $null
                            AsymmetricKeyName = $null
                            CertificateName   = 'OtherCertificate1'
                            UserType          = 'Certificate'
                        }
                    }
                }

                BeforeEach {
                    InModuleScope -ScriptBlock {
                        $mockTestTargetResourceParameters['LoginName'] = 'CONTOSO\Login1'
                        $mockTestTargetResourceParameters['UserType'] = 'Login'
                    }
                }

                It 'Should return the state as $false' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $testTargetResourceResult = Test-TargetResource @mockTestTargetResourceParameters

                        $testTargetResourceResult | Should -BeFalse
                    }

                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the database is not updatable' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure            = 'Present'
                            LoginName         = 'OtherLogin1'
                            AsymmetricKeyName = $null
                            CertificateName   = $null
                            UserType          = 'Login'
                            DatabaseIsUpdateable = $false
                        }
                    }
                }

                BeforeEach {
                    InModuleScope -ScriptBlock {
                        $mockTestTargetResourceParameters['LoginName'] = 'CONTOSO\Login1'
                        $mockTestTargetResourceParameters['UserType'] = 'Login'
                    }
                }

                It 'Should return the state as $true' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $testTargetResourceResult = Test-TargetResource @mockTestTargetResourceParameters

                        $testTargetResourceResult | Should -BeTrue
                    }

                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                }
            }
        }
    }
}

Describe 'DSC_SqlDatabaseUser\Set-TargetResource' -Tag 'Set' {
    BeforeAll {
        Mock -CommandName Invoke-SqlDscQuery
        Mock -CommandName Assert-SqlLogin
        Mock -CommandName Assert-DatabaseAsymmetricKey
        Mock -CommandName Assert-DatabaseCertificate

        InModuleScope -ScriptBlock {
            # Default parameters that are used for the It-blocks.
            $script:mockDefaultParameters = @{
                Name         = 'DatabaseUser1'
                InstanceName = 'MSSQLSERVER'
                ServerName   = 'localhost'
                DatabaseName = 'TestDB'
            }
        }
    }

    BeforeEach {
        InModuleScope -ScriptBlock {
            $script:mockSetTargetResourceParameters = $script:mockDefaultParameters.Clone()
        }
    }

    Context 'When the system is in the desired state' {
        Context 'When the configuration is absent' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Ensure             = 'Absent'
                        Name               = 'DatabaseUser1'
                        ServerName         = 'localhost'
                        InstanceName       = 'MSSQLSERVER'
                        DatabaseName       = 'TestDB'
                        LoginName          = $null
                        AsymmetricKeyName  = $null
                        CertificateName    = $null
                        UserType           = $null
                        AuthenticationType = $null
                        LoginType          = $null
                    }
                }
            }

            BeforeEach {
                InModuleScope -ScriptBlock {
                    $mockSetTargetResourceParameters['Ensure'] = 'Absent'
                }
            }

            It 'Should not throw and should call the correct mocks' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It
            }
        }

        Context 'When the configuration is present' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Ensure             = 'Present'
                        Name               = 'DatabaseUser1'
                        ServerName         = 'localhost'
                        InstanceName       = 'MSSQLSERVER'
                        DatabaseName       = 'TestDB'
                        LoginName          = 'CONTOSO\Login1'
                        AsymmetricKeyName  = $null
                        CertificateName    = $null
                        UserType           = 'Login'
                        AuthenticationType = 'Windows'
                        LoginType          = 'WindowsUser'
                    }
                }
            }

            BeforeEach {
                InModuleScope -ScriptBlock {
                    $mockSetTargetResourceParameters['UserType'] = 'Login'
                    $mockSetTargetResourceParameters['LoginName'] = 'CONTOSO\Login1'
                }
            }

            It 'Should not throw and should call the correct mocks' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It
            }
        }
    }

    Context 'When the system is not in the desired state' {
        Context 'When the configuration should be absent' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Ensure             = 'Present'
                        Name               = 'DatabaseUser1'
                        ServerName         = 'localhost'
                        InstanceName       = 'MSSQLSERVER'
                        DatabaseName       = 'TestDB'
                        LoginName          = 'CONTOSO\Login1'
                        AsymmetricKeyName  = $null
                        CertificateName    = $null
                        UserType           = 'Login'
                        AuthenticationType = 'Windows'
                        LoginType          = 'WindowsUser'
                    }
                }
            }

            BeforeEach {
                InModuleScope -ScriptBlock {
                    $mockSetTargetResourceParameters['Ensure'] = 'Absent'
                }
            }

            It 'Should not throw and should call the correct mocks' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Invoke-SqlDscQuery -ParameterFilter {
                    $Query -eq ('DROP USER [{0}];' -f 'DatabaseUser1')
                } -Exactly -Times 1 -Scope It
            }

            Context 'When trying to drop a database user but Invoke-SqlDscQuery fails' {
                BeforeAll {
                    Mock -CommandName Invoke-SqlDscQuery -MockWith {
                        throw
                    }
                }

                BeforeEach {
                    InModuleScope -ScriptBlock {
                        $mockSetTargetResourceParameters['Ensure'] = 'Absent'
                    }
                }

                It 'Should throw the correct error' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $mockErrorMessage = $script:localizedData.FailedDropDatabaseUser -f 'DatabaseUser1', 'TestDB'
                        {
                            Set-TargetResource @mockSetTargetResourceParameters
                        } | Should -Throw ('*' + $mockErrorMessage + '*')
                    }

                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 1 -Scope It
                }
            }
        }

        Context 'When the configuration should be present' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Ensure             = 'Absent'
                        Name               = 'DatabaseUser1'
                        ServerName         = 'localhost'
                        InstanceName       = 'MSSQLSERVER'
                        DatabaseName       = 'TestDB'
                        LoginName          = $null
                        AsymmetricKeyName  = $null
                        CertificateName    = $null
                        UserType           = $null
                        AuthenticationType = $null
                        LoginType          = $null
                    }
                }
            }

            Context 'When creating a database user with a login' {
                Context 'When calling an using the default ServerName' {
                    BeforeEach {
                        InModuleScope -ScriptBlock {
                            $mockSetTargetResourceParameters['LoginName'] = 'CONTOSO\Login1'
                            $mockSetTargetResourceParameters['UserType'] = 'Login'

                            <#
                                Make sure to use the default value for ServerName.
                                Regression test for issue #1647.
                            #>
                            $mockSetTargetResourceParameters.Remove('ServerName')
                        }
                    }

                    It 'Should not throw and should call the correct mocks' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                        }

                        Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                        Should -Invoke -CommandName Invoke-SqlDscQuery -ParameterFilter {
                            $Query -eq ('CREATE USER [{0}] FOR LOGIN [{1}];' -f 'DatabaseUser1', 'CONTOSO\Login1')
                        } -Exactly -Times 1 -Scope It

                        Should -Invoke -CommandName Assert-SqlLogin -ParameterFilter {
                            $ServerName -eq (Get-ComputerName)
                        } -Exactly -Times 1 -Scope It
                    }
                }

                Context 'When calling with an explicit ServerName' {
                    BeforeEach {
                        InModuleScope -ScriptBlock {
                            $mockSetTargetResourceParameters['LoginName'] = 'CONTOSO\Login1'
                            $mockSetTargetResourceParameters['UserType'] = 'Login'

                            <#
                                Set an explicit value for ServerName.
                                Regression test for issue #1647.
                            #>
                            $mockSetTargetResourceParameters['ServerName'] = 'host.company.local'
                        }
                    }

                    It 'Should not throw and should call the correct mocks' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                        }

                        Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                        Should -Invoke -CommandName Invoke-SqlDscQuery -ParameterFilter {
                            $Query -eq ('CREATE USER [{0}] FOR LOGIN [{1}];' -f 'DatabaseUser1', 'CONTOSO\Login1')
                        } -Exactly -Times 1 -Scope It

                        Should -Invoke -CommandName Assert-SqlLogin -ParameterFilter {
                            $ServerName -eq 'host.company.local'
                        } -Exactly -Times 1 -Scope It
                    }
                }
            }

            Context 'When creating a database user without a login' {
                BeforeEach {
                    InModuleScope -ScriptBlock {
                        $mockSetTargetResourceParameters['UserType'] = 'NoLogin'
                    }
                }

                It 'Should not throw and should call the correct mocks' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                    }

                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName Invoke-SqlDscQuery -ParameterFilter {
                        $Query -eq ('CREATE USER [{0}] WITHOUT LOGIN;' -f 'DatabaseUser1')
                    } -Exactly -Times 1 -Scope It
                }
            }

            Context 'When creating a database user mapped to a certificate' {
                BeforeEach {
                    InModuleScope -ScriptBlock {
                        $mockSetTargetResourceParameters['CertificateName'] = 'Certificate1'
                        $mockSetTargetResourceParameters['UserType'] = 'Certificate'
                    }
                }

                It 'Should not throw and should call the correct mocks' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                    }

                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName Invoke-SqlDscQuery -ParameterFilter {
                        $Query -eq ('CREATE USER [{0}] FOR CERTIFICATE [{1}];' -f 'DatabaseUser1', 'Certificate1')
                    } -Exactly -Times 1 -Scope It
                }
            }

            Context 'When creating a database user mapped to an asymmetric key' {
                BeforeEach {
                    InModuleScope -ScriptBlock {
                        $mockSetTargetResourceParameters['AsymmetricKeyName'] = 'AsymmetricKey1'
                        $mockSetTargetResourceParameters['UserType'] = 'AsymmetricKey'
                    }
                }

                It 'Should not throw and should call the correct mocks' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                    }

                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName Invoke-SqlDscQuery -ParameterFilter {
                        $Query -eq ('CREATE USER [{0}] FOR ASYMMETRIC KEY [{1}];' -f 'DatabaseUser1', 'AsymmetricKey1')
                    } -Exactly -Times 1 -Scope It
                }
            }

            Context 'When trying to create a database user but Invoke-SqlDscQuery fails' {
                BeforeAll {
                    Mock -CommandName Invoke-SqlDscQuery -MockWith {
                        throw
                    }
                }

                BeforeEach {
                    InModuleScope -ScriptBlock {
                        $mockSetTargetResourceParameters['UserType'] = 'NoLogin'
                    }
                }

                It 'Should throw the correct error' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $mockErrorMessage = $script:localizedData.FailedCreateDatabaseUser -f 'DatabaseUser1', 'TestDB', 'NoLogin'

                        {
                            Set-TargetResource @mockSetTargetResourceParameters
                        } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage + '*')
                    }

                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 1 -Scope It
                }
            }
        }

        Context 'When properties are not in desired state' {
            Context 'When the database user has the wrong login name' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure             = 'Present'
                            Name               = 'DatabaseUser1'
                            ServerName         = 'localhost'
                            InstanceName       = 'MSSQLSERVER'
                            DatabaseName       = 'TestDB'
                            LoginName          = 'CONTOSO\Login1'
                            AsymmetricKeyName  = $null
                            CertificateName    = $null
                            UserType           = 'Login'
                            AuthenticationType = 'Windows'
                            LoginType          = 'WindowsUser'
                        }
                    }
                }

                Context 'When calling an using the default ServerName' {
                    BeforeEach {
                        InModuleScope -ScriptBlock {
                            $mockSetTargetResourceParameters['LoginName'] = 'OtherLogin1'
                            $mockSetTargetResourceParameters['UserType'] = 'Login'

                            <#
                                Make sure to use the default value for ServerName.
                                Regression test for issue #1647.
                            #>
                            $mockSetTargetResourceParameters.Remove('ServerName')
                        }
                    }

                    It 'Should not throw and should call the correct mocks' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                                { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                        }

                        Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                        Should -Invoke -CommandName Invoke-SqlDscQuery -ParameterFilter {
                            $Query -eq ('ALTER USER [{0}] WITH NAME = [{1}], LOGIN = [{2}];' -f 'DatabaseUser1', 'DatabaseUser1', 'OtherLogin1')
                        } -Exactly -Times 1 -Scope It

                        Should -Invoke -CommandName Assert-SqlLogin -ParameterFilter {
                            $ServerName -eq (Get-ComputerName)
                        } -Exactly -Times 1 -Scope It
                    }
                }

                Context 'When calling with an explicit ServerName' {
                    BeforeEach {
                        InModuleScope -ScriptBlock {
                            $mockSetTargetResourceParameters['LoginName'] = 'OtherLogin1'
                            $mockSetTargetResourceParameters['UserType'] = 'Login'

                            <#
                                Set an explicit value for ServerName.
                                Regression test for issue #1647.
                            #>
                            $mockSetTargetResourceParameters['ServerName'] = 'host.company.local'
                        }
                    }

                    It 'Should not throw and should call the correct mocks' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                                { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                        }

                        Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                        Should -Invoke -CommandName Invoke-SqlDscQuery -ParameterFilter {
                            $Query -eq ('ALTER USER [{0}] WITH NAME = [{1}], LOGIN = [{2}];' -f 'DatabaseUser1', 'DatabaseUser1', 'OtherLogin1')
                        } -Exactly -Times 1 -Scope It

                        Should -Invoke -CommandName Assert-SqlLogin -ParameterFilter {
                            $ServerName -eq 'host.company.local'
                        } -Exactly -Times 1 -Scope It
                    }
                }

                Context 'When trying to alter the login name but Invoke-SqlDscQuery fails' {
                    BeforeAll {
                        Mock -CommandName Invoke-SqlDscQuery -MockWith {
                            throw
                        }
                    }

                    BeforeEach {
                        InModuleScope -ScriptBlock {
                            $mockSetTargetResourceParameters['LoginName'] = 'OtherLogin1'
                            $mockSetTargetResourceParameters['UserType'] = 'Login'
                        }
                    }

                    It 'Should throw the correct error' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $mockErrorMessage = $script:localizedData.FailedUpdateDatabaseUser -f 'DatabaseUser1', 'TestDB', 'Login'
                            {
                                Set-TargetResource @mockSetTargetResourceParameters
                            } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage + '*')
                        }

                        Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                        Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 1 -Scope It
                    }
                }
            }

            Context 'When the database user has the wrong asymmetric key name' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure             = 'Present'
                            Name               = 'DatabaseUser1'
                            ServerName         = 'localhost'
                            InstanceName       = 'MSSQLSERVER'
                            DatabaseName       = 'TestDB'
                            LoginName          = 'CONTOSO\Login1'
                            AsymmetricKeyName  = 'AsymmetricKey1'
                            CertificateName    = $null
                            UserType           = 'AsymmetricKey'
                            AuthenticationType = 'Windows'
                            LoginType          = 'AsymmetricKey'
                        }
                    }
                }

                BeforeEach {
                    InModuleScope -ScriptBlock {
                        $mockSetTargetResourceParameters['AsymmetricKeyName'] = 'OtherAsymmetricKey1'
                        $mockSetTargetResourceParameters['UserType'] = 'AsymmetricKey'
                        $mockSetTargetResourceParameters['Force'] = $true
                    }
                }

                It 'Should not throw and should call the correct mocks' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                    }

                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It

                    Should -Invoke -CommandName Invoke-SqlDscQuery -ParameterFilter {
                        $Query -eq ('DROP USER [{0}];' -f 'DatabaseUser1')
                    } -Exactly -Times 1 -Scope It

                    Should -Invoke -CommandName Invoke-SqlDscQuery -ParameterFilter {
                        $Query -eq ('CREATE USER [{0}] FOR ASYMMETRIC KEY [{1}];' -f 'DatabaseUser1', 'OtherAsymmetricKey1')
                    } -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the database user has the wrong certificate name' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure             = 'Present'
                            Name               = 'DatabaseUser1'
                            ServerName         = 'localhost'
                            InstanceName       = 'MSSQLSERVER'
                            DatabaseName       = 'TestDB'
                            LoginName          = 'CONTOSO\Login1'
                            AsymmetricKeyName  = 'AsymmetricKey1'
                            CertificateName    = $null
                            UserType           = 'Certificate'
                            AuthenticationType = 'Windows'
                            LoginType          = 'Certificate'
                        }
                    }
                }

                BeforeEach {
                    InModuleScope -ScriptBlock {
                        $mockSetTargetResourceParameters['CertificateName'] = 'OtherCertificate1'
                        $mockSetTargetResourceParameters['UserType'] = 'Certificate'
                        $mockSetTargetResourceParameters['Force'] = $true
                    }
                }

                It 'Should not throw and should call the correct mocks' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                    }

                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It

                    Should -Invoke -CommandName Invoke-SqlDscQuery -ParameterFilter {
                        $Query -eq ('DROP USER [{0}];' -f 'DatabaseUser1')
                    } -Exactly -Times 1 -Scope It

                    Should -Invoke -CommandName Invoke-SqlDscQuery -ParameterFilter {
                        $Query -eq ('CREATE USER [{0}] FOR CERTIFICATE [{1}];' -f 'DatabaseUser1', 'OtherCertificate1')
                    } -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the database user has the wrong certificate name' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure             = 'Present'
                            Name               = 'DatabaseUser1'
                            ServerName         = 'localhost'
                            InstanceName       = 'MSSQLSERVER'
                            DatabaseName       = 'TestDB'
                            LoginName          = 'CONTOSO\Login1'
                            AsymmetricKeyName  = 'AsymmetricKey1'
                            CertificateName    = $null
                            UserType           = 'Certificate'
                            AuthenticationType = 'Windows'
                            LoginType          = 'Certificate'
                        }
                    }
                }

                BeforeEach {
                    InModuleScope -ScriptBlock {
                        $mockSetTargetResourceParameters['LoginName'] = 'OtherLogin1'
                        $mockSetTargetResourceParameters['UserType'] = 'Login'
                        $mockSetTargetResourceParameters['Force'] = $true
                    }
                }

                It 'Should not throw and should call the correct mocks' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                    }

                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It

                    Should -Invoke -CommandName Invoke-SqlDscQuery -ParameterFilter {
                        $Query -eq ('DROP USER [{0}];' -f 'DatabaseUser1')
                    } -Exactly -Times 1 -Scope It

                    Should -Invoke -CommandName Invoke-SqlDscQuery -ParameterFilter {
                        $Query -eq ('CREATE USER [{0}] FOR LOGIN [{1}];' -f 'DatabaseUser1', 'OtherLogin1')
                    } -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the configuration has not opt-in to re-create a database user' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure             = 'Present'
                            Name               = 'DatabaseUser1'
                            ServerName         = 'localhost'
                            InstanceName       = 'MSSQLSERVER'
                            DatabaseName       = 'TestDB'
                            LoginName          = 'CONTOSO\Login1'
                            AsymmetricKeyName  = 'AsymmetricKey1'
                            CertificateName    = $null
                            UserType           = 'Certificate'
                            AuthenticationType = 'Windows'
                            LoginType          = 'Certificate'
                        }
                    }
                }

                BeforeEach {
                    InModuleScope -ScriptBlock {
                        $mockSetTargetResourceParameters['LoginName'] = 'OtherLogin1'
                        $mockSetTargetResourceParameters['UserType'] = 'Login'
                    }
                }

                It 'Should not throw and should call the correct mocks' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $mockErrorMessage = $script:localizedData.ForceNotEnabled

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage)
                    }

                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName Invoke-SqlDscQuery -Exactly -Times 0 -Scope It
                }
            }
        }
    }
}

Describe 'Assert-Parameters' -Tag 'Helper' {
    Context 'When parameter LoginName is provided, but with the wrong user type' {
        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockErrorMessage = $script:localizedData.LoginNameProvidedWithWrongUserType -f 'NoLogin'

                {
                    Assert-Parameters -LoginName 'AnyValue' -UserType 'NoLogin'
                } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage + " (Parameter 'Action')")
            }
        }
    }

    Context 'When parameter CertificateName is provided, but with the wrong user type' {
        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockErrorMessage = $script:localizedData.CertificateNameProvidedWithWrongUserType -f 'NoLogin'

                {
                    Assert-Parameters -CertificateName 'AnyValue' -UserType 'NoLogin'
                } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage + " (Parameter 'Action')")
            }
        }
    }

    Context 'When parameter AsymmetricKeyName is provided, but with the wrong user type' {
        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockErrorMessage = $script:localizedData.AsymmetricKeyNameProvidedWithWrongUserType -f 'NoLogin'

                {
                    Assert-Parameters -AsymmetricKeyName 'AnyValue' -UserType 'NoLogin'
                } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage + " (Parameter 'Action')")
            }
        }
    }

    Context 'When parameter LoginName is not provided when providing the user type ''Login''' {
        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockErrorMessage = $script:localizedData.LoginUserTypeWithoutLoginName -f 'Login'

                {
                    Assert-Parameters -UserType 'Login'
                } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage + " (Parameter 'Action')")
            }
        }
    }

    Context 'When parameter AsymmetricKeyName is not provide when providing the user type ''AsymmetricKey''' {
        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockErrorMessage = $script:localizedData.AsymmetricKeyUserTypeWithoutAsymmetricKeyName -f 'AsymmetricKey'

                {
                    Assert-Parameters -UserType 'AsymmetricKey'
                } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage + " (Parameter 'Action')")
            }
        }
    }

    Context 'When parameter CertificateName is not provide when providing the user type ''Certificate''' {
        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockErrorMessage = $script:localizedData.CertificateUserTypeWithoutCertificateName -f 'Certificate'

                {
                    Assert-Parameters -UserType 'Certificate'
                } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage + " (Parameter 'Action')")
            }
        }
    }
}

Describe 'ConvertTo-UserType' -Tag 'Helper' {
    Context 'When converting to a user type' {
        It 'Should return the correct value when converting authentication type <AuthenticationType> and login type <LoginType>' -ForEach @(
            @{
                AuthenticationType = 'Windows'
                LoginType          = 'WindowsUser'
                ExpectedResult     = 'Login'
            }
            @{
                AuthenticationType = 'Windows'
                LoginType          = 'WindowsGroup'
                ExpectedResult     = 'Login'
            }
            @{
                AuthenticationType = 'Instance'
                LoginType          = 'SqlLogin'
                ExpectedResult     = 'Login'
            }
            @{
                AuthenticationType = 'None'
                LoginType          = 'SqlLogin'
                ExpectedResult     = 'NoLogin'
            }
            @{
                AuthenticationType = 'None'
                LoginType          = 'AsymmetricKey'
                ExpectedResult     = 'AsymmetricKey'
            }
            @{
                AuthenticationType = 'None'
                LoginType          = 'Certificate'
                ExpectedResult     = 'Certificate'
            }
        ) {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                $convertToUserTypeResult = ConvertTo-UserType -AuthenticationType $AuthenticationType -LoginType $LoginType

                $convertToUserTypeResult | Should -Be $ExpectedResult
            }
        }

        Context 'When calling with an unsupported authentication type' {
            It 'Should throw the correct error' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockErrorMessage = $script:localizedData.UnknownAuthenticationType -f 'UnsupportedValue', 'SqlLogin'
                    {
                        ConvertTo-UserType -AuthenticationType 'UnsupportedValue' -LoginType 'SqlLogin'
                    } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage)
                }
            }
        }
    }
}

Describe 'Assert-SqlLogin' -Tag 'Helper' {
    BeforeAll {
        $mockSqlServerObject = {
            New-Object -TypeName Object |
            Add-Member -MemberType ScriptProperty -Name 'Logins' -Value {
                return @(
                    @{
                        'CONTOSO\Login1' = New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value 'CONTOSO\Login1' -PassThru -Force
                    }
                )
            } -PassThru -Force
        }

        Mock -CommandName Connect-SQL -MockWith $mockSqlServerObject
    }

    Context 'When the SQL login exist' {
        It 'Should not throw any error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $assertSqlLoginParameters = @{
                    InstanceName = 'MSSQLSERVER'
                    ServerName   = 'localhost'
                    LoginName    = 'CONTOSO\Login1'
                    Verbose      = $true
                }

                { Assert-SqlLogin @assertSqlLoginParameters } | Should -Not -Throw
            }
        }
    }

    Context 'When the SQL login does not exist' {
        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $assertSqlLoginParameters = @{
                    InstanceName = 'MSSQLSERVER'
                    ServerName   = 'localhost'
                    LoginName    = 'AnyValue'
                    Verbose      = $true
                }

                $mockErrorMessage = $script:localizedData.SqlLoginNotFound -f 'AnyValue'
                {
                    Assert-SqlLogin @assertSqlLoginParameters
                } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage)
            }
        }
    }
}

Describe 'Assert-DatabaseCertificate' -Tag 'Helper' {
    BeforeAll {
        $mockSqlServerObject = {
            New-Object -TypeName Object |
            Add-Member -MemberType ScriptProperty -Name 'Databases' -Value {
                return @(
                    @{
                        'TestDB' = New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value 'TestDB' -PassThru |
                        Add-Member -MemberType ScriptProperty -Name 'Certificates' -Value {
                            return @(
                                @{
                                    'Certificate1' = New-Object -TypeName Object |
                                    Add-Member -MemberType NoteProperty -Name 'Name' -Value 'Certificate1' -PassThru -Force
                                }
                            )
                        } -PassThru -Force
                    }
                )
            } -PassThru -Force
        }

        Mock -CommandName Connect-SQL -MockWith $mockSqlServerObject

        InModuleScope -ScriptBlock {
            $script:mockDefaultParameters = @{
                Name         = 'DatabaseUser1'
                InstanceName = 'MSSQLSERVER'
                ServerName   = 'localhost'
                DatabaseName = 'TestDB'
            }
        }
    }

    Context 'When the certificate exist in the database' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:assertDatabaseCertificateParameters = $mockDefaultParameters.Clone()
                $script:assertDatabaseCertificateParameters['CertificateName'] = 'Certificate1'
            }
        }

        It 'Should not throw any error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Assert-DatabaseCertificate @assertDatabaseCertificateParameters } | Should -Not -Throw
            }
        }
    }

    Context 'When the certificate does not exist in the database' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:assertDatabaseCertificateParameters = $mockDefaultParameters.Clone()
                $script:assertDatabaseCertificateParameters['CertificateName'] = 'AnyValue'
            }
        }

        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockErrorMessage = ($script:localizedData.CertificateNotFound -f 'AnyValue', 'TestDB')
                {
                    Assert-DatabaseCertificate @assertDatabaseCertificateParameters
                } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage)
            }
        }
    }
}

Describe 'Assert-DatabaseAsymmetricKey' -Tag 'Helper' {
    BeforeAll {
        $mockSqlServerObject = {
            New-Object -TypeName Object |
            Add-Member -MemberType ScriptProperty -Name 'Databases' -Value {
                return @(
                    @{
                        'TestDB' = New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value 'TestDB' -PassThru |
                        Add-Member -MemberType ScriptProperty -Name 'AsymmetricKeys' -Value {
                            return @(
                                @{
                                    'AsymmetricKey1' = New-Object -TypeName Object |
                                    Add-Member -MemberType NoteProperty -Name 'Name' -Value 'AsymmetricKey1' -PassThru -Force
                                }
                            )
                        } -PassThru -Force
                    }
                )
            } -PassThru -Force
        }

        Mock -CommandName Connect-SQL -MockWith $mockSqlServerObject

        InModuleScope -ScriptBlock {
            $script:mockDefaultParameters = @{
                Name         = 'DatabaseUser1'
                InstanceName = 'MSSQLSERVER'
                ServerName   = 'localhost'
                DatabaseName = 'TestDB'
            }
        }
    }

    Context 'When the asymmetric key exist in the database' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:assertDatabaseAsymmetricKeyParameters = $mockDefaultParameters.Clone()
                $script:assertDatabaseAsymmetricKeyParameters['AsymmetricKeyName'] = 'AsymmetricKey1'
            }
        }

        It 'Should not throw any error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Assert-DatabaseAsymmetricKey @assertDatabaseAsymmetricKeyParameters } | Should -Not -Throw
            }
        }
    }

    Context 'When the asymmetric key does not exist in the database' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:assertDatabaseAsymmetricKeyParameters = $mockDefaultParameters.Clone()
                $script:assertDatabaseAsymmetricKeyParameters['AsymmetricKeyName'] = 'AnyValue'
            }
        }

        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockErrorMessage = $script:localizedData.AsymmetryKeyNotFound -f 'AnyValue', 'TestDB'

                {
                    Assert-DatabaseAsymmetricKey @assertDatabaseAsymmetricKeyParameters
                } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage)
            }
        }
    }
}
