<#
    .SYNOPSIS
        Unit test for DSC_SqlRole DSC resource.
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
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first'
    }
}

BeforeAll {
    $script:dscModuleName = 'SqlServerDsc'
    $script:dscResourceName = 'DSC_SqlRole'

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

    $mockPrincipalsAsArrays = $false

    $mockEnumMemberNames = (
        'CONTOSO\John',
        'CONTOSO\Kelly'
    )

    $mockConnectSQL = {
        $mockServerObjectHashtable = @{
            InstanceName = 'MSSQLSERVER'
            ComputerNamePhysicalNetBIOS = 'localhost'
            Name = 'localhost\MSSQLSERVER'
        }

        if ($mockPrincipalsAsArrays)
        {
            $mockServerObjectHashtable += @{
                Logins = @()
                Roles = @()
            }
        }
        else
        {
            $mockServerObjectHashtable += @{
                Logins = @{}
                Roles = @{}
            }
        }

        $mockServerObject = [PSCustomObject] $mockServerObjectHashtable

        # Add the roles to the mock Server objet
        foreach ($mockRole in $('AdminSqlForBI', 'TestChildRole'))
        {
            # Create the role objet
            $mockRoleObject = [PSCustomObject] @{
                Name = $mockRole
            }

            # Add mocked methods
            $mockRoleObject | Add-Member -MemberType ScriptMethod -Name EnumMemberNames -Value {
                if ($mockInvalidOperationForEnumMethod)
                {
                    throw 'Mock EnumMemberNames Method was called with invalid operation'
                }
                else
                {
                    $mockEnumMemberNames
                }
            } -PassThru |
            Add-Member -MemberType ScriptMethod -Name Drop -Value {
                if ($mockInvalidOperationForDropMethod)
                {
                    throw 'Mock Drop Method was called with invalid operation'
                }

                if ( $this.Name -ne 'ServerRoleToDrop' )
                {
                    throw "Called mocked drop() method without dropping the right server role. Expected '{0}'. But was '{1}'." `
                        -f 'ServerRoleToDrop', $this.Name
                }
            } -PassThru |
            Add-Member -MemberType ScriptMethod -Name AddMember -Value {
                param
                (
                    [Parameter(Mandatory = $true)]
                    [String]
                    $memberName
                )

                if ($mockInvalidOperationForAddMemberMethod)
                {
                    throw 'Mock AddMember Method was called with invalid operation'
                }

                if ($mockExpectedMemberToAdd -ne $memberName)
                {
                    throw "Called mocked AddMember() method without adding the right login. Expected '{0}'. But was '{1}'." `
                        -f $mockExpectedMemberToAdd, $memberName
                }
            } -PassThru |
            Add-Member -MemberType ScriptMethod -Name DropMember -Value {
                param
                (
                    [Parameter(Mandatory = $true)]
                    [String]
                    $memberName
                )

                if ($mockInvalidOperationForDropMemberMethod)
                {
                    throw 'Mock DropMember Method was called with invalid operation'
                }

                if ($mockExpectedMemberToDrop -ne $memberName)
                {
                    throw "Called mocked DropMember() method without removing the right login. Expected '{0}'. But was '{1}'." `
                        -f $mockExpectedMemberToDrop, $memberName
                }
            }

            # Add the mock role to the roles collection
            if ($mockServerObject.Roles -is [array])
            {
                $mockServerObject.Roles += $mockRoleObject
            }
            else
            {
                $mockServerObject.Roles.Add($mockRole, $mockRoleObject)
            }
        }

        # Add all mock logins
        foreach ($mockLoginName in @('CONTOSO\John', 'CONTOSO\Kelly', 'CONTOSO\Lucy', 'CONTOSO\Steve'))
        {
            $mockLoginObject = [PSCustomObject] @{
                Name = $mockLoginName
                LoginType = 'WindowsUser'
            }

            if ($mockServerObject.Logins -is [array])
            {
                $mockServerObject.Logins += $mockLoginObject
            }
            else
            {
                $mockServerObject.Logins.Add($mockLoginName, $mockLoginObject)
            }
        }

        return @($mockServerObject)
    }
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

Describe "DSC_SqlRole\Get-TargetResource" -Tag 'Get' {
    BeforeAll {
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
            Set-StrictMode -Version 1.0

            $script:mockTestParameters = $script:mockDefaultParameters.Clone()
        }
    }

    Context 'When the system is in the desired state and ensure is set to Absent' {
        BeforeEach {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestParameters.ServerRoleName = 'UnknownRoleName'

                $script:result = Get-TargetResource @mockTestParameters
            }
        }

        It 'Should return the state as absent when the role does not exist' {
            InModuleScope -ScriptBlock {
                $result.Ensure | Should -Be 'Absent'
            }
        }

        It 'Should return the members as null' {
            InModuleScope -ScriptBlock {
                $result.membersInRole | Should -BeNullOrEmpty
            }
        }

        It 'Should return the same values as passed as parameters' {
            InModuleScope -ScriptBlock {
                $result.ServerName | Should -Be $mockTestParameters.ServerName
                $result.InstanceName | Should -Be $mockTestParameters.InstanceName
                $result.ServerRoleName | Should -Be $mockTestParameters.ServerRoleName
            }
        }

        It 'Should be executed once' {
            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the system is not in the desired state and ensure is set to Absent' {
        BeforeEach {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestParameters.ServerRoleName = 'AdminSqlForBI'

                $script:result = Get-TargetResource @mockTestParameters
            }
        }

        It 'Should not return the state as absent when the role exist' {
            InModuleScope -ScriptBlock {
                $result.Ensure | Should -Not -Be 'Absent'
            }
        }

        It 'Should return the members as not null' {
            InModuleScope -ScriptBlock {
                $result.Members | Should -Not -BeNullOrEmpty
            }
        }

        # Regression test for issue #790
        It 'Should return the members as string array' {
            InModuleScope -ScriptBlock {
                ($result.Members -is [System.String[]]) | Should -BeTrue
            }
        }

        It 'Should return the same values as passed as parameters' {
            InModuleScope -ScriptBlock {
                $result.ServerName | Should -Be $mockTestParameters.ServerName
                $result.InstanceName | Should -Be $mockTestParameters.InstanceName
                $result.ServerRoleName | Should -Be $mockTestParameters.ServerRoleName
            }
        }

        It 'Should be executed once' {
            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }
    }

    Context 'When passing values to parameters and throwing with EnumMemberNames method' {
        BeforeAll {
            $mockInvalidOperationForEnumMethod = $true
        }

        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestParameters.ServerRoleName = 'AdminSqlForBI'

                $mockErrorMessage = $script:localizedData.EnumMemberNamesServerRoleGetError -f @(
                    'localhost',
                    'MSSQLSERVER',
                    'AdminSqlForBI'
                )

                { Get-TargetResource @mockTestParameters } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage + '*')
            }
        }

        It 'Should call the mock function Connect-SQL' {
            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
        }
    }
}

Describe "DSC_SqlRole\Test-TargetResource" -Tag 'Test' {
    BeforeAll {
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
            Set-StrictMode -Version 1.0

            $script:mockTestParameters = $script:mockDefaultParameters.Clone()
        }
    }

    Context 'When the system is not in the desired state and ensure is set to Absent' {
        BeforeEach {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestParameters.Ensure         = 'Absent'
                $mockTestParameters.ServerRoleName = 'AdminSqlForBI'

                $script:result = Test-TargetResource @mockTestParameters
            }
        }

        It 'Should return false when desired server role exist' {
            InModuleScope -ScriptBlock {
                $result | Should -BeFalse
            }
        }

        It 'Should be executed once' {
            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the system is in the desired state and ensure is set to Absent' {
        BeforeEach {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestParameters.Ensure         = 'Absent'
                $mockTestParameters.ServerRoleName = 'newServerRole'

                $script:result = Test-TargetResource @mockTestParameters
            }
        }

        It 'Should return true when desired server role does not exist' {
            InModuleScope -ScriptBlock {
                $result | Should -BeTrue
            }
        }

        It 'Should be executed once' {
            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the system is in the desired state and ensure is set to Present' {
        BeforeEach {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestParameters.Ensure         = 'Present'
                $mockTestParameters.ServerRoleName = 'AdminSqlForBI'

                $script:result = Test-TargetResource @mockTestParameters
            }
        }

        It 'Should return true when desired server role exist' {
            InModuleScope -ScriptBlock {
                $result | Should -BeTrue
            }
        }

        It 'Should be executed once' {
            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the system is not in the desired state and ensure is set to Present' {
        BeforeEach {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestParameters.Ensure         = 'Present'
                $mockTestParameters.ServerRoleName = 'newServerRole'

                $script:result = Test-TargetResource @mockTestParameters
            }
        }

        It 'Should return false when desired server role does not exist' {
            InModuleScope -ScriptBlock {
                $result | Should -BeFalse
            }
        }

        It 'Should be executed once' {
            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the system is not in the desired state and ensure is set to Present' {
        BeforeEach {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestParameters.Ensure         = 'Present'
                $mockTestParameters.ServerRoleName = 'AdminSqlForBI'
                $mockTestParameters.Members        = @('CONTOSO\Lucy', 'CONTOSO\Steve')

                $script:result = Test-TargetResource @mockTestParameters
            }
        }

        It 'Should return false when desired members are not in desired server role' {
            InModuleScope -ScriptBlock {
                $result | Should -BeFalse
            }
        }

        It 'Should be executed once' {
            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }
    }

    Context 'When both the parameters Members and MembersToInclude are assigned a value and ensure is set to Present' {
        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestParameters.Ensure           = 'Present'
                $mockTestParameters.ServerRoleName   = 'AdminSqlForBI'
                $mockTestParameters.Members          = @('CONTOSO\John', 'CONTOSO\Kelly')
                $mockTestParameters.MembersToInclude = 'CONTOSO\Lucy'

                $mockErrorMessage = $script:localizedData.MembersToIncludeAndExcludeParamMustBeNull

                { Test-TargetResource @mockTestParameters } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage)
            }
        }

        It 'Should not be executed' {
            Should -Invoke -CommandName Connect-SQL -Exactly -Times 0 -Scope It
        }
    }

    Context 'When parameter MembersToInclude is assigned a value, parameter Members is not assigned a value, and ensure is set to Present' {
        BeforeEach {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestParameters.Ensure           = 'Present'
                $mockTestParameters.ServerRoleName   = 'AdminSqlForBI'
                $mockTestParameters.MembersToInclude = 'CONTOSO\Kelly'

                $script:result = Test-TargetResource @mockTestParameters
            }
        }

        It 'Should return true when desired server role exist' {
            InModuleScope -ScriptBlock {
                $result | Should -BeTrue
            }
        }

        It 'Should be executed once' {
            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }
    }

    Context 'When parameter MembersToInclude is assigned a value, parameter Members is not assigned a value, and ensure is set to Present' {
        BeforeEach {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestParameters.Ensure           = 'Present'
                $mockTestParameters.ServerRoleName   = 'RoleNotExist'
                $mockTestParameters.MembersToInclude = 'CONTOSO\Lucy'

                $script:result = Test-TargetResource @mockTestParameters
            }
        }

        It 'Should return false when desired server role does not exist' {
            InModuleScope -ScriptBlock {
                $result | Should -BeFalse
            }
        }

        It 'Should be executed once' {
            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }
    }

    Context 'When parameter MembersToInclude contains a new member that is not part of the current state' {
        BeforeEach {
            Mock -CommandName Get-TargetResource -MockWith {
                return @{
                    MembersToExclude = $null
                    MembersToInclude = $null
                    Ensure = 'Present'
                    InstanceName = 'MSSQLSERVER'
                    ServerRoleName = 'RoleNotExist'
                    Members = @('CONTOSO\Lucy')
                    ServerName = 'localhost'
                }
            }

            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestParameters.Ensure           = 'Present'
                $mockTestParameters.ServerRoleName   = 'RoleNotExist'
                $mockTestParameters.MembersToInclude = @('CONTOSO\Lucy', 'CONTOSO\NewUser')

                $script:result = Test-TargetResource @mockTestParameters
            }
        }

        It 'Should return false when desired server role does not exist' {
            InModuleScope -ScriptBlock {
                $result | Should -BeFalse
            }
        }

        It 'Should be executed once' {
            Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
        }
    }

    Context 'When both the parameters Members and MembersToExclude are assigned a value and ensure is set to Present' {
        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestParameters.Ensure           = 'Present'
                $mockTestParameters.ServerRoleName   = 'AdminSqlForBI'
                $mockTestParameters.Members          = @('CONTOSO\John', 'CONTOSO\Kelly')
                $mockTestParameters.MembersToExclude = 'CONTOSO\Kelly'

                $mockErrorMessage = $script:localizedData.MembersToIncludeAndExcludeParamMustBeNull

                { Test-TargetResource @mockTestParameters } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage)
            }
        }

        It 'Should not be executed' {
            Should -Invoke -CommandName Connect-SQL -Exactly -Times 0 -Scope It
        }
    }

    Context 'When parameter MembersToExclude is assigned a value, parameter Members is not assigned a value, and ensure is set to Present' {
        BeforeEach {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestParameters.Ensure           = 'Present'
                $mockTestParameters.ServerRoleName   = 'AdminSqlForBI'
                $mockTestParameters.MembersToExclude = 'CONTOSO\Lucy'

                $script:result = Test-TargetResource @mockTestParameters
            }
        }

        It 'Should return true when desired server role does not exist' {
            InModuleScope -ScriptBlock {
                $result | Should -BeTrue
            }
        }

        It 'Should be executed once' {
            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }
    }

    Context 'When parameter MembersToExclude is assigned a value, parameter Members is not assigned a value, and ensure is set to Present' {
        BeforeEach {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestParameters.Ensure           = 'Present'
                $mockTestParameters.ServerRoleName   = 'AdminSqlForBI'
                $mockTestParameters.MembersToExclude = 'CONTOSO\Kelly'

                $script:result = Test-TargetResource @mockTestParameters
            }
        }

        It 'Should return false when desired server role exist' {
            InModuleScope -ScriptBlock {
                $result | Should -BeFalse
            }
        }

        It 'Should be executed once' {
            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }
    }
}

Describe "DSC_SqlRole\Set-TargetResource" -Tag 'Set' {
    BeforeAll {
        Mock -CommandName Connect-SQL -MockWith $mockConnectSQL

        $mockNewObjectServerRole = {
            $mockObject = [PSCustomObject] @{
                Name = $mockSqlServerRoleAdd
            }

            $mockObject | Add-Member -MemberType ScriptMethod -Name Create -Value {
                if ($mockInvalidOperationForCreateMethod)
                {
                    throw 'Mock Create Method was called with invalid operation'
                }

                if ( $this.Name -ne $mockExpectedServerRoleToCreate )
                {
                    throw "Called mocked Create() method without adding the right server role. Expected '{0}'. But was '{1}'." `
                        -f $mockExpectedServerRoleToCreate, $this.Name
                }
            }

            return @($mockObject)
        }

        Mock -CommandName New-Object -MockWith $mockNewObjectServerRole -ParameterFilter {
            $TypeName -eq 'Microsoft.SqlServer.Management.Smo.ServerRole'
        }

        Mock -CommandName Test-SqlSecurityPrincipal -MockWith {
            return (
                @(
                    'CONTOSO\John'
                    'CONTOSO\Kelly'
                    'CONTOSO\Lucy'
                    'CONTOSO\Steve'
                    'TestChildRole'
                ) -contains $SecurityPrincipal
            )
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
            Set-StrictMode -Version 1.0

            $script:mockTestParameters = $script:mockDefaultParameters.Clone()
        }
    }

    Context 'When the system is not in the desired state and ensure is set to Absent' {
        It 'Should not throw when calling the drop method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockSqlServerRole = 'ServerRoleToDrop'
                $mockExpectedServerRoleToDrop = 'ServerRoleToDrop'

                $mockTestParameters.Ensure = 'Absent'
                $mockTestParameters.ServerRoleName = $mockSqlServerRole

                { Set-TargetResource @mockTestParameters } | Should -Not -Throw
            }
        }

        It 'Should be executed once' {
            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
        }
    }

    Context 'When the system is not in the desired state and ensure is set to Absent' {
        It 'Should throw the correct error when calling the drop method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockInvalidOperationForDropMethod = $true

                $mockTestParameters.Ensure         = 'Absent'
                $mockTestParameters.ServerRoleName = 'AdminSqlForBI'


                $mockErrorMessage = $script:localizedData.DropServerRoleSetError `
                    -f 'localhost', 'MSSQLSERVER', 'AdminSqlForBI'

                { Set-TargetResource @mockTestParameters } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage + '*')
            }

            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the system is not in the desired state and ensure is set to Present' {
        It 'Should not throw when calling the create method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockSqlServerRoleAdd = 'ServerRoleToAdd'
                $mockExpectedServerRoleToCreate = 'ServerRoleToAdd'

                $mockTestParameters.Ensure         = 'Present'
                $mockTestParameters.ServerRoleName = $mockSqlServerRoleAdd

                { Set-TargetResource @mockTestParameters } | Should -Not -Throw
            }

            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }

        It 'Should call the mock function New-Object with TypeName equal to Microsoft.SqlServer.Management.Smo.ServerRole' {
            Should -Invoke -CommandName New-Object -Exactly -Times 1 -ParameterFilter {
                $TypeName -eq 'Microsoft.SqlServer.Management.Smo.ServerRole'
            } -Scope Context
        }
    }

    Context 'When the system is not in the desired state and ensure is set to Present' {
        BeforeAll {
            $mockInvalidOperationForCreateMethod = $true
        }

        It 'Should throw the correct error when calling the create method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockSqlServerRoleAdd = 'ServerRoleToAdd'
                $mockExpectedServerRoleToCreate = 'ServerRoleToAdd'

                $mockTestParameters.Ensure         = 'Present'
                $mockTestParameters.ServerRoleName = $mockSqlServerRoleAdd

                $mockErrorMessage = $script:localizedData.CreateServerRoleSetError `
                    -f 'localhost', 'MSSQLSERVER', $mockSqlServerRoleAdd

                { Set-TargetResource @mockTestParameters } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage + '*')
            }

            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }

        It 'Should call the mock function New-Object with TypeName equal to Microsoft.SqlServer.Management.Smo.ServerRole' {
            Should -Invoke -CommandName New-Object -Exactly -Times 1 -ParameterFilter {
                $TypeName -eq 'Microsoft.SqlServer.Management.Smo.ServerRole'
            } -Scope Context
        }
    }

    Context 'When both the parameters Members and MembersToInclude are assigned a value and ensure is set to Present' {
        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestParameters.Ensure          = 'Present'
                $mockTestParameters.ServerRoleName   = 'AdminSqlForBI'
                $mockTestParameters.Members          = @('CONTOSO\John', 'CONTOSO\Kelly')
                $mockTestParameters.MembersToInclude = 'CONTOSO\Lucy'

                { Set-TargetResource @mockTestParameters } | Should -Throw -ExpectedMessage '*(DRC0010)*'
            }
        }

        It 'Should should not call Connect-SQL' {
            Should -Invoke -CommandName Connect-SQL -Exactly -Times 0 -Scope Context
        }
    }

    Context 'When both the parameters Members and MembersToExclude are assigned a value and ensure is set to Present' {
        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestParameters.Ensure           = 'Present'
                $mockTestParameters.ServerRoleName   = 'AdminSqlForBI'
                $mockTestParameters.Members          = @('CONTOSO\John', 'CONTOSO\Kelly')
                $mockTestParameters.MembersToExclude = 'CONTOSO\Kelly'

                $errorMessage = $script:localizedData.MembersToIncludeAndExcludeParamMustBeNull

                { Set-TargetResource @mockTestParameters } | Should -Throw -ExpectedMessage '*(DRC0010)*'
            }

            Should -Invoke -CommandName Connect-SQL -Exactly -Times 0 -Scope It
        }
    }

    Context 'When parameter MembersToInclude is assigned a value, parameter Members is not assigned a value, and ensure is set to Present' {
        BeforeAll {
            $mockExpectedMemberToAdd = 'CONTOSO\Lucy'
        }

        It 'Should not thrown when calling the AddMember method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestParameters.Ensure           = 'Present'
                $mockTestParameters.ServerRoleName   = 'AdminSqlForBI'
                $mockTestParameters.MembersToInclude = 'CONTOSO\Lucy'

                { Set-TargetResource @mockTestParameters } | Should -Not -Throw
            }

            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }
    }

    Context 'When parameter MembersToInclude is assigned a value, parameter Members is not assigned a value, and ensure is set to Present' {
        BeforeAll {
            $mockInvalidOperationForAddMemberMethod = $true
            $mockExpectedMemberToAdd = 'CONTOSO\Lucy'
        }

        It 'Should throw the correct error when calling the AddMember method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestParameters.Ensure           = 'Present'
                $mockTestParameters.ServerRoleName   = 'AdminSqlForBI'
                $mockTestParameters.MembersToInclude = 'CONTOSO\Lucy'

                $mockErrorMessage = $script:localizedData.AddMemberServerRoleSetError `
                    -f 'localhost', 'MSSQLSERVER', 'AdminSqlForBI', 'CONTOSO\Lucy'

                { Set-TargetResource @mockTestParameters } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage + '*')
            }

            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }
    }

    Context 'When parameter MembersToInclude is assigned a value, parameter Members is not assigned a value, and ensure is set to Present' {
        BeforeAll {
            $mockExpectedMemberToAdd = 'CONTOSO\Lucy'
        }

        It 'Should throw the correct error when login does not exist' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestParameters.Ensure           = 'Present'
                $mockTestParameters.ServerRoleName   = 'AdminSqlForBI'
                $mockTestParameters.MembersToInclude = 'KingJulian'

                $mockErrorMessage = $script:localizedData.AddMemberServerRoleSetError -f (
                    'localhost',
                    'MSSQLSERVER',
                    'AdminSqlForBI',
                    'KingJulian'
                )

                { Set-TargetResource @mockTestParameters } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage + '*')
            }

            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }
    }

    Context 'When parameter MembersToExclude is assigned a value, parameter Members is not assigned a value, and ensure is set to Present' {
        BeforeAll {
            $mockExpectedMemberToDrop = 'CONTOSO\Kelly'
        }

        It 'Should not throw when calling the DropMember method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockExpectedMemberToDrop = 'CONTOSO\Kelly'

                $mockTestParameters.Ensure           = 'Present'
                $mockTestParameters.ServerRoleName   = 'AdminSqlForBI'
                $mockTestParameters.MembersToExclude = 'CONTOSO\Kelly'

                { Set-TargetResource @mockTestParameters } | Should -Not -Throw
            }

            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }
    }

    Context 'When parameter MembersToExclude is assigned a value, parameter Members is not assigned a value, and ensure is set to Present' {
        BeforeAll {
            $mockInvalidOperationForDropMemberMethod = $true
            $mockExpectedMemberToDrop = 'CONTOSO\Kelly'
        }

        It 'Should throw the correct error when calling the DropMember method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestParameters.Ensure           = 'Present'
                $mockTestParameters.ServerRoleName   = 'AdminSqlForBI'
                $mockTestParameters.MembersToExclude = 'CONTOSO\Kelly'

                $mockErrorMessage = $script:localizedData.DropMemberServerRoleSetError `
                    -f 'localhost', 'MSSQLSERVER', 'AdminSqlForBI', 'CONTOSO\Kelly'

                { Set-TargetResource @mockTestParameters } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage + '*')
            }

            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }
    }

    Context 'When parameter MembersToExclude is assigned a value, parameter Members is not assigned a value, and ensure is set to Present' {
        BeforeAll {
            $mockEnumMemberNames = @('KingJulian', 'CONTOSO\John', 'CONTOSO\Kelly')
            $mockExpectedMemberToAdd = 'CONTOSO\Lucy'
        }

        It 'Should throw the correct error when login does not exist' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestParameters.Ensure           = 'Present'
                $mockTestParameters.ServerRoleName   = 'AdminSqlForBI'
                $mockTestParameters.MembersToExclude = 'KingJulian'

                $mockErrorMessage = $script:localizedData.DropMemberServerRoleSetError -f (
                    'localhost',
                    'MSSQLSERVER',
                    'AdminSqlForBI',
                    'KingJulian'
                )

                { Set-TargetResource @mockTestParameters } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage + '*')
            }

            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }
    }

    Context 'When parameter Members is assigned a value and ensure is set to Present' {
        BeforeAll {
            $mockExpectedMemberToDrop = 'CONTOSO\Kelly'
        }

        It 'Should throw the correct error when login does not exist' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestParameters.Ensure         = 'Present'
                $mockTestParameters.ServerRoleName = 'AdminSqlForBI'
                $mockTestParameters.Members        = @('KingJulian', 'CONTOSO\John', 'CONTOSO\Lucy')

                $mockErrorMessage = $script:localizedData.AddMemberServerRoleSetError -f (
                    'localhost',
                    'MSSQLSERVER',
                    'AdminSqlForBI',
                    'KingJulian'
                )

                { Set-TargetResource @mockTestParameters } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage + '*')
            }

            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }
    }

    Context 'When Members parameter is set and ensure parameter is set to Present' {
        BeforeAll {
            $mockExpectedMemberToAdd = 'CONTOSO\Lucy'
            $mockExpectedMemberToDrop = 'CONTOSO\Kelly'
        }

        It 'Should not throw when calling both the AddMember and DropMember methods' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestParameters.Ensure         = 'Present'
                $mockTestParameters.ServerRoleName = 'AdminSqlForBI'
                $mockTestParameters.Members        = @('CONTOSO\John', 'CONTOSO\Lucy')

                { Set-TargetResource @mockTestParameters } | Should -Not -Throw
            }

            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }
    }

    Context 'When nesting role membership' {
        Context 'When defining an explicit list of members' {
            BeforeAll {
                $mockExpectedMemberToAdd = 'TestChildRole'
            }

            It 'Should not throw when the member is a Role' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestParameters.Ensure = 'Present'
                    $mockTestParameters.ServerRoleName = 'AdminSqlForBI'
                    $mockTestParameters.Members = @('CONTOSO\John', 'CONTOSO\Kelly', 'TestChildRole')

                    { Set-TargetResource @mockTestParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
            }
        }

        Context 'When specifying a list of security principals to include in the Role' {
            BeforeAll {
                $mockExpectedMemberToAdd = 'TestChildRole'
            }

            It 'Should not throw when a member to include is a Role' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestParameters.Ensure = 'Present'
                    $mockTestParameters.ServerRoleName = 'AdminSqlForBI'
                    $mockTestParameters.MembersToInclude = @('TestChildRole')

                    { Set-TargetResource @mockTestParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
            }
        }

        Context 'When specifying a list of security principals to remove from the Role' {
            BeforeAll {
                $mockExpectedMemberToDrop = 'TestChildRole'
            }

            It 'Should not throw when the member to exclude is a Role' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestParameters.Ensure = 'Present'
                    $mockTestParameters.ServerRoleName = 'AdminSqlForBI'
                    $mockTestParameters.MembersToExclude = @('TestChildRole')

                    { Set-TargetResource @mockTestParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When evaluating role membership, case sensitivity should not be used. (Issue #1153)' {
        Context 'When specifying explicit role members' {
            It 'Should not attempt to remove an explicit member from the role' {
                $mockExpectedMemberToDrop = 'CONTOSO\Kelly'

                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestParameters.ServerRoleName = 'AdminSqlForBI'
                    $mockTestParameters.Ensure = 'Present'
                    $mockTestParameters.Members = 'CONTOSO\John'.ToUpper()

                    { Set-TargetResource @mockTestParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
            }

            It 'Should not attempt to add an explicit member that already exists in the role' {
                $mockExpectedMemberToAdd = ''

                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestParameters.ServerRoleName = 'AdminSqlForBI'
                    $mockTestParameters.Ensure = 'Present'
                    $mockTestParameters.Members = @('CONTOSO\John'.ToUpper(), 'CONTOSO\Kelly')

                    { Set-TargetResource @mockTestParameters } | Should -Not -Throw

                    Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }
        }

        Context 'When specifying mandatory role membership' {
            It 'Should not attempt to add a member that already exists in the role' {
                $mockExpectedMemberToAdd = ''

                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestParameters.ServerRoleName = 'AdminSqlForBI'
                    $mockTestParameters.Ensure = 'Present'
                    $mockTestParameters.MembersToInclude = @('CONTOSO\John'.ToUpper())

                    { Set-TargetResource @mockTestParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
            }

            It 'Should attempt to remove a member that is to be excluded' {
                $mockExpectedMemberToDrop = 'CONTOSO\John'

                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestParameters.ServerRoleName = 'AdminSqlForBI'
                    $mockTestParameters.Ensure = 'Present'
                    $mockTestParameters.MembersToExclude = @('CONTOSO\John'.ToUpper())

                    { Set-TargetResource @mockTestParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
            }
        }
    }
}

Describe 'DSC_SqlRole\Test-SqlSecurityPrincipal' -Tag 'Helper' {
    BeforeAll {
        Mock -CommandName Connect-SQL -MockWith $mockConnectSQL

        $mockPrincipalsAsArrays = $true

        InModuleScope -ScriptBlock {
            $script:testSqlServerObject = Connect-SQL -ServerName 'localhost' -InstanceName 'MSSQLSERVER'
        }
    }

    AfterAll {
        $mockPrincipalsAsArrays = $false
    }

    Context 'When the security principal does not exist' {
        It 'Should throw the correct exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockSecurityPrincipal = 'Nabrond'

                $mockTestParameters = @{
                    SqlServerObject = $testSqlServerObject
                    SecurityPrincipal = $mockSecurityPrincipal
                }

                $mockErrorMessage = $script:localizedData.SecurityPrincipalNotFound -f (
                    $mockSecurityPrincipal,
                    'localhost\MSSQLSERVER'
                )

                { Test-SqlSecurityPrincipal @mockTestParameters } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage)
            }
        }
    }

    Context 'When the security principal exists' {
        It 'Should return true when the principal is a Login' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestParameters = @{
                    SqlServerObject = $testSqlServerObject
                    SecurityPrincipal = 'CONTOSO\John'
                }

                Test-SqlSecurityPrincipal @mockTestParameters | Should -BeTrue
            }
        }

        It 'Should return true when the principal is a Login and case does not match' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestParameters = @{
                    SqlServerObject = $testSqlServerObject
                    SecurityPrincipal = 'CONTOSO\John'.ToUpper()
                }

                Test-SqlSecurityPrincipal @mockTestParameters | Should -BeTrue
            }
        }

        It 'Should return true when the principal is a Role' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestParameters = @{
                    SqlServerObject = $testSqlServerObject
                    SecurityPrincipal = 'AdminSqlForBI'
                }

                Test-SqlSecurityPrincipal @mockTestParameters | Should -BeTrue
            }
        }

        It 'Should return true when the principal is a Role and case does not match' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestParameters = @{
                    SqlServerObject = $testSqlServerObject
                    SecurityPrincipal = 'AdminSqlForBI'.ToUpper()
                }

                Test-SqlSecurityPrincipal @mockTestParameters | Should -BeTrue
            }
        }
    }
}

Describe 'DSC_SqlRole\Get-CorrectedMemberParameters' -Tag 'Helper' {
    Context 'When parameter Members is assigned a value and the role is not sysadmin, the output should be the same' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestParameters = @{
                    ServerRoleName   = 'AdminSqlForBI'
                    Members          = @(
                        'CONTOSO\John',
                        'CONTOSO\Kelly'
                    )
                }

                $script:result = Get-CorrectedMemberParameters @mockTestParameters
            }
        }

        It 'Should return an array with 2 elements' {
            InModuleScope -ScriptBlock {
                $result.Members | Should -HaveCount 2
            }
        }

        It 'Should return the same elements' {
            InModuleScope -ScriptBlock {
                $result.Members | Should -Be @(
                    'CONTOSO\John',
                    'CONTOSO\Kelly'
                )
            }
        }

        It 'Should not return extra values' {
            InModuleScope -ScriptBlock {
                $result.MembersToInclude | Should -BeNullOrEmpty
                $result.MembersToExclude | Should -BeNullOrEmpty
            }
        }
    }

    Context 'When parameter Members is assigned a value and the role is sysadmin, if SA is in Members, the output should be the same' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestParameters = @{
                    ServerRoleName   = 'sysadmin'
                    Members          = @(
                        'CONTOSO\John',
                        'CONTOSO\Kelly',
                        'SA'
                    )
                }

                $script:result = Get-CorrectedMemberParameters @mockTestParameters
            }
        }

        It 'Should return an array with 3 elements' {
            InModuleScope -ScriptBlock {
                $result.Members | Should -HaveCount 3
            }
        }

        It 'Should return the same elements' {
            InModuleScope -ScriptBlock {
                $result.Members | Should -Be @(
                    'CONTOSO\John',
                    'CONTOSO\Kelly',
                    'SA'
                )
            }
        }

        It 'Should not return extra values' {
            InModuleScope -ScriptBlock {
                $result.MembersToInclude | Should -BeNullOrEmpty
                $result.MembersToExclude | Should -BeNullOrEmpty
            }
        }
    }

    Context 'When parameter Members is assigned a value and the role is sysadmin, if SA is not in Members, SA should be added to the  output' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestParameters = @{
                    ServerRoleName   = 'sysadmin'
                    Members          = @(
                        'CONTOSO\John',
                        'CONTOSO\Kelly'
                    )
                }

                $script:result = Get-CorrectedMemberParameters @mockTestParameters
            }
        }

        It 'Should return an array with 3 elements' {
            InModuleScope -ScriptBlock {
                $result.Members | Should -HaveCount 3
            }
        }

        It 'Should have SA in Members' {
            InModuleScope -ScriptBlock {
                $result.Members | Should -Contain 'SA'
            }
        }

        It 'Should not return extra values' {
            InModuleScope -ScriptBlock {
                $result.MembersToInclude | Should -BeNullOrEmpty
                $result.MembersToExclude | Should -BeNullOrEmpty
            }
        }
    }

    Context 'When parameter MembersToInclude is assigned a value and the role is not sysadmin, if SA is in MembersToInclude, the output should be the same' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestParameters = @{
                    ServerRoleName   = 'AdminSqlForBI'
                    MembersToInclude = @(
                        'CONTOSO\John',
                        'CONTOSO\Kelly',
                        'SA'
                    )
                }

                $script:result = Get-CorrectedMemberParameters @mockTestParameters
            }
        }

        It 'Should return an array with 3 elements' {
            InModuleScope -ScriptBlock {
                $result.MembersToInclude | Should -HaveCount 3
            }
        }

        It 'Should return the elements from Members' {
            InModuleScope -ScriptBlock {
                $result.MembersToInclude | Should -Be @(
                    'CONTOSO\John',
                    'CONTOSO\Kelly',
                    'SA'
                )
            }
        }

        It 'Should not return extra values' {
            InModuleScope -ScriptBlock {
                $result.Members | Should -BeNullOrEmpty
                $result.MembersToExclude | Should -BeNullOrEmpty
            }
        }
    }

    Context 'When parameter MembersToInclude is assigned a value and the role is not sysadmin, if SA is not in MembersToInclude, the output should be the same' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestParameters = @{
                    ServerRoleName   = 'AdminSqlForBI'
                    MembersToInclude = @(
                        'CONTOSO\John',
                        'CONTOSO\Kelly'
                    )
                }

                $script:result = Get-CorrectedMemberParameters @mockTestParameters
            }
        }

        It 'Should return an array with 2 elements' {
            InModuleScope -ScriptBlock {
                $result.MembersToInclude | Should -HaveCount 2
            }
        }

        It 'Should return the elements from Members' {
            InModuleScope -ScriptBlock {
                $result.MembersToInclude | Should -Be  @(
                    'CONTOSO\John',
                    'CONTOSO\Kelly'
                )
            }
        }

        It 'Should not return extra values' {
            InModuleScope -ScriptBlock {
                $result.Members | Should -BeNullOrEmpty
                $result.MembersToExclude | Should -BeNullOrEmpty
            }
        }
    }

    Context 'When parameter MembersToInclude is assigned a value and the role is sysadmin, if SA is not in MembersToInclude, the output should be the same' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestParameters = @{
                    ServerRoleName   = 'sysadmin'
                    MembersToInclude = @(
                        'CONTOSO\John',
                        'CONTOSO\Kelly'
                    )
                }

                $script:result = Get-CorrectedMemberParameters @mockTestParameters
            }
        }

        It 'Should return an array with 2 elements' {
            InModuleScope -ScriptBlock {
                $result.MembersToInclude | Should -HaveCount 2
            }
        }

        It 'Should return the elements from Members' {
            InModuleScope -ScriptBlock {
                $result.MembersToInclude | Should -Be @(
                    'CONTOSO\John',
                    'CONTOSO\Kelly'
                )
            }
        }

        It 'Should not return extra values' {
            InModuleScope -ScriptBlock {
                $result.Members | Should -BeNullOrEmpty
                $result.MembersToExclude | Should -BeNullOrEmpty
            }
        }
    }

    Context 'When parameter MembersToInclude is assigned a value and the role is sysadmin, if SA is in MembersToInclude, the output should be the same' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestParameters = @{
                    ServerRoleName   = 'sysadmin'
                    MembersToInclude = @(
                        'CONTOSO\John',
                        'CONTOSO\Kelly',
                        'SA'
                    )
                }

                $script:result = Get-CorrectedMemberParameters @mockTestParameters
            }
        }

        It 'Should return an array with 3 elements' {
            InModuleScope -ScriptBlock {
                $result.MembersToInclude | Should -HaveCount 3
            }
        }

        It 'Should return the elements from Members' {
            InModuleScope -ScriptBlock {
                $result.MembersToInclude | Should -Be @(
                    'CONTOSO\John',
                    'CONTOSO\Kelly',
                    'SA'
                )
            }
        }

        It 'Should not return extra values' {
            InModuleScope -ScriptBlock {
                $result.Members | Should -BeNullOrEmpty
                $result.MembersToExclude | Should -BeNullOrEmpty
            }
        }
    }

    Context 'When parameter MembersToExclude is assigned a value and the role is not sysadmin, if SA is in MembersToExclude, the output should be the same' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestParameters = @{
                    ServerRoleName   = 'AdminSqlForBI'
                    MembersToExclude = @(
                        'CONTOSO\John',
                        'CONTOSO\Kelly',
                        'SA'
                    )
                }

                $script:result = Get-CorrectedMemberParameters @mockTestParameters
            }
        }

        It 'Should return an array with 3 elements' {
            InModuleScope -ScriptBlock {
                $result.MembersToExclude | Should -HaveCount 3
            }
        }

        It 'Should return the elements from Members' {
            InModuleScope -ScriptBlock {
                $result.MembersToExclude | Should -Be @(
                    'CONTOSO\John',
                    'CONTOSO\Kelly',
                    'SA'
                )
            }
        }

        It 'Should not return extra values' {
            InModuleScope -ScriptBlock {
                $result.Members | Should -BeNullOrEmpty
                $result.MembersToInclude | Should -BeNullOrEmpty
            }
        }
    }

    Context 'When parameter MembersToExclude is assigned a value and the role is not sysadmin, if SA is not in MembersToExclude, the output should be the same' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestParameters = @{
                    ServerRoleName   = 'AdminSqlForBI'
                    MembersToExclude = @(
                        'CONTOSO\John',
                        'CONTOSO\Kelly'
                    )
                }

                $script:result = Get-CorrectedMemberParameters @mockTestParameters
            }
        }

        It 'Should return an array with 2 elements' {
            InModuleScope -ScriptBlock {
                $result.MembersToExclude | Should -HaveCount 2
            }
        }

        It 'Should return the elements from Members' {
            InModuleScope -ScriptBlock {
                $result.MembersToExclude | Should -Be @(
                    'CONTOSO\John',
                    'CONTOSO\Kelly'
                )
            }
        }

        It 'Should not return extra values' {
            InModuleScope -ScriptBlock {
                $result.Members | Should -BeNullOrEmpty
                $result.MembersToInclude | Should -BeNullOrEmpty
            }
        }
    }

    Context 'When parameter MembersToExclude is assigned a value and the role is sysadmin, if SA is not in MembersToExclude, the output should be the same' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestParameters = @{
                    ServerRoleName   = 'sysadmin'
                    MembersToExclude = @(
                        'CONTOSO\John',
                        'CONTOSO\Kelly'
                    )
                }

                $script:result = Get-CorrectedMemberParameters @mockTestParameters
            }
        }

        It 'Should return an array with 2 elements' {
            InModuleScope -ScriptBlock {
                $result.MembersToExclude | Should -HaveCount 2
            }
        }

        It 'Should return the elements from Members' {
            InModuleScope -ScriptBlock {
                $result.MembersToExclude | Should -Be @(
                    'CONTOSO\John',
                    'CONTOSO\Kelly'
                )
            }
        }

        It 'Should not return extra values' {
            InModuleScope -ScriptBlock {
                $result.Members | Should -BeNullOrEmpty
                $result.MembersToInclude | Should -BeNullOrEmpty
            }
        }
    }

    Context 'When parameter MembersToExclude is assigned a value and the role is sysadmin, if SA is in MembersToExclude, SA should be removed' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestParameters = @{
                    ServerRoleName   = 'sysadmin'
                    MembersToExclude = @(
                        'CONTOSO\John',
                        'CONTOSO\Kelly',
                        'SA'
                    )
                }

                $result = Get-CorrectedMemberParameters @mockTestParameters
            }
        }

        It 'Should return an array with 2 elements' {
            InModuleScope -ScriptBlock {
                $result.MembersToExclude | Should -HaveCount 2
            }
        }

        It 'Should return the elements from Members' {
            InModuleScope -ScriptBlock {
                $result.MembersToExclude | Should -Not -Contain 'SA'
            }
        }

        It 'Should not return extra values' {
            InModuleScope -ScriptBlock {
                $result.Members | Should -BeNullOrEmpty
                $result.MembersToInclude | Should -BeNullOrEmpty
            }
        }
    }
}
