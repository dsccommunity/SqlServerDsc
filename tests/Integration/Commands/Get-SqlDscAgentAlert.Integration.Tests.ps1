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
}

AfterAll {
    $env:SqlServerDscCI = $null

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force
}

Describe 'Get-SqlDscAgentAlert' -Tag 'Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022' {
    BeforeAll {
        # Connect to the SQL Server instance
        $script:sqlServerObject = Connect-SqlDscDatabaseEngine -InstanceName $script:sqlServerInstance

        # Clean up any test alerts that might exist from previous runs
        $testAlerts = @(
            'IntegrationTest_GetAlert1',
            'IntegrationTest_GetAlert2'
        )

        foreach ($alertName in $testAlerts)
        {
            $existingAlert = $script:sqlServerObject | Get-SqlDscAgentAlert -Name $alertName -ErrorAction 'SilentlyContinue'
            if ($existingAlert)
            {
                $existingAlert | Remove-SqlDscAgentAlert -Force
            }
        }

        # Create test alerts for getting
        $script:sqlServerObject | New-SqlDscAgentAlert -Name 'IntegrationTest_GetAlert1' -Severity 16
        $script:sqlServerObject | New-SqlDscAgentAlert -Name 'IntegrationTest_GetAlert2' -MessageId 50001
    }

    AfterAll {
        # Clean up test alerts
        $testAlerts = @(
            'IntegrationTest_GetAlert1',
            'IntegrationTest_GetAlert2'
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

    It 'Should get all alerts' {
        $alerts = $script:sqlServerObject | Get-SqlDscAgentAlert

        $alerts | Should -Not -BeNullOrEmpty
        $alerts | Should -BeOfType [Microsoft.SqlServer.Management.Smo.Agent.Alert]
    }

    It 'Should get specific alert by name' {
        $alert = $script:sqlServerObject | Get-SqlDscAgentAlert -Name 'IntegrationTest_GetAlert1'

        $alert | Should -Not -BeNullOrEmpty
        $alert.Name | Should -Be 'IntegrationTest_GetAlert1'
        $alert.Severity | Should -Be 16
    }

    It 'Should return null for non-existent alert' {
        $alert = $script:sqlServerObject | Get-SqlDscAgentAlert -Name 'NonExistentAlert'

        $alert | Should -BeNull
    }

    It 'Should get alert with message ID' {
        $alert = $script:sqlServerObject | Get-SqlDscAgentAlert -Name 'IntegrationTest_GetAlert2'

        $alert | Should -Not -BeNullOrEmpty
        $alert.Name | Should -Be 'IntegrationTest_GetAlert2'
        $alert.MessageId | Should -Be 50001
    }
}
