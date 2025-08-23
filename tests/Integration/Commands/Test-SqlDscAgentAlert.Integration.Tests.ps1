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

Describe 'Test-SqlDscAgentAlert' -Tag 'Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022' {
    BeforeAll {
        # Connect to the SQL Server instance
        $script:sqlServerObject = Connect-SqlDscDatabaseEngine -InstanceName $script:sqlServerInstance

        # Clean up any test alerts that might exist from previous runs
        $testAlerts = @(
            'IntegrationTest_SeverityAlert',
            'IntegrationTest_MessageIdAlert'
        )

        foreach ($alertName in $testAlerts)
        {
            $existingAlert = $script:sqlServerObject | Get-SqlDscAgentAlert -Name $alertName -ErrorAction 'SilentlyContinue'
            if ($existingAlert)
            {
                $existingAlert | Remove-SqlDscAgentAlert -Force
            }
        }

        # Create test alerts for testing
        $script:sqlServerObject | New-SqlDscAgentAlert -Name 'IntegrationTest_SeverityAlert' -Severity '16'
        $script:sqlServerObject | New-SqlDscAgentAlert -Name 'IntegrationTest_MessageIdAlert' -MessageId '50001'
    }

    AfterAll {
        # Clean up test alerts
        $testAlerts = @(
            'IntegrationTest_SeverityAlert',
            'IntegrationTest_MessageIdAlert'
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

    It 'Should return true when alert exists' {
        $result = $script:sqlServerObject | Test-SqlDscAgentAlert -Name 'IntegrationTest_SeverityAlert'

        $result | Should -BeTrue
    }

    It 'Should return false when alert does not exist' {
        $result = $script:sqlServerObject | Test-SqlDscAgentAlert -Name 'NonExistentAlert'

        $result | Should -BeFalse
    }

    It 'Should return true when alert exists and severity matches' {
        $result = $script:sqlServerObject | Test-SqlDscAgentAlert -Name 'IntegrationTest_SeverityAlert' -Severity '16'

        $result | Should -BeTrue
    }

    It 'Should return false when alert exists but severity does not match' {
        $result = $script:sqlServerObject | Test-SqlDscAgentAlert -Name 'IntegrationTest_SeverityAlert' -Severity '14'

        $result | Should -BeFalse
    }

    It 'Should return true when alert exists and message ID matches' {
        $result = $script:sqlServerObject | Test-SqlDscAgentAlert -Name 'IntegrationTest_MessageIdAlert' -MessageId '50001'

        $result | Should -BeTrue
    }

    It 'Should return false when alert exists but message ID does not match' {
        $result = $script:sqlServerObject | Test-SqlDscAgentAlert -Name 'IntegrationTest_MessageIdAlert' -MessageId '50002'

        $result | Should -BeFalse
    }

    It 'Should throw error when both Severity and MessageId are specified' {
        { $script:sqlServerObject | Test-SqlDscAgentAlert -Name 'IntegrationTest_SeverityAlert' -Severity '16' -MessageId '50001' } |
            Should -Throw -ExpectedMessage '*Cannot specify both Severity and MessageId*'
    }
}
