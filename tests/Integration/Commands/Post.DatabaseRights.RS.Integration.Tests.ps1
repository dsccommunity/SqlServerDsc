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

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '../../TestHelpers/CommonTestHelper.psm1')

    # Do not use -Force. Doing so, or unloading the module in AfterAll, causes
    # PowerShell class types to get new identities, breaking type comparisons.
    Import-Module -Name $script:moduleName -ErrorAction 'Stop'
}

<#
    .NOTES
        This test file grants database rights to the new service account after
        the service account has been changed. The new service account needs
        database permissions to access the ReportServer and ReportServerTempDB
        databases.

        This test runs after Set-SqlDscRSServiceAccount and Get-SqlDscRSServiceAccount
        tests, and before Post.UrlReservationRecreate.RS to ensure the service
        account has database access before testing accessibility.
#>
Describe 'Post.DatabaseRights.RS' -Tag @('Integration_SQL2017_RS', 'Integration_SQL2019_RS', 'Integration_SQL2022_RS', 'Integration_PowerBI') {
    BeforeAll {
        if (Test-ContinuousIntegrationTaskCategory -Category 'Integration_PowerBI')
        {
            $script:instanceName = 'PBIRS'
        }
        else
        {
            # Default to SSRS for SQL2017_RS, SQL2019_RS, SQL2022_RS
            $script:instanceName = 'SSRS'
        }

        $computerName = Get-ComputerName
        $script:expectedServiceAccount = '{0}\svc-RS' -f $computerName

        $script:configuration = Get-SqlDscRSConfiguration -InstanceName $script:instanceName -ErrorAction 'Stop'

        # Get database name from configuration
        $script:databaseName = $script:configuration.DatabaseName

        Write-Verbose -Message "Instance: $script:instanceName, Database: $script:databaseName, ServiceAccount: $script:expectedServiceAccount" -Verbose
    }

    Context 'When granting database rights to the new service account' {
        It 'Should have the expected service account set' {
            $currentServiceAccount = $script:configuration | Get-SqlDscRSServiceAccount -ErrorAction 'Stop'

            $currentServiceAccount | Should -BeExactly $script:expectedServiceAccount -Because 'the service account should have been changed by Set-SqlDscRSServiceAccount tests'
        }

        It 'Should generate database rights script for the new service account' {
            $script:databaseRightsScript = $script:configuration |
                Request-SqlDscRSDatabaseRightsScript -DatabaseName $script:databaseName -UserName $script:expectedServiceAccount -ErrorAction 'Stop'

            $script:databaseRightsScript | Should -Not -BeNullOrEmpty -Because 'the database rights script should be generated'
        }

        It 'Should execute the database rights script against the database' {
            # Use the RSDB instance that hosts the ReportServer database
            $serverObject = Connect-SqlDscDatabaseEngine -ServerName 'localhost' -InstanceName 'RSDB' -ErrorAction 'Stop'

            try
            {
                $invokeSqlDscQueryParameters = @{
                    ServerName   = 'localhost'
                    InstanceName = 'RSDB'
                    DatabaseName = 'master'
                    Query        = $script:databaseRightsScript
                    Force        = $true
                    ErrorAction  = 'Stop'
                }

                { Invoke-SqlDscQuery @invokeSqlDscQueryParameters } | Should -Not -Throw -Because 'the database rights script should execute successfully'
            }
            finally
            {
                Disconnect-SqlDscDatabaseEngine -ServerObject $serverObject -ErrorAction 'SilentlyContinue'
            }
        }

        It 'Should restart the Reporting Services service to apply changes' {
            $null = $script:configuration | Restart-SqlDscRSService -Force -ErrorAction 'Stop'
        }
    }
}
