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

Describe 'Remove-SqlDscDatabase' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        $script:mockInstanceName = 'DSCSQLTEST'
        $script:mockComputerName = Get-ComputerName

        $mockSqlAdministratorUserName = 'SqlAdmin' # Using computer name as NetBIOS name throw exception.
        $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

        $script:mockSqlAdminCredential = [System.Management.Automation.PSCredential]::new($mockSqlAdministratorUserName, $mockSqlAdministratorPassword)

        $script:serverObject = Connect-SqlDscDatabaseEngine -InstanceName $script:mockInstanceName -Credential $script:mockSqlAdminCredential -ErrorAction 'Stop'
    }

    AfterAll {
        Disconnect-SqlDscDatabaseEngine -ServerObject $script:serverObject
    }

    Context 'When removing a database using ServerObject parameter set' {
        BeforeEach {
            # Create a test database for each test
            $script:testDatabaseName = 'SqlDscTestRemoveDatabase_' + (Get-Random)
            $null = New-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -Force -ErrorAction 'Stop'
        }

        It 'Should remove a database successfully' {
            # Verify database exists before removal
            $existingDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -ErrorAction 'Stop'
            $existingDb | Should -Not -BeNullOrEmpty

            # Remove the database
            $null = Remove-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -Force -ErrorAction 'Stop'

            # Verify database no longer exists
            $removedDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -ErrorAction 'SilentlyContinue'
            $removedDb | Should -BeNullOrEmpty
        }

        It 'Should throw error when trying to remove non-existent database' {
            { Remove-SqlDscDatabase -ServerObject $script:serverObject -Name 'NonExistentDatabase' -Force -ErrorAction 'Stop' } |
                Should -Throw
        }
    }

    Context 'When removing a database using DatabaseObject parameter set' {
        BeforeEach {
            # Create a test database for each test
            $script:testDatabaseNameForObject = 'SqlDscTestRemoveDatabaseObj_' + (Get-Random)
            $null = New-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseNameForObject -Force -ErrorAction 'Stop'
        }

        It 'Should remove a database using database object' {
            $databaseObject = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseNameForObject -ErrorAction 'Stop'
            $databaseObject | Should -Not -BeNullOrEmpty

            # Remove the database using database object
            $null = Remove-SqlDscDatabase -DatabaseObject $databaseObject -Force -ErrorAction 'Stop'

            # Verify database no longer exists
            $removedDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseNameForObject -ErrorAction 'SilentlyContinue'
            $removedDb | Should -BeNullOrEmpty
        }

        It 'Should support pipeline input with database object' {
            $databaseObject = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseNameForObject -ErrorAction 'Stop'
            $databaseObject | Should -Not -BeNullOrEmpty

            # Remove the database using pipeline
            $databaseObject | Remove-SqlDscDatabase -Force -ErrorAction 'Stop'

            # Verify database no longer exists
            $removedDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseNameForObject -ErrorAction 'SilentlyContinue'
            $removedDb | Should -BeNullOrEmpty
        }
    }

    Context 'When attempting to remove system databases' {
        It 'Should throw error when trying to remove master database' {
            { Remove-SqlDscDatabase -ServerObject $script:serverObject -Name 'master' -Force -ErrorAction 'Stop' } |
                Should -Throw
        }

        It 'Should throw error when trying to remove model database' {
            { Remove-SqlDscDatabase -ServerObject $script:serverObject -Name 'model' -Force -ErrorAction 'Stop' } |
                Should -Throw
        }

        It 'Should throw error when trying to remove msdb database' {
            { Remove-SqlDscDatabase -ServerObject $script:serverObject -Name 'msdb' -Force -ErrorAction 'Stop' } |
                Should -Throw
        }

        It 'Should throw error when trying to remove tempdb database' {
            { Remove-SqlDscDatabase -ServerObject $script:serverObject -Name 'tempdb' -Force -ErrorAction 'Stop' } |
                Should -Throw
        }
    }

    Context 'When using the Refresh parameter' {
        BeforeEach {
            # Create a test database for each test
            $script:testDatabaseNameRefresh = 'SqlDscTestRemoveDatabaseRefresh_' + (Get-Random)
            $null = New-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseNameRefresh -Force -ErrorAction 'Stop'
        }

        It 'Should refresh the database collection before removing' {
            # Remove the database with refresh
            $null = Remove-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseNameRefresh -Refresh -Force -ErrorAction 'Stop'

            # Verify database no longer exists
            $removedDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseNameRefresh -ErrorAction 'SilentlyContinue'
            $removedDb | Should -BeNullOrEmpty
        }
    }
}
