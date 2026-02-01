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

Describe 'ConvertTo-SqlString' -Tag 'Private' {
    Context 'When escaping single quotes' {
        It 'Should escape a single quote in a string' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = ConvertTo-SqlString -Text "O'Brien"

                $result | Should -Be "O''Brien"
            }
        }

        It 'Should escape multiple single quotes in a string' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = ConvertTo-SqlString -Text "O'Brien's"

                $result | Should -Be "O''Brien''s"
            }
        }

        It 'Should return the same string when no single quotes present' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = ConvertTo-SqlString -Text 'Smith'

                $result | Should -Be 'Smith'
            }
        }
    }

    Context 'When handling special characters' {
        It 'Should escape single quotes in passwords with special characters' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = ConvertTo-SqlString -Text "Pass'word;--123"

                $result | Should -Be "Pass''word;--123"
            }
        }

        It 'Should handle string with only single quotes' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = ConvertTo-SqlString -Text "'''"

                $result | Should -Be "''''''"
            }
        }

        It 'Should handle empty string' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = ConvertTo-SqlString -Text ''

                $result | Should -Be ''
            }
        }
    }

    Context 'When used with ConvertTo-EscapedQueryString' {
        It 'Should produce matching escaped values for redaction' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $password = "Pass'word;123"
                $escapedPassword = ConvertTo-SqlString -Text $password

                $query = ConvertTo-EscapedQueryString -Query "EXECUTE sp_test @password = N'{0}';" -Argument $password

                # The escaped password should appear in the query
                $query | Should -BeLike "*$escapedPassword*"

                # The escaped password should be "Pass''word;123"
                $escapedPassword | Should -Be "Pass''word;123"
            }
        }
    }
}
