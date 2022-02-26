<#
    .SYNOPSIS
        Unit test for DSC_SqlDatabaseRole DSC resource.
#>

# Suppressing this rule because Script Analyzer does not understand Pester's syntax.
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
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
    $script:dscResourceName = 'DSC_SqlDatabaseRole'

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

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

Describe 'SqlDatabaseRole\Get-TargetResource' {
    BeforeAll {
        $mockConnectSQL = {
            return @(
                (
                    New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name InstanceName -Value $mockInstanceName -PassThru |
                    Add-Member -MemberType NoteProperty -Name ComputerNamePhysicalNetBIOS -Value $mockServerName -PassThru |
                    Add-Member -MemberType ScriptProperty -Name Databases -Value {
                        return @{
                            'AdventureWorks' = @((
                                    New-Object -TypeName Object |
                                    Add-Member -MemberType NoteProperty -Name Name -Value 'AdventureWorks' -PassThru |
                                    Add-Member -MemberType ScriptProperty -Name Users -Value {
                                        return @{
                                            'John' = @((
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
                                            'CONTOSO\KingJulian' = @((
                                                    New-Object -TypeName Object |
                                                    Add-Member -MemberType ScriptMethod -Name IsMember -Value {
                                                        return $true
                                                    } -PassThru
                                                ))
                                            'CONTOSO\SQLAdmin' = @((
                                                    New-Object -TypeName Object |
                                                    Add-Member -MemberType ScriptMethod -Name IsMember -Value {
                                                        return $true
                                                    } -PassThru
                                                ))

                                        }
                                    } -PassThru |
                                    Add-Member -MemberType ScriptProperty -Name Roles -Value {
                                        return @{
                                            'MyRole' = @((
                                                    New-Object -TypeName Object |
                                                    Add-Member -MemberType NoteProperty -Name Name -Value 'MyRole' -PassThru |
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

                                                        if ($Name -ne 'MySecondRole')
                                                        {
                                                            throw "Called mocked AddMember() method without adding the right user. Expected '{0}'. But was '{1}'." `
                                                                -f 'MySecondRole', $Name
                                                        }
                                                    } -PassThru |
                                                    Add-Member -MemberType ScriptMethod -Name Drop -Value {
                                                        if ($mockInvalidOperationForDropMethod)
                                                        {
                                                            throw 'Mock Drop Method was called with invalid operation.'
                                                        }

                                                        if ($Name -ne 'MyRole')
                                                        {
                                                            throw "Called mocked Drop() method without dropping the right database role. Expected '{0}'. But was '{1}'." `
                                                                -f 'MyRole', $Name
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

                                                        if ($Name -ne 'MyRole')
                                                        {
                                                            throw "Called mocked Drop() method without adding the right user. Expected '{0}'. But was '{1}'." `
                                                                -f 'MyRole', $Name
                                                        }
                                                    } -PassThru |
                                                    Add-Member -MemberType ScriptMethod -Name EnumMembers -Value {
                                                        if ($mockInvalidOperationForEnumMethod)
                                                        {
                                                            throw 'Mock EnumMembers Method was called with invalid operation.'
                                                        }
                                                        else
                                                        {
                                                            return @('John', 'CONTOSO\KingJulian')
                                                        }
                                                    } -PassThru
                                                ))
                                            'MySecondRole' = @((
                                                    New-Object -TypeName Object |
                                                    Add-Member -MemberType NoteProperty -Name Name -Value 'MySecondRole' -PassThru |
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
                                                        if ($Name -ne 'MySecondRole')
                                                        {
                                                            throw "Called mocked AddMember() method without adding the right user. Expected '{0}'. But was '{1}'." `
                                                                -f 'MySecondRole', $Name
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
                                                        if ($Name -ne 'MyRole')
                                                        {
                                                            throw "Called mocked Drop() method without adding the right user. Expected '{0}'. But was '{1}'." `
                                                                -f 'MyRole', $Name
                                                        }
                                                    } -PassThru
                                                ))
                                        }
                                    } -PassThru -Force
                                ))
                        }
                    } -PassThru -Force |
                    Add-Member -MemberType ScriptProperty -Name Logins -Value {
                        return @{
                            'John' = @((
                                    New-Object -TypeName Object |
                                    Add-Member -MemberType NoteProperty -Name LoginType -Value 'WindowsUser' -PassThru
                                ))
                            'CONTOSO\KingJulian' = @((
                                    New-Object -TypeName Object |
                                    Add-Member -MemberType NoteProperty -Name LoginType -Value 'WindowsGroup' -PassThru
                                ))
                            'CONTOSO\SQLAdmin' = @((
                                    New-Object -TypeName Object |
                                    Add-Member -MemberType NoteProperty -Name LoginType -Value 'WindowsGroup' -PassThru
                                ))
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

    Context 'When only key parameters have values and database name does not exist' {
        BeforeEach {
            InModuleScope -ScriptBlock {
                $mockGetTargetResourceParameters.DatabaseName = 'unknownDatabaseName'
                $mockGetTargetResourceParameters.Name         = 'MyRole'
            }
        }

        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $errorMessage = $script:localizedData.DatabaseNotFound -f $mockGetTargetResourceParameters.DatabaseName

                { Get-TargetResource @mockGetTargetResourceParameters } | Should -Throw -ExpectedMessage ('*' + $errorMessage)
            }
        }

        It 'Should call the mock function Connect-SQL' {
            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
        }
    }

    Context 'When only key parameters have values and the role does not exist' {
        BeforeEach {
            InModuleScope -ScriptBlock {
                $mockGetTargetResourceParameters.DatabaseName = 'AdventureWorks'
                $mockGetTargetResourceParameters.Name         = 'UnknownRoleName'
            }
        }

        It 'Should return the state as Absent' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockGetTargetResourceParameters
                $result.Ensure | Should -Be 'Absent'
            }

            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }

        It 'Should return the members as null' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockGetTargetResourceParameters
                $result.Members | Should -BeNullOrEmpty
            }

            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
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

            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }
    }

    Context 'When only key parameters have values and the role exists' {
        BeforeEach {
            InModuleScope -ScriptBlock {
                $mockGetTargetResourceParameters.DatabaseName = 'AdventureWorks'
                $mockGetTargetResourceParameters.Name         = 'MyRole'
            }
        }

        It 'Should return the state as Present' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockGetTargetResourceParameters
                $result.Ensure | Should -Be 'Present'
            }

            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }

        It 'Should call the mock function Connect-SQL' {
            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
        }
    }

    Context 'When only key parameters have values and throwing with EnumMembers method' {
        BeforeEach {
            $mockInvalidOperationForEnumMethod = $true

            InModuleScope -ScriptBlock {
                $mockGetTargetResourceParameters.DatabaseName = 'AdventureWorks'
                $mockGetTargetResourceParameters.Name         = 'MyRole'
            }
        }

        AfterAll {
            $mockInvalidOperationForEnumMethod = $false
        }

        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $errorMessage = $script:localizedData.EnumDatabaseRoleMemberNamesError -f 'MyRole', 'AdventureWorks'

                { Get-TargetResource @mockGetTargetResourceParameters } | Should -Throw -ExpectedMessage ('*' + $errorMessage + '*')
            }
        }

        It 'Should call the mock function Connect-SQL' {
            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
        }
    }

    Context 'When parameter Members is assigned a value, the role exists, and the role members are in the desired state' {
        BeforeEach {
            InModuleScope -ScriptBlock {
                $mockGetTargetResourceParameters.DatabaseName = 'AdventureWorks'
                $mockGetTargetResourceParameters.Name         = 'MyRole'
                $mockGetTargetResourceParameters.Members      = @('John', 'CONTOSO\KingJulian')
            }
        }

        It 'Should return Ensure as Present' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockGetTargetResourceParameters
                $result.Ensure | Should -Be 'Present'
            }

            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }

        It 'Should return MembersInDesiredState as True' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockGetTargetResourceParameters
                $result.MembersInDesiredState | Should -BeTrue
            }

            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }

        It 'Should return the members as not null' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockGetTargetResourceParameters
                $result.Members | Should -Be $mockGetTargetResourceParameters.Members
            }

            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }

        It 'Should return the members as string array' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockGetTargetResourceParameters
                ($result.Members -is [System.String[]]) | Should -BeTrue
            }

            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }

        It 'Should return the same values as passed as parameters' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockGetTargetResourceParameters
                $result.ServerName | Should -Be $mockGetTargetResourceParameters.ServerName
                $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                $result.DatabaseName | Should -Be $mockGetTargetResourceParameters.DatabaseName
                $result.Name | Should -Be $mockGetTargetResourceParameters.Name
                $result.Members | Should -Be $mockGetTargetResourceParameters.Members
            }

            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }
    }

    Context 'When parameter Members is assigned a value, the role exists, and the role members are not in the desired state' {
        BeforeEach {
            InModuleScope -ScriptBlock {
                $mockGetTargetResourceParameters.DatabaseName = 'AdventureWorks'
                $mockGetTargetResourceParameters.Name         = 'MyRole'
                $mockGetTargetResourceParameters.Members      = @('John', 'CONTOSO\SQLAdmin')
            }
        }

        It 'Should return Ensure as Present' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockGetTargetResourceParameters
                $result.Ensure | Should -Be 'Present'
            }

            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }

        It 'Should return MembersInDesiredState as False' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockGetTargetResourceParameters
                $result.MembersInDesiredState | Should -BeFalse
            }

            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }

        It 'Should return the members as string array' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockGetTargetResourceParameters
                ($result.Members -is [System.String[]]) | Should -BeTrue
            }

            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }
    }

    Context 'When both parameters MembersToInclude and Members are assigned a value' {
        BeforeEach {
            InModuleScope -ScriptBlock {
                $mockGetTargetResourceParameters.DatabaseName     = 'AdventureWorks'
                $mockGetTargetResourceParameters.Name             = 'MyRole'
                $mockGetTargetResourceParameters.Members          = @('John', 'CONTOSO\KingJulian')
                $mockGetTargetResourceParameters.MembersToInclude = 'John'
            }
        }

        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $errorMessage = $script:localizedData.MembersToIncludeAndExcludeParamMustBeNull

                { Get-TargetResource @mockGetTargetResourceParameters } | Should -Throw -ExpectedMessage ('*' + $errorMessage)
            }
        }

        It 'Should call the mock function Connect-SQL' {
            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
        }
    }

    Context 'When parameter MembersToInclude is assigned a value, the role exists, and the role members are in the desired state' {
        BeforeEach {
            InModuleScope -ScriptBlock {
                $mockGetTargetResourceParameters.DatabaseName     = 'AdventureWorks'
                $mockGetTargetResourceParameters.Name             = 'MyRole'
                $mockGetTargetResourceParameters.MembersToInclude = 'John'
            }
        }

        It 'Should return Ensure as Present' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockGetTargetResourceParameters
                $result.Ensure | Should -Be 'Present'
            }

            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }

        It 'Should return MembersInDesiredState as True' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockGetTargetResourceParameters
                $result.MembersInDesiredState | Should -BeTrue
            }

            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }

        It 'Should return the members as not null' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockGetTargetResourceParameters
                $result.Members | Should -Not -BeNullOrEmpty
            }

            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }

        It 'Should return the members as string array' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockGetTargetResourceParameters
                ($result.Members -is [System.String[]]) | Should -BeTrue
            }

            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }

        It 'Should return the same values as passed as parameters' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockGetTargetResourceParameters
                $result.ServerName | Should -Be $mockGetTargetResourceParameters.ServerName
                $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                $result.DatabaseName | Should -Be $mockGetTargetResourceParameters.DatabaseName
                $result.Name | Should -Be $mockGetTargetResourceParameters.Name
                $result.MembersToInclude | Should -Be $mockGetTargetResourceParameters.MembersToInclude
            }

            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }
    }

    Context 'When parameter MembersToInclude is assigned a value, the role exists, and the role members are not in the desired state' {
        BeforeEach {
            InModuleScope -ScriptBlock {
                $mockGetTargetResourceParameters.DatabaseName     = 'AdventureWorks'
                $mockGetTargetResourceParameters.Name             = 'MyRole'
                $mockGetTargetResourceParameters.MembersToInclude = 'CONTOSO\SQLAdmin'
            }
        }

        It 'Should return Ensure as Present' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockGetTargetResourceParameters
                $result.Ensure | Should -Be 'Present'
            }

            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }

        It 'Should return MembersInDesiredState as False' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockGetTargetResourceParameters
                $result.MembersInDesiredState | Should -BeFalse
            }

            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }

        It 'Should return the members as string array' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockGetTargetResourceParameters
                ($result.Members -is [System.String[]]) | Should -BeTrue
            }

            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }
    }

    Context 'When both parameters MembersToExclude and Members are assigned a value' {
        BeforeEach {
            InModuleScope -ScriptBlock {
                $mockGetTargetResourceParameters.DatabaseName     = 'AdventureWorks'
                $mockGetTargetResourceParameters.Name             = 'MyRole'
                $mockGetTargetResourceParameters.Members          = @('John', 'CONTOSO\KingJulian')
                $mockGetTargetResourceParameters.MembersToExclude = 'John'

            }
        }

        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $errorMessage = $script:localizedData.MembersToIncludeAndExcludeParamMustBeNull

                { Get-TargetResource @mockGetTargetResourceParameters } | Should -Throw -ExpectedMessage ('*' + $errorMessage)
            }
        }

        It 'Should call the mock function Connect-SQL' {
            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
        }
    }

    Context 'When parameter MembersToExclude is assigned a value, the role exists, and the role members are in the desired state' {
        BeforeEach {
            InModuleScope -ScriptBlock {
                $mockGetTargetResourceParameters.DatabaseName     = 'AdventureWorks'
                $mockGetTargetResourceParameters.Name             = 'MyRole'
                $mockGetTargetResourceParameters.MembersToExclude = 'CONTOSO\SQLAdmin'
            }
        }

        It 'Should return Ensure as Present' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockGetTargetResourceParameters
                $result.Ensure | Should -Be 'Present'
            }

            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }

        It 'Should return MembersInDesiredState as True' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockGetTargetResourceParameters
                $result.MembersInDesiredState | Should -BeTrue
            }

            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }

        It 'Should return the same values as passed as parameters' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockGetTargetResourceParameters
                $result.ServerName | Should -Be $mockGetTargetResourceParameters.ServerName
                $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                $result.DatabaseName | Should -Be $mockGetTargetResourceParameters.DatabaseName
                $result.Name | Should -Be $mockGetTargetResourceParameters.Name
                $result.MembersToExclude | Should -Be $mockGetTargetResourceParameters.MembersToExclude
            }

            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }
    }

    Context 'When parameter MembersToExclude is assigned a value, the role exists, and the role members are not in the desired state' {
        BeforeEach {
            InModuleScope -ScriptBlock {
                $mockGetTargetResourceParameters.DatabaseName     = 'AdventureWorks'
                $mockGetTargetResourceParameters.Name             = 'MyRole'
                $mockGetTargetResourceParameters.MembersToExclude = 'CONTOSO\KingJulian'
            }
        }

        It 'Should return Ensure as Present' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockGetTargetResourceParameters
                $result.Ensure | Should -Be 'Present'
            }

            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }

        It 'Should return MembersInDesiredState as False' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockGetTargetResourceParameters
                $result.MembersInDesiredState | Should -BeFalse
            }

            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }

        It 'Should return the members as string array' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockGetTargetResourceParameters
                ($result.Members -is [System.String[]]) | Should -BeTrue
            }

            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }
    }
}

# try
# {
#     InModuleScope $script:dscResourceName {
#         $mockServerName = 'localhost'
#         $mockInstanceName = 'MSSQLSERVER'

#         $mockInvalidOperationForAddMemberMethod = $false
#         $mockInvalidOperationForCreateMethod = $false
#         $mockInvalidOperationForDropMethod = $false
#         $mockInvalidOperationForDropMemberMethod = $false

#         # Default parameters that are used for the It-blocks
#         $mockDefaultParameters = @{
#             ServerName   = $mockServerName
#             InstanceName = $mockInstanceName
#         }

#         #region Function mocks


#         $mockNewObjectDatabaseRole = {
#             return @(
#                 New-Object -TypeName Object |
#                 Add-Member -MemberType NoteProperty -Name Name -Value 'MyRole' -PassThru |
#                 Add-Member -MemberType ScriptMethod -Name Create -Value {
#                     if ($mockInvalidOperationForCreateMethod)
#                     {
#                         throw 'Mock Create Method was called with invalid operation.'
#                     }
#                     if ($this.Name -ne 'MyRole')
#                     {
#                         throw "Called mocked Create() method without adding the right user. Expected '{0}'. But was '{1}'." `
#                             -f 'MyRole', $this.Name
#                     }
#                 } -PassThru -Force
#             )
#         }
#         #endregion



#         Describe "DSC_SqlDatabaseRole\Set-TargetResource" -Tag 'Set' {
#             BeforeEach {
#                 Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
#                 Mock -CommandName New-Object -MockWith $mockNewObjectDatabaseRole -ParameterFilter {
#                     $TypeName -eq 'Microsoft.SqlServer.Management.Smo.DatabaseRole'
#                 }
#             }

#             Context 'When the system is not in the desired state and Ensure is set to Absent' {
#                 It 'Should not throw when calling the Drop method' {
#                     $mockSqlDatabaseRoleToDrop = 'DatabaseRoleToDrop'
#                     $mockExpectedSqlDatabaseRole = 'DatabaseRoleToDrop'
#                     $testParameters = $mockDefaultParameters
#                     $testParameters += @{
#                         DatabaseName = 'AdventureWorks'
#                         Name         = $mockSqlDatabaseRoleToDrop
#                         Ensure       = 'Absent'
#                     }

#                     { Set-TargetResource @testParameters } | Should -Not -Throw

#                     Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#                 }
#             }

#             Context 'When the system is not in the desired state and Ensure is set to Absent' {
#                 It 'Should throw the correct error when calling the Drop method' {
#                     $mockInvalidOperationForDropMethod = $true
#                     $testParameters = $mockDefaultParameters
#                     $testParameters += @{
#                         DatabaseName = 'AdventureWorks'
#                         Name         = 'MyRole'
#                         Ensure       = 'Absent'
#                     }

#                     $errorMessage = $script:localizedData.DropDatabaseRoleError -f 'MyRole', 'AdventureWorks'

#                     { Set-TargetResource @testParameters } | Should -Throw $errorMessage

#                     Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#                 }
#             }

#             Context 'When the system is not in the desired state and Ensure is set to Present' {
#                 It 'Should not throw when calling the Create method' {
#                     $mockSqlDatabaseRoleAdd = 'DatabaseRoleToAdd'
#                     $mockExpectedSqlDatabaseRole = 'DatabaseRoleToAdd'
#                     $testParameters = $mockDefaultParameters
#                     $testParameters += @{
#                         DatabaseName = 'AdventureWorks'
#                         Name         = $mockSqlDatabaseRoleAdd
#                         Ensure       = 'Present'
#                     }

#                     { Set-TargetResource @testParameters } | Should -Not -Throw

#                     Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#                 }

#                 It 'Should call the mock function New-Object with TypeName equal to Microsoft.SqlServer.Management.Smo.DatabaseRole' {
#                     Should -Invoke -CommandName New-Object -Exactly -Times 1 -ParameterFilter {
#                         $TypeName -eq 'Microsoft.SqlServer.Management.Smo.DatabaseRole'
#                     } -Scope Context
#                 }
#             }

#             Context 'When the system is not in the desired state and Ensure is set to Present' {
#                 It 'Should throw the correct error when calling the Create method' {
#                     $mockSqlDatabaseRoleAdd = 'DatabaseRoleToAdd'
#                     $mockExpectedSqlDatabaseRole = 'DatabaseRoleToAdd'
#                     $mockInvalidOperationForCreateMethod = $true
#                     $testParameters = $mockDefaultParameters
#                     $testParameters += @{
#                         DatabaseName = 'AdventureWorks'
#                         Name         = $mockSqlDatabaseRoleAdd
#                         Ensure       = 'Present'
#                     }

#                     $errorMessage = $script:localizedData.CreateDatabaseRoleError -f $mockSqlDatabaseRoleAdd, 'AdventureWorks'

#                     { Set-TargetResource @testParameters } | Should -Throw $errorMessage

#                     Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#                 }

#                 It 'Should call the mock function New-Object with TypeName equal to Microsoft.SqlServer.Management.Smo.DatabaseRole' {
#                     Should -Invoke -CommandName New-Object -Exactly -Times 1 -ParameterFilter {
#                         $TypeName -eq 'Microsoft.SqlServer.Management.Smo.DatabaseRole'
#                     } -Scope Context
#                 }
#             }

#             Context 'When parameter Members is assigned a value and Ensure is set to Present' {
#                 It 'Should throw the correct error when database user does not exist' {
#                     'MySecondRole' = 'KingJulian'
#                     $testParameters = $mockDefaultParameters
#                     $testParameters += @{
#                         DatabaseName = 'AdventureWorks'
#                         Name         = 'MyRole'
#                         Members      = @('KingJulian', 'John', 'CONTOSO\KingJulian')
#                         Ensure       = 'Present'
#                     }

#                     $errorMessage = $script:localizedData.DatabaseUserNotFound -f 'KingJulian', 'AdventureWorks'

#                     { Set-TargetResource @testParameters } | Should -Throw $errorMessage

#                     Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#                 }

#                 It 'Should not throw when calling both the AddMember and DropMember methods' {
#                     'MySecondRole' = 'CONTOSO\SQLAdmin'
#                     $mockExpectedMemberToDrop = 'CONTOSO\KingJulian'
#                     $testParameters = $mockDefaultParameters
#                     $testParameters += @{
#                         DatabaseName = 'AdventureWorks'
#                         Name         = 'MyRole'
#                         Members      = @('John', 'CONTOSO\SQLAdmin')
#                         Ensure       = 'Present'
#                     }

#                     { Set-TargetResource @testParameters } | Should -Not -Throw

#                     Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#                 }
#             }

#             Context 'When both parameters Members and MembersToInclude are assigned a value and Ensure is set to Present' {
#                 It 'Should throw the correct error' {
#                     $testParameters = $mockDefaultParameters
#                     $testParameters += @{
#                         DatabaseName     = 'AdventureWorks'
#                         Name             = 'MyRole'
#                         Members          = @('John', 'CONTOSO\KingJulian')
#                         MembersToInclude = 'CONTOSO\SQLAdmin'
#                         Ensure           = 'Present'
#                     }

#                     $errorMessage = $script:localizedData.MembersToIncludeAndExcludeParamMustBeNull

#                     { Set-TargetResource @testParameters } | Should -Throw $errorMessage

#                     Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#                 }
#             }

#             Context 'When parameter MembersToInclude is assigned a value, parameter Members is not assigned a value, and Ensure is set to Present' {
#                 It 'Should throw the correct error when the database user does not exist' {
#                     'MySecondRole' = 'CONTOSO\SQLAdmin'
#                     $testParameters = $mockDefaultParameters
#                     $testParameters += @{
#                         DatabaseName     = 'AdventureWorks'
#                         Name             = 'MyRole'
#                         MembersToInclude = 'KingJulian'
#                         Ensure           = 'Present'
#                     }

#                     $errorMessage = $script:localizedData.DatabaseUserNotFound -f 'KingJulian', 'AdventureWorks'

#                     { Set-TargetResource @testParameters } | Should -Throw $errorMessage

#                     Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#                 }

#                 It 'Should not throw when calling the AddMember method' {
#                     'MySecondRole' = 'CONTOSO\SQLAdmin'
#                     $testParameters = $mockDefaultParameters
#                     $testParameters += @{
#                         DatabaseName     = 'AdventureWorks'
#                         Name             = 'MyRole'
#                         MembersToInclude = 'CONTOSO\SQLAdmin'
#                         Ensure           = 'Present'
#                     }

#                     { Set-TargetResource @testParameters } | Should -Not -Throw

#                     Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#                 }

#                 It 'Should throw the correct error when calling the AddMember method' {
#                     $mockInvalidOperationForAddMemberMethod = $true
#                     'MySecondRole' = 'CONTOSO\SQLAdmin'
#                     $testParameters = $mockDefaultParameters
#                     $testParameters += @{
#                         DatabaseName     = 'AdventureWorks'
#                         Name             = 'MyRole'
#                         MembersToInclude = 'CONTOSO\SQLAdmin'
#                         Ensure           = 'Present'
#                     }

#                     $errorMessage = $script:localizedData.AddDatabaseRoleMemberError -f 'CONTOSO\SQLAdmin', 'MyRole', 'AdventureWorks'

#                     { Set-TargetResource @testParameters } | Should -Throw $errorMessage

#                     Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#                 }
#             }

#             Context 'When both parameters Members and MembersToExclude are assigned a value and Ensure is set to Present' {
#                 It 'Should throw the correct error' {
#                     $testParameters = $mockDefaultParameters
#                     $testParameters += @{
#                         DatabaseName     = 'AdventureWorks'
#                         Name             = 'MyRole'
#                         Members          = @('John', 'CONTOSO\KingJulian')
#                         MembersToExclude = 'CONTOSO\KingJulian'
#                         Ensure           = 'Present'
#                     }

#                     $errorMessage = $script:localizedData.MembersToIncludeAndExcludeParamMustBeNull

#                     { Set-TargetResource @testParameters } | Should -Throw $errorMessage

#                     Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#                 }
#             }

#             Context 'When parameter MembersToExclude is assigned a value, parameter Members is not assigned a value, and Ensure is set to Present' {
#                 It 'Should not throw when calling the DropMember method' {
#                     $mockExpectedMemberToDrop = 'CONTOSO\SQLAdmin'
#                     $testParameters = $mockDefaultParameters
#                     $testParameters += @{
#                         DatabaseName     = 'AdventureWorks'
#                         Name             = 'MyRole'
#                         MembersToExclude = 'CONTOSO\SQLAdmin'
#                         Ensure           = 'Present'
#                     }

#                     { Set-TargetResource @testParameters } | Should -Not -Throw

#                     Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#                 }

#                 It 'Should throw the correct error when calling the DropMember method' {
#                     $mockInvalidOperationForDropMemberMethod = $true
#                     $mockExpectedMemberToDrop = 'CONTOSO\KingJulian'
#                     $testParameters = $mockDefaultParameters
#                     $testParameters += @{
#                         DatabaseName     = 'AdventureWorks'
#                         Name             = 'MyRole'
#                         MembersToExclude = 'CONTOSO\KingJulian'
#                         Ensure           = 'Present'
#                     }

#                     $errorMessage = $script:localizedData.DropDatabaseRoleMemberError -f 'CONTOSO\KingJulian', 'MyRole', 'AdventureWorks'

#                     { Set-TargetResource @testParameters } | Should -Throw $errorMessage

#                     Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#                 }
#             }

#             Assert-VerifiableMock
#         }

#         Describe "DSC_SqlDatabaseRole\Test-TargetResource" -Tag 'Test' {
#             BeforeEach {
#                 Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
#             }

#             Context 'When the system is not in the desired state and Ensure is set to Absent' {
#                 It 'Should return False when the desired database role exists' {
#                     $testParameters = $mockDefaultParameters
#                     $testParameters += @{
#                         DatabaseName = 'AdventureWorks'
#                         Name         = 'MyRole'
#                         Ensure       = 'Absent'
#                     }

#                     $result = Test-TargetResource @testParameters
#                     $result | Should -BeFalse

#                     Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#                 }
#             }

#             Context 'When the system is not in the desired state and Ensure is set to Present' {
#                 It 'Should return True when the desired database role does not exist' {
#                     $testParameters = $mockDefaultParameters
#                     $testParameters += @{
#                         DatabaseName = 'AdventureWorks'
#                         Name         = 'NewRole'
#                         Ensure       = 'Present'
#                     }

#                     $result = Test-TargetResource @testParameters
#                     $result | Should -BeFalse

#                     Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#                 }
#             }

#             Context 'When the system is in the desired state and Ensure is set to Absent' {
#                 It 'Should return True when the desired database role does not exist' {
#                     $testParameters = $mockDefaultParameters
#                     $testParameters += @{
#                         DatabaseName = 'AdventureWorks'
#                         Name         = 'NewRole'
#                         Ensure       = 'Absent'
#                     }

#                     $result = Test-TargetResource @testParameters
#                     $result | Should -BeTrue

#                     Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#                 }
#             }

#             Context 'When the system is in the desired state and Ensure is set to Present' {
#                 It 'Should return True when the desired database role exists' {
#                     $testParameters = $mockDefaultParameters
#                     $testParameters += @{
#                         DatabaseName = 'AdventureWorks'
#                         Name         = 'MyRole'
#                         Ensure       = 'Present'
#                     }

#                     $result = Test-TargetResource @testParameters
#                     $result | Should -BeTrue

#                     Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#                 }
#             }

#             Context 'When parameter Members is assigned a value and Ensure parameter is set to Present' {
#                 It 'Should return False when the desired members are not in the desired database role' {
#                     $testParameters = $mockDefaultParameters
#                     $testParameters += @{
#                         DatabaseName = 'AdventureWorks'
#                         Name         = 'MyRole'
#                         Members      = @('CONTOSO\SQLAdmin')
#                         Ensure       = 'Present'
#                     }

#                     $result = Test-TargetResource @testParameters
#                     $result | Should -BeFalse

#                     Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#                 }
#             }

#             Context 'When both parameters Members and MembersToInclude are assigned a value and Ensure is set to Present' {
#                 It 'Should throw the correct error' {
#                     $testParameters = $mockDefaultParameters
#                     $testParameters += @{
#                         DatabaseName     = 'AdventureWorks'
#                         Name             = 'MyRole'
#                         Members          = @('John', 'CONTOSO\KingJulian')
#                         MembersToInclude = 'CONTOSO\SQLAdmin'
#                         Ensure           = 'Present'
#                     }

#                     $errorMessage = $script:localizedData.MembersToIncludeAndExcludeParamMustBeNull

#                     { Test-TargetResource @testParameters } | Should -Throw $errorMessage
#                 }

#                 It 'Should call the mock function Connect-SQL' {
#                     Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
#                 }
#             }

#             Context 'When parameter MembersToInclude is assigned a value, parameter Members is not assigned a value, and Ensure is set to Present' {
#                 It 'Should return False when desired database role does not exist' {
#                     $testParameters = $mockDefaultParameters
#                     $testParameters += @{
#                         DatabaseName     = 'AdventureWorks'
#                         Name             = 'NewRole'
#                         MembersToInclude = 'John'
#                         Ensure           = 'Present'
#                     }

#                     $result = Test-TargetResource @testParameters
#                     $result | Should -BeFalse

#                     Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#                 }

#                 It 'Should return True when the desired database role exists and the MembersToInclude contains members that already exist' {
#                     $testParameters = $mockDefaultParameters
#                     $testParameters += @{
#                         DatabaseName     = 'AdventureWorks'
#                         Name             = 'MyRole'
#                         MembersToInclude = 'CONTOSO\KingJulian'
#                         Ensure           = 'Present'
#                     }

#                     $result = Test-TargetResource @testParameters
#                     $result | Should -BeTrue

#                     Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#                 }

#                 It 'Should return False when the desired database role exists and the MembersToInclude contains members that are missing' {
#                     $testParameters = $mockDefaultParameters
#                     $testParameters += @{
#                         DatabaseName     = 'AdventureWorks'
#                         Name             = 'MyRole'
#                         MembersToInclude = 'CONTOSO\SQLAdmin'
#                         Ensure           = 'Present'
#                     }

#                     $result = Test-TargetResource @testParameters
#                     $result | Should -BeFalse

#                     Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#                 }
#             }

#             Context 'When both parameters Members and MembersToExclude are assigned a value and Ensure is set to Present' {
#                 It 'Should throw the correct error' {
#                     $testParameters = $mockDefaultParameters
#                     $testParameters += @{
#                         DatabaseName     = 'AdventureWorks'
#                         Name             = 'MyRole'
#                         Members          = @('John', 'CONTOSO\KingJulian')
#                         MembersToExclude = 'CONTOSO\SQLAdmin'
#                         Ensure           = 'Present'
#                     }

#                     $errorMessage = $script:localizedData.MembersToIncludeAndExcludeParamMustBeNull

#                     { Test-TargetResource @testParameters } | Should -Throw $errorMessage
#                 }

#                 It 'Should call the mock function Connect-SQL' {
#                     Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
#                 }
#             }

#             Context 'When parameter MembersToExclude is assigned a value, parameter Members is not assigned a value, and Ensure is set to Present' {
#                 It 'Should return False when desired database role does not exist' {
#                     $testParameters = $mockDefaultParameters
#                     $testParameters += @{
#                         DatabaseName     = 'AdventureWorks'
#                         Name             = 'NewRole'
#                         MembersToExclude = 'CONTOSO\SQLAdmin'
#                         Ensure           = 'Present'
#                     }

#                     $result = Test-TargetResource @testParameters
#                     $result | Should -BeFalse

#                     Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#                 }

#                 It 'Should return True when the desired database role exists and the MembersToExclude contains members that do not yet exist' {
#                     $testParameters = $mockDefaultParameters
#                     $testParameters += @{
#                         DatabaseName     = 'AdventureWorks'
#                         Name             = 'MyRole'
#                         MembersToExclude = 'CONTOSO\SQLAdmin'
#                         Ensure           = 'Present'
#                     }

#                     $result = Test-TargetResource @testParameters
#                     $result | Should -BeTrue

#                     Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#                 }

#                 It 'Should return False when the desired database role exists and the MembersToExclude contains members that already exist' {
#                     $testParameters = $mockDefaultParameters
#                     $testParameters += @{
#                         DatabaseName     = 'AdventureWorks'
#                         Name             = 'MyRole'
#                         MembersToExclude = 'John'
#                         Ensure           = 'Present'
#                     }

#                     $result = Test-TargetResource @testParameters
#                     $result | Should -BeFalse

#                     Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#                 }
#             }

#             Assert-VerifiableMock
#         }

#         Describe 'Add-SqlDscDatabaseRoleMember' -Tag 'Helper' {
#             BeforeAll {
#                 $mockSqlDatabaseObject = @{
#                     Name = 'AdventureWorks'
#                     Roles = @{
#                         'MyRole' = 'Role'
#                     }
#                     Users = @{
#                         'John' = 'User'
#                     }
#                 }
#                 $mockName = 'MissingRole'
#                 $mockMemberName = 'MissingUser'

#             }
#             Context 'When calling with a role that does not exist' {
#                 It 'Should throw the correct error' {
#                     {
#                         Add-SqlDscDatabaseRoleMember -SqlDatabaseObject $mockSqlDatabaseObject -Name $mockName -MemberName $mockMemberName
#                     } | Should -Throw ($script:localizedData.DatabaseRoleOrUserNotFound -f $mockName, $mockMemberName, 'AdventureWorks')
#                 }
#             }
#         }
#     }
# }
# finally
# {
#     Invoke-TestCleanup
# }
