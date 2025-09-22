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

Describe 'Remove-SqlDscAgentAlert' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        # Integration tests are run on the DSCSQLTEST instance
        $script:sqlServerInstance = 'DSCSQLTEST'

        # Note: SQL Server service is already running from Install-SqlDscServer test for performance optimization

        $mockSqlAdministratorUserName = 'SqlAdmin' # Using computer name as NetBIOS name throw exception.
        $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

        $script:mockSqlAdminCredential = [System.Management.Automation.PSCredential]::new($mockSqlAdministratorUserName, $mockSqlAdministratorPassword)

        # Connect to the SQL Server instance
        $script:sqlServerObject = Connect-SqlDscDatabaseEngine -InstanceName $script:sqlServerInstance -Credential $script:mockSqlAdminCredential -ErrorAction 'Stop'
    }


    AfterAll {
        # Disconnect from the SQL Server
        Disconnect-SqlDscDatabaseEngine -ServerObject $script:sqlServerObject
    }

    Context 'When removing by ServerObject' {
        It 'Should remove alert' {
            # Create alert for this test
            $script:sqlServerObject | New-SqlDscAgentAlert -Name 'IntegrationTest_RemoveAlert' -Severity 16 -ErrorAction Stop

            $null = $script:sqlServerObject | Remove-SqlDscAgentAlert -Name 'IntegrationTest_RemoveAlert' -Force -ErrorAction Stop

            $alert = $script:sqlServerObject | Get-SqlDscAgentAlert -Name 'IntegrationTest_RemoveAlert'
            $alert | Should -BeNull
        }
    }

    Context 'When removing by AlertObject' {
        It 'Should remove alert' {
            # Create a new alert for this test
            $script:sqlServerObject | New-SqlDscAgentAlert -Name 'IntegrationTest_RemoveAlert2' -Severity 16 -ErrorAction Stop
            $alert = $script:sqlServerObject | Get-SqlDscAgentAlert -Name 'IntegrationTest_RemoveAlert2'

            $null = $alert | Remove-SqlDscAgentAlert -Force -ErrorAction Stop

            $removedAlert = $script:sqlServerObject | Get-SqlDscAgentAlert -Name 'IntegrationTest_RemoveAlert2'
            $removedAlert | Should -BeNull
        }
    }

    Context 'When alert does not exist' {
        It 'Should not throw error' {
            $null = $script:sqlServerObject | Remove-SqlDscAgentAlert -Name 'NonExistentAlert' -Force -ErrorAction Stop
        }
    }
}
