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

Describe 'Request-SqlDscRSDatabaseScript' {
    Context 'When generating database creation script for SQL Server Reporting Services' -Tag @('Integration_SQL2017_RS') {
        BeforeAll {
            <#
                Ensure the Reporting Services service is running before running
                tests. The service may have been stopped by a previous test to
                save memory on the build worker.
            #>
            $service = Get-Service -Name 'SQLServerReportingServices' -ErrorAction 'SilentlyContinue'

            if ($service -and $service.Status -ne 'Running')
            {
                Write-Verbose -Message 'Starting SQLServerReportingServices service...' -Verbose

                Start-Service -Name 'SQLServerReportingServices' -ErrorAction 'Stop'
            }

            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'
        }

        It 'Should generate the database creation script without throwing' {
            { $script:databaseScript = $script:configuration | Request-SqlDscRSDatabaseScript -DatabaseName 'ReportServer' -ErrorAction 'Stop' } | Should -Not -Throw
        }

        It 'Should return a string containing T-SQL' {
            $script:databaseScript | Should -Not -BeNullOrEmpty
            $script:databaseScript | Should -Match 'CREATE DATABASE'
        }
    }

    Context 'When generating database creation script for SQL Server 2019 Reporting Services' -Tag @('Integration_SQL2019_RS') {
        BeforeAll {
            <#
                Ensure the Reporting Services service is running before running
                tests. The service may have been stopped by a previous test to
                save memory on the build worker.
            #>
            $service = Get-Service -Name 'SQLServerReportingServices' -ErrorAction 'SilentlyContinue'

            if ($service -and $service.Status -ne 'Running')
            {
                Write-Verbose -Message 'Starting SQLServerReportingServices service...' -Verbose

                Start-Service -Name 'SQLServerReportingServices' -ErrorAction 'Stop'
            }

            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'
        }

        It 'Should generate the database creation script without throwing' {
            { $script:databaseScript = $script:configuration | Request-SqlDscRSDatabaseScript -DatabaseName 'ReportServer' -ErrorAction 'Stop' } | Should -Not -Throw
        }

        It 'Should return a string containing T-SQL' {
            $script:databaseScript | Should -Not -BeNullOrEmpty
            $script:databaseScript | Should -Match 'CREATE DATABASE'
        }
    }

    Context 'When generating database creation script for SQL Server 2022 Reporting Services' -Tag @('Integration_SQL2022_RS') {
        BeforeAll {
            <#
                Ensure the Reporting Services service is running before running
                tests. The service may have been stopped by a previous test to
                save memory on the build worker.
            #>
            $service = Get-Service -Name 'SQLServerReportingServices' -ErrorAction 'SilentlyContinue'

            if ($service -and $service.Status -ne 'Running')
            {
                Write-Verbose -Message 'Starting SQLServerReportingServices service...' -Verbose

                Start-Service -Name 'SQLServerReportingServices' -ErrorAction 'Stop'
            }

            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'
        }

        It 'Should generate the database creation script without throwing' {
            { $script:databaseScript = $script:configuration | Request-SqlDscRSDatabaseScript -DatabaseName 'ReportServer' -ErrorAction 'Stop' } | Should -Not -Throw
        }

        It 'Should return a string containing T-SQL' {
            $script:databaseScript | Should -Not -BeNullOrEmpty
            $script:databaseScript | Should -Match 'CREATE DATABASE'
        }
    }

    Context 'When generating database creation script for Power BI Report Server' -Tag @('Integration_PowerBI') {
        BeforeAll {
            <#
                Ensure the Power BI Report Server service is running before
                running tests. The service may have been stopped by a previous
                test to save memory on the build worker.
            #>
            $service = Get-Service -Name 'PowerBIReportServer' -ErrorAction 'SilentlyContinue'

            if ($service -and $service.Status -ne 'Running')
            {
                Write-Verbose -Message 'Starting PowerBIReportServer service...' -Verbose

                Start-Service -Name 'PowerBIReportServer' -ErrorAction 'Stop'
            }

            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'PBIRS' -ErrorAction 'Stop'
        }

        It 'Should generate the database creation script without throwing' {
            { $script:databaseScript = $script:configuration | Request-SqlDscRSDatabaseScript -DatabaseName 'ReportServer' -ErrorAction 'Stop' } | Should -Not -Throw
        }

        It 'Should return a string containing T-SQL' {
            $script:databaseScript | Should -Not -BeNullOrEmpty
            $script:databaseScript | Should -Match 'CREATE DATABASE'
        }
    }
}
