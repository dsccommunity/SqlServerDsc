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

Describe 'Remove-SqlDscAgentOperator' -Tag 'Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022', 'Integration_SQL2025' {
    BeforeAll {
        $mockSqlAdministratorUserName = 'SqlAdmin' # Using computer name as NetBIOS name throw exception.
        $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force
        $mockSqlAdministratorCredential = [System.Management.Automation.PSCredential]::new($mockSqlAdministratorUserName, $mockSqlAdministratorPassword)

        $script:serverObject = Connect-SqlDscDatabaseEngine -InstanceName $script:sqlServerInstance -Credential $mockSqlAdministratorCredential -ErrorAction 'Stop'
    }

    AfterAll {
        Disconnect-SqlDscDatabaseEngine -ServerObject $script:serverObject
    }

    Context 'When removing test agent operators' {
        It 'Should create and remove a temporary operator' {
            # Create a temporary operator for removal testing
            $tempOperatorName = 'SqlDscTempOperator_ToRemove'
            $null = New-SqlDscAgentOperator -ServerObject $script:serverObject -Name $tempOperatorName -EmailAddress 'temp@example.com' -Force -ErrorAction 'Stop'

            # Verify it was created
            $operatorExists = Test-SqlDscIsAgentOperator -ServerObject $script:serverObject -Name $tempOperatorName -ErrorAction 'Stop'
            $operatorExists | Should -BeTrue

            # Remove the operator
            $null = Remove-SqlDscAgentOperator -ServerObject $script:serverObject -Name $tempOperatorName -Force -ErrorAction 'Stop'

            # Verify it was removed
            $operatorExists = Test-SqlDscIsAgentOperator -ServerObject $script:serverObject -Name $tempOperatorName -ErrorAction 'Stop'
            $operatorExists | Should -BeFalse
        }

        It 'Should remove operator using OperatorObject parameter set' {
            # Create a temporary operator
            $tempOperatorName = 'SqlDscTempOperator_ByObject'
            $null = New-SqlDscAgentOperator -ServerObject $script:serverObject -Name $tempOperatorName -EmailAddress 'temp2@example.com' -Force -ErrorAction 'Stop'

            # Get the operator object
            $operatorObject = Get-SqlDscAgentOperator -ServerObject $script:serverObject -Name $tempOperatorName -ErrorAction 'Stop'
            $operatorObject | Should -Not -BeNullOrEmpty

            # Remove using OperatorObject parameter set
            $null = Remove-SqlDscAgentOperator -OperatorObject $operatorObject -Force -ErrorAction 'Stop'

            # Verify it was removed
            $operatorExists = Test-SqlDscIsAgentOperator -ServerObject $script:serverObject -Name $tempOperatorName -ErrorAction 'Stop'
            $operatorExists | Should -BeFalse
        }
    }
}
