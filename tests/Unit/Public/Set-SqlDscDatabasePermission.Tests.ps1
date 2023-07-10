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

Describe 'Set-SqlDscDatabasePermission' -Tag 'Public' {
    Context 'When no databases exist' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' |
                Add-Member -MemberType 'ScriptProperty' -Name 'Databases' -Value {
                    return $null
                } -PassThru -Force

            $script:mockDefaultParameters = @{
                DatabaseName = 'MissingDatabase'
                Name         = 'KnownUser'
                State        = 'Grant'
                Permission   = [Microsoft.SqlServer.Management.Smo.DatabasePermissionSet]::new()
            }
        }

        It 'Should throw the correct error' {
            $mockErrorMessage = InModuleScope -ScriptBlock {
                $script:localizedData.DatabasePermission_MissingDatabase
            }

            { Set-SqlDscDatabasePermission -ServerObject $mockServerObject @mockDefaultParameters } |
                Should -Throw -ExpectedMessage ($mockErrorMessage -f 'MissingDatabase')
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

            $script:mockDefaultParameters = @{
                DatabaseName = 'MissingDatabase'
                Name         = 'KnownUser'
                State        = 'Grant'
                Permission   = [Microsoft.SqlServer.Management.Smo.DatabasePermissionSet]::new()
            }
        }


        It 'Should throw the correct error' {
            $mockErrorMessage = InModuleScope -ScriptBlock {
                $script:localizedData.DatabasePermission_MissingDatabase
            }

            { Set-SqlDscDatabasePermission -ServerObject $mockServerObject @mockDefaultParameters } |
                Should -Throw -ExpectedMessage ($mockErrorMessage -f 'MissingDatabase')
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

            $script:mockDefaultParameters = @{
                DatabaseName = 'AdventureWorks'
                Name         = 'UnknownUser'
                State        = 'Grant'
                Permission   = [Microsoft.SqlServer.Management.Smo.DatabasePermissionSet]::new()
            }
        }

        It 'Should throw the correct error' {
            $mockErrorMessage = InModuleScope -ScriptBlock {
                $script:localizedData.DatabasePermission_MissingPrincipal
            }

            { Set-SqlDscDatabasePermission -ServerObject $mockServerObject @mockDefaultParameters } |
                Should -Throw -ExpectedMessage ($mockErrorMessage -f 'UnknownUser', 'AdventureWorks')
        }
    }

    Context 'When the database principal exist' {
        Context 'When using parameter Confirm with value $false' {
            BeforeAll {
                $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' |
                    Add-Member -MemberType 'ScriptProperty' -Name 'Databases' -Value {
                        return @{
                            'AdventureWorks' = New-Object -TypeName Object |
                                Add-Member -MemberType 'NoteProperty' -Name Name -Value 'AdventureWorks' -PassThru |
                                Add-Member -MemberType 'ScriptMethod' -Name 'Deny' -Value {
                                    $script:mockMethodDenyCallCount += 1
                                } -PassThru -Force
                        }
                    } -PassThru -Force

                Mock -CommandName Test-SqlDscIsDatabasePrincipal -MockWith {
                    return $true
                }

                $script:mockDefaultParameters = @{
                    Confirm      = $false
                    DatabaseName = 'AdventureWorks'
                    Name         = 'Zebes\SamusAran'
                    State        = 'Deny'
                    Permission   = [Microsoft.SqlServer.Management.Smo.DatabasePermissionSet] @{
                        Connect = $true
                    }
                }
            }

            BeforeEach {
                $script:mockMethodDenyCallCount = 0
            }

            It 'Should call the correct mocked method' {
                { Set-SqlDscDatabasePermission -ServerObject $mockServerObject @mockDefaultParameters } |
                    Should -Not -Throw

                $script:mockMethodDenyCallCount | Should -Be 1
            }
        }

        Context 'When using parameter Force' {
            BeforeAll {
                $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' |
                    Add-Member -MemberType 'ScriptProperty' -Name 'Databases' -Value {
                        return @{
                            'AdventureWorks' = New-Object -TypeName Object |
                                Add-Member -MemberType 'NoteProperty' -Name Name -Value 'AdventureWorks' -PassThru |
                                Add-Member -MemberType 'ScriptMethod' -Name 'Deny' -Value {
                                    $script:mockMethodDenyCallCount += 1
                                } -PassThru -Force
                        }
                    } -PassThru -Force

                Mock -CommandName Test-SqlDscIsDatabasePrincipal -MockWith {
                    return $true
                }

                $script:mockDefaultParameters = @{
                    Force        = $true
                    DatabaseName = 'AdventureWorks'
                    Name         = 'Zebes\SamusAran'
                    State        = 'Deny'
                    Permission   = [Microsoft.SqlServer.Management.Smo.DatabasePermissionSet] @{
                        Connect = $true
                    }
                }
            }

            BeforeEach {
                $script:mockMethodDenyCallCount = 0
            }

            It 'Should call the correct mocked method' {
                { Set-SqlDscDatabasePermission -ServerObject $mockServerObject @mockDefaultParameters } |
                    Should -Not -Throw

                $script:mockMethodDenyCallCount | Should -Be 1
            }
        }

        Context 'When using parameter WhatIf' {
            BeforeAll {
                $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' |
                    Add-Member -MemberType 'ScriptProperty' -Name 'Databases' -Value {
                        return @{
                            'AdventureWorks' = New-Object -TypeName Object |
                                Add-Member -MemberType 'NoteProperty' -Name Name -Value 'AdventureWorks' -PassThru |
                                Add-Member -MemberType 'ScriptMethod' -Name 'Deny' -Value {
                                    $script:mockMethodDenyCallCount += 1
                                } -PassThru -Force
                        }
                    } -PassThru -Force

                Mock -CommandName Test-SqlDscIsDatabasePrincipal -MockWith {
                    return $true
                }

                $script:mockDefaultParameters = @{
                    WhatIf       = $true
                    DatabaseName = 'AdventureWorks'
                    Name         = 'Zebes\SamusAran'
                    State        = 'Deny'
                    Permission   = [Microsoft.SqlServer.Management.Smo.DatabasePermissionSet] @{
                        Connect = $true
                    }
                }
            }

            BeforeEach {
                $script:mockMethodDenyCallCount = 0
            }

            It 'Should not call the mocked method' {
                { Set-SqlDscDatabasePermission -ServerObject $mockServerObject @mockDefaultParameters } |
                    Should -Not -Throw

                $script:mockMethodDenyCallCount | Should -Be 0
            }
        }

        Context 'When permission should be granted' {
            BeforeAll {
                $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' |
                    Add-Member -MemberType 'ScriptProperty' -Name 'Databases' -Value {
                        return @{
                            'AdventureWorks' = New-Object -TypeName Object |
                                Add-Member -MemberType 'NoteProperty' -Name Name -Value 'AdventureWorks' -PassThru |
                                Add-Member -MemberType 'ScriptMethod' -Name 'Grant' -Value {
                                    $script:mockMethodGrantCallCount += 1
                                } -PassThru -Force
                        }
                    } -PassThru -Force

                Mock -CommandName Test-SqlDscIsDatabasePrincipal -MockWith {
                    return $true
                }

                $script:mockDefaultParameters = @{
                    Confirm      = $false
                    DatabaseName = 'AdventureWorks'
                    Name         = 'Zebes\SamusAran'
                    State        = 'Grant'
                    Permission   = [Microsoft.SqlServer.Management.Smo.DatabasePermissionSet] @{
                        Connect = $true
                    }
                }
            }

            BeforeEach {
                $script:mockMethodGrantCallCount = 0
            }

            It 'Should call the correct mocked method' {
                { Set-SqlDscDatabasePermission -ServerObject $mockServerObject @mockDefaultParameters } |
                    Should -Not -Throw

                $script:mockMethodGrantCallCount | Should -Be 1
            }

            Context 'When passing ServerObject over the pipeline' {
                It 'Should call the correct mocked method' {
                    { $mockServerObject | Set-SqlDscDatabasePermission @mockDefaultParameters } |
                        Should -Not -Throw

                    $script:mockMethodGrantCallCount | Should -Be 1
                }
            }
        }

        Context 'When permission should be granted and using parameter WithGrant' {
            BeforeAll {
                $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' |
                    Add-Member -MemberType 'ScriptProperty' -Name 'Databases' -Value {
                        return @{
                            'AdventureWorks' = New-Object -TypeName Object |
                                Add-Member -MemberType 'NoteProperty' -Name Name -Value 'AdventureWorks' -PassThru |
                                Add-Member -MemberType 'ScriptMethod' -Name 'Grant' -Value {
                                    param
                                    (
                                        [Parameter()]
                                        $Permission,

                                        [Parameter()]
                                        $Name,

                                        [Parameter()]
                                        $WithGrant
                                    )

                                    if ($WithGrant)
                                    {
                                        $script:mockMethodGrantUsingWithGrantCallCount += 1
                                    }
                                } -PassThru -Force
                        }
                    } -PassThru -Force

                Mock -CommandName Test-SqlDscIsDatabasePrincipal -MockWith {
                    return $true
                }

                $script:mockDefaultParameters = @{
                    Confirm      = $false
                    DatabaseName = 'AdventureWorks'
                    Name         = 'Zebes\SamusAran'
                    State        = 'Grant'
                    WithGrant    = $true
                    Permission   = [Microsoft.SqlServer.Management.Smo.DatabasePermissionSet] @{
                        Connect = $true
                    }
                }
            }

            BeforeEach {
                $script:mockMethodGrantUsingWithGrantCallCount = 0
            }

            It 'Should call the correct mocked method' {
                { Set-SqlDscDatabasePermission -ServerObject $mockServerObject @mockDefaultParameters } |
                    Should -Not -Throw

                $script:mockMethodGrantUsingWithGrantCallCount | Should -Be 1
            }

            Context 'When passing ServerObject over the pipeline' {
                It 'Should call the correct mocked method' {
                    { $mockServerObject | Set-SqlDscDatabasePermission @mockDefaultParameters } |
                        Should -Not -Throw

                    $script:mockMethodGrantUsingWithGrantCallCount | Should -Be 1
                }
            }
        }

        Context 'When permission should be revoked' {
            BeforeAll {
                $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' |
                    Add-Member -MemberType 'ScriptProperty' -Name 'Databases' -Value {
                        return @{
                            'AdventureWorks' = New-Object -TypeName Object |
                                Add-Member -MemberType 'NoteProperty' -Name Name -Value 'AdventureWorks' -PassThru |
                                Add-Member -MemberType 'ScriptMethod' -Name 'Revoke' -Value {
                                    $script:mockMethodRevokeCallCount += 1
                                } -PassThru -Force
                        }
                    } -PassThru -Force

                Mock -CommandName Test-SqlDscIsDatabasePrincipal -MockWith {
                    return $true
                }

                $script:mockDefaultParameters = @{
                    Confirm      = $false
                    DatabaseName = 'AdventureWorks'
                    Name         = 'Zebes\SamusAran'
                    State        = 'Revoke'
                    Permission   = [Microsoft.SqlServer.Management.Smo.DatabasePermissionSet] @{
                        Connect = $true
                    }
                }
            }

            BeforeEach {
                $script:mockMethodRevokeCallCount = 0
            }

            It 'Should call the correct mocked method' {
                { Set-SqlDscDatabasePermission -ServerObject $mockServerObject @mockDefaultParameters } |
                    Should -Not -Throw

                $script:mockMethodRevokeCallCount | Should -Be 1
            }

            Context 'When passing ServerObject over the pipeline' {
                It 'Should call the correct mocked method' {
                    { $mockServerObject | Set-SqlDscDatabasePermission @mockDefaultParameters } |
                        Should -Not -Throw

                    $script:mockMethodRevokeCallCount | Should -Be 1
                }
            }
        }

        Context 'When permission should be revoked and using parameter WithGrant' {
            BeforeAll {
                $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' |
                    Add-Member -MemberType 'ScriptProperty' -Name 'Databases' -Value {
                        return @{
                            'AdventureWorks' = New-Object -TypeName Object |
                                Add-Member -MemberType 'NoteProperty' -Name Name -Value 'AdventureWorks' -PassThru |
                                Add-Member -MemberType 'ScriptMethod' -Name 'Revoke' -Value {
                                    param
                                    (
                                        [Parameter()]
                                        $Permission,

                                        [Parameter()]
                                        $Name,

                                        [Parameter()]
                                        $RevokeGrant,

                                        [Parameter()]
                                        $Cascade
                                    )

                                    if (-not $RevokeGrant -and $Cascade)
                                    {
                                        $script:mockMethodRevokeUsingWithGrantCallCount += 1
                                    }
                                } -PassThru -Force
                        }
                    } -PassThru -Force

                Mock -CommandName Test-SqlDscIsDatabasePrincipal -MockWith {
                    return $true
                }

                $script:mockDefaultParameters = @{
                    Confirm      = $false
                    DatabaseName = 'AdventureWorks'
                    Name         = 'Zebes\SamusAran'
                    State        = 'Revoke'
                    WithGrant    = $true
                    Permission   = [Microsoft.SqlServer.Management.Smo.DatabasePermissionSet] @{
                        Connect = $true
                    }
                }
            }

            BeforeEach {
                $script:mockMethodRevokeUsingWithGrantCallCount = 0
            }

            It 'Should call the correct mocked method' {
                { Set-SqlDscDatabasePermission -ServerObject $mockServerObject @mockDefaultParameters } |
                    Should -Not -Throw

                $script:mockMethodRevokeUsingWithGrantCallCount | Should -Be 1
            }

            Context 'When passing ServerObject over the pipeline' {
                It 'Should call the correct mocked method' {
                    { $mockServerObject | Set-SqlDscDatabasePermission @mockDefaultParameters } |
                        Should -Not -Throw

                    $script:mockMethodGrantUsingWithGrantCallCount | Should -Be 1
                }
            }
        }

        Context 'When permission should be denied' {
            BeforeAll {
                $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' |
                    Add-Member -MemberType 'ScriptProperty' -Name 'Databases' -Value {
                        return @{
                            'AdventureWorks' = New-Object -TypeName Object |
                                Add-Member -MemberType 'NoteProperty' -Name Name -Value 'AdventureWorks' -PassThru |
                                Add-Member -MemberType 'ScriptMethod' -Name 'Deny' -Value {
                                    $script:mockMethodDenyCallCount += 1
                                } -PassThru -Force
                        }
                    } -PassThru -Force

                Mock -CommandName Test-SqlDscIsDatabasePrincipal -MockWith {
                    return $true
                }

                $script:mockDefaultParameters = @{
                    Confirm      = $false
                    DatabaseName = 'AdventureWorks'
                    Name         = 'Zebes\SamusAran'
                    State        = 'Deny'
                    Permission   = [Microsoft.SqlServer.Management.Smo.DatabasePermissionSet] @{
                        Connect = $true
                    }
                }
            }

            BeforeEach {
                $script:mockMethodDenyCallCount = 0
            }

            It 'Should call the correct mocked method' {
                { Set-SqlDscDatabasePermission -ServerObject $mockServerObject @mockDefaultParameters } |
                    Should -Not -Throw

                $script:mockMethodDenyCallCount | Should -Be 1
            }

            Context 'When passing ServerObject over the pipeline' {
                It 'Should call the correct mocked method' {
                    { $mockServerObject | Set-SqlDscDatabasePermission @mockDefaultParameters } |
                        Should -Not -Throw

                    $script:mockMethodDenyCallCount | Should -Be 1
                }
            }

            Context 'When passing WithGrant' {
                BeforeAll {
                    Mock -CommandName Write-Warning
                }

                It 'Should output the correct warning message and return the correct values' {
                    $mockWarningMessage = InModuleScope -ScriptBlock {
                        $script:localizedData.DatabasePermission_IgnoreWithGrantForStateDeny
                    }

                    { $mockServerObject | Set-SqlDscDatabasePermission -WithGrant @mockDefaultParameters } |
                        Should -Not -Throw

                    $script:mockMethodDenyCallCount | Should -Be 1

                    Should -Invoke -CommandName 'Write-Warning' -ParameterFilter {
                        $Message -eq $mockWarningMessage
                    }
                }
            }
        }
    }
}
