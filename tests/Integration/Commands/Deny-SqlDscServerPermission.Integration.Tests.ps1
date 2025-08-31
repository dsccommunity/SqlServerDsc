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
AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:moduleName -All | Remove-Module -Force

    Remove-Module -Name SqlServer -Force
}

Describe 'Deny-SqlDscServerPermission' -Tag 'IntegrationTest' {
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

    Context 'When denying server permissions to login' {
        BeforeEach {
        BeforeEach {
            $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName
            Revoke-SqlDscServerPermission -Login $loginObject -Permission ViewServerState -Force -ErrorAction 'SilentlyContinue'
            Revoke-SqlDscServerPermission -Login $loginObject -Permission ViewAnyDefinition -Force -ErrorAction 'SilentlyContinue'
        }

        It 'Should deny ViewServerState permission' {
            $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName

            $null = Deny-SqlDscServerPermission -Login $loginObject -Permission @('ViewServerState') -Force
        }

        It 'Should show the permissions as denied' {
            $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName

            # First deny the permission
            $null = Deny-SqlDscServerPermission -Login $loginObject -Permission @('ViewAnyDatabase') -Force

            # Then test if it's denied
            $result = Test-SqlDscServerPermission -Login $loginObject -Deny -Permission @('ViewAnyDatabase')

            $result | Should -BeTrue
        }

        It 'Should accept Login from pipeline' {
            $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName

            $null = $loginObject | Deny-SqlDscServerPermission -Permission @('ViewAnyDefinition') -Force

            # Verify the permission was denied
            $result = Test-SqlDscServerPermission -Login $loginObject -Deny -Permission @('ViewAnyDefinition')
            $result | Should -BeTrue
        }
    }

    Context 'When denying server permissions to role' {
        BeforeEach {
            Revoke-SqlDscServerPermission -ServerObject $script:serverObject -Name $script:testRoleName -Permission 'ViewServerState' -Force -ErrorAction 'SilentlyContinue'
        }

        It 'Should deny ViewServerState permission to role' {
            $roleObject = Get-SqlDscRole -ServerObject $script:serverObject -Name $script:testRoleName

            $null = Deny-SqlDscServerPermission -ServerRole $roleObject -Permission @('ViewServerState') -Force

            # Verify the permission was denied
            $result = Test-SqlDscServerPermission -ServerRole $roleObject -Deny -Permission @('ViewServerState')
            $result | Should -BeTrue
        }

        It 'Should deny persistent AlterTrace permission to login for other tests' {
            $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName

            $null = Deny-SqlDscServerPermission -Login $loginObject -Permission @('AlterTrace') -Force

            # Verify the permission was denied - this denial will remain persistent for other integration tests
            $result = Test-SqlDscServerPermission -Login $loginObject -Deny -Permission @('AlterTrace')
            $result | Should -BeTrue
        }
    }
}
