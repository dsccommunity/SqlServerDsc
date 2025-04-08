[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies has been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies has not been resolved, this will throw an error.
            Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
        }
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
    }
}

BeforeAll {
    $script:dscModuleName = 'SqlServerDsc'

    $env:SqlServerDscCI = $true

    Import-Module -Name $script:dscModuleName

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscModuleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force

    Remove-Item -Path 'env:SqlServerDscCI'
}

Describe 'ConvertTo-SqlDscEditionName' {
    Context 'When converting a known EditionId' {
        BeforeAll {
            $mockLocalizedConvertingEditionId = InModuleScope -ScriptBlock {
                $script:localizedData.ConvertTo_EditionName_ConvertingEditionId
            }

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
            $mockLocalizedUnknownEditionId = InModuleScope -ScriptBlock {
                $script:localizedData.ConvertTo_EditionName_UnknownEditionId
            }

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
