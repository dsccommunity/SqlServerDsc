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

Describe 'Initialize-SqlDscImage' -Tag 'Public' {
    It 'Should have the correct parameters in parameter set <MockParameterSetName>' -ForEach @(
        @{
            MockParameterSetName   = '__AllParameterSets'
            # cSpell: disable-next
            MockExpectedParameters = '[-MediaPath] <string> [-Features] <string[]> [[-UpdateSource] <string>] [[-InstallSharedDir] <string>] [[-InstallSharedWowDir] <string>] [[-InstanceDir] <string>] [[-InstanceId] <string>] [[-PBEngSvcAccount] <string>] [[-PBEngSvcPassword] <securestring>] [[-PBEngSvcStartupType] <string>] [[-PBStartPortRange] <ushort>] [[-PBEndPortRange] <ushort>] [[-Timeout] <uint>] -AcceptLicensingTerms [-IAcknowledgeEntCalLimits] [-Enu] [-UpdateEnabled] [-PBScaleOut] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
    ) {
        $result = (Get-Command -Name 'Initialize-SqlDscImage').ParameterSets |
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

    Context 'When setup action is ''PrepareImage''' {
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
                    AcceptLicensingTerms = $true
                    MediaPath            = '\SqlMedia'
                    Features             = 'SQLENGINE'
                    InstanceId           = 'MSSQLSERVER'
                    Force                = $true
                    ErrorAction          = 'Stop'
                }
            }

            Context 'When using parameter Confirm with value $false' {
                It 'Should call the mock with the correct argument string' {
                    Initialize-SqlDscImage -Confirm:$false @mockDefaultParameters

                    Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                        $ArgumentList | Should -MatchExactly '\/ACTION=PrepareImage'
                        $ArgumentList | Should -MatchExactly '\/FEATURES=SQLENGINE'
                        $ArgumentList | Should -MatchExactly '\/INSTANCEID="MSSQLSERVER"'

                        # Return $true if none of the above throw.
                        $true
                    } -Exactly -Times 1 -Scope It
                }
            }

            Context 'When using parameter Force' {
                It 'Should call the mock with the correct argument string' {
                    Initialize-SqlDscImage -Force @mockDefaultParameters

                    Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                        $ArgumentList | Should -MatchExactly '\/ACTION=PrepareImage'

                        # Return $true if none of the above throw.
                        $true
                    } -Exactly -Times 1 -Scope It
                }
            }

            Context 'When using parameter WhatIf' {
                It 'Should call the mock with the correct argument string' {
                    Initialize-SqlDscImage -WhatIf @mockDefaultParameters

                    Should -Invoke -CommandName Start-SqlSetupProcess -Exactly -Times 0 -Scope It
                }
            }
        }

        Context 'When specifying optional parameters PBStartPortRange and PBEndPortRange' {
            BeforeAll {
                Mock -CommandName Start-SqlSetupProcess -MockWith {
                    return 0
                } -RemoveParameterValidation 'FilePath'

                $initializeSqlDscImageParameters = @{
                    AcceptLicensingTerms = $true
                    MediaPath            = '\SqlMedia'
                    Features             = 'SQLENGINE'
                    InstanceId           = 'MSSQLSERVER'
                    Force                = $true
                    PBStartPortRange     = 16450
                    PBEndPortRange       = 16460
                }
            }

            It 'Should call the mock with the correct argument string' {
                Initialize-SqlDscImage @initializeSqlDscImageParameters

                Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                    $ArgumentList | Should -MatchExactly 'PBPORTRANGE=16450-16460' # cspell: disable-line

                    # Return $true if none of the above throw.
                    $true
                } -Exactly -Times 1 -Scope It
            }
        }

        Context 'When specifying optional parameter <MockParameterName>' -ForEach @(
            @{
                MockParameterName  = 'Enu'
                MockParameterValue = $true
                MockExpectedRegEx  = '\/ENU\s*'
            }
            @{
                MockParameterName  = 'UpdateEnabled'
                MockParameterValue = $true
                MockExpectedRegEx  = '\/UPDATEENABLED=True'
            }
            @{
                MockParameterName  = 'UpdateSource'
                MockParameterValue = 'C:\Updates'
                MockExpectedRegEx  = '\/UPDATESOURCE="C:\\Updates"'
            }
            @{
                MockParameterName  = 'InstallSharedDir'
                MockParameterValue = 'C:\Program Files\Microsoft SQL Server'
                MockExpectedRegEx  = '\/INSTALLSHAREDDIR="C:\\Program Files\\Microsoft SQL Server"' # cspell: disable-line
            }
            @{
                MockParameterName  = 'InstallSharedWowDir'
                MockParameterValue = 'C:\Program Files (x86)\Microsoft SQL Server'
                MockExpectedRegEx  = '\/INSTALLSHAREDWOWDIR="C:\\Program Files \(x86\)\\Microsoft SQL Server"' # cspell: disable-line
            }
            @{
                MockParameterName  = 'InstanceDir'
                MockParameterValue = 'C:\Program Files\Microsoft SQL Server'
                MockExpectedRegEx  = '\/INSTANCEDIR="C:\\Program Files\\Microsoft SQL Server"' # cspell: disable-line
            }
            @{
                MockParameterName  = 'InstanceId'
                MockParameterValue = 'INSTANCE'
                MockExpectedRegEx  = '\/INSTANCEID="INSTANCE"' # cspell: disable-line
            }
            @{
                MockParameterName  = 'PBEngSvcAccount'
                MockParameterValue = 'NT Authority\NETWORK SERVICE'
                MockExpectedRegEx  = '\/PBENGSVCACCOUNT="NT Authority\\NETWORK SERVICE"' # cspell: disable-line
            }
            @{
                MockParameterName  = 'PBEngSvcPassword'
                MockParameterValue = 'jT7ELPbD2GGuvLmjABDL' | ConvertTo-SecureString -AsPlainText -Force # cspell: disable-line
                MockExpectedRegEx  = '\/PBENGSVCPASSWORD="jT7ELPbD2GGuvLmjABDL"' # cspell: disable-line
            }
            @{
                MockParameterName  = 'PBEngSvcStartupType'
                MockParameterValue = 'Automatic'
                MockExpectedRegEx  = '\/PBENGSVCSTARTUPTYPE="Automatic"' # cspell: disable-line
            }
            @{
                MockParameterName  = 'PBScaleOut'
                MockParameterValue = $true
                MockExpectedRegEx  = '\/PBSCALEOUT=True' # cspell: disable-line
            }
        ) {
            BeforeAll {
                Mock -CommandName Start-SqlSetupProcess -MockWith {
                    return 0
                } -RemoveParameterValidation 'FilePath'

                $initializeSqlDscImageParameters = @{
                    AcceptLicensingTerms = $true
                    MediaPath            = '\SqlMedia'
                    Features             = 'SQLENGINE'
                    InstanceId           = 'MSSQLSERVER'
                    Force                = $true
                }
            }

            It 'Should call the mock with the correct argument string' {
                $initializeSqlDscImageParameters.$MockParameterName = $MockParameterValue

                Initialize-SqlDscImage @initializeSqlDscImageParameters

                Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                    $ArgumentList | Should -MatchExactly $MockExpectedRegEx

                    # Return $true if none of the above throw.
                    $true
                } -Exactly -Times 1 -Scope It
            }
        }
    }
}
