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

    Import-Module -Name $script:moduleName -Force -ErrorAction 'Stop'
}

Describe 'Get-SqlDscDateTime' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        $script:mockInstanceName = 'DSCSQLTEST'
        $script:mockComputerName = Get-ComputerName

        $mockSqlAdministratorUserName = 'SqlAdmin'
        $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

        $script:mockSqlAdminCredential = [System.Management.Automation.PSCredential]::new($mockSqlAdministratorUserName, $mockSqlAdministratorPassword)

        $script:serverObject = Connect-SqlDscDatabaseEngine -InstanceName $script:mockInstanceName -Credential $script:mockSqlAdminCredential
    }

    AfterAll {
        Disconnect-SqlDscDatabaseEngine -ServerObject $script:serverObject -Force
    }

    Context 'When retrieving date and time from SQL Server' {
        Context 'When using default DateTimeFunction parameter' {
            It 'Should return a DateTime value' {
                $result = Get-SqlDscDateTime -ServerObject $script:serverObject -ErrorAction 'Stop'

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType [System.DateTime]

                # Verify the result is close to current time (within 5 minutes)
                $timeDifference = [Math]::Abs(([System.DateTime]::Now - $result).TotalMinutes)
                $timeDifference | Should -BeLessThan 5
            }
        }

        Context 'When using different DateTimeFunction values' {
            It 'Should return a DateTime value using <DateTimeFunction>' -ForEach @(
                @{ DateTimeFunction = 'SYSDATETIME' }
                @{ DateTimeFunction = 'SYSUTCDATETIME' }
                @{ DateTimeFunction = 'GETDATE' }
                @{ DateTimeFunction = 'GETUTCDATE' }
            ) {
                $result = Get-SqlDscDateTime -ServerObject $script:serverObject -DateTimeFunction $DateTimeFunction -ErrorAction 'Stop'

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType [System.DateTime]
            }

            It 'Should return a DateTime value when using SYSDATETIMEOFFSET (converted from DateTimeOffset)' {
                $result = Get-SqlDscDateTime -ServerObject $script:serverObject -DateTimeFunction 'SYSDATETIMEOFFSET' -ErrorAction 'Stop'

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType [System.DateTime]
            }
        }

        Context 'When comparing UTC and local time functions' {
            It 'Should return consistent UTC time when converting local time to UTC' {
                $localTime = Get-SqlDscDateTime -ServerObject $script:serverObject -DateTimeFunction 'SYSDATETIME' -ErrorAction 'Stop'
                $utcTime = Get-SqlDscDateTime -ServerObject $script:serverObject -DateTimeFunction 'SYSUTCDATETIME' -ErrorAction 'Stop'

                $localTime | Should -BeOfType [System.DateTime]
                $utcTime | Should -BeOfType [System.DateTime]

                # Both should be within 1 second of each other when converted to UTC
                $localTimeUtc = $localTime.ToUniversalTime()
                $timeDifference = [Math]::Abs(($localTimeUtc - $utcTime).TotalSeconds)
                $timeDifference | Should -BeLessThan 2
            }
        }

        Context 'When using custom StatementTimeout' {
            It 'Should execute successfully with custom timeout' {
                $result = Get-SqlDscDateTime -ServerObject $script:serverObject -StatementTimeout 30 -ErrorAction 'Stop'

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType [System.DateTime]
            }
        }

        Context 'When passing ServerObject via pipeline' {
            It 'Should execute successfully' {
                $result = $script:serverObject | Get-SqlDscDateTime -ErrorAction 'Stop'

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType [System.DateTime]
            }
        }

        Context 'When verifying clock consistency' {
            It 'Should return consistent times when called multiple times rapidly' {
                $result1 = Get-SqlDscDateTime -ServerObject $script:serverObject -ErrorAction 'Stop'
                $result2 = Get-SqlDscDateTime -ServerObject $script:serverObject -ErrorAction 'Stop'
                $result3 = Get-SqlDscDateTime -ServerObject $script:serverObject -ErrorAction 'Stop'

                # All three calls should be within 2 seconds of each other
                $timeDiff1 = [Math]::Abs(($result2 - $result1).TotalSeconds)
                $timeDiff2 = [Math]::Abs(($result3 - $result2).TotalSeconds)

                $timeDiff1 | Should -BeLessThan 2
                $timeDiff2 | Should -BeLessThan 2
            }
        }
    }
}
