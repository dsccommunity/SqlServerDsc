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
    $script:dscModuleName = 'SqlServerDsc'

    $env:SqlServerDscCI = $true

    Import-Module -Name $script:dscModuleName -Force -ErrorAction 'Stop'

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

Describe 'Get-SqlDscSetupLog' -Tag 'Public' {
    Context 'When the setup log file exists' {
        BeforeAll {
            Mock -CommandName Test-Path -MockWith {
                return $true
            }

            Mock -CommandName Get-ChildItem -MockWith {
                $mockFileInfo = New-Object -TypeName PSObject
                $mockFileInfo | Add-Member -MemberType NoteProperty -Name 'FullName' -Value 'C:\Program Files\Microsoft SQL Server\150\Setup Bootstrap\Log\Summary.txt'
                $mockFileInfo | Add-Member -MemberType NoteProperty -Name 'LastWriteTime' -Value ([DateTime]::Now)

                return $mockFileInfo
            }

            Mock -CommandName Get-Content -MockWith {
                return @(
                    'Overall summary:',
                    '  Final result:                  Passed',
                    '  Exit code (Decimal):           0'
                )
            }
        }

        It 'Should return the log content with header and footer using default parameters' {
            $result = Get-SqlDscSetupLog

            $result | Should -HaveCount 5
            $result[0] | Should -Match 'SQL Server Setup.*Summary\.txt.*from'
            $result[1] | Should -Be 'Overall summary:'
            $result[2] | Should -Be '  Final result:                  Passed'
            $result[3] | Should -Be '  Exit code (Decimal):           0'
            $result[4] | Should -Match 'End of.*Summary\.txt'
        }

        It 'Should call Get-ChildItem with the correct default parameters' {
            $result = Get-SqlDscSetupLog

            Should -Invoke -CommandName Get-ChildItem -ParameterFilter {
                $Path -eq 'C:\Program Files\Microsoft SQL Server' -and
                $Filter -eq 'Summary.txt' -and
                $Recurse -eq $true
            } -Exactly -Times 1
        }

        It 'Should call Get-ChildItem with custom path' {
            $result = Get-SqlDscSetupLog -Path 'D:\SQLServer'

            Should -Invoke -CommandName Get-ChildItem -ParameterFilter {
                $Path -eq 'D:\SQLServer' -and
                $Filter -eq 'Summary.txt' -and
                $Recurse -eq $true
            } -Exactly -Times 1
        }



        It 'Should call Get-Content with the correct file path' {
            $result = Get-SqlDscSetupLog

            Should -Invoke -CommandName Get-Content -ParameterFilter {
                $Path -eq 'C:\Program Files\Microsoft SQL Server\150\Setup Bootstrap\Log\Summary.txt'
            } -Exactly -Times 1
        }
    }

    Context 'When multiple setup log files exist' {
        BeforeAll {
            Mock -CommandName Test-Path -MockWith {
                return $true
            }

            Mock -CommandName Get-ChildItem -MockWith {
                $mockFileInfo1 = New-Object -TypeName PSObject
                $mockFileInfo1 | Add-Member -MemberType NoteProperty -Name 'FullName' -Value 'C:\Program Files\Microsoft SQL Server\150\Setup Bootstrap\Log\Summary.txt'
                $mockFileInfo1 | Add-Member -MemberType NoteProperty -Name 'LastWriteTime' -Value ([DateTime]::Now.AddDays(-1))

                $mockFileInfo2 = New-Object -TypeName PSObject
                $mockFileInfo2 | Add-Member -MemberType NoteProperty -Name 'FullName' -Value 'C:\Program Files\Microsoft SQL Server\160\Setup Bootstrap\Log\Summary.txt'
                $mockFileInfo2 | Add-Member -MemberType NoteProperty -Name 'LastWriteTime' -Value ([DateTime]::Now)

                return @($mockFileInfo1, $mockFileInfo2)
            }

            Mock -CommandName Get-Content -MockWith {
                return @('Most recent log content')
            }
        }

        It 'Should return the most recent log file' {
            $result = Get-SqlDscSetupLog

            $result[0] | Should -Match '160\\Setup Bootstrap\\Log\\Summary\.txt'

            Should -Invoke -CommandName Get-Content -ParameterFilter {
                $Path -eq 'C:\Program Files\Microsoft SQL Server\160\Setup Bootstrap\Log\Summary.txt'
            } -Exactly -Times 1
        }
    }

    Context 'When the setup log file does not exist' {
        BeforeAll {
            Mock -CommandName Test-Path -MockWith {
                return $true
            }

            Mock -CommandName Get-ChildItem -MockWith {
                return $null
            }
        }

        It 'Should return a message indicating no log file was found' {
            $result = Get-SqlDscSetupLog

            $result | Should -BeNullOrEmpty
        }

        It 'Should not call Get-Content' {
            Mock -CommandName Get-Content -MockWith {
                throw 'Get-Content should not be called'
            }

            $result = Get-SqlDscSetupLog

            Should -Invoke -CommandName Get-Content -Exactly -Times 0
        }
    }

    Context 'When the specified path does not exist' {
        BeforeAll {
            Mock -CommandName Test-Path -MockWith {
                return $false
            }

            Mock -CommandName Get-ChildItem -MockWith {
                throw 'Get-ChildItem should not be called when path does not exist'
            }

            Mock -CommandName Write-Error
        }

        It 'Should return null without searching for files' {
            $result = Get-SqlDscSetupLog -Path 'C:\NonExistentPath' -ErrorAction 'SilentlyContinue'

            $result | Should -BeNullOrEmpty
        }

        It 'Should not call Get-ChildItem when path does not exist' {
            $result = Get-SqlDscSetupLog -Path 'C:\NonExistentPath' -ErrorAction 'SilentlyContinue'

            Should -Invoke -CommandName Get-ChildItem -Exactly -Times 0
        }

        It 'Should call Test-Path with the correct parameters' {
            $result = Get-SqlDscSetupLog -Path 'C:\NonExistentPath' -ErrorAction 'SilentlyContinue'

            Should -Invoke -CommandName Test-Path -ParameterFilter {
                $Path -eq 'C:\NonExistentPath' -and
                $PathType -eq 'Container'
            } -Exactly -Times 1
        }

        It 'Should call Write-Error with the correct parameters' {
            $result = Get-SqlDscSetupLog -Path 'C:\NonExistentPath' -ErrorAction 'SilentlyContinue'

            Should -Invoke -CommandName Write-Error -ParameterFilter {
                $Message -match 'C:\\NonExistentPath' -and
                $Category -eq 'ObjectNotFound' -and
                $ErrorId -eq 'GSDSL0006' -and
                $TargetObject -eq 'C:\NonExistentPath'
            } -Exactly -Times 1
        }
    }

    Context 'When the specified path does not exist and ErrorAction is Stop' {
        BeforeAll {
            Mock -CommandName Test-Path -MockWith {
                return $false
            }

            Mock -CommandName Get-ChildItem -MockWith {
                throw 'Get-ChildItem should not be called when path does not exist'
            }
        }

        It 'Should throw a terminating error when using ErrorAction Stop' {
            {
                Get-SqlDscSetupLog -Path 'C:\NonExistentPath' -ErrorAction 'Stop'
            } | Should -Throw -ErrorId 'GSDSL0006,Get-SqlDscSetupLog'
        }
    }

    Context 'When filtering for Setup Bootstrap\Log directory' {
        BeforeAll {
            Mock -CommandName Test-Path -MockWith {
                return $true
            }

            Mock -CommandName Get-ChildItem -MockWith {
                $mockFileInfo1 = New-Object -TypeName PSObject
                $mockFileInfo1 | Add-Member -MemberType NoteProperty -Name 'FullName' -Value 'C:\Program Files\Microsoft SQL Server\SomeOtherLocation\Summary.txt'
                $mockFileInfo1 | Add-Member -MemberType NoteProperty -Name 'LastWriteTime' -Value ([DateTime]::Now)

                $mockFileInfo2 = New-Object -TypeName PSObject
                $mockFileInfo2 | Add-Member -MemberType NoteProperty -Name 'FullName' -Value 'C:\Program Files\Microsoft SQL Server\150\Setup Bootstrap\Log\Summary.txt'
                $mockFileInfo2 | Add-Member -MemberType NoteProperty -Name 'LastWriteTime' -Value ([DateTime]::Now.AddMinutes(-5))

                return @($mockFileInfo1, $mockFileInfo2)
            }

            Mock -CommandName Get-Content -MockWith {
                return @('Bootstrap log content')
            }
        }

        It 'Should only return files from Setup Bootstrap\Log directory' {
            $result = Get-SqlDscSetupLog

            $result[0] | Should -Match 'Setup Bootstrap\\Log\\Summary\.txt'
            $result[0] | Should -Not -Match 'SomeOtherLocation'
        }
    }

    Context 'Parameter validation' {
        It 'Should have the correct parameters in parameter set __AllParameterSets' {
            $result = (Get-Command -Name 'Get-SqlDscSetupLog').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq '__AllParameterSets' } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be '__AllParameterSets'
            $result.ParameterListAsString | Should -Be '[[-Path] <String>] [<CommonParameters>]'
        }

        It 'Should have Path as an optional parameter' {
            $commandInfo = Get-Command -Name 'Get-SqlDscSetupLog'
            $commandInfo.Parameters['Path'].Attributes.Mandatory | Should -BeFalse
        }

        It 'Should have the correct output type' {
            $commandInfo = Get-Command -Name 'Get-SqlDscSetupLog'
            $commandInfo.OutputType.Name | Should -Contain 'System.String[]'
        }
    }
}
