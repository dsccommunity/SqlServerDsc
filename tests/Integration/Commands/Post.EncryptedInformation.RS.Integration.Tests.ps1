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
        This test is specifically for SQL Server 2017 where the encryption key
        operations (Remove-SqlDscRSEncryptionKey and New-SqlDscRSEncryptionKey)
        fail with "rsCannotValidateEncryptedData" and "Keyset does not exist"
        errors.

        As a workaround for SQL Server 2017, this test removes all encrypted
        information from the report server database using
        Remove-SqlDscRSEncryptedInformation.

        This test runs after Post.DatabaseRights.RS.Integration.Tests.ps1 and
        before New-SqlDscRSEncryptionKey.Integration.Tests.ps1.
#>
Describe 'Post.EncryptedInformation.RS' {
    Context 'When removing encrypted information for SQL Server Reporting Services on SQL Server 2017' -Tag @('Integration_SQL2017_RS') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'
        }

        It 'Should remove the encrypted information' {
            $null = $script:configuration | Remove-SqlDscRSEncryptedInformation -Force -ErrorAction 'Stop'
        }
    }
}
