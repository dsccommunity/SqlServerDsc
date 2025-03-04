[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Suppressing this rule because Script Analyzer does not understand Pester syntax.')]
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Justification = 'because ConvertTo-SecureString is used to simplify the tests.')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies has been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies has not been resolved, this will throw an error.
            Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
        }
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
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

Describe "$($script:dscResourceName)_Integration" -Tag @('Integration_SQL2016', 'Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        $resourceId = "[$($script:dscResourceFriendlyName)]Integration_Test"
    }

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_Grant_Config"
    ) {
        BeforeAll {
            $configurationName = $_
        }

        AfterEach {
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

        AfterEach {
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

        AfterEach {
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

        AfterEach {
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

        AfterEach {
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

        AfterEach {
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

        AfterEach {
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

        AfterEach {
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

        <#
            The tests will leave Connect as granted permission.

            Test 1: Assigning the permissions Connect, Update, and Alter for the state
                    Grant.
                    Testing: Adding permission for state Grant, and testing to handle
                    the permission Connect that already exist from previous tests.

            Test 2: Assigning permission Delete and Update for the state Deny, and
                    permission Connect for the state Grant.
                    Testing: Adding permission for state Deny. From previous test
                    the permission Alter will be revoked, and the permission Update
                    will be moved from Grant to Deny.

            Test 3: Assigning permission Select for the state GrantWithGrant, and
                    permission Connect for the state Grant.
                    Testing: Adding permission for state GrantWithGrant. From previous
                    test the permission Delete and Update will be revoked.

            Test 4: Assigning permission Connect for the state Grant.
                    Testing: From previous test the permission Select will be revoked.
        #>
        Context 'When assigning parameter Permission' {
            <#
                Test 1: Assigning the permissions Connect, Update, and Alter for the state
                        Grant.
                        Testing: Adding permission for state Grant, and testing to handle
                        the permission Connect that already exist from previous tests.
            #>
            Context 'When only specifying permissions for state Grant' {
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

                Context 'When the system is not in the desired state' {
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

                Context 'When the system is in the desired state' {
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

                    <#
                        This test is meant to validate that method Set() also evaluates
                        the current state against the desired state, and if they match
                        the Set() method returns without calling Set-SqlDscDatabasePermission
                        to change permissions.

                        It is not possible to validate that Set-SqlDscDatabasePermission
                        is not call since it is not possible to mock the command in
                        the session when LCM runs (which Invoke-DscResource invokes).
                        There are no other indications that can be caught to validate
                        this, unless looking for the verbose output that says that
                        all properties are in desired state.
                    #>
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
            }

            <#
                Test 2: Assigning permission Delete and Update for the state Deny, and
                        permission Connect for the state Grant.
                        Testing: Adding permission for state Deny. From previous test
                        the permission Alter will be revoked, and the permission Update
                        will be moved from Grant to Deny.
            #>
            Context 'When only specifying permissions for state Deny' {
                BeforeAll {
                    $mockInvokeDscResourceProperty = $mockDefaultInvokeDscResourceProperty.Clone()

                    $mockInvokeDscResourceProperty.Permission = [Microsoft.Management.Infrastructure.CimInstance[]] @(
                        (New-CimInstance @mockDefaultNewCimInstanceParameters -Property @{
                            State = 'Grant'
                            Permission = @(
                                'connect'
                            )
                        })
                        (New-CimInstance @mockDefaultNewCimInstanceParameters -Property @{
                            State = 'GrantWithGrant'
                            Permission = [System.String[]] @()
                        })
                        (New-CimInstance @mockDefaultNewCimInstanceParameters -Property @{
                            State = 'Deny'
                            Permission = @(
                                'delete',
                                'update'
                            )
                        })
                    )
                }

                Context 'When the system is not in the desired state' {
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

                        $resourceCurrentState.Reasons | Should -HaveCount 1
                        $resourceCurrentState.Reasons[0].Code | Should -Be 'SqlDatabasePermission:SqlDatabasePermission:Permission'
                        $resourceCurrentState.Reasons[0].Phrase | Should -Be 'The property Permission should be [{"State":"Grant","Permission":["connect"]},{"State":"GrantWithGrant","Permission":[]},{"State":"Deny","Permission":["delete","update"]}], but was [{"State":"Grant","Permission":["alter","connect","update"]},{"State":"GrantWithGrant","Permission":[]},{"State":"Deny","Permission":[]}]'
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

                Context 'When the system is in the desired state' {
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
                        $denyState.Permission | Should -HaveCount 2
                        $denyState.Permission | Should -Contain 'Delete'
                        $denyState.Permission | Should -Contain 'Update'

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

                    <#
                        This test is meant to validate that method Set() also evaluates
                        the current state against the desired state, and if they match
                        the Set() method returns without calling Set-SqlDscDatabasePermission
                        to change permissions.

                        It is not possible to validate that Set-SqlDscDatabasePermission
                        is not call since it is not possible to mock the command in
                        the session when LCM runs (which Invoke-DscResource invokes).
                        There are no other indications that can be caught to validate
                        this, unless looking for the verbose output that says that
                        all properties are in desired state.
                    #>
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
            }

            <#
                Test 3: Assigning permission Select for the state GrantWithGrant, and
                        permission Connect for the state Grant.
                        Testing: Adding permission for state GrantWithGrant. From previous
                        test the permission Delete and Update will be revoked.
            #>
            Context 'When only specifying permissions for state GrantWithGrant' {
                BeforeAll {
                    $mockInvokeDscResourceProperty = $mockDefaultInvokeDscResourceProperty.Clone()

                    $mockInvokeDscResourceProperty.Permission = [Microsoft.Management.Infrastructure.CimInstance[]] @(
                        (New-CimInstance @mockDefaultNewCimInstanceParameters -Property @{
                            State = 'Grant'
                            Permission = @(
                                'connect'
                            )
                        })
                        (New-CimInstance @mockDefaultNewCimInstanceParameters -Property @{
                            State = 'GrantWithGrant'
                            Permission = @(
                                'select'
                            )
                        })
                        (New-CimInstance @mockDefaultNewCimInstanceParameters -Property @{
                            State = 'Deny'
                            Permission = [System.String[]] @()
                        })
                    )
                }

                Context 'When the system is not in the desired state' {
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
                        $denyState.Permission | Should -HaveCount 2
                        $denyState.Permission | Should -Contain 'Delete'
                        $denyState.Permission | Should -Contain 'Update'

                        $resourceCurrentState.Reasons | Should -HaveCount 1
                        $resourceCurrentState.Reasons[0].Code | Should -Be 'SqlDatabasePermission:SqlDatabasePermission:Permission'
                        $resourceCurrentState.Reasons[0].Phrase | Should -Be 'The property Permission should be [{"State":"Grant","Permission":["connect"]},{"State":"GrantWithGrant","Permission":["select"]},{"State":"Deny","Permission":[]}], but was [{"State":"Grant","Permission":["connect"]},{"State":"Deny","Permission":["delete","update"]},{"State":"GrantWithGrant","Permission":[]}]'
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

                Context 'When the system is in the desired state' {
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
                        $grantWithGrantState.Permission | Should -HaveCount 1
                        $grantWithGrantState.Permission | Should -Contain 'Select'

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

                    <#
                        This test is meant to validate that method Set() also evaluates
                        the current state against the desired state, and if they match
                        the Set() method returns without calling Set-SqlDscDatabasePermission
                        to change permissions.

                        It is not possible to validate that Set-SqlDscDatabasePermission
                        is not call since it is not possible to mock the command in
                        the session when LCM runs (which Invoke-DscResource invokes).
                        There are no other indications that can be caught to validate
                        this, unless looking for the verbose output that says that
                        all properties are in desired state.
                    #>
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
            }

            <#
                Test 4: Assigning permission Connect for the state Grant.
                        Testing: From previous test the permission Select will be revoked.
            #>
            Context 'When only specifying permissions for state Grant to revoke permission in state GrantWithGrant' {
                BeforeAll {
                    $mockInvokeDscResourceProperty = $mockDefaultInvokeDscResourceProperty.Clone()

                    $mockInvokeDscResourceProperty.Permission = [Microsoft.Management.Infrastructure.CimInstance[]] @(
                        (New-CimInstance @mockDefaultNewCimInstanceParameters -Property @{
                            State = 'Grant'
                            Permission = @(
                                'connect'
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

                Context 'When the system is not in the desired state' {
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
                        $grantWithGrantState.Permission | Should -HaveCount 1
                        $grantWithGrantState.Permission | Should -Contain 'Select'

                        $denyState = $resourceCurrentState.Permission.Where({ $_.State -eq 'Deny' })
                        $denyState.State | Should -Be 'Deny'
                        $denyState.Permission | Should -BeNullOrEmpty

                        $resourceCurrentState.Reasons | Should -HaveCount 1
                        $resourceCurrentState.Reasons[0].Code | Should -Be 'SqlDatabasePermission:SqlDatabasePermission:Permission'
                        $resourceCurrentState.Reasons[0].Phrase | Should -Be 'The property Permission should be [{"State":"Grant","Permission":["connect"]},{"State":"GrantWithGrant","Permission":[]},{"State":"Deny","Permission":[]}], but was [{"State":"Grant","Permission":["connect"]},{"State":"GrantWithGrant","Permission":["select"]},{"State":"Deny","Permission":[]}]'
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

                Context 'When the system is in the desired state' {
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

                    <#
                        This test is meant to validate that method Set() also evaluates
                        the current state against the desired state, and if they match
                        the Set() method returns without calling Set-SqlDscDatabasePermission
                        to change permissions.

                        It is not possible to validate that Set-SqlDscDatabasePermission
                        is not call since it is not possible to mock the command in
                        the session when LCM runs (which Invoke-DscResource invokes).
                        There are no other indications that can be caught to validate
                        this, unless looking for the verbose output that says that
                        all properties are in desired state.
                    #>
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
            }
        }

        <#
            The tests for PermissionToExclude after this Context-block is dependent
            on that this test leaves the expected permission. If these tests for
            PermissionToInclude is changed, make sure the tests for PermissionToExclude
            is updated as necessary as well.

            Test 1: Assigning the permission Update to state Grant, and the
                    permission Select to the state GrantWithGrant, and the
                    permission Delete to the state Deny.
                    Testing: Adding permission to all states, and testing to handle
                    the permission Connect that already exist from previous tests.
        #>
        Context 'When assigning parameter PermissionToInclude' {
            # Test 1
            Context 'When only specifying permissions for state Grant' {
                BeforeAll {
                    $mockInvokeDscResourceProperty = $mockDefaultInvokeDscResourceProperty.Clone()

                    $mockInvokeDscResourceProperty.PermissionToInclude = [Microsoft.Management.Infrastructure.CimInstance[]] @(
                        (New-CimInstance @mockDefaultNewCimInstanceParameters -Property @{
                            State = 'Grant'
                            Permission = @(
                                'update'
                            )
                        })
                        (New-CimInstance @mockDefaultNewCimInstanceParameters -Property @{
                            State = 'GrantWithGrant'
                            Permission = @(
                                'select'
                            )
                        })
                        (New-CimInstance @mockDefaultNewCimInstanceParameters -Property @{
                            State = 'Deny'
                            Permission = @(
                                'delete'
                            )
                        })
                    )
                }

                Context 'When the system is not in the desired state' {
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
                        $resourceCurrentState.PermissionToExclude | Should -BeNullOrEmpty

                        # Property Permission
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

                        # Property PermissionToInclude
                        $grantState = $resourceCurrentState.PermissionToInclude.Where({ $_.State -eq 'Grant' })
                        $grantState.State | Should -Be 'Grant'
                        $grantState.Permission | Should -BeNullOrEmpty

                        $grantWithGrantState = $resourceCurrentState.PermissionToInclude.Where({ $_.State -eq 'GrantWithGrant' })
                        $grantWithGrantState.State | Should -Be 'GrantWithGrant'
                        $grantWithGrantState.Permission | Should -BeNullOrEmpty

                        $denyState = $resourceCurrentState.PermissionToInclude.Where({ $_.State -eq 'Deny' })
                        $denyState.State | Should -Be 'Deny'
                        $denyState.Permission | Should -BeNullOrEmpty

                        # Property Reasons
                        $resourceCurrentState.Reasons | Should -HaveCount 1
                        $resourceCurrentState.Reasons[0].Code | Should -Be 'SqlDatabasePermission:SqlDatabasePermission:PermissionToInclude'
                        $resourceCurrentState.Reasons[0].Phrase | Should -Be 'The property PermissionToInclude should be [{"State":"Grant","Permission":["update"]},{"State":"GrantWithGrant","Permission":["select"]},{"State":"Deny","Permission":["delete"]}], but was [{"State":"Grant","Permission":[]},{"State":"GrantWithGrant","Permission":[]},{"State":"Deny","Permission":[]}]'
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

                Context 'When the system is in the desired state' {
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
                        $resourceCurrentState.PermissionToExclude | Should -BeNullOrEmpty

                        # Property Permission
                        $grantState = $resourceCurrentState.Permission.Where({ $_.State -eq 'Grant' })
                        $grantState.State | Should -Be 'Grant'
                        $grantState.Permission | Should -HaveCount 2
                        $grantState.Permission | Should -Contain 'Connect'
                        $grantState.Permission | Should -Contain 'Update'

                        $grantWithGrantState = $resourceCurrentState.Permission.Where({ $_.State -eq 'GrantWithGrant' })
                        $grantWithGrantState.State | Should -Be 'GrantWithGrant'
                        $grantWithGrantState.Permission | Should -HaveCount 1
                        $grantWithGrantState.Permission | Should -Contain 'Select'

                        $denyState = $resourceCurrentState.Permission.Where({ $_.State -eq 'Deny' })
                        $denyState.State | Should -Be 'Deny'
                        $denyState.Permission | Should -HaveCount 1
                        $denyState.Permission | Should -Contain 'Delete'

                        # Property PermissionToInclude
                        $grantState = $resourceCurrentState.PermissionToInclude.Where({ $_.State -eq 'Grant' })
                        $grantState.State | Should -Be 'Grant'
                        $grantState.Permission | Should -HaveCount 1
                        $grantState.Permission | Should -Contain 'Update'

                        $grantWithGrantState = $resourceCurrentState.PermissionToInclude.Where({ $_.State -eq 'GrantWithGrant' })
                        $grantWithGrantState.State | Should -Be 'GrantWithGrant'
                        $grantWithGrantState.Permission | Should -HaveCount 1
                        $grantWithGrantState.Permission | Should -Contain 'Select'

                        $denyState = $resourceCurrentState.PermissionToInclude.Where({ $_.State -eq 'Deny' })
                        $denyState.State | Should -Be 'Deny'
                        $denyState.Permission | Should -HaveCount 1
                        $denyState.Permission | Should -Contain 'Delete'

                        # Property Reasons
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

                    <#
                        This test is meant to validate that method Set() also evaluates
                        the current state against the desired state, and if they match
                        the Set() method returns without calling Set-SqlDscDatabasePermission
                        to change permissions.

                        It is not possible to validate that Set-SqlDscDatabasePermission
                        is not call since it is not possible to mock the command in
                        the session when LCM runs (which Invoke-DscResource invokes).
                        There are no other indications that can be caught to validate
                        this, unless looking for the verbose output that says that
                        all properties are in desired state.
                    #>
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
            }
        }

        <#
            The tests will leave Connect as granted permission for the principal.

            Test 1: Revoking the permission Update for state Grant, and the
                    permission Select for the state GrantWithGrant, and the
                    permission Delete for the state Deny.
                    Testing: Revoking permission to all states, and testing that
                    the permission Connect is left in state Grant.
        #>
        Context 'When assigning parameter PermissionToExclude' {
            # Test 1
            Context 'When only specifying permissions for state Grant' {
                BeforeAll {
                    $mockInvokeDscResourceProperty = $mockDefaultInvokeDscResourceProperty.Clone()

                    $mockInvokeDscResourceProperty.PermissionToExclude = [Microsoft.Management.Infrastructure.CimInstance[]] @(
                        (New-CimInstance @mockDefaultNewCimInstanceParameters -Property @{
                            State = 'Grant'
                            Permission = @(
                                'update'
                            )
                        })
                        (New-CimInstance @mockDefaultNewCimInstanceParameters -Property @{
                            State = 'GrantWithGrant'
                            Permission = @(
                                'select'
                            )
                        })
                        (New-CimInstance @mockDefaultNewCimInstanceParameters -Property @{
                            State = 'Deny'
                            Permission = @(
                                'delete'
                            )
                        })
                    )
                }

                Context 'When the system is not in the desired state' {
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

                        # Property Permission
                        $grantState = $resourceCurrentState.Permission.Where({ $_.State -eq 'Grant' })
                        $grantState.State | Should -Be 'Grant'
                        $grantState.Permission | Should -HaveCount 2
                        $grantState.Permission | Should -Contain 'Connect'
                        $grantState.Permission | Should -Contain 'Update'

                        $grantWithGrantState = $resourceCurrentState.Permission.Where({ $_.State -eq 'GrantWithGrant' })
                        $grantWithGrantState.State | Should -Be 'GrantWithGrant'
                        $grantWithGrantState.Permission | Should -HaveCount 1
                        $grantWithGrantState.Permission | Should -Contain 'Select'

                        $denyState = $resourceCurrentState.Permission.Where({ $_.State -eq 'Deny' })
                        $denyState.State | Should -Be 'Deny'
                        $denyState.Permission | Should -HaveCount 1
                        $denyState.Permission | Should -Contain 'Delete'

                        # Property PermissionToExclude
                        $grantState = $resourceCurrentState.PermissionToExclude.Where({ $_.State -eq 'Grant' })
                        $grantState.State | Should -Be 'Grant'
                        $grantState.Permission | Should -BeNullOrEmpty

                        $grantWithGrantState = $resourceCurrentState.PermissionToExclude.Where({ $_.State -eq 'GrantWithGrant' })
                        $grantWithGrantState.State | Should -Be 'GrantWithGrant'
                        $grantWithGrantState.Permission | Should -BeNullOrEmpty

                        $denyState = $resourceCurrentState.PermissionToExclude.Where({ $_.State -eq 'Deny' })
                        $denyState.State | Should -Be 'Deny'
                        $denyState.Permission | Should -BeNullOrEmpty

                        # Property Reasons
                        $resourceCurrentState.Reasons | Should -HaveCount 1
                        $resourceCurrentState.Reasons[0].Code | Should -Be 'SqlDatabasePermission:SqlDatabasePermission:PermissionToExclude'
                        $resourceCurrentState.Reasons[0].Phrase | Should -Be 'The property PermissionToExclude should be [{"State":"Grant","Permission":["update"]},{"State":"GrantWithGrant","Permission":["select"]},{"State":"Deny","Permission":["delete"]}], but was [{"State":"Grant","Permission":[]},{"State":"GrantWithGrant","Permission":[]},{"State":"Deny","Permission":[]}]'
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

                Context 'When the system is in the desired state' {
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

                        # Property Permission
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

                        # Property PermissionToExclude
                        $grantState = $resourceCurrentState.PermissionToExclude.Where({ $_.State -eq 'Grant' })
                        $grantState.State | Should -Be 'Grant'
                        $grantState.Permission | Should -HaveCount 1
                        $grantState.Permission | Should -Contain 'Update'

                        $grantWithGrantState = $resourceCurrentState.PermissionToExclude.Where({ $_.State -eq 'GrantWithGrant' })
                        $grantWithGrantState.State | Should -Be 'GrantWithGrant'
                        $grantWithGrantState.Permission | Should -HaveCount 1
                        $grantWithGrantState.Permission | Should -Contain 'Select'

                        $denyState = $resourceCurrentState.PermissionToExclude.Where({ $_.State -eq 'Deny' })
                        $denyState.State | Should -Be 'Deny'
                        $denyState.Permission | Should -HaveCount 1
                        $denyState.Permission | Should -Contain 'Delete'

                        # Property Reasons
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

                    <#
                        This test is meant to validate that method Set() also evaluates
                        the current state against the desired state, and if they match
                        the Set() method returns without calling Set-SqlDscDatabasePermission
                        to change permissions.

                        It is not possible to validate that Set-SqlDscDatabasePermission
                        is not call since it is not possible to mock the command in
                        the session when LCM runs (which Invoke-DscResource invokes).
                        There are no other indications that can be caught to validate
                        this, unless looking for the verbose output that says that
                        all properties are in desired state.
                    #>
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
            }
        }
    }
}
