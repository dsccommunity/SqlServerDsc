[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies has been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies has not been resolved, this will throw an error.
            Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
        }
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
    }
}

BeforeAll {
    $script:dscModuleName = 'SqlServerDsc'

    $env:SqlServerDscCI = $true

    Import-Module -Name $script:dscModuleName

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscModuleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force

    Remove-Item -Path 'env:SqlServerDscCI'
}

Describe 'Repair-SqlDscBIReportServer' -Tag 'Public' {
    It 'Should have the correct parameters in parameter set <MockParameterSetName>' -ForEach @(
        @{
            MockParameterSetName   = '__AllParameterSets'
            MockExpectedParameters = '[-MediaPath] <string> [[-ProductKey] <string>] [[-Edition] <string>] [[-LogPath] <string>] [[-InstallFolder] <string>] [[-Timeout] <uint>] -AcceptLicensingTerms [-EditionUpgrade] [-SuppressRestart] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
    ) {
        $result = (Get-Command -Name 'Repair-SqlDscBIReportServer').ParameterSets |
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
                    Repair-SqlDscBIReportServer -Confirm:$false @mockDefaultParameters

                    Should -Invoke -CommandName Invoke-ReportServerSetupAction -ParameterFilter {
                        $Repair -eq $true -and
                        $AcceptLicensingTerms -eq $true -and
                        $MediaPath -eq '\PowerBIReportServer.exe'
                    } -Exactly -Times 1 -Scope It
                }
            }

            Context 'When using parameter Force' {
                It 'Should call the Invoke-ReportServerSetupAction with Repair action' {
                    Repair-SqlDscBIReportServer -Force @mockDefaultParameters

                    Should -Invoke -CommandName Invoke-ReportServerSetupAction -ParameterFilter {
                        $Repair -eq $true -and
                        $Force -eq $true
                    } -Exactly -Times 1 -Scope It
                }
            }

            Context 'When using parameter WhatIf' {
                It 'Should call Invoke-ReportServerSetupAction' {
                    Repair-SqlDscBIReportServer -WhatIf @mockDefaultParameters

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
                Repair-SqlDscBIReportServer @repairParameters

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
                Repair-SqlDscBIReportServer @repairParameters

                Should -Invoke -CommandName Invoke-ReportServerSetupAction -ParameterFilter {
                    $Repair -eq $true -and
                    $Edition -eq 'Developer'
                } -Exactly -Times 1 -Scope It
            }
        }
    }
}
