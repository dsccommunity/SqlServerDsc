<#
    .SYNOPSIS
        Automated unit test for DSC_SqlDatabasePermission DSC resource.

#>

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

$script:dscModuleName = 'SqlServerDsc'
$script:dscResourceName = 'DSC_SqlDatabasePermission'

function Invoke-TestSetup
{
    try
    {
        Import-Module -Name DscResource.Test -Force -ErrorAction 'Stop'
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
    }

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    # Loading mocked classes
    Add-Type -Path (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Stubs') -ChildPath 'SMO.cs')
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Invoke-TestSetup

try
{
    InModuleScope $script:dscResourceName {
        $mockServerName = 'localhost'
        $mockInstanceName = 'MSSQLSERVER'
        $mockSqlDatabaseName = 'AdventureWorks'
        $mockUserName = 'Zebes\SamusAran'
        $mockRoleName = 'public'
        $mockApplicationRoleName = 'MyAppRole'
        $mockUserNameUnknown = 'Elysia\Chozo'
        $mockLoginType = 'WindowsUser'
        $mockInvalidOperationEnumDatabasePermissions = $false
        $mockInvalidOperationForCreateMethod = $false
        $mockExpectedSqlServerLogin = 'Zebes\SamusAran'
        $mockSqlPermissionState = 'Grant'

        $mockSqlPermissionType01 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionSet' -ArgumentList @($true, $false)
        $mockSqlPermissionType02 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionSet' -ArgumentList @($false, $true)

        $script:mockMethodGrantRan = $false
        $script:mockMethodDenyRan = $false
        $script:mockMethodRevokeRan = $false
        $script:mockMethodCreateLoginRan = $false

        # Default parameters that are used for the It-blocks
        $mockDefaultParameters = @{
            InstanceName = $mockInstanceName
            ServerName   = $mockServerName
        }

        #region Function mocks
        $mockConnectSQL = {
            return @(
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType 'ScriptProperty' -Name 'Databases' -Value {
                        return @{
                            $mockSqlDatabaseName = @(
                                (
                                    New-Object -TypeName Object |
                                        Add-Member -MemberType 'NoteProperty' -Name Name -Value $mockSqlDatabaseName -PassThru |
                                        Add-Member -MemberType 'ScriptProperty' -Name 'Users' -Value {
                                            return @{
                                                $mockUserName = @(
                                                    (
                                                        New-Object -TypeName Object |
                                                            Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value $mockUserName -PassThru -Force
                                                    )
                                                )
                                            }
                                        } -PassThru |
                                        Add-Member -MemberType 'ScriptProperty' -Name 'ApplicationRoles' -Value {
                                            return @{
                                                $mockApplicationRoleName = @(
                                                    (
                                                        New-Object -TypeName Object |
                                                            Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value $mockApplicationRoleName -PassThru -Force
                                                    )
                                                )
                                            }
                                        } -PassThru |
                                        Add-Member -MemberType 'ScriptProperty' -Name 'Roles' -Value {
                                            return @{
                                                $mockRoleName = @(
                                                    (
                                                        New-Object -TypeName Object |
                                                            Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value $mockRoleName |
                                                            Add-Member -MemberType 'NoteProperty' -Name 'IsFixedRole' -Value $true -PassThru -Force
                                                    )
                                                )
                                            }
                                        } -PassThru |
                                        Add-Member -MemberType 'ScriptMethod' -Name 'EnumDatabasePermissions' -Value {
                                            param
                                            (
                                                [Parameter()]
                                                [System.String]
                                                $SqlServerLogin
                                            )
                                            if ($mockInvalidOperationEnumDatabasePermissions)
                                            {
                                                throw 'Mock EnumDatabasePermissions Method was called with invalid operation.'
                                            }

                                            if ( $SqlServerLogin -eq $mockExpectedSqlServerLogin )
                                            {
                                                $mockEnumDatabasePermissions = @()
                                                $mockEnumDatabasePermissions += New-Object -TypeName Object |
                                                    Add-Member -MemberType NoteProperty -Name PermissionType -Value $mockSqlPermissionType01 -PassThru |
                                                    Add-Member -MemberType NoteProperty -Name PermissionState -Value $mockSqlPermissionState -PassThru |
                                                    Add-Member -MemberType NoteProperty -Name Grantee -Value $mockExpectedSqlServerLogin -PassThru |
                                                    Add-Member -MemberType NoteProperty -Name GrantorType -Value 'User' -PassThru |
                                                    Add-Member -MemberType NoteProperty -Name ObjectClass -Value 'DatabaseName' -PassThru |
                                                    Add-Member -MemberType NoteProperty -Name ObjectName -Value $mockSqlDatabaseName -PassThru
                                                $mockEnumDatabasePermissions += New-Object -TypeName Object |
                                                    Add-Member -MemberType NoteProperty -Name PermissionType -Value $mockSqlPermissionType02 -PassThru |
                                                    Add-Member -MemberType NoteProperty -Name PermissionState -Value $mockSqlPermissionState -PassThru |
                                                    Add-Member -MemberType NoteProperty -Name Grantee -Value $mockExpectedSqlServerLogin -PassThru |
                                                    Add-Member -MemberType NoteProperty -Name GrantorType -Value 'User' -PassThru |
                                                    Add-Member -MemberType NoteProperty -Name ObjectClass -Value 'DatabaseName' -PassThru |
                                                    Add-Member -MemberType NoteProperty -Name ObjectName -Value $mockSqlDatabaseName -PassThru

                                                $mockEnumDatabasePermissions
                                            }
                                            else
                                            {
                                                return $null
                                            }
                                        } -PassThru |
                                        Add-Member -MemberType 'ScriptMethod' -Name 'Grant' -Value {
                                            param
                                            (
                                                [Parameter()]
                                                [System.Object]
                                                $permissionSet,

                                                [Parameter()]
                                                [System.String]
                                                $SqlServerLogin
                                            )

                                            $script:mockMethodGrantRan = $true

                                            if ( $SqlServerLogin -ne $mockExpectedSqlServerLogin )
                                            {
                                                throw "Called mocked Grant() method without setting the right login name. Expected '{0}'. But was '{1}'." `
                                                    -f $mockExpectedSqlServerLogin, $SqlServerLogin
                                            }
                                        } -PassThru |
                                        Add-Member -MemberType 'ScriptMethod' -Name 'Revoke' -Value {
                                            param
                                            (
                                                [Parameter()]
                                                [System.Object]
                                                $permissionSet,

                                                [Parameter()]
                                                [System.String]
                                                $SqlServerLogin
                                            )

                                            $script:mockMethodRevokeRan = $true

                                            if ( $SqlServerLogin -ne $mockExpectedSqlServerLogin )
                                            {
                                                throw "Called mocked Revoke() method without setting the right login name. Expected '{0}'. But was '{1}'." `
                                                    -f $mockExpectedSqlServerLogin, $SqlServerLogin
                                            }
                                        } -PassThru |
                                        Add-Member -MemberType 'ScriptMethod' -Name 'Deny' -Value {
                                            param
                                            (
                                                [Parameter()]
                                                [System.Object]
                                                $permissionSet,

                                                [Parameter()]
                                                [System.String]
                                                $SqlServerLogin
                                            )

                                            $script:mockMethodDenyRan = $true

                                            if ( $SqlServerLogin -ne $mockExpectedSqlServerLogin )
                                            {
                                                throw "Called mocked Deny() method without setting the right login name. Expected '{0}'. But was '{1}'." `
                                                    -f $mockExpectedSqlServerLogin, $SqlServerLogin
                                            }
                                        } -PassThru -Force
                                )
                            )
                        }
                    } -PassThru -Force
                )
            )
        }
        #endregion

        Describe "DSC_SqlDatabasePermission\Get-TargetResource" -Tag 'Get' {
            BeforeEach {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
            }

            Context 'When passing values to parameters and database does not exist' {
                It 'Should throw the correct error' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        DatabaseName    = 'unknownDatabaseName'
                        Name            = $mockUserName
                        PermissionState = 'Grant'
                        Permissions     = @( 'Connect', 'Update' )
                    }

                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should -Be 'Absent'

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the system is in the desired state and ensure is set to Absent' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    DatabaseName    = $mockSqlDatabaseName
                    Name            = $mockUserName
                    PermissionState = 'Grant'
                    Permissions     = @( 'Connect', 'Update', 'Select' )
                }

                It 'Should return the state as present when the key properties exist' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should -Be 'Absent'

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                It 'Should return the same values as passed as parameters' {
                    $result = Get-TargetResource @testParameters
                    $result.ServerName | Should -Be $testParameters.ServerName
                    $result.InstanceName | Should -Be $testParameters.InstanceName
                    $result.ServerRoleName | Should -Be $testParameters.ServerRoleName

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the system is not in the desired state and ensure is set to Absent' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    DatabaseName    = $mockSqlDatabaseName
                    Name            = $mockUserName
                    PermissionState = 'Grant'
                    Permissions     = @( 'Connect', 'Update' )
                }

                It 'Should not return the state as absent when the desired permission does not exist' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should -Not -Be 'Absent'

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                It 'Should return the same values as passed as parameters' {
                    $result = Get-TargetResource @testParameters
                    $result.ServerName | Should -Be $testParameters.ServerName
                    $result.InstanceName | Should -Be $testParameters.InstanceName
                    $result.ServerRoleName | Should -Be $testParameters.ServerRoleName

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the system is in the desired state and ensure is set to Present' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    DatabaseName    = $mockSqlDatabaseName
                    Name            = $mockUserName
                    PermissionState = 'Grant'
                    Permissions     = @( 'Connect', 'Update' )
                }

                It 'Should return the state as absent when the desired permission does not exist' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should -Be 'Present'

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                It 'Should return the same values as passed as parameters' {
                    $result = Get-TargetResource @testParameters
                    $result.ServerName | Should -Be $testParameters.ServerName
                    $result.InstanceName | Should -Be $testParameters.InstanceName
                    $result.ServerRoleName | Should -Be $testParameters.ServerRoleName

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the system is not in the desired state and ensure is set to Present' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    DatabaseName    = $mockSqlDatabaseName
                    Name            = $mockUserName
                    PermissionState = 'Grant'
                    Permissions     = @( 'Connect', 'Update', 'Select' )
                }

                It 'Should not return the state as absent when the desired permission does not exist' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should -Not -Be 'Present'

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                It 'Should return the same values as passed as parameters' {
                    $result = Get-TargetResource @testParameters
                    $result.ServerName | Should -Be $testParameters.ServerName
                    $result.InstanceName | Should -Be $testParameters.InstanceName
                    $result.ServerRoleName | Should -Be $testParameters.ServerRoleName

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Assert-VerifiableMock
        }

        Describe "DSC_SqlDatabasePermission\Test-TargetResource" -Tag 'Test' {
            BeforeEach {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
            }

            Context 'When passing values to parameters and database name and login name do exist' {
                It 'Should throw the correct error with EnumDatabasePermissions method' {
                    $mockInvalidOperationEnumDatabasePermissions = $true
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        DatabaseName    = $mockSqlDatabaseName
                        Name            = $mockUserName
                        PermissionState = 'Grant'
                        Permissions     = @( 'Connect', 'Update' )
                        Ensure          = 'Present'
                    }

                    $errorMessage = $script:localizedData.FailedToEnumDatabasePermissions -f $testParameters.Name, $testParameters.DatabaseName

                    { Test-TargetResource @testParameters } | Should -Throw $errorMessage

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the system is in the desired state and ensure is set to Absent' {
                It 'Should return the state as true when the desired permission does not exist' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        DatabaseName    = $mockSqlDatabaseName
                        Name            = $mockUserName
                        PermissionState = 'Grant'
                        Permissions     = @( 'Connect', 'Update', 'Select' )
                        Ensure          = 'Absent'
                    }

                    Test-TargetResource @testParameters | Should -Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the system is not in the desired state and ensure is set to Absent' {
                It 'Should return the state as false when the desired permission does not exist' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        DatabaseName    = $mockSqlDatabaseName
                        Name            = $mockUserName
                        PermissionState = 'Grant'
                        Permissions     = @( 'Connect', 'Update' )
                        Ensure          = 'Absent'
                    }

                    Test-TargetResource @testParameters | Should -Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the system is not in the desired state and ensure is set to Present' {
                It 'Should return the state as false when the desired permission does not exist' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        DatabaseName    = $mockSqlDatabaseName
                        Name            = $mockUserName
                        PermissionState = 'Grant'
                        Permissions     = @( 'Connect', 'Update', 'Select' )
                        Ensure          = 'Present'
                    }

                    Test-TargetResource @testParameters | Should -Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the system is in the desired state and ensure is set to Present' {
                It 'Should return the state as true when the desired permission does exist' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        DatabaseName    = $mockSqlDatabaseName
                        Name            = $mockUserName
                        PermissionState = 'Grant'
                        Permissions     = @( 'Connect', 'Update' )
                        Ensure          = 'Present'
                    }

                    Test-TargetResource @testParameters | Should -Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Assert-VerifiableMock
        }

        Describe "DSC_SqlDatabasePermission\Set-TargetResource" -Tag 'Set' {
            BeforeEach {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

                $script:mockMethodGrantRan = $false
                $script:mockMethodDenyRan = $false
                $script:mockMethodRevokeRan = $false
                $script:mockMethodCreateLoginRan = $false
            }

            Context 'When passing values to parameters and database name does not exist' {
                It 'Should throw the correct error' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        DatabaseName    = 'unknownDatabaseName'
                        Name            = $mockUserName
                        PermissionState = 'Grant'
                        Permissions     = @( 'Connect', 'Update' )
                        Ensure          = 'Present'
                    }

                    $errorMessage = $script:localizedData.DatabaseNotFound -f $testParameters.DatabaseName

                    { Set-TargetResource @testParameters } | Should -Throw $errorMessage

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When passing values to parameters and database user does not exist' {
                It 'Should throw the correct error' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        DatabaseName    = $mockSqlDatabaseName
                        Name            = 'unknownLoginName'
                        PermissionState = 'Grant'
                        Permissions     = @( 'Connect', 'Update' )
                        Ensure          = 'Present'
                    }


                    $errorMessage = $script:localizedData.NameIsMissing -f $testParameters.Name, $mockSqlDatabaseName

                    { Set-TargetResource @testParameters } | Should -Throw $errorMessage

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the system is not in the desired state' {
                Context 'When the mock methods fail (testing the test)' {
                    BeforeAll {
                        $throwInvalidOperation = $script:localizedData.FailedToSetPermissionDatabase -f 'Zebes\SamusAran', 'AdventureWorks'

                        $mockExpectedSqlServerLogin = $mockUserNameUnknown
                    }

                    It 'Should throw the correct error when mock Grant() method is called' {
                        $testParameters = $mockDefaultParameters.Clone()
                        $testParameters += @{
                            DatabaseName    = $mockSqlDatabaseName
                            Name            = $mockUserName
                            PermissionState = 'Grant'
                            Permissions     = @( 'Connect', 'Update' )
                            Ensure          = 'Present'
                        }

                        { Set-TargetResource @testParameters } | Should -Throw $throwInvalidOperation

                        $script:mockMethodGrantRan | Should -Be $true
                        $script:mockMethodDenyRan | Should -Be $false
                        $script:mockMethodRevokeRan | Should -Be $false
                    }

                    It 'Should throw the correct error when mock Grant() method is called (for GrantWithGrant)' {
                        $testParameters = $mockDefaultParameters.Clone()
                        $testParameters += @{
                            DatabaseName    = $mockSqlDatabaseName
                            Name            = $mockUserName
                            PermissionState = 'GrantWithGrant'
                            Permissions     = @( 'Connect', 'Update' )
                            Ensure          = 'Present'
                        }

                        { Set-TargetResource @testParameters } | Should -Throw $throwInvalidOperation

                        $script:mockMethodGrantRan | Should -Be $true
                        $script:mockMethodDenyRan | Should -Be $false
                        $script:mockMethodRevokeRan | Should -Be $false
                    }


                    It 'Should throw the correct error when mock Deny() method is called' {
                        $testParameters = $mockDefaultParameters.Clone()
                        $testParameters += @{
                            DatabaseName    = $mockSqlDatabaseName
                            Name            = $mockUserName
                            PermissionState = 'Deny'
                            Permissions     = @( 'Connect', 'Update' )
                            Ensure          = 'Present'
                        }

                        { Set-TargetResource @testParameters } | Should -Throw $throwInvalidOperation

                        $script:mockMethodGrantRan | Should -Be $false
                        $script:mockMethodDenyRan | Should -Be $true
                        $script:mockMethodRevokeRan | Should -Be $false
                    }

                    It 'Should throw the correct error when mock Revoke() method is called' {
                        $testParameters = $mockDefaultParameters.Clone()
                        $testParameters += @{
                            DatabaseName    = $mockSqlDatabaseName
                            Name            = $mockUserName
                            PermissionState = 'Grant'
                            Permissions     = @( 'Connect', 'Update' )
                            Ensure          = 'Absent'
                        }

                        { Set-TargetResource @testParameters } | Should -Throw $throwInvalidOperation

                        $script:mockMethodGrantRan | Should -Be $false
                        $script:mockMethodDenyRan | Should -Be $false
                        $script:mockMethodRevokeRan | Should -Be $true
                    }

                    It 'Should throw the correct error when mock Revoke() method is called' {
                        $testParameters = $mockDefaultParameters.Clone()
                        $testParameters += @{
                            DatabaseName    = $mockSqlDatabaseName
                            Name            = $mockUserName
                            PermissionState = 'GrantWithGrant'
                            Permissions     = @( 'Connect', 'Update' )
                            Ensure          = 'Absent'
                        }

                        { Set-TargetResource @testParameters } | Should -Throw $throwInvalidOperation

                        $script:mockMethodGrantRan | Should -Be $false
                        $script:mockMethodDenyRan | Should -Be $false
                        $script:mockMethodRevokeRan | Should -Be $true
                    }
                }

                Context 'When Ensure is set to Present' {
                    It 'Should call the method Grant() without throwing' {
                        $mockExpectedSqlServerLogin = $mockUserName
                        $testParameters = $mockDefaultParameters
                        $testParameters += @{
                            DatabaseName    = $mockSqlDatabaseName
                            Name            = $mockUserName
                            PermissionState = 'Grant'
                            Permissions     = @( 'Connect', 'Update' )
                            Ensure          = 'Present'
                        }

                        { Set-TargetResource @testParameters } | Should -Not -Throw

                        $script:mockMethodGrantRan | Should -Be $true
                        $script:mockMethodDenyRan | Should -Be $false
                        $script:mockMethodRevokeRan | Should -Be $false

                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                    }

                    It 'Should call the method Grant() (WithGrant) without throwing' {
                        $mockExpectedSqlServerLogin = $mockUserName
                        $testParameters = $mockDefaultParameters
                        $testParameters += @{
                            DatabaseName    = $mockSqlDatabaseName
                            Name            = $mockUserName
                            PermissionState = 'GrantWithGrant'
                            Permissions     = @( 'Connect', 'Update' )
                            Ensure          = 'Present'
                        }

                        { Set-TargetResource @testParameters } | Should -Not -Throw

                        $script:mockMethodGrantRan | Should -Be $true
                        $script:mockMethodDenyRan | Should -Be $false
                        $script:mockMethodRevokeRan | Should -Be $false

                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                    }

                    It 'Should call the method Deny() without throwing' {
                        $mockExpectedSqlServerLogin = $mockUserName
                        $testParameters = $mockDefaultParameters
                        $testParameters += @{
                            DatabaseName    = $mockSqlDatabaseName
                            Name            = $mockUserName
                            PermissionState = 'Deny'
                            Permissions     = @( 'Connect', 'Update' )
                            Ensure          = 'Present'
                        }

                        { Set-TargetResource @testParameters } | Should -Not -Throw

                        $script:mockMethodGrantRan | Should -Be $false
                        $script:mockMethodDenyRan | Should -Be $true
                        $script:mockMethodRevokeRan | Should -Be $false

                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                    }
                }

                Context 'When Ensure is set to Absent' {
                    It 'Should call the method Revoke() for permission state ''Grant'' without throwing' {
                        $mockExpectedSqlServerLogin = $mockUserName
                        $testParameters = $mockDefaultParameters
                        $testParameters += @{
                            DatabaseName    = $mockSqlDatabaseName
                            Name            = $mockUserName
                            PermissionState = 'Grant'
                            Permissions     = @( 'Connect', 'Update' )
                            Ensure          = 'Absent'
                        }

                        { Set-TargetResource @testParameters } | Should -Not -Throw

                        $script:mockMethodGrantRan | Should -Be $false
                        $script:mockMethodDenyRan | Should -Be $false
                        $script:mockMethodRevokeRan | Should -Be $true

                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                    }

                    It 'Should call the method Revoke() for permission state ''GrantWithGrant'' without throwing' {
                        $mockExpectedSqlServerLogin = $mockUserName
                        $testParameters = $mockDefaultParameters
                        $testParameters += @{
                            DatabaseName    = $mockSqlDatabaseName
                            Name            = $mockUserName
                            PermissionState = 'GrantWithGrant'
                            Permissions     = @( 'Connect', 'Update' )
                            Ensure          = 'Absent'
                        }

                        { Set-TargetResource @testParameters } | Should -Not -Throw

                        $script:mockMethodGrantRan | Should -Be $false
                        $script:mockMethodDenyRan | Should -Be $false
                        $script:mockMethodRevokeRan | Should -Be $true

                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                    }

                    It 'Should call the method Revoke() for permission state ''Deny'' without throwing' {
                        $mockExpectedSqlServerLogin = $mockUserName
                        $testParameters = $mockDefaultParameters
                        $testParameters += @{
                            DatabaseName    = $mockSqlDatabaseName
                            Name            = $mockUserName
                            PermissionState = 'Deny'
                            Permissions     = @( 'Connect', 'Update' )
                            Ensure          = 'Absent'
                        }

                        { Set-TargetResource @testParameters } | Should -Not -Throw

                        $script:mockMethodGrantRan | Should -Be $false
                        $script:mockMethodDenyRan | Should -Be $false
                        $script:mockMethodRevokeRan | Should -Be $true

                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
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
