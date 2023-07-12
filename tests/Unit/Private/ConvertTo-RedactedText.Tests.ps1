[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Justification = 'because ConvertTo-SecureString is used to simplify the tests.')]
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
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
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

Describe 'ConvertTo-RedactedText' -Tag 'Private' {
    It 'Should redact a single phrase' {
        InModuleScope -Parameters $_ -ScriptBlock {
            Set-StrictMode -Version 1.0

            $result = ConvertTo-RedactedText -Text 'My secret phrase: secret123 secret456' -RedactPhrase 'secret123'

            $result | Should -Be 'My secret phrase: ******* secret456'
        }
    }

    It 'Should redact multiple phrases' {
        InModuleScope -Parameters $_ -ScriptBlock {
            Set-StrictMode -Version 1.0

            $result = ConvertTo-RedactedText -Text 'My secret phrase: secret123 secret456' -RedactPhrase 'secret123', 'secret456'

            $result | Should -Be 'My secret phrase: ******* *******'
        }
    }

    It 'Should redact a multi line text' {
        InModuleScope -Parameters $_ -ScriptBlock {
            Set-StrictMode -Version 1.0

            $result = ConvertTo-RedactedText -Text @'
My secret phrase:
secret123
secret456
'@ -RedactPhrase 'secret123', 'secret456'

            $result | Should -Be @'
My secret phrase:
*******
*******
'@
        }
    }

    It 'Should redact text using optional string phrase' {
        InModuleScope -Parameters $_ -ScriptBlock {
            Set-StrictMode -Version 1.0

            $result = ConvertTo-RedactedText -RedactWith '----' -Text 'My secret phrase: secret123' -RedactPhrase 'secret123'

            $result | Should -Be 'My secret phrase: ----'
        }
    }

    It 'Should correctly redact text that look like regular expression' {
        InModuleScope -Parameters $_ -ScriptBlock {
            Set-StrictMode -Version 1.0

            # CSpell: disable-next
            $result = ConvertTo-RedactedText -Text 'My secret phrase: ^s/d(ecret)123' -RedactPhrase '^s/d(ecret)123'

            $result | Should -Be 'My secret phrase: *******'
        }
    }
}
