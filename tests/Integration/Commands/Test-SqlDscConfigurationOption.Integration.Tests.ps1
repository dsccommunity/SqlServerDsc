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

Describe 'Test-SqlDscConfigurationOption' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022', 'Integration_SQL2025') {
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

    Context 'When testing Agent XPs configuration option' {
        It 'Should return true when testing current value' {
            # Get current value
            $currentValue = Get-SqlDscConfigurationOption -ServerObject $script:serverObject -Name 'Agent XPs'

            # Test should return true for current value
            $result = Test-SqlDscConfigurationOption -ServerObject $script:serverObject -Name 'Agent XPs' -Value $currentValue.RunValue
            $result | Should -BeTrue
        }

        It 'Should return false when testing incorrect value' {
            # Get current value
            $currentValue = Get-SqlDscConfigurationOption -ServerObject $script:serverObject -Name 'Agent XPs'

            # Test opposite value - should return false
            $oppositeValue = if ($currentValue.RunValue -eq 0) { 1 } else { 0 }
            $result = Test-SqlDscConfigurationOption -ServerObject $script:serverObject -Name 'Agent XPs' -Value $oppositeValue
            $result | Should -BeFalse
        }

        It 'Should return true after setting value and testing' {
            # Set Agent XPs to 1
            Set-SqlDscConfigurationOption -ServerObject $script:serverObject -Name 'Agent XPs' -Value 1 -Force

            # Test should return true for the value we just set
            $result = Test-SqlDscConfigurationOption -ServerObject $script:serverObject -Name 'Agent XPs' -Value 1
            $result | Should -BeTrue

            # Test should return false for the opposite value
            $result = Test-SqlDscConfigurationOption -ServerObject $script:serverObject -Name 'Agent XPs' -Value 0
            $result | Should -BeFalse
        }

        It 'Should return true after setting different value and testing' {
            # Set Agent XPs to 0
            Set-SqlDscConfigurationOption -ServerObject $script:serverObject -Name 'Agent XPs' -Value 0 -Force

            # Test should return true for the value we just set
            $result = Test-SqlDscConfigurationOption -ServerObject $script:serverObject -Name 'Agent XPs' -Value 0
            $result | Should -BeTrue

            # Test should return false for the opposite value
            $result = Test-SqlDscConfigurationOption -ServerObject $script:serverObject -Name 'Agent XPs' -Value 1
            $result | Should -BeFalse
        }

        It 'Should throw an error when the configuration option does not exist' {
            { Test-SqlDscConfigurationOption -ServerObject $script:serverObject -Name 'NonExistentOption' -Value 1 -ErrorAction 'Stop' } |
                Should -Throw
        }
    }

    Context 'When testing different configuration options' {
        It 'Should correctly test cost threshold for parallelism option' {
            # Get current value
            $currentValue = Get-SqlDscConfigurationOption -ServerObject $script:serverObject -Name 'cost threshold for parallelism'

            # Test should return true for current value
            $result = Test-SqlDscConfigurationOption -ServerObject $script:serverObject -Name 'cost threshold for parallelism' -Value $currentValue.RunValue
            $result | Should -BeTrue

            # Test should return false for a different value (if current is not 99, test 99, otherwise test 50)
            $differentValue = if ($currentValue.RunValue -ne 99) { 99 } else { 50 }
            $result = Test-SqlDscConfigurationOption -ServerObject $script:serverObject -Name 'cost threshold for parallelism' -Value $differentValue
            $result | Should -BeFalse
        }

        It 'Should correctly test max degree of parallelism option' {
            # Get current value
            $currentValue = Get-SqlDscConfigurationOption -ServerObject $script:serverObject -Name 'max degree of parallelism'

            # Test should return true for current value
            $result = Test-SqlDscConfigurationOption -ServerObject $script:serverObject -Name 'max degree of parallelism' -Value $currentValue.RunValue
            $result | Should -BeTrue

            # Test should return false for a different value (if current is not 8, test 8, otherwise test 4)
            $differentValue = if ($currentValue.RunValue -ne 8) { 8 } else { 4 }
            $result = Test-SqlDscConfigurationOption -ServerObject $script:serverObject -Name 'max degree of parallelism' -Value $differentValue
            $result | Should -BeFalse
        }
    }

    Context 'When using pipeline input' {
        It 'Should accept ServerObject from pipeline' {
            # Get current value
            $currentValue = Get-SqlDscConfigurationOption -ServerObject $script:serverObject -Name 'Agent XPs'

            # Test using pipeline should return true for current value
            $result = $script:serverObject | Test-SqlDscConfigurationOption -Name 'Agent XPs' -Value $currentValue.RunValue
            $result | Should -BeTrue

            # Test using pipeline should return false for opposite value
            $oppositeValue = if ($currentValue.RunValue -eq 0) { 1 } else { 0 }
            $result = $script:serverObject | Test-SqlDscConfigurationOption -Name 'Agent XPs' -Value $oppositeValue
            $result | Should -BeFalse
        }
    }

    Context 'When testing boundary values' {
        It 'Should correctly test minimum boundary value for Agent XPs' {
            # Set to minimum value (0)
            Set-SqlDscConfigurationOption -ServerObject $script:serverObject -Name 'Agent XPs' -Value 0 -Force

            # Test minimum value
            $result = Test-SqlDscConfigurationOption -ServerObject $script:serverObject -Name 'Agent XPs' -Value 0
            $result | Should -BeTrue
        }

        It 'Should correctly test maximum boundary value for Agent XPs' {
            # Set to maximum value (1)
            Set-SqlDscConfigurationOption -ServerObject $script:serverObject -Name 'Agent XPs' -Value 1 -Force

            # Test maximum value
            $result = Test-SqlDscConfigurationOption -ServerObject $script:serverObject -Name 'Agent XPs' -Value 1
            $result | Should -BeTrue
        }
    }
}
