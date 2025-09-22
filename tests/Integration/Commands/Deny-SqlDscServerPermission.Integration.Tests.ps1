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

    Import-Module -Name $script:moduleName -Force -ErrorAction 'Stop'
}

Describe 'Deny-SqlDscServerPermission' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        # Note: SQL Server service is already running from Install-SqlDscServer test for performance optimization

        $script:mockInstanceName = 'DSCSQLTEST'

        $mockSqlAdministratorUserName = 'SqlAdmin' # Using computer name as NetBIOS name throw exception.
        $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

        $script:mockSqlAdminCredential = [System.Management.Automation.PSCredential]::new($mockSqlAdministratorUserName, $mockSqlAdministratorPassword)

        $script:serverObject = Connect-SqlDscDatabaseEngine -InstanceName $script:mockInstanceName -Credential $script:mockSqlAdminCredential -ErrorAction 'Stop'

        # Use persistent test login and role created by earlier integration tests
        $script:testLoginName = 'IntegrationTestSqlLogin'
        $script:testRoleName = 'SqlDscIntegrationTestRole_Persistent'
    }

    AfterAll {
        Disconnect-SqlDscDatabaseEngine -ServerObject $script:serverObject

        # Note: SQL Server service is left running for subsequent tests for performance optimization
    }

    Context 'When denying server permissions to login' {
        BeforeEach {
            $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -ErrorAction 'Stop'

            Revoke-SqlDscServerPermission -Login $loginObject -Permission 'ViewServerState' -Force -ErrorAction 'SilentlyContinue'
            Revoke-SqlDscServerPermission -Login $loginObject -Permission 'ViewAnyDefinition' -Force -ErrorAction 'SilentlyContinue'
        }

        It 'Should deny ViewServerState permission' {
            $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -ErrorAction 'Stop'

            $null = Deny-SqlDscServerPermission -Login $loginObject -Permission @('ViewServerState') -Force -ErrorAction 'Stop'
        }

        It 'Should show the permissions as denied' {
            $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -ErrorAction 'Stop'

            # First deny the permission
            $null = Deny-SqlDscServerPermission -Login $loginObject -Permission @('ViewAnyDatabase') -Force -ErrorAction 'Stop'

            # Then test if it's denied
            $result = Test-SqlDscServerPermission -Login $loginObject -Deny -Permission @('ViewAnyDatabase') -ErrorAction 'Stop'

            $result | Should -BeTrue
        }

        It 'Should accept Login from pipeline' {
            $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -ErrorAction 'Stop'

            $null = $loginObject | Deny-SqlDscServerPermission -Permission @('ViewAnyDefinition') -Force -ErrorAction 'Stop'

            # Verify the permission was denied
            $result = Test-SqlDscServerPermission -Login $loginObject -Deny -Permission @('ViewAnyDefinition') -ErrorAction 'Stop'
            $result | Should -BeTrue
        }
    }

    Context 'When denying server permissions to role' {
        BeforeEach {
            $roleObject = Get-SqlDscRole -ServerObject $script:serverObject -Name $script:testRoleName -ErrorAction 'Stop'

            Revoke-SqlDscServerPermission -ServerRole $roleObject -Permission 'ViewServerState' -Force -ErrorAction 'SilentlyContinue'
        }

        It 'Should deny ViewServerState permission to role' {
            $roleObject = Get-SqlDscRole -ServerObject $script:serverObject -Name $script:testRoleName -ErrorAction 'Stop'

            $null = Deny-SqlDscServerPermission -ServerRole $roleObject -Permission @('ViewServerState') -Force -ErrorAction 'Stop'

            # Verify the permission was denied
            $result = Test-SqlDscServerPermission -ServerRole $roleObject -Deny -Permission @('ViewServerState') -ErrorAction 'Stop'
            $result | Should -BeTrue
        }

        It 'Should deny persistent AlterTrace permission to login for other tests' {
            $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -ErrorAction 'Stop'

            $null = Deny-SqlDscServerPermission -Login $loginObject -Permission @('AlterTrace') -Force -ErrorAction 'Stop'

            # Verify the permission was denied - this denial will remain persistent for other integration tests
            $result = Test-SqlDscServerPermission -Login $loginObject -Deny -Permission @('AlterTrace') -ErrorAction 'Stop'
            $result | Should -BeTrue
        }

        It 'Should accept ServerRole from pipeline' {
            $roleObject = Get-SqlDscRole -ServerObject $script:serverObject -Name $script:testRoleName -ErrorAction 'Stop'

            $null = $roleObject | Deny-SqlDscServerPermission -Permission @('ViewServerState') -Force -ErrorAction 'Stop'

            $result = Test-SqlDscServerPermission -ServerRole $roleObject -Deny -Permission @('ViewServerState') -ErrorAction 'Stop'
            $result | Should -BeTrue
        }
    }
}
