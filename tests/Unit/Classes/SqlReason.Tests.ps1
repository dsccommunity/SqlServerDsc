<#
    .SYNOPSIS
        Unit test for SqlReason class.
#>

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

Describe 'SqlReason' -Tag 'SqlReason' {
    Context 'When instantiating the class' {
        It 'Should not throw an error' {
            $script:mockSqlReasonInstance = InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                [SqlReason]::new()
            }
        }

        It 'Should be of the correct type' {
            $script:mockSqlReasonInstance | Should -Not -BeNullOrEmpty
            $script:mockSqlReasonInstance.GetType().Name | Should -Be 'SqlReason'
        }
    }

    Context 'When setting an reading values' {
        It 'Should be able to set value in instance' {
            $script:mockSqlReasonInstance = InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $sqlReasonInstance = [SqlReason]::new()

                $sqlReasonInstance.Code = 'SqlAudit:SqlAudit:Ensure'
                $sqlReasonInstance.Phrase = 'The property Ensure should be "Present", but was "Absent"'

                return $sqlReasonInstance
            }
        }

        It 'Should be able read the values from instance' {
            $script:mockSqlReasonInstance.Code | Should -Be 'SqlAudit:SqlAudit:Ensure'
            $script:mockSqlReasonInstance.Phrase | Should -Be 'The property Ensure should be "Present", but was "Absent"'
        }
    }
}
