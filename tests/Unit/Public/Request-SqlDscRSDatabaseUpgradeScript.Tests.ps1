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

    $env:SqlServerDscCI = $true

    Import-Module -Name $script:moduleName -ErrorAction 'Stop'

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:moduleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Remove-Item -Path 'env:SqlServerDscCI'
}

Describe 'Request-SqlDscRSDatabaseUpgradeScript' {
    Context 'When validating parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = '__AllParameterSets'
                ExpectedParameters = '[-Configuration] <Object> [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Request-SqlDscRSDatabaseUpgradeScript').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }
    }

    Context 'When generating database upgrade script successfully' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            $mockScript = @"
-- Upgrade script for ReportServer database
ALTER TABLE dbo.Catalog ADD NewColumn nvarchar(100) NULL;
GO
"@

            Mock -CommandName Invoke-RsCimMethod -MockWith {
                return @{
                    Script = $mockScript
                }
            }
        }

        It 'Should return the database upgrade script' {
            $result = $mockCimInstance | Request-SqlDscRSDatabaseUpgradeScript

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeLike '*Upgrade script*'
            $result | Should -BeLike '*ALTER TABLE*'

            Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                $MethodName -eq 'GenerateDatabaseUpgradeScript'
            } -Exactly -Times 1
        }
    }

    Context 'When no upgrade is needed' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod -MockWith {
                return @{
                    Script = ''
                }
            }
        }

        It 'Should return an empty script' {
            $result = $mockCimInstance | Request-SqlDscRSDatabaseUpgradeScript

            $result | Should -BeNullOrEmpty

            Should -Invoke -CommandName Invoke-RsCimMethod -Exactly -Times 1
        }
    }

    Context 'When CIM method fails' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod -MockWith {
                throw 'Method GenerateDatabaseUpgradeScript() failed with an error.'
            }
        }

        It 'Should throw a terminating error' {
            { $mockCimInstance | Request-SqlDscRSDatabaseUpgradeScript } | Should -Throw -ErrorId 'RSRSDBUS0001,Request-SqlDscRSDatabaseUpgradeScript'
        }
    }

    Context 'When passing configuration as parameter' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod -MockWith {
                return @{
                    Script = '-- Upgrade script'
                }
            }
        }

        It 'Should generate database upgrade script' {
            $result = Request-SqlDscRSDatabaseUpgradeScript -Configuration $mockCimInstance

            $result | Should -Not -BeNullOrEmpty

            Should -Invoke -CommandName Invoke-RsCimMethod -Exactly -Times 1
        }
    }
}
