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

    # Loading mocked classes
    Add-Type -Path (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '../Stubs') -ChildPath 'SMO.cs')

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

Describe 'Get-SqlDscDateTime' -Tag 'Public' {
    It 'Should have the correct parameters in parameter set <MockParameterSetName>' -ForEach @(
        @{
            MockParameterSetName   = '__AllParameterSets'
            # cSpell: disable-next
            MockExpectedParameters = '[-ServerObject] <Server> [[-DateTimeFunction] <string>] [[-StatementTimeout] <int>] [<CommonParameters>]'
        }
    ) {
        $result = (Get-Command -Name 'Get-SqlDscDateTime').ParameterSets |
            Where-Object -FilterScript {
                $_.Name -eq $mockParameterSetName
            } |
            Select-Object -Property @(
                @{
                    Name       = 'ParameterSetName'
                    Expression = { $_.Name }
                },
                @{
                    Name       = 'ParameterListAsString'
                    Expression = { $_.ToString() }
                }
            )

        $result.ParameterSetName | Should -Be $MockParameterSetName
        $result.ParameterListAsString | Should -Be $MockExpectedParameters
    }

    Context 'When retrieving date and time from SQL Server' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'

            $mockDateTime = [System.DateTime]::Parse('2023-12-13 10:30:45.1234567')
        }

        Context 'When calling the command with only mandatory parameters' {
            BeforeAll {
                Mock -CommandName Invoke-SqlDscScalarQuery -MockWith {
                    return $mockDateTime
                }
            }

            It 'Should execute the query using default SYSDATETIME function and return the DateTime result' {
                $result = Get-SqlDscDateTime -ServerObject $mockServerObject

                $result | Should -BeOfType [System.DateTime]
                $result | Should -Be $mockDateTime

                Should -Invoke -CommandName Invoke-SqlDscScalarQuery -Exactly -Times 1 -Scope It -ParameterFilter {
                    $Query -eq 'SELECT SYSDATETIME()'
                }
            }
        }

        Context 'When passing parameter ServerObject over the pipeline' {
            BeforeAll {
                Mock -CommandName Invoke-SqlDscScalarQuery -MockWith {
                    return $mockDateTime
                }
            }

            It 'Should execute the query and return the DateTime result' {
                $result = $mockServerObject | Get-SqlDscDateTime

                $result | Should -BeOfType [System.DateTime]
                $result | Should -Be $mockDateTime

                Should -Invoke -CommandName Invoke-SqlDscScalarQuery -Exactly -Times 1 -Scope It
            }
        }

        Context 'When calling the command with DateTimeFunction parameter' {
            BeforeAll {
                Mock -CommandName Invoke-SqlDscScalarQuery -MockWith {
                    return $mockDateTime
                }
            }

            It 'Should execute the query using <DateTimeFunction> function' -ForEach @(
                @{ DateTimeFunction = 'SYSDATETIME'; ExpectedQuery = 'SELECT SYSDATETIME()' }
                @{ DateTimeFunction = 'SYSDATETIMEOFFSET'; ExpectedQuery = 'SELECT SYSDATETIMEOFFSET()' }
                @{ DateTimeFunction = 'SYSUTCDATETIME'; ExpectedQuery = 'SELECT SYSUTCDATETIME()' }
                @{ DateTimeFunction = 'GETDATE'; ExpectedQuery = 'SELECT GETDATE()' }
                @{ DateTimeFunction = 'GETUTCDATE'; ExpectedQuery = 'SELECT GETUTCDATE()' }
            ) {
                $result = Get-SqlDscDateTime -ServerObject $mockServerObject -DateTimeFunction $DateTimeFunction

                $result | Should -BeOfType [System.DateTime]

                Should -Invoke -CommandName Invoke-SqlDscScalarQuery -Exactly -Times 1 -Scope It -ParameterFilter {
                    $Query -eq $ExpectedQuery
                }
            }
        }

        Context 'When calling the command with StatementTimeout parameter' {
            BeforeAll {
                Mock -CommandName Invoke-SqlDscScalarQuery -MockWith {
                    return $mockDateTime
                }
            }

            It 'Should execute the query with the specified timeout' {
                $result = Get-SqlDscDateTime -ServerObject $mockServerObject -StatementTimeout 900

                $result | Should -BeOfType [System.DateTime]

                Should -Invoke -CommandName Invoke-SqlDscScalarQuery -Exactly -Times 1 -Scope It -ParameterFilter {
                    $StatementTimeout -eq 900
                }
            }
        }

        Context 'When the query returns a DateTimeOffset value' {
            BeforeAll {
                $mockDateTimeOffset = [System.DateTimeOffset]::Parse('2023-12-13 10:30:45.1234567 -05:00')

                Mock -CommandName Invoke-SqlDscScalarQuery -MockWith {
                    return $mockDateTimeOffset
                }
            }

            It 'Should convert DateTimeOffset to DateTime and return the result' {
                $result = Get-SqlDscDateTime -ServerObject $mockServerObject -DateTimeFunction 'SYSDATETIMEOFFSET'

                $result | Should -BeOfType [System.DateTime]
                $result | Should -Be $mockDateTimeOffset.DateTime

                Should -Invoke -CommandName Invoke-SqlDscScalarQuery -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When an exception is thrown' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'

            Mock -CommandName Invoke-SqlDscScalarQuery -MockWith {
                throw 'Mocked error'
            }
        }

        Context 'When ErrorAction is set to Stop' {
            It 'Should throw the correct error' {
                {
                    Get-SqlDscDateTime -ServerObject $mockServerObject -ErrorAction 'Stop'
                } | Should -Throw

                Should -Invoke -CommandName Invoke-SqlDscScalarQuery -Exactly -Times 1 -Scope It
            }
        }

        Context 'When ErrorAction is set to Ignore or SilentlyContinue' {
            It 'Should not throw an exception and does not return any result' {
                $result = Get-SqlDscDateTime -ServerObject $mockServerObject -ErrorAction 'Ignore'

                $result | Should -BeNullOrEmpty

                Should -Invoke -CommandName Invoke-SqlDscScalarQuery -Exactly -Times 1 -Scope It
            }
        }
    }
}
