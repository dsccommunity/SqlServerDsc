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

Describe 'New-SqlDscAgentOperator' -Tag 'Public' {
    Context 'When command has correct parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = '__AllParameterSets'
                ExpectedParameters = '[-ServerObject] <Server> [-Name] <string> [[-EmailAddress] <string>] [[-CategoryName] <string>] [[-NetSendAddress] <string>] [[-PagerAddress] <string>] [[-PagerDays] <WeekDays>] [[-SaturdayPagerEndTime] <timespan>] [[-SaturdayPagerStartTime] <timespan>] [[-SundayPagerEndTime] <timespan>] [[-SundayPagerStartTime] <timespan>] [[-WeekdayPagerEndTime] <timespan>] [[-WeekdayPagerStartTime] <timespan>] [-PassThru] [-Force] [-Refresh] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'New-SqlDscAgentOperator').ParameterSets |
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
            $parameterInfo = (Get-Command -Name 'New-SqlDscAgentOperator').Parameters['ServerObject']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have ServerObject accept pipeline input' {
            $parameterInfo = (Get-Command -Name 'New-SqlDscAgentOperator').Parameters['ServerObject']
            $parameterInfo.Attributes.ValueFromPipeline | Should -BeTrue
        }

        It 'Should have Name as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'New-SqlDscAgentOperator').Parameters['Name']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }
    }

    Context 'When creating a new operator successfully' {
        BeforeAll {
            # Mock empty operator collection
            $script:mockOperatorCollection = [Microsoft.SqlServer.Management.Smo.Agent.OperatorCollection]::CreateTypeInstance()

            # Mock JobServer object
            $script:mockJobServer = [Microsoft.SqlServer.Management.Smo.Agent.JobServer]::CreateTypeInstance()
            $script:mockJobServer.Operators = $script:mockOperatorCollection

            # Mock server object
            $script:mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()
            $script:mockServerObject.JobServer = $script:mockJobServer
            $script:mockServerObject.InstanceName = 'TestInstance'

            # Mock Get-SqlDscAgentOperator to return null (operator doesn't exist)
            Mock -CommandName 'Get-SqlDscAgentOperator' -MockWith {
                return $null
            }
        }

        It 'Should call Create method on operator when creating new operator' {
            # Reset counter
            $script:mockJobServer.MockOperatorMethodCreateCalled = 0

            New-SqlDscAgentOperator -Force -ServerObject $script:mockServerObject -Name 'TestOperator' -EmailAddress 'test@contoso.com'

            $script:mockJobServer.MockOperatorMethodCreateCalled | Should -Be 1
        }

        It 'Should create operator with email address when specified' {
            # Reset counter
            $script:mockJobServer.MockOperatorMethodCreateCalled = 0

            $null = New-SqlDscAgentOperator -Force -ServerObject $script:mockServerObject -Name 'TestOperator' -EmailAddress 'test@contoso.com'

            $script:mockJobServer.MockOperatorMethodCreateCalled | Should -Be 1
        }

        It 'Should return operator object when PassThru is specified' {
            # Reset counter
            $script:mockJobServer.MockOperatorMethodCreateCalled = 0

            $result = New-SqlDscAgentOperator -Force -ServerObject $script:mockServerObject -Name 'TestOperator' -EmailAddress 'test@contoso.com' -PassThru

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'TestOperator'
            $script:mockJobServer.MockOperatorMethodCreateCalled | Should -Be 1
        }

        Context 'When using parameter WhatIf' {
            It 'Should not perform any action when using WhatIf' {
                # Reset counter
                $script:mockJobServer.MockOperatorMethodCreateCalled = 0

                $null = New-SqlDscAgentOperator -WhatIf -ServerObject $script:mockServerObject -Name 'TestOperator' -EmailAddress 'test@contoso.com'

                # Create method should not be called when using WhatIf
                $script:mockJobServer.MockOperatorMethodCreateCalled | Should -Be 0
            }
        }

        Context 'When passing parameter ServerObject over the pipeline' {
            It 'Should create operator via pipeline without throwing an error' {
                # Reset counter
                $script:mockJobServer.MockOperatorMethodCreateCalled = 0

                $null = $script:mockServerObject | New-SqlDscAgentOperator -Force -Name 'TestOperator' -EmailAddress 'test@contoso.com'

                $script:mockJobServer.MockOperatorMethodCreateCalled | Should -Be 1
            }
        }

        Context 'When creating operator with different properties' {
            It 'Should create operator with property <PropertyName> set correctly' -ForEach @(
                @{
                    PropertyName = 'EmailAddress'
                    PropertyValue = 'test@contoso.com'
                    Parameters = @{ EmailAddress = 'test@contoso.com' }
                }
                @{
                    PropertyName = 'CategoryName'
                    PropertyValue = 'TestCategory'
                    Parameters = @{ CategoryName = 'TestCategory' }
                }
                @{
                    PropertyName = 'NetSendAddress'
                    PropertyValue = 'COMPUTER01'
                    Parameters = @{ NetSendAddress = 'COMPUTER01' }
                }
                @{
                    PropertyName = 'PagerAddress'
                    PropertyValue = '555-123-4567'
                    Parameters = @{ PagerAddress = '555-123-4567' }
                }
                @{
                    PropertyName = 'PagerDays'
                    PropertyValue = 'Weekdays'
                    Parameters = @{ PagerDays = 'Weekdays' }
                }
                @{
                    PropertyName = 'SaturdayPagerEndTime'
                    PropertyValue = [System.TimeSpan]::new(18, 0, 0)
                    Parameters = @{ SaturdayPagerEndTime = [System.TimeSpan]::new(18, 0, 0) }
                }
                @{
                    PropertyName = 'SaturdayPagerStartTime'
                    PropertyValue = [System.TimeSpan]::new(8, 0, 0)
                    Parameters = @{ SaturdayPagerStartTime = [System.TimeSpan]::new(8, 0, 0) }
                }
                @{
                    PropertyName = 'SundayPagerEndTime'
                    PropertyValue = [System.TimeSpan]::new(17, 0, 0)
                    Parameters = @{ SundayPagerEndTime = [System.TimeSpan]::new(17, 0, 0) }
                }
                @{
                    PropertyName = 'SundayPagerStartTime'
                    PropertyValue = [System.TimeSpan]::new(9, 0, 0)
                    Parameters = @{ SundayPagerStartTime = [System.TimeSpan]::new(9, 0, 0) }
                }
                @{
                    PropertyName = 'WeekdayPagerEndTime'
                    PropertyValue = [System.TimeSpan]::new(17, 30, 0)
                    Parameters = @{ WeekdayPagerEndTime = [System.TimeSpan]::new(17, 30, 0) }
                }
                @{
                    PropertyName = 'WeekdayPagerStartTime'
                    PropertyValue = [System.TimeSpan]::new(8, 30, 0)
                    Parameters = @{ WeekdayPagerStartTime = [System.TimeSpan]::new(8, 30, 0) }
                }
            ) {
                # Reset counter
                $script:mockJobServer.MockOperatorMethodCreateCalled = 0

                # Create parameters hash with base parameters
                $testParameters = @{
                    Force = $true
                    ServerObject = $script:mockServerObject
                    Name = "TestOperator_$PropertyName"
                    PassThru = $true
                }

                # Add the specific property being tested
                $testParameters += $Parameters

                $result = New-SqlDscAgentOperator @testParameters

                # Verify the operator was created
                $script:mockJobServer.MockOperatorMethodCreateCalled | Should -Be 1

                # Verify the property was set correctly
                $result.$PropertyName | Should -Be $PropertyValue
            }
        }

        Context 'When creating operator with multiple properties' {
            It 'Should create operator with all properties set correctly' {
                # Reset counter
                $script:mockJobServer.MockOperatorMethodCreateCalled = 0

                $testParameters = @{
                    Force = $true
                    ServerObject = $script:mockServerObject
                    Name = 'CompleteTestOperator'
                    EmailAddress = 'admin@contoso.com'
                    CategoryName = 'DatabaseAdmins'
                    NetSendAddress = 'SQLSERVER01'
                    PagerAddress = '555-999-8888'
                    PagerDays = 'EveryDay'
                    SaturdayPagerStartTime = [System.TimeSpan]::new(8, 0, 0)
                    SaturdayPagerEndTime = [System.TimeSpan]::new(18, 0, 0)
                    SundayPagerStartTime = [System.TimeSpan]::new(9, 0, 0)
                    SundayPagerEndTime = [System.TimeSpan]::new(17, 0, 0)
                    WeekdayPagerStartTime = [System.TimeSpan]::new(8, 0, 0)
                    WeekdayPagerEndTime = [System.TimeSpan]::new(17, 0, 0)
                    PassThru = $true
                }

                $result = New-SqlDscAgentOperator @testParameters

                # Verify the operator was created
                $script:mockJobServer.MockOperatorMethodCreateCalled | Should -Be 1

                # Verify all properties were set correctly
                $result.Name | Should -Be 'CompleteTestOperator'
                $result.EmailAddress | Should -Be 'admin@contoso.com'
                $result.CategoryName | Should -Be 'DatabaseAdmins'
                $result.NetSendAddress | Should -Be 'SQLSERVER01'
                $result.PagerAddress | Should -Be '555-999-8888'
                $result.PagerDays | Should -Be 'EveryDay'
                $result.SaturdayPagerStartTime | Should -Be ([System.TimeSpan]::new(8, 0, 0))
                $result.SaturdayPagerEndTime | Should -Be ([System.TimeSpan]::new(18, 0, 0))
                $result.SundayPagerStartTime | Should -Be ([System.TimeSpan]::new(9, 0, 0))
                $result.SundayPagerEndTime | Should -Be ([System.TimeSpan]::new(17, 0, 0))
                $result.WeekdayPagerStartTime | Should -Be ([System.TimeSpan]::new(8, 0, 0))
                $result.WeekdayPagerEndTime | Should -Be ([System.TimeSpan]::new(17, 0, 0))
            }
        }
    }

    Context 'When operator already exists' {
        BeforeAll {
            # Mock existing operator
            $script:mockExistingOperator = [Microsoft.SqlServer.Management.Smo.Agent.Operator]::CreateTypeInstance()
            $script:mockExistingOperator.Name = 'ExistingOperator'

            # Mock operator collection with existing operator
            $script:mockOperatorCollection = [Microsoft.SqlServer.Management.Smo.Agent.OperatorCollection]::CreateTypeInstance()
            $script:mockOperatorCollection.Add($script:mockExistingOperator)

            # Mock JobServer object
            $script:mockJobServer = [Microsoft.SqlServer.Management.Smo.Agent.JobServer]::CreateTypeInstance()
            $script:mockJobServer.Operators = $script:mockOperatorCollection

            # Mock server object
            $script:mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()
            $script:mockServerObject.JobServer = $script:mockJobServer
        }

        It 'Should throw when operator already exists' {
            { New-SqlDscAgentOperator -Force -ServerObject $script:mockServerObject -Name 'ExistingOperator' -EmailAddress 'test@contoso.com' -ErrorAction 'Stop' } |
                Should -Throw -ExpectedMessage '*SQL Agent Operator ''ExistingOperator'' already exists*'
        }
    }

    Context 'When create operation fails' {
        BeforeAll {
            # Mock empty operator collection
            $script:mockOperatorCollection = [Microsoft.SqlServer.Management.Smo.Agent.OperatorCollection]::CreateTypeInstance()

            # Mock JobServer object
            $script:mockJobServer = [Microsoft.SqlServer.Management.Smo.Agent.JobServer]::CreateTypeInstance()
            $script:mockJobServer.Operators = $script:mockOperatorCollection

            # Mock server object
            $script:mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()
            $script:mockServerObject.JobServer = $script:mockJobServer
            $script:mockServerObject.InstanceName = 'TestInstance'

            # Mock Get-SqlDscAgentOperator to return null (operator doesn't exist)
            Mock -CommandName 'Get-SqlDscAgentOperator' -MockWith {
                return $null
            }
        }

        It 'Should throw when create operation fails' {
            { New-SqlDscAgentOperator -Force -ServerObject $script:mockServerObject -Name 'MockFailMethodCreateOperator' -EmailAddress 'test@contoso.com' -ErrorAction 'Stop' } |
                Should -Throw -ExpectedMessage "*Failed to create SQL Agent Operator 'MockFailMethodCreateOperator'*"
        }

        It 'Should increment Create method counter even when create operation fails' {
            # Reset counter
            $script:mockJobServer.MockOperatorMethodCreateCalled = 0

            { New-SqlDscAgentOperator -Force -ServerObject $script:mockServerObject -Name 'MockFailMethodCreateOperator' -EmailAddress 'test@contoso.com' -ErrorAction 'Stop' } |
                Should -Throw

            # Counter should be incremented since Create() method was called, even though it failed
            $script:mockJobServer.MockOperatorMethodCreateCalled | Should -Be 1
        }
    }
}
