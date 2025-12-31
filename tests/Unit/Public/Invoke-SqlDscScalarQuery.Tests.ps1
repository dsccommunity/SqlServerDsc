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

Describe 'Invoke-SqlDscScalarQuery' -Tag 'Public' {
    It 'Should have the correct parameters in parameter set <MockParameterSetName>' -ForEach @(
        @{
            MockParameterSetName   = '__AllParameterSets'
            # cSpell: disable-next
            MockExpectedParameters = '[-ServerObject] <Server> [-Query] <string> [[-StatementTimeout] <int>] [[-RedactText] <string[]>] [<CommonParameters>]'
        }
    ) {
        $result = (Get-Command -Name 'Invoke-SqlDscScalarQuery').ParameterSets |
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

    It 'Should have ServerObject as a mandatory parameter' {
        $parameterInfo = (Get-Command -Name 'Invoke-SqlDscScalarQuery').Parameters['ServerObject']
        $parameterInfo.Attributes.Mandatory | Should -BeTrue
    }

    It 'Should have Query as a mandatory parameter' {
        $parameterInfo = (Get-Command -Name 'Invoke-SqlDscScalarQuery').Parameters['Query']
        $parameterInfo.Attributes.Mandatory | Should -BeTrue
    }

    It 'Should accept ServerObject from pipeline' {
        $parameterInfo = (Get-Command -Name 'Invoke-SqlDscScalarQuery').Parameters['ServerObject']
        $parameterInfo.Attributes.ValueFromPipeline | Should -BeTrue
    }

    Context 'When executing a scalar query' {
        BeforeAll {
            $mockConnectionContext = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerConnection'
            $mockConnectionContext.StatementTimeout = 100
            $mockConnectionContext | Add-Member -MemberType 'ScriptMethod' -Name 'ExecuteScalar' -Value {
                param
                (
                    [Parameter()]
                    [System.String]
                    $sqlCommand
                )

                $script:mockMethodExecuteScalarCallCount += 1

                return $script:mockExecuteScalarResult
            } -Force

            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' |
                Add-Member -MemberType 'NoteProperty' -Name 'ConnectionContext' -Value $mockConnectionContext -PassThru -Force
        }

        BeforeEach {
            $script:mockMethodExecuteScalarCallCount = 0
            $script:mockExecuteScalarResult = $null
        }

        Context 'When calling the command with only mandatory parameters' {
            It 'Should execute the query without throwing and return the scalar result' {
                $script:mockExecuteScalarResult = 'TestResult'

                $result = Invoke-SqlDscScalarQuery -ServerObject $mockServerObject -Query 'SELECT @@VERSION'

                $result | Should -Be 'TestResult'

                $mockMethodExecuteScalarCallCount | Should -Be 1
            }
        }

        Context 'When passing parameter ServerObject over the pipeline' {
            It 'Should execute the query without throwing and return the scalar result' {
                $script:mockExecuteScalarResult = '12345'

                $result = $mockServerObject | Invoke-SqlDscScalarQuery -Query 'SELECT 12345'

                $result | Should -Be '12345'

                $mockMethodExecuteScalarCallCount | Should -Be 1
            }
        }

        Context 'When calling the command with optional parameter StatementTimeout' {
            It 'Should execute the query without throwing and return the scalar result' {
                $script:mockExecuteScalarResult = 42

                $result = Invoke-SqlDscScalarQuery -StatementTimeout 900 -ServerObject $mockServerObject -Query 'SELECT 42'

                $result | Should -Be 42

                $mockMethodExecuteScalarCallCount | Should -Be 1
            }
        }

        Context 'When calling the command with optional parameter RedactText' {
            It 'Should execute the query without throwing and return the scalar result' {
                $script:mockExecuteScalarResult = 'Success'

                $result = Invoke-SqlDscScalarQuery -RedactText @('MySecret') -ServerObject $mockServerObject -Query 'SELECT MySecret'

                $result | Should -Be 'Success'

                $mockMethodExecuteScalarCallCount | Should -Be 1
            }
        }

        Context 'When the query returns a DateTime value' {
            It 'Should return the DateTime value' {
                $script:mockExecuteScalarResult = [System.DateTime]::Parse('2023-01-01 12:00:00')

                $result = Invoke-SqlDscScalarQuery -ServerObject $mockServerObject -Query 'SELECT SYSDATETIME()'

                $result | Should -BeOfType [System.DateTime]
                $result | Should -Be ([System.DateTime]::Parse('2023-01-01 12:00:00'))

                $mockMethodExecuteScalarCallCount | Should -Be 1
            }
        }

        Context 'When the query returns null' {
            It 'Should return null' {
                $script:mockExecuteScalarResult = $null

                $result = Invoke-SqlDscScalarQuery -ServerObject $mockServerObject -Query 'SELECT NULL'

                $result | Should -BeNullOrEmpty

                $mockMethodExecuteScalarCallCount | Should -Be 1
            }
        }
    }

    Context 'When an exception is thrown' {
        BeforeAll {
            $mockConnectionContext = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerConnection'
            $mockConnectionContext.StatementTimeout = 100
            $mockConnectionContext | Add-Member -MemberType 'ScriptMethod' -Name 'ExecuteScalar' -Value {
                $script:mockMethodExecuteScalarCallCount += 1

                throw 'Mocked error'
            } -Force

            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' |
                Add-Member -MemberType 'NoteProperty' -Name 'ConnectionContext' -Value $mockConnectionContext -PassThru -Force
        }

        BeforeEach {
            $script:mockMethodExecuteScalarCallCount = 0
        }

        Context 'When ErrorAction is set to Stop' {
            It 'Should throw the correct error' {
                {
                    Invoke-SqlDscScalarQuery -ServerObject $mockServerObject -Query 'SELECT invalid' -ErrorAction 'Stop'
                } | Should -Throw -ExpectedMessage '*Mocked error*'

                $mockMethodExecuteScalarCallCount | Should -Be 1
            }
        }

        Context 'When ErrorAction is set to Ignore' {
            It 'Should not throw an exception and does not return any result' {
                $result = Invoke-SqlDscScalarQuery -ServerObject $mockServerObject -Query 'SELECT invalid' -ErrorAction 'Ignore'

                $result | Should -BeNullOrEmpty

                $mockMethodExecuteScalarCallCount | Should -Be 1
            }
        }
    }
}
