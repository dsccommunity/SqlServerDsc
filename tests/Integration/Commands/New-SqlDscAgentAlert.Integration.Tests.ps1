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

Describe 'New-SqlDscAgentAlert' -Tag 'Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022' {
    BeforeAll {
        # Connect to the SQL Server instance
        $script:sqlServerObject = Connect-SqlDscDatabaseEngine -InstanceName $script:sqlServerInstance
    }

    BeforeEach {
        # Clean up any test alerts that might exist from previous runs
        $testAlerts = @(
            'IntegrationTest_SeverityAlert',
            'IntegrationTest_MessageIdAlert',
            'IntegrationTest_PassThruAlert',
            'IntegrationTest_DuplicateAlert',
            'IntegrationTest_InvalidAlert'
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
            'IntegrationTest_SeverityAlert',
            'IntegrationTest_MessageIdAlert',
            'IntegrationTest_PassThruAlert',
            'IntegrationTest_DuplicateAlert',
            'IntegrationTest_InvalidAlert'
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

    It 'Should create alert with severity' {
        $null = $script:sqlServerObject | New-SqlDscAgentAlert -Name 'IntegrationTest_SeverityAlert' -Severity 14 -ErrorAction Stop

        $alert = $script:sqlServerObject | Get-SqlDscAgentAlert -Name 'IntegrationTest_SeverityAlert'
        $alert | Should -Not -BeNullOrEmpty
        $alert.Name | Should -Be 'IntegrationTest_SeverityAlert'
        $alert.Severity | Should -Be 14
    }

    It 'Should create alert with message ID' {
        $null = $script:sqlServerObject | New-SqlDscAgentAlert -Name 'IntegrationTest_MessageIdAlert' -MessageId 50002 -ErrorAction Stop

        $alert = $script:sqlServerObject | Get-SqlDscAgentAlert -Name 'IntegrationTest_MessageIdAlert'
        $alert | Should -Not -BeNullOrEmpty
        $alert.Name | Should -Be 'IntegrationTest_MessageIdAlert'
        $alert.MessageId | Should -Be 50002
    }

    It 'Should return alert object when PassThru is specified' {
        $result = $script:sqlServerObject | New-SqlDscAgentAlert -Name 'IntegrationTest_PassThruAlert' -Severity 16 -PassThru -ErrorAction Stop

        $result | Should -Not -BeNullOrEmpty
        $result.Name | Should -Be 'IntegrationTest_PassThruAlert'
        $result.Severity | Should -Be 16
    }

    It 'Should throw error when alert already exists' {
        # First create the alert
        $script:sqlServerObject | New-SqlDscAgentAlert -Name 'IntegrationTest_DuplicateAlert' -Severity 16 -ErrorAction Stop

        # Try to create it again - should throw
        { $script:sqlServerObject | New-SqlDscAgentAlert -Name 'IntegrationTest_DuplicateAlert' -Severity 14 } |
            Should -Throw
    }

    It 'Should throw error when both Severity and MessageId are specified' {
        { $script:sqlServerObject | New-SqlDscAgentAlert -Name 'IntegrationTest_InvalidAlert' -Severity 16 -MessageId 50001 } |
            Should -Throw
    }
}
