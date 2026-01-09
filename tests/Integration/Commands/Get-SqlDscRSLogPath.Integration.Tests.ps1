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

    Import-Module -Name $script:moduleName -ErrorAction 'Stop'
}

Describe 'Get-SqlDscRSLogPath' {
    Context 'When getting the log path for SQL Server Reporting Services instance' -Tag @('Integration_SQL2019_RS', 'Integration_SQL2022_RS') {
        It 'Should return the correct log path for SSRS instance' {
            $result = Get-SqlDscRSLogPath -InstanceName 'SSRS' -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result | Should -Be 'C:\Program Files\SSRS\SSRS\LogFiles'
            Test-Path -Path $result | Should -BeTrue
        }

        It 'Should return a path that contains log files' {
            $logPath = Get-SqlDscRSLogPath -InstanceName 'SSRS' -ErrorAction 'Stop'

            $logFiles = Get-ChildItem -Path $logPath -Filter '*.log' -ErrorAction SilentlyContinue

            # After initialization, there should be log files
            $logFiles | Should -Not -BeNullOrEmpty
        }

        It 'Should work with pipeline input from Get-SqlDscRSConfiguration' {
            $result = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop' | Get-SqlDscRSLogPath -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result | Should -Be 'C:\Program Files\SSRS\SSRS\LogFiles'
            Test-Path -Path $result | Should -BeTrue
        }
    }

    Context 'When getting the log path for Power BI Report Server instance' -Tag @('Integration_PowerBI') {
        # cSpell: ignore PBIRS
        It 'Should return the correct log path for PBIRS instance' {
            $result = Get-SqlDscRSLogPath -InstanceName 'PBIRS' -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result | Should -Be 'C:\Program Files\PBIRS\PBIRS\LogFiles'
            Test-Path -Path $result | Should -BeTrue
        }

        It 'Should return a path that contains log files' {
            $logPath = Get-SqlDscRSLogPath -InstanceName 'PBIRS' -ErrorAction 'Stop'

            $logFiles = Get-ChildItem -Path $logPath -Filter '*.log' -ErrorAction SilentlyContinue

            # After initialization, there should be log files
            $logFiles | Should -Not -BeNullOrEmpty
        }

        It 'Should work with pipeline input from Get-SqlDscRSConfiguration' {
            $result = Get-SqlDscRSConfiguration -InstanceName 'PBIRS' -ErrorAction 'Stop' | Get-SqlDscRSLogPath -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result | Should -Be 'C:\Program Files\PBIRS\PBIRS\LogFiles'
            Test-Path -Path $result | Should -BeTrue
        }
    }

    Context 'When trying to get the log path for a non-existent instance' -Tag @('Integration_SQL2019_RS', 'Integration_SQL2022_RS', 'Integration_PowerBI') {
        It 'Should throw a terminating error' {
            { Get-SqlDscRSLogPath -InstanceName 'NonExistentInstance' -ErrorAction 'Stop' } | Should -Throw
        }
    }
}
