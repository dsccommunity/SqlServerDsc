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
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks noop" first.'
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

Describe 'Get-SqlDscAgentOperator' -Tag 'Public' {
    Context 'When command has correct parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = 'All'
                ExpectedParameters = '-ServerObject <Server> [<CommonParameters>]'
            }
            @{
                ExpectedParameterSetName = 'ByName'
                ExpectedParameters = '-ServerObject <Server> -Name <string> [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Get-SqlDscAgentOperator').ParameterSets |
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
            $parameterInfo = (Get-Command -Name 'Get-SqlDscAgentOperator').Parameters['ServerObject']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have ServerObject accept pipeline input' {
            $parameterInfo = (Get-Command -Name 'Get-SqlDscAgentOperator').Parameters['ServerObject']
            $parameterInfo.Attributes.ValueFromPipeline | Should -BeTrue
        }

        It 'Should have Name as a mandatory parameter in ByName parameter set' {
            $parameterInfo = (Get-Command -Name 'Get-SqlDscAgentOperator').Parameters['Name']
            $byNameParameterSet = $parameterInfo.ParameterSets['ByName']
            $byNameParameterSet.IsMandatory | Should -BeTrue
        }
    }

    Context 'When getting all operators' {
        BeforeAll {
            # Mock operator objects using SMO stub types
            $script:mockOperator1 = [Microsoft.SqlServer.Management.Smo.Agent.Operator]::CreateTypeInstance()
            $script:mockOperator1.Name = 'Operator1'
            $script:mockOperator1.EmailAddress = 'operator1@contoso.com'

            $script:mockOperator2 = [Microsoft.SqlServer.Management.Smo.Agent.Operator]::CreateTypeInstance()
            $script:mockOperator2.Name = 'Operator2'
            $script:mockOperator2.EmailAddress = 'operator2@contoso.com'

            # Mock operator collection
            $script:mockOperatorCollection = [Microsoft.SqlServer.Management.Smo.Agent.OperatorCollection]::CreateTypeInstance()
            $script:mockOperatorCollection.Add($script:mockOperator1)
            $script:mockOperatorCollection.Add($script:mockOperator2)

            # Mock JobServer object
            $script:mockJobServer = [Microsoft.SqlServer.Management.Smo.Agent.JobServer]::CreateTypeInstance()
            $script:mockJobServer.Operators = $script:mockOperatorCollection

            # Mock server object
            $script:mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()
            $script:mockServerObject.JobServer = $script:mockJobServer
        }

        It 'Should return all operators when no name is specified' {
            $result = Get-SqlDscAgentOperator -ServerObject $script:mockServerObject

            $result | Should -HaveCount 2
            $result[0].Name | Should -Be 'Operator1'
            $result[1].Name | Should -Be 'Operator2'
        }
    }

    Context 'When getting a specific operator' {
        BeforeAll {
            # Mock operator objects using SMO stub types
            $script:mockOperator1 = [Microsoft.SqlServer.Management.Smo.Agent.Operator]::CreateTypeInstance()
            $script:mockOperator1.Name = 'TestOperator'
            $script:mockOperator1.EmailAddress = 'test@contoso.com'

            # Mock operator collection
            $script:mockOperatorCollection = [Microsoft.SqlServer.Management.Smo.Agent.OperatorCollection]::CreateTypeInstance()
            $script:mockOperatorCollection.Add($script:mockOperator1)

            # Mock JobServer object
            $script:mockJobServer = [Microsoft.SqlServer.Management.Smo.Agent.JobServer]::CreateTypeInstance()
            $script:mockJobServer.Operators = $script:mockOperatorCollection

            # Mock server object
            $script:mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()
            $script:mockServerObject.JobServer = $script:mockJobServer
        }

        It 'Should return specific operator when name matches' {
            $result = Get-SqlDscAgentOperator -ServerObject $script:mockServerObject -Name 'TestOperator'

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'TestOperator'
            $result.EmailAddress | Should -Be 'test@contoso.com'
        }

        It 'Should return null when operator does not exist' {
            $result = Get-SqlDscAgentOperator -ServerObject $script:mockServerObject -Name 'NonExistentOperator'

            $result | Should -BeNull
        }
    }

    Context 'When using pipeline input' {
        BeforeAll {
            # Mock operator collection
            $script:mockOperatorCollection = [Microsoft.SqlServer.Management.Smo.Agent.OperatorCollection]::CreateTypeInstance()

            # Mock JobServer object
            $script:mockJobServer = [Microsoft.SqlServer.Management.Smo.Agent.JobServer]::CreateTypeInstance()
            $script:mockJobServer.Operators = $script:mockOperatorCollection

            # Mock server object
            $script:mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()
            $script:mockServerObject.JobServer = $script:mockJobServer
        }

        It 'Should accept server object from pipeline' {
            $result = $script:mockServerObject | Get-SqlDscAgentOperator
            $result | Should -BeNullOrEmpty
        }
    }
}
