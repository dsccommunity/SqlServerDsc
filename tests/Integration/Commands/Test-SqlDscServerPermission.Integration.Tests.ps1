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

    Remove-Module -Name SqlServer -Force
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

        # Setup default parameter values to reduce verbosity in the tests
        $PSDefaultParameterValues['*:ServerName'] = $script:computerName
        $PSDefaultParameterValues['*:InstanceName'] = $script:sqlServerInstanceName
        $PSDefaultParameterValues['*:ErrorAction'] = 'Stop'

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

        $PSDefaultParameterValues.Remove('*:ServerName')
        $PSDefaultParameterValues.Remove('*:InstanceName')
        $PSDefaultParameterValues.Remove('*:ErrorAction')
    }

    Context 'When testing server permissions for login' {
        BeforeAll {
            # Set up known permissions for testing
            $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName
            $null = Grant-SqlDscServerPermission -Login $loginObject -Permission @('ViewServerState') -Force
        }

        AfterAll {
            $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName
            $null = Revoke-SqlDscServerPermission -Login $loginObject -Permission @('ViewServerState') -Force -ErrorAction 'SilentlyContinue'
        }

        It 'Should return true when permissions match desired state' {
            $permissions = @(
                [ServerPermission] @{
                    State = 'Grant'
                    Permission = @('ConnectSql', 'ViewServerState')
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
                    Permission = @('AlterAnyDatabase')
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
                    Permission = @('ConnectSql', 'ViewServerState')
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

        It 'Should return true when only testing specific grant permission that exists' {
            $permissions = @(
                [ServerPermission] @{
                    State = 'Grant'
                    Permission = @('ConnectSql')
                }
            )

            $result = Test-SqlDscServerPermission -ServerObject $script:serverObject -Name $script:testLoginName -Permission $permissions

            $result | Should -BeTrue
        }

        It 'Should return false when testing for permission that does not exist' {
            $permissions = @(
                [ServerPermission] @{
                    State = 'Grant'
                    Permission = @('AlterAnyCredential')
                }
            )

            $result = Test-SqlDscServerPermission -ServerObject $script:serverObject -Name $script:testLoginName -Permission $permissions

            $result | Should -BeFalse
        }
    }

    Context 'When testing server permissions for role' {
        BeforeAll {
            # Set up known permissions for testing
            $roleObject = Get-SqlDscRole -ServerObject $script:serverObject -Name $script:testRoleName
            $null = Grant-SqlDscServerPermission -ServerRole $roleObject -Permission @('ViewServerState') -Force
        }

        AfterAll {
            $roleObject = Get-SqlDscRole -ServerObject $script:serverObject -Name $script:testRoleName
            $null = Revoke-SqlDscServerPermission -ServerRole $roleObject -Permission @('ViewServerState') -Force -ErrorAction 'SilentlyContinue'
        }

        It 'Should return true when role permissions match desired state' {
            $permissions = @(
                [ServerPermission] @{
                    State = 'Grant'
                    Permission = @('ConnectSql', 'ViewServerState')
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

            $result = Test-SqlDscServerPermission -ServerObject $script:serverObject -Name $script:testRoleName -Permission $permissions

            $result | Should -BeTrue
        }

        It 'Should return false when role permissions do not match desired state' {
            $permissions = @(
                [ServerPermission] @{
                    State = 'Grant'
                    Permission = @('CreateAnyDatabase')
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

            $result = Test-SqlDscServerPermission -ServerObject $script:serverObject -Name $script:testRoleName -Permission $permissions

            $result | Should -BeFalse
        }
    }

    Context 'When testing deny permissions' {
        BeforeAll {
            # Set up denied permissions for testing
            $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName
            Deny-SqlDscServerPermission -Login $loginObject -Permission @('ViewAnyDefinition') -Force
        }

        AfterAll {
            $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName
            Revoke-SqlDscServerPermission -Login $loginObject -Permission @('ViewAnyDefinition') -Force -ErrorAction 'SilentlyContinue'
        }

        It 'Should return true when testing for denied permission that exists' {
            $permissions = @(
                [ServerPermission] @{
                    State = 'Deny'
                    Permission = @('ViewAnyDefinition')
                }
            )

            $result = Test-SqlDscServerPermission -ServerObject $script:serverObject -Name $script:testLoginName -Permission $permissions

            $result | Should -BeTrue
        }

        It 'Should return false when testing for denied permission that does not exist' {
            $permissions = @(
                [ServerPermission] @{
                    State = 'Deny'
                    Permission = @('AlterServerState')
                }
            )

            $result = Test-SqlDscServerPermission -ServerObject $script:serverObject -Name $script:testLoginName -Permission $permissions

            $result | Should -BeFalse
        }
    }

    Context 'When testing grant with grant permissions' {
        BeforeAll {
            # Set up grant with grant permissions for testing
            $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName
            $null = Grant-SqlDscServerPermission -Login $loginObject -Permission @('ViewAnyDatabase') -WithGrant -Force
        }

        AfterAll {
            $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName
            $null = Revoke-SqlDscServerPermission -Login $loginObject -Permission @('ViewAnyDatabase') -WithGrant -Force -ErrorAction 'SilentlyContinue'
        }

        It 'Should return true when testing for grant with grant permission that exists' {
            $permissions = @(
                [ServerPermission] @{
                    State = 'GrantWithGrant'
                    Permission = @('ViewAnyDatabase')
                }
            )

            $result = Test-SqlDscServerPermission -ServerObject $script:serverObject -Name $script:testLoginName -Permission $permissions

            $result | Should -BeTrue
        }

        It 'Should return false when testing for grant with grant permission that does not exist' {
            $permissions = @(
                [ServerPermission] @{
                    State = 'GrantWithGrant'
                    Permission = @('CreateEndpoint')
                }
            )

            $result = Test-SqlDscServerPermission -ServerObject $script:serverObject -Name $script:testLoginName -Permission $permissions

            $result | Should -BeFalse
        }
    }

    Context 'When testing non-existent principal' {
        It 'Should return false when testing permissions for non-existent login' {
            $permissions = @(
                [ServerPermission] @{
                    State = 'Grant'
                    Permission = @('ConnectSql')
                }
            )

            $result = Test-SqlDscServerPermission -ServerObject $script:serverObject -Name 'NonExistentLogin' -Permission $permissions

            $result | Should -BeFalse
        }
    }
}
