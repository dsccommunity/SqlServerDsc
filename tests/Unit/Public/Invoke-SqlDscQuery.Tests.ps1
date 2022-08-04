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
                & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
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

    Import-Module -Name $script:dscModuleName

    # Loading mocked classes
    Add-Type -Path (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '../Stubs') -ChildPath 'SMO.cs')

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
}

Describe 'Invoke-SqlDscQuery' -Tag 'Public' {
    Context 'When calling the command with only mandatory parameters' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'

            Mock -CommandName Invoke-Query
        }

        It 'Should execute the query without throwing and without returning any result' {
            $result = Invoke-SqlDscQuery -ServerObject $mockServerObject -DatabaseName 'master' -Query 'select name from sys.databases'

            $result | Should -BeNullOrEmpty

            Should -Invoke -CommandName Invoke-Query -ParameterFilter {
                $PesterBoundParameters.Keys -contains 'SqlServerObject' -and
                $PesterBoundParameters.Keys -contains 'Database' -and
                $PesterBoundParameters.Keys -contains 'Query'
            } -Exactly -Times 1 -Scope It
        }

        Context 'When passing ServerObject over the pipeline' {
            It 'Should execute the query without throwing and without returning any result' {
                $result = $mockServerObject | Invoke-SqlDscQuery -DatabaseName 'master' -Query 'select name from sys.databases'

                $result | Should -BeNullOrEmpty

                Should -Invoke -CommandName Invoke-Query -ParameterFilter {
                    $PesterBoundParameters.Keys -contains 'SqlServerObject' -and
                    $PesterBoundParameters.Keys -contains 'Database' -and
                    $PesterBoundParameters.Keys -contains 'Query'
                } -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When calling the command with optional parameter StatementTimeout' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'

            Mock -CommandName Invoke-Query
        }

        It 'Should execute the query without throwing and without returning any result' {
            $result = Invoke-SqlDscQuery -StatementTimeout 900 -ServerObject $mockServerObject -DatabaseName 'master' -Query 'select name from sys.databases'

            $result | Should -BeNullOrEmpty

            Should -Invoke -CommandName Invoke-Query -ParameterFilter {
                $PesterBoundParameters.Keys -contains 'SqlServerObject' -and
                $PesterBoundParameters.Keys -contains 'Database' -and
                $PesterBoundParameters.Keys -contains 'Query' -and
                $PesterBoundParameters.Keys -contains 'StatementTimeout'
            } -Exactly -Times 1 -Scope It
        }
    }

    Context 'When calling the command with optional parameter RedactText' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'

            Mock -CommandName Invoke-Query
        }

        It 'Should execute the query without throwing and without returning any result' {
            $result = Invoke-SqlDscQuery -RedactText @('MyString') -ServerObject $mockServerObject -DatabaseName 'master' -Query 'select name from sys.databases'

            $result | Should -BeNullOrEmpty

            Should -Invoke -CommandName Invoke-Query -ParameterFilter {
                $PesterBoundParameters.Keys -contains 'SqlServerObject' -and
                $PesterBoundParameters.Keys -contains 'Database' -and
                $PesterBoundParameters.Keys -contains 'Query' -and
                $PesterBoundParameters.Keys -contains 'RedactText'
            } -Exactly -Times 1 -Scope It
        }
    }

    Context 'When calling the command with optional parameter PassThru' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'

            # Actual testing that Invoke-Query returns values is done in the unit tests for Invoke-Query.
            Mock -CommandName Invoke-Query
        }

        It 'Should execute the query without throwing and without returning any result' {
            $result = Invoke-SqlDscQuery -PassThru -ServerObject $mockServerObject -DatabaseName 'master' -Query 'select name from sys.databases'

            $result | Should -BeNullOrEmpty

            Should -Invoke -CommandName Invoke-Query -ParameterFilter {
                $PesterBoundParameters.Keys -contains 'SqlServerObject' -and
                $PesterBoundParameters.Keys -contains 'Database' -and
                $PesterBoundParameters.Keys -contains 'Query' -and
                $PesterBoundParameters.Keys -contains 'WithResults'
            } -Exactly -Times 1 -Scope It
        }
    }
}
