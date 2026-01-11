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

Describe 'Get-SqlDscRSDatabaseInstallation' {
    Context 'When getting database installation status for SQL Server Reporting Services' -Tag @('Integration_SQL2017_RS') {
        BeforeAll {
            $script:expectedMachineName = Get-ComputerName
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'
            $script:expectedInstallationID = $script:configuration.InstallationID
        }

        It 'Should return database installation information' {
            $result = @($script:configuration | Get-SqlDscRSDatabaseInstallation -ErrorAction 'Stop')

            $result | Should -Not -BeNullOrEmpty
            $result | Should -HaveCount 1
            $result[0].MachineName | Should -Be $script:expectedMachineName
            $result[0].InstanceName | Should -Be 'SSRS'
            $result[0].IsInitialized | Should -BeTrue
            $result[0].InstallationID | Should -Be $script:expectedInstallationID
        }

        It 'Should return the same installation ID on subsequent calls' {
            $result = @($script:configuration | Get-SqlDscRSDatabaseInstallation -ErrorAction 'Stop')

            $result[0].InstallationID | Should -Be $script:expectedInstallationID
        }
    }

    Context 'When getting database installation status for SQL Server Reporting Services' -Tag @('Integration_SQL2019_RS') {
        BeforeAll {
            $script:expectedMachineName = Get-ComputerName
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'
            $script:expectedInstallationID = $script:configuration.InstallationID
        }

        It 'Should return database installation information' {
            $result = @($script:configuration | Get-SqlDscRSDatabaseInstallation -ErrorAction 'Stop')

            $result | Should -Not -BeNullOrEmpty
            $result | Should -HaveCount 1
            $result[0].MachineName | Should -Be $script:expectedMachineName
            $result[0].InstanceName | Should -Be 'SSRS'
            $result[0].IsInitialized | Should -BeTrue
            $result[0].InstallationID | Should -Be $script:expectedInstallationID
        }

        It 'Should return the same installation ID on subsequent calls' {
            $result = @($script:configuration | Get-SqlDscRSDatabaseInstallation -ErrorAction 'Stop')

            $result[0].InstallationID | Should -Be $script:expectedInstallationID
        }
    }

    Context 'When getting database installation status for SQL Server Reporting Services' -Tag @('Integration_SQL2022_RS') {
        BeforeAll {
            $script:expectedMachineName = Get-ComputerName
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'
            $script:expectedInstallationID = $script:configuration.InstallationID
        }

        It 'Should return database installation information' {
            $result = @($script:configuration | Get-SqlDscRSDatabaseInstallation -ErrorAction 'Stop')

            $result | Should -Not -BeNullOrEmpty
            $result | Should -HaveCount 1
            $result[0].MachineName | Should -Be $script:expectedMachineName
            $result[0].InstanceName | Should -Be 'SSRS'
            $result[0].IsInitialized | Should -BeTrue
            $result[0].InstallationID | Should -Be $script:expectedInstallationID
        }

        It 'Should return the same installation ID on subsequent calls' {
            $result = @($script:configuration | Get-SqlDscRSDatabaseInstallation -ErrorAction 'Stop')

            $result[0].InstallationID | Should -Be $script:expectedInstallationID
        }
    }

    Context 'When getting database installation status for Power BI Report Server' -Tag @('Integration_PowerBI') {
        BeforeAll {
            $script:expectedMachineName = Get-ComputerName
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'PBIRS' -ErrorAction 'Stop'
            $script:expectedInstallationID = $script:configuration.InstallationID
        }

        It 'Should return database installation information' {
            $result = @($script:configuration | Get-SqlDscRSDatabaseInstallation -ErrorAction 'Stop')

            $result | Should -Not -BeNullOrEmpty
            $result | Should -HaveCount 1
            $result[0].MachineName | Should -Be $script:expectedMachineName
            $result[0].InstanceName | Should -Be 'PBIRS'
            $result[0].IsInitialized | Should -BeTrue
            $result[0].InstallationID | Should -Be $script:expectedInstallationID
        }

        It 'Should return the same installation ID on subsequent calls' {
            $result = @($script:configuration | Get-SqlDscRSDatabaseInstallation -ErrorAction 'Stop')

            $result[0].InstallationID | Should -Be $script:expectedInstallationID
        }
    }
}
