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

Describe 'Get-SqlDscBackupFileList' -Tag 'Public' {
    Context 'When reading file list from a backup file' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
        }

        It 'Should return empty array when backup has no files (mock returns null DataTable)' {
            # The stub's ReadFileList returns MockReadFileListResult which defaults to null
            $result = Get-SqlDscBackupFileList -ServerObject $mockServerObject -BackupFile 'C:\Backups\TestBackup.bak'

            $result | Should -BeNullOrEmpty
        }

        It 'Should accept FileNumber parameter' {
            $result = Get-SqlDscBackupFileList -ServerObject $mockServerObject -BackupFile 'C:\Backups\TestBackup.bak' -FileNumber 2

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'When pipeline is used' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
        }

        It 'Should accept ServerObject from pipeline' {
            $result = $mockServerObject | Get-SqlDscBackupFileList -BackupFile 'C:\Backups\TestBackup.bak'

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Parameter validation' {
        It 'Should have mandatory ServerObject parameter' {
            $result = (Get-Command -Name 'Get-SqlDscBackupFileList').Parameters['ServerObject']
            $result.Attributes.Mandatory | Should -Contain $true
        }

        It 'Should have mandatory BackupFile parameter' {
            $result = (Get-Command -Name 'Get-SqlDscBackupFileList').Parameters['BackupFile']
            $result.Attributes.Mandatory | Should -Contain $true
        }

        It 'Should have optional FileNumber parameter' {
            $result = (Get-Command -Name 'Get-SqlDscBackupFileList').Parameters['FileNumber']
            $result.Attributes.Mandatory | Should -Not -Contain $true
        }

        It 'Should have FileNumber parameter with range validation' {
            $result = (Get-Command -Name 'Get-SqlDscBackupFileList').Parameters['FileNumber']
            $rangeAttribute = $result.Attributes | Where-Object -FilterScript { $_ -is [System.Management.Automation.ValidateRangeAttribute] }
            $rangeAttribute.MinRange | Should -Be 1
            $rangeAttribute.MaxRange | Should -Be 2147483647
        }
    }
}
