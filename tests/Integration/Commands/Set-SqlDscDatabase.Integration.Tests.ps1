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

Describe 'Set-SqlDscDatabase' -Tag @('Integration_SQL2016', 'Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        # Starting the named instance SQL Server service prior to running tests.
        Start-Service -Name 'MSSQL$DSCSQLTEST' -Verbose -ErrorAction 'Stop'

        $script:mockInstanceName = 'DSCSQLTEST'
        $script:mockComputerName = Get-ComputerName

        $mockSqlAdministratorUserName = 'SqlAdmin' # Using computer name as NetBIOS name throw exception.
        $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

        $script:mockSqlAdminCredential = [System.Management.Automation.PSCredential]::new($mockSqlAdministratorUserName, $mockSqlAdministratorPassword)

        $script:serverObject = Connect-SqlDscDatabaseEngine -InstanceName $script:mockInstanceName -Credential $script:mockSqlAdminCredential

        # Test database names
        $script:testDatabaseName = 'SqlDscTestSetDatabase_' + (Get-Random)
        $script:testDatabaseNameForObject = 'SqlDscTestSetDatabaseObj_' + (Get-Random)

        # Create test databases
        New-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -Force -ErrorAction 'Stop'
        New-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseNameForObject -Force -ErrorAction 'Stop'
    }

    AfterAll {
        # Clean up test databases
        $testDatabasesToRemove = @($script:testDatabaseName, $script:testDatabaseNameForObject)

        foreach ($dbName in $testDatabasesToRemove) {
            $existingDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $dbName -ErrorAction 'SilentlyContinue'
            if ($existingDb) {
                Remove-SqlDscDatabase -DatabaseObject $existingDb -Force
            }
        }

        Disconnect-SqlDscDatabaseEngine -ServerObject $script:serverObject

        # Stop the named instance SQL Server service to save memory on the build worker.
        Stop-Service -Name 'MSSQL$DSCSQLTEST' -Verbose -ErrorAction 'Stop'
    }

    Context 'When setting database properties using ServerObject parameter set' {
        It 'Should set recovery model successfully' {
            Set-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -RecoveryModel 'Simple' -Force -ErrorAction 'Stop'

            # Verify the change
            $updatedDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName
            $updatedDb.RecoveryModel | Should -Be 'Simple'
        }

        It 'Should set owner name successfully' {
            Set-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -OwnerName ('{0}\SqlAdmin' -f $script:mockComputerName) -Force -ErrorAction 'Stop'

            # Verify the change
            $updatedDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -ErrorAction 'Stop'
            $updatedDb.Owner | Should -Be ('{0}\SqlAdmin' -f $script:mockComputerName)
        }

        It 'Should set multiple properties successfully' {
            Set-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -RecoveryModel 'Full' -OwnerName ('{0}\SqlAdmin' -f $script:mockComputerName) -Force -ErrorAction 'Stop'

            # Verify the changes
            $updatedDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -ErrorAction 'Stop'
            $updatedDb.RecoveryModel | Should -Be 'Full'
            $updatedDb.Owner | Should -Be ('{0}\SqlAdmin' -f $script:mockComputerName)
        }

        It 'Should throw error when trying to set properties of non-existent database' {
            { Set-SqlDscDatabase -ServerObject $script:serverObject -Name 'NonExistentDatabase' -RecoveryModel 'Simple' -Force -ErrorAction 'Stop' } |
                Should -Throw
        }
    }

    Context 'When setting database properties using DatabaseObject parameter set' {
        It 'Should set recovery model using database object' {
            $databaseObject = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseNameForObject -ErrorAction 'Stop'
            Set-SqlDscDatabase -DatabaseObject $databaseObject -RecoveryModel 'Simple' -Force -ErrorAction 'Stop'

            # Verify the change
            $updatedDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseNameForObject -ErrorAction 'Stop'
            $updatedDb.RecoveryModel | Should -Be 'Simple'
        }

        It 'Should set owner name using database object' {
            $databaseObject = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseNameForObject -ErrorAction 'Stop'
            Set-SqlDscDatabase -DatabaseObject $databaseObject -OwnerName ('{0}\SqlAdmin' -f $script:mockComputerName) -Force -ErrorAction 'Stop'

            # Verify the change
            $updatedDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseNameForObject -ErrorAction 'Stop'
            $updatedDb.Owner | Should -Be ('{0}\SqlAdmin' -f $script:mockComputerName)
        }

        It 'Should support pipeline input with database object' {
            $databaseObject = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseNameForObject -ErrorAction 'Stop'
            $databaseObject | Set-SqlDscDatabase -RecoveryModel 'Full' -Force -ErrorAction 'Stop'

            # Verify the change
            $updatedDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseNameForObject -ErrorAction 'Stop'
            $updatedDb.RecoveryModel | Should -Be 'Full'
        }
    }

    Context 'When using the Refresh parameter' {
        It 'Should refresh the database collection before setting properties' {
            Set-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -RecoveryModel 'BulkLogged' -Refresh -Force -ErrorAction 'Stop'

            # Verify the change
            $updatedDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -ErrorAction 'Stop'
            $updatedDb.RecoveryModel | Should -Be 'BulkLogged'
        }
    }

    Context 'When using the PassThru parameter' {
        It 'Should return the database object when PassThru is specified' {
            $result = Set-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -RecoveryModel 'Simple' -PassThru -Force -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.Database'
            $result.Name | Should -Be $script:testDatabaseName
            $result.RecoveryModel | Should -Be 'Simple'
        }
    }
}
