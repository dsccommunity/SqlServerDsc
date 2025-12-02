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

Describe 'Resume-SqlDscDatabase' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        $script:mockInstanceName = 'DSCSQLTEST'
        $script:mockComputerName = Get-ComputerName

        $mockSqlAdministratorUserName = 'SqlAdmin'
        $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

        $script:mockSqlAdminCredential = [System.Management.Automation.PSCredential]::new($mockSqlAdministratorUserName, $mockSqlAdministratorPassword)

        $script:serverObject = Connect-SqlDscDatabaseEngine -InstanceName $script:mockInstanceName -Credential $script:mockSqlAdminCredential -ErrorAction 'Stop'

        # Test database names
        $script:testDatabaseName = 'SqlDscTestResumeDb_' + (Get-Random)
        $script:testDatabaseNameForObject = 'SqlDscTestResumeDbObj_' + (Get-Random)

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

    Context 'When bringing a database online using ServerObject parameter set' {
        It 'Should bring the database online successfully' {
            # First take the database offline
            $null = Suspend-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -Force -ErrorAction 'Stop'

            # Verify database is offline
            $offlineDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -Refresh -ErrorAction 'Stop'
            $offlineDb.Status.HasFlag([Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Offline) | Should -BeTrue

            # Bring the database online
            $resultDb = Resume-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -Force -PassThru -ErrorAction 'Stop'
            $resultDb.Status | Should -Be ([Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Normal)

            # Verify the change
            $onlineDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -Refresh -ErrorAction 'Stop'
            $onlineDb.Status | Should -Be ([Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Normal)
        }

        It 'Should be idempotent when database is already online' {
            # Ensure database is online
            $null = Resume-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -Force -ErrorAction 'Stop'

            # Bring online again - should not throw
            $null = Resume-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -Force -ErrorAction 'Stop'

            # Verify the database is still online
            $onlineDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -Refresh -ErrorAction 'Stop'
            $onlineDb.Status | Should -Be ([Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Normal)
        }

        It 'Should throw error when trying to bring online non-existent database' {
            { Resume-SqlDscDatabase -ServerObject $script:serverObject -Name 'NonExistentDatabase' -Force -ErrorAction 'Stop' } |
                Should -Throw
        }
    }

    Context 'When bringing a database online using DatabaseObject parameter set' {
        It 'Should bring the database online using DatabaseObject' {
            # First take the database offline
            $null = Suspend-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseNameForObject -Force -ErrorAction 'Stop'

            # Get the database object
            $databaseObject = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseNameForObject -Refresh -ErrorAction 'Stop'
            $databaseObject.Status.HasFlag([Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Offline) | Should -BeTrue

            # Bring the database online
            $resultDb = Resume-SqlDscDatabase -DatabaseObject $databaseObject -Force -PassThru -ErrorAction 'Stop'
            $resultDb.Status | Should -Be ([Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Normal)

            # Verify the change
            $onlineDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseNameForObject -Refresh -ErrorAction 'Stop'
            $onlineDb.Status | Should -Be ([Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Normal)
        }
    }

    Context 'When using pipeline input' {
        It 'Should bring the database online via pipeline using ServerObject' {
            # First take the database offline
            $null = Suspend-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -Force -ErrorAction 'Stop'

            # Bring online via pipeline
            $resultDb = $script:serverObject | Resume-SqlDscDatabase -Name $script:testDatabaseName -Force -PassThru -ErrorAction 'Stop'
            $resultDb.Status | Should -Be ([Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Normal)
        }

        It 'Should bring the database online via pipeline using DatabaseObject' {
            # First take the database offline
            $null = Suspend-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseNameForObject -Force -ErrorAction 'Stop'

            # Get the database object and bring online via pipeline
            $databaseObject = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseNameForObject -Refresh -ErrorAction 'Stop'
            $resultDb = $databaseObject | Resume-SqlDscDatabase -Force -PassThru -ErrorAction 'Stop'
            $resultDb.Status | Should -Be ([Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Normal)
        }
    }

    Context 'When using with Get-SqlDscDatabase' {
        It 'Should bring the database online using Get-SqlDscDatabase piped to Resume-SqlDscDatabase' {
            # First take the database offline
            $null = Suspend-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -Force -ErrorAction 'Stop'

            # Bring online using pipeline
            $resultDb = $script:serverObject | Get-SqlDscDatabase -Name $script:testDatabaseName | Resume-SqlDscDatabase -Force -PassThru -ErrorAction 'Stop'
            $resultDb.Status | Should -Be ([Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Normal)
        }
    }
}
