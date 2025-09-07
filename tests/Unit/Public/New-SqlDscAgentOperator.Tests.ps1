[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
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

    $env:SqlServerDscCI = $false

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:moduleName -All | Remove-Module -Force
}

Describe 'New-SqlDscAgentOperator' -Tag 'Public' {
    Context 'When command has correct parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = '__AllParameterSets'
                ExpectedParameters = '[-ServerObject] <Server> [-Name] <string> [[-EmailAddress] <string>] [[-CategoryName] <string>] [[-NetSendAddress] <string>] [[-PagerAddress] <string>] [[-PagerDays] <WeekDays>] [[-SaturdayPagerEndTime] <timespan>] [[-SaturdayPagerStartTime] <timespan>] [[-SundayPagerEndTime] <timespan>] [[-SundayPagerStartTime] <timespan>] [[-WeekdayPagerEndTime] <timespan>] [[-WeekdayPagerStartTime] <timespan>] [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]'
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

            # Track method calls
            $script:mockMethodCreateCallCount = 0
            $script:mockCreatedOperator = $null

            # Mock Get-SqlDscAgentOperator to return null (operator doesn't exist)
            Mock -CommandName 'Get-SqlDscAgentOperator' -MockWith {
                return $null
            }

            # Mock the New-Object command for creating operator
            Mock -CommandName 'New-Object' -ParameterFilter { $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Agent.Operator' } -MockWith {
                $mockOperatorObject = [Microsoft.SqlServer.Management.Smo.Agent.Operator]::CreateTypeInstance()
                $mockOperatorObject.Name = $ArgumentList[1]  # Second argument is the name
                $mockOperatorObject | Add-Member -MemberType 'ScriptMethod' -Name 'Create' -Value {
                    $script:mockMethodCreateCallCount++
                } -Force
                
                # Store the created object for verification
                $script:mockCreatedOperator = $mockOperatorObject
                return $mockOperatorObject
            }

            $script:mockMethodCreateCallCount = 0
        }

        It 'Should call the mocked method and have correct values in the object' {
            New-SqlDscAgentOperator -Confirm:$false -ServerObject $script:mockServerObject -Name 'TestOperator'

            Should -Invoke -CommandName 'New-Object' -ParameterFilter { 
                $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Agent.Operator' -and $ArgumentList[1] -eq 'TestOperator'
            } -Exactly -Times 1

            $script:mockMethodCreateCallCount | Should -Be 1
        }

        It 'Should set email address when specified' {
            $script:mockMethodCreateCallCount = 0

            New-SqlDscAgentOperator -Confirm:$false -ServerObject $script:mockServerObject -Name 'TestOperator' -EmailAddress 'test@contoso.com'

            # Verify the mock was called with correct parameters
            Should -Invoke -CommandName 'New-Object' -ParameterFilter { 
                $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Agent.Operator' -and $ArgumentList[1] -eq 'TestOperator'
            } -Exactly -Times 1

            # Verify the object was configured correctly
            $script:mockCreatedOperator.Name | Should -Be 'TestOperator'
            $script:mockCreatedOperator.EmailAddress | Should -Be 'test@contoso.com'

            $script:mockMethodCreateCallCount | Should -Be 1
        }

        It 'Should return operator object when PassThru is specified' {
            $script:mockMethodCreateCallCount = 0

            $result = New-SqlDscAgentOperator -Confirm:$false -ServerObject $script:mockServerObject -Name 'TestOperator' -PassThru

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'TestOperator'

            $script:mockMethodCreateCallCount | Should -Be 1
        }

        Context 'When using parameter WhatIf' {
            It 'Should not call the mocked method when using WhatIf' {
                $script:mockMethodCreateCallCount = 0

                New-SqlDscAgentOperator -WhatIf -ServerObject $script:mockServerObject -Name 'TestOperator'

                $script:mockMethodCreateCallCount | Should -Be 0
            }
        }

        Context 'When passing parameter ServerObject over the pipeline' {
            It 'Should call the mocked method and have correct values in the object' {
                $script:mockMethodCreateCallCount = 0

                $script:mockServerObject | New-SqlDscAgentOperator -Confirm:$false -Name 'TestOperator'

                # Verify the mock was called with correct parameters
                Should -Invoke -CommandName 'New-Object' -ParameterFilter { 
                    $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Agent.Operator' -and $ArgumentList[1] -eq 'TestOperator'
                } -Exactly -Times 1

                $script:mockMethodCreateCallCount | Should -Be 1
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
            { New-SqlDscAgentOperator -ServerObject $script:mockServerObject -Name 'ExistingOperator' -ErrorAction 'Stop' } |
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

            # Mock the New-Object command for creating operator that throws an error
            Mock -CommandName 'New-Object' -ParameterFilter { $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Agent.Operator' } -MockWith {
                $mockOperatorObject = [Microsoft.SqlServer.Management.Smo.Agent.Operator]::CreateTypeInstance()
                $mockOperatorObject.Name = $ArgumentList[1]
                $mockOperatorObject | Add-Member -MemberType ScriptMethod -Name 'Create' -Value {
                    throw 'Mocked create failure'
                } -Force
                return $mockOperatorObject
            }
        }

        It 'Should throw when create operation fails' {
            { New-SqlDscAgentOperator -Confirm:$false -ServerObject $script:mockServerObject -Name 'FailOperator' -ErrorAction 'Stop' } |
                Should -Throw -ExpectedMessage '*Mocked create failure*'
        }
    }
}
