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
    $script:dscModuleName = 'SqlServerDsc'

    $env:SqlServerDscCI = $true

    Import-Module -Name $script:dscModuleName -Force -ErrorAction 'Stop'

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

Describe 'Test-SqlDscServerPermission' -Tag 'Public' {
    Context 'When testing parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = 'LoginGrant'
                ExpectedParameters = '-Login <Login> -Grant -Permission <SqlServerPermission[]> [-WithGrant] [-ExactMatch] [<CommonParameters>]'
            }
            @{
                ExpectedParameterSetName = 'LoginDeny'
                ExpectedParameters = '-Login <Login> -Deny -Permission <SqlServerPermission[]> [-WithGrant] [-ExactMatch] [<CommonParameters>]'
            }
            @{
                ExpectedParameterSetName = 'ServerRoleGrant'
                ExpectedParameters = '-ServerRole <ServerRole> -Grant -Permission <SqlServerPermission[]> [-WithGrant] [-ExactMatch] [<CommonParameters>]'
            }
            @{
                ExpectedParameterSetName = 'ServerRoleDeny'
                ExpectedParameters = '-ServerRole <ServerRole> -Deny -Permission <SqlServerPermission[]> [-WithGrant] [-ExactMatch] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Test-SqlDscServerPermission').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )
            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }
    }

    Context 'When testing parameter properties' {
        It 'Should have Login as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Test-SqlDscServerPermission').Parameters['Login']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have ServerRole as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Test-SqlDscServerPermission').Parameters['ServerRole']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have Grant as a mandatory parameter in Grant parameter sets' {
            $parameterInfo = (Get-Command -Name 'Test-SqlDscServerPermission').Parameters['Grant']
            $grantParameterSetAttributes = $parameterInfo.Attributes | Where-Object { $_.GetType().Name -eq 'ParameterAttribute' -and ($_.ParameterSetName -eq 'LoginGrant' -or $_.ParameterSetName -eq 'ServerRoleGrant') }
            $grantParameterSetAttributes.Mandatory | Should -BeTrue
        }

        It 'Should have Deny as a mandatory parameter in Deny parameter sets' {
            $parameterInfo = (Get-Command -Name 'Test-SqlDscServerPermission').Parameters['Deny']
            $denyParameterSetAttributes = $parameterInfo.Attributes | Where-Object { $_.GetType().Name -eq 'ParameterAttribute' -and ($_.ParameterSetName -eq 'LoginDeny' -or $_.ParameterSetName -eq 'ServerRoleDeny') }
            $denyParameterSetAttributes.Mandatory | Should -BeTrue
        }

        It 'Should have Permission as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Test-SqlDscServerPermission').Parameters['Permission']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have Permission parameter allow empty collections' {
            $parameterInfo = (Get-Command -Name 'Test-SqlDscServerPermission').Parameters['Permission']
            $allowEmptyCollectionAttribute = $parameterInfo.Attributes | Where-Object { $_.GetType().Name -eq 'AllowEmptyCollectionAttribute' }
            $allowEmptyCollectionAttribute | Should -Not -BeNullOrEmpty
        }

        It 'Should have WithGrant as an optional parameter' {
            $parameterInfo = (Get-Command -Name 'Test-SqlDscServerPermission').Parameters['WithGrant']
            $parameterInfo.Attributes.Mandatory | Should -BeFalse
        }

        It 'Should have ExactMatch as an optional parameter' {
            $parameterInfo = (Get-Command -Name 'Test-SqlDscServerPermission').Parameters['ExactMatch']
            $parameterInfo.Attributes.Mandatory | Should -BeFalse
        }
    }

    Context 'When testing permissions successfully' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'MockInstance'

            $mockLogin = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Login' -ArgumentList $mockServerObject, 'TestUser'
            $mockServerRole = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerRole' -ArgumentList $mockServerObject, 'TestRole'

            Mock -CommandName Get-SqlDscServerPermission -MockWith {
                # Mock ServerPermissionInfo with ConnectSql permission in Grant state
                $mockPermissionInfo = [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo[]] @()

                $mockPermissionSet = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionSet'
                $mockPermissionSet.ConnectSql = $true

                $mockInfo = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionInfo'
                $mockInfo.PermissionState = $mockState  # Will be set by parameter filter
                $mockInfo.PermissionType = $mockPermissionSet

                $mockPermissionInfo += $mockInfo

                return $mockPermissionInfo
            } -ParameterFilter { $mockState = 'Grant'; $true }

            Mock -CommandName ConvertTo-SqlDscServerPermission -MockWith {
                return @(
                    [PSCustomObject] @{
                        State = 'Grant'
                        Permission = @('ConnectSql')
                    }
                    [PSCustomObject] @{
                        State = 'GrantWithGrant'
                        Permission = @('ConnectSql')
                    }
                    [PSCustomObject] @{
                        State = 'Deny'
                        Permission = @('ConnectSql')
                    }
                )
            }
        }

        It 'Should return true when testing grant permissions for login' {
            InModuleScope -Parameters @{
                mockLogin = $mockLogin
            } -ScriptBlock {
                $result = Test-SqlDscServerPermission -Login $mockLogin -Grant -Permission ConnectSql

                $result | Should -BeTrue
            }
        }

        It 'Should return true when testing deny permissions for login' {
            InModuleScope -Parameters @{
                mockLogin = $mockLogin
            } -ScriptBlock {
                $result = Test-SqlDscServerPermission -Login $mockLogin -Deny -Permission ConnectSql

                $result | Should -BeTrue
            }
        }

        It 'Should return true when testing grant permissions for server role' {
            InModuleScope -Parameters @{
                mockServerRole = $mockServerRole
            } -ScriptBlock {
                $result = Test-SqlDscServerPermission -ServerRole $mockServerRole -Grant -Permission ConnectSql

                $result | Should -BeTrue
            }
        }

        It 'Should return true when testing deny permissions for server role' {
            InModuleScope -Parameters @{
                mockServerRole = $mockServerRole
            } -ScriptBlock {
                $result = Test-SqlDscServerPermission -ServerRole $mockServerRole -Deny -Permission ConnectSql

                $result | Should -BeTrue
            }
        }

        It 'Should handle WithGrant parameter correctly' {
            InModuleScope -Parameters @{
                mockLogin = $mockLogin
            } -ScriptBlock {
                $result = Test-SqlDscServerPermission -Login $mockLogin -Grant -Permission ConnectSql -WithGrant

                $result | Should -BeTrue
            }
        }

        It 'Should call Get-SqlDscServerPermission with correct parameters' {
            InModuleScope -Parameters @{
                mockLogin = $mockLogin
            } -ScriptBlock {
                $null = Test-SqlDscServerPermission -Login $mockLogin -Grant -Permission ConnectSql

                Should -Invoke -CommandName Get-SqlDscServerPermission -Times 1 -ParameterFilter {
                    $ServerObject -ne $null -and
                    $Name -eq 'TestUser' -and
                    $ErrorAction -eq 'Stop'
                }
            }
        }
    }

    Context 'When permissions are not in desired state' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'MockInstance'

            $mockLogin = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Login' -ArgumentList $mockServerObject, 'TestUser'

            Mock -CommandName Get-SqlDscServerPermission -MockWith {
                # Mock ServerPermissionInfo with ViewServerState permission in Grant state (not the desired ConnectSql)
                $mockPermissionInfo = [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo[]] @()

                $mockPermissionSet = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionSet'
                $mockPermissionSet.ViewServerState = $true

                $mockInfo = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionInfo'
                $mockInfo.PermissionState = 'Grant'
                $mockInfo.PermissionType = $mockPermissionSet

                $mockPermissionInfo += $mockInfo

                return $mockPermissionInfo
            }

            Mock -CommandName ConvertTo-SqlDscServerPermission -MockWith {
                return @(
                    [PSCustomObject] @{
                        State = 'Grant'
                        Permission = @('ViewServerState')  # Different permission than what's being tested
                    }
                )
            }
        }

        It 'Should return false when permissions are not in desired state' {
            InModuleScope -Parameters @{
                mockLogin = $mockLogin
            } -ScriptBlock {
                $result = Test-SqlDscServerPermission -Login $mockLogin -Grant -Permission ConnectSql

                $result | Should -BeFalse
            }
        }
    }

    Context 'When testing fails with an exception' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'MockInstance'

            $mockLogin = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Login' -ArgumentList $mockServerObject, 'TestUser'

            Mock -CommandName Get-SqlDscServerPermission -MockWith {
                throw 'Mock error'
            }
        }

        It 'Should return false when an exception occurs' {
            InModuleScope -Parameters @{
                mockLogin = $mockLogin
            } -ScriptBlock {
                $result = Test-SqlDscServerPermission -Login $mockLogin -Grant -Permission ConnectSql

                $result | Should -BeFalse
            }
        }
    }

    Context 'When testing with empty permission collection' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'MockInstance'

            $mockLogin = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Login' -ArgumentList $mockServerObject, 'TestUser'
        }

        Context 'When no permissions exist' {
            BeforeAll {
                Mock -CommandName Get-SqlDscServerPermission -MockWith {
                    return $null
                }
            }

            It 'Should return true when no permissions exist and empty collection is desired' {
                InModuleScope -Parameters @{
                    mockLogin = $mockLogin
                } -ScriptBlock {
                    $result = Test-SqlDscServerPermission -Login $mockLogin -Grant -Permission @()

                    $result | Should -BeTrue
                }
            }
        }

        Context 'When permissions exist but empty collection is desired' {
            BeforeAll {
                Mock -CommandName Get-SqlDscServerPermission -MockWith {
                    # Mock ServerPermissionInfo with ConnectSql permission in Grant state
                    $mockPermissionInfo = [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo[]] @()

                    $mockPermissionSet = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionSet'
                    $mockPermissionSet.ConnectSql = $true

                    $mockInfo = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionInfo'
                    $mockInfo.PermissionState = 'Grant'
                    $mockInfo.PermissionType = $mockPermissionSet

                    $mockPermissionInfo += $mockInfo

                    return $mockPermissionInfo
                }

                Mock -CommandName ConvertTo-SqlDscServerPermission -MockWith {
                    return @(
                        [PSCustomObject] @{
                            State = 'Grant'
                            Permission = @('ConnectSql')
                        }
                    )
                }
            }

            It 'Should return false when permissions exist but empty collection is desired' {
                InModuleScope -Parameters @{
                    mockLogin = $mockLogin
                } -ScriptBlock {
                    $result = Test-SqlDscServerPermission -Login $mockLogin -Grant -Permission @()

                    $result | Should -BeFalse
                }
            }
        }

        Context 'When no permissions exist and empty collection is desired' {
            BeforeAll {
                Mock -CommandName Get-SqlDscServerPermission -MockWith {
                    # Mock empty ServerPermissionInfo (no permissions)
                    $mockPermissionInfo = [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo[]] @()
                    return $mockPermissionInfo
                }

                Mock -CommandName ConvertTo-SqlDscServerPermission -MockWith {
                    return @(
                        [PSCustomObject] @{
                            State = 'Grant'
                            Permission = @()
                        }
                        [PSCustomObject] @{
                            State = 'Deny'
                            Permission = @()
                        }
                        [PSCustomObject] @{
                            State = 'GrantWithGrant'
                            Permission = @()
                        }
                    )
                }
            }

            It 'Should return true when no permissions are set and empty collection is desired' {
                InModuleScope -Parameters @{
                    mockLogin = $mockLogin
                } -ScriptBlock {
                    $result = Test-SqlDscServerPermission -Login $mockLogin -Grant -Permission @()

                    $result | Should -BeTrue
                }
            }
        }
    }

    Context 'When using pipeline input' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'MockInstance'

            $mockLogin = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Login' -ArgumentList $mockServerObject, 'TestUser'
            $mockServerRole = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerRole' -ArgumentList $mockServerObject, 'TestRole'

            Mock -CommandName Get-SqlDscServerPermission -MockWith {
                # Mock ServerPermissionInfo with ConnectSql permission in Grant state
                $mockPermissionInfo = [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo[]] @()

                $mockPermissionSet = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionSet'
                $mockPermissionSet.ConnectSql = $true

                $mockInfo = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionInfo'
                $mockInfo.PermissionState = 'Grant'
                $mockInfo.PermissionType = $mockPermissionSet

                $mockPermissionInfo += $mockInfo

                return $mockPermissionInfo
            }

            Mock -CommandName ConvertTo-SqlDscServerPermission -MockWith {
                return @(
                    [PSCustomObject] @{
                        State = 'Grant'
                        Permission = @('ConnectSql')
                    }
                )
            }
        }

        It 'Should accept Login from pipeline' {
            InModuleScope -Parameters @{
                mockLogin = $mockLogin
            } -ScriptBlock {
                $result = $mockLogin | Test-SqlDscServerPermission -Grant -Permission ConnectSql

                $result | Should -BeTrue
            }
        }

        It 'Should accept ServerRole from pipeline' {
            InModuleScope -Parameters @{
                mockServerRole = $mockServerRole
            } -ScriptBlock {
                $result = $mockServerRole | Test-SqlDscServerPermission -Grant -Permission ConnectSql

                $result | Should -BeTrue
            }
        }
    }

    Context 'When testing ExactMatch parameter functionality' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'MockInstance'

            $mockLogin = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Login' -ArgumentList $mockServerObject, 'TestUser'

            Mock -CommandName Get-SqlDscServerPermission -MockWith {
                # Mock ServerPermissionInfo with multiple permissions
                $mockPermissionInfo = [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo[]] @()

                $mockPermissionSet = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionSet'
                $mockPermissionSet.AlterAnyEndpoint = $true
                $mockPermissionSet.AlterAnyAvailabilityGroup = $true

                $mockInfo = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionInfo'
                $mockInfo.PermissionState = 'Grant'
                $mockInfo.PermissionType = $mockPermissionSet

                $mockPermissionInfo += $mockInfo

                return $mockPermissionInfo
            }

            Mock -CommandName ConvertTo-SqlDscServerPermission -MockWith {
                return @(
                    [PSCustomObject] @{
                        State = 'Grant'
                        Permission = @('AlterAnyEndpoint', 'AlterAnyAvailabilityGroup')
                    }
                    [PSCustomObject] @{
                        State = 'GrantWithGrant'
                        Permission = @()
                    }
                    [PSCustomObject] @{
                        State = 'Deny'
                        Permission = @()
                    }
                )
            }
        }

        It 'Should return <Expected> when requesting permission <RequestedPermission> with ExactMatch <ExactMatch>' -ForEach @(
            @{
                RequestedPermission = @('AlterAnyEndpoint')
                ExactMatch          = $false
                Expected            = $true
                Description         = 'Should return true when testing for subset without ExactMatch'
            }
            @{
                RequestedPermission = @('AlterAnyEndpoint')
                ExactMatch          = $true
                Expected            = $false
                Description         = 'Should return false when testing for subset with ExactMatch'
            }
            @{
                RequestedPermission = @('AlterAnyEndpoint', 'AlterAnyAvailabilityGroup')
                ExactMatch          = $false
                Expected            = $true
                Description         = 'Should return true when testing for exact match without ExactMatch'
            }
            @{
                RequestedPermission = @('AlterAnyEndpoint', 'AlterAnyAvailabilityGroup')
                ExactMatch          = $true
                Expected            = $true
                Description         = 'Should return true when testing for exact match with ExactMatch'
            }
        ) {
            InModuleScope -Parameters @{
                mockLogin           = $mockLogin
                RequestedPermission = $RequestedPermission
                ExactMatch          = $ExactMatch
                Expected            = $Expected
                Description         = $Description
            } -ScriptBlock {
                $testParameters = @{
                    Login      = $mockLogin
                    Grant      = $true
                    Permission = $RequestedPermission
                }

                if ($ExactMatch)
                {
                    $testParameters['ExactMatch'] = $true
                }

                $result = Test-SqlDscServerPermission @testParameters

                $result | Should -Be $Expected -Because $Description
            }
        }
    }
}
