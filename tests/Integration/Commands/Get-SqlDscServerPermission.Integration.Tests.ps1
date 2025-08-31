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

    # Use persistent test login and role created by earlier integration tests
    $script:testLoginName = 'IntegrationTestSqlLogin'
    $script:testRoleName = 'SqlDscIntegrationTestRole_Persistent'

    # Verify the persistent principals exist (should be created by New-SqlDscLogin and New-SqlDscRole integration tests)
    $existingLogin = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -ErrorAction 'SilentlyContinue'
    if (-not $existingLogin)
    {
        throw ('Test login {0} does not exist. Please run New-SqlDscLogin integration tests first to create persistent test principals.' -f $script:testLoginName)
    }

    $existingRole = Get-SqlDscRole -ServerObject $script:serverObject -Name $script:testRoleName -ErrorAction 'SilentlyContinue'
    if (-not $existingRole)
    {
        throw ('Test role {0} does not exist. Please run New-SqlDscRole integration tests first to create persistent test principals.' -f $script:testRoleName)
    }
}

AfterAll {
    Disconnect-SqlDscDatabaseEngine -ServerObject $script:serverObject

    $PSDefaultParameterValues.Remove('*:ServerName')
    $PSDefaultParameterValues.Remove('*:InstanceName')
    $PSDefaultParameterValues.Remove('*:ErrorAction')
}

Describe 'Get-SqlDscServerPermission Integration Tests' -Tag 'Integration' {
    Context 'When getting server permissions for login' {
        It 'Should return permissions for existing login' {
            $result = Get-SqlDscServerPermission -ServerObject $script:serverObject -Name $script:testLoginName

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType '[Microsoft.SqlServer.Management.Smo.ServerPermissionInfo]'
            # Should have at least the persistent ConnectSql permission
            $grantedPermissions = $result | Where-Object { $_.PermissionState -eq 'Grant' }
            $grantedPermissions | Should -Not -BeNullOrEmpty
            $grantedPermissions.PermissionType.ConnectSql | Should -BeTrue
        }

        It 'Should accept ServerObject from pipeline' {
            $result = $script:serverObject | Get-SqlDscServerPermission -Name $script:testLoginName

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType '[Microsoft.SqlServer.Management.Smo.ServerPermissionInfo]'
        }

        It 'Should throw error for non-existent login' {
            {
                Get-SqlDscServerPermission -ServerObject $script:serverObject -Name 'NonExistentLogin' -ErrorAction 'Stop'
            } | Should -Throw
        }
    }

    Context 'When getting server permissions for role' {
        It 'Should return permissions for existing role' {
            $result = Get-SqlDscServerPermission -ServerObject $script:serverObject -Name $script:testRoleName

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType '[Microsoft.SqlServer.Management.Smo.ServerPermissionInfo]'
            # Should have at least the persistent ConnectSql permission
            $grantedPermissions = $result | Where-Object { $_.PermissionState -eq 'Grant' }
            $grantedPermissions | Should -Not -BeNullOrEmpty
            $grantedPermissions.PermissionType.ConnectSql | Should -BeTrue
        }

        It 'Should accept ServerObject from pipeline for role' {
            $result = $script:serverObject | Get-SqlDscServerPermission -Name $script:testRoleName

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType '[Microsoft.SqlServer.Management.Smo.ServerPermissionInfo]'
        }
    }

    Context 'When getting specific permission states' {
        BeforeAll {
            # Get the login object for testing
            $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName

            # Grant additional permissions for testing
            Grant-SqlDscServerPermission -Login $loginObject -Permission @('ViewServerState') -Force

            # Grant with grant permissions
            Grant-SqlDscServerPermission -Login $loginObject -Permission @('ViewAnyDatabase') -WithGrant -Force

            # Deny some permissions
            Deny-SqlDscServerPermission -Login $loginObject -Permission @('ViewAnyDefinition') -Force
        }

        AfterAll {
            # Clean up test permissions but keep persistent ones
            $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName

            Revoke-SqlDscServerPermission -Login $loginObject -Permission @('ViewServerState') -Force -ErrorAction 'SilentlyContinue'
            Revoke-SqlDscServerPermission -Login $loginObject -Permission @('ViewAnyDatabase') -WithGrant -Force -ErrorAction 'SilentlyContinue'
            Revoke-SqlDscServerPermission -Login $loginObject -Permission @('ViewAnyDefinition') -Force -ErrorAction 'SilentlyContinue'
        }

        It 'Should return grant permissions' {
            $result = Get-SqlDscServerPermission -ServerObject $script:serverObject -Name $script:testLoginName

            $grantedPermissions = $result | Where-Object { $_.PermissionState -eq 'Grant' }
            $grantedPermissions | Should -Not -BeNullOrEmpty
            $grantedPermissions.PermissionType.ConnectSql | Should -BeTrue
            $grantedPermissions.PermissionType.ViewServerState | Should -BeTrue
        }

        It 'Should return grant with grant permissions' {
            $result = Get-SqlDscServerPermission -ServerObject $script:serverObject -Name $script:testLoginName

            $grantWithGrantPermissions = $result | Where-Object { $_.PermissionState -eq 'GrantWithGrant' }
            $grantWithGrantPermissions | Should -Not -BeNullOrEmpty
            $grantWithGrantPermissions.PermissionType.ViewAnyDatabase | Should -BeTrue
        }

        It 'Should return deny permissions' {
            $result = Get-SqlDscServerPermission -ServerObject $script:serverObject -Name $script:testLoginName

            $deniedPermissions = $result | Where-Object { $_.PermissionState -eq 'Deny' }
            $deniedPermissions | Should -Not -BeNullOrEmpty
            $deniedPermissions.PermissionType.ViewAnyDefinition | Should -BeTrue
        }
    }
}
