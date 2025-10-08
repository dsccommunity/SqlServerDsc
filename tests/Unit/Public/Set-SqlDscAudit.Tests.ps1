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

Describe 'Set-SqlDscAudit' -Tag 'Public' {
    It 'Should have the correct parameters in parameter set <MockParameterSetName>' -ForEach @(
        @{
            MockParameterSetName   = 'ServerObject'
            MockExpectedParameters = '-ServerObject <Server> -Name <string> [-AuditFilter <string>] [-OnFailure <string>] [-QueueDelay <uint>] [-AuditGuid <string>] [-AllowAuditGuidChange] [-Force] [-Refresh] [-PassThru] [-Path <string>] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
        @{
            MockParameterSetName   = 'ServerObjectWithSize'
            MockExpectedParameters = '-ServerObject <Server> -Name <string> -MaximumFileSize <uint> -MaximumFileSizeUnit <string> [-AuditFilter <string>] [-OnFailure <string>] [-QueueDelay <uint>] [-AuditGuid <string>] [-AllowAuditGuidChange] [-Force] [-Refresh] [-PassThru] [-Path <string>] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
        @{
            MockParameterSetName   = 'ServerObjectWithMaxFiles'
            MockExpectedParameters = '-ServerObject <Server> -Name <string> -MaximumFiles <uint> [-AuditFilter <string>] [-OnFailure <string>] [-QueueDelay <uint>] [-AuditGuid <string>] [-AllowAuditGuidChange] [-Force] [-Refresh] [-PassThru] [-Path <string>] [-ReserveDiskSpace] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
        @{
            MockParameterSetName   = 'ServerObjectWithMaxRolloverFiles'
            MockExpectedParameters = '-ServerObject <Server> -Name <string> -MaximumRolloverFiles <uint> [-AuditFilter <string>] [-OnFailure <string>] [-QueueDelay <uint>] [-AuditGuid <string>] [-AllowAuditGuidChange] [-Force] [-Refresh] [-PassThru] [-Path <string>] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
        @{
            MockParameterSetName   = 'ServerObjectWithSizeAndMaxFiles'
            MockExpectedParameters = '-ServerObject <Server> -Name <string> -MaximumFileSize <uint> -MaximumFileSizeUnit <string> -MaximumFiles <uint> [-AuditFilter <string>] [-OnFailure <string>] [-QueueDelay <uint>] [-AuditGuid <string>] [-AllowAuditGuidChange] [-Force] [-Refresh] [-PassThru] [-Path <string>] [-ReserveDiskSpace] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
        @{
            MockParameterSetName   = 'ServerObjectWithSizeAndMaxRolloverFiles'
            MockExpectedParameters = '-ServerObject <Server> -Name <string> -MaximumFileSize <uint> -MaximumFileSizeUnit <string> -MaximumRolloverFiles <uint> [-AuditFilter <string>] [-OnFailure <string>] [-QueueDelay <uint>] [-AuditGuid <string>] [-AllowAuditGuidChange] [-Force] [-Refresh] [-PassThru] [-Path <string>] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
        @{
            MockParameterSetName   = 'AuditObject'
            MockExpectedParameters = '-AuditObject <Audit> [-AuditFilter <string>] [-OnFailure <string>] [-QueueDelay <uint>] [-AuditGuid <string>] [-AllowAuditGuidChange] [-Force] [-Refresh] [-PassThru] [-Path <string>] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
        @{
            MockParameterSetName   = 'AuditObjectWithSize'
            MockExpectedParameters = '-AuditObject <Audit> -MaximumFileSize <uint> -MaximumFileSizeUnit <string> [-AuditFilter <string>] [-OnFailure <string>] [-QueueDelay <uint>] [-AuditGuid <string>] [-AllowAuditGuidChange] [-Force] [-Refresh] [-PassThru] [-Path <string>] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
        @{
            MockParameterSetName   = 'AuditObjectWithMaxFiles'
            MockExpectedParameters = '-AuditObject <Audit> -MaximumFiles <uint> [-AuditFilter <string>] [-OnFailure <string>] [-QueueDelay <uint>] [-AuditGuid <string>] [-AllowAuditGuidChange] [-Force] [-Refresh] [-PassThru] [-Path <string>] [-ReserveDiskSpace] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
        @{
            MockParameterSetName   = 'AuditObjectWithMaxRolloverFiles'
            MockExpectedParameters = '-AuditObject <Audit> -MaximumRolloverFiles <uint> [-AuditFilter <string>] [-OnFailure <string>] [-QueueDelay <uint>] [-AuditGuid <string>] [-AllowAuditGuidChange] [-Force] [-Refresh] [-PassThru] [-Path <string>] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
        @{
            MockParameterSetName   = 'AuditObjectWithSizeAndMaxFiles'
            MockExpectedParameters = '-AuditObject <Audit> -MaximumFileSize <uint> -MaximumFileSizeUnit <string> -MaximumFiles <uint> [-AuditFilter <string>] [-OnFailure <string>] [-QueueDelay <uint>] [-AuditGuid <string>] [-AllowAuditGuidChange] [-Force] [-Refresh] [-PassThru] [-Path <string>] [-ReserveDiskSpace] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
        @{
            MockParameterSetName   = 'AuditObjectWithSizeAndMaxRolloverFiles'
            MockExpectedParameters = '-AuditObject <Audit> -MaximumFileSize <uint> -MaximumFileSizeUnit <string> -MaximumRolloverFiles <uint> [-AuditFilter <string>] [-OnFailure <string>] [-QueueDelay <uint>] [-AuditGuid <string>] [-AllowAuditGuidChange] [-Force] [-Refresh] [-PassThru] [-Path <string>] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
    ) {
        $result = (Get-Command -Name 'Set-SqlDscAudit').ParameterSets |
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

    Context 'When setting an audit by an ServerObject' {
        BeforeAll {
            $script:mockAuditObject = $null

            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'TestInstance'

            Mock -CommandName Get-SqlDscAudit -MockWith {
                <#
                    The Audit object is created in the script scope so that the
                    properties can be validated.
                #>
                $script:mockAuditObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Audit' -ArgumentList @(
                    $mockServerObject,
                    'Log1'
                ) |
                    Add-Member -MemberType 'ScriptMethod' -Name 'Alter' -Value {
                        $script:mockMethodAlterCallCount += 1
                    } -PassThru -Force

                return $script:mockAuditObject
            }

            $mockDefaultParameters = @{
                ServerObject = $mockServerObject
                Name         = 'Log1'
            }
        }

        BeforeEach {
            $script:mockMethodAlterCallCount = 0
        }

        Context 'When using parameter Confirm with value $false' {
            It 'Should call the mocked method and have correct values in the object' {
                Set-SqlDscAudit -Confirm:$false -QueueDelay 1000 @mockDefaultParameters

                # This is the object created by the mock and modified by the command.
                $mockAuditObject.Name | Should -Be 'Log1'
                $mockAuditObject.QueueDelay | Should -Be 1000

                $mockMethodAlterCallCount | Should -Be 1
            }
        }

        Context 'When using parameter Force' {
            It 'Should call the mocked method and have correct values in the object' {
                Set-SqlDscAudit -Force -QueueDelay 1000 @mockDefaultParameters

                # This is the object created by the mock and modified by the command.
                $mockAuditObject.Name | Should -Be 'Log1'
                $mockAuditObject.QueueDelay | Should -Be 1000

                $mockMethodAlterCallCount | Should -Be 1
            }
        }

        Context 'When using parameter WhatIf' {
            It 'Should call the mocked method and have correct values in the object' {
                Set-SqlDscAudit -WhatIf -QueueDelay 1000 @mockDefaultParameters

                # This is the object created by the mock and modified by the command.
                $mockAuditObject.Name | Should -Be 'Log1'
                $mockAuditObject.QueueDelay | Should -BeNullOrEmpty

                $mockMethodAlterCallCount | Should -Be 0
            }
        }

        Context 'When passing parameter ServerObject over the pipeline' {
            It 'Should call the mocked method and have correct values in the object' {
                $mockServerObject | Set-SqlDscAudit -Name 'Log1' -QueueDelay 1000 -Force

                # This is the object created by the mock and modified by the command.
                $mockAuditObject.Name | Should -Be 'Log1'
                $mockAuditObject.QueueDelay | Should -Be 1000

                $mockMethodAlterCallCount | Should -Be 1
            }
        }
    }

    Context 'When setting an audit by an AuditObject' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'TestInstance'
        }

        BeforeEach {
            $mockAuditObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Audit' -ArgumentList @(
                $mockServerObject,
                'Log1'
            ) |
                Add-Member -MemberType 'ScriptMethod' -Name 'Alter' -Value {
                    $script:mockMethodAlterCallCount += 1
                } -PassThru -Force

            $mockDefaultParameters = @{
                AuditObject = $mockAuditObject
            }

            $script:mockMethodAlterCallCount = 0
        }

        Context 'When using parameter Confirm with value $false' {
            It 'Should call the mocked method and have correct values in the object' {
                Set-SqlDscAudit -Confirm:$false -QueueDelay 1000 @mockDefaultParameters

                # This is the object created by the mock and modified by the command.
                $mockAuditObject.Name | Should -Be 'Log1'
                $mockAuditObject.QueueDelay | Should -Be 1000

                $mockMethodAlterCallCount | Should -Be 1
            }
        }

        Context 'When using parameter Force' {
            It 'Should call the mocked method and have correct values in the object' {
                Set-SqlDscAudit -Force -QueueDelay 1000 @mockDefaultParameters

                # This is the object created by the mock and modified by the command.
                $mockAuditObject.Name | Should -Be 'Log1'
                $mockAuditObject.QueueDelay | Should -Be 1000

                $mockMethodAlterCallCount | Should -Be 1
            }
        }

        Context 'When using parameter WhatIf' {
            It 'Should call the mocked method and have correct values in the object' {
                Set-SqlDscAudit -WhatIf -QueueDelay 1000 @mockDefaultParameters

                # This is the object created by the mock and modified by the command.
                $mockAuditObject.Name | Should -Be 'Log1'
                $mockAuditObject.QueueDelay | Should -BeNullOrEmpty

                $mockMethodAlterCallCount | Should -Be 0
            }
        }

        Context 'When passing parameter AuditObject over the pipeline' {
            It 'Should call the mocked method and have correct values in the object' {
                $mockAuditObject | Set-SqlDscAudit -QueueDelay 1000 -Force

                # This is the object created by the mock and modified by the command.
                $mockAuditObject.Name | Should -Be 'Log1'
                $mockAuditObject.QueueDelay | Should -Be 1000

                $mockMethodAlterCallCount | Should -Be 1
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
                Path         = Get-TemporaryFolder
                Name         = 'Log1'
            }

            $mockErrorMessage = InModuleScope -ScriptBlock {
                $script:localizedData.Audit_PathParameterValueInvalid
            }

            $mockErrorMessage = "Cannot validate argument on parameter 'Path'. " + ($mockErrorMessage -f (Get-TemporaryFolder))

            { Set-SqlDscAudit @mockNewSqlDscAuditParameters } | Should -Throw -ExpectedMessage $mockErrorMessage
        }
    }

    Context 'When adding an file audit and passing an invalid MaximumFileSize' {
        It 'Should throw the correct error when the value is <_>' -ForEach @(1, 2147483648) {
            $mockNewSqlDscAuditParameters = @{
                ServerObject    = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                Name            = 'Log1'
                MaximumFileSize = $_
            }

            $mockErrorMessage = 'Cannot validate argument on parameter ''MaximumFileSize''. '
            $mockErrorMessage += InModuleScope -ScriptBlock {
                $script:localizedData.Audit_MaximumFileSizeParameterValueInvalid
            }

            { Set-SqlDscAudit @mockNewSqlDscAuditParameters } | Should -Throw -ExpectedMessage $mockErrorMessage
        }
    }

    Context 'When adding an file audit and passing an invalid QueueDelay' {
        It 'Should throw the correct error when the value is <_>' -ForEach @(1, 457, 999, 2147483648) {
            $mockNewSqlDscAuditParameters = @{
                ServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                Name         = 'Log1'
                QueueDelay   = $_
            }

            $mockErrorMessage = 'Cannot validate argument on parameter ''QueueDelay''. '
            $mockErrorMessage += InModuleScope -ScriptBlock {
                $script:localizedData.Audit_QueueDelayParameterValueInvalid
            }

            { Set-SqlDscAudit @mockNewSqlDscAuditParameters } | Should -Throw -ExpectedMessage $mockErrorMessage
        }
    }

    Context 'When passing file audit optional parameter Path' {
        BeforeAll {
            $script:mockAuditObject = $null

            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'TestInstance'

            $script:mockAuditObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Audit' -ArgumentList @(
                $mockServerObject,
                'Log1'
            ) |
                Add-Member -MemberType 'ScriptMethod' -Name 'Alter' -Value {
                    $script:mockMethodAlterCallCount += 1
                } -PassThru -Force

            $mockDefaultParameters = @{
                AuditObject = $mockAuditObject
                Force       = $true
            }
        }

        BeforeEach {
            $script:mockMethodAlterCallCount = 0
        }

        It 'Should call the mocked method and have correct values in the object' {
            Set-SqlDscAudit -Path (Get-TemporaryFolder) @mockDefaultParameters

            # This is the object created by the mock and modified by the command.
            $mockAuditObject.Name | Should -Be 'Log1'
            $mockAuditObject.FilePath | Should -Be (Get-TemporaryFolder)

            $mockMethodAlterCallCount | Should -Be 1
        }
    }

    Context 'When passing file audit optional parameters MaximumFileSize and MaximumFileSizeUnit' {
        BeforeAll {
            $script:mockAuditObject = $null

            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'TestInstance'

            $script:mockAuditObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Audit' -ArgumentList @(
                $mockServerObject,
                'Log1'
            ) |
                Add-Member -MemberType 'ScriptMethod' -Name 'Alter' -Value {
                    $script:mockMethodAlterCallCount += 1
                } -PassThru -Force

            $mockDefaultParameters = @{
                AuditObject = $mockAuditObject
                Force       = $true
            }
        }

        BeforeEach {
            $script:mockMethodAlterCallCount = 0
        }

        It 'Should call the mocked method and have correct values in the object' {
            Set-SqlDscAudit -MaximumFileSize 1000 -MaximumFileSizeUnit 'Megabyte' @mockDefaultParameters

            # This is the object created by the mock and modified by the command.
            $mockAuditObject.Name | Should -Be 'Log1'
            $mockAuditObject.MaximumFileSize | Should -Be 1000
            $mockAuditObject.MaximumFileSizeUnit | Should -Be 'Mb'

            $mockMethodAlterCallCount | Should -Be 1
        }
    }

    Context 'When passing file audit optional parameters MaximumFiles' {
        BeforeAll {
            $script:mockAuditObject = $null

            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'TestInstance'

            $script:mockAuditObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Audit' -ArgumentList @(
                $mockServerObject,
                'Log1'
            ) |
                Add-Member -MemberType 'ScriptMethod' -Name 'Alter' -Value {
                    $script:mockMethodAlterCallCount += 1
                } -PassThru -Force

            $mockDefaultParameters = @{
                AuditObject = $mockAuditObject
                Force       = $true
            }
        }

        BeforeEach {
            $script:mockMethodAlterCallCount = 0
        }

        It 'Should call the mocked method and have correct values in the object' {
            Set-SqlDscAudit -MaximumFiles 2 @mockDefaultParameters

            # This is the object created by the mock and modified by the command.
            $mockAuditObject.Name | Should -Be 'Log1'
            $mockAuditObject.MaximumFiles | Should -Be 2

            $mockMethodAlterCallCount | Should -Be 1
        }
    }

    Context 'When passing file audit optional parameters MaximumFiles and ReserveDiskSpace' {
        BeforeAll {
            $script:mockAuditObject = $null

            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'TestInstance'

            $script:mockAuditObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Audit' -ArgumentList @(
                $mockServerObject,
                'Log1'
            ) |
                Add-Member -MemberType 'ScriptMethod' -Name 'Alter' -Value {
                    $script:mockMethodAlterCallCount += 1
                } -PassThru -Force

            $mockDefaultParameters = @{
                AuditObject = $mockAuditObject
                Force       = $true
            }
        }

        BeforeEach {
            $script:mockMethodAlterCallCount = 0
        }

        It 'Should call the mocked method and have correct values in the object' {
            Set-SqlDscAudit -MaximumFiles 2 -ReserveDiskSpace @mockDefaultParameters

            # This is the object created by the mock and modified by the command.
            $mockAuditObject.Name | Should -Be 'Log1'
            $mockAuditObject.MaximumFiles | Should -Be 2
            $mockAuditObject.ReserveDiskSpace | Should -BeTrue

            $mockMethodAlterCallCount | Should -Be 1
        }

        Context 'When ReserveDiskSpace is set to $false' {
            It 'Should call the mocked method and have correct values in the object' {
                Set-SqlDscAudit -MaximumFiles 2 -ReserveDiskSpace:$false @mockDefaultParameters

                # This is the object created by the mock and modified by the command.
                $mockAuditObject.Name | Should -Be 'Log1'
                $mockAuditObject.MaximumFiles | Should -Be 2
                $mockAuditObject.ReserveDiskSpace | Should -BeFalse

                $mockMethodAlterCallCount | Should -Be 1
            }
        }
    }

    Context 'When passing file audit optional parameters MaximumRolloverFiles' {
        BeforeAll {
            $script:mockAuditObject = $null

            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'TestInstance'

            $script:mockAuditObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Audit' -ArgumentList @(
                $mockServerObject,
                'Log1'
            ) |
                Add-Member -MemberType 'ScriptMethod' -Name 'Alter' -Value {
                    $script:mockMethodAlterCallCount += 1
                } -PassThru -Force

            $mockDefaultParameters = @{
                AuditObject = $mockAuditObject
                Force       = $true
            }
        }

        BeforeEach {
            $script:mockMethodAlterCallCount = 0
        }

        It 'Should call the mocked method and have correct values in the object' {
            Set-SqlDscAudit -MaximumRolloverFiles 2 @mockDefaultParameters

            # This is the object created by the mock and modified by the command.
            $mockAuditObject.Name | Should -Be 'Log1'
            $mockAuditObject.MaximumRolloverFiles | Should -Be 2

            $mockMethodAlterCallCount | Should -Be 1
        }
    }

    Context 'When passing audit optional parameter AuditGuid' {
        BeforeAll {
            $script:mockAuditObject = $null

            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'TestInstance'

            $script:mockAuditObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Audit' -ArgumentList @(
                $mockServerObject,
                'Log1'
            ) |
                Add-Member -MemberType 'ScriptMethod' -Name 'Alter' -Value {
                    $script:mockMethodAlterCallCount += 1
                } -PassThru -Force

            # Set a different initial GUID
            $script:mockAuditObject.Guid = 'a1111111-1111-1111-1111-111111111111'

            Mock -CommandName ConvertTo-AuditNewParameterSet -MockWith {
                return @{
                    ServerObject = $AuditObject.Parent
                    Name         = $AuditObject.Name
                    LogType      = 'ApplicationLog'
                    AuditGuid    = $AuditGuid
                }
            }

            Mock -CommandName Remove-SqlDscAudit

            Mock -CommandName New-SqlDscAudit -MockWith {
                $newAudit = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Audit' -ArgumentList @(
                    $ServerObject,
                    $Name
                )

                # Add the Alter method
                $newAudit | Add-Member -MemberType 'ScriptMethod' -Name 'Alter' -Value {
                    $script:mockMethodAlterCallCount += 1
                } -Force

                # Set the Guid property directly on the SMO object (convert string to GUID)
                # PowerShell should automatically convert the string to a GUID when assigning
                if ($null -ne $AuditGuid -and $AuditGuid -ne '')
                {
                    $newAudit.Guid = $AuditGuid
                }

                return $newAudit
            }

            $mockDefaultParameters = @{
                AuditObject = $mockAuditObject
                Force       = $true
            }
        }

        BeforeEach {
            $script:mockMethodAlterCallCount = 0
        }

        It 'Should recreate the audit with the new GUID when AllowAuditGuidChange is specified' {
            $result = Set-SqlDscAudit -AuditGuid 'b5962b93-a359-42ef-bf1e-193e8a5f6222' -AllowAuditGuidChange -PassThru @mockDefaultParameters

            # Debug: Check what we got back
            $result | Should -Not -BeNullOrEmpty -Because 'PassThru should return the audit object'
            $result.Name | Should -Be 'Log1' -Because 'The audit name should match'
            $result.Guid | Should -Be 'b5962b93-a359-42ef-bf1e-193e8a5f6222' -Because 'The GUID should be set to the new value'

            # Verify the helper function was called with correct GUID
            Should -Invoke -CommandName ConvertTo-AuditNewParameterSet -Exactly -Times 1 -Scope It -ParameterFilter {
                $AuditGuid -eq 'b5962b93-a359-42ef-bf1e-193e8a5f6222'
            }

            # Verify the audit was removed
            Should -Invoke -CommandName Remove-SqlDscAudit -Exactly -Times 1 -Scope It

            # Verify the audit was recreated with PassThru and the correct GUID
            Should -Invoke -CommandName New-SqlDscAudit -Exactly -Times 1 -Scope It -ParameterFilter {
                $PassThru.IsPresent -and $AuditGuid -eq 'b5962b93-a359-42ef-bf1e-193e8a5f6222'
            }
        }

        Context 'When AuditGuid is same as existing GUID' {
            It 'Should not recreate the audit but still call Alter' {
                $mockAuditObject.Guid = 'b5962b93-a359-42ef-bf1e-193e8a5f6222'

                Set-SqlDscAudit -AuditGuid 'b5962b93-a359-42ef-bf1e-193e8a5f6222' -AllowAuditGuidChange @mockDefaultParameters

                # Should not invoke helper functions when GUID is not changing
                Should -Invoke -CommandName ConvertTo-AuditNewParameterSet -Exactly -Times 0 -Scope It
                Should -Invoke -CommandName Remove-SqlDscAudit -Exactly -Times 0 -Scope It
                Should -Invoke -CommandName New-SqlDscAudit -Exactly -Times 0 -Scope It

                # Alter() is still called even when no property values change
                $mockMethodAlterCallCount | Should -Be 1 -Because 'Alter() is always called in the normal update path'
            }
        }

        Context 'When AuditGuid is same as existing GUID but other properties change' {
            It 'Should update properties without recreating the audit' {
                # Set the existing GUID and QueueDelay
                $mockAuditObject.Guid = 'b5962b93-a359-42ef-bf1e-193e8a5f6222'
                $mockAuditObject.QueueDelay = 500

                # Call with same GUID but different QueueDelay
                Set-SqlDscAudit -AuditGuid 'b5962b93-a359-42ef-bf1e-193e8a5f6222' -QueueDelay 1000 -AllowAuditGuidChange @mockDefaultParameters

                # Should not invoke helper functions when GUID is not changing
                Should -Invoke -CommandName ConvertTo-AuditNewParameterSet -Exactly -Times 0 -Scope It
                Should -Invoke -CommandName Remove-SqlDscAudit -Exactly -Times 0 -Scope It
                Should -Invoke -CommandName New-SqlDscAudit -Exactly -Times 0 -Scope It

                # Verify the property was updated
                $mockAuditObject.QueueDelay | Should -Be 1000 -Because 'QueueDelay should be updated to the new value'

                # Alter() should be called to persist the property change
                $mockMethodAlterCallCount | Should -Be 1 -Because 'Alter() is called to update the property'
            }
        }

        Context 'When trying to change AuditGuid without AllowAuditGuidChange parameter' {
            It 'Should throw the correct error' {
                # Ensure the GUID is different from what we're trying to set
                $mockAuditObject.Guid = 'a1111111-1111-1111-1111-111111111111'

                $mockErrorMessage = InModuleScope -ScriptBlock {
                    $script:localizedData.Audit_AuditGuidChangeRequiresAllowParameter -f 'Log1'
                }

                { Set-SqlDscAudit -AuditGuid 'b5962b93-a359-42ef-bf1e-193e8a5f6222' @mockDefaultParameters } |
                    Should -Throw -ExpectedMessage $mockErrorMessage
            }
        }

        Context 'When passing an invalid GUID' {
            It 'Should throw the correct error' {
                $mockErrorMessage = 'Cannot validate argument on parameter ''AuditGuid''. The argument "not a guid" does not match the "^[0-9a-fA-F]{8}-(?:[0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$" pattern.'

                # Escape bracket so that Should -Throw works.
                $mockErrorMessage = $mockErrorMessage -replace '\[', '`['

                { Set-SqlDscAudit -AuditGuid 'not a guid' @mockDefaultParameters } |
                    Should -Throw -ExpectedMessage ($mockErrorMessage + '*')
            }
        }
    }

    Context 'When passing audit optional parameter OnFailure' {
        BeforeAll {
            $script:mockAuditObject = $null

            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'TestInstance'

            $script:mockAuditObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Audit' -ArgumentList @(
                $mockServerObject,
                'Log1'
            ) |
                Add-Member -MemberType 'ScriptMethod' -Name 'Alter' -Value {
                    $script:mockMethodAlterCallCount += 1
                } -PassThru -Force

            $mockDefaultParameters = @{
                AuditObject = $mockAuditObject
                Force       = $true
            }
        }

        BeforeEach {
            $script:mockMethodAlterCallCount = 0
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
                Set-SqlDscAudit -OnFailure $MockOnFailureValue @mockDefaultParameters

                # This is the object created by the mock and modified by the command.
                $mockAuditObject.Name | Should -Be 'Log1'
                $mockAuditObject.OnFailure | Should -Be $MockOnFailureValue

                $mockMethodAlterCallCount | Should -Be 1
            }
        }
    }

    Context 'When passing audit optional parameter QueueDelay' {
        BeforeAll {
            $script:mockAuditObject = $null

            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'TestInstance'

            $script:mockAuditObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Audit' -ArgumentList @(
                $mockServerObject,
                'Log1'
            ) |
                Add-Member -MemberType 'ScriptMethod' -Name 'Alter' -Value {
                    $script:mockMethodAlterCallCount += 1
                } -PassThru -Force

            $mockDefaultParameters = @{
                AuditObject = $mockAuditObject
                Force       = $true
            }
        }

        BeforeEach {
            $script:mockMethodAlterCallCount = 0
        }

        It 'Should call the mocked method and have correct values in the object' {
            Set-SqlDscAudit -QueueDelay 1000 @mockDefaultParameters

            # This is the object created by the mock and modified by the command.
            $mockAuditObject.Name | Should -Be 'Log1'
            $mockAuditObject.QueueDelay | Should -Be 1000

            $mockMethodAlterCallCount | Should -Be 1
        }
    }

    Context 'When passing audit optional parameter Filter' {
        BeforeAll {
            $script:mockAuditObject = $null

            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'TestInstance'

            $script:mockAuditObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Audit' -ArgumentList @(
                $mockServerObject,
                'Log1'
            ) |
                Add-Member -MemberType 'ScriptMethod' -Name 'Alter' -Value {
                    $script:mockMethodAlterCallCount += 1
                } -PassThru -Force

            $mockDefaultParameters = @{
                AuditObject = $mockAuditObject
                Force       = $true
            }
        }

        BeforeEach {
            $script:mockMethodAlterCallCount = 0
        }

        It 'Should call the mocked method and have correct values in the object' {
            Set-SqlDscAudit -AuditFilter "([server_principal_name] like '%ADMINISTRATOR'" @mockDefaultParameters

            # This is the object created by the mock and modified by the command.
            $mockAuditObject.Name | Should -Be 'Log1'
            $mockAuditObject.Filter | Should -Be "([server_principal_name] like '%ADMINISTRATOR'"

            $mockMethodAlterCallCount | Should -Be 1
        }
    }

    Context 'When passing optional parameter PassThru' {
        BeforeAll {
            $script:mockAuditObject = $null

            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'TestInstance'

            $script:mockAuditObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Audit' -ArgumentList @(
                $mockServerObject,
                'Log1'
            ) |
                Add-Member -MemberType 'ScriptMethod' -Name 'Alter' -Value {
                    $script:mockMethodAlterCallCount += 1
                } -PassThru -Force

            $mockDefaultParameters = @{
                AuditObject = $mockAuditObject
                Force       = $true
            }
        }

        BeforeEach {
            $script:mockMethodAlterCallCount = 0
        }

        It 'Should call the mocked method and have correct values in the object' {
            $newSqlDscAuditResult = Set-SqlDscAudit -QueueDelay 1000 -PassThru @mockDefaultParameters

            $newSqlDscAuditResult.Name | Should -Be 'Log1'
            $newSqlDscAuditResult.QueueDelay | Should -Be 1000

            $mockMethodAlterCallCount | Should -Be 1
        }
    }

    Context 'When passing optional parameter Refresh' {
        BeforeAll {
            $script:mockAuditObject = $null

            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'TestInstance'

            $script:mockAuditObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Audit' -ArgumentList @(
                $mockServerObject,
                'Log1'
            ) |
                Add-Member -MemberType 'ScriptMethod' -Name 'Alter' -Value {
                    $script:mockMethodAlterCallCount += 1
                } -PassThru |
                Add-Member -MemberType 'ScriptMethod' -Name 'Refresh' -Value {
                    $script:mockMethodRefreshCallCount += 1
                } -PassThru -Force

            $mockDefaultParameters = @{
                AuditObject = $mockAuditObject
                Force       = $true
            }
        }

        BeforeEach {
            $script:mockMethodAlterCallCount = 0
            $script:mockMethodRefreshCallCount = 0
        }

        It 'Should call the mocked method and have correct values in the object' {
            Set-SqlDscAudit -QueueDelay 1000 -Refresh @mockDefaultParameters

            $mockAuditObject.Name | Should -Be 'Log1'
            $mockAuditObject.QueueDelay | Should -Be 1000

            $mockMethodAlterCallCount | Should -Be 1
            $mockMethodRefreshCallCount | Should -Be 1
        }
    }

    Context 'When changing AuditGuid with AllowAuditGuidChange and other properties' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'TestInstance'

            $script:mockAuditObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Audit' -ArgumentList @(
                $mockServerObject,
                'Log1'
            ) |
                Add-Member -MemberType 'ScriptMethod' -Name 'Alter' -Value {
                    $script:mockMethodAlterCallCount += 1
                } -PassThru -Force

            # Set a different initial GUID
            $script:mockAuditObject.Guid = 'a1111111-1111-1111-1111-111111111111'

            Mock -CommandName ConvertTo-AuditNewParameterSet -MockWith {
                return @{
                    ServerObject = $AuditObject.Parent
                    Name         = $AuditObject.Name
                    LogType      = 'ApplicationLog'
                    AuditGuid    = $AuditGuid
                }
            }

            Mock -CommandName Remove-SqlDscAudit

            # Track recursive call to Set-SqlDscAudit
            $script:setAuditRecursiveCallCount = 0

            Mock -CommandName New-SqlDscAudit -MockWith {
                $newAudit = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Audit' -ArgumentList @(
                    $ServerObject,
                    $Name
                )

                # Add the Alter method
                $newAudit | Add-Member -MemberType 'ScriptMethod' -Name 'Alter' -Value {
                    $script:mockMethodAlterCallCount += 1
                } -Force

                # Set the Guid property directly on the SMO object (convert string to GUID)
                # PowerShell should automatically convert the string to a GUID when assigning
                if ($null -ne $AuditGuid -and $AuditGuid -ne '')
                {
                    $newAudit.Guid = $AuditGuid
                }

                return $newAudit
            }

            $mockDefaultParameters = @{
                AuditObject = $mockAuditObject
                Force       = $true
            }
        }

        BeforeEach {
            $script:mockMethodAlterCallCount = 0
            $script:setAuditRecursiveCallCount = 0
        }

        It 'Should recreate the audit with new GUID and apply other property changes' {
            $result = Set-SqlDscAudit -AuditGuid 'b5962b93-a359-42ef-bf1e-193e8a5f6222' -AllowAuditGuidChange -QueueDelay 1000 -PassThru @mockDefaultParameters

            # Verify the helper function was called with correct GUID
            Should -Invoke -CommandName ConvertTo-AuditNewParameterSet -Exactly -Times 1 -Scope It -ParameterFilter {
                $AuditGuid -eq 'b5962b93-a359-42ef-bf1e-193e8a5f6222'
            }

            # Verify the audit was removed
            Should -Invoke -CommandName Remove-SqlDscAudit -Exactly -Times 1 -Scope It

            # Verify the audit was recreated with PassThru and the correct GUID
            Should -Invoke -CommandName New-SqlDscAudit -Exactly -Times 1 -Scope It -ParameterFilter {
                $PassThru.IsPresent -and $AuditGuid -eq 'b5962b93-a359-42ef-bf1e-193e8a5f6222'
            }

            # The result should not be null
            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'Log1'

            # The QueueDelay should be set (via recursive call to Set-SqlDscAudit)
            $result.QueueDelay | Should -Be 1000
            $result.Guid | Should -Be 'b5962b93-a359-42ef-bf1e-193e8a5f6222' -Because 'The GUID should be set to the new value'
        }
    }

    Context 'When switching from MaximumRolloverFiles to MaximumFiles' {
        BeforeAll {
            $script:mockAuditObject = $null

            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'TestInstance'

            $script:mockAuditObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Audit' -ArgumentList @(
                $mockServerObject,
                'Log1'
            ) |
                Add-Member -MemberType 'ScriptMethod' -Name 'Alter' -Value {
                    $script:mockMethodAlterCallCount += 1
                } -PassThru -Force

            $script:mockAuditObject.MaximumRolloverFiles = 10

            $mockDefaultParameters = @{
                AuditObject = $mockAuditObject
                Force       = $true
            }
        }

        BeforeEach {
            $script:mockMethodAlterCallCount = 0
        }

        It 'Should call the mocked method and have correct values in the object' {
            $mockAuditObject.MaximumRolloverFiles | Should -Be 10 -Because 'there has to be a value greater than 0 in the object that is passed to the command in this test'

            Set-SqlDscAudit -MaximumFiles 2 @mockDefaultParameters

            # This is the object created by the mock and modified by the command.
            $mockAuditObject.Name | Should -Be 'Log1'
            $mockAuditObject.MaximumRolloverFiles | Should -Be 0
            $mockAuditObject.MaximumFiles | Should -Be 2

            $mockMethodAlterCallCount | Should -Be 2 -Because 'the call to Alter() need to happen twice, first to set MaximumRolloverFiles to 0, then another to set MaximumFiles to the new value'
        }
    }

    Context 'When switching from MaximumFiles to MaximumRolloverFiles' {
        BeforeAll {
            $script:mockAuditObject = $null

            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'TestInstance'

            $script:mockAuditObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Audit' -ArgumentList @(
                $mockServerObject,
                'Log1'
            ) |
                Add-Member -MemberType 'ScriptMethod' -Name 'Alter' -Value {
                    $script:mockMethodAlterCallCount += 1
                } -PassThru -Force

            $script:mockAuditObject.MaximumFiles = 10

            $mockDefaultParameters = @{
                AuditObject = $mockAuditObject
                Force       = $true
            }
        }

        BeforeEach {
            $script:mockMethodAlterCallCount = 0
        }

        It 'Should call the mocked method and have correct values in the object' {
            $mockAuditObject.MaximumFiles | Should -Be 10 -Because 'there has to be a value greater than 0 in the object that is passed to the command in this test'

            Set-SqlDscAudit -MaximumRolloverFiles 2 @mockDefaultParameters

            # This is the object created by the mock and modified by the command.
            $mockAuditObject.Name | Should -Be 'Log1'
            $mockAuditObject.MaximumFiles | Should -Be 0
            $mockAuditObject.MaximumRolloverFiles | Should -Be 2

            $mockMethodAlterCallCount | Should -Be 2 -Because 'the call to Alter() need to happen twice, first to set MaximumFiles to 0, then another to set MaximumRolloverFiles to the new value'
        }
    }
}
