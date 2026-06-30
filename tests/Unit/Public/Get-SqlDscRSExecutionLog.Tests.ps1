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

    # Loading mocked classes
    Add-Type -Path (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '../Stubs') -ChildPath 'SMO.cs')

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Should-Invoke:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Should-NotInvoke:ModuleName'] = $script:moduleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should-Invoke:ModuleName')
    $PSDefaultParameterValues.Remove('Should-NotInvoke:ModuleName')

    Remove-Item -Path 'env:SqlServerDscCI'
}

Describe 'Get-SqlDscRSExecutionLog' {
    Context 'When parameter validation' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = '__AllParameterSets'
                ExpectedParameters = '[-InstanceName] <string> [[-StartTime] <datetime>] [[-EndTime] <datetime>] [[-UserName] <string>] [[-ReportPath] <string>] [[-MaxRows] <int>] [[-Credential] <pscredential>] [[-LoginType] <string>] [[-StatementTimeout] <int>] [-Encrypt] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Get-SqlDscRSExecutionLog').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should-Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should-Be $ExpectedParameters
        }

        It 'Should have InstanceName as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Get-SqlDscRSExecutionLog').Parameters['InstanceName']

            $parameterInfo.Attributes.Mandatory | Should-All { $_ | Should-BeTrue }
        }

        It 'Should have MaxRows with a default value of 1000' {
            $parameterInfo = (Get-Command -Name 'Get-SqlDscRSExecutionLog').Parameters['MaxRows']

            # Find the default value by examining parameter attributes or testing the command
            $parameterInfo | Should-BeTruthy
        }

        It 'Should have LoginType with a default value of Integrated' {
            $parameterInfo = (Get-Command -Name 'Get-SqlDscRSExecutionLog').Parameters['LoginType']

            $parameterInfo | Should-BeTruthy
        }
    }

    Context 'When querying the execution log successfully' {
        BeforeAll {
            Mock -CommandName Get-SqlDscRSConfiguration -MockWith {
                return [PSCustomObject]@{
                    InstanceName       = 'SSRS'
                    DatabaseServerName = 'localhost'
                    DatabaseName       = 'ReportServer'
                }
            }

            # Create a mock DataSet with results
            $mockDataTable = [System.Data.DataTable]::new()
            $null = $mockDataTable.Columns.Add('InstanceName', [System.String])
            $null = $mockDataTable.Columns.Add('ItemPath', [System.String])
            $null = $mockDataTable.Columns.Add('UserName', [System.String])
            $null = $mockDataTable.Columns.Add('TimeStart', [System.DateTime])
            $null = $mockDataTable.Columns.Add('Status', [System.String])

            $mockRow = $mockDataTable.NewRow()
            $mockRow['InstanceName'] = 'SSRS'
            $mockRow['ItemPath'] = '/Sales/Revenue'
            $mockRow['UserName'] = 'DOMAIN\TestUser'
            $mockRow['TimeStart'] = [System.DateTime]::new(2025, 1, 1, 10, 0, 0)
            $mockRow['Status'] = 'rsSuccess'
            $mockDataTable.Rows.Add($mockRow)

            $mockDataSet = [System.Data.DataSet]::new()
            $mockDataSet.Tables.Add($mockDataTable)

            Mock -CommandName Invoke-SqlDscQuery -MockWith {
                return $mockDataSet
            }
        }

        It 'Should return execution log entries' {
            $result = Get-SqlDscRSExecutionLog -InstanceName 'SSRS' -Force

            $result | Should-BeTruthy
            $result.ItemPath | Should-Be '/Sales/Revenue'
            $result.UserName | Should-Be 'DOMAIN\TestUser'

            Should-Invoke -CommandName Get-SqlDscRSConfiguration -Exactly -Scope It -Times 1
            Should-Invoke -CommandName Invoke-SqlDscQuery -Exactly -Scope It -Times 1
        }

        It 'Should pass the correct parameters to Invoke-SqlDscQuery' {
            Get-SqlDscRSExecutionLog -InstanceName 'SSRS' -Force

            Should-Invoke -CommandName Invoke-SqlDscQuery -Exactly -ParameterFilter {
                $ServerName -eq 'localhost' -and
                $InstanceName -eq 'MSSQLSERVER' -and
                $DatabaseName -eq 'ReportServer' -and
                $PassThru -eq $true -and
                $Force -eq $true
            } -Scope It -Times 1
        }
    }

    Context 'When the database server name contains a named instance' {
        BeforeAll {
            Mock -CommandName Get-SqlDscRSConfiguration -MockWith {
                return [PSCustomObject]@{
                    InstanceName       = 'SSRS'
                    DatabaseServerName = 'SqlServer01\RSDB'
                    DatabaseName       = 'ReportServer'
                }
            }

            $mockDataSet = [System.Data.DataSet]::new()
            $mockDataTable = [System.Data.DataTable]::new()
            $mockDataSet.Tables.Add($mockDataTable)

            Mock -CommandName Invoke-SqlDscQuery -MockWith {
                return $mockDataSet
            }
        }

        It 'Should parse the server and instance name correctly' {
            Get-SqlDscRSExecutionLog -InstanceName 'SSRS' -Force

            Should-Invoke -CommandName Invoke-SqlDscQuery -Exactly -ParameterFilter {
                $ServerName -eq 'SqlServer01' -and
                $InstanceName -eq 'RSDB'
            } -Scope It -Times 1
        }
    }

    Context 'When using filter parameters' {
        BeforeAll {
            Mock -CommandName Get-SqlDscRSConfiguration -MockWith {
                return [PSCustomObject]@{
                    InstanceName       = 'SSRS'
                    DatabaseServerName = 'localhost'
                    DatabaseName       = 'ReportServer'
                }
            }

            $mockDataSet = [System.Data.DataSet]::new()
            $mockDataTable = [System.Data.DataTable]::new()
            $mockDataSet.Tables.Add($mockDataTable)

            Mock -CommandName Invoke-SqlDscQuery -MockWith {
                return $mockDataSet
            }
        }

        It 'Should include StartTime filter in the query' {
            $startTime = [System.DateTime]::new(2025, 1, 1)

            Get-SqlDscRSExecutionLog -InstanceName 'SSRS' -StartTime $startTime -Force

            Should-Invoke -CommandName Invoke-SqlDscQuery -Exactly -ParameterFilter {
                $Query -match "TimeStart >= '2025-01-01 00:00:00'"
            } -Scope It -Times 1
        }

        It 'Should include EndTime filter in the query' {
            $endTime = [System.DateTime]::new(2025, 12, 31, 23, 59, 59)

            Get-SqlDscRSExecutionLog -InstanceName 'SSRS' -EndTime $endTime -Force

            Should-Invoke -CommandName Invoke-SqlDscQuery -Exactly -ParameterFilter {
                $Query -match "TimeStart <= '2025-12-31 23:59:59'"
            } -Scope It -Times 1
        }

        It 'Should include UserName filter in the query' {
            Get-SqlDscRSExecutionLog -InstanceName 'SSRS' -UserName 'DOMAIN\%' -Force

            Should-Invoke -CommandName Invoke-SqlDscQuery -Exactly -ParameterFilter {
                $Query -match "UserName LIKE 'DOMAIN\\%'"
            } -Scope It -Times 1
        }

        It 'Should include ReportPath filter in the query' {
            Get-SqlDscRSExecutionLog -InstanceName 'SSRS' -ReportPath '/Sales/%' -Force

            Should-Invoke -CommandName Invoke-SqlDscQuery -Exactly -ParameterFilter {
                $Query -match "ItemPath LIKE '/Sales/%'"
            } -Scope It -Times 1
        }

        It 'Should include MaxRows in the query' {
            Get-SqlDscRSExecutionLog -InstanceName 'SSRS' -MaxRows 500 -Force

            Should-Invoke -CommandName Invoke-SqlDscQuery -Exactly -ParameterFilter {
                $Query -match 'TOP \(500\)'
            } -Scope It -Times 1
        }

        It 'Should not include TOP clause when MaxRows is 0' {
            Get-SqlDscRSExecutionLog -InstanceName 'SSRS' -MaxRows 0 -Force

            Should-Invoke -CommandName Invoke-SqlDscQuery -Exactly -ParameterFilter {
                $Query -notmatch 'TOP'
            } -Scope It -Times 1
        }
    }

    Context 'When using credential parameters' {
        BeforeAll {
            Mock -CommandName Get-SqlDscRSConfiguration -MockWith {
                return [PSCustomObject]@{
                    InstanceName       = 'SSRS'
                    DatabaseServerName = 'localhost'
                    DatabaseName       = 'ReportServer'
                }
            }

            $mockDataSet = [System.Data.DataSet]::new()
            $mockDataTable = [System.Data.DataTable]::new()
            $mockDataSet.Tables.Add($mockDataTable)

            Mock -CommandName Invoke-SqlDscQuery -MockWith {
                return $mockDataSet
            }
        }

        It 'Should pass Credential to Invoke-SqlDscQuery' {
            $securePassword = ConvertTo-SecureString -String 'TestPassword' -AsPlainText -Force
            $credential = [System.Management.Automation.PSCredential]::new('TestUser', $securePassword)

            Get-SqlDscRSExecutionLog -InstanceName 'SSRS' -Credential $credential -LoginType 'SqlLogin' -Force

            Should-Invoke -CommandName Invoke-SqlDscQuery -Exactly -ParameterFilter {
                $null -ne $Credential -and
                $LoginType -eq 'SqlLogin'
            } -Scope It -Times 1
        }

        It 'Should pass Encrypt to Invoke-SqlDscQuery' {
            Get-SqlDscRSExecutionLog -InstanceName 'SSRS' -Encrypt -Force

            Should-Invoke -CommandName Invoke-SqlDscQuery -Exactly -ParameterFilter {
                $Encrypt -eq $true
            } -Scope It -Times 1
        }

        It 'Should pass StatementTimeout to Invoke-SqlDscQuery' {
            Get-SqlDscRSExecutionLog -InstanceName 'SSRS' -StatementTimeout 120 -Force

            Should-Invoke -CommandName Invoke-SqlDscQuery -Exactly -ParameterFilter {
                $StatementTimeout -eq 120
            } -Scope It -Times 1
        }
    }

    Context 'When the query fails' {
        BeforeAll {
            Mock -CommandName Get-SqlDscRSConfiguration -MockWith {
                return [PSCustomObject]@{
                    InstanceName       = 'SSRS'
                    DatabaseServerName = 'localhost'
                    DatabaseName       = 'ReportServer'
                }
            }

            Mock -CommandName Invoke-SqlDscQuery -MockWith {
                throw 'Connection failed'
            }
        }

        It 'Should write an error and return null' {
            $result = Get-SqlDscRSExecutionLog -InstanceName 'SSRS' -Force -ErrorAction SilentlyContinue -ErrorVariable testError 3>&1 4>&1 5>&1 6>&1

            $result | Should-BeFalsy
            $testError | Should-BeTruthy

            Should-Invoke -CommandName Invoke-SqlDscQuery -Exactly -Scope It -Times 1
        }
    }

    Context 'When querying Power BI Report Server' {
        # cSpell: ignore PBIRS
        BeforeAll {
            Mock -CommandName Get-SqlDscRSConfiguration -MockWith {
                return [PSCustomObject]@{
                    InstanceName       = 'PBIRS'
                    DatabaseServerName = 'localhost'
                    DatabaseName       = 'ReportServerPBIRS'
                }
            }

            $mockDataSet = [System.Data.DataSet]::new()
            $mockDataTable = [System.Data.DataTable]::new()
            $mockDataSet.Tables.Add($mockDataTable)

            Mock -CommandName Invoke-SqlDscQuery -MockWith {
                return $mockDataSet
            }
        }

        It 'Should query the correct database for PBIRS' {
            Get-SqlDscRSExecutionLog -InstanceName 'PBIRS' -Force

            Should-Invoke -CommandName Get-SqlDscRSConfiguration -Exactly -ParameterFilter {
                $InstanceName -eq 'PBIRS'
            } -Scope It -Times 1

            Should-Invoke -CommandName Invoke-SqlDscQuery -Exactly -ParameterFilter {
                $DatabaseName -eq 'ReportServerPBIRS'
            } -Scope It -Times 1
        }
    }

    Context 'When WhatIf is used' {
        BeforeAll {
            Mock -CommandName Get-SqlDscRSConfiguration -MockWith {
                return [PSCustomObject]@{
                    InstanceName       = 'SSRS'
                    DatabaseServerName = 'localhost'
                    DatabaseName       = 'ReportServer'
                }
            }

            Mock -CommandName Invoke-SqlDscQuery
        }

        It 'Should not execute the query' {
            Get-SqlDscRSExecutionLog -InstanceName 'SSRS' -WhatIf

            Should-Invoke -CommandName Invoke-SqlDscQuery -Exactly -Scope It -Times 0
        }
    }
}
