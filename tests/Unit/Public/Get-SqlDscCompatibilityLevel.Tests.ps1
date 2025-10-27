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

Describe 'Get-SqlDscCompatibilityLevel' -Tag 'Public' {
    Context 'When getting compatibility levels for a server object' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'MSSQLSERVER'
        }

        Context 'When SQL Server version is 16 (SQL Server 2022)' {
            BeforeAll {
                $mockServerObject.VersionMajor = 16
            }

            It 'Should return all supported compatibility levels from 100 to 160' {
                $result = Get-SqlDscCompatibilityLevel -ServerObject $mockServerObject

                $result | Should -Contain 'Version100'
                $result | Should -Contain 'Version110'
                $result | Should -Contain 'Version120'
                $result | Should -Contain 'Version130'
                $result | Should -Contain 'Version140'
                $result | Should -Contain 'Version150'
                $result | Should -Contain 'Version160'
                $result | Should -Not -Contain 'Version90'
                $result | Should -Not -Contain 'Version80'
            }
        }

        Context 'When SQL Server version is 15 (SQL Server 2019)' {
            BeforeAll {
                $mockServerObject.VersionMajor = 15
            }

            It 'Should return all supported compatibility levels from 100 to 150' {
                $result = Get-SqlDscCompatibilityLevel -ServerObject $mockServerObject

                $result | Should -Contain 'Version100'
                $result | Should -Contain 'Version110'
                $result | Should -Contain 'Version120'
                $result | Should -Contain 'Version130'
                $result | Should -Contain 'Version140'
                $result | Should -Contain 'Version150'
                $result | Should -Not -Contain 'Version160'
                $result | Should -Not -Contain 'Version90'
            }
        }

        Context 'When SQL Server version is 11 (SQL Server 2012)' {
            BeforeAll {
                $mockServerObject.VersionMajor = 11
            }

            It 'Should return all supported compatibility levels from 90 to 110' {
                $result = Get-SqlDscCompatibilityLevel -ServerObject $mockServerObject

                $result | Should -Contain 'Version90'
                $result | Should -Contain 'Version100'
                $result | Should -Contain 'Version110'
                $result | Should -Not -Contain 'Version120'
                $result | Should -Not -Contain 'Version80'
            }
        }

        Context 'When SQL Server version is 10 (SQL Server 2008/2008 R2)' {
            BeforeAll {
                $mockServerObject.VersionMajor = 10
            }

            It 'Should return all supported compatibility levels from 80 to 100' {
                $result = Get-SqlDscCompatibilityLevel -ServerObject $mockServerObject

                $result | Should -Contain 'Version80'
                $result | Should -Contain 'Version90'
                $result | Should -Contain 'Version100'
                $result | Should -Not -Contain 'Version110'
            }
        }

        Context 'When SQL Server version is newer than SMO library supports' {
            BeforeAll {
                # Assuming SMO library supports up to Version170
                $mockServerObject.VersionMajor = 18
            }

            It 'Should return available compatibility levels and output a warning' {
                # Suppress warning output for cleaner test results
                $result = Get-SqlDscCompatibilityLevel -ServerObject $mockServerObject 3>&1

                # Should contain warnings
                $warnings = $result | Where-Object -FilterScript { $_ -is [System.Management.Automation.WarningRecord] }
                $warnings | Should -Not -BeNullOrEmpty
                $warnings[0].Message | Should -Match 'SMO library does not support SQL Server major version 18'

                # Should still return compatibility levels up to what SMO knows
                $compatLevels = $result | Where-Object -FilterScript { $_ -is [System.String] }
                $compatLevels | Should -Contain 'Version100'
            }
        }
    }

    Context 'When getting compatibility levels using Version parameter' {
        Context 'When version is 16.0.1000.6 (SQL Server 2022)' {
            It 'Should return all supported compatibility levels from 100 to 160' {
                $result = Get-SqlDscCompatibilityLevel -Version '16.0.1000.6'

                $result | Should -Contain 'Version100'
                $result | Should -Contain 'Version110'
                $result | Should -Contain 'Version120'
                $result | Should -Contain 'Version130'
                $result | Should -Contain 'Version140'
                $result | Should -Contain 'Version150'
                $result | Should -Contain 'Version160'
                $result | Should -Not -Contain 'Version90'
            }
        }

        Context 'When version is 15.0.2000.5 (SQL Server 2019)' {
            It 'Should return all supported compatibility levels from 100 to 150' {
                $result = Get-SqlDscCompatibilityLevel -Version '15.0.2000.5'

                $result | Should -Contain 'Version100'
                $result | Should -Contain 'Version150'
                $result | Should -Not -Contain 'Version160'
            }
        }

        Context 'When version is 11.0.2100.60 (SQL Server 2012)' {
            It 'Should return all supported compatibility levels from 90 to 110' {
                $result = Get-SqlDscCompatibilityLevel -Version '11.0.2100.60'

                $result | Should -Contain 'Version90'
                $result | Should -Contain 'Version100'
                $result | Should -Contain 'Version110'
                $result | Should -Not -Contain 'Version120'
                $result | Should -Not -Contain 'Version80'
            }
        }

        Context 'When version is 10.50.1600.1 (SQL Server 2008 R2)' {
            It 'Should return all supported compatibility levels from 80 to 100' {
                $result = Get-SqlDscCompatibilityLevel -Version '10.50.1600.1'

                $result | Should -Contain 'Version80'
                $result | Should -Contain 'Version90'
                $result | Should -Contain 'Version100'
                $result | Should -Not -Contain 'Version110'
            }
        }
    }

    Context 'When using pipeline input' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'MSSQLSERVER'
            $mockServerObject.VersionMajor = 16
        }

        It 'Should accept ServerObject from pipeline' {
            $result = $mockServerObject | Get-SqlDscCompatibilityLevel

            $result | Should -Contain 'Version160'
            $result | Should -Contain 'Version100'
        }
    }
}
