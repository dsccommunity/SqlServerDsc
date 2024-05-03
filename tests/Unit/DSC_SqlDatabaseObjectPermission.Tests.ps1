<#
    .SYNOPSIS
        Unit test for DSC_SqlDatabaseObjectPermission DSC resource.
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
    $script:dscResourceName = 'DSC_SqlDatabaseObjectPermission'

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

Describe 'SqlDatabaseObjectPermission\Get-TargetResource' -Tag 'Get' {
    BeforeAll {
        $mockConnectSQL = {
            $mockSmoServer = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server

            $mockSmoServer.InstanceName = 'MSSQLSERVER'
            $mockSmoServer.ComputerNamePhysicalNetBIOS = 'localhost'
            $mockSmoServer.DefaultFile = 'C:\Program Files\Data\'
            $mockSmoServer.DefaultLog = 'C:\Program Files\Log\'
            <#
                Ending backslash is not set on the backup directory path here
                because of a regression test for issue #1307.
            #>
            $mockSmoServer.BackupDirectory = 'C:\Program Files\Backup'

            return $mockSmoServer
        }

        Mock -CommandName Connect-SQL -MockWith $mockConnectSQL
    }

    Context 'When the system is in the desired state' {
        BeforeAll {
            Mock -CommandName New-Object -ParameterFilter {
                $TypeName -eq 'Microsoft.SqlServer.Management.Smo.ObjectPermissionSet'
            } -MockWith {
                # Return anything so we get an object to pass in the pipeline.
                return ''
            }

            Mock -CommandName Get-Member -MockWith {
                <#
                    Returns the names of the properties of the type
                    Microsoft.SqlServer.Management.Smo.ObjectPermissionSet.
                #>
                return @(
                    @{
                        Name = 'Alter'
                    }
                    @{
                        Name = 'Connect'
                    }
                    @{
                        Name = 'Control'
                    }
                    @{
                        Name = 'CreateSequence'
                    }
                    @{
                        Name = 'Delete'
                    }
                    @{
                        Name = 'Execute'
                    }
                    @{
                        Name = 'Impersonate'
                    }
                    @{
                        Name = 'Insert'
                    }
                    @{
                        Name = 'Receive'
                    }
                    @{
                        Name = 'References'
                    }
                    @{
                        Name = 'Select'
                    }
                    @{
                        Name = 'Send'
                    }
                    @{
                        Name = 'TakeOwnership'
                    }
                    @{
                        Name = 'Update'
                    }
                    @{
                        Name = 'ViewChangeTracking'
                    }
                    @{
                        Name = 'ViewDefinition'
                    }
                )
            }

            Mock -CommandName Get-DatabaseObject -MockWith {
                # Should mock a database object, e.g. Schema, Table, View.
                return New-Object -TypeName PSCustomObject |
                    Add-Member -MemberType ScriptMethod -Name 'EnumObjectPermissions' -Value {
                        # Returns properties of the type Microsoft.SqlServer.Management.Smo.ObjectPermissionInfo.
                        return New-Object -TypeName PSCustomObject |
                            Add-Member -MemberType NoteProperty -Name 'Grantee' -Value 'TestAppRole' -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'GranteeType' -Value 'ApplicationRole' -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'Grantor' -Value 'dbo' -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'GrantorType' -Value 'User' -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'ColumnName' -Value $null -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'ObjectClass' -Value 'ObjectColumn' -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'ObjectName' -Value 'Table1' -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'ObjectSchema' -Value 'dbo' -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'ObjectID' -Value '245575913' -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'PermissionState' -Value 'Grant' -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'PermissionType' -Value @(
                                # Returns properties of the type Microsoft.SqlServer.Management.Smo.ObjectPermissionSet.
                                New-Object -TypeName PSCustomObject |
                                    Add-Member -MemberType NoteProperty -Name 'Alter' -Value $false -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'Connect' -Value $false -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'Control' -Value $false -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'CreateSequence' -Value $false -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'Delete' -Value $false -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'Execute' -Value $false -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'Impersonate' -Value $false -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'Insert' -Value $false -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'Receive' -Value $false -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'References' -Value $false -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'Select' -Value $true -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'Send' -Value $false -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'TakeOwnership' -Value $false -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'Update' -Value $true -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'ViewChangeTracking' -Value $false -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'ViewDefinition' -Value $false -PassThru -Force
                                ) -PassThru -Force
                            } -PassThru -Force
            }

            InModuleScope -ScriptBlock {
                # Create an empty collection of CimInstance that we can return.
                $cimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                <#
                    Intentionally not using helper ConvertTo-CimDatabaseObjectPermission
                    to increase code coverage.
                #>
                $cimInstancePermissionCollection += New-CimInstance `
                    -ClassName 'DSC_DatabaseObjectPermission' `
                    -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                    -Property @{
                        State      = 'Grant'
                        Permission = 'Select'
                        Ensure     = '' # Must be empty string to hit a line in the code.
                    } `
                    -ClientOnly

                $cimInstancePermissionCollection += New-CimInstance `
                    -ClassName 'DSC_DatabaseObjectPermission' `
                    -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                    -Property @{
                        State      = 'Grant'
                        Permission = 'Update'
                        Ensure     = '' # Must be empty string to hit a line in the code.
                    } `
                    -ClientOnly

                $script:mockGetTargetResourceParameters = @{
                    InstanceName = 'DSCTEST'
                    DatabaseName = 'AdventureWorks'
                    SchemaName   = 'dbo'
                    ObjectName   = 'Table1'
                    ObjectType   = 'Table'
                    Name         = 'TestAppRole'
                    Permission   = $cimInstancePermissionCollection
                }
            }
        }

        It 'Should return the same values as the passed parameter values' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $getTargetResourceResult = Get-TargetResource @mockGetTargetResourceParameters

                $getTargetResourceResult.ServerName | Should -Be $env:COMPUTERNAME
                $getTargetResourceResult.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                $getTargetResourceResult.DatabaseName | Should -Be $mockGetTargetResourceParameters.DatabaseName
                $getTargetResourceResult.SchemaName | Should -Be $mockGetTargetResourceParameters.SchemaName
                $getTargetResourceResult.ObjectName | Should -Be $mockGetTargetResourceParameters.ObjectName
                $getTargetResourceResult.ObjectType | Should -Be $mockGetTargetResourceParameters.ObjectType
                $getTargetResourceResult.Name | Should -Be $mockGetTargetResourceParameters.Name
            }
        }

        It 'Should return the correct metadata for the permission state' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $getTargetResourceResult = Get-TargetResource @mockGetTargetResourceParameters

                $getTargetResourceResult.Permission | Should -HaveCount 2
                $getTargetResourceResult.Permission[0] | Should -BeOfType 'CimInstance'
                $getTargetResourceResult.Permission[1] | Should -BeOfType 'CimInstance'

                $grantPermission = $getTargetResourceResult.Permission | Where-Object -FilterScript { $_.State -eq 'Grant' }
                $grantPermission | Should -Not -BeNullOrEmpty
                $grantPermission.Ensure[0] | Should -Be 'Present'
                $grantPermission.Ensure[1] | Should -Be 'Present'
                $grantPermission.Permission | Should -HaveCount 2
                $grantPermission.Permission | Should -Contain @('Select')
                $grantPermission.Permission | Should -Contain @('Update')
            }
        }
    }

    Context 'When the system is not in the desired state' {
        BeforeAll {
            Mock -CommandName New-Object -ParameterFilter {
                $TypeName -eq 'Microsoft.SqlServer.Management.Smo.ObjectPermissionSet'
            } -MockWith {
                # Return anything so we get an object to pass in the pipeline.
                return ''
            }

            Mock -CommandName Get-Member -MockWith {
                <#
                    Returns the names of the properties of the type
                    Microsoft.SqlServer.Management.Smo.ObjectPermissionSet.
                #>
                return @(
                    @{
                        Name = 'Alter'
                    }
                    @{
                        Name = 'Connect'
                    }
                    @{
                        Name = 'Control'
                    }
                    @{
                        Name = 'CreateSequence'
                    }
                    @{
                        Name = 'Delete'
                    }
                    @{
                        Name = 'Execute'
                    }
                    @{
                        Name = 'Impersonate'
                    }
                    @{
                        Name = 'Insert'
                    }
                    @{
                        Name = 'Receive'
                    }
                    @{
                        Name = 'References'
                    }
                    @{
                        Name = 'Select'
                    }
                    @{
                        Name = 'Send'
                    }
                    @{
                        Name = 'TakeOwnership'
                    }
                    @{
                        Name = 'Update'
                    }
                    @{
                        Name = 'ViewChangeTracking'
                    }
                    @{
                        Name = 'ViewDefinition'
                    }
                )
            }

            Mock -CommandName Get-DatabaseObject -MockWith {
                # Should mock a database object, e.g. Schema, Table, View.
                return New-Object -TypeName PSCustomObject |
                    Add-Member -MemberType ScriptMethod -Name 'EnumObjectPermissions' -Value {
                        # Returns properties of the type Microsoft.SqlServer.Management.Smo.ObjectPermissionInfo.
                        return New-Object -TypeName PSCustomObject |
                            Add-Member -MemberType NoteProperty -Name 'Grantee' -Value 'TestAppRole' -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'GranteeType' -Value 'ApplicationRole' -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'Grantor' -Value 'dbo' -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'GrantorType' -Value 'User' -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'ColumnName' -Value $null -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'ObjectClass' -Value 'ObjectColumn' -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'ObjectName' -Value 'Table1' -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'ObjectSchema' -Value 'dbo' -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'ObjectID' -Value '245575913' -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'PermissionState' -Value 'Grant' -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'PermissionType' -Value @(
                                # Returns properties of the type Microsoft.SqlServer.Management.Smo.ObjectPermissionSet.
                                New-Object -TypeName PSCustomObject |
                                    Add-Member -MemberType NoteProperty -Name 'Alter' -Value $false -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'Connect' -Value $false -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'Control' -Value $false -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'CreateSequence' -Value $false -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'Delete' -Value $false -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'Execute' -Value $false -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'Impersonate' -Value $false -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'Insert' -Value $false -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'Receive' -Value $false -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'References' -Value $false -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'Select' -Value $true -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'Send' -Value $false -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'TakeOwnership' -Value $false -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'Update' -Value $true -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'ViewChangeTracking' -Value $false -PassThru |
                                    Add-Member -MemberType NoteProperty -Name 'ViewDefinition' -Value $false -PassThru -Force
                                ) -PassThru -Force
                            } -PassThru -Force
            }
        }

        Context 'When an existing permission state is missing a permission' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    # Create an empty collection of CimInstance that we can return.
                    $cimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                    <#
                        Intentionally not using helper ConvertTo-CimDatabaseObjectPermission
                        to increase code coverage.
                    #>
                    $cimInstancePermissionCollection += New-CimInstance `
                        -ClassName 'DSC_DatabaseObjectPermission' `
                        -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                        -Property @{
                            State      = 'Grant'
                            Permission = 'Delete'
                            Ensure     = 'Present'
                        } `
                        -ClientOnly

                    $script:mockGetTargetResourceParameters = @{
                        InstanceName = 'DSCTEST'
                        DatabaseName = 'AdventureWorks'
                        SchemaName   = 'dbo'
                        ObjectName   = 'Table1'
                        ObjectType   = 'Table'
                        Name         = 'TestAppRole'
                        Permission   = $cimInstancePermissionCollection
                    }
                }
            }

            It 'Should return the same values as the passed parameter values' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $getTargetResourceResult = Get-TargetResource @mockGetTargetResourceParameters

                    $getTargetResourceResult.ServerName | Should -Be $env:COMPUTERNAME
                    $getTargetResourceResult.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                    $getTargetResourceResult.DatabaseName | Should -Be $mockGetTargetResourceParameters.DatabaseName
                    $getTargetResourceResult.SchemaName | Should -Be $mockGetTargetResourceParameters.SchemaName
                    $getTargetResourceResult.ObjectName | Should -Be $mockGetTargetResourceParameters.ObjectName
                    $getTargetResourceResult.ObjectType | Should -Be $mockGetTargetResourceParameters.ObjectType
                    $getTargetResourceResult.Name | Should -Be $mockGetTargetResourceParameters.Name
                }
            }

            It 'Should return the correct metadata for the permission state' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $getTargetResourceResult = Get-TargetResource @mockGetTargetResourceParameters

                    $getTargetResourceResult.Permission | Should -HaveCount 1
                    $getTargetResourceResult.Permission[0] | Should -BeOfType 'CimInstance'

                    $grantPermission = $getTargetResourceResult.Permission | Where-Object -FilterScript { $_.State -eq 'Grant' }
                    $grantPermission | Should -Not -BeNullOrEmpty
                    $grantPermission.Ensure | Should -Be 'Absent'
                    $grantPermission.Permission | Should -HaveCount 1
                    $grantPermission.Permission | Should -Contain @('Delete')
                }
            }
        }

        Context 'When a permission state is missing that should be present' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    # Create an empty collection of CimInstance that we can return.
                    $cimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                    <#
                        Intentionally not using helper ConvertTo-CimDatabaseObjectPermission
                        to increase code coverage.
                    #>
                    $cimInstancePermissionCollection += New-CimInstance `
                        -ClassName 'DSC_DatabaseObjectPermission' `
                        -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                        -Property @{
                            State      = 'Deny'
                            Permission = 'Delete'
                            Ensure     = 'Present'
                        } `
                        -ClientOnly

                    $script:mockGetTargetResourceParameters = @{
                        InstanceName = 'DSCTEST'
                        DatabaseName = 'AdventureWorks'
                        SchemaName   = 'dbo'
                        ObjectName   = 'Table1'
                        ObjectType   = 'Table'
                        Name         = 'TestAppRole'
                        Permission   = $cimInstancePermissionCollection
                    }
                }
            }

            It 'Should return the same values as the passed parameter values' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $getTargetResourceResult = Get-TargetResource @mockGetTargetResourceParameters

                    $getTargetResourceResult.ServerName | Should -Be $env:COMPUTERNAME
                    $getTargetResourceResult.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                    $getTargetResourceResult.DatabaseName | Should -Be $mockGetTargetResourceParameters.DatabaseName
                    $getTargetResourceResult.SchemaName | Should -Be $mockGetTargetResourceParameters.SchemaName
                    $getTargetResourceResult.ObjectName | Should -Be $mockGetTargetResourceParameters.ObjectName
                    $getTargetResourceResult.ObjectType | Should -Be $mockGetTargetResourceParameters.ObjectType
                    $getTargetResourceResult.Name | Should -Be $mockGetTargetResourceParameters.Name
                }
            }

            It 'Should return the correct metadata for the permission state' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $getTargetResourceResult = Get-TargetResource @mockGetTargetResourceParameters

                    $getTargetResourceResult.Permission | Should -HaveCount 1
                    $getTargetResourceResult.Permission[0] | Should -BeOfType 'CimInstance'

                    $grantPermission = $getTargetResourceResult.Permission | Where-Object -FilterScript { $_.State -eq 'Deny' }
                    $grantPermission | Should -Not -BeNullOrEmpty
                    $grantPermission.Ensure | Should -Be 'Absent'
                    $grantPermission.Permission | Should -HaveCount 1
                    $grantPermission.Permission | Should -Contain @('Delete')
                }
            }
        }

        Context 'When a permission state is present but should be absent' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    # Create an empty collection of CimInstance that we can return.
                    $cimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                    <#
                        Intentionally not using helper ConvertTo-CimDatabaseObjectPermission
                        to increase code coverage.
                    #>
                    $cimInstancePermissionCollection += New-CimInstance `
                        -ClassName 'DSC_DatabaseObjectPermission' `
                        -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                        -Property @{
                            State      = 'Grant'
                            Permission = 'Select'
                            Ensure     = 'Absent'
                        } `
                        -ClientOnly

                    $script:mockGetTargetResourceParameters = @{
                        InstanceName = 'DSCTEST'
                        DatabaseName = 'AdventureWorks'
                        SchemaName   = 'dbo'
                        ObjectName   = 'Table1'
                        ObjectType   = 'Table'
                        Name         = 'TestAppRole'
                        Permission   = $cimInstancePermissionCollection
                    }
                }
            }

            It 'Should return the same values as the passed parameter values' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $getTargetResourceResult = Get-TargetResource @mockGetTargetResourceParameters

                    $getTargetResourceResult.ServerName | Should -Be $env:COMPUTERNAME
                    $getTargetResourceResult.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                    $getTargetResourceResult.DatabaseName | Should -Be $mockGetTargetResourceParameters.DatabaseName
                    $getTargetResourceResult.SchemaName | Should -Be $mockGetTargetResourceParameters.SchemaName
                    $getTargetResourceResult.ObjectName | Should -Be $mockGetTargetResourceParameters.ObjectName
                    $getTargetResourceResult.ObjectType | Should -Be $mockGetTargetResourceParameters.ObjectType
                    $getTargetResourceResult.Name | Should -Be $mockGetTargetResourceParameters.Name
                }
            }

            It 'Should return the correct metadata for the permission state' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $getTargetResourceResult = Get-TargetResource @mockGetTargetResourceParameters

                    $getTargetResourceResult.Permission | Should -HaveCount 1
                    $getTargetResourceResult.Permission[0] | Should -BeOfType 'CimInstance'

                    $grantPermission = $getTargetResourceResult.Permission | Where-Object -FilterScript { $_.State -eq 'Grant' }
                    $grantPermission | Should -Not -BeNullOrEmpty
                    $grantPermission.Ensure | Should -Be 'Present'
                    $grantPermission.Permission | Should -HaveCount 1
                    $grantPermission.Permission | Should -Contain @('Select')
                    $grantPermission.Permission | Should -Not -Contain @('Delete')
                }
            }
        }
    }
}

Describe 'SqlDatabaseObjectPermission\Test-TargetResource' -Tag 'Test' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            $cimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

            $cimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                -Permission 'Select' `
                -PermissionState 'Grant' `
                -Ensure 'Present'

            # Using all lower-case on 'update' intentionally.
            $cimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                -Permission 'update' `
                -PermissionState 'Grant' `
                -Ensure 'Present'

            $script:mockTestTargetResourceParameters = @{
                InstanceName = 'sql2014'
                DatabaseName = 'AdventureWorks'
                SchemaName   = 'dbo'
                ObjectName   = 'Table1'
                ObjectType   = 'Table'
                Name         = 'TestAppRole'
                Permission   = $cimInstancePermissionCollection
            }
        }
    }

    Context 'When the system is in the desired state' {
        BeforeAll {
            Mock -CommandName Compare-TargetResourceState -MockWith {
                return @(
                    @{
                        ParameterName  = 'Permission'
                        InDesiredState = $true
                    }
                )
            }
        }

        It 'Should return $true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testTargetResourceResult = Test-TargetResource @mockTestTargetResourceParameters
                $testTargetResourceResult | Should -BeTrue

                Should -Invoke -CommandName Compare-TargetResourceState -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When the system is not in the desired state' {
        BeforeAll {
            Mock -CommandName Compare-TargetResourceState -MockWith {
                return @(
                    @{
                        ParameterName  = 'Permission'
                        InDesiredState = $false
                    }
                )
            }
        }

        It 'Should return $false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testTargetResourceResult = Test-TargetResource @mockTestTargetResourceParameters
                $testTargetResourceResult | Should -BeFalse

                Should -Invoke -CommandName Compare-TargetResourceState -Exactly -Times 1 -Scope It
            }
        }
    }
}

Describe 'SqlDatabaseObjectPermission\Compare-TargetResourceState' -Tag 'Compare' {
    Context 'When the system is in the desired state' {
        BeforeAll {
            # Create an empty collection of CimInstance that we can return.
            $cimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

            $cimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                -Permission 'Select' `
                -PermissionState 'Grant'

            <#
                Using all lower-case on 'update' intentionally.
                Intentionally not providing the CIM instance property
                'Ensure' on this CIM instance.
            #>
            $cimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                -Permission 'update' `
                -PermissionState 'Grant'

            <#
                Intentionally not using helper ConvertTo-CimDatabaseObjectPermission
                to increase code coverage.
            #>
            $cimInstancePermissionCollection += New-CimInstance `
                -ClassName 'DSC_DatabaseObjectPermission' `
                -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                -Property @{
                    State      = 'Deny'
                    Permission = 'Delete'
                    Ensure     = '' # Must be empty string to hit a line in the code.
                } `
                -ClientOnly

            $cimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                -Permission 'Drop' `
                -PermissionState 'GrantWithGrant' `
                -Ensure 'Absent'

            Mock -CommandName Get-TargetResource -MockWith {
                return @{
                    InstanceName = 'sql2014'
                    DatabaseName = 'AdventureWorks'
                    SchemaName   = 'dbo'
                    ObjectName   = 'Table1'
                    ObjectType   = 'Table'
                    Name         = 'TestAppRole'
                    Permission   = $cimInstancePermissionCollection
                    ServerName   = 'testclu01a'
                }
            }

            # Intentionally left the parameter ServerName out.
            $script:mockCompareTargetResourceParameters = @{
                InstanceName = 'sql2014'
                DatabaseName = 'AdventureWorks'
                SchemaName   = 'dbo'
                ObjectName   = 'Table1'
                ObjectType   = 'Table'
                Name         = 'TestAppRole'
                Permission   = $cimInstancePermissionCollection
            }
        }

        It 'Should return the correct metadata for the permission property' {
            $compareTargetResourceStateResult = Compare-TargetResourceState @mockCompareTargetResourceParameters
            $compareTargetResourceStateResult | Should -HaveCount 1

            $comparedReturnValue = $compareTargetResourceStateResult | Where-Object -FilterScript { $_.ParameterName -eq 'Permission' }
            $comparedReturnValue | Should -Not -BeNullOrEmpty
            $comparedReturnValue.InDesiredState | Should -BeTrue

            # Actual permissions
            $comparedReturnValue.Actual | Should -HaveCount 4
            $comparedReturnValue.Actual[0] | Should -BeOfType 'CimInstance'
            $comparedReturnValue.Actual[1] | Should -BeOfType 'CimInstance'
            $comparedReturnValue.Actual[2] | Should -BeOfType 'CimInstance'
            $comparedReturnValue.Actual[3] | Should -BeOfType 'CimInstance'

            $grantPermission = $comparedReturnValue.Actual | Where-Object -FilterScript { $_.State -eq 'Grant' }
            $grantPermission | Should -Not -BeNullOrEmpty
            $grantPermission.Ensure[0] | Should -Be 'Present'
            $grantPermission.Ensure[1] | Should -Be 'Present'
            $grantPermission.Permission | Should -HaveCount 2
            $grantPermission.Permission | Should -Contain @('Select')
            $grantPermission.Permission | Should -Contain @('Update')

            $grantPermission = $comparedReturnValue.Actual | Where-Object -FilterScript { $_.State -eq 'Deny' }
            $grantPermission | Should -Not -BeNullOrEmpty
            $grantPermission.Ensure | Should -Be 'Present'
            $grantPermission.Permission | Should -HaveCount 1
            $grantPermission.Permission | Should -Contain @('Delete')

            $grantPermission = $comparedReturnValue.Actual | Where-Object -FilterScript { $_.State -eq 'GrantWithGrant' }
            $grantPermission | Should -Not -BeNullOrEmpty
            $grantPermission.Ensure | Should -Be 'Absent'
            $grantPermission.Permission | Should -HaveCount 1
            $grantPermission.Permission | Should -Contain @('Drop')

            # Expected permissions
            $comparedReturnValue.Expected | Should -HaveCount 4
            $comparedReturnValue.Expected[0] | Should -BeOfType 'CimInstance'
            $comparedReturnValue.Expected[1] | Should -BeOfType 'CimInstance'
            $comparedReturnValue.Expected[2] | Should -BeOfType 'CimInstance'
            $comparedReturnValue.Expected[3] | Should -BeOfType 'CimInstance'

            $grantPermission = $comparedReturnValue.Expected | Where-Object -FilterScript { $_.State -eq 'Grant' }
            $grantPermission | Should -Not -BeNullOrEmpty
            $grantPermission.Ensure[0] | Should -Be 'Present'
            $grantPermission.Ensure[1] | Should -Be 'Present'
            $grantPermission.Permission | Should -HaveCount 2
            $grantPermission.Permission | Should -Contain @('Select')
            $grantPermission.Permission | Should -Contain @('Update')

            $grantPermission = $comparedReturnValue.Expected | Where-Object -FilterScript { $_.State -eq 'Deny' }
            $grantPermission | Should -Not -BeNullOrEmpty
            $grantPermission.Ensure | Should -Be 'Present'
            $grantPermission.Permission | Should -HaveCount 1
            $grantPermission.Permission | Should -Contain @('Delete')

            $grantPermission = $comparedReturnValue.Expected | Where-Object -FilterScript { $_.State -eq 'GrantWithGrant' }
            $grantPermission | Should -Not -BeNullOrEmpty
            $grantPermission.Ensure | Should -Be 'Absent'
            $grantPermission.Permission | Should -HaveCount 1
            $grantPermission.Permission | Should -Contain @('Drop')

            Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the system is not in the desired state' {
        Context 'When the permission state is already present in the current state but not in the desired state' {
            BeforeAll {
                # Holds the current permissions.
                $currentCimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                $currentCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                    -Permission 'Select' `
                    -PermissionState 'Grant' `
                    -Ensure 'Present'

                # Using all lower-case on 'update' intentionally.
                $currentCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                    -Permission 'update' `
                    -PermissionState 'Grant' `
                    -Ensure 'Present'

                $currentCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                    -Permission 'Delete' `
                    -PermissionState 'Deny' `
                    -Ensure 'Present'

                $currentCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                    -Permission 'Drop' `
                    -PermissionState 'GrantWithGrant' `
                    -Ensure 'Present'

                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        InstanceName = 'sql2014'
                        DatabaseName = 'AdventureWorks'
                        SchemaName   = 'dbo'
                        ObjectName   = 'Table1'
                        ObjectType   = 'Table'
                        Name         = 'TestAppRole'
                        Permission   = $currentCimInstancePermissionCollection
                        ServerName   = 'testclu01a'
                    }
                }
            }

            <#
                We test the actual permission that are reused in the nested
                Context-blocks so that we don't have to test that for each test.
            #>
            It 'Should return the correct actual permissions for the ''Permission'' property' {
                $script:mockCompareTargetResourceParameters = @{
                    InstanceName = 'sql2014'
                    DatabaseName = 'AdventureWorks'
                    SchemaName   = 'dbo'
                    ObjectName   = 'Table1'
                    ObjectType   = 'Table'
                    Name         = 'TestAppRole'
                    Permission   = $currentCimInstancePermissionCollection
                    ServerName   = 'testclu01a'
                }

                $compareTargetResourceStateResult = Compare-TargetResourceState @mockCompareTargetResourceParameters
                $compareTargetResourceStateResult | Should -HaveCount 1

                $comparedReturnValue = $compareTargetResourceStateResult | Where-Object -FilterScript { $_.ParameterName -eq 'Permission' }
                $comparedReturnValue | Should -Not -BeNullOrEmpty

                $comparedReturnValue.Actual | Should -HaveCount 4
                $comparedReturnValue.Actual[0] | Should -BeOfType 'CimInstance'
                $comparedReturnValue.Actual[1] | Should -BeOfType 'CimInstance'
                $comparedReturnValue.Actual[2] | Should -BeOfType 'CimInstance'
                $comparedReturnValue.Actual[3] | Should -BeOfType 'CimInstance'

                # Actual permissions
                $grantPermission = $comparedReturnValue.Actual | Where-Object -FilterScript { $_.State -eq 'Grant' }
                $grantPermission | Should -Not -BeNullOrEmpty
                $grantPermission.Ensure[0] | Should -Be 'Present'
                $grantPermission.Ensure[1] | Should -Be 'Present'
                $grantPermission.Permission | Should -HaveCount 2
                $grantPermission.Permission | Should -Contain @('Select')
                $grantPermission.Permission | Should -Contain @('Update')

                $grantPermission = $comparedReturnValue.Actual | Where-Object -FilterScript { $_.State -eq 'Deny' }
                $grantPermission | Should -Not -BeNullOrEmpty
                $grantPermission.Ensure | Should -Be 'Present'
                $grantPermission.Permission | Should -HaveCount 1
                $grantPermission.Permission | Should -Contain @('Delete')

                $grantPermission = $comparedReturnValue.Actual | Where-Object -FilterScript { $_.State -eq 'GrantWithGrant' }
                $grantPermission | Should -Not -BeNullOrEmpty
                $grantPermission.Ensure | Should -Be 'Present'
                $grantPermission.Permission | Should -HaveCount 1
                $grantPermission.Permission | Should -Contain @('Drop')

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }

            Context 'When the permission state ''Grant'' is ''Present'' but desired state is ''Absent''' {
                BeforeAll {
                    # Holds the desired permissions.
                    $desiredCimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                    $desiredCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                        -Permission 'Select' `
                        -PermissionState 'Grant' `
                        -Ensure 'Absent'

                    # Using all lower-case on 'update' intentionally.
                    $desiredCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                        -Permission 'update' `
                        -PermissionState 'Grant' `
                        -Ensure 'Absent'

                    $desiredCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                        -Permission 'Delete' `
                        -PermissionState 'Deny' `
                        -Ensure 'Present'

                    $desiredCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                        -Permission 'Drop' `
                        -PermissionState 'GrantWithGrant' `
                        -Ensure 'Present'
                }

                It 'Should return the correct metadata for the ''Permission'' property' {
                    $script:mockCompareTargetResourceParameters = @{
                        InstanceName = 'sql2014'
                        DatabaseName = 'AdventureWorks'
                        SchemaName   = 'dbo'
                        ObjectName   = 'Table1'
                        ObjectType   = 'Table'
                        Name         = 'TestAppRole'
                        Permission   = $desiredCimInstancePermissionCollection
                        ServerName   = 'testclu01a'
                    }

                    $compareTargetResourceStateResult = Compare-TargetResourceState @mockCompareTargetResourceParameters
                    $compareTargetResourceStateResult | Should -HaveCount 1

                    $comparedReturnValue = $compareTargetResourceStateResult | Where-Object -FilterScript { $_.ParameterName -eq 'Permission' }
                    $comparedReturnValue | Should -Not -BeNullOrEmpty
                    $comparedReturnValue.InDesiredState | Should -BeFalse

                    $comparedReturnValue.Expected | Should -HaveCount 4
                    $comparedReturnValue.Expected[0] | Should -BeOfType 'CimInstance'
                    $comparedReturnValue.Expected[1] | Should -BeOfType 'CimInstance'
                    $comparedReturnValue.Expected[2] | Should -BeOfType 'CimInstance'
                    $comparedReturnValue.Expected[3] | Should -BeOfType 'CimInstance'

                    # Expected permissions
                    $grantPermission = $comparedReturnValue.Expected | Where-Object -FilterScript { $_.State -eq 'Grant' }
                    $grantPermission | Should -Not -BeNullOrEmpty
                    $grantPermission.Ensure[0] | Should -Be 'Absent'
                    $grantPermission.Ensure[1] | Should -Be 'Absent'
                    $grantPermission.Permission | Should -HaveCount 2
                    $grantPermission.Permission | Should -Contain @('Select')
                    $grantPermission.Permission | Should -Contain @('Update')

                    $grantPermission = $comparedReturnValue.Expected | Where-Object -FilterScript { $_.State -eq 'Deny' }
                    $grantPermission | Should -Not -BeNullOrEmpty
                    $grantPermission.Ensure | Should -Be 'Present'
                    $grantPermission.Permission | Should -HaveCount 1
                    $grantPermission.Permission | Should -Contain @('Delete')

                    $grantPermission = $comparedReturnValue.Expected | Where-Object -FilterScript { $_.State -eq 'GrantWithGrant' }
                    $grantPermission | Should -Not -BeNullOrEmpty
                    $grantPermission.Ensure | Should -Be 'Present'
                    $grantPermission.Permission | Should -HaveCount 1
                    $grantPermission.Permission | Should -Contain @('Drop')

                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the permission state ''GrantWithGrant'' is ''Present'' but desired state is ''Absent''' {
                BeforeAll {
                    # Holds the desired permissions.
                    $desiredCimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                    $desiredCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                        -Permission 'Select' `
                        -PermissionState 'Grant' `
                        -Ensure 'Present'

                    # Using all lower-case on 'update' intentionally.
                    $desiredCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                        -Permission 'update' `
                        -PermissionState 'Grant' `
                        -Ensure 'Present'

                    $desiredCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                        -Permission 'Delete' `
                        -PermissionState 'Deny' `
                        -Ensure 'Present'

                    $desiredCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                        -Permission 'Drop' `
                        -PermissionState 'GrantWithGrant' `
                        -Ensure 'Absent'
                }

                It 'Should return the correct metadata for the ''Permission'' property' {
                    $script:mockCompareTargetResourceParameters = @{
                        InstanceName = 'sql2014'
                        DatabaseName = 'AdventureWorks'
                        SchemaName   = 'dbo'
                        ObjectName   = 'Table1'
                        ObjectType   = 'Table'
                        Name         = 'TestAppRole'
                        Permission   = $desiredCimInstancePermissionCollection
                        ServerName   = 'testclu01a'
                    }

                    $compareTargetResourceStateResult = Compare-TargetResourceState @mockCompareTargetResourceParameters
                    $compareTargetResourceStateResult | Should -HaveCount 1

                    $comparedReturnValue = $compareTargetResourceStateResult | Where-Object -FilterScript { $_.ParameterName -eq 'Permission' }
                    $comparedReturnValue | Should -Not -BeNullOrEmpty
                    $comparedReturnValue.InDesiredState | Should -BeFalse

                    $comparedReturnValue.Expected | Should -HaveCount 4
                    $comparedReturnValue.Expected[0] | Should -BeOfType 'CimInstance'
                    $comparedReturnValue.Expected[1] | Should -BeOfType 'CimInstance'
                    $comparedReturnValue.Expected[2] | Should -BeOfType 'CimInstance'
                    $comparedReturnValue.Expected[3] | Should -BeOfType 'CimInstance'

                    # Expected permissions
                    $grantPermission = $comparedReturnValue.Expected | Where-Object -FilterScript { $_.State -eq 'Grant' }
                    $grantPermission | Should -Not -BeNullOrEmpty
                    $grantPermission.Ensure[0] | Should -Be 'Present'
                    $grantPermission.Ensure[1] | Should -Be 'Present'
                    $grantPermission.Permission | Should -HaveCount 2
                    $grantPermission.Permission | Should -Contain @('Select')
                    $grantPermission.Permission | Should -Contain @('Update')

                    $grantPermission = $comparedReturnValue.Expected | Where-Object -FilterScript { $_.State -eq 'Deny' }
                    $grantPermission | Should -Not -BeNullOrEmpty
                    $grantPermission.Ensure | Should -Be 'Present'
                    $grantPermission.Permission | Should -HaveCount 1
                    $grantPermission.Permission | Should -Contain @('Delete')

                    $grantPermission = $comparedReturnValue.Expected | Where-Object -FilterScript { $_.State -eq 'GrantWithGrant' }
                    $grantPermission | Should -Not -BeNullOrEmpty
                    $grantPermission.Ensure | Should -Be 'Absent'
                    $grantPermission.Permission | Should -HaveCount 1
                    $grantPermission.Permission | Should -Contain @('Drop')

                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the permission state ''Deny'' is ''Present'' but desired state is ''Absent''' {
                BeforeAll {
                    # Holds the desired permissions.
                    $desiredCimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                    $desiredCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                        -Permission 'Select' `
                        -PermissionState 'Grant' `
                        -Ensure 'Present'

                    # Using all lower-case on 'update' intentionally.
                    $desiredCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                        -Permission 'update' `
                        -PermissionState 'Grant' `
                        -Ensure 'Present'

                    $desiredCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                        -Permission 'Delete' `
                        -PermissionState 'Deny' `
                        -Ensure 'Absent'

                    $desiredCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                        -Permission 'Drop' `
                        -PermissionState 'GrantWithGrant' `
                        -Ensure 'Present'
                }

                It 'Should return the correct metadata for the ''Permission'' property' {
                    $script:mockCompareTargetResourceParameters = @{
                        InstanceName = 'sql2014'
                        DatabaseName = 'AdventureWorks'
                        SchemaName   = 'dbo'
                        ObjectName   = 'Table1'
                        ObjectType   = 'Table'
                        Name         = 'TestAppRole'
                        Permission   = $desiredCimInstancePermissionCollection
                        ServerName   = 'testclu01a'
                    }

                    $compareTargetResourceStateResult = Compare-TargetResourceState @mockCompareTargetResourceParameters
                    $compareTargetResourceStateResult | Should -HaveCount 1

                    $comparedReturnValue = $compareTargetResourceStateResult | Where-Object -FilterScript { $_.ParameterName -eq 'Permission' }
                    $comparedReturnValue | Should -Not -BeNullOrEmpty
                    $comparedReturnValue.InDesiredState | Should -BeFalse

                    $comparedReturnValue.Expected | Should -HaveCount 4
                    $comparedReturnValue.Expected[0] | Should -BeOfType 'CimInstance'
                    $comparedReturnValue.Expected[1] | Should -BeOfType 'CimInstance'
                    $comparedReturnValue.Expected[2] | Should -BeOfType 'CimInstance'
                    $comparedReturnValue.Expected[3] | Should -BeOfType 'CimInstance'

                    # Expected permissions
                    $grantPermission = $comparedReturnValue.Expected | Where-Object -FilterScript { $_.State -eq 'Grant' }
                    $grantPermission | Should -Not -BeNullOrEmpty
                    $grantPermission.Ensure[0] | Should -Be 'Present'
                    $grantPermission.Ensure[1] | Should -Be 'Present'
                    $grantPermission.Permission | Should -HaveCount 2
                    $grantPermission.Permission | Should -Contain @('Select')
                    $grantPermission.Permission | Should -Contain @('Update')

                    $grantPermission = $comparedReturnValue.Expected | Where-Object -FilterScript { $_.State -eq 'Deny' }
                    $grantPermission | Should -Not -BeNullOrEmpty
                    $grantPermission.Ensure | Should -Be 'Absent'
                    $grantPermission.Permission | Should -HaveCount 1
                    $grantPermission.Permission | Should -Contain @('Delete')

                    $grantPermission = $comparedReturnValue.Expected | Where-Object -FilterScript { $_.State -eq 'GrantWithGrant' }
                    $grantPermission | Should -Not -BeNullOrEmpty
                    $grantPermission.Ensure | Should -Be 'Present'
                    $grantPermission.Permission | Should -HaveCount 1
                    $grantPermission.Permission | Should -Contain @('Drop')

                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the permissions for the permission state ''Grant'' is not in desired state' {
                BeforeAll {
                    # Holds the desired permissions.
                    $desiredCimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                    # Using all lower-case on 'update' intentionally.
                    $desiredCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                        -Permission 'CreateTable' `
                        -PermissionState 'Grant' `
                        -Ensure 'Present'
                }

                It 'Should return the correct metadata for the ''Permission'' property' {
                    $script:mockCompareTargetResourceParameters = @{
                        InstanceName = 'sql2014'
                        DatabaseName = 'AdventureWorks'
                        SchemaName   = 'dbo'
                        ObjectName   = 'Table1'
                        ObjectType   = 'Table'
                        Name         = 'TestAppRole'
                        Permission   = $desiredCimInstancePermissionCollection
                        ServerName   = 'testclu01a'
                    }

                    $compareTargetResourceStateResult = Compare-TargetResourceState @mockCompareTargetResourceParameters
                    $compareTargetResourceStateResult | Should -HaveCount 1

                    $comparedReturnValue = $compareTargetResourceStateResult | Where-Object -FilterScript { $_.ParameterName -eq 'Permission' }
                    $comparedReturnValue | Should -Not -BeNullOrEmpty
                    $comparedReturnValue.InDesiredState | Should -BeFalse

                    $comparedReturnValue.Expected | Should -HaveCount 1
                    $comparedReturnValue.Expected[0] | Should -BeOfType 'CimInstance'

                    # Expected permissions
                    $grantPermission = $comparedReturnValue.Expected | Where-Object -FilterScript { $_.State -eq 'Grant' }
                    $grantPermission | Should -Not -BeNullOrEmpty
                    $grantPermission.Ensure | Should -Be 'Present'
                    $grantPermission.Permission | Should -HaveCount 1
                    $grantPermission.Permission | Should -Contain @('CreateTable')

                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the permissions for the permission state ''GrantWithGrant'' is not in desired state' {
                BeforeAll {
                    # Holds the desired permissions.
                    $desiredCimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                    # Using all lower-case on 'update' intentionally.
                    $desiredCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                        -Permission 'CreateTable' `
                        -PermissionState 'GrantWithGrant' `
                        -Ensure 'Present'
                }

                It 'Should return the correct metadata for the ''Permission'' property' {
                    $script:mockCompareTargetResourceParameters = @{
                        InstanceName = 'sql2014'
                        DatabaseName = 'AdventureWorks'
                        SchemaName   = 'dbo'
                        ObjectName   = 'Table1'
                        ObjectType   = 'Table'
                        Name         = 'TestAppRole'
                        Permission   = $desiredCimInstancePermissionCollection
                        ServerName   = 'testclu01a'
                    }

                    $compareTargetResourceStateResult = Compare-TargetResourceState @mockCompareTargetResourceParameters
                    $compareTargetResourceStateResult | Should -HaveCount 1

                    $comparedReturnValue = $compareTargetResourceStateResult | Where-Object -FilterScript { $_.ParameterName -eq 'Permission' }
                    $comparedReturnValue | Should -Not -BeNullOrEmpty
                    $comparedReturnValue.InDesiredState | Should -BeFalse

                    $comparedReturnValue.Expected | Should -HaveCount 1
                    $comparedReturnValue.Expected[0] | Should -BeOfType 'CimInstance'

                    # Expected permissions
                    $grantPermission = $comparedReturnValue.Expected | Where-Object -FilterScript { $_.State -eq 'GrantWithGrant' }
                    $grantPermission | Should -Not -BeNullOrEmpty
                    $grantPermission.Ensure | Should -Be 'Present'
                    $grantPermission.Permission | Should -HaveCount 1
                    $grantPermission.Permission | Should -Contain @('CreateTable')

                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the permissions for the permission state ''Deny'' is not in desired state' {
                BeforeAll {
                    # Holds the desired permissions.
                    $desiredCimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                    # Using all lower-case on 'update' intentionally.
                    $desiredCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                        -Permission 'CreateTable' `
                        -PermissionState 'Deny' `
                        -Ensure 'Present'
                }

                It 'Should return the correct metadata for the ''Permission'' property' {
                    $script:mockCompareTargetResourceParameters = @{
                        InstanceName = 'sql2014'
                        DatabaseName = 'AdventureWorks'
                        SchemaName   = 'dbo'
                        ObjectName   = 'Table1'
                        ObjectType   = 'Table'
                        Name         = 'TestAppRole'
                        Permission   = $desiredCimInstancePermissionCollection
                        ServerName   = 'testclu01a'
                    }

                    $compareTargetResourceStateResult = Compare-TargetResourceState @mockCompareTargetResourceParameters
                    $compareTargetResourceStateResult | Should -HaveCount 1

                    $comparedReturnValue = $compareTargetResourceStateResult | Where-Object -FilterScript { $_.ParameterName -eq 'Permission' }
                    $comparedReturnValue | Should -Not -BeNullOrEmpty
                    $comparedReturnValue.InDesiredState | Should -BeFalse

                    $comparedReturnValue.Expected | Should -HaveCount 1
                    $comparedReturnValue.Expected[0] | Should -BeOfType 'CimInstance'

                    # Expected permissions
                    $grantPermission = $comparedReturnValue.Expected | Where-Object -FilterScript { $_.State -eq 'Deny' }
                    $grantPermission | Should -Not -BeNullOrEmpty
                    $grantPermission.Ensure | Should -Be 'Present'
                    $grantPermission.Permission | Should -HaveCount 1
                    $grantPermission.Permission | Should -Contain @('CreateTable')

                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                }
            }
        }

        Context 'When the specified permission state is missing in the current state' {
            Context 'When the permission state ''Grant'' is ''Absent'' but desired state is ''Present''' {
                BeforeAll {
                    # Empty collection to mock no existing permissions in the current state.
                    $currentCimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            InstanceName = 'sql2014'
                            DatabaseName = 'AdventureWorks'
                            SchemaName   = 'dbo'
                            ObjectName   = 'Table1'
                            ObjectType   = 'Table'
                            Name         = 'TestAppRole'
                            Permission   = $currentCimInstancePermissionCollection
                            ServerName   = 'testclu01a'
                        }
                    }

                    # Holds the desired permissions.
                    $desiredCimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                    $desiredCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                        -Permission 'Select' `
                        -PermissionState 'Grant' `
                        -Ensure 'Present'

                    # Using all lower-case on 'update' intentionally.
                    $desiredCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                        -Permission 'update' `
                        -PermissionState 'Grant' `
                        -Ensure 'Present'
                }

                It 'Should return the correct metadata for the ''Permission'' property' {
                    $script:mockCompareTargetResourceParameters = @{
                        InstanceName = 'sql2014'
                        DatabaseName = 'AdventureWorks'
                        SchemaName   = 'dbo'
                        ObjectName   = 'Table1'
                        ObjectType   = 'Table'
                        Name         = 'TestAppRole'
                        Permission   = $desiredCimInstancePermissionCollection
                        ServerName   = 'testclu01a'
                    }

                    $compareTargetResourceStateResult = Compare-TargetResourceState @mockCompareTargetResourceParameters
                    $compareTargetResourceStateResult | Should -HaveCount 1

                    $comparedReturnValue = $compareTargetResourceStateResult | Where-Object -FilterScript { $_.ParameterName -eq 'Permission' }
                    $comparedReturnValue | Should -Not -BeNullOrEmpty
                    $comparedReturnValue.InDesiredState | Should -BeFalse

                    # Actual permissions
                    $comparedReturnValue.Actual | Should -BeNullOrEmpty

                    # Expected permissions
                    $comparedReturnValue.Expected | Should -HaveCount 2
                    $comparedReturnValue.Expected[0] | Should -BeOfType 'CimInstance'
                    $comparedReturnValue.Expected[1] | Should -BeOfType 'CimInstance'

                    $grantPermission = $comparedReturnValue.Expected | Where-Object -FilterScript { $_.State -eq 'Grant' }
                    $grantPermission | Should -Not -BeNullOrEmpty
                    $grantPermission.Ensure[0] | Should -Be 'Present'
                    $grantPermission.Ensure[1] | Should -Be 'Present'
                    $grantPermission.Permission | Should -HaveCount 2
                    $grantPermission.Permission | Should -Contain @('Select')
                    $grantPermission.Permission | Should -Contain @('Update')

                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the permission state ''GrantWithGrant'' is ''Absent'' but desired state is ''Present''' {
                BeforeAll {
                    # Empty collection to mock no existing permissions in the current state.
                    $currentCimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            InstanceName = 'sql2014'
                            DatabaseName = 'AdventureWorks'
                            SchemaName   = 'dbo'
                            ObjectName   = 'Table1'
                            ObjectType   = 'Table'
                            Name         = 'TestAppRole'
                            Permission   = $currentCimInstancePermissionCollection
                            ServerName   = 'testclu01a'
                        }
                    }

                    # Holds the desired permissions.
                    $desiredCimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                    $desiredCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                        -Permission 'Select' `
                        -PermissionState 'GrantWithGrant' `
                        -Ensure 'Present'

                    # Using all lower-case on 'update' intentionally.
                    $desiredCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                        -Permission 'update' `
                        -PermissionState 'GrantWithGrant' `
                        -Ensure 'Present'
                }

                It 'Should return the correct metadata for the ''Permission'' property' {
                    $script:mockCompareTargetResourceParameters = @{
                        InstanceName = 'sql2014'
                        DatabaseName = 'AdventureWorks'
                        SchemaName   = 'dbo'
                        ObjectName   = 'Table1'
                        ObjectType   = 'Table'
                        Name         = 'TestAppRole'
                        Permission   = $desiredCimInstancePermissionCollection
                        ServerName   = 'testclu01a'
                    }

                    $compareTargetResourceStateResult = Compare-TargetResourceState @mockCompareTargetResourceParameters
                    $compareTargetResourceStateResult | Should -HaveCount 1

                    $comparedReturnValue = $compareTargetResourceStateResult | Where-Object -FilterScript { $_.ParameterName -eq 'Permission' }
                    $comparedReturnValue | Should -Not -BeNullOrEmpty
                    $comparedReturnValue.InDesiredState | Should -BeFalse

                    # Actual permissions
                    $comparedReturnValue.Actual | Should -BeNullOrEmpty

                    # Expected permissions
                    $comparedReturnValue.Expected | Should -HaveCount 2
                    $comparedReturnValue.Expected[0] | Should -BeOfType 'CimInstance'
                    $comparedReturnValue.Expected[1] | Should -BeOfType 'CimInstance'

                    $grantPermission = $comparedReturnValue.Expected | Where-Object -FilterScript { $_.State -eq 'GrantWithGrant' }
                    $grantPermission | Should -Not -BeNullOrEmpty
                    $grantPermission.Ensure[0] | Should -Be 'Present'
                    $grantPermission.Ensure[1] | Should -Be 'Present'
                    $grantPermission.Permission | Should -HaveCount 2
                    $grantPermission.Permission | Should -Contain @('Select')
                    $grantPermission.Permission | Should -Contain @('Update')

                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the permission state ''Deny'' is ''Absent'' but desired state is ''Present''' {
                BeforeAll {
                    # Empty collection to mock no existing permissions in the current state.
                    $currentCimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            InstanceName = 'sql2014'
                            DatabaseName = 'AdventureWorks'
                            SchemaName   = 'dbo'
                            ObjectName   = 'Table1'
                            ObjectType   = 'Table'
                            Name         = 'TestAppRole'
                            Permission   = $currentCimInstancePermissionCollection
                            ServerName   = 'testclu01a'
                        }
                    }

                    # Holds the desired permissions.
                    $desiredCimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                    $desiredCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                        -Permission 'Select' `
                        -PermissionState 'Deny' `
                        -Ensure 'Present'

                    # Using all lower-case on 'update' intentionally.
                    $desiredCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                        -Permission 'update' `
                        -PermissionState 'Deny' `
                        -Ensure 'Present'
                }

                It 'Should return the correct metadata for the ''Permission'' property' {
                    $script:mockCompareTargetResourceParameters = @{
                        InstanceName = 'sql2014'
                        DatabaseName = 'AdventureWorks'
                        SchemaName   = 'dbo'
                        ObjectName   = 'Table1'
                        ObjectType   = 'Table'
                        Name         = 'TestAppRole'
                        Permission   = $desiredCimInstancePermissionCollection
                        ServerName   = 'testclu01a'
                    }

                    $compareTargetResourceStateResult = Compare-TargetResourceState @mockCompareTargetResourceParameters
                    $compareTargetResourceStateResult | Should -HaveCount 1

                    $comparedReturnValue = $compareTargetResourceStateResult | Where-Object -FilterScript { $_.ParameterName -eq 'Permission' }
                    $comparedReturnValue | Should -Not -BeNullOrEmpty
                    $comparedReturnValue.InDesiredState | Should -BeFalse

                    # Actual permissions
                    $comparedReturnValue.Actual | Should -BeNullOrEmpty

                    # Expected permissions
                    $comparedReturnValue.Expected | Should -HaveCount 2
                    $comparedReturnValue.Expected[0] | Should -BeOfType 'CimInstance'
                    $comparedReturnValue.Expected[1] | Should -BeOfType 'CimInstance'

                    $grantPermission = $comparedReturnValue.Expected | Where-Object -FilterScript { $_.State -eq 'Deny' }
                    $grantPermission | Should -Not -BeNullOrEmpty
                    $grantPermission.Ensure[0] | Should -Be 'Present'
                    $grantPermission.Ensure[1] | Should -Be 'Present'
                    $grantPermission.Permission | Should -HaveCount 2
                    $grantPermission.Permission | Should -Contain @('Select')
                    $grantPermission.Permission | Should -Contain @('Update')

                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                }
            }
        }

        Context 'When there already are other existing permissions for specified permission state' {
            Context 'When the permission state ''Grant'' should include the permission ''Update''' {
                BeforeAll {
                    # Holds the current permissions.
                    $currentCimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                    # Using all lower-case on 'update' intentionally.
                    $currentCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                        -Permission 'Select' `
                        -PermissionState 'Grant' `
                        -Ensure 'Present'

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            InstanceName = 'sql2014'
                            DatabaseName = 'AdventureWorks'
                            SchemaName   = 'dbo'
                            ObjectName   = 'Table1'
                            ObjectType   = 'Table'
                            Name         = 'TestAppRole'
                            Permission   = $currentCimInstancePermissionCollection
                            ServerName   = 'testclu01a'
                        }
                    }

                    # Holds the desired permissions.
                    $desiredCimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                    # Using all lower-case on 'update' intentionally.
                    $desiredCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                        -Permission 'Update' `
                        -PermissionState 'Grant' `
                        -Ensure 'Present'
                }

                It 'Should return the correct metadata for the ''Permission'' property' {
                    $script:mockCompareTargetResourceParameters = @{
                        InstanceName = 'sql2014'
                        DatabaseName = 'AdventureWorks'
                        SchemaName   = 'dbo'
                        ObjectName   = 'Table1'
                        ObjectType   = 'Table'
                        Name         = 'TestAppRole'
                        Permission   = $desiredCimInstancePermissionCollection
                        ServerName   = 'testclu01a'
                    }

                    $compareTargetResourceStateResult = Compare-TargetResourceState @mockCompareTargetResourceParameters
                    $compareTargetResourceStateResult | Should -HaveCount 1

                    $comparedReturnValue = $compareTargetResourceStateResult | Where-Object -FilterScript { $_.ParameterName -eq 'Permission' }
                    $comparedReturnValue | Should -Not -BeNullOrEmpty
                    $comparedReturnValue.InDesiredState | Should -BeFalse

                    # Actual permissions
                    $comparedReturnValue.Actual | Should -HaveCount 1
                    $comparedReturnValue.Actual[0] | Should -BeOfType 'CimInstance'

                    $grantPermission = $comparedReturnValue.Actual | Where-Object -FilterScript { $_.State -eq 'Grant' }
                    $grantPermission | Should -Not -BeNullOrEmpty
                    $grantPermission.Ensure | Should -Be 'Present'
                    $grantPermission.Permission | Should -HaveCount 1
                    $grantPermission.Permission | Should -Contain @('Select')

                    # Expected permissions
                    $comparedReturnValue.Expected | Should -HaveCount 1
                    $comparedReturnValue.Expected[0] | Should -BeOfType 'CimInstance'

                    $grantPermission = $comparedReturnValue.Expected | Where-Object -FilterScript { $_.State -eq 'Grant' }
                    $grantPermission | Should -Not -BeNullOrEmpty
                    $grantPermission.Ensure | Should -Be 'Present'
                    $grantPermission.Permission | Should -HaveCount 1
                    $grantPermission.Permission | Should -Contain @('Update')

                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the permission state ''GrantWithGrant'' should include the permission ''Update''' {
                BeforeAll {
                    # Holds the current permissions.
                    $currentCimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                    # Using all lower-case on 'update' intentionally.
                    $currentCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                        -Permission 'Select' `
                        -PermissionState 'GrantWithGrant' `
                        -Ensure 'Present'

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            InstanceName = 'sql2014'
                            DatabaseName = 'AdventureWorks'
                            SchemaName   = 'dbo'
                            ObjectName   = 'Table1'
                            ObjectType   = 'Table'
                            Name         = 'TestAppRole'
                            Permission   = $currentCimInstancePermissionCollection
                            ServerName   = 'testclu01a'
                        }
                    }

                    # Holds the desired permissions.
                    $desiredCimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                    # Using all lower-case on 'update' intentionally.
                    $desiredCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                        -Permission 'Update' `
                        -PermissionState 'GrantWithGrant' `
                        -Ensure 'Present'
                }

                It 'Should return the correct metadata for the ''Permission'' property' {
                    $script:mockCompareTargetResourceParameters = @{
                        InstanceName = 'sql2014'
                        DatabaseName = 'AdventureWorks'
                        SchemaName   = 'dbo'
                        ObjectName   = 'Table1'
                        ObjectType   = 'Table'
                        Name         = 'TestAppRole'
                        Permission   = $desiredCimInstancePermissionCollection
                        ServerName   = 'testclu01a'
                    }

                    $compareTargetResourceStateResult = Compare-TargetResourceState @mockCompareTargetResourceParameters
                    $compareTargetResourceStateResult | Should -HaveCount 1

                    $comparedReturnValue = $compareTargetResourceStateResult | Where-Object -FilterScript { $_.ParameterName -eq 'Permission' }
                    $comparedReturnValue | Should -Not -BeNullOrEmpty
                    $comparedReturnValue.InDesiredState | Should -BeFalse

                    # Actual permissions
                    $comparedReturnValue.Actual | Should -HaveCount 1
                    $comparedReturnValue.Actual[0] | Should -BeOfType 'CimInstance'

                    $grantPermission = $comparedReturnValue.Actual | Where-Object -FilterScript { $_.State -eq 'GrantWithGrant' }
                    $grantPermission | Should -Not -BeNullOrEmpty
                    $grantPermission.Ensure | Should -Be 'Present'
                    $grantPermission.Permission | Should -HaveCount 1
                    $grantPermission.Permission | Should -Contain @('Select')

                    # Expected permissions
                    $comparedReturnValue.Expected | Should -HaveCount 1
                    $comparedReturnValue.Expected[0] | Should -BeOfType 'CimInstance'

                    $grantPermission = $comparedReturnValue.Expected | Where-Object -FilterScript { $_.State -eq 'GrantWithGrant' }
                    $grantPermission | Should -Not -BeNullOrEmpty
                    $grantPermission.Ensure | Should -Be 'Present'
                    $grantPermission.Permission | Should -HaveCount 1
                    $grantPermission.Permission | Should -Contain @('Update')

                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the permission state ''Deny'' should include the permission ''Update''' {
                BeforeAll {
                    # Holds the current permissions.
                    $currentCimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                    # Using all lower-case on 'update' intentionally.
                    $currentCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                        -Permission 'Select' `
                        -PermissionState 'Deny' `
                        -Ensure 'Present'

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            InstanceName = 'sql2014'
                            DatabaseName = 'AdventureWorks'
                            SchemaName   = 'dbo'
                            ObjectName   = 'Table1'
                            ObjectType   = 'Table'
                            Name         = 'TestAppRole'
                            Permission   = $currentCimInstancePermissionCollection
                            ServerName   = 'testclu01a'
                        }
                    }

                    # Holds the desired permissions.
                    $desiredCimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                    # Using all lower-case on 'update' intentionally.
                    $desiredCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                        -Permission 'Update' `
                        -PermissionState 'Deny' `
                        -Ensure 'Present'
                }

                It 'Should return the correct metadata for the ''Permission'' property' {
                    $script:mockCompareTargetResourceParameters = @{
                        InstanceName = 'sql2014'
                        DatabaseName = 'AdventureWorks'
                        SchemaName   = 'dbo'
                        ObjectName   = 'Table1'
                        ObjectType   = 'Table'
                        Name         = 'TestAppRole'
                        Permission   = $desiredCimInstancePermissionCollection
                        ServerName   = 'testclu01a'
                    }

                    $compareTargetResourceStateResult = Compare-TargetResourceState @mockCompareTargetResourceParameters
                    $compareTargetResourceStateResult | Should -HaveCount 1

                    $comparedReturnValue = $compareTargetResourceStateResult | Where-Object -FilterScript { $_.ParameterName -eq 'Permission' }
                    $comparedReturnValue | Should -Not -BeNullOrEmpty
                    $comparedReturnValue.InDesiredState | Should -BeFalse

                    # Actual permissions
                    $comparedReturnValue.Actual | Should -HaveCount 1
                    $comparedReturnValue.Actual[0] | Should -BeOfType 'CimInstance'

                    $grantPermission = $comparedReturnValue.Actual | Where-Object -FilterScript { $_.State -eq 'Deny' }
                    $grantPermission | Should -Not -BeNullOrEmpty
                    $grantPermission.Ensure | Should -Be 'Present'
                    $grantPermission.Permission | Should -HaveCount 1
                    $grantPermission.Permission | Should -Contain @('Select')

                    # Expected permissions
                    $comparedReturnValue.Expected | Should -HaveCount 1
                    $comparedReturnValue.Expected[0] | Should -BeOfType 'CimInstance'

                    $grantPermission = $comparedReturnValue.Expected | Where-Object -FilterScript { $_.State -eq 'Deny' }
                    $grantPermission | Should -Not -BeNullOrEmpty
                    $grantPermission.Ensure | Should -Be 'Present'
                    $grantPermission.Permission | Should -HaveCount 1
                    $grantPermission.Permission | Should -Contain @('Update')

                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                }
            }
        }

        Context 'When there exist other permission states than the one that is desired' {
            Context 'When the permission state ''Grant'' should exist' {
                BeforeAll {
                    # Holds the current permissions.
                    $currentCimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                    # Using all lower-case on 'update' intentionally.
                    $currentCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                        -Permission 'Update' `
                        -PermissionState 'Deny' `
                        -Ensure 'Present'

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            InstanceName = 'sql2014'
                            DatabaseName = 'AdventureWorks'
                            SchemaName   = 'dbo'
                            ObjectName   = 'Table1'
                            ObjectType   = 'Table'
                            Name         = 'TestAppRole'
                            Permission   = $currentCimInstancePermissionCollection
                            ServerName   = 'testclu01a'
                        }
                    }

                    # Holds the desired permissions.
                    $desiredCimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                    # Using all lower-case on 'update' intentionally.
                    $desiredCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                        -Permission 'Select' `
                        -PermissionState 'Grant' `
                        -Ensure 'Present'
                }

                It 'Should return the correct metadata for the ''Permission'' property' {
                    $script:mockCompareTargetResourceParameters = @{
                        InstanceName = 'sql2014'
                        DatabaseName = 'AdventureWorks'
                        SchemaName   = 'dbo'
                        ObjectName   = 'Table1'
                        ObjectType   = 'Table'
                        Name         = 'TestAppRole'
                        Permission   = $desiredCimInstancePermissionCollection
                        ServerName   = 'testclu01a'
                    }

                    $compareTargetResourceStateResult = Compare-TargetResourceState @mockCompareTargetResourceParameters
                    $compareTargetResourceStateResult | Should -HaveCount 1

                    $comparedReturnValue = $compareTargetResourceStateResult | Where-Object -FilterScript { $_.ParameterName -eq 'Permission' }
                    $comparedReturnValue | Should -Not -BeNullOrEmpty
                    $comparedReturnValue.InDesiredState | Should -BeFalse

                    # Actual permissions
                    $comparedReturnValue.Actual | Should -HaveCount 1
                    $comparedReturnValue.Actual[0] | Should -BeOfType 'CimInstance'

                    $grantPermission = $comparedReturnValue.Actual | Where-Object -FilterScript { $_.State -eq 'Deny' }
                    $grantPermission | Should -Not -BeNullOrEmpty
                    $grantPermission.Ensure | Should -Be 'Present'
                    $grantPermission.Permission | Should -HaveCount 1
                    $grantPermission.Permission | Should -Contain @('Update')

                    # Expected permissions
                    $comparedReturnValue.Expected | Should -HaveCount 1
                    $comparedReturnValue.Expected[0] | Should -BeOfType 'CimInstance'

                    $grantPermission = $comparedReturnValue.Expected | Where-Object -FilterScript { $_.State -eq 'Grant' }
                    $grantPermission | Should -Not -BeNullOrEmpty
                    $grantPermission.Ensure | Should -Be 'Present'
                    $grantPermission.Permission | Should -HaveCount 1
                    $grantPermission.Permission | Should -Contain @('Select')

                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the permission state ''GrantWithGrant'' should exist' {
                BeforeAll {
                    # Holds the current permissions.
                    $currentCimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                    # Using all lower-case on 'update' intentionally.
                    $currentCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                        -Permission 'Update' `
                        -PermissionState 'Deny' `
                        -Ensure 'Present'

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            InstanceName = 'sql2014'
                            DatabaseName = 'AdventureWorks'
                            SchemaName   = 'dbo'
                            ObjectName   = 'Table1'
                            ObjectType   = 'Table'
                            Name         = 'TestAppRole'
                            Permission   = $currentCimInstancePermissionCollection
                            ServerName   = 'testclu01a'
                        }
                    }

                    # Holds the desired permissions.
                    $desiredCimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                    # Using all lower-case on 'update' intentionally.
                    $desiredCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                        -Permission 'Select' `
                        -PermissionState 'GrantWithGrant' `
                        -Ensure 'Present'
                }

                It 'Should return the correct metadata for the ''Permission'' property' {
                    $script:mockCompareTargetResourceParameters = @{
                        InstanceName = 'sql2014'
                        DatabaseName = 'AdventureWorks'
                        SchemaName   = 'dbo'
                        ObjectName   = 'Table1'
                        ObjectType   = 'Table'
                        Name         = 'TestAppRole'
                        Permission   = $desiredCimInstancePermissionCollection
                        ServerName   = 'testclu01a'
                    }

                    $compareTargetResourceStateResult = Compare-TargetResourceState @mockCompareTargetResourceParameters
                    $compareTargetResourceStateResult | Should -HaveCount 1

                    $comparedReturnValue = $compareTargetResourceStateResult | Where-Object -FilterScript { $_.ParameterName -eq 'Permission' }
                    $comparedReturnValue | Should -Not -BeNullOrEmpty
                    $comparedReturnValue.InDesiredState | Should -BeFalse

                    # Actual permissions
                    $comparedReturnValue.Actual | Should -HaveCount 1
                    $comparedReturnValue.Actual[0] | Should -BeOfType 'CimInstance'

                    $grantPermission = $comparedReturnValue.Actual | Where-Object -FilterScript { $_.State -eq 'Deny' }
                    $grantPermission | Should -Not -BeNullOrEmpty
                    $grantPermission.Ensure | Should -Be 'Present'
                    $grantPermission.Permission | Should -HaveCount 1
                    $grantPermission.Permission | Should -Contain @('Update')

                    # Expected permissions
                    $comparedReturnValue.Expected | Should -HaveCount 1
                    $comparedReturnValue.Expected[0] | Should -BeOfType 'CimInstance'

                    $grantPermission = $comparedReturnValue.Expected | Where-Object -FilterScript { $_.State -eq 'GrantWithGrant' }
                    $grantPermission | Should -Not -BeNullOrEmpty
                    $grantPermission.Ensure | Should -Be 'Present'
                    $grantPermission.Permission | Should -HaveCount 1
                    $grantPermission.Permission | Should -Contain @('Select')

                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the permission state ''Deny'' should exist' {
                BeforeAll {
                    # Holds the current permissions.
                    $currentCimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                    # Using all lower-case on 'update' intentionally.
                    $currentCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                        -Permission 'Select' `
                        -PermissionState 'Grant' `
                        -Ensure 'Present'

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            InstanceName = 'sql2014'
                            DatabaseName = 'AdventureWorks'
                            SchemaName   = 'dbo'
                            ObjectName   = 'Table1'
                            ObjectType   = 'Table'
                            Name         = 'TestAppRole'
                            Permission   = $currentCimInstancePermissionCollection
                            ServerName   = 'testclu01a'
                        }
                    }

                    # Holds the desired permissions.
                    $desiredCimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                    # Using all lower-case on 'update' intentionally.
                    $desiredCimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                        -Permission 'Update' `
                        -PermissionState 'Deny' `
                        -Ensure 'Present'
                }

                It 'Should return the correct metadata for the ''Permission'' property' {
                    $script:mockCompareTargetResourceParameters = @{
                        InstanceName = 'sql2014'
                        DatabaseName = 'AdventureWorks'
                        SchemaName   = 'dbo'
                        ObjectName   = 'Table1'
                        ObjectType   = 'Table'
                        Name         = 'TestAppRole'
                        Permission   = $desiredCimInstancePermissionCollection
                        ServerName   = 'testclu01a'
                    }

                    $compareTargetResourceStateResult = Compare-TargetResourceState @mockCompareTargetResourceParameters
                    $compareTargetResourceStateResult | Should -HaveCount 1

                    $comparedReturnValue = $compareTargetResourceStateResult | Where-Object -FilterScript { $_.ParameterName -eq 'Permission' }
                    $comparedReturnValue | Should -Not -BeNullOrEmpty
                    $comparedReturnValue.InDesiredState | Should -BeFalse

                    # Actual permissions
                    $comparedReturnValue.Actual | Should -HaveCount 1
                    $comparedReturnValue.Actual[0] | Should -BeOfType 'CimInstance'

                    $grantPermission = $comparedReturnValue.Actual | Where-Object -FilterScript { $_.State -eq 'Grant' }
                    $grantPermission | Should -Not -BeNullOrEmpty
                    $grantPermission.Ensure | Should -Be 'Present'
                    $grantPermission.Permission | Should -HaveCount 1
                    $grantPermission.Permission | Should -Contain @('Select')

                    # Expected permissions
                    $comparedReturnValue.Expected | Should -HaveCount 1
                    $comparedReturnValue.Expected[0] | Should -BeOfType 'CimInstance'

                    $grantPermission = $comparedReturnValue.Expected | Where-Object -FilterScript { $_.State -eq 'Deny' }
                    $grantPermission | Should -Not -BeNullOrEmpty
                    $grantPermission.Ensure | Should -Be 'Present'
                    $grantPermission.Permission | Should -HaveCount 1
                    $grantPermission.Permission | Should -Contain @('Update')

                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                }
            }
        }
    }
}

Describe 'SqlDatabaseObjectPermission\Set-TargetResource' -Tag 'Set' {
    Context 'When the system is in the desired state' {
        BeforeAll {
            Mock -CommandName Get-DatabaseObject
            Mock -CommandName Compare-TargetResourceState -MockWith {
                return @(
                    @{
                        ParameterName  = 'Permission'
                        InDesiredState = $true
                        Actual         = @(
                            (New-Object -TypeName PSCustomObject |
                                Add-Member -MemberType NoteProperty -Name 'State' -Value 'Grant' -PassThru |
                                Add-Member -MemberType NoteProperty -Name 'Ensure' -Value 'Present' -PassThru -Force)
                        )
                    }
                )
            }

            # Create an empty collection of CimInstance that we can return.
            $cimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

            <#
                Intentionally not using helper ConvertTo-CimDatabaseObjectPermission
                to increase code coverage.
            #>
            $cimInstancePermissionCollection += New-CimInstance `
                -ClassName 'DSC_DatabaseObjectPermission' `
                -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                -Property @{
                    State      = 'Grant'
                    Permission = 'Select'
                    Ensure     = '' # Must be empty string to hit a line in the code.
                } `
                -ClientOnly

            $cimInstancePermissionCollection += New-CimInstance `
                -ClassName 'DSC_DatabaseObjectPermission' `
                -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                -Property @{
                    State      = 'Grant'
                    Permission = 'Update'
                    Ensure     = '' # Must be empty string to hit a line in the code.
                } `
                -ClientOnly

            $script:mockSetTargetResourceParameters = @{
                InstanceName = 'DSCTEST'
                DatabaseName = 'AdventureWorks'
                SchemaName   = 'dbo'
                ObjectName   = 'Table1'
                ObjectType   = 'Table'
                Name         = 'TestAppRole'
                Permission   = $cimInstancePermissionCollection
            }
        }

        It 'Should not try to set any values and should not throw an exception' {
            { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

            Should -Invoke -CommandName Get-DatabaseObject -Exactly -Times 0 -Scope It
        }
    }

    Context 'When the system is not in the desired state' {
        Context 'When the database object is not found' {
            BeforeAll {
                Mock -CommandName Compare-TargetResourceState -MockWith {
                    return @(
                        @{
                            ParameterName  = 'Permission'
                            InDesiredState = $false
                        }
                    )
                }

                Mock -CommandName Get-DatabaseObject

                # Create an empty collection of CimInstance that we can return.
                $cimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                <#
                    Intentionally not using helper ConvertTo-CimDatabaseObjectPermission
                    to increase code coverage.
                #>
                $cimInstancePermissionCollection += New-CimInstance `
                    -ClassName 'DSC_DatabaseObjectPermission' `
                    -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                    -Property @{
                        State      = 'Grant'
                        Permission = 'Select'
                        Ensure     = '' # Must be empty string to hit a line in the code.
                    } `
                    -ClientOnly

                $cimInstancePermissionCollection += New-CimInstance `
                    -ClassName 'DSC_DatabaseObjectPermission' `
                    -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                    -Property @{
                        State      = 'Grant'
                        Permission = 'Update'
                        Ensure     = '' # Must be empty string to hit a line in the code.
                    } `
                    -ClientOnly

                $script:mockSetTargetResourceParameters = @{
                    InstanceName = 'DSCTEST'
                    DatabaseName = 'AdventureWorks'
                    SchemaName   = 'dbo'
                    ObjectName   = 'Table1'
                    ObjectType   = 'Table'
                    Name         = 'TestAppRole'
                    Permission   = $cimInstancePermissionCollection
                }
            }

            It 'Should throw the correct exception' {
                $mockErrorMessage = $script:localizedData.FailedToGetDatabaseObject -f @(
                    ('{0}.{1}' -f $mockSetTargetResourceParameters.SchemaName, $mockSetTargetResourceParameters.ObjectName),
                    $mockSetTargetResourceParameters.ObjectType,
                    $mockSetTargetResourceParameters.DatabaseName
                )

                { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw $mockErrorMessage
            }
        }

        Context 'When setting permission for a permission state' {
            BeforeAll {
                Mock -CommandName New-Object -ParameterFilter {
                    $TypeName -eq 'Microsoft.SqlServer.Management.Smo.ObjectPermissionSet'
                } -MockWith {
                    return New-Object -TypeName PSCustomObject |
                    Add-Member -MemberType NoteProperty -Name 'Alter' -Value $false -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'Connect' -Value $false -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'Control' -Value $false -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'CreateSequence' -Value $false -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'Delete' -Value $false -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'Execute' -Value $false -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'Impersonate' -Value $false -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'Insert' -Value $false -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'Receive' -Value $false -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'References' -Value $false -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'Select' -Value $false -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'Send' -Value $false -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'TakeOwnership' -Value $false -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'Update' -Value $false -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'ViewChangeTracking' -Value $false -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'ViewDefinition' -Value $false -PassThru -Force
                }
            }

            BeforeEach {
                $script:mockMethodGrantRanTimes = 0
                $script:mockMethodDenyRanTimes = 0
                $script:mockMethodRevokeRanTimes = 0
            }

            Context 'When setting permission for the permission state ''Grant''' {
                BeforeAll {
                    Mock -CommandName Compare-TargetResourceState -MockWith {
                        return @(
                            @{
                                ParameterName  = 'Permission'
                                InDesiredState = $false
                                Actual         = @(
                                    (New-Object -TypeName PSCustomObject |
                                        Add-Member -MemberType NoteProperty -Name 'State' -Value 'Grant' -PassThru |
                                        Add-Member -MemberType NoteProperty -Name 'Ensure' -Value 'Absent' -PassThru -Force)
                                )
                            }
                        )
                    }

                    Mock -CommandName Get-DatabaseObject -MockWith {
                        # Should mock a database object, e.g. Schema, Table, View.
                        return New-Object -TypeName PSCustomObject |
                            Add-Member -MemberType ScriptMethod -Name 'Grant' -Value {
                                $script:mockMethodGrantRanTimes += 1
                            } -PassThru |
                            Add-Member -MemberType ScriptMethod -Name 'Deny' -Value {
                                $script:mockMethodDenyRanTimes += 1
                            } -PassThru |
                            Add-Member -MemberType ScriptMethod -Name 'EnumObjectPermissions' -Value {
                                return $null
                            } -PassThru -Force
                    }

                    # Create an empty collection of CimInstance that we can return.
                    $cimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                    <#
                        Intentionally not using helper ConvertTo-CimDatabaseObjectPermission
                        to increase code coverage.
                    #>
                    $cimInstancePermissionCollection += New-CimInstance `
                        -ClassName 'DSC_DatabaseObjectPermission' `
                        -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                        -Property @{
                            State      = 'Grant'
                            Permission = 'Delete'
                            Ensure     = 'Present'
                        } `
                        -ClientOnly

                    $script:mockSetTargetResourceParameters = @{
                        InstanceName = 'DSCTEST'
                        DatabaseName = 'AdventureWorks'
                        SchemaName   = 'dbo'
                        ObjectName   = 'Table1'
                        ObjectType   = 'Table'
                        Name         = 'TestAppRole'
                        Permission   = $cimInstancePermissionCollection
                        Verbose      = $true
                    }
                }

                It 'Should set the permissions without throwing an exception' {
                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                    Should -Invoke -CommandName Get-DatabaseObject -Exactly -Times 1 -Scope It

                    $script:mockMethodGrantRanTimes | Should -Be 1
                    $script:mockMethodDenyRanTimes  | Should -Be 0
                }

                # Regression test for issue #1602.
                Context 'When current permission state already is GrantWithGrant' {
                    BeforeAll {
                        Mock -CommandName Get-DatabaseObject -MockWith {
                            # Should mock a database object, e.g. Schema, Table, View.
                            return New-Object -TypeName PSCustomObject |
                                Add-Member -MemberType ScriptMethod -Name 'Grant' -Value {
                                    $script:mockMethodGrantRanTimes += 1
                                } -PassThru |
                                Add-Member -MemberType ScriptMethod -Name 'Deny' -Value {
                                    $script:mockMethodDenyRanTimes += 1
                                } -PassThru |
                                Add-Member -MemberType ScriptMethod -Name 'Revoke' -Value {
                                    $script:mockMethodRevokeRanTimes += 1
                                } -PassThru |
                                Add-Member -MemberType ScriptMethod -Name 'EnumObjectPermissions' -Value {
                                    <#
                                        Normally it returns an array of
                                        Microsoft.SqlServer.Management.Smo.ObjectPermissionInfo[]
                                        with the permissions that had the state 'GrantWithGrant'.
                                    #>
                                    return @(
                                        New-Object -TypeName PSCustomObject |
                                            Add-Member -MemberType NoteProperty -Name 'PermissionState' -Value 'GrantWithGrant' -PassThru -Force
                                    )
                                } -PassThru -Force
                        }
                    }

                    Context 'When Force is not set or set to $false' {
                        It 'Should set the permissions without throwing an exception' {
                            $mockErrorMessage = $script:localizedData.GrantCantBeSetBecauseRevokeIsNotOptedIn -f @(
                                ($cimInstancePermissionCollection[0].Permission -join ','),
                                $mockSetTargetResourceParameters.Name,
                                ('{0}.{1}' -f $mockSetTargetResourceParameters.SchemaName, $mockSetTargetResourceParameters.ObjectName),
                                $mockSetTargetResourceParameters.ObjectType,
                                $mockSetTargetResourceParameters.DatabaseName
                            )

                            { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw
                        }
                    }

                    Context 'When Force is set to $true' {
                        BeforeAll {
                            $mockSetTargetResourceParameters['Force'] = $true
                        }

                        It 'Should set the permissions without throwing an exception' {
                            { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                            Should -Invoke -CommandName Get-DatabaseObject -Exactly -Times 1 -Scope It

                            $script:mockMethodRevokeRanTimes | Should -Be 1
                            $script:mockMethodGrantRanTimes | Should -Be 1
                            $script:mockMethodDenyRanTimes  | Should -Be 0
                        }
                    }
                }
            }

            Context 'When setting permission for the permission state ''GrantWithGrant''' {
                BeforeAll {
                    Mock -CommandName Compare-TargetResourceState -MockWith {
                        return @(
                            @{
                                ParameterName  = 'Permission'
                                InDesiredState = $false
                                Actual         = @(
                                    (New-Object -TypeName PSCustomObject |
                                        Add-Member -MemberType NoteProperty -Name 'State' -Value 'GrantWithGrant' -PassThru |
                                        Add-Member -MemberType NoteProperty -Name 'Ensure' -Value 'Absent' -PassThru -Force)
                                )
                            }
                        )
                    }

                    Mock -CommandName Get-DatabaseObject -MockWith {
                        # Should mock a database object, e.g. Schema, Table, View.
                        return New-Object -TypeName PSCustomObject |
                            Add-Member -MemberType ScriptMethod -Name 'Grant' -Value {
                                $script:mockMethodGrantRanTimes += 1
                            } -PassThru |
                            Add-Member -MemberType ScriptMethod -Name 'Deny' -Value {
                                $script:mockMethodDenyRanTimes += 1
                            } -PassThru -Force
                    }

                    # Create an empty collection of CimInstance that we can return.
                    $cimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                    <#
                        Intentionally not using helper ConvertTo-CimDatabaseObjectPermission
                        to increase code coverage.
                    #>
                    $cimInstancePermissionCollection += New-CimInstance `
                        -ClassName 'DSC_DatabaseObjectPermission' `
                        -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                        -Property @{
                            State      = 'GrantWithGrant'
                            Permission = 'Delete'
                            Ensure     = 'Present'
                        } `
                        -ClientOnly

                    $script:mockSetTargetResourceParameters = @{
                        InstanceName = 'DSCTEST'
                        DatabaseName = 'AdventureWorks'
                        SchemaName   = 'dbo'
                        ObjectName   = 'Table1'
                        ObjectType   = 'Table'
                        Name         = 'TestAppRole'
                        Permission   = $cimInstancePermissionCollection
                    }
                }

                It 'Should set the permissions without throwing an exception' {
                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                    Should -Invoke -CommandName Get-DatabaseObject -Exactly -Times 1 -Scope It

                    $script:mockMethodGrantRanTimes | Should -Be 1
                    $script:mockMethodDenyRanTimes  | Should -Be 0
                }
            }

            Context 'When setting permission for the permission state ''Deny''' {
                BeforeAll {
                    Mock -CommandName Compare-TargetResourceState -MockWith {
                        return @(
                            @{
                                ParameterName  = 'Permission'
                                InDesiredState = $false
                                Actual         = @(
                                    (New-Object -TypeName PSCustomObject |
                                        Add-Member -MemberType NoteProperty -Name 'State' -Value 'Deny' -PassThru |
                                        Add-Member -MemberType NoteProperty -Name 'Ensure' -Value 'Absent' -PassThru -Force)
                                )
                            }
                        )
                    }

                    Mock -CommandName Get-DatabaseObject -MockWith {
                        # Should mock a database object, e.g. Schema, Table, View.
                        return New-Object -TypeName PSCustomObject |
                            Add-Member -MemberType ScriptMethod -Name 'Grant' -Value {
                                $script:mockMethodGrantRanTimes += 1
                            } -PassThru |
                            Add-Member -MemberType ScriptMethod -Name 'Deny' -Value {
                                $script:mockMethodDenyRanTimes += 1
                            } -PassThru -Force
                    }

                    # Create an empty collection of CimInstance that we can return.
                    $cimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                    <#
                        Intentionally not using helper ConvertTo-CimDatabaseObjectPermission
                        to increase code coverage.
                    #>
                    $cimInstancePermissionCollection += New-CimInstance `
                        -ClassName 'DSC_DatabaseObjectPermission' `
                        -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                        -Property @{
                            State      = 'Deny'
                            Permission = 'Delete'
                            Ensure     = 'Present'
                        } `
                        -ClientOnly

                    $script:mockSetTargetResourceParameters = @{
                        InstanceName = 'DSCTEST'
                        DatabaseName = 'AdventureWorks'
                        SchemaName   = 'dbo'
                        ObjectName   = 'Table1'
                        ObjectType   = 'Table'
                        Name         = 'TestAppRole'
                        Permission   = $cimInstancePermissionCollection
                    }
                }

                It 'Should set the permissions without throwing an exception' {
                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                    Should -Invoke -CommandName Get-DatabaseObject -Exactly -Times 1 -Scope It

                    $script:mockMethodGrantRanTimes | Should -Be 0
                    $script:mockMethodDenyRanTimes  | Should -Be 1
                }
            }

            Context 'When one of the permission states is already in desired state' {
                BeforeAll {
                    Mock -CommandName Compare-TargetResourceState -MockWith {
                        return @(
                            @{
                                ParameterName  = 'Permission'
                                InDesiredState = $false
                                Actual         = @(
                                    (New-Object -TypeName PSCustomObject |
                                        Add-Member -MemberType NoteProperty -Name 'State' -Value 'Deny' -PassThru |
                                        Add-Member -MemberType NoteProperty -Name 'Ensure' -Value 'Absent' -PassThru -Force)
                                    (New-Object -TypeName PSCustomObject |
                                        Add-Member -MemberType NoteProperty -Name 'State' -Value 'Grant' -PassThru |
                                        Add-Member -MemberType NoteProperty -Name 'Ensure' -Value 'Present' -PassThru -Force)
                                )
                            }
                        )
                    }

                    Mock -CommandName Get-DatabaseObject -MockWith {
                        # Should mock a database object, e.g. Schema, Table, View.
                        return New-Object -TypeName PSCustomObject |
                            Add-Member -MemberType ScriptMethod -Name 'Grant' -Value {
                                $script:mockMethodGrantRanTimes += 1
                            } -PassThru |
                            Add-Member -MemberType ScriptMethod -Name 'Deny' -Value {
                                $script:mockMethodDenyRanTimes += 1
                            } -PassThru -Force
                    }

                    # Create an empty collection of CimInstance that we can return.
                    $cimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                    <#
                        Intentionally not using helper ConvertTo-CimDatabaseObjectPermission
                        to increase code coverage.
                    #>
                    $cimInstancePermissionCollection += New-CimInstance `
                        -ClassName 'DSC_DatabaseObjectPermission' `
                        -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                        -Property @{
                            State      = 'Grant'
                            Permission = 'Delete'
                            Ensure     = 'Present'
                        } `
                        -ClientOnly

                    $cimInstancePermissionCollection += New-CimInstance `
                        -ClassName 'DSC_DatabaseObjectPermission' `
                        -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                        -Property @{
                            State      = 'Deny'
                            Permission = 'Delete'
                            Ensure     = 'Present'
                        } `
                        -ClientOnly

                    $script:mockSetTargetResourceParameters = @{
                        InstanceName = 'DSCTEST'
                        DatabaseName = 'AdventureWorks'
                        SchemaName   = 'dbo'
                        ObjectName   = 'Table1'
                        ObjectType   = 'Table'
                        Name         = 'TestAppRole'
                        Permission   = $cimInstancePermissionCollection
                    }
                }

                It 'Should set the permissions without throwing an exception' {
                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                    Should -Invoke -CommandName Get-DatabaseObject -Exactly -Times 1 -Scope It

                    $script:mockMethodGrantRanTimes | Should -Be 0
                    $script:mockMethodDenyRanTimes  | Should -Be 1
                }
            }
        }

        Context 'When revoking permission for a permission state' {
            BeforeAll {
                Mock -CommandName New-Object -ParameterFilter {
                    $TypeName -eq 'Microsoft.SqlServer.Management.Smo.ObjectPermissionSet'
                } -MockWith {
                    return New-Object -TypeName PSCustomObject |
                    Add-Member -MemberType NoteProperty -Name 'Alter' -Value $false -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'Connect' -Value $false -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'Control' -Value $false -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'CreateSequence' -Value $false -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'Delete' -Value $false -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'Execute' -Value $false -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'Impersonate' -Value $false -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'Insert' -Value $false -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'Receive' -Value $false -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'References' -Value $false -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'Select' -Value $false -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'Send' -Value $false -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'TakeOwnership' -Value $false -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'Update' -Value $false -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'ViewChangeTracking' -Value $false -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'ViewDefinition' -Value $false -PassThru -Force
                }

                Mock -CommandName Get-DatabaseObject -MockWith {
                    # Should mock a database object, e.g. Schema, Table, View.
                    return New-Object -TypeName PSCustomObject |
                        Add-Member -MemberType ScriptMethod -Name 'Revoke' -Value {
                            $script:mockMethodRevokeRanTimes += 1
                        } -PassThru -Force
                }
            }

            BeforeEach {
                $script:mockMethodRevokeRanTimes = 0
            }

            Context 'When revoking permission for the permission state ''Grant''' {
                BeforeAll {
                    Mock -CommandName Compare-TargetResourceState -MockWith {
                        return @(
                            @{
                                ParameterName  = 'Permission'
                                InDesiredState = $false
                                Actual         = @(
                                    (New-Object -TypeName PSCustomObject |
                                        Add-Member -MemberType NoteProperty -Name 'State' -Value 'Grant' -PassThru |
                                        Add-Member -MemberType NoteProperty -Name 'Ensure' -Value 'Present' -PassThru -Force)
                                )
                            }
                        )
                    }

                    # Create an empty collection of CimInstance that we can return.
                    $cimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                    <#
                        Intentionally not using helper ConvertTo-CimDatabaseObjectPermission
                        to increase code coverage.
                    #>
                    $cimInstancePermissionCollection += New-CimInstance `
                        -ClassName 'DSC_DatabaseObjectPermission' `
                        -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                        -Property @{
                            State      = 'Grant'
                            Permission = 'Delete'
                            Ensure     = 'Absent'
                        } `
                        -ClientOnly

                    $script:mockSetTargetResourceParameters = @{
                        InstanceName = 'DSCTEST'
                        DatabaseName = 'AdventureWorks'
                        SchemaName   = 'dbo'
                        ObjectName   = 'Table1'
                        ObjectType   = 'Table'
                        Name         = 'TestAppRole'
                        Permission   = $cimInstancePermissionCollection
                        Verbose      = $true
                    }
                }

                It 'Should revoke the permissions without throwing an exception' {
                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                    Should -Invoke -CommandName Get-DatabaseObject -Exactly -Times 1 -Scope It

                    $script:mockMethodRevokeRanTimes | Should -Be 1
                }
            }

            Context 'When revoking permission for the permission state ''GrantWithGrant''' {
                BeforeAll {
                    Mock -CommandName Compare-TargetResourceState -MockWith {
                        return @(
                            @{
                                ParameterName  = 'Permission'
                                InDesiredState = $false
                                Actual         = @(
                                    (New-Object -TypeName PSCustomObject |
                                        Add-Member -MemberType NoteProperty -Name 'State' -Value 'GrantWithGrant' -PassThru |
                                        Add-Member -MemberType NoteProperty -Name 'Ensure' -Value 'Present' -PassThru -Force)
                                )
                            }
                        )
                    }

                    # Create an empty collection of CimInstance that we can return.
                    $cimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                    <#
                        Intentionally not using helper ConvertTo-CimDatabaseObjectPermission
                        to increase code coverage.
                    #>
                    $cimInstancePermissionCollection += New-CimInstance `
                        -ClassName 'DSC_DatabaseObjectPermission' `
                        -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                        -Property @{
                            State      = 'GrantWithGrant'
                            Permission = 'Delete'
                            Ensure     = 'Absent'
                        } `
                        -ClientOnly

                    $script:mockSetTargetResourceParameters = @{
                        InstanceName = 'DSCTEST'
                        DatabaseName = 'AdventureWorks'
                        SchemaName   = 'dbo'
                        ObjectName   = 'Table1'
                        ObjectType   = 'Table'
                        Name         = 'TestAppRole'
                        Permission   = $cimInstancePermissionCollection
                    }
                }

                It 'Should revoke the permissions without throwing an exception' {
                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                    Should -Invoke -CommandName Get-DatabaseObject -Exactly -Times 1 -Scope It

                    $script:mockMethodRevokeRanTimes | Should -Be 1
                }
            }

            Context 'When revoking permission for the permission state ''Deny''' {
                BeforeAll {
                    Mock -CommandName Compare-TargetResourceState -MockWith {
                        return @(
                            @{
                                ParameterName  = 'Permission'
                                InDesiredState = $false
                                Actual         = @(
                                    (New-Object -TypeName PSCustomObject |
                                        Add-Member -MemberType NoteProperty -Name 'State' -Value 'Deny' -PassThru |
                                        Add-Member -MemberType NoteProperty -Name 'Ensure' -Value 'Present' -PassThru -Force)
                                )
                            }
                        )
                    }

                    # Create an empty collection of CimInstance that we can return.
                    $cimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                    <#
                        Intentionally not using helper ConvertTo-CimDatabaseObjectPermission
                        to increase code coverage.
                    #>
                    $cimInstancePermissionCollection += New-CimInstance `
                        -ClassName 'DSC_DatabaseObjectPermission' `
                        -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                        -Property @{
                            State      = 'Deny'
                            Permission = 'Delete'
                            Ensure     = 'Absent'
                        } `
                        -ClientOnly

                    $script:mockSetTargetResourceParameters = @{
                        InstanceName = 'DSCTEST'
                        DatabaseName = 'AdventureWorks'
                        SchemaName   = 'dbo'
                        ObjectName   = 'Table1'
                        ObjectType   = 'Table'
                        Name         = 'TestAppRole'
                        Permission   = $cimInstancePermissionCollection
                    }
                }

                It 'Should revoke the permissions without throwing an exception' {
                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                    Should -Invoke -CommandName Get-DatabaseObject -Exactly -Times 1 -Scope It

                    $script:mockMethodRevokeRanTimes | Should -Be 1
                }
            }
        }

        Context 'When failing to change permissions' {
            BeforeAll {
                Mock -CommandName Compare-TargetResourceState -MockWith {
                    return @(
                        @{
                            ParameterName  = 'Permission'
                            InDesiredState = $false
                        }
                    )
                }

                Mock -CommandName New-Object -ParameterFilter {
                    $TypeName -eq 'Microsoft.SqlServer.Management.Smo.ObjectPermissionSet'
                } -MockWith {
                    return New-Object -TypeName PSCustomObject |
                    Add-Member -MemberType NoteProperty -Name 'Alter' -Value $false -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'Connect' -Value $false -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'Control' -Value $false -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'CreateSequence' -Value $false -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'Delete' -Value $false -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'Execute' -Value $false -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'Impersonate' -Value $false -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'Insert' -Value $false -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'Receive' -Value $false -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'References' -Value $false -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'Select' -Value $false -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'Send' -Value $false -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'TakeOwnership' -Value $false -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'Update' -Value $false -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'ViewChangeTracking' -Value $false -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'ViewDefinition' -Value $false -PassThru -Force
                }

                Mock -CommandName Get-DatabaseObject -MockWith {
                    # Should mock a database object, e.g. Schema, Table, View.
                    return New-Object -TypeName PSCustomObject |
                        Add-Member -MemberType ScriptMethod -Name 'Revoke' -Value {
                            throw 'Mocked error'
                        } -PassThru -Force
                }

                # Create an empty collection of CimInstance that we can return.
                $cimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

                <#
                    Intentionally not using helper ConvertTo-CimDatabaseObjectPermission
                    to increase code coverage.
                #>
                $cimInstancePermissionCollection += New-CimInstance `
                    -ClassName 'DSC_DatabaseObjectPermission' `
                    -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' `
                    -Property @{
                        State      = 'Grant'
                        Permission = 'Delete'
                        Ensure     = 'Absent'
                    } `
                    -ClientOnly

                $script:mockSetTargetResourceParameters = @{
                    InstanceName = 'DSCTEST'
                    DatabaseName = 'AdventureWorks'
                    SchemaName   = 'dbo'
                    ObjectName   = 'Table1'
                    ObjectType   = 'Table'
                    Name         = 'TestAppRole'
                    Permission   = $cimInstancePermissionCollection
                }
            }

            It 'Should throw the correct exception' {
                $mockErrorMessage = $script:localizedData.FailedToSetDatabaseObjectPermission -f @(
                    $mockSetTargetResourceParameters.Name,
                    ('{0}.{1}' -f $mockSetTargetResourceParameters.SchemaName, $mockSetTargetResourceParameters.ObjectName),
                    $mockSetTargetResourceParameters.DatabaseName
                )

                { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw $mockErrorMessage
            }
        }
    }
}

Describe 'SqlDatabaseObjectPermission\Get-DatabaseObject' -Tag 'Helper' {
    BeforeAll {
        Mock -Command Connect-SQL -MockWith {
            return New-Object -TypeName PSObject |
                Add-Member -MemberType NoteProperty -Name 'Databases' -Value @{
                    'AdventureWorks' = New-Object -TypeName PSObject |
                        Add-Member -MemberType NoteProperty -Name 'Schemas' -Value (
                            New-Object -TypeName PSObject |
                                Add-Member -MemberType ScriptMethod -Name 'Item' -Value {
                                    return 'Schema'
                                } -PassThru -Force
                        ) -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'Tables' -Value (
                            New-Object -TypeName PSObject |
                                Add-Member -MemberType ScriptMethod -Name 'Item' -Value {
                                    return 'Table'
                                } -PassThru -Force
                        ) -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'StoredProcedures' -Value (
                            New-Object -TypeName PSObject |
                                Add-Member -MemberType ScriptMethod -Name 'Item' -Value {
                                    return 'StoredProcedure'
                                } -PassThru -Force
                        ) -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'Views' -Value (
                            New-Object -TypeName PSObject |
                                Add-Member -MemberType ScriptMethod -Name 'Item' -Value {
                                    return 'View'
                                } -PassThru -Force
                        ) -PassThru -Force
                } -PassThru -Force
        }
    }

    It 'Should call the correct mocked method to get object type ''<ObjectType>''' -ForEach @(
        @{
            ObjectType = 'Schema'
        }
        @{
            ObjectType = 'Table'
        }
        @{
            ObjectType = 'StoredProcedure'
        }
        @{
            ObjectType = 'View'
        }
     ) {
        InModuleScope -Parameters $_ -ScriptBlock {
            Set-StrictMode -Version 1.0

            $getDatabaseObjectParameters = @{
                ServerName = $env:COMPUTERNAME
                InstanceName = 'DSCTEST'
                DatabaseName = 'AdventureWorks'
                SchemaName   = 'dbo'
                ObjectName   = 'Table1'
                ObjectType   = $ObjectType
            }

            # The methods that was mocked returns the expect object type.
            Get-DatabaseObject @getDatabaseObjectParameters | Should -Be $ObjectType
        }
    }
}
