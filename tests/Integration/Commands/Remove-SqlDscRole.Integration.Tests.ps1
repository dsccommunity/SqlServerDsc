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

Describe 'Remove-SqlDscRole' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        # Starting the named instance SQL Server service prior to running tests.
        Start-Service -Name 'MSSQL$DSCSQLTEST' -Verbose -ErrorAction 'Stop'

        $script:mockInstanceName = 'DSCSQLTEST'
        $script:mockComputerName = Get-ComputerName

        $mockSqlAdministratorUserName = 'SqlAdmin' # Using computer name as NetBIOS name throw exception.
        $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

        $script:mockSqlAdminCredential = [System.Management.Automation.PSCredential]::new($mockSqlAdministratorUserName, $mockSqlAdministratorPassword)

        $script:serverObject = Connect-SqlDscDatabaseEngine -InstanceName $script:mockInstanceName -Credential $script:mockSqlAdminCredential

        # Shared test role names created by New-SqlDscRole integration tests
        $script:sharedTestRoleForRemoval = 'SharedTestRole_ForRemoval'
        $script:persistentTestRole = 'SqlDscIntegrationTestRole_Persistent'

        # Test role names that will be created for removal tests
        $script:testRoleName = 'TestRoleForRemoval_' + (Get-Random)
        $script:testRoleNameByObject = 'TestRoleByObject_' + (Get-Random)
    }

    AfterAll {
        # Clean up any test roles that might still exist
        $existingRole = Get-SqlDscRole -ServerObject $script:serverObject -Name $script:testRoleName -ErrorAction 'SilentlyContinue'
        if ($existingRole)
        {
            Remove-SqlDscRole -RoleObject $existingRole -Force -ErrorAction 'SilentlyContinue'
        }

        $existingRoleByObject = Get-SqlDscRole -ServerObject $script:serverObject -Name $script:testRoleNameByObject -ErrorAction 'SilentlyContinue'
        if ($existingRoleByObject)
        {
            Remove-SqlDscRole -RoleObject $existingRoleByObject -Force -ErrorAction 'SilentlyContinue'
        }

        Disconnect-SqlDscDatabaseEngine -ServerObject $script:serverObject

        # Stop the named instance SQL Server service to save memory on the build worker.
        Stop-Service -Name 'MSSQL$DSCSQLTEST' -Verbose -ErrorAction 'Stop'
    }

    Context 'When removing a SQL Server role by name' {
        BeforeEach {
            # Only create test role if it doesn't exist
            $existingRole = Get-SqlDscRole -ServerObject $script:serverObject -Name $script:testRoleName -ErrorAction 'SilentlyContinue'
            if (-not $existingRole) {
                New-SqlDscRole -ServerObject $script:serverObject -Name $script:testRoleName -Force
            }
        }

        It 'Should remove a role when it exists' {
            # Verify the role exists before removal
            $existingRole = Get-SqlDscRole -ServerObject $script:serverObject -Name $script:testRoleName
            $existingRole | Should -Not -BeNullOrEmpty

            # Remove the role
            Remove-SqlDscRole -ServerObject $script:serverObject -Name $script:testRoleName -Force

            # Verify the role no longer exists
            $removedRole = Get-SqlDscRole -ServerObject $script:serverObject -Name $script:testRoleName -ErrorAction 'SilentlyContinue'
            $removedRole | Should -BeNullOrEmpty
        }

        It 'Should throw an error when removing a non-existent role' {
            { Remove-SqlDscRole -ServerObject $script:serverObject -Name 'NonExistentRole' -Force -ErrorAction 'Stop' } |
                Should -Throw -ExpectedMessage '*Server role ''NonExistentRole'' was not found.*'
        }

        It 'Should throw an error when trying to remove a fixed role' {
            { Remove-SqlDscRole -ServerObject $script:serverObject -Name 'sysadmin' -Force -ErrorAction 'Stop' } |
                Should -Throw -ExpectedMessage '*Cannot remove built-in server role ''sysadmin''*'
        }
    }

    Context 'When removing shared test roles' {
        It 'Should remove the shared test role for removal' {
            # Verify the shared role exists before removal
            $existingRole = Get-SqlDscRole -ServerObject $script:serverObject -Name $script:sharedTestRoleForRemoval
            $existingRole | Should -Not -BeNullOrEmpty

            # Remove the shared role
            Remove-SqlDscRole -ServerObject $script:serverObject -Name $script:sharedTestRoleForRemoval -Force

            # Verify the role no longer exists
            $removedRole = Get-SqlDscRole -ServerObject $script:serverObject -Name $script:sharedTestRoleForRemoval -ErrorAction 'SilentlyContinue'
            $removedRole | Should -BeNullOrEmpty
        }

        It 'Should NOT remove the persistent test role (verify it exists)' {
            # Verify the persistent role still exists and should not be removed
            $persistentRole = Get-SqlDscRole -ServerObject $script:serverObject -Name $script:persistentTestRole -ErrorAction 'SilentlyContinue'
            $persistentRole | Should -Not -BeNullOrEmpty
            $persistentRole.Name | Should -Be $script:persistentTestRole
            $persistentRole.Owner | Should -Be 'sa'
        }
    }

    Context 'When removing a SQL Server role by object' {
        BeforeEach {
            # Only create test role if it doesn't exist
            $existingRole = Get-SqlDscRole -ServerObject $script:serverObject -Name $script:testRoleNameByObject -ErrorAction 'SilentlyContinue'
            if (-not $existingRole) {
                New-SqlDscRole -ServerObject $script:serverObject -Name $script:testRoleNameByObject -Force
            }
        }

        It 'Should remove a role when passed a role object' {
            # Get the role object
            $roleObject = Get-SqlDscRole -ServerObject $script:serverObject -Name $script:testRoleNameByObject

            # Remove the role using the object
            Remove-SqlDscRole -RoleObject $roleObject -Force

            # Verify the role no longer exists
            $removedRole = Get-SqlDscRole -ServerObject $script:serverObject -Name $script:testRoleNameByObject -ErrorAction 'SilentlyContinue'
            $removedRole | Should -BeNullOrEmpty
        }

        It 'Should throw an error when trying to remove a fixed role by object' {
            # Get a fixed role object
            $fixedRoleObject = Get-SqlDscRole -ServerObject $script:serverObject -Name 'sysadmin'

            { Remove-SqlDscRole -RoleObject $fixedRoleObject -Force -ErrorAction 'Stop' } |
                Should -Throw -ExpectedMessage '*Cannot remove built-in server role ''sysadmin''*'
        }
    }

    Context 'When using pipeline input' {
        BeforeEach {
            # Only create test role if it doesn't exist
            $existingRole = Get-SqlDscRole -ServerObject $script:serverObject -Name $script:testRoleName -ErrorAction 'SilentlyContinue'
            if (-not $existingRole) {
                New-SqlDscRole -ServerObject $script:serverObject -Name $script:testRoleName -Force
            }
        }

        It 'Should accept ServerObject from pipeline for removal by name' {
            # Verify the role exists before removal
            $existingRole = Get-SqlDscRole -ServerObject $script:serverObject -Name $script:testRoleName
            $existingRole | Should -Not -BeNullOrEmpty

            # Remove the role using pipeline
            $script:serverObject | Remove-SqlDscRole -Name $script:testRoleName -Force

            # Verify the role no longer exists
            $removedRole = Get-SqlDscRole -ServerObject $script:serverObject -Name $script:testRoleName -ErrorAction 'SilentlyContinue'
            $removedRole | Should -BeNullOrEmpty
        }

        It 'Should accept RoleObject from pipeline for removal' {
            # Get the role object and remove it via pipeline
            $roleObject = Get-SqlDscRole -ServerObject $script:serverObject -Name $script:testRoleName

            $roleObject | Remove-SqlDscRole -Force

            # Verify the role no longer exists
            $removedRole = Get-SqlDscRole -ServerObject $script:serverObject -Name $script:testRoleName -ErrorAction 'SilentlyContinue'
            $removedRole | Should -BeNullOrEmpty
        }
    }
}
