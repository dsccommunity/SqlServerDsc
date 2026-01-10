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
        operations for Power BI Report Server.
        After changing the service account, these commands must run in sequence
        to restore site accessibility.

        Power BI Report Server uses the encryption key workflow (Remove-SqlDscRSEncryptionKey
        and New-SqlDscRSEncryptionKey) which works correctly, same as SQL Server 2019+.

        Command sequence:
        1. New-SqlDscLogin - Create SQL login for service account
        2. Request-SqlDscRSDatabaseRightsScript - Generate database rights script
        3. Invoke-SqlDscQuery - Execute database rights script
        4. Restart-SqlDscRSService - Restart service after granting rights
        5. Remove-SqlDscRSEncryptionKey - Remove encryption key
        6. New-SqlDscRSEncryptionKey - Create new encryption key
        7. Set-SqlDscRSUrlReservation -RecreateExisting - Recreate URL reservations
        8. Initialize-SqlDscRS - Re-initialize Reporting Services
        9. Restart-SqlDscRSService - Final service restart
        10. Test-SqlDscRSAccessible - Validate site accessibility
#>
Describe 'Post.ServiceAccountChange.PowerBI.RS' -Tag @('Integration_PowerBI') {
    BeforeAll {
        $script:instanceName = 'PBIRS'
        $script:configuration = Get-SqlDscRSConfiguration -InstanceName $script:instanceName -ErrorAction 'Stop'

        # Get the Reporting Services service account from the configuration object.
        $script:serviceAccount = $script:configuration.WindowsServiceIdentityActual

        # Get database name from configuration
        $script:databaseName = $script:configuration.DatabaseName

        $script:computerName = Get-ComputerName
        $script:expectedServiceAccount = '{0}\svc-PBIRS' -f $script:computerName

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

            Invoke-SqlDscQuery @invokeSqlDscQueryParameters
        }

        It 'Should restart the Reporting Services service after granting rights' {
            $null = $script:configuration | Restart-SqlDscRSService -Force -ErrorAction 'Stop'
        }
    }

    Context 'When regenerating encryption key after service account change' {
        It 'Should remove the encryption key' {
            # Refresh configuration after restart
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName $script:instanceName -ErrorAction 'Stop'

            $null = $script:configuration | Remove-SqlDscRSEncryptionKey -Force -ErrorAction 'Stop'
        }

        It 'Should create a new encryption key' {
            # Refresh configuration after removing encryption key
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName $script:instanceName -ErrorAction 'Stop'

            $null = $script:configuration | New-SqlDscRSEncryptionKey -Force -ErrorAction 'Stop'
        }
    }

    Context 'When recreating URL reservations after service account change' {
        It 'Should recreate all URL reservations' {
            # Refresh configuration after encryption key change
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName $script:instanceName -ErrorAction 'Stop'

            $null = $script:configuration | Set-SqlDscRSUrlReservation -RecreateExisting -Force -ErrorAction 'Stop'
        }
    }

    Context 'When re-initializing Reporting Services after service account change' {
        It 'Should re-initialize the Reporting Services instance' {
            # Refresh configuration
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName $script:instanceName -ErrorAction 'Stop'

            $script:configuration | Initialize-SqlDscRS -Force -ErrorAction 'Stop'
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
