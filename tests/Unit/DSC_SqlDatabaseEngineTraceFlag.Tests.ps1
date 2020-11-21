<#
    .SYNOPSIS
        Automated unit test for DSC_SqlDatabaseEngineTraceFlag DSC resource.

#>

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

if (-not (Test-BuildCategory -Type 'Unit'))
{
    return
}

$script:dscModuleName = 'SqlServerDsc'
$script:dscResourceName = 'DSC_SqlDatabaseEngineTraceFlag'

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
        $mockServerName = 'TestInstance'
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
        $mockDefaultParameters2 = @{
            InstanceName = $mockInstanceName2
            ServerName   = $mockServerName
        }
        $mockDefaultParameters3 = @{
            InstanceName = $mockInstanceName3
            ServerName   = $mockServerName
        }
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
                    if ($mockInvalidOperationForAlterMethod)
                        {
                            throw 'Mock Alter Method was called with invalid operation.'
                        }
                        else
                        {
                            $mockEnumMemberNames
                        }
                } -PassThru |
                Add-Member -MemberType ScriptMethod -Name Stop -Value {
                    if ($mockInvalidOperationForStopMethod)
                    {
                        throw 'Mock Stop Method was called with invalid operation.'
                    }

                    if ( $this.Name -ne $mockExpectedServerRoleToDrop )
                    {
                        throw "Called mocked drop() method without dropping the right server role. Expected '{0}'. But was '{1}'." `
                            -f $mockExpectedServerRoleToDrop, $this.Name
                    }
                } -PassThru |
                Add-Member -MemberType ScriptMethod -Name Start -Value {
                    if ($mockInvalidOperationForStartMethod)
                    {
                        throw 'Mock Start Method was called with invalid operation.'
                    }

                    if ( $this.Name -ne $mockExpectedServerRoleToDrop )
                    {
                        throw "Called mocked drop() method without dropping the right server role. Expected '{0}'. But was '{1}'." `
                            -f $mockExpectedServerRoleToDrop, $this.Name
                    }
                }

                $ServerServices.Add( $mockService) | Out-Null
            }

            $mockServerObjectHashtable += @{
                Services = $ServerServices
            }
            $mockServerObject = [PSCustomObject]$mockServerObjectHashtable

            return @($mockServerObject)
        }

#DSCResources\DSC_SqlDatabaseEngineTraceFlag\DSC_SqlDatabaseEngineTraceFlag.psm1         Set-TargetResource                            155 if ($TraceFlags)...
#DSCResources\DSC_SqlDatabaseEngineTraceFlag\DSC_SqlDatabaseEngineTraceFlag.psm1         Set-TargetResource                            157 $WishTraceFlags = $T...
#DSCResources\DSC_SqlDatabaseEngineTraceFlag\DSC_SqlDatabaseEngineTraceFlag.psm1         Set-TargetResource                            161 $getTargetResourceRe...
#DSCResources\DSC_SqlDatabaseEngineTraceFlag\DSC_SqlDatabaseEngineTraceFlag.psm1         Set-TargetResource                            162 $WishTraceFlags = $g...
#DSCResources\DSC_SqlDatabaseEngineTraceFlag\DSC_SqlDatabaseEngineTraceFlag.psm1         Set-TargetResource                            164 if ($TraceFlagsToInc...
#DSCResources\DSC_SqlDatabaseEngineTraceFlag\DSC_SqlDatabaseEngineTraceFlag.psm1         Set-TargetResource                            166 $TraceFlagsToInclude
#DSCResources\DSC_SqlDatabaseEngineTraceFlag\DSC_SqlDatabaseEngineTraceFlag.psm1         Set-TargetResource                            168 if ($getTargetResour...
#DSCResources\DSC_SqlDatabaseEngineTraceFlag\DSC_SqlDatabaseEngineTraceFlag.psm1         Set-TargetResource                            170 $WishTraceFlags.Add(...
#DSCResources\DSC_SqlDatabaseEngineTraceFlag\DSC_SqlDatabaseEngineTraceFlag.psm1         Set-TargetResource                            175 if ($TraceFlagsToExc...
#DSCResources\DSC_SqlDatabaseEngineTraceFlag\DSC_SqlDatabaseEngineTraceFlag.psm1         Set-TargetResource                            177 $TraceFlagsToExclude
#DSCResources\DSC_SqlDatabaseEngineTraceFlag\DSC_SqlDatabaseEngineTraceFlag.psm1         Set-TargetResource                            179 if ($getTargetResour...
#DSCResources\DSC_SqlDatabaseEngineTraceFlag\DSC_SqlDatabaseEngineTraceFlag.psm1         Set-TargetResource                            181 $WishTraceFlags.Remo...
#DSCResources\DSC_SqlDatabaseEngineTraceFlag\DSC_SqlDatabaseEngineTraceFlag.psm1         Set-TargetResource                            188 $traceFlagList = $wi...
#DSCResources\DSC_SqlDatabaseEngineTraceFlag\DSC_SqlDatabaseEngineTraceFlag.psm1         Set-TargetResource                            188 $traceFlagList = $wi...
#DSCResources\DSC_SqlDatabaseEngineTraceFlag\DSC_SqlDatabaseEngineTraceFlag.psm1         Set-TargetResource                            189 "-T$PSItem"
#DSCResources\DSC_SqlDatabaseEngineTraceFlag\DSC_SqlDatabaseEngineTraceFlag.psm1         Set-TargetResource                            222 if ($Flag -notin $pa...
#DSCResources\DSC_SqlDatabaseEngineTraceFlag\DSC_SqlDatabaseEngineTraceFlag.psm1         Set-TargetResource                            223 $parameterList.Add($...
#DSCResources\DSC_SqlDatabaseEngineTraceFlag\DSC_SqlDatabaseEngineTraceFlag.psm1         Set-TargetResource                            223 Out-Null
#DSCResources\DSC_SqlDatabaseEngineTraceFlag\DSC_SqlDatabaseEngineTraceFlag.psm1         Set-TargetResource                            233 $AgentServiceStatus ...
#DSCResources\DSC_SqlDatabaseEngineTraceFlag\DSC_SqlDatabaseEngineTraceFlag.psm1         Set-TargetResource                            233 $sqlManagement.Services
#DSCResources\DSC_SqlDatabaseEngineTraceFlag\DSC_SqlDatabaseEngineTraceFlag.psm1         Set-TargetResource                            233 Where-Object -Filter...
#DSCResources\DSC_SqlDatabaseEngineTraceFlag\DSC_SqlDatabaseEngineTraceFlag.psm1         Set-TargetResource                            233 $PSItem.Name -eq $Se...
#DSCResources\DSC_SqlDatabaseEngineTraceFlag\DSC_SqlDatabaseEngineTraceFlag.psm1         Set-TargetResource                            235 $wmiService.Stop()
#DSCResources\DSC_SqlDatabaseEngineTraceFlag\DSC_SqlDatabaseEngineTraceFlag.psm1         Set-TargetResource                            236 Start-Sleep -Seconds 10
#DSCResources\DSC_SqlDatabaseEngineTraceFlag\DSC_SqlDatabaseEngineTraceFlag.psm1         Set-TargetResource                            237 $wmiService.Start()
#DSCResources\DSC_SqlDatabaseEngineTraceFlag\DSC_SqlDatabaseEngineTraceFlag.psm1         Set-TargetResource                            239 if($AgentServiceStat...
#DSCResources\DSC_SqlDatabaseEngineTraceFlag\DSC_SqlDatabaseEngineTraceFlag.psm1         Set-TargetResource                            241 ($sqlManagement.Serv...
#DSCResources\DSC_SqlDatabaseEngineTraceFlag\DSC_SqlDatabaseEngineTraceFlag.psm1         Set-TargetResource                            241 $sqlManagement.Services
#DSCResources\DSC_SqlDatabaseEngineTraceFlag\DSC_SqlDatabaseEngineTraceFlag.psm1         Set-TargetResource                            241 Where-Object -Filter...
#DSCResources\DSC_SqlDatabaseEngineTraceFlag\DSC_SqlDatabaseEngineTraceFlag.psm1         Set-TargetResource                            241 $PSItem.Name -eq $Se...
#DSCResources\DSC_SqlDatabaseEngineTraceFlag\DSC_SqlDatabaseEngineTraceFlag.psm1         Set-TargetResource                            247 $errorMessage = $scr...
#DSCResources\DSC_SqlDatabaseEngineTraceFlag\DSC_SqlDatabaseEngineTraceFlag.psm1         Set-TargetResource                            248 New-InvalidOperation...
#DSCResources\DSC_SqlDatabaseEngineTraceFlag\DSC_SqlDatabaseEngineTraceFlag.psm1         Set-TargetResource                            253 $errorMessage = $scr...
#DSCResources\DSC_SqlDatabaseEngineTraceFlag\DSC_SqlDatabaseEngineTraceFlag.psm1         Set-TargetResource                            254 New-InvalidOperation...
#DSCResources\DSC_SqlDatabaseEngineTraceFlag\DSC_SqlDatabaseEngineTraceFlag.psm1         Test-TargetResource                           363 if ($TraceFlagsToInc...
#DSCResources\DSC_SqlDatabaseEngineTraceFlag\DSC_SqlDatabaseEngineTraceFlag.psm1         Test-TargetResource                           365 $TraceFlagsToInclude
#DSCResources\DSC_SqlDatabaseEngineTraceFlag\DSC_SqlDatabaseEngineTraceFlag.psm1         Test-TargetResource                           367 if ($getTargetResour...
#DSCResources\DSC_SqlDatabaseEngineTraceFlag\DSC_SqlDatabaseEngineTraceFlag.psm1         Test-TargetResource                           369 Write-Verbose -Messa...
#DSCResources\DSC_SqlDatabaseEngineTraceFlag\DSC_SqlDatabaseEngineTraceFlag.psm1         Test-TargetResource                           370 $script:localizedDat...
#DSCResources\DSC_SqlDatabaseEngineTraceFlag\DSC_SqlDatabaseEngineTraceFlag.psm1         Test-TargetResource                           374 $isInDesiredState = ...
#DSCResources\DSC_SqlDatabaseEngineTraceFlag\DSC_SqlDatabaseEngineTraceFlag.psm1         Test-TargetResource                           379 if ($TraceFlagsToExc...
#DSCResources\DSC_SqlDatabaseEngineTraceFlag\DSC_SqlDatabaseEngineTraceFlag.psm1         Test-TargetResource                           381 $TraceFlagsToExclude
#DSCResources\DSC_SqlDatabaseEngineTraceFlag\DSC_SqlDatabaseEngineTraceFlag.psm1         Test-TargetResource                           383 if ($getTargetResour...
#DSCResources\DSC_SqlDatabaseEngineTraceFlag\DSC_SqlDatabaseEngineTraceFlag.psm1         Test-TargetResource                           385 Write-Verbose -Messa...
#DSCResources\DSC_SqlDatabaseEngineTraceFlag\DSC_SqlDatabaseEngineTraceFlag.psm1         Test-TargetResource                           386 $script:localizedDat...
#DSCResources\DSC_SqlDatabaseEngineTraceFlag\DSC_SqlDatabaseEngineTraceFlag.psm1         Test-TargetResource                           390 $isInDesiredState = ...
        #endregion

        Describe "DSC_SqlDatabaseEngineTraceFlag\Get-TargetResource" -Tag 'Get'  {
            BeforeAll {
                Mock -CommandName New-Object -MockWith $mockSmoWmiManagedComputer -Verifiable
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
                    $testParameters = $mockDefaultParameters2

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
                    $testParameters = $mockDefaultParameters3
                }
                It 'Should throw for incorect parameters' {
                    {Get-TargetResource @testParameters} |
                    Should -Throw -ExpectedMessage ("Was unable to connect to WMI information '{0}' in '{1}'." -f $mockInstanceName3, $mockServerName)
                }
            }
        }

        Describe "DSC_SqlDatabaseEngineTraceFlag\Test-TargetResource" -Tag 'Test' {
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

                    $result = Test-TargetResource @testParameters -verbose
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
                    $testParameters = $mockDefaultParameters2
                    $testParameters += @{
                        Ensure = 'Absent'
                    }

                    $result = Test-TargetResource @testParameters -verbose
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

                    $result = Test-TargetResource @testParameters -verbose
                }

                It 'Should return false when Traceflags on the instance do not match the actual TraceFlags' {
                    $result | Should -BeFalse
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




         Describe "DSC_SqlDatabaseEngineTraceFlag\Set-TargetResource" -Tag 'Set' {
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

                It 'Should not throw when calling the drop method' {
                    { Set-TargetResource @testParameters } | Should -Not -Throw
                }

                #It 'Should be executed once' {
                #    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
                #}
            }
        }

#                BeforeAll {
#                    $testParameters = $mockDefaultParameters
#                    $testParameters += @{
#                        ServerRoleName = 'UnknownRoleName'
#                    }
#
#                    $result = Get-TargetResource @testParameters
#                }
#
#                It 'Should return the state as absent when the role does not exist' {
#                    $result.Ensure | Should -Be 'Absent'
#                }
#
#                It 'Should return the members as null' {
#                    $result.membersInRole | Should -BeNullOrEmpty
#                }
#
#                It 'Should return the same values as passed as parameters' {
#                    $result.ServerName | Should -Be $testParameters.ServerName
#                    $result.InstanceName | Should -Be $testParameters.InstanceName
#                    $result.ServerRoleName | Should -Be $testParameters.ServerRoleName
#                }
#
#                It 'Should be executed once' {
#                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
#                }
#            }
#
#            Context 'When the system is not in the desired state and ensure is set to Absent' {
#                BeforeAll {
#                    $testParameters = $mockDefaultParameters
#                    $testParameters += @{
#                        ServerRoleName = $mockSqlServerRole
#                    }
#
#                    $result = Get-TargetResource @testParameters
#                }
#
#                It 'Should not return the state as absent when the role exist' {
#                    $result.Ensure | Should -Not -Be 'Absent'
#                }
#
#                It 'Should return the members as not null' {
#                    $result.Members | Should -Not -BeNullOrEmpty
#                }
#
#                # Regression test for issue #790
#                It 'Should return the members as string array' {
#                    ($result.Members -is [System.String[]]) | Should -BeTrue
#                }
#
#                It 'Should return the same values as passed as parameters' {
#                    $result.ServerName | Should -Be $testParameters.ServerName
#                    $result.InstanceName | Should -Be $testParameters.InstanceName
#                    $result.ServerRoleName | Should -Be $testParameters.ServerRoleName
#                }
#
#                It 'Should be executed once' {
#                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
#                }
#            }
#
#            Context 'When passing values to parameters and throwing with EnumMemberNames method' {
#                BeforeAll {
#                    $mockInvalidOperationForEnumMethod = $true
#                    $testParameters = $mockDefaultParameters
#                    $testParameters += @{
#                        ServerRoleName = $mockSqlServerRole
#                    }
#
#                    $errorMessage = $script:localizedData.EnumMemberNamesServerRoleGetError `
#                        -f $mockServerName, $mockInstanceName, $mockSqlServerRole
#                }
#
#                It 'Should throw the correct error' {
#                    { Get-TargetResource @testParameters } | Should -Throw $errorMessage
#                }
#
#                It 'Should call the mock function Connect-SQL' {
#                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
#                }
#            }
#
#            Assert-VerifiableMock
#        }
#
#        Describe "DSC_SqlRole\Test-TargetResource" -Tag 'Test' {
#            BeforeAll {
#                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
#            }
#
#            Context 'When the system is not in the desired state and ensure is set to Absent' {
#                BeforeAll {
#                    $testParameters = $mockDefaultParameters
#                    $testParameters += @{
#                        Ensure         = 'Absent'
#                        ServerRoleName = $mockSqlServerRole
#                    }
#
#                    $result = Test-TargetResource @testParameters
#                }
#
#                It 'Should return false when desired server role exist' {
#                    $result | Should -BeFalse
#                }
#
#                It 'Should be executed once' {
#                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
#                }
#            }
#
#            Context 'When the system is in the desired state and ensure is set to Absent' {
#                BeforeAll {
#                    $testParameters = $mockDefaultParameters
#                    $testParameters += @{
#                        Ensure         = 'Absent'
#                        ServerRoleName = 'newServerRole'
#                    }
#
#                    $result = Test-TargetResource @testParameters
#                }
#
#                It 'Should return true when desired server role does not exist' {
#                    $result | Should -BeTrue
#                }
#
#                It 'Should be executed once' {
#                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
#                }
#            }
#
#            Context 'When the system is in the desired state and ensure is set to Present' {
#                BeforeAll {
#                    $testParameters = $mockDefaultParameters
#                    $testParameters += @{
#                        Ensure         = 'Present'
#                        ServerRoleName = $mockSqlServerRole
#                    }
#
#                    $result = Test-TargetResource @testParameters
#                }
#
#                It 'Should return true when desired server role exist' {
#                    $result | Should -BeTrue
#                }
#
#                It 'Should be executed once' {
#                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
#                }
#            }
#
#            Context 'When the system is not in the desired state and ensure is set to Present' {
#                BeforeAll {
#                    $testParameters = $mockDefaultParameters
#                    $testParameters += @{
#                        Ensure         = 'Present'
#                        ServerRoleName = 'newServerRole'
#                    }
#
#                    $result = Test-TargetResource @testParameters
#                }
#
#                It 'Should return false when desired server role does not exist' {
#                    $result | Should -BeFalse
#                }
#
#                It 'Should be executed once' {
#                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
#                }
#            }
#
#            Context 'When the system is not in the desired state and ensure is set to Present' {
#                BeforeAll {
#                    $testParameters = $mockDefaultParameters
#                    $testParameters += @{
#                        Ensure         = 'Present'
#                        ServerRoleName = $mockSqlServerRole
#                        Members        = @($mockSqlServerLoginThree, $mockSqlServerLoginFour)
#                    }
#
#                    $result = Test-TargetResource @testParameters
#                }
#
#                It 'Should return false when desired members are not in desired server role' {
#                    $result | Should -BeFalse
#                }
#
#                It 'Should be executed once' {
#                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
#                }
#            }
#
#            Context 'When both the parameters Members and MembersToInclude are assigned a value and ensure is set to Present' {
#                BeforeAll {
#                    $testParameters = $mockDefaultParameters
#                    $testParameters += @{
#                        Ensure           = 'Present'
#                        ServerRoleName   = $mockSqlServerRole
#                        Members          = $mockEnumMemberNames
#                        MembersToInclude = $mockSqlServerLoginThree
#                    }
#
#                    $errorMessage = $script:localizedData.MembersToIncludeAndExcludeParamMustBeNull
#                }
#
#                It 'Should throw the correct error' {
#                    { Test-TargetResource @testParameters } | Should -Throw '(DRC0010)'
#                }
#
#                It 'Should not be executed' {
#                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 0 -Scope Context
#                }
#            }
#
#            Context 'When parameter MembersToInclude is assigned a value, parameter Members is not assigned a value, and ensure is set to Present' {
#                BeforeAll {
#                    $testParameters = $mockDefaultParameters
#                    $testParameters += @{
#                        Ensure           = 'Present'
#                        ServerRoleName   = $mockSqlServerRole
#                        MembersToInclude = $mockSqlServerLoginTwo
#                    }
#
#                    $result = Test-TargetResource @testParameters
#                }
#
#                It 'Should return true when desired server role exist' {
#                    $result | Should -BeTrue
#                }
#
#                It 'Should be executed once' {
#                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
#                }
#            }
#
#            Context 'When parameter MembersToInclude is assigned a value, parameter Members is not assigned a value, and ensure is set to Present' {
#                BeforeAll {
#                    $testParameters = $mockDefaultParameters
#                    $testParameters += @{
#                        Ensure           = 'Present'
#                        ServerRoleName   = 'RoleNotExist' # $mockSqlServerRole
#                        MembersToInclude = $mockSqlServerLoginThree
#                    }
#
#                    $result = Test-TargetResource @testParameters
#                }
#
#                It 'Should return false when desired server role does not exist' {
#                    $result | Should -BeFalse
#                }
#
#                It 'Should be executed once' {
#                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
#                }
#            }
#
#            Context 'When both the parameters Members and MembersToExclude are assigned a value and ensure is set to Present' {
#                 BeforeAll {
#                    $testParameters = $mockDefaultParameters
#                    $testParameters += @{
#                        Ensure           = 'Present'
#                        ServerRoleName   = $mockSqlServerRole
#                        Members          = $mockEnumMemberNames
#                        MembersToExclude = $mockSqlServerLoginTwo
#                    }
#
#                    $errorMessage = $script:localizedData.MembersToIncludeAndExcludeParamMustBeNull
#                }
#
#                It 'Should throw the correct error' {
#                    {Test-TargetResource @testParameters}  | Should -Throw '(DRC0010)'
#                }
#
#                It 'Should not be executed' {
#                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 0 -Scope Context
#                }
#            }
#
#            Context 'When parameter MembersToExclude is assigned a value, parameter Members is not assigned a value, and ensure is set to Present' {
#                BeforeAll {
#                    $testParameters = $mockDefaultParameters
#                    $testParameters += @{
#                        Ensure           = 'Present'
#                        ServerRoleName   = $mockSqlServerRole
#                        MembersToExclude = $mockSqlServerLoginThree
#                    }
#
#                    $result = Test-TargetResource @testParameters
#                }
#
#                It 'Should return true when desired server role does not exist' {
#                    $result | Should -BeTrue
#                }
#
#                It 'Should be executed once' {
#                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
#                }
#            }
#
#            Context 'When parameter MembersToExclude is assigned a value, parameter Members is not assigned a value, and ensure is set to Present' {
#                BeforeAll {
#                    $testParameters = $mockDefaultParameters
#                    $testParameters += @{
#                        Ensure           = 'Present'
#                        ServerRoleName   = $mockSqlServerRole
#                        MembersToExclude = $mockSqlServerLoginTwo
#                    }
#
#                    $result = Test-TargetResource @testParameters
#                }
#
#                It 'Should return false when desired server role exist' {
#                    $result | Should -BeFalse
#                }
#
#                It 'Should be executed once' {
#                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
#                }
#            }
#
#            Assert-VerifiableMock
#        }
#
#        Describe "DSC_SqlRole\Set-TargetResource" -Tag 'Set' {
#            BeforeAll {
#                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
#                Mock -CommandName New-Object -MockWith $mockNewObjectServerRole -ParameterFilter {
#                    $TypeName -eq 'Microsoft.SqlServer.Management.Smo.ServerRole'
#                }
#                Mock -CommandName Test-SqlSecurityPrincipal -MockWith {
#                    return ($mockSecurityPrincipals -contains $SecurityPrincipal)
#                }
#            }
#
#            Context 'When the system is not in the desired state and ensure is set to Absent' {
#                BeforeAll {
#                    $mockSqlServerRole = 'ServerRoleToDrop'
#                    $mockExpectedServerRoleToDrop = 'ServerRoleToDrop'
#                    $testParameters = $mockDefaultParameters
#                    $testParameters += @{
#                        Ensure         = 'Absent'
#                        ServerRoleName = $mockSqlServerRole
#                    }
#                }
#
#                It 'Should not throw when calling the drop method' {
#                    { Set-TargetResource @testParameters } | Should -Not -Throw
#                }
#
#                It 'Should be executed once' {
#                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
#                }
#            }
#
#            Context 'When the system is not in the desired state and ensure is set to Absent' {
#                It 'Should throw the correct error when calling the drop method' {
#                    $mockInvalidOperationForDropMethod = $true
#                    $testParameters = $mockDefaultParameters
#                    $testParameters += @{
#                        Ensure         = 'Absent'
#                        ServerRoleName = $mockSqlServerRole
#                    }
#
#                    $errorMessage = $script:localizedData.DropServerRoleSetError `
#                        -f $mockServerName, $mockInstanceName, $mockSqlServerRole
#
#                    { Set-TargetResource @testParameters } | Should -Throw $errorMessage
#
#                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#                }
#            }
#
#            Context 'When the system is not in the desired state and ensure is set to Present' {
#                It 'Should not throw when calling the create method' {
#                    $mockSqlServerRoleAdd = 'ServerRoleToAdd'
#                    $mockExpectedServerRoleToCreate = 'ServerRoleToAdd'
#                    $testParameters = $mockDefaultParameters
#                    $testParameters += @{
#                        Ensure         = 'Present'
#                        ServerRoleName = $mockSqlServerRoleAdd
#                    }
#
#                    { Set-TargetResource @testParameters } | Should -Not -Throw
#
#                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#                }
#
#                It 'Should call the mock function New-Object with TypeName equal to Microsoft.SqlServer.Management.Smo.ServerRole' {
#                    Assert-MockCalled -CommandName New-Object -Exactly -Times 1 -ParameterFilter {
#                        $TypeName -eq 'Microsoft.SqlServer.Management.Smo.ServerRole'
#                    } -Scope Context
#                }
#            }
#
#            Context 'When the system is not in the desired state and ensure is set to Present' {
#                It 'Should throw the correct error when calling the create method' {
#                    $mockSqlServerRoleAdd = 'ServerRoleToAdd'
#                    $mockExpectedServerRoleToCreate = 'ServerRoleToAdd'
#                    $mockInvalidOperationForCreateMethod = $true
#                    $testParameters = $mockDefaultParameters
#                    $testParameters += @{
#                        Ensure         = 'Present'
#                        ServerRoleName = $mockSqlServerRoleAdd
#                    }
#
#                    $errorMessage = $script:localizedData.CreateServerRoleSetError `
#                        -f $mockServerName, $mockInstanceName, $mockSqlServerRoleAdd
#
#                    { Set-TargetResource @testParameters } | Should -Throw $errorMessage
#
#                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#                }
#
#                It 'Should call the mock function New-Object with TypeName equal to Microsoft.SqlServer.Management.Smo.ServerRole' {
#                    Assert-MockCalled -CommandName New-Object -Exactly -Times 1 -ParameterFilter {
#                        $TypeName -eq 'Microsoft.SqlServer.Management.Smo.ServerRole'
#                    } -Scope Context
#                }
#            }
#
#            Context 'When both the parameters Members and MembersToInclude are assigned a value and ensure is set to Present' {
#                It 'Should throw the correct error' {
#                    $testParameters = $mockDefaultParameters
#                    $testParameters += @{
#                        Ensure           = 'Present'
#                        ServerRoleName   = $mockSqlServerRole
#                        Members          = $mockEnumMemberNames
#                        MembersToInclude = $mockSqlServerLoginThree
#                    }
#
#                    { Set-TargetResource @testParameters } | Should -Throw '(DRC0010)'
#                }
#
#                It 'Should should not call Connect-SQL' {
#                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 0 -Scope Context
#                }
#            }
#
#            Context 'When both the parameters Members and MembersToExclude are assigned a value and ensure is set to Present' {
#                It 'Should throw the correct error' {
#                    $testParameters = $mockDefaultParameters
#                    $testParameters += @{
#                        Ensure           = 'Present'
#                        ServerRoleName   = $mockSqlServerRole
#                        Members          = $mockEnumMemberNames
#                        MembersToExclude = $mockSqlServerLoginTwo
#                    }
#
#                    $errorMessage = $script:localizedData.MembersToIncludeAndExcludeParamMustBeNull
#
#                    { Set-TargetResource @testParameters } | Should -Throw '(DRC0010)'
#
#                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 0 -Scope It
#                }
#            }
#
#            Context 'When parameter MembersToInclude is assigned a value, parameter Members is not assigned a value, and ensure is set to Present' {
#                It 'Should not thrown when calling the AddMember method' {
#                    $mockExpectedMemberToAdd = $mockSqlServerLoginThree
#                    $testParameters = $mockDefaultParameters
#                    $testParameters += @{
#                        Ensure           = 'Present'
#                        ServerRoleName   = $mockSqlServerRole
#                        MembersToInclude = $mockSqlServerLoginThree
#                    }
#
#                    { Set-TargetResource @testParameters } | Should -Not -Throw
#
#                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#                }
#            }
#
#            Context 'When parameter MembersToInclude is assigned a value, parameter Members is not assigned a value, and ensure is set to Present' {
#                It 'Should throw the correct error when calling the AddMember method' {
#                    $mockInvalidOperationForAddMemberMethod = $true
#                    $mockExpectedMemberToAdd = $mockSqlServerLoginThree
#                    $testParameters = $mockDefaultParameters
#                    $testParameters += @{
#                        Ensure           = 'Present'
#                        ServerRoleName   = $mockSqlServerRole
#                        MembersToInclude = $mockSqlServerLoginThree
#                    }
#
#                    $errorMessage = $script:localizedData.AddMemberServerRoleSetError `
#                        -f $mockServerName, $mockInstanceName, $mockSqlServerRole, $mockSqlServerLoginThree
#
#                    { Set-TargetResource @testParameters } | Should -Throw $errorMessage
#
#                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#                }
#            }
#
#            Context 'When parameter MembersToInclude is assigned a value, parameter Members is not assigned a value, and ensure is set to Present' {
#                It 'Should throw the correct error when login does not exist' {
#                    $mockExpectedMemberToAdd = $mockSqlServerLoginThree
#                    $testParameters = $mockDefaultParameters
#                    $testParameters += @{
#                        Ensure           = 'Present'
#                        ServerRoleName   = $mockSqlServerRole
#                        MembersToInclude = 'KingJulian'
#                    }
#
#                    $errorMessage = $script:localizedData.AddMemberServerRoleSetError -f (
#                        $mockServerName,
#                        $mockInstanceName,
#                        $mockSqlServerRole,
#                        'KingJulian'
#                    )
#
#                    { Set-TargetResource @testParameters } | Should -Throw $errorMessage
#
#                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#                }
#            }
#
#            Context 'When parameter MembersToExclude is assigned a value, parameter Members is not assigned a value, and ensure is set to Present' {
#                It 'Should not throw when calling the DropMember method' {
#                    $mockExpectedMemberToDrop = $mockSqlServerLoginTwo
#
#                    $testParameters = $mockDefaultParameters
#                    $testParameters += @{
#                        Ensure           = 'Present'
#                        ServerRoleName   = $mockSqlServerRole
#                        MembersToExclude = $mockSqlServerLoginTwo
#                    }
#
#                    { Set-TargetResource @testParameters } | Should -Not -Throw
#
#                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#                }
#            }
#
#            Context 'When parameter MembersToExclude is assigned a value, parameter Members is not assigned a value, and ensure is set to Present' {
#                It 'Should throw the correct error when calling the DropMember method' {
#                    $mockInvalidOperationForDropMemberMethod = $true
#                    $mockExpectedMemberToDrop = $mockSqlServerLoginTwo
#                    $testParameters = $mockDefaultParameters
#                    $testParameters += @{
#                        Ensure           = 'Present'
#                        ServerRoleName   = $mockSqlServerRole
#                        MembersToExclude = $mockSqlServerLoginTwo
#                    }
#
#                    $errorMessage = $script:localizedData.DropMemberServerRoleSetError `
#                        -f $mockServerName, $mockInstanceName, $mockSqlServerRole, $mockSqlServerLoginTwo
#
#                    { Set-TargetResource @testParameters } | Should -Throw $errorMessage
#
#                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#                }
#            }
#
#            Context 'When parameter MembersToExclude is assigned a value, parameter Members is not assigned a value, and ensure is set to Present' {
#                It 'Should throw the correct error when login does not exist' {
#                    $mockEnumMemberNames = @('KingJulian', $mockSqlServerLoginOne, $mockSqlServerLoginTwo)
#                    $mockExpectedMemberToAdd = $mockSqlServerLoginThree
#                    $testParameters = $mockDefaultParameters
#                    $testParameters += @{
#                        Ensure           = 'Present'
#                        ServerRoleName   = $mockSqlServerRole
#                        MembersToExclude = 'KingJulian'
#                    }
#
#                    $errorMessage = $script:localizedData.DropMemberServerRoleSetError -f (
#                        $mockServerName,
#                        $mockInstanceName,
#                        $mockSqlServerRole,
#                        'KingJulian'
#                    )
#
#                    { Set-TargetResource @testParameters } | Should -Throw $errorMessage
#
#                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#                }
#            }
#
#            Context 'When parameter Members is assigned a value and ensure is set to Present' {
#                It 'Should throw the correct error when login does not exist' {
#                    $mockExpectedMemberToDrop = $mockSqlServerLoginTwo
#
#                    $testParameters = $mockDefaultParameters
#                    $testParameters += @{
#                        Ensure         = 'Present'
#                        ServerRoleName = $mockSqlServerRole
#                        Members        = @('KingJulian', $mockSqlServerLoginOne, $mockSqlServerLoginThree)
#                    }
#
#                    $errorMessage = $script:localizedData.AddMemberServerRoleSetError -f (
#                        $mockServerName,
#                        $mockInstanceName,
#                        $mockSqlServerRole,
#                        'KingJulian'
#                    )
#
#                    { Set-TargetResource @testParameters } | Should -Throw $errorMessage
#
#                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#                }
#            }
#
#            Context 'When Members parameter is set and ensure parameter is set to Present' {
#                It 'Should not throw when calling both the AddMember and DropMember methods' {
#                    $mockExpectedMemberToAdd = $mockSqlServerLoginThree
#                    $mockExpectedMemberToDrop = $mockSqlServerLoginTwo
#                    $testParameters = $mockDefaultParameters
#                    $testParameters += @{
#                        Ensure         = 'Present'
#                        ServerRoleName = $mockSqlServerRole
#                        Members        = @($mockSqlServerLoginOne, $mockSqlServerLoginThree)
#                    }
#
#                    { Set-TargetResource @testParameters } | Should -Not -Throw
#
#                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#                }
#            }
#
#            Context 'When nesting role membership' {
#                Context 'When defining an explicit list of members.' {
#                    It 'Should not throw when the member is a Role' {
#                        $mockExpectedMemberToAdd = $mockSqlServerChildRole
#                        $testParameters = $mockDefaultParameters.Clone()
#
#                        $testParameters += @{
#                            Ensure = 'Present'
#                            ServerRoleName = $mockSqlServerRole
#                            Members = @($mockSqlServerLoginOne, $mockSqlServerLoginTwo, $mockSqlServerChildRole)
#                        }
#
#                        { Set-TargetResource @testParameters } | Should -Not -Throw
#
#                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#                    }
#                }
#
#                Context 'When specifying a list of security principals to include in the Role.' {
#                    It 'Should not throw when a member to include is a Role.' {
#                        $mockExpectedMemberToAdd = $mockSqlServerChildRole
#                        $testParameters = $mockDefaultParameters.Clone()
#
#                        $testParameters += @{
#                            Ensure = 'Present'
#                            ServerRoleName = $mockSqlServerRole
#                            MembersToInclude = @($mockSqlServerChildRole)
#                        }
#
#                        { Set-TargetResource @testParameters } | Should -Not -Throw
#
#                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#                    }
#                }
#
#                Context 'When specifying a list of security principals to remove from the Role.' {
#                    It 'Should not throw when the member to exclude is a Role.' {
#                        $mockExpectedMemberToDrop = $mockSqlServerChildRole
#                        $testParameters = $mockDefaultParameters.Clone()
#
#                        $testParameters += @{
#                            Ensure = 'Present'
#                            ServerRoleName = $mockSqlServerRole
#                            MembersToExclude = @($mockSqlServerChildRole)
#                        }
#
#                        { Set-TargetResource @testParameters } | Should -Not -Throw
#
#                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#                    }
#                }
#            }
#
#            Context 'When evaluating role membership, case sensitivity should not be used. (Issue #1153)' {
#                Context 'When specifying explicit role members.' {
#                    It 'Should not attempt to remove an explicit member from the role.' {
#                        $mockExpectedMemberToDrop = $mockSqlServerLoginTwo
#
#                        $testParameters = $mockDefaultParameters.Clone()
#                        $testParameters += @{
#                            ServerRoleName = $mockSqlServerRole
#                            Ensure = 'Present'
#                            Members = $mockSqlServerLoginOne.ToUpper()
#                        }
#
#                        { Set-TargetResource @testParameters } | Should -Not -Throw
#
#                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#                    }
#
#                    It 'Should not attempt to add an explicit member that already exists in the role.' {
#                        $mockExpectedMemberToAdd = ''
#
#                        $testParameters = $mockDefaultParameters.Clone()
#                        $testParameters += @{
#                            ServerRoleName = $mockSqlServerRole
#                            Ensure = 'Present'
#                            Members = @($mockSqlServerLoginOne.ToUpper(), $mockSqlServerLoginTwo)
#                        }
#
#                        { Set-TargetResource @testParameters } | Should -Not -Throw
#
#                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#                    }
#                }
#
#                Context 'When specifying mandatory role membership.' {
#                    It 'Should not attempt to add a member that already exists in the role.' {
#                        $mockExpectedMemberToAdd = ''
#
#                        $testParameters = $mockDefaultParameters.Clone()
#                        $testParameters += @{
#                            ServerRoleName = $mockSqlServerRole
#                            Ensure = 'Present'
#                            MembersToInclude = @($mockSqlServerLoginOne.ToUpper())
#                        }
#
#                        { Set-TargetResource @testParameters } | Should -Not -Throw
#
#                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#                    }
#
#                    It 'Should attempt to remove a member that is to be excluded.' {
#                        $mockExpectedMemberToDrop = $mockSqlServerLoginOne
#
#                        $testParameters = $mockDefaultParameters.Clone()
#                        $testParameters += @{
#                            ServerRoleName = $mockSqlServerRole
#                            Ensure = 'Present'
#                            MembersToExclude = @($mockSqlServerLoginOne.ToUpper())
#                        }
#
#                        { Set-TargetResource @testParameters } | Should -Not -Throw
#
#                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#                    }
#                }
#            }
#
#            Assert-VerifiableMock
#        }
#
#        Describe 'DSC_SqlRole\Test-SqlSecurityPrincipal' -Tag 'Helper' {
#            BeforeAll {
#                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
#
#                $mockPrincipalsAsArrays = $true
#                $testSqlServerObject = Connect-SQL -ServerName $mockServerName -InstanceName $mockInstanceName
#            }
#
#            Context 'When the security principal does not exist.' {
#                It 'Should throw the correct exception' {
#                    $testSecurityPrincipal = 'Nabrond'
#
#                    $testParameters = @{
#                        SqlServerObject = $testSqlServerObject
#                        SecurityPrincipal = $testSecurityPrincipal
#                    }
#
#                    $testErrorMessage = $script:localizedData.SecurityPrincipalNotFound -f (
#                        $testSecurityPrincipal,
#                        "$mockServerName\$mockInstanceName"
#                    )
#
#                    { Test-SqlSecurityPrincipal @testParameters } | Should -Throw -ExpectedMessage $testErrorMessage
#                }
#            }
#
#            Context 'When the security principal exists.' {
#                It 'Should return true when the principal is a Login.' {
#                    $testParameters = @{
#                        SqlServerObject = $testSqlServerObject
#                        SecurityPrincipal = $mockSqlServerLoginOne
#                    }
#
#                    Test-SqlSecurityPrincipal @testParameters | Should -BeTrue
#                }
#
#                It 'Should return true when the principal is a Login and case does not match.' {
#                    $testParameters = @{
#                        SqlServerObject = $testSqlServerObject
#                        SecurityPrincipal = $mockSqlServerLoginOne.ToUpper()
#                    }
#
#                    Test-SqlSecurityPrincipal @testParameters | Should -BeTrue
#                }
#
#                It 'Should return true when the principal is a Role.' {
#                    $testParameters = @{
#                        SqlServerObject = $testSqlServerObject
#                        SecurityPrincipal = $mockSqlServerRole
#                    }
#
#                    Test-SqlSecurityPrincipal @testParameters | Should -BeTrue
#                }
#
#                It 'Should return true when the principal is a Role and case does not match.' {
#                    $testParameters = @{
#                        SqlServerObject = $testSqlServerObject
#                        SecurityPrincipal = $mockSqlServerRole.ToUpper()
#                    }
#
#                    Test-SqlSecurityPrincipal @testParameters | Should -BeTrue
#                }
#            }
#        }
#
#        Describe 'DSC_SqlRole\Get-CorrectedMemberParameters' -Tag 'Helper' {
#            Context 'When parameter Members is assigned a value and the role is not sysadmin, the output should be the same' {
#                BeforeAll {
#                    $testParameters = @{
#                        ServerRoleName   = $mockSqlServerRole
#                        Members          = $mockEnumMemberNames
#                    }
#
#                    $result = Get-CorrectedMemberParameters @testParameters
#                }
#
#                It 'Should return an array with 2 elements' {
#                    $result.Members | Should -HaveCount 2
#                }
#
#                It 'Should return the same elements' {
#                    $result.Members | Should -Be $mockEnumMemberNames
#                }
#
#                It 'Should not return extra values' {
#                    $result.MembersToInclude | Should -BeNullOrEmpty
#                    $result.MembersToExclude | Should -BeNullOrEmpty
#                }
#            }
#
#            Context 'When parameter Members is assigned a value and the role is sysadmin, if SA is in Members, the output should be the same' {
#                BeforeAll {
#                    $testParameters = @{
#                        ServerRoleName   = $mockSqlServerRoleSysAdmin
#                        Members          = $mockEnumMemberNamesSysAdmin
#                    }
#
#                    $result = Get-CorrectedMemberParameters @testParameters
#                }
#
#                It 'Should return an array with 3 elements' {
#                    $result.Members | Should -HaveCount 3
#                }
#
#                It 'Should return the same elements' {
#                    $result.Members | Should -Be $mockEnumMemberNamesSysAdmin
#                }
#
#                It 'Should not return extra values' {
#                    $result.MembersToInclude | Should -BeNullOrEmpty
#                    $result.MembersToExclude | Should -BeNullOrEmpty
#                }
#            }
#
#            Context 'When parameter Members is assigned a value and the role is sysadmin, if SA is not in Members, SA should be added to the  output' {
#                BeforeAll {
#                    $testParameters = @{
#                        ServerRoleName   = $mockSqlServerRoleSysAdmin
#                        Members          = $mockEnumMemberNames
#                    }
#
#                    $result = Get-CorrectedMemberParameters @testParameters
#                }
#
#                It 'Should return an array with 3 elements' {
#                    $result.Members | Should -HaveCount 3
#                }
#
#                It 'Should have SA in Members' {
#                    $result.Members | Should -Contain $mockSqlServerSA
#                }
#
#                It 'Should not return extra values' {
#                    $result.MembersToInclude | Should -BeNullOrEmpty
#                    $result.MembersToExclude | Should -BeNullOrEmpty
#                }
#            }
#
#            Context 'When parameter MembersToInclude is assigned a value and the role is not sysadmin, if SA is in MembersToInclude, the output should be the same' {
#                BeforeAll {
#                    $testParameters = @{
#                        ServerRoleName   = $mockSqlServerRole
#                        MembersToInclude = $mockEnumMemberNamesSysAdmin
#                    }
#
#                    $result = Get-CorrectedMemberParameters @testParameters
#                }
#
#                It 'Should return an array with 3 elements' {
#                    $result.MembersToInclude | Should -HaveCount 3
#                }
#
#                It 'Should return the elements from Members' {
#                    $result.MembersToInclude | Should -Be $mockEnumMemberNamesSysAdmin
#                }
#
#                It 'Should not return extra values' {
#                    $result.Members | Should -BeNullOrEmpty
#                    $result.MembersToExclude | Should -BeNullOrEmpty
#                }
#            }
#
#            Context 'When parameter MembersToInclude is assigned a value and the role is not sysadmin, if SA is not in MembersToInclude, the output should be the same' {
#                BeforeAll {
#                    $testParameters = @{
#                        ServerRoleName   = $mockSqlServerRole
#                        MembersToInclude = $mockEnumMemberNames
#                    }
#
#                    $result = Get-CorrectedMemberParameters @testParameters
#                }
#
#                It 'Should return an array with 2 elements' {
#                    $result.MembersToInclude | Should -HaveCount 2
#                }
#
#                It 'Should return the elements from Members' {
#                    $result.MembersToInclude | Should -Be $mockEnumMemberNames
#                }
#
#                It 'Should not return extra values' {
#                    $result.Members | Should -BeNullOrEmpty
#                    $result.MembersToExclude | Should -BeNullOrEmpty
#                }
#            }
#
#            Context 'When parameter MembersToInclude is assigned a value and the role is sysadmin, if SA is not in MembersToInclude, the output should be the same' {
#                BeforeAll {
#                    $testParameters = @{
#                        ServerRoleName   = $mockSqlServerRoleSysAdmin
#                        MembersToInclude = $mockEnumMemberNames
#                    }
#
#                    $result = Get-CorrectedMemberParameters @testParameters
#                }
#
#                It 'Should return an array with 2 elements' {
#                    $result.MembersToInclude | Should -HaveCount 2
#                }
#
#                It 'Should return the elements from Members' {
#                    $result.MembersToInclude | Should -Be $mockEnumMemberNames
#                }
#
#                It 'Should not return extra values' {
#                    $result.Members | Should -BeNullOrEmpty
#                    $result.MembersToExclude | Should -BeNullOrEmpty
#                }
#            }
#
#            Context 'When parameter MembersToInclude is assigned a value and the role is sysadmin, if SA is in MembersToInclude, the output should be the same' {
#                BeforeAll {
#                    $testParameters = @{
#                        ServerRoleName   = $mockSqlServerRoleSysAdmin
#                        MembersToInclude = $mockEnumMemberNamesSysAdmin
#                    }
#
#                    $result = Get-CorrectedMemberParameters @testParameters
#                }
#
#                It 'Should return an array with 3 elements' {
#                    $result.MembersToInclude | Should -HaveCount 3
#                }
#
#                It 'Should return the elements from Members' {
#                    $result.MembersToInclude | Should -Be $mockEnumMemberNamesSysAdmin
#                }
#
#                It 'Should not return extra values' {
#                    $result.Members | Should -BeNullOrEmpty
#                    $result.MembersToExclude | Should -BeNullOrEmpty
#                }
#            }
#
#            Context 'When parameter MembersToExclude is assigned a value and the role is not sysadmin, if SA is in MembersToExclude, the output should be the same' {
#                BeforeAll {
#                    $testParameters = @{
#                        ServerRoleName   = $mockSqlServerRole
#                        MembersToExclude = $mockEnumMemberNamesSysAdmin
#                    }
#
#                    $result = Get-CorrectedMemberParameters @testParameters
#                }
#
#                It 'Should return an array with 3 elements' {
#                    $result.MembersToExclude | Should -HaveCount 3
#                }
#
#                It 'Should return the elements from Members' {
#                    $result.MembersToExclude | Should -Be $mockEnumMemberNamesSysAdmin
#                }
#
#                It 'Should not return extra values' {
#                    $result.Members | Should -BeNullOrEmpty
#                    $result.MembersToInclude | Should -BeNullOrEmpty
#                }
#            }
#
#            Context 'When parameter MembersToExclude is assigned a value and the role is not sysadmin, if SA is not in MembersToExclude, the output should be the same' {
#                BeforeAll {
#                    $testParameters = @{
#                        ServerRoleName   = $mockSqlServerRole
#                        MembersToExclude = $mockEnumMemberNames
#                    }
#
#                    $result = Get-CorrectedMemberParameters @testParameters
#                }
#
#                It 'Should return an array with 2 elements' {
#                    $result.MembersToExclude | Should -HaveCount 2
#                }
#
#                It 'Should return the elements from Members' {
#                    $result.MembersToExclude | Should -Be $mockEnumMemberNames
#                }
#
#                It 'Should not return extra values' {
#                    $result.Members | Should -BeNullOrEmpty
#                    $result.MembersToInclude | Should -BeNullOrEmpty
#                }
#            }
#
#            Context 'When parameter MembersToExclude is assigned a value and the role is sysadmin, if SA is not in MembersToExclude, the output should be the same' {
#                BeforeAll {
#                    $testParameters = @{
#                        ServerRoleName   = $mockSqlServerRoleSysAdmin
#                        MembersToExclude = $mockEnumMemberNames
#                    }
#
#                    $result = Get-CorrectedMemberParameters @testParameters
#                }
#
#                It 'Should return an array with 2 elements' {
#                    $result.MembersToExclude | Should -HaveCount 2
#                }
#
#                It 'Should return the elements from Members' {
#                    $result.MembersToExclude | Should -Be $mockEnumMemberNames
#                }
#
#                It 'Should not return extra values' {
#                    $result.Members | Should -BeNullOrEmpty
#                    $result.MembersToInclude | Should -BeNullOrEmpty
#                }
#            }
#
#            Context 'When parameter MembersToExclude is assigned a value and the role is sysadmin, if SA is in MembersToExclude, SA should be removed' {
#                BeforeAll {
#                    $testParameters = @{
#                        ServerRoleName   = $mockSqlServerRoleSysAdmin
#                        MembersToExclude = $mockEnumMemberNamesSysAdmin
#                    }
#
#                    $result = Get-CorrectedMemberParameters @testParameters
#                }
#
#                It 'Should return an array with 2 elements' {
#                    $result.MembersToExclude | Should -HaveCount 2
#                }
#
#                It 'Should return the elements from Members' {
#                    $result.MembersToExclude | Should -Not -Contain $mockSqlServerSA
#                }
#
#                It 'Should not return extra values' {
#                    $result.Members | Should -BeNullOrEmpty
#                    $result.MembersToInclude | Should -BeNullOrEmpty
#                }
#            }
#        }
    }
}
finally
{
    Invoke-TestCleanup
}
#Parent             : Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer
#AcceptsPause       : True
#AcceptsStop        : True
#Description        : Provides storage, processing and controlled access of data, and rapid transaction processing.
#DisplayName        : SQL Server (INST00)
#ErrorControl       : Normal
#ExitCode           : 0
#PathName           : "C:\Program Files\Microsoft SQL Server\MSSQL15.INST00\MSSQL\Binn\sqlservr.exe" -sINST00
#ProcessId          : 3236
#ServiceAccount     : NT Service\MSSQL$INST00
#ServiceState       : Running
#StartMode          : Auto
#Type               : SqlServer
#IsHadrEnabled      : False
#StartupParameters  : -dC:\Program Files\Microsoft SQL Server\MSSQL15.INST00\MSSQL\DATA\master.mdf;-eC:\Program Files\Microsoft SQL
#                     Server\MSSQL15.INST00\MSSQL\Log\ERRORLOG;-lC:\Program Files\Microsoft SQL
#                     Server\MSSQL15.INST00\MSSQL\DATA\mastlog.ldf;-T3226;-T1802
#Dependencies       : {System.String[]}
#AdvancedProperties : {Name=CLUSTERED/Type=System.Boolean/Writable=False/Value=False,
#                     Name=DATAPATH/Type=System.String/Writable=False/Value=C:\Program Files\Microsoft SQL
#                     Server\MSSQL15.INST00\MSSQL, Name=DUMPDIR/Type=System.String/Writable=True/Value=C:\Program Files\Microsoft SQL
#                     Server\MSSQL15.INST00\MSSQL\LOG\, Name=ERRORREPORTING/Type=System.Boolean/Writable=True/Value=False...}
#Urn                : ManagedComputer[@Name='SQL2019-00']/Service[@Name='MSSQL$INST00']
#Name               : MSSQL$INST00
#Properties         : {Name=AcceptsPause/Type=System.Boolean/Writable=False/Value=True,
#                     Name=AcceptsStop/Type=System.Boolean/Writable=False/Value=True,
#                     Name=Dependencies/Type=System.String/Writable=False/Value=System.String[],
#                     Name=Description/Type=System.String/Writable=False/Value=Provides storage, processing and controlled access of
#                     data, and rapid transaction processing....}
#UserData           :
#State              : Existing
#

#Parent             : Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer
#AcceptsPause       : False
#AcceptsStop        : True
#Description        : Service to launch Advanced Analytics Extensions Launchpad process that enables integration with Microsoft R
#                     Open using standard T-SQL statements. Disabling this service will make Advanced Analytics features of SQL
#                     Server unavailable.
#DisplayName        : SQL Server Launchpad (INST00)
#ErrorControl       : Normal
#ExitCode           : 0
#PathName           : "C:\Program Files\Microsoft SQL Server\MSSQL15.INST00\MSSQL\Binn\launchpad.exe" -launcher RLauncher.dll
#                     -launcher Pythonlauncher.dll -launcher commonlauncher.dll -pipename sqlsatellitelaunchINST00 -timeout 600000
#                     -logPath "C:\Program Files\Microsoft SQL Serve
#ProcessId          : 3552
#ServiceAccount     : NT Service\MSSQLLaunchpad$INST00
#ServiceState       : Running
#StartMode          : Auto
#Type               : 12
#IsHadrEnabled      :
#StartupParameters  :
#Dependencies       : {System.String[]}
#AdvancedProperties : {Name=INSTANCEID/Type=System.String/Writable=False/Value=MSSQL15.INST00,
#                     Name=REGROOT/Type=System.String/Writable=False/Value=Software\Microsoft\Microsoft SQL Server\MSSQL15.INST00,
#                     Name=SECURITY_CONTEXTS_COUNT/Type=System.Int64/Writable=True/Value=20,
#                     Name=VERSION/Type=System.String/Writable=False/Value=15.0.2000.5}
#Urn                : ManagedComputer[@Name='SQL2019-00']/Service[@Name='MSSQLLAUNCHPAD$INST00']
#Name               : MSSQLLAUNCHPAD$INST00
#Properties         : {Name=AcceptsPause/Type=System.Boolean/Writable=False/Value=False,
#                     Name=AcceptsStop/Type=System.Boolean/Writable=False/Value=True,
#                     Name=Dependencies/Type=System.String/Writable=False/Value=System.String[],
#                     Name=Description/Type=System.String/Writable=False/Value=Service to launch Advanced Analytics Extensions
#                     Launchpad process that enables integration with Microsoft R Open using standard T-SQL statements. Disabling
#                     this service will make Advanced Analytics features of SQL Server unavailable....}
#UserData           :
#State              : Existing


#
#Parent             : Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer
#AcceptsPause       : False
#AcceptsStop        : False
#Description        : Executes jobs, monitors SQL Server, fires alerts, and allows automation of some administrative tasks.
#DisplayName        : SQL Server Agent (INST00)
#ErrorControl       : Normal
#ExitCode           : 1077
#PathName           : "C:\Program Files\Microsoft SQL Server\MSSQL15.INST00\MSSQL\Binn\SQLAGENT.EXE" -i INST00
#ProcessId          : 0
#ServiceAccount     : NT Service\SQLAgent$INST00
#ServiceState       : Stopped
#StartMode          : Manual
#Type               : SqlAgent
#IsHadrEnabled      :
#StartupParameters  :
#Dependencies       : {System.String[]}
#AdvancedProperties : {Name=CLUSTERED/Type=System.Boolean/Writable=False/Value=False,
#                     Name=DUMPDIR/Type=System.String/Writable=True/Value=C:\Program Files\Microsoft SQL
#                     Server\MSSQL15.INST00\MSSQL\LOG\, Name=ERRORREPORTING/Type=System.Boolean/Writable=True/Value=False,
#                     Name=INSTANCEID/Type=System.String/Writable=False/Value=MSSQL15.INST00...}
#Urn                : ManagedComputer[@Name='SQL2019-00']/Service[@Name='SQLAgent$INST00']
#Name               : SQLAgent$INST00
#Properties         : {Name=AcceptsPause/Type=System.Boolean/Writable=False/Value=False,
#                     Name=AcceptsStop/Type=System.Boolean/Writable=False/Value=False,
#                     Name=Dependencies/Type=System.String/Writable=False/Value=System.String[],
#                     Name=Description/Type=System.String/Writable=False/Value=Executes jobs, monitors SQL Server, fires alerts, and
#                     allows automation of some administrative tasks....}
#UserData           :
#State              : Existing


#
#Parent             : Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer
#AcceptsPause       : True
#AcceptsStop        : True
#Description        : Provides SQL Server connection information to client computers.
#DisplayName        : SQL Server Browser
#ErrorControl       : Normal
#ExitCode           : 0
#PathName           : "C:\Program Files (x86)\Microsoft SQL Server\90\Shared\sqlbrowser.exe"
#ProcessId          : 2284
#ServiceAccount     : NT AUTHORITY\LOCALSERVICE
#ServiceState       : Running
#StartMode          : Auto
#Type               : SqlBrowser
#IsHadrEnabled      :
#StartupParameters  :
#Dependencies       : {System.String[]}
#AdvancedProperties : {Name=BROWSER/Type=System.Boolean/Writable=True/Value=True,
#                     Name=CLUSTERED/Type=System.Boolean/Writable=False/Value=False,
#                     Name=DUMPDIR/Type=System.String/Writable=True/Value=C:\Program Files\Microsoft SQL
#                     Server\MSSQL15.INST00\MSSQL\LOG\, Name=ERRORREPORTING/Type=System.Boolean/Writable=True/Value=False...}
#Urn                : ManagedComputer[@Name='SQL2019-00']/Service[@Name='SQLBrowser']
#Name               : SQLBrowser
#Properties         : {Name=AcceptsPause/Type=System.Boolean/Writable=False/Value=True,
#                     Name=AcceptsStop/Type=System.Boolean/Writable=False/Value=True,
#                     Name=Dependencies/Type=System.String/Writable=False/Value=System.String[],
#                     Name=Description/Type=System.String/Writable=False/Value=Provides SQL Server connection information to client
#                     computers....}
#UserData           :
#State              : Existing

                                #ServerProtocols = @{
                                #    Tcp = @{
                                #        IsEnabled           = $true
                                #        HasMultiIPAddresses = $true
                                #        ProtocolProperties  = @{
                                #            ListenOnAllIPs = $true
                                #            KeepAlive      = 30000
                                #        }
                                #    }
                                #}