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
        This test is marked as potentially destructive because it removes all
        encrypted information stored in the report server database.
        Use with caution in test environments only.
#>

Describe 'Remove-SqlDscRSEncryptedInformation' {
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
        Start-Sleep -Seconds 300
    }

    Context 'When removing encrypted information for SQL Server 2017 Reporting Services' -Tag @('Integration_SQL2017_RS') -Skip:$true {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'
        }

        It 'Should remove the encrypted information' {
            $null = $script:configuration | Remove-SqlDscRSEncryptedInformation -Force -ErrorAction 'Stop'
        }
    }

    Context 'When removing encrypted information for SQL Server 2019 Reporting Services' -Tag @('Integration_SQL2019_RS') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'
        }

        It 'Should remove the encrypted information' {
            $null = $script:configuration | Remove-SqlDscRSEncryptedInformation -Force -ErrorAction 'Stop'
        }
    }

    Context 'When removing encrypted information for SQL Server 2022 Reporting Services' -Tag @('Integration_SQL2022_RS') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'
        }

        It 'Should remove the encrypted information' {
            $null = $script:configuration | Remove-SqlDscRSEncryptedInformation -Force -ErrorAction 'Stop'
        }
    }

    Context 'When removing encrypted information for Power BI Report Server' -Tag @('Integration_PowerBI') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'PBIRS' -ErrorAction 'Stop'
        }

        It 'Should remove the encrypted information' {
            $null = $script:configuration | Remove-SqlDscRSEncryptedInformation -Force -ErrorAction 'Stop'
        }
    }
}
