[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Suppressing this rule because Script Analyzer does not understand Pester syntax.')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies have been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies have not been resolved, this will throw an error.
            Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
        }
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks noop" first.'
    }
}

BeforeAll {
    $script:moduleName = 'SqlServerDsc'

    $env:SqlServerDscCI = $true

    # Do not use -Force. Doing so, or unloading the module in AfterAll, causes
    # PowerShell class types to get new identities, breaking type comparisons.
    Import-Module -Name $script:moduleName -ErrorAction 'Stop'

    # Loading mocked classes
    Add-Type -Path (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '../Stubs') -ChildPath 'SMO.cs')

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:moduleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Remove-Item -Path 'env:SqlServerDscCI'
}

Describe 'Get-SqlDscDatabasePermission' -Tag 'Public' {
    Context 'When no databases exist' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' |
                Add-Member -MemberType 'ScriptProperty' -Name 'Databases' -Value {
                    return $null
                } -PassThru -Force
        }

        Context 'When specifying to throw on error' {
            BeforeAll {
                $mockErrorMessage = InModuleScope -ScriptBlock {
                    $script:localizedData.DatabasePermission_MissingDatabase
                }
            }

            It 'Should throw the correct error' {
                { Get-SqlDscDatabasePermission -ServerObject $mockServerObject -DatabaseName 'MissingDatabase' -Name 'KnownUser' -ErrorAction 'Stop' } |
                    Should -Throw -ExpectedMessage ($mockErrorMessage -f 'MissingDatabase')
            }
        }

        Context 'When ignoring the error' {
            It 'Should not throw an exception and return $null' {
                Get-SqlDscDatabasePermission -ServerObject $mockServerObject -DatabaseName 'MissingDatabase' -Name 'KnownUser' -ErrorAction 'SilentlyContinue' |
                    Should -BeNullOrEmpty
            }
        }
    }

    Context 'When the specified database does not exist among existing database' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' |
                Add-Member -MemberType 'ScriptProperty' -Name 'Databases' -Value {
                    return @{
                        'AdventureWorks' = New-Object -TypeName Object |
                            Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'AdventureWorks' -PassThru -Force
                        }
                    } -PassThru -Force
        }

        Context 'When specifying to throw on error' {
            BeforeAll {
                $mockErrorMessage = InModuleScope -ScriptBlock {
                    $script:localizedData.DatabasePermission_MissingDatabase
                }
            }

            It 'Should throw the correct error' {
                { Get-SqlDscDatabasePermission -ServerObject $mockServerObject -DatabaseName 'MissingDatabase' -Name 'KnownUser' -ErrorAction 'Stop' } |
                    Should -Throw -ExpectedMessage ($mockErrorMessage -f 'MissingDatabase')
            }
        }

        Context 'When ignoring the error' {
            It 'Should not throw an exception and return $null' {
                Get-SqlDscDatabasePermission -ServerObject $mockServerObject -DatabaseName 'MissingDatabase' -Name 'KnownUser' -ErrorAction 'SilentlyContinue' |
                    Should -BeNullOrEmpty
            }
        }
    }

    Context 'When the database principal does not exist' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' |
                Add-Member -MemberType 'ScriptProperty' -Name 'Databases' -Value {
                    return @{
                        'AdventureWorks' = New-Object -TypeName Object |
                            Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'AdventureWorks' -PassThru -Force
                        }
                    } -PassThru -Force

            Mock -CommandName Test-SqlDscIsDatabasePrincipal -MockWith {
                return $false
            }
        }

        Context 'When specifying to throw on error' {
            BeforeAll {
                $mockErrorMessage = InModuleScope -ScriptBlock {
                    $script:localizedData.DatabasePermission_MissingPrincipal
                }
            }

            It 'Should throw the correct error' {
                { Get-SqlDscDatabasePermission -ServerObject $mockServerObject -DatabaseName 'AdventureWorks' -Name 'UnknownUser' -ErrorAction 'Stop' } |
                    Should -Throw -ExpectedMessage ($mockErrorMessage -f 'UnknownUser', 'AdventureWorks')
            }
        }

        Context 'When ignoring the error' {
            It 'Should not throw an exception and return $null' {
                Get-SqlDscDatabasePermission -ServerObject $mockServerObject -DatabaseName 'AdventureWorks' -Name 'UnknownUser' -ErrorAction 'SilentlyContinue' |
                    Should -BeNullOrEmpty
            }
        }
    }

    Context 'When the database principal exist' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' |
                Add-Member -MemberType 'ScriptProperty' -Name 'Databases' -Value {
                    return @{
                        'AdventureWorks' = New-Object -TypeName Object |
                            Add-Member -MemberType 'NoteProperty' -Name Name -Value 'AdventureWorks' -PassThru |
                            Add-Member -MemberType 'ScriptMethod' -Name 'EnumDatabasePermissions' -Value {
                                param
                                (
                                    [Parameter()]
                                    [System.String]
                                    $SqlServerLogin
                                )

                                $mockEnumDatabasePermissions = [Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo[]] @()

                                $mockEnumDatabasePermissions += [Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo] @{
                                    PermissionType  =  [Microsoft.SqlServer.Management.Smo.DatabasePermissionSet] @{
                                        Connect = $true
                                    }
                                    PermissionState = 'Grant'
                                    Grantee         = 'Zebes\SamusAran'
                                    GrantorType     = 'User'
                                    ObjectClass     = 'DatabaseName'
                                    ObjectName      = 'AdventureWork'
                                }

                                $mockEnumDatabasePermissions += [Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo] @{
                                    PermissionType  =  [Microsoft.SqlServer.Management.Smo.DatabasePermissionSet] @{
                                        Update = $true
                                    }
                                    PermissionState = 'Grant'
                                    Grantee         = 'Zebes\SamusAran'
                                    GrantorType     = 'User'
                                    ObjectClass     = 'DatabaseName'
                                    ObjectName      = 'AdventureWork'
                                }

                                return $mockEnumDatabasePermissions
                            } -PassThru -Force
                    }
                } -PassThru -Force

            Mock -CommandName Test-SqlDscIsDatabasePrincipal -MockWith {
                return $true
            }
        }

        It 'Should return the correct values' {
            $mockResult = Get-SqlDscDatabasePermission -ServerObject $mockServerObject -DatabaseName 'AdventureWorks' -Name 'Zebes\SamusAran' -ErrorAction 'Stop'

            $mockResult | Should -HaveCount 2

            $mockResult[0].PermissionState | Should -Be 'Grant'
            $mockResult[0].PermissionType.Connect | Should -BeTrue
            $mockResult[0].PermissionType.Update | Should -BeFalse

            $mockResult[1].PermissionState | Should -Be 'Grant'
            $mockResult[1].PermissionType.Connect | Should -BeFalse
            $mockResult[1].PermissionType.Update | Should -BeTrue
        }

        Context 'When passing ServerObject over the pipeline' {
            It 'Should return the correct values' {
                $mockResult = $mockServerObject | Get-SqlDscDatabasePermission -DatabaseName 'AdventureWorks' -Name 'Zebes\SamusAran' -ErrorAction 'Stop'

                $mockResult | Should -HaveCount 2

                $mockResult[0].PermissionState | Should -Be 'Grant'
                $mockResult[0].PermissionType.Connect | Should -BeTrue
                $mockResult[0].PermissionType.Update | Should -BeFalse

                $mockResult[1].PermissionState | Should -Be 'Grant'
                $mockResult[1].PermissionType.Connect | Should -BeFalse
                $mockResult[1].PermissionType.Update | Should -BeTrue
            }
        }

        Context 'When using the Refresh parameter' {
            It 'Should pass the Refresh parameter to Test-SqlDscIsDatabasePrincipal' {
                Mock -CommandName Test-SqlDscIsDatabasePrincipal -MockWith {
                    return $true
                } -ParameterFilter { $Refresh -eq $true }

                $mockResult = Get-SqlDscDatabasePermission -ServerObject $mockServerObject -DatabaseName 'AdventureWorks' -Name 'Zebes\SamusAran' -Refresh -ErrorAction 'Stop'

                Should -Invoke -CommandName Test-SqlDscIsDatabasePrincipal -ParameterFilter { $Refresh -eq $true } -Exactly -Times 1 -Scope It
            }
        }
    }
}
