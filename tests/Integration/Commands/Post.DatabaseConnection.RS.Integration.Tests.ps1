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
        operations have issues after removing encrypted information.

        This test runs Set-SqlDscRSDatabaseConnection to re-establish the database
        connection after Post.EncryptedInformation.RS.Integration.Tests.ps1 has
        removed encrypted information.

        This test runs after Post.EncryptedInformation.RS.Integration.Tests.ps1.
#>
Describe 'Post.DatabaseConnection.RS' {
    Context 'When re-establishing database connection for SQL Server Reporting Services on SQL Server 2017' -Tag @('Integration_SQL2017_RS') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'

            $script:computerName = Get-ComputerName
        }

        It 'Should set the database connection' {
            $script:configuration | Set-SqlDscRSDatabaseConnection -ServerName $script:computerName -InstanceName 'RSDB' -DatabaseName 'ReportServer' -Force -ErrorAction 'Stop'
        }
    }
}
