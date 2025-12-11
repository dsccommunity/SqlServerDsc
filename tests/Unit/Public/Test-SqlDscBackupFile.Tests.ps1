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

Describe 'Test-SqlDscBackupFile' -Tag 'Public' {
    Context 'When verifying a valid backup file' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force

            $script:mockRestoreObject = $null

            Mock -CommandName New-Object -MockWith {
                if ($TypeName -eq 'Microsoft.SqlServer.Management.Smo.Restore')
                {
                    $script:mockRestoreObject = [Microsoft.SqlServer.Management.Smo.Restore]::new()
                    $script:mockRestoreObject.MockSqlVerifyResult = $true

                    return $script:mockRestoreObject
                }

                # For BackupDeviceItem, use the real constructor
                if ($TypeName -eq 'Microsoft.SqlServer.Management.Smo.BackupDeviceItem')
                {
                    return [Microsoft.SqlServer.Management.Smo.BackupDeviceItem]::new($ArgumentList[0], $ArgumentList[1])
                }
            }
        }

        It 'Should return true for a valid backup file' {
            $result = Test-SqlDscBackupFile -ServerObject $mockServerObject -BackupFile 'C:\Backups\ValidBackup.bak'

            $result | Should -BeTrue
        }

        It 'Should return true when FileNumber is specified' {
            $result = Test-SqlDscBackupFile -ServerObject $mockServerObject -BackupFile 'C:\Backups\ValidBackup.bak' -FileNumber 2

            $result | Should -BeTrue
        }
    }

    Context 'When verifying an invalid backup file' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force

            $script:mockRestoreObject = $null

            Mock -CommandName New-Object -MockWith {
                if ($TypeName -eq 'Microsoft.SqlServer.Management.Smo.Restore')
                {
                    $script:mockRestoreObject = [Microsoft.SqlServer.Management.Smo.Restore]::new()
                    $script:mockRestoreObject.MockSqlVerifyResult = $false

                    return $script:mockRestoreObject
                }

                # For BackupDeviceItem, use the real constructor
                if ($TypeName -eq 'Microsoft.SqlServer.Management.Smo.BackupDeviceItem')
                {
                    return [Microsoft.SqlServer.Management.Smo.BackupDeviceItem]::new($ArgumentList[0], $ArgumentList[1])
                }
            }
        }

        It 'Should return false for an invalid backup file' {
            $result = Test-SqlDscBackupFile -ServerObject $mockServerObject -BackupFile 'C:\Backups\InvalidBackup.bak'

            $result | Should -BeFalse
        }

        It 'Should return false when FileNumber is specified' {
            $result = Test-SqlDscBackupFile -ServerObject $mockServerObject -BackupFile 'C:\Backups\InvalidBackup.bak' -FileNumber 2

            $result | Should -BeFalse
        }
    }

    Context 'When SqlVerify throws an exception' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force

            $script:mockRestoreObject = $null

            Mock -CommandName New-Object -MockWith {
                if ($TypeName -eq 'Microsoft.SqlServer.Management.Smo.Restore')
                {
                    $script:mockRestoreObject = [Microsoft.SqlServer.Management.Smo.Restore]::new()
                    $script:mockRestoreObject.MockShouldThrowOnSqlVerify = $true

                    return $script:mockRestoreObject
                }

                # For BackupDeviceItem, use the real constructor
                if ($TypeName -eq 'Microsoft.SqlServer.Management.Smo.BackupDeviceItem')
                {
                    return [Microsoft.SqlServer.Management.Smo.BackupDeviceItem]::new($ArgumentList[0], $ArgumentList[1])
                }
            }
        }

        It 'Should throw a localized error' {
            { Test-SqlDscBackupFile -ServerObject $mockServerObject -BackupFile 'C:\Backups\CorruptBackup.bak' } | Should -Throw -ErrorId 'TSBF0004,Test-SqlDscBackupFile'
        }
    }

    Context 'When pipeline is used' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
        }

        It 'Should accept ServerObject from pipeline' {
            $result = $mockServerObject | Test-SqlDscBackupFile -BackupFile 'C:\Backups\ValidBackup.bak'

            $result | Should -BeFalse
        }
    }

    Context 'Parameter validation' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = '__AllParameterSets'
                ExpectedParameters = '[-ServerObject] <Server> [-BackupFile] <string> [[-FileNumber] <int>] [-LoadHistory] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Test-SqlDscBackupFile').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )
            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }

        It 'Should have mandatory ServerObject parameter' {
            $result = (Get-Command -Name 'Test-SqlDscBackupFile').Parameters['ServerObject']
            $result.Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have mandatory BackupFile parameter' {
            $result = (Get-Command -Name 'Test-SqlDscBackupFile').Parameters['BackupFile']
            $result.Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have optional FileNumber parameter' {
            $result = (Get-Command -Name 'Test-SqlDscBackupFile').Parameters['FileNumber']
            $result.Attributes.Mandatory | Should -BeFalse
        }

        It 'Should output Boolean type' {
            $result = Get-Command -Name 'Test-SqlDscBackupFile'
            $result.OutputType.Type | Should -Contain ([System.Boolean])
        }
    }
}
