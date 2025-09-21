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

Describe 'Set-SqlDscDatabasePermission' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        # Starting the named instance SQL Server service prior to running tests.
        Start-Service -Name 'MSSQL$DSCSQLTEST' -Verbose -ErrorAction 'Stop'

        $script:mockInstanceName = 'DSCSQLTEST'

        $mockSqlAdministratorUserName = 'SqlAdmin' # Using computer name as NetBIOS name throw exception.
        $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

        $script:mockSqlAdminCredential = [System.Management.Automation.PSCredential]::new($mockSqlAdministratorUserName, $mockSqlAdministratorPassword)

        $script:serverObject = Connect-SqlDscDatabaseEngine -InstanceName $script:mockInstanceName -Credential $script:mockSqlAdminCredential -ErrorAction 'Stop'

        # Use existing persistent test database from New-SqlDscDatabase integration tests
        $script:testDatabaseName = 'SqlDscIntegrationTestDatabase'
        
        # Use existing persistent principals created by earlier integration tests
        $script:testLoginName = 'IntegrationTestSqlLogin'
        $script:testRoleName = 'SqlDscIntegrationTestRole_Persistent'

        # Ensure the test database exists
        $existingDatabase = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -ErrorAction 'SilentlyContinue'
        
        if (-not $existingDatabase)
        {
            $null = New-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -Force -ErrorAction 'Stop'
        }

        # Create a database user for the existing login for testing database permissions
        $sqlQuery = @"
USE [$script:testDatabaseName];
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = '$script:testLoginName')
BEGIN
    CREATE USER [$script:testLoginName] FOR LOGIN [$script:testLoginName];
END
"@
        $null = Invoke-SqlDscQuery -ServerObject $script:serverObject -Query $sqlQuery -ErrorAction 'Stop'
    }

    AfterAll {
        # Clean up test database user but leave database intact for other tests
        $sqlQuery = @"
USE [$script:testDatabaseName];
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = '$script:testLoginName')
BEGIN
    DROP USER [$script:testLoginName];
END
"@
        $null = Invoke-SqlDscQuery -ServerObject $script:serverObject -Query $sqlQuery -ErrorAction 'SilentlyContinue'

        Disconnect-SqlDscDatabaseEngine -ServerObject $script:serverObject

        # Stop the named instance SQL Server service to save memory on the build worker.
        Stop-Service -Name 'MSSQL$DSCSQLTEST' -Verbose -ErrorAction 'Stop'
    }

    Context 'When setting database permissions with Grant state' {
        BeforeEach {
            # Revoke any existing permissions to start with clean state
            $permissionSet = [Microsoft.SqlServer.Management.Smo.DatabasePermissionSet] @{
                Connect = $true
            }
            $null = Set-SqlDscDatabasePermission -ServerObject $script:serverObject -DatabaseName $script:testDatabaseName -Name $script:testLoginName -State 'Revoke' -Permission $permissionSet -Force -ErrorAction 'SilentlyContinue'

            $permissionSet = [Microsoft.SqlServer.Management.Smo.DatabasePermissionSet] @{
                Select = $true
            }
            $null = Set-SqlDscDatabasePermission -ServerObject $script:serverObject -DatabaseName $script:testDatabaseName -Name $script:testLoginName -State 'Revoke' -Permission $permissionSet -Force -ErrorAction 'SilentlyContinue'
        }

        It 'Should grant Connect permission successfully' {
            $permissionSet = [Microsoft.SqlServer.Management.Smo.DatabasePermissionSet] @{
                Connect = $true
            }

            $null = Set-SqlDscDatabasePermission -ServerObject $script:serverObject -DatabaseName $script:testDatabaseName -Name $script:testLoginName -State 'Grant' -Permission $permissionSet -Force -ErrorAction 'Stop'

            # Verify the permission was granted
            $permissions = Get-SqlDscDatabasePermission -ServerObject $script:serverObject -DatabaseName $script:testDatabaseName -Name $script:testLoginName -ErrorAction 'Stop'

            $permissions | Should -Not -BeNullOrEmpty
            $grantedPermission = $permissions | Where-Object { $_.PermissionState -eq 'Grant' -and $_.PermissionType.Connect -eq $true }
            $grantedPermission | Should -Not -BeNullOrEmpty
            $grantedPermission.PermissionType.Connect | Should -BeTrue
        }

        It 'Should grant multiple permissions successfully' {
            $permissionSet = [Microsoft.SqlServer.Management.Smo.DatabasePermissionSet] @{
                Connect = $true
                Select = $true
            }

            $null = Set-SqlDscDatabasePermission -ServerObject $script:serverObject -DatabaseName $script:testDatabaseName -Name $script:testLoginName -State 'Grant' -Permission $permissionSet -Force -ErrorAction 'Stop'

            # Verify the permissions were granted
            $permissions = Get-SqlDscDatabasePermission -ServerObject $script:serverObject -DatabaseName $script:testDatabaseName -Name $script:testLoginName -ErrorAction 'Stop'

            $permissions | Should -Not -BeNullOrEmpty
            
            $connectPermission = $permissions | Where-Object { $_.PermissionState -eq 'Grant' -and $_.PermissionType.Connect -eq $true }
            $connectPermission | Should -Not -BeNullOrEmpty
            $connectPermission.PermissionType.Connect | Should -BeTrue

            $selectPermission = $permissions | Where-Object { $_.PermissionState -eq 'Grant' -and $_.PermissionType.Select -eq $true }
            $selectPermission | Should -Not -BeNullOrEmpty
            $selectPermission.PermissionType.Select | Should -BeTrue
        }

        It 'Should grant permissions with WithGrant option' {
            $permissionSet = [Microsoft.SqlServer.Management.Smo.DatabasePermissionSet] @{
                Select = $true
            }

            $null = Set-SqlDscDatabasePermission -ServerObject $script:serverObject -DatabaseName $script:testDatabaseName -Name $script:testLoginName -State 'Grant' -Permission $permissionSet -WithGrant -Force -ErrorAction 'Stop'

            # Verify the permission was granted with grant option
            $permissions = Get-SqlDscDatabasePermission -ServerObject $script:serverObject -DatabaseName $script:testDatabaseName -Name $script:testLoginName -ErrorAction 'Stop'

            $permissions | Should -Not -BeNullOrEmpty
            $grantedPermission = $permissions | Where-Object { $_.PermissionState -eq 'GrantWithGrant' -and $_.PermissionType.Select -eq $true }
            $grantedPermission | Should -Not -BeNullOrEmpty
            $grantedPermission.PermissionType.Select | Should -BeTrue
        }
    }

    Context 'When setting database permissions with Deny state' {
        BeforeEach {
            # Start with clean state
            $permissionSet = [Microsoft.SqlServer.Management.Smo.DatabasePermissionSet] @{
                Update = $true
            }
            $null = Set-SqlDscDatabasePermission -ServerObject $script:serverObject -DatabaseName $script:testDatabaseName -Name $script:testLoginName -State 'Revoke' -Permission $permissionSet -Force -ErrorAction 'SilentlyContinue'
        }

        It 'Should deny Update permission successfully' {
            $permissionSet = [Microsoft.SqlServer.Management.Smo.DatabasePermissionSet] @{
                Update = $true
            }

            $null = Set-SqlDscDatabasePermission -ServerObject $script:serverObject -DatabaseName $script:testDatabaseName -Name $script:testLoginName -State 'Deny' -Permission $permissionSet -Force -ErrorAction 'Stop'

            # Verify the permission was denied
            $permissions = Get-SqlDscDatabasePermission -ServerObject $script:serverObject -DatabaseName $script:testDatabaseName -Name $script:testLoginName -ErrorAction 'Stop'

            $permissions | Should -Not -BeNullOrEmpty
            $deniedPermission = $permissions | Where-Object { $_.PermissionState -eq 'Deny' -and $_.PermissionType.Update -eq $true }
            $deniedPermission | Should -Not -BeNullOrEmpty
            $deniedPermission.PermissionType.Update | Should -BeTrue
        }
    }

    Context 'When setting database permissions with Revoke state' {
        BeforeEach {
            # Grant a permission first to then revoke it
            $permissionSet = [Microsoft.SqlServer.Management.Smo.DatabasePermissionSet] @{
                Insert = $true
            }
            $null = Set-SqlDscDatabasePermission -ServerObject $script:serverObject -DatabaseName $script:testDatabaseName -Name $script:testLoginName -State 'Grant' -Permission $permissionSet -Force -ErrorAction 'Stop'
        }

        It 'Should revoke Insert permission successfully' {
            $permissionSet = [Microsoft.SqlServer.Management.Smo.DatabasePermissionSet] @{
                Insert = $true
            }

            $null = Set-SqlDscDatabasePermission -ServerObject $script:serverObject -DatabaseName $script:testDatabaseName -Name $script:testLoginName -State 'Revoke' -Permission $permissionSet -Force -ErrorAction 'Stop'

            # Verify the permission was revoked (should not appear in granted permissions)
            $permissions = Get-SqlDscDatabasePermission -ServerObject $script:serverObject -DatabaseName $script:testDatabaseName -Name $script:testLoginName -ErrorAction 'Stop'

            if ($permissions)
            {
                $insertPermission = $permissions | Where-Object { $_.PermissionType.Insert -eq $true }
                $insertPermission | Should -BeNullOrEmpty
            }
        }

        It 'Should revoke permissions with WithGrant option to cascade revocation' {
            # First grant with grant option
            $permissionSet = [Microsoft.SqlServer.Management.Smo.DatabasePermissionSet] @{
                Delete = $true
            }
            $null = Set-SqlDscDatabasePermission -ServerObject $script:serverObject -DatabaseName $script:testDatabaseName -Name $script:testLoginName -State 'Grant' -Permission $permissionSet -WithGrant -Force -ErrorAction 'Stop'

            # Then revoke with WithGrant to cascade
            $null = Set-SqlDscDatabasePermission -ServerObject $script:serverObject -DatabaseName $script:testDatabaseName -Name $script:testLoginName -State 'Revoke' -Permission $permissionSet -WithGrant -Force -ErrorAction 'Stop'

            # Verify the permission was revoked (should not appear in permissions)
            $permissions = Get-SqlDscDatabasePermission -ServerObject $script:serverObject -DatabaseName $script:testDatabaseName -Name $script:testLoginName -ErrorAction 'Stop'

            if ($permissions)
            {
                $deletePermission = $permissions | Where-Object { $_.PermissionType.Delete -eq $true }
                $deletePermission | Should -BeNullOrEmpty
            }
        }
    }

    Context 'When setting database permissions through pipeline' {
        BeforeEach {
            # Clean state
            $permissionSet = [Microsoft.SqlServer.Management.Smo.DatabasePermissionSet] @{
                Execute = $true
            }
            $null = Set-SqlDscDatabasePermission -ServerObject $script:serverObject -DatabaseName $script:testDatabaseName -Name $script:testLoginName -State 'Revoke' -Permission $permissionSet -Force -ErrorAction 'SilentlyContinue'
        }

        It 'Should accept ServerObject from pipeline' {
            $permissionSet = [Microsoft.SqlServer.Management.Smo.DatabasePermissionSet] @{
                Execute = $true
            }

            $null = $script:serverObject | Set-SqlDscDatabasePermission -DatabaseName $script:testDatabaseName -Name $script:testLoginName -State 'Grant' -Permission $permissionSet -Force -ErrorAction 'Stop'

            # Verify the permission was granted
            $permissions = Get-SqlDscDatabasePermission -ServerObject $script:serverObject -DatabaseName $script:testDatabaseName -Name $script:testLoginName -ErrorAction 'Stop'

            $permissions | Should -Not -BeNullOrEmpty
            $grantedPermission = $permissions | Where-Object { $_.PermissionState -eq 'Grant' -and $_.PermissionType.Execute -eq $true }
            $grantedPermission | Should -Not -BeNullOrEmpty
            $grantedPermission.PermissionType.Execute | Should -BeTrue
        }
    }

    Context 'When setting database permissions with error conditions' {
        It 'Should throw an error when database does not exist' {
            $permissionSet = [Microsoft.SqlServer.Management.Smo.DatabasePermissionSet] @{
                Connect = $true
            }

            { Set-SqlDscDatabasePermission -ServerObject $script:serverObject -DatabaseName 'NonExistentDatabase' -Name $script:testLoginName -State 'Grant' -Permission $permissionSet -Force -ErrorAction 'Stop' } | Should -Throw -ExpectedMessage '*database*'
        }

        It 'Should throw an error when database principal does not exist' {
            $permissionSet = [Microsoft.SqlServer.Management.Smo.DatabasePermissionSet] @{
                Connect = $true
            }

            { Set-SqlDscDatabasePermission -ServerObject $script:serverObject -DatabaseName $script:testDatabaseName -Name 'NonExistentPrincipal' -State 'Grant' -Permission $permissionSet -Force -ErrorAction 'Stop' } | Should -Throw -ExpectedMessage '*principal*'
        }
    }
}