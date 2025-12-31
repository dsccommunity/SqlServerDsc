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

Describe 'Get-SqlDscDatabasePermission' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        $script:mockInstanceName = 'DSCSQLTEST'

        $mockSqlAdministratorUserName = 'SqlAdmin' # Using computer name as NetBIOS name throw exception.
        $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

        $script:mockSqlAdminCredential = [System.Management.Automation.PSCredential]::new($mockSqlAdministratorUserName, $mockSqlAdministratorPassword)

        $script:serverObject = Connect-SqlDscDatabaseEngine -InstanceName $script:mockInstanceName -Credential $script:mockSqlAdminCredential

        # Create a test database for the integration tests
        $script:testDatabaseName = 'SqlDscDatabasePermissionTest_' + (Get-Random)
        $null = New-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -Force -ErrorAction 'Stop'

        # Create a test user in the database for permission testing
        $script:testUserName = 'SqlDscTestUser_' + (Get-Random)
        $testUserSql = "USE [$($script:testDatabaseName)]; CREATE USER [$($script:testUserName)] WITHOUT LOGIN;"
        Invoke-SqlDscQuery -ServerObject $script:serverObject -DatabaseName $script:testDatabaseName -Query $testUserSql -Force -ErrorAction 'Stop'

        # Grant some permissions to the test user for testing
        $grantPermissionSql = "USE [$($script:testDatabaseName)]; GRANT CONNECT, SELECT TO [$($script:testUserName)];"
        Invoke-SqlDscQuery -ServerObject $script:serverObject -DatabaseName $script:testDatabaseName -Query $grantPermissionSql -Force -ErrorAction 'Stop'
    }

    AfterAll {
        # Clean up test database (this will also remove the test user)
        $testDatabase = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -ErrorAction 'SilentlyContinue'
        if ($testDatabase)
        {
            $null = Remove-SqlDscDatabase -DatabaseObject $testDatabase -Force -ErrorAction 'Stop'
        }

        Disconnect-SqlDscDatabaseEngine -ServerObject $script:serverObject
    }

    Context 'When connecting to SQL Server instance' {
        Context 'When getting permissions for valid database principals' {
            It 'Should return permissions for dbo user in master database' {
                $result = Get-SqlDscDatabasePermission -ServerObject $script:serverObject -DatabaseName 'master' -Name 'dbo'

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType [Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo]
            }

            It 'Should return permissions for dbo user in master database using pipeline' {
                $result = $script:serverObject | Get-SqlDscDatabasePermission -DatabaseName 'master' -Name 'dbo'

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType [Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo]
            }

            It 'Should return permissions for public role in master database' {
                $result = Get-SqlDscDatabasePermission -ServerObject $script:serverObject -DatabaseName 'master' -Name 'public'

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType [Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo]
            }

            It 'Should return permissions for test user in test database' {
                $result = Get-SqlDscDatabasePermission -ServerObject $script:serverObject -DatabaseName $script:testDatabaseName -Name $script:testUserName

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType [Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo]

                # Verify that the Connect and Select permissions we granted are present
                $connectPermission = $result | Where-Object { $_.PermissionType.Connect -eq $true }
                $selectPermission = $result | Where-Object { $_.PermissionType.Select -eq $true }

                $connectPermission | Should -Not -BeNullOrEmpty -Because 'Connect permission should have been granted to test user'
                $connectPermission.PermissionState | Should -Be 'Grant'

                $selectPermission | Should -Not -BeNullOrEmpty -Because 'Select permission should have been granted to test user'
                $selectPermission.PermissionState | Should -Be 'Grant'
            }
        }

        Context 'When getting permissions for invalid principals' {
            It 'Should throw error for non-existent database with ErrorAction Stop' {
                { Get-SqlDscDatabasePermission -ServerObject $script:serverObject -DatabaseName 'NonExistentDatabase123' -Name 'dbo' -ErrorAction 'Stop' } |
                    Should -Throw
            }

            It 'Should return null for non-existent database with ErrorAction SilentlyContinue' {
                $result = Get-SqlDscDatabasePermission -ServerObject $script:serverObject -DatabaseName 'NonExistentDatabase123' -Name 'dbo' -ErrorAction 'SilentlyContinue'

                $result | Should -BeNullOrEmpty
            }

            It 'Should throw error for non-existent principal with ErrorAction Stop' {
                { Get-SqlDscDatabasePermission -ServerObject $script:serverObject -DatabaseName 'master' -Name 'NonExistentUser123' -ErrorAction 'Stop' } |
                    Should -Throw
            }

            It 'Should return null for non-existent principal with ErrorAction SilentlyContinue' {
                $result = Get-SqlDscDatabasePermission -ServerObject $script:serverObject -DatabaseName 'master' -Name 'NonExistentUser123' -ErrorAction 'SilentlyContinue'

                $result | Should -BeNullOrEmpty
            }
        }

        Context 'When verifying permission properties' {
            BeforeAll {
                # Get permissions for a known principal that should have permissions
                $script:testPermissions = Get-SqlDscDatabasePermission -ServerObject $script:serverObject -DatabaseName $script:testDatabaseName -Name $script:testUserName
            }

            It 'Should return DatabasePermissionInfo objects with PermissionState property' {
                $script:testPermissions | Should -Not -BeNullOrEmpty

                foreach ($permission in $script:testPermissions) {
                    $permission.PermissionState | Should -BeIn @('Grant', 'Deny', 'GrantWithGrant')
                }
            }

            It 'Should return DatabasePermissionInfo objects with PermissionType property' {
                $script:testPermissions | Should -Not -BeNullOrEmpty

                foreach ($permission in $script:testPermissions) {
                    $permission.PermissionType | Should -Not -BeNullOrEmpty
                    $permission.PermissionType | Should -BeOfType [Microsoft.SqlServer.Management.Smo.DatabasePermissionSet]
                }
            }

            It 'Should return DatabasePermissionInfo objects with Grantee property' {
                $script:testPermissions | Should -Not -BeNullOrEmpty

                foreach ($permission in $script:testPermissions) {
                    $permission.Grantee | Should -Be $script:testUserName
                }
            }
        }

        Context 'When working with built-in database roles' {
            BeforeEach {
                $script:customRoleName = $null
            }

            AfterEach {
                # Clean up the custom role if it was created
                if ($script:customRoleName)
                {
                    $dropRoleSql = "USE [$($script:testDatabaseName)]; DROP ROLE [$script:customRoleName];"
                    Invoke-SqlDscQuery -ServerObject $script:serverObject -DatabaseName $script:testDatabaseName -Query $dropRoleSql -Force -ErrorAction 'SilentlyContinue'
                }
            }

            It 'Should return permissions for db_datareader role' {
                # Note: The command excludes fixed roles by default, so this should return null or empty
                $result = Get-SqlDscDatabasePermission -ServerObject $script:serverObject -DatabaseName $script:testDatabaseName -Name 'db_datareader' -ErrorAction 'SilentlyContinue'

                # Fixed roles are excluded by default, so result should be null
                $result | Should -BeNullOrEmpty
            }

            It 'Should work with non-fixed database roles when they exist' {
                # Create a custom database role for testing
                $script:customRoleName = 'TestRole_' + (Get-Random)
                $createRoleSql = "USE [$($script:testDatabaseName)]; CREATE ROLE [$script:customRoleName];"
                Invoke-SqlDscQuery -ServerObject $script:serverObject -DatabaseName $script:testDatabaseName -Query $createRoleSql -Force -ErrorAction 'Stop'

                # Grant a permission to the custom role
                $grantRolePermissionSql = "USE [$($script:testDatabaseName)]; GRANT CONNECT TO [$script:customRoleName];"
                Invoke-SqlDscQuery -ServerObject $script:serverObject -DatabaseName $script:testDatabaseName -Query $grantRolePermissionSql -Force -ErrorAction 'Stop'

                # Test getting permissions for the custom role
                $result = Get-SqlDscDatabasePermission -ServerObject $script:serverObject -DatabaseName $script:testDatabaseName -Name $script:customRoleName -Refresh

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType [Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo]

                # Verify the Connect permission we granted is present
                $connectPermission = $result | Where-Object { $_.PermissionType.Connect -eq $true }
                $connectPermission | Should -Not -BeNullOrEmpty
                $connectPermission.PermissionState | Should -Be 'Grant'
            }
        }
    }
}
