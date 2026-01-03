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

Describe 'Get-SqlDscRSVersion' {
    Context 'When validating parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = '__AllParameterSets'
                ExpectedParameters = '[-Configuration] <Object> [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Get-SqlDscRSVersion').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }
    }

    Context 'When getting the version successfully' {
        It 'Should return the version for SQL Server 2016 (version 13)' {
            $mockConfiguration = @{
                CurrentVersion = '13.0.4001.0'
            }

            $result = $mockConfiguration | Get-SqlDscRSVersion

            $result | Should -BeOfType [System.Version]
            $result.Major | Should -Be 13
            $result.Minor | Should -Be 0
            $result.Build | Should -Be 4001
            $result.Revision | Should -Be 0
        }

        It 'Should return the version for SQL Server 2017 (version 14)' {
            $mockConfiguration = @{
                CurrentVersion = '14.0.600.250'
            }

            $result = $mockConfiguration | Get-SqlDscRSVersion

            $result | Should -BeOfType [System.Version]
            $result.Major | Should -Be 14
            $result.Minor | Should -Be 0
            $result.Build | Should -Be 600
            $result.Revision | Should -Be 250
        }

        It 'Should return the version for SQL Server 2019 (version 15)' {
            $mockConfiguration = @{
                CurrentVersion = '15.0.1100.0'
            }

            $result = $mockConfiguration | Get-SqlDscRSVersion

            $result | Should -BeOfType [System.Version]
            $result.Major | Should -Be 15
        }

        It 'Should return the version for SQL Server 2022 (version 16)' {
            $mockConfiguration = @{
                CurrentVersion = '16.0.1000.6'
            }

            $result = $mockConfiguration | Get-SqlDscRSVersion

            $result | Should -BeOfType [System.Version]
            $result.Major | Should -Be 16
        }

        It 'Should return the version for SQL Server 2014 (version 12)' {
            $mockConfiguration = @{
                CurrentVersion = '12.0.4100.0'
            }

            $result = $mockConfiguration | Get-SqlDscRSVersion

            $result | Should -BeOfType [System.Version]
            $result.Major | Should -Be 12
        }
    }

    Context 'When CurrentVersion is null or empty' {
        It 'Should write an error when CurrentVersion is null' {
            $mockConfiguration = @{
                CurrentVersion = $null
            }

            $mockConfiguration | Get-SqlDscRSVersion -ErrorVariable mockErrorVariable -ErrorAction 'SilentlyContinue'

            $mockErrorVariable | Should -HaveCount 1
            $mockErrorVariable[0].FullyQualifiedErrorId | Should -Be 'GSRSV0001,Get-SqlDscRSVersion'
        }

        It 'Should write an error when CurrentVersion is empty' {
            $mockConfiguration = @{
                CurrentVersion = ''
            }

            $mockConfiguration | Get-SqlDscRSVersion -ErrorVariable mockErrorVariable -ErrorAction 'SilentlyContinue'

            $mockErrorVariable | Should -HaveCount 1
            $mockErrorVariable[0].FullyQualifiedErrorId | Should -Be 'GSRSV0001,Get-SqlDscRSVersion'
        }
    }

    Context 'When using parameter instead of pipeline input' {
        It 'Should return the version when Configuration is passed as parameter' {
            $mockConfiguration = @{
                CurrentVersion = '15.0.1100.0'
            }

            $result = Get-SqlDscRSVersion -Configuration $mockConfiguration

            $result | Should -BeOfType [System.Version]
            $result.Major | Should -Be 15
        }
    }
}
