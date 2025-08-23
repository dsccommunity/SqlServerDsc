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
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
    }
}

BeforeAll {
    $script:dscModuleName = 'SqlServerDsc'

    Import-Module -Name $script:dscModuleName -Force -ErrorAction 'Stop'

    $env:SqlServerDscCI = $true

    # Integration tests are run on the DSCSQLTEST instance
    $script:sqlServerInstance = 'DSCSQLTEST'
    $script:sqlServerName = Get-ComputerName
}

AfterAll {
    $env:SqlServerDscCI = $null

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force
}

Describe 'Remove-SqlDscAgentAlert' -Tag 'Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022' {
    BeforeAll {
        # Connect to the SQL Server instance
        $script:sqlServerObject = Connect-SqlDscDatabaseEngine -InstanceName $script:sqlServerInstance
    }

    BeforeEach {
        # Clean up any test alerts that might exist from previous runs
        $testAlerts = @(
            'IntegrationTest_RemoveAlert',
            'IntegrationTest_RemoveAlert2'
        )

        foreach ($alertName in $testAlerts)
        {
            $existingAlert = $script:sqlServerObject | Get-SqlDscAgentAlert -Name $alertName -ErrorAction 'SilentlyContinue'
            if ($existingAlert)
            {
                $existingAlert | Remove-SqlDscAgentAlert -Force
            }
        }
    }

    AfterAll {
        # Clean up test alerts
        $testAlerts = @(
            'IntegrationTest_RemoveAlert',
            'IntegrationTest_RemoveAlert2'
        )

        foreach ($alertName in $testAlerts)
        {
            $existingAlert = $script:sqlServerObject | Get-SqlDscAgentAlert -Name $alertName -ErrorAction 'SilentlyContinue'
            if ($existingAlert)
            {
                $existingAlert | Remove-SqlDscAgentAlert -Force
            }
        }

        # Disconnect from the SQL Server
        Disconnect-SqlDscDatabaseEngine -ServerObject $script:sqlServerObject
    }

    It 'Should remove alert using ServerObject parameter set' {
        # Create alert for this test
        $script:sqlServerObject | New-SqlDscAgentAlert -Name 'IntegrationTest_RemoveAlert' -Severity '16'

        { $script:sqlServerObject | Remove-SqlDscAgentAlert -Name 'IntegrationTest_RemoveAlert' -Force } | Should -Not -Throw

        $alert = $script:sqlServerObject | Get-SqlDscAgentAlert -Name 'IntegrationTest_RemoveAlert'
        $alert | Should -BeNull
    }

    It 'Should remove alert using AlertObject parameter set' {
        # Create a new alert for this test
        $script:sqlServerObject | New-SqlDscAgentAlert -Name 'IntegrationTest_RemoveAlert2' -Severity '16'
        $alert = $script:sqlServerObject | Get-SqlDscAgentAlert -Name 'IntegrationTest_RemoveAlert2'

        { $alert | Remove-SqlDscAgentAlert -Force } | Should -Not -Throw

        $removedAlert = $script:sqlServerObject | Get-SqlDscAgentAlert -Name 'IntegrationTest_RemoveAlert2'
        $removedAlert | Should -BeNull
    }

    It 'Should not throw error when alert does not exist' {
        { $script:sqlServerObject | Remove-SqlDscAgentAlert -Name 'NonExistentAlert' -Force } | Should -Not -Throw
    }
}
