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

Describe 'Restore-SqlDscRSEncryptionKey' {
    Context 'When validating parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = 'ByCredential'
                ExpectedParameters = '-Configuration <Object> -Path <string> -Password <securestring> [-Credential <pscredential>] [-DriveName <string>] [-PassThru] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Restore-SqlDscRSEncryptionKey').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }

        It 'Should have Configuration as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Restore-SqlDscRSEncryptionKey').Parameters['Configuration']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have Path as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Restore-SqlDscRSEncryptionKey').Parameters['Path']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have Password as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Restore-SqlDscRSEncryptionKey').Parameters['Password']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }
    }

    Context 'When restoring encryption key successfully' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            $mockPassword = ConvertTo-SecureString -String 'P@ssw0rd' -AsPlainText -Force

            # Create a test key file using TestDrive
            $script:testKeyFilePath = Join-Path -Path $TestDrive -ChildPath 'RSKey.snk'
            [System.IO.File]::WriteAllBytes($script:testKeyFilePath, [byte[]] @(1, 2, 3, 4))

            Mock -CommandName Invoke-RsCimMethod
        }

        It 'Should restore encryption key without errors' {
            $mockCimInstance | Restore-SqlDscRSEncryptionKey -Password $mockPassword -Path $script:testKeyFilePath -Confirm:$false

            Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                $MethodName -eq 'RestoreEncryptionKey'
            } -Exactly -Times 1
        }

        It 'Should not return anything by default' {
            $result = $mockCimInstance | Restore-SqlDscRSEncryptionKey -Password $mockPassword -Path $script:testKeyFilePath -Confirm:$false

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'When restoring encryption key with PassThru' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            $mockPassword = ConvertTo-SecureString -String 'P@ssw0rd' -AsPlainText -Force

            # Create a test key file using TestDrive
            $script:testKeyFilePath = Join-Path -Path $TestDrive -ChildPath 'RSKey.snk'
            [System.IO.File]::WriteAllBytes($script:testKeyFilePath, [byte[]] @(1, 2, 3, 4))

            Mock -CommandName Invoke-RsCimMethod
        }

        It 'Should return the configuration CIM instance' {
            $result = $mockCimInstance | Restore-SqlDscRSEncryptionKey -Password $mockPassword -Path $script:testKeyFilePath -PassThru -Confirm:$false

            $result | Should -Not -BeNullOrEmpty
            $result.InstanceName | Should -Be 'SSRS'
        }
    }

    Context 'When restoring encryption key with Force' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            $mockPassword = ConvertTo-SecureString -String 'P@ssw0rd' -AsPlainText -Force

            # Create a test key file using TestDrive
            $script:testKeyFilePath = Join-Path -Path $TestDrive -ChildPath 'RSKey.snk'
            [System.IO.File]::WriteAllBytes($script:testKeyFilePath, [byte[]] @(1, 2, 3, 4))

            Mock -CommandName Invoke-RsCimMethod
        }

        It 'Should restore encryption key without confirmation' {
            $mockCimInstance | Restore-SqlDscRSEncryptionKey -Password $mockPassword -Path $script:testKeyFilePath -Force

            Should -Invoke -CommandName Invoke-RsCimMethod -Exactly -Times 1
        }
    }

    Context 'When CIM method fails' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            $mockPassword = ConvertTo-SecureString -String 'P@ssw0rd' -AsPlainText -Force

            # Create a test key file using TestDrive
            $script:testKeyFilePath = Join-Path -Path $TestDrive -ChildPath 'RSKey.snk'
            [System.IO.File]::WriteAllBytes($script:testKeyFilePath, [byte[]] @(1, 2, 3, 4))

            Mock -CommandName Invoke-RsCimMethod -MockWith {
                throw 'Method RestoreEncryptionKey() failed with an error.'
            }
        }

        It 'Should throw a terminating error' {
            { $mockCimInstance | Restore-SqlDscRSEncryptionKey -Password $mockPassword -Path $script:testKeyFilePath -Confirm:$false } | Should -Throw -ErrorId 'RSRSEK0001,Restore-SqlDscRSEncryptionKey'
        }
    }

    Context 'When using WhatIf' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            $mockPassword = ConvertTo-SecureString -String 'P@ssw0rd' -AsPlainText -Force

            # Create a test key file using TestDrive
            $script:testKeyFilePath = Join-Path -Path $TestDrive -ChildPath 'RSKey.snk'
            [System.IO.File]::WriteAllBytes($script:testKeyFilePath, [byte[]] @(1, 2, 3, 4))

            Mock -CommandName Invoke-RsCimMethod
        }

        It 'Should not call Invoke-RsCimMethod' {
            $mockCimInstance | Restore-SqlDscRSEncryptionKey -Password $mockPassword -Path $script:testKeyFilePath -WhatIf

            Should -Invoke -CommandName Invoke-RsCimMethod -Exactly -Times 0
        }
    }

    Context 'When passing configuration as parameter' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            $mockPassword = ConvertTo-SecureString -String 'P@ssw0rd' -AsPlainText -Force

            # Create a test key file using TestDrive
            $script:testKeyFilePath = Join-Path -Path $TestDrive -ChildPath 'RSKey.snk'
            [System.IO.File]::WriteAllBytes($script:testKeyFilePath, [byte[]] @(1, 2, 3, 4))

            Mock -CommandName Invoke-RsCimMethod
        }

        It 'Should restore encryption key' {
            Restore-SqlDscRSEncryptionKey -Configuration $mockCimInstance -Password $mockPassword -Path $script:testKeyFilePath -Confirm:$false

            Should -Invoke -CommandName Invoke-RsCimMethod -Exactly -Times 1
        }
    }

    Context 'When restoring encryption key using Credential parameter with UNC path' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            $mockPassword = ConvertTo-SecureString -String 'P@ssw0rd' -AsPlainText -Force
            $mockCredential = [System.Management.Automation.PSCredential]::new('Domain\User', (ConvertTo-SecureString -String 'CredPass' -AsPlainText -Force))

            # Create a test key file using TestDrive
            $script:testKeyFilePath = Join-Path -Path $TestDrive -ChildPath 'RSKey.snk'
            [System.IO.File]::WriteAllBytes($script:testKeyFilePath, [byte[]] @(1, 2, 3, 4))

            Mock -CommandName Invoke-RsCimMethod
            Mock -CommandName New-PSDrive -MockWith {
                return [PSCustomObject] @{
                    Name = 'RSKeyRestore'
                    Root = '\\server\share'
                }
            }
            Mock -CommandName Remove-PSDrive

            <#
                Mock Split-Path to simulate Windows behavior for UNC paths.
                On macOS, Split-Path does not properly handle UNC paths.
            #>
            Mock -CommandName Split-Path -MockWith {
                return '\\server\share'
            } -ParameterFilter {
                $Path -eq '\\server\share\RSKey.snk' -and $Parent -eq $true
            }

            Mock -CommandName Split-Path -MockWith {
                return 'RSKey.snk'
            } -ParameterFilter {
                $Path -eq '\\server\share\RSKey.snk' -and $Leaf -eq $true
            }

            <#
                Mock Resolve-Path to return the actual test file path when the
                PSDrive path is resolved. This simulates the behavior of resolving
                a PSDrive path to the underlying filesystem path.
            #>
            Mock -CommandName Resolve-Path -MockWith {
                return [PSCustomObject] @{
                    ProviderPath = $script:testKeyFilePath
                }
            } -ParameterFilter {
                $LiteralPath -eq 'RSKeyRestore:\RSKey.snk'
            }
        }

        It 'Should resolve PSDrive path and restore encryption key' {
            $mockCimInstance | Restore-SqlDscRSEncryptionKey -Password $mockPassword -Path '\\server\share\RSKey.snk' -Credential $mockCredential -Confirm:$false

            Should -Invoke -CommandName New-PSDrive -Exactly -Times 1
            Should -Invoke -CommandName Resolve-Path -ParameterFilter {
                $LiteralPath -eq 'RSKeyRestore:\RSKey.snk'
            } -Exactly -Times 1
            Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                $MethodName -eq 'RestoreEncryptionKey'
            } -Exactly -Times 1
            Should -Invoke -CommandName Remove-PSDrive -Exactly -Times 1
        }
    }
}
