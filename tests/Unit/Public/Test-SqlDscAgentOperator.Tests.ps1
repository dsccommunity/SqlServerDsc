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

Describe 'Test-SqlDscAgentOperator' -Tag 'Public' {
    Context 'When command has correct parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = '__AllParameterSets'
                ExpectedParameters = '-ServerObject <Server> -Name <string> [-EmailAddress <string>] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Test-SqlDscAgentOperator').ParameterSets |
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
            $parameterInfo = (Get-Command -Name 'Test-SqlDscAgentOperator').Parameters['ServerObject']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have ServerObject accept pipeline input' {
            $parameterInfo = (Get-Command -Name 'Test-SqlDscAgentOperator').Parameters['ServerObject']
            $parameterInfo.Attributes.ValueFromPipeline | Should -BeTrue
        }

        It 'Should have Name as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Test-SqlDscAgentOperator').Parameters['Name']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }
    }

    Context 'When testing operator existence only' {
        BeforeAll {
            # Mock existing operator
            $script:mockOperator = [Microsoft.SqlServer.Management.Smo.Agent.Operator]::CreateTypeInstance()
            $script:mockOperator.Name = 'TestOperator'
            $script:mockOperator.EmailAddress = 'test@contoso.com'
            
            # Mock operator collection with existing operator
            $script:mockOperatorCollection = [Microsoft.SqlServer.Management.Smo.Agent.OperatorCollection]::CreateTypeInstance()
            $script:mockOperatorCollection.Add($script:mockOperator)

            # Mock JobServer object
            $script:mockJobServer = [Microsoft.SqlServer.Management.Smo.Agent.JobServer]::CreateTypeInstance()
            $script:mockJobServer.Operators = $script:mockOperatorCollection

            # Mock server object
            $script:mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()
            $script:mockServerObject.JobServer = $script:mockJobServer
        }

        It 'Should return true when operator exists' {
            $result = Test-SqlDscAgentOperator -ServerObject $script:mockServerObject -Name 'TestOperator'

            $result | Should -BeTrue
        }

        It 'Should return false when operator does not exist' {
            $result = Test-SqlDscAgentOperator -ServerObject $script:mockServerObject -Name 'NonExistentOperator'

            $result | Should -BeFalse
        }

        Context 'When using pipeline input' {
            It 'Should return true when operator exists using pipeline input' {
                $result = $script:mockServerObject | Test-SqlDscAgentOperator -Name 'TestOperator'

                $result | Should -BeTrue
            }
        }
    }

    Context 'When testing operator with specific properties' {
        BeforeAll {
            # Mock existing operator with correct email
            $script:mockOperatorCorrect = [Microsoft.SqlServer.Management.Smo.Agent.Operator]::CreateTypeInstance()
            $script:mockOperatorCorrect.Name = 'CorrectOperator'
            $script:mockOperatorCorrect.EmailAddress = 'correct@contoso.com'

            # Mock existing operator with wrong email
            $script:mockOperatorWrong = [Microsoft.SqlServer.Management.Smo.Agent.Operator]::CreateTypeInstance()
            $script:mockOperatorWrong.Name = 'WrongOperator'
            $script:mockOperatorWrong.EmailAddress = 'wrong@contoso.com'
            
            # Mock operator collection with existing operators
            $script:mockOperatorCollection = [Microsoft.SqlServer.Management.Smo.Agent.OperatorCollection]::CreateTypeInstance()
            $script:mockOperatorCollection.Add($script:mockOperatorCorrect)
            $script:mockOperatorCollection.Add($script:mockOperatorWrong)

            # Mock JobServer object
            $script:mockJobServer = [Microsoft.SqlServer.Management.Smo.Agent.JobServer]::CreateTypeInstance()
            $script:mockJobServer.Operators = $script:mockOperatorCollection

            # Mock server object
            $script:mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()
            $script:mockServerObject.JobServer = $script:mockJobServer
        }

        It 'Should return true when operator exists with correct email address' {
            $result = Test-SqlDscAgentOperator -ServerObject $script:mockServerObject -Name 'CorrectOperator' -EmailAddress 'correct@contoso.com'

            $result | Should -BeTrue
        }

        It 'Should return false when operator exists with wrong email address' {
            $result = Test-SqlDscAgentOperator -ServerObject $script:mockServerObject -Name 'WrongOperator' -EmailAddress 'correct@contoso.com'

            $result | Should -BeFalse
        }

        It 'Should return false when operator does not exist' {
            $result = Test-SqlDscAgentOperator -ServerObject $script:mockServerObject -Name 'NonExistentOperator' -EmailAddress 'test@contoso.com'

            $result | Should -BeFalse
        }

        Context 'When using pipeline input' {
            It 'Should return true when operator has correct properties using pipeline input' {
                $result = $script:mockServerObject | Test-SqlDscAgentOperator -Name 'CorrectOperator' -EmailAddress 'correct@contoso.com'

                $result | Should -BeTrue
            }

            It 'Should return false when operator has wrong properties using pipeline input' {
                $result = $script:mockServerObject | Test-SqlDscAgentOperator -Name 'WrongOperator' -EmailAddress 'correct@contoso.com'

                $result | Should -BeFalse
            }
        }
    }

    Context 'When testing operator with empty email address' {
        BeforeAll {
            # Mock existing operator with no email
            $script:mockOperatorNoEmail = [Microsoft.SqlServer.Management.Smo.Agent.Operator]::CreateTypeInstance()
            $script:mockOperatorNoEmail.Name = 'NoEmailOperator'
            $script:mockOperatorNoEmail.EmailAddress = ''
            
            # Mock operator collection with existing operator
            $script:mockOperatorCollection = [Microsoft.SqlServer.Management.Smo.Agent.OperatorCollection]::CreateTypeInstance()
            $script:mockOperatorCollection.Add($script:mockOperatorNoEmail)

            # Mock JobServer object
            $script:mockJobServer = [Microsoft.SqlServer.Management.Smo.Agent.JobServer]::CreateTypeInstance()
            $script:mockJobServer.Operators = $script:mockOperatorCollection

            # Mock server object
            $script:mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()
            $script:mockServerObject.JobServer = $script:mockJobServer
        }

        It 'Should return true when operator exists with empty email and empty email is expected' {
            $result = Test-SqlDscAgentOperator -ServerObject $script:mockServerObject -Name 'NoEmailOperator' -EmailAddress ''

            $result | Should -BeTrue
        }

        It 'Should return false when operator exists with empty email but non-empty email is expected' {
            $result = Test-SqlDscAgentOperator -ServerObject $script:mockServerObject -Name 'NoEmailOperator' -EmailAddress 'test@contoso.com'

            $result | Should -BeFalse
        }
    }
}
