<#
    .SYNOPSIS
        Unit test for helper functions in module SqlServerDsc.Common.

    .NOTES
        SMO stubs
        ---------
        These are loaded at the start so that it is known that they are left in the
        session after test finishes, and will spill over to other tests. There does
        not exist a way to unload assemblies. It is possible to load these in a
        InModuleScope but the classes are still present in the parent scope when
        Pester has ran.

        SqlServer/SQLPS stubs
        ---------------------
        These are imported using Import-SqlModuleStub in a BeforeAll-block in only
        a test that requires them, and must be removed in an AfterAll-block using
        Remove-SqlModuleStub so the stub cmdlets does not spill over to another
        test.
#>

# Suppressing this rule because ConvertTo-SecureString is used to simplify the tests.
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
# Suppressing this rule because Script Analyzer does not understand Pester's syntax.
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
                & "$PSScriptRoot/../../../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
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
    $script:subModuleName = 'SqlServerDsc.Common'

    $script:parentModule = Get-Module -Name $script:moduleName -ListAvailable | Select-Object -First 1
    $script:subModulesFolder = Join-Path -Path $script:parentModule.ModuleBase -ChildPath 'Modules'

    $script:subModulePath = Join-Path -Path $script:subModulesFolder -ChildPath $script:subModuleName

    Import-Module -Name $script:subModulePath -ErrorAction 'Stop'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\TestHelpers\CommonTestHelper.psm1')

    # Loading SMO stubs.
    if (-not ('Microsoft.SqlServer.Management.Smo.Server' -as [Type]))
    {
        Add-Type -Path (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..\Stubs') -ChildPath 'SMO.cs')
    }

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:subModuleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:subModuleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:subModuleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:subModuleName -All | Remove-Module -Force

    # Remove module common test helper.
    Get-Module -Name 'CommonTestHelper' -All | Remove-Module -Force
}

Describe 'SqlServerDsc.Common\Connect-SQL' -Tag 'ConnectSql' {
    BeforeEach {
        $mockNewObject_MicrosoftDatabaseEngine = {
            <#
                $ArgumentList[0] will contain the ServiceInstance when calling mock New-Object.
                But since the mock New-Object will also be called without arguments, we first
                have to evaluate if $ArgumentList contains values.
            #>
            if ( $ArgumentList.Count -gt 0)
            {
                $serverInstance = $ArgumentList[0]
            }

            return New-Object -TypeName Object |
                Add-Member -MemberType ScriptProperty -Name Status -Value {
                    if ($mockExpectedDatabaseEngineInstance -eq 'MSSQLSERVER')
                    {
                        $mockExpectedServiceInstance = $mockExpectedDatabaseEngineServer
                    }
                    else
                    {
                        $mockExpectedServiceInstance = "$mockExpectedDatabaseEngineServer\$mockExpectedDatabaseEngineInstance"
                    }

                    if ( $this.ConnectionContext.ServerInstance -eq $mockExpectedServiceInstance )
                    {
                        return 'Online'
                    }
                    else
                    {
                        return $null
                    }
                } -PassThru |
                Add-Member -MemberType NoteProperty -Name ConnectionContext -Value (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name ServerInstance -Value $serverInstance -PassThru |
                        Add-Member -MemberType NoteProperty -Name LoginSecure -Value $true -PassThru |
                        Add-Member -MemberType NoteProperty -Name Login -Value '' -PassThru |
                        Add-Member -MemberType NoteProperty -Name SecurePassword -Value $null -PassThru |
                        Add-Member -MemberType NoteProperty -Name ConnectAsUser -Value $false -PassThru |
                        Add-Member -MemberType NoteProperty -Name ConnectAsUserPassword -Value '' -PassThru |
                        Add-Member -MemberType NoteProperty -Name ConnectAsUserName -Value '' -PassThru |
                        Add-Member -MemberType NoteProperty -Name StatementTimeout -Value 600 -PassThru |
                        Add-Member -MemberType NoteProperty -Name ConnectTimeout -Value 600 -PassThru |
                        Add-Member -MemberType NoteProperty -Name EncryptConnection -Value $false -PassThru |
                        Add-Member -MemberType NoteProperty -Name ApplicationName -Value 'SqlServerDsc' -PassThru |
                        Add-Member -MemberType ScriptMethod -Name Disconnect -Value {
                            return $true
                        } -PassThru |
                        Add-Member -MemberType ScriptMethod -Name Connect -Value {
                            if ($mockExpectedDatabaseEngineInstance -eq 'MSSQLSERVER')
                            {
                                $mockExpectedServiceInstance = $mockExpectedDatabaseEngineServer
                            }
                            else
                            {
                                $mockExpectedServiceInstance = "$mockExpectedDatabaseEngineServer\$mockExpectedDatabaseEngineInstance"
                            }

                            if ($this.serverInstance -ne $mockExpectedServiceInstance)
                            {
                                throw ("Mock method Connect() was expecting ServerInstance to be '{0}', but was '{1}'." -f $mockExpectedServiceInstance, $this.serverInstance )
                            }

                            if ($mockThrowInvalidOperation)
                            {
                                throw 'Unable to connect.'
                            }
                        } -PassThru -Force
                    ) -PassThru -Force
        }

        $mockNewObject_MicrosoftDatabaseEngine_ParameterFilter = {
            $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Server'
        }

        $mockSqlCredentialUserName = 'TestUserName12345'
        $mockSqlCredentialPassword = 'StrongOne7.'
        $mockSqlCredentialSecurePassword = ConvertTo-SecureString -String $mockSqlCredentialPassword -AsPlainText -Force
        $mockSqlCredential = New-Object -TypeName PSCredential -ArgumentList ($mockSqlCredentialUserName, $mockSqlCredentialSecurePassword)

        $mockWinCredentialUserName = 'DOMAIN\TestUserName12345'
        $mockWinCredentialPassword = 'StrongerOne7.'
        $mockWinCredentialSecurePassword = ConvertTo-SecureString -String $mockWinCredentialPassword -AsPlainText -Force
        $mockWinCredential = New-Object -TypeName PSCredential -ArgumentList ($mockWinCredentialUserName, $mockWinCredentialSecurePassword)

        $mockWinFqdnCredentialUserName = 'TestUserName12345@domain.local'
        $mockWinFqdnCredentialPassword = 'StrongerOne7.'
        $mockWinFqdnCredentialSecurePassword = ConvertTo-SecureString -String $mockWinFqdnCredentialPassword -AsPlainText -Force
        $mockWinFqdnCredential = New-Object -TypeName PSCredential -ArgumentList ($mockWinFqdnCredentialUserName, $mockWinFqdnCredentialSecurePassword)

        Mock -CommandName Import-SqlDscPreferredModule
    }

    # Skipping on Linux and macOS because they do not support Windows Authentication.
    Context 'When connecting to the default instance using integrated Windows Authentication' -Skip:($IsLinux -or $IsMacOS) {
        BeforeEach {
            $mockExpectedDatabaseEngineServer = 'TestServer'
            $mockExpectedDatabaseEngineInstance = 'MSSQLSERVER'

            Mock -CommandName New-Object `
                -MockWith $mockNewObject_MicrosoftDatabaseEngine `
                -ParameterFilter $mockNewObject_MicrosoftDatabaseEngine_ParameterFilter
        }

        It 'Should return the correct service instance' {
            $databaseEngineServerObject = Connect-SQL -ServerName $mockExpectedDatabaseEngineServer -ErrorAction 'Stop'
            $databaseEngineServerObject.ConnectionContext.ServerInstance | Should -BeExactly $mockExpectedDatabaseEngineServer

            Should -Invoke -CommandName New-Object -Exactly -Times 1 -Scope It `
                -ParameterFilter $mockNewObject_MicrosoftDatabaseEngine_ParameterFilter
        }
    }

    Context 'When connecting to the default instance using SQL Server Authentication' {
        BeforeEach {
            $mockExpectedDatabaseEngineServer = 'TestServer'
            $mockExpectedDatabaseEngineInstance = 'MSSQLSERVER'
            $mockExpectedDatabaseEngineLoginSecure = $false

            Mock -CommandName New-Object `
                -MockWith $mockNewObject_MicrosoftDatabaseEngine `
                -ParameterFilter $mockNewObject_MicrosoftDatabaseEngine_ParameterFilter
        }

        It 'Should return the correct service instance' {
            $databaseEngineServerObject = Connect-SQL -ServerName $mockExpectedDatabaseEngineServer -SetupCredential $mockSqlCredential -LoginType 'SqlLogin' -ErrorAction 'Stop'
            $databaseEngineServerObject.ConnectionContext.LoginSecure | Should -BeFalse
            $databaseEngineServerObject.ConnectionContext.Login | Should -Be $mockSqlCredentialUserName
            $databaseEngineServerObject.ConnectionContext.SecurePassword | Should -Be $mockSqlCredentialSecurePassword
            $databaseEngineServerObject.ConnectionContext.ServerInstance | Should -BeExactly $mockExpectedDatabaseEngineServer

            Should -Invoke -CommandName New-Object -Exactly -Times 1 -Scope It `
                -ParameterFilter $mockNewObject_MicrosoftDatabaseEngine_ParameterFilter
        }
    }

    # Skipping on Linux and macOS because they do not support Windows Authentication.
    Context 'When connecting to the named instance using integrated Windows Authentication' -Skip:($IsLinux -or $IsMacOS) {
        BeforeEach {
            $mockExpectedDatabaseEngineServer = Get-ComputerName
            $mockExpectedDatabaseEngineInstance = 'SqlInstance'

            Mock -CommandName New-Object `
                -MockWith $mockNewObject_MicrosoftDatabaseEngine `
                -ParameterFilter $mockNewObject_MicrosoftDatabaseEngine_ParameterFilter
        }

        It 'Should return the correct service instance' {
            $databaseEngineServerObject = Connect-SQL -InstanceName $mockExpectedDatabaseEngineInstance -ErrorAction 'Stop'
            $databaseEngineServerObject.ConnectionContext.ServerInstance | Should -BeExactly "$mockExpectedDatabaseEngineServer\$mockExpectedDatabaseEngineInstance"

            Should -Invoke -CommandName New-Object -Exactly -Times 1 -Scope It `
                -ParameterFilter $mockNewObject_MicrosoftDatabaseEngine_ParameterFilter
        }
    }

    Context 'When connecting to the named instance using SQL Server Authentication' {
        BeforeEach {
            $mockExpectedDatabaseEngineServer = Get-ComputerName
            $mockExpectedDatabaseEngineInstance = 'SqlInstance'
            $mockExpectedDatabaseEngineLoginSecure = $false

            Mock -CommandName New-Object `
                -MockWith $mockNewObject_MicrosoftDatabaseEngine `
                -ParameterFilter $mockNewObject_MicrosoftDatabaseEngine_ParameterFilter
        }

        It 'Should return the correct service instance' {
            $databaseEngineServerObject = Connect-SQL -InstanceName $mockExpectedDatabaseEngineInstance -SetupCredential $mockSqlCredential -LoginType 'SqlLogin' -ErrorAction 'Stop'
            $databaseEngineServerObject.ConnectionContext.LoginSecure | Should -BeFalse
            $databaseEngineServerObject.ConnectionContext.Login | Should -Be $mockSqlCredentialUserName
            $databaseEngineServerObject.ConnectionContext.SecurePassword | Should -Be $mockSqlCredentialSecurePassword
            $databaseEngineServerObject.ConnectionContext.ServerInstance | Should -BeExactly "$mockExpectedDatabaseEngineServer\$mockExpectedDatabaseEngineInstance"

            Should -Invoke -CommandName New-Object -Exactly -Times 1 -Scope It `
                -ParameterFilter $mockNewObject_MicrosoftDatabaseEngine_ParameterFilter
        }
    }

    # Skipping on Linux and macOS because they do not support Windows Authentication.
    Context 'When connecting to the named instance using integrated Windows Authentication and different server name' -Skip:($IsLinux -or $IsMacOS) {
        BeforeEach {
            $mockExpectedDatabaseEngineServer = 'SERVER'
            $mockExpectedDatabaseEngineInstance = 'SqlInstance'

            Mock -CommandName New-Object `
                -MockWith $mockNewObject_MicrosoftDatabaseEngine `
                -ParameterFilter $mockNewObject_MicrosoftDatabaseEngine_ParameterFilter
        }

        It 'Should return the correct service instance' {
            $databaseEngineServerObject = Connect-SQL -ServerName $mockExpectedDatabaseEngineServer -InstanceName $mockExpectedDatabaseEngineInstance -ErrorAction 'Stop'
            $databaseEngineServerObject.ConnectionContext.ServerInstance | Should -BeExactly "$mockExpectedDatabaseEngineServer\$mockExpectedDatabaseEngineInstance"

            Should -Invoke -CommandName New-Object -Exactly -Times 1 -Scope It `
                -ParameterFilter $mockNewObject_MicrosoftDatabaseEngine_ParameterFilter
        }
    }

    Context 'When connecting to the named instance using Windows Authentication impersonation' {
        BeforeEach {
            $mockExpectedDatabaseEngineServer = Get-ComputerName
            $mockExpectedDatabaseEngineInstance = 'SqlInstance'

            Mock -CommandName New-Object `
                -MockWith $mockNewObject_MicrosoftDatabaseEngine `
                -ParameterFilter $mockNewObject_MicrosoftDatabaseEngine_ParameterFilter
        }

        Context 'When using the default login type' {
            BeforeEach {
                $testParameters = @{
                    ServerName      = $mockExpectedDatabaseEngineServer
                    InstanceName    = $mockExpectedDatabaseEngineInstance
                    SetupCredential = $mockWinCredential
                }
            }

            It 'Should return the correct service instance' {
                $databaseEngineServerObject = Connect-SQL @testParameters -ErrorAction 'Stop'
                $databaseEngineServerObject.ConnectionContext.ServerInstance | Should -BeExactly "$mockExpectedDatabaseEngineServer\$mockExpectedDatabaseEngineInstance"
                $databaseEngineServerObject.ConnectionContext.ConnectAsUser | Should -BeTrue
                $databaseEngineServerObject.ConnectionContext.ConnectAsUserPassword | Should -BeExactly $mockWinCredential.GetNetworkCredential().Password
                $databaseEngineServerObject.ConnectionContext.ConnectAsUserName | Should -BeExactly $mockWinCredential.UserName
                $databaseEngineServerObject.ConnectionContext.ConnectAsUser | Should -BeTrue
                $databaseEngineServerObject.ConnectionContext.LoginSecure | Should -BeTrue

                Should -Invoke -CommandName New-Object -Exactly -Times 1 -Scope It `
                    -ParameterFilter $mockNewObject_MicrosoftDatabaseEngine_ParameterFilter
            }
        }

        Context 'When using the WindowsUser login type' {
            Context 'When authenticating using NetBIOS domain' {
                BeforeEach {
                    $testParameters = @{
                        ServerName      = $mockExpectedDatabaseEngineServer
                        InstanceName    = $mockExpectedDatabaseEngineInstance
                        SetupCredential = $mockWinCredential
                        LoginType       = 'WindowsUser'
                    }
                }

                It 'Should return the correct service instance' {
                    $databaseEngineServerObject = Connect-SQL @testParameters -ErrorAction 'Stop'
                    $databaseEngineServerObject.ConnectionContext.ServerInstance | Should -BeExactly "$mockExpectedDatabaseEngineServer\$mockExpectedDatabaseEngineInstance"
                    $databaseEngineServerObject.ConnectionContext.ConnectAsUser | Should -BeTrue
                    $databaseEngineServerObject.ConnectionContext.ConnectAsUserPassword | Should -BeExactly $mockWinCredential.GetNetworkCredential().Password
                    $databaseEngineServerObject.ConnectionContext.ConnectAsUserName | Should -BeExactly $mockWinCredential.UserName
                    $databaseEngineServerObject.ConnectionContext.ConnectAsUser | Should -BeTrue
                    $databaseEngineServerObject.ConnectionContext.LoginSecure | Should -BeTrue

                    Should -Invoke -CommandName New-Object -Exactly -Times 1 -Scope It `
                        -ParameterFilter $mockNewObject_MicrosoftDatabaseEngine_ParameterFilter
                }
            }

            Context 'When authenticating using Fully Qualified Domain Name (FQDN)' {
                BeforeEach {
                    $testParameters = @{
                        ServerName      = $mockExpectedDatabaseEngineServer
                        InstanceName    = $mockExpectedDatabaseEngineInstance
                        SetupCredential = $mockWinFqdnCredential
                        LoginType       = 'WindowsUser'
                    }
                }

                It 'Should return the correct service instance' {
                    $databaseEngineServerObject = Connect-SQL @testParameters -ErrorAction 'Stop'
                    $databaseEngineServerObject.ConnectionContext.ServerInstance | Should -BeExactly "$mockExpectedDatabaseEngineServer\$mockExpectedDatabaseEngineInstance"
                    $databaseEngineServerObject.ConnectionContext.ConnectAsUser | Should -BeTrue
                    $databaseEngineServerObject.ConnectionContext.ConnectAsUserPassword | Should -BeExactly $mockWinFqdnCredential.GetNetworkCredential().Password
                    $databaseEngineServerObject.ConnectionContext.ConnectAsUserName | Should -BeExactly $mockWinFqdnCredential.UserName
                    $databaseEngineServerObject.ConnectionContext.ConnectAsUser | Should -BeTrue
                    $databaseEngineServerObject.ConnectionContext.LoginSecure | Should -BeTrue

                    Should -Invoke -CommandName New-Object -Exactly -Times 1 -Scope It `
                        -ParameterFilter $mockNewObject_MicrosoftDatabaseEngine_ParameterFilter
                }
            }
        }
    }

    Context 'When using encryption' {
        BeforeEach {
            $mockExpectedDatabaseEngineServer = 'SERVER'
            $mockExpectedDatabaseEngineInstance = 'SqlInstance'

            Mock -CommandName New-Object `
                -MockWith $mockNewObject_MicrosoftDatabaseEngine `
                -ParameterFilter $mockNewObject_MicrosoftDatabaseEngine_ParameterFilter
        }

        # Skipping on Linux and macOS because they do not support Windows Authentication.
        It 'Should return the correct service instance' -Skip:($IsLinux -or $IsMacOS) {
            $databaseEngineServerObject = Connect-SQL -Encrypt -ServerName $mockExpectedDatabaseEngineServer -InstanceName $mockExpectedDatabaseEngineInstance -ErrorAction 'Stop'
            $databaseEngineServerObject.ConnectionContext.ServerInstance | Should -BeExactly "$mockExpectedDatabaseEngineServer\$mockExpectedDatabaseEngineInstance"

            Should -Invoke -CommandName New-Object -Exactly -Times 1 -Scope It `
                -ParameterFilter $mockNewObject_MicrosoftDatabaseEngine_ParameterFilter
        }
    }

    Context 'When connecting using Protocol parameter' {
        BeforeEach {
            $mockExpectedDatabaseEngineServer = 'TestServer'
            $mockExpectedDatabaseEngineInstance = 'MSSQLSERVER'

            # Mock that expects protocol prefix in the ServerInstance
            Mock -CommandName New-Object -ParameterFilter $mockNewObject_MicrosoftDatabaseEngine_ParameterFilter -MockWith {
                return New-Object -TypeName Object |
                    Add-Member -MemberType ScriptProperty -Name Status -Value {
                        return 'Online'
                    } -PassThru |
                    Add-Member -MemberType NoteProperty -Name ConnectionContext -Value (
                        New-Object -TypeName Object |
                            Add-Member -MemberType NoteProperty -Name ServerInstance -Value '' -PassThru |
                            Add-Member -MemberType NoteProperty -Name LoginSecure -Value $true -PassThru |
                            Add-Member -MemberType NoteProperty -Name StatementTimeout -Value 600 -PassThru |
                            Add-Member -MemberType NoteProperty -Name ConnectTimeout -Value 600 -PassThru |
                            Add-Member -MemberType NoteProperty -Name ApplicationName -Value 'SqlServerDsc' -PassThru |
                            Add-Member -MemberType ScriptMethod -Name Disconnect -Value { return $true } -PassThru |
                            Add-Member -MemberType ScriptMethod -Name Connect -Value { } -PassThru -Force
                        ) -PassThru -Force
            }
        }

        # Skipping on Linux and macOS because they do not support Windows Authentication.
        It 'Should format the connection string with tcp protocol prefix for default instance' -Skip:($IsLinux -or $IsMacOS) {
            $databaseEngineServerObject = Connect-SQL -ServerName $mockExpectedDatabaseEngineServer -Protocol 'tcp' -ErrorAction 'Stop'
            $databaseEngineServerObject.ConnectionContext.ServerInstance | Should -BeExactly "tcp:$mockExpectedDatabaseEngineServer"
        }

        # Skipping on Linux and macOS because they do not support Windows Authentication.
        It 'Should format the connection string with tcp protocol prefix for named instance' -Skip:($IsLinux -or $IsMacOS) {
            $databaseEngineServerObject = Connect-SQL -ServerName $mockExpectedDatabaseEngineServer -InstanceName 'MyInstance' -Protocol 'tcp' -ErrorAction 'Stop'
            $databaseEngineServerObject.ConnectionContext.ServerInstance | Should -BeExactly "tcp:$mockExpectedDatabaseEngineServer\MyInstance"
        }
    }

    Context 'When connecting using Port parameter' {
        BeforeEach {
            $mockExpectedDatabaseEngineServer = 'TestServer'
            $mockExpectedDatabaseEngineInstance = 'MSSQLSERVER'

            # Mock that expects port suffix in the ServerInstance
            Mock -CommandName New-Object -ParameterFilter $mockNewObject_MicrosoftDatabaseEngine_ParameterFilter -MockWith {
                return New-Object -TypeName Object |
                    Add-Member -MemberType ScriptProperty -Name Status -Value {
                        return 'Online'
                    } -PassThru |
                    Add-Member -MemberType NoteProperty -Name ConnectionContext -Value (
                        New-Object -TypeName Object |
                            Add-Member -MemberType NoteProperty -Name ServerInstance -Value '' -PassThru |
                            Add-Member -MemberType NoteProperty -Name LoginSecure -Value $true -PassThru |
                            Add-Member -MemberType NoteProperty -Name StatementTimeout -Value 600 -PassThru |
                            Add-Member -MemberType NoteProperty -Name ConnectTimeout -Value 600 -PassThru |
                            Add-Member -MemberType NoteProperty -Name ApplicationName -Value 'SqlServerDsc' -PassThru |
                            Add-Member -MemberType ScriptMethod -Name Disconnect -Value { return $true } -PassThru |
                            Add-Member -MemberType ScriptMethod -Name Connect -Value { } -PassThru -Force
                        ) -PassThru -Force
            }
        }

        # Skipping on Linux and macOS because they do not support Windows Authentication.
        It 'Should format the connection string with port for default instance' -Skip:($IsLinux -or $IsMacOS) {
            $databaseEngineServerObject = Connect-SQL -ServerName $mockExpectedDatabaseEngineServer -Port 1433 -ErrorAction 'Stop'
            $databaseEngineServerObject.ConnectionContext.ServerInstance | Should -BeExactly "$mockExpectedDatabaseEngineServer,1433"
        }

        # Skipping on Linux and macOS because they do not support Windows Authentication.
        It 'Should format the connection string with port for named instance' -Skip:($IsLinux -or $IsMacOS) {
            $databaseEngineServerObject = Connect-SQL -ServerName $mockExpectedDatabaseEngineServer -InstanceName 'MyInstance' -Port 50200 -ErrorAction 'Stop'
            $databaseEngineServerObject.ConnectionContext.ServerInstance | Should -BeExactly "$mockExpectedDatabaseEngineServer\MyInstance,50200"
        }
    }

    Context 'When connecting using both Protocol and Port parameters' {
        BeforeEach {
            $mockExpectedDatabaseEngineServer = '192.168.1.1'
            $mockExpectedDatabaseEngineInstance = 'MSSQLSERVER'

            # Mock that expects protocol prefix and port suffix in the ServerInstance
            Mock -CommandName New-Object -ParameterFilter $mockNewObject_MicrosoftDatabaseEngine_ParameterFilter -MockWith {
                return New-Object -TypeName Object |
                    Add-Member -MemberType ScriptProperty -Name Status -Value {
                        return 'Online'
                    } -PassThru |
                    Add-Member -MemberType NoteProperty -Name ConnectionContext -Value (
                        New-Object -TypeName Object |
                            Add-Member -MemberType NoteProperty -Name ServerInstance -Value '' -PassThru |
                            Add-Member -MemberType NoteProperty -Name LoginSecure -Value $true -PassThru |
                            Add-Member -MemberType NoteProperty -Name StatementTimeout -Value 600 -PassThru |
                            Add-Member -MemberType NoteProperty -Name ConnectTimeout -Value 600 -PassThru |
                            Add-Member -MemberType NoteProperty -Name ApplicationName -Value 'SqlServerDsc' -PassThru |
                            Add-Member -MemberType ScriptMethod -Name Disconnect -Value { return $true } -PassThru |
                            Add-Member -MemberType ScriptMethod -Name Connect -Value { } -PassThru -Force
                        ) -PassThru -Force
            }
        }

        # Skipping on Linux and macOS because they do not support Windows Authentication.
        It 'Should format the connection string with protocol and port for default instance' -Skip:($IsLinux -or $IsMacOS) {
            $databaseEngineServerObject = Connect-SQL -ServerName $mockExpectedDatabaseEngineServer -Protocol 'tcp' -Port 1433 -ErrorAction 'Stop'
            $databaseEngineServerObject.ConnectionContext.ServerInstance | Should -BeExactly "tcp:$mockExpectedDatabaseEngineServer,1433"
        }

        # Skipping on Linux and macOS because they do not support Windows Authentication.
        It 'Should format the connection string with protocol and port for named instance' -Skip:($IsLinux -or $IsMacOS) {
            $databaseEngineServerObject = Connect-SQL -ServerName $mockExpectedDatabaseEngineServer -InstanceName 'MyInstance' -Protocol 'tcp' -Port 50200 -ErrorAction 'Stop'
            $databaseEngineServerObject.ConnectionContext.ServerInstance | Should -BeExactly "tcp:$mockExpectedDatabaseEngineServer\MyInstance,50200"
        }
    }

    Context 'When connecting to the default instance using the correct service instance but does not return a correct Database Engine object' {
        Context 'When using ErrorAction set to Stop' -Skip:($IsLinux -or $IsMacOS) {
            BeforeAll {
                Mock -CommandName New-Object -ParameterFilter {
                    $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Server'
                } -MockWith {
                    return New-Object -TypeName Object |
                        Add-Member -MemberType ScriptProperty -Name Status -Value {
                            return $null
                        } -PassThru |
                        Add-Member -MemberType NoteProperty -Name ConnectionContext -Value (
                            New-Object -TypeName Object |
                                Add-Member -MemberType NoteProperty -Name ServerInstance -Value 'localhost' -PassThru |
                                Add-Member -MemberType NoteProperty -Name LoginSecure -Value $true -PassThru |
                                Add-Member -MemberType NoteProperty -Name Login -Value '' -PassThru |
                                Add-Member -MemberType NoteProperty -Name SecurePassword -Value $null -PassThru |
                                Add-Member -MemberType NoteProperty -Name ConnectAsUser -Value $false -PassThru |
                                Add-Member -MemberType NoteProperty -Name ConnectAsUserPassword -Value '' -PassThru |
                                Add-Member -MemberType NoteProperty -Name ConnectAsUserName -Value '' -PassThru |
                                Add-Member -MemberType NoteProperty -Name StatementTimeout -Value 600 -PassThru |
                                Add-Member -MemberType NoteProperty -Name ConnectTimeout -Value 600 -PassThru |
                                Add-Member -MemberType NoteProperty -Name ApplicationName -Value 'SqlServerDsc' -PassThru |
                                Add-Member -MemberType ScriptMethod -Name Disconnect -Value {
                                    return $true
                                } -PassThru |
                                Add-Member -MemberType ScriptMethod -Name Connect -Value {
                                    return
                                } -PassThru -Force
                            ) -PassThru -Force
                }
            }

            It 'Should throw the correct error' {
                $mockLocalizedString = InModuleScope -ScriptBlock {
                    $script:localizedData.FailedToConnectToDatabaseEngineInstance
                }

                $mockErrorMessage = $mockLocalizedString -f 'localhost'

                { Connect-SQL -ServerName 'localhost' -ErrorAction 'Stop' } |
                    Should -Throw -ExpectedMessage $mockErrorMessage

                Should -Invoke -CommandName New-Object -ParameterFilter {
                    $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Server'
                } -Exactly -Times 1 -Scope It
            }
        }

        Context 'When using ErrorAction set to SilentlyContinue' {
            BeforeAll {
                Mock -CommandName New-Object -ParameterFilter {
                    $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Server'
                } -MockWith {
                    return New-Object -TypeName Object |
                        Add-Member -MemberType ScriptProperty -Name Status -Value {
                            return $null
                        } -PassThru |
                        Add-Member -MemberType NoteProperty -Name ConnectionContext -Value (
                            New-Object -TypeName Object |
                                Add-Member -MemberType NoteProperty -Name ServerInstance -Value 'localhost' -PassThru |
                                Add-Member -MemberType NoteProperty -Name LoginSecure -Value $true -PassThru |
                                Add-Member -MemberType NoteProperty -Name Login -Value '' -PassThru |
                                Add-Member -MemberType NoteProperty -Name SecurePassword -Value $null -PassThru |
                                Add-Member -MemberType NoteProperty -Name ConnectAsUser -Value $false -PassThru |
                                Add-Member -MemberType NoteProperty -Name ConnectAsUserPassword -Value '' -PassThru |
                                Add-Member -MemberType NoteProperty -Name ConnectAsUserName -Value '' -PassThru |
                                Add-Member -MemberType NoteProperty -Name StatementTimeout -Value 600 -PassThru |
                                Add-Member -MemberType NoteProperty -Name ConnectTimeout -Value 600 -PassThru |
                                Add-Member -MemberType NoteProperty -Name ApplicationName -Value 'SqlServerDsc' -PassThru |
                                Add-Member -MemberType ScriptMethod -Name Disconnect -Value {
                                    return $true
                                } -PassThru |
                                Add-Member -MemberType ScriptMethod -Name Connect -Value {
                                    return
                                } -PassThru -Force
                            ) -PassThru -Force
                }
            }

            It 'Should not throw an exception' {
                $null = Connect-SQL -ServerName 'localhost' -SetupCredential $mockSqlCredential -LoginType 'SqlLogin' -ErrorAction 'SilentlyContinue'

                Should -Invoke -CommandName New-Object -ParameterFilter {
                    $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Server'
                } -Exactly -Times 1 -Scope It
            }
        }
    }
}
