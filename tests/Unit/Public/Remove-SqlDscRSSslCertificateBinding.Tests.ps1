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
    $PSDefaultParameterValues['Should-Invoke:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Should-NotInvoke:ModuleName'] = $script:moduleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should-Invoke:ModuleName')
    $PSDefaultParameterValues.Remove('Should-NotInvoke:ModuleName')

    Remove-Item -Path 'env:SqlServerDscCI'
}

Describe 'Remove-SqlDscRSSslCertificateBinding' {
    BeforeAll {
        Mock -CommandName Get-OperatingSystem -MockWith {
            return [PSCustomObject] @{
                OSLanguage = 1033
            }
        }
    }

    Context 'When validating parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = '__AllParameterSets'
                ExpectedParameters = '[-Configuration] <Object> [-Application] <string> [-CertificateHash] <string> [[-IPAddress] <string>] [[-Port] <int>] [[-Lcid] <int>] [-PassThru] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Remove-SqlDscRSSslCertificateBinding').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should-Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should-Be $ExpectedParameters
        }
    }

    Context 'When removing SSL certificate binding successfully' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod
        }

        It 'Should remove SSL certificate binding without errors' {
            $mockCimInstance | Remove-SqlDscRSSslCertificateBinding -CertificateHash 'AABBCCDD' -Application 'ReportServerWebService' -Confirm:$false

            Should-Invoke -CommandName Invoke-RsCimMethod -Exactly -ParameterFilter {
                $MethodName -eq 'RemoveSSLCertificateBindings' -and
                $Arguments.CertificateHash -eq 'aabbccdd' -and
                $Arguments.Application -eq 'ReportServerWebService' -and
                $Arguments.IPAddress -eq '0.0.0.0' -and
                $Arguments.Port -eq 443 -and
                $Arguments.Lcid -eq 1033
            } -Times 1
        }

        It 'Should not return anything by default' {
            $result = $mockCimInstance | Remove-SqlDscRSSslCertificateBinding -CertificateHash 'AABBCCDD' -Application 'ReportServerWebService' -Confirm:$false

            $result | Should-BeFalsy
        }
    }

    Context 'When removing SSL certificate binding with custom parameters' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod
        }

        It 'Should use custom IP address and port' {
            $null = & ({ $mockCimInstance | Remove-SqlDscRSSslCertificateBinding -CertificateHash 'AABBCCDD' -Application 'ReportServerWebService' -IPAddress '192.168.1.1' -Port 8443 -Lcid 1031 -Confirm:$false })

            Should-Invoke -CommandName Invoke-RsCimMethod -Exactly -ParameterFilter {
                $Arguments.IPAddress -eq '192.168.1.1' -and
                $Arguments.Port -eq 8443 -and
                $Arguments.Lcid -eq 1031
            } -Times 1
        }
    }

    Context 'When removing SSL certificate binding with PassThru' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod
        }

        It 'Should return the configuration CIM instance' {
            $result = $mockCimInstance | Remove-SqlDscRSSslCertificateBinding -CertificateHash 'AABBCCDD' -Application 'ReportServerWebService' -PassThru -Confirm:$false

            $result | Should-BeTruthy
            $result.InstanceName | Should-Be 'SSRS'
        }
    }

    Context 'When removing SSL certificate binding with Force' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod
        }

        It 'Should remove SSL certificate binding without confirmation' {
            $null = & ({ $mockCimInstance | Remove-SqlDscRSSslCertificateBinding -CertificateHash 'AABBCCDD' -Application 'ReportServerWebService' -Force })

            Should-Invoke -CommandName Invoke-RsCimMethod -Exactly -Times 1
        }
    }

    Context 'When CIM method fails' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod -MockWith {
                throw 'Method RemoveSSLCertificateBindings() failed with an error.'
            }
        }

        It 'Should throw a terminating error' {
            { $mockCimInstance | Remove-SqlDscRSSslCertificateBinding -CertificateHash 'AABBCCDD' -Application 'ReportServerWebService' -Confirm:$false } | Should-Throw -FullyQualifiedErrorId 'RSRSSCB0001,Remove-SqlDscRSSslCertificateBinding'
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
            $mockCimInstance | Remove-SqlDscRSSslCertificateBinding -CertificateHash 'AABBCCDD' -Application 'ReportServerWebService' -WhatIf

            Should-Invoke -CommandName Invoke-RsCimMethod -Exactly -Times 0
        }
    }

    Context 'When passing configuration as parameter' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod
        }

        It 'Should remove SSL certificate binding' {
            $null = & ({ Remove-SqlDscRSSslCertificateBinding -Configuration $mockCimInstance -CertificateHash 'AABBCCDD' -Application 'ReportServerWebService' -Confirm:$false })

            Should-Invoke -CommandName Invoke-RsCimMethod -Exactly -Times 1
        }
    }
}
