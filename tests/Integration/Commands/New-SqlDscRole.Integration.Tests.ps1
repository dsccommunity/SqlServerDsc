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
    $script:dscModuleName = 'SqlServerDsc'

    Import-Module -Name $script:dscModuleName
}

Describe 'New-SqlDscRole' -Tag @('Integration_SQL2016', 'Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        # Starting the named instance SQL Server service prior to running tests.
        Start-Service -Name 'MSSQL$DSCSQLTEST' -Verbose -ErrorAction 'Stop'

        $script:mockInstanceName = 'DSCSQLTEST'
        $script:mockComputerName = Get-ComputerName

        $mockSqlAdministratorUserName = 'SqlAdmin' # Using computer name as NetBIOS name throw exception.
        $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

        $script:mockSqlAdminCredential = [System.Management.Automation.PSCredential]::new($mockSqlAdministratorUserName, $mockSqlAdministratorPassword)

        $script:serverObject = Connect-SqlDscDatabaseEngine -InstanceName $script:mockInstanceName -Credential $script:mockSqlAdminCredential

        # Test role names that will be created and cleaned up
        $script:testRoleName = 'TestRole_' + (Get-Random)
        $script:testRoleNameWithOwner = 'TestRoleOwner_' + (Get-Random)
        # Shared test roles for other integration tests
        $script:sharedTestRoleForIntegrationTests = 'SharedTestRole_ForIntegrationTests'
        $script:sharedTestRoleForRemoval = 'SharedTestRole_ForRemoval'
        $script:persistentTestRole = 'SqlDscIntegrationTestRole_Persistent'
    }

    AfterAll {
        # Clean up only the temporary test roles, not the shared ones
        $existingRole = Get-SqlDscRole -ServerObject $script:serverObject -Name $script:testRoleName -ErrorAction 'Ignore'
        if ($existingRole)
        {
            Remove-SqlDscRole -RoleObject $existingRole -Force -ErrorAction 'Ignore'
        }

        $existingRoleWithOwner = Get-SqlDscRole -ServerObject $script:serverObject -Name $script:testRoleNameWithOwner -ErrorAction 'Ignore'
        if ($existingRoleWithOwner)
        {
            Remove-SqlDscRole -RoleObject $existingRoleWithOwner -Force -ErrorAction 'Ignore'
        }

        Disconnect-SqlDscDatabaseEngine -ServerObject $script:serverObject

        # Stop the named instance SQL Server service to save memory on the build worker.
        Stop-Service -Name 'MSSQL$DSCSQLTEST' -Verbose -ErrorAction 'Stop'
    }

    Context 'When creating a new SQL Server role' {
        It 'Should create a role and return a ServerRole object' {
            $result = New-SqlDscRole -ServerObject $script:serverObject -Name $script:testRoleName -Force

            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.ServerRole'
            $result.Name | Should -Be $script:testRoleName
            $result.IsFixedRole | Should -BeFalse

            # Verify the role exists in the server
            $verifyRole = Get-SqlDscRole -ServerObject $script:serverObject -Name $script:testRoleName
            $verifyRole | Should -Not -BeNullOrEmpty
            $verifyRole.Name | Should -Be $script:testRoleName
        }

        It 'Should create a role with a specified owner' {
            $result = New-SqlDscRole -ServerObject $script:serverObject -Name $script:testRoleNameWithOwner -Owner 'sa' -Force

            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.ServerRole'
            $result.Name | Should -Be $script:testRoleNameWithOwner
            $result.Owner | Should -Be 'sa'
            $result.IsFixedRole | Should -BeFalse
        }
    }

    Context 'When using pipeline input' {
        It 'Should accept ServerObject from pipeline' {
            $uniqueRoleName = 'PipelineTestRole_' + (Get-Random)

            $result = $script:serverObject | New-SqlDscRole -Name $uniqueRoleName -Force

            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.ServerRole'
            $result.Name | Should -Be $uniqueRoleName

            # Clean up the pipeline test role
            Remove-SqlDscRole -RoleObject $result -Force -ErrorAction 'Ignore'
        }
    }

    Context 'When creating shared test roles for other integration tests' {
        It 'Should create a shared role for integration tests' {
            # Create shared role for Get-SqlDscRole integration tests
            $result = New-SqlDscRole -ServerObject $script:serverObject -Name $script:sharedTestRoleForIntegrationTests -Force

            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.ServerRole'
            $result.Name | Should -Be $script:sharedTestRoleForIntegrationTests
            $result.IsFixedRole | Should -BeFalse

            # Verify the role exists in the server
            $verifyRole = Get-SqlDscRole -ServerObject $script:serverObject -Name $script:sharedTestRoleForIntegrationTests
            $verifyRole | Should -Not -BeNullOrEmpty
            $verifyRole.Name | Should -Be $script:sharedTestRoleForIntegrationTests
        }

        It 'Should create a shared role for removal tests' {
            # Create shared role for Remove-SqlDscRole integration tests
            $result = New-SqlDscRole -ServerObject $script:serverObject -Name $script:sharedTestRoleForRemoval -Force

            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.ServerRole'
            $result.Name | Should -Be $script:sharedTestRoleForRemoval
            $result.IsFixedRole | Should -BeFalse

            # Verify the role exists in the server
            $verifyRole = Get-SqlDscRole -ServerObject $script:serverObject -Name $script:sharedTestRoleForRemoval
            $verifyRole | Should -Not -BeNullOrEmpty
            $verifyRole.Name | Should -Be $script:sharedTestRoleForRemoval
        }

        It 'Should create a persistent role that remains on the instance' {
            # Create persistent role with sa owner that will remain on the instance
            $result = New-SqlDscRole -ServerObject $script:serverObject -Name $script:persistentTestRole -Owner 'sa' -Force

            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.ServerRole'
            $result.Name | Should -Be $script:persistentTestRole
            $result.Owner | Should -Be 'sa'
            $result.IsFixedRole | Should -BeFalse

            # Verify the role exists in the server
            $verifyRole = Get-SqlDscRole -ServerObject $script:serverObject -Name $script:persistentTestRole
            $verifyRole | Should -Not -BeNullOrEmpty
            $verifyRole.Name | Should -Be $script:persistentTestRole
            $verifyRole.Owner | Should -Be 'sa'
        }
    }

    Context 'When attempting to create duplicate roles' {
        It 'Should throw an error when creating a role that already exists' {
            # Try to re-create the persistent role which should already exist
            { New-SqlDscRole -ServerObject $script:serverObject -Name $script:persistentTestRole -Force -ErrorAction 'Stop' } |
                Should -Throw -ExpectedMessage "*already exists*"
        }
    }
}
