# This is used to make sure the integration test run in the correct order.
[Microsoft.DscResourceKit.IntegrationTest(OrderNumber = 2)]
param()

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

if (Test-SkipContinuousIntegrationTask -Type 'Integration')
{
    return
}

$script:dscModuleName = 'SqlServerDsc'
$script:dscResourceFriendlyName = 'SqlAlwaysOnService'
$script:dscResourceName = "MSFT_$($script:dscResourceFriendlyName)"

#region HEADER
# Integration Test Template Version: 1.1.2
[System.String] $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:dscModuleName `
    -DSCResourceName $script:dscResourceName `
    -TestType Integration

#endregion

$testRootFolderPath = Split-Path -Path $PSScriptRoot -Parent
Import-Module -Name (Join-Path -Path $testRootFolderPath -ChildPath (Join-Path -Path 'TestHelpers' -ChildPath 'CommonTestHelper.psm1')) -Force

$mockSqlInstallAccountPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force
$mockSqlInstallAccountUserName = "$env:COMPUTERNAME\SqlInstall"
$mockSqlInstallCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $mockSqlInstallAccountUserName, $mockSqlInstallAccountPassword

try
{
    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
    . $configFile

    # These sets variables used for verification from the dot-sourced $ConfigurationData variable.
    $mockLoopbackAdapterName = $ConfigurationData.AllNodes.LoopbackAdapterName

    <#
        Create the loopback adapter to be used with the cluster.
        The loopback adapter is kept on the build worker after test finishes
        so that the cluster is available.
        The IP address of the loopback adapter is set in the dependencies
        configuration.
    #>
    New-IntegrationLoopbackAdapter -AdapterName $mockLoopbackAdapterName

    Describe "$($script:dscResourceName)_Integration" {
        BeforeAll {
            $resourceId = "[$($script:dscResourceFriendlyName)]Integration_Test"
        }

        $configurationName = "$($script:dscResourceName)_CreateDependencies_Config"

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

        $configurationName = "$($script:dscResourceName)_EnableAlwaysOn_Config"

        Context ('When using configuration {0}' -f $configurationName) {
            It 'Should compile and apply the MOF without throwing' {
                {
                    $configurationParameters = @{
                        SqlInstallCredential = $mockSqlInstallCredential
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

            It 'Should be able to call Get-DscConfiguration without throwing' {
                {
                    $script:currentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop
                } | Should -Not -Throw
            }

            It 'Should have set the resource and all the parameters should match' {
                $resourceCurrentState = $script:currentConfiguration | Where-Object -FilterScript {
                    $_.ConfigurationName -eq $configurationName
                } | Where-Object -FilterScript {
                    $_.ResourceId -eq $resourceId
                }

                $resourceCurrentState.IsHadrEnabled | Should -Be $true
            }
        }

        $configurationName = "$($script:dscResourceName)_DisableAlwaysOn_Config"

        Context ('When using configuration {0}' -f $configurationName) {
            It 'Should compile and apply the MOF without throwing' {
                {
                    $configurationParameters = @{
                        SqlInstallCredential = $mockSqlInstallCredential
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

            It 'Should be able to call Get-DscConfiguration without throwing' {
                {
                    $script:currentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop
                } | Should -Not -Throw
            }

            It 'Should have set the resource and all the parameters should match' {
                $resourceCurrentState = $script:currentConfiguration | Where-Object -FilterScript {
                    $_.ConfigurationName -eq $configurationName
                } | Where-Object -FilterScript {
                    $_.ResourceId -eq $resourceId
                }

                $resourceCurrentState.IsHadrEnabled | Should -Be $false
            }
        }

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
    #region FOOTER

    Restore-TestEnvironment -TestEnvironment $TestEnvironment

    #endregion
}
