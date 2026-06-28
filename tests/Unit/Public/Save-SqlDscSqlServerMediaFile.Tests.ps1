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
    $PSDefaultParameterValues['Should-Invoke:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Should-NotInvoke:ModuleName'] = $script:dscModuleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should-Invoke:ModuleName')
    $PSDefaultParameterValues.Remove('Should-NotInvoke:ModuleName')

    Remove-Item -Path 'env:SqlServerDscCI'
}

Describe 'Save-SqlDscSqlServerMediaFile' -Tag 'Public' {
    It 'Should have the correct parameters in parameter set <MockParameterSetName>' -ForEach @(
        @{
            MockParameterSetName = '__AllParameterSets'
            # cSpell: disable-next
            MockExpectedParameters = '[-Url] <string> [-DestinationPath] <FileInfo> [[-FileName] <string>] [[-Language] <string>] [-Quiet] [-Force] [-SkipExecution] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
    ) {
        $result = (Get-Command -Name 'Save-SqlDscSqlServerMediaFile').ParameterSets |
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

        $result.ParameterSetName | Should-Be $MockParameterSetName
        $result.ParameterListAsString | Should-Be $MockExpectedParameters
    }

    BeforeAll {
        # Pester 6 no longer falls through to the real command when a later
        # -ParameterFilter mock doesn't match. Restore the Pester 5 behavior for
        # Test-Path so unmatched calls run the real cmdlet.
        Mock -CommandName Test-Path -MockWith {
            & (Get-Command -Name 'Test-Path' -CommandType Cmdlet) @PesterBoundParameters
        }

        # Mock the Invoke-WebRequest cmdlet to prevent actual downloads during testing
        Mock -CommandName Invoke-WebRequest

        # Mock the Start-Process cmdlet to prevent actual process execution during testing
        Mock -CommandName  Start-Process

        # Mock the Remove-Item cmdlet to prevent actual file deletion during testing
        Mock -CommandName  Remove-Item

        # Mock the Rename-Item cmdlet to prevent actual file renaming during testing
        Mock -CommandName  Rename-Item

        <#
            Mock the Get-Item cmdlet to simulate both that there is no presence
            of a file in the destination path (Count property), and then that we
            successfully downloaded a file to the destination path (FullName property).
        #>
        Mock -CommandName  Get-Item -MockWith {
            return @{
                Count = 0
                FullName = 'C:\Temp\media.iso'
            }
        }

        # Define parameters for the function
        $Url = 'http://example.com/media.iso'
        $DestinationPath = $TestDrive
    }

    Context 'When the URL does not end with .exe' {
        It 'Should call Invoke-WebRequest to download the media file' {
            Save-SqlDscSqlServerMediaFile -Url $Url -DestinationPath $DestinationPath -Confirm:$false

            Should-Invoke -CommandName Invoke-WebRequest -Exactly -Scope It -Times 1
        }
    }

    Context 'When the URL ends with .exe' {
        BeforeAll {
            $Url = "$Url.exe"

            Mock -CommandName Test-Path -MockWith {
                return $false
            } -ParameterFilter {
                $Path -eq (Join-Path -Path $DestinationPath -ChildPath 'media.iso')
            }
        }

        It 'Should call Invoke-WebRequest to download the executable file' {
            Save-SqlDscSqlServerMediaFile -Url $Url -DestinationPath $DestinationPath -Confirm:$false

            Should-Invoke -CommandName Invoke-WebRequest -Exactly -Scope It -Times 1
        }

        It 'Should call Start-Process to initiate download using the downloaded executable file' {
            Save-SqlDscSqlServerMediaFile -Url $Url -DestinationPath $DestinationPath -Confirm:$false

            Should-Invoke -CommandName Start-Process -Exactly -Scope It -Times 1
        }

        It 'Should call Remove-Item to remove the executable file' {
            Save-SqlDscSqlServerMediaFile -Url $Url -DestinationPath $DestinationPath -Confirm:$false

            Should-Invoke -CommandName Remove-Item -Exactly -Scope It -Times 1
        }

        It 'Should call Rename-Item to rename the downloaded ISO file to the specified name' {
            Save-SqlDscSqlServerMediaFile -Url $Url -DestinationPath $DestinationPath -Confirm:$false

            Should-Invoke -CommandName Rename-Item -Exactly -Scope It -Times 1
        }
    }

    Context 'When file is already present and should be overridden' {
        BeforeAll {
            Mock -CommandName Test-Path -MockWith {
                return $true
            } -ParameterFilter {
                $Path -eq (Join-Path -Path $DestinationPath -ChildPath 'media.iso')
            }
        }

        It 'Should remove the existing file' {
            Mock -CommandName Invoke-WebRequest
            Mock -CommandName Remove-Item

            Save-SqlDscSqlServerMediaFile -Url 'https://example.com/media.iso' -DestinationPath $TestDrive -Force

            Should-Invoke -CommandName Invoke-WebRequest -Exactly -Scope It -Times 1
            Should-Invoke -CommandName Remove-Item -Exactly -Scope It -Times 1
        }
    }

    Context 'When the Force parameter is used' {
        It 'Should force the download of the media file' {
            Mock -CommandName Invoke-WebRequest

            Save-SqlDscSqlServerMediaFile -Url 'https://example.com/media.iso' -DestinationPath $TestDrive -Force

            Should-Invoke -CommandName Invoke-WebRequest -Exactly -Scope It -Times 1
        }
    }

    Context 'When the Quiet parameter is used' {
        It 'Should download the media file silently' {
            Mock -CommandName Invoke-WebRequest

            Save-SqlDscSqlServerMediaFile -Url 'https://example.com/media.iso' -DestinationPath $TestDrive -Quiet  -Confirm:$false

            Should-Invoke -CommandName Invoke-WebRequest -Exactly -Scope It -Times 1
        }
    }

    Context 'When the Language parameter is used' {
        It 'Should download the media file in the specified language' {
            Mock -CommandName Invoke-WebRequest
            Mock -CommandName Start-Process

            Save-SqlDscSqlServerMediaFile -Url 'https://example.com/media.exe' -DestinationPath $TestDrive -Language 'fr-FR'  -Confirm:$false

            Should-Invoke -CommandName Invoke-WebRequest -Exactly -Times 1
            Should-Invoke -CommandName Start-Process -Exactly -Times 1
        }
    }

    Context 'When the same ISO file already exists and Force parameter is used' {
        BeforeAll {
            Mock -CommandName Get-Item -MockWith {
                return @(
                    @{
                        FullName = Join-Path -Path $DestinationPath -ChildPath 'media.iso'
                        Count = 1
                    }
                )
            } -ParameterFilter {
                $Path -eq "$DestinationPath/*.iso"
            }

            Mock -CommandName Test-Path -MockWith {
                return $true
            } -ParameterFilter {
                $Path -eq (Join-Path -Path $DestinationPath -ChildPath 'media.iso')
            }

            Mock -CommandName Invoke-WebRequest
            Mock -CommandName Remove-Item
        }

        It 'Should allow overwriting the existing file with Force parameter' {
            Save-SqlDscSqlServerMediaFile -Url 'https://example.com/media.iso' -DestinationPath $DestinationPath -Force

            Should-Invoke -CommandName Invoke-WebRequest -Exactly -Scope It -Times 1
            Should-Invoke -CommandName Remove-Item -Exactly -Scope It -Times 1
        }
    }

    Context 'When URL is an .exe and the same ISO file already exists with Force parameter' {
        BeforeAll {
            $exeUrl = 'https://example.com/installer.exe'

            Mock -CommandName Get-Item -MockWith {
                return @(
                    @{
                        FullName = Join-Path -Path $DestinationPath -ChildPath 'media.iso'
                        Count = 1
                    }
                )
            } -ParameterFilter {
                $Path -eq "$DestinationPath/*.iso"
            }

            Mock -CommandName Test-Path -MockWith {
                return $true
            } -ParameterFilter {
                $Path -eq (Join-Path -Path $DestinationPath -ChildPath 'media.iso')
            }

            Mock -CommandName Invoke-WebRequest
            Mock -CommandName Start-Process
            Mock -CommandName Remove-Item
            Mock -CommandName Rename-Item
        }

        It 'Should allow overwriting the existing file with Force parameter' {
            Save-SqlDscSqlServerMediaFile -Url $exeUrl -DestinationPath $DestinationPath -Force

            Should-Invoke -CommandName Invoke-WebRequest -Exactly -Scope It -Times 1
            Should-Invoke -CommandName Remove-Item -Exactly -ParameterFilter {
                $Path -eq (Join-Path -Path $DestinationPath -ChildPath 'media.iso')
            } -Scope It -Times 1
            Should-Invoke -CommandName Start-Process -Exactly -Scope It -Times 1
            Should-Invoke -CommandName Remove-Item -Exactly -ParameterFilter {
                $Path -eq (Join-Path -Path $DestinationPath -ChildPath 'media.exe')
            } -Scope It -Times 1
        }
    }
}
