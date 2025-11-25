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
            $result = New-SqlDscFileGroup -Database $mockDatabaseObject -Name 'MyFileGroup' -Confirm:$false

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.FileGroup'
            $result.Name | Should -Be 'MyFileGroup'
            $result.Parent | Should -Be $mockDatabaseObject
        }

        It 'Should create a PRIMARY FileGroup successfully' {
            $result = New-SqlDscFileGroup -Database $mockDatabaseObject -Name 'PRIMARY' -Confirm:$false

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'PRIMARY'
            $result.Parent | Should -Be $mockDatabaseObject
        }

        It 'Should support Force parameter to bypass confirmation' {
            $result = New-SqlDscFileGroup -Database $mockDatabaseObject -Name 'ForcedFileGroup' -Force

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'ForcedFileGroup'
            $result.Parent | Should -Be $mockDatabaseObject
        }

        It 'Should throw terminating error when Database object has no Parent property set' {
            $mockDatabaseWithoutParent = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
            $mockDatabaseWithoutParent.Name = 'TestDatabaseNoParent'

            { New-SqlDscFileGroup -Database $mockDatabaseWithoutParent -Name 'InvalidFileGroup' -Confirm:$false } |
                Should -Throw -ExpectedMessage '*must have a Server object attached to the Parent property*' -ErrorId 'NSDFG0003,New-SqlDscFileGroup'
        }

        It 'Should return null when WhatIf is specified' {
            $result = New-SqlDscFileGroup -Database $mockDatabaseObject -Name 'WhatIfFileGroup' -WhatIf

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'When creating a standalone FileGroup' {
        It 'Should create a standalone FileGroup without a Database' {
            $result = New-SqlDscFileGroup -Name 'StandaloneFileGroup'

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.FileGroup'
            $result.Name | Should -Be 'StandaloneFileGroup'
            $result.Parent | Should -BeNullOrEmpty
        }

        It 'Should create a standalone PRIMARY FileGroup' {
            $result = New-SqlDscFileGroup -Name 'PRIMARY'

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'PRIMARY'
            $result.Parent | Should -BeNullOrEmpty
        }
    }

    Context 'When creating a FileGroup specification using AsSpec' {
        It 'Should create a DatabaseFileGroupSpec object' {
            InModuleScope -ScriptBlock {
                $result = New-SqlDscFileGroup -Name 'MyFileGroup' -AsSpec

                $result | Should -Not -BeNullOrEmpty
                $result.GetType().Name | Should -Be 'DatabaseFileGroupSpec'
                $result.Name | Should -Be 'MyFileGroup'
                $result.Files | Should -BeNullOrEmpty
                $result.ReadOnly | Should -BeFalse
                $result.IsDefault | Should -BeFalse
            }
        }

        It 'Should create a DatabaseFileGroupSpec with ReadOnly property set' {
            InModuleScope -ScriptBlock {
                $result = New-SqlDscFileGroup -Name 'ReadOnlyFileGroup' -AsSpec -ReadOnly

                $result | Should -Not -BeNullOrEmpty
                $result.GetType().Name | Should -Be 'DatabaseFileGroupSpec'
                $result.Name | Should -Be 'ReadOnlyFileGroup'
                $result.ReadOnly | Should -BeTrue
                $result.IsDefault | Should -BeFalse
            }
        }

        It 'Should create a DatabaseFileGroupSpec with IsDefault property set' {
            InModuleScope -ScriptBlock {
                $result = New-SqlDscFileGroup -Name 'PRIMARY' -AsSpec -IsDefault

                $result | Should -Not -BeNullOrEmpty
                $result.GetType().Name | Should -Be 'DatabaseFileGroupSpec'
                $result.Name | Should -Be 'PRIMARY'
                $result.IsDefault | Should -BeTrue
                $result.ReadOnly | Should -BeFalse
            }
        }

        It 'Should create a DatabaseFileGroupSpec with Files property set' {
            InModuleScope -ScriptBlock {
                # Create mock DatabaseFileSpec objects
                $mockFileSpec1 = [DatabaseFileSpec]::new()
                $mockFileSpec1.Name = 'TestFile1'
                $mockFileSpec1.FileName = 'C:\SQLData\TestFile1.ndf'

                $mockFileSpec2 = [DatabaseFileSpec]::new()
                $mockFileSpec2.Name = 'TestFile2'
                $mockFileSpec2.FileName = 'C:\SQLData\TestFile2.ndf'

                $result = New-SqlDscFileGroup -Name 'DataFileGroup' -AsSpec -Files @($mockFileSpec1, $mockFileSpec2)

                $result | Should -Not -BeNullOrEmpty
                $result.GetType().Name | Should -Be 'DatabaseFileGroupSpec'
                $result.Name | Should -Be 'DataFileGroup'
                $result.Files | Should -HaveCount 2
                $result.Files[0].Name | Should -Be 'TestFile1'
                $result.Files[1].Name | Should -Be 'TestFile2'
            }
        }

        It 'Should create a DatabaseFileGroupSpec with all properties set' {
            InModuleScope -ScriptBlock {
                $mockFileSpec = [DatabaseFileSpec]::new()
                $mockFileSpec.Name = 'PrimaryFile'
                $mockFileSpec.FileName = 'C:\SQLData\PrimaryFile.mdf'

                $result = New-SqlDscFileGroup -Name 'PRIMARY' -AsSpec -Files @($mockFileSpec) -IsDefault -ReadOnly

                $result | Should -Not -BeNullOrEmpty
                $result.GetType().Name | Should -Be 'DatabaseFileGroupSpec'
                $result.Name | Should -Be 'PRIMARY'
                $result.Files | Should -HaveCount 1
                $result.IsDefault | Should -BeTrue
                $result.ReadOnly | Should -BeTrue
            }
        }
    }

    Context 'When creating a FileGroup from a FileGroupSpec with Database' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'TestInstance'

            $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
            $mockDatabaseObject.Name = 'TestDatabase'
            $mockDatabaseObject.Parent = $mockServerObject

            # Mock ConvertTo-SqlDscFileGroup
            Mock -CommandName ConvertTo-SqlDscFileGroup -MockWith {
                $fileGroup = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.FileGroup' -ArgumentList $DatabaseObject, $FileGroupSpec.Name
                $fileGroup.ReadOnly = $FileGroupSpec.ReadOnly
                $fileGroup.IsDefault = $FileGroupSpec.IsDefault
                return $fileGroup
            }
        }

        It 'Should create a FileGroup from a FileGroupSpec object' {
            $mockFileGroupSpec = InModuleScope -ScriptBlock {
                $spec = [DatabaseFileGroupSpec]::new()
                $spec.Name = 'SpecFileGroup'
                $spec.ReadOnly = $false
                $spec.IsDefault = $false
                return $spec
            }

            $result = New-SqlDscFileGroup -Database $mockDatabaseObject -FileGroupSpec $mockFileGroupSpec -Confirm:$false

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.FileGroup'
            $result.Name | Should -Be 'SpecFileGroup'
            $result.Parent | Should -Be $mockDatabaseObject

            Should -Invoke -CommandName ConvertTo-SqlDscFileGroup -ParameterFilter {
                $DatabaseObject -eq $mockDatabaseObject -and $FileGroupSpec.Name -eq 'SpecFileGroup'
            } -Exactly -Times 1 -Scope It
        }

        It 'Should create a FileGroup from a FileGroupSpec with properties set' {
            $mockFileGroupSpec = InModuleScope -ScriptBlock {
                $spec = [DatabaseFileGroupSpec]::new()
                $spec.Name = 'ReadOnlySpec'
                $spec.ReadOnly = $true
                $spec.IsDefault = $false
                return $spec
            }

            $result = New-SqlDscFileGroup -Database $mockDatabaseObject -FileGroupSpec $mockFileGroupSpec -Force

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.FileGroup'
            $result.Name | Should -Be 'ReadOnlySpec'
            $result.ReadOnly | Should -BeTrue

            Should -Invoke -CommandName ConvertTo-SqlDscFileGroup -ParameterFilter {
                $DatabaseObject -eq $mockDatabaseObject -and $FileGroupSpec.ReadOnly -eq $true
            } -Exactly -Times 1 -Scope It
        }

        It 'Should throw terminating error when Database object has no Parent property set' {
            $mockDatabaseWithoutParent = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
            $mockDatabaseWithoutParent.Name = 'TestDatabaseNoParent'

            $mockFileGroupSpec = InModuleScope -ScriptBlock {
                $spec = [DatabaseFileGroupSpec]::new()
                $spec.Name = 'FailFileGroup'
                return $spec
            }

            { New-SqlDscFileGroup -Database $mockDatabaseWithoutParent -FileGroupSpec $mockFileGroupSpec -Confirm:$false } |
                Should -Throw -ExpectedMessage '*must have a Server object attached to the Parent property*' -ErrorId 'NSDFG0003,New-SqlDscFileGroup'
        }

        It 'Should return null when WhatIf is specified' {
            $mockFileGroupSpec = InModuleScope -ScriptBlock {
                $spec = [DatabaseFileGroupSpec]::new()
                $spec.Name = 'WhatIfSpec'
                return $spec
            }

            $result = New-SqlDscFileGroup -Database $mockDatabaseObject -FileGroupSpec $mockFileGroupSpec -WhatIf

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Parameter validation' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = 'WithDatabase'
                ExpectedParameters = '-Database <Database> -Name <string> [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
            @{
                ExpectedParameterSetName = 'WithDatabaseFromSpec'
                ExpectedParameters = '-Database <Database> -FileGroupSpec <DatabaseFileGroupSpec> [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
            @{
                ExpectedParameterSetName = 'AsSpec'
                ExpectedParameters = '-Name <string> -AsSpec [-Files <DatabaseFileSpec[]>] [-ReadOnly] [-IsDefault] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
            @{
                ExpectedParameterSetName = 'Standalone'
                ExpectedParameters = '-Name <string> [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'New-SqlDscFileGroup').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }

        It 'Should have Database as a mandatory parameter in WithDatabase parameter set' {
            $parameterInfo = (Get-Command -Name 'New-SqlDscFileGroup').Parameters['Database']
            $parameterSetInfo = $parameterInfo.ParameterSets['WithDatabase']
            $parameterSetInfo.IsMandatory | Should -BeTrue
        }

        It 'Should have Database as a mandatory parameter in WithDatabaseFromSpec parameter set' {
            $parameterInfo = (Get-Command -Name 'New-SqlDscFileGroup').Parameters['Database']
            $parameterSetInfo = $parameterInfo.ParameterSets['WithDatabaseFromSpec']
            $parameterSetInfo.IsMandatory | Should -BeTrue
        }

        It 'Should have Database parameter not be in Standalone parameter set' {
            $parameterInfo = (Get-Command -Name 'New-SqlDscFileGroup').Parameters['Database']
            $parameterInfo.ParameterSets.Keys | Should -Not -Contain 'Standalone'
        }

        It 'Should have Database parameter not be in AsSpec parameter set' {
            $parameterInfo = (Get-Command -Name 'New-SqlDscFileGroup').Parameters['Database']
            $parameterInfo.ParameterSets.Keys | Should -Not -Contain 'AsSpec'
        }

        It 'Should have Name as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'New-SqlDscFileGroup').Parameters['Name']
            $parameterInfo.Attributes.Mandatory | Should -Contain $true
        }

        It 'Should have Name parameter in WithDatabase parameter set' {
            $parameterInfo = (Get-Command -Name 'New-SqlDscFileGroup').Parameters['Name']
            $parameterInfo.ParameterSets.Keys | Should -Contain 'WithDatabase'
        }

        It 'Should have Name parameter in Standalone parameter set' {
            $parameterInfo = (Get-Command -Name 'New-SqlDscFileGroup').Parameters['Name']
            $parameterInfo.ParameterSets.Keys | Should -Contain 'Standalone'
        }

        It 'Should have Name parameter in AsSpec parameter set' {
            $parameterInfo = (Get-Command -Name 'New-SqlDscFileGroup').Parameters['Name']
            $parameterInfo.ParameterSets.Keys | Should -Contain 'AsSpec'
        }

        It 'Should have Name parameter not be in WithDatabaseFromSpec parameter set' {
            $parameterInfo = (Get-Command -Name 'New-SqlDscFileGroup').Parameters['Name']
            $parameterInfo.ParameterSets.Keys | Should -Not -Contain 'WithDatabaseFromSpec'
        }

        It 'Should have FileGroupSpec as a mandatory parameter in WithDatabaseFromSpec parameter set' {
            $parameterInfo = (Get-Command -Name 'New-SqlDscFileGroup').Parameters['FileGroupSpec']
            $parameterSetInfo = $parameterInfo.ParameterSets['WithDatabaseFromSpec']
            $parameterSetInfo.IsMandatory | Should -BeTrue
        }

        It 'Should have AsSpec as a mandatory parameter in AsSpec parameter set' {
            $parameterInfo = (Get-Command -Name 'New-SqlDscFileGroup').Parameters['AsSpec']
            $parameterSetInfo = $parameterInfo.ParameterSets['AsSpec']
            $parameterSetInfo.IsMandatory | Should -BeTrue
        }

        It 'Should have Files parameter only in AsSpec parameter set' {
            $parameterInfo = (Get-Command -Name 'New-SqlDscFileGroup').Parameters['Files']
            $parameterInfo.ParameterSets.Keys | Should -Contain 'AsSpec'
            $parameterInfo.ParameterSets.Keys | Should -HaveCount 1
        }

        It 'Should have ReadOnly parameter only in AsSpec parameter set' {
            $parameterInfo = (Get-Command -Name 'New-SqlDscFileGroup').Parameters['ReadOnly']
            $parameterInfo.ParameterSets.Keys | Should -Contain 'AsSpec'
            $parameterInfo.ParameterSets.Keys | Should -HaveCount 1
        }

        It 'Should have IsDefault parameter only in AsSpec parameter set' {
            $parameterInfo = (Get-Command -Name 'New-SqlDscFileGroup').Parameters['IsDefault']
            $parameterInfo.ParameterSets.Keys | Should -Contain 'AsSpec'
            $parameterInfo.ParameterSets.Keys | Should -HaveCount 1
        }

        It 'Should have four parameter sets (WithDatabase, WithDatabaseFromSpec, AsSpec, Standalone)' {
            $command = Get-Command -Name 'New-SqlDscFileGroup'
            $command.ParameterSets.Count | Should -Be 4
            $command.ParameterSets.Name | Should -Contain 'WithDatabase'
            $command.ParameterSets.Name | Should -Contain 'WithDatabaseFromSpec'
            $command.ParameterSets.Name | Should -Contain 'AsSpec'
            $command.ParameterSets.Name | Should -Contain 'Standalone'
        }

        It 'Should have Standalone as the default parameter set' {
            $command = Get-Command -Name 'New-SqlDscFileGroup'
            $command.DefaultParameterSet | Should -Be 'Standalone'
        }

        It 'Should support ShouldProcess' {
            $command = Get-Command -Name 'New-SqlDscFileGroup'
            $command.Parameters.ContainsKey('WhatIf') | Should -BeTrue
            $command.Parameters.ContainsKey('Confirm') | Should -BeTrue
        }

        It 'Should have Force parameter only in WithDatabase and WithDatabaseFromSpec parameter sets' {
            $parameterInfo = (Get-Command -Name 'New-SqlDscFileGroup').Parameters['Force']
            $parameterInfo | Should -Not -BeNullOrEmpty
            $parameterInfo.ParameterSets.Keys | Should -Contain 'WithDatabase'
            $parameterInfo.ParameterSets.Keys | Should -Contain 'WithDatabaseFromSpec'
            $parameterInfo.ParameterSets.Keys | Should -HaveCount 2
        }

        It 'Should have ConfirmImpact set to High' {
            $command = Get-Command -Name 'New-SqlDscFileGroup'
            $command.ScriptBlock.Attributes | Where-Object { $_.TypeId.Name -eq 'CmdletBindingAttribute' } |
                ForEach-Object { $_.ConfirmImpact } | Should -Be 'High'
        }
    }
}
