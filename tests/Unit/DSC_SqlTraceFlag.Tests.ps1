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
    $script:dscResourceName = 'DSC_SqlTraceFlag'

    $env:SqlServerDscCI = $true

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

    Remove-Item -Path 'env:SqlServerDscCI'
}

Describe 'DSC_SqlTraceFlag\Get-TargetResource' -Tag 'Get' {
    BeforeAll {
        $mockSmoWmiManagedComputer = {
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

        Mock -CommandName Import-SqlDscPreferredModule

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
            InModuleScope -ScriptBlock {
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

Describe 'DSC_SqlTraceFlag\Test-TargetResource' -Tag 'Test' {
    BeforeAll {
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
            $script:mockTestTargetResourceParameters = $script:mockDefaultParameters.Clone()
        }
    }

    Context 'When the system is in the desired state' {
        Context 'When there should be no trace flags' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        ServerName          = 'TestServer'
                        InstanceName        = 'MSSQLSERVER'
                        TraceFlags          = @()
                    }
                }
            }

            It 'Should return true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.ClearAllTraceFlags = $true

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeTrue -Because 'it should return that the trace flags are in the desired state'
                }
            }

            It 'Should call the correct mock' {
                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope Context
            }
        }

        Context 'When the correct trace flags exist' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        ServerName          = 'TestServer'
                        InstanceName        = 'MSSQLSERVER'
                        TraceFlags          = @('1802', '3226')
                    }
                }
            }

            It 'Should return true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    <#
                        The trace flags are in reverse order than the mock to
                        make sure the order does not matter.
                    #>
                    $mockTestTargetResourceParameters.TraceFlags = @('3226', '1802')

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeTrue -Because 'it should return that the trace flags are in the desired state'
                }
            }

            It 'Should call the correct mock' {
                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope Context
            }
        }

        Context 'When adding a trace flag and the trace flag already exist' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        ServerName          = 'TestServer'
                        InstanceName        = 'MSSQLSERVER'
                        TraceFlags          = @('1802', '3226')
                    }
                }
            }

            It 'Should return true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.TraceFlagsToInclude = '1802'

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeTrue -Because 'it should return that the trace flags are in the desired state'
                }
            }

            It 'Should call the correct mock' {
                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope Context
            }
        }

        Context 'When removing an existing trace flag' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        ServerName          = 'TestServer'
                        InstanceName        = 'MSSQLSERVER'
                        TraceFlags          = @('1802', '3226')
                    }
                }
            }

            It 'Should return true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.TraceFlagsToExclude = '4199'

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeTrue -Because 'it should return that the trace flags are in the desired state'
                }
            }

            It 'Should call the correct mock' {
                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope Context
            }
        }

        Context 'When removing an existing trace flag, when there are no existent trace flags' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        ServerName          = 'TestServer'
                        InstanceName        = 'MSSQLSERVER'
                        TraceFlags          = @()
                    }
                }
            }

            It 'Should return true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.TraceFlagsToExclude = '4199'

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeTrue -Because 'it should return that the trace flags are in the desired state'
                }
            }

            It 'Should call the correct mock' {
                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope Context
            }
        }

        Context 'When both adding a new trace flag and removing an existing trace flag' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        ServerName          = 'TestServer'
                        InstanceName        = 'MSSQLSERVER'
                        TraceFlags          = @('1802', '3226')
                    }
                }
            }

            It 'Should return true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.TraceFlagsToInclude = '3226'
                    $mockTestTargetResourceParameters.TraceFlagsToExclude = '4199'

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeTrue -Because 'it should return that the trace flags are in the desired state'
                }
            }

            It 'Should call the correct mock' {
                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope Context
            }
        }
    }

    Context 'When the system is not in the desired state' {
        Context 'When there should be no trace flags' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        ServerName          = 'TestServer'
                        InstanceName        = 'MSSQLSERVER'
                        TraceFlags          = @('1802', '3226')
                    }
                }
            }

            It 'Should return false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.ClearAllTraceFlags = $true

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeFalse -Because 'it should return that the trace flags are not in the desired state'
                }
            }

            It 'Should call the correct mock' {
                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope Context
            }
        }

        Context 'When specifying one trace flag that does not match' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        ServerName          = 'TestServer'
                        InstanceName        = 'MSSQLSERVER'
                        TraceFlags          = @('1802', '3226')
                    }
                }
            }

            It 'Should return false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.TraceFlags = '4137'

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeFalse -Because 'it should return that the trace flags are not in the desired state'
                }
            }

            It 'Should call the correct mock' {
                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope Context
            }
        }

        Context 'When specified several trace flags that does not match' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        ServerName          = 'TestServer'
                        InstanceName        = 'MSSQLSERVER'
                        TraceFlags          = @('1802', '3226')
                    }
                }
            }

            It 'Should return false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.TraceFlags = @('4137', '4199')

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeFalse -Because 'it should return that the trace flags are not in the desired state'
                }
            }

            It 'Should call the correct mock' {
                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope Context
            }
        }

        Context 'When specifying one trace flag that exist and one that does not exist' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        ServerName          = 'TestServer'
                        InstanceName        = 'MSSQLSERVER'
                        TraceFlags          = @('1802', '3226')
                    }
                }
            }

            It 'Should return false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.TraceFlags = @('1802', '4199')

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeFalse -Because 'it should return that the trace flags are not in the desired state'
                }
            }

            It 'Should call the correct mock' {
                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope Context
            }
        }

        Context 'When there are no existing trace flags' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        ServerName          = 'TestServer'
                        InstanceName        = 'MSSQLSERVER'
                        TraceFlags          = @()
                    }
                }
            }

            It 'Should return false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.TraceFlags = @('1802', '4199')

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeFalse -Because 'it should return that the trace flags are not in the desired state'
                }
            }

            It 'Should call the correct mock' {
                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope Context
            }
        }

        Context 'When adding an non-existent trace flag' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        ServerName          = 'TestServer'
                        InstanceName        = 'MSSQLSERVER'
                        TraceFlags          = @('1802', '3226')
                    }
                }
            }

            It 'Should return false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.TraceFlagsToInclude = '4199'

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeFalse -Because 'it should return that the trace flags are not in the desired state'
                }
            }

            It 'Should call the correct mock' {
                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope Context
            }
        }

        Context 'When adding an non-existent trace flag, when there are no existent trace flags' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        ServerName          = 'TestServer'
                        InstanceName        = 'MSSQLSERVER'
                        TraceFlags          = @()
                    }
                }
            }

            It 'Should return false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.TraceFlagsToInclude = '4199'

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeFalse -Because 'it should return that the trace flags are not in the desired state'
                }
            }

            It 'Should call the correct mock' {
                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope Context
            }
        }

        Context 'When removing an existing trace flag' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        ServerName          = 'TestServer'
                        InstanceName        = 'MSSQLSERVER'
                        TraceFlags          = @('1802', '3226')
                    }
                }
            }

            It 'Should return false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.TraceFlagsToExclude = '3226'

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeFalse -Because 'it should return that the trace flags are not in the desired state'
                }
            }

            It 'Should call the correct mock' {
                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope Context
            }
        }

        Context 'When both adding a new trace flag and removing an existing trace flag' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        ServerName          = 'TestServer'
                        InstanceName        = 'MSSQLSERVER'
                        TraceFlags          = @('1802', '3226')
                    }
                }
            }

            It 'Should return false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.TraceFlagsToInclude = '4199'
                    $mockTestTargetResourceParameters.TraceFlagsToExclude = '3226'

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeFalse -Because 'it should return that the trace flags are not in the desired state'
                }
            }

            It 'Should call the correct mock' {
                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope Context
            }
        }
    }

    Context 'When both the parameters TraceFlags and TraceFlagsToInclude are assigned a value' {
        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestTargetResourceParameters.TraceFlags = '3226'
                $mockTestTargetResourceParameters.TraceFlagsToInclude = '3226'

                { Test-TargetResource @mockTestTargetResourceParameters } | Should -Throw -ExpectedMessage '*(DRC0010)*'
            }
        }
    }

    Context 'When both the parameters TraceFlags and TraceFlagsToExclude are assigned a value' {
        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestTargetResourceParameters.TraceFlags = '3226'
                $mockTestTargetResourceParameters.TraceFlagsToExclude = '3226'

                { Test-TargetResource @mockTestTargetResourceParameters } | Should -Throw -ExpectedMessage '*(DRC0010)*'
            }
        }
    }
}

Describe 'DSC_SqlTraceFlag\Set-TargetResource' -Tag 'Set' {
    BeforeAll {
        $mockSmoWmiManagedComputer = {
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

            $service1.StartupParameters = @"
-dC:\Program Files\Microsoft SQL Server\MSSQL15.INST00\MSSQL\DATA\master.mdf;-eC:\Program Files\Microsoft SQL
Server\MSSQL15.INST00\MSSQL\Log\ERRORLOG;-lC:\Program Files\Microsoft SQL
Server\MSSQL15.INST00\MSSQL\DATA\mastlog.ldf;-T3226;-T1802
"@

            $Services.Add($service1) | Out-Null

            $service2 = [service]::new()
            $service2.Name = 'SQLSERVERAGENT'
            $service2.ServiceState = 'Running'
            $service2.StartupParameters = ''

            $Services.Add($service2) | Out-Null

            $service3 = [service]::new()
            $service3.Name = 'MSSQL$INST00'
            $service3.ServiceState = 'Running'

            $service3.StartupParameters = @"
-dC:\Program Files\Microsoft SQL Server\MSSQL15.INST00\MSSQL\DATA\master.mdf;-eC:\Program Files\Microsoft SQL
Server\MSSQL15.INST00\MSSQL\Log\ERRORLOG;-lC:\Program Files\Microsoft SQL
Server\MSSQL15.INST00\MSSQL\DATA\mastlog.ldf
"@

            $Services.Add($service3) | Out-Null

            $service4 = [service]::new()
            $service4.Name = 'SQLAgent$SQLAgent$INST00'
            $service4.ServiceState = 'Stopped'
            $service4.StartupParameters = ''

            $Services.Add($service4) | Out-Null

            $ServerServices = [System.Collections.ArrayList]::new()

            foreach ($mockService in $Services)
            {
                $mockService | Add-Member -MemberType ScriptMethod -Name Alter -Value {
                    $_.StartupParameters = $this.StartupParameters

                    InModuleScope -Parameters $_ -ScriptBlock {
                        $script:mockMethodAlterRan = $true
                        $script:mockMethodAlterValue = $StartupParameters
                    }
                } -PassThru

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

        Mock -CommandName Import-SqlDscPreferredModule
        Mock -CommandName Restart-SqlService

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
            $script:mockMethodAlterRan = $false
            $script:mockSetTargetResourceParameters = $script:mockDefaultParameters.Clone()
        }
    }

    Context 'When the system is not in the desired state' {
        Context 'When no trace flag parameter is assigned' {
            It 'Should not throw and set no value' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                    $script:mockMethodAlterRan | Should -BeFalse -Because 'no TraceFlag parameter was set'
                }

                Should -Invoke -CommandName New-Object -Exactly -Times 0 -Scope It
            }
        }

        Context 'When there should be no trace flags' {
            It 'Should not throw and set the correct value' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters.ClearAllTraceFlags = $true

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                    $script:mockMethodAlterRan | Should -BeTrue -Because 'method Alter() should run'

                    $script:mockMethodAlterValue | Should -Be @"
-dC:\Program Files\Microsoft SQL Server\MSSQL15.INST00\MSSQL\DATA\master.mdf;-eC:\Program Files\Microsoft SQL
Server\MSSQL15.INST00\MSSQL\Log\ERRORLOG;-lC:\Program Files\Microsoft SQL
Server\MSSQL15.INST00\MSSQL\DATA\mastlog.ldf
"@ -Because 'Alter must change the value correct'
                }

                Should -Invoke -CommandName New-Object -Exactly -Times 1 -Scope It
            }
        }

        Context 'When specifying a trace flag' {
            It 'Should not throw and set the correct value' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters.TraceFlags = '3228'

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                    $script:mockMethodAlterRan | Should -BeTrue -Because 'method Alter() should run'

                    $script:mockMethodAlterValue | Should -Be @"
-dC:\Program Files\Microsoft SQL Server\MSSQL15.INST00\MSSQL\DATA\master.mdf;-eC:\Program Files\Microsoft SQL
Server\MSSQL15.INST00\MSSQL\Log\ERRORLOG;-lC:\Program Files\Microsoft SQL
Server\MSSQL15.INST00\MSSQL\DATA\mastlog.ldf;-T3228
"@ -Because 'Alter must change the value correct'
                }

                Should -Invoke -CommandName New-Object -Exactly -Times 1 -Scope It
            }
        }

        Context 'When adding a trace flag' {
            It 'Should not throw when calling the alter method' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters.InstanceName = 'INST00'
                    $mockSetTargetResourceParameters.TraceFlagsToInclude = '3228'

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                    $script:mockMethodAlterRan | Should -BeTrue -Because 'method Alter() should run'

                    $script:mockMethodAlterValue | Should -Be @"
-dC:\Program Files\Microsoft SQL Server\MSSQL15.INST00\MSSQL\DATA\master.mdf;-eC:\Program Files\Microsoft SQL
Server\MSSQL15.INST00\MSSQL\Log\ERRORLOG;-lC:\Program Files\Microsoft SQL
Server\MSSQL15.INST00\MSSQL\DATA\mastlog.ldf;-T3228
"@
                }

                # New-Object is also called in Get-TargetResource since there is no mock for Get-TargetResource.
                Should -Invoke -CommandName New-Object -Exactly -Times 2 -Scope It
            }
        }

        Context 'When adding a trace flag to existent trace flags' {
            It 'Should not throw when calling the alter method' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters.TraceFlagsToInclude = '3228'

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                    $script:mockMethodAlterRan | Should -BeTrue -Because 'method Alter() should run'

                    $script:mockMethodAlterValue | Should -Be @"
-dC:\Program Files\Microsoft SQL Server\MSSQL15.INST00\MSSQL\DATA\master.mdf;-eC:\Program Files\Microsoft SQL
Server\MSSQL15.INST00\MSSQL\Log\ERRORLOG;-lC:\Program Files\Microsoft SQL
Server\MSSQL15.INST00\MSSQL\DATA\mastlog.ldf;-T3226;-T1802;-T3228
"@
                }

                # New-Object is also called in Get-TargetResource since there is no mock for Get-TargetResource.
                Should -Invoke -CommandName New-Object -Exactly -Times 2 -Scope It
            }
        }

        Context 'When removing a trace flag' {
            It 'Should not throw when calling the alter method' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters.TraceFlagsToExclude = '1802'

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                    $script:mockMethodAlterRan | Should -BeTrue -Because 'method Alter() should run'

                    $script:mockMethodAlterValue | Should -Be @"
-dC:\Program Files\Microsoft SQL Server\MSSQL15.INST00\MSSQL\DATA\master.mdf;-eC:\Program Files\Microsoft SQL
Server\MSSQL15.INST00\MSSQL\Log\ERRORLOG;-lC:\Program Files\Microsoft SQL
Server\MSSQL15.INST00\MSSQL\DATA\mastlog.ldf;-T3226
"@
                }

                # New-Object is also called in Get-TargetResource since there is no mock for Get-TargetResource.
                Should -Invoke -CommandName New-Object -Exactly -Times 2 -Scope It
            }
        }

        Context 'When removing several trace flags' {
            It 'Should not throw when calling the alter method' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters.TraceFlagsToExclude = '1802', '3226'

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                    $script:mockMethodAlterRan | Should -BeTrue -Because 'method Alter() should run'

                    $script:mockMethodAlterValue | Should -Be @"
-dC:\Program Files\Microsoft SQL Server\MSSQL15.INST00\MSSQL\DATA\master.mdf;-eC:\Program Files\Microsoft SQL
Server\MSSQL15.INST00\MSSQL\Log\ERRORLOG;-lC:\Program Files\Microsoft SQL
Server\MSSQL15.INST00\MSSQL\DATA\mastlog.ldf
"@
                }

                # New-Object is also called in Get-TargetResource since there is no mock for Get-TargetResource.
                Should -Invoke -CommandName New-Object -Exactly -Times 2 -Scope It
            }
        }

        Context 'When restarting the SQL Server service after modifying trace flags' {
            It 'Should not throw when calling the alter method' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters.TraceFlags = '4199'
                    $mockSetTargetResourceParameters.RestartService = $true

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                    $script:mockMethodAlterRan | Should -BeTrue -Because 'method Alter() should run'

                    $script:mockMethodAlterValue | Should -Be @"
-dC:\Program Files\Microsoft SQL Server\MSSQL15.INST00\MSSQL\DATA\master.mdf;-eC:\Program Files\Microsoft SQL
Server\MSSQL15.INST00\MSSQL\Log\ERRORLOG;-lC:\Program Files\Microsoft SQL
Server\MSSQL15.INST00\MSSQL\DATA\mastlog.ldf;-T4199
"@
                }

                # New-Object is also called in Get-TargetResource since there is no mock for Get-TargetResource.
                Should -Invoke -CommandName New-Object -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Restart-SqlService -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When both the parameters TraceFlags and TraceFlagsToInclude are assigned a value' {
        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockSetTargetResourceParameters.TraceFlags = '4199'
                $mockSetTargetResourceParameters.TraceFlagsToInclude = '4037'

                { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw -ExpectedMessage '*(DRC0010)*'
            }
        }

        It 'Should not call mock New-Object' {
            Should -Invoke -CommandName New-Object -Exactly -Times 0 -Scope Context
        }
    }

    Context 'When both the parameters TraceFlags and TraceFlagsToExclude are assigned a value' {
        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockSetTargetResourceParameters.TraceFlags = '4199'
                $mockSetTargetResourceParameters.TraceFlagsToExclude = '4037'

                { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw -ExpectedMessage '*(DRC0010)*'
            }
        }

        It 'Should not call mock New-Object' {
            Should -Invoke -CommandName New-Object -Exactly -Times 0 -Scope Context
        }
    }

    Context 'For a nonexistent instance' {
        It 'Should throw for incorrect parameters' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockSetTargetResourceParameters.InstanceName = 'INST01'

                $mockErrorMessage = $script:localizedData.NotConnectedToWMI -f 'INST01', 'TestServer'

                { Test-TargetResource @mockSetTargetResourceParameters } |
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

                $mockSetTargetResourceParameters.ServerName = 'FakeServer'
                $mockSetTargetResourceParameters.InstanceName = 'INST00' # Instance exist

                $mockErrorMessage = $script:localizedData.NotConnectedToComputerManagement -f 'FakeServer'

                { Test-TargetResource @mockSetTargetResourceParameters } |
                    Should -Throw -ExpectedMessage ('*' + $mockErrorMessage)            }
        }
    }
}
