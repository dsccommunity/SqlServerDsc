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

Describe 'New-SqlDscAgentAlert' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
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
            $null = $script:sqlServerObject |
                Remove-SqlDscAgentAlert -Name $alertName -Force -ErrorAction 'SilentlyContinue'
        }

        # Disconnect from the SQL Server
        Disconnect-SqlDscDatabaseEngine -ServerObject $script:sqlServerObject

        # Note: SQL Server service is left running for subsequent tests for performance optimization
    }

    It 'Should create alert with severity' {
        $null = $script:sqlServerObject | New-SqlDscAgentAlert -Name 'IntegrationTest_SeverityAlert' -Severity 14 -ErrorAction Stop

        $alert = $script:sqlServerObject | Get-SqlDscAgentAlert -Name 'IntegrationTest_SeverityAlert'
        $alert | Should -Not -BeNullOrEmpty
        $alert.Name | Should -Be 'IntegrationTest_SeverityAlert'
        $alert.Severity | Should -Be 14
    }

    It 'Should create alert with message ID' {
                $addMessageQuery = @'
IF NOT EXISTS (SELECT 1 FROM sys.messages WHERE message_id = 50002 AND language_id = 1033)
BEGIN
    EXECUTE sp_addmessage
        50002,
        16,
        N'Mock message 50002';
END
'@
        $script:sqlServerObject | Invoke-SqlDscQuery -DatabaseName 'master' -Query $addMessageQuery -Verbose -Force -ErrorAction 'Stop'

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
        $script:sqlServerObject | New-SqlDscAgentAlert -Name 'IntegrationTest_DuplicateAlert' -Severity 15 -ErrorAction Stop

        # Try to create it again - should throw
        { $script:sqlServerObject | New-SqlDscAgentAlert -Name 'IntegrationTest_DuplicateAlert' -Severity 14 -ErrorAction Stop } |
            Should -Throw
    }

    It 'Should throw error when both Severity and MessageId are specified' {
        { $script:sqlServerObject | New-SqlDscAgentAlert -Name 'IntegrationTest_InvalidAlert' -Severity 16 -MessageId 50001 -ErrorAction Stop } |
            Should -Throw
    }
}
