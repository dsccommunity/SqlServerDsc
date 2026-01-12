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

    Import-Module -Name $script:moduleName -ErrorAction 'Stop'

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

Describe 'Get-SqlDscRSDatabaseInstallation' {
    Context 'When validating parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = '__AllParameterSets'
                ExpectedParameters = '[-Configuration] <Object> [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Get-SqlDscRSDatabaseInstallation').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }
    }

    Context 'When getting report server installations' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod -MockWith {
                return @{
                    Length         = 2
                    InstallationIDs = @('GUID1', 'GUID2')
                    MachineNames    = @('SERVER1', 'SERVER2')
                    InstanceNames   = @('SSRS', 'SSRS')
                    IsInitialized   = @($true, $true)
                }
            }
        }

        It 'Should return installation objects' {
            $result = $mockCimInstance | Get-SqlDscRSDatabaseInstallation

            $result | Should -Not -BeNullOrEmpty
            $result | Should -HaveCount 2
            $result[0].InstallationID | Should -Be 'GUID1'
            $result[0].MachineName | Should -Be 'SERVER1'
            $result[0].InstanceName | Should -Be 'SSRS'
            $result[0].IsInitialized | Should -BeTrue

            Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                $MethodName -eq 'ListReportServersInDatabase'
            } -Exactly -Times 1
        }
    }

    Context 'When there are no installations' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod -MockWith {
                return @{
                    Length          = 0
                    InstallationIDs = @()
                    MachineNames    = @()
                    InstanceNames   = @()
                    IsInitialized   = @()
                }
            }
        }

        It 'Should return an empty result' {
            $result = $mockCimInstance | Get-SqlDscRSDatabaseInstallation

            $result | Should -BeNullOrEmpty

            Should -Invoke -CommandName Invoke-RsCimMethod -Exactly -Times 1
        }
    }

    Context 'When CIM method fails' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod -MockWith {
                throw 'Method ListReportServersInDatabase() failed with an error.'
            }
        }

        It 'Should throw a terminating error' {
            { $mockCimInstance | Get-SqlDscRSDatabaseInstallation } | Should -Throw -ErrorId 'GSRSDI0001,Get-SqlDscRSDatabaseInstallation'
        }
    }

    Context 'When passing configuration as parameter' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod -MockWith {
                return @{
                    Length          = 1
                    InstallationIDs = @('GUID1')
                    MachineNames    = @('SERVER1')
                    InstanceNames   = @('SSRS')
                    IsInitialized   = @($true)
                }
            }
        }

        It 'Should get database installation information' {
            $result = Get-SqlDscRSDatabaseInstallation -Configuration $mockCimInstance

            $result | Should -Not -BeNullOrEmpty
            $result | Should -HaveCount 1

            Should -Invoke -CommandName Invoke-RsCimMethod -Exactly -Times 1
        }
    }
}
