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
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
    }
}

BeforeAll {
    $script:dscModuleName = 'SqlServerDsc'

    Import-Module -Name $script:dscModuleName -Force -ErrorAction 'Stop'

    # Check if there is a CI database instance to use for testing
    $script:sqlServerInstanceName = $env:SqlServerInstanceName

    if (-not $script:sqlServerInstanceName)
    {
        $script:sqlServerInstanceName = 'DSCSQLTEST'
    }

    # Get a computer name that will work in the CI environment
    $script:computerName = Get-ComputerName

    Write-Verbose -Message ('Integration tests will run using computer name ''{0}'' and instance name ''{1}''.' -f $script:computerName, $script:sqlServerInstanceName) -Verbose

    # Setup default parameter values to reduce verbosity in the tests
    $PSDefaultParameterValues['*:ServerName'] = $script:computerName
    $PSDefaultParameterValues['*:InstanceName'] = $script:sqlServerInstanceName
    $PSDefaultParameterValues['*:ErrorAction'] = 'Stop'

    # Test connection to ensure instance is available
    try
    {
        $script:serverObject = Connect-SqlDscDatabaseEngine -ServerName $script:computerName -InstanceName $script:sqlServerInstanceName -Force
    }
    catch
    {
        throw ('Unable to connect to SQL Server instance ''{0}\{1}''. Make sure the instance is running and accessible.' -f $script:computerName, $script:sqlServerInstanceName)
    }

    # Test login for integration tests
    $script:testLoginName = 'TestPermissionLogin'

    # Create test login if it doesn't exist
    $existingLogin = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -ErrorAction 'SilentlyContinue'
    if (-not $existingLogin)
    {
        $securePassword = ConvertTo-SecureString -String 'P@ssw0rd!' -AsPlainText -Force
        New-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -LoginCredential ([PSCredential]::new($script:testLoginName, $securePassword)) -Force
    }
}

AfterAll {
    # Clean up test login
    $existingLogin = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -ErrorAction 'SilentlyContinue'
    if ($existingLogin)
    {
        Remove-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -Force
    }

    Disconnect-SqlDscDatabaseEngine -ServerObject $script:serverObject

    $PSDefaultParameterValues.Remove('*:ServerName')
    $PSDefaultParameterValues.Remove('*:InstanceName')
    $PSDefaultParameterValues.Remove('*:ErrorAction')
}

Describe 'New-SqlDscServerPermission Integration Tests' -Tag 'Integration' {
    Context 'When granting server permissions' {
        BeforeEach {
            # Ensure clean state by removing any existing permissions
            $currentPermissions = Get-SqlDscServerPermission -ServerObject $script:serverObject -Name $script:testLoginName -ErrorAction 'SilentlyContinue'
            if ($currentPermissions)
            {
                $permissions = @(
                    [ServerPermission] @{
                        State = 'Grant'
                        Permission = ($currentPermissions | Where-Object { $_.PermissionState -eq 'Grant' } | ForEach-Object { $_.PermissionType | Get-Member -MemberType Property | Where-Object { $_.Name -ne 'Equals' -and $_.Name -ne 'GetHashCode' -and $_.Name -ne 'GetType' -and $_.Name -ne 'ToString' } | Where-Object { $_.Definition -like '*get;set;*' } | Select-Object -ExpandProperty Name | Where-Object { $currentPermissions[0].PermissionType.$_ } })
                    }
                )
                if ($permissions[0].Permission.Count -gt 0)
                {
                    Remove-SqlDscServerPermission -ServerObject $script:serverObject -Name $script:testLoginName -Permission $permissions -Force
                }
            }
        }

        It 'Should grant ConnectSql permission successfully' {
            $permissions = @(
                [ServerPermission] @{
                    State = 'Grant'
                    Permission = @('ConnectSql')
                }
            )

            { New-SqlDscServerPermission -ServerObject $script:serverObject -Name $script:testLoginName -Permission $permissions -Force } |
                Should -Not -Throw

            # Verify the permission was granted
            $grantedPermissions = Get-SqlDscServerPermission -ServerObject $script:serverObject -Name $script:testLoginName
            $grantedPermissions | Should -Not -BeNullOrEmpty
            $grantedPermissions.PermissionType.ConnectSql | Should -BeTrue
        }

        It 'Should grant multiple permissions successfully' {
            $permissions = @(
                [ServerPermission] @{
                    State = 'Grant'
                    Permission = @('ConnectSql', 'ViewServerState')
                }
            )

            { New-SqlDscServerPermission -ServerObject $script:serverObject -Name $script:testLoginName -Permission $permissions -Force } |
                Should -Not -Throw

            # Verify the permissions were granted
            $grantedPermissions = Get-SqlDscServerPermission -ServerObject $script:serverObject -Name $script:testLoginName
            $grantedPermissions | Should -Not -BeNullOrEmpty
            $grantedPermissions.PermissionType.ConnectSql | Should -BeTrue
            $grantedPermissions.PermissionType.ViewServerState | Should -BeTrue
        }

        It 'Should accept ServerObject from pipeline' {
            $permissions = @(
                [ServerPermission] @{
                    State = 'Grant'
                    Permission = @('ConnectSql')
                }
            )

            { $script:serverObject | New-SqlDscServerPermission -Name $script:testLoginName -Permission $permissions -Force } |
                Should -Not -Throw

            # Verify the permission was granted
            $grantedPermissions = Get-SqlDscServerPermission -ServerObject $script:serverObject -Name $script:testLoginName
            $grantedPermissions | Should -Not -BeNullOrEmpty
            $grantedPermissions.PermissionType.ConnectSql | Should -BeTrue
        }
    }
}

Describe 'Test-SqlDscServerPermission Integration Tests' -Tag 'Integration' {
    Context 'When testing server permissions' {
        BeforeEach {
            # Grant a known permission for testing
            $permissions = @(
                [ServerPermission] @{
                    State = 'Grant'
                    Permission = @('ConnectSql')
                }
            )
            New-SqlDscServerPermission -ServerObject $script:serverObject -Name $script:testLoginName -Permission $permissions -Force
        }

        It 'Should return true when permissions match desired state' {
            $permissions = @(
                [ServerPermission] @{
                    State = 'Grant'
                    Permission = @('ConnectSql')
                }
                [ServerPermission] @{
                    State = 'GrantWithGrant'
                    Permission = @()
                }
                [ServerPermission] @{
                    State = 'Deny'
                    Permission = @()
                }
            )

            $result = Test-SqlDscServerPermission -ServerObject $script:serverObject -Name $script:testLoginName -Permission $permissions

            $result | Should -BeTrue
        }

        It 'Should return false when permissions do not match desired state' {
            $permissions = @(
                [ServerPermission] @{
                    State = 'Grant'
                    Permission = @('ViewServerState')
                }
                [ServerPermission] @{
                    State = 'GrantWithGrant'
                    Permission = @()
                }
                [ServerPermission] @{
                    State = 'Deny'
                    Permission = @()
                }
            )

            $result = Test-SqlDscServerPermission -ServerObject $script:serverObject -Name $script:testLoginName -Permission $permissions

            $result | Should -BeFalse
        }

        It 'Should accept ServerObject from pipeline' {
            $permissions = @(
                [ServerPermission] @{
                    State = 'Grant'
                    Permission = @('ConnectSql')
                }
                [ServerPermission] @{
                    State = 'GrantWithGrant'
                    Permission = @()
                }
                [ServerPermission] @{
                    State = 'Deny'
                    Permission = @()
                }
            )

            $result = $script:serverObject | Test-SqlDscServerPermission -Name $script:testLoginName -Permission $permissions

            $result | Should -BeTrue
        }
    }
}

Describe 'Remove-SqlDscServerPermission Integration Tests' -Tag 'Integration' {
    Context 'When removing server permissions' {
        BeforeEach {
            # Grant permissions to remove
            $permissions = @(
                [ServerPermission] @{
                    State = 'Grant'
                    Permission = @('ConnectSql', 'ViewServerState')
                }
            )
            New-SqlDscServerPermission -ServerObject $script:serverObject -Name $script:testLoginName -Permission $permissions -Force
        }

        It 'Should remove ConnectSql permission successfully' {
            $permissions = @(
                [ServerPermission] @{
                    State = 'Grant'
                    Permission = @('ConnectSql')
                }
            )

            { Remove-SqlDscServerPermission -ServerObject $script:serverObject -Name $script:testLoginName -Permission $permissions -Force } |
                Should -Not -Throw

            # Verify the permission was removed
            $remainingPermissions = Get-SqlDscServerPermission -ServerObject $script:serverObject -Name $script:testLoginName -ErrorAction 'SilentlyContinue'
            if ($remainingPermissions)
            {
                $remainingPermissions.PermissionType.ConnectSql | Should -BeFalse
                # ViewServerState should still be there
                $remainingPermissions.PermissionType.ViewServerState | Should -BeTrue
            }
        }

        It 'Should remove multiple permissions successfully' {
            $permissions = @(
                [ServerPermission] @{
                    State = 'Grant'
                    Permission = @('ConnectSql', 'ViewServerState')
                }
            )

            { Remove-SqlDscServerPermission -ServerObject $script:serverObject -Name $script:testLoginName -Permission $permissions -Force } |
                Should -Not -Throw

            # Verify the permissions were removed (should return no permissions or all false)
            $remainingPermissions = Get-SqlDscServerPermission -ServerObject $script:serverObject -Name $script:testLoginName -ErrorAction 'SilentlyContinue'
            if ($remainingPermissions)
            {
                $remainingPermissions.PermissionType.ConnectSql | Should -BeFalse
                $remainingPermissions.PermissionType.ViewServerState | Should -BeFalse
            }
        }

        It 'Should accept ServerObject from pipeline' {
            $permissions = @(
                [ServerPermission] @{
                    State = 'Grant'
                    Permission = @('ConnectSql')
                }
            )

            { $script:serverObject | Remove-SqlDscServerPermission -Name $script:testLoginName -Permission $permissions -Force } |
                Should -Not -Throw

            # Verify the permission was removed
            $remainingPermissions = Get-SqlDscServerPermission -ServerObject $script:serverObject -Name $script:testLoginName -ErrorAction 'SilentlyContinue'
            if ($remainingPermissions)
            {
                $remainingPermissions.PermissionType.ConnectSql | Should -BeFalse
            }
        }
    }
}
