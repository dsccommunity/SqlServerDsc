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

Describe 'Suspend-SqlDscDatabase' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        $script:mockInstanceName = 'DSCSQLTEST'
        $script:mockComputerName = Get-ComputerName

        $mockSqlAdministratorUserName = 'SqlAdmin'
        $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

        $script:mockSqlAdminCredential = [System.Management.Automation.PSCredential]::new($mockSqlAdministratorUserName, $mockSqlAdministratorPassword)

        $script:serverObject = Connect-SqlDscDatabaseEngine -InstanceName $script:mockInstanceName -Credential $script:mockSqlAdminCredential -ErrorAction 'Stop'

        # Test database names
        $script:testDatabaseName = 'SqlDscTestSuspendDb_' + (Get-Random)
        $script:testDatabaseNameForObject = 'SqlDscTestSuspendDbObj_' + (Get-Random)

        # Create test databases
        $null = New-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -Force -ErrorAction 'Stop'
        $null = New-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseNameForObject -Force -ErrorAction 'Stop'

        Write-Verbose -Message "Created test databases '$($script:testDatabaseName)' and '$($script:testDatabaseNameForObject)'." -Verbose
    }

    AfterAll {
        # Clean up test databases
        $testDatabasesToRemove = @($script:testDatabaseName, $script:testDatabaseNameForObject)

        foreach ($dbName in $testDatabasesToRemove)
        {
            $existingDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $dbName -ErrorAction 'SilentlyContinue'

            if ($existingDb)
            {
                # Ensure database is online before removing
                if ($existingDb.Status.HasFlag([Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Offline))
                {
                    $null = Resume-SqlDscDatabase -DatabaseObject $existingDb -Force -ErrorAction 'SilentlyContinue'
                }

                $null = Remove-SqlDscDatabase -DatabaseObject $existingDb -Force -ErrorAction 'Stop'
            }
        }

        Disconnect-SqlDscDatabaseEngine -ServerObject $script:serverObject -ErrorAction 'Stop'
    }

    Context 'When taking a database offline using ServerObject parameter set' {
        It 'Should take the database offline successfully' {
            # Ensure database is online
            $null = Resume-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -Force -ErrorAction 'Stop'

            # Verify database is online
            $onlineDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -Refresh -ErrorAction 'Stop'
            $onlineDb.Status.HasFlag([Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Offline) | Should -BeFalse
            $onlineDb.Status.HasFlag([Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Normal) | Should -BeTrue

            # Take the database offline
            $resultDb = Suspend-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -Force -PassThru -ErrorAction 'Stop'
            $resultDb.Status.HasFlag([Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Offline) | Should -BeTrue

            # Verify the change
            $offlineDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -Refresh -ErrorAction 'Stop'
            $offlineDb.Status.HasFlag([Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Offline) | Should -BeTrue
        }

        It 'Should be idempotent when database is already offline' {
            # Ensure database is offline
            $null = Suspend-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -Force -ErrorAction 'Stop'

            # Take offline again - should not throw
            $null = Suspend-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -Force -ErrorAction 'Stop'

            # Verify the database is still offline
            $offlineDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -Refresh -ErrorAction 'Stop'
            $offlineDb.Status.HasFlag([Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Offline) | Should -BeTrue
        }

        It 'Should throw error when trying to take offline non-existent database' {
            { Suspend-SqlDscDatabase -ServerObject $script:serverObject -Name 'NonExistentDatabase' -Force -ErrorAction 'Stop' } |
                Should -Throw
        }
    }

    Context 'When taking a database offline using DatabaseObject parameter set' {
        It 'Should take the database offline using DatabaseObject' {
            # Ensure database is online
            $null = Resume-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseNameForObject -Force -ErrorAction 'Stop'

            # Get the database object
            $databaseObject = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseNameForObject -Refresh -ErrorAction 'Stop'
            $databaseObject.Status.HasFlag([Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Offline) | Should -BeFalse
            $databaseObject.Status.HasFlag([Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Normal) | Should -BeTrue

            # Take the database offline
            $resultDb = Suspend-SqlDscDatabase -DatabaseObject $databaseObject -Force -PassThru -ErrorAction 'Stop'
            $resultDb.Status.HasFlag([Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Offline) | Should -BeTrue

            # Verify the change
            $offlineDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseNameForObject -Refresh -ErrorAction 'Stop'
            $offlineDb.Status.HasFlag([Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Offline) | Should -BeTrue
        }
    }

    Context 'When using pipeline input' {
        It 'Should take the database offline via pipeline using ServerObject' {
            # Ensure database is online
            $null = Resume-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -Force -ErrorAction 'Stop'

            # Take offline via pipeline
            $resultDb = $script:serverObject | Suspend-SqlDscDatabase -Name $script:testDatabaseName -Force -Refresh -PassThru -ErrorAction 'Stop'
            $resultDb.Status.HasFlag([Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Offline) | Should -BeTrue
        }

        It 'Should take the database offline via pipeline using DatabaseObject' {
            # Ensure database is online
            $null = Resume-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseNameForObject -Force -ErrorAction 'Stop'

            # Get the database object and take offline via pipeline
            $databaseObject = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseNameForObject -Refresh -ErrorAction 'Stop'
            $resultDb = $databaseObject | Suspend-SqlDscDatabase -Force -PassThru -ErrorAction 'Stop'
            $resultDb.Status.HasFlag([Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Offline) | Should -BeTrue
        }
    }

    Context 'When using with Get-SqlDscDatabase' {
        It 'Should take the database offline using Get-SqlDscDatabase piped to Suspend-SqlDscDatabase' {
            # Ensure database is online
            $null = Resume-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -Force -ErrorAction 'Stop'

            # Take offline using pipeline
            $resultDb = $script:serverObject | Get-SqlDscDatabase -Name $script:testDatabaseName | Suspend-SqlDscDatabase -Force -PassThru -ErrorAction 'Stop'
            $resultDb.Status.HasFlag([Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Offline) | Should -BeTrue
        }
    }
}
