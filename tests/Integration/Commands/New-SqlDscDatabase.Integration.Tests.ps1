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

Describe 'New-SqlDscDatabase' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        # Starting the named instance SQL Server service prior to running tests.
        Start-Service -Name 'MSSQL$DSCSQLTEST' -Verbose -ErrorAction 'Stop'

        $script:mockInstanceName = 'DSCSQLTEST'
        $script:mockComputerName = Get-ComputerName

        $mockSqlAdministratorUserName = 'SqlAdmin' # Using computer name as NetBIOS name throw exception.
        $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

        $script:mockSqlAdminCredential = [System.Management.Automation.PSCredential]::new($mockSqlAdministratorUserName, $mockSqlAdministratorPassword)

        $script:serverObject = Connect-SqlDscDatabaseEngine -InstanceName $script:mockInstanceName -Credential $script:mockSqlAdminCredential -ErrorAction Stop

        # Test database names
        $script:testDatabaseName = 'SqlDscTestDatabase_' + (Get-Random)
        $script:testDatabaseNameWithProperties = 'SqlDscTestDatabaseWithProps_' + (Get-Random)
    }

    AfterAll {
        # Clean up test databases
        $testDatabasesToRemove = @($script:testDatabaseName, $script:testDatabaseNameWithProperties)

        foreach ($dbName in $testDatabasesToRemove)
        {
            $existingDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $dbName -ErrorAction 'SilentlyContinue'

            if ($existingDb)
            {
                Remove-SqlDscDatabase -DatabaseObject $existingDb -Force
            }
        }

        Disconnect-SqlDscDatabaseEngine -ServerObject $script:serverObject

        # Stop the named instance SQL Server service to save memory on the build worker.
        Stop-Service -Name 'MSSQL$DSCSQLTEST' -Verbose -ErrorAction 'Stop'
    }

    Context 'When creating a new database' {
        It 'Should create a database successfully with minimal parameters' {
            $result = New-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -Force -ErrorAction Stop

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be $script:testDatabaseName
            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.Database'

            # Verify the database exists
            $createdDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -ErrorAction Stop
            $createdDb | Should -Not -BeNullOrEmpty
        }

        It 'Should create a database with specified properties' {
            $result = New-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseNameWithProperties -RecoveryModel 'Simple' -Force -ErrorAction Stop

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be $script:testDatabaseNameWithProperties
            $result.RecoveryModel | Should -Be 'Simple'

            # Verify the database exists with correct properties
            $createdDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseNameWithProperties -ErrorAction Stop
            $createdDb | Should -Not -BeNullOrEmpty
            $createdDb.RecoveryModel | Should -Be 'Simple'
        }

        It 'Should throw error when trying to create a database that already exists' {
            { New-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -Force -ErrorAction Stop } |
                Should -Throw
        }
    }

    Context 'When using the Refresh parameter' {
        It 'Should refresh the database collection before creating' {
            $uniqueName = 'SqlDscTestRefresh_' + (Get-Random)

            try
            {
                $result = New-SqlDscDatabase -ServerObject $script:serverObject -Name $uniqueName -Refresh -Force -ErrorAction Stop

                $result | Should -Not -BeNullOrEmpty
                $result.Name | Should -Be $uniqueName
            }
            finally
            {
                # Clean up
                $dbToRemove = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $uniqueName -ErrorAction 'SilentlyContinue'
                if ($dbToRemove)
                {
                    Remove-SqlDscDatabase -DatabaseObject $dbToRemove -Force
                }
            }
        }
    }
}
