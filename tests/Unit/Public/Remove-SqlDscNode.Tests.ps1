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

Describe 'Remove-SqlDscNode' -Tag 'Public' {
    It 'Should have the correct parameters in parameter set <MockParameterSetName>' -ForEach @(
        @{
            MockParameterSetName   = '__AllParameterSets'
            # cSpell: disable-next
            MockExpectedParameters = '[-MediaPath] <string> [-InstanceName] <string> [[-Timeout] <uint>] [-ConfirmIPDependencyChange] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
    ) {
        $result = (Get-Command -Name 'Remove-SqlDscNode').ParameterSets |
            Where-Object -FilterScript {
                $_.Name -eq $mockParameterSetName
            } |
            Select-Object -Property @(
                @{
                    Name       = 'ParameterSetName'
                    Expression = { $_.Name }
                },
                @{
                    Name       = 'ParameterListAsString'
                    Expression = { $_.ToString() }
                }
            )

        $result.ParameterSetName | Should -Be $MockParameterSetName
        $result.ParameterListAsString | Should -Be $MockExpectedParameters
    }

    Context 'When setup action is ''RemoveNode''' {
        BeforeAll {
            Mock -CommandName Assert-SetupActionProperties
            Mock -CommandName Assert-ElevatedUser
            Mock -CommandName Test-Path -ParameterFilter {
                $Path -match 'setup\.exe'
            } -MockWith {
                return $true
            }
        }

        Context 'When specifying only mandatory parameters' {
            BeforeAll {
                Mock -CommandName Start-SqlSetupProcess -MockWith {
                    return 0
                } -RemoveParameterValidation 'FilePath'

                $mockDefaultParameters = @{
                    MediaPath    = '\SqlMedia'
                    InstanceName = 'INSTANCE'
                    ErrorAction  = 'Stop'
                }
            }

            Context 'When using parameter Confirm with value $false' {
                It 'Should call the mock with the correct argument string' {
                    Remove-SqlDscNode -Confirm:$false @mockDefaultParameters

                    Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                        $ArgumentList | Should -MatchExactly '\/ACTION=RemoveNode'
                        $ArgumentList | Should -MatchExactly '\/INSTANCENAME="INSTANCE"' # cspell: disable-line

                        # Return $true if none of the above throw.
                        $true
                    } -Exactly -Times 1 -Scope It
                }
            }

            Context 'When using parameter Force' {
                It 'Should call the mock with the correct argument string' {
                    Remove-SqlDscNode -Force @mockDefaultParameters

                    Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                        $ArgumentList | Should -MatchExactly '\/ACTION=RemoveNode'
                        $ArgumentList | Should -MatchExactly '\/INSTANCENAME="INSTANCE"' # cspell: disable-line

                        # Return $true if none of the above throw.
                        $true
                    } -Exactly -Times 1 -Scope It
                }
            }

            Context 'When using parameter WhatIf' {
                It 'Should call the mock with the correct argument string' {
                    Remove-SqlDscNode -WhatIf @mockDefaultParameters

                    Should -Invoke -CommandName Start-SqlSetupProcess -Exactly -Times 0 -Scope It
                }
            }
        }

        Context 'When specifying optional parameter <MockParameterName>' -ForEach @(
            @{
                MockParameterName  = 'ConfirmIPDependencyChange'
                MockParameterValue = $true
                MockExpectedRegEx  = '\/CONFIRMIPDEPENDENCYCHANGE=1' # cspell: disable-line
            }
        ) {
            BeforeAll {
                Mock -CommandName Start-SqlSetupProcess -MockWith {
                    return 0
                } -RemoveParameterValidation 'FilePath'

                $mockDefaultParameters = @{
                    MediaPath    = '\SqlMedia'
                    InstanceName = 'INSTANCE'
                    Force        = $true
                    ErrorAction  = 'Stop'
                }
            }

            BeforeEach {
                $removeSqlDscNodeParameters = $mockDefaultParameters.Clone()
            }

            It 'Should call the mock with the correct argument string' {
                $removeSqlDscNodeParameters.$MockParameterName = $MockParameterValue

                Remove-SqlDscNode @removeSqlDscNodeParameters

                Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                    $ArgumentList | Should -MatchExactly $MockExpectedRegEx

                    # Return $true if none of the above throw.
                    $true
                } -Exactly -Times 1 -Scope It
            }
        }
    }
}
