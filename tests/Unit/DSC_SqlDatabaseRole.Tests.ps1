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
    $script:dscResourceName = 'DSC_SqlDatabaseRole'

    $env:SqlServerDscCI = $true

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

    Remove-Item -Path 'env:SqlServerDscCI'
}

Describe 'SqlDatabaseRole\Get-TargetResource' {
    BeforeAll {
        $mockConnectSQL = {
            return @(
                (
                    New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name InstanceName -Value 'MSSQLSERVER' -PassThru |
                    Add-Member -MemberType NoteProperty -Name ComputerNamePhysicalNetBIOS -Value 'localhost' -PassThru |
                    Add-Member -MemberType ScriptProperty -Name Databases -Value {
                        return @{
                            'AdventureWorks' = @((
                                    New-Object -TypeName Object |
                                    Add-Member -MemberType NoteProperty -Name Name -Value 'AdventureWorks' -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'IsUpdateable' -Value $false -PassThru |
                                    Add-Member -MemberType ScriptProperty -Name Users -Value {
                                        return @{
                                            'John' = New-Object -TypeName Object
                                            'CONTOSO\KingJulian' = New-Object -TypeName Object
                                            'CONTOSO\SQLAdmin' = New-Object -TypeName Object
                                        }
                                    } -PassThru |
                                    Add-Member -MemberType ScriptProperty -Name Roles -Value {
                                        return @{
                                            'MyRole' = @((
                                                    New-Object -TypeName Object |
                                                    Add-Member -MemberType NoteProperty -Name Name -Value 'MyRole' -PassThru |
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
                                                    Add-Member -MemberType NoteProperty -Name Name -Value 'MySecondRole' -PassThru -Force
                                                ))
                                        }
                                    } -PassThru -Force
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

    Context 'When role does not exist and the database is not updatable' {
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

        It 'Should return $false for the property DatabaseIsUpdateable' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockGetTargetResourceParameters

                $result.DatabaseIsUpdateable | Should -BeFalse
            }
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

Describe 'SqlDatabaseRole\Test-TargetResource' -Tag 'Test' {
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

    Context 'When the system is in the desired' {
        Context 'When the role should be absent' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Ensure = 'Present'
                        MembersInDesiredState = $true
                    }
                }
            }

            It 'Should return $true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.DatabaseName = 'AdventureWorks'
                    $mockTestTargetResourceParameters.Name         = 'MyRole'
                    $mockTestTargetResourceParameters.Ensure       = 'Present'

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeTrue
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the role should be present' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Ensure = 'Absent'
                        MembersInDesiredState = $true
                    }
                }
            }

            It 'Should return $true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.DatabaseName = 'AdventureWorks'
                    $mockTestTargetResourceParameters.Name         = 'MyRole'
                    $mockTestTargetResourceParameters.Ensure       = 'Absent'

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeTrue
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When the system is not in the desired' {
        Context 'When the role should be absent' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Ensure = 'Present'
                        MembersInDesiredState = $false
                        DatabaseIsUpdateable = $true
                    }
                }
            }

            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.DatabaseName = 'AdventureWorks'
                    $mockTestTargetResourceParameters.Name         = 'MyRole'
                    $mockTestTargetResourceParameters.Ensure       = 'Absent'

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeFalse
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the role should be present' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Ensure = 'Absent'
                        MembersInDesiredState = $false
                        DatabaseIsUpdateable = $true
                    }
                }
            }

            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.DatabaseName = 'AdventureWorks'
                    $mockTestTargetResourceParameters.Name         = 'MyRole'
                    $mockTestTargetResourceParameters.Ensure       = 'Present'

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeFalse
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the role is present but the members are not in the desired state' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Ensure = 'Present'
                        MembersInDesiredState = $false
                        DatabaseIsUpdateable = $true
                    }
                }
            }

            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.DatabaseName = 'AdventureWorks'
                    $mockTestTargetResourceParameters.Name         = 'MyRole'
                    $mockTestTargetResourceParameters.Ensure       = 'Present'

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeFalse
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the role should not exist but the database is not updateable' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Ensure = 'Present'
                        MembersInDesiredState = $false
                        DatabaseIsUpdateable = $false
                    }
                }
            }

            It 'Should return $true even if the desired database role exists' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.DatabaseName = 'AdventureWorks'
                    $mockTestTargetResourceParameters.Name         = 'MyRole'
                    $mockTestTargetResourceParameters.Ensure       = 'Absent'

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeTrue -Because 'the database is not updatable'
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the role should exist but the database is not updateable' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Ensure = 'Present'
                        MembersInDesiredState = $false
                        DatabaseIsUpdateable = $false
                    }
                }
            }

            It 'Should return $true even if the desired database role does not exists' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.DatabaseName = 'AdventureWorks'
                    $mockTestTargetResourceParameters.Name         = 'NewRole'

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeTrue -Because 'the database is not updatable'
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }
    }
}

Describe 'SqlDatabaseRole\Set-TargetResource' -Tag 'Set' {
    BeforeAll {
        $mockConnectSQL = {
            return @(
                (
                    New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name InstanceName -Value 'MSSQLSERVER' -PassThru |
                    Add-Member -MemberType NoteProperty -Name ComputerNamePhysicalNetBIOS -Value 'localhost' -PassThru |
                    Add-Member -MemberType ScriptProperty -Name 'Databases' -Value {
                        return @{
                            'AdventureWorks' = @((
                                    New-Object -TypeName Object |
                                    Add-Member -MemberType NoteProperty -Name 'Name' -Value 'AdventureWorks' -PassThru |
                                    Add-Member -MemberType ScriptProperty -Name 'Users' -Value {
                                        return @{
                                            'John' = New-Object -TypeName Object
                                            'CONTOSO\KingJulian' = New-Object -TypeName Object
                                            'CONTOSO\SQLAdmin' = New-Object -TypeName Object
                                        }
                                    } -PassThru |
                                    Add-Member -MemberType ScriptProperty -Name 'Roles' -Value {
                                        return @{
                                            'MyRole' = @((
                                                    New-Object -TypeName Object |
                                                    Add-Member -MemberType NoteProperty -Name 'Name' -Value 'MyRole' -PassThru |
                                                    Add-Member -MemberType ScriptMethod -Name 'Drop' -Value {
                                                        if ($mockInvalidOperationForDropMethod)
                                                        {
                                                            throw 'Mock Drop method was called with invalid operation.'
                                                        }

                                                        InModuleScope -ScriptBlock {
                                                            $script:mockMethodDropWasCalled += 1
                                                        }
                                                    } -PassThru |
                                                    Add-Member -MemberType ScriptMethod -Name 'EnumMembers' -Value {
                                                        return @('John', 'CONTOSO\KingJulian')
                                                    } -PassThru
                                                ))
                                            'MySecondRole' = @((
                                                    New-Object -TypeName Object |
                                                    Add-Member -MemberType NoteProperty -Name 'Name' -Value 'MySecondRole' -PassThru -Force
                                                ))
                                        }
                                    } -PassThru -Force
                                ))
                        }
                    } -PassThru -Force
                )
            )
        }

        $mockNewObjectDatabaseRole = {
            return @(
                New-Object -TypeName Object |
                Add-Member -MemberType NoteProperty -Name 'Name' -Value 'MyRole' -PassThru |
                Add-Member -MemberType ScriptMethod -Name 'Create' -Value {
                    if ($mockInvalidOperationForCreateMethod)
                    {
                        throw 'Mock Create method was called with invalid operation.'
                    }

                    InModuleScope -ScriptBlock {
                        $script:mockMethodCreateWasCalled += 1
                    }
                } -PassThru -Force
            )
        }

        Mock -CommandName Connect-SQL -MockWith $mockConnectSQL
        Mock -CommandName New-Object -MockWith $mockNewObjectDatabaseRole -ParameterFilter {
            $TypeName -eq 'Microsoft.SqlServer.Management.Smo.DatabaseRole'
        }

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
            $script:mockMethodDropWasCalled = 0
            $script:mockMethodCreateWasCalled = 0

            $script:mockSetTargetResourceParameters = $script:mockDefaultParameters.Clone()
        }
    }

    Context 'When the system is not in the desired state' {
        Context 'When database role should not exist' {
            It 'Should not throw when calling the Drop method' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters.DatabaseName = 'AdventureWorks'
                    $mockSetTargetResourceParameters.Name         = 'MyRole'
                    $mockSetTargetResourceParameters.Ensure       = 'Absent'

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                    $mockMethodDropWasCalled | Should -Be 1
                }

                Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the Drop() method fails' {
            It 'Should throw the correct error' {
                $mockInvalidOperationForDropMethod = $true

                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters.DatabaseName = 'AdventureWorks'
                    $mockSetTargetResourceParameters.Name         = 'MyRole'
                    $mockSetTargetResourceParameters.Ensure       = 'Absent'

                    $errorMessage = $script:localizedData.DropDatabaseRoleError -f 'MyRole', 'AdventureWorks'

                    {
                        Set-TargetResource @mockSetTargetResourceParameters
                    } | Should -Throw -ExpectedMessage ('*' + $errorMessage +'*Mock Drop method was called with invalid operation.*')
                }

                Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It

                $mockInvalidOperationForDropMethod = $false
            }
        }

        Context 'When the role should exist' {
            It 'Should not throw and call the correct mocked method' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters.DatabaseName = 'AdventureWorks'
                    $mockSetTargetResourceParameters.Name         = 'DatabaseRoleToAdd'
                    $mockSetTargetResourceParameters.Ensure       = 'Present'

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                    $mockMethodCreateWasCalled | Should -Be 1
                }

                Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName New-Object -Exactly -Times 1 -ParameterFilter {
                    $TypeName -eq 'Microsoft.SqlServer.Management.Smo.DatabaseRole'
                } -Scope Context
            }
        }

        Context 'When the Create() method fails' {
            It 'Should throw the correct error' {
                $mockInvalidOperationForCreateMethod = $true

                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters.DatabaseName = 'AdventureWorks'
                    $mockSetTargetResourceParameters.Name         = 'DatabaseRoleToAdd'
                    $mockSetTargetResourceParameters.Ensure       = 'Present'

                    $errorMessage = $script:localizedData.CreateDatabaseRoleError -f 'DatabaseRoleToAdd', 'AdventureWorks'

                    {
                        Set-TargetResource @mockSetTargetResourceParameters
                    } | Should -Throw -ExpectedMessage ('*' + $errorMessage +'*Mock Create method was called with invalid operation.*')
                }

                Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It

                $mockInvalidOperationForCreateMethod = $false
            }
        }

        Context 'When both parameters Members and MembersToExclude are assigned a value' {
            It 'Should throw the correct error' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters.DatabaseName     = 'AdventureWorks'
                    $mockSetTargetResourceParameters.Name             = 'MyRole'
                    $mockSetTargetResourceParameters.Ensure           = 'Present'
                    $mockSetTargetResourceParameters.Members          = @('John', 'CONTOSO\KingJulian')
                    $mockSetTargetResourceParameters.MembersToExclude = 'CONTOSO\KingJulian'

                    $errorMessage = $script:localizedData.MembersToIncludeAndExcludeParamMustBeNull

                    {
                        Set-TargetResource @mockSetTargetResourceParameters
                    } | Should -Throw -ExpectedMessage ('*' + $errorMessage)
                }

                Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
            }
        }

        Context 'When both parameters Members and MembersToInclude are assigned a value' {
            It 'Should throw the correct error' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters.DatabaseName     = 'AdventureWorks'
                    $mockSetTargetResourceParameters.Name             = 'MyRole'
                    $mockSetTargetResourceParameters.Ensure           = 'Present'
                    $mockSetTargetResourceParameters.Members          = @('John', 'CONTOSO\KingJulian')
                    $mockSetTargetResourceParameters.MembersToInclude = 'CONTOSO\SQLAdmin'

                    $errorMessage = $script:localizedData.MembersToIncludeAndExcludeParamMustBeNull

                    {
                        Set-TargetResource @mockSetTargetResourceParameters
                    } | Should -Throw -ExpectedMessage ('*' + $errorMessage)
                }

                Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
            }
        }

        Context 'When specifying parameter Members to both add and remove members' {
            BeforeAll {
                Mock -CommandName Add-SqlDscDatabaseRoleMember
                Mock -CommandName Remove-SqlDscDatabaseRoleMember
            }

            It 'Should not throw and call the correct mocks' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters.DatabaseName = 'AdventureWorks'
                    $mockSetTargetResourceParameters.Name         = 'MyRole'
                    $mockSetTargetResourceParameters.Ensure       = 'Present'
                    <#
                        This should remove the mocked member 'CONTOSO\KingJulian' which
                        is mocked in the EnumMembers() method.
                    #>
                    $mockSetTargetResourceParameters.Members      = @('John', 'CONTOSO\SQLAdmin')

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Add-SqlDscDatabaseRoleMember -ParameterFilter {
                    $MemberName -eq 'CONTOSO\SQLAdmin'
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Remove-SqlDscDatabaseRoleMember -ParameterFilter {
                    $MemberName -eq 'CONTOSO\KingJulian'
                } -Exactly -Times 1 -Scope It
            }
        }

        Context 'When specifying parameter MembersToInclude' {
            BeforeAll {
                Mock -CommandName Add-SqlDscDatabaseRoleMember
                Mock -CommandName Remove-SqlDscDatabaseRoleMember
            }

            It 'Should not throw and call the correct mocks' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters.DatabaseName     = 'AdventureWorks'
                    $mockSetTargetResourceParameters.Name             = 'MyRole'
                    $mockSetTargetResourceParameters.Ensure           = 'Present'
                    <#
                        This should add the member since it is not returned by the
                        EnumMembers() mocked method.
                    #>
                    $mockSetTargetResourceParameters.MembersToInclude = @('CONTOSO\SQLAdmin')

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Add-SqlDscDatabaseRoleMember -ParameterFilter {
                    $MemberName -eq 'CONTOSO\SQLAdmin'
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Remove-SqlDscDatabaseRoleMember -Exactly -Times 0 -Scope It
            }
        }

        Context 'When specifying parameter MembersToExclude' {
            BeforeAll {
                Mock -CommandName Add-SqlDscDatabaseRoleMember
                Mock -CommandName Remove-SqlDscDatabaseRoleMember
            }

            It 'Should not throw and call the correct mocks' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters.DatabaseName     = 'AdventureWorks'
                    $mockSetTargetResourceParameters.Name             = 'MyRole'
                    $mockSetTargetResourceParameters.Ensure           = 'Present'
                    <#
                        This should add the member since it is not returned by the
                        EnumMembers() mocked method.
                    #>
                    $mockSetTargetResourceParameters.MembersToExclude = @('CONTOSO\KingJulian')

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Add-SqlDscDatabaseRoleMember -Exactly -Times 0 -Scope It
                Should -Invoke -CommandName Remove-SqlDscDatabaseRoleMember -ParameterFilter {
                    $MemberName -eq 'CONTOSO\KingJulian'
                } -Exactly -Times 1 -Scope It
            }
        }
    }
}

Describe 'Add-SqlDscDatabaseRoleMember' -Tag 'Helper' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            $script:mockInvalidOperationForAddMemberMethod = $false

            $script:mockSqlDatabaseObject = @(
                    (
                        New-Object -TypeName Object |
                            Add-Member -MemberType NoteProperty -Name 'Name' -Value 'AdventureWorks' -PassThru |
                            Add-Member -MemberType ScriptProperty -Name 'Users' -Value {
                                return @{
                                    'John' = New-Object -TypeName Object
                                }
                            } -PassThru |
                            Add-Member -MemberType ScriptProperty -Name 'Roles' -Value {
                                return @{
                                    'MyRole' = @(
                                        (
                                            New-Object -TypeName Object |
                                            Add-Member -MemberType NoteProperty -Name 'Name' -Value 'MyRole' -PassThru |
                                            Add-Member -MemberType ScriptMethod -Name 'AddMember' -Value {
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

                                                $script:mockMethodAddMemberWasCalled += 1
                                            } -PassThru -Force
                                        )
                                    )
                                }
                            } -PassThru -Force
                    )
                )
        }
    }

    Context 'When calling with a role that does not exist' {
        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockErrorMessage = $script:localizedData.DatabaseRoleOrUserNotFound -f 'MissingRole', 'MissingUser', 'AdventureWorks'
                {
                    Add-SqlDscDatabaseRoleMember -SqlDatabaseObject $mockSqlDatabaseObject -Name 'MissingRole' -MemberName 'MissingUser'
                } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage)
            }
        }
    }

    Context 'When add a member from a role' {
        BeforeEach {
            InModuleScope -ScriptBlock {
                $script:mockMethodAddMemberWasCalled = 0
            }
        }

        It 'Should call the correct method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                {
                    Add-SqlDscDatabaseRoleMember -SqlDatabaseObject $mockSqlDatabaseObject -Name 'MyRole' -MemberName 'John'
                } | Should -Not -Throw

                $mockMethodAddMemberWasCalled | Should -Be 1
            }
        }
    }

    Context 'When method AddMember() fails' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockInvalidOperationForAddMemberMethod = $true
            }
        }

        AfterAll {
            InModuleScope -ScriptBlock {
                $script:mockInvalidOperationForAddMemberMethod = $false
            }
        }

        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockErrorMessage = $script:localizedData.AddDatabaseRoleMemberError -f 'John', 'MyRole', 'AdventureWorks'

                {
                    Add-SqlDscDatabaseRoleMember -SqlDatabaseObject $mockSqlDatabaseObject -Name 'MyRole' -MemberName 'John'
                } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage + '*Mock AddMember Method was called with invalid operation.*')
            }
        }
    }
}

Describe 'Remove-SqlDscDatabaseRoleMember' -Tag 'Helper' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            $script:mockInvalidOperationForDropMemberMethod = $false

            $script:mockSqlDatabaseObject = @(
                    (
                        New-Object -TypeName Object |
                            Add-Member -MemberType NoteProperty -Name 'Name' -Value 'AdventureWorks' -PassThru |
                            Add-Member -MemberType ScriptProperty -Name 'Users' -Value {
                                return @{
                                    'John' = New-Object -TypeName Object
                                }
                            } -PassThru |
                            Add-Member -MemberType ScriptProperty -Name 'Roles' -Value {
                                return @{
                                    'MyRole' = @(
                                        (
                                            New-Object -TypeName Object |
                                            Add-Member -MemberType NoteProperty -Name 'Name' -Value 'MyRole' -PassThru |
                                            Add-Member -MemberType ScriptMethod -Name 'DropMember' -Value {
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

                                                $script:mockMethodDropMemberWasCalled += 1
                                            } -PassThru -Force
                                        )
                                    )
                                }
                            } -PassThru -Force
                    )
                )
        }
    }

    Context 'When removing a member from a role' {
        BeforeEach {
            InModuleScope -ScriptBlock {
                $script:mockMethodDropMemberWasCalled = 0
            }
        }

        It 'Should call the correct method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                {
                    Remove-SqlDscDatabaseRoleMember -SqlDatabaseObject $mockSqlDatabaseObject -Name 'MyRole' -MemberName 'MyRole'
                } | Should -Not -Throw

                $mockMethodDropMemberWasCalled | Should -Be 1
            }
        }
    }

    Context 'When method DropMember() fails' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockInvalidOperationForDropMemberMethod = $true
            }
        }

        AfterAll {
            InModuleScope -ScriptBlock {
                $script:mockInvalidOperationForDropMemberMethod = $false
            }
        }

        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockErrorMessage = $script:localizedData.DropDatabaseRoleMemberError -f 'MyRole', 'MyRole', 'AdventureWorks'

                {
                    Remove-SqlDscDatabaseRoleMember -SqlDatabaseObject $mockSqlDatabaseObject -Name 'MyRole' -MemberName 'MyRole'
                } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage + '*Mock DropMember Method was called with invalid operation.*')
            }
        }
    }
}
