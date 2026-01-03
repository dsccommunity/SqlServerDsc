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

Describe 'Request-SqlDscRSDatabaseRightsScript' {
    Context 'When generating database rights script for SQL Server Reporting Services' -Tag @('Integration_SQL2017_RS') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'

            # Get the Reporting Services service account
            $script:rsService = Get-SqlDscManagedComputerService -ServiceType 'ReportingServices'
            $script:serviceAccount = $script:rsService.ServiceAccount
        }

        It 'Should generate the database rights script without throwing' {
            { $script:rightsScript = $script:configuration | Request-SqlDscRSDatabaseRightsScript -DatabaseName 'ReportServer' -UserName $script:serviceAccount -ErrorAction 'Stop' } | Should -Not -Throw
        }

        It 'Should return a string containing T-SQL' {
            $script:rightsScript | Should -Not -BeNullOrEmpty
            # The script should contain permission grants
            $script:rightsScript | Should -Match 'GRANT|CREATE USER|ALTER'
        }
    }

    Context 'When generating database rights script for SQL Server 2019 Reporting Services' -Tag @('Integration_SQL2019_RS') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'

            # Get the Reporting Services service account
            $script:rsService = Get-SqlDscManagedComputerService -ServiceType 'ReportingServices'
            $script:serviceAccount = $script:rsService.ServiceAccount
        }

        It 'Should generate the database rights script without throwing' {
            { $script:rightsScript = $script:configuration | Request-SqlDscRSDatabaseRightsScript -DatabaseName 'ReportServer' -UserName $script:serviceAccount -ErrorAction 'Stop' } | Should -Not -Throw
        }

        It 'Should return a string containing T-SQL' {
            $script:rightsScript | Should -Not -BeNullOrEmpty
            $script:rightsScript | Should -Match 'GRANT|CREATE USER|ALTER'
        }
    }

    Context 'When generating database rights script for SQL Server 2022 Reporting Services' -Tag @('Integration_SQL2022_RS') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'

            # Get the Reporting Services service account
            $script:rsService = Get-SqlDscManagedComputerService -ServiceType 'ReportingServices'
            $script:serviceAccount = $script:rsService.ServiceAccount
        }

        It 'Should generate the database rights script without throwing' {
            { $script:rightsScript = $script:configuration | Request-SqlDscRSDatabaseRightsScript -DatabaseName 'ReportServer' -UserName $script:serviceAccount -ErrorAction 'Stop' } | Should -Not -Throw
        }

        It 'Should return a string containing T-SQL' {
            $script:rightsScript | Should -Not -BeNullOrEmpty
            $script:rightsScript | Should -Match 'GRANT|CREATE USER|ALTER'
        }
    }

    Context 'When generating database rights script for Power BI Report Server' -Tag @('Integration_PowerBI') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'PBIRS' -ErrorAction 'Stop'

            # Get the Power BI Report Server service account
            $script:rsService = Get-SqlDscManagedComputerService -ServiceType 'ReportingServices'
            $script:serviceAccount = $script:rsService.ServiceAccount
        }

        It 'Should generate the database rights script without throwing' {
            { $script:rightsScript = $script:configuration | Request-SqlDscRSDatabaseRightsScript -DatabaseName 'ReportServer' -UserName $script:serviceAccount -ErrorAction 'Stop' } | Should -Not -Throw
        }

        It 'Should return a string containing T-SQL' {
            $script:rightsScript | Should -Not -BeNullOrEmpty
            $script:rightsScript | Should -Match 'GRANT|CREATE USER|ALTER'
        }
    }
}
