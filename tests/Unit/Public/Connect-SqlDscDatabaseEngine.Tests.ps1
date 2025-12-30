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

    # Loading mocked classes
    Add-Type -Path (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '../Stubs') -ChildPath 'SMO.cs')

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

Describe 'Connect-SqlDscDatabaseEngine' -Tag 'Public' {
    It 'Should have the correct parameters in parameter set <MockParameterSetName>' -ForEach @(
        @{
            MockParameterSetName   = 'SqlServer'
            # cSpell: disable-next
            MockExpectedParameters = '[-ServerName <string>] [-InstanceName <string>] [-Protocol <string>] [-Port <ushort>] [-StatementTimeout <int>] [-Encrypt] [<CommonParameters>]'
        }
        @{
            MockParameterSetName   = 'SqlServerWithCredential'
            # cSpell: disable-next
            MockExpectedParameters = '-Credential <pscredential> [-ServerName <string>] [-InstanceName <string>] [-LoginType <string>] [-Protocol <string>] [-Port <ushort>] [-StatementTimeout <int>] [-Encrypt] [<CommonParameters>]'
        }
    ) {
        $result = (Get-Command -Name 'Connect-SqlDscDatabaseEngine').ParameterSets |
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

    Context 'When connecting to an instance' {
        BeforeAll {
            Mock -CommandName Connect-Sql

            $mockCredentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @(
                'COMPANY\SqlAdmin',
                ('dummyPassW0rd' | ConvertTo-SecureString -AsPlainText -Force)
            )
        }

        It 'Should call the correct mock with the expected parameters' {
            $mockConnectSqlDscDatabaseEngineParameters = @{
                ServerName       = 'MyServer'
                InstanceName     = 'MyInstance'
                Credential       = $mockCredentials
                LoginType        = 'WindowsUser'
                StatementTimeout = 800
            }

            Connect-SqlDscDatabaseEngine @mockConnectSqlDscDatabaseEngineParameters

            Should -Invoke -CommandName Connect-Sql -ParameterFilter {
                $ServerName -eq 'MyServer' -and
                $InstanceName -eq 'MyInstance' -and
                $Credential -eq $mockCredentials -and
                $LoginType -eq 'WindowsUser' -and
                $StatementTimeout -eq 800
            }
        }

        It 'Should pass Protocol parameter to Connect-Sql' {
            $mockConnectSqlDscDatabaseEngineParameters = @{
                ServerName   = 'MyServer'
                InstanceName = 'MyInstance'
                Protocol     = 'tcp'
            }

            Connect-SqlDscDatabaseEngine @mockConnectSqlDscDatabaseEngineParameters

            Should -Invoke -CommandName Connect-Sql -ParameterFilter {
                $ServerName -eq 'MyServer' -and
                $InstanceName -eq 'MyInstance' -and
                $Protocol -eq 'tcp'
            }
        }

        It 'Should pass Port parameter to Connect-Sql' {
            $mockConnectSqlDscDatabaseEngineParameters = @{
                ServerName   = 'MyServer'
                InstanceName = 'MSSQLSERVER'
                Port         = 1433
            }

            Connect-SqlDscDatabaseEngine @mockConnectSqlDscDatabaseEngineParameters

            Should -Invoke -CommandName Connect-Sql -ParameterFilter {
                $ServerName -eq 'MyServer' -and
                $InstanceName -eq 'MSSQLSERVER' -and
                $Port -eq 1433
            }
        }

        It 'Should pass both Protocol and Port parameters to Connect-Sql' {
            $mockConnectSqlDscDatabaseEngineParameters = @{
                ServerName   = '192.168.1.1'
                InstanceName = 'MyInstance'
                Protocol     = 'tcp'
                Port         = 50200
            }

            Connect-SqlDscDatabaseEngine @mockConnectSqlDscDatabaseEngineParameters

            Should -Invoke -CommandName Connect-Sql -ParameterFilter {
                $ServerName -eq '192.168.1.1' -and
                $InstanceName -eq 'MyInstance' -and
                $Protocol -eq 'tcp' -and
                $Port -eq 50200
            }
        }
    }
}
