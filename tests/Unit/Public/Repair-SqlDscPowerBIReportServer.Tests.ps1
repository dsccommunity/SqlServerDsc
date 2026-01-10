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

Describe 'Repair-SqlDscPowerBIReportServer' -Tag 'Public' {
    It 'Should have the correct parameters in parameter set <MockParameterSetName>' -ForEach @(
        @{
            MockParameterSetName   = '__AllParameterSets'
            MockExpectedParameters = '[-MediaPath] <string> [[-ProductKey] <string>] [[-Edition] <string>] [[-LogPath] <string>] [[-InstallFolder] <string>] [[-Timeout] <uint>] -AcceptLicensingTerms [-EditionUpgrade] [-SuppressRestart] [-Force] [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
    ) {
        $result = (Get-Command -Name 'Repair-SqlDscPowerBIReportServer').ParameterSets |
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

    Context 'When repairing SQL Server Power BI Report Server' {
        BeforeAll {
            Mock -CommandName Invoke-ReportServerSetupAction -RemoveParameterValidation @(
                'MediaPath',
                'InstallFolder'
            )
        }

        Context 'When using mandatory parameters only' {
            BeforeAll {
                $mockDefaultParameters = @{
                    AcceptLicensingTerms = $true
                    MediaPath           = '\PowerBIReportServer.exe'
                    ErrorAction         = 'Stop'
                }
            }

            Context 'When using parameter Confirm with value $false' {
                It 'Should call the Invoke-ReportServerSetupAction with Repair action' {
                    Repair-SqlDscPowerBIReportServer -Confirm:$false @mockDefaultParameters

                    Should -Invoke -CommandName Invoke-ReportServerSetupAction -ParameterFilter {
                        $Repair -eq $true -and
                        $AcceptLicensingTerms -eq $true -and
                        $MediaPath -eq '\PowerBIReportServer.exe'
                    } -Exactly -Times 1 -Scope It
                }
            }

            Context 'When using parameter Force' {
                It 'Should call the Invoke-ReportServerSetupAction with Repair action' {
                    Repair-SqlDscPowerBIReportServer -Force @mockDefaultParameters

                    Should -Invoke -CommandName Invoke-ReportServerSetupAction -ParameterFilter {
                        $Repair -eq $true -and
                        $Force -eq $true
                    } -Exactly -Times 1 -Scope It
                }
            }

            Context 'When using parameter WhatIf' {
                It 'Should call Invoke-ReportServerSetupAction' {
                    Repair-SqlDscPowerBIReportServer -WhatIf @mockDefaultParameters

                    Should -Invoke -CommandName Invoke-ReportServerSetupAction -Exactly -Times 1     -Scope It
                }
            }
        }

        Context 'When using optional parameters' {
            BeforeAll {
                $repairParameters = @{
                    AcceptLicensingTerms = $true
                    MediaPath           = '\PowerBIReportServer.exe'
                    ProductKey          = '12345-12345-12345-12345-12345'
                    EditionUpgrade      = $true
                    LogPath             = 'C:\Logs\Repair.log'
                    InstallFolder       = 'C:\Program Files\Power BI Report Server'
                    SuppressRestart     = $true
                    Timeout             = 3600
                    Force               = $true
                    ErrorAction         = 'Stop'
                }
            }

            It 'Should pass all parameters to Invoke-ReportServerSetupAction' {
                Repair-SqlDscPowerBIReportServer @repairParameters

                Should -Invoke -CommandName Invoke-ReportServerSetupAction -ParameterFilter {
                    $Repair -eq $true -and
                    $AcceptLicensingTerms -eq $true -and
                    $MediaPath -eq '\PowerBIReportServer.exe' -and
                    $ProductKey -eq '12345-12345-12345-12345-12345' -and
                    $EditionUpgrade -eq $true -and
                    $LogPath -eq 'C:\Logs\Repair.log' -and
                    $InstallFolder -eq 'C:\Program Files\Power BI Report Server' -and
                    $SuppressRestart -eq $true -and
                    $Timeout -eq 3600 -and
                    $Force -eq $true
                } -Exactly -Times 1 -Scope It
            }
        }

        Context 'When using Edition instead of ProductKey' {
            BeforeAll {
                $repairParameters = @{
                    AcceptLicensingTerms = $true
                    MediaPath           = '\PowerBIReportServer.exe'
                    Edition             = 'Developer'
                    Force               = $true
                    ErrorAction         = 'Stop'
                }
            }

            It 'Should pass the Edition parameter to Invoke-ReportServerSetupAction' {
                Repair-SqlDscPowerBIReportServer @repairParameters

                Should -Invoke -CommandName Invoke-ReportServerSetupAction -ParameterFilter {
                    $Repair -eq $true -and
                    $Edition -eq 'Developer'
                } -Exactly -Times 1 -Scope It
            }
        }

        Context 'When using PassThru parameter' {
            BeforeAll {
                $mockDefaultParameters = @{
                    AcceptLicensingTerms = $true
                    MediaPath           = '\PowerBIReportServer.exe'
                    Force               = $true
                    ErrorAction         = 'Stop'
                }

                # Mock the Invoke-ReportServerSetupAction to return an exit code
                Mock -CommandName Invoke-ReportServerSetupAction -MockWith {
                    return 3010
                }
            }

            It 'Should return the exit code when PassThru is specified' {
                $result = Repair-SqlDscPowerBIReportServer -PassThru @mockDefaultParameters

                $result | Should -Be 3010
                $result | Should -BeOfType [System.Int32]

                Should -Invoke -CommandName Invoke-ReportServerSetupAction
            }

            It 'Should not return an exit code when PassThru is not specified' {
                $result = Repair-SqlDscPowerBIReportServer @mockDefaultParameters

                $result | Should -BeNullOrEmpty

                Should -Invoke -CommandName Invoke-ReportServerSetupAction
            }
        }
    }
}
