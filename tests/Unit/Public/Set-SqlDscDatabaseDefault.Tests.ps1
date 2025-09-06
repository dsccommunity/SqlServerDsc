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

Describe 'Set-SqlDscDatabaseDefault' -Tag 'Public' {
    Context 'When command is called' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = 'ServerObject'
                ExpectedParameters = '-ServerObject <Server> -Name <string> [-DefaultFileGroup <string>] [-DefaultFileStreamFileGroup <string>] [-DefaultFullTextCatalog <string>] [-Force] [-Refresh] [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
            @{
                ExpectedParameterSetName = 'DatabaseObject'
                ExpectedParameters = '-DatabaseObject <Database> [-DefaultFileGroup <string>] [-DefaultFileStreamFileGroup <string>] [-DefaultFullTextCatalog <string>] [-Force] [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Set-SqlDscDatabaseDefault').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }

        It 'Should have Name as a mandatory parameter in ServerObject parameter set' {
            $parameterInfo = (Get-Command -Name 'Set-SqlDscDatabaseDefault').Parameters['Name']
            $parameterInfo.Attributes.Where({ $_.TypeId -eq [System.Management.Automation.ParameterAttribute] -and $_.ParameterSetName -eq 'ServerObject' }).Mandatory | Should -BeTrue
        }

        It 'Should have ServerObject as a mandatory parameter in ServerObject parameter set' {
            $parameterInfo = (Get-Command -Name 'Set-SqlDscDatabaseDefault').Parameters['ServerObject']
            $parameterInfo.Attributes.Where({ $_.TypeId -eq [System.Management.Automation.ParameterAttribute] -and $_.ParameterSetName -eq 'ServerObject' }).Mandatory | Should -BeTrue
        }

        It 'Should have DatabaseObject as a mandatory parameter in DatabaseObject parameter set' {
            $parameterInfo = (Get-Command -Name 'Set-SqlDscDatabaseDefault').Parameters['DatabaseObject']
            $parameterInfo.Attributes.Where({ $_.TypeId -eq [System.Management.Automation.ParameterAttribute] -and $_.ParameterSetName -eq 'DatabaseObject' }).Mandatory | Should -BeTrue
        }

        It 'Should support ShouldProcess' {
            $commandInfo = Get-Command -Name 'Set-SqlDscDatabaseDefault'
            $commandInfo.Parameters['WhatIf'] | Should -Not -BeNullOrEmpty
            $commandInfo.Parameters['Confirm'] | Should -Not -BeNullOrEmpty
        }
    }

    Context 'When using parameter set ServerObject' {
        Context 'When database exists' {
            It 'Should set default filegroup when DefaultFileGroup parameter is specified' {
                InModuleScope -ScriptBlock {
                    $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
                    $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestDatabase' -Force
                    $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'DefaultFileGroup' -Value 'PRIMARY' -Force
                    $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'SetDefaultFileGroup' -Value {
                        param($fileGroupName)
                        $this.DefaultFileGroup = $fileGroupName
                    } -Force

                    $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                    $mockServerObject | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
                    $mockServerObject | Add-Member -MemberType 'ScriptProperty' -Name 'Databases' -Value {
                        return @{
                            'TestDatabase' = $mockDatabaseObject
                        }
                    } -Force

                    $null = Set-SqlDscDatabaseDefault -ServerObject $mockServerObject -Name 'TestDatabase' -DefaultFileGroup 'NewFileGroup' -Force
                    $mockDatabaseObject.DefaultFileGroup | Should -Be 'NewFileGroup'
                }
            }

            It 'Should set default FILESTREAM filegroup when DefaultFileStreamFileGroup parameter is specified' {
                InModuleScope -ScriptBlock {
                    $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
                    $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestDatabase' -Force
                    $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'DefaultFileStreamFileGroup' -Value 'FileStreamGroup' -Force
                    $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'SetDefaultFileStreamFileGroup' -Value {
                        param($fileGroupName)
                        $this.DefaultFileStreamFileGroup = $fileGroupName
                    } -Force

                    $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                    $mockServerObject | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
                    $mockServerObject | Add-Member -MemberType 'ScriptProperty' -Name 'Databases' -Value {
                        return @{
                            'TestDatabase' = $mockDatabaseObject
                        }
                    } -Force

                    $null = Set-SqlDscDatabaseDefault -ServerObject $mockServerObject -Name 'TestDatabase' -DefaultFileStreamFileGroup 'NewFileStreamGroup' -Force
                    $mockDatabaseObject.DefaultFileStreamFileGroup | Should -Be 'NewFileStreamGroup'
                }
            }

            It 'Should set default Full-Text catalog when DefaultFullTextCatalog parameter is specified' {
                InModuleScope -ScriptBlock {
                    $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
                    $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestDatabase' -Force
                    $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'DefaultFullTextCatalog' -Value 'FTCatalog' -Force
                    $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'SetDefaultFullTextCatalog' -Value {
                        param($catalogName)
                        $this.DefaultFullTextCatalog = $catalogName
                    } -Force

                    $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                    $mockServerObject | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
                    $mockServerObject | Add-Member -MemberType 'ScriptProperty' -Name 'Databases' -Value {
                        return @{
                            'TestDatabase' = $mockDatabaseObject
                        }
                    } -Force

                    $null = Set-SqlDscDatabaseDefault -ServerObject $mockServerObject -Name 'TestDatabase' -DefaultFullTextCatalog 'NewFTCatalog' -Force
                    $mockDatabaseObject.DefaultFullTextCatalog | Should -Be 'NewFTCatalog'
                }
            }

            It 'Should return database object when PassThru is specified' {
                InModuleScope -ScriptBlock {
                    $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
                    $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestDatabase' -Force
                    $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'DefaultFileGroup' -Value 'PRIMARY' -Force
                    $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'SetDefaultFileGroup' -Value {
                        param($fileGroupName)
                        $this.DefaultFileGroup = $fileGroupName
                    } -Force

                    $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                    $mockServerObject | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
                    $mockServerObject | Add-Member -MemberType 'ScriptProperty' -Name 'Databases' -Value {
                        return @{
                            'TestDatabase' = $mockDatabaseObject
                        }
                    } -Force

                    $result = Set-SqlDscDatabaseDefault -ServerObject $mockServerObject -Name 'TestDatabase' -DefaultFileGroup 'PassThruTest' -PassThru -Force
                    $result | Should -Be $mockDatabaseObject
                    $result.DefaultFileGroup | Should -Be 'PassThruTest'
                }
            }
        }

        Context 'When database does not exist' {
            It 'Should throw an exception when database is not found' {
                InModuleScope -ScriptBlock {
                    $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                    $mockServerObject | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
                    $mockServerObject | Add-Member -MemberType 'ScriptProperty' -Name 'Databases' -Value {
                        return @{} # Empty collection
                    } -Force

                    $mockExpectedErrorMessage = $script:localizedData.Database_NotFound -f 'NonExistentDatabase'

                    { Set-SqlDscDatabaseDefault -ServerObject $mockServerObject -Name 'NonExistentDatabase' -DefaultFileGroup 'TestGroup' -Force } | Should -Throw -ExpectedMessage "*$mockExpectedErrorMessage*"
                }
            }
        }
    }

    Context 'When using parameter set DatabaseObject' {
        It 'Should set default filegroup when DefaultFileGroup parameter is specified' {
            InModuleScope -ScriptBlock {
                $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
                $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestDatabase' -Force
                $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'DefaultFileGroup' -Value 'PRIMARY' -Force
                $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'SetDefaultFileGroup' -Value {
                    param($fileGroupName)
                    $this.DefaultFileGroup = $fileGroupName
                } -Force
                $mockDatabaseObject | Add-Member -MemberType 'ScriptProperty' -Name 'Parent' -Value {
                    $mockParent = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                    $mockParent | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
                    return $mockParent
                } -Force

                $null = Set-SqlDscDatabaseDefault -DatabaseObject $mockDatabaseObject -DefaultFileGroup 'DirectFileGroup' -Force
                $mockDatabaseObject.DefaultFileGroup | Should -Be 'DirectFileGroup'
            }
        }

        It 'Should set default FILESTREAM filegroup when DefaultFileStreamFileGroup parameter is specified' {
            InModuleScope -ScriptBlock {
                $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
                $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestDatabase' -Force
                $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'DefaultFileStreamFileGroup' -Value 'FileStreamGroup' -Force
                $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'SetDefaultFileStreamFileGroup' -Value {
                    param($fileGroupName)
                    $this.DefaultFileStreamFileGroup = $fileGroupName
                } -Force
                $mockDatabaseObject | Add-Member -MemberType 'ScriptProperty' -Name 'Parent' -Value {
                    $mockParent = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                    $mockParent | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
                    return $mockParent
                } -Force

                $null = Set-SqlDscDatabaseDefault -DatabaseObject $mockDatabaseObject -DefaultFileStreamFileGroup 'DirectStreamGroup' -Force
                $mockDatabaseObject.DefaultFileStreamFileGroup | Should -Be 'DirectStreamGroup'
            }
        }

        It 'Should set default Full-Text catalog when DefaultFullTextCatalog parameter is specified' {
            InModuleScope -ScriptBlock {
                $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
                $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestDatabase' -Force
                $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'DefaultFullTextCatalog' -Value 'FTCatalog' -Force
                $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'SetDefaultFullTextCatalog' -Value {
                    param($catalogName)
                    $this.DefaultFullTextCatalog = $catalogName
                } -Force
                $mockDatabaseObject | Add-Member -MemberType 'ScriptProperty' -Name 'Parent' -Value {
                    $mockParent = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                    $mockParent | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
                    return $mockParent
                } -Force

                $null = Set-SqlDscDatabaseDefault -DatabaseObject $mockDatabaseObject -DefaultFullTextCatalog 'DirectFTCatalog' -Force
                $mockDatabaseObject.DefaultFullTextCatalog | Should -Be 'DirectFTCatalog'
            }
        }

        It 'Should return database object when PassThru is specified' {
            InModuleScope -ScriptBlock {
                $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
                $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestDatabase' -Force
                $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'DefaultFileGroup' -Value 'PRIMARY' -Force
                $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'SetDefaultFileGroup' -Value {
                    param($fileGroupName)
                    $this.DefaultFileGroup = $fileGroupName
                } -Force
                $mockDatabaseObject | Add-Member -MemberType 'ScriptProperty' -Name 'Parent' -Value {
                    $mockParent = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                    $mockParent | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
                    return $mockParent
                } -Force

                $result = Set-SqlDscDatabaseDefault -DatabaseObject $mockDatabaseObject -DefaultFileGroup 'PassThruDirect' -PassThru -Force
                $result | Should -Be $mockDatabaseObject
                $result.DefaultFileGroup | Should -Be 'PassThruDirect'
            }
        }
    }

    Context 'When using ShouldProcess' {
        It 'Should not modify database when WhatIf is specified' {
            InModuleScope -ScriptBlock {
                $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
                $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestDatabase' -Force
                $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'DefaultFileGroup' -Value 'PRIMARY' -Force
                $mockDatabaseObject | Add-Member -MemberType 'ScriptMethod' -Name 'SetDefaultFileGroup' -Value {
                    param($fileGroupName)
                    $this.DefaultFileGroup = $fileGroupName
                } -Force

                $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                $mockServerObject | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
                $mockServerObject | Add-Member -MemberType 'ScriptProperty' -Name 'Databases' -Value {
                    return @{
                        'TestDatabase' = $mockDatabaseObject
                    }
                } -Force

                $originalDefaultFileGroup = $mockDatabaseObject.DefaultFileGroup

                Set-SqlDscDatabaseDefault -ServerObject $mockServerObject -Name 'TestDatabase' -DefaultFileGroup 'WhatIfTest' -WhatIf

                $mockDatabaseObject.DefaultFileGroup | Should -Be $originalDefaultFileGroup
            }
        }
    }

    Context 'When no parameters that change defaults are specified' {
        It 'Should not call any SetDefault methods' {
            InModuleScope -ScriptBlock {
                $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
                $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestDatabase' -Force
                $mockDatabaseObject | Add-Member -MemberType 'NoteProperty' -Name 'DefaultFileGroup' -Value 'PRIMARY' -Force

                $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                $mockServerObject | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force
                $mockServerObject | Add-Member -MemberType 'ScriptProperty' -Name 'Databases' -Value {
                    return @{
                        'TestDatabase' = $mockDatabaseObject
                    }
                } -Force

                $originalDefaultFileGroup = $mockDatabaseObject.DefaultFileGroup

                Set-SqlDscDatabaseDefault -ServerObject $mockServerObject -Name 'TestDatabase' -Force

                $mockDatabaseObject.DefaultFileGroup | Should -Be $originalDefaultFileGroup
            }
        }
    }
}
