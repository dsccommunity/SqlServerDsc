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
    $script:moduleName = 'SqlServerDsc'

    Import-Module -Name $script:moduleName -Force -ErrorAction 'Stop'
}

Describe 'Grant-SqlDscServerPermission' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        # Check if there is a CI database instance to use for testing
        $script:sqlServerInstanceName = $env:SqlServerInstanceName

        if (-not $script:sqlServerInstanceName)
        {
            $script:sqlServerInstanceName = 'DSCSQLTEST'
        }

        # Get a computer name that will work in the CI environment
        $script:computerName = Get-ComputerName

        Write-Verbose -Message ('Integration tests will run using computer name ''{0}'' and instance name ''{1}''.' -f $script:computerName, $script:sqlServerInstanceName) -Verbose

        $script:serverObject = Connect-SqlDscDatabaseEngine -ServerName $script:computerName -InstanceName $script:sqlServerInstanceName -Force

        # Use existing persistent principals created by earlier integration tests
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
        # Keep the persistent principals for other tests to use
        # Do not remove $script:testLoginName and $script:testRoleName as they are managed by New-SqlDscLogin and New-SqlDscRole tests

        Disconnect-SqlDscDatabaseEngine -ServerObject $script:serverObject
    }

    Context 'When granting server permissions to login' {
        BeforeEach {
            # Get the login object for testing
            $script:loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -ErrorAction 'Stop'

            Revoke-SqlDscServerPermission -Login $script:loginObject -Permission 'ViewServerState' -Force -ErrorAction 'SilentlyContinue'
            Revoke-SqlDscServerPermission -Login $script:loginObject -Permission 'ViewAnyDatabase' -Force -ErrorAction 'SilentlyContinue'
            Revoke-SqlDscServerPermission -Login $script:loginObject -Permission 'ViewAnyDefinition' -Force -ErrorAction 'SilentlyContinue'
        }

        It 'Should grant ViewServerState permission successfully' {
            $null = Grant-SqlDscServerPermission -Login $script:loginObject -Permission @('ViewServerState') -Force -ErrorAction 'Stop'

            # Verify the permission was granted
            $grantedPermissions = Get-SqlDscServerPermission -ServerObject $script:serverObject -Name $script:testLoginName -ErrorAction 'Stop'
            $grantedPermissions | Should -Not -BeNullOrEmpty
            $grantedPermissions.PermissionType.ViewServerState | Should -BeTrue
        }

        It 'Should grant multiple permissions successfully' {
            $null = Grant-SqlDscServerPermission -Login $script:loginObject -Permission @('ViewServerState', 'ViewAnyDatabase') -Force -ErrorAction 'Stop'

            # Verify the permissions were granted
            $grantedPermissions = Get-SqlDscServerPermission -ServerObject $script:serverObject -Name $script:testLoginName -ErrorAction 'Stop'
            $grantedPermissions | Should -Not -BeNullOrEmpty
            $grantedPermissions.PermissionType.ViewServerState | Should -BeTrue
            $grantedPermissions.PermissionType.ViewAnyDatabase | Should -BeTrue
        }

        It 'Should grant permissions with WithGrant option' {
            $null = Grant-SqlDscServerPermission -Login $script:loginObject -Permission @('ViewServerState') -WithGrant -Force -ErrorAction 'Stop'

            # Verify the permission was granted with grant option
            $grantedPermissions = Get-SqlDscServerPermission -ServerObject $script:serverObject -Name $script:testLoginName -ErrorAction 'Stop'
            $grantedPermissions | Should -Not -BeNullOrEmpty
            $grantWithGrantPermission = $grantedPermissions | Where-Object { $_.PermissionState -eq 'GrantWithGrant' }
            $grantWithGrantPermission.PermissionType.ViewServerState | Should -BeTrue
        }

        It 'Should accept Login from pipeline' {
            $null = $script:loginObject | Grant-SqlDscServerPermission -Permission @('ViewAnyDefinition') -Force -ErrorAction 'Stop'

            # Verify the permission was granted
            $grantedPermissions = Get-SqlDscServerPermission -ServerObject $script:serverObject -Name $script:testLoginName -ErrorAction 'Stop'
            $grantedPermissions | Should -Not -BeNullOrEmpty
            $grantedPermissions.PermissionType.ViewAnyDefinition | Should -BeTrue
        }
    }

    Context 'When granting server permissions to role' {
        BeforeEach {
            # Get the role object for testing
            $script:roleObject = Get-SqlDscRole -ServerObject $script:serverObject -Name $script:testRoleName -ErrorAction 'Stop'

            Revoke-SqlDscServerPermission -ServerRole $roleObject -Permission 'ViewServerState' -Force -ErrorAction 'SilentlyContinue'
        }

        It 'Should grant ViewServerState permission to role successfully' {
            $roleObject = Get-SqlDscRole -ServerObject $script:serverObject -Name $script:testRoleName -ErrorAction 'Stop'

            $null = Grant-SqlDscServerPermission -ServerRole $roleObject -Permission @('ViewServerState') -Force -ErrorAction 'Stop'

            # Verify the permission was granted
            $grantedPermissions = Get-SqlDscServerPermission -ServerObject $script:serverObject -Name $script:testRoleName -ErrorAction 'Stop'
            $grantedPermissions | Should -Not -BeNullOrEmpty
            $grantedPermissions.PermissionType.ViewServerState | Should -BeTrue
        }

        It 'Should grant persistent CreateEndpoint permission to role for other tests' {
            $roleObject = Get-SqlDscRole -ServerObject $script:serverObject -Name $script:testRoleName -ErrorAction 'Stop'

            $null = Grant-SqlDscServerPermission -ServerRole $roleObject -Permission @('CreateEndpoint') -Force -ErrorAction 'Stop'

            # Verify the permission was granted - this permission will remain persistent for other integration tests
            $grantedPermissions = Get-SqlDscServerPermission -ServerObject $script:serverObject -Name $script:testRoleName -ErrorAction 'Stop'
            $grantedPermissions | Should -Not -BeNullOrEmpty
            $grantedPermissions.PermissionType.PermissionState | Should -Be 'Grant'
            $grantedPermissions.PermissionType.CreateEndpoint | Should -BeTrue
        }
    }
}
