<#
    .SYNOPSIS
        Automated unit test for DSC_SqlTraceFlag DSC resource.

#>

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

if (-not (Test-BuildCategory -Type 'Unit'))
{
    return
}

$script:dscModuleName = 'SqlServerDsc'
$script:dscResourceName = 'DSC_SqlTraceFlag'

function Invoke-TestSetup
{
    try
    {
        Import-Module -Name DscResource.Test -Force -ErrorAction 'Stop'
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
    }

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Invoke-TestSetup

Write-Host (Get-Module pester).Version

try
{
    InModuleScope $script:dscResourceName {
        $mockServerName = 'TestServer'
        $mockFakeServerName = 'FakeServer'
        $mockInstanceName1 = 'MSSQLSERVER'
        $mockInstanceName1Agent = 'SQLSERVERAGENT'
        $mockInstanceName2 = 'INST00'
        $mockInstanceName2Agent = 'SQLAgent$INST00'
        $mockInstanceName3 = 'INST01'
        $mockInstanceName3Agent = 'SQLAgent$INST01'

        $mockInvalidOperationForAlterMethod = $false
        $mockInvalidOperationForStopMethod = $false
        $mockInvalidOperationForStartMethod = $false

        $mockServerInstances = [System.Collections.ArrayList]::new()
        $mockServerInstances.Add($mockInstanceName1) | Out-Null
        $mockServerInstances.Add($mockInstanceName2) | Out-Null




         #The Trailing spaces in this here string are ment to be there. Do not remove!
        $mockStartupParametersInstance1 = @"
-dC:\Program Files\Microsoft SQL Server\MSSQL15.INST00\MSSQL\DATA\master.mdf;-eC:\Program Files\Microsoft SQL 
Server\MSSQL15.INST00\MSSQL\Log\ERRORLOG;-lC:\Program Files\Microsoft SQL 
Server\MSSQL15.INST00\MSSQL\DATA\mastlog.ldf;-T3226;-T1802
"@
        $mockStartupParametersInstance2 = @"
-dC:\Program Files\Microsoft SQL Server\MSSQL15.INST00\MSSQL\DATA\master.mdf;-eC:\Program Files\Microsoft SQL 
Server\MSSQL15.INST00\MSSQL\Log\ERRORLOG;-lC:\Program Files\Microsoft SQL 
Server\MSSQL15.INST00\MSSQL\DATA\mastlog.ldf
"@

        # Default parameters that are used for the It-blocks
        $mockDefaultParameters1 = @{
            InstanceName = $mockInstanceName1
            ServerName   = $mockServerName
        }

        $mockInst00Parameters = @{
            InstanceName = $mockInstanceName2
            ServerName   = $mockServerName
        }

        $mockInst01Parameters = @{
            InstanceName = $mockInstanceName3
            ServerName   = $mockServerName
        }

        $mockNonExistServerParameters = @{
            InstanceName = $mockInstanceName1
            ServerName   = $mockFakeServerName
        }

        $mockNewObject_ParameterFilter_RealServerName = {
            $ServerName -eq $mockServerName
        }

        $mockNewObject_ParameterFilter_FakeServerName = {
            $ServerName -eq $mockFakeServerName
        }

        $script:mockMethodAlterRan = $false
        $script:mockMethodStopRan = $false
        $script:mockMethodStartRan = $false
        $script:mockMethodAlterValue = ''

        #region Function mocks
        $mockSmoWmiManagedComputer = {
            $mockServerObjectHashtable = @{
                State = "Existing"
                Name = $mockServerName
                ServerInstances = $mockServerInstances
            }

            class service
            {
                [string]$Name
                [string]$ServiceState
                [string]$StartupParameters
            }

            $Services = [System.Collections.ArrayList]::new()

            $service1 = [service]::new()
            $service1.Name = $mockInstanceName1
            $service1.ServiceState = "Running"
            $service1.StartupParameters = $mockStartupParametersInstance1

            $Services.Add($service1) | Out-Null

            $service2 = [service]::new()
            $service2.Name = $mockInstanceName1Agent
            $service2.ServiceState = "Running"
            $service2.StartupParameters = ""

            $Services.Add($service2) | Out-Null

            $service3 = [service]::new()
            $service3.Name = 'MSSQL${0}' -f $mockInstanceName2
            $service3.ServiceState = "Running"
            $service3.StartupParameters = $mockStartupParametersInstance2

            $Services.Add($service3) | Out-Null

            $service4 = [service]::new()
            $service4.Name = 'SQLAgent${0}' -f $mockInstanceName2Agent
            $service4.ServiceState = "Stopped"
            $service4.StartupParameters = ""

            $Services.Add($service4) | Out-Null

            $ServerServices = [System.Collections.ArrayList]::new()

            foreach ($mockService in $Services)
            {
                $mockService | Add-Member -MemberType ScriptMethod -Name Alter -Value {
                    $script:mockMethodAlterRan = $true
                    $script:mockMethodAlterValue = $this.StartupParameters
                } -PassThru |
                Add-Member -MemberType ScriptMethod -Name Stop -Value {
                    $script:mockMethodStopRan = $true
                } -PassThru |
                Add-Member -MemberType ScriptMethod -Name Start -Value {
                    $script:mockMethodStartRan = $true
                }

                $ServerServices.Add( $mockService) | Out-Null
            }

            $mockServerObjectHashtable += @{
                Services = $ServerServices
            }
            $mockServerObject = [PSCustomObject]$mockServerObjectHashtable

            return @($mockServerObject)
        }

        Describe "DSC_SqlTraceFlag\Get-TargetResource" -Tag 'Get'  {
            BeforeAll {
                Mock -CommandName New-Object -MockWith $mockSmoWmiManagedComputer -ParameterFilter $mockNewObject_ParameterFilter_RealServerName -Verifiable
            }

            Context 'For the default instance' {
                BeforeAll {
                    $testParameters = $mockDefaultParameters1

                    $result = Get-TargetResource @testParameters
                }
                It 'Should return a ManagedComputer object with the correct servername' {
                    $result.ServerName | Should -Be $mockServerName
                }
                It 'Should return a ManagedComputer object with the correct InstanceName' {
                    $result.InstanceName | Should -Be $mockInstanceName1
                }
                It 'Should return a ManagedComputer object with the correct TraceFlags' {
                    $result.ActualTraceFlags | Should -Be '3226' ,'1802'
                }
                It 'Should return a ManagedComputer object with the correct number of TraceFlags' {
                    $result.ActualTraceFlags.Count | Should -Be 2
                }
                It 'Should not throw' {
                    {Get-TargetResource @testParameters} | Should -Not -Throw
                }
            }

            Context 'For a named instance' {
                BeforeAll {
                    $testParameters = $mockInst00Parameters

                    $result = Get-TargetResource @testParameters
                }
                It 'Should return a ManagedComputer object with the correct servername' {
                    $result.ServerName | Should -Be $mockServerName
                }
                It 'Should return a ManagedComputer object with the correct InstanceName' {
                    $result.InstanceName | Should -Be $mockInstanceName2
                }
                It 'Should return a ManagedComputer object with the correct TraceFlags' {
                    $result.ActualTraceFlags | Should -BeNullOrEmpty
                }
                It 'Should return a ManagedComputer object with the correct number of TraceFlags' {
                    $result.ActualTraceFlags.Count | Should -Be 0
                }
                It 'Should not throw' {
                    {Get-TargetResource @testParameters} | Should -Not -Throw
                }
            }

            Context 'For a nonexist instance' {
                BeforeAll {
                    $testParameters = $mockInst01Parameters
                }
                It 'Should throw for incorect parameters' {
                    {Get-TargetResource @testParameters} |
                    Should -Throw -ExpectedMessage ("Was unable to connect to WMI information '{0}' in '{1}'." -f $mockInstanceName3, $mockServerName)
                }
            }

            Context 'For a nonexist server' {
                BeforeAll {
                    $testParameters = $mockNonExistServerParameters
                    Mock -CommandName New-Object -MockWith {
                        return $null
                    } -ParameterFilter $mockNewObject_ParameterFilter_FakeServerName -Verifiable
                }
                It 'Should throw for incorect parameters' {
                    {Get-TargetResource @testParameters} |
                    Should -Throw -ExpectedMessage ("Was unable to connect to ComputerManagement '{0}'." -f $mockFakeServerName)
                }
            }
        }

        Describe "DSC_SqlTraceFlag\Test-TargetResource" -Tag 'Test' {
            BeforeAll {
                #Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
                Mock -CommandName New-Object -MockWith $mockSmoWmiManagedComputer -Verifiable
            }

            Context 'When the system is not in the desired state and ensure is set to Absent' {
                BeforeAll {
                    $testParameters = $mockDefaultParameters1
                    $testParameters += @{
                        Ensure = 'Absent'
                    }

                    $result = Test-TargetResource @testParameters
                }

                It 'Should return false when Traceflags on the instance exist' {
                    $result | Should -BeFalse
                }

                It 'Should be executed once' {
                    Assert-MockCalled -CommandName New-Object -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is in the desired state and ensure is set to Absent' {
                BeforeAll {
                    $testParameters = $mockInst00Parameters
                    $testParameters += @{
                        Ensure = 'Absent'
                    }

                    $result = Test-TargetResource @testParameters
                }

                It 'Should return true when no Traceflags on the instance exist' {
                    $result | Should -BeTrue
                }

                It 'Should be executed once' {
                    Assert-MockCalled -CommandName New-Object -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is not in the desired state and ensure is set to Present and `$TraceFlags does not match the actual TraceFlags' {
                BeforeAll {
                    $testParameters = $mockDefaultParameters1
                    $testParameters += @{
                        Ensure = 'Present'
                        TraceFlags = '3228'
                    }

                    $result = Test-TargetResource @testParameters
                }

                It 'Should return false when Traceflags do not match the actual TraceFlags' {
                    $result | Should -BeFalse
                }

                It 'Should be executed once' {
                    Assert-MockCalled -CommandName New-Object -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is not in the desired state and ensure is set to Present and `$TraceFlagsToInclude are not in the actual TraceFlags' {
                BeforeAll {
                    $testParameters = $mockDefaultParameters1
                    $testParameters += @{
                        Ensure              = 'Present'
                        TraceFlagsToInclude = '3228'
                    }

                    $result = Test-TargetResource @testParameters
                }

                It 'Should return false when TraceflagsToInclude are not in the actual TraceFlags' {
                    $result | Should -BeFalse
                }

                It 'Should be executed once' {
                    Assert-MockCalled -CommandName New-Object -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is in the desired state and ensure is set to Present and `$TraceFlagsToInclude are in the actual TraceFlags' {
                BeforeAll {
                    $testParameters = $mockDefaultParameters1
                    $testParameters += @{
                        Ensure              = 'Present'
                        TraceFlagsToInclude = '3226'
                    }

                    $result = Test-TargetResource @testParameters
                }

                It 'Should return false when TraceflagsToInclude are in the actual TraceFlags' {
                    $result | Should -BeTrue
                }

                It 'Should be executed once' {
                    Assert-MockCalled -CommandName New-Object -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is not in the desired state and ensure is set to Present and `$TraceFlagsToExclude are in the actual TraceFlags' {
                BeforeAll {
                    $testParameters = $mockDefaultParameters1
                    $testParameters += @{
                        Ensure              = 'Present'
                        TraceFlagsToExclude = '3226'
                    }

                    $result = Test-TargetResource @testParameters
                }

                It 'Should return false when TraceflagsToExclude are in the actual TraceFlags' {
                    $result | Should -BeFalse
                }

                It 'Should be executed once' {
                    Assert-MockCalled -CommandName New-Object -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is in the desired state and ensure is set to Present and `$TraceFlagsToExclude are not in the actual TraceFlags' {
                BeforeAll {
                    $testParameters = $mockDefaultParameters1
                    $testParameters += @{
                        Ensure              = 'Present'
                        TraceFlagsToExclude = '3228'
                    }

                    $result = Test-TargetResource @testParameters
                }

                It 'Should return true when TraceflagsToExclude are not in the actual TraceFlags' {
                    $result | Should -BeTrue
                }

                It 'Should be executed once' {
                    Assert-MockCalled -CommandName New-Object -Exactly -Times 1 -Scope Context
                }
            }


            Context 'When both the parameters TraceFlags and TraceFlagsToInclude are assigned a value.' {
                BeforeAll {
                    $testParameters = $mockDefaultParameters1
                    $testParameters += @{
                        Ensure              = 'Present'
                        TraceFlags          = '3228'
                        TraceFlagsToInclude = '3228'
                    }
                }

                It 'Should throw the correct error' {
                    { Test-TargetResource @testParameters } | Should -Throw '(DRC0010)'
                }

                It 'Should not be executed' {
                    Assert-MockCalled -CommandName New-Object -Exactly -Times 0 -Scope Context
                }
            }

            Context 'When both the parameters TraceFlags and TraceFlagsToExclude are assigned a value.' {
                BeforeAll {
                    $testParameters = $mockDefaultParameters1
                    $testParameters += @{
                        Ensure              = 'Present'
                        TraceFlags          = '3228'
                        TraceFlagsToExclude = '3228'
                    }
                }

                It 'Should throw the correct error' {
                    { Test-TargetResource @testParameters } | Should -Throw '(DRC0010)'
                }

                It 'Should not be executed' {
                    Assert-MockCalled -CommandName New-Object -Exactly -Times 0 -Scope Context
                }
            }

        }

#DSCResources\DSC_SqlTraceFlag\DSC_SqlTraceFlag.psm1                                     Set-TargetResource                            259 $errorMessage = $script:localizedData...
#DSCResources\DSC_SqlTraceFlag\DSC_SqlTraceFlag.psm1                                     Set-TargetResource                            260 New-InvalidOperationException -Messag...
#DSCResources\DSC_SqlTraceFlag\DSC_SqlTraceFlag.psm1                                     Set-TargetResource                            265 $errorMessage = $script:localizedData...
#DSCResources\DSC_SqlTraceFlag\DSC_SqlTraceFlag.psm1                                     Set-TargetResource                            266 New-InvalidOperationException -Messag...


         Describe "DSC_SqlTraceFlag\Set-TargetResource" -Tag 'Set' {
            BeforeAll {
                #Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
                Mock -CommandName New-Object -MockWith $mockSmoWmiManagedComputer -Verifiable
            }

            Context 'When the system is not in the desired state and ensure is set to Absent' {
                BeforeAll {
                    $testParameters = $mockDefaultParameters1
                    $testParameters += @{
                        Ensure         = 'Absent'
                    }
                }

                It 'Should not throw when calling the alter method' {
                    { Set-TargetResource @testParameters } | Should -Not -Throw
                    $script:mockMethodStopRan | Should -BeFalse
                    $script:mockMethodStartRan | Should -BeFalse
                    $script:mockMethodAlterRan | Should -BeTrue
                    $script:mockMethodAlterValue | Should -Be @"
-dC:\Program Files\Microsoft SQL Server\MSSQL15.INST00\MSSQL\DATA\master.mdf;-eC:\Program Files\Microsoft SQL 
Server\MSSQL15.INST00\MSSQL\Log\ERRORLOG;-lC:\Program Files\Microsoft SQL 
Server\MSSQL15.INST00\MSSQL\DATA\mastlog.ldf
"@

                    Assert-MockCalled -CommandName New-Object -Exactly -Times 1 -Scope It
                }

            }

            Context 'When the system is not in the desired state and ensure is set to Present and `$TraceFlags does not match the actual TraceFlags' {
                BeforeAll {
                    $testParameters = $mockDefaultParameters1
                    $testParameters += @{
                        Ensure = 'Present'
                        TraceFlags = '3228'
                    }
                }

                It 'Should not throw when calling the alter method' {
                    { Set-TargetResource @testParameters } | Should -Not -Throw
                    $script:mockMethodStopRan | Should -BeFalse
                    $script:mockMethodStartRan | Should -BeFalse
                    $script:mockMethodAlterRan | Should -BeTrue
                    $script:mockMethodAlterValue | Should -Be @"
-dC:\Program Files\Microsoft SQL Server\MSSQL15.INST00\MSSQL\DATA\master.mdf;-eC:\Program Files\Microsoft SQL 
Server\MSSQL15.INST00\MSSQL\Log\ERRORLOG;-lC:\Program Files\Microsoft SQL 
Server\MSSQL15.INST00\MSSQL\DATA\mastlog.ldf;-T3228
"@

                    Assert-MockCalled -CommandName New-Object -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the system is not in the desired state and ensure is set to Present and `$TraceFlagsToInclude is not in TraceFlags' {
                BeforeAll {
                    $testParameters = $mockDefaultParameters1
                    $testParameters += @{
                        Ensure = 'Present'
                        TraceFlagsToInclude = '3228'
                    }
                }

                It 'Should not throw when calling the alter method' {
                    { Set-TargetResource @testParameters } | Should -Not -Throw
                    $script:mockMethodStopRan | Should -BeFalse
                    $script:mockMethodStartRan | Should -BeFalse
                    $script:mockMethodAlterRan | Should -BeTrue
                    $script:mockMethodAlterValue | Should -Be @"
-dC:\Program Files\Microsoft SQL Server\MSSQL15.INST00\MSSQL\DATA\master.mdf;-eC:\Program Files\Microsoft SQL 
Server\MSSQL15.INST00\MSSQL\Log\ERRORLOG;-lC:\Program Files\Microsoft SQL 
Server\MSSQL15.INST00\MSSQL\DATA\mastlog.ldf;-T3226;-T1802;-T3228
"@

                    Assert-MockCalled -CommandName New-Object -Exactly -Times 2 -Scope It
                }
            }

            Context 'When the system is not in the desired state and ensure is set to Present and `$TraceFlagsToExclude is in TraceFlags' {
                BeforeAll {
                    $testParameters = $mockDefaultParameters1
                    $testParameters += @{
                        Ensure = 'Present'
                        TraceFlagsToExclude = '1802'
                    }
                }

                It 'Should not throw when calling the alter method' {
                    { Set-TargetResource @testParameters } | Should -Not -Throw
                    $script:mockMethodStopRan | Should -BeFalse
                    $script:mockMethodStartRan | Should -BeFalse
                    $script:mockMethodAlterRan | Should -BeTrue
                    $script:mockMethodAlterValue | Should -Be @"
-dC:\Program Files\Microsoft SQL Server\MSSQL15.INST00\MSSQL\DATA\master.mdf;-eC:\Program Files\Microsoft SQL 
Server\MSSQL15.INST00\MSSQL\Log\ERRORLOG;-lC:\Program Files\Microsoft SQL 
Server\MSSQL15.INST00\MSSQL\DATA\mastlog.ldf;-T3226
"@

                    Assert-MockCalled -CommandName New-Object -Exactly -Times 2 -Scope It
                }
            }

            Context 'When the system is not in the desired state and ensure is set to Present and `$TraceFlags does not match the actual TraceFlags' {
                BeforeAll {
                    $testParameters = $mockDefaultParameters1
                    $testParameters += @{
                        Ensure = 'Present'
                        TraceFlags = '3228'
                        RestartInstance = $true
                    }
                }

                It 'Should not throw when calling the restart method' {
                    { Set-TargetResource @testParameters  } | Should -Not -Throw
                    $script:mockMethodStopRan | Should -BeTrue
                    $script:mockMethodStartRan | Should -BeTrue
                    $script:mockMethodAlterRan | Should -BeTrue
                    $script:mockMethodAlterValue | Should -Be @"
-dC:\Program Files\Microsoft SQL Server\MSSQL15.INST00\MSSQL\DATA\master.mdf;-eC:\Program Files\Microsoft SQL 
Server\MSSQL15.INST00\MSSQL\Log\ERRORLOG;-lC:\Program Files\Microsoft SQL 
Server\MSSQL15.INST00\MSSQL\DATA\mastlog.ldf;-T3228
"@

                    Assert-MockCalled -CommandName New-Object -Exactly -Times 1 -Scope It
                }
            }

            Context 'When both the parameters TraceFlags and TraceFlagsToInclude are assigned a value.' {
                BeforeAll {
                    $testParameters = $mockDefaultParameters1
                    $testParameters += @{
                        Ensure              = 'Present'
                        TraceFlags          = '3228'
                        TraceFlagsToInclude = '3228'
                    }
                }

                It 'Should throw the correct error' {
                    { Set-TargetResource @testParameters} | Should -Throw '(DRC0010)'
                }

                It 'Should not be executed' {
                    Assert-MockCalled -CommandName New-Object -Exactly -Times 0 -Scope Context
                }
            }

            Context 'When both the parameters TraceFlags and TraceFlagsToExclude are assigned a value.' {
                BeforeAll {
                    $testParameters = $mockDefaultParameters1
                    $testParameters += @{
                        Ensure              = 'Present'
                        TraceFlags          = '3228'
                        TraceFlagsToExclude = '3228'
                    }
                }

                It 'Should throw the correct error' {
                    { Set-TargetResource @testParameters } | Should -Throw '(DRC0010)'
                }

                It 'Should not be executed' {
                    Assert-MockCalled -CommandName New-Object -Exactly -Times 0 -Scope Context
                }
            }

            Context 'For a nonexist instance' {
                BeforeAll {
                    $testParameters = $mockInst01Parameters
                }
                It 'Should throw for incorect parameters' {
                    {Set-TargetResource @testParameters} |
                    Should -Throw -ExpectedMessage ("Was unable to connect to WMI information '{0}' in '{1}'." -f $mockInstanceName3, $mockServerName)
                }
            }

            Context 'For a nonexist server' {
                BeforeAll {
                    $testParameters = $mockNonExistServerParameters
                    Mock -CommandName New-Object -MockWith {
                        return $null
                    } -ParameterFilter $mockNewObject_ParameterFilter_FakeServerName -Verifiable
                }
                It 'Should throw for incorect parameters' {
                    {Set-TargetResource @testParameters} |
                    Should -Throw -ExpectedMessage ("Was unable to connect to ComputerManagement '{0}'." -f $mockFakeServerName)
                }
            }
        }

    }
}
finally
{
    Invoke-TestCleanup
}