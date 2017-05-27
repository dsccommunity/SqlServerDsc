$script:DSCModuleName      = 'xSQLServer'
$script:DSCResourceName    = 'MSFT_xSQLServerDatabasePermission'

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
    # Loading mocked classes
    Add-Type -Path (Join-Path -Path $script:moduleRoot -ChildPath 'Tests\Unit\Stubs\SMO.cs')
}

function Invoke-TestCleanup {
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

# Begin Testing
try
{
    Invoke-TestSetup

    InModuleScope $script:DSCResourceName {
        $mockSqlServerName                            = 'localhost'
        $mockSqlServerInstanceName                    = 'MSSQLSERVER'
        $mockSqlDatabaseName                          = 'AdventureWorks'
        $mockLogin                                    = 'Zebes\SamusAran'
        $mockLoginUnknown                             = 'Elysia\Chozo'
        $mockLoginType                                = 'WindowsUser'
        $mockInvalidOperationEnumDatabasePermissions  = $false
        $mockInvalidOperationForCreateMethod          = $false
        $mockExpectedSqlServerLogin                   = 'Zebes\SamusAran'
        $mockSqlPermissionState                       = 'Grant'

        $mockSqlPermissionType01 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.DatabasePermissionSet -ArgumentList ($true, $false)
        $mockSqlPermissionType02 = New-Object -TypeName Microsoft.SqlServer.Management.Smo.DatabasePermissionSet -ArgumentList ($false, $true)

        $script:mockMethodGrantRan = $false
        $script:mockMethodDenyRan = $false
        $script:mockMethodRevokeRan = $false
        $script:mockMethodCreateLoginRan = $false

        # Default parameters that are used for the It-blocks
        $mockDefaultParameters = @{
            SQLInstanceName = $mockSqlServerInstanceName
            SQLServer       = $mockSqlServerName
        }

        #region Function mocks
        $mockConnectSQL = {
            return @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name InstanceName -Value $mockSqlServerInstanceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name ComputerNamePhysicalNetBIOS -Value $mockSqlServerName -PassThru |
                        Add-Member -MemberType ScriptProperty -Name Databases -Value {
                            return @{
                                $mockSqlDatabaseName = @((
                                    New-Object Object |
                                        Add-Member -MemberType NoteProperty -Name Name -Value $mockSqlDatabaseName -PassThru |
                                        Add-Member -MemberType ScriptProperty -Name Users -Value {
                                            return @{
                                                $mockLogin = @((
                                                    New-Object Object |
                                                        Add-Member -MemberType ScriptMethod -Name IsMember -Value {
                                                                return $true
                                                        } -PassThru
                                                ))
                                            }
                                        } -PassThru |
                                        Add-Member -MemberType ScriptMethod -Name EnumDatabasePermissions -Value {
                                            param
                                            (
                                                [Parameter()]
                                                [System.String]
                                                $mockLogin
                                            )
                                            if ($mockInvalidOperationEnumDatabasePermissions)
                                            {
                                                throw 'Mock EnumDatabasePermissions Method was called with invalid operation.'
                                            }

                                            if ( $mockLogin -eq $mockExpectedSqlServerLogin )
                                            {
                                                $mockEnumDatabasePermissions = @()
                                                $mockEnumDatabasePermissions += New-Object Object |
                                                        Add-Member -MemberType NoteProperty -Name PermissionType -Value $mockSqlPermissionType01 -PassThru |
                                                        Add-Member -MemberType NoteProperty -Name PermissionState -Value $mockSqlPermissionState -PassThru |
                                                        Add-Member -MemberType NoteProperty -Name Grantee -Value $mockExpectedSqlServerLogin -PassThru |
                                                        Add-Member -MemberType NoteProperty -Name GrantorType -Value 'User' -PassThru |
                                                        Add-Member -MemberType NoteProperty -Name ObjectClass -Value 'Database' -PassThru |
                                                        Add-Member -MemberType NoteProperty -Name ObjectName -Value $mockSqlDatabaseName -PassThru
                                                $mockEnumDatabasePermissions += New-Object Object |
                                                        Add-Member -MemberType NoteProperty -Name PermissionType -Value $mockSqlPermissionType02 -PassThru |
                                                        Add-Member -MemberType NoteProperty -Name PermissionState -Value $mockSqlPermissionState -PassThru |
                                                        Add-Member -MemberType NoteProperty -Name Grantee -Value $mockExpectedSqlServerLogin -PassThru |
                                                        Add-Member -MemberType NoteProperty -Name GrantorType -Value 'User' -PassThru |
                                                        Add-Member -MemberType NoteProperty -Name ObjectClass -Value 'Database' -PassThru |
                                                        Add-Member -MemberType NoteProperty -Name ObjectName -Value $mockSqlDatabaseName -PassThru

                                                $mockEnumDatabasePermissions
                                            }
                                            else
                                            {
                                                return $null
                                            }
                                        } -PassThru |
                                        Add-Member -MemberType ScriptMethod -Name Grant -Value {
                                            param
                                            (
                                                [Parameter()]
                                                [System.Object]
                                                $permissionSet,

                                                [Parameter()]
                                                [System.String]
                                                $mockLogin
                                            )

                                            $script:mockMethodGrantRan = $true

                                            if ( $mockLogin -ne $mockExpectedSqlServerLogin )
                                            {
                                                throw "Called mocked Grant() method without setting the right login name. Expected '{0}'. But was '{1}'." `
                                                      -f $mockExpectedSqlServerLogin, $mockLogin
                                            }
                                        } -PassThru |
                                        Add-Member -MemberType ScriptMethod -Name Revoke -Value {
                                            param
                                            (
                                                [Parameter()]
                                                [System.Object]
                                                $permissionSet,

                                                [Parameter()]
                                                [System.String]
                                                $mockLogin
                                            )

                                            $script:mockMethodRevokeRan = $true

                                            if ( $mockLogin -ne $mockExpectedSqlServerLogin )
                                            {
                                                throw "Called mocked Revoke() method without setting the right login name. Expected '{0}'. But was '{1}'." `
                                                      -f $mockExpectedSqlServerLogin, $mockLogin
                                            }
                                        } -PassThru |
                                        Add-Member -MemberType ScriptMethod -Name Deny -Value {
                                            param
                                            (
                                                [Parameter()]
                                                [System.Object]
                                                $permissionSet,

                                                [Parameter()]
                                                [System.String]
                                                $mockLogin
                                            )

                                            $script:mockMethodDenyRan = $true

                                            if ( $mockLogin -ne $mockExpectedSqlServerLogin )
                                            {
                                                throw "Called mocked Deny() method without setting the right login name. Expected '{0}'. But was '{1}'." `
                                                      -f $mockExpectedSqlServerLogin, $mockLogin
                                            }
                                        } -PassThru -Force
                                    ))
                                }
                            } -PassThru -Force |
                        Add-Member -MemberType ScriptProperty -Name Logins -Value {
                            return @{
                                $mockLogin = @((
                                    New-Object Object |
                                        Add-Member -MemberType NoteProperty -Name LoginType -Value $mockLoginType -PassThru
                                ))
                                $mockLoginUnknown= @((
                                    New-Object Object |
                                        Add-Member -MemberType NoteProperty -Name LoginType -Value $mockLoginType -PassThru
                                ))
                            }
                        } -PassThru -Force
                )
            )
        }

        $mockNewObjectUser = {
            return @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name Name -Value $mockLoginUnknown -PassThru |
                        Add-Member -MemberType NoteProperty -Name Login -Value $mockLoginUnknown -PassThru |
                        Add-Member -MemberType ScriptMethod -Name Create -Value {
                            $script:mockMethodCreateLoginRan = $true

                            if ($mockInvalidOperationForCreateMethod)
                            {
                                throw 'Mock Create Method was called with invalid operation.'
                            }
                            if ( $this.Name -ne $mockExpectedSqlServerLogin )
                            {
                                throw "Called mocked Create() method without adding the right user. Expected '{0}'. But was '{1}'." `
                                        -f $mockExpectedSqlServerLogin, $this.Name
                            }
                        } -PassThru -Force
                )
            )
        }

        #endregion

        Describe "MSFT_xSQLServerDatabasePermission\Get-TargetResource" -Tag 'Get'{
            BeforeEach {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
            }

            Context 'When passing values to parameters and database name does not exist' {
                It 'Should throw the correct error' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Database    = 'unknownDatabaseName'
                        Name        = $mockLogin
                        PermissionState = 'Grant'
                        Permissions = @( 'Connect','Update' )
                    }

                    $throwInvalidOperation = ("Database 'unknownDatabaseName' does not exist " + `
                                              "on SQL server 'localhost\MSSQLSERVER'.")

                    { Get-TargetResource @testParameters } | Should Throw $throwInvalidOperation

                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When passing values to parameters and login name does not exist' {
                It 'Should throw the correct error' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Database    = $mockSqlDatabaseName
                        Name        = 'unknownLoginName'
                        PermissionState = 'Grant'
                        Permissions = @( 'Connect','Update' )
                    }

                    $throwInvalidOperation = ("Login 'unknownLoginName' does not exist " + `
                                              "on SQL server 'localhost\MSSQLSERVER'.")

                    { Get-TargetResource @testParameters } | Should Throw $throwInvalidOperation

                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When passing values to parameters and database name and login name do exist' {
                It 'Should throw the correct error with EnumDatabasePermissions method' {
                    $mockInvalidOperationEnumDatabasePermissions = $true
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Database    = $mockSqlDatabaseName
                        Name        = $mockLogin
                        PermissionState = 'Grant'
                        Permissions = @( 'Connect','Update' )
                    }

                    $throwInvalidOperation = ('Failed to get permission for login named Zebes\SamusAran of ' + `
                                              'the database named AdventureWorks on localhost\MSSQLSERVER.')

                    { Get-TargetResource @testParameters } | Should Throw $throwInvalidOperation

                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the system is in the desired state and ensure is set to Absent' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    Database    = $mockSqlDatabaseName
                    Name        = $mockLogin
                    PermissionState = 'Grant'
                    Permissions = @( 'Connect','Update','Select' )
                }

                It 'Should return the state as absent when the desired permission does not exist' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should Be 'Absent'

                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                }

                It 'Should return the same values as passed as parameters' {
                    $result = Get-TargetResource @testParameters
                    $result.SQLServer | Should Be $testParameters.SQLServer
                    $result.SQLInstanceName | Should Be $testParameters.SQLInstanceName
                    $result.ServerRoleName | Should Be $testParameters.ServerRoleName

                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the system is not in the desired state and ensure is set to Absent' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    Database    = $mockSqlDatabaseName
                    Name        = $mockLogin
                    PermissionState = 'Grant'
                    Permissions = @( 'Connect','Update' )
                }

                It 'Should not return the state as absent when the desired permission does not exist' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should Not Be 'Absent'

                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                }

                It 'Should return the same values as passed as parameters' {
                    $result = Get-TargetResource @testParameters
                    $result.SQLServer | Should Be $testParameters.SQLServer
                    $result.SQLInstanceName | Should Be $testParameters.SQLInstanceName
                    $result.ServerRoleName | Should Be $testParameters.ServerRoleName

                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the system is in the desired state and ensure is set to Present' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    Database    = $mockSqlDatabaseName
                    Name        = $mockLogin
                    PermissionState = 'Grant'
                    Permissions = @( 'Connect','Update' )
                }

                It 'Should return the state as absent when the desired permission does not exist' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should Be 'Present'

                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                }

                It 'Should return the same values as passed as parameters' {
                    $result = Get-TargetResource @testParameters
                    $result.SQLServer | Should Be $testParameters.SQLServer
                    $result.SQLInstanceName | Should Be $testParameters.SQLInstanceName
                    $result.ServerRoleName | Should Be $testParameters.ServerRoleName

                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the system is not in the desired state and ensure is set to Present' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    Database    = $mockSqlDatabaseName
                    Name        = $mockLogin
                    PermissionState = 'Grant'
                    Permissions = @( 'Connect','Update','Select' )
                }

                It 'Should not return the state as absent when the desired permission does not exist' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should Not Be 'Present'

                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                }

                It 'Should return the same values as passed as parameters' {
                    $result = Get-TargetResource @testParameters
                    $result.SQLServer | Should Be $testParameters.SQLServer
                    $result.SQLInstanceName | Should Be $testParameters.SQLInstanceName
                    $result.ServerRoleName | Should Be $testParameters.ServerRoleName

                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Assert-VerifiableMocks
        }

        Describe "MSFT_xSQLServerDatabasePermission\Test-TargetResource" -Tag 'Test'{
            BeforeEach {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
            }

            Context 'When passing values to parameters and database name does not exist' {
                It 'Should throw the correct error' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Database    = 'unknownDatabaseName'
                        Name        = $mockLogin
                        PermissionState = 'Grant'
                        Permissions = @( 'Connect','Update' )
                        Ensure      = 'Present'
                    }

                    $throwInvalidOperation = ("Database 'unknownDatabaseName' does not exist " + `
                                              "on SQL server 'localhost\MSSQLSERVER'.")

                    { Test-TargetResource @testParameters } | Should Throw $throwInvalidOperation

                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When passing values to parameters and login name does not exist' {
                It 'Should throw the correct error' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Database    = $mockSqlDatabaseName
                        Name        = 'unknownLoginName'
                        PermissionState = 'Grant'
                        Permissions = @( 'Connect','Update' )
                        Ensure      = 'Present'
                    }

                    $throwInvalidOperation = ("Login 'unknownLoginName' does not exist " + `
                                              "on SQL server 'localhost\MSSQLSERVER'.")

                    { Test-TargetResource @testParameters } | Should Throw $throwInvalidOperation

                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When passing values to parameters and database name and login name do exist' {
                It 'Should throw the correct error with EnumDatabasePermissions method' {
                    $mockInvalidOperationEnumDatabasePermissions = $true
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Database    = $mockSqlDatabaseName
                        Name        = $mockLogin
                        PermissionState = 'Grant'
                        Permissions = @( 'Connect','Update' )
                        Ensure      = 'Present'
                    }

                    $throwInvalidOperation = ('Failed to get permission for login named Zebes\SamusAran of ' + `
                                              'the database named AdventureWorks on localhost\MSSQLSERVER.')

                    { Test-TargetResource @testParameters } | Should Throw $throwInvalidOperation

                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the system is in the desired state and ensure is set to Absent' {
                It 'Should return the state as true when the desired permission does not exist' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Database    = $mockSqlDatabaseName
                        Name        = $mockLogin
                        PermissionState = 'Grant'
                        Permissions = @( 'Connect','Update','Select' )
                        Ensure = 'Absent'
                    }

                    Test-TargetResource @testParameters | Should Be $true

                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the system is not in the desired state and ensure is set to Absent' {
                It 'Should return the state as false when the desired permission does not exist' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Database    = $mockSqlDatabaseName
                        Name        = $mockLogin
                        PermissionState = 'Grant'
                        Permissions = @( 'Connect','Update' )
                        Ensure = 'Absent'
                    }

                    Test-TargetResource @testParameters | Should Be $false

                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the system is not in the desired state and ensure is set to Present' {
                It 'Should return the state as false when the desired permission does not exist' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Database    = $mockSqlDatabaseName
                        Name        = $mockLogin
                        PermissionState = 'Grant'
                        Permissions = @( 'Connect','Update','Select' )
                        Ensure = 'Present'
                    }

                    Test-TargetResource @testParameters | Should Be $false

                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the system is in the desired state and ensure is set to Present' {
                It 'Should return the state as true when the desired permission does exist' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Database    = $mockSqlDatabaseName
                        Name        = $mockLogin
                        PermissionState = 'Grant'
                        Permissions = @( 'Connect','Update' )
                        Ensure = 'Present'
                    }

                    Test-TargetResource @testParameters | Should Be $true

                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Assert-VerifiableMocks
        }

        Describe "MSFT_xSQLServerDatabasePermission\Set-TargetResource" -Tag 'Set'{
            BeforeEach {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
                Mock -CommandName New-Object -MockWith $mockNewObjectUser -ParameterFilter {
                    $TypeName -eq 'Microsoft.SqlServer.Management.Smo.User'
                } -Verifiable

                $script:mockMethodGrantRan = $false
                $script:mockMethodDenyRan = $false
                $script:mockMethodRevokeRan = $false
                $script:mockMethodCreateLoginRan = $false
            }

            Context 'When passing values to parameters and database name does not exist' {
                It 'Should throw the correct error' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Database    = 'unknownDatabaseName'
                        Name        = $mockLogin
                        PermissionState = 'Grant'
                        Permissions = @( 'Connect','Update' )
                        Ensure      = 'Present'
                    }

                    $throwInvalidOperation = ("Database 'unknownDatabaseName' does not exist " + `
                                              "on SQL server 'localhost\MSSQLSERVER'.")

                    { Set-TargetResource @testParameters } | Should Throw $throwInvalidOperation

                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When passing values to parameters and login name does not exist' {
                It 'Should throw the correct error' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Database    = $mockSqlDatabaseName
                        Name        = 'unknownLoginName'
                        PermissionState = 'Grant'
                        Permissions = @( 'Connect','Update' )
                        Ensure      = 'Present'
                    }

                    $throwInvalidOperation = ("Login 'unknownLoginName' does not exist " + `
                                              "on SQL server 'localhost\MSSQLSERVER'.")

                    { Set-TargetResource @testParameters } | Should Throw $throwInvalidOperation

                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the login cannot be created' {
                It 'Should throw the correct error' {
                    $mockInvalidOperationForCreateMethod = $true
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Database    = $mockSqlDatabaseName
                        Name        = $mockLoginUnknown
                        PermissionState = 'Grant'
                        Permissions = @( 'Connect','Update' )
                        Ensure      = 'Present'
                    }

                    $throwInvalidOperation = ('Failed adding the login Elysia\Chozo ' + `
                                              'as a user of the database AdventureWorks, ' + `
                                              'on the instance localhost\MSSQLSERVER.')

                    { Set-TargetResource @testParameters } | Should Throw $throwInvalidOperation

                    $script:mockMethodCreateLoginRan | Should Be $true

                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the system is not in the desired state' {
                Context 'When the mock methods fail (testing the test)' {
                    BeforeAll {
                        $throwInvalidOperation = ('Failed to set permission for login named ' + `
                                                'Zebes\SamusAran of the database named ' + `
                                                'AdventureWorks on localhost\MSSQLSERVER.')

                        $mockExpectedSqlServerLogin = $mockLoginUnknown
                    }

                    It 'Should throw the correct error when mock Grant() method is called' {
                        $testParameters = $mockDefaultParameters.Clone()
                        $testParameters += @{
                            Database    = $mockSqlDatabaseName
                            Name        = $mockLogin
                            PermissionState = 'Grant'
                            Permissions = @( 'Connect','Update' )
                            Ensure      = 'Present'
                        }

                        { Set-TargetResource @testParameters } | Should Throw $throwInvalidOperation

                        $script:mockMethodGrantRan | Should Be $true
                        $script:mockMethodDenyRan | Should Be $false
                        $script:mockMethodRevokeRan | Should Be $false
                    }

                    It 'Should throw the correct error when mock Grant() method is called (for GrantWithGrant)' {
                        $testParameters = $mockDefaultParameters.Clone()
                        $testParameters += @{
                            Database    = $mockSqlDatabaseName
                            Name        = $mockLogin
                            PermissionState = 'GrantWithGrant'
                            Permissions = @( 'Connect','Update' )
                            Ensure      = 'Present'
                        }

                        { Set-TargetResource @testParameters } | Should Throw $throwInvalidOperation

                        $script:mockMethodGrantRan | Should Be $true
                        $script:mockMethodDenyRan | Should Be $false
                        $script:mockMethodRevokeRan | Should Be $false
                    }


                    It 'Should throw the correct error when mock Deny() method is called' {
                        $testParameters = $mockDefaultParameters.Clone()
                        $testParameters += @{
                            Database    = $mockSqlDatabaseName
                            Name        = $mockLogin
                            PermissionState = 'Deny'
                            Permissions = @( 'Connect','Update' )
                            Ensure      = 'Present'
                        }

                        { Set-TargetResource @testParameters } | Should Throw $throwInvalidOperation

                        $script:mockMethodGrantRan | Should Be $false
                        $script:mockMethodDenyRan | Should Be $true
                        $script:mockMethodRevokeRan | Should Be $false
                    }

                    It 'Should throw the correct error when mock Revoke() method is called' {
                        $testParameters = $mockDefaultParameters.Clone()
                        $testParameters += @{
                            Database    = $mockSqlDatabaseName
                            Name        = $mockLogin
                            PermissionState = 'Grant'
                            Permissions = @( 'Connect','Update' )
                            Ensure      = 'Absent'
                        }

                        { Set-TargetResource @testParameters } | Should Throw $throwInvalidOperation

                        $script:mockMethodGrantRan | Should Be $false
                        $script:mockMethodDenyRan | Should Be $false
                        $script:mockMethodRevokeRan | Should Be $true
                    }

                    It 'Should throw the correct error when mock Revoke() method is called' {
                        $testParameters = $mockDefaultParameters.Clone()
                        $testParameters += @{
                            Database    = $mockSqlDatabaseName
                            Name        = $mockLogin
                            PermissionState = 'GrantWithGrant'
                            Permissions = @( 'Connect','Update' )
                            Ensure      = 'Absent'
                        }

                        { Set-TargetResource @testParameters } | Should Throw $throwInvalidOperation

                        $script:mockMethodGrantRan | Should Be $false
                        $script:mockMethodDenyRan | Should Be $false
                        $script:mockMethodRevokeRan | Should Be $true
                    }
                }

                Context 'When Ensure is set to Present' {
                    Context 'When the login does not exist' {
                        It 'Should create the login without throwing an error' {
                            $mockInvalidOperationForCreateMethod = $false
                            $mockExpectedSqlServerLogin = $mockLoginUnknown
                            $testParameters = $mockDefaultParameters
                            $testParameters += @{
                                Database    = $mockSqlDatabaseName
                                Name        = $mockLoginUnknown
                                PermissionState = 'Grant'
                                Permissions = @( 'Connect','Update' )
                                Ensure      = 'Present'
                            }

                            { Set-TargetResource @testParameters } | Should Not Throw

                            $script:mockMethodCreateLoginRan | Should Be $true

                            Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                        }
                    }

                    It 'Should call the method Grant() without throwing' {
                        $mockExpectedSqlServerLogin = $mockLogin
                        $testParameters = $mockDefaultParameters
                        $testParameters += @{
                            Database    = $mockSqlDatabaseName
                            Name        = $mockLogin
                            PermissionState = 'Grant'
                            Permissions = @( 'Connect','Update' )
                            Ensure      = 'Present'
                        }

                        { Set-TargetResource @testParameters } | Should Not Throw

                        $script:mockMethodGrantRan | Should Be $true
                        $script:mockMethodDenyRan | Should Be $false
                        $script:mockMethodRevokeRan | Should Be $false

                        Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                    }

                    It 'Should call the method Grant() (WithGrant) without throwing' {
                        $mockExpectedSqlServerLogin = $mockLogin
                        $testParameters = $mockDefaultParameters
                        $testParameters += @{
                            Database    = $mockSqlDatabaseName
                            Name        = $mockLogin
                            PermissionState = 'GrantWithGrant'
                            Permissions = @( 'Connect','Update' )
                            Ensure      = 'Present'
                        }

                        { Set-TargetResource @testParameters } | Should Not Throw

                        $script:mockMethodGrantRan | Should Be $true
                        $script:mockMethodDenyRan | Should Be $false
                        $script:mockMethodRevokeRan | Should Be $false

                        Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                    }

                    It 'Should call the method Deny() without throwing' {
                        $mockExpectedSqlServerLogin = $mockLogin
                        $testParameters = $mockDefaultParameters
                        $testParameters += @{
                            Database    = $mockSqlDatabaseName
                            Name        = $mockLogin
                            PermissionState = 'Deny'
                            Permissions = @( 'Connect','Update' )
                            Ensure      = 'Present'
                        }

                        { Set-TargetResource @testParameters } | Should Not Throw

                        $script:mockMethodGrantRan | Should Be $false
                        $script:mockMethodDenyRan | Should Be $true
                        $script:mockMethodRevokeRan | Should Be $false

                        Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                    }
                }

                Context 'When Ensure is set to Absent' {
                    It 'Should call the method Revoke() for permission state ''Grant'' without throwing' {
                        $mockExpectedSqlServerLogin = $mockLogin
                        $testParameters = $mockDefaultParameters
                        $testParameters += @{
                            Database    = $mockSqlDatabaseName
                            Name        = $mockLogin
                            PermissionState = 'Grant'
                            Permissions = @( 'Connect','Update' )
                            Ensure      = 'Absent'
                        }

                        { Set-TargetResource @testParameters } | Should Not Throw

                        $script:mockMethodGrantRan | Should Be $false
                        $script:mockMethodDenyRan | Should Be $false
                        $script:mockMethodRevokeRan | Should Be $true

                        Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                    }

                    It 'Should call the method Revoke() for permission state ''GrantWithGrant'' without throwing' {
                        $mockExpectedSqlServerLogin = $mockLogin
                        $testParameters = $mockDefaultParameters
                        $testParameters += @{
                            Database    = $mockSqlDatabaseName
                            Name        = $mockLogin
                            PermissionState = 'GrantWithGrant'
                            Permissions = @( 'Connect','Update' )
                            Ensure      = 'Absent'
                        }

                        { Set-TargetResource @testParameters } | Should Not Throw

                        $script:mockMethodGrantRan | Should Be $false
                        $script:mockMethodDenyRan | Should Be $false
                        $script:mockMethodRevokeRan | Should Be $true

                        Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                    }

                    It 'Should call the method Revoke() for permission state ''Deny'' without throwing' {
                        $mockExpectedSqlServerLogin = $mockLogin
                        $testParameters = $mockDefaultParameters
                        $testParameters += @{
                            Database    = $mockSqlDatabaseName
                            Name        = $mockLogin
                            PermissionState = 'Deny'
                            Permissions = @( 'Connect','Update' )
                            Ensure      = 'Absent'
                        }

                        { Set-TargetResource @testParameters } | Should Not Throw

                        $script:mockMethodGrantRan | Should Be $false
                        $script:mockMethodDenyRan | Should Be $false
                        $script:mockMethodRevokeRan | Should Be $true

                        Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                    }
                }
            }

            Assert-VerifiableMocks
        }
    }
}
finally
{
    Invoke-TestCleanup
}#endregion
