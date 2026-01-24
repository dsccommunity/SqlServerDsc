
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Suppressing this rule because Script Analyzer does not understand Pester syntax.')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
            }

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

Describe 'Get-TlsProtocolRegistryPath' -Tag 'Private' {
    Context 'When building the registry path for Server' {
        It 'returns server registry path for Tls12 by default' {
            InModuleScope -ScriptBlock {
                Mock -CommandName ConvertTo-TlsProtocolRegistryKeyName -MockWith { 'Tls12' }
                Mock -CommandName Get-TlsProtocolTargetRegistryName -MockWith { 'Server' }

                $result = Get-TlsProtocolRegistryPath -Protocol 'Tls12'

                $expected = 'HKLM:\\SYSTEM\\CurrentControlSet\\Control\\SecurityProviders\\SCHANNEL\\Protocols\\Tls12\\Server'
                $result | Should -Be $expected
            }
        }
    }

    Context 'When building the registry path for Client' {
        It 'returns client registry path when -Client is specified' {
            InModuleScope -ScriptBlock {
                Mock -CommandName ConvertTo-TlsProtocolRegistryKeyName -MockWith { 'Tls12' }
                Mock -CommandName Get-TlsProtocolTargetRegistryName -MockWith { 'Client' }

                $result = Get-TlsProtocolRegistryPath -Protocol 'Tls12' -Client

                $expected = 'HKLM:\\SYSTEM\\CurrentControlSet\\Control\\SecurityProviders\\SCHANNEL\\Protocols\\Tls12\\Client'
                $result | Should -Be $expected
            }
        }
    }
}
