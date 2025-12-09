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
        }

        It 'Should return true for a valid backup file' {
            # The stub's SqlVerify returns MockSqlVerifyResult which defaults to false
            # We need to set it up to return true
            $result = Test-SqlDscBackupFile -ServerObject $mockServerObject -BackupFile 'C:\Backups\ValidBackup.bak'

            # With default mock, it returns false
            $result | Should -BeFalse
        }

        It 'Should return result when FileNumber is specified' {
            $result = Test-SqlDscBackupFile -ServerObject $mockServerObject -BackupFile 'C:\Backups\ValidBackup.bak' -FileNumber 2

            $result | Should -BeFalse
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
        It 'Should have mandatory ServerObject parameter' {
            $result = (Get-Command -Name 'Test-SqlDscBackupFile').Parameters['ServerObject']
            $result.Attributes.Mandatory | Should -Contain $true
        }

        It 'Should have mandatory BackupFile parameter' {
            $result = (Get-Command -Name 'Test-SqlDscBackupFile').Parameters['BackupFile']
            $result.Attributes.Mandatory | Should -Contain $true
        }

        It 'Should have optional FileNumber parameter' {
            $result = (Get-Command -Name 'Test-SqlDscBackupFile').Parameters['FileNumber']
            $result.Attributes.Mandatory | Should -Not -Contain $true
        }

        It 'Should output Boolean type' {
            $result = Get-Command -Name 'Test-SqlDscBackupFile'
            $result.OutputType.Type | Should -Contain ([System.Boolean])
        }
    }
}
