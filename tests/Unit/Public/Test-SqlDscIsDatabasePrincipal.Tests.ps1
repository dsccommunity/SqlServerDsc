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
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
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

    $env:SqlServerDscCI = $true

    Import-Module -Name $script:dscModuleName

    # Loading mocked classes
    Add-Type -Path (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '../Stubs') -ChildPath 'SMO.cs')

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscModuleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force

    Remove-Item -Path 'env:SqlServerDscCI'
}

Describe 'Test-SqlDscIsDatabasePrincipal' -Tag 'Public' {
    Context 'When database does not exist' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' |
                Add-Member -MemberType 'ScriptProperty' -Name 'Databases' -Value {
                    return @(
                        @{
                            'AdventureWorks' = New-Object -TypeName Object
                        }
                    )
                } -PassThru -Force

            $mockErrorMessage = InModuleScope -ScriptBlock {
                $script:localizedData.IsDatabasePrincipal_DatabaseMissing
            }
        }

        It 'Should throw the correct error' {
            { Test-SqlDscIsDatabasePrincipal -ServerObject $mockServerObject -DatabaseName 'MissingDatabase' -Name 'KnownUser' } |
                Should -Throw -ExpectedMessage ($mockErrorMessage -f 'MissingDatabase')
        }
    }

    Context 'When database does not have the specified principal' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' |
                Add-Member -MemberType 'ScriptProperty' -Name 'Databases' -Value {
                    return @{
                        'AdventureWorks' = New-Object -TypeName Object |
                            Add-Member -MemberType 'NoteProperty' -Name Name -Value 'AdventureWorks' -PassThru |
                            Add-Member -MemberType 'ScriptProperty' -Name 'Users' -Value {
                                return @{
                                    'Zebes\SamusAran' = New-Object -TypeName Object |
                                        Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'Zebes\SamusAran' -PassThru -Force
                                }
                            } -PassThru |
                            Add-Member -MemberType 'ScriptProperty' -Name 'ApplicationRoles' -Value {
                                return @{
                                    'MyAppRole' = New-Object -TypeName Object |
                                        Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'MyAppRole' -PassThru -Force
                                }
                            } -PassThru |
                            Add-Member -MemberType 'ScriptProperty' -Name 'Roles' -Value {
                                return @{
                                    'db_datareader'   = New-Object -TypeName Object |
                                        Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'db_datareader' -PassThru |
                                        Add-Member -MemberType 'NoteProperty' -Name 'IsFixedRole' -Value $true -PassThru -Force

                                    'UserDefinedRole' = New-Object -TypeName Object |
                                        Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'UserDefinedRole' -PassThru |
                                        Add-Member -MemberType 'NoteProperty' -Name 'IsFixedRole' -Value $false -PassThru -Force
                                }
                            } -PassThru -Force
                    }
                } -PassThru -Force
        }

        It 'Should return $false' {
            $result = Test-SqlDscIsDatabasePrincipal -ServerObject $mockServerObject -DatabaseName 'AdventureWorks' -Name 'UnknownUser'

            $result | Should -BeFalse
        }
    }

    Context 'When database have the specified principal' {
        Context 'When the specified principal is a user' {
            BeforeAll {
                $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' |
                    Add-Member -MemberType 'ScriptProperty' -Name 'Databases' -Value {
                        return @{
                            'AdventureWorks' = New-Object -TypeName Object |
                                Add-Member -MemberType 'NoteProperty' -Name Name -Value 'AdventureWorks' -PassThru |
                                Add-Member -MemberType 'ScriptProperty' -Name 'Users' -Value {
                                    return @{
                                        'Zebes\SamusAran' = New-Object -TypeName Object |
                                            Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'Zebes\SamusAran' -PassThru -Force
                                    }
                                } -PassThru |
                                Add-Member -MemberType 'ScriptProperty' -Name 'ApplicationRoles' -Value {
                                    return @{
                                        'MyAppRole' = New-Object -TypeName Object |
                                            Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'MyAppRole' -PassThru -Force
                                    }
                                } -PassThru |
                                Add-Member -MemberType 'ScriptProperty' -Name 'Roles' -Value {
                                    return @{
                                        'db_datareader'   = New-Object -TypeName Object |
                                            Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'db_datareader' -PassThru |
                                            Add-Member -MemberType 'NoteProperty' -Name 'IsFixedRole' -Value $true -PassThru -Force

                                        'UserDefinedRole' = New-Object -TypeName Object |
                                            Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'UserDefinedRole' -PassThru |
                                            Add-Member -MemberType 'NoteProperty' -Name 'IsFixedRole' -Value $false -PassThru -Force
                                    }
                                } -PassThru -Force
                        }
                    } -PassThru -Force
            }

            It 'Should return $true' {
                $result = Test-SqlDscIsDatabasePrincipal -ServerObject $mockServerObject -DatabaseName 'AdventureWorks' -Name 'Zebes\SamusAran'

                $result | Should -BeTrue
            }

            Context 'When passing ServerObject over the pipeline' {
                It 'Should return $true' {
                    $result = $mockServerObject | Test-SqlDscIsDatabasePrincipal -DatabaseName 'AdventureWorks' -Name 'Zebes\SamusAran'

                    $result | Should -BeTrue
                }
            }

            Context 'When users are excluded from evaluation' {
                It 'Should return $false' {
                    $result = Test-SqlDscIsDatabasePrincipal -ServerObject $mockServerObject -DatabaseName 'AdventureWorks' -Name 'Zebes\SamusAran' -ExcludeUsers

                    $result | Should -BeFalse
                }
            }
        }

        Context 'When the specified principal is a application role' {
            BeforeAll {
                $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' |
                    Add-Member -MemberType 'ScriptProperty' -Name 'Databases' -Value {
                        return @{
                            'AdventureWorks' = New-Object -TypeName Object |
                                Add-Member -MemberType 'NoteProperty' -Name Name -Value 'AdventureWorks' -PassThru |
                                Add-Member -MemberType 'ScriptProperty' -Name 'Users' -Value {
                                    return @{
                                        'Zebes\SamusAran' = New-Object -TypeName Object |
                                            Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'Zebes\SamusAran' -PassThru -Force
                                    }
                                } -PassThru |
                                Add-Member -MemberType 'ScriptProperty' -Name 'ApplicationRoles' -Value {
                                    return @{
                                        'MyAppRole' = New-Object -TypeName Object |
                                            Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'MyAppRole' -PassThru -Force
                                    }
                                } -PassThru |
                                Add-Member -MemberType 'ScriptProperty' -Name 'Roles' -Value {
                                    return @{
                                        'db_datareader'   = New-Object -TypeName Object |
                                            Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'db_datareader' -PassThru |
                                            Add-Member -MemberType 'NoteProperty' -Name 'IsFixedRole' -Value $true -PassThru -Force

                                        'UserDefinedRole' = New-Object -TypeName Object |
                                            Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'UserDefinedRole' -PassThru |
                                            Add-Member -MemberType 'NoteProperty' -Name 'IsFixedRole' -Value $false -PassThru -Force
                                    }
                                } -PassThru -Force
                        }
                    } -PassThru -Force
            }

            It 'Should return $true' {
                $result = Test-SqlDscIsDatabasePrincipal -ServerObject $mockServerObject -DatabaseName 'AdventureWorks' -Name 'MyAppRole'

                $result | Should -BeTrue
            }

            Context 'When application roles are excluded from evaluation' {
                It 'Should return $false' {
                    $result = Test-SqlDscIsDatabasePrincipal -ServerObject $mockServerObject -DatabaseName 'AdventureWorks' -Name 'MyAppRole' -ExcludeApplicationRoles

                    $result | Should -BeFalse
                }
            }
        }

        Context 'When the specified principal is a user defined role' {
            BeforeAll {
                $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' |
                    Add-Member -MemberType 'ScriptProperty' -Name 'Databases' -Value {
                        return @{
                            'AdventureWorks' = New-Object -TypeName Object |
                                Add-Member -MemberType 'NoteProperty' -Name Name -Value 'AdventureWorks' -PassThru |
                                Add-Member -MemberType 'ScriptProperty' -Name 'Users' -Value {
                                    return @{
                                        'Zebes\SamusAran' = New-Object -TypeName Object |
                                            Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'Zebes\SamusAran' -PassThru -Force
                                    }
                                } -PassThru |
                                Add-Member -MemberType 'ScriptProperty' -Name 'ApplicationRoles' -Value {
                                    return @{
                                        'MyAppRole' = New-Object -TypeName Object |
                                            Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'MyAppRole' -PassThru -Force
                                    }
                                } -PassThru |
                                Add-Member -MemberType 'ScriptProperty' -Name 'Roles' -Value {
                                    return @{
                                        'db_datareader'   = New-Object -TypeName Object |
                                            Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'db_datareader' -PassThru |
                                            Add-Member -MemberType 'NoteProperty' -Name 'IsFixedRole' -Value $true -PassThru -Force

                                        'UserDefinedRole' = New-Object -TypeName Object |
                                            Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'UserDefinedRole' -PassThru |
                                            Add-Member -MemberType 'NoteProperty' -Name 'IsFixedRole' -Value $false -PassThru -Force
                                    }
                                } -PassThru -Force
                        }
                    } -PassThru -Force
            }

            It 'Should return $true' {
                $result = Test-SqlDscIsDatabasePrincipal -ServerObject $mockServerObject -DatabaseName 'AdventureWorks' -Name 'UserDefinedRole'

                $result | Should -BeTrue
            }

            Context 'When roles are excluded from evaluation' {
                It 'Should return $false' {
                    $result = Test-SqlDscIsDatabasePrincipal -ServerObject $mockServerObject -DatabaseName 'AdventureWorks' -Name 'UserDefinedRole' -ExcludeRoles

                    $result | Should -BeFalse
                }
            }

            Context 'When fixed roles are excluded from evaluation' {
                BeforeAll {
                    $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' |
                        Add-Member -MemberType 'ScriptProperty' -Name 'Databases' -Value {
                            return @{
                                'AdventureWorks' = New-Object -TypeName Object |
                                    Add-Member -MemberType 'NoteProperty' -Name Name -Value 'AdventureWorks' -PassThru |
                                    Add-Member -MemberType 'ScriptProperty' -Name 'Users' -Value {
                                        return @{
                                            'Zebes\SamusAran' = New-Object -TypeName Object |
                                                Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'Zebes\SamusAran' -PassThru -Force
                                        }
                                    } -PassThru |
                                    Add-Member -MemberType 'ScriptProperty' -Name 'ApplicationRoles' -Value {
                                        return @{
                                            'MyAppRole' = New-Object -TypeName Object |
                                                Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'MyAppRole' -PassThru -Force
                                        }
                                    } -PassThru |
                                    Add-Member -MemberType 'ScriptProperty' -Name 'Roles' -Value {
                                        return (
                                            @{
                                                'db_datareader'   = New-Object -TypeName Object |
                                                    Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'db_datareader' -PassThru |
                                                    Add-Member -MemberType 'NoteProperty' -Name 'IsFixedRole' -Value $true -PassThru -Force

                                                'UserDefinedRole' = New-Object -TypeName Object |
                                                    Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'UserDefinedRole' -PassThru |
                                                    Add-Member -MemberType 'NoteProperty' -Name 'IsFixedRole' -Value $false -PassThru -Force
                                            }
                                        ).GetEnumerator() | Select-Object -ExpandProperty Value
                                    } -PassThru -Force
                            }
                        } -PassThru -Force
                }

                It 'Should return $true' {
                    $result = Test-SqlDscIsDatabasePrincipal -ServerObject $mockServerObject -DatabaseName 'AdventureWorks' -Name 'UserDefinedRole' -ExcludeFixedRoles

                    $result | Should -BeTrue
                }
            }
        }

        Context 'When the specified principal is a fixed role' {
            BeforeAll {
                $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' |
                    Add-Member -MemberType 'ScriptProperty' -Name 'Databases' -Value {
                        return @{
                            'AdventureWorks' = New-Object -TypeName Object |
                                Add-Member -MemberType 'NoteProperty' -Name Name -Value 'AdventureWorks' -PassThru |
                                Add-Member -MemberType 'ScriptProperty' -Name 'Users' -Value {
                                    return @{
                                        'Zebes\SamusAran' = New-Object -TypeName Object |
                                            Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'Zebes\SamusAran' -PassThru -Force
                                    }
                                } -PassThru |
                                Add-Member -MemberType 'ScriptProperty' -Name 'ApplicationRoles' -Value {
                                    return @{
                                        'MyAppRole' = New-Object -TypeName Object |
                                            Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'MyAppRole' -PassThru -Force
                                    }
                                } -PassThru |
                                Add-Member -MemberType 'ScriptProperty' -Name 'Roles' -Value {
                                    return @{
                                        'db_datareader'   = New-Object -TypeName Object |
                                            Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'db_datareader' -PassThru |
                                            Add-Member -MemberType 'NoteProperty' -Name 'IsFixedRole' -Value $true -PassThru -Force

                                        'UserDefinedRole' = New-Object -TypeName Object |
                                            Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'UserDefinedRole' -PassThru |
                                            Add-Member -MemberType 'NoteProperty' -Name 'IsFixedRole' -Value $false -PassThru -Force
                                    }
                                } -PassThru -Force
                        }
                    } -PassThru -Force
            }

            It 'Should return $true' {
                $result = Test-SqlDscIsDatabasePrincipal -ServerObject $mockServerObject -DatabaseName 'AdventureWorks' -Name 'db_datareader'

                $result | Should -BeTrue
            }

            Context 'When roles are excluded from evaluation' {
                It 'Should return $false' {
                    $result = Test-SqlDscIsDatabasePrincipal -ServerObject $mockServerObject -DatabaseName 'AdventureWorks' -Name 'db_datareader' -ExcludeRoles

                    $result | Should -BeFalse
                }
            }

            Context 'When fixed roles are excluded from evaluation' {
                BeforeAll {
                    $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' |
                        Add-Member -MemberType 'ScriptProperty' -Name 'Databases' -Value {
                            return @{
                                'AdventureWorks' = New-Object -TypeName Object |
                                    Add-Member -MemberType 'NoteProperty' -Name Name -Value 'AdventureWorks' -PassThru |
                                    Add-Member -MemberType 'ScriptProperty' -Name 'Users' -Value {
                                        return @{
                                            'Zebes\SamusAran' = New-Object -TypeName Object |
                                                Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'Zebes\SamusAran' -PassThru -Force
                                        }
                                    } -PassThru |
                                    Add-Member -MemberType 'ScriptProperty' -Name 'ApplicationRoles' -Value {
                                        return @{
                                            'MyAppRole' = New-Object -TypeName Object |
                                                Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'MyAppRole' -PassThru -Force
                                        }
                                    } -PassThru |
                                    Add-Member -MemberType 'ScriptProperty' -Name 'Roles' -Value {
                                        return (
                                            @{
                                                'db_datareader'   = New-Object -TypeName Object |
                                                    Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'db_datareader' -PassThru |
                                                    Add-Member -MemberType 'NoteProperty' -Name 'IsFixedRole' -Value $true -PassThru -Force

                                                'UserDefinedRole' = New-Object -TypeName Object |
                                                    Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'UserDefinedRole' -PassThru |
                                                    Add-Member -MemberType 'NoteProperty' -Name 'IsFixedRole' -Value $false -PassThru -Force
                                            }
                                        ).GetEnumerator() | Select-Object -ExpandProperty Value
                                    } -PassThru -Force
                            }
                        } -PassThru -Force
                }

                It 'Should return $false' {
                    $result = Test-SqlDscIsDatabasePrincipal -ServerObject $mockServerObject -DatabaseName 'AdventureWorks' -Name 'db_datareader' -ExcludeFixedRoles

                    $result | Should -BeFalse
                }
            }
        }
    }
}
