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

    Import-Module -Name $script:moduleName -ErrorAction 'Stop'

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:moduleName

    $env:SqlServerDscCI = $true

    InModuleScope -ScriptBlock {
        <#
            Stub for Get-CimInstance since it doesn't exist on macOS and
            we need to be able to mock it.
        #>
        function script:Get-CimInstance
        {
            param
            (
                [System.String]
                $ClassName,

                [System.String]
                $Namespace,

                [System.String]
                $ErrorAction
            )

            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    'StubNotImplemented',
                    'StubCalledError',
                    [System.Management.Automation.ErrorCategory]::InvalidOperation,
                    $MyInvocation.MyCommand
                )
            )
        }
    }
}

AfterAll {
    $env:SqlServerDscCI = $null

    InModuleScope -ScriptBlock {
        Remove-Item -Path 'function:script:Get-CimInstance' -Force -ErrorAction SilentlyContinue
    }

    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')
}

Describe 'Get-OperatingSystem' -Tag 'Private' {
    Context 'When getting the operating system successfully' {
        BeforeAll {
            Mock -CommandName Get-CimInstance -MockWith {
                return [PSCustomObject] @{
                    OSLanguage    = 1033
                    Caption       = 'Microsoft Windows Server 2022'
                    OSArchitecture = '64-bit'
                }
            }
        }

        It 'Should return the operating system CIM instance' {
            InModuleScope -ScriptBlock {
                $result = Get-OperatingSystem

                $result | Should -Not -BeNullOrEmpty
                $result.OSLanguage | Should -Be 1033
                $result.Caption | Should -Be 'Microsoft Windows Server 2022'
            }

            Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                $ClassName -eq 'Win32_OperatingSystem' -and
                $Namespace -eq 'root/cimv2'
            } -Exactly -Times 1
        }
    }

    Context 'When failing to get the operating system' {
        BeforeAll {
            Mock -CommandName Get-CimInstance -MockWith {
                return $null
            }
        }

        It 'Should throw a terminating error' {
            InModuleScope -ScriptBlock {
                { Get-OperatingSystem } | Should -Throw -ErrorId 'GOS0001,Get-OperatingSystem'
            }
        }
    }
}
