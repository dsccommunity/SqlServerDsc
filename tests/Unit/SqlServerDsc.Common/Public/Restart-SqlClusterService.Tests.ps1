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
                & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
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
        Add-Type -Path (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Stubs') -ChildPath 'SMO.cs')
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

# This test is skipped on Linux and macOS due to it is missing CIM Instance.
Describe 'SqlServerDsc.Common\Restart-SqlClusterService' -Tag 'RestartSqlClusterService' -Skip:($IsLinux -or $IsMacOS) {
    Context 'When not clustered instance is found' {
        BeforeAll {
            Mock -CommandName Get-CimInstance
            Mock -CommandName Get-CimAssociatedInstance
            Mock -CommandName Invoke-CimMethod
        }

        It 'Should not restart any cluster resources' {
            InModuleScope -ScriptBlock {
                $null = Restart-SqlClusterService -InstanceName 'MSSQLSERVER' -ErrorAction 'Stop'
            }

            Should -Invoke -CommandName Get-CimInstance -Scope It -Exactly -Times 1
        }
    }

    Context 'When clustered instance is offline' {
        BeforeAll {
            Mock -CommandName Get-CimInstance -MockWith {
                $mock = New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance -ArgumentList 'MSCluster_Resource', 'root/MSCluster'

                $mock | Add-Member -MemberType NoteProperty -Name 'Name' -Value 'SQL Server (MSSQLSERVER)' -TypeName 'String'
                $mock | Add-Member -MemberType NoteProperty -Name 'Type' -Value 'SQL Server' -TypeName 'String'
                $mock | Add-Member -MemberType NoteProperty -Name 'PrivateProperties' -Value @{
                    InstanceName = 'MSSQLSERVER'
                }
                # Mock the resource to be online.
                $mock | Add-Member -MemberType NoteProperty -Name 'State' -Value 3 -TypeName 'Int32'

                return $mock
            }

            Mock -CommandName Get-CimAssociatedInstance
            Mock -CommandName Invoke-CimMethod
        }

        It 'Should not restart any cluster resources' {
            InModuleScope -ScriptBlock {
                $null = Restart-SqlClusterService -InstanceName 'MSSQLSERVER' -ErrorAction 'Stop'
            }

            Should -Invoke -CommandName Get-CimInstance -Scope It -Exactly -Times 1
            Should -Invoke -CommandName Get-CimAssociatedInstance -Scope It -Exactly -Times 0

            Should -Invoke -CommandName Invoke-CimMethod -ParameterFilter {
                $MethodName -eq 'TakeOffline'
            } -Scope It -Exactly -Times 0

            Should -Invoke -CommandName Invoke-CimMethod -ParameterFilter {
                $MethodName -eq 'BringOnline'
            } -Scope It -Exactly -Times 0
        }
    }

    Context 'When restarting a Sql Server clustered instance' {
        Context 'When it is the default instance' {
            BeforeAll {
                Mock -CommandName Get-CimInstance -MockWith {
                    $mock = New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance -ArgumentList 'MSCluster_Resource', 'root/MSCluster'

                    $mock | Add-Member -MemberType NoteProperty -Name 'Name' -Value 'SQL Server (MSSQLSERVER)' -TypeName 'String'
                    $mock | Add-Member -MemberType NoteProperty -Name 'Type' -Value 'SQL Server' -TypeName 'String'
                    $mock | Add-Member -MemberType NoteProperty -Name 'PrivateProperties' -Value @{
                        InstanceName = 'MSSQLSERVER'
                    }
                    # Mock the resource to be online.
                    $mock | Add-Member -MemberType NoteProperty -Name 'State' -Value 2 -TypeName 'Int32'

                    return $mock
                }

                Mock -CommandName Get-CimAssociatedInstance -MockWith {
                    $mock = New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance -ArgumentList 'MSCluster_Resource', 'root/MSCluster'

                    $mock | Add-Member -MemberType NoteProperty -Name 'Name' -Value "SQL Server Agent ($($InputObject.PrivateProperties.InstanceName))" -TypeName 'String'
                    $mock | Add-Member -MemberType NoteProperty -Name 'Type' -Value 'SQL Server Agent' -TypeName 'String'
                    # Mock the resource to be online.
                    $mock | Add-Member -MemberType NoteProperty -Name 'State' -Value 2 -TypeName 'Int32'

                    return $mock
                }

                Mock -CommandName Invoke-CimMethod
            }

            It 'Should restart SQL Server cluster resource and the SQL Agent cluster resource' {
                InModuleScope -ScriptBlock {
                    $null = Restart-SqlClusterService -InstanceName 'MSSQLSERVER' -ErrorAction 'Stop'
                }

                Should -Invoke -CommandName Get-CimInstance -Scope It -Exactly -Times 1
                Should -Invoke -CommandName Get-CimAssociatedInstance -Scope It -Exactly -Times 1

                Should -Invoke -CommandName Invoke-CimMethod -ParameterFilter {
                    $MethodName -eq 'TakeOffline' -and $InputObject.Name -eq 'SQL Server (MSSQLSERVER)'
                } -Scope It -Exactly -Times 1

                Should -Invoke -CommandName Invoke-CimMethod -ParameterFilter {
                    $MethodName -eq 'BringOnline' -and $InputObject.Name -eq 'SQL Server (MSSQLSERVER)'
                } -Scope It -Exactly -Times 1

                Should -Invoke -CommandName Invoke-CimMethod -ParameterFilter {
                    $MethodName -eq 'BringOnline' -and $InputObject.Name -eq 'SQL Server Agent (MSSQLSERVER)'
                } -Scope It -Exactly -Times 1
            }
        }

        Context 'When it is a named instance' {
            BeforeAll {
                Mock -CommandName Get-CimInstance -MockWith {
                    $mock = New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance -ArgumentList 'MSCluster_Resource', 'root/MSCluster'

                    $mock | Add-Member -MemberType NoteProperty -Name 'Name' -Value 'SQL Server (DSCTEST)' -TypeName 'String'
                    $mock | Add-Member -MemberType NoteProperty -Name 'Type' -Value 'SQL Server' -TypeName 'String'
                    $mock | Add-Member -MemberType NoteProperty -Name 'PrivateProperties' -Value @{
                        InstanceName = 'DSCTEST'
                    }
                    # Mock the resource to be online.
                    $mock | Add-Member -MemberType NoteProperty -Name 'State' -Value 2 -TypeName 'Int32'

                    return $mock
                }

                Mock -CommandName Get-CimAssociatedInstance -MockWith {
                    $mock = New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance -ArgumentList 'MSCluster_Resource', 'root/MSCluster'

                    $mock | Add-Member -MemberType NoteProperty -Name 'Name' -Value "SQL Server Agent ($($InputObject.PrivateProperties.InstanceName))" -TypeName 'String'
                    $mock | Add-Member -MemberType NoteProperty -Name 'Type' -Value 'SQL Server Agent' -TypeName 'String'
                    # Mock the resource to be online.
                    $mock | Add-Member -MemberType NoteProperty -Name 'State' -Value 2 -TypeName 'Int32'

                    return $mock
                }

                Mock -CommandName Invoke-CimMethod
            }

            It 'Should restart SQL Server cluster resource and the SQL Agent cluster resource' {
                InModuleScope -ScriptBlock {
                    $null = Restart-SqlClusterService -InstanceName 'DSCTEST' -ErrorAction 'Stop'
                }

                Should -Invoke -CommandName Get-CimInstance -Scope It -Exactly -Times 1
                Should -Invoke -CommandName Get-CimAssociatedInstance -Scope It -Exactly -Times 1

                Should -Invoke -CommandName Invoke-CimMethod -ParameterFilter {
                    $MethodName -eq 'TakeOffline' -and $InputObject.Name -eq 'SQL Server (DSCTEST)'
                } -Scope It -Exactly -Times 1

                Should -Invoke -CommandName Invoke-CimMethod -ParameterFilter {
                    $MethodName -eq 'BringOnline' -and $InputObject.Name -eq 'SQL Server (DSCTEST)'
                } -Scope It -Exactly -Times 1

                Should -Invoke -CommandName Invoke-CimMethod -ParameterFilter {
                    $MethodName -eq 'BringOnline' -and $InputObject.Name -eq 'SQL Server Agent (DSCTEST)'
                } -Scope It -Exactly -Times 1
            }
        }
    }

    Context 'When restarting a Sql Server clustered instance and the SQL Agent is offline' {
        BeforeAll {
            Mock -CommandName Get-CimInstance -MockWith {
                $mock = New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance -ArgumentList 'MSCluster_Resource', 'root/MSCluster'

                $mock | Add-Member -MemberType NoteProperty -Name 'Name' -Value 'SQL Server (MSSQLSERVER)' -TypeName 'String'
                $mock | Add-Member -MemberType NoteProperty -Name 'Type' -Value 'SQL Server' -TypeName 'String'
                $mock | Add-Member -MemberType NoteProperty -Name 'PrivateProperties' -Value @{
                    InstanceName = 'MSSQLSERVER'
                }
                # Mock the resource to be online.
                $mock | Add-Member -MemberType NoteProperty -Name 'State' -Value 2 -TypeName 'Int32'

                return $mock
            }

            Mock -CommandName Get-CimAssociatedInstance -MockWith {
                $mock = New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance -ArgumentList 'MSCluster_Resource', 'root/MSCluster'

                $mock | Add-Member -MemberType NoteProperty -Name 'Name' -Value "SQL Server Agent ($($InputObject.PrivateProperties.InstanceName))" -TypeName 'String'
                $mock | Add-Member -MemberType NoteProperty -Name 'Type' -Value 'SQL Server Agent' -TypeName 'String'
                # Mock the resource to be offline.
                $mock | Add-Member -MemberType NoteProperty -Name 'State' -Value 3 -TypeName 'Int32'

                return $mock
            }

            Mock -CommandName Invoke-CimMethod
        }

        It 'Should restart the SQL Server cluster resource and ignore the SQL Agent cluster resource online ' {
            InModuleScope -ScriptBlock {
                $null = Restart-SqlClusterService -InstanceName 'MSSQLSERVER'
            }

            Should -Invoke -CommandName Get-CimInstance -Scope It -Exactly -Times 1
            Should -Invoke -CommandName Get-CimAssociatedInstance -Scope It -Exactly -Times 1

            Should -Invoke -CommandName Invoke-CimMethod -ParameterFilter {
                $MethodName -eq 'TakeOffline' -and $InputObject.Name -eq 'SQL Server (MSSQLSERVER)'
            } -Scope It -Exactly -Times 1

            Should -Invoke -CommandName Invoke-CimMethod -ParameterFilter {
                $MethodName -eq 'BringOnline' -and $InputObject.Name -eq 'SQL Server (MSSQLSERVER)'
            } -Scope It -Exactly -Times 1
        }
    }

    Context 'When passing the parameter OwnerNode' {
        Context 'When both the SQL Server and SQL Agent cluster resources is owned by the current node' {
            BeforeAll {
                Mock -CommandName Get-CimInstance -MockWith {
                    $mock = New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance -ArgumentList 'MSCluster_Resource', 'root/MSCluster'

                    $mock | Add-Member -MemberType NoteProperty -Name 'Name' -Value 'SQL Server (MSSQLSERVER)' -TypeName 'String'
                    $mock | Add-Member -MemberType NoteProperty -Name 'Type' -Value 'SQL Server' -TypeName 'String'
                    $mock | Add-Member -MemberType NoteProperty -Name 'PrivateProperties' -Value @{
                        InstanceName = 'MSSQLSERVER'
                    }
                    # Mock the resource to be online.
                    $mock | Add-Member -MemberType NoteProperty -Name 'State' -Value 2 -TypeName 'Int32'
                    $mock | Add-Member -MemberType NoteProperty -Name 'OwnerNode' -Value 'NODE1' -TypeName 'String'

                    return $mock
                }

                Mock -CommandName Get-CimAssociatedInstance -MockWith {
                    $mock = New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance -ArgumentList 'MSCluster_Resource', 'root/MSCluster'

                    $mock | Add-Member -MemberType NoteProperty -Name 'Name' -Value "SQL Server Agent ($($InputObject.PrivateProperties.InstanceName))" -TypeName 'String'
                    $mock | Add-Member -MemberType NoteProperty -Name 'Type' -Value 'SQL Server Agent' -TypeName 'String'
                    # Mock the resource to be offline.
                    $mock | Add-Member -MemberType NoteProperty -Name 'State' -Value 2 -TypeName 'Int32'
                    $mock | Add-Member -MemberType NoteProperty -Name 'OwnerNode' -Value 'NODE1' -TypeName 'String'

                    return $mock
                }

                Mock -CommandName Invoke-CimMethod
            }

            It 'Should restart the SQL Server cluster resource and the SQL Agent cluster resource' {
                InModuleScope -ScriptBlock {
                    $null = Restart-SqlClusterService -InstanceName 'MSSQLSERVER' -OwnerNode @('NODE1')
                }

                Should -Invoke -CommandName Get-CimInstance -Scope It -Exactly -Times 1
                Should -Invoke -CommandName Get-CimAssociatedInstance -Scope It -Exactly -Times 1

                Should -Invoke -CommandName Invoke-CimMethod -ParameterFilter {
                    $MethodName -eq 'TakeOffline' -and $InputObject.Name -eq 'SQL Server (MSSQLSERVER)'
                } -Scope It -Exactly -Times 1

                Should -Invoke -CommandName Invoke-CimMethod -ParameterFilter {
                    $MethodName -eq 'BringOnline' -and $InputObject.Name -eq 'SQL Server (MSSQLSERVER)'
                } -Scope It -Exactly -Times 1

                Should -Invoke -CommandName Invoke-CimMethod -ParameterFilter {
                    $MethodName -eq 'BringOnline' -and $InputObject.Name -eq 'SQL Server Agent (MSSQLSERVER)'
                } -Scope It -Exactly -Times 1
            }
        }

        Context 'When both the SQL Server and SQL Agent cluster resources is owned by the current node but the SQL Agent cluster resource is offline' {
            BeforeAll {
                Mock -CommandName Get-CimInstance -MockWith {
                    $mock = New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance -ArgumentList 'MSCluster_Resource', 'root/MSCluster'

                    $mock | Add-Member -MemberType NoteProperty -Name 'Name' -Value 'SQL Server (MSSQLSERVER)' -TypeName 'String'
                    $mock | Add-Member -MemberType NoteProperty -Name 'Type' -Value 'SQL Server' -TypeName 'String'
                    $mock | Add-Member -MemberType NoteProperty -Name 'PrivateProperties' -Value @{
                        InstanceName = 'MSSQLSERVER'
                    }
                    # Mock the resource to be online.
                    $mock | Add-Member -MemberType NoteProperty -Name 'State' -Value 2 -TypeName 'Int32'
                    $mock | Add-Member -MemberType NoteProperty -Name 'OwnerNode' -Value 'NODE1' -TypeName 'String'

                    return $mock
                }

                Mock -CommandName Get-CimAssociatedInstance -MockWith {
                    $mock = New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance -ArgumentList 'MSCluster_Resource', 'root/MSCluster'

                    $mock | Add-Member -MemberType NoteProperty -Name 'Name' -Value "SQL Server Agent ($($InputObject.PrivateProperties.InstanceName))" -TypeName 'String'
                    $mock | Add-Member -MemberType NoteProperty -Name 'Type' -Value 'SQL Server Agent' -TypeName 'String'
                    # Mock the resource to be offline.
                    $mock | Add-Member -MemberType NoteProperty -Name 'State' -Value 3 -TypeName 'Int32'
                    $mock | Add-Member -MemberType NoteProperty -Name 'OwnerNode' -Value 'NODE1' -TypeName 'String'

                    return $mock
                }

                Mock -CommandName Invoke-CimMethod
            }

            It 'Should only restart the SQL Server cluster resource' {
                InModuleScope -ScriptBlock {
                    $null = Restart-SqlClusterService -InstanceName 'MSSQLSERVER' -OwnerNode @('NODE1')
                }

                Should -Invoke -CommandName Get-CimInstance -Scope It -Exactly -Times 1
                Should -Invoke -CommandName Get-CimAssociatedInstance -Scope It -Exactly -Times 1

                Should -Invoke -CommandName Invoke-CimMethod -ParameterFilter {
                    $MethodName -eq 'TakeOffline' -and $InputObject.Name -eq 'SQL Server (MSSQLSERVER)'
                } -Scope It -Exactly -Times 1

                Should -Invoke -CommandName Invoke-CimMethod -ParameterFilter {
                    $MethodName -eq 'BringOnline' -and $InputObject.Name -eq 'SQL Server (MSSQLSERVER)'
                } -Scope It -Exactly -Times 1

                Should -Invoke -CommandName Invoke-CimMethod -ParameterFilter {
                    $MethodName -eq 'BringOnline' -and $InputObject.Name -eq 'SQL Server Agent (MSSQLSERVER)'
                } -Scope It -Exactly -Times 0
            }
        }

        Context 'When only the SQL Server cluster resources is owned by the current node' {
            BeforeAll {
                Mock -CommandName Get-CimInstance -MockWith {
                    $mock = New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance -ArgumentList 'MSCluster_Resource', 'root/MSCluster'

                    $mock | Add-Member -MemberType NoteProperty -Name 'Name' -Value 'SQL Server (MSSQLSERVER)' -TypeName 'String'
                    $mock | Add-Member -MemberType NoteProperty -Name 'Type' -Value 'SQL Server' -TypeName 'String'
                    $mock | Add-Member -MemberType NoteProperty -Name 'PrivateProperties' -Value @{
                        InstanceName = 'MSSQLSERVER'
                    }
                    # Mock the resource to be online.
                    $mock | Add-Member -MemberType NoteProperty -Name 'State' -Value 2 -TypeName 'Int32'
                    $mock | Add-Member -MemberType NoteProperty -Name 'OwnerNode' -Value 'NODE1' -TypeName 'String'

                    return $mock
                }

                Mock -CommandName Get-CimAssociatedInstance -MockWith {
                    $mock = New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance -ArgumentList 'MSCluster_Resource', 'root/MSCluster'

                    $mock | Add-Member -MemberType NoteProperty -Name 'Name' -Value "SQL Server Agent ($($InputObject.PrivateProperties.InstanceName))" -TypeName 'String'
                    $mock | Add-Member -MemberType NoteProperty -Name 'Type' -Value 'SQL Server Agent' -TypeName 'String'
                    # Mock the resource to be offline.
                    $mock | Add-Member -MemberType NoteProperty -Name 'State' -Value 2 -TypeName 'Int32'
                    $mock | Add-Member -MemberType NoteProperty -Name 'OwnerNode' -Value 'NODE2' -TypeName 'String'

                    return $mock
                }

                Mock -CommandName Invoke-CimMethod
            }

            It 'Should only restart the SQL Server cluster resource' {
                InModuleScope -ScriptBlock {
                    $null = Restart-SqlClusterService -InstanceName 'MSSQLSERVER' -OwnerNode @('NODE1')
                }

                Should -Invoke -CommandName Get-CimInstance -Scope It -Exactly -Times 1
                Should -Invoke -CommandName Get-CimAssociatedInstance -Scope It -Exactly -Times 1

                Should -Invoke -CommandName Invoke-CimMethod -ParameterFilter {
                    $MethodName -eq 'TakeOffline' -and $InputObject.Name -eq 'SQL Server (MSSQLSERVER)'
                } -Scope It -Exactly -Times 1

                Should -Invoke -CommandName Invoke-CimMethod -ParameterFilter {
                    $MethodName -eq 'BringOnline' -and $InputObject.Name -eq 'SQL Server (MSSQLSERVER)'
                } -Scope It -Exactly -Times 1

                Should -Invoke -CommandName Invoke-CimMethod -ParameterFilter {
                    $MethodName -eq 'BringOnline' -and $InputObject.Name -eq 'SQL Server Agent (MSSQLSERVER)'
                } -Scope It -Exactly -Times 0
            }
        }

        Context 'When the SQL Server cluster resources is not owned by the current node' {
            BeforeAll {
                Mock -CommandName Get-CimInstance -MockWith {
                    $mock = New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance -ArgumentList 'MSCluster_Resource', 'root/MSCluster'

                    $mock | Add-Member -MemberType NoteProperty -Name 'Name' -Value 'SQL Server (MSSQLSERVER)' -TypeName 'String'
                    $mock | Add-Member -MemberType NoteProperty -Name 'Type' -Value 'SQL Server' -TypeName 'String'
                    $mock | Add-Member -MemberType NoteProperty -Name 'PrivateProperties' -Value @{
                        InstanceName = 'MSSQLSERVER'
                    }
                    # Mock the resource to be online.
                    $mock | Add-Member -MemberType NoteProperty -Name 'State' -Value 2 -TypeName 'Int32'
                    $mock | Add-Member -MemberType NoteProperty -Name 'OwnerNode' -Value 'NODE2' -TypeName 'String'

                    return $mock
                }

                Mock -CommandName Get-CimAssociatedInstance
                Mock -CommandName Invoke-CimMethod
            }

            It 'Should not restart any cluster resources' {
                InModuleScope -ScriptBlock {
                    $null = Restart-SqlClusterService -InstanceName 'MSSQLSERVER' -OwnerNode @('NODE1')
                }

                Should -Invoke -CommandName Get-CimInstance -Scope It -Exactly -Times 1
                Should -Invoke -CommandName Get-CimAssociatedInstance -Scope It -Exactly -Times 0

                Should -Invoke -CommandName Invoke-CimMethod -ParameterFilter {
                    $MethodName -eq 'TakeOffline'
                } -Scope It -Exactly -Times 0

                Should -Invoke -CommandName Invoke-CimMethod -ParameterFilter {
                    $MethodName -eq 'BringOnline'
                } -Scope It -Exactly -Times 0
            }
        }
    }
}
