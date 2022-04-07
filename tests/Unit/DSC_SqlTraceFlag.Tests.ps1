<#
    .SYNOPSIS
        Unit test for DSC_SqlTraceFlag DSC resource.
#>

# Suppressing this rule because Script Analyzer does not understand Pester's syntax.
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
                # Redirect all streams to $null, except the error stream (stream 3)
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
    $script:dscResourceName = 'DSC_SqlTraceFlag'

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

    # Load the correct SQL Module stub
    $script:stubModuleName = Import-SQLModuleStub -PassThru

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscResourceName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscResourceName -All | Remove-Module -Force

    # Unload the stub module.
    Remove-SqlModuleStub -Name $script:stubModuleName

    # Remove module common test helper.
    Get-Module -Name 'CommonTestHelper' -All | Remove-Module -Force
}

Describe 'DSC_SqlTraceFlag\Get-TargetResource' -Tag 'Get' {
    BeforeAll {
        #region Function mocks
        $mockSmoWmiManagedComputer = {
            param($ServerName)
            $mockServerInstances = [System.Collections.ArrayList]::new()
            $mockServerInstances.Add('MSSQLSERVER') | Out-Null
            $mockServerInstances.Add('INST00') | Out-Null

            $mockServerObjectHashtable = @{
                State = 'Existing'
                Name = 'TestServer'
                ServerInstances = $mockServerInstances
            }

            class service
            {
                [string] $Name
                [string] $ServiceState
                [string] $StartupParameters
            }

            $Services = [System.Collections.ArrayList]::new()

            $service1 = [service]::new()
            $service1.Name = 'MSSQLSERVER'
            $service1.ServiceState = 'Running'

            $mockStartupParameters = [System.Text.StringBuilder]::new()
            # The Trailing spaces in these strings are ment to be there.
            $mockStartupParameters.AppendLine('-dC:\Program Files\Microsoft SQL Server\MSSQL15.INST00\MSSQL\DATA\master.mdf;-eC:\Program Files\Microsoft SQL ') | Out-Null
            $mockStartupParameters.AppendLine('Server\MSSQL15.INST00\MSSQL\Log\ERRORLOG;-lC:\Program Files\Microsoft SQL ') | Out-Null
            $mockStartupParameters.Append('Server\MSSQL15.INST00\MSSQL\DATA\mastlog.ldf;-T3226;-T1802') | Out-Null

            $service1.StartupParameters = $mockStartupParameters.ToString()

            $Services.Add($service1) | Out-Null

            $service2 = [service]::new()
            $service2.Name = 'SQLSERVERAGENT'
            $service2.ServiceState = 'Running'
            $service2.StartupParameters = ''

            $Services.Add($service2) | Out-Null

            $service3 = [service]::new()
            $service3.Name = 'MSSQL$INST00'
            $service3.ServiceState = 'Running'

            $mockStartupParameters = [System.Text.StringBuilder]::new()
            # The Trailing spaces in these strings are ment to be there.
            $mockStartupParameters.AppendLine('-dC:\Program Files\Microsoft SQL Server\MSSQL15.INST00\MSSQL\DATA\master.mdf;-eC:\Program Files\Microsoft SQL ') | Out-Null
            $mockStartupParameters.AppendLine('Server\MSSQL15.INST00\MSSQL\Log\ERRORLOG;-lC:\Program Files\Microsoft SQL ') | Out-Null
            $mockStartupParameters.Append('Server\MSSQL15.INST00\MSSQL\DATA\mastlog.ldf') | Out-Null

            $service3.StartupParameters = $mockStartupParameters.ToString()

            $Services.Add($service3) | Out-Null

            $service4 = [service]::new()
            $service4.Name = 'SQLAgent$SQLAgent$INST00'
            $service4.ServiceState = 'Stopped'
            $service4.StartupParameters = ''

            $Services.Add($service4) | Out-Null

            $ServerServices = [System.Collections.ArrayList]::new()

            foreach ($mockService in $Services)
            {
                $ServerServices.Add($mockService) | Out-Null
            }

            $mockServerObjectHashtable += @{
                Services = $ServerServices
            }

            $mockServerObject = [PSCustomObject] $mockServerObjectHashtable

            return @($mockServerObject)
        }

        Mock -CommandName New-Object -MockWith $mockSmoWmiManagedComputer -ParameterFilter {
            $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer'
        }

        Mock -CommandName Import-SQLPSModule

        InModuleScope -ScriptBlock {
            # Default parameters that are used for the It-blocks.
            $script:mockDefaultParameters = @{
                InstanceName = 'MSSQLSERVER'
                ServerName   = 'TestServer'
            }
        }
    }

    BeforeEach {
        InModuleScope -ScriptBlock {
            $script:mockGetTargetResourceParameters = $script:mockDefaultParameters.Clone()
        }
    }

    Context 'For the default instance' {
        It 'Should return a ManagedComputer object' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockGetTargetResourceParameters

                $result.ServerName | Should -Be 'TestServer' -Because 'ServerName must be correct'
                $result.InstanceName | Should -Be 'MSSQLSERVER' -Because 'InstanceName must be correct'
                $result.TraceFlags | Should -Be @('3226', '1802') -Because 'TraceFlags must be correct'
                $result.TraceFlags.Count | Should -Be 2 -Because 'number of TraceFlags must be correct'
            }
        }

        It 'Should not throw' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Get-TargetResource @mockGetTargetResourceParameters } | Should -Not -Throw
            }
        }
    }

    Context 'For a named instance' {
        It 'Should return a ManagedComputer object.' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockGetTargetResourceParameters.InstanceName = 'INST00'

                $result = Get-TargetResource @mockGetTargetResourceParameters

                $result.ServerName | Should -Be 'TestServer' -Because 'ServerName must be correct'
                $result.InstanceName | Should -Be 'INST00' -Because 'InstanceName must be correct'
                $result.TraceFlags | Should -BeNullOrEmpty -Because 'TraceFlags must be correct'
                $result.TraceFlags.Count | Should -Be 0 -Because 'number of TraceFlags must be correct'
            }
        }

        It 'Should not throw' {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Get-TargetResource @mockGetTargetResourceParameters } | Should -Not -Throw
            }
        }
    }

    Context 'For a nonexistent instance' {
        It 'Should throw for incorrect parameters' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockGetTargetResourceParameters.InstanceName = 'INST01'

                $mockErrorMessage = $script:localizedData.NotConnectedToWMI -f 'INST01', 'TestServer'

                { Get-TargetResource @mockGetTargetResourceParameters } |
                    Should -Throw -ExpectedMessage ('*' + $mockErrorMessage)
            }
        }
    }

    Context 'For a nonexistent server' {
        BeforeAll {
            Mock -CommandName New-Object -MockWith {
                return $null
            } -ParameterFilter {
                $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer'
            }
        }

        It 'Should throw for incorrect parameters' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockGetTargetResourceParameters.ServerName = 'FakeServer'
                $mockGetTargetResourceParameters.InstanceName = 'INST00' # Instance exist

                $mockErrorMessage = $script:localizedData.NotConnectedToComputerManagement -f 'FakeServer'

                { Get-TargetResource @mockGetTargetResourceParameters } |
                    Should -Throw -ExpectedMessage ('*' + $mockErrorMessage)            }
        }
    }
}

# Describe 'DSC_SqlTraceFlag\Test-TargetResource' -Tag 'Test' {
#     BeforeAll {
#         $mockServerName = 'TestServer'
#         $mockFakeServerName = 'FakeServer'
#         $mockInstanceName1 = 'MSSQLSERVER'
#         $mockInstanceName1Agent = 'SQLSERVERAGENT'
#         $mockInstanceName2 = 'INST00'
#         $mockInstanceName2Agent = 'SQLAgent$INST00'
#         $mockInstanceName3 = 'INST01'
#         $mockInstanceName3Agent = 'SQLAgent$INST01'

#         $mockInvalidOperationForAlterMethod = $false

#         $mockServerInstances = [System.Collections.ArrayList]::new()
#         $mockServerInstances.Add($mockInstanceName1) | Out-Null
#         $mockServerInstances.Add($mockInstanceName2) | Out-Null

#         # The Trailing spaces in these here strings are ment to be there. Do not remove!
#         $mockStartupParametersInstance1 = @"
# -dC:\Program Files\Microsoft SQL Server\MSSQL15.INST00\MSSQL\DATA\master.mdf;-eC:\Program Files\Microsoft SQL
# Server\MSSQL15.INST00\MSSQL\Log\ERRORLOG;-lC:\Program Files\Microsoft SQL
# Server\MSSQL15.INST00\MSSQL\DATA\mastlog.ldf;-T3226;-T1802
# "@
#         $mockStartupParametersInstance2 = @"
# -dC:\Program Files\Microsoft SQL Server\MSSQL15.INST00\MSSQL\DATA\master.mdf;-eC:\Program Files\Microsoft SQL
# Server\MSSQL15.INST00\MSSQL\Log\ERRORLOG;-lC:\Program Files\Microsoft SQL
# Server\MSSQL15.INST00\MSSQL\DATA\mastlog.ldf
# "@

#         # Default parameters that are used for the It-blocks
#         $mockDefaultParameters1 = @{
#             InstanceName = $mockInstanceName1
#             ServerName   = $mockServerName
#         }

#         $mockInst00Parameters = @{
#             InstanceName = $mockInstanceName2
#             ServerName   = $mockServerName
#         }

#         $mockInst01Parameters = @{
#             InstanceName = $mockInstanceName3
#             ServerName   = $mockServerName
#         }

#         $mockNonExistServerParameters = @{
#             InstanceName = $mockInstanceName1
#             ServerName   = $mockFakeServerName
#         }

#         $mockNewObject_ParameterFilter_RealServerName = {
#             $ServerName -eq $mockServerName
#         }

#         $mockNewObject_ParameterFilter_FakeServerName = {
#             $ServerName -eq $mockFakeServerName
#         }

#         $script:mockMethodAlterRan = $false
#         $script:mockMethodAlterValue = ''

#         #region Function mocks
#         $mockSmoWmiManagedComputer = {
#             $mockServerObjectHashtable = @{
#                 State = 'Existing'
#                 Name = $mockServerName
#                 ServerInstances = $mockServerInstances
#             }

#             class service
#             {
#                 [string]$Name
#                 [string]$ServiceState
#                 [string]$StartupParameters
#             }

#             $Services = [System.Collections.ArrayList]::new()

#             $service1 = [service]::new()
#             $service1.Name = $mockInstanceName1
#             $service1.ServiceState = 'Running'
#             $service1.StartupParameters = $mockStartupParametersInstance1

#             $Services.Add($service1) | Out-Null

#             $service2 = [service]::new()
#             $service2.Name = $mockInstanceName1Agent
#             $service2.ServiceState = 'Running'
#             $service2.StartupParameters = ''

#             $Services.Add($service2) | Out-Null

#             $service3 = [service]::new()
#             $service3.Name = 'MSSQL${0}' -f $mockInstanceName2
#             $service3.ServiceState = 'Running'
#             $service3.StartupParameters = $mockStartupParametersInstance2

#             $Services.Add($service3) | Out-Null

#             $service4 = [service]::new()
#             $service4.Name = 'SQLAgent${0}' -f $mockInstanceName2Agent
#             $service4.ServiceState = 'Stopped'
#             $service4.StartupParameters = ''

#             $Services.Add($service4) | Out-Null

#             $ServerServices = [System.Collections.ArrayList]::new()

#             foreach ($mockService in $Services)
#             {
#                 $mockService | Add-Member -MemberType ScriptMethod -Name Alter -Value {
#                     $script:mockMethodAlterRan = $true
#                     $script:mockMethodAlterValue = $this.StartupParameters
#                 } -PassThru
#                 $ServerServices.Add( $mockService) | Out-Null
#             }

#             $mockServerObjectHashtable += @{
#                 Services = $ServerServices
#             }
#             $mockServerObject = [PSCustomObject]$mockServerObjectHashtable

#             return @($mockServerObject)
#         }
#         Mock -CommandName New-Object -MockWith $mockSmoWmiManagedComputer
#         Mock -CommandName Import-SQLPSModule
#     }

#     Context 'When the system is not in the desired state and TraceFlags is empty with existing traceflag' {
#         BeforeAll {
#             $testParameters = $mockDefaultParameters1
#             $testParameters += @{
#                 TraceFlags = @()
#             }
#         }

#         It 'Should return false when Traceflags on the instance exist' {
#             $result = Test-TargetResource @testParameters
#             $result | Should -BeFalse
#         }

#         It 'Should be executed once' {
#             Assert-MockCalled -CommandName New-Object -Exactly -Times 1 -Scope Context
#         }
#     }

#     Context 'When the system is in the desired state and TraceFlags is empty without existing traceflag' {
#         BeforeAll {
#             $testParameters = $mockInst00Parameters
#             $testParameters += @{
#                 TraceFlags = @()
#             }
#         }

#         It 'Should return true when no Traceflags on the instance exist' {
#             $result = Test-TargetResource @testParameters
#             $result | Should -BeTrue
#         }

#         It 'Should be executed once' {
#             Assert-MockCalled -CommandName New-Object -Exactly -Times 1 -Scope Context
#         }
#     }

#     Context 'When the system is not in the desired state and ensure is set to Present and `$TraceFlags does not match the actual TraceFlags with existing traceflag' {
#         BeforeAll {
#             $testParameters = $mockDefaultParameters1
#             $testParameters += @{
#                 TraceFlags = '3228'
#             }
#         }

#         It 'Should return false when Traceflags do not match the actual TraceFlags' {
#             $result = Test-TargetResource @testParameters
#             $result | Should -BeFalse
#         }

#         It 'Should be executed once' {
#             Assert-MockCalled -CommandName New-Object -Exactly -Times 1 -Scope Context
#         }
#     }

#     Context 'When the system is not in the desired state and ensure is set to Present and `$TraceFlags does not match the actual TraceFlags without existing traceflag' {
#         BeforeAll {
#             $testParameters = $mockInst00Parameters
#             $testParameters += @{
#                 TraceFlags = '3228'
#             }
#         }

#         It 'Should return false when Traceflags do not match the actual TraceFlags' {
#             $result = Test-TargetResource @testParameters
#             $result | Should -BeFalse
#         }

#         It 'Should be executed once' {
#             Assert-MockCalled -CommandName New-Object -Exactly -Times 1 -Scope Context
#         }
#     }

#     Context 'When the system is not in the desired state and ensure is set to Present and `$TraceFlagsToInclude are not in the actual TraceFlags with existing traceflag' {
#         BeforeAll {
#             $testParameters = $mockDefaultParameters1
#             $testParameters += @{
#                 TraceFlagsToInclude = '3228'
#             }
#         }

#         It 'Should return false when TraceflagsToInclude are not in the actual TraceFlags' {
#             $result = Test-TargetResource @testParameters
#             $result | Should -BeFalse
#         }

#         It 'Should be executed once' {
#             Assert-MockCalled -CommandName New-Object -Exactly -Times 1 -Scope Context
#         }
#     }

#     Context 'When the system is not in the desired state and ensure is set to Present and `$TraceFlagsToInclude are not in the actual TraceFlags without existing traceflag' {
#         BeforeAll {
#             $testParameters = $mockInst00Parameters
#             $testParameters += @{
#                 TraceFlagsToInclude = '3228'
#             }
#         }

#         It 'Should return false when TraceflagsToInclude are not in the actual TraceFlags' {
#             $result = Test-TargetResource @testParameters
#             $result | Should -BeFalse
#         }

#         It 'Should be executed once' {
#             Assert-MockCalled -CommandName New-Object -Exactly -Times 1 -Scope Context
#         }
#     }

#     Context 'When the system is in the desired state and ensure is set to Present and `$TraceFlagsToInclude are in the actual TraceFlags' {
#         BeforeAll {
#             $testParameters = $mockDefaultParameters1
#             $testParameters += @{
#                 TraceFlagsToInclude = '3226'
#             }
#         }

#         It 'Should return false when TraceflagsToInclude are in the actual TraceFlags' {
#             $result = Test-TargetResource @testParameters
#             $result | Should -BeTrue
#         }

#         It 'Should be executed once' {
#             Assert-MockCalled -CommandName New-Object -Exactly -Times 1 -Scope Context
#         }
#     }

#     Context 'When the system is not in the desired state and ensure is set to Present and `$TraceFlagsToExclude are in the actual TraceFlags' {
#         BeforeAll {
#             $testParameters = $mockDefaultParameters1
#             $testParameters += @{
#                 TraceFlagsToExclude = '3226'
#             }
#         }

#         It 'Should return false when TraceflagsToExclude are in the actual TraceFlags' {
#             $result = Test-TargetResource @testParameters
#             $result | Should -BeFalse
#         }

#         It 'Should be executed once' {
#             Assert-MockCalled -CommandName New-Object -Exactly -Times 1 -Scope Context
#         }
#     }

#     Context 'When the system is in the desired state and ensure is set to Present and `$TraceFlagsToExclude are not in the actual TraceFlags with existing traceflag' {
#         BeforeAll {
#             $testParameters = $mockDefaultParameters1
#             $testParameters += @{
#                 TraceFlagsToExclude = '3228'
#             }
#         }

#         It 'Should return true when TraceflagsToExclude are not in the actual TraceFlags' {
#             $result = Test-TargetResource @testParameters
#             $result | Should -BeTrue
#         }

#         It 'Should be executed once' {
#             Assert-MockCalled -CommandName New-Object -Exactly -Times 1 -Scope Context
#         }
#     }

#     Context 'When the system is in the desired state and ensure is set to Present and `$TraceFlagsToExclude are not in the actual TraceFlags without existing traceflag' {
#         BeforeAll {
#             $testParameters = $mockInst00Parameters
#             $testParameters += @{
#                 TraceFlagsToExclude = '3228'
#             }
#         }

#         It 'Should return true when TraceflagsToExclude are not in the actual TraceFlags' {
#             $result = Test-TargetResource @testParameters
#             $result | Should -BeTrue
#         }

#         It 'Should be executed once' {
#             Assert-MockCalled -CommandName New-Object -Exactly -Times 1 -Scope Context
#         }
#     }

#     Context 'When both the parameters TraceFlags and TraceFlagsToInclude are assigned a value.' {
#         BeforeAll {
#             $testParameters = $mockDefaultParameters1
#             $testParameters += @{
#                 TraceFlags          = '3228'
#                 TraceFlagsToInclude = '3228'
#             }
#         }

#         It 'Should throw the correct error' {
#             { Test-TargetResource @testParameters } | Should -Throw '(DRC0010)'
#         }

#         It 'Should not be executed' {
#             Assert-MockCalled -CommandName New-Object -Exactly -Times 0 -Scope Context
#         }
#     }

#     Context 'When both the parameters TraceFlags and TraceFlagsToExclude are assigned a value.' {
#         BeforeAll {
#             $testParameters = $mockDefaultParameters1
#             $testParameters += @{
#                 TraceFlags          = '3228'
#                 TraceFlagsToExclude = '3228'
#             }
#         }

#         It 'Should throw the correct error' {
#             { Test-TargetResource @testParameters } | Should -Throw '(DRC0010)'
#         }

#         It 'Should not be executed' {
#             Assert-MockCalled -CommandName New-Object -Exactly -Times 0 -Scope Context
#         }
#     }
# }

#     Describe 'DSC_SqlTraceFlag\Set-TargetResource' -Tag 'Set' {
#     BeforeAll {
#                 $mockServerName = 'TestServer'
#                 $mockFakeServerName = 'FakeServer'
#                 $mockInstanceName1 = 'MSSQLSERVER'
#                 $mockInstanceName1Agent = 'SQLSERVERAGENT'
#                 $mockInstanceName2 = 'INST00'
#                 $mockInstanceName2Agent = 'SQLAgent$INST00'
#                 $mockInstanceName3 = 'INST01'
#                 $mockInstanceName3Agent = 'SQLAgent$INST01'

#                 $mockInvalidOperationForAlterMethod = $false

#                 $mockServerInstances = [System.Collections.ArrayList]::new()
#                 $mockServerInstances.Add($mockInstanceName1) | Out-Null
#                 $mockServerInstances.Add($mockInstanceName2) | Out-Null

#                     # The Trailing spaces in these here strings are ment to be there. Do not remove!
#                 $mockStartupParametersInstance1 = @"
# -dC:\Program Files\Microsoft SQL Server\MSSQL15.INST00\MSSQL\DATA\master.mdf;-eC:\Program Files\Microsoft SQL
# Server\MSSQL15.INST00\MSSQL\Log\ERRORLOG;-lC:\Program Files\Microsoft SQL
# Server\MSSQL15.INST00\MSSQL\DATA\mastlog.ldf;-T3226;-T1802
# "@
#                 $mockStartupParametersInstance2 = @"
# -dC:\Program Files\Microsoft SQL Server\MSSQL15.INST00\MSSQL\DATA\master.mdf;-eC:\Program Files\Microsoft SQL
# Server\MSSQL15.INST00\MSSQL\Log\ERRORLOG;-lC:\Program Files\Microsoft SQL
# Server\MSSQL15.INST00\MSSQL\DATA\mastlog.ldf
# "@

#                 # Default parameters that are used for the It-blocks
#                 $mockDefaultParameters1 = @{
#                     InstanceName = $mockInstanceName1
#                     ServerName   = $mockServerName
#                 }

#                 $mockInst00Parameters = @{
#                     InstanceName = $mockInstanceName2
#                     ServerName   = $mockServerName
#                 }

#                 $mockInst01Parameters = @{
#                     InstanceName = $mockInstanceName3
#                     ServerName   = $mockServerName
#                 }

#                 $mockNonExistServerParameters = @{
#                     InstanceName = $mockInstanceName1
#                     ServerName   = $mockFakeServerName
#                 }

#                 $mockNewObject_ParameterFilter_RealServerName = {
#                     $ServerName -eq $mockServerName
#                 }

#                 $mockNewObject_ParameterFilter_FakeServerName = {
#                     $ServerName -eq $mockFakeServerName
#                 }

#                 $script:mockMethodAlterRan = $false
#                 $script:mockMethodAlterValue = ''

#                 #region Function mocks
#                 $mockSmoWmiManagedComputer = {
#                     $mockServerObjectHashtable = @{
#                         State = 'Existing'
#                         Name = $mockServerName
#                         ServerInstances = $mockServerInstances
#                     }

#                     class service
#                     {
#                         [string]$Name
#                         [string]$ServiceState
#                         [string]$StartupParameters
#                     }

#                     $Services = [System.Collections.ArrayList]::new()

#                     $service1 = [service]::new()
#                     $service1.Name = $mockInstanceName1
#                     $service1.ServiceState = 'Running'
#                     $service1.StartupParameters = $mockStartupParametersInstance1

#                     $Services.Add($service1) | Out-Null

#                     $service2 = [service]::new()
#                     $service2.Name = $mockInstanceName1Agent
#                     $service2.ServiceState = 'Running'
#                     $service2.StartupParameters = ''

#                     $Services.Add($service2) | Out-Null

#                     $service3 = [service]::new()
#                     $service3.Name = 'MSSQL${0}' -f $mockInstanceName2
#                     $service3.ServiceState = 'Running'
#                     $service3.StartupParameters = $mockStartupParametersInstance2

#                     $Services.Add($service3) | Out-Null

#                     $service4 = [service]::new()
#                     $service4.Name = 'SQLAgent${0}' -f $mockInstanceName2Agent
#                     $service4.ServiceState = 'Stopped'
#                     $service4.StartupParameters = ''

#                     $Services.Add($service4) | Out-Null

#                     $ServerServices = [System.Collections.ArrayList]::new()

#                     foreach ($mockService in $Services)
#                     {
#                         $mockService | Add-Member -MemberType ScriptMethod -Name Alter -Value {
#                             $script:mockMethodAlterRan = $true
#                             $script:mockMethodAlterValue = $this.StartupParameters
#                         } -PassThru
#                         $ServerServices.Add( $mockService) | Out-Null
#                     }

#                     $mockServerObjectHashtable += @{
#                         Services = $ServerServices
#                     }
#                     $mockServerObject = [PSCustomObject]$mockServerObjectHashtable

#                     return @($mockServerObject)
#                 }
#         Mock -CommandName New-Object -MockWith $mockSmoWmiManagedComputer
#         Mock -CommandName Restart-SqlService -ModuleName $script:dscResourceName
#         Mock -CommandName Import-SQLPSModule
#     }

#     Context 'When the system is not in the desired state and ensure is set to Absent with existing traceflag' {
#         BeforeAll {
#             $testParameters = $mockDefaultParameters1
#             $testParameters += @{
#                 TraceFlags = @()
#             }
#         }

#         It 'Should not throw when calling the alter method' {
#             { Set-TargetResource @testParameters } | Should -Not -Throw
#             $script:mockMethodAlterRan | Should -BeTrue -Because 'Alter should run'
#             $script:mockMethodAlterValue | Should -Be @"
# -dC:\Program Files\Microsoft SQL Server\MSSQL15.INST00\MSSQL\DATA\master.mdf;-eC:\Program Files\Microsoft SQL
# Server\MSSQL15.INST00\MSSQL\Log\ERRORLOG;-lC:\Program Files\Microsoft SQL
# Server\MSSQL15.INST00\MSSQL\DATA\mastlog.ldf
# "@ -Because 'Alter must change the value correct'

#             Assert-MockCalled -CommandName New-Object -Exactly -Times 1 -Scope It
#         }
#     }

#     Context 'When the system is not in the desired state and ensure is set to Absent without existing traceflag' {
#         BeforeAll {
#             $testParameters = $mockInst00Parameters
#             $testParameters += @{
#                 TraceFlags = '3228'
#             }
#         }

#         It 'Should not throw when calling the alter method' {
#             { Set-TargetResource @testParameters } | Should -Not -Throw
#             $script:mockMethodAlterRan | Should -BeTrue -Because 'Alter should run'
#             $script:mockMethodAlterValue | Should -Be @"
# -dC:\Program Files\Microsoft SQL Server\MSSQL15.INST00\MSSQL\DATA\master.mdf;-eC:\Program Files\Microsoft SQL
# Server\MSSQL15.INST00\MSSQL\Log\ERRORLOG;-lC:\Program Files\Microsoft SQL
# Server\MSSQL15.INST00\MSSQL\DATA\mastlog.ldf;-T3228
# "@ -Because 'Alter must change the value correct'

#             Assert-MockCalled -CommandName New-Object -Exactly -Times 1 -Scope It
#         }
#     }

#     Context 'When the system is not in the desired state and ensure is set to Present and `$TraceFlags does not match the actual TraceFlags with existing traceflag' {
#         BeforeAll {
#             $testParameters = $mockDefaultParameters1
#             $testParameters += @{
#                 TraceFlags = '3228'
#             }
#         }

#         It 'Should not throw when calling the alter method' {
#             { Set-TargetResource @testParameters } | Should -Not -Throw
#             $script:mockMethodAlterRan | Should -BeTrue -Because 'Alter should run'
#             $script:mockMethodAlterValue | Should -Be @"
# -dC:\Program Files\Microsoft SQL Server\MSSQL15.INST00\MSSQL\DATA\master.mdf;-eC:\Program Files\Microsoft SQL
# Server\MSSQL15.INST00\MSSQL\Log\ERRORLOG;-lC:\Program Files\Microsoft SQL
# Server\MSSQL15.INST00\MSSQL\DATA\mastlog.ldf;-T3228
# "@ -Because 'Alter must change the value correct'

#             Assert-MockCalled -CommandName New-Object -Exactly -Times 1 -Scope It
#         }
#     }

#     Context 'When the system is not in the desired state and ensure is set to Present and `$TraceFlags does not match the actual TraceFlags without existing traceflag' {
#         BeforeAll {
#             $testParameters = $mockInst00Parameters
#             $testParameters += @{
#                 TraceFlags = '3228'
#             }
#         }

#         It 'Should not throw when calling the alter method' {
#             { Set-TargetResource @testParameters } | Should -Not -Throw
#             $script:mockMethodAlterRan | Should -BeTrue -Because 'Alter should run'
#             $script:mockMethodAlterValue | Should -Be @"
# -dC:\Program Files\Microsoft SQL Server\MSSQL15.INST00\MSSQL\DATA\master.mdf;-eC:\Program Files\Microsoft SQL
# Server\MSSQL15.INST00\MSSQL\Log\ERRORLOG;-lC:\Program Files\Microsoft SQL
# Server\MSSQL15.INST00\MSSQL\DATA\mastlog.ldf;-T3228
# "@ -Because 'Alter must change the value correct'

#             Assert-MockCalled -CommandName New-Object -Exactly -Times 1 -Scope It
#         }
#     }

#     Context 'When the system is not in the desired state and ensure is set to Present and `$TraceFlagsToInclude is not in TraceFlags with existing traceflag' {
#         BeforeAll {
#             $testParameters = $mockDefaultParameters1
#             $testParameters += @{
#                 TraceFlagsToInclude = '3228'
#             }
#         }

#         It 'Should not throw when calling the alter method' {
#             { Set-TargetResource @testParameters } | Should -Not -Throw
#             $script:mockMethodAlterRan | Should -BeTrue
#             $script:mockMethodAlterValue | Should -Be @"
# -dC:\Program Files\Microsoft SQL Server\MSSQL15.INST00\MSSQL\DATA\master.mdf;-eC:\Program Files\Microsoft SQL
# Server\MSSQL15.INST00\MSSQL\Log\ERRORLOG;-lC:\Program Files\Microsoft SQL
# Server\MSSQL15.INST00\MSSQL\DATA\mastlog.ldf;-T3226;-T1802;-T3228
# "@

#             Assert-MockCalled -CommandName New-Object -Exactly -Times 2 -Scope It
#         }
#     }

#     Context 'When the system is not in the desired state and ensure is set to Present and `$TraceFlagsToInclude is not in TraceFlags without existing traceflag' {
#         BeforeAll {
#             $testParameters = $mockInst00Parameters
#             $testParameters += @{
#                 TraceFlagsToInclude = '3228'
#             }
#         }

#         It 'Should not throw when calling the alter method' {
#             { Set-TargetResource @testParameters } | Should -Not -Throw
#             $script:mockMethodAlterRan | Should -BeTrue
#             $script:mockMethodAlterValue | Should -Be @"
# -dC:\Program Files\Microsoft SQL Server\MSSQL15.INST00\MSSQL\DATA\master.mdf;-eC:\Program Files\Microsoft SQL
# Server\MSSQL15.INST00\MSSQL\Log\ERRORLOG;-lC:\Program Files\Microsoft SQL
# Server\MSSQL15.INST00\MSSQL\DATA\mastlog.ldf;-T3228
# "@

#             Assert-MockCalled -CommandName New-Object -Exactly -Times 2 -Scope It
#         }
#     }

#     Context 'When the system is not in the desired state and ensure is set to Present and `$TraceFlagsToExclude is in TraceFlags' {
#         BeforeAll {
#             $testParameters = $mockDefaultParameters1
#             $testParameters += @{
#                 TraceFlagsToExclude = '1802'
#             }
#         }

#         It 'Should not throw when calling the alter method' {
#             { Set-TargetResource @testParameters } | Should -Not -Throw
#             $script:mockMethodAlterRan | Should -BeTrue
#             $script:mockMethodAlterValue | Should -Be @"
# -dC:\Program Files\Microsoft SQL Server\MSSQL15.INST00\MSSQL\DATA\master.mdf;-eC:\Program Files\Microsoft SQL
# Server\MSSQL15.INST00\MSSQL\Log\ERRORLOG;-lC:\Program Files\Microsoft SQL
# Server\MSSQL15.INST00\MSSQL\DATA\mastlog.ldf;-T3226
# "@

#             Assert-MockCalled -CommandName New-Object -Exactly -Times 2 -Scope It
#         }
#     }

#     Context 'When the system is not in the desired state and ensure is set to Present and `$TraceFlags does not match the actual TraceFlags' {
#         BeforeAll {
#             $testParameters = $mockDefaultParameters1
#             $testParameters += @{
#                 TraceFlags = '3228'
#                 RestartService = $true
#             }
#         }

#         It 'Should not throw when calling the restart method' {
#             { Set-TargetResource @testParameters } | Should -Not -Throw
#             $script:mockMethodAlterRan | Should -BeTrue
#             $script:mockMethodAlterValue | Should -Be @"
# -dC:\Program Files\Microsoft SQL Server\MSSQL15.INST00\MSSQL\DATA\master.mdf;-eC:\Program Files\Microsoft SQL
# Server\MSSQL15.INST00\MSSQL\Log\ERRORLOG;-lC:\Program Files\Microsoft SQL
# Server\MSSQL15.INST00\MSSQL\DATA\mastlog.ldf;-T3228
# "@

#             Assert-MockCalled -CommandName Restart-SqlService -Exactly -Times 1 -Scope It
#             Assert-MockCalled -CommandName New-Object -Exactly -Times 1 -Scope It
#         }
#     }

#     Context 'When both the parameters TraceFlags and TraceFlagsToInclude are assigned a value.' {
#         BeforeAll {
#             $testParameters = $mockDefaultParameters1
#             $testParameters += @{
#                 TraceFlags          = '3228'
#                 TraceFlagsToInclude = '3228'
#             }
#         }

#         It 'Should throw the correct error' {
#             { Set-TargetResource @testParameters } | Should -Throw '(DRC0010)'
#         }

#         It 'Should not be executed' {
#             Assert-MockCalled -CommandName New-Object -Exactly -Times 0 -Scope Context
#         }
#     }

#     Context 'When both the parameters TraceFlags and TraceFlagsToExclude are assigned a value.' {
#         BeforeAll {
#             $testParameters = $mockDefaultParameters1
#             $testParameters += @{
#                 TraceFlags          = '3228'
#                 TraceFlagsToExclude = '3228'
#             }
#         }

#         It 'Should throw the correct error' {
#             { Set-TargetResource @testParameters } | Should -Throw '(DRC0010)'
#         }

#         It 'Should not be executed' {
#             Assert-MockCalled -CommandName New-Object -Exactly -Times 0 -Scope Context
#         }
#     }

#     Context 'For a nonexistent instance' {
#         BeforeAll {
#             $testParameters = $mockInst01Parameters
#         }
#         It 'Should throw for incorrect parameters' {
#             { Set-TargetResource @testParameters } |
#                 Should -Throw -ExpectedMessage ("Was unable to connect to WMI information '{0}' in '{1}'." -f $mockInstanceName3, $mockServerName)
#         }
#     }

#     Context 'For a nonexistent server' {
#         BeforeAll {
#             $testParameters = $mockNonExistServerParameters
#             Mock -CommandName New-Object -MockWith {
#                 return $null
#             } -ParameterFilter $mockNewObject_ParameterFilter_FakeServerName
#         }
#         It 'Should throw for incorrect parameters' {
#             { Set-TargetResource @testParameters } |
#             Should -Throw -ExpectedMessage ("Was unable to connect to ComputerManagement '{0}'." -f $mockFakeServerName)
#         }
#     }
# }
