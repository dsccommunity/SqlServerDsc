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

    $env:SqlServerDscCI = $true

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

    Remove-Item -Path 'env:SqlServerDscCI'
}

Describe 'Invoke-SqlDscQuery' -Tag 'Public' {
    # TODO: SHOULD HAVE PARAMETER SET CHECK HERE

    Context 'When calling the command with only mandatory parameters' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'

            Mock -CommandName Invoke-SqlDscQuery
        }

        It 'Should execute the query without throwing and without returning any result' {
            $result = Invoke-SqlDscQuery -ServerObject $mockServerObject -DatabaseName 'master' -Query 'select name from sys.databases'

            $result | Should -BeNullOrEmpty

            Should -Invoke -CommandName Invoke-SqlDscQuery -ParameterFilter {
                $PesterBoundParameters.Keys -contains 'SqlServerObject' -and
                $PesterBoundParameters.Keys -contains 'Database' -and
                $PesterBoundParameters.Keys -contains 'Query'
            } -Exactly -Times 1 -Scope It
        }

        Context 'When passing ServerObject over the pipeline' {
            It 'Should execute the query without throwing and without returning any result' {
                $result = $mockServerObject | Invoke-SqlDscQuery -DatabaseName 'master' -Query 'select name from sys.databases'

                $result | Should -BeNullOrEmpty

                Should -Invoke -CommandName Invoke-SqlDscQuery -ParameterFilter {
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

            Mock -CommandName Invoke-SqlDscQuery
        }

        It 'Should execute the query without throwing and without returning any result' {
            $result = Invoke-SqlDscQuery -StatementTimeout 900 -ServerObject $mockServerObject -DatabaseName 'master' -Query 'select name from sys.databases'

            $result | Should -BeNullOrEmpty

            Should -Invoke -CommandName Invoke-SqlDscQuery -ParameterFilter {
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

            Mock -CommandName Invoke-SqlDscQuery
        }

        It 'Should execute the query without throwing and without returning any result' {
            $result = Invoke-SqlDscQuery -RedactText @('MyString') -ServerObject $mockServerObject -DatabaseName 'master' -Query 'select name from sys.databases'

            $result | Should -BeNullOrEmpty

            Should -Invoke -CommandName Invoke-SqlDscQuery -ParameterFilter {
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

            # Actual testing that Invoke-SqlDscQuery returns values is done in the unit tests for Invoke-SqlDscQuery.
            Mock -CommandName Invoke-SqlDscQuery
        }

        It 'Should execute the query without throwing and without returning any result' {
            $result = Invoke-SqlDscQuery -PassThru -ServerObject $mockServerObject -DatabaseName 'master' -Query 'select name from sys.databases'

            $result | Should -BeNullOrEmpty

            Should -Invoke -CommandName Invoke-SqlDscQuery -ParameterFilter {
                $PesterBoundParameters.Keys -contains 'SqlServerObject' -and
                $PesterBoundParameters.Keys -contains 'Database' -and
                $PesterBoundParameters.Keys -contains 'Query' -and
                $PesterBoundParameters.Keys -contains 'WithResults'
            } -Exactly -Times 1 -Scope It
        }
    }
}

# Describe 'SqlServerDsc.Common\Invoke-SqlDscQuery' -Tag 'InvokeSqlDscQuery' {
#     BeforeAll {
#         $mockExpectedQuery = ''

#         $mockSqlCredentialUserName = 'TestUserName12345'
#         $mockSqlCredentialPassword = 'StrongOne7.'
#         $mockSqlCredentialSecurePassword = ConvertTo-SecureString -String $mockSqlCredentialPassword -AsPlainText -Force
#         $mockSqlCredential = New-Object -TypeName PSCredential -ArgumentList ($mockSqlCredentialUserName, $mockSqlCredentialSecurePassword)

#         $masterDatabaseObject = New-Object -TypeName PSObject
#         $masterDatabaseObject | Add-Member -MemberType NoteProperty -Name 'Name' -Value 'master'
#         $masterDatabaseObject | Add-Member -MemberType ScriptMethod -Name 'ExecuteNonQuery' -Value {
#             param
#             (
#                 [Parameter()]
#                 [System.String]
#                 $sqlCommand
#             )

#             if ( $sqlCommand -ne $mockExpectedQuery )
#             {
#                 throw
#             }
#         }

#         $masterDatabaseObject | Add-Member -MemberType ScriptMethod -Name 'ExecuteWithResults' -Value {
#             param
#             (
#                 [Parameter()]
#                 [System.String]
#                 $sqlCommand
#             )

#             if ( $sqlCommand -ne $mockExpectedQuery )
#             {
#                 throw
#             }

#             return New-Object -TypeName System.Data.DataSet
#         }

#         $databasesObject = New-Object -TypeName PSObject
#         $databasesObject | Add-Member -MemberType NoteProperty -Name 'Databases' -Value @{
#             'master' = $masterDatabaseObject
#         }

#         $mockSMOServer = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
#         $mockSMOServer | Add-Member -MemberType NoteProperty -Name 'Databases' -Value @{
#             'master' = $masterDatabaseObject
#         } -Force

#         $mockConnectSql = {
#             return @($databasesObject)
#         }

#         $queryParameters = @{
#             ServerName         = 'Server1'
#             InstanceName       = 'MSSQLSERVER'
#             Database           = 'master'
#             Query              = ''
#             DatabaseCredential = $mockSqlCredential
#         }

#         $queryParametersWithSMO = @{
#             Query              = ''
#             SqlServerObject    = $mockSMOServer
#             Database           = 'master'
#         }
#     }

#     BeforeEach {
#         Mock -CommandName Connect-SQL -MockWith $mockConnectSql
#     }

#     Context 'When executing a query with no results' {
#         AfterEach {
#             Should -Invoke -CommandName Connect-SQL -Scope It -Times 1 -Exactly
#         }

#         It 'Should execute the query silently' {
#             $queryParameters.Query = "EXEC sp_configure 'show advanced option', '1'"
#             $mockExpectedQuery = $queryParameters.Query.Clone()

#             { Invoke-SqlDscQuery @queryParameters } | Should -Not -Throw

#             Should -Invoke -CommandName Connect-SQL -ParameterFilter {
#                 <#
#                     Should not be called with a login type.

#                     Due to issue https://github.com/pester/Pester/issues/1542
#                     we cannot use `$PSBoundParameters.ContainsKey('LoginType') -eq $false`.
#                 #>
#                 $null -eq $LoginType
#             } -Scope It -Times 1 -Exactly
#         }

#         It 'Should throw the correct error, ExecuteNonQueryFailed, when executing the query fails' {
#             $queryParameters.Query = 'BadQuery'

#             $mockLocalizedString = InModuleScope -ScriptBlock {
#                 $script:localizedData.ExecuteNonQueryFailed
#             }

#             $mockErrorRecord = Get-InvalidOperationRecord -Message (
#                 $mockLocalizedString -f $queryParameters.Database
#             )

#             { Invoke-SqlDscQuery @queryParameters } | Should -Throw -ExpectedMessage ($mockErrorRecord.Exception.Message + '*')
#         }

#         Context 'When text should be redacted' {
#             BeforeAll {
#                 Mock -CommandName Write-Verbose -ParameterFilter {
#                     $mockLocalizedString = InModuleScope -ScriptBlock {
#                         $script:localizedData.ExecuteNonQuery
#                     }

#                     $Message -eq (
#                         $mockLocalizedString -f
#                             "select * from MyTable where password = '*******' and password = '*******'"
#                     )
#                 } -MockWith {
#                     <#
#                         MUST return another message than the parameter filter
#                         is looking for, otherwise we get into a endless loop.
#                         We returning the to show in the output how the verbose
#                         message was redacted.
#                     #>
#                     Write-Verbose -Message ('MOCK OUTPUT: {0}' -f $Message) -Verbose
#                 }
#             }

#             It 'Should execute the query silently and redact text in the verbose output' {
#                 $queryParameters.Query = "select * from MyTable where password = 'Pa\ssw0rd1' and password = 'secret passphrase'"
#                 $mockExpectedQuery = $queryParameters.Query.Clone()

#                 # The `Secret PassPhrase` is using the casing like this to test case-insensitive replace.
#                 { Invoke-SqlDscQuery @queryParameters -RedactText @('Pa\sSw0rd1', 'Secret PassPhrase') } | Should -Not -Throw
#             }
#         }
#     }

#     Context 'When executing a query with no results using Windows impersonation' {
#         It 'Should execute the query silently' {
#             $testParameters = $queryParameters.Clone()
#             $testParameters.LoginType = 'WindowsUser'
#             $testParameters.Query = "EXEC sp_configure 'show advanced option', '1'"
#             $mockExpectedQuery = $testParameters.Query.Clone()

#             { Invoke-SqlDscQuery @testParameters } | Should -Not -Throw

#             Should -Invoke -CommandName Connect-SQL -ParameterFilter {
#                 $LoginType -eq 'WindowsUser'
#             } -Scope It -Times 1 -Exactly
#         }
#     }

#     Context 'when executing a query with no results using SQL impersonation' {
#         It 'Should execute the query silently' {
#             $testParameters = $queryParameters.Clone()
#             $testParameters.LoginType = 'SqlLogin'
#             $testParameters.Query = "EXEC sp_configure 'show advanced option', '1'"
#             $mockExpectedQuery = $testParameters.Query.Clone()

#             { Invoke-SqlDscQuery @testParameters } | Should -Not -Throw

#             Should -Invoke -CommandName Connect-SQL -ParameterFilter {
#                 $LoginType -eq 'SqlLogin'
#             } -Scope It -Times 1 -Exactly
#         }
#     }

#     Context 'when executing a query with results' {
#         It 'Should execute the query and return a result set' {
#             $queryParameters.Query = 'SELECT name FROM sys.databases'
#             $mockExpectedQuery = $queryParameters.Query.Clone()

#             Invoke-SqlDscQuery @queryParameters -WithResults | Should -Not -BeNullOrEmpty

#             Should -Invoke -CommandName Connect-SQL -Scope It -Times 1 -Exactly
#         }

#         It 'Should throw the correct error, ExecuteQueryWithResultsFailed, when executing the query fails' {
#             $queryParameters.Query = 'BadQuery'

#             $mockLocalizedString = InModuleScope -ScriptBlock {
#                 $script:localizedData.ExecuteQueryWithResultsFailed
#             }

#             $mockErrorRecord = Get-InvalidOperationRecord -Message (
#                 $mockLocalizedString -f $queryParameters.Database
#             )

#             { Invoke-SqlDscQuery @queryParameters -WithResults } | Should -Throw -ExpectedMessage ($mockErrorRecord.Exception.Message + '*')

#             Should -Invoke -CommandName Connect-SQL -Scope It -Times 1 -Exactly
#         }

#         Context 'When text should be redacted' {
#             BeforeAll {
#                 Mock -CommandName Write-Verbose -ParameterFilter {
#                     $mockLocalizedString = InModuleScope -ScriptBlock {
#                         $script:localizedData.ExecuteQueryWithResults
#                     }

#                     $Message -eq (
#                         $mockLocalizedString -f
#                             "select * from MyTable where password = '*******' and password = '*******'"
#                     )
#                 } -MockWith {
#                     <#
#                         MUST return another message than the parameter filter
#                         is looking for, otherwise we get into a endless loop.
#                         We returning the to show in the output how the verbose
#                         message was redacted.
#                     #>
#                     Write-Verbose -Message ('MOCK OUTPUT: {0}' -f $Message) -Verbose
#                 }
#             }

#             It 'Should execute the query silently and redact text in the verbose output' {
#                 $queryParameters.Query = "select * from MyTable where password = 'Pa\ssw0rd1' and password = 'secret passphrase'"
#                 $mockExpectedQuery = $queryParameters.Query.Clone()

#                 # The `Secret PassPhrase` is using the casing like this to test case-insensitive replace.
#                 { Invoke-SqlDscQuery @queryParameters -RedactText @('Pa\sSw0rd1', 'Secret PassPhrase') -WithResults } | Should -Not -Throw
#             }
#         }
#     }

#     Context 'When passing in an SMO Server Object' {
#         Context 'Execute a query with no results' {
#             It 'Should execute the query silently' {
#                 $queryParametersWithSMO.Query = "EXEC sp_configure 'show advanced option', '1'"
#                 $mockExpectedQuery = $queryParametersWithSMO.Query.Clone()

#                 { Invoke-SqlDscQuery @queryParametersWithSMO } | Should -Not -Throw

#                 Should -Invoke -CommandName Connect-SQL -Scope It -Times 0 -Exactly
#             }

#             It 'Should throw the correct error, ExecuteNonQueryFailed, when executing the query fails' {
#                 $queryParametersWithSMO.Query = 'BadQuery'

#                 $mockLocalizedString = InModuleScope -ScriptBlock {
#                     $script:localizedData.ExecuteNonQueryFailed
#                 }

#                 $mockErrorRecord = Get-InvalidOperationRecord -Message (
#                     $mockLocalizedString -f $queryParameters.Database
#                 )

#                 { Invoke-SqlDscQuery @queryParametersWithSMO } | Should -Throw -ExpectedMessage ($mockErrorRecord.Exception.Message + '*')

#                 Should -Invoke -CommandName Connect-SQL -Scope It -Times 0 -Exactly
#             }
#         }

#         Context 'When executing a query with results' {
#             It 'Should execute the query and return a result set' {
#                 $queryParametersWithSMO.Query = 'SELECT name FROM sys.databases'
#                 $mockExpectedQuery = $queryParametersWithSMO.Query.Clone()

#                 Invoke-SqlDscQuery @queryParametersWithSMO -WithResults | Should -Not -BeNullOrEmpty

#                 Should -Invoke -CommandName Connect-SQL -Scope It -Times 0 -Exactly
#             }

#             It 'Should throw the correct error, ExecuteQueryWithResultsFailed, when executing the query fails' {
#                 $queryParametersWithSMO.Query = 'BadQuery'

#                 $mockLocalizedString = InModuleScope -ScriptBlock {
#                     $script:localizedData.ExecuteQueryWithResultsFailed
#                 }

#                 $mockErrorRecord = Get-InvalidOperationRecord -Message (
#                     $mockLocalizedString -f $queryParameters.Database
#                 )

#                 { Invoke-SqlDscQuery @queryParametersWithSMO -WithResults } | Should -Throw -ExpectedMessage ($mockErrorRecord.Exception.Message + '*')

#                 Should -Invoke -CommandName Connect-SQL -Scope It -Times 0 -Exactly
#             }
#         }

#         Context 'When executing a query with piped SMO server object' {
#             It 'Should execute the query and return a result set' {
#                 $mockQuery = 'SELECT name FROM sys.databases'
#                 $mockExpectedQuery = $mockQuery

#                 $mockSMOServer | Invoke-SqlDscQuery -Query $mockQuery -Database master -WithResults |
#                     Should -Not -BeNullOrEmpty

#                 Should -Invoke -CommandName Connect-SQL -Scope It -Times 0 -Exactly
#             }

#             It 'Should throw the correct error, ExecuteQueryWithResultsFailed, when executing the query fails' {
#                 $mockQuery = 'BadQuery'

#                 $mockLocalizedString = InModuleScope -ScriptBlock {
#                     $script:localizedData.ExecuteQueryWithResultsFailed
#                 }

#                 $mockErrorRecord = Get-InvalidOperationRecord -Message (
#                     $mockLocalizedString -f $queryParameters.Database
#                 )

#                 { $mockSMOServer | Invoke-SqlDscQuery -Query $mockQuery -Database master -WithResults } | Should -Throw -ExpectedMessage ($mockErrorRecord.Exception.Message + '*')

#                 Should -Invoke -CommandName Connect-SQL -Scope It -Times 0 -Exactly
#             }
#         }
#     }
# }
