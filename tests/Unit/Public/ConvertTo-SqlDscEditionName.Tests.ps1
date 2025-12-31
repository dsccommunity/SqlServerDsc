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

    # Do not use -Force. Doing so, or unloading the module in AfterAll, causes
    # PowerShell class types to get new identities, breaking type comparisons.
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

Describe 'ConvertTo-SqlDscEditionName' {
    Context 'When converting a known EditionId' {
        BeforeAll {
            $testEditionId = 2176971986

            $mockExpectedResult = @{
                EditionId = 2176971986
                Edition = 'Developer'
                EditionName = 'SQL Server Developer'
            }
        }

        It 'Should return the correct information' {
            $result = ConvertTo-SqlDscEditionName -Id $testEditionId

            $result.EditionId | Should -Be $mockExpectedResult.EditionId
            $result.Edition | Should -Be $mockExpectedResult.Edition
            $result.EditionName | Should -Be $mockExpectedResult.EditionName

            $result | Should -BeOfType 'System.Management.Automation.PSCustomObject'
        }
    }

    Context 'When converting a second known EditionId' {
        BeforeAll {
            $testEditionId = 2017617798
            $mockExpectedResult = @{
                EditionId = 2017617798
                Edition = 'Developer'
                EditionName = 'Power BI Report Server - Developer'
            }
        }

        It 'Should return the correct information' {
            $result = ConvertTo-SqlDscEditionName -Id $testEditionId

            $result.EditionId | Should -Be $mockExpectedResult.EditionId
            $result.Edition | Should -Be $mockExpectedResult.Edition
            $result.EditionName | Should -Be $mockExpectedResult.EditionName
        }
    }

    Context 'When converting an unknown EditionId' {
        BeforeAll {
            $testEditionId = 99999
            $mockExpectedResult = @{
                EditionId = 99999
                Edition = 'Unknown'
                EditionName = 'Unknown'
            }
        }

        It 'Should return Unknown for unknown EditionId' {
            $result = ConvertTo-SqlDscEditionName -Id $testEditionId

            $result.EditionId | Should -Be $mockExpectedResult.EditionId
            $result.Edition | Should -Be $mockExpectedResult.Edition
            $result.EditionName | Should -Be $mockExpectedResult.EditionName
        }
    }
}
