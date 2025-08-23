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
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
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

Describe 'Test-SqlDscDatabase' -Tag 'Public' {
    Context 'When testing database presence' {
        BeforeAll {
            $mockExistingDatabase = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
            $mockExistingDatabase | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestDatabase' -Force
            $mockExistingDatabase | Add-Member -MemberType 'NoteProperty' -Name 'Collation' -Value 'SQL_Latin1_General_CP1_CI_AS' -Force
            $mockExistingDatabase | Add-Member -MemberType 'NoteProperty' -Name 'CompatibilityLevel' -Value 'Version150' -Force
            $mockExistingDatabase | Add-Member -MemberType 'NoteProperty' -Name 'RecoveryModel' -Value 'Full' -Force
            $mockExistingDatabase | Add-Member -MemberType 'NoteProperty' -Name 'Owner' -Value 'sa' -Force

            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
            $mockServerObject | Add-Member -MemberType 'ScriptProperty' -Name 'Databases' -Value {
                return @{
                    'TestDatabase' = $mockExistingDatabase
                } | Add-Member -MemberType 'ScriptMethod' -Name 'Refresh' -Value {
                    # Mock implementation
                } -PassThru -Force
            } -Force
        }

        It 'Should return true when database exists and Ensure is Present' {
            Mock -CommandName 'Write-Verbose'

            $result = Test-SqlDscDatabase -ServerObject $mockServerObject -Name 'TestDatabase' -Ensure 'Present'

            $result | Should -BeTrue
        }

        It 'Should return false when database does not exist and Ensure is Present' {
            Mock -CommandName 'Write-Verbose'

            $result = Test-SqlDscDatabase -ServerObject $mockServerObject -Name 'NonExistentDatabase' -Ensure 'Present'

            $result | Should -BeFalse
        }

        It 'Should return false when database exists and Ensure is Absent' {
            Mock -CommandName 'Write-Verbose'

            $result = Test-SqlDscDatabase -ServerObject $mockServerObject -Name 'TestDatabase' -Ensure 'Absent'

            $result | Should -BeFalse
        }

        It 'Should return true when database does not exist and Ensure is Absent' {
            Mock -CommandName 'Write-Verbose'

            $result = Test-SqlDscDatabase -ServerObject $mockServerObject -Name 'NonExistentDatabase' -Ensure 'Absent'

            $result | Should -BeTrue
        }
    }

    Context 'When testing database properties' {
        BeforeAll {
            $mockExistingDatabase = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
            $mockExistingDatabase | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestDatabase' -Force
            $mockExistingDatabase | Add-Member -MemberType 'NoteProperty' -Name 'Collation' -Value 'SQL_Latin1_General_CP1_CI_AS' -Force
            $mockExistingDatabase | Add-Member -MemberType 'NoteProperty' -Name 'CompatibilityLevel' -Value 'Version150' -Force
            $mockExistingDatabase | Add-Member -MemberType 'NoteProperty' -Name 'RecoveryModel' -Value 'Full' -Force
            $mockExistingDatabase | Add-Member -MemberType 'NoteProperty' -Name 'Owner' -Value 'sa' -Force

            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
            $mockServerObject | Add-Member -MemberType 'ScriptProperty' -Name 'Databases' -Value {
                return @{
                    'TestDatabase' = $mockExistingDatabase
                } | Add-Member -MemberType 'ScriptMethod' -Name 'Refresh' -Value {
                    # Mock implementation
                } -PassThru -Force
            } -Force
        }

        It 'Should return true when all properties match' {
            Mock -CommandName 'Write-Verbose'

            $result = Test-SqlDscDatabase -ServerObject $mockServerObject -Name 'TestDatabase' -Ensure 'Present' -Collation 'SQL_Latin1_General_CP1_CI_AS' -CompatibilityLevel 'Version150' -RecoveryModel 'Full' -OwnerName 'sa'

            $result | Should -BeTrue
        }

        It 'Should return false when collation does not match' {
            Mock -CommandName 'Write-Verbose'

            $result = Test-SqlDscDatabase -ServerObject $mockServerObject -Name 'TestDatabase' -Ensure 'Present' -Collation 'Different_Collation'

            $result | Should -BeFalse
        }

        It 'Should return false when compatibility level does not match' {
            Mock -CommandName 'Write-Verbose'

            $result = Test-SqlDscDatabase -ServerObject $mockServerObject -Name 'TestDatabase' -Ensure 'Present' -CompatibilityLevel 'Version140'

            $result | Should -BeFalse
        }

        It 'Should return false when recovery model does not match' {
            Mock -CommandName 'Write-Verbose'

            $result = Test-SqlDscDatabase -ServerObject $mockServerObject -Name 'TestDatabase' -Ensure 'Present' -RecoveryModel 'Simple'

            $result | Should -BeFalse
        }

        It 'Should return false when owner does not match' {
            Mock -CommandName 'Write-Verbose'

            $result = Test-SqlDscDatabase -ServerObject $mockServerObject -Name 'TestDatabase' -Ensure 'Present' -OwnerName 'DifferentOwner'

            $result | Should -BeFalse
        }
    }

    Context 'Parameter validation' {
        It 'Should have the correct parameters in parameter set __AllParameterSets' -ForEach @(
            @{
                ExpectedParameterSetName = '__AllParameterSets'
                ExpectedParameters = '[-ServerObject] <Server> [-Name] <String> [[-Ensure] <String>] [[-Collation] <String>] [[-CompatibilityLevel] <String>] [[-RecoveryModel] <String>] [[-OwnerName] <String>] [-Refresh] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Test-SqlDscDatabase').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }

        It 'Should have ServerObject as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Test-SqlDscDatabase').Parameters['ServerObject']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have Name as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Test-SqlDscDatabase').Parameters['Name']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }
    }
}