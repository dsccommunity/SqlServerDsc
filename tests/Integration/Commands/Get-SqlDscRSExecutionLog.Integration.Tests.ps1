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

Describe 'Get-SqlDscRSExecutionLog' {
    Context 'When querying execution log for SQL Server Reporting Services instance' -Tag @('Integration_SQL2019_RS', 'Integration_SQL2022_RS') {
        It 'Should query the execution log without errors' {
            # Query may return empty results if no reports have been executed
            $result = Get-SqlDscRSExecutionLog -InstanceName 'SSRS' -MaxRows 10 -Force -ErrorAction 'Stop'

            Write-Verbose -Message ('Result object: {0}' -f ($result | Out-String)) -Verbose

            # Result may be null if no executions exist, but should not throw
            # If there are results, verify they have expected properties
            if ($result)
            {
                $result[0].PSObject.Properties.Name | Should -Contain 'ItemPath'
                $result[0].PSObject.Properties.Name | Should -Contain 'UserName'
                $result[0].PSObject.Properties.Name | Should -Contain 'TimeStart'
                $result[0].PSObject.Properties.Name | Should -Contain 'Status'
            }
        }

        It 'Should be able to filter by MaxRows' {
            $result = Get-SqlDscRSExecutionLog -InstanceName 'SSRS' -MaxRows 5 -Force -ErrorAction 'Stop'

            Write-Verbose -Message ('Result object: {0}' -f ($result | Out-String)) -Verbose

            if ($result)
            {
                @($result).Count | Should -BeLessOrEqual 5
            }
        }

        It 'Should be able to filter by date range' {
            $startTime = (Get-Date).AddDays(-30)
            $endTime = Get-Date

            # Should not throw with date filters
            $result = Get-SqlDscRSExecutionLog -InstanceName 'SSRS' -StartTime $startTime -EndTime $endTime -MaxRows 10 -Force -ErrorAction 'Stop'

            Write-Verbose -Message ('Result object: {0}' -f ($result | Out-String)) -Verbose

            # Verify all returned entries are within the date range if any exist
            if ($result)
            {
                foreach ($entry in $result)
                {
                    $entry.TimeStart | Should -BeGreaterOrEqual $startTime
                    $entry.TimeStart | Should -BeLessOrEqual $endTime
                }
            }
        }
    }

    Context 'When querying execution log for Power BI Report Server instance' -Tag @('Integration_PowerBI') {
        # cSpell: ignore PBIRS
        It 'Should query the execution log without errors' {
            # Query may return empty results if no reports have been executed
            $result = Get-SqlDscRSExecutionLog -InstanceName 'PBIRS' -MaxRows 10 -Force -ErrorAction 'Stop'

            Write-Verbose -Message ('Result object: {0}' -f ($result | Out-String)) -Verbose

            # Result may be null if no executions exist, but should not throw
            # If there are results, verify they have expected properties
            if ($result)
            {
                $result[0].PSObject.Properties.Name | Should -Contain 'ItemPath'
                $result[0].PSObject.Properties.Name | Should -Contain 'UserName'
                $result[0].PSObject.Properties.Name | Should -Contain 'TimeStart'
                $result[0].PSObject.Properties.Name | Should -Contain 'Status'
            }
        }

        It 'Should be able to filter by MaxRows' {
            $result = Get-SqlDscRSExecutionLog -InstanceName 'PBIRS' -MaxRows 5 -Force -ErrorAction 'Stop'

            Write-Verbose -Message ('Result object: {0}' -f ($result | Out-String)) -Verbose

            if ($result)
            {
                @($result).Count | Should -BeLessOrEqual 5
            }
        }
    }
}
