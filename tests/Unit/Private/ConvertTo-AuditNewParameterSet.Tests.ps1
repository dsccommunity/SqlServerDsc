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
                & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
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
    Add-Type -Path (Join-Path -Path $PSScriptRoot -ChildPath '../Stubs/SMO.cs')

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

Describe 'ConvertTo-AuditNewParameterSet' -Tag 'Private' {
    Context 'When converting a File audit with basic properties' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                $script:mockServerObject.InstanceName = 'MSSQLSERVER'

                $script:mockAuditObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Audit' -ArgumentList @($script:mockServerObject, 'TestAudit')
                $script:mockAuditObject.DestinationType = 'File'
                $script:mockAuditObject.FilePath = 'C:\Temp'
                $script:mockAuditObject.OnFailure = 'Continue'
                $script:mockAuditObject.QueueDelay = 1000
            }
        }

        It 'Should return correct parameters for basic file audit' {
            InModuleScope -ScriptBlock {
                $result = ConvertTo-AuditNewParameterSet -AuditObject $script:mockAuditObject

                $result | Should -BeOfType [System.Collections.Hashtable]
                $result['ServerObject'] | Should -Be $script:mockServerObject
                $result['Name'] | Should -Be 'TestAudit'
                $result['Path'] | Should -Be 'C:\Temp'
                $result['OnFailure'] | Should -Be 'Continue'
                $result['QueueDelay'] | Should -Be 1000
                $result['Force'] | Should -BeTrue
                $result['Confirm'] | Should -BeFalse
            }
        }
    }

    Context 'When converting a File audit with file size limits' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                $script:mockAuditObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Audit' -ArgumentList @($script:mockServerObject, 'TestAudit')
                $script:mockAuditObject.DestinationType = 'File'
                $script:mockAuditObject.FilePath = 'C:\Temp'
                $script:mockAuditObject.MaximumFileSize = 100
                $script:mockAuditObject.MaximumFileSizeUnit = 'MB'
            }
        }

        It 'Should return correct parameters including file size' {
            InModuleScope -ScriptBlock {
                $result = ConvertTo-AuditNewParameterSet -AuditObject $script:mockAuditObject

                $result['MaximumFileSize'] | Should -Be 100
                $result['MaximumFileSizeUnit'] | Should -Be 'Megabyte'
            }
        }
    }

    Context 'When converting a File audit with MaximumFiles' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                $script:mockAuditObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Audit' -ArgumentList @($script:mockServerObject, 'TestAudit')
                $script:mockAuditObject.DestinationType = 'File'
                $script:mockAuditObject.FilePath = 'C:\Temp'
                $script:mockAuditObject.MaximumFiles = 10
                $script:mockAuditObject.ReserveDiskSpace = $true
            }
        }

        It 'Should return correct parameters including MaximumFiles and ReserveDiskSpace' {
            InModuleScope -ScriptBlock {
                $result = ConvertTo-AuditNewParameterSet -AuditObject $script:mockAuditObject

                $result['MaximumFiles'] | Should -Be 10
                $result['ReserveDiskSpace'] | Should -BeTrue
                $result.ContainsKey('MaximumRolloverFiles') | Should -BeFalse
            }
        }
    }

    Context 'When converting a File audit with MaximumRolloverFiles' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                $script:mockAuditObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Audit' -ArgumentList @($script:mockServerObject, 'TestAudit')
                $script:mockAuditObject.DestinationType = 'File'
                $script:mockAuditObject.FilePath = 'C:\Temp'
                $script:mockAuditObject.MaximumRolloverFiles = 5
            }
        }

        It 'Should return correct parameters including MaximumRolloverFiles' {
            InModuleScope -ScriptBlock {
                $result = ConvertTo-AuditNewParameterSet -AuditObject $script:mockAuditObject

                $result['MaximumRolloverFiles'] | Should -Be 5
                $result.ContainsKey('MaximumFiles') | Should -BeFalse
                $result.ContainsKey('ReserveDiskSpace') | Should -BeFalse
            }
        }
    }

    Context 'When converting an ApplicationLog audit' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                $script:mockAuditObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Audit' -ArgumentList @($script:mockServerObject, 'TestAudit')
                $script:mockAuditObject.DestinationType = 'ApplicationLog'
            }
        }

        It 'Should return correct parameters for ApplicationLog' {
            InModuleScope -ScriptBlock {
                $result = ConvertTo-AuditNewParameterSet -AuditObject $script:mockAuditObject

                $result['LogType'] | Should -Be 'ApplicationLog'
                $result.ContainsKey('Path') | Should -BeFalse
            }
        }
    }

    Context 'When converting a SecurityLog audit' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                $script:mockAuditObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Audit' -ArgumentList @($script:mockServerObject, 'TestAudit')
                $script:mockAuditObject.DestinationType = 'SecurityLog'
            }
        }

        It 'Should return correct parameters for SecurityLog' {
            InModuleScope -ScriptBlock {
                $result = ConvertTo-AuditNewParameterSet -AuditObject $script:mockAuditObject

                $result['LogType'] | Should -Be 'SecurityLog'
                $result.ContainsKey('Path') | Should -BeFalse
            }
        }
    }

    Context 'When converting an audit with AuditFilter' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                $script:mockAuditObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Audit' -ArgumentList @($script:mockServerObject, 'TestAudit')
                $script:mockAuditObject.DestinationType = 'File'
                $script:mockAuditObject.FilePath = 'C:\Temp'
                $script:mockAuditObject.Filter = 'database_name = ''master'''
            }
        }

        It 'Should return correct parameters including AuditFilter' {
            InModuleScope -ScriptBlock {
                $result = ConvertTo-AuditNewParameterSet -AuditObject $script:mockAuditObject

                $result['AuditFilter'] | Should -Be 'database_name = ''master'''
            }
        }
    }

    Context 'When providing a new AuditGuid parameter' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                $script:mockAuditObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Audit' -ArgumentList @($script:mockServerObject, 'TestAudit')
                $script:mockAuditObject.DestinationType = 'File'
                $script:mockAuditObject.FilePath = 'C:\Temp'
                $script:mockAuditObject.Guid = '12345678-1234-1234-1234-123456789012'
            }
        }

        It 'Should use the provided GUID instead of the existing one' {
            InModuleScope -ScriptBlock {
                $newGuid = '87654321-4321-4321-4321-210987654321'
                $result = ConvertTo-AuditNewParameterSet -AuditObject $script:mockAuditObject -AuditGuid $newGuid

                $result['AuditGuid'] | Should -Be $newGuid
            }
        }
    }

    Context 'When audit has existing GUID' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                $script:mockAuditObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Audit' -ArgumentList @($script:mockServerObject, 'TestAudit')
                $script:mockAuditObject.DestinationType = 'File'
                $script:mockAuditObject.FilePath = 'C:\Temp'
                $script:mockAuditObject.Guid = '12345678-1234-1234-1234-123456789012'
            }
        }

        It 'Should include the existing GUID' {
            InModuleScope -ScriptBlock {
                $result = ConvertTo-AuditNewParameterSet -AuditObject $script:mockAuditObject

                $result['AuditGuid'] | Should -Be '12345678-1234-1234-1234-123456789012'
            }
        }
    }
}
