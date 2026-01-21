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


Describe 'SqlServerDsc.Common\Restart-SqlService' -Tag 'RestartSqlService' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            # Stubs for cross-platform testing.
            function script:Get-Service
            {
                throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
            }

            function script:Restart-Service
            {
                throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
            }

            function script:Start-Service
            {
                throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
            }
        }
    }

    AfterAll {
        InModuleScope -ScriptBlock {
            # Remove stubs that was used for cross-platform testing.
            Remove-Item -Path function:Get-Service
            Remove-Item -Path function:Restart-Service
            Remove-Item -Path function:Start-Service
        }
    }

    Context 'Restart-SqlService standalone instance' {
        Context 'When the Windows services should be restarted' {
            BeforeAll {
                Mock -CommandName Connect-SQL -MockWith {
                    return @{
                        Name        = 'MSSQLSERVER'
                        ServiceName = 'MSSQLSERVER'
                        Status      = 'Online'
                        IsClustered = $false
                    }
                }

                Mock -CommandName Get-Service -MockWith {
                    return @{
                        Name              = 'MSSQLSERVER'
                        DisplayName       = 'Microsoft SQL Server (MSSQLSERVER)'
                        DependentServices = @(
                            @{
                                Name              = 'SQLSERVERAGENT'
                                DisplayName       = 'SQL Server Agent (MSSQLSERVER)'
                                Status            = 'Running'
                                DependentServices = @()
                            }
                        )
                    }
                }

                Mock -CommandName Restart-Service
                Mock -CommandName Start-Service
                Mock -CommandName Restart-SqlClusterService -ModuleName $subModuleName
            }

            It 'Should restart SQL Service and running SQL Agent service' {
                $null = Restart-SqlService -ServerName (Get-ComputerName) -InstanceName 'MSSQLSERVER' -ErrorAction 'Stop'

                Should -Invoke -CommandName Connect-SQL -ParameterFilter {
                    <#
                        Make sure we assert just the first call to Connect-SQL.

                        Due to issue https://github.com/pester/Pester/issues/1542
                        we cannot use `$PSBoundParameters.ContainsKey('ErrorAction') -eq $false`.
                    #>
                    $ErrorAction -ne 'SilentlyContinue'
                } -Scope It -Exactly -Times 1

                Should -Invoke -CommandName Restart-SqlClusterService -Scope It -Exactly -Times 0 -ModuleName $subModuleName
                Should -Invoke -CommandName Get-Service -Scope It -Exactly -Times 1
                Should -Invoke -CommandName Restart-Service -Scope It -Exactly -Times 1
                Should -Invoke -CommandName Start-Service -Scope It -Exactly -Times 1
            }

            Context 'When skipping the cluster check' {
                It 'Should restart SQL Service and running SQL Agent service' {
                    $null = Restart-SqlService -ServerName (Get-ComputerName) -InstanceName 'MSSQLSERVER' -SkipClusterCheck -ErrorAction 'Stop'

                    Should -Invoke -CommandName Connect-SQL -ParameterFilter {
                        <#
                            Make sure we assert just the first call to Connect-SQL.

                            Due to issue https://github.com/pester/Pester/issues/1542
                            we cannot use `$PSBoundParameters.ContainsKey('ErrorAction') -eq $false`.
                        #>
                        $ErrorAction -ne 'SilentlyContinue'
                    } -Scope It -Exactly -Times 0

                    Should -Invoke -CommandName Restart-SqlClusterService -Scope It -Exactly -Times 0 -ModuleName $subModuleName
                    Should -Invoke -CommandName Get-Service -Scope It -Exactly -Times 1
                    Should -Invoke -CommandName Restart-Service -Scope It -Exactly -Times 1
                    Should -Invoke -CommandName Start-Service -Scope It -Exactly -Times 1
                }
            }

            Context 'When skipping the online check' {
                It 'Should restart SQL Service and running SQL Agent service and not wait for the SQL Server instance to come back online' {
                    $null = Restart-SqlService -ServerName (Get-ComputerName) -InstanceName 'MSSQLSERVER' -SkipWaitForOnline -ErrorAction 'Stop'

                    Should -Invoke -CommandName Connect-SQL -ParameterFilter {
                        <#
                            Make sure we assert just the first call to Connect-SQL.

                            Due to issue https://github.com/pester/Pester/issues/1542
                            we cannot use `$PSBoundParameters.ContainsKey('ErrorAction') -eq $false`.
                        #>
                        $ErrorAction -ne 'SilentlyContinue'
                    } -Scope It -Exactly -Times 1

                    Should -Invoke -CommandName Connect-SQL -ParameterFilter {
                        <#
                            Make sure we assert the second call to Connect-SQL

                            Due to issue https://github.com/pester/Pester/issues/1542
                            we cannot use `$PSBoundParameters.ContainsKey('ErrorAction') -eq $true`.
                        #>
                        $ErrorAction -eq 'SilentlyContinue'
                    } -Scope It -Exactly -Times 0

                    Should -Invoke -CommandName Restart-SqlClusterService -Scope It -Exactly -Times 0 -ModuleName $subModuleName
                    Should -Invoke -CommandName Get-Service -Scope It -Exactly -Times 1
                    Should -Invoke -CommandName Restart-Service -Scope It -Exactly -Times 1
                    Should -Invoke -CommandName Start-Service -Scope It -Exactly -Times 1
                }
            }
        }

        Context 'When the SQL Server instance is a Failover Cluster instance' {
            BeforeAll {
                Mock -CommandName Connect-SQL -MockWith {
                    return @{
                        Name        = 'MSSQLSERVER'
                        ServiceName = 'MSSQLSERVER'
                        Status      = 'Online'
                        IsClustered = $true
                    }
                }

                Mock -CommandName Get-Service
                Mock -CommandName Restart-Service
                Mock -CommandName Start-Service
                Mock -CommandName Restart-SqlClusterService -ModuleName $subModuleName
            }

            It 'Should just call Restart-SqlClusterService to restart the SQL Server cluster instance' {
                $null = Restart-SqlService -ServerName (Get-ComputerName) -InstanceName 'MSSQLSERVER' -ErrorAction 'Stop'

                Should -Invoke -CommandName Connect-SQL -ParameterFilter {
                    <#
                        Make sure we assert just the first call to Connect-SQL.

                        Due to issue https://github.com/pester/Pester/issues/1542
                        we cannot use `$PSBoundParameters.ContainsKey('ErrorAction') -eq $false`.
                    #>
                    $ErrorAction -ne 'SilentlyContinue'
                } -Scope It -Exactly -Times 1

                Should -Invoke -CommandName Restart-SqlClusterService -Scope It -Exactly -Times 1 -ModuleName $subModuleName
                Should -Invoke -CommandName Get-Service -Scope It -Exactly -Times 0
                Should -Invoke -CommandName Restart-Service -Scope It -Exactly -Times 0
                Should -Invoke -CommandName Start-Service -Scope It -Exactly -Times 0
            }

            Context 'When passing the Timeout value' {
                It 'Should just call Restart-SqlClusterService with the correct parameter' {
                    $null = Restart-SqlService -ServerName (Get-ComputerName) -InstanceName 'MSSQLSERVER' -Timeout 120 -ErrorAction 'Stop'

                    Should -Invoke -CommandName Restart-SqlClusterService -ParameterFilter {
                        <#
                            Due to issue https://github.com/pester/Pester/issues/1542
                            we cannot use `$PSBoundParameters.ContainsKey('Timeout') -eq $true`.
                        #>
                        $null -ne $Timeout
                    } -Scope It -Exactly -Times 1 -ModuleName $subModuleName
                }
            }

            Context 'When passing the OwnerNode value' {
                It 'Should just call Restart-SqlClusterService with the correct parameter' {
                    $null = Restart-SqlService -ServerName (Get-ComputerName) -InstanceName 'MSSQLSERVER' -OwnerNode @('TestNode') -ErrorAction 'Stop'

                    Should -Invoke -CommandName Restart-SqlClusterService -ParameterFilter {
                        <#
                            Due to issue https://github.com/pester/Pester/issues/1542
                            we cannot use `$PSBoundParameters.ContainsKey('OwnerNode') -eq $true`.
                        #>
                        $null -ne $OwnerNode
                    } -Scope It -Exactly -Times 1 -ModuleName $subModuleName
                }
            }
        }

        Context 'When the Windows services should be restarted but there is not SQL Agent service' {
            BeforeAll {
                Mock -CommandName Connect-SQL -MockWith {
                    return @{
                        Name         = 'NOAGENT'
                        InstanceName = 'NOAGENT'
                        ServiceName  = 'NOAGENT'
                        Status       = 'Online'
                    }
                }

                Mock -CommandName Get-Service -MockWith {
                    return @{
                        Name              = 'MSSQL$NOAGENT'
                        DisplayName       = 'Microsoft SQL Server (NOAGENT)'
                        DependentServices = @()
                    }
                }

                Mock -CommandName Restart-Service
                Mock -CommandName Start-Service
                Mock -CommandName Restart-SqlClusterService -ModuleName $subModuleName
            }

            It 'Should restart SQL Service and not try to restart missing SQL Agent service' {
                $null = Restart-SqlService -ServerName (Get-ComputerName) -InstanceName 'NOAGENT' -SkipClusterCheck -ErrorAction 'Stop'

                Should -Invoke -CommandName Get-Service -Scope It -Exactly -Times 1
                Should -Invoke -CommandName Restart-Service -Scope It -Exactly -Times 1
                Should -Invoke -CommandName Start-Service -Scope It -Exactly -Times 0
            }
        }

        Context 'When the Windows services should be restarted but the SQL Agent service is stopped' {
            BeforeAll {
                Mock -CommandName Connect-SQL -MockWith {
                    return @{
                        Name         = 'STOPPEDAGENT'
                        InstanceName = 'STOPPEDAGENT'
                        ServiceName  = 'STOPPEDAGENT'
                        Status       = 'Online'
                    }
                }

                Mock -CommandName Get-Service -MockWith {
                    return @{
                        Name              = 'MSSQL$STOPPEDAGENT'
                        DisplayName       = 'Microsoft SQL Server (STOPPEDAGENT)'
                        DependentServices = @(
                            @{
                                Name              = 'SQLAGENT$STOPPEDAGENT'
                                DisplayName       = 'SQL Server Agent (STOPPEDAGENT)'
                                Status            = 'Stopped'
                                DependentServices = @()
                            }
                        )
                    }
                }

                Mock -CommandName Restart-Service
                Mock -CommandName Start-Service
                Mock -CommandName Restart-SqlClusterService -ModuleName $subModuleName
            }

            It 'Should restart SQL Service and not try to restart stopped SQL Agent service' {
                $null = Restart-SqlService -ServerName (Get-ComputerName) -InstanceName 'STOPPEDAGENT' -SkipClusterCheck -ErrorAction 'Stop'

                Should -Invoke -CommandName Get-Service -Scope It -Exactly -Times 1
                Should -Invoke -CommandName Restart-Service -Scope It -Exactly -Times 1
                Should -Invoke -CommandName Start-Service -Scope It -Exactly -Times 0
            }
        }

        Context 'When it fails to connect to the instance within the timeout period' {
            Context 'When the connection throws an exception' {
                BeforeAll {
                    Mock -CommandName Connect-SQL -MockWith {
                        # Using SilentlyContinue to not show the errors in the Pester output.
                        Write-Error -Message 'Mock connection error' -ErrorAction 'SilentlyContinue'
                    }

                    Mock -CommandName Get-Service -MockWith {
                        return @{
                            Name              = 'MSSQLSERVER'
                            DisplayName       = 'Microsoft SQL Server (MSSQLSERVER)'
                            DependentServices = @(
                                @{
                                    Name              = 'SQLSERVERAGENT'
                                    DisplayName       = 'SQL Server Agent (MSSQLSERVER)'
                                    Status            = 'Running'
                                    DependentServices = @()
                                }
                            )
                        }
                    }

                    Mock -CommandName Restart-Service
                    Mock -CommandName Start-Service
                }

                It 'Should wait for timeout before throwing error message' {
                    $mockLocalizedString = InModuleScope -ScriptBlock {
                        $localizedData.FailedToConnectToInstanceTimeout
                    }

                    $mockErrorMessage = Get-InvalidOperationRecord -Message (
                        ($mockLocalizedString -f (Get-ComputerName), 'MSSQLSERVER', 4) + '*Mock connection error*'
                    )

                    $mockErrorMessage.Exception.Message | Should -Not -BeNullOrEmpty

                    {
                        Restart-SqlService -ServerName (Get-ComputerName) -InstanceName 'MSSQLSERVER' -Timeout 4 -SkipClusterCheck
                    } | Should -Throw -ExpectedMessage $mockErrorMessage

                    <#
                        Not using -Exactly to handle when CI is slower, result is
                        that there are 3 calls to Connect-SQL.
                    #>
                    Should -Invoke -CommandName Connect-SQL -ParameterFilter {
                        <#
                            Make sure we assert the second call to Connect-SQL

                            Due to issue https://github.com/pester/Pester/issues/1542
                            we cannot use `$PSBoundParameters.ContainsKey('ErrorAction') -eq $true`.
                        #>
                        $ErrorAction -eq 'SilentlyContinue'
                    } -Scope It -Times 2
                }
            }

            Context 'When the Status returns offline' {
                BeforeAll {
                    Mock -CommandName Connect-SQL -MockWith {
                        return @{
                            Name         = 'MSSQLSERVER'
                            InstanceName = ''
                            ServiceName  = 'MSSQLSERVER'
                            Status       = 'Offline'
                        }
                    }

                    Mock -CommandName Get-Service -MockWith {
                        return @{
                            Name              = 'MSSQLSERVER'
                            DisplayName       = 'Microsoft SQL Server (MSSQLSERVER)'
                            DependentServices = @(
                                @{
                                    Name              = 'SQLSERVERAGENT'
                                    DisplayName       = 'SQL Server Agent (MSSQLSERVER)'
                                    Status            = 'Running'
                                    DependentServices = @()
                                }
                            )
                        }
                    }

                    Mock -CommandName Restart-Service
                    Mock -CommandName Start-Service
                }

                It 'Should wait for timeout before throwing error message' {
                    $mockLocalizedString = InModuleScope -ScriptBlock {
                        $localizedData.FailedToConnectToInstanceTimeout
                    }

                    $mockErrorMessage = Get-InvalidOperationRecord -Message (
                        $mockLocalizedString -f (Get-ComputerName), 'MSSQLSERVER', 4
                    )

                    $mockErrorMessage.Exception.Message | Should -Not -BeNullOrEmpty

                    {
                        Restart-SqlService -ServerName (Get-ComputerName) -InstanceName 'MSSQLSERVER' -Timeout 4 -SkipClusterCheck
                    } | Should -Throw -ExpectedMessage $mockErrorMessage

                    <#
                        Not using -Exactly to handle when CI is slower, result is
                        that there are 3 calls to Connect-SQL.
                    #>
                    Should -Invoke -CommandName Connect-SQL -ParameterFilter {
                        <#
                            Make sure we assert the second call to Connect-SQL

                            Due to issue https://github.com/pester/Pester/issues/1542
                            we cannot use `$PSBoundParameters.ContainsKey('ErrorAction') -eq $true`.
                        #>
                        $ErrorAction -eq 'SilentlyContinue'
                    } -Scope It -Times 2
                }
            }
        }
    }
}
