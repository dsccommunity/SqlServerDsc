<#
    .SYNOPSIS
        Unit test for DSC_SqlDatabasePermission DSC resource.
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
                # Redirect all streams to $null, except the error stream (stream 3)
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
    $script:dscResourceName = 'DSC_SqlDatabasePermission'

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

Describe 'SqlDatabasePermission\Get-TargetResource' -Tag 'Get' {
    BeforeAll {
        $mockConnectSQL = {
            return @(
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType 'ScriptProperty' -Name 'Databases' -Value {
                        return @{
                            'AdventureWorks' = @(
                                (
                                    New-Object -TypeName Object |
                                        Add-Member -MemberType 'NoteProperty' -Name Name -Value 'AdventureWorks' -PassThru |
                                        Add-Member -MemberType 'ScriptProperty' -Name 'Users' -Value {
                                            return @{
                                                'Zebes\SamusAran' = @(
                                                    (
                                                        New-Object -TypeName Object |
                                                            Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'Zebes\SamusAran' -PassThru -Force
                                                    )
                                                )
                                            }
                                        } -PassThru |
                                        Add-Member -MemberType 'ScriptProperty' -Name 'ApplicationRoles' -Value {
                                            return @{
                                                'MyAppRole' = @(
                                                    (
                                                        New-Object -TypeName Object |
                                                            Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'MyAppRole' -PassThru -Force
                                                    )
                                                )
                                            }
                                        } -PassThru |
                                        Add-Member -MemberType 'ScriptProperty' -Name 'Roles' -Value {
                                            return @{
                                                'public' = @(
                                                    (
                                                        New-Object -TypeName Object |
                                                            Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'public' |
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

                                            if ( $SqlServerLogin -eq 'Zebes\SamusAran' )
                                            {
                                                $mockEnumDatabasePermissions = @()
                                                $mockEnumDatabasePermissions += New-Object -TypeName Object |
                                                    Add-Member -MemberType NoteProperty -Name PermissionType -Value (New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionSet' -ArgumentList @($true, $false)) -PassThru |
                                                    Add-Member -MemberType NoteProperty -Name PermissionState -Value 'Grant' -PassThru |
                                                    Add-Member -MemberType NoteProperty -Name Grantee -Value 'Zebes\SamusAran' -PassThru |
                                                    Add-Member -MemberType NoteProperty -Name GrantorType -Value 'User' -PassThru |
                                                    Add-Member -MemberType NoteProperty -Name ObjectClass -Value 'DatabaseName' -PassThru |
                                                    Add-Member -MemberType NoteProperty -Name ObjectName -Value 'AdventureWorks' -PassThru
                                                $mockEnumDatabasePermissions += New-Object -TypeName Object |
                                                    Add-Member -MemberType NoteProperty -Name PermissionType -Value $(New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionSet' -ArgumentList @($false, $true)) -PassThru |
                                                    Add-Member -MemberType NoteProperty -Name PermissionState -Value 'Grant' -PassThru |
                                                    Add-Member -MemberType NoteProperty -Name Grantee -Value 'Zebes\SamusAran' -PassThru |
                                                    Add-Member -MemberType NoteProperty -Name GrantorType -Value 'User' -PassThru |
                                                    Add-Member -MemberType NoteProperty -Name ObjectClass -Value 'DatabaseName' -PassThru |
                                                    Add-Member -MemberType NoteProperty -Name ObjectName -Value 'AdventureWorks' -PassThru

                                                $mockEnumDatabasePermissions
                                            }
                                            else
                                            {
                                                return $null
                                            }
                                        } -PassThru -Force
                                )
                            )
                        }
                    } -PassThru -Force
                )
            )
        }

        Mock -CommandName Connect-SQL -MockWith $mockConnectSQL

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
        Context 'When the desired permission does exist' {
            BeforeEach {
                InModuleScope -ScriptBlock {
                    $mockGetTargetResourceParameters.DatabaseName    = 'AdventureWorks'
                    $mockGetTargetResourceParameters.Name            = 'Zebes\SamusAran'
                    $mockGetTargetResourceParameters.PermissionState = 'Grant'
                    $mockGetTargetResourceParameters.Permissions     = @( 'Connect', 'Update' )
                }
            }

            It 'Should return the state as present' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.Ensure | Should -Be 'Present'

                    Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            It 'Should return the same values as passed as parameters' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.ServerName | Should -Be $mockGetTargetResourceParameters.ServerName
                    $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                    $result.ServerRoleName | Should -Be $mockGetTargetResourceParameters.ServerRoleName
                }

                Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the desired permission does not exist' {
            BeforeEach {
                InModuleScope -ScriptBlock {
                    $mockGetTargetResourceParameters.DatabaseName    = 'AdventureWorks'
                    $mockGetTargetResourceParameters.Name            = 'Zebes\SamusAran'
                    $mockGetTargetResourceParameters.PermissionState = 'Grant'
                    $mockGetTargetResourceParameters.Permissions     = @( 'Connect', 'Update', 'Select' )
                }
            }

            It 'Should not return the state as absent' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.Ensure | Should -Not -Be 'Present'
                }

                Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
            }

            It 'Should return the same values as passed as parameters' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.ServerName | Should -Be $mockGetTargetResourceParameters.ServerName
                    $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                    $result.ServerRoleName | Should -Be $mockGetTargetResourceParameters.ServerRoleName
                }

                Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When the system is not in the desired state' {
        Context 'When passing values to parameters and database does not exist' {
            It 'Should throw the correct error' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockGetTargetResourceParameters.DatabaseName    = 'unknownDatabaseName'
                    $mockGetTargetResourceParameters.Name            = 'Zebes\SamusAran'
                    $mockGetTargetResourceParameters.PermissionState = 'Grant'
                    $mockGetTargetResourceParameters.Permissions     = @( 'Connect', 'Update' )

                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.Ensure | Should -Be 'Absent'
                }

                Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
            }
        }

        Context 'When permissions are missing' {
            BeforeEach {
                InModuleScope -ScriptBlock {
                    $mockGetTargetResourceParameters.DatabaseName    = 'AdventureWorks'
                    $mockGetTargetResourceParameters.Name            = 'Zebes\SamusAran'
                    $mockGetTargetResourceParameters.PermissionState = 'Grant'
                    $mockGetTargetResourceParameters.Permissions     = @( 'Connect', 'Update', 'Select' )
                }
            }

            It 'Should return the state as absent' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.Ensure | Should -Be 'Absent'
                }

                Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
            }

            It 'Should return the same values as passed as parameters' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.ServerName | Should -Be $mockGetTargetResourceParameters.ServerName
                    $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                    $result.ServerRoleName | Should -Be $mockGetTargetResourceParameters.ServerRoleName
                }

                Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the desired permission does not exist' {
            BeforeEach {
                InModuleScope -ScriptBlock {
                    $mockGetTargetResourceParameters.DatabaseName    = 'AdventureWorks'
                    $mockGetTargetResourceParameters.Name            = 'Zebes\SamusAran'
                    $mockGetTargetResourceParameters.PermissionState = 'Grant'
                    $mockGetTargetResourceParameters.Permissions     = @( 'Connect', 'Update' )
                }
            }

            It 'Should not return the state as absent' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.Ensure | Should -Not -Be 'Absent'
                }

                Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
            }

            It 'Should return the same values as passed as parameters' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.ServerName | Should -Be $mockGetTargetResourceParameters.ServerName
                    $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                    $result.ServerRoleName | Should -Be $mockGetTargetResourceParameters.ServerRoleName
                }

                Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
            }
        }
    }
}

Describe "SqlDatabasePermission\Test-TargetResource" -Tag 'Test' {
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
        Context 'When the desired permission should exist' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        ServerName      = 'localhost'
                        InstanceName    = 'MSSQLSERVER'
                        Name            = 'Zebes\SamusAran'
                        PermissionState = 'Grant'
                        Permissions     = @( 'Connect', 'Update' )
                        Ensure          = 'Present'
                    }
                }
            }

            It 'Should return $true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.DatabaseName    = 'AdventureWorks'
                    $mockTestTargetResourceParameters.Name            = 'Zebes\SamusAran'
                    $mockTestTargetResourceParameters.PermissionState = 'Grant'
                    $mockTestTargetResourceParameters.Permissions     = @( 'Connect', 'Update' )
                    $mockTestTargetResourceParameters.Ensure          = 'Present'

                    $result = Test-TargetResource @mockTestTargetResourceParameters -Verbose

                    $result | Should -BeTrue
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the desired permission should not exist' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        ServerName      = 'localhost'
                        InstanceName    = 'MSSQLSERVER'
                        Name            = 'Zebes\SamusAran'
                        PermissionState = 'Grant'
                        Permissions     = @()
                        Ensure          = 'Absent'
                    }
                }
            }

            It 'Should return $true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.DatabaseName    = 'AdventureWorks'
                    $mockTestTargetResourceParameters.Name            = 'Zebes\SamusAran'
                    $mockTestTargetResourceParameters.PermissionState = 'Grant'
                    $mockTestTargetResourceParameters.Permissions     = @( 'Connect', 'Update' )
                    $mockTestTargetResourceParameters.Ensure          = 'Absent'

                    Test-TargetResource @mockTestTargetResourceParameters | Should -BeTrue
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When the system is not in the desired state' {
        Context 'When the desired permission are missing' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        ServerName      = 'localhost'
                        InstanceName    = 'MSSQLSERVER'
                        Name            = 'Zebes\SamusAran'
                        PermissionState = 'Grant'
                        Permissions     = @( 'Connect', 'Update' )
                        Ensure          = 'Absent'
                    }
                }
            }

            It 'Should return the state as true ' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.DatabaseName    = 'AdventureWorks'
                    $mockTestTargetResourceParameters.Name            = 'Zebes\SamusAran'
                    $mockTestTargetResourceParameters.PermissionState = 'Grant'
                    $mockTestTargetResourceParameters.Permissions     = @( 'Connect', 'Update', 'Select' )
                    $mockTestTargetResourceParameters.Ensure          = 'Present'

                    Test-TargetResource @mockTestTargetResourceParameters | Should -BeFalse
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }

        Context 'When there are more permissions than desired' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        ServerName      = 'localhost'
                        InstanceName    = 'MSSQLSERVER'
                        Name            = 'Zebes\SamusAran'
                        PermissionState = 'Grant'
                        Permissions     = @( 'Connect', 'Update' )
                        Ensure          = 'Absent'
                    }
                }
            }

            It 'Should return the state as true ' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.DatabaseName    = 'AdventureWorks'
                    $mockTestTargetResourceParameters.Name            = 'Zebes\SamusAran'
                    $mockTestTargetResourceParameters.PermissionState = 'Grant'
                    $mockTestTargetResourceParameters.Permissions     = @( 'Connect' )
                    $mockTestTargetResourceParameters.Ensure          = 'Present'

                    Test-TargetResource @mockTestTargetResourceParameters | Should -BeFalse
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }
    }
}

Describe "DSC_SqlDatabasePermission\Set-TargetResource" -Tag 'Set' {
    BeforeAll {
        $mockConnectSQL = {
            return @(
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType 'ScriptProperty' -Name 'Databases' -Value {
                        return @{
                            'AdventureWorks' = @(
                                (
                                    New-Object -TypeName Object |
                                        Add-Member -MemberType 'NoteProperty' -Name Name -Value 'AdventureWorks' -PassThru |
                                        Add-Member -MemberType 'ScriptProperty' -Name 'Users' -Value {
                                            return @{
                                                'Zebes\SamusAran' = @(
                                                    (
                                                        New-Object -TypeName Object |
                                                            Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'Zebes\SamusAran' -PassThru -Force
                                                    )
                                                )
                                            }
                                        } -PassThru |
                                        Add-Member -MemberType 'ScriptProperty' -Name 'ApplicationRoles' -Value {
                                            return @{
                                                'MyAppRole' = @(
                                                    (
                                                        New-Object -TypeName Object |
                                                            Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'MyAppRole' -PassThru -Force
                                                    )
                                                )
                                            }
                                        } -PassThru |
                                        Add-Member -MemberType 'ScriptProperty' -Name 'Roles' -Value {
                                            return @{
                                                'public' = @(
                                                    (
                                                        New-Object -TypeName Object |
                                                            Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'public' |
                                                            Add-Member -MemberType 'NoteProperty' -Name 'IsFixedRole' -Value $true -PassThru -Force
                                                    )
                                                )
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

                                            if ($mockInvalidOperationForGrantMethod)
                                            {
                                                throw 'Mocked InvalidOperationException'
                                            }

                                            InModuleScope -ScriptBlock {
                                                $script:mockMethodGrantWasRan += 1
                                            }

                                            # Make sure the method is called with the expected login
                                            if ( $SqlServerLogin -ne 'Zebes\SamusAran' )
                                            {
                                                throw "Called mocked Grant() method without setting the right login name. Expected '{0}'. But was '{1}'." `
                                                    -f 'Zebes\SamusAran', $SqlServerLogin
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

                                            if ($mockInvalidOperationForRevokeMethod)
                                            {
                                                throw 'Mocked InvalidOperationException'
                                            }

                                            InModuleScope -ScriptBlock {
                                                $script:mockMethodRevokeWasRan += 1
                                            }

                                            # Make sure the method is called with the expected login
                                            if ( $SqlServerLogin -ne 'Zebes\SamusAran' )
                                            {
                                                throw "Called mocked Revoke() method without setting the right login name. Expected '{0}'. But was '{1}'." `
                                                    -f 'Zebes\SamusAran', $SqlServerLogin
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

                                            if ($mockInvalidOperationForDenyMethod)
                                            {
                                                throw 'Mocked InvalidOperationException'
                                            }

                                            InModuleScope -ScriptBlock {
                                                $script:mockMethodDenyWasRan += 1
                                            }

                                            # Make sure the method is called with the expected login
                                            if ( $SqlServerLogin -ne 'Zebes\SamusAran' )
                                            {
                                                throw "Called mocked Deny() method without setting the right login name. Expected '{0}'. But was '{1}'." `
                                                    -f 'Zebes\SamusAran', $SqlServerLogin
                                            }
                                        } -PassThru -Force
                                )
                            )
                        }
                    } -PassThru -Force
                )
            )
        }

        Mock -CommandName Connect-SQL -MockWith $mockConnectSQL

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
            $script:mockSetTargetResourceParameters = $script:mockDefaultParameters.Clone()

            $script:mockMethodGrantWasRan = 0
            $script:mockMethodDenyWasRan = 0
            $script:mockMethodRevokeWasRan = 0
            $script:mockMethodCreateWasRan = 0
        }
    }

    Context 'When passing values to parameters and database name does not exist' {
        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockSetTargetResourceParameters.DatabaseName    = 'unknownDatabaseName'
                $mockSetTargetResourceParameters.Name            = 'Zebes\SamusAran'
                $mockSetTargetResourceParameters.PermissionState = 'Grant'
                $mockSetTargetResourceParameters.Permissions     = @( 'Connect', 'Update' )
                $mockSetTargetResourceParameters.Ensure          = 'Present'

                $errorMessage = $script:localizedData.DatabaseNotFound -f $mockSetTargetResourceParameters.DatabaseName

                { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw ('*' + $errorMessage)
            }

            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }
    }

    Context 'When passing values to parameters and database user does not exist' {
        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockSetTargetResourceParameters.DatabaseName    = 'AdventureWorks'
                $mockSetTargetResourceParameters.Name            = 'unknownLoginNamen'
                $mockSetTargetResourceParameters.PermissionState = 'Grant'
                $mockSetTargetResourceParameters.Permissions     = @( 'Connect', 'Update' )
                $mockSetTargetResourceParameters.Ensure          = 'Present'

                $errorMessage = $script:localizedData.NameIsMissing -f $mockSetTargetResourceParameters.Name, 'AdventureWorks'

                { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw ('*' + $errorMessage)
            }

            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the system is not in the desired state' {
        Context 'When Ensure is set to Present' {
            It 'Should call the method Grant() without throwing' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters.DatabaseName    = 'AdventureWorks'
                    $mockSetTargetResourceParameters.Name            = 'Zebes\SamusAran'
                    $mockSetTargetResourceParameters.PermissionState = 'Grant'
                    $mockSetTargetResourceParameters.Permissions     = @( 'Connect', 'Update' )
                    $mockSetTargetResourceParameters.Ensure          = 'Present'

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                    $script:mockMethodGrantWasRan | Should -Be 1
                    $script:mockMethodDenyWasRan | Should -Be 0
                    $script:mockMethodRevokeWasRan | Should -Be 0
                }

                Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
            }

            It 'Should call the method Grant() (WithGrant) without throwing' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters.DatabaseName    = 'AdventureWorks'
                    $mockSetTargetResourceParameters.Name            = 'Zebes\SamusAran'
                    $mockSetTargetResourceParameters.PermissionState = 'GrantWithGrant'
                    $mockSetTargetResourceParameters.Permissions     = @( 'Connect', 'Update' )
                    $mockSetTargetResourceParameters.Ensure          = 'Present'

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                    $script:mockMethodGrantWasRan | Should -Be 1
                    $script:mockMethodDenyWasRan | Should -Be 0
                    $script:mockMethodRevokeWasRan | Should -Be 0
                }

                Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
            }

            It 'Should call the method Deny() without throwing' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters.DatabaseName    = 'AdventureWorks'
                    $mockSetTargetResourceParameters.Name            = 'Zebes\SamusAran'
                    $mockSetTargetResourceParameters.PermissionState = 'Deny'
                    $mockSetTargetResourceParameters.Permissions     = @( 'Connect', 'Update' )
                    $mockSetTargetResourceParameters.Ensure          = 'Present'

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                    $script:mockMethodGrantWasRan | Should -Be 0
                    $script:mockMethodDenyWasRan | Should -Be 1
                    $script:mockMethodRevokeWasRan | Should -Be 0
                }

                Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
            }
        }

        Context 'When Ensure is set to Absent' {
            It 'Should call the method Revoke() for permission state ''Grant'' without throwing' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters.DatabaseName    = 'AdventureWorks'
                    $mockSetTargetResourceParameters.Name            = 'Zebes\SamusAran'
                    $mockSetTargetResourceParameters.PermissionState = 'Grant'
                    $mockSetTargetResourceParameters.Permissions     = @( 'Connect', 'Update' )
                    $mockSetTargetResourceParameters.Ensure          = 'Absent'

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                    $script:mockMethodGrantWasRan | Should -Be 0
                    $script:mockMethodDenyWasRan | Should -Be 0
                    $script:mockMethodRevokeWasRan | Should -Be 1
                }

                Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
            }

            It 'Should call the method Revoke() for permission state ''GrantWithGrant'' without throwing' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters.DatabaseName    = 'AdventureWorks'
                    $mockSetTargetResourceParameters.Name            = 'Zebes\SamusAran'
                    $mockSetTargetResourceParameters.PermissionState = 'GrantWithGrant'
                    $mockSetTargetResourceParameters.Permissions     = @( 'Connect', 'Update' )
                    $mockSetTargetResourceParameters.Ensure          = 'Absent'

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                    $script:mockMethodGrantWasRan | Should -Be 0
                    $script:mockMethodDenyWasRan | Should -Be 0
                    $script:mockMethodRevokeWasRan | Should -Be 1
                }

                Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
            }

            It 'Should call the method Revoke() for permission state ''Deny'' without throwing' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters.DatabaseName    = 'AdventureWorks'
                    $mockSetTargetResourceParameters.Name            = 'Zebes\SamusAran'
                    $mockSetTargetResourceParameters.PermissionState = 'Deny'
                    $mockSetTargetResourceParameters.Permissions     = @( 'Connect', 'Update' )
                    $mockSetTargetResourceParameters.Ensure          = 'Absent'

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                    $script:mockMethodGrantWasRan | Should -Be 0
                    $script:mockMethodDenyWasRan | Should -Be 0
                    $script:mockMethodRevokeWasRan | Should -Be 1
                }

                Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
            }
        }

        Context 'When method <MockMethod> fails' -ForEach @(
            @{
                MockMethod = 'Grant'
                MockVariableName = 'mockInvalidOperationForGrantMethod'
                MockEnsure = 'Present'
            }
            @{
                MockMethod = 'Grant'
                MockVariableName = 'mockInvalidOperationForRevokeMethod'
                MockEnsure = 'Absent'
            }
            @{
                MockMethod = 'Deny'
                MockVariableName = 'mockInvalidOperationForDenyMethod'
                MockEnsure = 'Present'
            }
        ) {
            BeforeAll {
                Set-Variable -Name $MockVariableName -Value $true
            }

            AfterAll {
                Set-Variable -Name $MockVariableName -Value $false
            }

            It 'Should throw a mocked invalid operation error' {
                InModuleScope -Parameters $_ -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters.DatabaseName    = 'AdventureWorks'
                    $mockSetTargetResourceParameters.Name            = 'Zebes\SamusAran'
                    $mockSetTargetResourceParameters.PermissionState = $MockMethod
                    $mockSetTargetResourceParameters.Permissions     = @( 'Connect', 'Update' )
                    $mockSetTargetResourceParameters.Ensure          = $MockEnsure

                    $errorMessage = $script:localizedData.FailedToSetPermissionDatabas -f 'Zebes\SamusAran', 'AdventureWorks'

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw -ExpectedMessage ('*' + $errorMessage + '*')
                }

                Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
            }
        }
    }
}

# try
# {
#     InModuleScope $script:dscResourceName {
#         $mockServerName = 'localhost'
#         $mockInstanceName = 'MSSQLSERVER'
#         'AdventureWorks' = 'AdventureWorks'
#         'Zebes\SamusAran' = 'Zebes\SamusAran'
#         'public' = 'public'
#         'MyAppRole' = 'MyAppRole'
#         'Zebes\SamusAran'Unknown = 'Elysia\Chozo'
#         'WindowsUser' = 'WindowsUser'
#         $mockInvalidOperationEnumDatabasePermissions = $false
#         $mockInvalidOperationForCreateMethod = $false
#         $mockExpectedSqlServerLogin = 'Zebes\SamusAran'
#         $mockSqlPermissionState = 'Grant'

#         $mockSqlPermissionType01 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionSet' -ArgumentList @($true, $false)
#         $mockSqlPermissionType02 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionSet' -ArgumentList @($false, $true)

#         $script:mockMethodGrantWasRan = $false
#         $script:mockMethodDenyWasRan = $false
#         $script:mockMethodRevokeWasRan = $false
#         $script:mockMethodCreateWasRan = $false

#         # Default parameters that are used for the It-blocks
#         $mockDefaultParameters = @{
#             InstanceName = $mockInstanceName
#             ServerName   = $mockServerName
#         }

#         #region Function mocks
#         $mockConnectSQL = {
#             return @(
#                 (
#                     New-Object -TypeName Object |
#                         Add-Member -MemberType 'ScriptProperty' -Name 'Databases' -Value {
#                         return @{
#                             'AdventureWorks' = @(
#                                 (
#                                     New-Object -TypeName Object |
#                                         Add-Member -MemberType 'NoteProperty' -Name Name -Value 'AdventureWorks' -PassThru |
#                                         Add-Member -MemberType 'ScriptProperty' -Name 'Users' -Value {
#                                             return @{
#                                                 'Zebes\SamusAran' = @(
#                                                     (
#                                                         New-Object -TypeName Object |
#                                                             Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'Zebes\SamusAran' -PassThru -Force
#                                                     )
#                                                 )
#                                             }
#                                         } -PassThru |
#                                         Add-Member -MemberType 'ScriptProperty' -Name 'ApplicationRoles' -Value {
#                                             return @{
#                                                 'MyAppRole' = @(
#                                                     (
#                                                         New-Object -TypeName Object |
#                                                             Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'MyAppRole' -PassThru -Force
#                                                     )
#                                                 )
#                                             }
#                                         } -PassThru |
#                                         Add-Member -MemberType 'ScriptProperty' -Name 'Roles' -Value {
#                                             return @{
#                                                 'public' = @(
#                                                     (
#                                                         New-Object -TypeName Object |
#                                                             Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'public' |
#                                                             Add-Member -MemberType 'NoteProperty' -Name 'IsFixedRole' -Value $true -PassThru -Force
#                                                     )
#                                                 )
#                                             }
#                                         } -PassThru |
#                                         Add-Member -MemberType 'ScriptMethod' -Name 'EnumDatabasePermissions' -Value {
#                                             param
#                                             (
#                                                 [Parameter()]
#                                                 [System.String]
#                                                 $SqlServerLogin
#                                             )
#                                             if ($mockInvalidOperationEnumDatabasePermissions)
#                                             {
#                                                 throw 'Mock EnumDatabasePermissions Method was called with invalid operation.'
#                                             }

#                                             if ( $SqlServerLogin -eq $mockExpectedSqlServerLogin )
#                                             {
#                                                 $mockEnumDatabasePermissions = @()
#                                                 $mockEnumDatabasePermissions += New-Object -TypeName Object |
#                                                     Add-Member -MemberType NoteProperty -Name PermissionType -Value $mockSqlPermissionType01 -PassThru |
#                                                     Add-Member -MemberType NoteProperty -Name PermissionState -Value $mockSqlPermissionState -PassThru |
#                                                     Add-Member -MemberType NoteProperty -Name Grantee -Value $mockExpectedSqlServerLogin -PassThru |
#                                                     Add-Member -MemberType NoteProperty -Name GrantorType -Value 'User' -PassThru |
#                                                     Add-Member -MemberType NoteProperty -Name ObjectClass -Value 'DatabaseName' -PassThru |
#                                                     Add-Member -MemberType NoteProperty -Name ObjectName -Value 'AdventureWorks' -PassThru
#                                                 $mockEnumDatabasePermissions += New-Object -TypeName Object |
#                                                     Add-Member -MemberType NoteProperty -Name PermissionType -Value $mockSqlPermissionType02 -PassThru |
#                                                     Add-Member -MemberType NoteProperty -Name PermissionState -Value $mockSqlPermissionState -PassThru |
#                                                     Add-Member -MemberType NoteProperty -Name Grantee -Value $mockExpectedSqlServerLogin -PassThru |
#                                                     Add-Member -MemberType NoteProperty -Name GrantorType -Value 'User' -PassThru |
#                                                     Add-Member -MemberType NoteProperty -Name ObjectClass -Value 'DatabaseName' -PassThru |
#                                                     Add-Member -MemberType NoteProperty -Name ObjectName -Value 'AdventureWorks' -PassThru

#                                                 $mockEnumDatabasePermissions
#                                             }
#                                             else
#                                             {
#                                                 return $null
#                                             }
#                                         } -PassThru |
#                                         Add-Member -MemberType 'ScriptMethod' -Name 'Grant' -Value {
#                                             param
#                                             (
#                                                 [Parameter()]
#                                                 [System.Object]
#                                                 $permissionSet,

#                                                 [Parameter()]
#                                                 [System.String]
#                                                 $SqlServerLogin
#                                             )

#                                             $script:mockMethodGrantWasRan = $true

#                                             if ( $SqlServerLogin -ne $mockExpectedSqlServerLogin )
#                                             {
#                                                 throw "Called mocked Grant() method without setting the right login name. Expected '{0}'. But was '{1}'." `
#                                                     -f $mockExpectedSqlServerLogin, $SqlServerLogin
#                                             }
#                                         } -PassThru |
#                                         Add-Member -MemberType 'ScriptMethod' -Name 'Revoke' -Value {
#                                             param
#                                             (
#                                                 [Parameter()]
#                                                 [System.Object]
#                                                 $permissionSet,

#                                                 [Parameter()]
#                                                 [System.String]
#                                                 $SqlServerLogin
#                                             )

#                                             $script:mockMethodRevokeWasRan = $true

#                                             if ( $SqlServerLogin -ne $mockExpectedSqlServerLogin )
#                                             {
#                                                 throw "Called mocked Revoke() method without setting the right login name. Expected '{0}'. But was '{1}'." `
#                                                     -f $mockExpectedSqlServerLogin, $SqlServerLogin
#                                             }
#                                         } -PassThru |
#                                         Add-Member -MemberType 'ScriptMethod' -Name 'Deny' -Value {
#                                             param
#                                             (
#                                                 [Parameter()]
#                                                 [System.Object]
#                                                 $permissionSet,

#                                                 [Parameter()]
#                                                 [System.String]
#                                                 $SqlServerLogin
#                                             )

#                                             $script:mockMethodDenyWasRan = $true

#                                             if ( $SqlServerLogin -ne $mockExpectedSqlServerLogin )
#                                             {
#                                                 throw "Called mocked Deny() method without setting the right login name. Expected '{0}'. But was '{1}'." `
#                                                     -f $mockExpectedSqlServerLogin, $SqlServerLogin
#                                             }
#                                         } -PassThru -Force
#                                 )
#                             )
#                         }
#                     } -PassThru -Force
#                 )
#             )
#         }
#         #endregion

#



#     }
# }
# finally
# {
#     Invoke-TestCleanup
# }
