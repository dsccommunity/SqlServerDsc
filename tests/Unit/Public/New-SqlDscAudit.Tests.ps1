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
                & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
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

    Import-Module -Name $script:dscModuleName

    # Loading mocked classes
    Add-Type -Path (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '../Stubs') -ChildPath 'SMO.cs')

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
}

Describe 'New-SqlDscAudit' -Tag 'Public' {
    It 'Should have the correct parameters in parameter set <MockParameterSetName>' -ForEach @(
        @{
            MockParameterSetName = 'Log'
            MockExpectedParameters = '-ServerObject <Server> -Name <string> -Type <string> [-Filter <string>] [-OnFailure <string>] [-QueueDelay <uint>] [-AuditGuid <string>] [-OperatorAudit] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
        @{
            MockParameterSetName = 'File'
            MockExpectedParameters = '-ServerObject <Server> -Name <string> -Path <string> [-Filter <string>] [-OnFailure <string>] [-QueueDelay <uint>] [-AuditGuid <string>] [-OperatorAudit] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
        @{
            MockParameterSetName = 'FileWithSize'
            MockExpectedParameters = '-ServerObject <Server> -Name <string> -Path <string> -MaximumFileSize <uint> -MaximumFileSizeUnit <string> [-Filter <string>] [-OnFailure <string>] [-QueueDelay <uint>] [-AuditGuid <string>] [-OperatorAudit] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
        @{
            MockParameterSetName = 'FileWithMaxFiles'
            MockExpectedParameters = '-ServerObject <Server> -Name <string> -Path <string> -MaximumFiles <uint> [-Filter <string>] [-OnFailure <string>] [-QueueDelay <uint>] [-AuditGuid <string>] [-OperatorAudit] [-Force] [-ReserveDiskSpace] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
        @{
            MockParameterSetName = 'FileWithMaxRolloverFiles'
            MockExpectedParameters = '-ServerObject <Server> -Name <string> -Path <string> -MaximumRolloverFiles <uint> [-Filter <string>] [-OnFailure <string>] [-QueueDelay <uint>] [-AuditGuid <string>] [-OperatorAudit] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
        @{
            MockParameterSetName = 'FileWithSizeAndMaxFiles'
            MockExpectedParameters = '-ServerObject <Server> -Name <string> -Path <string> -MaximumFileSize <uint> -MaximumFileSizeUnit <string> -MaximumFiles <uint> [-Filter <string>] [-OnFailure <string>] [-QueueDelay <uint>] [-AuditGuid <string>] [-OperatorAudit] [-Force] [-ReserveDiskSpace] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
        @{
            MockParameterSetName = 'FileWithSizeAndMaxRolloverFiles'
            MockExpectedParameters = '-ServerObject <Server> -Name <string> -Path <string> -MaximumFileSize <uint> -MaximumFileSizeUnit <string> -MaximumRolloverFiles <uint> [-Filter <string>] [-OnFailure <string>] [-QueueDelay <uint>] [-AuditGuid <string>] [-OperatorAudit] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
    ) {
        $result = (Get-Command -Name 'New-SqlDscAudit').ParameterSets |
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

        $result.ParameterSetName | Should -Be $MockParameterSetName
        $result.ParameterListAsString | Should -Be $MockExpectedParameters
    }

    Context 'When adding an application log audit using mandatory parameters' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'TestInstance'

            Mock -CommandName Invoke-SqlDscQuery

            $mockDefaultParameters = @{
                ServerObject = $mockServerObject
                Type = 'ApplicationLog'
                Name = 'Log1'
            }
        }

        Context 'When using parameter Confirm with value $false' {
            It 'Should call the mock with the expected query' {
                New-SqlDscAudit -Confirm:$false @mockDefaultParameters

                Should -Invoke -CommandName Invoke-SqlDscQuery -ParameterFilter {
                    $Query -eq 'CREATE SERVER AUDIT [Log1] TO APPLICATION_LOG'
                }
            }
        }

        Context 'When using parameter Force' {
            It 'Should call the mock with the expected query' {
                New-SqlDscAudit -Force @mockDefaultParameters

                Should -Invoke -CommandName Invoke-SqlDscQuery -ParameterFilter {
                    $Query -eq 'CREATE SERVER AUDIT [Log1] TO APPLICATION_LOG'
                }
            }
        }

        Context 'When using parameter WhatIf' {
            It 'Should call the mock with the expected query' {
                New-SqlDscAudit -WhatIf @mockDefaultParameters

                Should -Not -Invoke -CommandName Invoke-SqlDscQuery
            }
        }

        Context 'When passing parameter ServerObject over the pipeline' {
            It 'Should call the mock with the expected query' {
                $mockServerObject | New-SqlDscAudit -Type 'ApplicationLog' -Name 'Log1'

                Should -Invoke -CommandName Invoke-SqlDscQuery -ParameterFilter {
                    $Query -eq 'CREATE SERVER AUDIT [Log1] TO APPLICATION_LOG'
                }
            }
        }
    }

    Context 'When adding an security log audit using mandatory parameters' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'TestInstance'

            Mock -CommandName Invoke-SqlDscQuery
            Mock -CommandName Test-Path -MockWith {
                return $true
            }

            $mockDefaultParameters = @{
                ServerObject = $mockServerObject
                Type = 'SecurityLog'
                Name = 'Log1'
            }
        }

        Context 'When using parameter Confirm with value $false' {
            It 'Should call the mock with the expected query' {
                New-SqlDscAudit -Confirm:$false @mockDefaultParameters

                Should -Invoke -CommandName Invoke-SqlDscQuery -ParameterFilter {
                    $Query -eq 'CREATE SERVER AUDIT [Log1] TO SECURITY_LOG'
                }
            }
        }

        Context 'When using parameter Force' {
            It 'Should call the mock with the expected query' {
                New-SqlDscAudit -Force @mockDefaultParameters

                Should -Invoke -CommandName Invoke-SqlDscQuery -ParameterFilter {
                    $Query -eq 'CREATE SERVER AUDIT [Log1] TO SECURITY_LOG'
                }
            }
        }

        Context 'When using parameter WhatIf' {
            It 'Should call the mock with the expected query' {
                New-SqlDscAudit -WhatIf @mockDefaultParameters

                Should -Not -Invoke -CommandName Invoke-SqlDscQuery
            }
        }

        Context 'When passing parameter ServerObject over the pipeline' {
            It 'Should call the mock with the expected query' {
                $mockServerObject | New-SqlDscAudit -Type 'SecurityLog' -Name 'Log1'

                Should -Invoke -CommandName Invoke-SqlDscQuery -ParameterFilter {
                    $Query -eq 'CREATE SERVER AUDIT [Log1] TO SECURITY_LOG'
                }
            }
        }
    }

    Context 'When adding an file audit using mandatory parameters' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'TestInstance'

            Mock -CommandName Invoke-SqlDscQuery

            $mockDefaultParameters = @{
                ServerObject = $mockServerObject
                Name = 'Log1'
                Path = 'C:\Temp'
            }
        }

        Context 'When using parameter Confirm with value $false' {
            It 'Should call the mock with the expected query' {
                New-SqlDscAudit -Confirm:$false @mockDefaultParameters

                Should -Invoke -CommandName Invoke-SqlDscQuery -ParameterFilter {
                    $Query -eq "CREATE SERVER AUDIT [Log1] TO FILE (FILEPATH = 'C:\Temp')"
                }
            }
        }

        Context 'When using parameter Force' {
            It 'Should call the mock with the expected query' {
                New-SqlDscAudit -Force @mockDefaultParameters

                Should -Invoke -CommandName Invoke-SqlDscQuery -ParameterFilter {
                    $Query -eq "CREATE SERVER AUDIT [Log1] TO FILE (FILEPATH = 'C:\Temp')"
                }
            }
        }

        Context 'When using parameter WhatIf' {
            It 'Should call the mock with the expected query' {
                New-SqlDscAudit -WhatIf @mockDefaultParameters

                Should -Not -Invoke -CommandName Invoke-SqlDscQuery
            }
        }

        Context 'When passing parameter ServerObject over the pipeline' {
            It 'Should call the mock with the expected query' {
                $mockServerObject | New-SqlDscAudit -Path 'C:\Temp' -Name 'Log1'

                Should -Invoke -CommandName Invoke-SqlDscQuery -ParameterFilter {
                    $Query -eq "CREATE SERVER AUDIT [Log1] TO FILE (FILEPATH = 'C:\Temp')"
                }
            }
        }
    }

    Context 'When adding an file audit and passing an invalid path' {
        BeforeAll {
            Mock -CommandName Test-Path -MockWith {
                return $false
            }
        }

        It 'Should throw the correct error' {
            $mockNewSqlDscAuditParameters = @{
                ServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                Path = 'C:\Temp'
                Name = 'Log1'
            }

            $mockErrorMessage = InModuleScope -ScriptBlock {
                $script:localizedData.Audit_PathParameterValueInvalid
            }

            $mockErrorMessage = "Cannot validate argument on parameter 'Path'. " + ($mockErrorMessage -f 'C:\Temp')


            { New-SqlDscAudit @mockNewSqlDscAuditParameters } | Should -Throw -ExpectedMessage $mockErrorMessage
        }
    }

    Context 'When passing file audit optional parameter AuditGuid' {
        BeforeAll {
            Mock -CommandName Invoke-SqlDscQuery

            $mockDefaultParameters = @{
                ServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                Name = 'Log1'
                Path = 'C:\Temp'
                Force = $true
            }
        }

        It 'Should call the mock with the expected query' {
            New-SqlDscAudit -AuditGuid 'b5962b93-a359-42ef-bf1e-193e8a5f6222' @mockDefaultParameters

            Should -Invoke -CommandName Invoke-SqlDscQuery -ParameterFilter {
                $Query -eq "CREATE SERVER AUDIT [Log1] TO FILE (FILEPATH = 'C:\Temp') WITH (AUDIT_GUID = 'b5962b93-a359-42ef-bf1e-193e8a5f6222')"
            }
        }

        Context 'When passing an invalid GUID' {
            It 'Should call the mock with the expected query' {
                $mockErrorMessage = 'Cannot validate argument on parameter ''AuditGuid''. The argument "not a guid" does not match the "^[0-9a-fA-F]{8}-(?:[0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$" pattern.'

                # Escape bracket so that Should -Throw works.
                $mockErrorMessage = $mockErrorMessage -replace '\[', '`['

                { New-SqlDscAudit -AuditGuid 'not a guid' @mockDefaultParameters } |
                    Should -Throw -ExpectedMessage ($mockErrorMessage + '*')
            }
        }
    }

    Context 'When passing file audit optional parameter OperatorAudit' {
        BeforeAll {
            Mock -CommandName Invoke-SqlDscQuery

            $mockDefaultParameters = @{
                ServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                Name = 'Log1'
                Path = 'C:\Temp'
                Force = $true
            }
        }

        It 'Should call the mock with the expected query' {
            New-SqlDscAudit -OperatorAudit @mockDefaultParameters

            Should -Invoke -CommandName Invoke-SqlDscQuery -ParameterFilter {
                $Query -eq "CREATE SERVER AUDIT [Log1] TO FILE (FILEPATH = 'C:\Temp') WITH (OPERATOR_AUDIT = ON)"
            }
        }

        Context 'When passing $false for parameter OperatorAudit' {
            It 'Should call the mock with the expected query' {
                New-SqlDscAudit -OperatorAudit:$false @mockDefaultParameters

                Should -Invoke -CommandName Invoke-SqlDscQuery -ParameterFilter {
                    $Query -eq "CREATE SERVER AUDIT [Log1] TO FILE (FILEPATH = 'C:\Temp') WITH (OPERATOR_AUDIT = OFF)"
                }
            }
        }
    }

    Context 'When passing file audit optional parameter OnFailure' {
        BeforeAll {
            Mock -CommandName Invoke-SqlDscQuery

            $mockDefaultParameters = @{
                ServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                Name = 'Log1'
                Path = 'C:\Temp'
                Force = $true
            }
        }

        Context 'When passing the value <MockOnFailureValue>' -ForEach @(
            @{
                MockOnFailureValue = 'Continue'
                MockExpectedQueryValue = 'CONTINUE'
            }
            @{
                MockOnFailureValue = 'FailOperation'
                MockExpectedQueryValue = 'FAIL_OPERATION'
            }
            @{
                MockOnFailureValue = 'ShutDown'
                MockExpectedQueryValue = 'SHUTDOWN'
            }
        ) {
            It 'Should call the mock with the expected query' {
                New-SqlDscAudit -OperatorAudit @mockDefaultParameters

                Should -Invoke -CommandName Invoke-SqlDscQuery -ParameterFilter {
                    Write-Verbose -Verbose -Message $Query
                    $Query -eq "CREATE SERVER AUDIT [Log1] TO FILE (FILEPATH = 'C:\Temp') WITH (ON_FAILURE = $MockExpectedQueryValue)"
                }
            }
        }
    }
}
