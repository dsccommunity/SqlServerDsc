Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

if (-not (Test-BuildCategory -Type 'Integration' -Category @('Integration_SQL2016','Integration_SQL2017')))
{
    return
}

$script:dscModuleName = 'SqlServerDsc'
$script:dscResourceFriendlyName = 'SqlLogin'
$script:dscResourceName = "DSC_$($script:dscResourceFriendlyName)"

try
{
    Import-Module -Name DscResource.Test -Force -ErrorAction 'Stop'
}
catch [System.IO.FileNotFoundException]
{
    throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
}

$script:testEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:dscModuleName `
    -DSCResourceName $script:dscResourceName `
    -ResourceType 'Mof' `
    -TestType 'Integration'

try
{
    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
    . $configFile

     Describe "$($script:dscResourceName)_Integration" {
        BeforeAll {
            $resourceId = "[$($script:dscResourceFriendlyName)]Integration_Test"
        }

        $configurationName = "$($script:dscResourceName)_CreateDependencies_Config"

        <#
            This will install dependencies using other resource modules, and is
            done without running extra tests on the result.
            This is done to speed up testing.
        #>
        Context ('When using configuration {0}' -f $configurationName) {
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

        Wait-ForIdleLcm

        $configurationName = "$($script:dscResourceName)_AddLoginDscUser1_Config"

        Context ('When using configuration {0}' -f $configurationName) {
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

        Wait-ForIdleLcm

        $configurationName = "$($script:dscResourceName)_AddLoginDscUser2_Config"

        Context ('When using configuration {0}' -f $configurationName) {
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

        Wait-ForIdleLcm

        $configurationName = "$($script:dscResourceName)_AddLoginDscUser3_Disabled_Config"

        Context ('When using configuration {0}' -f $configurationName) {
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

        Wait-ForIdleLcm

        $configurationName = "$($script:dscResourceName)_AddLoginDscUser4_Config"

        Context ('When using configuration {0}' -f $configurationName) {
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

            It 'Should allow SQL Server, login username and password to connect to SQL Instance (using Connect-SQL)' {
                $serverName = $ConfigurationData.AllNodes.ServerName
                $instanceName = $ConfigurationData.AllNodes.InstanceName
                $userName = $ConfigurationData.AllNodes.DscUser4Name
                $password = $ConfigurationData.AllNodes.DscUser4Pass1 # Original password
                $sqlLoginCredential = New-Object `
                    -TypeName System.Management.Automation.PSCredential `
                    -ArgumentList @($userName, (ConvertTo-SecureString -String $password -AsPlainText -Force))

                { Connect-SQL -ServerName $ServerName -InstanceName $instanceName -SetupCredential $sqlLoginCredential -LoginType 'SqlLogin' -StatementTimeout 5 } | Should -Not -Throw
            }

            It 'Should allow SQL Server, login username and password to connect to SQL Instance (using SqlConnection.Open())' {
                $serverName = $ConfigurationData.AllNodes.ServerName
                $instanceName = $ConfigurationData.AllNodes.InstanceName
                $databaseName = $ConfigurationData.AllNodes.DefaultDbName
                $userName = $ConfigurationData.AllNodes.DscUser4Name
                $password = $ConfigurationData.AllNodes.DscUser4Pass1 # Original password

                $sqlConnectionString = 'Data Source={0}\{1};User ID={2};Password={3};Connect Timeout=5;Database={4};' -f $serverName, $instanceName, $userName, $password, $databaseName
                $sqlConnection = New-Object System.Data.SqlClient.SqlConnection $sqlConnectionString

                {
                    $sqlConnection.Open()
                    $sqlConnection.Close()
                } | Should -Not -Throw
            }

            It 'Should allow SQL Server, login username and password to correct, SQL instance, default database' {
                $serverName = $ConfigurationData.AllNodes.ServerName
                $instanceName = $ConfigurationData.AllNodes.InstanceName
                $userName = $ConfigurationData.AllNodes.DscUser4Name
                $password = $ConfigurationData.AllNodes.DscUser4Pass1 # Original password

                $sqlConnectionString = 'Data Source={0}\{1};User ID={2};Password={3};Connect Timeout=5;' -f $serverName, $instanceName, $userName, $password # Note: Not providing a database name
                $sqlConnection = New-Object System.Data.SqlClient.SqlConnection $sqlConnectionString
                $sqlCommand = New-Object System.Data.SqlClient.SqlCommand('SELECT DB_NAME() as CurrentDatabaseName', $sqlConnection)

                $sqlConnection.Open()
                $sqlDataAdapter = New-Object System.Data.SqlClient.SqlDataAdapter $sqlCommand
                $sqlDataSet = New-Object System.Data.DataSet
                $sqlDataAdapter.Fill($sqlDataSet) | Out-Null
                $sqlConnection.Close()

                $sqlDataSet.Tables[0].Rows[0].CurrentDatabaseName | Should -Be $ConfigurationData.AllNodes.DefaultDbName
            }
        }

        Wait-ForIdleLcm

        $configurationName = "$($script:dscResourceName)_UpdateLoginDscUser4_Config"

        Context ('When using configuration {0}' -f $configurationName) {
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
                $resourceCurrentState.LoginMustChangePassword | Should -Be $true
                $resourceCurrentState.LoginPasswordExpirationEnabled | Should -Be $false
                $resourceCurrentState.LoginPasswordPolicyEnforced | Should -Be $false
            }

            It 'Should return $true when Test-DscConfiguration is run' {
                Test-DscConfiguration -Verbose | Should -Be 'True'
            }


            It 'Should allow SQL Server, login username and (changed) password to connect to SQL Instance (using Connect-SQL)' {
                $serverName = $ConfigurationData.AllNodes.ServerName
                $instanceName = $ConfigurationData.AllNodes.InstanceName
                $userName = $ConfigurationData.AllNodes.DscUser4Name
                $password = $ConfigurationData.AllNodes.DscUser4Pass2 # Changed password
                $sqlLoginCredential = New-Object `
                    -TypeName System.Management.Automation.PSCredential `
                    -ArgumentList @($userName, (ConvertTo-SecureString -String $password -AsPlainText -Force))

                { Connect-SQL -ServerName $ServerName -InstanceName $instanceName -SetupCredential $sqlLoginCredential -LoginType 'SqlLogin' -StatementTimeout 5 } | Should -Not -Throw
            }

            It 'Should allow SQL Server, login username and (changed) password to connect to SQL Instance (using SqlConnection.Open())' {
                $serverName = $ConfigurationData.AllNodes.ServerName
                $instanceName = $ConfigurationData.AllNodes.InstanceName
                $databaseName = $ConfigurationData.AllNodes.DefaultDbName
                $userName = $ConfigurationData.AllNodes.DscUser4Name
                $password = $ConfigurationData.AllNodes.DscUser4Pass2 # Changed password

                $sqlConnectionString = 'Data Source={0}\{1};User ID={2};Password={3};Connect Timeout=5;Database={4};' -f $serverName, $instanceName, $userName, $password, $databaseName
                $sqlConnection = New-Object System.Data.SqlClient.SqlConnection $sqlConnectionString

                {
                    $sqlConnection.Open()
                    $sqlConnection.Close()
                } | Should -Not -Throw | Should -Not -Throw
            }

            It 'Should allow SQL Server, login username and (changed) password to correct, SQL instance, default database' {
                $serverName = $ConfigurationData.AllNodes.ServerName
                $instanceName = $ConfigurationData.AllNodes.InstanceName
                $userName = $ConfigurationData.AllNodes.DscUser4Name
                $password = $ConfigurationData.AllNodes.DscUser4Pass2 # Changed password

                $sqlConnectionString = 'Data Source={0}\{1};User ID={2};Password={3};Connect Timeout=5;' -f $serverName, $instanceName, $userName, $password # Note: Not providing a database name
                $sqlConnection = New-Object System.Data.SqlClient.SqlConnection $sqlConnectionString
                $sqlCommand = New-Object System.Data.SqlClient.SqlCommand('SELECT DB_NAME() as CurrentDatabaseName', $sqlConnection)

                $sqlConnection.Open()
                $sqlDataAdapter = New-Object System.Data.SqlClient.SqlDataAdapter $sqlCommand
                $sqlDataSet = New-Object System.Data.DataSet
                $sqlDataAdapter.Fill($sqlDataSet) | Out-Null
                $sqlConnection.Close()

                $sqlDataSet.Tables[0].Rows[0].CurrentDatabaseName | Should -Be $ConfigurationData.AllNodes.DefaultDbName
            }
        }

        Wait-ForIdleLcm

        $configurationName = "$($script:dscResourceName)_AddLoginDscSqlUsers1_Config"

        Context ('When using configuration {0}' -f $configurationName) {
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

        Wait-ForIdleLcm

        $configurationName = "$($script:dscResourceName)_RemoveLoginDscUser3_Config"

        Context ('When using configuration {0}' -f $configurationName) {
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

        Wait-ForIdleLcm

        $configurationName = "$($script:dscResourceName)_CleanupDependencies_Config"

        Context ('When using configuration {0}' -f $configurationName) {
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
}
finally
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}
