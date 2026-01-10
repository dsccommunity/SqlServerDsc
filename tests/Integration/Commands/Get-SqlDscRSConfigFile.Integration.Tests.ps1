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

    Import-Module -Name $script:moduleName -ErrorAction 'Stop'
}

Describe 'Get-SqlDscRSConfigFile' {
    Context 'When getting the configuration file for SQL Server Reporting Services instance' -Tag @('Integration_SQL2019_RS', 'Integration_SQL2022_RS') {
        It 'Should return the configuration file as an XML object for SSRS instance' {
            $result = Get-SqlDscRSConfigFile -InstanceName 'SSRS' -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType 'System.Xml.XmlDocument'
            $result.Configuration | Should -Not -BeNullOrEmpty
        }

        It 'Should return a configuration file with expected structure' {
            $config = Get-SqlDscRSConfigFile -InstanceName 'SSRS' -ErrorAction 'Stop'

            # Verify key configuration sections exist
            $config.Configuration.Dsn | Should -Not -BeNullOrEmpty
            $config.Configuration.InstanceId | Should -Not -BeNullOrEmpty
            $config.Configuration.Service | Should -Not -BeNullOrEmpty
            $config.Configuration.Authentication | Should -Not -BeNullOrEmpty
        }

        It 'Should support XPath queries on the returned XML' {
            $config = Get-SqlDscRSConfigFile -InstanceName 'SSRS' -ErrorAction 'Stop'

            # Use XPath to query authentication types
            $authTypes = $config.SelectSingleNode('//Authentication/AuthenticationTypes')

            $authTypes | Should -Not -BeNullOrEmpty
        }

        It 'Should work with pipeline input from Get-SqlDscRSSetupConfiguration' {
            $result = Get-SqlDscRSSetupConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop' | Get-SqlDscRSConfigFile -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType 'System.Xml.XmlDocument'
            $result.Configuration | Should -Not -BeNullOrEmpty
        }

        It 'Should work with Path parameter using the config file path' {
            $setupConfig = Get-SqlDscRSSetupConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'
            $configFilePath = $setupConfig.ConfigFilePath

            $result = Get-SqlDscRSConfigFile -Path $configFilePath -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType 'System.Xml.XmlDocument'
            $result.Configuration | Should -Not -BeNullOrEmpty
        }
    }

    Context 'When getting the configuration file for Power BI Report Server instance' -Tag @('Integration_PowerBI') {
        # cSpell: ignore PBIRS
        It 'Should return the configuration file as an XML object for PBIRS instance' {
            $result = Get-SqlDscRSConfigFile -InstanceName 'PBIRS' -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType 'System.Xml.XmlDocument'
            $result.Configuration | Should -Not -BeNullOrEmpty
        }

        It 'Should return a configuration file with expected structure' {
            $config = Get-SqlDscRSConfigFile -InstanceName 'PBIRS' -ErrorAction 'Stop'

            # Verify key configuration sections exist
            $config.Configuration.Dsn | Should -Not -BeNullOrEmpty
            $config.Configuration.InstanceId | Should -Not -BeNullOrEmpty
            $config.Configuration.Service | Should -Not -BeNullOrEmpty
        }

        It 'Should work with pipeline input from Get-SqlDscRSSetupConfiguration' {
            $result = Get-SqlDscRSSetupConfiguration -InstanceName 'PBIRS' -ErrorAction 'Stop' | Get-SqlDscRSConfigFile -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType 'System.Xml.XmlDocument'
            $result.Configuration | Should -Not -BeNullOrEmpty
        }

        It 'Should work with Path parameter using the config file path' {
            $setupConfig = Get-SqlDscRSSetupConfiguration -InstanceName 'PBIRS' -ErrorAction 'Stop'
            $configFilePath = $setupConfig.ConfigFilePath

            $result = Get-SqlDscRSConfigFile -Path $configFilePath -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType 'System.Xml.XmlDocument'
            $result.Configuration | Should -Not -BeNullOrEmpty
        }
    }

    Context 'When trying to get the configuration file for a non-existent instance' -Tag @('Integration_SQL2019_RS', 'Integration_SQL2022_RS', 'Integration_PowerBI') {
        It 'Should throw a terminating error' {
            { Get-SqlDscRSConfigFile -InstanceName 'NonExistentInstance' -ErrorAction 'Stop' } | Should -Throw
        }
    }

    Context 'When trying to read a non-existent file path' -Tag @('Integration_SQL2019_RS', 'Integration_SQL2022_RS', 'Integration_PowerBI') {
        It 'Should throw a terminating error' {
            { Get-SqlDscRSConfigFile -Path 'C:\NonExistent\rsreportserver.config' -ErrorAction 'Stop' } | Should -Throw
        }
    }
}
