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

    Import-Module -Name $script:moduleName -ErrorAction 'Stop'

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:moduleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Remove-Item -Path 'env:SqlServerDscCI'
}

Describe 'Set-SqlDscRSDatabaseTimeout' {
    Context 'When validating parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = 'LogonTimeout'
                ExpectedParameters = '-Configuration <Object> -LogonTimeout <int> [-PassThru] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
            @{
                ExpectedParameterSetName = 'QueryTimeout'
                ExpectedParameters = '-Configuration <Object> -QueryTimeout <int> [-PassThru] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
            @{
                ExpectedParameterSetName = 'BothTimeouts'
                ExpectedParameters = '-Configuration <Object> -LogonTimeout <int> -QueryTimeout <int> [-PassThru] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Set-SqlDscRSDatabaseTimeout').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }

        It 'Should have LogonTimeout as the default parameter set' {
            $commandMetadata = Get-Command -Name 'Set-SqlDscRSDatabaseTimeout'

            $commandMetadata.DefaultParameterSet | Should -Be 'LogonTimeout'
        }
    }

    Context 'When validating parameter attributes' {
        BeforeAll {
            $commandMetadata = Get-Command -Name 'Set-SqlDscRSDatabaseTimeout'
        }

        Context 'When validating the Configuration parameter' {
            BeforeAll {
                $configurationParameter = $commandMetadata.Parameters['Configuration']
            }

            It 'Should have Mandatory set to True in all parameter sets' {
                $configurationParameter.Attributes.Mandatory | Should -Contain $true
            }

            It 'Should have ValueFromPipeline set to True' {
                $configurationParameter.Attributes.ValueFromPipeline | Should -Contain $true
            }

            It 'Should have the expected parameter type' {
                $configurationParameter.ParameterType.Name | Should -Be 'Object'
            }

            It 'Should be a member of LogonTimeout parameter set' {
                $configurationParameter.ParameterSets.Keys | Should -Contain 'LogonTimeout'
            }

            It 'Should be a member of QueryTimeout parameter set' {
                $configurationParameter.ParameterSets.Keys | Should -Contain 'QueryTimeout'
            }

            It 'Should be a member of BothTimeouts parameter set' {
                $configurationParameter.ParameterSets.Keys | Should -Contain 'BothTimeouts'
            }
        }

        Context 'When validating the LogonTimeout parameter' {
            BeforeAll {
                $logonTimeoutParameter = $commandMetadata.Parameters['LogonTimeout']
            }

            It 'Should have the expected parameter type' {
                $logonTimeoutParameter.ParameterType.Name | Should -Be 'Int32'
            }

            It 'Should be a member of LogonTimeout parameter set' {
                $logonTimeoutParameter.ParameterSets.Keys | Should -Contain 'LogonTimeout'
            }

            It 'Should be a member of BothTimeouts parameter set' {
                $logonTimeoutParameter.ParameterSets.Keys | Should -Contain 'BothTimeouts'
            }

            It 'Should not be a member of QueryTimeout parameter set' {
                $logonTimeoutParameter.ParameterSets.Keys | Should -Not -Contain 'QueryTimeout'
            }

            It 'Should be mandatory in LogonTimeout parameter set' {
                $logonTimeoutParameter.ParameterSets['LogonTimeout'].IsMandatory | Should -BeTrue
            }

            It 'Should be mandatory in BothTimeouts parameter set' {
                $logonTimeoutParameter.ParameterSets['BothTimeouts'].IsMandatory | Should -BeTrue
            }

            It 'Should have ValidateRange attribute with minimum 0' {
                $validateRangeAttribute = $logonTimeoutParameter.Attributes |
                    Where-Object -FilterScript { $_ -is [System.Management.Automation.ValidateRangeAttribute] }

                $validateRangeAttribute.MinRange | Should -Be 0
            }
        }

        Context 'When validating the QueryTimeout parameter' {
            BeforeAll {
                $queryTimeoutParameter = $commandMetadata.Parameters['QueryTimeout']
            }

            It 'Should have the expected parameter type' {
                $queryTimeoutParameter.ParameterType.Name | Should -Be 'Int32'
            }

            It 'Should be a member of QueryTimeout parameter set' {
                $queryTimeoutParameter.ParameterSets.Keys | Should -Contain 'QueryTimeout'
            }

            It 'Should be a member of BothTimeouts parameter set' {
                $queryTimeoutParameter.ParameterSets.Keys | Should -Contain 'BothTimeouts'
            }

            It 'Should not be a member of LogonTimeout parameter set' {
                $queryTimeoutParameter.ParameterSets.Keys | Should -Not -Contain 'LogonTimeout'
            }

            It 'Should be mandatory in QueryTimeout parameter set' {
                $queryTimeoutParameter.ParameterSets['QueryTimeout'].IsMandatory | Should -BeTrue
            }

            It 'Should be mandatory in BothTimeouts parameter set' {
                $queryTimeoutParameter.ParameterSets['BothTimeouts'].IsMandatory | Should -BeTrue
            }

            It 'Should have ValidateRange attribute with minimum 0' {
                $validateRangeAttribute = $queryTimeoutParameter.Attributes |
                    Where-Object -FilterScript { $_ -is [System.Management.Automation.ValidateRangeAttribute] }

                $validateRangeAttribute.MinRange | Should -Be 0
            }
        }

        Context 'When validating the PassThru parameter' {
            BeforeAll {
                $passThruParameter = $commandMetadata.Parameters['PassThru']
            }

            It 'Should have Mandatory set to False' {
                $passThruParameter.Attributes.Mandatory | Should -Contain $false
            }

            It 'Should have ValueFromPipeline set to False' {
                $passThruParameter.Attributes.ValueFromPipeline | Should -Contain $false
            }

            It 'Should have the expected parameter type' {
                $passThruParameter.ParameterType.Name | Should -Be 'SwitchParameter'
            }
        }

        Context 'When validating the Force parameter' {
            BeforeAll {
                $forceParameter = $commandMetadata.Parameters['Force']
            }

            It 'Should have Mandatory set to False' {
                $forceParameter.Attributes.Mandatory | Should -Contain $false
            }

            It 'Should have ValueFromPipeline set to False' {
                $forceParameter.Attributes.ValueFromPipeline | Should -Contain $false
            }

            It 'Should have the expected parameter type' {
                $forceParameter.ParameterType.Name | Should -Be 'SwitchParameter'
            }
        }

        Context 'When validating the WhatIf parameter' {
            BeforeAll {
                $whatIfParameter = $commandMetadata.Parameters['WhatIf']
            }

            It 'Should have Mandatory set to False' {
                $whatIfParameter.Attributes.Mandatory | Should -BeIn @($false, $null)
            }

            It 'Should have the expected parameter type' {
                $whatIfParameter.ParameterType.Name | Should -Be 'SwitchParameter'
            }
        }

        Context 'When validating the Confirm parameter' {
            BeforeAll {
                $confirmParameter = $commandMetadata.Parameters['Confirm']
            }

            It 'Should have Mandatory set to False' {
                $confirmParameter.Attributes.Mandatory | Should -BeIn @($false, $null)
            }

            It 'Should have the expected parameter type' {
                $confirmParameter.ParameterType.Name | Should -Be 'SwitchParameter'
            }
        }
    }

    Context 'When setting LogonTimeout only' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod
        }

        It 'Should call SetDatabaseLogonTimeout method' {
            $null = $mockCimInstance | Set-SqlDscRSDatabaseTimeout -LogonTimeout 30 -Confirm:$false

            Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                $MethodName -eq 'SetDatabaseLogonTimeout' -and
                $Arguments.LogonTimeout -eq 30
            } -Exactly -Times 1
        }

        It 'Should not call SetDatabaseQueryTimeout method' {
            Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                $MethodName -eq 'SetDatabaseQueryTimeout'
            } -Exactly -Times 0
        }

        It 'Should not return anything by default' {
            $result = $mockCimInstance | Set-SqlDscRSDatabaseTimeout -LogonTimeout 30 -Confirm:$false

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'When setting QueryTimeout only' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod
        }

        It 'Should call SetDatabaseQueryTimeout method' {
            $null = $mockCimInstance | Set-SqlDscRSDatabaseTimeout -QueryTimeout 120 -Confirm:$false

            Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                $MethodName -eq 'SetDatabaseQueryTimeout' -and
                $Arguments.QueryTimeout -eq 120
            } -Exactly -Times 1
        }

        It 'Should not call SetDatabaseLogonTimeout method' {
            Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                $MethodName -eq 'SetDatabaseLogonTimeout'
            } -Exactly -Times 0
        }

        It 'Should not return anything by default' {
            $result = $mockCimInstance | Set-SqlDscRSDatabaseTimeout -QueryTimeout 120 -Confirm:$false

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'When setting both LogonTimeout and QueryTimeout' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod
        }

        It 'Should call both SetDatabaseLogonTimeout and SetDatabaseQueryTimeout methods' {
            $null = $mockCimInstance | Set-SqlDscRSDatabaseTimeout -LogonTimeout 30 -QueryTimeout 120 -Confirm:$false

            Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                $MethodName -eq 'SetDatabaseLogonTimeout' -and
                $Arguments.LogonTimeout -eq 30
            } -Exactly -Times 1

            Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                $MethodName -eq 'SetDatabaseQueryTimeout' -and
                $Arguments.QueryTimeout -eq 120
            } -Exactly -Times 1
        }

        It 'Should not return anything by default' {
            $result = $mockCimInstance | Set-SqlDscRSDatabaseTimeout -LogonTimeout 30 -QueryTimeout 120 -Confirm:$false

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'When setting timeout to 0 (no timeout)' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod
        }

        It 'Should accept LogonTimeout value of 0' {
            $null = $mockCimInstance | Set-SqlDscRSDatabaseTimeout -LogonTimeout 0 -Confirm:$false

            Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                $MethodName -eq 'SetDatabaseLogonTimeout' -and
                $Arguments.LogonTimeout -eq 0
            } -Exactly -Times 1
        }

        It 'Should accept QueryTimeout value of 0' {
            $null = $mockCimInstance | Set-SqlDscRSDatabaseTimeout -QueryTimeout 0 -Confirm:$false

            Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                $MethodName -eq 'SetDatabaseQueryTimeout' -and
                $Arguments.QueryTimeout -eq 0
            } -Exactly -Times 1
        }
    }

    Context 'When using PassThru' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod
        }

        It 'Should return the configuration CIM instance when setting LogonTimeout' {
            $result = $mockCimInstance | Set-SqlDscRSDatabaseTimeout -LogonTimeout 30 -PassThru -Confirm:$false

            $result | Should -Not -BeNullOrEmpty
            $result.InstanceName | Should -Be 'SSRS'
        }

        It 'Should return the configuration CIM instance when setting QueryTimeout' {
            $result = $mockCimInstance | Set-SqlDscRSDatabaseTimeout -QueryTimeout 120 -PassThru -Confirm:$false

            $result | Should -Not -BeNullOrEmpty
            $result.InstanceName | Should -Be 'SSRS'
        }

        It 'Should return the configuration CIM instance when setting both timeouts' {
            $result = $mockCimInstance | Set-SqlDscRSDatabaseTimeout -LogonTimeout 30 -QueryTimeout 120 -PassThru -Confirm:$false

            $result | Should -Not -BeNullOrEmpty
            $result.InstanceName | Should -Be 'SSRS'
        }
    }

    Context 'When using Force' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod
        }

        It 'Should set LogonTimeout without confirmation' {
            $null = $mockCimInstance | Set-SqlDscRSDatabaseTimeout -LogonTimeout 30 -Force

            Should -Invoke -CommandName Invoke-RsCimMethod -Exactly -Times 1
        }

        It 'Should set QueryTimeout without confirmation' {
            $null = $mockCimInstance | Set-SqlDscRSDatabaseTimeout -QueryTimeout 120 -Force

            Should -Invoke -CommandName Invoke-RsCimMethod -Exactly -Times 1
        }

        It 'Should set both timeouts without confirmation' {
            $null = $mockCimInstance | Set-SqlDscRSDatabaseTimeout -LogonTimeout 30 -QueryTimeout 120 -Force

            Should -Invoke -CommandName Invoke-RsCimMethod -Exactly -Times 2
        }
    }

    Context 'When SetDatabaseLogonTimeout method fails' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod -MockWith {
                throw 'Method SetDatabaseLogonTimeout() failed with an error.'
            }
        }

        It 'Should throw a terminating error with correct error ID' {
            { $mockCimInstance | Set-SqlDscRSDatabaseTimeout -LogonTimeout 30 -Confirm:$false } | Should -Throw -ErrorId 'SSRSDT0001,Set-SqlDscRSDatabaseTimeout'
        }
    }

    Context 'When SetDatabaseQueryTimeout method fails' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod -MockWith {
                throw 'Method SetDatabaseQueryTimeout() failed with an error.'
            }
        }

        It 'Should throw a terminating error with correct error ID' {
            { $mockCimInstance | Set-SqlDscRSDatabaseTimeout -QueryTimeout 120 -Confirm:$false } | Should -Throw -ErrorId 'SSRSDT0002,Set-SqlDscRSDatabaseTimeout'
        }
    }

    Context 'When using WhatIf' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod
        }

        It 'Should not call Invoke-RsCimMethod when setting LogonTimeout' {
            $null = $mockCimInstance | Set-SqlDscRSDatabaseTimeout -LogonTimeout 30 -WhatIf

            Should -Invoke -CommandName Invoke-RsCimMethod -Exactly -Times 0
        }

        It 'Should not call Invoke-RsCimMethod when setting QueryTimeout' {
            $null = $mockCimInstance | Set-SqlDscRSDatabaseTimeout -QueryTimeout 120 -WhatIf

            Should -Invoke -CommandName Invoke-RsCimMethod -Exactly -Times 0
        }

        It 'Should not call Invoke-RsCimMethod when setting both timeouts' {
            $null = $mockCimInstance | Set-SqlDscRSDatabaseTimeout -LogonTimeout 30 -QueryTimeout 120 -WhatIf

            Should -Invoke -CommandName Invoke-RsCimMethod -Exactly -Times 0
        }
    }

    Context 'When passing configuration as parameter' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod
        }

        It 'Should set LogonTimeout using Configuration parameter' {
            $null = Set-SqlDscRSDatabaseTimeout -Configuration $mockCimInstance -LogonTimeout 30 -Confirm:$false

            Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                $MethodName -eq 'SetDatabaseLogonTimeout'
            } -Exactly -Times 1
        }

        It 'Should set QueryTimeout using Configuration parameter' {
            $null = Set-SqlDscRSDatabaseTimeout -Configuration $mockCimInstance -QueryTimeout 120 -Confirm:$false

            Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                $MethodName -eq 'SetDatabaseQueryTimeout'
            } -Exactly -Times 1
        }
    }
}
