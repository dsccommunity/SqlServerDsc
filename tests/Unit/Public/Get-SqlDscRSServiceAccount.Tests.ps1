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

Describe 'Get-SqlDscRSServiceAccount' {
    Context 'When validating parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = '__AllParameterSets'
                ExpectedParameters = '[-Configuration] <Object> [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Get-SqlDscRSServiceAccount').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }
    }

    Context 'When getting service account successfully' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
                WindowsServiceIdentityConfigured = 'NT SERVICE\SQLServerReportingServices'
                WindowsServiceIdentityActual = 'NT SERVICE\SQLServerReportingServices'
            }
        }

        It 'Should return the service account information' {
            $result = $mockCimInstance | Get-SqlDscRSServiceAccount

            $result | Should -Not -BeNullOrEmpty
            $result.ConfiguredAccount | Should -Be 'NT SERVICE\SQLServerReportingServices'
            $result.ActualAccount | Should -Be 'NT SERVICE\SQLServerReportingServices'
        }
    }

    Context 'When passing configuration as parameter' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
                WindowsServiceIdentityConfigured = 'DOMAIN\ServiceAccount'
                WindowsServiceIdentityActual = 'DOMAIN\ServiceAccount'
            }
        }

        It 'Should return the service account information' {
            $result = Get-SqlDscRSServiceAccount -Configuration $mockCimInstance

            $result | Should -Not -BeNullOrEmpty
            $result.ConfiguredAccount | Should -Be 'DOMAIN\ServiceAccount'
            $result.ActualAccount | Should -Be 'DOMAIN\ServiceAccount'
        }
    }

    Context 'When configured and actual accounts differ' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
                WindowsServiceIdentityConfigured = 'DOMAIN\NewAccount'
                WindowsServiceIdentityActual = 'DOMAIN\OldAccount'
            }
        }

        It 'Should return both configured and actual accounts' {
            $result = $mockCimInstance | Get-SqlDscRSServiceAccount

            $result | Should -Not -BeNullOrEmpty
            $result.ConfiguredAccount | Should -Be 'DOMAIN\NewAccount'
            $result.ActualAccount | Should -Be 'DOMAIN\OldAccount'
        }
    }
}
