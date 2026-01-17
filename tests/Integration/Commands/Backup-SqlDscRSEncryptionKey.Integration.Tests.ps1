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

Describe 'Backup-SqlDscRSEncryptionKey' {

    <#
        .NOTES
            This context is used in the SSL/TLS (Secure) stage service account
            change workflow. It backs up the encryption key to a persistent
            path that will be used by subsequent tests to restore the key
            after the service account has been changed.

            This runs as part of the Integration_Test_Commands_BIReportServer_Secure
            pipeline stage in the following order:
            1. Pre.ServiceAccountChange.Secure.RS (creates backup directory)
            2. Backup-SqlDscRSEncryptionKey (this context - backs up to persistent path)
            3. Set-SqlDscRSServiceAccount (changes service account)
            4. Get-SqlDscRSServiceAccount (verifies change)
            5. Mid.ServiceAccountChange.Secure.RS (grants database rights)
            6. Restore-SqlDscRSEncryptionKey (restores from persistent path)
            7. Post.ServiceAccountChange.Secure.RS (URL reservations, re-init, validation)
    #>
    Context 'When backing up encryption key for Power BI Report Server service account change workflow' -Tag @('Integration_PowerBI') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'PBIRS' -ErrorAction 'Stop'

            # Persistent path for backup file - shared across service account change workflow tests
            $script:backupPath = 'C:\IntegrationTest\RSEncryptionKey.snk'
            $script:securePassword = ConvertTo-SecureString -String 'P@ssw0rd123!' -AsPlainText -Force

            Write-Verbose -Message "Backing up encryption key for service account change workflow to: $script:backupPath" -Verbose
        }

        It 'Should backup the encryption key to a persistent location for the service account change workflow' {
            # Remove any existing backup file from previous test runs
            if (Test-Path -Path $script:backupPath)
            {
                Remove-Item -Path $script:backupPath -Force -ErrorAction 'SilentlyContinue'
            }

            $script:configuration | Backup-SqlDscRSEncryptionKey -Password $script:securePassword -Path $script:backupPath -Force -ErrorAction 'Stop'

            Test-Path -Path $script:backupPath | Should -BeTrue -Because 'the encryption key backup file should be created at the persistent location'
        }

        It 'Should verify the backup file is not empty' {
            $backupFile = Get-Item -Path $script:backupPath -ErrorAction 'Stop'

            $backupFile.Length | Should -BeGreaterThan 0 -Because 'the backup file should contain data'
        }
    }
}
