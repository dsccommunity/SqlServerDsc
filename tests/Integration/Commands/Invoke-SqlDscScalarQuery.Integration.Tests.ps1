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

    $env:SqlServerDscCI = $true

    # Do not use -Force. Doing so, or unloading the module in AfterAll, causes
    # PowerShell class types to get new identities, breaking type comparisons.
    Import-Module -Name $script:moduleName -ErrorAction 'Stop'
}

AfterAll {
    Remove-Item -Path 'env:SqlServerDscCI' -ErrorAction 'SilentlyContinue'
}

Describe 'Invoke-SqlDscScalarQuery' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        $script:mockInstanceName = 'DSCSQLTEST'
        $script:mockComputerName = Get-ComputerName

        $mockSqlAdministratorUserName = 'SqlAdmin'
        $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

        $script:mockSqlAdminCredential = [System.Management.Automation.PSCredential]::new($mockSqlAdministratorUserName, $mockSqlAdministratorPassword)

        $script:serverObject = Connect-SqlDscDatabaseEngine -InstanceName $script:mockInstanceName -Credential $script:mockSqlAdminCredential
    }

    AfterAll {
        Disconnect-SqlDscDatabaseEngine -ServerObject $script:serverObject -Force
    }

    Context 'When executing a scalar query' {
        Context 'When querying for SQL Server version' {
            It 'Should return the version string' {
                $result = Invoke-SqlDscScalarQuery -ServerObject $script:serverObject -Query 'SELECT @@VERSION' -ErrorAction 'Stop'

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType [System.String]
                $result | Should -BeLike '*Microsoft SQL Server*'
            }
        }

        Context 'When querying for a numeric value' {
            It 'Should return the numeric result' {
                $result = Invoke-SqlDscScalarQuery -ServerObject $script:serverObject -Query 'SELECT 42' -ErrorAction 'Stop'

                $result | Should -Be 42
            }
        }

        Context 'When querying for the current date and time' {
            It 'Should return a DateTime value using SYSDATETIME' {
                $result = Invoke-SqlDscScalarQuery -ServerObject $script:serverObject -Query 'SELECT SYSDATETIME()' -ErrorAction 'Stop'

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType [System.DateTime]
            }

            It 'Should return a DateTime value using GETDATE' {
                $result = Invoke-SqlDscScalarQuery -ServerObject $script:serverObject -Query 'SELECT GETDATE()' -ErrorAction 'Stop'

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType [System.DateTime]
            }

            It 'Should return a DateTimeOffset value using SYSDATETIMEOFFSET' {
                $result = Invoke-SqlDscScalarQuery -ServerObject $script:serverObject -Query 'SELECT SYSDATETIMEOFFSET()' -ErrorAction 'Stop'

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType [System.DateTimeOffset]
            }
        }

        Context 'When querying with a custom timeout' {
            It 'Should execute the query successfully with custom timeout' {
                $result = Invoke-SqlDscScalarQuery -ServerObject $script:serverObject -Query 'SELECT @@SERVERNAME' -StatementTimeout 30 -ErrorAction 'Stop'

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType [System.String]
            }
        }

        Context 'When passing ServerObject via pipeline' {
            It 'Should execute the query successfully' {
                $result = $script:serverObject | Invoke-SqlDscScalarQuery -Query 'SELECT DB_NAME()' -ErrorAction 'Stop'

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType [System.String]
            }
        }

        Context 'When querying for NULL' {
            It 'Should return null' {
                $result = Invoke-SqlDscScalarQuery -ServerObject $script:serverObject -Query 'SELECT NULL' -ErrorAction 'Stop'

                $result | Should -BeNullOrEmpty
            }
        }
    }
}
