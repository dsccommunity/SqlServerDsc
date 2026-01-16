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
        This test file performs the final post-service-account-change operations
        for Power BI Report Server in the SSL/TLS (Secure) stage.

        At this point in the workflow:
        - The encryption key has been backed up (by Backup-SqlDscRSEncryptionKey)
        - The service account has been changed (by Set-SqlDscRSServiceAccount)
        - Database rights have been granted (by Mid.ServiceAccountChange.Secure.RS)
        - The encryption key has been restored (by Restore-SqlDscRSEncryptionKey)

        This file completes the workflow by:
        1. Recreating URL reservations
        2. Re-initializing Reporting Services
        3. Restarting the service
        4. Validating site accessibility

        This runs as part of the Integration_Test_Commands_BIReportServer_Secure
        pipeline stage in the following order:
        1. Pre.ServiceAccountChange.Secure.RS (creates backup directory)
        2. Backup-SqlDscRSEncryptionKey (backs up to persistent path)
        3. Set-SqlDscRSServiceAccount (changes service account)
        4. Get-SqlDscRSServiceAccount (verifies change)
        5. Mid.ServiceAccountChange.Secure.RS (grants database rights)
        6. Restore-SqlDscRSEncryptionKey (restores from persistent path)
        7. Post.ServiceAccountChange.Secure.RS (this file - URL reservations, re-init, validation)
#>
Describe 'Post.ServiceAccountChange.Secure.RS' -Tag @('Integration_PowerBI') {
    BeforeAll {
        $script:instanceName = 'PBIRS'
        $script:configuration = Get-SqlDscRSConfiguration -InstanceName $script:instanceName -ErrorAction 'Stop'

        $script:computerName = Get-ComputerName
        $script:expectedServiceAccount = '{0}\svc-RS' -f $script:computerName

        Write-Verbose -Message "Instance: $script:instanceName, ExpectedServiceAccount: $script:expectedServiceAccount" -Verbose
    }

    Context 'When recreating URL reservations after service account change' {
        It 'Should recreate all URL reservations' {
            # Refresh configuration after encryption key restore
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
