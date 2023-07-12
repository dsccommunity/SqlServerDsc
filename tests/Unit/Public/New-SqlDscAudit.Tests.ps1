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

    Remove-Item -Path 'env:SqlServerDscCI'
}

Describe 'New-SqlDscAudit' -Tag 'Public' {
    It 'Should have the correct parameters in parameter set <MockParameterSetName>' -ForEach @(
        @{
            MockParameterSetName = 'Log'
            MockExpectedParameters = '-ServerObject <Server> -Name <string> -LogType <string> [-AuditFilter <string>] [-OnFailure <string>] [-QueueDelay <uint>] [-AuditGuid <string>] [-Force] [-Refresh] [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
        @{
            MockParameterSetName = 'File'
            MockExpectedParameters = '-ServerObject <Server> -Name <string> -Path <string> [-AuditFilter <string>] [-OnFailure <string>] [-QueueDelay <uint>] [-AuditGuid <string>] [-Force] [-Refresh] [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
        @{
            MockParameterSetName = 'FileWithSize'
            MockExpectedParameters = '-ServerObject <Server> -Name <string> -Path <string> -MaximumFileSize <uint> -MaximumFileSizeUnit <string> [-AuditFilter <string>] [-OnFailure <string>] [-QueueDelay <uint>] [-AuditGuid <string>] [-Force] [-Refresh] [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
        @{
            MockParameterSetName = 'FileWithMaxFiles'
            MockExpectedParameters = '-ServerObject <Server> -Name <string> -Path <string> -MaximumFiles <uint> [-AuditFilter <string>] [-OnFailure <string>] [-QueueDelay <uint>] [-AuditGuid <string>] [-Force] [-Refresh] [-PassThru] [-ReserveDiskSpace] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
        @{
            MockParameterSetName = 'FileWithMaxRolloverFiles'
            MockExpectedParameters = '-ServerObject <Server> -Name <string> -Path <string> -MaximumRolloverFiles <uint> [-AuditFilter <string>] [-OnFailure <string>] [-QueueDelay <uint>] [-AuditGuid <string>] [-Force] [-Refresh] [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
        @{
            MockParameterSetName = 'FileWithSizeAndMaxFiles'
            MockExpectedParameters = '-ServerObject <Server> -Name <string> -Path <string> -MaximumFileSize <uint> -MaximumFileSizeUnit <string> -MaximumFiles <uint> [-AuditFilter <string>] [-OnFailure <string>] [-QueueDelay <uint>] [-AuditGuid <string>] [-Force] [-Refresh] [-PassThru] [-ReserveDiskSpace] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
        @{
            MockParameterSetName = 'FileWithSizeAndMaxRolloverFiles'
            MockExpectedParameters = '-ServerObject <Server> -Name <string> -Path <string> -MaximumFileSize <uint> -MaximumFileSizeUnit <string> -MaximumRolloverFiles <uint> [-AuditFilter <string>] [-OnFailure <string>] [-QueueDelay <uint>] [-AuditGuid <string>] [-Force] [-Refresh] [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]'
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
            $script:mockCreateAuditObject = $null

            Mock -CommandName New-Object -ParameterFilter {
                $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Audit'
            } -MockWith {
                <#
                    The Audit object is created in the script scope so that the
                    properties can be validated.
                #>
                $script:mockCreateAuditObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Audit' -ArgumentList @(
                    $PesterBoundParameters.ArgumentList[0],
                    $PesterBoundParameters.ArgumentList[1]
                ) |
                    Add-Member -MemberType 'ScriptMethod' -Name 'Create' -Value {
                        $script:mockMethodCreateCallCount += 1
                    } -PassThru -Force

                return $script:mockCreateAuditObject
            }

            Mock -CommandName Get-SqlDscAudit

            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'TestInstance'

            $mockDefaultParameters = @{
                ServerObject = $mockServerObject
                LogType = 'ApplicationLog'
                Name = 'Log1'
            }
        }

        BeforeEach {
            $script:mockMethodCreateCallCount = 0
        }

        Context 'When using parameter Confirm with value $false' {
            It 'Should call the mocked method and have correct values in the object' {
                New-SqlDscAudit -Confirm:$false @mockDefaultParameters

                # This is the object created by the mock and modified by the command.
                $mockCreateAuditObject.Name | Should -Be 'Log1'
                $mockCreateAuditObject.DestinationType | Should -Be 'ApplicationLog'

                $mockMethodCreateCallCount | Should -Be 1
            }
        }

        Context 'When using parameter Force' {
            It 'Should call the mocked method and have correct values in the object' {
                New-SqlDscAudit -Force @mockDefaultParameters

                # This is the object created by the mock and modified by the command.
                $mockCreateAuditObject.Name | Should -Be 'Log1'
                $mockCreateAuditObject.DestinationType | Should -Be 'ApplicationLog'

                $mockMethodCreateCallCount | Should -Be 1
            }
        }

        Context 'When using parameter WhatIf' {
            It 'Should call the mocked method and have correct values in the object' {
                New-SqlDscAudit -WhatIf @mockDefaultParameters

                # This is the object created by the mock and modified by the command.
                $mockCreateAuditObject.Name | Should -Be 'Log1'
                $mockCreateAuditObject.DestinationType | Should -Be 'ApplicationLog'

                $mockMethodCreateCallCount | Should -Be 0
            }
        }

        Context 'When passing parameter ServerObject over the pipeline' {
            It 'Should call the mocked method and have correct values in the object' {
                $mockServerObject | New-SqlDscAudit -LogType 'ApplicationLog' -Name 'Log1' -Force

                # This is the object created by the mock and modified by the command.
                $mockCreateAuditObject.Name | Should -Be 'Log1'
                $mockCreateAuditObject.DestinationType | Should -Be 'ApplicationLog'

                $mockMethodCreateCallCount | Should -Be 1
            }
        }
    }

    Context 'When adding an security log audit using mandatory parameters' {
        BeforeAll {
            $script:mockCreateAuditObject = $null

            Mock -CommandName New-Object -ParameterFilter {
                $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Audit'
            } -MockWith {
                <#
                    The Audit object is created in the script scope so that the
                    properties can be validated.
                #>
                $script:mockCreateAuditObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Audit' -ArgumentList @(
                    $PesterBoundParameters.ArgumentList[0],
                    $PesterBoundParameters.ArgumentList[1]
                ) |
                    Add-Member -MemberType 'ScriptMethod' -Name 'Create' -Value {
                        $script:mockMethodCreateCallCount += 1
                    } -PassThru -Force

                return $script:mockCreateAuditObject
            }

            Mock -CommandName Get-SqlDscAudit

            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'TestInstance'

            $mockDefaultParameters = @{
                ServerObject = $mockServerObject
                LogType = 'SecurityLog'
                Name = 'Log1'
            }
        }

        BeforeEach {
            $script:mockMethodCreateCallCount = 0
        }

        Context 'When using parameter Confirm with value $false' {
            It 'Should call the mocked method and have correct values in the object' {
                New-SqlDscAudit -Confirm:$false @mockDefaultParameters

                # This is the object created by the mock and modified by the command.
                $mockCreateAuditObject.Name | Should -Be 'Log1'
                $mockCreateAuditObject.DestinationType | Should -Be 'SecurityLog'

                $mockMethodCreateCallCount | Should -Be 1
            }
        }

        Context 'When using parameter Force' {
            It 'Should call the mocked method and have correct values in the object' {
                New-SqlDscAudit -Force @mockDefaultParameters

                # This is the object created by the mock and modified by the command.
                $mockCreateAuditObject.Name | Should -Be 'Log1'
                $mockCreateAuditObject.DestinationType | Should -Be 'SecurityLog'

                $mockMethodCreateCallCount | Should -Be 1
            }
        }

        Context 'When using parameter WhatIf' {
            It 'Should call the mocked method and have correct values in the object' {
                New-SqlDscAudit -WhatIf @mockDefaultParameters

                # This is the object created by the mock and modified by the command.
                $mockCreateAuditObject.Name | Should -Be 'Log1'
                $mockCreateAuditObject.DestinationType | Should -Be 'SecurityLog'

                $mockMethodCreateCallCount | Should -Be 0
            }
        }

        Context 'When passing parameter ServerObject over the pipeline' {
            It 'Should call the mocked method and have correct values in the object' {
                $mockServerObject | New-SqlDscAudit -LogType 'SecurityLog' -Name 'Log1' -Force

                # This is the object created by the mock and modified by the command.
                $mockCreateAuditObject.Name | Should -Be 'Log1'
                $mockCreateAuditObject.DestinationType | Should -Be 'SecurityLog'

                $mockMethodCreateCallCount | Should -Be 1
            }
        }
    }

    Context 'When adding an file audit using mandatory parameters' {
        BeforeAll {
            $script:mockCreateAuditObject = $null

            Mock -CommandName New-Object -ParameterFilter {
                $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Audit'
            } -MockWith {
                <#
                    The Audit object is created in the script scope so that the
                    properties can be validated.
                #>
                $script:mockCreateAuditObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Audit' -ArgumentList @(
                    $PesterBoundParameters.ArgumentList[0],
                    $PesterBoundParameters.ArgumentList[1]
                ) |
                    Add-Member -MemberType 'ScriptMethod' -Name 'Create' -Value {
                        $script:mockMethodCreateCallCount += 1
                    } -PassThru -Force

                return $script:mockCreateAuditObject
            }

            Mock -CommandName Get-SqlDscAudit

            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'TestInstance'

            $mockDefaultParameters = @{
                ServerObject = $mockServerObject
                Name = 'Log1'
                Path = Get-TemporaryFolder
            }
        }

        BeforeEach {
            $script:mockMethodCreateCallCount = 0
        }

        Context 'When using parameter Confirm with value $false' {
            It 'Should call the mocked method and have correct values in the object' {
                New-SqlDscAudit -Confirm:$false @mockDefaultParameters

                # This is the object created by the mock and modified by the command.
                $mockCreateAuditObject.Name | Should -Be 'Log1'
                $mockCreateAuditObject.DestinationType | Should -Be 'File'
                $mockCreateAuditObject.FilePath | Should -Be (Get-TemporaryFolder)

                $mockMethodCreateCallCount | Should -Be 1
            }
        }

        Context 'When using parameter Force' {
            It 'Should call the mocked method and have correct values in the object' {
                New-SqlDscAudit -Force @mockDefaultParameters

                # This is the object created by the mock and modified by the command.
                $mockCreateAuditObject.Name | Should -Be 'Log1'
                $mockCreateAuditObject.DestinationType | Should -Be 'File'
                $mockCreateAuditObject.FilePath | Should -Be (Get-TemporaryFolder)

                $mockMethodCreateCallCount | Should -Be 1
            }
        }

        Context 'When using parameter WhatIf' {
            It 'Should call the mocked method and have correct values in the object' {
                New-SqlDscAudit -WhatIf @mockDefaultParameters

                # This is the object created by the mock and modified by the command.
                $mockCreateAuditObject.Name | Should -Be 'Log1'
                $mockCreateAuditObject.DestinationType | Should -Be 'File'
                $mockCreateAuditObject.FilePath | Should -Be (Get-TemporaryFolder)

                $mockMethodCreateCallCount | Should -Be 0
            }
        }

        Context 'When passing parameter ServerObject over the pipeline' {
            It 'Should call the mocked method and have correct values in the object' {
                $mockServerObject | New-SqlDscAudit -Path (Get-TemporaryFolder) -Name 'Log1' -Force

                # This is the object created by the mock and modified by the command.
                $mockCreateAuditObject.Name | Should -Be 'Log1'
                $mockCreateAuditObject.DestinationType | Should -Be 'File'
                $mockCreateAuditObject.FilePath | Should -Be (Get-TemporaryFolder)

                $mockMethodCreateCallCount | Should -Be 1
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
                Path = Get-TemporaryFolder
                Name = 'Log1'
            }

            $mockErrorMessage = InModuleScope -ScriptBlock {
                $script:localizedData.Audit_PathParameterValueInvalid
            }

            $mockErrorMessage = "Cannot validate argument on parameter 'Path'. " + ($mockErrorMessage -f (Get-TemporaryFolder))

            { New-SqlDscAudit @mockNewSqlDscAuditParameters } | Should -Throw -ExpectedMessage $mockErrorMessage
        }
    }

    Context 'When passing file audit optional parameters MaximumFileSize and MaximumFileSizeUnit' {
        BeforeAll {
            $script:mockCreateAuditObject = $null

            Mock -CommandName New-Object -ParameterFilter {
                $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Audit'
            } -MockWith {
                <#
                    The Audit object is created in the script scope so that the
                    properties can be validated.
                #>
                $script:mockCreateAuditObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Audit' -ArgumentList @(
                    $PesterBoundParameters.ArgumentList[0],
                    $PesterBoundParameters.ArgumentList[1]
                ) |
                    Add-Member -MemberType 'ScriptMethod' -Name 'Create' -Value {
                        $script:mockMethodCreateCallCount += 1
                    } -PassThru -Force

                return $script:mockCreateAuditObject
            }

            Mock -CommandName Get-SqlDscAudit

            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'TestInstance'

            $mockDefaultParameters = @{
                ServerObject = $mockServerObject
                Name = 'Log1'
                Path = Get-TemporaryFolder
                Force = $true
            }
        }

        BeforeEach {
            $script:mockMethodCreateCallCount = 0
        }

        It 'Should call the mocked method and have correct values in the object' {
            New-SqlDscAudit -MaximumFileSize 1000 -MaximumFileSizeUnit 'Megabyte' @mockDefaultParameters

            # This is the object created by the mock and modified by the command.
            $mockCreateAuditObject.Name | Should -Be 'Log1'
            $mockCreateAuditObject.DestinationType | Should -Be 'File'
            $mockCreateAuditObject.FilePath | Should -Be (Get-TemporaryFolder)
            $mockCreateAuditObject.MaximumFileSize | Should -Be 1000
            $mockCreateAuditObject.MaximumFileSizeUnit | Should -Be 'Mb'

            $mockMethodCreateCallCount | Should -Be 1
        }
    }

    Context 'When passing file audit optional parameters MaximumFiles' {
        BeforeAll {
            $script:mockCreateAuditObject = $null

            Mock -CommandName New-Object -ParameterFilter {
                $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Audit'
            } -MockWith {
                <#
                    The Audit object is created in the script scope so that the
                    properties can be validated.
                #>
                $script:mockCreateAuditObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Audit' -ArgumentList @(
                    $PesterBoundParameters.ArgumentList[0],
                    $PesterBoundParameters.ArgumentList[1]
                ) |
                    Add-Member -MemberType 'ScriptMethod' -Name 'Create' -Value {
                        $script:mockMethodCreateCallCount += 1
                    } -PassThru -Force

                return $script:mockCreateAuditObject
            }

            Mock -CommandName Get-SqlDscAudit

            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'TestInstance'

            $mockDefaultParameters = @{
                ServerObject = $mockServerObject
                Name = 'Log1'
                Path = Get-TemporaryFolder
                Force = $true
            }
        }

        BeforeEach {
            $script:mockMethodCreateCallCount = 0
        }

        It 'Should call the mocked method and have correct values in the object' {
            New-SqlDscAudit -MaximumFiles 2 @mockDefaultParameters

            # This is the object created by the mock and modified by the command.
            $mockCreateAuditObject.Name | Should -Be 'Log1'
            $mockCreateAuditObject.DestinationType | Should -Be 'File'
            $mockCreateAuditObject.FilePath | Should -Be (Get-TemporaryFolder)
            $mockCreateAuditObject.MaximumFiles | Should -Be 2

            $mockMethodCreateCallCount | Should -Be 1
        }
    }

    Context 'When passing file audit optional parameters MaximumFiles and ReserveDiskSpace' {
        BeforeAll {
            $script:mockCreateAuditObject = $null

            Mock -CommandName New-Object -ParameterFilter {
                $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Audit'
            } -MockWith {
                <#
                    The Audit object is created in the script scope so that the
                    properties can be validated.
                #>
                $script:mockCreateAuditObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Audit' -ArgumentList @(
                    $PesterBoundParameters.ArgumentList[0],
                    $PesterBoundParameters.ArgumentList[1]
                ) |
                    Add-Member -MemberType 'ScriptMethod' -Name 'Create' -Value {
                        $script:mockMethodCreateCallCount += 1
                    } -PassThru -Force

                return $script:mockCreateAuditObject
            }

            Mock -CommandName Get-SqlDscAudit

            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'TestInstance'

            $mockDefaultParameters = @{
                ServerObject = $mockServerObject
                Name = 'Log1'
                Path = Get-TemporaryFolder
                Force = $true
            }
        }

        BeforeEach {
            $script:mockMethodCreateCallCount = 0
        }

        It 'Should call the mocked method and have correct values in the object' {
            New-SqlDscAudit -MaximumFiles 2 -ReserveDiskSpace @mockDefaultParameters

            # This is the object created by the mock and modified by the command.
            $mockCreateAuditObject.Name | Should -Be 'Log1'
            $mockCreateAuditObject.DestinationType | Should -Be 'File'
            $mockCreateAuditObject.FilePath | Should -Be (Get-TemporaryFolder)
            $mockCreateAuditObject.MaximumFiles | Should -Be 2
            $mockCreateAuditObject.ReserveDiskSpace | Should -BeTrue

            $mockMethodCreateCallCount | Should -Be 1
        }

        Context 'When ReserveDiskSpace is set to $false' {
            It 'Should call the mocked method and have correct values in the object' {
                New-SqlDscAudit -MaximumFiles 2 -ReserveDiskSpace:$false @mockDefaultParameters

                # This is the object created by the mock and modified by the command.
                $mockCreateAuditObject.Name | Should -Be 'Log1'
                $mockCreateAuditObject.DestinationType | Should -Be 'File'
                $mockCreateAuditObject.FilePath | Should -Be (Get-TemporaryFolder)
                $mockCreateAuditObject.MaximumFiles | Should -Be 2
                $mockCreateAuditObject.ReserveDiskSpace | Should -BeFalse

                $mockMethodCreateCallCount | Should -Be 1
            }
        }
    }

    Context 'When passing file audit optional parameters MaximumRolloverFiles' {
        BeforeAll {
            $script:mockCreateAuditObject = $null

            Mock -CommandName New-Object -ParameterFilter {
                $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Audit'
            } -MockWith {
                <#
                    The Audit object is created in the script scope so that the
                    properties can be validated.
                #>
                $script:mockCreateAuditObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Audit' -ArgumentList @(
                    $PesterBoundParameters.ArgumentList[0],
                    $PesterBoundParameters.ArgumentList[1]
                ) |
                    Add-Member -MemberType 'ScriptMethod' -Name 'Create' -Value {
                        $script:mockMethodCreateCallCount += 1
                    } -PassThru -Force

                return $script:mockCreateAuditObject
            }

            Mock -CommandName Get-SqlDscAudit

            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'TestInstance'

            $mockDefaultParameters = @{
                ServerObject = $mockServerObject
                Name = 'Log1'
                Path = Get-TemporaryFolder
                Force = $true
            }
        }

        BeforeEach {
            $script:mockMethodCreateCallCount = 0
        }

        It 'Should call the mocked method and have correct values in the object' {
            New-SqlDscAudit -MaximumRolloverFiles 2 @mockDefaultParameters

            # This is the object created by the mock and modified by the command.
            $mockCreateAuditObject.Name | Should -Be 'Log1'
            $mockCreateAuditObject.DestinationType | Should -Be 'File'
            $mockCreateAuditObject.FilePath | Should -Be (Get-TemporaryFolder)
            $mockCreateAuditObject.MaximumRolloverFiles | Should -Be 2

            $mockMethodCreateCallCount | Should -Be 1
        }
    }

    Context 'When passing audit optional parameter AuditGuid' {
        BeforeAll {
            $script:mockCreateAuditObject = $null

            Mock -CommandName New-Object -ParameterFilter {
                $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Audit'
            } -MockWith {
                <#
                    The Audit object is created in the script scope so that the
                    properties can be validated.
                #>
                $script:mockCreateAuditObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Audit' -ArgumentList @(
                    $PesterBoundParameters.ArgumentList[0],
                    $PesterBoundParameters.ArgumentList[1]
                ) |
                    Add-Member -MemberType 'ScriptMethod' -Name 'Create' -Value {
                        $script:mockMethodCreateCallCount += 1
                    } -PassThru -Force

                return $script:mockCreateAuditObject
            }

            Mock -CommandName Get-SqlDscAudit

            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'TestInstance'

            $mockDefaultParameters = @{
                ServerObject = $mockServerObject
                Name = 'Log1'
                Path = Get-TemporaryFolder
                Force = $true
            }
        }

        BeforeEach {
            $script:mockMethodCreateCallCount = 0
        }

        It 'Should call the mocked method and have correct values in the object' {
            New-SqlDscAudit -AuditGuid 'b5962b93-a359-42ef-bf1e-193e8a5f6222' @mockDefaultParameters

            # This is the object created by the mock and modified by the command.
            $mockCreateAuditObject.Name | Should -Be 'Log1'
            $mockCreateAuditObject.DestinationType | Should -Be 'File'
            $mockCreateAuditObject.FilePath | Should -Be (Get-TemporaryFolder)
            $mockCreateAuditObject.Guid | Should -Be 'b5962b93-a359-42ef-bf1e-193e8a5f6222'

            $mockMethodCreateCallCount | Should -Be 1
        }

        Context 'When passing an invalid GUID' {
            It 'Should throw the correct error' {
                $mockErrorMessage = 'Cannot validate argument on parameter ''AuditGuid''. The argument "not a guid" does not match the "^[0-9a-fA-F]{8}-(?:[0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$" pattern.'

                # Escape bracket so that Should -Throw works.
                $mockErrorMessage = $mockErrorMessage -replace '\[', '`['

                { New-SqlDscAudit -AuditGuid 'not a guid' @mockDefaultParameters } |
                    Should -Throw -ExpectedMessage ($mockErrorMessage + '*')
            }
        }
    }

    Context 'When passing audit optional parameter OnFailure' {
        BeforeAll {
            $script:mockCreateAuditObject = $null

            Mock -CommandName New-Object -ParameterFilter {
                $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Audit'
            } -MockWith {
                <#
                    The Audit object is created in the script scope so that the
                    properties can be validated.
                #>
                $script:mockCreateAuditObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Audit' -ArgumentList @(
                    $PesterBoundParameters.ArgumentList[0],
                    $PesterBoundParameters.ArgumentList[1]
                ) |
                    Add-Member -MemberType 'ScriptMethod' -Name 'Create' -Value {
                        $script:mockMethodCreateCallCount += 1
                    } -PassThru -Force

                return $script:mockCreateAuditObject
            }

            Mock -CommandName Get-SqlDscAudit

            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'TestInstance'

            $mockDefaultParameters = @{
                ServerObject = $mockServerObject
                Name = 'Log1'
                Path = Get-TemporaryFolder
                Force = $true
            }
        }

        BeforeEach {
            $script:mockMethodCreateCallCount = 0
        }

        Context 'When passing the value <MockOnFailureValue>' -ForEach @(
            @{
                MockOnFailureValue = 'Continue'
            }
            @{
                MockOnFailureValue = 'FailOperation'
            }
            @{
                MockOnFailureValue = 'ShutDown'
            }
        ) {
            It 'Should call the mocked method and have correct values in the object' {
                New-SqlDscAudit -OnFailure $MockOnFailureValue @mockDefaultParameters

                # This is the object created by the mock and modified by the command.
                $mockCreateAuditObject.Name | Should -Be 'Log1'
                $mockCreateAuditObject.DestinationType | Should -Be 'File'
                $mockCreateAuditObject.FilePath | Should -Be (Get-TemporaryFolder)
                $mockCreateAuditObject.OnFailure | Should -Be $MockOnFailureValue

                $mockMethodCreateCallCount | Should -Be 1
            }
        }
    }

    Context 'When passing audit optional parameter QueueDelay' {
        BeforeAll {
            $script:mockCreateAuditObject = $null

            Mock -CommandName New-Object -ParameterFilter {
                $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Audit'
            } -MockWith {
                <#
                    The Audit object is created in the script scope so that the
                    properties can be validated.
                #>
                $script:mockCreateAuditObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Audit' -ArgumentList @(
                    $PesterBoundParameters.ArgumentList[0],
                    $PesterBoundParameters.ArgumentList[1]
                ) |
                    Add-Member -MemberType 'ScriptMethod' -Name 'Create' -Value {
                        $script:mockMethodCreateCallCount += 1
                    } -PassThru -Force

                return $script:mockCreateAuditObject
            }

            Mock -CommandName Get-SqlDscAudit

            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'TestInstance'

            $mockDefaultParameters = @{
                ServerObject = $mockServerObject
                Name = 'Log1'
                Path = Get-TemporaryFolder
                Force = $true
            }
        }

        BeforeEach {
            $script:mockMethodCreateCallCount = 0
        }

        It 'Should call the mocked method and have correct values in the object' {
            New-SqlDscAudit -QueueDelay 1000 @mockDefaultParameters

            # This is the object created by the mock and modified by the command.
            $mockCreateAuditObject.Name | Should -Be 'Log1'
            $mockCreateAuditObject.DestinationType | Should -Be 'File'
            $mockCreateAuditObject.FilePath | Should -Be (Get-TemporaryFolder)
            $mockCreateAuditObject.QueueDelay | Should -Be 1000

            $mockMethodCreateCallCount | Should -Be 1
        }
    }

    Context 'When passing audit optional parameter Filter' {
        BeforeAll {
            $script:mockCreateAuditObject = $null

            Mock -CommandName New-Object -ParameterFilter {
                $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Audit'
            } -MockWith {
                <#
                    The Audit object is created in the script scope so that the
                    properties can be validated.
                #>
                $script:mockCreateAuditObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Audit' -ArgumentList @(
                    $PesterBoundParameters.ArgumentList[0],
                    $PesterBoundParameters.ArgumentList[1]
                ) |
                    Add-Member -MemberType 'ScriptMethod' -Name 'Create' -Value {
                        $script:mockMethodCreateCallCount += 1
                    } -PassThru -Force

                return $script:mockCreateAuditObject
            }

            Mock -CommandName Get-SqlDscAudit

            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'TestInstance'

            $mockDefaultParameters = @{
                ServerObject = $mockServerObject
                Name = 'Log1'
                Path = Get-TemporaryFolder
                Force = $true
            }
        }

        BeforeEach {
            $script:mockMethodCreateCallCount = 0
        }

        It 'Should call the mocked method and have correct values in the object' {
            New-SqlDscAudit -AuditFilter "([server_principal_name] like '%ADMINISTRATOR'" @mockDefaultParameters

            # This is the object created by the mock and modified by the command.
            $mockCreateAuditObject.Name | Should -Be 'Log1'
            $mockCreateAuditObject.DestinationType | Should -Be 'File'
            $mockCreateAuditObject.FilePath | Should -Be (Get-TemporaryFolder)
            $mockCreateAuditObject.Filter | Should -Be "([server_principal_name] like '%ADMINISTRATOR'"

            $mockMethodCreateCallCount | Should -Be 1
        }
    }

    Context 'When passing optional parameter PassThru' {
        BeforeAll {
            Mock -CommandName New-Object -ParameterFilter {
                $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Audit'
            } -MockWith {
                $mockNewCreateAuditObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Audit' -ArgumentList @(
                    $PesterBoundParameters.ArgumentList[0],
                    $PesterBoundParameters.ArgumentList[1]
                ) |
                    Add-Member -MemberType 'ScriptMethod' -Name 'Create' -Value {
                        $script:mockMethodCreateCallCount += 1
                    } -PassThru -Force

                return $mockNewCreateAuditObject
            }

            Mock -CommandName Get-SqlDscAudit

            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'TestInstance'

            $mockDefaultParameters = @{
                ServerObject = $mockServerObject
                Name = 'Log1'
                Path = Get-TemporaryFolder
                Force = $true
            }
        }

        BeforeEach {
            $script:mockMethodCreateCallCount = 0
        }

        It 'Should call the mocked method and have correct values in the object' {
            $newSqlDscAuditResult = New-SqlDscAudit -PassThru @mockDefaultParameters

            $newSqlDscAuditResult.Name | Should -Be 'Log1'
            $newSqlDscAuditResult.DestinationType | Should -Be 'File'
            $newSqlDscAuditResult.FilePath | Should -Be (Get-TemporaryFolder)

            $mockMethodCreateCallCount | Should -Be 1
        }
    }

    Context 'When the audit already exist' {
        BeforeAll {
            Mock -CommandName Get-SqlDscAudit -MockWith {
                return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Audit'
            }

            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'

            $mockDefaultParameters = @{
                ServerObject = $mockServerObject
                Name = 'Log1'
                LogType = 'ApplicationLog'
                Force = $true
            }
        }

        It 'Should throw the correct error' {
            $mockErrorMessage = InModuleScope -ScriptBlock {
                $script:localizedData.Audit_AlreadyPresent
            }

            { New-SqlDscAudit @mockDefaultParameters } |
                Should -Throw -ExpectedMessage ($mockErrorMessage -f 'Log1')
        }
    }
}
