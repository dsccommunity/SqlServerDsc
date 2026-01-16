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

    # Do not use -Force. Doing so, or unloading the module in AfterAll, causes
    # PowerShell class types to get new identities, breaking type comparisons.
    Import-Module -Name $script:moduleName -ErrorAction 'Stop'
}

<#
    .NOTES
        This test file prepares for the service account change workflow in the
        SSL/TLS (Secure) stage. It creates the backup directory that will be
        used by subsequent tests.

        The actual encryption key backup is performed by
        Backup-SqlDscRSEncryptionKey.Integration.Tests.ps1 which runs next
        in the pipeline.
#>
Describe 'Pre.ServiceAccountChange.Secure.RS' -Tag @('Integration_PowerBI') {
    Context 'When preparing for service account change with encryption key backup' {
        BeforeAll {
            $script:instanceName = 'PBIRS'

            # Persistent path for backup file - shared across service account change workflow tests
            $script:backupDirectory = 'C:\IntegrationTest'

            Write-Verbose -Message "Instance: $script:instanceName, BackupDirectory: $script:backupDirectory" -Verbose
        }

        It 'Should create the backup directory if it does not exist' {
            if (-not (Test-Path -Path $script:backupDirectory))
            {
                $null = New-Item -Path $script:backupDirectory -ItemType Directory -Force -ErrorAction 'Stop'
            }

            Test-Path -Path $script:backupDirectory | Should -BeTrue -Because 'the backup directory should exist'
        }

        It 'Should verify the Reporting Services instance is configured' {
            $configuration = Get-SqlDscRSConfiguration -InstanceName $script:instanceName -ErrorAction 'Stop'

            $configuration | Should -Not -BeNullOrEmpty -Because 'the RS instance should be configured'
            $configuration.IsInitialized | Should -BeTrue -Because 'the RS instance should be initialized'
        }
    }
}
