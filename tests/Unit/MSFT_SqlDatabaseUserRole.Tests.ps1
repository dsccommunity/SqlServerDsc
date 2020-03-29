<#
    .SYNOPSIS
        Automated unit test for MSFT_SqlDatabaseUserRole DSC resource.

    .NOTES
        To run this script locally, please make sure to first run the bootstrap
        script. Read more at
        https://github.com/PowerShell/SqlServerDsc/blob/dev/CONTRIBUTING.md#bootstrap-script-assert-testenvironment
#>

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

if (-not (Test-BuildCategory -Type 'Unit'))
{
    return
}

$script:dscModuleName = 'SqlServerDsc'
$script:dscResourceName = 'MSFT_SqlDatabaseUserRole'

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

        $mockSqlServerLogin1 = 'John'
        $mockSqlServerLogin1Type = 'WindowsUser'
        $mockSqlServerLogin2 = 'CONTOSO\KingJulian'
        $mockSqlServerLogin2Type = 'WindowsGroup'
        $mockSqlServerLogin3 = 'CONTOSO\SQLAdmin'
        $mockSqlServerLogin3Type = 'WindowsGroup'
        $mockSqlServerInvalidLogin = 'KingJulian'

        $mockSqlDatabaseRole1 = 'db_datareader'
        $mockSqlDatabaseRole2 = 'db_datawriter'
        $mockSqlDatabaseRole3 = 'NewRole'

        $mockEnumMembers1 = $mockSqlServerLogin1, $mockSqlServerLogin2
        $mockEnumMembers2 = , $mockSqlServerLogin1

        $mockExpectedSqlDatabaseRole = 'MyRole'

        $mockInvalidOperationForAddMemberMethod = $false
        $mockInvalidOperationForCreateMethod = $false
        $mockInvalidOperationForDropMethod = $false
        $mockInvalidOperationForDropMemberMethod = $false

        $mockExpectedMemberToAdd = 'MySecondRole'
        $mockExpectedMemberToDrop = 'MyRole'

        # Default parameters that are used for the It-blocks
        $mockDefaultParameters = @{
            ServerName   = $mockServerName
            InstanceName = $mockInstanceName
        }

        #region Function mocks
        $mockConnectSQL = {
            return @(
                (
                    New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name InstanceName -Value $mockInstanceName -PassThru |
                    Add-Member -MemberType NoteProperty -Name ComputerNamePhysicalNetBIOS -Value $mockServerName -PassThru |
                    Add-Member -MemberType ScriptProperty -Name Databases -Value {
                        return @{
                            $mockSqlDatabaseName = @((
                                    New-Object -TypeName Object |
                                    Add-Member -MemberType NoteProperty -Name Name -Value $mockSqlDatabaseName -PassThru |
                                    Add-Member -MemberType ScriptProperty -Name Users -Value {
                                        return @{
                                            $mockSqlServerLogin1 = @((
                                                    New-Object -TypeName Object |
                                                    Add-Member -MemberType ScriptMethod -Name IsMember -Value {
                                                        param
                                                        (
                                                            [Parameter()]
                                                            [System.String]
                                                            $Name
                                                        )
                                                        if ($Name -eq $mockExpectedSqlDatabaseRole)
                                                        {
                                                            return $true
                                                        }
                                                        else
                                                        {
                                                            return $false
                                                        }
                                                    } -PassThru
                                                ))
                                            $mockSqlServerLogin2 = @((
                                                    New-Object -TypeName Object |
                                                    Add-Member -MemberType ScriptMethod -Name IsMember -Value {
                                                        return $true
                                                    } -PassThru
                                                ))
                                            $mockSqlServerLogin3 = @((
                                                    New-Object -TypeName Object |
                                                    Add-Member -MemberType ScriptMethod -Name IsMember -Value {
                                                        return $true
                                                    } -PassThru
                                                ))

                                        }
                                    } -PassThru |
                                    Add-Member -MemberType ScriptProperty -Name Roles -Value {
                                        return @{
                                            $mockSqlDatabaseRole1 = @((
                                                    New-Object -TypeName Object |
                                                    Add-Member -MemberType NoteProperty -Name Name -Value $mockSqlDatabaseRole1 -PassThru |
                                                    Add-Member -MemberType ScriptMethod -Name AddMember -Value {
                                                        param
                                                        (
                                                            [Parameter()]
                                                            [System.String]
                                                            $Name
                                                        )
                                                        if ($mockInvalidOperationForAddMemberMethod)
                                                        {
                                                            throw 'Mock AddMember Method was called with invalid operation.'
                                                        }
                                                        if ($Name -ne $mockExpectedMemberToAdd)
                                                        {
                                                            throw "Called mocked AddMember() method without adding the right user. Expected '{0}'. But was '{1}'." `
                                                                -f $mockExpectedMemberToAdd, $Name
                                                        }
                                                    } -PassThru |
                                                    Add-Member -MemberType ScriptMethod -Name Drop -Value {
                                                        if ($mockInvalidOperationForDropMethod)
                                                        {
                                                            throw 'Mock Drop Method was called with invalid operation.'
                                                        }

                                                        if ($Name -ne $mockExpectedSqlDatabaseRole)
                                                        {
                                                            throw "Called mocked Drop() method without dropping the right database role. Expected '{0}'. But was '{1}'." `
                                                                -f $mockExpectedSqlDatabaseRole, $Name
                                                        }
                                                    } -PassThru |
                                                    Add-Member -MemberType ScriptMethod -Name DropMember -Value {
                                                        param
                                                        (
                                                            [Parameter()]
                                                            [System.String]
                                                            $Name
                                                        )
                                                        if ($mockInvalidOperationForDropMemberMethod)
                                                        {
                                                            throw 'Mock DropMember Method was called with invalid operation.'
                                                        }
                                                        if ($Name -ne $mockExpectedMemberToDrop)
                                                        {
                                                            throw "Called mocked Drop() method without adding the right user. Expected '{0}'. But was '{1}'." `
                                                                -f $mockExpectedMemberToDrop, $Name
                                                        }
                                                    } -PassThru |
                                                    Add-Member -MemberType ScriptMethod -Name EnumMembers -Value {
                                                        if ($mockInvalidOperationForEnumMethod)
                                                        {
                                                            throw 'Mock EnumMembers Method was called with invalid operation.'
                                                        }
                                                        else
                                                        {
                                                            $mockEnumMembers1
                                                        }
                                                    } -PassThru |
                                                    Add-Member -MemberType ScriptMethod -Name EnumMembers -Value {
                                                        if ($mockInvalidOperationForEnumMethod)
                                                        {
                                                            throw 'Mock EnumMembers Method was called with invalid operation.'
                                                        }
                                                        else
                                                        {
                                                            $mockEnumMembers2
                                                        }
                                                    } -PassThru
                                                ))
                                            $mockSqlDatabaseRole2 = @((
                                                    New-Object -TypeName Object |
                                                    Add-Member -MemberType NoteProperty -Name Name -Value $mockSqlDatabaseRole2 -PassThru |
                                                    Add-Member -MemberType ScriptMethod -Name AddMember -Value {
                                                        param
                                                        (
                                                            [Parameter()]
                                                            [System.String]
                                                            $Name
                                                        )
                                                        if ($mockInvalidOperationForAddMemberMethod)
                                                        {
                                                            throw 'Mock AddMember Method was called with invalid operation.'
                                                        }
                                                        if ($Name -ne $mockExpectedMemberToAdd)
                                                        {
                                                            throw "Called mocked AddMember() method without adding the right user. Expected '{0}'. But was '{1}'." `
                                                                -f $mockExpectedMemberToAdd, $Name
                                                        }
                                                    } -PassThru |
                                                    Add-Member -MemberType ScriptMethod -Name DropMember -Value {
                                                        param
                                                        (
                                                            [Parameter()]
                                                            [System.String]
                                                            $Name
                                                        )
                                                        if ($mockInvalidOperationForDropMemberMethod)
                                                        {
                                                            throw 'Mock DropMember Method was called with invalid operation.'
                                                        }
                                                        if ($Name -ne $mockExpectedMemberToDrop)
                                                        {
                                                            throw "Called mocked Drop() method without adding the right user. Expected '{0}'. But was '{1}'." `
                                                                -f $mockExpectedMemberToDrop, $Name
                                                        }
                                                    } -PassThru
                                                ))
                                        }
                                    }-PassThru -Force
                                ))
                        }
                    } -PassThru -Force |
                    Add-Member -MemberType ScriptProperty -Name Logins -Value {
                        return @{
                            $mockSqlServerLogin1 = @((
                                    New-Object -TypeName Object |
                                    Add-Member -MemberType NoteProperty -Name LoginType -Value $mockSqlServerLogin1Type -PassThru
                                ))
                            $mockSqlServerLogin2 = @((
                                    New-Object -TypeName Object |
                                    Add-Member -MemberType NoteProperty -Name LoginType -Value $mockSqlServerLogin2Type -PassThru
                                ))
                            $mockSqlServerLogin3 = @((
                                    New-Object -TypeName Object |
                                    Add-Member -MemberType NoteProperty -Name LoginType -Value $mockSqlServerLogin3Type -PassThru
                                ))
                        }
                    } -PassThru -Force

                )
            )
        }

        $mockNewObjectDatabaseRole = {
            return @(
                New-Object -TypeName Object |
                Add-Member -MemberType NoteProperty -Name Name -Value $mockExpectedSqlDatabaseRole -PassThru |
                Add-Member -MemberType ScriptMethod -Name Create -Value {
                    if ($mockInvalidOperationForCreateMethod)
                    {
                        throw 'Mock Create Method was called with invalid operation.'
                    }
                    if ($this.Name -ne $mockExpectedSqlDatabaseRole)
                    {
                        throw "Called mocked Create() method without adding the right user. Expected '{0}'. But was '{1}'." `
                            -f $mockExpectedSqlDatabaseRole, $this.Name
                    }
                } -PassThru -Force
            )
        }
        #endregion

        Describe 'MSFT_SqlDatabaseUserRole\Get-TargetResource' -Tag 'Get' {
            BeforeEach {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
            }

            Context 'When only key parameters have values and database name does not exist' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    DatabaseName = 'unknownDatabaseName'
                    UserName     = $mockSqlServerLogin1
                }

                It 'Should throw the correct error' {
                    $errorMessage = $script:localizedData.DatabaseNotFound -f $testParameters.DatabaseName

                    { Get-TargetResource @testParameters } | Should -Throw $errorMessage
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When only key parameters have values and the user does not exist' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    DatabaseName = $mockSqlDatabaseName
                    UserName     = 'UnknownUserName'
                }

                It 'Should return the role names as null' {
                    $result = Get-TargetResource @testParameters
                    $result.RoleNames | Should -BeNullOrEmpty

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                It 'Should return the same values as passed as parameters' {
                    $result = Get-TargetResource @testParameters
                    $result.ServerName   | Should -Be $testParameters.ServerName
                    $result.InstanceName | Should -Be $testParameters.InstanceName
                    $result.DatabaseName | Should -Be $testParameters.DatabaseName
                    $result.UserName     | Should -Be $testParameters.UserName

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When only key parameters have values and the user exists' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    DatabaseName = $mockSqlDatabaseName
                    UserName     = $mockSqlServerLogin1
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When only key parameters have values and throwing with EnumMembers method' {
                $mockInvalidOperationForEnumMethod = $true
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    DatabaseName = $mockSqlDatabaseName
                    UserName     = $mockSqlServerLogin1
                }

                It 'Should throw the correct error' {
                    $errorMessage = $script:localizedData.EnumDatabaseRoleMemberNamesError -f $mockSqlDatabaseRole1, $mockSqlDatabaseName

                    { Get-TargetResource @testParameters } | Should -Throw $errorMessage
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When parameter RoleNamesToEnforce is assigned a value, the user exists, and the role members are in the desired state' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    DatabaseName       = $mockSqlDatabaseName
                    UserName           = $mockSqlServerLogin1
                    RoleNamesToEnforce = 'db_datareader', 'db_datawriter'
                }

                It 'Should return the role names as not null' {
                    $result = Get-TargetResource @testParameters
                    $result.RoleNames | Should -Be $testParameters.RoleNames

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                It 'Should return the role names as string array' {
                    $result = Get-TargetResource @testParameters
                    ($result.RoleNames -is [System.String[]]) | Should -Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                It 'Should return the same values as passed as parameters' {
                    $result = Get-TargetResource @testParameters
                    $result.ServerName   | Should -Be $testParameters.ServerName
                    $result.InstanceName | Should -Be $testParameters.InstanceName
                    $result.DatabaseName | Should -Be $testParameters.DatabaseName
                    $result.UserName     | Should -Be $testParameters.UserName
                    $result.RoleNames    | Should -Be $testParameters.RoleNames

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When parameter RoleNamesToEnforce is assigned a value, the user exists, and there are fewer roles than the ones to be enforced' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    DatabaseName       = $mockSqlDatabaseName
                    UserName           = $mockSqlServerLogin2
                    RoleNamesToEnforce = 'db_datareader', 'db_datawriter'
                }

                It 'Should return the role names as string array' {
                    $result = Get-TargetResource @testParameters
                    ($result.RoleNames -is [System.String[]]) | Should -Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When parameter RoleNamesToEnforce is assigned a value, the user exists, and there are more roles than the ones to be enforced' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    DatabaseName       = $mockSqlDatabaseName
                    UserName           = $mockSqlServerLogin1
                    RoleNamesToEnforce = , 'db_datareader'
                }

                It 'Should return the role names as string array' {
                    $result = Get-TargetResource @testParameters
                    ($result.RoleNames -is [System.String[]]) | Should -Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

<# TO DO: error is thrown by PowerShell
            Context 'When both parameters RoleNamesToEnforce and RoleNamesToInclude are assigned a value' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    DatabaseName       = $mockSqlDatabaseName
                    UserName           = $mockSqlServerLogin1
                    RoleNamesToEnforce = , 'db_datareader'
                    RoleNamesToInclude = , 'db_datawriter'
                }

                It 'Should throw the correct error' {
                    $errorMessage = $script:localizedData.RoleNamesToIncludeAndExcludeParamMustBeNull

                    { Get-TargetResource @testParameters } | Should -Throw $errorMessage
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }
#>

            Context 'When parameter RoleNamesToInclude is assigned a value, the user exists, and there are more role members than the ones to be included' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    DatabaseName       = $mockSqlDatabaseName
                    UserName           = $mockSqlServerLogin1
                    RoleNamesToInclude = 'db_datareader'
                }

                It 'Should return the role names as not null' {
                    $result = Get-TargetResource @testParameters
                    $result.RoleNames | Should -Not -BeNullOrEmpty

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                It 'Should return the role names as string array' {
                    $result = Get-TargetResource @testParameters
                    ($result.RoleNames -is [System.String[]]) | Should -Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                It 'Should return the same values as passed as parameters' {
                    $result = Get-TargetResource @testParameters
                    $result.ServerName         | Should -Be $testParameters.ServerName
                    $result.InstanceName       | Should -Be $testParameters.InstanceName
                    $result.DatabaseName       | Should -Be $testParameters.DatabaseName
                    $result.UserName           | Should -Be $testParameters.UserName
                    $result.RoleNamesToInclude | Should -Be $testParameters.RoleNamesToInclude

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When parameter RoleNamesToInclude is assigned a value, the user exists, and there are fewer role members than the ones to be included' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    DatabaseName       = $mockSqlDatabaseName
                    UserName           = $mockSqlServerLogin1
                    RoleNamesToInclude = 'db_datareader', 'db_datawriter'
                }

                It 'Should return the role names as string array' {
                    $result = Get-TargetResource @testParameters
                    ($result.RoleNames -is [System.String[]]) | Should -Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When both parameters RoleNamesToEnforce and RoleNamesToExclude are assigned a value' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    DatabaseName       = $mockSqlDatabaseName
                    UserName           = $mockSqlServerLogin1
                    RoleNamesToEnforce = , 'db_datareader'
                    RoleNamesToExclude = , 'db_datawriter'
                }

                It 'Should throw the correct error' {
                    $errorMessage = $script:localizedData.RoleNamesToIncludeAndExcludeParamMustBeNull

                    { Get-TargetResource @testParameters } | Should -Throw $errorMessage
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
                }

            }

            Context 'When parameter RoleNamesToExclude is assigned a value, the user exists, and the role members are in the desired state' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    DatabaseName       = $mockSqlDatabaseName
                    UserName           = $mockSqlServerLogin2
                    RoleNamesToExclude = 'db_datawriter'
                }

                It 'Should return the same values as passed as parameters' {
                    $result = Get-TargetResource @testParameters
                    $result.ServerName         | Should -Be $testParameters.ServerName
                    $result.InstanceName       | Should -Be $testParameters.InstanceName
                    $result.DatabaseName       | Should -Be $testParameters.DatabaseName
                    $result.UserName           | Should -Be $testParameters.UserName
                    $result.RoleNamesToExclude | Should -Be $testParameters.RoleNamesToExclude

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When parameter RoleNamesToExclude is assigned a value, the user exists, and the role members are not in the desired state' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    DatabaseName       = $mockSqlDatabaseName
                    UserName           = $mockSqlServerLogin1
                    RoleNamesToExclude = 'db_datawriter'
                }

                It 'Should return the role names as string array' {
                    $result = Get-TargetResource @testParameters
                    ($result.RoleNames -is [System.String[]]) | Should -Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Assert-VerifiableMock
        }

        Describe "MSFT_SqlDatabaseUserRole\Set-TargetResource" -Tag 'Set' {
            BeforeEach {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
                Mock -CommandName New-Object -MockWith $mockNewObjectDatabaseRole -ParameterFilter {
                    $TypeName -eq 'Microsoft.SqlServer.Management.Smo.DatabaseRole'
                }
            }

            Context 'When parameter RoleNamesToEnforce is assigned a value' {
                It 'Should throw the correct error when database role does not exist' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        DatabaseName       = $mockSqlDatabaseName
                        UserName           = $mockSqlServerLogin1
                        RoleNamesToEnforce = , 'db_unknown-role'
                    }

                    $errorMessage = $script:localizedData.DatabaseRoleNotFound -f 'db_unknown-role', $mockSqlDatabaseName

                    { Set-TargetResource @testParameters } | Should -Throw $errorMessage

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When both parameters RoleNamesToEnforce and RoleNamesToInclude are assigned a value' {
                It 'Should throw the correct error' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        DatabaseName       = $mockSqlDatabaseName
                        UserName           = $mockSqlServerLogin2
                        RoleNamesToEnforce = 'db_datareader', 'db_datawriter'
                        RoleNamesToInclude = , 'db_datareader'
                    }

                    $errorMessage = $script:localizedData.RoleNamesToIncludeAndExcludeParamMustBeNull

                    { Set-TargetResource @testParameters } | Should -Throw $errorMessage

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When parameter RoleNamesToInclude is assigned a value, parameter RoleNamesToEnforce is not assigned a value' {
                It 'Should throw the correct error when the database user does not exist' {
                    $mockExpectedMemberToAdd = $mockSqlServerLogin3
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        DatabaseName       = $mockSqlDatabaseName
                        UserName           = $mockSqlServerLogin1
                        RoleNamesToInclude = $mockSqlServerInvalidLogin
                    }

                    $errorMessage = $script:localizedData.DatabaseUserNotFound -f $mockSqlServerInvalidLogin, $mockSqlDatabaseName

                    { Set-TargetResource @testParameters } | Should -Throw $errorMessage

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                It 'Should not throw when calling the AddMember method' {
                    $mockExpectedMemberToAdd = $mockSqlServerLogin2
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        DatabaseName       = $mockSqlDatabaseName
                        UserName           = $mockSqlServerLogin2
                        RoleNamesToInclude = 'db_datawriter'
                    }

                    { Set-TargetResource @testParameters } | Should -Not -Throw

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                It 'Should throw the correct error when calling the AddMember method' {
                    $mockInvalidOperationForAddMemberMethod = $true
                    $mockExpectedMemberToAdd = $mockSqlServerLogin2
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        DatabaseName       = $mockSqlDatabaseName
                        UserName           = $mockSqlServerLogin2
                        RoleNamesToInclude = 'db_datawriter'
                    }

                    $errorMessage = $script:localizedData.AddDatabaseRoleMemberError -f $mockSqlServerLogin3, $mockSqlDatabaseRole1, $mockSqlDatabaseName

                    { Set-TargetResource @testParameters } | Should -Throw $errorMessage

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When both parameters RoleNamesToEnforce and RoleNamesToExclude are assigned a value' {
                It 'Should throw the correct error' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        DatabaseName       = $mockSqlDatabaseName
                        UserName           = $mockSqlServerLogin1
                        RoleNamesToEnforce = 'db_datareader'
                        RoleNamesToExclude = 'db_datawriter'
                    }

                    $errorMessage = $script:localizedData.RoleNamesToIncludeAndExcludeParamMustBeNull

                    { Set-TargetResource @testParameters } | Should -Throw $errorMessage

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When parameter RoleNamesToExclude is assigned a value, parameter RoleNamesToEnforce is not assigned a value' {
                It 'Should not throw when calling the DropMember method' {
                    $mockExpectedMemberToDrop = $mockSqlServerLogin1
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        DatabaseName       = $mockSqlDatabaseName
                        UserName           = $mockSqlServerLogin1
                        RoleNamesToExclude = 'db_datawriter'
                    }

                    { Set-TargetResource @testParameters } | Should -Not -Throw

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                It 'Should throw the correct error when calling the DropMember method' {
                    $mockInvalidOperationForDropMemberMethod = $true
                    $mockExpectedMemberToDrop = $mockSqlServerLogin1
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        DatabaseName       = $mockSqlDatabaseName
                        UserName           = $mockSqlServerLogin1
                        RoleNamesToExclude = 'db_datawriter'
                    }

                    $errorMessage = $script:localizedData.DropDatabaseRoleMemberError -f $mockSqlServerLogin2, $mockSqlDatabaseRole1, $mockSqlDatabaseName

                    { Set-TargetResource @testParameters } | Should -Throw $errorMessage

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Assert-VerifiableMock
        }

        Describe "MSFT_SqlDatabaseUserRole\Test-TargetResource" -Tag 'Test' {
            BeforeEach {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
            }

            Context 'When the system is not in the desired state' {
                It 'Should return True when the desired database role does not exist' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        DatabaseName = $mockSqlDatabaseName
                        UserName     = $mockSqlServerLogin1
                        Name         = $mockSqlDatabaseRole3
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the system is in the desired state' {
                It 'Should return True when the desired database role exists' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        DatabaseName = $mockSqlDatabaseName
                        UserName     = $mockSqlServerLogin1
                        Name         = $mockSqlDatabaseRole1
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When parameter RoleNamesToEnforce is assigned a value' {
                It 'Should return False when the desired members are not in the desired database role' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        DatabaseName       = $mockSqlDatabaseName
                        UserName           = $mockSqlServerLogin2
                        RoleNamesToEnforce = 'db_datareader', 'db_datawriter'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When both parameters RoleNamesToEnforce and RoleNamesToInclude are assigned a value' {
                It 'Should throw the correct error' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        DatabaseName       = $mockSqlDatabaseName
                        UserName           = $mockSqlServerLogin1
                        RoleNamesToEnforce = 'db_datareader', 'db_datawriter'
                        RoleNamesToInclude = 'db_datareader'
                    }

                    $errorMessage = $script:localizedData.RoleNamesToIncludeAndExcludeParamMustBeNull

                    { Test-TargetResource @testParameters } | Should -Throw $errorMessage
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When parameter RoleNamesToInclude is assigned a value, parameter RoleNamesToEnforce is not assigned a value' {
<#
                It 'Should return False when desired database role does not exist' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        DatabaseName       = $mockSqlDatabaseName
                        UserName           = $mockSqlServerLogin2
                        RoleNamesToInclude = 'db_unknown-role'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
#>

                It 'Should return True when the desired database role exists and the RoleNamesToInclude contains members that already exist' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        DatabaseName       = $mockSqlDatabaseName
                        UserName           = $mockSqlServerLogin1
                        RoleNamesToInclude = 'db_datawriter'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                It 'Should return False when the desired database role exists and the RoleNamesToInclude contains members that are missing' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        DatabaseName       = $mockSqlDatabaseName
                        UserName           = $mockSqlServerLogin2
                        RoleNamesToInclude = 'db_datawriter'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When both parameters RoleNamesToEnforce and RoleNamesToExclude are assigned a value' {
                It 'Should throw the correct error' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        DatabaseName       = $mockSqlDatabaseName
                        UserName           = $mockSqlServerLogin1
                        RoleNamesToEnforce = , 'db_datareader'
                        RoleNamesToExclude = , 'db_datawriter'
                    }

                    $errorMessage = $script:localizedData.RoleNamesToIncludeAndExcludeParamMustBeNull

                    { Test-TargetResource @testParameters } | Should -Throw $errorMessage
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When parameter RoleNamesToExclude is assigned a value, parameter Members is not assigned a value' {
                It 'Should return False when desired database role does not exist' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        DatabaseName       = $mockSqlDatabaseName
                        UserName           = $mockSqlServerLogin1
                        RoleNamesToExclude = 'db_datawriter'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                It 'Should return True when the desired database role exists and the RoleNamesToExclude contains members that do not yet exist' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        DatabaseName       = $mockSqlDatabaseName
                        UserName           = $mockSqlServerLogin2
                        RoleNamesToExclude = 'db_datawriter'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $true

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                It 'Should return False when the desired database role exists and the RoleNamesToExclude contains members that already exist' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        DatabaseName       = $mockSqlDatabaseName
                        UserName           = $mockSqlServerLogin1
                        RoleNamesToExclude = 'db_datawriter'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $false

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
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
