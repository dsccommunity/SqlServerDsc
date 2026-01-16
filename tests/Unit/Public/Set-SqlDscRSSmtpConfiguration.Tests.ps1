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

Describe 'Set-SqlDscRSSmtpConfiguration' {
    Context 'When validating parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = '__AllParameterSets'
                ExpectedParameters = '[-Configuration] <Object> [-SmtpServer] <string> [-SenderEmailAddress] <string> [-PassThru] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Set-SqlDscRSSmtpConfiguration').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }
    }

    Context 'When validating parameter attributes' {
        BeforeAll {
            $commandMetadata = Get-Command -Name 'Set-SqlDscRSSmtpConfiguration'
        }

        Context 'When validating the Configuration parameter' {
            BeforeAll {
                $configurationParameter = $commandMetadata.Parameters['Configuration']
            }

            It 'Should have Mandatory set to True' {
                $configurationParameter.Attributes.Mandatory | Should -Contain $true
            }

            It 'Should have ValueFromPipeline set to True' {
                $configurationParameter.Attributes.ValueFromPipeline | Should -Contain $true
            }

            It 'Should have the expected parameter type' {
                $configurationParameter.ParameterType.Name | Should -Be 'Object'
            }

            It 'Should have Position set to 0' {
                $configurationParameter.Attributes.Position | Should -Contain 0
            }

            It 'Should be a member of __AllParameterSets parameter set' {
                $configurationParameter.ParameterSets.Keys | Should -Contain '__AllParameterSets'
            }
        }

        Context 'When validating the SmtpServer parameter' {
            BeforeAll {
                $smtpServerParameter = $commandMetadata.Parameters['SmtpServer']
            }

            It 'Should have Mandatory set to True' {
                $smtpServerParameter.Attributes.Mandatory | Should -Contain $true
            }

            It 'Should have ValueFromPipeline set to False' {
                $smtpServerParameter.Attributes.ValueFromPipeline | Should -Contain $false
            }

            It 'Should have the expected parameter type' {
                $smtpServerParameter.ParameterType.Name | Should -Be 'String'
            }

            It 'Should have Position set to 1' {
                $smtpServerParameter.Attributes.Position | Should -Contain 1
            }

            It 'Should be a member of __AllParameterSets parameter set' {
                $smtpServerParameter.ParameterSets.Keys | Should -Contain '__AllParameterSets'
            }
        }

        Context 'When validating the SenderEmailAddress parameter' {
            BeforeAll {
                $senderEmailAddressParameter = $commandMetadata.Parameters['SenderEmailAddress']
            }

            It 'Should have Mandatory set to True' {
                $senderEmailAddressParameter.Attributes.Mandatory | Should -Contain $true
            }

            It 'Should have ValueFromPipeline set to False' {
                $senderEmailAddressParameter.Attributes.ValueFromPipeline | Should -Contain $false
            }

            It 'Should have the expected parameter type' {
                $senderEmailAddressParameter.ParameterType.Name | Should -Be 'String'
            }

            It 'Should have Position set to 2' {
                $senderEmailAddressParameter.Attributes.Position | Should -Contain 2
            }

            It 'Should be a member of __AllParameterSets parameter set' {
                $senderEmailAddressParameter.ParameterSets.Keys | Should -Contain '__AllParameterSets'
            }
        }

        Context 'When validating the PassThru parameter' {
            BeforeAll {
                $passThruParameter = $commandMetadata.Parameters['PassThru']
            }

            It 'Should have Mandatory set to False' {
                $passThruParameter.Attributes.Mandatory | Should -Contain $false
            }

            It 'Should have ValueFromPipeline set to False' {
                $passThruParameter.Attributes.ValueFromPipeline | Should -Contain $false
            }

            It 'Should have the expected parameter type' {
                $passThruParameter.ParameterType.Name | Should -Be 'SwitchParameter'
            }

            It 'Should be a member of __AllParameterSets parameter set' {
                $passThruParameter.ParameterSets.Keys | Should -Contain '__AllParameterSets'
            }
        }

        Context 'When validating the Force parameter' {
            BeforeAll {
                $forceParameter = $commandMetadata.Parameters['Force']
            }

            It 'Should have Mandatory set to False' {
                $forceParameter.Attributes.Mandatory | Should -Contain $false
            }

            It 'Should have ValueFromPipeline set to False' {
                $forceParameter.Attributes.ValueFromPipeline | Should -Contain $false
            }

            It 'Should have the expected parameter type' {
                $forceParameter.ParameterType.Name | Should -Be 'SwitchParameter'
            }

            It 'Should be a member of __AllParameterSets parameter set' {
                $forceParameter.ParameterSets.Keys | Should -Contain '__AllParameterSets'
            }
        }

        Context 'When validating the WhatIf parameter' {
            BeforeAll {
                $whatIfParameter = $commandMetadata.Parameters['WhatIf']
            }

            It 'Should have Mandatory set to False' {
                $whatIfParameter.Attributes.Mandatory | Should -BeIn @($false, $null)
            }

            It 'Should have the expected parameter type' {
                $whatIfParameter.ParameterType.Name | Should -Be 'SwitchParameter'
            }
        }

        Context 'When validating the Confirm parameter' {
            BeforeAll {
                $confirmParameter = $commandMetadata.Parameters['Confirm']
            }

            It 'Should have Mandatory set to False' {
                $confirmParameter.Attributes.Mandatory | Should -BeIn @($false, $null)
            }

            It 'Should have the expected parameter type' {
                $confirmParameter.ParameterType.Name | Should -Be 'SwitchParameter'
            }
        }
    }

    Context 'When setting SMTP configuration successfully' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod
        }

        It 'Should set SMTP configuration without errors' {
            $null = $mockCimInstance | Set-SqlDscRSSmtpConfiguration -SmtpServer 'smtp.example.com' -SenderEmailAddress 'reports@example.com' -Confirm:$false

            Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                $MethodName -eq 'SetEmailConfiguration' -and
                $Arguments.SendUsingSMTPServer -eq $true -and
                $Arguments.SMTPServer -eq 'smtp.example.com' -and
                $Arguments.SenderEmailAddress -eq 'reports@example.com'
            } -Exactly -Times 1
        }

        It 'Should not return anything by default' {
            $result = $mockCimInstance | Set-SqlDscRSSmtpConfiguration -SmtpServer 'smtp.example.com' -SenderEmailAddress 'reports@example.com' -Confirm:$false

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'When setting SMTP configuration with PassThru' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod
        }

        It 'Should return the configuration CIM instance' {
            $result = $mockCimInstance | Set-SqlDscRSSmtpConfiguration -SmtpServer 'smtp.example.com' -SenderEmailAddress 'reports@example.com' -PassThru -Confirm:$false

            $result | Should -Not -BeNullOrEmpty
            $result.InstanceName | Should -Be 'SSRS'
        }
    }

    Context 'When setting SMTP configuration with Force' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod
        }

        It 'Should set SMTP configuration without confirmation' {
            $null = $mockCimInstance | Set-SqlDscRSSmtpConfiguration -SmtpServer 'smtp.example.com' -SenderEmailAddress 'reports@example.com' -Force

            Should -Invoke -CommandName Invoke-RsCimMethod -Exactly -Times 1
        }
    }

    Context 'When CIM method fails' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod -MockWith {
                throw 'Method SetEmailConfiguration() failed with an error.'
            }
        }

        It 'Should throw a terminating error' {
            { $mockCimInstance | Set-SqlDscRSSmtpConfiguration -SmtpServer 'smtp.example.com' -SenderEmailAddress 'reports@example.com' -Confirm:$false } | Should -Throw -ErrorId 'SSRSSC0001,Set-SqlDscRSSmtpConfiguration'
        }
    }

    Context 'When using WhatIf' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod
        }

        It 'Should not call Invoke-RsCimMethod' {
            $null = $mockCimInstance | Set-SqlDscRSSmtpConfiguration -SmtpServer 'smtp.example.com' -SenderEmailAddress 'reports@example.com' -WhatIf

            Should -Invoke -CommandName Invoke-RsCimMethod -Exactly -Times 0
        }
    }

    Context 'When passing configuration as parameter' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod
        }

        It 'Should set SMTP configuration' {
            $null = Set-SqlDscRSSmtpConfiguration -Configuration $mockCimInstance -SmtpServer 'smtp.example.com' -SenderEmailAddress 'reports@example.com' -Confirm:$false

            Should -Invoke -CommandName Invoke-RsCimMethod -Exactly -Times 1
        }
    }
}
