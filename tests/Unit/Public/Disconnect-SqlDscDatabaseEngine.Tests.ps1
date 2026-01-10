[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Suppressing this rule because Script Analyzer does not understand Pester syntax.')]
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Justification = 'because ConvertTo-SecureString is used to simplify the tests.')]
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

    # Do not use -Force. Doing so, or unloading the module in AfterAll, causes
    # PowerShell class types to get new identities, breaking type comparisons.
    Import-Module -Name $script:moduleName -ErrorAction 'Stop'

    # Loading mocked classes
    Add-Type -Path (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '../Stubs') -ChildPath 'SMO.cs')

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

Describe 'Disconnect-SqlDscDatabaseEngine' -Tag 'Public' {
    It 'Should have the correct parameters in parameter set <MockParameterSetName>' -ForEach @(
        @{
            MockParameterSetName = '__AllParameterSets'
            # cSpell: disable-next
            MockExpectedParameters = '[-ServerObject] <Server> [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
    ) {
        $result = (Get-Command -Name 'Disconnect-SqlDscDatabaseEngine').ParameterSets |
            Where-Object -FilterScript {
                $_.Name -eq $mockParameterSetName
            } |
            Select-Object -Property @(
                @{
                    Name = 'ParameterSetName'
                    Expression = { $_.Name }
                },
                @{
                    Name = 'ParameterListAsString'
                    Expression = { $_.ToString() }
                }
            )

        $result.ParameterSetName | Should -Be $MockParameterSetName
        $result.ParameterListAsString | Should -Be $MockExpectedParameters
    }

    Context 'When disconnecting using a server object' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'MockInstance'

            $mockConnectionContext = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerConnection' |
                Add-Member -MemberType 'ScriptMethod' -Name 'Disconnect' -Value {
                    $script:mockMethodDisconnectCallCount += 1
                } -PassThru -Force

            $mockServerObject.ConnectionContext = $mockConnectionContext
        }

        BeforeEach {
            $script:mockMethodDisconnectCallCount = 0
        }

        Context 'When using parameter Confirm with value $false' {
            It 'Should call the correct mock with the expected parameters' {
                $null = Disconnect-SqlDscDatabaseEngine -ServerObject $mockServerObject -Confirm:$false

                $mockMethodDisconnectCallCount | Should -Be 1
            }
        }

        Context 'When using parameter Force' {
            It 'Should call the correct mock with the expected parameters' {
                $null = Disconnect-SqlDscDatabaseEngine -ServerObject $mockServerObject -Force

                $mockMethodDisconnectCallCount | Should -Be 1
            }
        }

        Context 'When using parameter WhatIf' {
            It 'Should call the correct mock with the expected parameters' {
                $null = Disconnect-SqlDscDatabaseEngine -ServerObject $mockServerObject -WhatIf

                $mockMethodDisconnectCallCount | Should -Be 0
            }
        }

        Context 'When passing parameter ServerObject over the pipeline' {
            It 'Should call the correct mock with the expected parameters' {
                $null = $mockServerObject | Disconnect-SqlDscDatabaseEngine -Force

                $mockMethodDisconnectCallCount | Should -Be 1
            }
        }
    }
}
