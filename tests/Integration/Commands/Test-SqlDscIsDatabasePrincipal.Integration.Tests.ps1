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

Describe 'Test-SqlDscIsDatabasePrincipal' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        # Starting the named instance SQL Server service prior to running tests.
        Start-Service -Name 'MSSQL$DSCSQLTEST' -Verbose -ErrorAction 'Stop'

        $script:mockInstanceName = 'DSCSQLTEST'

        $mockSqlAdministratorUserName = 'SqlAdmin' # Using computer name as NetBIOS name throw exception.
        $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

        $script:mockSqlAdminCredential = [System.Management.Automation.PSCredential]::new($mockSqlAdministratorUserName, $mockSqlAdministratorPassword)

        $script:serverObject = Connect-SqlDscDatabaseEngine -InstanceName $script:mockInstanceName -Credential $script:mockSqlAdminCredential

        # Use a test database that should exist - we'll create it if it doesn't exist
        $script:testDatabaseName = 'IntegrationTestDatabase'
        
        # Create test database if it doesn't exist
        if (-not $script:serverObject.Databases[$script:testDatabaseName])
        {
            New-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -Force -ErrorAction 'Stop'
        }

        # Test principals that should exist in the database
        $script:testUserName = 'IntegrationTestUser'
        $script:testRoleName = 'IntegrationTestRole'
        $script:testAppRoleName = 'IntegrationTestAppRole'
        
        # Create test database user if it doesn't exist
        $testDatabase = $script:serverObject.Databases[$script:testDatabaseName]
        if (-not $testDatabase.Users[$script:testUserName])
        {
            $sqlCommand = "USE [$script:testDatabaseName]; CREATE USER [$script:testUserName] WITHOUT LOGIN;"
            $script:serverObject.ConnectionContext.ExecuteNonQuery($sqlCommand)
        }
        
        # Create test database role if it doesn't exist
        if (-not $testDatabase.Roles[$script:testRoleName])
        {
            $sqlCommand = "USE [$script:testDatabaseName]; CREATE ROLE [$script:testRoleName];"
            $script:serverObject.ConnectionContext.ExecuteNonQuery($sqlCommand)
        }
        
        # Create test application role if it doesn't exist
        if (-not $testDatabase.ApplicationRoles[$script:testAppRoleName])
        {
            $sqlCommand = "USE [$script:testDatabaseName]; CREATE APPLICATION ROLE [$script:testAppRoleName] WITH PASSWORD = 'TestPassword123';"
            $script:serverObject.ConnectionContext.ExecuteNonQuery($sqlCommand)
        }

        # Refresh database objects to ensure they are loaded
        $testDatabase.Users.Refresh()
        $testDatabase.Roles.Refresh()
        $testDatabase.ApplicationRoles.Refresh()
    }

    AfterAll {
        Disconnect-SqlDscDatabaseEngine -ServerObject $script:serverObject

        # Stop the named instance SQL Server service to save memory on the build worker.
        Stop-Service -Name 'MSSQL$DSCSQLTEST' -Verbose -ErrorAction 'Stop'
    }

    Context 'When testing database user existence' {
        It 'Should return True when database user exists' {
            $result = Test-SqlDscIsDatabasePrincipal -ServerObject $script:serverObject -DatabaseName $script:testDatabaseName -Name $script:testUserName

            $result | Should -BeOfType [System.Boolean]
            $result | Should -BeTrue
        }

        It 'Should return False when database user does not exist' {
            $result = Test-SqlDscIsDatabasePrincipal -ServerObject $script:serverObject -DatabaseName $script:testDatabaseName -Name 'NonExistentUser'

            $result | Should -BeOfType [System.Boolean]
            $result | Should -BeFalse
        }

        It 'Should return False when database user exists but ExcludeUsers is specified' {
            $result = Test-SqlDscIsDatabasePrincipal -ServerObject $script:serverObject -DatabaseName $script:testDatabaseName -Name $script:testUserName -ExcludeUsers

            $result | Should -BeOfType [System.Boolean]
            $result | Should -BeFalse
        }

        It 'Should return True for dbo user' {
            $result = Test-SqlDscIsDatabasePrincipal -ServerObject $script:serverObject -DatabaseName $script:testDatabaseName -Name 'dbo'

            $result | Should -BeOfType [System.Boolean]
            $result | Should -BeTrue
        }
    }

    Context 'When testing database role existence' {
        It 'Should return True when database role exists' {
            $result = Test-SqlDscIsDatabasePrincipal -ServerObject $script:serverObject -DatabaseName $script:testDatabaseName -Name $script:testRoleName

            $result | Should -BeOfType [System.Boolean]
            $result | Should -BeTrue
        }

        It 'Should return True when fixed role exists' {
            # Test with built-in db_datareader role
            $result = Test-SqlDscIsDatabasePrincipal -ServerObject $script:serverObject -DatabaseName $script:testDatabaseName -Name 'db_datareader'

            $result | Should -BeOfType [System.Boolean]
            $result | Should -BeTrue
        }

        It 'Should return False when fixed role exists but ExcludeFixedRoles is specified' {
            $result = Test-SqlDscIsDatabasePrincipal -ServerObject $script:serverObject -DatabaseName $script:testDatabaseName -Name 'db_datareader' -ExcludeFixedRoles

            $result | Should -BeOfType [System.Boolean]
            $result | Should -BeFalse
        }

        It 'Should return False when database role exists but ExcludeRoles is specified' {
            $result = Test-SqlDscIsDatabasePrincipal -ServerObject $script:serverObject -DatabaseName $script:testDatabaseName -Name $script:testRoleName -ExcludeRoles

            $result | Should -BeOfType [System.Boolean]
            $result | Should -BeFalse
        }

        It 'Should return True for user-defined role when ExcludeFixedRoles is specified' {
            $result = Test-SqlDscIsDatabasePrincipal -ServerObject $script:serverObject -DatabaseName $script:testDatabaseName -Name $script:testRoleName -ExcludeFixedRoles

            $result | Should -BeOfType [System.Boolean]
            $result | Should -BeTrue
        }
    }

    Context 'When testing application role existence' {
        It 'Should return True when application role exists' {
            $result = Test-SqlDscIsDatabasePrincipal -ServerObject $script:serverObject -DatabaseName $script:testDatabaseName -Name $script:testAppRoleName

            $result | Should -BeOfType [System.Boolean]
            $result | Should -BeTrue
        }

        It 'Should return False when application role exists but ExcludeApplicationRoles is specified' {
            $result = Test-SqlDscIsDatabasePrincipal -ServerObject $script:serverObject -DatabaseName $script:testDatabaseName -Name $script:testAppRoleName -ExcludeApplicationRoles

            $result | Should -BeOfType [System.Boolean]
            $result | Should -BeFalse
        }
    }

    Context 'When testing multiple exclusion parameters' {
        It 'Should return False when principal exists but all types are excluded' {
            $result = Test-SqlDscIsDatabasePrincipal -ServerObject $script:serverObject -DatabaseName $script:testDatabaseName -Name $script:testUserName -ExcludeUsers -ExcludeRoles -ExcludeApplicationRoles

            $result | Should -BeOfType [System.Boolean]
            $result | Should -BeFalse
        }

        It 'Should work with combination of exclusion parameters' {
            # Test role when users and app roles are excluded
            $result = Test-SqlDscIsDatabasePrincipal -ServerObject $script:serverObject -DatabaseName $script:testDatabaseName -Name $script:testRoleName -ExcludeUsers -ExcludeApplicationRoles

            $result | Should -BeOfType [System.Boolean]
            $result | Should -BeTrue
        }
    }

    Context 'When testing pipeline parameter support' {
        It 'Should accept ServerObject from pipeline' {
            $result = $script:serverObject | Test-SqlDscIsDatabasePrincipal -DatabaseName $script:testDatabaseName -Name $script:testUserName

            $result | Should -BeOfType [System.Boolean]
            $result | Should -BeTrue
        }
    }

    Context 'When testing error conditions' {
        It 'Should throw when database does not exist' {
            { Test-SqlDscIsDatabasePrincipal -ServerObject $script:serverObject -DatabaseName 'NonExistentDatabase' -Name 'SomePrincipal' -ErrorAction 'Stop' } | Should -Throw
        }
    }

    Context 'When testing case sensitivity' {
        It 'Should handle case differences correctly for database names' {
            # Database names are case-insensitive in SQL Server
            $result1 = Test-SqlDscIsDatabasePrincipal -ServerObject $script:serverObject -DatabaseName $script:testDatabaseName.ToUpper() -Name $script:testUserName
            $result2 = Test-SqlDscIsDatabasePrincipal -ServerObject $script:serverObject -DatabaseName $script:testDatabaseName.ToLower() -Name $script:testUserName

            $result1 | Should -BeOfType [System.Boolean]
            $result2 | Should -BeOfType [System.Boolean]
            $result1 | Should -Be $result2
        }

        It 'Should handle case differences correctly for principal names' {
            # Principal names are case-insensitive in SQL Server
            $result1 = Test-SqlDscIsDatabasePrincipal -ServerObject $script:serverObject -DatabaseName $script:testDatabaseName -Name $script:testUserName.ToUpper()
            $result2 = Test-SqlDscIsDatabasePrincipal -ServerObject $script:serverObject -DatabaseName $script:testDatabaseName -Name $script:testUserName.ToLower()

            $result1 | Should -BeOfType [System.Boolean]
            $result2 | Should -BeOfType [System.Boolean]
            $result1 | Should -Be $result2
        }
    }
}