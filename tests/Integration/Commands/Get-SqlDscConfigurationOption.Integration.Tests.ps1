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

Describe 'Get-SqlDscConfigurationOption' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        $script:mockInstanceName = 'DSCSQLTEST'

        $mockSqlAdministratorUserName = 'SqlAdmin' # Using computer name as NetBIOS name throw exception.
        $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

        $script:mockSqlAdminCredential = [System.Management.Automation.PSCredential]::new($mockSqlAdministratorUserName, $mockSqlAdministratorPassword)

        $script:serverObject = Connect-SqlDscDatabaseEngine -InstanceName $script:mockInstanceName -Credential $script:mockSqlAdminCredential

        # Get the original value of 'Agent XPs' to restore later
        $agentXPsOption = Get-SqlDscConfigurationOption -ServerObject $script:serverObject -Name 'Agent XPs'
        $script:originalAgentXPsValue = $agentXPsOption.ConfigValue

        # Set Agent XPs to 1 if it's not already set
        if ($script:originalAgentXPsValue -ne 1)
        {
            Set-SqlDscConfigurationOption -ServerObject $script:serverObject -Name 'Agent XPs' -Value 1
        }
    }

    AfterAll {
        # Restore the original value of 'Agent XPs' if it was not 1
        if ($script:originalAgentXPsValue -ne 1)
        {
            Set-SqlDscConfigurationOption -ServerObject $script:serverObject -Name 'Agent XPs' -Value $script:originalAgentXPsValue
        }

        Disconnect-SqlDscDatabaseEngine -ServerObject $script:serverObject
    }

    Context 'When getting all configuration options' {
        It 'Should return an array of configuration option metadata objects' {
            $result = Get-SqlDscConfigurationOption -ServerObject $script:serverObject

            <#
                Casting to array to ensure we get the count on Windows PowerShell
                when there is only one configuration option.
            #>
            @($result).Count | Should -BeGreaterOrEqual 1
            @($result)[0] | Should -BeOfType 'PSCustomObject'
            @($result)[0].PSTypeNames[0] | Should -Be 'SqlDsc.ConfigurationOption'
        }

        It 'Should return configuration options with expected properties' {
            $result = Get-SqlDscConfigurationOption -ServerObject $script:serverObject

            $firstOption = @($result)[0]
            $firstOption.Name | Should -Not -BeNullOrEmpty
            $firstOption.PSObject.Properties.Name | Should -Contain 'RunValue'
            $firstOption.PSObject.Properties.Name | Should -Contain 'ConfigValue'
            $firstOption.PSObject.Properties.Name | Should -Contain 'Minimum'
            $firstOption.PSObject.Properties.Name | Should -Contain 'Maximum'
            $firstOption.PSObject.Properties.Name | Should -Contain 'IsDynamic'
        }
    }

    Context 'When getting a specific configuration option' {
        It 'Should return the Agent XPs configuration option with expected values' {
            $result = Get-SqlDscConfigurationOption -ServerObject $script:serverObject -Name 'Agent XPs'

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType 'PSCustomObject'
            $result.PSTypeNames[0] | Should -Be 'SqlDsc.ConfigurationOption'
            $result.Name | Should -Be 'Agent XPs'
            $result.RunValue | Should -Be 1
            $result.ConfigValue | Should -Be 1
            $result.Minimum | Should -Be 0
            $result.Maximum | Should -Be 1
            $result.IsDynamic | Should -BeTrue
        }

        It 'Should throw an error when the configuration option does not exist' {
            { Get-SqlDscConfigurationOption -ServerObject $script:serverObject -Name 'NonExistentOption' -ErrorAction 'Stop' } |
                Should -Throw
        }

        It 'Should return null when the configuration option does not exist and error action is SilentlyContinue' {
            $result = Get-SqlDscConfigurationOption -ServerObject $script:serverObject -Name 'NonExistentOption' -ErrorAction 'SilentlyContinue'

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'When using wildcard patterns' {
        It 'Should return configuration options that match the wildcard pattern' {
            $result = Get-SqlDscConfigurationOption -ServerObject $script:serverObject -Name '*XP*'

            @($result).Count | Should -BeGreaterOrEqual 1
            $result | Where-Object -FilterScript { $_.Name -eq 'Agent XPs' } | Should -Not -BeNullOrEmpty
        }
    }

    Context 'When using the Raw parameter' {
        It 'Should return raw SMO ConfigProperty objects' {
            $result = Get-SqlDscConfigurationOption -ServerObject $script:serverObject -Name 'Agent XPs' -Raw

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.ConfigProperty'
            $result.DisplayName | Should -Be 'Agent XPs'
            $result.RunValue | Should -Be 1
            $result.ConfigValue | Should -Be 1
        }
    }

    Context 'When using the Refresh parameter' {
        It 'Should return the same results with and without Refresh' {
            $resultWithoutRefresh = Get-SqlDscConfigurationOption -ServerObject $script:serverObject -Name 'Agent XPs'
            $resultWithRefresh = Get-SqlDscConfigurationOption -ServerObject $script:serverObject -Name 'Agent XPs' -Refresh

            $resultWithoutRefresh.Name | Should -Be $resultWithRefresh.Name
            $resultWithoutRefresh.RunValue | Should -Be $resultWithRefresh.RunValue
            $resultWithoutRefresh.ConfigValue | Should -Be $resultWithRefresh.ConfigValue
        }
    }

    Context 'When using pipeline input' {
        It 'Should accept ServerObject from pipeline' {
            $result = $script:serverObject | Get-SqlDscConfigurationOption -Name 'Agent XPs'

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType 'PSCustomObject'
            $result.Name | Should -Be 'Agent XPs'
            $result.RunValue | Should -Be 1
        }
    }
}
