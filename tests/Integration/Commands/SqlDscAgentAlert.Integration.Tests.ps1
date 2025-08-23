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

Describe 'SqlDscAgentAlert Integration Tests' -Tag 'Integration' {
    BeforeAll {
        # Connect to the SQL Server instance
        $script:sqlServerObject = Connect-SqlDscDatabaseEngine -InstanceName $script:sqlServerInstance

        # Clean up any test alerts that might exist from previous runs
        $testAlerts = @(
            'IntegrationTest_Alert1',
            'IntegrationTest_Alert2',
            'IntegrationTest_SeverityAlert',
            'IntegrationTest_MessageIdAlert',
            'IntegrationTest_UpdateAlert',
            'IntegrationTest_RemoveAlert',
            'IntegrationTest_PassThruAlert'
        )

        foreach ($alertName in $testAlerts)
        {
            $existingAlert = $script:sqlServerObject | Get-SqlDscAgentAlert -Name $alertName
            if ($existingAlert)
            {
                $existingAlert | Remove-SqlDscAgentAlert -Force
            }
        }
    }

    AfterAll {
        # Clean up test alerts
        $testAlerts = @(
            'IntegrationTest_Alert1',
            'IntegrationTest_Alert2',
            'IntegrationTest_SeverityAlert',
            'IntegrationTest_MessageIdAlert',
            'IntegrationTest_UpdateAlert',
            'IntegrationTest_RemoveAlert',
            'IntegrationTest_PassThruAlert'
        )

        foreach ($alertName in $testAlerts)
        {
            $existingAlert = $script:sqlServerObject | Get-SqlDscAgentAlert -Name $alertName
            if ($existingAlert)
            {
                $existingAlert | Remove-SqlDscAgentAlert -Force
            }
        }

        # Disconnect from the SQL Server
        Disconnect-SqlDscDatabaseEngine -ServerObject $script:sqlServerObject
    }

    Context 'Get-SqlDscAgentAlert' {
        BeforeAll {
            # Create a test alert for getting
            $script:sqlServerObject | New-SqlDscAgentAlert -Name 'IntegrationTest_Alert1' -Severity '16'
            $script:sqlServerObject | New-SqlDscAgentAlert -Name 'IntegrationTest_Alert2' -MessageId '50001'
        }

        It 'Should get all alerts' {
            $alerts = $script:sqlServerObject | Get-SqlDscAgentAlert

            $alerts | Should -Not -BeNullOrEmpty
            $alerts | Should -BeOfType [Microsoft.SqlServer.Management.Smo.Agent.Alert]
        }

        It 'Should get specific alert by name' {
            $alert = $script:sqlServerObject | Get-SqlDscAgentAlert -Name 'IntegrationTest_Alert1'

            $alert | Should -Not -BeNullOrEmpty
            $alert.Name | Should -Be 'IntegrationTest_Alert1'
            $alert.Severity | Should -Be 16
        }

        It 'Should return null for non-existent alert' {
            $alert = $script:sqlServerObject | Get-SqlDscAgentAlert -Name 'NonExistentAlert'

            $alert | Should -BeNull
        }

        It 'Should get alert with message ID' {
            $alert = $script:sqlServerObject | Get-SqlDscAgentAlert -Name 'IntegrationTest_Alert2'

            $alert | Should -Not -BeNullOrEmpty
            $alert.Name | Should -Be 'IntegrationTest_Alert2'
            $alert.MessageId | Should -Be 50001
        }
    }

    Context 'New-SqlDscAgentAlert' {
        It 'Should create alert with severity' {
            { $script:sqlServerObject | New-SqlDscAgentAlert -Name 'IntegrationTest_SeverityAlert' -Severity '14' } | Should -Not -Throw

            $alert = $script:sqlServerObject | Get-SqlDscAgentAlert -Name 'IntegrationTest_SeverityAlert'
            $alert | Should -Not -BeNullOrEmpty
            $alert.Name | Should -Be 'IntegrationTest_SeverityAlert'
            $alert.Severity | Should -Be 14
        }

        It 'Should create alert with message ID' {
            { $script:sqlServerObject | New-SqlDscAgentAlert -Name 'IntegrationTest_MessageIdAlert' -MessageId '50002' } | Should -Not -Throw

            $alert = $script:sqlServerObject | Get-SqlDscAgentAlert -Name 'IntegrationTest_MessageIdAlert'
            $alert | Should -Not -BeNullOrEmpty
            $alert.Name | Should -Be 'IntegrationTest_MessageIdAlert'
            $alert.MessageId | Should -Be 50002
        }

        It 'Should return alert object when PassThru is specified' {
            $result = $script:sqlServerObject | New-SqlDscAgentAlert -Name 'IntegrationTest_PassThruAlert' -Severity '16' -PassThru

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'IntegrationTest_PassThruAlert'
            $result.Severity | Should -Be 16
        }

        It 'Should throw error when alert already exists' {
            # First create the alert
            $script:sqlServerObject | New-SqlDscAgentAlert -Name 'IntegrationTest_SeverityAlert' -Severity '16'

            # Try to create it again - should throw
            { $script:sqlServerObject | New-SqlDscAgentAlert -Name 'IntegrationTest_SeverityAlert' -Severity '14' } |
                Should -Throw -ExpectedMessage '*already exists*'
        }

        It 'Should throw error when both Severity and MessageId are specified' {
            { $script:sqlServerObject | New-SqlDscAgentAlert -Name 'IntegrationTest_InvalidAlert' -Severity '16' -MessageId '50001' } |
                Should -Throw -ExpectedMessage '*Cannot specify both Severity and MessageId*'
        }
    }

    Context 'Set-SqlDscAgentAlert' {
        BeforeAll {
            # Create a test alert for updating
            $script:sqlServerObject | New-SqlDscAgentAlert -Name 'IntegrationTest_UpdateAlert' -Severity '14'
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

    Context 'Test-SqlDscAgentAlert' {
        BeforeAll {
            # Create test alerts for testing
            $script:sqlServerObject | New-SqlDscAgentAlert -Name 'IntegrationTest_SeverityAlert' -Severity '16'
            $script:sqlServerObject | New-SqlDscAgentAlert -Name 'IntegrationTest_MessageIdAlert' -MessageId '50001'
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

    Context 'Remove-SqlDscAgentAlert' {
        BeforeAll {
            # Create test alerts for removal
            $script:sqlServerObject | New-SqlDscAgentAlert -Name 'IntegrationTest_RemoveAlert' -Severity '16'
        }

        It 'Should remove alert using ServerObject parameter set' {
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

    Context 'End-to-end workflow test' {
        It 'Should support complete alert lifecycle' {
            $alertName = 'IntegrationTest_LifecycleAlert'

            # Test that alert does not exist initially
            $script:sqlServerObject | Test-SqlDscAgentAlert -Name $alertName | Should -BeFalse

            # Create the alert
            $createdAlert = $script:sqlServerObject | New-SqlDscAgentAlert -Name $alertName -Severity '14' -PassThru
            $createdAlert | Should -Not -BeNullOrEmpty
            $createdAlert.Name | Should -Be $alertName
            $createdAlert.Severity | Should -Be 14

            # Test that alert exists
            $script:sqlServerObject | Test-SqlDscAgentAlert -Name $alertName | Should -BeTrue
            $script:sqlServerObject | Test-SqlDscAgentAlert -Name $alertName -Severity '14' | Should -BeTrue

            # Get the alert
            $retrievedAlert = $script:sqlServerObject | Get-SqlDscAgentAlert -Name $alertName
            $retrievedAlert | Should -Not -BeNullOrEmpty
            $retrievedAlert.Name | Should -Be $alertName

            # Update the alert
            $updatedAlert = $script:sqlServerObject | Set-SqlDscAgentAlert -Name $alertName -MessageId '50004' -PassThru
            $updatedAlert.MessageId | Should -Be 50004
            $updatedAlert.Severity | Should -Be 0

            # Test the updated alert
            $script:sqlServerObject | Test-SqlDscAgentAlert -Name $alertName -MessageId '50004' | Should -BeTrue
            $script:sqlServerObject | Test-SqlDscAgentAlert -Name $alertName -Severity '14' | Should -BeFalse

            # Remove the alert
            $script:sqlServerObject | Remove-SqlDscAgentAlert -Name $alertName -Force

            # Test that alert no longer exists
            $script:sqlServerObject | Test-SqlDscAgentAlert -Name $alertName | Should -BeFalse
            $script:sqlServerObject | Get-SqlDscAgentAlert -Name $alertName | Should -BeNull
        }
    }
}
