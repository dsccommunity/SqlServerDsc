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

Describe 'Get-SqlDscPreferredModule' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    Context 'When using default parameters' {
        It 'Should return a module object when preferred modules are available' {
            $result = Get-SqlDscPreferredModule -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType 'PSModuleInfo'
            $result.Name | Should -BeIn @('SqlServer', 'SQLPS')
        }

        It 'Should return SqlServer module if available' {
            # Check if SqlServer module is available
            $sqlServerModule = Get-Module -Name 'SqlServer' -ListAvailable | Select-Object -First 1

            if ($sqlServerModule) {
                $result = Get-SqlDscPreferredModule -ErrorAction 'Stop'

                $result | Should -Not -BeNullOrEmpty
                $result.Name | Should -Be 'SqlServer'
                $result.Version | Should -Not -BeNullOrEmpty
            }
            else {
                Set-ItResult -Skipped -Because 'SqlServer module is not available in test environment'
            }
        }

        It 'Should return the latest version when multiple versions are available' {
            $availableModules = Get-Module -Name 'SqlServer', 'SQLPS' -ListAvailable

            if ($availableModules) {
                $result = Get-SqlDscPreferredModule -ErrorAction 'Stop'

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType 'PSModuleInfo'

                # Verify it returns the latest version for the preferred module
                $sameNameModules = $availableModules | Where-Object { $_.Name -eq $result.Name }
                if ($sameNameModules.Count -gt 1) {
                    $latestVersion = ($sameNameModules | Sort-Object Version -Descending | Select-Object -First 1).Version
                    $result.Version | Should -Be $latestVersion
                }
            }
            else {
                Set-ItResult -Skipped -Because 'No preferred modules are available in test environment'
            }
        }
    }

    Context 'When using the Name parameter' {
        It 'Should return the specified module when it exists' {
            # Test with SqlServer if available
            $sqlServerModule = Get-Module -Name 'SqlServer' -ListAvailable | Select-Object -First 1

            if ($sqlServerModule) {
                $result = Get-SqlDscPreferredModule -Name @('SqlServer') -ErrorAction 'Stop'

                $result | Should -Not -BeNullOrEmpty
                $result.Name | Should -Be 'SqlServer'
            }
            else {
                Set-ItResult -Skipped -Because 'SqlServer module is not available in test environment'
            }
        }

        It 'Should return null when specified module does not exist' {
            $result = Get-SqlDscPreferredModule -Name @('NonExistentModule') -ErrorAction 'SilentlyContinue' -ErrorVariable errors

            $result | Should -BeNullOrEmpty
            $errors | Should -HaveCount 1
            $errors[0].FullyQualifiedErrorId | Should -Be 'GSDPM0001,Get-SqlDscPreferredModule'
        }

        It 'Should return the first available module from a list' {
            # Test with a list where first module doesn't exist but second does
            $sqlServerModule = Get-Module -Name 'SqlServer' -ListAvailable | Select-Object -First 1

            if ($sqlServerModule) {
                $result = Get-SqlDscPreferredModule -Name @('NonExistentModule', 'SqlServer') -ErrorAction 'Stop'

                $result | Should -Not -BeNullOrEmpty
                $result.Name | Should -Be 'SqlServer'
            }
            else {
                Set-ItResult -Skipped -Because 'SqlServer module is not available in test environment'
            }
        }
    }

    Context 'When using the Refresh parameter' {
        It 'Should refresh PSModulePath and return a module' {
            $result = Get-SqlDscPreferredModule -Refresh -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType 'PSModuleInfo'
            $result.Name | Should -BeIn @('SqlServer', 'SQLPS')
        }

        It 'Should return the same result with and without Refresh' {
            $resultWithoutRefresh = Get-SqlDscPreferredModule -ErrorAction 'Stop'
            $resultWithRefresh = Get-SqlDscPreferredModule -Refresh -ErrorAction 'Stop'

            $resultWithoutRefresh.Name | Should -Be $resultWithRefresh.Name
            $resultWithoutRefresh.Version | Should -Be $resultWithRefresh.Version
        }
    }

    Context 'When using environment variables' {
        Context 'When SMODefaultModuleName is set' {
            BeforeAll {
                # Backup original environment variable
                $originalSMODefaultModuleName = $env:SMODefaultModuleName
                
                # Set environment variable to SqlServer if available
                $sqlServerModule = Get-Module -Name 'SqlServer' -ListAvailable | Select-Object -First 1
                if ($sqlServerModule) {
                    $env:SMODefaultModuleName = 'SqlServer'
                }
            }

            AfterAll {
                # Restore original environment variable
                if ($originalSMODefaultModuleName) {
                    $env:SMODefaultModuleName = $originalSMODefaultModuleName
                }
                else {
                    Remove-Item -Path 'env:SMODefaultModuleName' -ErrorAction 'SilentlyContinue'
                }
            }

            It 'Should use the module specified in SMODefaultModuleName' {
                $sqlServerModule = Get-Module -Name 'SqlServer' -ListAvailable | Select-Object -First 1

                if ($sqlServerModule -and $env:SMODefaultModuleName -eq 'SqlServer') {
                    $result = Get-SqlDscPreferredModule -ErrorAction 'Stop'

                    $result | Should -Not -BeNullOrEmpty
                    $result.Name | Should -Be 'SqlServer'
                }
                else {
                    Set-ItResult -Skipped -Because 'SqlServer module is not available or environment variable not set properly'
                }
            }
        }

        Context 'When SMODefaultModuleVersion is set' {
            BeforeAll {
                # Backup original environment variable
                $originalSMODefaultModuleVersion = $env:SMODefaultModuleVersion
                
                # Get available SqlServer module version if available
                $sqlServerModule = Get-Module -Name 'SqlServer' -ListAvailable | Select-Object -First 1
                if ($sqlServerModule) {
                    $env:SMODefaultModuleVersion = $sqlServerModule.Version.ToString()
                }
            }

            AfterAll {
                # Restore original environment variable
                if ($originalSMODefaultModuleVersion) {
                    $env:SMODefaultModuleVersion = $originalSMODefaultModuleVersion
                }
                else {
                    Remove-Item -Path 'env:SMODefaultModuleVersion' -ErrorAction 'SilentlyContinue'
                }
            }

            It 'Should return the specific version specified in SMODefaultModuleVersion' {
                $sqlServerModule = Get-Module -Name 'SqlServer' -ListAvailable | Select-Object -First 1

                if ($sqlServerModule -and $env:SMODefaultModuleVersion) {
                    $result = Get-SqlDscPreferredModule -ErrorAction 'Stop'

                    $result | Should -Not -BeNullOrEmpty
                    $result.Name | Should -Be 'SqlServer'
                    $result.Version.ToString() | Should -Be $env:SMODefaultModuleVersion
                }
                else {
                    Set-ItResult -Skipped -Because 'SqlServer module is not available or environment variable not set properly'
                }
            }

            It 'Should throw an error when specified version does not exist' {
                # Backup original environment variable
                $originalSMODefaultModuleVersion = $env:SMODefaultModuleVersion
                
                try {
                    # Set to a non-existent version
                    $env:SMODefaultModuleVersion = '999.999.999'

                    { Get-SqlDscPreferredModule -ErrorAction 'Stop' } | Should -Throw -ErrorId 'GSDPM0001,Get-SqlDscPreferredModule'
                }
                finally {
                    # Restore original environment variable
                    if ($originalSMODefaultModuleVersion) {
                        $env:SMODefaultModuleVersion = $originalSMODefaultModuleVersion
                    }
                    else {
                        Remove-Item -Path 'env:SMODefaultModuleVersion' -ErrorAction 'SilentlyContinue'
                    }
                }
            }
        }
    }

    Context 'When validating error handling' {
        It 'Should throw a terminating error when no modules are found and ErrorAction is Stop' {
            { Get-SqlDscPreferredModule -Name @('NonExistentModule1', 'NonExistentModule2') -ErrorAction 'Stop' } | 
                Should -Throw -ErrorId 'GSDPM0001,Get-SqlDscPreferredModule'
        }

        It 'Should write a non-terminating error when no modules are found and ErrorAction is Continue' {
            $result = Get-SqlDscPreferredModule -Name @('NonExistentModule1', 'NonExistentModule2') -ErrorAction 'SilentlyContinue' -ErrorVariable errors

            $result | Should -BeNullOrEmpty
            $errors | Should -HaveCount 1
            $errors[0].FullyQualifiedErrorId | Should -Be 'GSDPM0001,Get-SqlDscPreferredModule'
            $errors[0].CategoryInfo.Category | Should -Be 'ObjectNotFound'
        }
    }

    Context 'When validating output type' {
        It 'Should return PSModuleInfo type' {
            $result = Get-SqlDscPreferredModule -ErrorAction 'Stop'

            $result | Should -BeOfType 'PSModuleInfo'
            $result.PSTypeNames | Should -Contain 'System.Management.Automation.PSModuleInfo'
        }

        It 'Should have expected properties' {
            $result = Get-SqlDscPreferredModule -ErrorAction 'Stop'

            $result.Name | Should -Not -BeNullOrEmpty
            $result.Version | Should -Not -BeNullOrEmpty
            $result.Path | Should -Not -BeNullOrEmpty
        }
    }
}