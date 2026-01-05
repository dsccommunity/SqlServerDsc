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

Describe 'Update-SqlDscServer' -Tag 'Public' {
    It 'Should have the correct parameters in parameter set <MockParameterSetName>' -ForEach @(
        @{
            MockParameterSetName   = '__AllParameterSets'
            # cSpell: disable-next
            MockExpectedParameters = '[-MediaPath] <string> [-InstanceName] <string> [[-UpdateSource] <string>] [[-InstanceDir] <string>] [[-InstanceId] <string>] [[-ProductKey] <string>] [[-BrowserSvcStartupType] <string>] [[-FTUpgradeOption] <string>] [[-ISSvcAccount] <string>] [[-ISSvcPassword] <securestring>] [[-ISSvcStartupType] <string>] [[-FailoverClusterRollOwnership] <ushort>] [[-Timeout] <uint>] -AcceptLicensingTerms [-Enu] [-UpdateEnabled] [-AllowUpgradeForSSRSSharePointMode] [-AllowDqRemoval] [-ProductCoveredBySA] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
    ) {
        $result = (Get-Command -Name 'Update-SqlDscServer').ParameterSets |
            Where-Object -FilterScript {
                $_.Name -eq $MockParameterSetName
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

    Context 'When setup action is ''Upgrade''' {
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
                    InstanceName         = 'MSSQLSERVER'
                    ErrorAction          = 'Stop'
                }
            }

            Context 'When using parameter Confirm with value $false' {
                It 'Should call the mock with the correct argument string' {
                    Update-SqlDscServer -Confirm:$false -Force @mockDefaultParameters

                    Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                        $ArgumentList | Should -MatchExactly '\/ACTION=Upgrade'
                        $ArgumentList | Should -MatchExactly '\/INSTANCENAME="MSSQLSERVER"' # cspell: disable-line

                        # Return $true if none of the above throw.
                        $true
                    } -Exactly -Times 1 -Scope It
                }
            }

            Context 'When using parameter Force' {
                It 'Should call the mock with the correct argument string' {
                    Update-SqlDscServer -Force @mockDefaultParameters

                    Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                        $ArgumentList | Should -MatchExactly '\/ACTION=Upgrade'

                        # Return $true if none of the above throw.
                        $true
                    } -Exactly -Times 1 -Scope It
                }
            }

            Context 'When using parameter WhatIf' {
                It 'Should call the mock with the correct argument string' {
                    Update-SqlDscServer -WhatIf @mockDefaultParameters

                    Should -Invoke -CommandName Start-SqlSetupProcess -Exactly -Times 0 -Scope It
                }
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
                MockParameterName  = 'ProductKey'
                MockParameterValue = '12345-12345-12345-12345-12345'
                MockExpectedRegEx  = '\/PID="12345-12345-12345-12345-12345"'
            }
            @{
                MockParameterName  = 'BrowserSvcStartupType'
                MockParameterValue = 'Automatic'
                MockExpectedRegEx  = '\/BROWSERSVCSTARTUPTYPE="Automatic"' # cspell: disable-line
            }
            @{
                MockParameterName  = 'FTUpgradeOption'
                MockParameterValue = 'Rebuild'
                MockExpectedRegEx  = '\/FTUPGRADEOPTION="Rebuild"' # cspell: disable-line
            }
            @{
                MockParameterName  = 'ISSvcAccount'
                MockParameterValue = 'NT Authority\NETWORK SERVICE'
                MockExpectedRegEx  = '\/ISSVCACCOUNT="NT Authority\\NETWORK SERVICE"' # cspell: disable-line
            }
            @{
                MockParameterName  = 'ISSvcPassword'
                MockParameterValue = 'jT7ELPbD2GGuvLmjABDL' | ConvertTo-SecureString -AsPlainText -Force # cspell: disable-line
                MockExpectedRegEx  = '\/ISSVCPASSWORD="jT7ELPbD2GGuvLmjABDL"' # cspell: disable-line
            }
            @{
                MockParameterName  = 'ISSvcStartupType'
                MockParameterValue = 'Automatic'
                MockExpectedRegEx  = '\/ISSVCSTARTUPTYPE="Automatic"' # cspell: disable-line
            }
            @{
                MockParameterName  = 'AllowUpgradeForSSRSSharePointMode'
                MockParameterValue = $true
                MockExpectedRegEx  = '\/ALLOWUPGRADEFORSSRSSHAREPOINTMODE\b' # cspell: disable-line
            }
            @{
                MockParameterName  = 'AllowDqRemoval'
                MockParameterValue = $true
                MockExpectedRegEx  = '\/IACCEPTDQUNINSTALL\b' # cspell: disable-line
            }
            @{
                MockParameterName  = 'FailoverClusterRollOwnership'
                MockParameterValue = 1
                MockExpectedRegEx  = '\/FAILOVERCLUSTERROLLOWNERSHIP=1' # cspell: disable-line
            }
            @{
                MockParameterName  = 'ProductCoveredBySA'
                MockParameterValue = $true
                MockExpectedRegEx  = '\/PRODUCTCOVEREDBYSA\b' # cspell: disable-line
            }
        ) {
            BeforeAll {
                Mock -CommandName Start-SqlSetupProcess -MockWith {
                    return 0
                } -RemoveParameterValidation 'FilePath'
            }

            BeforeEach {
                $updateSqlDscServerParameters = @{
                    AcceptLicensingTerms = $true
                    MediaPath            = '\SqlMedia'
                    InstanceName         = 'MSSQLSERVER'
                    Force                = $true
                }
            }

            It 'Should call the mock with the correct argument string' {
                $updateSqlDscServerParameters.$MockParameterName = $MockParameterValue

                Update-SqlDscServer @updateSqlDscServerParameters

                Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                    $ArgumentList | Should -MatchExactly $MockExpectedRegEx

                    # Return $true if none of the above throw.
                    $true
                } -Exactly -Times 1 -Scope It
            }
        }
    }
}
