[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Justification = 'Because ConvertTo-SecureString is used to simplify the tests.')]
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
    It 'Should have the correct parameters in parameter set <MockParameterSetName>' -ForEach @(
        @{
            MockParameterSetName   = 'ByServerName'
            # cSpell: disable-next
            MockExpectedParameters = '-DatabaseName <string> -Query <string> [-ServerName <string>] [-InstanceName <string>] [-Credential <pscredential>] [-LoginType <string>] [-Encrypt] [-PassThru] [-StatementTimeout <int>] [-RedactText <string[]>] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
        @{
            MockParameterSetName   = 'ByServerObject'
            # cSpell: disable-next
            MockExpectedParameters = '-ServerObject <Server> -DatabaseName <string> -Query <string> [-PassThru] [-StatementTimeout <int>] [-RedactText <string[]>] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
    ) {
        $result = (Get-Command -Name 'Invoke-SqlDscQuery').ParameterSets |
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

    Context 'When executing a query that cannot return any results' {
        BeforeAll {
            $databaseObject = New-Object -TypeName PSCustomObject |
                Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'MockDatabase' -PassThru |
                Add-Member -MemberType 'ScriptMethod' -Name 'ExecuteNonQuery' -Value {
                    param
                    (
                        [Parameter()]
                        [System.String]
                        $sqlCommand
                    )

                    $script:mockMethodExecuteNonQueryCallCount += 1
                } -PassThru -Force

            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' |
                Add-Member -MemberType 'NoteProperty' -Name 'Databases' -Value @{
                    'MockDatabase' = $databaseObject
                } -PassThru -Force

            $mockConnectionContext = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerConnection' |
                Add-Member -MemberType 'NoteProperty' -Name 'StatementTimeout' -Value 100 -PassThru -Force

            $mockServerObject.ConnectionContext = $mockConnectionContext
            $mockServerObject.InstanceName = 'MockInstance'
        }

        BeforeEach {
            $script:mockMethodExecuteNonQueryCallCount = 0
            $script:mockMethodExecuteWithResultsCallCount = 0
        }

        Context 'When calling using an existing server object' {
            Context 'When calling the command with only mandatory parameters' {
                Context 'When using parameter Confirm with value $false' {
                    It 'Should execute the query without throwing and without returning any result' {
                        $result = Invoke-SqlDscQuery -ServerObject $mockServerObject -DatabaseName 'MockDatabase' -Query 'select name from sys.databases' -Confirm:$false

                        $result | Should -BeNullOrEmpty

                        $mockMethodExecuteNonQueryCallCount | Should -Be 1
                    }
                }

                Context 'When using parameter Force' {
                    It 'Should execute the query without throwing and without returning any result' {
                        $result = Invoke-SqlDscQuery -ServerObject $mockServerObject -DatabaseName 'MockDatabase' -Query 'select name from sys.databases' -Force

                        $result | Should -BeNullOrEmpty

                        $mockMethodExecuteNonQueryCallCount | Should -Be 1
                    }
                }

                Context 'When using parameter WhatId' {
                    It 'Should execute the query without throwing and without returning any result' {
                        $result = Invoke-SqlDscQuery -ServerObject $mockServerObject -DatabaseName 'MockDatabase' -Query 'select name from sys.databases' -WhatIf

                        $result | Should -BeNullOrEmpty

                        $mockMethodExecuteNonQueryCallCount | Should -Be 0
                    }
                }

                Context 'When passing parameter ServerObject over the pipeline' {
                    It 'Should execute the query without throwing and without returning any result' {
                        $result = $mockServerObject | Invoke-SqlDscQuery -DatabaseName 'MockDatabase' -Query 'select name from sys.databases' -Force

                        $result | Should -BeNullOrEmpty

                        $mockMethodExecuteNonQueryCallCount | Should -Be 1
                    }
                }
            }

            Context 'When calling the command with optional parameter StatementTimeout' {
                It 'Should execute the query without throwing and without returning any result' {
                    $result = Invoke-SqlDscQuery -StatementTimeout 900 -ServerObject $mockServerObject -DatabaseName 'MockDatabase' -Query 'select name from sys.databases' -Force

                    $result | Should -BeNullOrEmpty

                    $mockMethodExecuteNonQueryCallCount | Should -Be 1
                }
            }

            Context 'When calling the command with optional parameter RedactText' {
                It 'Should execute the query without throwing and without returning any result' {
                    $result = Invoke-SqlDscQuery -RedactText @('MyString') -ServerObject $mockServerObject -DatabaseName 'MockDatabase' -Query 'select name from sys.databases' -Force

                    $result | Should -BeNullOrEmpty

                    $mockMethodExecuteNonQueryCallCount | Should -Be 1
                }
            }
        }

        Context 'When calling by using server name and instance name' {
            BeforeAll {
                $mockSqlCredentialUserName = 'TestUserName12345'
                $mockSqlCredentialPassword = 'StrongOne7.'
                $mockSqlCredentialSecurePassword = ConvertTo-SecureString -String $mockSqlCredentialPassword -AsPlainText -Force
                $mockSqlCredential = [System.Management.Automation.PSCredential]::new($mockSqlCredentialUserName, $mockSqlCredentialSecurePassword)

                Mock -CommandName Disconnect-SqlDscDatabaseEngine
                Mock -CommandName Connect-SqlDscDatabaseEngine -MockWith {
                    return $mockServerObject
                }
            }

            It 'Should execute the query without throwing and without returning any result' {
                $result = Invoke-SqlDscQuery -ServerName 'localhost' -InstanceName 'INSTANCE' -LoginType 'WindowsUser' -Credential $mockSqlCredential -DatabaseName 'MockDatabase' -Query 'select name from sys.databases' -Force

                $result | Should -BeNullOrEmpty

                $mockMethodExecuteNonQueryCallCount | Should -Be 1

                Should -Invoke -CommandName Connect-SqlDscDatabaseEngine -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Disconnect-SqlDscDatabaseEngine -Exactly -Times 1 -Scope It
            }

            Context 'When calling the command with optional parameter Encrypt' {
                It 'Should execute the query without throwing and without returning any result' {
                    $result = Invoke-SqlDscQuery -Encrypt -ServerName 'localhost' -InstanceName 'INSTANCE' -DatabaseName 'MockDatabase' -Query 'select name from sys.databases' -Force

                    $result | Should -BeNullOrEmpty

                    $mockMethodExecuteNonQueryCallCount | Should -Be 1

                    Should -Invoke -CommandName Connect-SqlDscDatabaseEngine -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName Disconnect-SqlDscDatabaseEngine -Exactly -Times 1 -Scope It
                }
            }
        }
    }

    Context 'When executing a query that should return results' {
        BeforeAll {
            $databaseObject = New-Object -TypeName PSCustomObject |
                Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'MockDatabase' -PassThru |
                Add-Member -MemberType ScriptMethod -Name 'ExecuteWithResults' -Value {
                    param
                    (
                        [Parameter()]
                        [System.String]
                        $sqlCommand
                    )

                    $script:mockMethodExecuteWithResultsCallCount += 1

                    return New-Object -TypeName 'System.Data.DataSet'
                } -PassThru -Force

            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' |
                Add-Member -MemberType 'NoteProperty' -Name 'Databases' -Value @{
                    'MockDatabase' = $databaseObject
                } -PassThru -Force

            $mockConnectionContext = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerConnection' |
                Add-Member -MemberType 'NoteProperty' -Name 'StatementTimeout' -Value 100 -PassThru -Force

            $mockServerObject.ConnectionContext = $mockConnectionContext
        }

        BeforeEach {
            $script:mockMethodExecuteWithResultsCallCount = 0
        }

        Context 'When calling using an existing server object' {
            Context 'When calling the command with optional parameter PassThru' {
                Context 'When using parameter Confirm with value $false' {
                    It 'Should execute the query without throwing and return the expected data set' {
                        $result = Invoke-SqlDscQuery -PassThru -ServerObject $mockServerObject -DatabaseName 'MockDatabase' -Query 'select name from sys.databases' -Confirm:$false

                        $result | Should -HaveType [System.Data.DataSet]

                        $mockMethodExecuteWithResultsCallCount | Should -Be 1
                    }
                }

                Context 'When using parameter Force' {
                    It 'Should execute the query without throwing and return the expected data set' {
                        $result = Invoke-SqlDscQuery -PassThru -ServerObject $mockServerObject -DatabaseName 'MockDatabase' -Query 'select name from sys.databases' -Force

                        $result | Should -HaveType [System.Data.DataSet]

                        $mockMethodExecuteWithResultsCallCount | Should -Be 1
                    }
                }

                Context 'When using parameter WhatIf' {
                    It 'Should execute the query without throwing and return the expected data set' {
                        $result = Invoke-SqlDscQuery -PassThru -ServerObject $mockServerObject -DatabaseName 'MockDatabase' -Query 'select name from sys.databases' -WhatIf

                        $result | Should -BeNullOrEmpty

                        $mockMethodExecuteWithResultsCallCount | Should -Be 0
                    }
                }

                Context 'When passing parameter ServerObject over the pipeline' {
                    It 'Should execute the query without throwing and return the expected data set' {
                        $result = $mockServerObject | Invoke-SqlDscQuery -PassThru -DatabaseName 'MockDatabase' -Query 'select name from sys.databases' -Force

                        $result | Should -HaveType [System.Data.DataSet]

                        $mockMethodExecuteWithResultsCallCount | Should -Be 1
                    }
                }
            }
        }
    }

    Context 'When an exception is thrown' {
        BeforeAll {
            $databaseObject = New-Object -TypeName PSCustomObject |
                Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'MockDatabase' -PassThru |
                Add-Member -MemberType ScriptMethod -Name 'ExecuteWithResults' -Value {
                    $script:mockMethodExecuteWithResultsCallCount += 1

                    throw 'Mocked error'
                } -PassThru |
                Add-Member -MemberType 'ScriptMethod' -Name 'ExecuteNonQuery' -Value {
                    $script:mockMethodExecuteNonQueryCallCount += 1
                } -PassThru -Force

            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' |
                Add-Member -MemberType 'NoteProperty' -Name 'Databases' -Value @{
                    'MockDatabase' = $databaseObject
                } -PassThru -Force

            $mockConnectionContext = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerConnection' |
                Add-Member -MemberType 'NoteProperty' -Name 'StatementTimeout' -Value 100 -PassThru -Force

            $mockServerObject.ConnectionContext = $mockConnectionContext
        }

        BeforeEach {
            $script:mockMethodExecuteWithResultsCallCount = 0
            $script:mockMethodExecuteNonQueryCallCount = 0
        }

        Context 'When ErrorAction is set to Stop' {
            BeforeAll {
                $mockInvokeSqlDscQueryParameters = @{
                    PassThru     = $true
                    ServerObject = $mockServerObject
                    DatabaseName = 'MockDatabase'
                    Query        = 'select name from sys.databases'
                    Force        = $true
                    ErrorAction  = 'Stop'
                }
            }

            Context 'When executing a query that should return results' {
                It 'Should throw the correct error' {
                    {
                        Invoke-SqlDscQuery @mockInvokeSqlDscQueryParameters
                    } | Should -Throw -ExpectedMessage '*Mocked error*'

                    $mockMethodExecuteWithResultsCallCount | Should -Be 1
                }
            }

            Context 'When executing a query that cannot return any results' {
                It 'Should throw the correct error' {
                    {
                        Invoke-SqlDscQuery @mockInvokeSqlDscQueryParameters
                    } | Should -Throw -ExpectedMessage '*Mocked error*'

                    $mockMethodExecuteWithResultsCallCount | Should -Be 1
                }
            }
        }

        Context 'When ErrorAction is set to Ignore or SilentlyContinue' {
            BeforeAll {
                $mockInvokeSqlDscQueryParameters = @{
                    PassThru     = $true
                    ServerObject = $mockServerObject
                    DatabaseName = 'MockDatabase'
                    Query        = 'select name from sys.databases'
                    Force        = $true
                    ErrorAction  = 'Ignore'
                }
            }

            Context 'When executing a query that should return results' {
                It 'Should not throw an exception and does not return any result' {
                    $result = Invoke-SqlDscQuery @mockInvokeSqlDscQueryParameters

                    $result | Should -BeNullOrEmpty

                    $mockMethodExecuteWithResultsCallCount | Should -Be 1
                }
            }

            Context 'When executing a query that cannot return any results' {
                It 'Should not throw an exception and does not return any result' {
                    $result = Invoke-SqlDscQuery @mockInvokeSqlDscQueryParameters

                    $result | Should -BeNullOrEmpty

                    $mockMethodExecuteWithResultsCallCount | Should -Be 1
                }
            }
        }
    }
}
