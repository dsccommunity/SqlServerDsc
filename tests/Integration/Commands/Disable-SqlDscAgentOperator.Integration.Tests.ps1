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

    # Do not use -Force. Doing so, or unloading the module in AfterAll, causes
    # PowerShell class types to get new identities, breaking type comparisons.
    Import-Module -Name $script:moduleName -ErrorAction 'Stop'

    $env:SqlServerDscCI = $true

    # Integration tests are run on the DSCSQLTEST instance
    $script:sqlServerInstance = 'DSCSQLTEST'
}

AfterAll {
    Remove-Item -Path 'Env:\SqlServerDscCI' -ErrorAction 'SilentlyContinue'
}

Describe 'Disable-SqlDscAgentOperator' -Tag 'Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022' {
    BeforeAll {
        $mockSqlAdministratorUserName = 'SqlAdmin' # Using computer name as NetBIOS name throw exception.
        $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force
        $mockSqlAdministratorCredential = [System.Management.Automation.PSCredential]::new($mockSqlAdministratorUserName, $mockSqlAdministratorPassword)

        $script:serverObject = Connect-SqlDscDatabaseEngine -InstanceName $script:sqlServerInstance -Credential $mockSqlAdministratorCredential -ErrorAction 'Stop'

        # Enable Agent XPs component for SQL Server Agent functionality
        Set-SqlDscConfigurationOption -ServerObject $script:serverObject -Name 'Agent XPs' -Value 1 -Force -Verbose -ErrorAction 'Stop'
    }

    AfterAll {
        # Disable Agent XPs component to clean up test environment
        Set-SqlDscConfigurationOption -ServerObject $script:serverObject -Name 'Agent XPs' -Value 0 -Force -Verbose -ErrorAction 'Stop'

        Disconnect-SqlDscDatabaseEngine -ServerObject $script:serverObject
    }

    Context 'When disabling an existing agent operator' {
        It 'Should disable the persistent operator' {
            # Get the persistent operator created by New-SqlDscAgentOperator integration test
            $operatorObject = Get-SqlDscAgentOperator -ServerObject $script:serverObject -Name 'SqlDscIntegrationTestOperator_Persistent' -ErrorAction 'Stop'
            $operatorObject | Should -Not -BeNullOrEmpty

            # Enable it first if it's not enabled
            if (-not $operatorObject.Enabled)
            {
                Enable-SqlDscAgentOperator -OperatorObject $operatorObject -Force -ErrorAction 'Stop'
            }

            # Disable the operator
            Disable-SqlDscAgentOperator -OperatorObject $operatorObject -Force -ErrorAction 'Stop'

            # Verify it's disabled
            $operatorObject.Refresh()
            $operatorObject.Enabled | Should -BeFalse
        }
    }

    Context 'When using ServerObject parameter set' {
        It 'Should disable an operator using ServerObject and Name parameters' {
            # First enable the operator to ensure it's enabled
            Enable-SqlDscAgentOperator -ServerObject $script:serverObject -Name 'SqlDscIntegrationTestOperator_Persistent' -Force -ErrorAction 'Stop'

            # Disable using ServerObject parameter set
            Disable-SqlDscAgentOperator -ServerObject $script:serverObject -Name 'SqlDscIntegrationTestOperator_Persistent' -Force -ErrorAction 'Stop'

            # Verify it's disabled
            $operatorObject = Get-SqlDscAgentOperator -ServerObject $script:serverObject -Name 'SqlDscIntegrationTestOperator_Persistent' -ErrorAction 'Stop'
            $operatorObject.Enabled | Should -BeFalse
        }
    }
}
