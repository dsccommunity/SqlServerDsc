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
}

Describe 'Set-SqlDscConfigurationOption' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        $script:mockInstanceName = 'DSCSQLTEST'

        $mockSqlAdministratorUserName = 'SqlAdmin' # Using computer name as NetBIOS name throw exception.
        $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

        $script:mockSqlAdminCredential = [System.Management.Automation.PSCredential]::new($mockSqlAdministratorUserName, $mockSqlAdministratorPassword)

        $script:serverObject = Connect-SqlDscDatabaseEngine -InstanceName $script:mockInstanceName -Credential $script:mockSqlAdminCredential

        # Store the original value of Agent XPs to restore it later
        $script:originalAgentXPsValue = Get-SqlDscConfigurationOption -ServerObject $script:serverObject -Name 'Agent XPs'
    }

    AfterAll {
        # Restore the original Agent XPs value
        if ($null -ne $script:originalAgentXPsValue)
        {
            Set-SqlDscConfigurationOption -ServerObject $script:serverObject -Name 'Agent XPs' -Value $script:originalAgentXPsValue.RunValue -Force -ErrorAction 'SilentlyContinue'
        }

        Disconnect-SqlDscDatabaseEngine -ServerObject $script:serverObject
    }

    Context 'When setting Agent XPs configuration option' {
        It 'Should set Agent XPs from 0 to 1 and verify the change' {
            # First, ensure Agent XPs is set to 0
            Set-SqlDscConfigurationOption -ServerObject $script:serverObject -Name 'Agent XPs' -Value 0 -Force -ErrorAction 'Stop'

            # Verify it's set to 0
            $result = Get-SqlDscConfigurationOption -ServerObject $script:serverObject -Name 'Agent XPs'
            $result.RunValue | Should -Be 0
            $result.ConfigValue | Should -Be 0

            # Now set it to 1
            Set-SqlDscConfigurationOption -ServerObject $script:serverObject -Name 'Agent XPs' -Value 1 -Force -ErrorAction 'Stop'

            # Verify it's set to 1
            $result = Get-SqlDscConfigurationOption -ServerObject $script:serverObject -Name 'Agent XPs'
            $result.RunValue | Should -Be 1
            $result.ConfigValue | Should -Be 1
        }

        It 'Should set Agent XPs from 1 back to 0 and verify the change' {
            # Ensure Agent XPs is set to 1 first
            Set-SqlDscConfigurationOption -ServerObject $script:serverObject -Name 'Agent XPs' -Value 1 -Force -ErrorAction 'Stop'

            # Verify it's set to 1
            $result = Get-SqlDscConfigurationOption -ServerObject $script:serverObject -Name 'Agent XPs'
            $result.RunValue | Should -Be 1
            $result.ConfigValue | Should -Be 1

            # Now set it back to 0
            Set-SqlDscConfigurationOption -ServerObject $script:serverObject -Name 'Agent XPs' -Value 0 -Force -ErrorAction 'Stop'

            # Verify it's set to 0
            $result = Get-SqlDscConfigurationOption -ServerObject $script:serverObject -Name 'Agent XPs'
            $result.RunValue | Should -Be 0
            $result.ConfigValue | Should -Be 0
        }

        It 'Should throw an error when setting an invalid value for Agent XPs' {
            { Set-SqlDscConfigurationOption -ServerObject $script:serverObject -Name 'Agent XPs' -Value 2 -Force -ErrorAction 'Stop' } |
                Should -Throw
        }

        It 'Should throw an error when setting a negative value for Agent XPs' {
            { Set-SqlDscConfigurationOption -ServerObject $script:serverObject -Name 'Agent XPs' -Value -1 -Force -ErrorAction 'Stop' } |
                Should -Throw
        }

        It 'Should throw an error when the configuration option does not exist' {
            { Set-SqlDscConfigurationOption -ServerObject $script:serverObject -Name 'NonExistentOption' -Value 1 -Force -ErrorAction 'Stop' } |
                Should -Throw
        }
    }

    Context 'When using ShouldProcess with WhatIf' {
        It 'Should not actually change the value when using WhatIf' {
            # Get current value
            $originalValue = Get-SqlDscConfigurationOption -ServerObject $script:serverObject -Name 'Agent XPs'

            # Use WhatIf to simulate setting a different value
            $newValue = if ($originalValue.RunValue -eq 0) { 1 } else { 0 }
            Set-SqlDscConfigurationOption -ServerObject $script:serverObject -Name 'Agent XPs' -Value $newValue -WhatIf

            # Verify the value hasn't changed
            $currentValue = Get-SqlDscConfigurationOption -ServerObject $script:serverObject -Name 'Agent XPs'
            $currentValue.RunValue | Should -Be $originalValue.RunValue
            $currentValue.ConfigValue | Should -Be $originalValue.ConfigValue
        }
    }

    Context 'When using pipeline input' {
        It 'Should accept ServerObject from pipeline' {
            # Get current value
            $originalValue = Get-SqlDscConfigurationOption -ServerObject $script:serverObject -Name 'Agent XPs'

            # Set to opposite value using pipeline
            $newValue = if ($originalValue.RunValue -eq 0) { 1 } else { 0 }
            $script:serverObject | Set-SqlDscConfigurationOption -Name 'Agent XPs' -Value $newValue -Force -ErrorAction 'Stop'

            # Verify the change
            $result = Get-SqlDscConfigurationOption -ServerObject $script:serverObject -Name 'Agent XPs'
            $result.RunValue | Should -Be $newValue
            $result.ConfigValue | Should -Be $newValue

            # Set back to original value
            $script:serverObject | Set-SqlDscConfigurationOption -Name 'Agent XPs' -Value $originalValue.RunValue -Force -ErrorAction 'Stop'
        }
    }
}
