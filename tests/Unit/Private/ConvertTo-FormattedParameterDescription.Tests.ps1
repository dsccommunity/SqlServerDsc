[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
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
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
    }
}

BeforeAll {
    $env:SqlServerDscCI = $true

    $script:moduleName = 'SqlServerDsc'

    Import-Module -Name $script:moduleName -Force -ErrorAction 'Stop'

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:moduleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Remove-Item -Path 'Env:\SqlServerDscCI' -ErrorAction 'SilentlyContinue'

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:moduleName -All | Remove-Module -Force
}

Describe 'ConvertTo-FormattedParameterDescription' -Tag 'Private' {
    Context 'When converting bound parameters to formatted description' {
        It 'Should format parameters correctly when multiple parameters are provided' {
            InModuleScope -ScriptBlock {
                $boundParameters = @{
                    EmailAddress = 'test@contoso.com'
                    CategoryName = 'TestCategory'
                    ServerObject = 'MockServerObject'
                    Name = 'TestOperator'
                    Force = $true
                }

                $excludeParameters = @('ServerObject', 'Name', 'Force')

                $result = ConvertTo-FormattedParameterDescription -BoundParameters $boundParameters -Exclude $excludeParameters

                # Check that parameters are sorted alphabetically
                $result | Should -Be "`r`n    CategoryName: 'TestCategory'`r`n    EmailAddress: 'test@contoso.com'"
            }
        }

        It 'Should return no parameters message when no settable parameters are provided' {
            InModuleScope -ScriptBlock {
                $boundParameters = @{
                    ServerObject = 'MockServerObject'
                    Name = 'TestOperator'
                    Force = $true
                }

                $excludeParameters = @('ServerObject', 'Name', 'Force')

                $result = ConvertTo-FormattedParameterDescription -BoundParameters $boundParameters -Exclude $excludeParameters

                $result | Should -Be " $($script:localizedData.ConvertTo_FormattedParameterDescription_NoParametersToUpdate)"
            }
        }

        It 'Should format single parameter correctly' {
            InModuleScope -ScriptBlock {
                $boundParameters = @{
                    EmailAddress = 'admin@company.com'
                    ServerObject = 'MockServerObject'
                }

                $excludeParameters = @('ServerObject')

                $result = ConvertTo-FormattedParameterDescription -BoundParameters $boundParameters -Exclude $excludeParameters

                $result | Should -Be "`r`n    EmailAddress: 'admin@company.com'"
            }
        }

        It 'Should handle empty exclude parameters array' {
            InModuleScope -ScriptBlock {
                $boundParameters = @{
                    EmailAddress = 'test@contoso.com'
                    CategoryName = 'TestCategory'
                }

                $result = ConvertTo-FormattedParameterDescription -BoundParameters $boundParameters -Exclude @()

                # Check that parameters are sorted alphabetically
                $result | Should -Be "`r`n    CategoryName: 'TestCategory'`r`n    EmailAddress: 'test@contoso.com'"
            }
        }

        It 'Should handle various data types correctly' {
            InModuleScope -ScriptBlock {
                $boundParameters = @{
                    EmailAddress = 'test@contoso.com'
                    PagerDays = 'Monday'
                    SaturdayPagerEndTime = [TimeSpan]::new(17, 0, 0)
                    Force = $true
                }

                $excludeParameters = @('Force')

                $result = ConvertTo-FormattedParameterDescription -BoundParameters $boundParameters -Exclude $excludeParameters

                # Check that parameters are sorted alphabetically
                $result | Should -Be "`r`n    EmailAddress: 'test@contoso.com'`r`n    PagerDays: 'Monday'`r`n    SaturdayPagerEndTime: '17:00:00'"
            }
        }

        It 'Should mask SecureString values' {
            InModuleScope -ScriptBlock {
                $securePassword = ConvertTo-SecureString 'P@ssw0rd' -AsPlainText -Force
                $boundParameters = @{
                    EmailAddress = 'test@contoso.com'
                    Password = $securePassword
                }

                $result = ConvertTo-FormattedParameterDescription -BoundParameters $boundParameters -Exclude @()

                $result | Should -Be "`r`n    EmailAddress: 'test@contoso.com'`r`n    Password: '***'"
            }
        }

        It 'Should show only username for PSCredential objects' {
            InModuleScope -ScriptBlock {
                $securePassword = ConvertTo-SecureString 'P@ssw0rd' -AsPlainText -Force
                $credential = [System.Management.Automation.PSCredential]::new('TestUser', $securePassword)
                $boundParameters = @{
                    EmailAddress = 'test@contoso.com'
                    Credential = $credential
                }

                $result = ConvertTo-FormattedParameterDescription -BoundParameters $boundParameters -Exclude @()

                $result | Should -Be "`r`n    Credential: 'TestUser'`r`n    EmailAddress: 'test@contoso.com'"
            }
        }

        It 'Should format arrays as comma-separated values' {
            InModuleScope -ScriptBlock {
                $boundParameters = @{
                    EmailAddress = 'test@contoso.com'
                    Categories = @('Category1', 'Category2', 'Category3')
                    Numbers = @(1, 2, 3)
                }

                $result = ConvertTo-FormattedParameterDescription -BoundParameters $boundParameters -Exclude @()

                $result | Should -Be "`r`n    Categories: 'Category1, Category2, Category3'`r`n    EmailAddress: 'test@contoso.com'`r`n    Numbers: '1, 2, 3'"
            }
        }

        It 'Should handle mixed sensitive and non-sensitive parameters' {
            InModuleScope -ScriptBlock {
                $securePassword = ConvertTo-SecureString 'P@ssw0rd' -AsPlainText -Force
                $credential = [System.Management.Automation.PSCredential]::new('TestUser', $securePassword)
                $boundParameters = @{
                    EmailAddress = 'test@contoso.com'
                    Password = $securePassword
                    Credential = $credential
                    Categories = @('Cat1', 'Cat2')
                    Force = $true
                }

                $excludeParameters = @('Force')

                $result = ConvertTo-FormattedParameterDescription -BoundParameters $boundParameters -Exclude $excludeParameters

                $result | Should -Be "`r`n    Categories: 'Cat1, Cat2'`r`n    Credential: 'TestUser'`r`n    EmailAddress: 'test@contoso.com'`r`n    Password: '***'"
            }
        }
    }
}
