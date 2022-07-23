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

    <#
        These tests assumes that only permission left for test user 'User1' is
        a grant for permission 'Connect'.
    #>
    Context 'When using Invoke-DscResource' {
        BeforeAll {
            <#
                Clear any configuration that was applied by a previous test so that
                the configuration is not enforced by LCM while the tests using
                Invoke-DscResource are run.
            #>
            Clear-DscLcmConfiguration

            $mockDefaultInvokeDscResourceParameters = @{
                ModuleName = $script:dscModuleName
                Name       = $script:dscResourceFriendlyName
                Verbose    = $true
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
            Context 'When only specifying permissions for state Grant' {
                Context 'When the system is not in the desired state' {
                    BeforeAll {
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
                    }

                    It 'Should run method Get() and return the correct values' {
                        {
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
                        $resourceCurrentState.PermissionToInclude | Should -BeNullOrEmpty
                        $resourceCurrentState.PermissionToExclude | Should -BeNullOrEmpty

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

                        $resourceCurrentState.Reasons | Should -HaveCount 1
                        $resourceCurrentState.Reasons[0].Code | Should -Be 'SqlDatabasePermission:SqlDatabasePermission:Permission'
                        $resourceCurrentState.Reasons[0].Phrase | Should -Be 'The property Permission should be [{"State":"Grant","Permission":["connect","update","alter"]},{"State":"GrantWithGrant","Permission":[]},{"State":"Deny","Permission":[]}], but was [{"State":"Grant","Permission":["Connect"]},{"State":"GrantWithGrant","Permission":[]},{"State":"Deny","Permission":[]}]'

                        # TODO: Remove this
                        Write-Verbose -Verbose -Message ($resourceCurrentState.Reasons[0].Phrase | Out-String)
                    }

                    It 'Should run method Test() and return the state as $false' {
                        {
                            $mockInvokeDscResourceParameters = $mockDefaultInvokeDscResourceParameters.Clone()

                            $mockInvokeDscResourceParameters.Method = 'Test'
                            $mockInvokeDscResourceParameters.Property = $mockInvokeDscResourceProperty

                            $script:resourceCurrentState = Invoke-DscResource @mockInvokeDscResourceParameters
                        } | Should -Not -Throw

                        $resourceCurrentState.InDesiredState | Should -BeFalse
                    }

                    It 'Should run method Set() without throwing and not require reboot' {
                        {
                            $mockInvokeDscResourceParameters = $mockDefaultInvokeDscResourceParameters.Clone()

                            $mockInvokeDscResourceParameters.Method = 'Set'
                            $mockInvokeDscResourceParameters.Property = $mockInvokeDscResourceProperty

                            $script:resourceCurrentState = Invoke-DscResource @mockInvokeDscResourceParameters
                        } | Should -Not -Throw

                        $resourceCurrentState.RebootRequired | Should -BeFalse
                    }
                }

                Context 'When the system is not in the desired state' {
                    BeforeAll {
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
                    }

                    AfterAll {
                        <#
                            This will remove the module SqlServer from the session
                            after it was imported by a test below).
                        #>
                        Get-Module -Name 'SqlServer' -All | Remove-Module -Force
                    }

                    It 'Should run method Get() and return the correct values' {
                        {
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
                        $resourceCurrentState.PermissionToInclude | Should -BeNullOrEmpty
                        $resourceCurrentState.PermissionToExclude | Should -BeNullOrEmpty

                        $grantState = $resourceCurrentState.Permission.Where({ $_.State -eq 'Grant' })
                        $grantState.State | Should -Be 'Grant'
                        $grantState.Permission | Should -HaveCount 3
                        $grantState.Permission | Should -Contain 'Connect'
                        $grantState.Permission | Should -Contain 'Update'
                        $grantState.Permission | Should -Contain 'Alter'

                        $grantWithGrantState = $resourceCurrentState.Permission.Where({ $_.State -eq 'GrantWithGrant' })
                        $grantWithGrantState.State | Should -Be 'GrantWithGrant'
                        $grantWithGrantState.Permission | Should -BeNullOrEmpty

                        $denyState = $resourceCurrentState.Permission.Where({ $_.State -eq 'Deny' })
                        $denyState.State | Should -Be 'Deny'
                        $denyState.Permission | Should -BeNullOrEmpty

                        $resourceCurrentState.Reasons | Should -BeNullOrEmpty
                    }

                    It 'Should run method Test() and return the state as $true' {
                        {
                            $mockInvokeDscResourceParameters = $mockDefaultInvokeDscResourceParameters.Clone()

                            $mockInvokeDscResourceParameters.Method = 'Test'
                            $mockInvokeDscResourceParameters.Property = $mockInvokeDscResourceProperty

                            $script:resourceCurrentState = Invoke-DscResource @mockInvokeDscResourceParameters
                        } | Should -Not -Throw

                        $resourceCurrentState.InDesiredState | Should -BeTrue
                    }

                    # TODO: This is a duplicate with the next test, if the next test works, this should be removed.
                    It 'Should run method Set() without throwing and not require reboot' {
                        {
                            $mockInvokeDscResourceParameters = $mockDefaultInvokeDscResourceParameters.Clone()

                            $mockInvokeDscResourceParameters.Method = 'Set'
                            $mockInvokeDscResourceParameters.Property = $mockInvokeDscResourceProperty

                            $script:resourceCurrentState = Invoke-DscResource @mockInvokeDscResourceParameters
                        } | Should -Not -Throw

                        $resourceCurrentState.RebootRequired | Should -BeFalse
                    }

                    # TODO: This test is meant to show that Set does not call
                    It 'Should run method Set() without throwing and not require reboot' {
                        # Import the module SqlServer to the complex types can be parsed by Mock below.
                        Import-Module -Name 'SqlServer'

                        Mock -CommandName Set-SqlDscDatabasePermission -ModuleName $script:dscModuleName
                        # -MockWith {
                        #     throw 'The mock of command Set-SqlDscDatabasePermission was called by a code path, but the command Set-SqlDscDatabasePermission should not have been called by the test.'
                        # }

                        {
                            # TODO: Remove this
                            $mockInvokeDscResourceProperty.Permission[0].Permission += 'create'

                            $mockInvokeDscResourceParameters = $mockDefaultInvokeDscResourceParameters.Clone()

                            $mockInvokeDscResourceParameters.Method = 'Set'
                            $mockInvokeDscResourceParameters.Property = $mockInvokeDscResourceProperty

                            $script:resourceCurrentState = Invoke-DscResource @mockInvokeDscResourceParameters
                        } | Should -Not -Throw

                        $resourceCurrentState.RebootRequired | Should -BeFalse

                        Should -Not -Invoke -CommandName Set-SqlDscDatabasePermission -ModuleName $script:dscModuleName
                    }
                }
            }
        }
    }
}
