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

    # Do not use -Force. Doing so, or unloading the module in AfterAll, causes
    # PowerShell class types to get new identities, breaking type comparisons.
    Import-Module -Name $script:moduleName -ErrorAction 'Stop'
}

Describe 'Grant-SqlDscServerPermission' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022', 'Integration_SQL2025') {
    BeforeAll {
        $script:mockInstanceName = 'DSCSQLTEST'

        $mockSqlAdministratorUserName = 'SqlAdmin' # Using computer name as NetBIOS name throw exception.
        $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

        $script:mockSqlAdminCredential = [System.Management.Automation.PSCredential]::new($mockSqlAdministratorUserName, $mockSqlAdministratorPassword)

        $script:serverObject = Connect-SqlDscDatabaseEngine -InstanceName $script:mockInstanceName -Credential $script:mockSqlAdminCredential -ErrorAction 'Stop'

        # Use existing persistent principals created by earlier integration tests
        $script:testLoginName = 'IntegrationTestSqlLogin'
        $script:testRoleName = 'SqlDscIntegrationTestRole_Persistent'
    }

    AfterAll {
        Disconnect-SqlDscDatabaseEngine -ServerObject $script:serverObject
    }

    Context 'When granting server permissions to login' {
        BeforeEach {
            # Get the login object for testing
            $script:loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -ErrorAction 'Stop'

            Revoke-SqlDscServerPermission -Login $script:loginObject -Permission 'ViewServerState' -Force -ErrorAction 'SilentlyContinue'
            Revoke-SqlDscServerPermission -Login $script:loginObject -Permission 'ViewAnyDatabase' -Force -ErrorAction 'SilentlyContinue'
            Revoke-SqlDscServerPermission -Login $script:loginObject -Permission 'ViewAnyDefinition' -Force -ErrorAction 'SilentlyContinue'
            Revoke-SqlDscServerPermission -Login $script:loginObject -Permission 'CreateAnyDatabase' -WithGrant -Force -ErrorAction 'SilentlyContinue'
        }

        It 'Should grant ViewServerState permission successfully' {
            $null = Grant-SqlDscServerPermission -Login $script:loginObject -Permission @('ViewServerState') -Force -ErrorAction 'Stop'

            # Verify the permission was granted
            $permission = Get-SqlDscServerPermission -ServerObject $script:serverObject -Name $script:testLoginName -ErrorAction 'Stop'

            $permission | Should -Not -BeNullOrEmpty
            $grantedPermissions = $permission | Where-Object { $_.PermissionState -eq 'Grant' }

            $expectedPermission = $grantedPermissions | Where-Object { $_.PermissionType.ViewServerState -eq $true }
            $expectedPermission | Should -HaveCount 1
            $expectedPermission.PermissionType.ViewServerState | Should -BeTrue
        }

        It 'Should grant multiple permissions successfully' {
            $null = Grant-SqlDscServerPermission -Login $script:loginObject -Permission @('ViewServerState', 'ViewAnyDatabase') -Force -ErrorAction 'Stop'

            # Verify the permissions were granted
            $permission = Get-SqlDscServerPermission -ServerObject $script:serverObject -Name $script:testLoginName -ErrorAction 'Stop'

            $permission | Should -Not -BeNullOrEmpty
            $grantedPermissions = $permission | Where-Object { $_.PermissionState -eq 'Grant' }

            $expectedPermission = $grantedPermissions | Where-Object { $_.PermissionType.ViewServerState -eq $true }
            $expectedPermission | Should -HaveCount 1
            $expectedPermission.PermissionType.ViewServerState | Should -BeTrue

            $expectedPermission = $grantedPermissions | Where-Object { $_.PermissionType.ViewAnyDatabase -eq $true }
            $expectedPermission | Should -HaveCount 1
            $expectedPermission.PermissionType.ViewAnyDatabase | Should -BeTrue
        }

        It 'Should grant permissions with WithGrant option' {
            $null = Grant-SqlDscServerPermission -Login $script:loginObject -Permission @('CreateAnyDatabase') -WithGrant -Force -ErrorAction 'Stop'

            # Verify the permission was granted with grant option
            $permission = Get-SqlDscServerPermission -ServerObject $script:serverObject -Name $script:testLoginName -ErrorAction 'Stop'

            $permission | Should -Not -BeNullOrEmpty
            $grantedPermissions = $permission | Where-Object { $_.PermissionState -eq 'GrantWithGrant' }

            $expectedPermission = $grantedPermissions | Where-Object { $_.PermissionType.CreateAnyDatabase -eq $true }
            $expectedPermission | Should -HaveCount 1
            $expectedPermission.PermissionType.CreateAnyDatabase | Should -BeTrue
        }

        It 'Should accept Login from pipeline' {
            $null = $script:loginObject | Grant-SqlDscServerPermission -Permission @('ViewAnyDefinition') -Force -ErrorAction 'Stop'

            # Verify the permission was granted
            $permission = Get-SqlDscServerPermission -ServerObject $script:serverObject -Name $script:testLoginName -ErrorAction 'Stop'

            $permission | Should -Not -BeNullOrEmpty
            $grantedPermissions = $permission | Where-Object { $_.PermissionState -eq 'Grant' }

            $expectedPermission = $grantedPermissions | Where-Object { $_.PermissionType.ViewAnyDefinition -eq $true }
            $expectedPermission | Should -HaveCount 1
            $expectedPermission.PermissionType.ViewAnyDefinition | Should -BeTrue
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
            $permission = Get-SqlDscServerPermission -ServerObject $script:serverObject -Name $script:testRoleName -ErrorAction 'Stop'

            $permission | Should -Not -BeNullOrEmpty
            $grantedPermissions = $permission | Where-Object { $_.PermissionState -eq 'Grant' }

            $expectedPermission = $grantedPermissions | Where-Object { $_.PermissionType.ViewServerState -eq $true }
            $expectedPermission | Should -HaveCount 1
            $expectedPermission.PermissionType.ViewServerState | Should -BeTrue
        }

        It 'Should grant persistent CreateEndpoint permission to role for other tests' {
            $roleObject = Get-SqlDscRole -ServerObject $script:serverObject -Name $script:testRoleName -ErrorAction 'Stop'

            $null = Grant-SqlDscServerPermission -ServerRole $roleObject -Permission @('CreateEndpoint') -Force -ErrorAction 'Stop'

            # Verify the permission was granted - this permission will remain persistent for other integration tests
            $permission = Get-SqlDscServerPermission -ServerObject $script:serverObject -Name $script:testRoleName -ErrorAction 'Stop'

            $permission | Should -Not -BeNullOrEmpty
            $grantedPermissions = $permission | Where-Object { $_.PermissionState -eq 'Grant' }

            $expectedPermission = $grantedPermissions | Where-Object { $_.PermissionType.CreateEndpoint -eq $true }
            $expectedPermission | Should -HaveCount 1
            $expectedPermission.PermissionType.CreateEndpoint | Should -BeTrue
        }
    }
}
