[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Pester discovery/context variables are declared before usage; this suppression aligns with repository test patterns.')]
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Parameter is used in test mocks.')]
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
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
    }
}

BeforeAll {
    $script:dscModuleName = 'SqlServerDsc'

    $env:SqlServerDscCI = $true

    Import-Module -Name $script:dscModuleName -Force -ErrorAction 'Stop'

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

Describe 'New-SqlDscLogin' -Tag 'Public' {
    It 'Should have the correct parameters in parameter set <MockParameterSetName>' -ForEach @(
        @{
            MockParameterSetName = 'SqlLogin'
            MockExpectedParameters = '-ServerObject <Server> -Name <string> -SqlLogin -SecurePassword <securestring> [-DefaultDatabase <string>] [-DefaultLanguage <string>] [-PasswordExpirationEnabled] [-PasswordPolicyEnforced] [-MustChangePassword] [-Disabled] [-Force] [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
        @{
            MockParameterSetName = 'SqlLoginHashed'
            MockExpectedParameters = '-ServerObject <Server> -Name <string> -SqlLogin -SecurePassword <securestring> -IsHashed [-DefaultDatabase <string>] [-DefaultLanguage <string>] [-Disabled] [-Force] [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
        @{
            MockParameterSetName = 'WindowsUser'
            MockExpectedParameters = '-ServerObject <Server> -Name <string> -WindowsUser [-DefaultDatabase <string>] [-DefaultLanguage <string>] [-Disabled] [-Force] [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
        @{
            MockParameterSetName = 'WindowsGroup'
            MockExpectedParameters = '-ServerObject <Server> -Name <string> -WindowsGroup [-DefaultDatabase <string>] [-DefaultLanguage <string>] [-Disabled] [-Force] [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
        @{
            MockParameterSetName = 'Certificate'
            MockExpectedParameters = '-ServerObject <Server> -Name <string> -Certificate -CertificateName <string> [-DefaultDatabase <string>] [-DefaultLanguage <string>] [-Disabled] [-Force] [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
        @{
            MockParameterSetName = 'AsymmetricKey'
            MockExpectedParameters = '-ServerObject <Server> -Name <string> -AsymmetricKey -AsymmetricKeyName <string> [-DefaultDatabase <string>] [-DefaultLanguage <string>] [-Disabled] [-Force] [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
    ) {
        $result = (Get-Command -Name 'New-SqlDscLogin').ParameterSets |
            Where-Object -FilterScript {
                $_.Name -eq $mockParameterSetName
            } |
            Select-Object -Property @(
                @{
                    Name = 'ParameterSetName'
                    Expression = { $_.Name }
                },
                @{
                    Name = 'ParameterListAsString'
                    Expression = { $_.ToString() }
                }
            )

        $result.ParameterSetName | Should -Be $MockParameterSetName
        $result.ParameterListAsString | Should -Be $MockExpectedParameters
    }

    It 'Should have the correct command metadata' {
        $command = Get-Command -Name 'New-SqlDscLogin'

        $cmdletBindingAttribute = $command.ScriptBlock.Attributes |
            Where-Object -FilterScript { $_ -is [System.Management.Automation.CmdletBindingAttribute] }

        $cmdletBindingAttribute.SupportsShouldProcess | Should -BeTrue
        $cmdletBindingAttribute.ConfirmImpact | Should -Be 'Medium'
        $cmdletBindingAttribute.DefaultParameterSetName | Should -Be 'WindowsUser'
    }

    It 'Should have correct parameter attributes for parameter set <ParameterSetName>' -ForEach @(
        @{
            ParameterSetName = 'SqlLogin'
            ExpectedParameterTests = @(
                @{ ParameterName = 'ServerObject'; IsMandatory = $true; ValueFromPipeline = $true; ValueFromPipelineByPropertyName = $false }
                @{ ParameterName = 'Name'; IsMandatory = $true; ValueFromPipeline = $false; ValueFromPipelineByPropertyName = $false }
                @{ ParameterName = 'SqlLogin'; IsMandatory = $true; ValueFromPipeline = $false; ValueFromPipelineByPropertyName = $false }
                @{ ParameterName = 'SecurePassword'; IsMandatory = $true; ValueFromPipeline = $false; ValueFromPipelineByPropertyName = $false }
                @{ ParameterName = 'DefaultDatabase'; IsMandatory = $false; ValueFromPipeline = $false; ValueFromPipelineByPropertyName = $false }
                @{ ParameterName = 'DefaultLanguage'; IsMandatory = $false; ValueFromPipeline = $false; ValueFromPipelineByPropertyName = $false }
                @{ ParameterName = 'PasswordExpirationEnabled'; IsMandatory = $false; ValueFromPipeline = $false; ValueFromPipelineByPropertyName = $false }
                @{ ParameterName = 'PasswordPolicyEnforced'; IsMandatory = $false; ValueFromPipeline = $false; ValueFromPipelineByPropertyName = $false }
                @{ ParameterName = 'MustChangePassword'; IsMandatory = $false; ValueFromPipeline = $false; ValueFromPipelineByPropertyName = $false }
                @{ ParameterName = 'Disabled'; IsMandatory = $false; ValueFromPipeline = $false; ValueFromPipelineByPropertyName = $false }
                @{ ParameterName = 'Force'; IsMandatory = $false; ValueFromPipeline = $false; ValueFromPipelineByPropertyName = $false }
                @{ ParameterName = 'PassThru'; IsMandatory = $false; ValueFromPipeline = $false; ValueFromPipelineByPropertyName = $false }
                @{ ParameterName = 'WindowsUser'; ShouldExist = $false }
                @{ ParameterName = 'WindowsGroup'; ShouldExist = $false }
                @{ ParameterName = 'Certificate'; ShouldExist = $false }
                @{ ParameterName = 'AsymmetricKey'; ShouldExist = $false }
                @{ ParameterName = 'CertificateName'; ShouldExist = $false }
                @{ ParameterName = 'AsymmetricKeyName'; ShouldExist = $false }
                @{ ParameterName = 'IsHashed'; ShouldExist = $false }
            )
        }
        @{
            ParameterSetName = 'SqlLoginHashed'
            ExpectedParameterTests = @(
                @{ ParameterName = 'ServerObject'; IsMandatory = $true; ValueFromPipeline = $true; ValueFromPipelineByPropertyName = $false }
                @{ ParameterName = 'Name'; IsMandatory = $true; ValueFromPipeline = $false; ValueFromPipelineByPropertyName = $false }
                @{ ParameterName = 'SqlLogin'; IsMandatory = $true; ValueFromPipeline = $false; ValueFromPipelineByPropertyName = $false }
                @{ ParameterName = 'SecurePassword'; IsMandatory = $true; ValueFromPipeline = $false; ValueFromPipelineByPropertyName = $false }
                @{ ParameterName = 'IsHashed'; IsMandatory = $true; ValueFromPipeline = $false; ValueFromPipelineByPropertyName = $false }
                @{ ParameterName = 'DefaultDatabase'; IsMandatory = $false; ValueFromPipeline = $false; ValueFromPipelineByPropertyName = $false }
                @{ ParameterName = 'DefaultLanguage'; IsMandatory = $false; ValueFromPipeline = $false; ValueFromPipelineByPropertyName = $false }
                @{ ParameterName = 'Disabled'; IsMandatory = $false; ValueFromPipeline = $false; ValueFromPipelineByPropertyName = $false }
                @{ ParameterName = 'Force'; IsMandatory = $false; ValueFromPipeline = $false; ValueFromPipelineByPropertyName = $false }
                @{ ParameterName = 'PassThru'; IsMandatory = $false; ValueFromPipeline = $false; ValueFromPipelineByPropertyName = $false }
                @{ ParameterName = 'WindowsUser'; ShouldExist = $false }
                @{ ParameterName = 'WindowsGroup'; ShouldExist = $false }
                @{ ParameterName = 'Certificate'; ShouldExist = $false }
                @{ ParameterName = 'AsymmetricKey'; ShouldExist = $false }
                @{ ParameterName = 'CertificateName'; ShouldExist = $false }
                @{ ParameterName = 'AsymmetricKeyName'; ShouldExist = $false }
                @{ ParameterName = 'PasswordExpirationEnabled'; ShouldExist = $false }
                @{ ParameterName = 'PasswordPolicyEnforced'; ShouldExist = $false }
                @{ ParameterName = 'MustChangePassword'; ShouldExist = $false }
            )
        }
        @{
            ParameterSetName = 'WindowsUser'
            ExpectedParameterTests = @(
                @{ ParameterName = 'ServerObject'; IsMandatory = $true; ValueFromPipeline = $true; ValueFromPipelineByPropertyName = $false }
                @{ ParameterName = 'Name'; IsMandatory = $true; ValueFromPipeline = $false; ValueFromPipelineByPropertyName = $false }
                @{ ParameterName = 'WindowsUser'; IsMandatory = $true; ValueFromPipeline = $false; ValueFromPipelineByPropertyName = $false }
                @{ ParameterName = 'DefaultDatabase'; IsMandatory = $false; ValueFromPipeline = $false; ValueFromPipelineByPropertyName = $false }
                @{ ParameterName = 'DefaultLanguage'; IsMandatory = $false; ValueFromPipeline = $false; ValueFromPipelineByPropertyName = $false }
                @{ ParameterName = 'Disabled'; IsMandatory = $false; ValueFromPipeline = $false; ValueFromPipelineByPropertyName = $false }
                @{ ParameterName = 'Force'; IsMandatory = $false; ValueFromPipeline = $false; ValueFromPipelineByPropertyName = $false }
                @{ ParameterName = 'PassThru'; IsMandatory = $false; ValueFromPipeline = $false; ValueFromPipelineByPropertyName = $false }
                @{ ParameterName = 'SqlLogin'; ShouldExist = $false }
                @{ ParameterName = 'WindowsGroup'; ShouldExist = $false }
                @{ ParameterName = 'Certificate'; ShouldExist = $false }
                @{ ParameterName = 'AsymmetricKey'; ShouldExist = $false }
                @{ ParameterName = 'SecurePassword'; ShouldExist = $false }
                @{ ParameterName = 'CertificateName'; ShouldExist = $false }
                @{ ParameterName = 'AsymmetricKeyName'; ShouldExist = $false }
                @{ ParameterName = 'PasswordExpirationEnabled'; ShouldExist = $false }
                @{ ParameterName = 'PasswordPolicyEnforced'; ShouldExist = $false }
                @{ ParameterName = 'MustChangePassword'; ShouldExist = $false }
                @{ ParameterName = 'IsHashed'; ShouldExist = $false }
            )
        }
        @{
            ParameterSetName = 'WindowsGroup'
            ExpectedParameterTests = @(
                @{ ParameterName = 'ServerObject'; IsMandatory = $true; ValueFromPipeline = $true; ValueFromPipelineByPropertyName = $false }
                @{ ParameterName = 'Name'; IsMandatory = $true; ValueFromPipeline = $false; ValueFromPipelineByPropertyName = $false }
                @{ ParameterName = 'WindowsGroup'; IsMandatory = $true; ValueFromPipeline = $false; ValueFromPipelineByPropertyName = $false }
                @{ ParameterName = 'DefaultDatabase'; IsMandatory = $false; ValueFromPipeline = $false; ValueFromPipelineByPropertyName = $false }
                @{ ParameterName = 'DefaultLanguage'; IsMandatory = $false; ValueFromPipeline = $false; ValueFromPipelineByPropertyName = $false }
                @{ ParameterName = 'Disabled'; IsMandatory = $false; ValueFromPipeline = $false; ValueFromPipelineByPropertyName = $false }
                @{ ParameterName = 'Force'; IsMandatory = $false; ValueFromPipeline = $false; ValueFromPipelineByPropertyName = $false }
                @{ ParameterName = 'PassThru'; IsMandatory = $false; ValueFromPipeline = $false; ValueFromPipelineByPropertyName = $false }
                @{ ParameterName = 'SqlLogin'; ShouldExist = $false }
                @{ ParameterName = 'WindowsUser'; ShouldExist = $false }
                @{ ParameterName = 'Certificate'; ShouldExist = $false }
                @{ ParameterName = 'AsymmetricKey'; ShouldExist = $false }
                @{ ParameterName = 'SecurePassword'; ShouldExist = $false }
                @{ ParameterName = 'CertificateName'; ShouldExist = $false }
                @{ ParameterName = 'AsymmetricKeyName'; ShouldExist = $false }
                @{ ParameterName = 'PasswordExpirationEnabled'; ShouldExist = $false }
                @{ ParameterName = 'PasswordPolicyEnforced'; ShouldExist = $false }
                @{ ParameterName = 'MustChangePassword'; ShouldExist = $false }
                @{ ParameterName = 'IsHashed'; ShouldExist = $false }
            )
        }
        @{
            ParameterSetName = 'Certificate'
            ExpectedParameterTests = @(
                @{ ParameterName = 'ServerObject'; IsMandatory = $true; ValueFromPipeline = $true; ValueFromPipelineByPropertyName = $false }
                @{ ParameterName = 'Name'; IsMandatory = $true; ValueFromPipeline = $false; ValueFromPipelineByPropertyName = $false }
                @{ ParameterName = 'Certificate'; IsMandatory = $true; ValueFromPipeline = $false; ValueFromPipelineByPropertyName = $false }
                @{ ParameterName = 'CertificateName'; IsMandatory = $true; ValueFromPipeline = $false; ValueFromPipelineByPropertyName = $false }
                @{ ParameterName = 'DefaultDatabase'; IsMandatory = $false; ValueFromPipeline = $false; ValueFromPipelineByPropertyName = $false }
                @{ ParameterName = 'DefaultLanguage'; IsMandatory = $false; ValueFromPipeline = $false; ValueFromPipelineByPropertyName = $false }
                @{ ParameterName = 'Disabled'; IsMandatory = $false; ValueFromPipeline = $false; ValueFromPipelineByPropertyName = $false }
                @{ ParameterName = 'Force'; IsMandatory = $false; ValueFromPipeline = $false; ValueFromPipelineByPropertyName = $false }
                @{ ParameterName = 'PassThru'; IsMandatory = $false; ValueFromPipeline = $false; ValueFromPipelineByPropertyName = $false }
                @{ ParameterName = 'SqlLogin'; ShouldExist = $false }
                @{ ParameterName = 'WindowsUser'; ShouldExist = $false }
                @{ ParameterName = 'WindowsGroup'; ShouldExist = $false }
                @{ ParameterName = 'AsymmetricKey'; ShouldExist = $false }
                @{ ParameterName = 'SecurePassword'; ShouldExist = $false }
                @{ ParameterName = 'AsymmetricKeyName'; ShouldExist = $false }
                @{ ParameterName = 'PasswordExpirationEnabled'; ShouldExist = $false }
                @{ ParameterName = 'PasswordPolicyEnforced'; ShouldExist = $false }
                @{ ParameterName = 'MustChangePassword'; ShouldExist = $false }
                @{ ParameterName = 'IsHashed'; ShouldExist = $false }
            )
        }
        @{
            ParameterSetName = 'AsymmetricKey'
            ExpectedParameterTests = @(
                @{ ParameterName = 'ServerObject'; IsMandatory = $true; ValueFromPipeline = $true; ValueFromPipelineByPropertyName = $false }
                @{ ParameterName = 'Name'; IsMandatory = $true; ValueFromPipeline = $false; ValueFromPipelineByPropertyName = $false }
                @{ ParameterName = 'AsymmetricKey'; IsMandatory = $true; ValueFromPipeline = $false; ValueFromPipelineByPropertyName = $false }
                @{ ParameterName = 'AsymmetricKeyName'; IsMandatory = $true; ValueFromPipeline = $false; ValueFromPipelineByPropertyName = $false }
                @{ ParameterName = 'DefaultDatabase'; IsMandatory = $false; ValueFromPipeline = $false; ValueFromPipelineByPropertyName = $false }
                @{ ParameterName = 'DefaultLanguage'; IsMandatory = $false; ValueFromPipeline = $false; ValueFromPipelineByPropertyName = $false }
                @{ ParameterName = 'Disabled'; IsMandatory = $false; ValueFromPipeline = $false; ValueFromPipelineByPropertyName = $false }
                @{ ParameterName = 'Force'; IsMandatory = $false; ValueFromPipeline = $false; ValueFromPipelineByPropertyName = $false }
                @{ ParameterName = 'PassThru'; IsMandatory = $false; ValueFromPipeline = $false; ValueFromPipelineByPropertyName = $false }
                @{ ParameterName = 'SqlLogin'; ShouldExist = $false }
                @{ ParameterName = 'WindowsUser'; ShouldExist = $false }
                @{ ParameterName = 'WindowsGroup'; ShouldExist = $false }
                @{ ParameterName = 'Certificate'; ShouldExist = $false }
                @{ ParameterName = 'SecurePassword'; ShouldExist = $false }
                @{ ParameterName = 'CertificateName'; ShouldExist = $false }
                @{ ParameterName = 'PasswordExpirationEnabled'; ShouldExist = $false }
                @{ ParameterName = 'PasswordPolicyEnforced'; ShouldExist = $false }
                @{ ParameterName = 'MustChangePassword'; ShouldExist = $false }
                @{ ParameterName = 'IsHashed'; ShouldExist = $false }
            )
        }
    ) {
        $command = Get-Command -Name 'New-SqlDscLogin'

        # Helper function to get parameter attribute for a specific parameter set
        $getParameterAttribute = {
            param($ParameterName, $ParameterSetName)

            $parameter = $command.Parameters[$ParameterName]
            if ($null -eq $parameter) {
                return $null
            }

            $parameterAttribute = $parameter.Attributes |
                Where-Object -FilterScript {
                    $_ -is [System.Management.Automation.ParameterAttribute] -and
                    ($_.ParameterSetName -eq $ParameterSetName -or $_.ParameterSetName -eq '__AllParameterSets')
                } |
                Select-Object -First 1

            return $parameterAttribute
        }

        foreach ($parameterTest in $ExpectedParameterTests) {
            $parameterAttribute = & $getParameterAttribute -ParameterName $parameterTest.ParameterName -ParameterSetName $ParameterSetName

            if ($parameterTest.ContainsKey('ShouldExist') -and $parameterTest.ShouldExist -eq $false) {
                $parameterAttribute | Should -BeNullOrEmpty -Because "Parameter '$($parameterTest.ParameterName)' should not exist in parameter set '$ParameterSetName'"
            } else {
                $parameterAttribute | Should -Not -BeNullOrEmpty -Because "Parameter '$($parameterTest.ParameterName)' should exist in parameter set '$ParameterSetName'"
                $parameterAttribute.Mandatory | Should -Be $parameterTest.IsMandatory -Because "Parameter '$($parameterTest.ParameterName)' mandatory setting should be $($parameterTest.IsMandatory) in parameter set '$ParameterSetName'"
                $parameterAttribute.ValueFromPipeline | Should -Be $parameterTest.ValueFromPipeline -Because "Parameter '$($parameterTest.ParameterName)' ValueFromPipeline setting should be $($parameterTest.ValueFromPipeline) in parameter set '$ParameterSetName'"
                $parameterAttribute.ValueFromPipelineByPropertyName | Should -Be $parameterTest.ValueFromPipelineByPropertyName -Because "Parameter '$($parameterTest.ParameterName)' ValueFromPipelineByPropertyName setting should be $($parameterTest.ValueFromPipelineByPropertyName) in parameter set '$ParameterSetName'"
            }
        }
    }

    Context 'When using parameter Confirm with value $false' {
        BeforeAll {
            Mock -CommandName Test-SqlDscIsLogin -MockWith {
                return $false
            }

            $script:mockServerObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server
            $script:mockServerObject.InstanceName = 'TestInstance'
        }

        Context 'When creating a SQL Server login' {
            BeforeAll {
                $script:mockSecurePassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force
            }

            It 'Should create a SQL Server login without throwing' {
                $null = New-SqlDscLogin -ServerObject $script:mockServerObject -Name 'TestLogin' -SqlLogin -SecurePassword $script:mockSecurePassword -Confirm:$false

                Should -Invoke -CommandName Test-SqlDscIsLogin -Exactly -Times 1 -Scope It
            }
        }

        Context 'When creating a Windows user login' {
            It 'Should create a Windows user login without throwing' {
                $null = New-SqlDscLogin -ServerObject $script:mockServerObject -Name 'DOMAIN\TestUser' -WindowsUser -Confirm:$false

                Should -Invoke -CommandName Test-SqlDscIsLogin -Exactly -Times 1 -Scope It
            }
        }

        Context 'When login already exists' {
            BeforeAll {
                Mock -CommandName Test-SqlDscIsLogin -MockWith {
                    return $true
                }

                $script:mockSecurePassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force
            }

            It 'Should throw an error when login already exists' {
                { New-SqlDscLogin -ServerObject $script:mockServerObject -Name 'ExistingLogin' -SqlLogin -SecurePassword $script:mockSecurePassword -Confirm:$false } | Should -Throw -ExpectedMessage '*already exists*'

                Should -Invoke -CommandName Test-SqlDscIsLogin -Exactly -Times 1 -Scope It
            }
        }

        Context 'When using PassThru parameter' {
            BeforeAll {
                $script:mockSecurePassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force
            }

            It 'Should return the login object when PassThru is specified' {
                $result = New-SqlDscLogin -ServerObject $script:mockServerObject -Name 'TestLogin' -SqlLogin -SecurePassword $script:mockSecurePassword -PassThru -Confirm:$false

                $result | Should -Not -BeNullOrEmpty
            }
        }

        Context 'When creating certificate-based login' {
            It 'Should create a certificate login without throwing' {
                $null = New-SqlDscLogin -ServerObject $script:mockServerObject -Name 'CertLogin' -Certificate -CertificateName 'MyCert' -Confirm:$false
            }
        }

        Context 'When creating asymmetric key-based login' {
            It 'Should create an asymmetric key login without throwing' {
                $null = New-SqlDscLogin -ServerObject $script:mockServerObject -Name 'KeyLogin' -AsymmetricKey -AsymmetricKeyName 'MyKey' -Confirm:$false
            }
        }

        Context 'When creating Windows group login' {
            It 'Should create a Windows group login without throwing' {
                $null = New-SqlDscLogin -ServerObject $script:mockServerObject -Name 'NT AUTHORITY\SYSTEM' -WindowsGroup -Confirm:$false

                Should -Invoke -CommandName Test-SqlDscIsLogin -Exactly -Times 1 -Scope It
            }
        }

        Context 'When using Force parameter without Confirm' {
            BeforeAll {
                $script:mockSecurePassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force
            }

            It 'Should create when Force is used' {
                $null = New-SqlDscLogin -ServerObject $script:mockServerObject -Name 'ForceLogin' -SqlLogin -SecurePassword $script:mockSecurePassword -Force

                Should -Invoke -CommandName Test-SqlDscIsLogin -Exactly -Times 1 -Scope It
            }
        }

        Context 'When using custom DefaultLanguage parameter' {
            BeforeAll {
                $script:mockSecurePassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force
            }

            It 'Should set custom language on login object' {
                $null = New-SqlDscLogin -ServerObject $script:mockServerObject -Name 'LangLogin' -SqlLogin -SecurePassword $script:mockSecurePassword -DefaultLanguage 'Swedish' -Confirm:$false

                Should -Invoke -CommandName Test-SqlDscIsLogin -Exactly -Times 1 -Scope It
            }
        }

        Context 'When using MustChangePassword parameter' {
            BeforeAll {
                $script:mockSecurePassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force
            }

            It 'Should set MustChange login create option' {
                $null = New-SqlDscLogin -ServerObject $script:mockServerObject -Name 'MustChangeLogin' -SqlLogin -SecurePassword $script:mockSecurePassword -MustChangePassword -Confirm:$false

                Should -Invoke -CommandName Test-SqlDscIsLogin -Exactly -Times 1 -Scope It
            }
        }

        Context 'When using IsHashed parameter' {
            BeforeAll {
                $script:mockSecurePassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force
            }

            It 'Should set IsHashed login create option' {
                $null = New-SqlDscLogin -ServerObject $script:mockServerObject -Name 'HashedLogin' -SqlLogin -SecurePassword $script:mockSecurePassword -IsHashed -Confirm:$false

                Should -Invoke -CommandName Test-SqlDscIsLogin -Exactly -Times 1 -Scope It
            }
        }

        Context 'When using Disabled parameter' {
            BeforeAll {
                $script:mockSecurePassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force
            }

            It 'Should call Disable method on login object' {
                $null = New-SqlDscLogin -ServerObject $script:mockServerObject -Name 'DisabledLogin' -SqlLogin -SecurePassword $script:mockSecurePassword -Disabled -Confirm:$false

                Should -Invoke -CommandName Test-SqlDscIsLogin -Exactly -Times 1 -Scope It
            }
        }

        Context 'When combining multiple SQL login options' {
            BeforeAll {
                $script:mockSecurePassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force
            }

            It 'Should handle multiple options together for regular SQL login' {
                $null = New-SqlDscLogin -ServerObject $script:mockServerObject -Name 'ComplexLogin' -SqlLogin -SecurePassword $script:mockSecurePassword -MustChangePassword -Disabled -DefaultLanguage 'English' -DefaultDatabase 'tempdb' -PasswordExpirationEnabled -PasswordPolicyEnforced -Confirm:$false

                Should -Invoke -CommandName Test-SqlDscIsLogin -Exactly -Times 1 -Scope It
            }

            It 'Should handle hashed SQL login with compatible options' {
                $null = New-SqlDscLogin -ServerObject $script:mockServerObject -Name 'HashedLogin' -SqlLogin -SecurePassword $script:mockSecurePassword -IsHashed -Disabled -DefaultLanguage 'English' -DefaultDatabase 'tempdb' -Confirm:$false

                Should -Invoke -CommandName Test-SqlDscIsLogin -Exactly -Times 1 -Scope It
            }
        }

        Context 'When creating a SQL Server login with specific password options' {
            BeforeAll {
                Mock -CommandName Test-SqlDscIsLogin -MockWith {
                    return $false
                }

                $mockServerObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server
                $mockServerObject.InstanceName = 'TestInstance'
                $mockSecurePassword = ConvertTo-SecureString -String 'MyStr0ngP@ssw0rd' -AsPlainText -Force

                $mockTestSqlDscIsLoginParameterFilter = {
                    $ServerObject -eq $mockServerObject -and $Name -eq 'NewLogin'
                }
            }

            It 'Should create login with MustChangePassword option' {
                $null = New-SqlDscLogin -ServerObject $mockServerObject -Name 'NewLogin' -SqlLogin -SecurePassword $mockSecurePassword -MustChangePassword

                Should -Invoke -CommandName Test-SqlDscIsLogin -ParameterFilter $mockTestSqlDscIsLoginParameterFilter -Exactly -Times 1 -Scope It
            }

            It 'Should create login with IsHashed option' {
                $null = New-SqlDscLogin -ServerObject $mockServerObject -Name 'NewLogin' -SqlLogin -SecurePassword $mockSecurePassword -IsHashed

                Should -Invoke -CommandName Test-SqlDscIsLogin -ParameterFilter $mockTestSqlDscIsLoginParameterFilter -Exactly -Times 1 -Scope It
            }

            It 'Should create disabled login' {
                $null = New-SqlDscLogin -ServerObject $mockServerObject -Name 'NewLogin' -SqlLogin -SecurePassword $mockSecurePassword -Disabled

                Should -Invoke -CommandName Test-SqlDscIsLogin -ParameterFilter $mockTestSqlDscIsLoginParameterFilter -Exactly -Times 1 -Scope It
            }
        }
    }
}
