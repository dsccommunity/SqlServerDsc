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

Describe 'Test-SqlDscIsSupportedFeature' -Tag @('Integration_SQL2016', 'Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    Context 'When testing supported features for different SQL Server versions' {
        It 'Should return $true for SQLENGINE feature across all major versions' {
            $testVersions = @('10', '11', '12', '13', '14', '15', '16')
            
            foreach ($version in $testVersions) {
                $result = Test-SqlDscIsSupportedFeature -Feature 'SQLENGINE' -ProductVersion $version -ErrorAction 'Stop'
                $result | Should -BeTrue -Because "SQLENGINE should be supported in SQL Server $version"
            }
        }

        It 'Should return $false for features removed in SQL Server 2014 (version 14)' {
            $removedFeatures = @('RS', 'RS_SHP', 'RS_SHPWFE')
            
            foreach ($feature in $removedFeatures) {
                $result = Test-SqlDscIsSupportedFeature -Feature $feature -ProductVersion '14' -ErrorAction 'Stop'
                $result | Should -BeFalse -Because "$feature was removed in SQL Server 2014"
            }
        }

        It 'Should return $true for features removed in SQL Server 2014 when testing earlier versions' {
            $result = Test-SqlDscIsSupportedFeature -Feature 'RS' -ProductVersion '13' -ErrorAction 'Stop'
            $result | Should -BeTrue -Because "RS should be supported in SQL Server 2013"
        }

        It 'Should return $false for features removed in SQL Server 2016 (version 16)' {
            $removedFeatures = @('Tools', 'BC', 'CONN', 'DREPLAY_CTLR', 'DREPLAY_CLT', 'SNAC_SDK', 'SDK', 'PolyBaseJava', 'SQL_INST_MR', 'SQL_INST_MPY', 'SQL_SHARED_MPY', 'SQL_SHARED_MR')
            
            foreach ($feature in $removedFeatures) {
                $result = Test-SqlDscIsSupportedFeature -Feature $feature -ProductVersion '16' -ErrorAction 'Stop'
                $result | Should -BeFalse -Because "$feature was removed in SQL Server 2016"
            }
        }

        It 'Should return $true for features added in SQL Server 2015 (version 15) when testing that version' {
            $addedFeatures = @('PolyBaseCore', 'PolyBaseJava', 'SQL_INST_JAVA')
            
            foreach ($feature in $addedFeatures) {
                $result = Test-SqlDscIsSupportedFeature -Feature $feature -ProductVersion '15' -ErrorAction 'Stop'
                $result | Should -BeTrue -Because "$feature was added in SQL Server 2015"
            }
        }

        It 'Should return $false for features added in SQL Server 2015 when testing earlier versions' {
            $result = Test-SqlDscIsSupportedFeature -Feature 'PolyBaseCore' -ProductVersion '14' -ErrorAction 'Stop'
            $result | Should -BeFalse -Because "PolyBaseCore was not available in SQL Server 2014"
        }
    }

    Context 'When using pipeline input' {
        It 'Should accept feature names from pipeline and return single result based on last processed item' {
            # The current implementation has a limitation where pipeline input only returns one result
            # This test validates the current behavior
            $features = @('SQLENGINE', 'AS', 'IS')
            
            $result = $features | Test-SqlDscIsSupportedFeature -ProductVersion '15' -ErrorAction 'Stop'
            
            $result | Should -BeOfType 'System.Boolean'
            $result | Should -BeTrue -Because "The last feature processed should be supported in SQL Server 2015"
        }

        It 'Should return false when last feature in pipeline is unsupported' {
            # Test with a mix where the last feature is unsupported
            $features = @('SQLENGINE', 'RS')  # RS is not supported in version 14
            
            $result = $features | Test-SqlDscIsSupportedFeature -ProductVersion '14' -ErrorAction 'Stop'
            
            $result | Should -BeFalse -Because "RS (the last feature) is not supported in SQL Server 2014"
        }
    }

    Context 'When testing edge cases' {
        It 'Should handle major version only input' {
            $result = Test-SqlDscIsSupportedFeature -Feature 'SQLENGINE' -ProductVersion '15' -ErrorAction 'Stop'
            $result | Should -BeTrue
        }

        It 'Should handle full version string input' {
            $result = Test-SqlDscIsSupportedFeature -Feature 'SQLENGINE' -ProductVersion '15.0.2000.5' -ErrorAction 'Stop'
            $result | Should -BeTrue
        }

        It 'Should be case insensitive for feature names' {
            $resultLower = Test-SqlDscIsSupportedFeature -Feature 'sqlengine' -ProductVersion '15' -ErrorAction 'Stop'
            $resultUpper = Test-SqlDscIsSupportedFeature -Feature 'SQLENGINE' -ProductVersion '15' -ErrorAction 'Stop'
            $resultMixed = Test-SqlDscIsSupportedFeature -Feature 'SqlEngine' -ProductVersion '15' -ErrorAction 'Stop'
            
            $resultLower | Should -Be $resultUpper
            $resultUpper | Should -Be $resultMixed
            $resultLower | Should -BeTrue
        }

        It 'Should handle very high version numbers' {
            $result = Test-SqlDscIsSupportedFeature -Feature 'SQLENGINE' -ProductVersion '999' -ErrorAction 'Stop'
            $result | Should -BeTrue -Because "SQLENGINE should be supported in future versions"
        }
    }

    Context 'When testing specific feature version dependencies' {
        It 'Should correctly identify PolyBaseJava as version-specific' {
            # PolyBaseJava was added in version 15 but removed in version 16
            $resultV14 = Test-SqlDscIsSupportedFeature -Feature 'PolyBaseJava' -ProductVersion '14' -ErrorAction 'Stop'
            $resultV15 = Test-SqlDscIsSupportedFeature -Feature 'PolyBaseJava' -ProductVersion '15' -ErrorAction 'Stop'
            $resultV16 = Test-SqlDscIsSupportedFeature -Feature 'PolyBaseJava' -ProductVersion '16' -ErrorAction 'Stop'
            
            $resultV14 | Should -BeFalse -Because "PolyBaseJava was not available before SQL Server 2015"
            $resultV15 | Should -BeTrue -Because "PolyBaseJava was available in SQL Server 2015"
            $resultV16 | Should -BeFalse -Because "PolyBaseJava was removed in SQL Server 2016"
        }
    }
}
