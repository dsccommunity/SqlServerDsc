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

Describe 'Get-SqlDscStartupParameter' -Tag 'Public' {
    It 'Should have the correct parameters in parameter set <MockParameterSetName>' -ForEach @(
        @{
            MockParameterSetName = 'ByServiceObject'
            MockExpectedParameters = '-ServiceObject <Service> [<CommonParameters>]'
        }
        @{
            MockParameterSetName = 'ByServerName'
            MockExpectedParameters = '[-ServerName <string>] [-InstanceName <string>] [<CommonParameters>]'
        }
    ) {
        $result = (Get-Command -Name 'Get-SqlDscStartupParameter').ParameterSets |
            Where-Object -FilterScript {
                $_.Name -eq $mockParameterSetName
            } |
            Select-Object -Property @(
                @{
                    Name = 'ParameterSetName'
                    Expression = { $_.Name }
                },
                @{
                    Name = 'ParameterListAsString'
                    Expression = { $_.ToString() }
                }
            )

        $result.ParameterSetName | Should -Be $MockParameterSetName
        $result.ParameterListAsString | Should -Be $MockExpectedParameters
    }

    Context 'When passing $null as ServiceObject' {
        It 'Should throw the correct error' {
            $mockErrorMessage = 'Cannot bind argument to parameter ''ServiceObject'' because it is null.'

            { Get-SqlDscStartupParameter -ServiceObject $null } | Should -Throw -ExpectedMessage $mockErrorMessage
        }
    }

    Context 'When passing a ServiceObject with wrong service type' {
        BeforeAll {
            $mockServiceObject = [Microsoft.SqlServer.Management.Smo.Wmi.Service]::CreateTypeInstance()
            $mockServiceObject.Type = 'SqlAgent'

            Mock -CommandName Assert-ElevatedUser
        }

        Context 'When passing the value Stop for parameter ErrorAction' {
            It 'Should throw the correct error' {
                $mockErrorMessage = InModuleScope -ScriptBlock {
                    $script:localizedData.TraceFlag_Get_WrongServiceType
                }

                $mockErrorMessage = $mockErrorMessage -f 'SqlServer', 'SqlAgent'

                { Get-SqlDscStartupParameter -ServiceObject $mockServiceObject -ErrorAction 'Stop' } |
                    Should -Throw -ExpectedMessage $mockErrorMessage
            }
        }

        Context 'When passing the value SilentlyContinue for parameter ErrorAction' {
            It 'Should still throw the correct terminating error' {
                $mockErrorMessage = InModuleScope -ScriptBlock {
                    $script:localizedData.TraceFlag_Get_WrongServiceType
                }

                $mockErrorMessage = $mockErrorMessage -f 'SqlServer', 'SqlAgent'

                { Get-SqlDscStartupParameter -ServiceObject $mockServiceObject -ErrorAction 'SilentlyContinue' } |
                    Should -Throw -ExpectedMessage $mockErrorMessage
            }
        }
    }

    Context 'When passing server name but an Managed Computer Service object is not returned' {
        BeforeAll {
            Mock -CommandName Assert-ElevatedUser

            Mock -CommandName Get-SqlDscManagedComputerService -MockWith {
                return $null
            }
        }

        Context 'When passing SilentlyContinue to ErrorAction' {
            It 'Should not throw and return an empty array' {
                $result = Get-SqlDscStartupParameter -ServerName 'localhost' -ErrorAction 'SilentlyContinue'

                $result | Should -BeNullOrEmpty

                Should -Invoke -CommandName Get-SqlDscManagedComputerService -Exactly -Times 1 -Scope It
            }
        }

        Context 'When passing Stop to ErrorAction' {
            It 'Should throw the correct error' {
                $mockErrorMessage = InModuleScope -ScriptBlock {
                    $script:localizedData.TraceFlag_Get_FailedToFindServiceObject
                }

                { Get-SqlDscStartupParameter -ServerName 'localhost' -ErrorAction 'Stop' } | Should -Throw -ExpectedMessage $mockErrorMessage

                Should -Invoke -CommandName Get-SqlDscManagedComputerService -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When only default startup parameters exist' {
        BeforeAll {
            $mockStartupParameters = '-dC:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\DATA\master.mdf;-eC:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\Log\ERRORLOG;-lC:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\DATA\log.ldf'

            $mockServiceObject = [Microsoft.SqlServer.Management.Smo.Wmi.Service]::CreateTypeInstance()
            $mockServiceObject.StartupParameters = $mockStartupParameters
            $mockServiceObject.Type = 'SqlServer'

            Mock -CommandName Assert-ElevatedUser

            Mock -CommandName Get-SqlDscManagedComputerService -MockWith {
                return $mockServiceObject
            }
        }

        Context 'When passing no parameters' {
            It 'Should return an empty array' {
                $result = Get-SqlDscStartupParameter

                Should -ActualValue $result -BeOfType (InModuleScope -ScriptBlock { [StartupParameters] })

                Should -ActualValue $result.TraceFlag -BeOfType 'System.UInt32[]'
                Should -ActualValue $result.DataFilePath -BeOfType 'System.String[]'
                Should -ActualValue $result.LogFilePath -BeOfType 'System.String[]'
                Should -ActualValue $result.ErrorLogPath -BeOfType 'System.String[]'

                $result.DataFilePath | Should -Be 'C:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\DATA\master.mdf'
                $result.LogFilePath | Should -Be 'C:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\DATA\log.ldf'
                $result.ErrorLogPath | Should -Be 'C:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\Log\ERRORLOG'
                $result.TraceFlag | Should -BeNullOrEmpty

                Should -Invoke -CommandName Get-SqlDscManagedComputerService -Exactly -Times 1 -Scope It
            }
        }

        Context 'When passing specific server name' {
            It 'Should return an empty array' {
                $result = Get-SqlDscStartupParameter -ServerName 'localhost'

                Should -ActualValue $result -BeOfType (InModuleScope -ScriptBlock { [StartupParameters] })

                Should -ActualValue $result.TraceFlag -BeOfType 'System.UInt32[]'
                Should -ActualValue $result.DataFilePath -BeOfType 'System.String[]'
                Should -ActualValue $result.LogFilePath -BeOfType 'System.String[]'
                Should -ActualValue $result.ErrorLogPath -BeOfType 'System.String[]'

                $result.DataFilePath | Should -Be 'C:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\DATA\master.mdf'
                $result.LogFilePath | Should -Be 'C:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\DATA\log.ldf'
                $result.ErrorLogPath | Should -Be 'C:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\Log\ERRORLOG'
                $result.TraceFlag | Should -BeNullOrEmpty

                Should -Invoke -CommandName Get-SqlDscManagedComputerService -ParameterFilter {
                    $ServerName -eq 'localhost'
                } -Exactly -Times 1 -Scope It
            }
        }

        Context 'When passing specific instance name' {
            It 'Should return an empty array' {
                $result = Get-SqlDscStartupParameter -InstanceName 'SQL2022'

                Should -ActualValue $result -BeOfType (InModuleScope -ScriptBlock { [StartupParameters] })

                Should -ActualValue $result.TraceFlag -BeOfType 'System.UInt32[]'
                Should -ActualValue $result.DataFilePath -BeOfType 'System.String[]'
                Should -ActualValue $result.LogFilePath -BeOfType 'System.String[]'
                Should -ActualValue $result.ErrorLogPath -BeOfType 'System.String[]'

                $result.DataFilePath | Should -Be 'C:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\DATA\master.mdf'
                $result.LogFilePath | Should -Be 'C:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\DATA\log.ldf'
                $result.ErrorLogPath | Should -Be 'C:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\Log\ERRORLOG'
                $result.TraceFlag | Should -BeNullOrEmpty

                Should -Invoke -CommandName Get-SqlDscManagedComputerService -ParameterFilter {
                    $InstanceName -eq 'SQL2022'
                } -Exactly -Times 1 -Scope It
            }
        }

        Context 'When passing a service object' {
            It 'Should return an empty array' {
                $result = Get-SqlDscStartupParameter -ServiceObject $mockServiceObject

                Should -ActualValue $result -BeOfType (InModuleScope -ScriptBlock { [StartupParameters] })

                Should -ActualValue $result.TraceFlag -BeOfType 'System.UInt32[]'
                Should -ActualValue $result.DataFilePath -BeOfType 'System.String[]'
                Should -ActualValue $result.LogFilePath -BeOfType 'System.String[]'
                Should -ActualValue $result.ErrorLogPath -BeOfType 'System.String[]'

                $result.DataFilePath | Should -Be 'C:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\DATA\master.mdf'
                $result.LogFilePath | Should -Be 'C:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\DATA\log.ldf'
                $result.ErrorLogPath | Should -Be 'C:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\Log\ERRORLOG'
                $result.TraceFlag | Should -BeNullOrEmpty

                Should -Invoke -CommandName Get-SqlDscManagedComputerService -Exactly -Times 0 -Scope It
            }
        }
    }

    Context 'When one trace flag exist' {
        BeforeAll {
            $mockStartupParameters = '-dC:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\DATA\master.mdf;-eC:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\Log\ERRORLOG;-lC:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\DATA\log.ldf;-T4199'

            $mockServiceObject = [Microsoft.SqlServer.Management.Smo.Wmi.Service]::CreateTypeInstance()
            $mockServiceObject.StartupParameters = $mockStartupParameters
            $mockServiceObject.Type = 'SqlServer'

            Mock -CommandName Assert-ElevatedUser
        }

        It 'Should return the correct values' {
            $result = Get-SqlDscStartupParameter -ServiceObject $mockServiceObject

            Should -ActualValue $result -BeOfType (InModuleScope -ScriptBlock { [StartupParameters] })

            Should -ActualValue $result.TraceFlag -BeOfType 'System.UInt32[]'
            Should -ActualValue $result.DataFilePath -BeOfType 'System.String[]'
            Should -ActualValue $result.LogFilePath -BeOfType 'System.String[]'
            Should -ActualValue $result.ErrorLogPath -BeOfType 'System.String[]'

            $result.DataFilePath | Should -Be 'C:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\DATA\master.mdf'
            $result.LogFilePath | Should -Be 'C:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\DATA\log.ldf'
            $result.ErrorLogPath | Should -Be 'C:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\Log\ERRORLOG'
            $result.TraceFlag | Should -HaveCount 1
            $result.TraceFlag | Should -Contain 4199
        }
    }
}
