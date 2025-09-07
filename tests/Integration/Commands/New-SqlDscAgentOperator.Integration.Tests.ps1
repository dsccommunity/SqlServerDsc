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

Describe 'New-SqlDscAgentOperator' -Tag 'Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022' {
    BeforeAll {
        # Starting the named instance SQL Server service prior to running tests.
        Start-Service -Name 'MSSQL$DSCSQLTEST' -Verbose -ErrorAction 'Stop'

        $mockSqlAdministratorUserName = 'SqlAdmin' # Using computer name as NetBIOS name throw exception.
        $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

        $script:mockSqlAdminCredential = [System.Management.Automation.PSCredential]::new($mockSqlAdministratorUserName, $mockSqlAdministratorPassword)

        # Connect to the SQL Server instance
        $script:sqlServerObject = Connect-SqlDscDatabaseEngine -InstanceName $script:sqlServerInstance -Credential $script:mockSqlAdminCredential -ErrorAction 'Stop'
    }

    AfterAll {
        # Remove temporary test operators (but keep the persistent one)
        $script:sqlServerObject | Remove-SqlDscAgentOperator -Name 'IntegrationTest_NewOperator1' -Force -ErrorAction 'SilentlyContinue'
        $script:sqlServerObject | Remove-SqlDscAgentOperator -Name 'IntegrationTest_NewOperator2' -Force -ErrorAction 'SilentlyContinue'
        $script:sqlServerObject | Remove-SqlDscAgentOperator -Name 'IntegrationTest_NewOperator3' -Force -ErrorAction 'SilentlyContinue'

        # Disconnect from the SQL Server
        Disconnect-SqlDscDatabaseEngine -ServerObject $script:sqlServerObject

        # Stop the named instance SQL Server service to save memory on the build worker.
        Stop-Service -Name 'MSSQL$DSCSQLTEST' -Verbose -ErrorAction 'Stop'
    }

    It 'Should create the persistent operator for other tests to use' {
        # Remove the persistent operator if it already exists
        $script:sqlServerObject | Remove-SqlDscAgentOperator -Name 'SqlDscIntegrationTestOperator_Persistent' -Force -ErrorAction 'SilentlyContinue'

        # Create the persistent operator with comprehensive properties
        $script:sqlServerObject | New-SqlDscAgentOperator -Name 'SqlDscIntegrationTestOperator_Persistent' -EmailAddress 'persistent@example.com' -NetSendAddress 'SERVER\User' -PagerAddress '555-0123' -Force -ErrorAction 'Stop'

        # Verify the operator was created
        $operator = $script:sqlServerObject | Get-SqlDscAgentOperator -Name 'SqlDscIntegrationTestOperator_Persistent'
        $operator | Should -Not -BeNullOrEmpty
        $operator.Name | Should -Be 'SqlDscIntegrationTestOperator_Persistent'
        $operator.EmailAddress | Should -Be 'persistent@example.com'
        $operator.NetSendAddress | Should -Be 'SERVER\User'
        $operator.PagerAddress | Should -Be '555-0123'
    }

    It 'Should create a new operator with just name' {
        $script:sqlServerObject | New-SqlDscAgentOperator -Name 'IntegrationTest_NewOperator1' -Force -ErrorAction 'Stop'

        # Verify the operator was created
        $operator = $script:sqlServerObject | Get-SqlDscAgentOperator -Name 'IntegrationTest_NewOperator1'
        $operator | Should -Not -BeNullOrEmpty
        $operator.Name | Should -Be 'IntegrationTest_NewOperator1'
    }

    It 'Should create a new operator with email address' {
        $script:sqlServerObject | New-SqlDscAgentOperator -Name 'IntegrationTest_NewOperator2' -EmailAddress 'operator2@contoso.com' -Force -ErrorAction 'Stop'

        # Verify the operator was created
        $operator = $script:sqlServerObject | Get-SqlDscAgentOperator -Name 'IntegrationTest_NewOperator2'
        $operator | Should -Not -BeNullOrEmpty
        $operator.Name | Should -Be 'IntegrationTest_NewOperator2'
        $operator.EmailAddress | Should -Be 'operator2@contoso.com'
    }

    It 'Should create a new operator and return the object with PassThru' {
        $operator = $script:sqlServerObject | New-SqlDscAgentOperator -Name 'IntegrationTest_NewOperator3' -EmailAddress 'operator3@contoso.com' -PassThru -Force -ErrorAction 'Stop'

        $operator | Should -Not -BeNullOrEmpty
        $operator | Should -BeOfType [Microsoft.SqlServer.Management.Smo.Agent.Operator]
        $operator.Name | Should -Be 'IntegrationTest_NewOperator3'
        $operator.EmailAddress | Should -Be 'operator3@contoso.com'
    }

    It 'Should create a new operator using ServerObject parameter directly' {
        # Remove operator first if it exists
        $script:sqlServerObject | Remove-SqlDscAgentOperator -Name 'IntegrationTest_NewOperator1' -Force -ErrorAction 'SilentlyContinue'

        New-SqlDscAgentOperator -ServerObject $script:sqlServerObject -Name 'IntegrationTest_NewOperator1' -Force -ErrorAction 'Stop'

        # Verify the operator was created
        $operator = $script:sqlServerObject | Get-SqlDscAgentOperator -Name 'IntegrationTest_NewOperator1'
        $operator | Should -Not -BeNullOrEmpty
        $operator.Name | Should -Be 'IntegrationTest_NewOperator1'
    }

    It 'Should throw an error when trying to create an operator that already exists' {
        # Create the operator first
        $script:sqlServerObject | Remove-SqlDscAgentOperator -Name 'IntegrationTest_NewOperator1' -Force -ErrorAction 'SilentlyContinue'
        $script:sqlServerObject | New-SqlDscAgentOperator -Name 'IntegrationTest_NewOperator1' -Force -ErrorAction 'Stop'

        # Try to create the same operator again
        { $script:sqlServerObject | New-SqlDscAgentOperator -Name 'IntegrationTest_NewOperator1' -ErrorAction 'Stop' } |
            Should -Throw -ExpectedMessage '*SQL Agent Operator ''IntegrationTest_NewOperator1'' already exists*'
    }
}