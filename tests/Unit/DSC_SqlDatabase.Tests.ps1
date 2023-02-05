<#
    .SYNOPSIS
        Unit test for DSC_SqlDatabase DSC resource.
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
    $script:dscResourceName = 'DSC_SqlDatabase'

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

Describe 'SqlDatabase\Get-TargetResource' {
    BeforeAll {
        $mockConnectSQL = {
            return @(
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType 'ScriptProperty' -Name 'Databases' -Value {
                            return @{
                                'AdventureWorks' = New-Object -TypeName Object |
                                    Add-Member -MemberType NoteProperty -Name 'Name' -Value 'AdventureWorks' -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'Collation' -Value 'SQL_Latin1_General_CP1_CS_AS' -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'CompatibilityLevel' -Value 'Version130' -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'RecoveryModel' -Value 'Full' -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'Owner' -Value 'sa' -PassThru -Force
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
        Context 'When the database should be absent' {
            BeforeEach {
                InModuleScope -ScriptBlock {
                    $script:mockGetTargetResourceParameters['Name'] = 'NonExistingDatabase'
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
                    $result.Name | Should -Be $mockGetTargetResourceParameters.Name
                }
            }

            It 'Should return the correct values for other properties' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.Collation | Should -BeNullOrEmpty
                    $result.CompatibilityLevel | Should -BeNullOrEmpty
                    $result.RecoveryModel | Should -BeNullOrEmpty
                    $result.Owner | Should -BeNullOrEmpty
                }
            }
        }

        Context 'When the database should be present' {
            BeforeEach {
                InModuleScope -ScriptBlock {
                    $script:mockGetTargetResourceParameters['Name'] = 'AdventureWorks'
                }
            }

            It 'Should return the state as present' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.Ensure | Should -Be 'Present'
                }

                Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
            }

            It 'Should return the same values as passed as parameters' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.ServerName | Should -Be $mockGetTargetResourceParameters.ServerName
                    $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                    $result.Name | Should -Be $mockGetTargetResourceParameters.Name
                }
            }

            It 'Should return the correct values for other properties' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.Collation | Should -Be 'SQL_Latin1_General_CP1_CS_AS'
                    $result.CompatibilityLevel | Should -Be 'Version130'
                    $result.RecoveryModel | Should -Be 'Full'
                    $result.OwnerName | Should -Be 'sa'
                }
            }
        }
    }
}

Describe 'SqlDatabase\Test-TargetResource' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            # Default parameters that are used for the It-blocks.
            $script:mockDefaultParameters = @{
                InstanceName = 'MSSQLSERVER'
                ServerName   = 'localhost'
                Name         = 'AdventureWorks'
            }
        }
    }

    BeforeEach {
        InModuleScope -ScriptBlock {
            $script:mockTestTargetResourceParameters = $script:mockDefaultParameters.Clone()
        }
    }

    Context 'When the system is in the desired state' {
        Context 'When the database should be absent' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Name               = 'AdventureWorks'
                        Ensure             = 'Absent'
                        ServerName         = 'localhost'
                        InstanceName       = 'MSSQLSERVER'
                        Collation          = $null
                        CompatibilityLevel = $null
                        RecoveryModel      = $null
                        OwnerName          = $null
                    }
                }
            }

            It 'Should return $true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:mockTestTargetResourceParameters['Ensure'] = 'Absent'

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeTrue
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the database should be present' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Name               = 'AdventureWorks'
                        Ensure             = 'Present'
                        ServerName         = 'localhost'
                        InstanceName       = 'MSSQLSERVER'
                        Collation          = 'SQL_Latin1_General_CP1_CS_AS'
                        CompatibilityLevel = 'Version130'
                        RecoveryModel      = 'Full'
                        OwnerName          = 'sa'
                    }
                }
            }

            It 'Should return $true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeTrue
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the property <PropertyName> is in desired state' -ForEach @(
            @{
                PropertyName = 'Collation'
                PropertyValue = 'SQL_Latin1_General_CP1_CS_AS'
            }
            @{
                PropertyName = 'CompatibilityLevel'
                PropertyValue = 'Version130'
            }
            @{
                PropertyName = 'RecoveryModel'
                PropertyValue = 'Full'
            }
            @{
                PropertyName = 'OwnerName'
                PropertyValue = 'sa'
            }
        ) {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Name               = 'AdventureWorks'
                        Ensure             = 'Present'
                        ServerName         = 'localhost'
                        InstanceName       = 'MSSQLSERVER'
                        Collation          = 'SQL_Latin1_General_CP1_CS_AS'
                        CompatibilityLevel = 'Version130'
                        RecoveryModel      = 'Full'
                        OwnerName          = 'sa'
                    }
                }
            }

            It 'Should return $true' {
                InModuleScope -Parameters $_ -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:mockTestTargetResourceParameters[$PropertyName] = $PropertyValue

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeTrue
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When the system is not in the desired state' {
        Context 'When the database exist but should be absent' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Name               = 'AdventureWorks'
                        Ensure             = 'Absent'
                        ServerName         = 'localhost'
                        InstanceName       = 'MSSQLSERVER'
                        Collation          = $null
                        CompatibilityLevel = $null
                        RecoveryModel      = $null
                        OwnerName          = $null
                    }
                }
            }

            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:mockTestTargetResourceParameters['Ensure'] = 'Present'

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeFalse
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the database is missing but should be present' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Name               = 'AdventureWorks'
                        Ensure             = 'Present'
                        ServerName         = 'localhost'
                        InstanceName       = 'MSSQLSERVER'
                        Collation          = 'SQL_Latin1_General_CP1_CS_AS'
                        CompatibilityLevel = 'Version130'
                        RecoveryModel      = 'Full'
                        OwnerName          = 'sa'
                    }
                }
            }

            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:mockTestTargetResourceParameters['Ensure'] = 'Absent'

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeFalse
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the property <PropertyName> is not in desired state' -ForEach @(
            @{
                PropertyName = 'Collation'
                PropertyValue = 'Finnish_Swedish_CI_AS'
            }
            @{
                PropertyName = 'CompatibilityLevel'
                PropertyValue = 'Version120'
            }
            @{
                PropertyName = 'RecoveryModel'
                PropertyValue = 'Simple'
            }
            @{
                PropertyName = 'OwnerName'
                PropertyValue = 'dbOwner1'
            }
        ) {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Name               = 'AdventureWorks'
                        Ensure             = 'Present'
                        ServerName         = 'localhost'
                        InstanceName       = 'MSSQLSERVER'
                        Collation          = 'SQL_Latin1_General_CP1_CS_AS'
                        CompatibilityLevel = 'Version130'
                        RecoveryModel      = 'Full'
                        OwnerName          = 'sa'
                    }
                }
            }

            It 'Should return $false' {
                InModuleScope -Parameters $_ -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:mockTestTargetResourceParameters[$PropertyName] = $PropertyValue

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeFalse
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }
    }
}

Describe 'SqlDatabase\Set-TargetResource' {
    BeforeAll {
        $mockConnectSQL = {
            return @(
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'MSSQLSERVER' -PassThru |
                        Add-Member -MemberType 'NoteProperty' -Name 'ComputerNamePhysicalNetBIOS' -Value 'localhost' -PassThru |
                        Add-Member -MemberType 'NoteProperty' -Name 'Collation' -Value 'SQL_Latin1_General_CP1_CI_AS' -PassThru |
                        Add-Member -MemberType 'NoteProperty' -Name 'VersionMajor' -Value 13 -PassThru |
                        Add-Member -MemberType 'ScriptMethod' -Name 'EnumCollations' -Value {
                            return @(
                                (
                                    New-Object -TypeName Object |
                                        Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'SQL_Latin1_General_CP1_CI_AS' -PassThru -Force
                                ),
                                (
                                    New-Object -TypeName Object |
                                        Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'SQL_Latin1_General_CP1_CS_AS' -PassThru -Force
                                ),
                                (
                                    New-Object -TypeName Object |
                                        Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'SQL_Latin1_General_Pref_CP850_CI_AS' -PassThru -Force
                                )
                            )
                        } -PassThru |
                        Add-Member -MemberType 'ScriptProperty' -Name 'Databases' -Value {
                            return @{
                                'AdventureWorks' = New-Object -TypeName Object |
                                    Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'AdventureWorks' -PassThru |
                                    Add-Member -MemberType 'NoteProperty' -Name 'Collation' -Value 'SQL_Latin1_General_CP1_CS_AS' -PassThru |
                                    Add-Member -MemberType 'NoteProperty' -Name 'CompatibilityLevel' -Value 'Version130' -PassThru |
                                    Add-Member -MemberType 'NoteProperty' -Name 'RecoveryModel' -Value 'Full' -PassThru |
                                    Add-Member -MemberType 'NoteProperty' -Name 'Owner' -Value 'sa' -PassThru |
                                    Add-Member -MemberType 'ScriptMethod' -Name 'Drop' -Value {
                                        if ($mockInvalidOperationForDropMethod)
                                        {
                                            throw 'Mock Drop method was called with invalid operation.'
                                        }

                                        if ($this.Name -ne $mockExpectedDatabaseNameToDrop)
                                        {
                                            throw "Called mocked Drop() method without dropping the right database. Expected '{0}'. But was '{1}'." `
                                                -f $mockExpectedDatabaseNameToDrop, $this.Name
                                        }

                                        InModuleScope -ScriptBlock {
                                            $script:methodDropWasCalled += 1
                                        }
                                    } -PassThru |
                                    Add-Member -MemberType 'ScriptMethod' -Name 'SetOwner' -Value {
                                        if ($mockInvalidOperationForSetOwnerMethod)
                                        {
                                            throw 'Mock SetOwner method was called with invalid operation.'
                                        }

                                        InModuleScope -ScriptBlock {
                                            $script:methodSetOwnerWasCalled += 1
                                        }
                                    } -PassThru |
                                    Add-Member -MemberType 'ScriptMethod' -Name 'Alter' -Value {
                                        if ($mockInvalidOperationForAlterMethod)
                                        {
                                            throw 'Mock Alter method was called with invalid operation.'
                                        }

                                        InModuleScope -ScriptBlock {
                                            $script:methodAlterWasCalled += 1
                                        }
                                    } -PassThru -Force
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
                Name         = 'AdventureWorks'
            }
        }
    }

    BeforeEach {
        InModuleScope -ScriptBlock {
            $script:mockSetTargetResourceParameters = $script:mockDefaultParameters.Clone()

            $script:methodDropWasCalled = 0
            $script:methodSetOwnerWasCalled = 0
            $script:methodAlterWasCalled = 0
            $script:newObjectMethodSetOwnerWasCalled = 0
            $script:newObjectMethodCreateWasCalled = 0
        }
    }

    Context 'When the system is not in the desired state' {
        Context 'When the database should be present' {
            BeforeAll {
                $mockNewObjectDatabase = {
                    return @(
                        (
                            New-Object -TypeName Object |
                                Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'NewDatabase' -PassThru |
                                Add-Member -MemberType 'NoteProperty' -Name 'Collation' -Value '' -PassThru |
                                Add-Member -MemberType 'NoteProperty' -Name 'CompatibilityLevel' -Value '' -PassThru |
                                Add-Member -MemberType 'NoteProperty' -Name 'RecoveryModel' -Value '' -PassThru |
                                Add-Member -MemberType 'NoteProperty' -Name 'Owner' -Value '' -PassThru |
                                Add-Member -MemberType 'ScriptMethod' -Name 'Create' -Value {
                                    if ($mockInvalidOperationForCreateMethod)
                                    {
                                        throw 'Mock Create Method was called with invalid operation.'
                                    }

                                    if ($this.Name -ne $mockExpectedDatabaseNameToCreate)
                                    {
                                        throw "Called mocked Create() method without adding the right database. Expected '{0}'. But was '{1}'." `
                                            -f $mockExpectedDatabaseNameToCreate, $this.Name
                                    }

                                    InModuleScope -ScriptBlock {
                                        $script:newObjectMethodCreateWasCalled += 1
                                    }
                                } -PassThru |
                                Add-Member -MemberType 'ScriptMethod' -Name 'SetOwner' -Value {
                                    InModuleScope -ScriptBlock {
                                        $script:newObjectMethodSetOwnerWasCalled += 1
                                    }
                                } -PassThru -Force
                        )
                    )
                }

                Mock -CommandName New-Object -MockWith $mockNewObjectDatabase -ParameterFilter {
                    $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Database'
                }
            }

            It 'Should call the correct method' {
                $mockExpectedDatabaseNameToCreate = 'NewDatabase'

                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:mockSetTargetResourceParameters['Ensure'] = 'Present'
                    $script:mockSetTargetResourceParameters['Name'] = 'NewDatabase'

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                    $script:newObjectMethodCreateWasCalled | Should -Be 1
                }

                Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
            }

            Context 'When creating the database and setting property <PropertyName>' -ForEach @(
                @{
                    PropertyName = 'Collation'
                    PropertyValue = 'SQL_Latin1_General_Pref_CP850_CI_AS'
                }
                @{
                    PropertyName = 'CompatibilityLevel'
                    PropertyValue = 'Version120'
                }
                @{
                    PropertyName = 'RecoveryModel'
                    PropertyValue = 'Simple'
                }
                @{
                    PropertyName = 'OwnerName'
                    PropertyValue = 'dbOwner1'
                }
            ) {
                It 'Should call the correct method' {
                    $mockExpectedDatabaseNameToCreate = 'NewDatabase'

                    InModuleScope -Parameters $_ -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $script:mockSetTargetResourceParameters['Ensure'] = 'Present'
                        $script:mockSetTargetResourceParameters['Name'] = 'NewDatabase'
                        $script:mockSetTargetResourceParameters[$PropertyName] = $PropertyValue

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                        $script:newObjectMethodCreateWasCalled | Should -Be 1

                        if ($PropertyName -eq 'OwnerName')
                        {
                            $script:newObjectMethodSetOwnerWasCalled | Should -Be 1
                        }
                    }

                    Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                It 'Should throw the correct error message when method Create() fails' {
                    $mockInvalidOperationForCreateMethod = $true

                    InModuleScope -Parameters $_ -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $script:mockSetTargetResourceParameters['Ensure'] = 'Present'
                        $script:mockSetTargetResourceParameters['Name'] = 'NewDatabase'
                        $script:mockSetTargetResourceParameters[$PropertyName] = $PropertyValue

                        $mockErrorMessage = $script:localizedData.FailedToCreateDatabase -f 'NewDatabase'

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw ('*' + $mockErrorMessage + '*')
                    }

                    $mockInvalidOperationForCreateMethod = $false
                }
            }
        }

        Context 'When the database should be absent' {
            BeforeAll {
                $mockExpectedDatabaseNameToDrop = 'AdventureWorks'
            }

            It 'Should call the correct method' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:mockSetTargetResourceParameters['Ensure'] = 'Absent'

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                    $script:methodDropWasCalled | Should -Be 1
                }

                Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
            }

            It 'Should throw the correct error if the database cannot be dropped' {
                $mockInvalidOperationForDropMethod = $true

                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:mockSetTargetResourceParameters['Ensure'] = 'Absent'

                    $mockErrorMessage = $script:localizedData.FailedToDropDatabase -f 'AdventureWorks'

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw ('*' + $mockErrorMessage + '*')
                }

                Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It

                $mockInvalidOperationForDropMethod = $false
            }
        }

        Context 'When the property <PropertyName> is not in desired state' -ForEach @(
            @{
                PropertyName = 'Collation'
                PropertyValue = 'SQL_Latin1_General_Pref_CP850_CI_AS'
            }
            @{
                PropertyName = 'CompatibilityLevel'
                PropertyValue = 'Version120'
            }
            @{
                PropertyName = 'RecoveryModel'
                PropertyValue = 'Simple'
            }
            @{
                PropertyName = 'OwnerName'
                PropertyValue = 'dbOwner1'
            }
        ) {
            It 'Should call the correct method' {
                InModuleScope -Parameters $_ -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:mockSetTargetResourceParameters[$PropertyName] = $PropertyValue

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                    $script:methodAlterWasCalled | Should -Be 1
                }

                Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
            }

            It 'Should throw the correct error message when method Alter() fails' {
                $mockInvalidOperationForAlterMethod = $true

                InModuleScope -Parameters $_ -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:mockSetTargetResourceParameters['Ensure'] = 'Present'
                    $script:mockSetTargetResourceParameters['Name'] = 'AdventureWorks'
                    $script:mockSetTargetResourceParameters[$PropertyName] = $PropertyValue

                    $mockErrorMessage = $script:localizedData.FailedToUpdateDatabase -f 'AdventureWorks'

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw ('*' + $mockErrorMessage + '*')
                }

                $mockInvalidOperationForAlterMethod = $false
            }
        }

        Context 'When the passing an invalid compatibility level' {
            It 'Should throw the correct error message' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:mockSetTargetResourceParameters['CompatibilityLevel'] = 'Version140'

                    $mockErrorMessage = $script:localizedData.InvalidCompatibilityLevel -f $mockSetTargetResourceParameters.CompatibilityLevel, 'MSSQLSERVER'

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw ('*' + $mockErrorMessage)
                }
            }
        }

        Context 'When the passing an invalid collation' {
            It 'Should throw the correct error message' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:mockSetTargetResourceParameters['Collation'] = 'Finnish_Swedish_CI_AS'

                    $mockErrorMessage = $script:localizedData.InvalidCollation -f $mockSetTargetResourceParameters.Collation, 'MSSQLSERVER'

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw ('*' + $mockErrorMessage)
                }
            }
        }

        Context 'When the owner fails to update on an existing database' {
            BeforeAll {
                $mockInvalidOperationForSetOwnerMethod = $true
            }

            AfterAll {
                $mockInvalidOperationForSetOwnerMethod = $false
            }

            It 'Should throw the correct error message' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:mockSetTargetResourceParameters['OwnerName'] = 'NewOwner'

                    $mockErrorMessage = $script:localizedData.FailedToUpdateOwner -f 'NewOwner', 'AdventureWorks'

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw ('*' + $mockErrorMessage + '*')
                }
            }
        }
    }
}
