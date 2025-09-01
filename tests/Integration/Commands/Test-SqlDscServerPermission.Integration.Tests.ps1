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

AfterAll {
    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:moduleName -All | Remove-Module -Force
}

Describe 'Test-SqlDscServerPermission Integration Tests' -Tag 'Integration' {
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

            $result = Test-SqlDscServerPermission -Login $loginObject -Grant -Permission @([SqlServerPermission]::ConnectSql, [SqlServerPermission]::ViewServerState) -ErrorAction 'Stop'

            $result | Should -BeTrue
        }

        It 'Should return false when permissions do not match desired state' {
            $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -ErrorAction 'Stop'

            $result = Test-SqlDscServerPermission -Login $loginObject -Grant -Permission @([SqlServerPermission]::AlterAnyDatabase) -ErrorAction 'Stop'

            $result | Should -BeFalse
        }

        It 'Should accept Login object from pipeline' {
            $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -ErrorAction 'Stop'

            $result = $loginObject | Test-SqlDscServerPermission -Grant -Permission @([SqlServerPermission]::ConnectSql, [SqlServerPermission]::ViewServerState) -ErrorAction 'Stop'

            $result | Should -BeTrue
        }

        It 'Should return true when only testing specific grant permission that exists' {
            $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -ErrorAction 'Stop'

            $result = Test-SqlDscServerPermission -Login $loginObject -Grant -Permission @([SqlServerPermission]::ConnectSql) -ErrorAction 'Stop'

            $result | Should -BeTrue
        }

        It 'Should return false when testing for permission that does not exist' {
            $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -ErrorAction 'Stop'

            $result = Test-SqlDscServerPermission -Login $loginObject -Grant -Permission @([SqlServerPermission]::AlterAnyCredential) -ErrorAction 'Stop'

            $result | Should -BeFalse
        }

        It 'Should return true when testing for empty permission collection on principal with no additional permissions' {
            # Create a temporary login for this test to ensure it has no additional permissions
            $tempLoginName = 'TempTestLogin_' + (Get-Random)
            $tempLoginObject = New-SqlDscLogin -ServerObject $script:serverObject -Name $tempLoginName -LoginType SqlLogin -SecureString (ConvertTo-SecureString -String 'TempPassword123!' -AsPlainText -Force) -Force -ErrorAction 'Stop'

            try {
                # Test that empty permission collection returns true when no permissions are set
                $result = Test-SqlDscServerPermission -Login $tempLoginObject -Grant -Permission @() -ErrorAction 'Stop'

                $result | Should -BeTrue
            }
            finally {
                # Clean up temporary login
                Remove-SqlDscLogin -Login $tempLoginObject -Force -ErrorAction 'SilentlyContinue'
            }
        }

        It 'Should return false when using ExactMatch and additional permissions exist' {
            $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -ErrorAction 'Stop'

            # Test with ExactMatch - should fail because ViewServerState is also granted
            $result = Test-SqlDscServerPermission -Login $loginObject -Grant -Permission @([SqlServerPermission]::ConnectSql) -ExactMatch -ErrorAction 'Stop'

            $result | Should -BeFalse
        }

        It 'Should return true when using ExactMatch and permissions exactly match' {
            $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -ErrorAction 'Stop'

            # Test with ExactMatch - should pass because both ConnectSql and ViewServerState are granted
            $result = Test-SqlDscServerPermission -Login $loginObject -Grant -Permission @([SqlServerPermission]::ConnectSql, [SqlServerPermission]::ViewServerState) -ExactMatch -ErrorAction 'Stop'

            $result | Should -BeTrue
        }
    }

    Context 'When testing server permissions for role' {
        BeforeAll {
            # Set up known permissions for testing
            $roleObject = Get-SqlDscRole -ServerObject $script:serverObject -Name $script:testRoleName -ErrorAction 'Stop'
            $null = Grant-SqlDscServerPermission -ServerRole $roleObject -Permission @('ViewServerState') -Force -ErrorAction 'Stop'
        }

        AfterAll {
            $roleObject = Get-SqlDscRole -ServerObject $script:serverObject -Name $script:testRoleName -ErrorAction 'Stop'
            $null = Revoke-SqlDscServerPermission -ServerRole $roleObject -Permission @('ViewServerState') -Force -ErrorAction 'SilentlyContinue'
        }

        It 'Should return true when role permissions match desired state' {
            $roleObject = Get-SqlDscRole -ServerObject $script:serverObject -Name $script:testRoleName -ErrorAction 'Stop'

            $result = Test-SqlDscServerPermission -ServerRole $roleObject -Grant -Permission @([SqlServerPermission]::ConnectSql, [SqlServerPermission]::ViewServerState) -ErrorAction 'Stop'

            $result | Should -BeTrue
        }

        It 'Should return false when role permissions do not match desired state' {
            $roleObject = Get-SqlDscRole -ServerObject $script:serverObject -Name $script:testRoleName -ErrorAction 'Stop'

            $result = Test-SqlDscServerPermission -ServerRole $roleObject -Grant -Permission @([SqlServerPermission]::CreateAnyDatabase) -ErrorAction 'Stop'

            $result | Should -BeFalse
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

            $result = Test-SqlDscServerPermission -Login $loginObject -Deny -Permission @([SqlServerPermission]::ViewAnyDefinition) -ErrorAction 'Stop'

            $result | Should -BeTrue
        }

        It 'Should return false when testing for denied permission that does not exist' {
            $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -ErrorAction 'Stop'

            $result = Test-SqlDscServerPermission -Login $loginObject -Deny -Permission @([SqlServerPermission]::AlterServerState) -ErrorAction 'Stop'

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

            $result = Test-SqlDscServerPermission -Login $loginObject -Grant -Permission @([SqlServerPermission]::ViewAnyDatabase) -WithGrant -ErrorAction 'Stop'

            $result | Should -BeTrue
        }

        It 'Should return false when testing for grant with grant permission that does not exist' {
            $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -ErrorAction 'Stop'

            $result = Test-SqlDscServerPermission -Login $loginObject -Grant -Permission @([SqlServerPermission]::CreateEndpoint) -WithGrant -ErrorAction 'Stop'

            $result | Should -BeFalse
        }
    }

    Context 'When testing non-existent principal' {
        It 'Should return false when testing permissions for non-existent login' {
            # Create a mock login object that references a non-existent login
            # We need to use a real server object but with a non-existent login name
            $mockLogin = [Microsoft.SqlServer.Management.Smo.Login]::new($script:serverObject, 'NonExistentLogin')

            $result = Test-SqlDscServerPermission -Login $mockLogin -Grant -Permission @([SqlServerPermission]::ConnectSql) -ErrorAction 'Stop'

            $result | Should -BeFalse
        }
    }
}
