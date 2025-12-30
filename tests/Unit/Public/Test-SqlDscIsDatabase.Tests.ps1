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

Describe 'Test-SqlDscIsDatabase' -Tag 'Public' {
    Context 'When testing if database exists' {
        BeforeAll {
            $mockExistingDatabase = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
            $mockExistingDatabase | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestDatabase' -Force

            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
        }

        It 'Should return true when database exists' {
            Mock -CommandName Get-SqlDscDatabase -MockWith {
                return $mockExistingDatabase
            }

            $result = Test-SqlDscIsDatabase -ServerObject $mockServerObject -Name 'TestDatabase'

            $result | Should -BeTrue

            Should -Invoke -CommandName Get-SqlDscDatabase -ParameterFilter {
                $ServerObject -eq $mockServerObject -and $Name -eq 'TestDatabase' -and $Refresh -eq $false
            } -Exactly -Times 1 -Scope It
        }

        It 'Should return false when database does not exist' {
            Mock -CommandName Get-SqlDscDatabase -MockWith {
                return $null
            }

            $result = Test-SqlDscIsDatabase -ServerObject $mockServerObject -Name 'NonExistentDatabase'

            $result | Should -BeFalse

            Should -Invoke -CommandName Get-SqlDscDatabase -ParameterFilter {
                $ServerObject -eq $mockServerObject -and $Name -eq 'NonExistentDatabase' -and $Refresh -eq $false
            } -Exactly -Times 1 -Scope It
        }

        It 'Should call Refresh when Refresh parameter is specified' {
            Mock -CommandName Get-SqlDscDatabase -MockWith {
                return $mockExistingDatabase
            }

            $result = Test-SqlDscIsDatabase -ServerObject $mockServerObject -Name 'TestDatabase' -Refresh

            $result | Should -BeTrue

            Should -Invoke -CommandName Get-SqlDscDatabase -ParameterFilter {
                $ServerObject -eq $mockServerObject -and $Name -eq 'TestDatabase' -and $Refresh -eq $true
            } -Exactly -Times 1 -Scope It
        }

        It 'Should support pipeline input' {
            Mock -CommandName Get-SqlDscDatabase -MockWith {
                return $mockExistingDatabase
            }

            $result = $mockServerObject | Test-SqlDscIsDatabase -Name 'TestDatabase'

            $result | Should -BeTrue

            Should -Invoke -CommandName Get-SqlDscDatabase -ParameterFilter {
                $ServerObject -eq $mockServerObject -and $Name -eq 'TestDatabase' -and $Refresh -eq $false
            } -Exactly -Times 1 -Scope It
        }
    }

    Context 'Parameter validation' {
        It 'Should have the correct parameters in parameter set __AllParameterSets' -ForEach @(
            @{
                ExpectedParameterSetName = '__AllParameterSets'
                ExpectedParameters = '[-ServerObject] <Server> [-Name] <String> [-Refresh] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Test-SqlDscIsDatabase').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }

        It 'Should have ServerObject as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Test-SqlDscIsDatabase').Parameters['ServerObject']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have Name as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Test-SqlDscIsDatabase').Parameters['Name']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have Refresh as an optional parameter' {
            $parameterInfo = (Get-Command -Name 'Test-SqlDscIsDatabase').Parameters['Refresh']
            $parameterInfo.Attributes.Mandatory | Should -BeFalse
        }

        It 'Should have ServerObject accept pipeline input' {
            $parameterInfo = (Get-Command -Name 'Test-SqlDscIsDatabase').Parameters['ServerObject']
            $parameterInfo.Attributes.ValueFromPipeline | Should -BeTrue
        }
    }
}
