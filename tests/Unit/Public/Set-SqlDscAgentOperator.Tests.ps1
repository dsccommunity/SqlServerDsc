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
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies have not been resolved, this will throw an error.
            Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
        }
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
    }
}

BeforeAll {
    $script:moduleName = 'SqlServerDsc'

    $env:SqlServerDscCI = $true

    Import-Module -Name $script:moduleName -Force -ErrorAction 'Stop'

    # Load SMO stub types
    Add-Type -Path "$PSScriptRoot/../Stubs/SMO.cs"

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:moduleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Remove-Item -Path 'Env:\SqlServerDscCI' -ErrorAction 'SilentlyContinue'

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:moduleName -All | Remove-Module -Force
}

Describe 'Set-SqlDscAgentOperator' -Tag 'Public' {
    Context 'When command has correct parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = 'ByName'
                ExpectedParameters = '-ServerObject <Server> -Name <string> [-EmailAddress <string>] [-CategoryName <string>] [-NetSendAddress <string>] [-PagerAddress <string>] [-PagerDays <WeekDays>] [-SaturdayPagerEndTime <timespan>] [-SaturdayPagerStartTime <timespan>] [-SundayPagerEndTime <timespan>] [-SundayPagerStartTime <timespan>] [-WeekdayPagerEndTime <timespan>] [-WeekdayPagerStartTime <timespan>] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
            @{
                ExpectedParameterSetName = 'ByObject'
                ExpectedParameters = '-OperatorObject <Operator> [-EmailAddress <string>] [-CategoryName <string>] [-NetSendAddress <string>] [-PagerAddress <string>] [-PagerDays <WeekDays>] [-SaturdayPagerEndTime <timespan>] [-SaturdayPagerStartTime <timespan>] [-SundayPagerEndTime <timespan>] [-SundayPagerStartTime <timespan>] [-WeekdayPagerEndTime <timespan>] [-WeekdayPagerStartTime <timespan>] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Set-SqlDscAgentOperator').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )
            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }
    }

    Context 'When command has correct parameter properties' {
        It 'Should have ServerObject as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Set-SqlDscAgentOperator').Parameters['ServerObject']
            $byNameParameterSet = $parameterInfo.ParameterSets['ByName']
            $byNameParameterSet.IsMandatory | Should -BeTrue
        }

        It 'Should have ServerObject accept pipeline input' {
            $parameterInfo = (Get-Command -Name 'Set-SqlDscAgentOperator').Parameters['ServerObject']
            $parameterInfo.Attributes.ValueFromPipeline | Should -BeTrue
        }

        It 'Should have OperatorObject as a mandatory parameter in ByObject parameter set' {
            $parameterInfo = (Get-Command -Name 'Set-SqlDscAgentOperator').Parameters['OperatorObject']
            $byObjectParameterSet = $parameterInfo.ParameterSets['ByObject']
            $byObjectParameterSet.IsMandatory | Should -BeTrue
        }

        It 'Should have OperatorObject accept pipeline input in ByObject parameter set' {
            $parameterInfo = (Get-Command -Name 'Set-SqlDscAgentOperator').Parameters['OperatorObject']
            $parameterInfo.Attributes.ValueFromPipeline | Should -BeTrue
        }

        It 'Should have Name as a mandatory parameter in ByName parameter set' {
            $parameterInfo = (Get-Command -Name 'Set-SqlDscAgentOperator').Parameters['Name']
            $byNameParameterSet = $parameterInfo.ParameterSets['ByName']
            $byNameParameterSet.IsMandatory | Should -BeTrue
        }
    }

    Context 'When parameter validation is performed' {
        It 'Should throw when no settable parameters are provided' {
            $mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()

            { Set-SqlDscAgentOperator -ServerObject $mockServerObject -Name 'TestOperator' -Force } | Should -Throw -ExpectedMessage '*At least one*'
        }

        It 'Should successfully execute when at least one settable parameter is provided' {
            # Create proper mock structure
            $mockOperator = [Microsoft.SqlServer.Management.Smo.Agent.Operator]::CreateTypeInstance()
            $mockOperator.Name = 'TestOperator'
            $mockOperator.EmailAddress = 'old@contoso.com'

            $mockOperatorCollection = [Microsoft.SqlServer.Management.Smo.Agent.OperatorCollection]::CreateTypeInstance()
            $mockOperatorCollection.Add($mockOperator)
            $mockOperatorCollection | Add-Member -MemberType ScriptMethod -Name 'Refresh' -Value { } -Force

            $mockJobServer = [Microsoft.SqlServer.Management.Smo.Agent.JobServer]::CreateTypeInstance()
            $mockJobServer.Operators = $mockOperatorCollection

            $mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()
            $mockServerObject.JobServer = $mockJobServer
            $mockServerObject.InstanceName = 'TestInstance'

            $mockMethodAlterCallCount = 0
            $mockOperator | Add-Member -MemberType ScriptMethod -Name 'Alter' -Value {
                $mockMethodAlterCallCount++
            } -Force

            Set-SqlDscAgentOperator -ServerObject $mockServerObject -Name 'TestOperator' -EmailAddress 'test@contoso.com' -WhatIf

            # Verify that WhatIf prevents Alter from being called
            $mockMethodAlterCallCount | Should -Be 0
            # Verify that the operator object is found and accessible
            $mockOperator.Name | Should -Be 'TestOperator'
        }
    }

    Context 'When updating operator using ByName parameter set' {
        BeforeAll {
            # Mock existing operator
            $script:mockOperator = [Microsoft.SqlServer.Management.Smo.Agent.Operator]::CreateTypeInstance()
            $script:mockOperator.Name = 'TestOperator'
            $script:mockOperator.EmailAddress = 'old@contoso.com'

            # Mock operator collection with existing operator
            $script:mockOperatorCollection = [Microsoft.SqlServer.Management.Smo.Agent.OperatorCollection]::CreateTypeInstance()
            $script:mockOperatorCollection.Add($script:mockOperator)

            # Mock JobServer object with mock refresh method
            $script:mockJobServer = [Microsoft.SqlServer.Management.Smo.Agent.JobServer]::CreateTypeInstance()
            $script:mockJobServer.Operators = $script:mockOperatorCollection
            $script:mockOperatorCollection | Add-Member -MemberType ScriptMethod -Name 'Refresh' -Value { } -Force

            # Mock server object
            $script:mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()
            $script:mockServerObject.JobServer = $script:mockJobServer
            $script:mockServerObject.InstanceName = 'TestInstance'

            $script:mockMethodAlterCallCount = 0
            $script:mockOperator | Add-Member -MemberType ScriptMethod -Name 'Alter' -Value {
                $script:mockMethodAlterCallCount++
            } -Force
        }

        It 'Should update operator email address when specified' {
            $script:mockMethodAlterCallCount = 0
            $script:mockOperator.EmailAddress = 'old@contoso.com'

            $null = Set-SqlDscAgentOperator -Force -ServerObject $script:mockServerObject -Name 'TestOperator' -EmailAddress 'new@contoso.com'

            $script:mockOperator.EmailAddress | Should -Be 'new@contoso.com'
            $script:mockMethodAlterCallCount | Should -Be 1
        }

        It 'Should update when email address is already correct (always set user-specified properties)' {
            $script:mockMethodAlterCallCount = 0
            $script:mockOperator.EmailAddress = 'correct@contoso.com'

            $null = Set-SqlDscAgentOperator -Force -ServerObject $script:mockServerObject -Name 'TestOperator' -EmailAddress 'correct@contoso.com'

            $script:mockMethodAlterCallCount | Should -Be 1
        }

        It 'Should throw when operator does not exist' {
            { Set-SqlDscAgentOperator -Force -ServerObject $script:mockServerObject -Name 'NonExistentOperator' -EmailAddress 'test@contoso.com' -ErrorAction 'Stop' } |
                Should -Throw -ExpectedMessage '*SQL Agent Operator ''NonExistentOperator'' was not found*'
        }

        Context 'When using parameter WhatIf' {
            It 'Should not call Alter method when using WhatIf' {
                $script:mockMethodAlterCallCount = 0
                $script:mockOperator.EmailAddress = 'old@contoso.com'

                $null = Set-SqlDscAgentOperator -WhatIf -ServerObject $script:mockServerObject -Name 'TestOperator' -EmailAddress 'new@contoso.com'

                $script:mockMethodAlterCallCount | Should -Be 0
            }
        }

        Context 'When passing parameter ServerObject over the pipeline' {
            It 'Should update operator email address using pipeline input' {
                $script:mockMethodAlterCallCount = 0
                $script:mockOperator.EmailAddress = 'old@contoso.com'

                $script:mockServerObject | Set-SqlDscAgentOperator -Force -Name 'TestOperator' -EmailAddress 'new@contoso.com'

                $script:mockOperator.EmailAddress | Should -Be 'new@contoso.com'
                $script:mockMethodAlterCallCount | Should -Be 1
            }
        }

        Context 'When updating operator with different properties' {
            It 'Should update operator with property <PropertyName> set correctly' -ForEach @(
                @{
                    PropertyName = 'EmailAddress'
                    PropertyValue = 'updated@contoso.com'
                    Parameters = @{ EmailAddress = 'updated@contoso.com' }
                }
                @{
                    PropertyName = 'CategoryName'
                    PropertyValue = 'UpdatedCategory'
                    Parameters = @{ CategoryName = 'UpdatedCategory' }
                }
                @{
                    PropertyName = 'NetSendAddress'
                    PropertyValue = 'COMPUTER02'
                    Parameters = @{ NetSendAddress = 'COMPUTER02' }
                }
                @{
                    PropertyName = 'PagerAddress'
                    PropertyValue = '555-987-6543'
                    Parameters = @{ PagerAddress = '555-987-6543' }
                }
                @{
                    PropertyName = 'PagerDays'
                    PropertyValue = 64 -bor 1 # Saturday and Sunday
                    Parameters = @{ PagerDays = 64 -bor 1 } # Saturday and Sunday
                }
                @{
                    PropertyName = 'SaturdayPagerEndTime'
                    PropertyValue = [System.TimeSpan]::new(20, 0, 0)
                    Parameters = @{ SaturdayPagerEndTime = [System.TimeSpan]::new(20, 0, 0) }
                }
                @{
                    PropertyName = 'SaturdayPagerStartTime'
                    PropertyValue = [System.TimeSpan]::new(9, 0, 0)
                    Parameters = @{ SaturdayPagerStartTime = [System.TimeSpan]::new(9, 0, 0) }
                }
                @{
                    PropertyName = 'SundayPagerEndTime'
                    PropertyValue = [System.TimeSpan]::new(19, 0, 0)
                    Parameters = @{ SundayPagerEndTime = [System.TimeSpan]::new(19, 0, 0) }
                }
                @{
                    PropertyName = 'SundayPagerStartTime'
                    PropertyValue = [System.TimeSpan]::new(10, 0, 0)
                    Parameters = @{ SundayPagerStartTime = [System.TimeSpan]::new(10, 0, 0) }
                }
                @{
                    PropertyName = 'WeekdayPagerEndTime'
                    PropertyValue = [System.TimeSpan]::new(18, 30, 0)
                    Parameters = @{ WeekdayPagerEndTime = [System.TimeSpan]::new(18, 30, 0) }
                }
                @{
                    PropertyName = 'WeekdayPagerStartTime'
                    PropertyValue = [System.TimeSpan]::new(7, 30, 0)
                    Parameters = @{ WeekdayPagerStartTime = [System.TimeSpan]::new(7, 30, 0) }
                }
            ) {
                # Reset counter and set initial values
                $script:mockMethodAlterCallCount = 0

                # Set different initial values to ensure the property is actually being updated
                switch ($PropertyName) {
                    'EmailAddress' { $script:mockOperator.EmailAddress = 'old@contoso.com' }
                    'CategoryName' { $script:mockOperator.CategoryName = 'OldCategory' }
                    'NetSendAddress' { $script:mockOperator.NetSendAddress = 'OLDCOMPUTER' }
                    'PagerAddress' { $script:mockOperator.PagerAddress = '555-000-0000' }
                    'PagerDays' { $script:mockOperator.PagerDays = [Microsoft.SqlServer.Management.Smo.Agent.WeekDays]::Weekdays }
                    'SaturdayPagerEndTime' { $script:mockOperator.SaturdayPagerEndTime = [System.TimeSpan]::new(17, 0, 0) }
                    'SaturdayPagerStartTime' { $script:mockOperator.SaturdayPagerStartTime = [System.TimeSpan]::new(8, 0, 0) }
                    'SundayPagerEndTime' { $script:mockOperator.SundayPagerEndTime = [System.TimeSpan]::new(16, 0, 0) }
                    'SundayPagerStartTime' { $script:mockOperator.SundayPagerStartTime = [System.TimeSpan]::new(9, 0, 0) }
                    'WeekdayPagerEndTime' { $script:mockOperator.WeekdayPagerEndTime = [System.TimeSpan]::new(17, 0, 0) }
                    'WeekdayPagerStartTime' { $script:mockOperator.WeekdayPagerStartTime = [System.TimeSpan]::new(8, 0, 0) }
                }

                # Create parameters hash with base parameters
                $testParameters = @{
                    Force = $true
                    ServerObject = $script:mockServerObject
                    Name = 'TestOperator'
                }

                # Add the specific property being tested
                $testParameters += $Parameters

                Set-SqlDscAgentOperator @testParameters

                # Verify the operator was updated
                $script:mockMethodAlterCallCount | Should -Be 1

                # Verify the property was set correctly
                $script:mockOperator.$PropertyName | Should -Be $PropertyValue
            }
        }

        Context 'When updating operator with multiple properties' {
            It 'Should update operator with all properties set correctly' {
                # Reset counter and set initial values
                $script:mockMethodAlterCallCount = 0
                $script:mockOperator.EmailAddress = 'old@contoso.com'
                $script:mockOperator.CategoryName = 'OldCategory'
                $script:mockOperator.NetSendAddress = 'OLDCOMPUTER'
                $script:mockOperator.PagerAddress = '555-000-0000'
                $script:mockOperator.PagerDays = [Microsoft.SqlServer.Management.Smo.Agent.WeekDays]::Weekdays
                $script:mockOperator.SaturdayPagerStartTime = [System.TimeSpan]::new(8, 0, 0)
                $script:mockOperator.SaturdayPagerEndTime = [System.TimeSpan]::new(17, 0, 0)
                $script:mockOperator.SundayPagerStartTime = [System.TimeSpan]::new(9, 0, 0)
                $script:mockOperator.SundayPagerEndTime = [System.TimeSpan]::new(16, 0, 0)
                $script:mockOperator.WeekdayPagerStartTime = [System.TimeSpan]::new(8, 0, 0)
                $script:mockOperator.WeekdayPagerEndTime = [System.TimeSpan]::new(17, 0, 0)

                $testParameters = @{
                    Force = $true
                    ServerObject = $script:mockServerObject
                    Name = 'TestOperator'
                    EmailAddress = 'admin@contoso.com'
                    CategoryName = 'DatabaseAdmins'
                    NetSendAddress = 'SQLSERVER01'
                    PagerAddress = '555-999-8888'
                    PagerDays = [Microsoft.SqlServer.Management.Smo.Agent.WeekDays]::EveryDay
                    SaturdayPagerStartTime = [System.TimeSpan]::new(10, 0, 0)
                    SaturdayPagerEndTime = [System.TimeSpan]::new(20, 0, 0)
                    SundayPagerStartTime = [System.TimeSpan]::new(11, 0, 0)
                    SundayPagerEndTime = [System.TimeSpan]::new(19, 0, 0)
                    WeekdayPagerStartTime = [System.TimeSpan]::new(7, 0, 0)
                    WeekdayPagerEndTime = [System.TimeSpan]::new(18, 0, 0)
                }

                Set-SqlDscAgentOperator @testParameters

                # Verify the operator was updated
                $script:mockMethodAlterCallCount | Should -Be 1

                # Verify all properties were set correctly
                $script:mockOperator.EmailAddress | Should -Be 'admin@contoso.com'
                $script:mockOperator.CategoryName | Should -Be 'DatabaseAdmins'
                $script:mockOperator.NetSendAddress | Should -Be 'SQLSERVER01'
                $script:mockOperator.PagerAddress | Should -Be '555-999-8888'
                $script:mockOperator.PagerDays | Should -Be ([Microsoft.SqlServer.Management.Smo.Agent.WeekDays]::EveryDay)
                $script:mockOperator.SaturdayPagerStartTime | Should -Be ([System.TimeSpan]::new(10, 0, 0))
                $script:mockOperator.SaturdayPagerEndTime | Should -Be ([System.TimeSpan]::new(20, 0, 0))
                $script:mockOperator.SundayPagerStartTime | Should -Be ([System.TimeSpan]::new(11, 0, 0))
                $script:mockOperator.SundayPagerEndTime | Should -Be ([System.TimeSpan]::new(19, 0, 0))
                $script:mockOperator.WeekdayPagerStartTime | Should -Be ([System.TimeSpan]::new(7, 0, 0))
                $script:mockOperator.WeekdayPagerEndTime | Should -Be ([System.TimeSpan]::new(18, 0, 0))
            }
        }
    }

    Context 'When updating operator using ByObject parameter set' {
        BeforeAll {
            # Mock existing operator with parent hierarchy
            $script:mockOperator = [Microsoft.SqlServer.Management.Smo.Agent.Operator]::CreateTypeInstance()
            $script:mockOperator.Name = 'TestOperator'
            $script:mockOperator.EmailAddress = 'old@contoso.com'

            # Mock JobServer object
            $script:mockJobServer = [Microsoft.SqlServer.Management.Smo.Agent.JobServer]::CreateTypeInstance()

            # Mock server object
            $script:mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()
            $script:mockServerObject.InstanceName = 'TestInstance'

            # Set up parent hierarchy
            $script:mockOperator.Parent = $script:mockJobServer
            $script:mockJobServer.Parent = $script:mockServerObject

            $script:mockMethodAlterCallCount = 0
            $script:mockOperator | Add-Member -MemberType ScriptMethod -Name 'Alter' -Value {
                $script:mockMethodAlterCallCount++
            } -Force
        }

        It 'Should update operator email address when using operator object' {
            $script:mockMethodAlterCallCount = 0
            $script:mockOperator.EmailAddress = 'old@contoso.com'

            $null = Set-SqlDscAgentOperator -Force -OperatorObject $script:mockOperator -EmailAddress 'new@contoso.com'

            $script:mockOperator.EmailAddress | Should -Be 'new@contoso.com'
            $script:mockMethodAlterCallCount | Should -Be 1
        }

        Context 'When passing parameter OperatorObject over the pipeline' {
            It 'Should update operator email address using pipeline input' {
                $script:mockMethodAlterCallCount = 0
                $script:mockOperator.EmailAddress = 'old@contoso.com'

                $script:mockOperator | Set-SqlDscAgentOperator -Force -EmailAddress 'new@contoso.com'

                $script:mockOperator.EmailAddress | Should -Be 'new@contoso.com'
                $script:mockMethodAlterCallCount | Should -Be 1
            }
        }

        Context 'When updating operator with different properties using ByObject parameter set' {
            It 'Should update operator with property <PropertyName> set correctly using operator object' -ForEach @(
                @{
                    PropertyName = 'EmailAddress'
                    PropertyValue = 'updated@contoso.com'
                    Parameters = @{ EmailAddress = 'updated@contoso.com' }
                }
                @{
                    PropertyName = 'CategoryName'
                    PropertyValue = 'UpdatedCategory'
                    Parameters = @{ CategoryName = 'UpdatedCategory' }
                }
                @{
                    PropertyName = 'NetSendAddress'
                    PropertyValue = 'COMPUTER02'
                    Parameters = @{ NetSendAddress = 'COMPUTER02' }
                }
                @{
                    PropertyName = 'PagerAddress'
                    PropertyValue = '555-987-6543'
                    Parameters = @{ PagerAddress = '555-987-6543' }
                }
                @{
                    PropertyName = 'PagerDays'
                    PropertyValue = 64 -bor 1 # Saturday and Sunday
                    Parameters = @{ PagerDays = 64 -bor 1 } # Saturday and Sunday
                }
                @{
                    PropertyName = 'SaturdayPagerEndTime'
                    PropertyValue = [System.TimeSpan]::new(20, 0, 0)
                    Parameters = @{ SaturdayPagerEndTime = [System.TimeSpan]::new(20, 0, 0) }
                }
                @{
                    PropertyName = 'SaturdayPagerStartTime'
                    PropertyValue = [System.TimeSpan]::new(9, 0, 0)
                    Parameters = @{ SaturdayPagerStartTime = [System.TimeSpan]::new(9, 0, 0) }
                }
                @{
                    PropertyName = 'SundayPagerEndTime'
                    PropertyValue = [System.TimeSpan]::new(19, 0, 0)
                    Parameters = @{ SundayPagerEndTime = [System.TimeSpan]::new(19, 0, 0) }
                }
                @{
                    PropertyName = 'SundayPagerStartTime'
                    PropertyValue = [System.TimeSpan]::new(10, 0, 0)
                    Parameters = @{ SundayPagerStartTime = [System.TimeSpan]::new(10, 0, 0) }
                }
                @{
                    PropertyName = 'WeekdayPagerEndTime'
                    PropertyValue = [System.TimeSpan]::new(18, 30, 0)
                    Parameters = @{ WeekdayPagerEndTime = [System.TimeSpan]::new(18, 30, 0) }
                }
                @{
                    PropertyName = 'WeekdayPagerStartTime'
                    PropertyValue = [System.TimeSpan]::new(7, 30, 0)
                    Parameters = @{ WeekdayPagerStartTime = [System.TimeSpan]::new(7, 30, 0) }
                }
            ) {
                # Reset counter and set initial values
                $script:mockMethodAlterCallCount = 0

                # Set different initial values to ensure the property is actually being updated
                switch ($PropertyName) {
                    'EmailAddress' { $script:mockOperator.EmailAddress = 'old@contoso.com' }
                    'CategoryName' { $script:mockOperator.CategoryName = 'OldCategory' }
                    'NetSendAddress' { $script:mockOperator.NetSendAddress = 'OLDCOMPUTER' }
                    'PagerAddress' { $script:mockOperator.PagerAddress = '555-000-0000' }
                    'PagerDays' { $script:mockOperator.PagerDays = [Microsoft.SqlServer.Management.Smo.Agent.WeekDays]::Weekdays }
                    'SaturdayPagerEndTime' { $script:mockOperator.SaturdayPagerEndTime = [System.TimeSpan]::new(17, 0, 0) }
                    'SaturdayPagerStartTime' { $script:mockOperator.SaturdayPagerStartTime = [System.TimeSpan]::new(8, 0, 0) }
                    'SundayPagerEndTime' { $script:mockOperator.SundayPagerEndTime = [System.TimeSpan]::new(16, 0, 0) }
                    'SundayPagerStartTime' { $script:mockOperator.SundayPagerStartTime = [System.TimeSpan]::new(9, 0, 0) }
                    'WeekdayPagerEndTime' { $script:mockOperator.WeekdayPagerEndTime = [System.TimeSpan]::new(17, 0, 0) }
                    'WeekdayPagerStartTime' { $script:mockOperator.WeekdayPagerStartTime = [System.TimeSpan]::new(8, 0, 0) }
                }

                # Create parameters hash with base parameters
                $testParameters = @{
                    Force = $true
                    OperatorObject = $script:mockOperator
                }

                # Add the specific property being tested
                $testParameters += $Parameters

                Set-SqlDscAgentOperator @testParameters

                # Verify the operator was updated
                $script:mockMethodAlterCallCount | Should -Be 1

                # Verify the property was set correctly
                $script:mockOperator.$PropertyName | Should -Be $PropertyValue
            }
        }
    }

    Context 'When update operation fails' {
        BeforeAll {
            # Mock existing operator
            $script:mockOperator = [Microsoft.SqlServer.Management.Smo.Agent.Operator]::CreateTypeInstance()
            $script:mockOperator.Name = 'TestOperator'
            $script:mockOperator.EmailAddress = 'old@contoso.com'

            # Mock operator collection with existing operator
            $script:mockOperatorCollection = [Microsoft.SqlServer.Management.Smo.Agent.OperatorCollection]::CreateTypeInstance()
            $script:mockOperatorCollection.Add($script:mockOperator)

            # Mock JobServer object with mock refresh method
            $script:mockJobServer = [Microsoft.SqlServer.Management.Smo.Agent.JobServer]::CreateTypeInstance()
            $script:mockJobServer.Operators = $script:mockOperatorCollection
            $script:mockOperatorCollection | Add-Member -MemberType ScriptMethod -Name 'Refresh' -Value { } -Force

            # Mock server object
            $script:mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()
            $script:mockServerObject.JobServer = $script:mockJobServer

            $script:mockOperator | Add-Member -MemberType ScriptMethod -Name 'Alter' -Value {
                throw 'Mocked alter failure'
            } -Force
        }

        It 'Should throw when alter operation fails' {
            { Set-SqlDscAgentOperator -Force -ServerObject $script:mockServerObject -Name 'TestOperator' -EmailAddress 'new@contoso.com' -ErrorAction 'Stop' } |
                Should -Throw -ExpectedMessage '*Failed to update SQL Agent Operator ''TestOperator''*'
        }
    }
}
