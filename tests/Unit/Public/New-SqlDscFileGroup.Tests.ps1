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

Describe 'New-SqlDscFileGroup' -Tag 'Public' {
    Context 'When creating a new FileGroup with a Database' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'TestInstance'

            $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
            $mockDatabaseObject.Name = 'TestDatabase'
            $mockDatabaseObject.Parent = $mockServerObject
        }

        It 'Should create a FileGroup successfully' {
            InModuleScope -Parameters @{
                mockDatabaseObject = $mockDatabaseObject
            } -ScriptBlock {
                param ($mockDatabaseObject)

                $result = New-SqlDscFileGroup -Database $mockDatabaseObject -Name 'MyFileGroup' -Confirm:$false

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.FileGroup'
                $result.Name | Should -Be 'MyFileGroup'
                $result.Parent | Should -Be $mockDatabaseObject
            }
        }

        It 'Should create a PRIMARY FileGroup successfully' {
            InModuleScope -Parameters @{
                mockDatabaseObject = $mockDatabaseObject
            } -ScriptBlock {
                param ($mockDatabaseObject)

                $result = New-SqlDscFileGroup -Database $mockDatabaseObject -Name 'PRIMARY' -Confirm:$false

                $result | Should -Not -BeNullOrEmpty
                $result.Name | Should -Be 'PRIMARY'
                $result.Parent | Should -Be $mockDatabaseObject
            }
        }

        It 'Should not accept Database parameter from pipeline (removed to prevent file path reuse)' {
            # Verify that the parameter doesn't have ValueFromPipeline attribute
            $parameterInfo = (Get-Command -Name 'New-SqlDscFileGroup').Parameters['Database']
            $parameterInfo.Attributes.ValueFromPipeline | Should -Not -Contain $true
        }

        It 'Should support Force parameter to bypass confirmation' {
            InModuleScope -Parameters @{
                mockDatabaseObject = $mockDatabaseObject
            } -ScriptBlock {
                param ($mockDatabaseObject)

                $result = New-SqlDscFileGroup -Database $mockDatabaseObject -Name 'ForcedFileGroup' -Force

                $result | Should -Not -BeNullOrEmpty
                $result.Name | Should -Be 'ForcedFileGroup'
                $result.Parent | Should -Be $mockDatabaseObject
            }
        }

        It 'Should throw terminating error when Database object has no Parent property set' {
            InModuleScope -ScriptBlock {
                $mockDatabaseWithoutParent = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
                $mockDatabaseWithoutParent.Name = 'TestDatabaseNoParent'

                { New-SqlDscFileGroup -Database $mockDatabaseWithoutParent -Name 'InvalidFileGroup' -Confirm:$false } |
                    Should -Throw -ExpectedMessage '*must have a Server object attached to the Parent property*' -ErrorId 'NSDFG0003,New-SqlDscFileGroup'
            }
        }

        It 'Should return null when WhatIf is specified' {
            InModuleScope -Parameters @{
                mockDatabaseObject = $mockDatabaseObject
            } -ScriptBlock {
                param ($mockDatabaseObject)

                $result = New-SqlDscFileGroup -Database $mockDatabaseObject -Name 'WhatIfFileGroup' -WhatIf

                $result | Should -BeNullOrEmpty
            }
        }
    }

    Context 'When creating a standalone FileGroup' {
        It 'Should create a standalone FileGroup without a Database' {
            InModuleScope -ScriptBlock {
                $result = New-SqlDscFileGroup -Name 'StandaloneFileGroup'

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.FileGroup'
                $result.Name | Should -Be 'StandaloneFileGroup'
                $result.Parent | Should -BeNullOrEmpty
            }
        }

        It 'Should create a standalone PRIMARY FileGroup' {
            InModuleScope -ScriptBlock {
                $result = New-SqlDscFileGroup -Name 'PRIMARY'

                $result | Should -Not -BeNullOrEmpty
                $result.Name | Should -Be 'PRIMARY'
                $result.Parent | Should -BeNullOrEmpty
            }
        }
    }

    Context 'Parameter validation' {
        It 'Should have Database as a mandatory parameter in WithDatabase parameter set' {
            $parameterInfo = (Get-Command -Name 'New-SqlDscFileGroup').Parameters['Database']
            $parameterSetInfo = $parameterInfo.ParameterSets['WithDatabase']
            $parameterSetInfo.IsMandatory | Should -BeTrue
        }

        It 'Should have Database parameter not be in Standalone parameter set' {
            $parameterInfo = (Get-Command -Name 'New-SqlDscFileGroup').Parameters['Database']
            $parameterInfo.ParameterSets.Keys | Should -Not -Contain 'Standalone'
        }

        It 'Should have Name as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'New-SqlDscFileGroup').Parameters['Name']
            $parameterInfo.Attributes.Mandatory | Should -Contain $true
        }

        It 'Should not have Database parameter accept pipeline input' {
            $parameterInfo = (Get-Command -Name 'New-SqlDscFileGroup').Parameters['Database']
            $parameterInfo.Attributes.ValueFromPipeline | Should -Not -Contain $true
        }

        It 'Should have three parameter sets (WithDatabase, WithDatabaseFromSpec, AsSpec)' {
            $command = Get-Command -Name 'New-SqlDscFileGroup'
            $command.ParameterSets.Count | Should -Be 3
            $command.ParameterSets.Name | Should -Contain 'WithDatabase'
            $command.ParameterSets.Name | Should -Contain 'WithDatabaseFromSpec'
            $command.ParameterSets.Name | Should -Contain 'AsSpec'
        }

        It 'Should have AsSpec as the default parameter set' {
            $command = Get-Command -Name 'New-SqlDscFileGroup'
            $command.DefaultParameterSet | Should -Be 'AsSpec'
        }

        It 'Should support ShouldProcess' {
            $command = Get-Command -Name 'New-SqlDscFileGroup'
            $command.Parameters.ContainsKey('WhatIf') | Should -BeTrue
            $command.Parameters.ContainsKey('Confirm') | Should -BeTrue
        }

        It 'Should have Force parameter only in WithDatabase parameter set' {
            $parameterInfo = (Get-Command -Name 'New-SqlDscFileGroup').Parameters['Force']
            $parameterInfo | Should -Not -BeNullOrEmpty
            $parameterInfo.ParameterSets.Keys | Should -Contain 'WithDatabase'
            $parameterInfo.ParameterSets.Keys | Should -Not -Contain 'Standalone'
        }

        It 'Should have ConfirmImpact set to High' {
            $command = Get-Command -Name 'New-SqlDscFileGroup'
            $command.ScriptBlock.Attributes | Where-Object { $_.TypeId.Name -eq 'CmdletBindingAttribute' } |
                ForEach-Object { $_.ConfirmImpact } | Should -Be 'High'
        }
    }
}
