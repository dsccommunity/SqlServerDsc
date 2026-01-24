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

Describe 'Test-TlsProtocol' -Tag 'Public' {
    Context 'When protocol is enabled in registry' {
        BeforeAll {
            Mock -CommandName Get-RegistryPropertyValue -MockWith {
                return 1
            } -ParameterFilter { $Path -like '*\\Server' -and $Name -eq 'Enabled' }

            Mock -CommandName Get-RegistryPropertyValue -MockWith {
                return 0
            } -ParameterFilter { $Path -like '*\\Server' -and $Name -eq 'DisabledByDefault' }
        }

        It 'Should return $true' {
            $result = Test-TlsProtocol -Protocol 'Tls12'

            $result | Should -BeTrue
        }
    }

    Context 'When protocol key is missing' {
        BeforeAll {
            Mock -CommandName Get-RegistryPropertyValue
        }

        It 'Should return $true' {
            $result = Test-TlsProtocol -Protocol 'Tls12'

            $result | Should -BeTrue
        }
    }

    Context 'When DisabledByDefault is set to 1' {
        BeforeAll {
            Mock -CommandName Get-RegistryPropertyValue -MockWith {
                return 1
            } -ParameterFilter { $Path -like '*\\Server' -and $Name -eq 'Enabled' }

            Mock -CommandName Get-RegistryPropertyValue -MockWith {
                return 1
            } -ParameterFilter { $Path -like '*\\Server' -and $Name -eq 'DisabledByDefault' }
        }

        It 'Should return $false when DisabledByDefault is 1' {
            $result = Test-TlsProtocol -Protocol 'Tls12'

            $result | Should -BeFalse
        }
    }

    Context 'When using the Client switch' {
        BeforeAll {
            Mock -CommandName Get-RegistryPropertyValue -MockWith {
                return 1
            } -ParameterFilter { $Path -like '*\\Client' -and $Name -eq 'Enabled' }

            Mock -CommandName Get-RegistryPropertyValue -MockWith {
                return 0
            } -ParameterFilter { $Path -like '*\\Client' -and $Name -eq 'DisabledByDefault' }
        }

        It 'Should check the Client registry key' {
            $result = Test-TlsProtocol -Protocol 'Tls12' -Client

            $result | Should -BeTrue

            Should -Invoke -CommandName Get-RegistryPropertyValue -ParameterFilter {
                 $Path -like '*\\Client' -and $Name -eq 'Enabled'
            } -Exactly -Times 1 -Scope It

            Should -Invoke -CommandName Get-RegistryPropertyValue -ParameterFilter {
                 $Path -like '*\\Client' -and $Name -eq 'DisabledByDefault'
            } -Exactly -Times 1 -Scope It
        }
    }

    Context 'When testing for Disabled protocols' {
        Context 'When protocol is explicitly disabled' {
            BeforeAll {
                Mock -CommandName Get-RegistryPropertyValue -MockWith {
                    return 0
                } -ParameterFilter { $Path -like '*\\Server' -and $Name -eq 'Enabled' }

                Mock -CommandName Get-RegistryPropertyValue -MockWith {
                    return 1
                } -ParameterFilter { $Path -like '*\\Server' -and $Name -eq 'DisabledByDefault' }
            }

            It 'Should return $true for -Disabled' {
                $result = Test-TlsProtocol -Protocol 'Tls12' -Disabled

                $result | Should -BeTrue
            }
        }

        Context 'When protocol is enabled' {
            BeforeAll {
                Mock -CommandName Get-RegistryPropertyValue -MockWith {
                    return 1
                } -ParameterFilter { $Path -like '*\\Server' -and $Name -eq 'Enabled' }

                Mock -CommandName Get-RegistryPropertyValue -MockWith {
                    return 0
                } -ParameterFilter { $Path -like '*\\Server' -and $Name -eq 'DisabledByDefault' }
            }

            It 'Should return $false for -Disabled' {
                $result = Test-TlsProtocol -Protocol 'Tls12' -Disabled

                $result | Should -BeFalse
            }
        }

        Context 'When protocol key is missing' {
            BeforeAll {
                Mock -CommandName Get-RegistryPropertyValue
            }

            It 'Should treat missing keys as enabled for -Disabled' {
                $result = Test-TlsProtocol -Protocol 'Tls12' -Disabled

                $result | Should -BeFalse
            }
        }
    }
}
