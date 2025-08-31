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

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:moduleName

    # Loading stub cmdlets
    Import-Module -Name "$PSScriptRoot/../../Unit/Stubs/SqlServer.psm1" -Force
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:moduleName -All | Remove-Module -Force

    Remove-Module -Name SqlServer -Force
}

Describe 'Revoke-SqlDscServerPermission' -Tag 'IntegrationTest' {
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

    Context 'When revoking server permissions from login' {
        BeforeEach {
            # Grant a known permission for testing
            $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName
            Grant-SqlDscServerPermission -Login $loginObject -Permission @('ViewServerState') -Force
        }

        It 'Should revoke permissions without throwing an error' {
            $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName

            {
                Revoke-SqlDscServerPermission -Login $loginObject -Permission @('ViewServerState') -Force
            } | Should -Not -Throw
        }

        It 'Should show the permissions as no longer granted' {
            $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName

            # First grant the permission
            Grant-SqlDscServerPermission -Login $loginObject -Permission @('ViewAnyDatabase') -Force

            # Then revoke it
            Revoke-SqlDscServerPermission -Login $loginObject -Permission @('ViewAnyDatabase') -Force

            # Test that it's no longer granted
            $result = Test-SqlDscServerPermission -Login $loginObject -Grant -Permission @('ViewAnyDatabase')

            $result | Should -BeFalse
        }

        It 'Should accept Login from pipeline' {
            $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName

            # First grant a permission to revoke
            Grant-SqlDscServerPermission -Login $loginObject -Permission @('ViewAnyDefinition') -Force

            {
                $loginObject | Revoke-SqlDscServerPermission -Permission @('ViewAnyDefinition') -Force
            } | Should -Not -Throw

            # Verify the permission was revoked
            $result = Test-SqlDscServerPermission -Login $loginObject -Grant -Permission @('ViewAnyDefinition')
            $result | Should -BeFalse
        }
    }

    Context 'When revoking server permissions from role' {
        BeforeEach {
            # Grant a known permission for testing
            $roleObject = Get-SqlDscRole -ServerObject $script:serverObject -Name $script:testRoleName
            Grant-SqlDscServerPermission -ServerRole $roleObject -Permission @('ViewServerState') -Force
        }

        It 'Should revoke permissions from role without throwing an error' {
            $roleObject = Get-SqlDscRole -ServerObject $script:serverObject -Name $script:testRoleName

            {
                Revoke-SqlDscServerPermission -ServerRole $roleObject -Permission @('ViewServerState') -Force
            } | Should -Not -Throw

            # Test that it's no longer granted
            $result = Test-SqlDscServerPermission -ServerRole $roleObject -Grant -Permission @('ViewServerState')

            $result | Should -BeFalse
        }
    }
}
