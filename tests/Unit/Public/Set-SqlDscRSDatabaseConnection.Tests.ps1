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

Describe 'Set-SqlDscRSDatabaseConnection' {
    Context 'When validating parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = '__AllParameterSets'
                ExpectedParameters = '[-Configuration] <Object> [-ServerName] <string> [[-InstanceName] <string>] [-DatabaseName] <string> [[-Type] <string>] [[-Credential] <pscredential>] [-PassThru] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Set-SqlDscRSDatabaseConnection').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }
    }

    Context 'When setting database connection with ServiceAccount credentials type' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod
        }

        It 'Should set database connection without errors' {
            { $mockCimInstance | Set-SqlDscRSDatabaseConnection -ServerName 'localhost' -DatabaseName 'ReportServer' -Confirm:$false } | Should -Not -Throw

            Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                $MethodName -eq 'SetDatabaseConnection' -and
                $Arguments.Server -eq 'localhost' -and
                $Arguments.DatabaseName -eq 'ReportServer' -and
                $Arguments.Username -eq '' -and
                $Arguments.Password -eq '' -and
                $Arguments.CredentialsType -eq 2
            } -Exactly -Times 1
        }

        It 'Should not return anything by default' {
            $result = $mockCimInstance | Set-SqlDscRSDatabaseConnection -ServerName 'localhost' -DatabaseName 'ReportServer' -Confirm:$false

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'When setting database connection with PassThru' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod
        }

        It 'Should return the configuration CIM instance' {
            $result = $mockCimInstance | Set-SqlDscRSDatabaseConnection -ServerName 'localhost' -DatabaseName 'ReportServer' -PassThru -Confirm:$false

            $result | Should -Not -BeNullOrEmpty
            $result.InstanceName | Should -Be 'SSRS'
        }
    }

    Context 'When setting database connection with Force' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod
        }

        It 'Should set database connection without confirmation' {
            { $mockCimInstance | Set-SqlDscRSDatabaseConnection -ServerName 'localhost' -DatabaseName 'ReportServer' -Force } | Should -Not -Throw

            Should -Invoke -CommandName Invoke-RsCimMethod -Exactly -Times 1
        }
    }

    Context 'When setting database connection with Windows credentials type' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            $mockCredential = [System.Management.Automation.PSCredential]::new(
                'DOMAIN\User',
                (ConvertTo-SecureString -String 'Password123' -AsPlainText -Force)
            )

            Mock -CommandName Invoke-RsCimMethod
        }

        It 'Should use the Windows credentials type (0)' {
            { $mockCimInstance | Set-SqlDscRSDatabaseConnection -ServerName 'localhost' -DatabaseName 'ReportServer' -Type 'Windows' -Credential $mockCredential -Confirm:$false } | Should -Not -Throw

            Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                $Arguments.CredentialsType -eq 0 -and
                $Arguments.Username -eq 'DOMAIN\User' -and
                $Arguments.Password -eq 'Password123'
            } -Exactly -Times 1
        }
    }

    Context 'When setting database connection with SqlServer credentials type' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            $mockCredential = [System.Management.Automation.PSCredential]::new(
                'sa',
                (ConvertTo-SecureString -String 'SqlPassword123' -AsPlainText -Force)
            )

            Mock -CommandName Invoke-RsCimMethod
        }

        It 'Should use the SqlServer credentials type (1)' {
            { $mockCimInstance | Set-SqlDscRSDatabaseConnection -ServerName 'localhost' -DatabaseName 'ReportServer' -Type 'SqlServer' -Credential $mockCredential -Confirm:$false } | Should -Not -Throw

            Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                $Arguments.CredentialsType -eq 1 -and
                $Arguments.Username -eq 'sa' -and
                $Arguments.Password -eq 'SqlPassword123'
            } -Exactly -Times 1
        }
    }

    Context 'When setting database connection with ServiceAccount credentials type explicitly' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod
        }

        It 'Should use the ServiceAccount credentials type (2)' {
            { $mockCimInstance | Set-SqlDscRSDatabaseConnection -ServerName 'localhost' -DatabaseName 'ReportServer' -Type 'ServiceAccount' -Confirm:$false } | Should -Not -Throw

            Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                $Arguments.CredentialsType -eq 2 -and
                $Arguments.Username -eq '' -and
                $Arguments.Password -eq ''
            } -Exactly -Times 1
        }
    }

    Context 'When Windows credentials type is specified without Credential parameter' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod
        }

        It 'Should throw a terminating error' {
            { $mockCimInstance | Set-SqlDscRSDatabaseConnection -ServerName 'localhost' -DatabaseName 'ReportServer' -Type 'Windows' -Confirm:$false } | Should -Throw -ErrorId 'SSRSDC0002,Set-SqlDscRSDatabaseConnection'
        }
    }

    Context 'When SqlServer credentials type is specified without Credential parameter' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod
        }

        It 'Should throw a terminating error' {
            { $mockCimInstance | Set-SqlDscRSDatabaseConnection -ServerName 'localhost' -DatabaseName 'ReportServer' -Type 'SqlServer' -Confirm:$false } | Should -Throw -ErrorId 'SSRSDC0002,Set-SqlDscRSDatabaseConnection'
        }
    }

    Context 'When CIM method fails' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod -MockWith {
                throw 'Method SetDatabaseConnection() failed with an error. Error: Access denied (HRESULT:-2147024891)'
            }
        }

        It 'Should throw a terminating error' {
            { $mockCimInstance | Set-SqlDscRSDatabaseConnection -ServerName 'localhost' -DatabaseName 'ReportServer' -Confirm:$false } | Should -Throw -ErrorId 'SSRSDC0001,Set-SqlDscRSDatabaseConnection'
        }
    }

    Context 'When using WhatIf' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod
        }

        It 'Should not call Invoke-RsCimMethod' {
            $mockCimInstance | Set-SqlDscRSDatabaseConnection -ServerName 'localhost' -DatabaseName 'ReportServer' -WhatIf

            Should -Invoke -CommandName Invoke-RsCimMethod -Exactly -Times 0
        }
    }

    Context 'When passing configuration as parameter' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod
        }

        It 'Should set database connection' {
            { Set-SqlDscRSDatabaseConnection -Configuration $mockCimInstance -ServerName 'localhost' -DatabaseName 'ReportServer' -Confirm:$false } | Should -Not -Throw

            Should -Invoke -CommandName Invoke-RsCimMethod -Exactly -Times 1
        }
    }

    Context 'When using named instance database server' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod
        }

        It 'Should pass the correct server name format when InstanceName is specified' {
            { $mockCimInstance | Set-SqlDscRSDatabaseConnection -ServerName 'SqlServer01' -InstanceName 'MSSQLSERVER' -DatabaseName 'ReportServer' -Confirm:$false } | Should -Not -Throw

            Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                $Arguments.Server -eq 'SqlServer01\MSSQLSERVER'
            } -Exactly -Times 1
        }

        It 'Should pass only the server name when InstanceName is not specified' {
            { $mockCimInstance | Set-SqlDscRSDatabaseConnection -ServerName 'SqlServer01' -DatabaseName 'ReportServer' -Confirm:$false } | Should -Not -Throw

            Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                $Arguments.Server -eq 'SqlServer01'
            } -Exactly -Times 1
        }
    }

    Context 'When using custom database name' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod
        }

        It 'Should pass the correct database name' {
            { $mockCimInstance | Set-SqlDscRSDatabaseConnection -ServerName 'localhost' -DatabaseName 'ReportServer$SSRS' -Confirm:$false } | Should -Not -Throw

            Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                $Arguments.DatabaseName -eq 'ReportServer$SSRS'
            } -Exactly -Times 1
        }
    }
}
