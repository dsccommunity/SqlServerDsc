Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

if (Test-SkipContinuousIntegrationTask -Type 'Integration' -Category @('Integration_SQL2016','Integration_SQL2017'))
{
    return
}

$script:dscModuleName = 'SqlServerDsc'
$script:dscResourceFriendlyName = 'SqlAlwaysOnService'
$script:dscResourceName = "MSFT_$($script:dscResourceFriendlyName)"

Import-Module -Name DscResource.Test -Force

$script:testEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:dscModuleName `
    -DSCResourceName $script:dscResourceName `
    -ResourceType 'Mof' `
    -TestType 'Integration'

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
                    $_.ConfigurationName -eq $configurationName `
                    -and $_.ResourceId -eq $resourceId
                }

                $resourceCurrentState.IsHadrEnabled | Should -Be $true
            }

            It 'Should return $true when Test-DscConfiguration is run' {
                Test-DscConfiguration -Verbose | Should -Be 'True'
            }
        }

        $configurationName = "$($script:dscResourceName)_DisableAlwaysOn_Config"

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

                $resourceCurrentState.IsHadrEnabled | Should -Be $false
            }

            It 'Should return $true when Test-DscConfiguration is run' {
                Test-DscConfiguration -Verbose | Should -Be 'True'
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
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}
