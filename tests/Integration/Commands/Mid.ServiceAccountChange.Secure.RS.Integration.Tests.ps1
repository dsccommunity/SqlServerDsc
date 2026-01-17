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
        This test file runs in the middle of the service account change workflow
        for the SSL/TLS (Secure) stage. It grants database rights to the new
        service account and restarts the service, which must happen BEFORE
        the encryption key can be restored.

        This runs as part of the Integration_Test_Commands_BIReportServer_Secure
        pipeline stage in the following order:
        1. Pre.ServiceAccountChange.Secure.RS (creates backup directory)
        2. Backup-SqlDscRSEncryptionKey (backs up to persistent path)
        3. Set-SqlDscRSServiceAccount (changes service account)
        4. Get-SqlDscRSServiceAccount (verifies change)
        5. Mid.ServiceAccountChange.Secure.RS (this file - grants database rights)
        6. Restore-SqlDscRSEncryptionKey (restores from persistent path)
        7. Post.ServiceAccountChange.Secure.RS (URL reservations, re-init, validation)
#>
Describe 'Mid.ServiceAccountChange.Secure.RS' -Tag @('Integration_PowerBI') {
    BeforeAll {
        $script:instanceName = 'PBIRS'
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

        It 'Should have the expected service account set' {
            $script:serviceAccount | Should -BeExactly $script:expectedServiceAccount -Because 'the service account should have been changed by Set-SqlDscRSServiceAccount'
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
}
