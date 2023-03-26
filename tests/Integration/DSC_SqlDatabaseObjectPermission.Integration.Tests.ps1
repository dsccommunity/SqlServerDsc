[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Suppressing this rule because Script Analyzer does not understand Pester syntax.')]
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
    $script:dscResourceFriendlyName = 'SqlDatabaseObjectPermission'
    $script:dscResourceName = "DSC_$($script:dscResourceFriendlyName)"
}

BeforeAll {
    # Need to define the variables here which will be used in Pester Run.
    $script:dscModuleName = 'SqlServerDsc'
    $script:dscResourceFriendlyName = 'SqlDatabaseObjectPermission'
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
        "$($script:dscResourceName)_Prerequisites_Table1_Config"
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
    }

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_Prerequisites_Procedure1_Config"
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
    }

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_Prerequisites_Procedure2_Config"
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
    }

    Context ('When using configuration <_>') -ForEach @(
        <#
            This is a regression test for issue #1602. The next test should
            replace the permission GrantWithGrant with the permission Grant.
        #>
        "$($script:dscResourceName)_Single_GrantWithGrant_Config"
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
            $resourceCurrentState.SchemaName | Should -Be $ConfigurationData.AllNodes.SchemaName
            $resourceCurrentState.ObjectName | Should -Be $ConfigurationData.AllNodes.TableName
            $resourceCurrentState.ObjectType | Should -Be 'Table'
            $resourceCurrentState.Name | Should -Be $ConfigurationData.AllNodes.User1_Name
            $resourceCurrentState.Force | Should -BeFalse

            $resourceCurrentState.Permission | Should -HaveCount 1
            $resourceCurrentState.Permission[0] | Should -BeOfType 'CimInstance'

            $grantPermission = $resourceCurrentState.Permission.Where( { $_.State -eq 'GrantWithGrant' })
            $grantPermission | Should -Not -BeNullOrEmpty
            $grantPermission.Ensure | Should -Be 'Present'
            $grantPermission.Permission | Should -HaveCount 1
            $grantPermission.Permission | Should -Contain @('Select')
        }

        It 'Should return $true when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should -Be 'True'
        }
    }

    Context ('When using configuration <_>') -ForEach @(
        <#
            This test is used for the previous regression test for issue #1602.
            This test should replace the previous test that set the permission
            GrantWithGrant with the permission Grant.
        #>
        "$($script:dscResourceName)_Single_Grant_Config"
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
            $resourceCurrentState.SchemaName | Should -Be $ConfigurationData.AllNodes.SchemaName
            $resourceCurrentState.ObjectName | Should -Be $ConfigurationData.AllNodes.TableName
            $resourceCurrentState.ObjectType | Should -Be 'Table'
            $resourceCurrentState.Name | Should -Be $ConfigurationData.AllNodes.User1_Name
            $resourceCurrentState.Force | Should -BeTrue

            $resourceCurrentState.Permission | Should -HaveCount 1
            $resourceCurrentState.Permission[0] | Should -BeOfType 'CimInstance'

            $grantPermission = $resourceCurrentState.Permission.Where( { $_.State -eq 'Grant' })
            $grantPermission | Should -Not -BeNullOrEmpty
            $grantPermission.Ensure | Should -Be 'Present'
            $grantPermission.Permission | Should -HaveCount 1
            $grantPermission.Permission | Should -Contain @('Select')
        }

        It 'Should return $true when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should -Be 'True'
        }
    }

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_Single_Revoke_Config"
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
            $resourceCurrentState.SchemaName | Should -Be $ConfigurationData.AllNodes.SchemaName
            $resourceCurrentState.ObjectName | Should -Be $ConfigurationData.AllNodes.TableName
            $resourceCurrentState.ObjectType | Should -Be 'Table'
            $resourceCurrentState.Name | Should -Be $ConfigurationData.AllNodes.User1_Name

            $resourceCurrentState.Permission | Should -HaveCount 1
            $resourceCurrentState.Permission[0] | Should -BeOfType 'CimInstance'

            $grantPermission = $resourceCurrentState.Permission.Where( { $_.State -eq 'Grant' })
            $grantPermission | Should -Not -BeNullOrEmpty
            $grantPermission.Ensure | Should -Be 'Absent'
            $grantPermission.Permission | Should -HaveCount 1
            $grantPermission.Permission | Should -Contain @('Select')
        }

        It 'Should return $true when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should -Be 'True'
        }
    }

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_Multiple_Grant_Config"
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
            $resourceCurrentState.SchemaName | Should -Be $ConfigurationData.AllNodes.SchemaName
            $resourceCurrentState.ObjectName | Should -Be $ConfigurationData.AllNodes.TableName
            $resourceCurrentState.ObjectType | Should -Be 'Table'
            $resourceCurrentState.Name | Should -Be $ConfigurationData.AllNodes.User1_Name

            $resourceCurrentState.Permission | Should -HaveCount 3
            $resourceCurrentState.Permission[0] | Should -BeOfType 'CimInstance'
            $resourceCurrentState.Permission[1] | Should -BeOfType 'CimInstance'
            $resourceCurrentState.Permission[2] | Should -BeOfType 'CimInstance'

            $grantPermission = $resourceCurrentState.Permission.Where( { $_.State -eq 'Grant' })
            $grantPermission | Should -Not -BeNullOrEmpty
            $grantPermission.Ensure | Should -Be 'Present'
            $grantPermission.Permission | Should -HaveCount 1
            $grantPermission.Permission | Should -Contain @('Select')

            $grantPermission = $resourceCurrentState.Permission.Where( { $_.State -eq 'Deny' })
            $grantPermission | Should -Not -BeNullOrEmpty
            $grantPermission.Ensure[0] | Should -Be 'Present'
            $grantPermission.Ensure[1] | Should -Be 'Present'
            $grantPermission.Permission | Should -HaveCount 2
            $grantPermission.Permission | Should -Contain @('Delete')
            $grantPermission.Permission | Should -Contain @('Alter')
        }

        It 'Should return $true when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should -Be 'True'
        }
    }

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_Multiple_Revoke_Config"
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
            $resourceCurrentState.SchemaName | Should -Be $ConfigurationData.AllNodes.SchemaName
            $resourceCurrentState.ObjectName | Should -Be $ConfigurationData.AllNodes.TableName
            $resourceCurrentState.ObjectType | Should -Be 'Table'
            $resourceCurrentState.Name | Should -Be $ConfigurationData.AllNodes.User1_Name

            $resourceCurrentState.Permission | Should -HaveCount 3
            $resourceCurrentState.Permission[0] | Should -BeOfType 'CimInstance'
            $resourceCurrentState.Permission[1] | Should -BeOfType 'CimInstance'
            $resourceCurrentState.Permission[2] | Should -BeOfType 'CimInstance'

            $grantPermission = $resourceCurrentState.Permission.Where( { $_.State -eq 'Grant' })
            $grantPermission | Should -Not -BeNullOrEmpty
            $grantPermission.Ensure | Should -Be 'Present'
            $grantPermission.Permission | Should -HaveCount 1
            $grantPermission.Permission | Should -Contain @('Select')

            $grantPermission = $resourceCurrentState.Permission.Where( { $_.State -eq 'Deny' })
            $grantPermission | Should -Not -BeNullOrEmpty
            $grantPermission.Ensure[0] | Should -Be 'Absent'
            $grantPermission.Ensure[1] | Should -Be 'Absent'
            $grantPermission.Permission | Should -HaveCount 2
            $grantPermission.Permission | Should -Contain @('Delete')
            $grantPermission.Permission | Should -Contain @('Alter')
        }

        It 'Should return $true when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should -Be 'True'
        }
    }
}
