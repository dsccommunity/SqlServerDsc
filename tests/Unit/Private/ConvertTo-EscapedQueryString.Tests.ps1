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

Describe 'ConvertTo-EscapedQueryString' -Tag 'Private' {
    Context 'When escaping single quotes in query arguments' {
        It 'Should escape a single quote in an argument' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = ConvertTo-EscapedQueryString -Query "SELECT * FROM Users WHERE Name = N'{0}'" -Argument "O'Brien"

                $result | Should -Be "SELECT * FROM Users WHERE Name = N'O''Brien'"
            }
        }

        It 'Should escape multiple single quotes in an argument' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = ConvertTo-EscapedQueryString -Query "SELECT * FROM Users WHERE Name = N'{0}'" -Argument "O'Brien's"

                $result | Should -Be "SELECT * FROM Users WHERE Name = N'O''Brien''s'"
            }
        }

        It 'Should handle arguments without single quotes' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = ConvertTo-EscapedQueryString -Query "SELECT * FROM Users WHERE Name = N'{0}'" -Argument 'Smith'

                $result | Should -Be "SELECT * FROM Users WHERE Name = N'Smith'"
            }
        }
    }

    Context 'When formatting a query with multiple arguments' {
        It 'Should escape single quotes in all arguments' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = ConvertTo-EscapedQueryString -Query "EXECUTE sys.sp_adddistributor @distributor = N'{0}', @password = N'{1}';" -Argument 'Server1', "Pass'word;123"

                $result | Should -Be "EXECUTE sys.sp_adddistributor @distributor = N'Server1', @password = N'Pass''word;123';"
            }
        }

        It 'Should handle multiple arguments with single quotes' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = ConvertTo-EscapedQueryString -Query "INSERT INTO Users (FirstName, LastName) VALUES (N'{0}', N'{1}')" -Argument "Mary's", "O'Connor"

                $result | Should -Be "INSERT INTO Users (FirstName, LastName) VALUES (N'Mary''s', N'O''Connor')"
            }
        }
    }

    Context 'When handling special characters that could be used for SQL injection' {
        It 'Should escape single quotes in passwords with special characters' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                # Password with single quote, semicolon, and dashes
                $result = ConvertTo-EscapedQueryString -Query "EXECUTE sys.sp_adddistributor @password = N'{0}';" -Argument "Pass'word;--DROP TABLE Users"

                $result | Should -Be "EXECUTE sys.sp_adddistributor @password = N'Pass''word;--DROP TABLE Users';"
            }
        }

        It 'Should handle argument with only single quotes' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = ConvertTo-EscapedQueryString -Query "SELECT N'{0}'" -Argument "'''"

                $result | Should -Be "SELECT N''''''''"
            }
        }

        It 'Should handle empty string argument' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = ConvertTo-EscapedQueryString -Query "SELECT N'{0}'" -Argument ''

                $result | Should -Be "SELECT N''"
            }
        }
    }
}
