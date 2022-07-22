[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Justification = 'because ConvertTo-SecureString is used to simplify the tests.')]
param ()

BeforeDiscovery {
    try
    {
        Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
    }

    <#
        Need to define that variables here to be used in the Pester Discover to
        build the ForEach-blocks.
    #>
    $script:dscResourceFriendlyName = 'SqlDatabasePermission'
    $script:dscResourceName = "DSC_$($script:dscResourceFriendlyName)"
}

BeforeAll {
    # Need to define the variables here which will be used in Pester Run.
    $script:dscModuleName = 'SqlServerDsc'
    $script:dscResourceFriendlyName = 'SqlDatabasePermission'
    $script:dscResourceName = "DSC_$($script:dscResourceFriendlyName)"

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Integration'

    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
    . $configFile
}

AfterAll {
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Describe "$($script:dscResourceName)_Integration" -Tag @('Integration_SQL2016', 'Integration_SQL2017', 'Integration_SQL2019') {
    BeforeAll {
        $resourceId = "[$($script:dscResourceFriendlyName)]Integration_Test"
    }

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_Grant_Config"
    ) {
        BeforeAll {
            $configurationName = $_
        }

        AfterAll {
            Wait-ForIdleLcm
        }

        It 'Should compile and apply the MOF without throwing' {
            {
                $configurationParameters = @{
                    OutputPath           = $TestDrive
                    # The variable $ConfigurationData was dot-sourced above.
                    ConfigurationData    = $ConfigurationData
                }

                & $configurationName @configurationParameters

                $startDscConfigurationParameters = @{
                    Path         = $TestDrive
                    ComputerName = 'localhost'
                    Wait         = $true
                    Verbose      = $true
                    Force        = $true
                    ErrorAction  = 'Stop'
                }

                Start-DscConfiguration @startDscConfigurationParameters
            } | Should -Not -Throw
        }

        It 'Should be able to call Get-DscConfiguration without throwing' {
            {
                $script:currentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop
            } | Should -Not -Throw
        }

        It 'Should have set the resource and all the parameters should match' {
            $resourceCurrentState = $script:currentConfiguration | Where-Object -FilterScript {
                $_.ConfigurationName -eq $configurationName `
                -and $_.ResourceId -eq $resourceId
            }

            $resourceCurrentState.ServerName | Should -Be $ConfigurationData.AllNodes.ServerName
            $resourceCurrentState.InstanceName | Should -Be $ConfigurationData.AllNodes.InstanceName
            $resourceCurrentState.DatabaseName | Should -Be $ConfigurationData.AllNodes.DatabaseName
            $resourceCurrentState.Name | Should -Be $ConfigurationData.AllNodes.User1_Name
            $resourceCurrentState.Permission | Should -HaveCount 3

            $grantState = $resourceCurrentState.Permission.Where({ $_.State -eq 'Grant' })

            $grantState.State | Should -Be 'Grant'
            $grantState.Permission | Should -HaveCount 3
            $grantState.Permission | Should -Contain 'Connect'
            $grantState.Permission | Should -Contain 'Select'
            $grantState.Permission | Should -Contain 'CreateTable'
        }

        It 'Should return $true when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should -Be 'True'
        }
    }

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_RemoveGrant_Config"
    ) {
        BeforeAll {
            $configurationName = $_
        }

        AfterAll {
            Wait-ForIdleLcm
        }

        It 'Should compile and apply the MOF without throwing' {
            {
                $configurationParameters = @{
                    OutputPath           = $TestDrive
                    # The variable $ConfigurationData was dot-sourced above.
                    ConfigurationData    = $ConfigurationData
                }

                & $configurationName @configurationParameters

                $startDscConfigurationParameters = @{
                    Path         = $TestDrive
                    ComputerName = 'localhost'
                    Wait         = $true
                    Verbose      = $true
                    Force        = $true
                    ErrorAction  = 'Stop'
                }

                Start-DscConfiguration @startDscConfigurationParameters
            } | Should -Not -Throw
        }

        It 'Should be able to call Get-DscConfiguration without throwing' {
            {
                $script:currentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop
            } | Should -Not -Throw
        }

        It 'Should have set the resource and all the parameters should match' {
            $resourceCurrentState = $script:currentConfiguration | Where-Object -FilterScript {
                $_.ConfigurationName -eq $configurationName `
                -and $_.ResourceId -eq $resourceId
            }

            $resourceCurrentState.ServerName | Should -Be $ConfigurationData.AllNodes.ServerName
            $resourceCurrentState.InstanceName | Should -Be $ConfigurationData.AllNodes.InstanceName
            $resourceCurrentState.DatabaseName | Should -Be $ConfigurationData.AllNodes.DatabaseName
            $resourceCurrentState.Name | Should -Be $ConfigurationData.AllNodes.User1_Name
            $resourceCurrentState.Permission | Should -HaveCount 3

            $grantState = $resourceCurrentState.Permission.Where({ $_.State -eq 'Grant' })

            $grantState.State | Should -Be 'Grant'
            $grantState.Permission | Should -HaveCount 1
            $grantState.Permission | Should -Contain 'Connect'
            $grantState.Permission | Should -Not -Contain 'Select'
            $grantState.Permission | Should -Not -Contain 'CreateTable'
        }

        It 'Should return $true when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should -Be 'True'
        }
    }

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_Deny_Config"
    ) {
        BeforeAll {
            $configurationName = $_
        }

        AfterAll {
            Wait-ForIdleLcm
        }

        It 'Should compile and apply the MOF without throwing' {
            {
                $configurationParameters = @{
                    OutputPath           = $TestDrive
                    # The variable $ConfigurationData was dot-sourced above.
                    ConfigurationData    = $ConfigurationData
                }

                & $configurationName @configurationParameters

                $startDscConfigurationParameters = @{
                    Path         = $TestDrive
                    ComputerName = 'localhost'
                    Wait         = $true
                    Verbose      = $true
                    Force        = $true
                    ErrorAction  = 'Stop'
                }

                Start-DscConfiguration @startDscConfigurationParameters
            } | Should -Not -Throw
        }

        It 'Should be able to call Get-DscConfiguration without throwing' {
            {
                $script:currentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop
            } | Should -Not -Throw
        }

        It 'Should have set the resource and all the parameters should match' {
            $resourceCurrentState = $script:currentConfiguration | Where-Object -FilterScript {
                $_.ConfigurationName -eq $configurationName `
                -and $_.ResourceId -eq $resourceId
            }

            $resourceCurrentState.ServerName | Should -Be $ConfigurationData.AllNodes.ServerName
            $resourceCurrentState.InstanceName | Should -Be $ConfigurationData.AllNodes.InstanceName
            $resourceCurrentState.DatabaseName | Should -Be $ConfigurationData.AllNodes.DatabaseName
            $resourceCurrentState.Name | Should -Be $ConfigurationData.AllNodes.User1_Name
            $resourceCurrentState.Permission | Should -HaveCount 3

            $grantState = $resourceCurrentState.Permission.Where({ $_.State -eq 'Grant' })

            $grantState.State | Should -Be 'Grant'
            $grantState.Permission | Should -HaveCount 1
            $grantState.Permission | Should -Contain 'Connect'

            $denyState = $resourceCurrentState.Permission.Where({ $_.State -eq 'Deny' })

            $denyState.State | Should -Be 'Deny'
            $denyState.Permission | Should -HaveCount 2
            $denyState.Permission | Should -Contain 'Select'
            $denyState.Permission | Should -Contain 'CreateTable'
        }

        It 'Should return $true when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should -Be 'True'
        }
    }

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_RemoveDeny_Config"
    ) {
        BeforeAll {
            $configurationName = $_
        }

        AfterAll {
            Wait-ForIdleLcm
        }

        It 'Should compile and apply the MOF without throwing' {
            {
                $configurationParameters = @{
                    OutputPath           = $TestDrive
                    # The variable $ConfigurationData was dot-sourced above.
                    ConfigurationData    = $ConfigurationData
                }

                & $configurationName @configurationParameters

                $startDscConfigurationParameters = @{
                    Path         = $TestDrive
                    ComputerName = 'localhost'
                    Wait         = $true
                    Verbose      = $true
                    Force        = $true
                    ErrorAction  = 'Stop'
                }

                Start-DscConfiguration @startDscConfigurationParameters
            } | Should -Not -Throw
        }

        It 'Should be able to call Get-DscConfiguration without throwing' {
            {
                $script:currentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop
            } | Should -Not -Throw
        }

        It 'Should have set the resource and all the parameters should match' {
            $resourceCurrentState = $script:currentConfiguration | Where-Object -FilterScript {
                $_.ConfigurationName -eq $configurationName `
                -and $_.ResourceId -eq $resourceId
            }

            $resourceCurrentState.ServerName | Should -Be $ConfigurationData.AllNodes.ServerName
            $resourceCurrentState.InstanceName | Should -Be $ConfigurationData.AllNodes.InstanceName
            $resourceCurrentState.DatabaseName | Should -Be $ConfigurationData.AllNodes.DatabaseName
            $resourceCurrentState.Name | Should -Be $ConfigurationData.AllNodes.User1_Name
            $resourceCurrentState.Permission | Should -HaveCount 3

            $grantState = $resourceCurrentState.Permission.Where({ $_.State -eq 'Grant' })

            $grantState.State | Should -Be 'Grant'
            $grantState.Permission | Should -HaveCount 1
            $grantState.Permission | Should -Contain 'Connect'

            $denyState = $resourceCurrentState.Permission.Where({ $_.State -eq 'Deny' })

            $denyState.State | Should -Be 'Deny'
            <#
                Using '-HaveCount 0' does not work as it returns the error
                'Expected an empty collection, but got collection with size 1 @($null).'
                even though the array is empty (does not contain oen item that is $null).
                Probably due to issue: https://github.com/pester/Pester/issues/1000
            #>
            $denyState.Permission | Should -BeNullOrEmpty
        }

        It 'Should return $true when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should -Be 'True'
        }
    }

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_GrantGuest_Config"
    ) {
        BeforeAll {
            $configurationName = $_
        }

        AfterAll {
            Wait-ForIdleLcm
        }

        It 'Should compile and apply the MOF without throwing' {
            {
                $configurationParameters = @{
                    OutputPath           = $TestDrive
                    # The variable $ConfigurationData was dot-sourced above.
                    ConfigurationData    = $ConfigurationData
                }

                & $configurationName @configurationParameters

                $startDscConfigurationParameters = @{
                    Path         = $TestDrive
                    ComputerName = 'localhost'
                    Wait         = $true
                    Verbose      = $true
                    Force        = $true
                    ErrorAction  = 'Stop'
                }

                Start-DscConfiguration @startDscConfigurationParameters
            } | Should -Not -Throw
        }

        It 'Should be able to call Get-DscConfiguration without throwing' {
            {
                $script:currentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop
            } | Should -Not -Throw
        }

        It 'Should have set the resource and all the parameters should match' {
            $resourceCurrentState = $script:currentConfiguration | Where-Object -FilterScript {
                $_.ConfigurationName -eq $configurationName `
                -and $_.ResourceId -eq $resourceId
            }

            $resourceCurrentState.ServerName | Should -Be $ConfigurationData.AllNodes.ServerName
            $resourceCurrentState.InstanceName | Should -Be $ConfigurationData.AllNodes.InstanceName
            $resourceCurrentState.DatabaseName | Should -Be $ConfigurationData.AllNodes.DatabaseName
            $resourceCurrentState.Name | Should -Be 'guest'
            $resourceCurrentState.Permission | Should -HaveCount 3

            $grantState = $resourceCurrentState.Permission.Where({ $_.State -eq 'Grant' })

            $grantState.State | Should -Be 'Grant'
            $grantState.Permission | Should -HaveCount 2
            $grantState.Permission | Should -Contain 'Connect'
            $grantState.Permission | Should -Contain 'Select'
        }

        It 'Should return $true when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should -Be 'True'
        }
    }

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_RemoveGrantGuest_Config"
    ) {
        BeforeAll {
            $configurationName = $_
        }

        AfterAll {
            Wait-ForIdleLcm
        }

        It 'Should compile and apply the MOF without throwing' {
            {
                $configurationParameters = @{
                    OutputPath           = $TestDrive
                    # The variable $ConfigurationData was dot-sourced above.
                    ConfigurationData    = $ConfigurationData
                }

                & $configurationName @configurationParameters

                $startDscConfigurationParameters = @{
                    Path         = $TestDrive
                    ComputerName = 'localhost'
                    Wait         = $true
                    Verbose      = $true
                    Force        = $true
                    ErrorAction  = 'Stop'
                }

                Start-DscConfiguration @startDscConfigurationParameters
            } | Should -Not -Throw
        }

        It 'Should be able to call Get-DscConfiguration without throwing' {
            {
                $script:currentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop
            } | Should -Not -Throw
        }

        It 'Should have set the resource and all the parameters should match' {
            $resourceCurrentState = $script:currentConfiguration | Where-Object -FilterScript {
                $_.ConfigurationName -eq $configurationName `
                -and $_.ResourceId -eq $resourceId
            }

            $resourceCurrentState.ServerName | Should -Be $ConfigurationData.AllNodes.ServerName
            $resourceCurrentState.InstanceName | Should -Be $ConfigurationData.AllNodes.InstanceName
            $resourceCurrentState.DatabaseName | Should -Be $ConfigurationData.AllNodes.DatabaseName
            $resourceCurrentState.Name | Should -Be 'guest'
            $resourceCurrentState.Permission | Should -HaveCount 3

            $grantState = $resourceCurrentState.Permission.Where({ $_.State -eq 'Grant' })

            $grantState.State | Should -Be 'Grant'
            $grantState.Permission | Should -HaveCount 1
            $grantState.Permission | Should -Contain 'Connect'
            $grantState.Permission | Should -Not -Contain 'Select'
        }

        It 'Should return $true when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should -Be 'True'
        }
    }

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_GrantPublic_Config"
    ) {
        BeforeAll {
            $configurationName = $_
        }

        AfterAll {
            Wait-ForIdleLcm
        }

        It 'Should compile and apply the MOF without throwing' {
            {
                $configurationParameters = @{
                    OutputPath           = $TestDrive
                    # The variable $ConfigurationData was dot-sourced above.
                    ConfigurationData    = $ConfigurationData
                }

                & $configurationName @configurationParameters

                $startDscConfigurationParameters = @{
                    Path         = $TestDrive
                    ComputerName = 'localhost'
                    Wait         = $true
                    Verbose      = $true
                    Force        = $true
                    ErrorAction  = 'Stop'
                }

                Start-DscConfiguration @startDscConfigurationParameters
            } | Should -Not -Throw
        }

        It 'Should be able to call Get-DscConfiguration without throwing' {
            {
                $script:currentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop
            } | Should -Not -Throw
        }

        It 'Should have set the resource and all the parameters should match' {
            $resourceCurrentState = $script:currentConfiguration | Where-Object -FilterScript {
                $_.ConfigurationName -eq $configurationName `
                -and $_.ResourceId -eq $resourceId
            }

            $resourceCurrentState.ServerName | Should -Be $ConfigurationData.AllNodes.ServerName
            $resourceCurrentState.InstanceName | Should -Be $ConfigurationData.AllNodes.InstanceName
            $resourceCurrentState.DatabaseName | Should -Be $ConfigurationData.AllNodes.DatabaseName
            $resourceCurrentState.Name | Should -Be 'public'
            $resourceCurrentState.Permission | Should -HaveCount 3

            $grantState = $resourceCurrentState.Permission.Where({ $_.State -eq 'Grant' })

            $grantState.State | Should -Be 'Grant'
            $grantState.Permission | Should -HaveCount 2
            $grantState.Permission | Should -Contain 'Connect'
            $grantState.Permission | Should -Contain 'Select'
        }

        It 'Should return $true when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should -Be 'True'
        }
    }

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_RemoveGrantPublic_Config"
    ) {
        BeforeAll {
            $configurationName = $_
        }

        AfterAll {
            Wait-ForIdleLcm
        }

        It 'Should compile and apply the MOF without throwing' {
            {
                $configurationParameters = @{
                    OutputPath           = $TestDrive
                    # The variable $ConfigurationData was dot-sourced above.
                    ConfigurationData    = $ConfigurationData
                }

                & $configurationName @configurationParameters

                $startDscConfigurationParameters = @{
                    Path         = $TestDrive
                    ComputerName = 'localhost'
                    Wait         = $true
                    Verbose      = $true
                    Force        = $true
                    ErrorAction  = 'Stop'
                }

                Start-DscConfiguration @startDscConfigurationParameters
            } | Should -Not -Throw
        }

        It 'Should be able to call Get-DscConfiguration without throwing' {
            {
                $script:currentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop
            } | Should -Not -Throw
        }

        It 'Should have set the resource and all the parameters should match' {
            $resourceCurrentState = $script:currentConfiguration | Where-Object -FilterScript {
                $_.ConfigurationName -eq $configurationName `
                -and $_.ResourceId -eq $resourceId
            }

            $resourceCurrentState.ServerName | Should -Be $ConfigurationData.AllNodes.ServerName
            $resourceCurrentState.InstanceName | Should -Be $ConfigurationData.AllNodes.InstanceName
            $resourceCurrentState.DatabaseName | Should -Be $ConfigurationData.AllNodes.DatabaseName
            $resourceCurrentState.Name | Should -Be 'public'
            $resourceCurrentState.Permission | Should -HaveCount 3

            $grantState = $resourceCurrentState.Permission.Where({ $_.State -eq 'Grant' })

            $grantState.State | Should -Be 'Grant'
            $grantState.Permission | Should -HaveCount 1
            $grantState.Permission | Should -Contain 'Connect'
            $grantState.Permission | Should -Not -Contain 'Select'
        }

        It 'Should return $true when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should -Be 'True'
        }
    }

    Context 'When using Invoke-DscResource' {
        BeforeAll {
            $mockDefaultInvokeDscResourceParameters = @{
                ModuleName = $script:dscModuleName
                Name       = $script:dscResourceFriendlyName
                Verbode    = $true
            }

            $mockSqlCredential = [System.Management.Automation.PSCredential]::new(
                $ConfigurationData.AllNodes.UserName,
                ($ConfigurationData.AllNodes.Password | ConvertTo-SecureString -AsPlainText -Force)
            )

            $mockDefaultInvokeDscResourceProperty = @{
                ServerName   = $ConfigurationData.AllNodes.ServerName
                InstanceName = $ConfigurationData.AllNodes.InstanceName
                DatabaseName = $ConfigurationData.AllNodes.DatabaseName
                Name         = $ConfigurationData.AllNodes.User1_Name
                Credential   = $mockSqlCredential
            }

            $mockDefaultNewCimInstanceParameters = @{
                ClientOnly = $true
                Namespace = 'root/Microsoft/Windows/DesiredStateConfiguration'
                ClassName = 'DatabasePermission'
            }
        }

        AfterEach {
            Wait-ForIdleLcm
        }

        Context 'When assigning parameter Permission' {
            Context 'When the system is not in the desired state' {
                It 'Should run method Get() and return the correct values' {
                    {
                        $mockInvokeDscResourceProperty = $mockDefaultInvokeDscResourceProperty.Clone()

                        $mockInvokeDscResourceProperty.Permission = [Microsoft.Management.Infrastructure.CimInstance[]] @(
                            (New-CimInstance @mockDefaultNewCimInstanceParameters -Property @{
                                State = 'Grant'
                                Permission = @(
                                    'connect',
                                    'update',
                                    'alter'
                                )
                            })
                            (New-CimInstance @mockDefaultNewCimInstanceParameters -Property @{
                                State = 'GrantWithGrant'
                                Permission = [System.String[]] @()
                            })
                            (New-CimInstance @mockDefaultNewCimInstanceParameters -Property @{
                                State = 'Deny'
                                Permission = [System.String[]] @()
                            })
                        )

                        $mockInvokeDscResourceParameters = $mockDefaultInvokeDscResourceParameters.Clone()

                        $mockInvokeDscResourceParameters.Method = 'Get'
                        $mockInvokeDscResourceParameters.Property = $mockInvokeDscResourceProperty

                        $script:resourceCurrentState = Invoke-DscResource @mockInvokeDscResourceParameters
                    } | Should -Not -Throw

                    $resourceCurrentState.ServerName | Should -Be $ConfigurationData.AllNodes.ServerName
                    $resourceCurrentState.InstanceName | Should -Be $ConfigurationData.AllNodes.InstanceName
                    $resourceCurrentState.DatabaseName | Should -Be $ConfigurationData.AllNodes.DatabaseName
                    $resourceCurrentState.Name | Should -Be $ConfigurationData.AllNodes.User1_Name
                    $resourceCurrentState.Permission | Should -HaveCount 3

                    $grantState = $resourceCurrentState.Permission.Where({ $_.State -eq 'Grant' })
                    $grantState.State | Should -Be 'Grant'
                    $grantState.Permission | Should -HaveCount 1
                    $grantState.Permission | Should -Contain 'Connect'

                    $grantWithGrantState = $resourceCurrentState.Permission.Where({ $_.State -eq 'GrantWithGrant' })
                    $grantWithGrantState.State | Should -Be 'GrantWithGrant'
                    $grantWithGrantState.Permission | Should -BeNullOrEmpty

                    $denyState = $resourceCurrentState.Permission.Where({ $_.State -eq 'Deny' })
                    $denyState.State | Should -Be 'Deny'
                    $denyState.Permission | Should -BeNullOrEmpty

                    # TODO: Make sure to test that this returns the correct output.
                    $grant.Reasons | Should -HaveCount 1
                }

                # It 'Should run method Test() and return the correct value' {
                #     Test-DscConfiguration -Verbose | Should -Be 'True'
                # }

                # It 'Should run method Set() without throwing' {
                #     {
                #         $configurationParameters = @{
                #             OutputPath           = $TestDrive
                #             # The variable $ConfigurationData was dot-sourced above.
                #             ConfigurationData    = $ConfigurationData
                #         }

                #         & $configurationName @configurationParameters

                #         $startDscConfigurationParameters = @{
                #             Path         = $TestDrive
                #             ComputerName = 'localhost'
                #             Wait         = $true
                #             Verbose      = $true
                #             Force        = $true
                #             ErrorAction  = 'Stop'
                #         }

                #         Start-DscConfiguration @startDscConfigurationParameters
                #     } | Should -Not -Throw
                # }
            }

            Context 'When the system is in the desired state' {
                # It 'Should run method Get() and return the correct values' {
                #     {
                #         $script:currentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop
                #     } | Should -Not -Throw

                #     $resourceCurrentState = $script:currentConfiguration | Where-Object -FilterScript {
                #         $_.ConfigurationName -eq $configurationName `
                #         -and $_.ResourceId -eq $resourceId
                #     }

                #     $resourceCurrentState.ServerName | Should -Be $ConfigurationData.AllNodes.ServerName
                #     $resourceCurrentState.InstanceName | Should -Be $ConfigurationData.AllNodes.InstanceName
                #     $resourceCurrentState.DatabaseName | Should -Be $ConfigurationData.AllNodes.DatabaseName
                #     $resourceCurrentState.Name | Should -Be 'public'
                #     $resourceCurrentState.Permission | Should -HaveCount 3

                #     $grantState = $resourceCurrentState.Permission.Where({ $_.State -eq 'Grant' })

                #     $grantState.State | Should -Be 'Grant'
                #     $grantState.Permission | Should -HaveCount 1
                #     $grantState.Permission | Should -Contain 'Connect'
                #     $grantState.Permission | Should -Not -Contain 'Select'
                # }

                # It 'Should run method Test() and return the correct value' {
                #     Test-DscConfiguration -Verbose | Should -Be 'True'
                # }

                # It 'Should run method Set() without throwing' {
                #     {
                #         $configurationParameters = @{
                #             OutputPath           = $TestDrive
                #             # The variable $ConfigurationData was dot-sourced above.
                #             ConfigurationData    = $ConfigurationData
                #         }

                #         & $configurationName @configurationParameters

                #         $startDscConfigurationParameters = @{
                #             Path         = $TestDrive
                #             ComputerName = 'localhost'
                #             Wait         = $true
                #             Verbose      = $true
                #             Force        = $true
                #             ErrorAction  = 'Stop'
                #         }

                #         Start-DscConfiguration @startDscConfigurationParameters
                #     } | Should -Not -Throw
                # }
            }
        }
    }
}
