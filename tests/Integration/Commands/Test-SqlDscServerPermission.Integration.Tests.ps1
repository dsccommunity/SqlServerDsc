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

Describe 'Test-SqlDscServerPermission' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022', 'Integration_SQL2025') {
    BeforeAll {
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
    }

    Context 'When testing server permissions for login' {
        BeforeAll {
            # Set up known permissions for testing
            $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -ErrorAction 'Stop'
            $null = Grant-SqlDscServerPermission -Login $loginObject -Permission @('ViewServerState') -Force -ErrorAction 'Stop'
        }

        AfterAll {
            $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -ErrorAction 'Stop'
            $null = Revoke-SqlDscServerPermission -Login $loginObject -Permission @('ViewServerState') -Force -ErrorAction 'SilentlyContinue'
        }

        It 'Should return true when permissions match desired state' {
            $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -ErrorAction 'Stop'

            $result = Test-SqlDscServerPermission -Login $loginObject -Grant -Permission @('ConnectSql', 'ViewServerState') -ErrorAction 'Stop'

            $result | Should -BeTrue
        }

        It 'Should return false when permissions do not match desired state' {
            $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -ErrorAction 'Stop'

            $result = Test-SqlDscServerPermission -Login $loginObject -Grant -Permission @('AlterAnyDatabase') -ErrorAction 'Stop'

            $result | Should -BeFalse
        }

        It 'Should accept Login object from pipeline' {
            $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -ErrorAction 'Stop'

            $result = $loginObject | Test-SqlDscServerPermission -Grant -Permission @('ConnectSql', 'ViewServerState') -ErrorAction 'Stop'

            $result | Should -BeTrue
        }

        It 'Should return true when only testing specific grant permission that exists' {
            $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -ErrorAction 'Stop'

            $result = Test-SqlDscServerPermission -Login $loginObject -Grant -Permission @('ConnectSql') -ErrorAction 'Stop'

            $result | Should -BeTrue
        }

        It 'Should return false when testing for permission that does not exist' {
            $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -ErrorAction 'Stop'

            $result = Test-SqlDscServerPermission -Login $loginObject -Grant -Permission @('AlterAnyCredential') -ErrorAction 'Stop'

            $result | Should -BeFalse
        }

        # cSpell:ignore securityadmin
        It 'Should return true when testing for empty permission collection on principal with no additional permissions' {
            # Get the built-in securityadmin server role which should have no explicit permissions
            $securityAdminRole = Get-SqlDscRole -ServerObject $script:serverObject -Name 'securityadmin' -ErrorAction 'Stop'

            # Test that empty permission collection returns true when no permissions are set
            $result = Test-SqlDscServerPermission -ServerRole $securityAdminRole -Grant -Permission @() -ErrorAction 'Stop'

            $result | Should -BeTrue
        }

        It 'Should return false when using ExactMatch and additional permissions exist' {
            $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -ErrorAction 'Stop'

            # Test with ExactMatch - should fail because ViewServerState and ViewAnyDefinition is also granted
            $result = Test-SqlDscServerPermission -Login $loginObject -Grant -Permission @('ConnectSql') -ExactMatch -ErrorAction 'Stop'

            $result | Should -BeFalse
        }

        It 'Should return true when using ExactMatch and permissions exactly match' {
            $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -ErrorAction 'Stop'

            # Test with ExactMatch - should pass because both ConnectSql, ViewAnyDefinition and ViewServerState are granted
            $result = Test-SqlDscServerPermission -Login $loginObject -Grant -Permission @('ConnectSql', 'ViewServerState', 'ViewAnyDefinition') -ExactMatch -ErrorAction 'Stop'

            $result | Should -BeTrue
        }
    }

    Context 'When testing server permissions for role' {
        BeforeAll {
            # Set up known permissions for testing
            $roleObject = Get-SqlDscRole -ServerObject $script:serverObject -Name $script:testRoleName -ErrorAction 'Stop'
            $null = Grant-SqlDscServerPermission -ServerRole $roleObject -Permission @('ConnectSql', 'ViewServerState', 'CreateAnyDatabase') -Force -ErrorAction 'Stop'
        }

        AfterAll {
            $roleObject = Get-SqlDscRole -ServerObject $script:serverObject -Name $script:testRoleName -ErrorAction 'Stop'
            $null = Revoke-SqlDscServerPermission -ServerRole $roleObject -Permission @('ConnectSql', 'ViewServerState', 'CreateAnyDatabase') -Force -ErrorAction 'SilentlyContinue'
        }

        It 'Should return true when role permissions match desired state' {
            $roleObject = Get-SqlDscRole -ServerObject $script:serverObject -Name $script:testRoleName -ErrorAction 'Stop'

            $result = Test-SqlDscServerPermission -ServerRole $roleObject -Grant -Permission @('ConnectSql', 'ViewServerState') -ErrorAction 'Stop'

            $result | Should -BeTrue
        }

        It 'Should return true when role permissions exact match desired state' {
            $roleObject = Get-SqlDscRole -ServerObject $script:serverObject -Name $script:testRoleName -ErrorAction 'Stop'

            $result = Test-SqlDscServerPermission -ServerRole $roleObject -Grant -Permission @('ConnectSql', 'ViewServerState', 'CreateEndpoint', 'CreateAnyDatabase') -ExactMatch -ErrorAction 'Stop'

            $result | Should -BeTrue
        }

        It 'Should return false when role permissions do not match desired state' {
            $roleObject = Get-SqlDscRole -ServerObject $script:serverObject -Name $script:testRoleName -ErrorAction 'Stop'

            $result = Test-SqlDscServerPermission -ServerRole $roleObject -Grant -Permission @('AlterAnyEndpoint') -ErrorAction 'Stop'

            $result | Should -BeFalse
        }

        It 'Should return false when role permissions do not exact match desired state' {
            $roleObject = Get-SqlDscRole -ServerObject $script:serverObject -Name $script:testRoleName -ErrorAction 'Stop'

            $result = Test-SqlDscServerPermission -ServerRole $roleObject -Grant -Permission @('ViewServerState') -ExactMatch -ErrorAction 'Stop'

            $result | Should -BeFalse
        }

        It 'Should accept ServerRole object from pipeline' {
            $roleObject = Get-SqlDscRole -ServerObject $script:serverObject -Name $script:testRoleName -ErrorAction 'Stop'

            $result = $roleObject | Test-SqlDscServerPermission -Grant -Permission @('ConnectSql', 'ViewServerState') -ErrorAction 'Stop'

            $result | Should -BeTrue
        }
    }

    Context 'When testing deny permissions' {
        BeforeAll {
            # Set up denied permissions for testing
            $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -ErrorAction 'Stop'
            $null = Deny-SqlDscServerPermission -Login $loginObject -Permission @('ViewAnyDefinition') -Force -ErrorAction 'Stop'
        }

        AfterAll {
            $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -ErrorAction 'Stop'
            $null = Revoke-SqlDscServerPermission -Login $loginObject -Permission @('ViewAnyDefinition') -Force -ErrorAction 'SilentlyContinue'
        }

        It 'Should return true when testing for denied permission that exists' {
            $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -ErrorAction 'Stop'

            $result = Test-SqlDscServerPermission -Login $loginObject -Deny -Permission @('ViewAnyDefinition') -ErrorAction 'Stop'

            $result | Should -BeTrue
        }

        It 'Should return false when testing for denied permission that does not exist' {
            $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -ErrorAction 'Stop'

            $result = Test-SqlDscServerPermission -Login $loginObject -Deny -Permission @('AlterServerState') -ErrorAction 'Stop'

            $result | Should -BeFalse
        }
    }

    Context 'When testing grant with grant permissions' {
        BeforeAll {
            # Set up grant with grant permissions for testing
            $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -ErrorAction 'Stop'
            $null = Grant-SqlDscServerPermission -Login $loginObject -Permission @('ViewAnyDatabase') -WithGrant -Force -ErrorAction 'Stop'
        }

        AfterAll {
            $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -ErrorAction 'Stop'
            $null = Revoke-SqlDscServerPermission -Login $loginObject -Permission @('ViewAnyDatabase') -WithGrant -Force -ErrorAction 'SilentlyContinue'
        }

        It 'Should return true when testing for grant with grant permission that exists' {
            $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -ErrorAction 'Stop'

            $result = Test-SqlDscServerPermission -Login $loginObject -Grant -Permission @('ViewAnyDatabase') -WithGrant -ErrorAction 'Stop'

            $result | Should -BeTrue
        }

        It 'Should return false when testing for grant with grant permission that does not exist' {
            $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -ErrorAction 'Stop'

            $result = Test-SqlDscServerPermission -Login $loginObject -Grant -Permission @('CreateEndpoint') -WithGrant -ErrorAction 'Stop'

            $result | Should -BeFalse
        }
    }

    Context 'When testing non-existent principal' {
        It 'Should return false when testing permissions for non-existent login' {
            # Create a mock login object that references a non-existent login
            # We need to use a real server object but with a non-existent login name
            $mockLogin = [Microsoft.SqlServer.Management.Smo.Login]::new($script:serverObject, 'NonExistentLogin')

            $result = Test-SqlDscServerPermission -Login $mockLogin -Grant -Permission @('ConnectSql') -ErrorAction 'Stop'

            $result | Should -BeFalse
        }
    }
}
