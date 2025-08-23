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

Describe 'Set-SqlDscAgentAlert' -Tag 'Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022' {
    BeforeAll {
        # Connect to the SQL Server instance
        $script:sqlServerObject = Connect-SqlDscDatabaseEngine -InstanceName $script:sqlServerInstance

        # Clean up any test alerts that might exist from previous runs
        $testAlerts = @(
            'IntegrationTest_UpdateAlert'
        )

        foreach ($alertName in $testAlerts)
        {
            $existingAlert = $script:sqlServerObject | Get-SqlDscAgentAlert -Name $alertName -ErrorAction 'SilentlyContinue'
            if ($existingAlert)
            {
                $existingAlert | Remove-SqlDscAgentAlert -Force
            }
        }

        # Create a test alert for updating
        $script:sqlServerObject | New-SqlDscAgentAlert -Name 'IntegrationTest_UpdateAlert' -Severity '14'
    }

    AfterAll {
        # Clean up test alerts
        $testAlerts = @(
            'IntegrationTest_UpdateAlert'
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

    It 'Should update alert severity using ServerObject parameter set' {
        { $script:sqlServerObject | Set-SqlDscAgentAlert -Name 'IntegrationTest_UpdateAlert' -Severity '16' } | Should -Not -Throw

        $alert = $script:sqlServerObject | Get-SqlDscAgentAlert -Name 'IntegrationTest_UpdateAlert'
        $alert.Severity | Should -Be 16
        $alert.MessageId | Should -Be 0
    }

    It 'Should update alert message ID using ServerObject parameter set' {
        { $script:sqlServerObject | Set-SqlDscAgentAlert -Name 'IntegrationTest_UpdateAlert' -MessageId '50003' } | Should -Not -Throw

        $alert = $script:sqlServerObject | Get-SqlDscAgentAlert -Name 'IntegrationTest_UpdateAlert'
        $alert.MessageId | Should -Be 50003
        $alert.Severity | Should -Be 0
    }

    It 'Should update alert using AlertObject parameter set' {
        # First reset to severity for this test
        $script:sqlServerObject | Set-SqlDscAgentAlert -Name 'IntegrationTest_UpdateAlert' -Severity '14'

        $alert = $script:sqlServerObject | Get-SqlDscAgentAlert -Name 'IntegrationTest_UpdateAlert'

        { $alert | Set-SqlDscAgentAlert -Severity '18' } | Should -Not -Throw

        # Refresh the alert to get updated values
        $updatedAlert = $script:sqlServerObject | Get-SqlDscAgentAlert -Name 'IntegrationTest_UpdateAlert'
        $updatedAlert.Severity | Should -Be 18
        $updatedAlert.MessageId | Should -Be 0
    }

    It 'Should return updated alert when PassThru is specified' {
        $result = $script:sqlServerObject | Set-SqlDscAgentAlert -Name 'IntegrationTest_UpdateAlert' -Severity '20' -PassThru

        $result | Should -Not -BeNullOrEmpty
        $result.Name | Should -Be 'IntegrationTest_UpdateAlert'
        $result.Severity | Should -Be 20
    }

    It 'Should throw error when alert does not exist' {
        { $script:sqlServerObject | Set-SqlDscAgentAlert -Name 'NonExistentAlert' -Severity '16' } |
            Should -Throw -ExpectedMessage '*was not found*'
    }

    It 'Should throw error when both Severity and MessageId are specified' {
        { $script:sqlServerObject | Set-SqlDscAgentAlert -Name 'IntegrationTest_UpdateAlert' -Severity '16' -MessageId '50001' } |
            Should -Throw -ExpectedMessage '*Cannot specify both Severity and MessageId*'
    }
}
