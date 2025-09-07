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
    $script:moduleName = 'SqlServerDsc'

    Import-Module -Name $script:moduleName -Force -ErrorAction 'Stop'

    $env:SqlServerDscCI = $true

    # Integration tests are run on the DSCSQLTEST instance
    $script:sqlServerInstance = 'DSCSQLTEST'
}

AfterAll {
    $env:SqlServerDscCI = $null

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:moduleName -All | Remove-Module -Force
}

Describe 'Enable-SqlDscAgentOperator' -Tag 'Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022' {
    BeforeAll {
        # Starting the named instance SQL Server service prior to running tests.
        Start-Service -Name 'MSSQL$DSCSQLTEST' -Verbose -ErrorAction 'Stop'

        $mockSqlAdministratorUserName = 'SqlAdmin' # Using computer name as NetBIOS name throw exception.
        $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force
        $mockSqlAdministratorCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $mockSqlAdministratorUserName, $mockSqlAdministratorPassword

        $script:serverObject = Connect-SqlDscDatabaseEngine -InstanceName $script:sqlServerInstance -Credential $mockSqlAdministratorCredential
    }

    AfterAll {
        Disconnect-SqlDscDatabaseEngine -ServerObject $script:serverObject

        # Stopping the named instance SQL Server service after running tests.
        Stop-Service -Name 'MSSQL$DSCSQLTEST' -Verbose -ErrorAction 'Stop'
    }

    Context 'When enabling an existing agent operator' {
        It 'Should enable the persistent operator' {
            # Get the persistent operator created by New-SqlDscAgentOperator integration test
            $operatorObject = Get-SqlDscAgentOperator -ServerObject $script:serverObject -Name 'SqlDscIntegrationTestOperator_Persistent' -ErrorAction 'Stop'
            $operatorObject | Should -Not -BeNullOrEmpty

            # Disable it first if it's enabled
            if ($operatorObject.Enabled)
            {
                Disable-SqlDscAgentOperator -OperatorObject $operatorObject -Force -ErrorAction 'Stop'
            }

            # Enable the operator
            Enable-SqlDscAgentOperator -OperatorObject $operatorObject -Force -ErrorAction 'Stop'

            # Verify it's enabled
            $operatorObject.Refresh()
            $operatorObject.Enabled | Should -BeTrue
        }
    }

    Context 'When using ServerObject parameter set' {
        It 'Should enable an operator using ServerObject and Name parameters' {
            # First disable the operator to ensure it's disabled
            Disable-SqlDscAgentOperator -ServerObject $script:serverObject -Name 'SqlDscIntegrationTestOperator_Persistent' -Force -ErrorAction 'Stop'

            # Enable using ServerObject parameter set
            Enable-SqlDscAgentOperator -ServerObject $script:serverObject -Name 'SqlDscIntegrationTestOperator_Persistent' -Force -ErrorAction 'Stop'

            # Verify it's enabled
            $operatorObject = Get-SqlDscAgentOperator -ServerObject $script:serverObject -Name 'SqlDscIntegrationTestOperator_Persistent' -ErrorAction 'Stop'
            $operatorObject.Enabled | Should -BeTrue
        }
    }
}