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
        This consolidated test file performs all post-service-account-change
        operations for SQL Server 2017 Reporting Services. After changing the
        service account, these commands must run in sequence to restore site
        accessibility.

        SQL Server 2017 requires a different workflow than SQL Server 2019+
        because the encryption key commands fail with "rsCannotValidateEncryptedData"
        and "Keyset does not exist" errors. Instead, this workflow uses
        Remove-SqlDscRSEncryptedInformation and Set-SqlDscRSDatabaseConnection
        as a workaround.

        Command sequence:
        1. New-SqlDscLogin - Create SQL login for service account
        2. Request-SqlDscRSDatabaseRightsScript - Generate database rights script
        3. Invoke-SqlDscQuery - Execute database rights script
        4. Restart-SqlDscRSService - Restart service after granting rights
        5. Remove-SqlDscRSEncryptedInformation - Remove encrypted info (SQL 2017 workaround)
        6. Set-SqlDscRSDatabaseConnection - Re-establish database connection
        7. Set-SqlDscRSUrlReservation -RecreateExisting - Recreate URL reservations
        8. Initialize-SqlDscRS - Re-initialize Reporting Services
        9. Restart-SqlDscRSService - Final service restart
        10. Test-SqlDscRSAccessible - Validate site accessibility
#>
Describe 'Post.ServiceAccountChange.SQL2017.RS' -Tag @('Integration_SQL2017_RS') {
    BeforeAll {
        $script:instanceName = 'SSRS'
        $script:configuration = Get-SqlDscRSConfiguration -InstanceName $script:instanceName -ErrorAction 'Stop'

        # Get the Reporting Services service account from the configuration object.
        $script:serviceAccount = $script:configuration.WindowsServiceIdentityActual

        # Get database name from configuration
        $script:databaseName = $script:configuration.DatabaseName

        $script:computerName = Get-ComputerName
        $script:expectedServiceAccount = '{0}\svc-RS' -f $script:computerName

        Write-Verbose -Message "Instance: $script:instanceName, Database: $script:databaseName, ServiceAccount: $script:serviceAccount" -Verbose
    }

    Context 'When granting database rights to the new service account' {
        BeforeAll {
            # Connect to the database engine for the RS database instance.
            $script:serverObject = Connect-SqlDscDatabaseEngine -ServerName 'localhost' -InstanceName 'RSDB' -ErrorAction 'Stop'
        }

        AfterAll {
            Disconnect-SqlDscDatabaseEngine -ServerObject $script:serverObject -ErrorAction 'SilentlyContinue'
        }

        It 'Should create a SQL Server login for the new service account' {
            $null = New-SqlDscLogin -ServerObject $script:serverObject -Name $script:serviceAccount -WindowsUser -Force -ErrorAction 'Stop'
        }

        It 'Should generate database rights script for the new service account' {
            $script:databaseRightsScript = $script:configuration |
                Request-SqlDscRSDatabaseRightsScript -DatabaseName $script:databaseName -UserName $script:serviceAccount -ErrorAction 'Stop'

            $script:databaseRightsScript | Should -Not -BeNullOrEmpty -Because 'the database rights script should be generated'
        }

        It 'Should execute the database rights script against the database' {
            $invokeSqlDscQueryParameters = @{
                ServerName   = 'localhost'
                InstanceName = 'RSDB'
                DatabaseName = 'master'
                Query        = $script:databaseRightsScript
                Force        = $true
                ErrorAction  = 'Stop'
            }

            $null = Invoke-SqlDscQuery @invokeSqlDscQueryParameters
        }

        It 'Should restart the Reporting Services service after granting rights' {
            $null = $script:configuration | Restart-SqlDscRSService -Force -ErrorAction 'Stop'
        }
    }

    Context 'When removing encrypted information (SQL Server 2017 workaround)' {
        It 'Should remove the encrypted information' {
            # Refresh configuration after restart
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName $script:instanceName -ErrorAction 'Stop'

            $null = $script:configuration | Remove-SqlDscRSEncryptedInformation -Force -ErrorAction 'Stop'
        }

        It 'Should re-establish the database connection' {
            # Refresh configuration after removing encrypted information
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName $script:instanceName -ErrorAction 'Stop'

            $null = $script:configuration | Set-SqlDscRSDatabaseConnection -ServerName $script:computerName -InstanceName 'RSDB' -DatabaseName $script:databaseName -Force -ErrorAction 'Stop'
        }
    }

    Context 'When recreating URL reservations after service account change' {
        It 'Should recreate all URL reservations' {
            # Refresh configuration after database connection change
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName $script:instanceName -ErrorAction 'Stop'

            $null = $script:configuration | Set-SqlDscRSUrlReservation -RecreateExisting -Force -ErrorAction 'Stop'
        }
    }

    Context 'When re-initializing Reporting Services after service account change' {
        It 'Should re-initialize the Reporting Services instance' {
            # Refresh configuration
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName $script:instanceName -ErrorAction 'Stop'

            $null = $script:configuration | Initialize-SqlDscRS -Force -ErrorAction 'Stop'
        }

        It 'Should have an initialized instance after re-initialization' {
            $configuration = Get-SqlDscRSConfiguration -InstanceName $script:instanceName -ErrorAction 'Stop'

            $isInitialized = $configuration | Test-SqlDscRSInitialized -ErrorAction 'Stop'

            $isInitialized | Should -BeTrue -Because 'the instance should be initialized after re-initialization'
        }

        It 'Should restart the Reporting Services service' {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName $script:instanceName -ErrorAction 'Stop'

            $null = $script:configuration | Restart-SqlDscRSService -Force -ErrorAction 'Stop'
        }
    }

    Context 'When validating Reporting Services accessibility after service account change' {
        It 'Should have the expected service account set' {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName $script:instanceName -ErrorAction 'Stop'

            $currentServiceAccount = $script:configuration | Get-SqlDscRSServiceAccount -ErrorAction 'Stop'

            $currentServiceAccount | Should -BeExactly $script:expectedServiceAccount -Because 'the service account should have been changed'
        }

        It 'Should have an initialized instance' {
            $isInitialized = $script:configuration | Test-SqlDscRSInitialized -ErrorAction 'Stop'

            $isInitialized | Should -BeTrue -Because 'the instance should remain initialized after service account change'
        }

        It 'Should have all configured sites accessible after service account change' {
            $results = $script:configuration | Test-SqlDscRSAccessible -Detailed -TimeoutSeconds 240 -RetryIntervalSeconds 10 -ErrorAction 'Stop' -Verbose

            Write-Verbose -Message "Accessibility results: $($results | ConvertTo-Json -Compress)" -Verbose

            $urlReservations = $script:configuration | Get-SqlDscRSUrlReservation -ErrorAction 'Stop'
            $expectedApplications = $urlReservations.Application | Select-Object -Unique

            $results | Should -Not -BeNullOrEmpty -Because 'the command should return site accessibility results'

            foreach ($application in $expectedApplications)
            {
                $siteResult = $results | Where-Object -FilterScript { $_.Site -eq $application }

                $siteResult | Should -Not -BeNullOrEmpty -Because "the '$application' site should have a result"
                $siteResult.Accessible | Should -BeTrue -Because "the '$application' site should be accessible after service account change"
                $siteResult.StatusCode | Should -Be 200 -Because "the '$application' site should return HTTP 200 after service account change"
            }
        }
    }
}
