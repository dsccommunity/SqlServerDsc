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

Describe 'ConvertTo-TlsProtocolRegistryKeyName' -Tag 'Private' {
    Context 'When converting known friendly protocol names' {
        It 'Maps Tls12 to TLS 1.2' {
            InModuleScope -ScriptBlock {
                ConvertTo-TlsProtocolRegistryKeyName -Protocol 'Tls12' | Should -Be 'TLS 1.2'
            }
        }

        It 'Maps Tls11 to TLS 1.1' {
            InModuleScope -ScriptBlock {
                ConvertTo-TlsProtocolRegistryKeyName -Protocol 'Tls11' | Should -Be 'TLS 1.1'
            }
        }

        It 'Maps Tls to TLS 1.0' {
            InModuleScope -ScriptBlock {
                ConvertTo-TlsProtocolRegistryKeyName -Protocol 'Tls' | Should -Be 'TLS 1.0'
            }
        }

        It 'Maps Ssl3 to SSL 3.0' {
            InModuleScope -ScriptBlock {
                ConvertTo-TlsProtocolRegistryKeyName -Protocol 'Ssl3' | Should -Be 'SSL 3.0'
            }
        }

        It 'Maps Ssl2 to SSL 2.0' {
            InModuleScope -ScriptBlock {
                ConvertTo-TlsProtocolRegistryKeyName -Protocol 'Ssl2' | Should -Be 'SSL 2.0'
            }
        }

        It 'Maps Tls13 to TLS 1.3' {
            InModuleScope -ScriptBlock {
                ConvertTo-TlsProtocolRegistryKeyName -Protocol 'Tls13' | Should -Be 'TLS 1.3'
            }
        }
    }

    Context 'When given an unknown protocol' {
        It 'Should throw a terminating error' {
            InModuleScope -ScriptBlock {
                { ConvertTo-TlsProtocolRegistryKeyName -Protocol 'NoSuchProto' } | Should -Throw -ErrorId 'InvalidProtocol,ConvertTo-TlsProtocolRegistryKeyName'
            }
        }
    }
}
