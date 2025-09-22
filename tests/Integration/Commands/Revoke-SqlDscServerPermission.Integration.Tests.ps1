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

Describe 'Revoke-SqlDscServerPermission' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        # Note: SQL Server service is already running from Install-SqlDscServer test for performance optimization

        $script:mockInstanceName = 'DSCSQLTEST'

        $mockSqlAdministratorUserName = 'SqlAdmin' # Using computer name as NetBIOS name throw exception.
        $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

        $script:mockSqlAdminCredential = [System.Management.Automation.PSCredential]::new($mockSqlAdministratorUserName, $mockSqlAdministratorPassword)

        $script:serverObject = Connect-SqlDscDatabaseEngine -InstanceName $script:mockInstanceName -Credential $script:mockSqlAdminCredential

        # Use persistent test login and role created by earlier integration tests
        $script:testLoginName = 'IntegrationTestSqlLogin'
        $script:testRoleName = 'SqlDscIntegrationTestRole_Persistent'
    }

    AfterAll {
        Disconnect-SqlDscDatabaseEngine -ServerObject $script:serverObject

        # Note: SQL Server service is left running for subsequent tests for performance optimization
    }

    Context 'When revoking server permissions from login' {
        BeforeEach {
            # Grant a known permission for testing
            $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -ErrorAction 'Stop'
            $null = Grant-SqlDscServerPermission -Login $loginObject -Permission @('ViewServerState') -Force -ErrorAction 'Stop'
        }

        It 'Should revoke permissions' {
            $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -ErrorAction 'Stop'

            $null = Revoke-SqlDscServerPermission -Login $loginObject -Permission @('ViewServerState') -Force -ErrorAction 'Stop'
        }

        It 'Should show the permissions as no longer granted' {
            $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -ErrorAction 'Stop'

            # First grant the permission
            $null = Grant-SqlDscServerPermission -Login $loginObject -Permission @('ViewAnyDatabase') -Force -ErrorAction 'Stop'

            # Then revoke it
            $null = Revoke-SqlDscServerPermission -Login $loginObject -Permission @('ViewAnyDatabase') -Force -ErrorAction 'Stop'

            # Test that it's no longer granted
            $result = Test-SqlDscServerPermission -Login $loginObject -Grant -Permission @('ViewAnyDatabase') -ErrorAction 'Stop'

            $result | Should -BeFalse
        }

        It 'Should accept Login from pipeline' {
            $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -ErrorAction 'Stop'

            # First grant a permission to revoke
            $null = Grant-SqlDscServerPermission -Login $loginObject -Permission @('ViewAnyDefinition') -Force -ErrorAction 'Stop'

            $null = $loginObject | Revoke-SqlDscServerPermission -Permission @('ViewAnyDefinition') -Force -ErrorAction 'Stop'

            # Verify the permission was revoked
            $result = Test-SqlDscServerPermission -Login $loginObject -Grant -Permission @('ViewAnyDefinition') -ErrorAction 'Stop'
            $result | Should -BeFalse
        }
    }

    Context 'When revoking server permissions from role' {
        BeforeEach {
            # Grant a known permission for testing
            $roleObject = Get-SqlDscRole -ServerObject $script:serverObject -Name $script:testRoleName -ErrorAction 'Stop'
            $null = Grant-SqlDscServerPermission -ServerRole $roleObject -Permission @('ViewServerState') -Force -ErrorAction 'Stop'
        }

        It 'Should revoke permissions from role' {
            $roleObject = Get-SqlDscRole -ServerObject $script:serverObject -Name $script:testRoleName -ErrorAction 'Stop'

            $null = Revoke-SqlDscServerPermission -ServerRole $roleObject -Permission @('ViewServerState') -Force -ErrorAction 'Stop'

            # Test that it's no longer granted
            $result = Test-SqlDscServerPermission -ServerRole $roleObject -Grant -Permission @('ViewServerState') -ErrorAction 'Stop'

            $result | Should -BeFalse
        }
    }
}
