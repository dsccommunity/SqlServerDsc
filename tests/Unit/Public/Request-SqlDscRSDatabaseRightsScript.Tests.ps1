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

Describe 'Request-SqlDscRSDatabaseRightsScript' {
    Context 'When validating parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = '__AllParameterSets'
                ExpectedParameters = '[-Configuration] <Object> [-DatabaseName] <string> [-UserName] <string> [-IsRemote] [-UseSqlAuthentication] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Request-SqlDscRSDatabaseRightsScript').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }
    }

    Context 'When generating database rights script with default parameters' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod -MockWith {
                return [PSCustomObject] @{
                    Script = 'GRANT SELECT ON [ReportServer] TO [NT SERVICE\SQLServerReportingServices]'
                }
            }
        }

        It 'Should generate script without errors' {
            { $mockCimInstance | Request-SqlDscRSDatabaseRightsScript -DatabaseName 'ReportServer' -UserName 'NT SERVICE\SQLServerReportingServices' } | Should -Not -Throw

            Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                $MethodName -eq 'GenerateDatabaseRightsScript' -and
                $Arguments.DatabaseName -eq 'ReportServer' -and
                $Arguments.UserName -eq 'NT SERVICE\SQLServerReportingServices' -and
                $Arguments.IsRemote -eq $false -and
                $Arguments.IsWindowsUser -eq $true
            } -Exactly -Times 1
        }

        It 'Should return the script as a string' {
            $result = $mockCimInstance | Request-SqlDscRSDatabaseRightsScript -DatabaseName 'ReportServer' -UserName 'NT SERVICE\SQLServerReportingServices'

            $result | Should -Be 'GRANT SELECT ON [ReportServer] TO [NT SERVICE\SQLServerReportingServices]'
        }
    }

    Context 'When generating database rights script for remote database' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod -MockWith {
                return [PSCustomObject] @{
                    Script = 'GRANT SELECT ON [ReportServer] TO [DOMAIN\SQLRSUser]'
                }
            }
        }

        It 'Should set IsRemote to true' {
            { $mockCimInstance | Request-SqlDscRSDatabaseRightsScript -DatabaseName 'ReportServer' -UserName 'DOMAIN\SQLRSUser' -IsRemote } | Should -Not -Throw

            Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                $Arguments.IsRemote -eq $true
            } -Exactly -Times 1
        }
    }

    Context 'When generating database rights script for SQL Server authentication user' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod -MockWith {
                return [PSCustomObject] @{
                    Script = 'GRANT SELECT ON [ReportServer] TO [sqluser]'
                }
            }
        }

        It 'Should set IsWindowsUser to false when UseSqlAuthentication is specified' {
            { $mockCimInstance | Request-SqlDscRSDatabaseRightsScript -DatabaseName 'ReportServer' -UserName 'sqluser' -UseSqlAuthentication } | Should -Not -Throw

            Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                $Arguments.IsWindowsUser -eq $false
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
                    Script = 'GRANT SELECT ON [ReportServer] TO [NT SERVICE\SQLServerReportingServices]'
                }
            }
        }

        It 'Should generate script' {
            { Request-SqlDscRSDatabaseRightsScript -Configuration $mockCimInstance -DatabaseName 'ReportServer' -UserName 'NT SERVICE\SQLServerReportingServices' } | Should -Not -Throw

            Should -Invoke -CommandName Invoke-RsCimMethod -Exactly -Times 1
        }
    }

    Context 'When CIM method fails' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod -MockWith {
                throw 'Method GenerateDatabaseRightsScript() failed with an error.'
            }
        }

        It 'Should throw a terminating error' {
            { $mockCimInstance | Request-SqlDscRSDatabaseRightsScript -DatabaseName 'ReportServer' -UserName 'NT SERVICE\SQLServerReportingServices' } | Should -Throw -ErrorId 'RSRDBRS0001,Request-SqlDscRSDatabaseRightsScript'
        }
    }

    Context 'When IsRemote is used with Windows authentication and invalid username format' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }
        }

        It 'Should throw a terminating error when UserName does not contain a backslash' {
            { $mockCimInstance | Request-SqlDscRSDatabaseRightsScript -DatabaseName 'ReportServer' -UserName 'SQLRSUser' -IsRemote } | Should -Throw -ErrorId 'UserName,New-ArgumentException'
        }

        It 'Should throw a terminating error when UserName contains multiple backslashes' {
            { $mockCimInstance | Request-SqlDscRSDatabaseRightsScript -DatabaseName 'ReportServer' -UserName 'DOMAIN\SUB\SQLRSUser' -IsRemote } | Should -Throw -ErrorId 'UserName,New-ArgumentException'
        }

        It 'Should throw a terminating error when UserName is only a domain' {
            { $mockCimInstance | Request-SqlDscRSDatabaseRightsScript -DatabaseName 'ReportServer' -UserName 'DOMAIN\' -IsRemote } | Should -Throw -ErrorId 'UserName,New-ArgumentException'
        }

        It 'Should throw a terminating error when UserName is only a username' {
            { $mockCimInstance | Request-SqlDscRSDatabaseRightsScript -DatabaseName 'ReportServer' -UserName '\SQLRSUser' -IsRemote } | Should -Throw -ErrorId 'UserName,New-ArgumentException'
        }
    }

    Context 'When IsRemote is used with Windows authentication and valid username format' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod -MockWith {
                return [PSCustomObject] @{
                    Script = 'GRANT SELECT ON [ReportServer] TO [DOMAIN\SQLRSUser]'
                }
            }
        }

        It 'Should not throw when UserName is in <domain>\<username> format' {
            { $mockCimInstance | Request-SqlDscRSDatabaseRightsScript -DatabaseName 'ReportServer' -UserName 'DOMAIN\SQLRSUser' -IsRemote } | Should -Not -Throw
        }

        It 'Should call Invoke-RsCimMethod when username is valid' {
            $mockCimInstance | Request-SqlDscRSDatabaseRightsScript -DatabaseName 'ReportServer' -UserName 'DOMAIN\SQLRSUser' -IsRemote

            Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                $MethodName -eq 'GenerateDatabaseRightsScript' -and
                $Arguments.DatabaseName -eq 'ReportServer' -and
                $Arguments.UserName -eq 'DOMAIN\SQLRSUser' -and
                $Arguments.IsRemote -eq $true -and
                $Arguments.IsWindowsUser -eq $true
            } -Exactly -Times 1
        }
    }

    Context 'When IsRemote is used with SQL Server authentication' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod -MockWith {
                return [PSCustomObject] @{
                    Script = 'GRANT SELECT ON [ReportServer] TO [SqlUser]'
                }
            }
        }

        It 'Should not validate username format when UseSqlAuthentication is specified' {
            { $mockCimInstance | Request-SqlDscRSDatabaseRightsScript -DatabaseName 'ReportServer' -UserName 'SqlUser' -IsRemote -UseSqlAuthentication } | Should -Not -Throw
        }

        It 'Should call Invoke-RsCimMethod with correct parameters' {
            $mockCimInstance | Request-SqlDscRSDatabaseRightsScript -DatabaseName 'ReportServer' -UserName 'SqlUser' -IsRemote -UseSqlAuthentication

            Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                $MethodName -eq 'GenerateDatabaseRightsScript' -and
                $Arguments.DatabaseName -eq 'ReportServer' -and
                $Arguments.UserName -eq 'SqlUser' -and
                $Arguments.IsRemote -eq $true -and
                $Arguments.IsWindowsUser -eq $false
            } -Exactly -Times 1
        }
    }
}
