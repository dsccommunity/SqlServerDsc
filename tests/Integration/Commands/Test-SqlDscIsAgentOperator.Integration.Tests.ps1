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
    $env:SqlServerDscCI = $null

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:moduleName -All | Remove-Module -Force
}

Describe 'Test-SqlDscIsAgentOperator' -Tag 'Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022' {
    BeforeAll {
        $mockSqlAdministratorUserName = 'SqlAdmin' # Using computer name as NetBIOS name throw exception.
        $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force
        $mockSqlAdministratorCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $mockSqlAdministratorUserName, $mockSqlAdministratorPassword

        $script:serverObject = Connect-SqlDscDatabaseEngine -InstanceName $script:sqlServerInstance -Credential $mockSqlAdministratorCredential -ErrorAction 'Stop'
    }

    AfterAll {
        Disconnect-SqlDscDatabaseEngine -ServerObject $script:serverObject
    }

    Context 'When testing for an existing agent operator' {
        It 'Should return true for existing operator' {
            # Test for the persistent operator created by New-SqlDscAgentOperator integration test
            $result = Test-SqlDscIsAgentOperator -ServerObject $script:serverObject -Name 'SqlDscIntegrationTestOperator_Persistent' -ErrorAction 'Stop'
            $result | Should -BeTrue
        }

        It 'Should return false for non-existing operator' {
            # Test for a non-existing operator
            $result = Test-SqlDscIsAgentOperator -ServerObject $script:serverObject -Name 'NonExistentOperator' -ErrorAction 'Stop'
            $result | Should -BeFalse
        }
    }

    Context 'When using pipeline input' {
        It 'Should accept ServerObject from pipeline' {
            $result = $script:serverObject | Test-SqlDscIsAgentOperator -Name 'SqlDscIntegrationTestOperator_Persistent' -ErrorAction 'Stop'
            $result | Should -BeTrue
        }
    }
}
