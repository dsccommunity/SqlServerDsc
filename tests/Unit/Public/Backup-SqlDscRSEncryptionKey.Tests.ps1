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

Describe 'Backup-SqlDscRSEncryptionKey' {
    Context 'When validating parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = 'ByCredential'
                ExpectedParameters = '-Configuration <Object> -Path <string> -Password <securestring> [-Credential <pscredential>] [-DriveName <string>] [-PassThru] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Backup-SqlDscRSEncryptionKey').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }

        It 'Should have Configuration as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Backup-SqlDscRSEncryptionKey').Parameters['Configuration']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have Path as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Backup-SqlDscRSEncryptionKey').Parameters['Path']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have Password as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Backup-SqlDscRSEncryptionKey').Parameters['Password']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }
    }

    Context 'When backing up encryption key successfully' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            $mockPassword = ConvertTo-SecureString -String 'P@ssw0rd' -AsPlainText -Force

            Mock -CommandName Invoke-RsCimMethod -MockWith {
                return @{
                    KeyFile = [System.Text.Encoding]::UTF8.GetBytes('MockKeyFileContent')
                }
            }
        }

        It 'Should backup encryption key without errors' {
            $testPath = Join-Path -Path $TestDrive -ChildPath 'RSKey.snk'

            $null = $mockCimInstance | Backup-SqlDscRSEncryptionKey -Password $mockPassword -Path $testPath -Confirm:$false

            Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                $MethodName -eq 'BackupEncryptionKey'
            } -Exactly -Times 1

            $testPath | Should -Exist
        }

        It 'Should not return anything by default' {
            $testPath = Join-Path -Path $TestDrive -ChildPath 'RSKey2.snk'

            $result = $mockCimInstance | Backup-SqlDscRSEncryptionKey -Password $mockPassword -Path $testPath -Confirm:$false

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'When backing up encryption key with PassThru' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            $mockPassword = ConvertTo-SecureString -String 'P@ssw0rd' -AsPlainText -Force

            Mock -CommandName Invoke-RsCimMethod -MockWith {
                return @{
                    KeyFile = [System.Text.Encoding]::UTF8.GetBytes('MockKeyFileContent')
                }
            }
        }

        It 'Should return the configuration CIM instance' {
            $testPath = Join-Path -Path $TestDrive -ChildPath 'RSKey.snk'

            $result = $mockCimInstance | Backup-SqlDscRSEncryptionKey -Password $mockPassword -Path $testPath -PassThru -Confirm:$false

            $result | Should -Not -BeNullOrEmpty
            $result.InstanceName | Should -Be 'SSRS'
        }
    }

    Context 'When backing up encryption key with Force' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            $mockPassword = ConvertTo-SecureString -String 'P@ssw0rd' -AsPlainText -Force

            Mock -CommandName Invoke-RsCimMethod -MockWith {
                return @{
                    KeyFile = [System.Text.Encoding]::UTF8.GetBytes('MockKeyFileContent')
                }
            }
        }

        It 'Should backup encryption key without confirmation' {
            $testPath = Join-Path -Path $TestDrive -ChildPath 'RSKey.snk'

            $null = $mockCimInstance | Backup-SqlDscRSEncryptionKey -Password $mockPassword -Path $testPath -Force

            Should -Invoke -CommandName Invoke-RsCimMethod -Exactly -Times 1
        }
    }

    Context 'When CIM method fails' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            $mockPassword = ConvertTo-SecureString -String 'P@ssw0rd' -AsPlainText -Force

            Mock -CommandName Invoke-RsCimMethod -MockWith {
                throw 'Method BackupEncryptionKey() failed with an error.'
            }
        }

        It 'Should throw a terminating error' {
            $testPath = Join-Path -Path $TestDrive -ChildPath 'RSKey.snk'

            { $mockCimInstance | Backup-SqlDscRSEncryptionKey -Password $mockPassword -Path $testPath -Confirm:$false } | Should -Throw -ErrorId 'BSRSEK0001,Backup-SqlDscRSEncryptionKey'
        }
    }

    Context 'When using WhatIf' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            $mockPassword = ConvertTo-SecureString -String 'P@ssw0rd' -AsPlainText -Force

            Mock -CommandName Invoke-RsCimMethod
        }

        It 'Should not call Invoke-RsCimMethod' {
            $testPath = Join-Path -Path $TestDrive -ChildPath 'RSKey.snk'

            $null = $mockCimInstance | Backup-SqlDscRSEncryptionKey -Password $mockPassword -Path $testPath -WhatIf

            Should -Invoke -CommandName Invoke-RsCimMethod -Exactly -Times 0

            $testPath | Should -Not -Exist
        }
    }

    Context 'When passing configuration as parameter' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            $mockPassword = ConvertTo-SecureString -String 'P@ssw0rd' -AsPlainText -Force

            Mock -CommandName Invoke-RsCimMethod -MockWith {
                return @{
                    KeyFile = [System.Text.Encoding]::UTF8.GetBytes('MockKeyFileContent')
                }
            }
        }

        It 'Should backup encryption key' {
            $testPath = Join-Path -Path $TestDrive -ChildPath 'RSKey.snk'

            $null = Backup-SqlDscRSEncryptionKey -Configuration $mockCimInstance -Password $mockPassword -Path $testPath -Confirm:$false

            Should -Invoke -CommandName Invoke-RsCimMethod -Exactly -Times 1
        }
    }

    Context 'When backing up to UNC path with Credential' -Skip:(-not ($IsWindows -or $PSVersionTable.PSVersion.Major -eq 5)) {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            $mockPassword = ConvertTo-SecureString -String 'P@ssw0rd' -AsPlainText -Force
            $mockCredential = [System.Management.Automation.PSCredential]::new(
                'TestUser',
                (ConvertTo-SecureString -String 'TestPassword' -AsPlainText -Force)
            )

            # Use TestDrive for the actual file write
            $script:testBackupPath = Join-Path -Path $TestDrive -ChildPath 'RSKey.snk'

            Mock -CommandName Invoke-RsCimMethod -MockWith {
                return @{
                    KeyFile = [System.Text.Encoding]::UTF8.GetBytes('MockKeyFileContent')
                }
            }

            Mock -CommandName New-PSDrive
            Mock -CommandName Remove-PSDrive
        }

        It 'Should create and remove PSDrive when using UNC path with Credential' {
            $uncPath = '\\server\share\RSKey.snk'

            $null = Backup-SqlDscRSEncryptionKey -Configuration $mockCimInstance -Password $mockPassword -Path $uncPath -Credential $mockCredential -Confirm:$false

            Should -Invoke -CommandName New-PSDrive -Exactly -Times 1
            Should -Invoke -CommandName Remove-PSDrive -Exactly -Times 1
        }
    }
}
