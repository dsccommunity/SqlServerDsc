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

    # Do not use -Force. Doing so, or unloading the module in AfterAll, causes
    # PowerShell class types to get new identities, breaking type comparisons.
    Import-Module -Name $script:moduleName -ErrorAction 'Stop'

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:moduleName

    $env:SqlServerDscCI = $true
}

AfterAll {
    Remove-Item -Path 'env:SqlServerDscCI'

    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')
}

Describe 'Get-HResultMessage' -Tag 'Private' {
    Context 'When translating known HRESULT codes' {
        BeforeDiscovery {
            $testCases = @(
                @{
                    HResult         = -2147024891
                    ExpectedPattern = '*Access is denied*'
                    Description     = 'E_ACCESSDENIED'
                }
                @{
                    HResult         = -2147023181
                    ExpectedPattern = '*logon type*'
                    Description     = 'ERROR_LOGON_TYPE_NOT_GRANTED'
                }
                @{
                    HResult         = -2147467259
                    ExpectedPattern = '*unspecified failure*'
                    Description     = 'E_FAIL'
                }
                @{
                    HResult         = -2147024809
                    ExpectedPattern = '*arguments are not valid*'
                    Description     = 'E_INVALIDARG'
                }
                @{
                    HResult         = -2147024882
                    ExpectedPattern = '*out of memory*'
                    Description     = 'E_OUTOFMEMORY'
                }
                @{
                    HResult         = -2147417848
                    ExpectedPattern = '*disconnected*'
                    Description     = 'RPC_E_DISCONNECTED'
                }
                @{
                    HResult         = -2147023174
                    ExpectedPattern = '*RPC server is unavailable*'
                    Description     = 'RPC_S_SERVER_UNAVAILABLE'
                }
                @{
                    HResult         = -2147023834
                    ExpectedPattern = '*service has not been started*'
                    Description     = 'ERROR_SERVICE_NOT_ACTIVE'
                }
            )
        }

        It 'Should return a descriptive message for <Description> (HRESULT: <HResult>)' -ForEach $testCases {
            InModuleScope -Parameters $_ -ScriptBlock {
                $result = Get-HResultMessage -HResult $HResult

                $result | Should -BeLike $ExpectedPattern
            }
        }
    }

    Context 'When translating an unknown HRESULT code' {
        It 'Should return a generic message with the hexadecimal code' {
            InModuleScope -ScriptBlock {
                $result = Get-HResultMessage -HResult -2147483648

                $result | Should -BeLike '*Unknown HRESULT*'
                $result | Should -BeLike '*0x80000000*'
            }
        }
    }

    Context 'When translating a positive HRESULT code' {
        It 'Should return a generic message for positive values' {
            InModuleScope -ScriptBlock {
                # Positive values are typically success codes but if they don't map, return unknown
                $result = Get-HResultMessage -HResult 12345

                $result | Should -BeLike '*Unknown HRESULT*'
            }
        }
    }
}
