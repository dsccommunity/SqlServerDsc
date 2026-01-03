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

Describe 'Request-SqlDscRSDatabaseScript' {
    Context 'When validating parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = '__AllParameterSets'
                ExpectedParameters = '[-Configuration] <Object> [-DatabaseName] <string> [[-Lcid] <int>] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Request-SqlDscRSDatabaseScript').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }
    }

    Context 'When generating database creation script with default parameters' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod -MockWith {
                return [PSCustomObject] @{
                    Script = 'CREATE DATABASE [ReportServer]'
                }
            }

            Mock -CommandName Get-OperatingSystem -MockWith {
                return [PSCustomObject] @{
                    OSLanguage = 1033
                }
            }
        }

        It 'Should generate script without errors' {
            { $mockCimInstance | Request-SqlDscRSDatabaseScript -DatabaseName 'ReportServer' } | Should -Not -Throw

            Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                $MethodName -eq 'GenerateDatabaseCreationScript' -and
                $Arguments.DatabaseName -eq 'ReportServer' -and
                $Arguments.IsSharePointMode -eq $false -and
                $Arguments.Lcid -eq 1033
            } -Exactly -Times 1
        }

        It 'Should return the script as a string' {
            $result = $mockCimInstance | Request-SqlDscRSDatabaseScript -DatabaseName 'ReportServer'

            $result | Should -Be 'CREATE DATABASE [ReportServer]'
        }
    }

    Context 'When generating database creation script with explicit Lcid' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod -MockWith {
                return [PSCustomObject] @{
                    Script = 'CREATE DATABASE [ReportServer]'
                }
            }
        }

        It 'Should use the specified Lcid' {
            { $mockCimInstance | Request-SqlDscRSDatabaseScript -DatabaseName 'ReportServer' -Lcid 1053 } | Should -Not -Throw

            Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                $Arguments.Lcid -eq 1053
            } -Exactly -Times 1
        }
    }

    Context 'When passing configuration as parameter' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod -MockWith {
                return [PSCustomObject] @{
                    Script = 'CREATE DATABASE [ReportServer]'
                }
            }

            Mock -CommandName Get-OperatingSystem -MockWith {
                return [PSCustomObject] @{
                    OSLanguage = 1033
                }
            }
        }

        It 'Should generate script' {
            { Request-SqlDscRSDatabaseScript -Configuration $mockCimInstance -DatabaseName 'ReportServer' } | Should -Not -Throw

            Should -Invoke -CommandName Invoke-RsCimMethod -Exactly -Times 1
        }
    }

    Context 'When CIM method fails' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod -MockWith {
                throw 'Method GenerateDatabaseCreationScript() failed with an error.'
            }

            Mock -CommandName Get-OperatingSystem -MockWith {
                return [PSCustomObject] @{
                    OSLanguage = 1033
                }
            }
        }

        It 'Should throw a terminating error' {
            { $mockCimInstance | Request-SqlDscRSDatabaseScript -DatabaseName 'ReportServer' } | Should -Throw -ErrorId 'RSRDBS0001,Request-SqlDscRSDatabaseScript'
        }
    }
}
