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

Describe 'Set-SqlDscRSDatabaseTimeout' {
    Context 'When setting database timeout for SQL Server Reporting Services' -Tag @('Integration_SQL2017_RS') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'

            # Verbose output the timeouts before changing them
            Write-Verbose "Current DatabaseLogonTimeout: $($script:configuration.DatabaseLogonTimeout)" -Verbose
            Write-Verbose "Current DatabaseQueryTimeout: $($script:configuration.DatabaseQueryTimeout)" -Verbose
        }

        It 'Should not throw when setting LogonTimeout' {
            $null = $script:configuration | Set-SqlDscRSDatabaseTimeout -LogonTimeout 120 -Force -ErrorAction 'Stop'
        }

        It 'Should not throw when setting QueryTimeout' {
            $null = $script:configuration | Set-SqlDscRSDatabaseTimeout -QueryTimeout 120 -Force -ErrorAction 'Stop'
        }

        It 'Should not throw when setting both LogonTimeout and QueryTimeout' {
            $null = $script:configuration | Set-SqlDscRSDatabaseTimeout -LogonTimeout 120 -QueryTimeout 120 -Force -ErrorAction 'Stop'
        }

        It 'Should return the configuration when using PassThru' {
            $result = $script:configuration | Set-SqlDscRSDatabaseTimeout -LogonTimeout 120 -PassThru -Force -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result.InstanceName | Should -Be 'SSRS'
        }
    }

    Context 'When setting database timeout for SQL Server Reporting Services' -Tag @('Integration_SQL2019_RS') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'

            # Verbose output the timeouts before changing them
            Write-Verbose "Current DatabaseLogonTimeout: $($script:configuration.DatabaseLogonTimeout)" -Verbose
            Write-Verbose "Current DatabaseQueryTimeout: $($script:configuration.DatabaseQueryTimeout)" -Verbose
        }

        It 'Should not throw when setting LogonTimeout' {
            $null = $script:configuration | Set-SqlDscRSDatabaseTimeout -LogonTimeout 120 -Force -ErrorAction 'Stop'
        }

        It 'Should not throw when setting QueryTimeout' {
            $null = $script:configuration | Set-SqlDscRSDatabaseTimeout -QueryTimeout 120 -Force -ErrorAction 'Stop'
        }

        It 'Should not throw when setting both LogonTimeout and QueryTimeout' {
            $null = $script:configuration | Set-SqlDscRSDatabaseTimeout -LogonTimeout 120 -QueryTimeout 120 -Force -ErrorAction 'Stop'
        }

        It 'Should return the configuration when using PassThru' {
            $result = $script:configuration | Set-SqlDscRSDatabaseTimeout -LogonTimeout 120 -PassThru -Force -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result.InstanceName | Should -Be 'SSRS'
        }
    }

    Context 'When setting database timeout for SQL Server Reporting Services' -Tag @('Integration_SQL2022_RS') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'

            # Verbose output the timeouts before changing them
            Write-Verbose "Current DatabaseLogonTimeout: $($script:configuration.DatabaseLogonTimeout)" -Verbose
            Write-Verbose "Current DatabaseQueryTimeout: $($script:configuration.DatabaseQueryTimeout)" -Verbose
        }

        It 'Should not throw when setting LogonTimeout' {
            $null = $script:configuration | Set-SqlDscRSDatabaseTimeout -LogonTimeout 120 -Force -ErrorAction 'Stop'
        }

        It 'Should not throw when setting QueryTimeout' {
            $null = $script:configuration | Set-SqlDscRSDatabaseTimeout -QueryTimeout 120 -Force -ErrorAction 'Stop'
        }

        It 'Should not throw when setting both LogonTimeout and QueryTimeout' {
            $null = $script:configuration | Set-SqlDscRSDatabaseTimeout -LogonTimeout 120 -QueryTimeout 120 -Force -ErrorAction 'Stop'
        }

        It 'Should return the configuration when using PassThru' {
            $result = $script:configuration | Set-SqlDscRSDatabaseTimeout -LogonTimeout 120 -PassThru -Force -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result.InstanceName | Should -Be 'SSRS'
        }
    }

    Context 'When setting database timeout for Power BI Report Server' -Tag @('Integration_PowerBI') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'PBIRS' -ErrorAction 'Stop'

            # Verbose output the timeouts before changing them
            Write-Verbose "Current DatabaseLogonTimeout: $($script:configuration.DatabaseLogonTimeout)" -Verbose
            Write-Verbose "Current DatabaseQueryTimeout: $($script:configuration.DatabaseQueryTimeout)" -Verbose
        }

        It 'Should not throw when setting LogonTimeout' {
            $null = $script:configuration | Set-SqlDscRSDatabaseTimeout -LogonTimeout 120 -Force -ErrorAction 'Stop'
        }

        It 'Should not throw when setting QueryTimeout' {
            $null = $script:configuration | Set-SqlDscRSDatabaseTimeout -QueryTimeout 120 -Force -ErrorAction 'Stop'
        }

        It 'Should not throw when setting both LogonTimeout and QueryTimeout' {
            $null = $script:configuration | Set-SqlDscRSDatabaseTimeout -LogonTimeout 120 -QueryTimeout 120 -Force -ErrorAction 'Stop'
        }

        It 'Should return the configuration when using PassThru' {
            $result = $script:configuration | Set-SqlDscRSDatabaseTimeout -LogonTimeout 120 -PassThru -Force -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result.InstanceName | Should -Be 'PBIRS'
        }
    }
}
