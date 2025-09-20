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

    $env:SqlServerDscCI = $true

    # Integration tests are run on the DSCSQLTEST instance
    $script:sqlServerInstance = 'DSCSQLTEST'
}

AfterAll {
    Remove-Item -Path 'Env:\SqlServerDscCI' -ErrorAction 'SilentlyContinue'

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:moduleName -All | Remove-Module -Force
}

Describe 'Get-SqlDscAgentOperator' -Tag 'Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022' {
    BeforeAll {
        # Starting the named instance SQL Server service prior to running tests.
        Start-Service -Name 'MSSQL$DSCSQLTEST' -Verbose -ErrorAction 'Stop'

        $mockSqlAdministratorUserName = 'SqlAdmin' # Using computer name as NetBIOS name throw exception.
        $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

        $script:mockSqlAdminCredential = [System.Management.Automation.PSCredential]::new($mockSqlAdministratorUserName, $mockSqlAdministratorPassword)

        # Connect to the SQL Server instance
        $script:sqlServerObject = Connect-SqlDscDatabaseEngine -InstanceName $script:sqlServerInstance -Credential $script:mockSqlAdminCredential -ErrorAction 'Stop'

        # Create test operators for getting
        $script:sqlServerObject | New-SqlDscAgentOperator -Name 'IntegrationTest_GetOperator1' -EmailAddress 'operator1@contoso.com' -Force -ErrorAction 'Stop'
        $script:sqlServerObject | New-SqlDscAgentOperator -Name 'IntegrationTest_GetOperator2' -EmailAddress 'operator2@contoso.com' -Force -ErrorAction 'Stop'
    }

    AfterAll {
        $script:sqlServerObject | Remove-SqlDscAgentOperator -Name 'IntegrationTest_GetOperator1' -Force -ErrorAction 'SilentlyContinue'
        $script:sqlServerObject | Remove-SqlDscAgentOperator -Name 'IntegrationTest_GetOperator2' -Force -ErrorAction 'SilentlyContinue'

        # Disconnect from the SQL Server
        Disconnect-SqlDscDatabaseEngine -ServerObject $script:sqlServerObject

        # Stop the named instance SQL Server service to save memory on the build worker.
        Stop-Service -Name 'MSSQL$DSCSQLTEST' -Verbose -ErrorAction 'Stop'
    }

    It 'Should get all operators' {
        $operators = $script:sqlServerObject | Get-SqlDscAgentOperator -ErrorAction 'Stop'

        $operators | Should -Not -BeNullOrEmpty
        @($operators)[0] | Should -BeOfType [Microsoft.SqlServer.Management.Smo.Agent.Operator]
    }

    It 'Should get specific operator by name' {
        $operator = $script:sqlServerObject | Get-SqlDscAgentOperator -Name 'IntegrationTest_GetOperator1' -ErrorAction 'Stop'

        $operator | Should -Not -BeNullOrEmpty
        $operator | Should -BeOfType [Microsoft.SqlServer.Management.Smo.Agent.Operator]
        $operator.Name | Should -Be 'IntegrationTest_GetOperator1'
        $operator.EmailAddress | Should -Be 'operator1@contoso.com'
    }

    It 'Should return nothing when operator does not exist' {
        $operator = $script:sqlServerObject | Get-SqlDscAgentOperator -Name 'NonExistentOperator' -ErrorAction 'Stop'

        $operator | Should -BeNullOrEmpty
    }

    It 'Should get operator using ServerObject parameter directly' {
        $operator = Get-SqlDscAgentOperator -ServerObject $script:sqlServerObject -Name 'IntegrationTest_GetOperator2' -ErrorAction 'Stop'

        $operator | Should -Not -BeNullOrEmpty
        $operator | Should -BeOfType [Microsoft.SqlServer.Management.Smo.Agent.Operator]
        $operator.Name | Should -Be 'IntegrationTest_GetOperator2'
    }
}
