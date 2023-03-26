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
    $script:dscResourceFriendlyName = 'SqlLogin'
    $script:dscResourceName = "DSC_$($script:dscResourceFriendlyName)"
}

BeforeAll {
    # Need to define the variables here which will be used in Pester Run.
    $script:dscModuleName = 'SqlServerDsc'
    $script:dscResourceFriendlyName = 'SqlLogin'
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

    <#
        This will install dependencies using other resource modules, and is
        done without running extra tests on the result.
        This is done to speed up testing.
    #>
    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_CreateDependencies_Config"
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
                    OutputPath        = $TestDrive
                    # The variable $ConfigurationData was dot-sourced above.
                    ConfigurationData = $ConfigurationData
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
        "$($script:dscResourceName)_AddLoginDscUser1_Config"
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
                    OutputPath                 = $TestDrive
                    # The variable $ConfigurationData was dot-sourced above.
                    ConfigurationData          = $ConfigurationData
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

            $resourceCurrentState.Ensure | Should -Be 'Present'
            $resourceCurrentState.Name | Should -Be $ConfigurationData.AllNodes.DscUser1Name
            $resourceCurrentState.LoginType | Should -Be $ConfigurationData.AllNodes.DscUser1Type
            $resourceCurrentState.Disabled | Should -Be $false
        }

        It 'Should return $true when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should -Be 'True'
        }
    }

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_AddLoginDscUser2_Config"
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
                    OutputPath                 = $TestDrive
                    # The variable $ConfigurationData was dot-sourced above.
                    ConfigurationData          = $ConfigurationData
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

            $resourceCurrentState.Ensure | Should -Be 'Present'
            $resourceCurrentState.Name | Should -Be $ConfigurationData.AllNodes.DscUser2Name
            $resourceCurrentState.LoginType | Should -Be $ConfigurationData.AllNodes.DscUser2Type
            $resourceCurrentState.DefaultDatabase | Should -Be $ConfigurationData.AllNodes.DefaultDbName
            $resourceCurrentState.Disabled | Should -Be $false
        }

        It 'Should return $true when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should -Be 'True'
        }
    }

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_AddLoginDscUser3_Disabled_Config"
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
                    OutputPath                 = $TestDrive
                    # The variable $ConfigurationData was dot-sourced above.
                    ConfigurationData          = $ConfigurationData
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

            $resourceCurrentState.Ensure | Should -Be 'Present'
            $resourceCurrentState.Name | Should -Be $ConfigurationData.AllNodes.DscUser3Name
            $resourceCurrentState.LoginType | Should -Be $ConfigurationData.AllNodes.DscUser3Type
            $resourceCurrentState.Disabled | Should -Be $true
        }

        It 'Should return $true when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should -Be 'True'
        }
    }

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_AddLoginDscUser4_Config"
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
                    OutputPath                 = $TestDrive
                    # The variable $ConfigurationData was dot-sourced above.
                    ConfigurationData          = $ConfigurationData
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

            $resourceCurrentState.Ensure | Should -Be 'Present'
            $resourceCurrentState.Name | Should -Be $ConfigurationData.AllNodes.DscUser4Name
            $resourceCurrentState.LoginType | Should -Be $ConfigurationData.AllNodes.DscUser4Type
            $resourceCurrentState.Disabled | Should -Be $false
            $resourceCurrentState.LoginMustChangePassword | Should -Be $false
            $resourceCurrentState.LoginPasswordExpirationEnabled | Should -Be $true
            $resourceCurrentState.LoginPasswordPolicyEnforced | Should -Be $true
        }

        It 'Should return $true when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should -Be 'True'
        }

        It 'Should allow SQL Server, login username and password to connect to SQL Instance (using SqlConnection.Open())' {
            $serverName = $ConfigurationData.AllNodes.ServerName
            $instanceName = $ConfigurationData.AllNodes.InstanceName
            $databaseName = $ConfigurationData.AllNodes.DefaultDbName
            $userName = $ConfigurationData.AllNodes.DscUser4Name
            $password = $ConfigurationData.AllNodes.DscUser4Pass1 # Original password

            $sqlConnectionString = 'Data Source={0}\{1};User ID={2};Password={3};Connect Timeout=5;Database={4};' -f $serverName, $instanceName, $userName, $password, $databaseName

            {
                $sqlConnection = New-Object System.Data.SqlClient.SqlConnection $sqlConnectionString
                $sqlConnection.Open()
                $sqlConnection.Close()
            } | Should -Not -Throw
        }

        It 'Should allow SQL Server, login username and password to connect to correct, SQL instance, default database' {
            $script:CurrentDatabaseName = $null

            $serverName = $ConfigurationData.AllNodes.ServerName
            $instanceName = $ConfigurationData.AllNodes.InstanceName
            $userName = $ConfigurationData.AllNodes.DscUser4Name
            $password = $ConfigurationData.AllNodes.DscUser4Pass1 # Original password

            $sqlConnectionString = 'Data Source={0}\{1};User ID={2};Password={3};Connect Timeout=5;' -f $serverName, $instanceName, $userName, $password # Note: Not providing a database name

            {
                $sqlConnection = New-Object System.Data.SqlClient.SqlConnection $sqlConnectionString
                $sqlCommand = New-Object System.Data.SqlClient.SqlCommand('SELECT DB_NAME() as CurrentDatabaseName', $sqlConnection)

                $sqlConnection.Open()
                $sqlDataAdapter = New-Object System.Data.SqlClient.SqlDataAdapter $sqlCommand
                $sqlDataSet = New-Object System.Data.DataSet
                $sqlDataAdapter.Fill($sqlDataSet) | Out-Null
                $sqlConnection.Close()

                $sqlDataSet.Tables[0].Rows[0].CurrentDatabaseName | Should -Be $ConfigurationData.AllNodes.DefaultDbName

                $script:CurrentDatabaseName = $sqlDataSet.Tables[0].Rows[0].CurrentDatabaseName
            } | Should -Not -Throw

            $script:CurrentDatabaseName | Should -Be $ConfigurationData.AllNodes.DefaultDbName

            $script:CurrentDatabaseName = $null
        }
    }

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_UpdateLoginDscUser4_Config"
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
                    OutputPath                 = $TestDrive
                    # The variable $ConfigurationData was dot-sourced above.
                    ConfigurationData          = $ConfigurationData
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

            $resourceCurrentState.Ensure | Should -Be 'Present'
            $resourceCurrentState.Name | Should -Be $ConfigurationData.AllNodes.DscUser4Name
            $resourceCurrentState.LoginType | Should -Be $ConfigurationData.AllNodes.DscUser4Type
            $resourceCurrentState.Disabled | Should -Be $false
            $resourceCurrentState.LoginMustChangePassword | Should -Be $false # Left the same as this cannot be updated
            $resourceCurrentState.LoginPasswordExpirationEnabled | Should -Be $false
            $resourceCurrentState.LoginPasswordPolicyEnforced | Should -Be $false
        }

        It 'Should return $true when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should -Be 'True'
        }

        It 'Should allow SQL Server, login username and (changed) password to connect to SQL Instance (using SqlConnection.Open())' {
            $serverName = $ConfigurationData.AllNodes.ServerName
            $instanceName = $ConfigurationData.AllNodes.InstanceName
            $databaseName = $ConfigurationData.AllNodes.DefaultDbName
            $userName = $ConfigurationData.AllNodes.DscUser4Name
            $password = $ConfigurationData.AllNodes.DscUser4Pass2 # Changed password

            $sqlConnectionString = 'Data Source={0}\{1};User ID={2};Password={3};Connect Timeout=5;Database={4};' -f $serverName, $instanceName, $userName, $password, $databaseName

            {
                $sqlConnection = New-Object System.Data.SqlClient.SqlConnection $sqlConnectionString
                $sqlConnection.Open()
                $sqlConnection.Close()
            } | Should -Not -Throw
        }

        It 'Should allow SQL Server, login username and (changed) password to connect to correct, SQL instance, default database' {
            $script:CurrentDatabaseName = $null

            $serverName = $ConfigurationData.AllNodes.ServerName
            $instanceName = $ConfigurationData.AllNodes.InstanceName
            $userName = $ConfigurationData.AllNodes.DscUser4Name
            $password = $ConfigurationData.AllNodes.DscUser4Pass2 # Changed password

            $sqlConnectionString = 'Data Source={0}\{1};User ID={2};Password={3};Connect Timeout=5;' -f $serverName, $instanceName, $userName, $password # Note: Not providing a database name

            {
                $sqlConnection = New-Object System.Data.SqlClient.SqlConnection $sqlConnectionString
                $sqlCommand = New-Object System.Data.SqlClient.SqlCommand('SELECT DB_NAME() as CurrentDatabaseName', $sqlConnection)

                $sqlConnection.Open()
                $sqlDataAdapter = New-Object System.Data.SqlClient.SqlDataAdapter $sqlCommand
                $sqlDataSet = New-Object System.Data.DataSet
                $sqlDataAdapter.Fill($sqlDataSet) | Out-Null
                $sqlConnection.Close()

                $sqlDataSet.Tables[0].Rows[0].CurrentDatabaseName | Should -Be $ConfigurationData.AllNodes.DefaultDbName

                $script:CurrentDatabaseName = $sqlDataSet.Tables[0].Rows[0].CurrentDatabaseName
            } | Should -Not -Throw

            $script:CurrentDatabaseName | Should -Be $ConfigurationData.AllNodes.DefaultDbName

            $script:CurrentDatabaseName = $null
        }
    }

    <#
        Note that this configuration has already been run within these Integration tests but is
        executed once more to reset the password back to the original one provided.
    #>
    Context ('When using configuration <_> (to update back to original password)') -ForEach @(
        "$($script:dscResourceName)_AddLoginDscUser4_Config"
    ) {
        BeforeAll {
            $configurationName = $_
        }

        AfterEach {
            Wait-ForIdleLcm
        }

        It 'Should re-compile and re-apply the MOF without throwing' {
            {
                $configurationParameters = @{
                    OutputPath                 = $TestDrive
                    # The variable $ConfigurationData was dot-sourced above.
                    ConfigurationData          = $ConfigurationData
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

        It 'Should return $true when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should -Be 'True'
        }

        It 'Should allow SQL Server, login username and password to connect to SQL Instance (using SqlConnection.Open())' {
            $serverName = $ConfigurationData.AllNodes.ServerName
            $instanceName = $ConfigurationData.AllNodes.InstanceName
            $databaseName = $ConfigurationData.AllNodes.DefaultDbName
            $userName = $ConfigurationData.AllNodes.DscUser4Name
            $password = $ConfigurationData.AllNodes.DscUser4Pass1 # Original password

            $sqlConnectionString = 'Data Source={0}\{1};User ID={2};Password={3};Connect Timeout=5;Database={4};' -f $serverName, $instanceName, $userName, $password, $databaseName

            {
                $sqlConnection = New-Object System.Data.SqlClient.SqlConnection $sqlConnectionString
                $sqlConnection.Open()
                $sqlConnection.Close()
            } | Should -Not -Throw
        }
    }

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_AddLoginDscUser5_DefaultValues_Config"
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
                    OutputPath                 = $TestDrive
                    # The variable $ConfigurationData was dot-sourced above.
                    ConfigurationData          = $ConfigurationData
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

            $resourceCurrentState.Ensure | Should -Be 'Present'
            $resourceCurrentState.Name | Should -Be $ConfigurationData.AllNodes.DscUser5Name
            $resourceCurrentState.LoginType | Should -Be $ConfigurationData.AllNodes.DscUser5Type
            $resourceCurrentState.Disabled | Should -Be $false
            $resourceCurrentState.LoginMustChangePassword | Should -BeFalse
            $resourceCurrentState.LoginPasswordExpirationEnabled | Should -BeFalse
            $resourceCurrentState.LoginPasswordPolicyEnforced | Should -BeFalse
        }

        It 'Should return $true when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should -Be 'True'
        }
    }

    <#
        Removing the user DscUser5 to be able to re add it with different configuration.
        At the end of the test it will be removed again permanently, and with a
        verification of properties from Get-TargetResource.
    #>
    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_RemoveLoginDscUser5_Config"
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
                    OutputPath                 = $TestDrive
                    # The variable $ConfigurationData was dot-sourced above.
                    ConfigurationData          = $ConfigurationData
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

        It 'Should return $true when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should -Be 'True'
        }
    }

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_AddLoginDscUser5_Set_LoginPasswordPolicyEnforced_Config"
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
                    OutputPath                 = $TestDrive
                    # The variable $ConfigurationData was dot-sourced above.
                    ConfigurationData          = $ConfigurationData
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

            $resourceCurrentState.Ensure | Should -Be 'Present'
            $resourceCurrentState.Name | Should -Be $ConfigurationData.AllNodes.DscUser5Name
            $resourceCurrentState.LoginType | Should -Be $ConfigurationData.AllNodes.DscUser5Type
            $resourceCurrentState.Disabled | Should -Be $false
            $resourceCurrentState.LoginMustChangePassword | Should -BeFalse
            $resourceCurrentState.LoginPasswordExpirationEnabled | Should -BeFalse
            $resourceCurrentState.LoginPasswordPolicyEnforced | Should -BeTrue
        }

        It 'Should return $true when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should -Be 'True'
        }
    }

    <#
        Removing the user DscUser5 to be able to re add it with different configuration.
        At the end of the test it will be removed again permanently, and with a
        verification of properties from Get-TargetResource.
    #>
    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_RemoveLoginDscUser5_Config"
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
                    OutputPath                 = $TestDrive
                    # The variable $ConfigurationData was dot-sourced above.
                    ConfigurationData          = $ConfigurationData
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

        It 'Should return $true when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should -Be 'True'
        }
    }

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_AddLoginDscUser5_Set_LoginPasswordExpirationEnabled_Config"
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
                    OutputPath                 = $TestDrive
                    # The variable $ConfigurationData was dot-sourced above.
                    ConfigurationData          = $ConfigurationData
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
            } | Should -Throw -ExpectedMessage '*The CHECK_EXPIRATION option cannot be used when CHECK_POLICY is OFF*'
        }
    }

    <#
        This adds the user DscUser5 with both LoginPasswordExpirationEnabled and
        LoginPasswordPolicyEnforced set to False. It will be used to test if the
        properties can be changed individually on an existing login.
    #>
    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_AddLoginDscUser5_Set_LoginPasswordExpirationEnabled_LoginPasswordPolicyEnforced_Config"
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
                    OutputPath                 = $TestDrive
                    # The variable $ConfigurationData was dot-sourced above.
                    ConfigurationData          = $ConfigurationData
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

            $resourceCurrentState.Ensure | Should -Be 'Present'
            $resourceCurrentState.Name | Should -Be $ConfigurationData.AllNodes.DscUser5Name
            $resourceCurrentState.LoginType | Should -Be $ConfigurationData.AllNodes.DscUser5Type
            $resourceCurrentState.Disabled | Should -Be $false
            $resourceCurrentState.LoginMustChangePassword | Should -BeFalse
            $resourceCurrentState.LoginPasswordExpirationEnabled | Should -BeTrue
            $resourceCurrentState.LoginPasswordPolicyEnforced | Should -BeTrue
        }

        It 'Should return $true when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should -Be 'True'
        }
    }

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_UpdateLoginDscUser5_Set_LoginPasswordExpirationEnabled_Config"
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
                    OutputPath                 = $TestDrive
                    # The variable $ConfigurationData was dot-sourced above.
                    ConfigurationData          = $ConfigurationData
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

            $resourceCurrentState.Ensure | Should -Be 'Present'
            $resourceCurrentState.Name | Should -Be $ConfigurationData.AllNodes.DscUser5Name
            $resourceCurrentState.LoginType | Should -Be $ConfigurationData.AllNodes.DscUser5Type
            $resourceCurrentState.Disabled | Should -Be $false
            $resourceCurrentState.LoginMustChangePassword | Should -BeFalse
            $resourceCurrentState.LoginPasswordExpirationEnabled | Should -BeFalse
            # This was set to true by the previous test.
            $resourceCurrentState.LoginPasswordPolicyEnforced | Should -BeTrue
        }

        It 'Should return $true when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should -Be 'True'
        }
    }

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_UpdateLoginDscUser5_Set_LoginPasswordPolicyEnforced_Config"
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
                    OutputPath                 = $TestDrive
                    # The variable $ConfigurationData was dot-sourced above.
                    ConfigurationData          = $ConfigurationData
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

            $resourceCurrentState.Ensure | Should -Be 'Present'
            $resourceCurrentState.Name | Should -Be $ConfigurationData.AllNodes.DscUser5Name
            $resourceCurrentState.LoginType | Should -Be $ConfigurationData.AllNodes.DscUser5Type
            $resourceCurrentState.Disabled | Should -Be $false
            $resourceCurrentState.LoginMustChangePassword | Should -BeFalse
            $resourceCurrentState.LoginPasswordExpirationEnabled | Should -BeFalse
            $resourceCurrentState.LoginPasswordPolicyEnforced | Should -BeFalse
        }

        It 'Should return $true when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should -Be 'True'
        }
    }

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_AddLoginDscSqlUsers1_Config"
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
                    OutputPath                 = $TestDrive
                    # The variable $ConfigurationData was dot-sourced above.
                    ConfigurationData          = $ConfigurationData
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

            $resourceCurrentState.Ensure | Should -Be 'Present'
            $resourceCurrentState.Name | Should -Be $ConfigurationData.AllNodes.DscSqlUsers1Name
            $resourceCurrentState.LoginType | Should -Be $ConfigurationData.AllNodes.DscSqlUsers1Type
            $resourceCurrentState.Disabled | Should -Be $false
        }

        It 'Should return $true when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should -Be 'True'
        }
    }

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_RemoveLoginDscUser3_Config"
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
                    OutputPath                 = $TestDrive
                    # The variable $ConfigurationData was dot-sourced above.
                    ConfigurationData          = $ConfigurationData
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

            $resourceCurrentState.Ensure | Should -Be 'Absent'
            $resourceCurrentState.Name | Should -Be $ConfigurationData.AllNodes.DscUser3Name
            $resourceCurrentState.LoginType | Should -BeNullOrEmpty
        }

        It 'Should return $true when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should -Be 'True'
        }
    }

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_RemoveLoginDscUser5_Config"
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
                    OutputPath                 = $TestDrive
                    # The variable $ConfigurationData was dot-sourced above.
                    ConfigurationData          = $ConfigurationData
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

            $resourceCurrentState.Ensure | Should -Be 'Absent'
            $resourceCurrentState.Name | Should -Be $ConfigurationData.AllNodes.DscUser5Name
            $resourceCurrentState.LoginType | Should -BeNullOrEmpty
        }

        It 'Should return $true when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should -Be 'True'
        }
    }

    Context 'When preparing database, dependencies cleanup' {
        BeforeAll {
            # Details used for database, dependency cleanup/preparation
            $serverName = $ConfigurationData.AllNodes.ServerName
            $instanceName = $ConfigurationData.AllNodes.InstanceName
            $userName = $ConfigurationData.AllNodes.DscUser4Name
            $password = $ConfigurationData.AllNodes.DscUser4Pass1 # Using original password
            $defaultDbName = $ConfigurationData.AllNodes.DefaultDbName
        }

        # Uses the variable from the BeforeAll-block to fill the default database name.
        It ('Should be able to take the "<defaultDbName>" database offline without throwing') {
            {
                # Take database offline (closing any existing connections and transactions) before it is dropped in subsequent, 'CleanupDependencies' configuration/test
                $sqlConnectionString = 'Data Source={0}\{1};User ID={2};Password={3};Connect Timeout=5;Database=master;' -f $serverName, $instanceName, $userName, $password
                $sqlConnection = New-Object System.Data.SqlClient.SqlConnection $sqlConnectionString
                $sqlStatement = 'ALTER DATABASE [{0}] SET OFFLINE WITH ROLLBACK IMMEDIATE' -f $defaultDbName
                $sqlCommand = New-Object System.Data.SqlClient.SqlCommand($sqlStatement, $sqlConnection)
                $sqlConnection.Open()
                $sqlCommand.ExecuteNonQuery()
                $sqlConnection.Close()
            } | Should -Not -Throw
        }
    }

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_CleanupDependencies_Config"
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
                    OutputPath = $TestDrive
                    # The variable $ConfigurationData was dot-sourced above.
                    ConfigurationData = $ConfigurationData
                }

                & $configurationName @configurationParameters

                $startDscConfigurationParameters = @{
                    Path = $TestDrive
                    ComputerName = 'localhost'
                    Wait = $true
                    Verbose = $true
                    Force = $true
                    ErrorAction = 'Stop'
                }

                Start-DscConfiguration @startDscConfigurationParameters
            } | Should -Not -Throw
        }
    }
}
