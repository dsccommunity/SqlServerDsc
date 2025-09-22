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

Describe 'Set-SqlDscAgentOperator' -Tag 'Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022' {
    BeforeAll {
        $mockSqlAdministratorUserName = 'SqlAdmin' # Using computer name as NetBIOS name throw exception.
        $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force
        $mockSqlAdministratorCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $mockSqlAdministratorUserName, $mockSqlAdministratorPassword

        $script:serverObject = Connect-SqlDscDatabaseEngine -InstanceName $script:sqlServerInstance -Credential $mockSqlAdministratorCredential -ErrorAction 'Stop'

        # Enable Agent XPs component for SQL Server Agent functionality
        Set-SqlDscConfigurationOption -ServerObject $script:serverObject -Name 'Agent XPs' -Value 1 -Force -Verbose -ErrorAction 'Stop'
    }

    AfterAll {
        # Disable Agent XPs component to clean up test environment
        Set-SqlDscConfigurationOption -ServerObject $script:serverObject -Name 'Agent XPs' -Value 0 -Force -Verbose -ErrorAction 'Stop'

        Disconnect-SqlDscDatabaseEngine -ServerObject $script:serverObject
    }

    Context 'When updating an existing agent operator' {
        It 'Should update the email address' {
            # Get the persistent operator created by New-SqlDscAgentOperator integration test
            $operatorObject = Get-SqlDscAgentOperator -ServerObject $script:serverObject -Name 'SqlDscIntegrationTestOperator_Persistent' -ErrorAction 'Stop'
            $operatorObject | Should -Not -BeNullOrEmpty

            # Update the email address
            $newEmailAddress = 'updated@example.com'
            $null = Set-SqlDscAgentOperator -OperatorObject $operatorObject -EmailAddress $newEmailAddress -Force -ErrorAction 'Stop'

            # Verify the email address was updated
            $operatorObject.Refresh()
            $operatorObject.EmailAddress | Should -Be $newEmailAddress
        }

        It 'Should update multiple properties' {
            # Get the persistent operator
            $operatorObject = Get-SqlDscAgentOperator -ServerObject $script:serverObject -Name 'SqlDscIntegrationTestOperator_Persistent' -ErrorAction 'Stop'

            # Update multiple properties
            $newEmailAddress = 'multi@example.com'
            $newNetSendAddress = 'COMPUTER\User'
            $newPagerAddress = '555-1234'

            $null = Set-SqlDscAgentOperator -OperatorObject $operatorObject -EmailAddress $newEmailAddress -NetSendAddress $newNetSendAddress -PagerAddress $newPagerAddress -Force -ErrorAction 'Stop'

            # Verify all properties were updated
            $operatorObject.Refresh()
            $operatorObject.EmailAddress | Should -Be $newEmailAddress
            $operatorObject.NetSendAddress | Should -Be $newNetSendAddress
            $operatorObject.PagerAddress | Should -Be $newPagerAddress
        }
    }

    Context 'When using ServerObject parameter set' {
        It 'Should update an operator using ServerObject and Name parameters' {
            $newEmailAddress = 'serverset@example.com'

            # Update using ServerObject parameter set
            $null = Set-SqlDscAgentOperator -ServerObject $script:serverObject -Name 'SqlDscIntegrationTestOperator_Persistent' -EmailAddress $newEmailAddress -Force -ErrorAction 'Stop'

            # Verify the email address was updated
            $operatorObject = Get-SqlDscAgentOperator -ServerObject $script:serverObject -Name 'SqlDscIntegrationTestOperator_Persistent' -ErrorAction 'Stop'
            $operatorObject.EmailAddress | Should -Be $newEmailAddress
        }
    }
}
