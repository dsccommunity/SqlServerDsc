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
        This test is marked as potentially destructive because it removes the
        encryption key which will delete all encrypted data.
        Use with caution in test environments only.
#>

<#
    TODO: The following integration tests are skipped on SQL Server 2017 due to
          encryption key validation failures. These tests are linked and all fail
          with similar errors related to "rsCannotValidateEncryptedData" and
          "Keyset does not exist".

          Failing tests on SQL Server 2017:
          - Remove-SqlDscRSEncryptionKey.Integration.Tests.ps1
          - New-SqlDscRSEncryptionKey.Integration.Tests.ps1
          - Post.Reinitialize.RS.Integration.Tests.ps1
          - Post.ServiceAccountChange.RS.Integration.Tests.ps1

          Error: "The report server was unable to validate the integrity of encrypted
          data in the database. (rsCannotValidateEncryptedData);Keyset does not exist
          (Exception from HRESULT: 0x80090016)"
#>
Describe 'Remove-SqlDscRSEncryptionKey' {
    BeforeAll {
        <#
            Wait for SQL Server Reporting Services to be fully operational after we
            remove the encryption key in prior integration tests.

            This is needed because the service seems to take some time to become fully
            operational again, because this integration test fails intermittently.

            There a no known wait mechanism available that we can use to detect when
            the service is fully operational again, so we use a fixed wait time here.

            TODO: Maybe it is possible to poll the file logs or Application event
            log for an event in the command New-SqlDscRSEncryptionKey to determine
            when the service is fully operational again and not return until it is.
        #>
        Write-Verbose -Message 'Workaround. Waiting 2 minutes for SQL Server Reporting Services to become fully operational...' -Verbose
        Start-Sleep -Seconds 60 #300
    }

    Context 'When removing encryption key for SQL Server Reporting Services' -Tag @('Integration_SQL2017_RS') -Skip:$true {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop' -Verbose
        }

        It 'Should remove the encryption key' {
            # Tried using -IncludeEncryptedInformation but it still fails on SQL Server 2017, see TODO above.
            $null = $script:configuration | Remove-SqlDscRSEncryptionKey -Force -ErrorAction 'Stop' -Verbose
        }
    }

    Context 'When removing encryption key for SQL Server Reporting Services' -Tag @('Integration_SQL2019_RS') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop' -Verbose
        }

        It 'Should remove the encryption key' {
            $null = $script:configuration | Remove-SqlDscRSEncryptionKey -Force -ErrorAction 'Stop' -Verbose
        }
    }

    Context 'When removing encryption key for SQL Server Reporting Services' -Tag @('Integration_SQL2022_RS') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop' -Verbose
        }

        It 'Should remove the encryption key' {
            $null = $script:configuration | Remove-SqlDscRSEncryptionKey -Force -ErrorAction 'Stop' -Verbose
        }
    }

    Context 'When removing encryption key for Power BI Report Server' -Tag @('Integration_PowerBI') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'PBIRS' -ErrorAction 'Stop' -Verbose
        }

        It 'Should remove the encryption key' {
            $null = $script:configuration | Remove-SqlDscRSEncryptionKey -Force -ErrorAction 'Stop' -Verbose
        }
    }
}
