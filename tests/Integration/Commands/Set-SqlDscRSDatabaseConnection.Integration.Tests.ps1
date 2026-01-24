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

# cSpell: ignore RSDB
Describe 'Set-SqlDscRSDatabaseConnection' {
    Context 'When setting database connection for SQL Server Reporting Services' -Tag @('Integration_SQL2017_RS') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'

            # Get the Reporting Services service account from the configuration object.
            $script:serviceAccount = $script:configuration.WindowsServiceIdentityActual

            <#
                Create the report server database on the RSDB SQL Server instance.
                This follows the workflow:
                1. Generate database creation script
                2. Execute script using Invoke-SqlDscQuery
                3. Generate database rights script
                4. Execute rights script using Invoke-SqlDscQuery
            #>

            # Generate and execute database creation script
            $databaseScript = $script:configuration | Request-SqlDscRSDatabaseScript -DatabaseName 'ReportServer' -ErrorAction 'Stop'

            Import-SqlDscPreferredModule -ErrorAction 'Stop'

            Invoke-SqlDscQuery -ServerName 'localhost' -InstanceName 'RSDB' -DatabaseName 'master' -Query $databaseScript -Force -ErrorAction 'Stop'

            # Generate and execute database rights script
            $rightsScript = $script:configuration | Request-SqlDscRSDatabaseRightsScript -DatabaseName 'ReportServer' -UserName $script:serviceAccount -ErrorAction 'Stop'

            Invoke-SqlDscQuery -ServerName 'localhost' -InstanceName 'RSDB' -DatabaseName 'master' -Query $rightsScript -Force -ErrorAction 'Stop'
        }

        It 'Should set the database connection' {
            $script:configuration | Set-SqlDscRSDatabaseConnection -ServerName 'localhost' -InstanceName 'RSDB' -DatabaseName 'ReportServer' -Force -ErrorAction 'Stop'
        }
    }

    Context 'When setting database connection for SQL Server 2019 Reporting Services' -Tag @('Integration_SQL2019_RS') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'

            # Get the Reporting Services service account from the configuration object.
            $script:serviceAccount = $script:configuration.WindowsServiceIdentityActual

            $databaseScript = $script:configuration | Request-SqlDscRSDatabaseScript -DatabaseName 'ReportServer' -ErrorAction 'Stop'

            Import-SqlDscPreferredModule -ErrorAction 'Stop'

            Invoke-SqlDscQuery -ServerName 'localhost' -InstanceName 'RSDB' -DatabaseName 'master' -Query $databaseScript -Force -ErrorAction 'Stop'

            $rightsScript = $script:configuration | Request-SqlDscRSDatabaseRightsScript -DatabaseName 'ReportServer' -UserName $script:serviceAccount -ErrorAction 'Stop'

            Invoke-SqlDscQuery -ServerName 'localhost' -InstanceName 'RSDB' -DatabaseName 'master' -Query $rightsScript -Force -ErrorAction 'Stop'
        }

        It 'Should set the database connection' {
            $script:configuration | Set-SqlDscRSDatabaseConnection -ServerName 'localhost' -InstanceName 'RSDB' -DatabaseName 'ReportServer' -Force -ErrorAction 'Stop'
        }
    }

    Context 'When setting database connection for SQL Server 2022 Reporting Services' -Tag @('Integration_SQL2022_RS') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'

            # Get the Reporting Services service account from the configuration object.
            $script:serviceAccount = $script:configuration.WindowsServiceIdentityActual

            $databaseScript = $script:configuration | Request-SqlDscRSDatabaseScript -DatabaseName 'ReportServer' -ErrorAction 'Stop'

            Import-SqlDscPreferredModule -ErrorAction 'Stop'

            Invoke-SqlDscQuery -ServerName 'localhost' -InstanceName 'RSDB' -DatabaseName 'master' -Query $databaseScript -Force -ErrorAction 'Stop'

            $rightsScript = $script:configuration | Request-SqlDscRSDatabaseRightsScript -DatabaseName 'ReportServer' -UserName $script:serviceAccount -ErrorAction 'Stop'

            Invoke-SqlDscQuery -ServerName 'localhost' -InstanceName 'RSDB' -DatabaseName 'master' -Query $rightsScript -Force -ErrorAction 'Stop'
        }

        It 'Should set the database connection' {
            $script:configuration | Set-SqlDscRSDatabaseConnection -ServerName 'localhost' -InstanceName 'RSDB' -DatabaseName 'ReportServer' -Force -ErrorAction 'Stop'
        }
    }

    Context 'When setting database connection for Power BI Report Server' -Tag @('Integration_PowerBI') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'PBIRS' -ErrorAction 'Stop'

            # Get the Power BI Report Server service account from the configuration object.
            $script:serviceAccount = $script:configuration.WindowsServiceIdentityActual

            $databaseScript = $script:configuration | Request-SqlDscRSDatabaseScript -DatabaseName 'ReportServer' -ErrorAction 'Stop'

            Import-SqlDscPreferredModule -ErrorAction 'Stop'

            Invoke-SqlDscQuery -ServerName 'localhost' -InstanceName 'RSDB' -DatabaseName 'master' -Query $databaseScript -Force -ErrorAction 'Stop'

            $rightsScript = $script:configuration | Request-SqlDscRSDatabaseRightsScript -DatabaseName 'ReportServer' -UserName $script:serviceAccount -ErrorAction 'Stop'

            Invoke-SqlDscQuery -ServerName 'localhost' -InstanceName 'RSDB' -DatabaseName 'master' -Query $rightsScript -Force -ErrorAction 'Stop'
        }

        It 'Should set the database connection' {
            $script:configuration | Set-SqlDscRSDatabaseConnection -ServerName 'localhost' -InstanceName 'RSDB' -DatabaseName 'ReportServer' -Force -ErrorAction 'Stop'
        }
    }
}
