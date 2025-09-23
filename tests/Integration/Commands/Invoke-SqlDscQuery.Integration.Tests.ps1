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

Describe 'Invoke-SqlDscQuery' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        $script:mockInstanceName = 'DSCSQLTEST'
        $script:mockComputerName = Get-ComputerName

        $mockSqlAdministratorUserName = 'SqlAdmin' # Using computer name as NetBIOS name throw exception.
        $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

        $script:mockSqlAdminCredential = [System.Management.Automation.PSCredential]::new($mockSqlAdministratorUserName, $mockSqlAdministratorPassword)

        $script:serverObject = Connect-SqlDscDatabaseEngine -InstanceName $script:mockInstanceName -Credential $script:mockSqlAdminCredential

        # Create a test database for our queries
        $script:testDatabaseName = 'SqlDscTestInvokeQuery_' + (Get-Random)
        $null = New-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -Force -ErrorAction 'Stop'

        # Create a test table with some data
        $createTableQuery = @"
CREATE TABLE TestTable (
    ID int IDENTITY(1,1) PRIMARY KEY,
    Name nvarchar(50),
    Value int
)

INSERT INTO TestTable (Name, Value) VALUES ('Test1', 100), ('Test2', 200), ('Test3', 300)
"@

        Invoke-SqlDscQuery -ServerObject $script:serverObject -DatabaseName $script:testDatabaseName -Query $createTableQuery -Force -ErrorAction 'Stop'
    }

    AfterAll {
        # Clean up test database
        if ($script:testDatabaseName)
        {
            try
            {
                Remove-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -Force -ErrorAction 'Stop'
            }
            catch
            {
                Write-Warning -Message "Failed to remove test database '$($script:testDatabaseName)': $($_.Exception.Message)"
            }
        }

        Disconnect-SqlDscDatabaseEngine -ServerObject $script:serverObject
    }

    Context 'When executing a query using ServerObject parameter set' {
        Context 'When executing a query without returning results' {
            It 'Should execute the query without throwing (using Force parameter)' {
                {
                    Invoke-SqlDscQuery -ServerObject $script:serverObject -DatabaseName $script:testDatabaseName -Query 'UPDATE TestTable SET Value = 500 WHERE ID = 1' -Force -ErrorAction 'Stop'
                } | Should -Not -Throw
            }

            It 'Should execute the query without throwing (using Confirm:$false parameter)' {
                {
                    Invoke-SqlDscQuery -ServerObject $script:serverObject -DatabaseName $script:testDatabaseName -Query 'UPDATE TestTable SET Value = 600 WHERE ID = 2' -Confirm:$false -ErrorAction 'Stop'
                } | Should -Not -Throw
            }
        }

        Context 'When executing a query with PassThru parameter' {
            It 'Should return results when using PassThru parameter' {
                $result = Invoke-SqlDscQuery -ServerObject $script:serverObject -DatabaseName $script:testDatabaseName -Query 'SELECT * FROM TestTable' -PassThru -Force -ErrorAction 'Stop'

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType 'System.Data.DataSet'
                $result.Tables[0].Rows.Count | Should -BeGreaterOrEqual 3
            }

            It 'Should return specific results when querying with WHERE clause' {
                $result = Invoke-SqlDscQuery -ServerObject $script:serverObject -DatabaseName $script:testDatabaseName -Query "SELECT Name FROM TestTable WHERE Name = 'Test1'" -PassThru -Force -ErrorAction 'Stop'

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType 'System.Data.DataSet'
                $result.Tables[0].Rows.Count | Should -Be 1
                $result.Tables[0].Rows[0]['Name'] | Should -Be 'Test1'
            }
        }

        Context 'When using optional parameters with ServerObject parameter set' {
            It 'Should execute query with custom StatementTimeout' {
                {
                    Invoke-SqlDscQuery -ServerObject $script:serverObject -DatabaseName $script:testDatabaseName -Query 'SELECT COUNT(*) FROM TestTable' -StatementTimeout 30 -PassThru -Force -ErrorAction 'Stop'
                } | Should -Not -Throw
            }

            It 'Should execute query with RedactText parameter' {
                {
                    Invoke-SqlDscQuery -ServerObject $script:serverObject -DatabaseName $script:testDatabaseName -Query "SELECT * FROM TestTable WHERE Name = 'SensitiveData'" -RedactText @('SensitiveData') -PassThru -Force -ErrorAction 'Stop'
                } | Should -Not -Throw
            }
        }

        Context 'When accepting ServerObject from pipeline' {
            It 'Should execute query when ServerObject is passed through pipeline' {
                $result = $script:serverObject | Invoke-SqlDscQuery -DatabaseName $script:testDatabaseName -Query 'SELECT COUNT(*) as RecordCount FROM TestTable' -PassThru -Force -ErrorAction 'Stop'

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType 'System.Data.DataSet'
                $result.Tables[0].Rows[0]['RecordCount'] | Should -BeGreaterOrEqual 3
            }
        }
    }

    Context 'When executing a query using ByServerName parameter set' {
        Context 'When executing a query without returning results' {
            It 'Should execute the query without throwing' {
                {
                    Invoke-SqlDscQuery -ServerName $script:mockComputerName -InstanceName $script:mockInstanceName -Credential $script:mockSqlAdminCredential -DatabaseName $script:testDatabaseName -Query 'UPDATE TestTable SET Value = 700 WHERE ID = 3' -Force -ErrorAction 'Stop'
                } | Should -Not -Throw
            }
        }

        Context 'When executing a query with PassThru parameter' {
            It 'Should return results when using PassThru parameter' {
                $result = Invoke-SqlDscQuery -ServerName $script:mockComputerName -InstanceName $script:mockInstanceName -Credential $script:mockSqlAdminCredential -DatabaseName $script:testDatabaseName -Query 'SELECT Name, Value FROM TestTable ORDER BY ID' -PassThru -Force -ErrorAction 'Stop'

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType 'System.Data.DataSet'
                $result.Tables[0].Rows.Count | Should -BeGreaterOrEqual 3
            }
        }

        Context 'When using optional parameters with ByServerName parameter set' {
            # Using Encrypt in the CI is not possible until we add the required support (certificate) in the CI.
            It 'Should execute query with Encrypt parameter' -Skip {
                {
                    Invoke-SqlDscQuery -ServerName $script:mockComputerName -InstanceName $script:mockInstanceName -Credential $script:mockSqlAdminCredential -DatabaseName $script:testDatabaseName -Query 'SELECT 1 as TestValue' -Encrypt -PassThru -Force -ErrorAction 'Stop'
                } | Should -Not -Throw
            }

            It 'Should execute query with LoginType parameter' {
                # Create SQL Server credential for 'sa' login
                $sqlLoginPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force
                $sqlLoginCredential = [System.Management.Automation.PSCredential]::new('sa', $sqlLoginPassword)

                {
                    Invoke-SqlDscQuery -ServerName $script:mockComputerName -InstanceName $script:mockInstanceName -Credential $sqlLoginCredential -LoginType 'SqlLogin' -DatabaseName $script:testDatabaseName -Query 'SELECT 1 as TestValue' -PassThru -Force -ErrorAction 'Stop'
                } | Should -Not -Throw
            }

            It 'Should execute query with custom StatementTimeout' {
                {
                    Invoke-SqlDscQuery -ServerName $script:mockComputerName -InstanceName $script:mockInstanceName -Credential $script:mockSqlAdminCredential -DatabaseName $script:testDatabaseName -Query 'SELECT 1 as TestValue' -StatementTimeout 60 -PassThru -Force -ErrorAction 'Stop'
                } | Should -Not -Throw
            }
        }
    }

    Context 'When testing error handling' {
        It 'Should throw error when querying non-existent database' {
            {
                Invoke-SqlDscQuery -ServerObject $script:serverObject -DatabaseName 'NonExistentDatabase' -Query 'SELECT 1' -Force -ErrorAction 'Stop'
            } | Should -Throw
        }

        It 'Should throw error when executing invalid SQL query' {
            {
                Invoke-SqlDscQuery -ServerObject $script:serverObject -DatabaseName $script:testDatabaseName -Query 'INVALID SQL SYNTAX' -Force -ErrorAction 'Stop'
            } | Should -Throw
        }

        It 'Should throw error when querying non-existent table' {
            {
                Invoke-SqlDscQuery -ServerObject $script:serverObject -DatabaseName $script:testDatabaseName -Query 'SELECT * FROM NonExistentTable' -Force -ErrorAction 'Stop'
            } | Should -Throw
        }
    }

    Context 'When testing system databases' {
        It 'Should execute query against master database' {
            $result = Invoke-SqlDscQuery -ServerObject $script:serverObject -DatabaseName 'master' -Query 'SELECT name FROM sys.databases WHERE name = ''master''' -PassThru -Force -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType 'System.Data.DataSet'
            $result.Tables[0].Rows.Count | Should -Be 1
            $result.Tables[0].Rows[0]['name'] | Should -Be 'master'
        }

        It 'Should execute query against msdb database' {
            $result = Invoke-SqlDscQuery -ServerObject $script:serverObject -DatabaseName 'msdb' -Query 'SELECT COUNT(*) as TableCount FROM INFORMATION_SCHEMA.TABLES' -PassThru -Force -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType 'System.Data.DataSet'
            $result.Tables[0].Rows[0]['TableCount'] | Should -BeGreaterThan 0
        }
    }

    Context 'When testing WhatIf functionality' {
        It 'Should not execute query when using WhatIf parameter' {
            # Get initial count
            $initialResult = Invoke-SqlDscQuery -ServerObject $script:serverObject -DatabaseName $script:testDatabaseName -Query 'SELECT COUNT(*) as RecordCount FROM TestTable' -PassThru -Force -ErrorAction 'Stop'
            $initialCount = $initialResult.Tables[0].Rows[0]['RecordCount']

            # Run WhatIf query that would add a record
            $null = Invoke-SqlDscQuery -ServerObject $script:serverObject -DatabaseName $script:testDatabaseName -Query "INSERT INTO TestTable (Name, Value) VALUES ('WhatIfTest', 999)" -WhatIf -ErrorAction 'Stop'

            # Verify count is unchanged
            $finalResult = Invoke-SqlDscQuery -ServerObject $script:serverObject -DatabaseName $script:testDatabaseName -Query 'SELECT COUNT(*) as RecordCount FROM TestTable' -PassThru -Force -ErrorAction 'Stop'
            $finalCount = $finalResult.Tables[0].Rows[0]['RecordCount']

            $finalCount | Should -Be $initialCount
        }
    }
}
