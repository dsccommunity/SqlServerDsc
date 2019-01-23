# This is used to make sure the integration test run in the correct order.
[Microsoft.DscResourceKit.IntegrationTest(OrderNumber = 2)]
param()

$script:dscModuleName = 'SqlServerDsc'
$script:dscResourceFriendlyName = 'SqlServerEndpoint'
$script:dcsResourceName = "MSFT_$($script:dscResourceFriendlyName)"

if (-not $env:APPVEYOR -eq $true)
{
    Write-Warning -Message ('Integration test for {0} will be skipped unless $env:APPVEYOR equals $true' -f $script:DSCResourceName)
    return
}

if ($env:APPVEYOR -eq $true -and $env:CONFIGURATION -ne 'Integration')
{
    Write-Verbose -Message ('Integration test for {0} will be skipped unless $env:CONFIGURATION is set to ''Integration''.' -f $script:DSCResourceName) -Verbose
    return
}

#region HEADER
# Integration Test Template Version: 1.3.1
[String] $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath 'DscResource.Tests'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:dscModuleName `
    -DSCResourceName $script:dcsResourceName `
    -TestType Integration
#endregion

$mockSqlInstallAccountPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force
$mockSqlInstallAccountUserName = "$env:COMPUTERNAME\SqlInstall"
$mockSqlInstallCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $mockSqlInstallAccountUserName, $mockSqlInstallAccountPassword

# Using try/finally to always cleanup.
try
{
    #region Integration Tests
    $configurationFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dcsResourceName).config.ps1"
    . $configurationFile

    $mockEndpointName = $ConfigurationData.AllNodes.EndpointName
    $mockPort = $ConfigurationData.AllNodes.Port
    $mockIpAddress = $ConfigurationData.AllNodes.IpAddress
    $mockOwner = $ConfigurationData.AllNodes.Owner

    Describe "$($script:dcsResourceName)_Integration" {

        $configurationName = "$($script:dcsResourceName)_Add_Config"

        Context ('When using configuration {0}' -f $configurationName) {
            It 'Should compile and apply the MOF without throwing' {
                {
                    $configurationParameters = @{
                        OutputPath           = $TestDrive
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
                    -and $_.ResourceId -eq "[$($script:dscResourceFriendlyName)]Integration_Test"
                }

                $resourceCurrentState.Ensure | Should -Be 'Present'
                $resourceCurrentState.EndpointName | Should -Be $mockEndpointName
                $resourceCurrentState.Port | Should -Be $mockPort
                $resourceCurrentState.IpAddress | Should -Be $mockIpAddress
                #$resourceCurrentState.Owner | Should -Be $mockOwner ## TO UNCOMMENT WHEN ISSUE 1251 IS FIXED
            }

            It 'Should return $true when Test-DscConfiguration is run' {
                Test-DscConfiguration -Verbose | Should -Be $true
            }
        }

        $configurationName = "$($script:dcsResourceName)_Remove_Config"

        Context ('When using configuration {0}' -f $configurationName) {
            It 'Should compile and apply the MOF without throwing' {
                {
                    $configurationParameters = @{
                        OutputPath           = $TestDrive
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
                    -and $_.ResourceId -eq "[$($script:dscResourceFriendlyName)]Integration_Test"
                }

                $resourceCurrentState.Ensure | Should -Be 'Absent'
                $resourceCurrentState.EndpointName | Should -BeNullOrEmpty
                $resourceCurrentState.Port | Should -BeNullOrEmpty
                $resourceCurrentState.IpAddress | Should -BeNullOrEmpty
                $resourceCurrentState.Owner | Should -BeNullOrEmpty
            }

            It 'Should return $true when Test-DscConfiguration is run' {
                Test-DscConfiguration -Verbose | Should -Be $true
            }
        }

    }
    #endregion

}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
