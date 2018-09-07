<#
    This is used to make sure the integration test run in the correct order.
    The integration test should run after the integration tests SqlServerLogin
    and SqlServerRole, so any problems in those will be caught first, since
    these integration tests are using those resources.
#>
[Microsoft.DscResourceKit.IntegrationTest(OrderNumber = 5)]
param()

$script:DSCModuleName = 'SqlServerDsc'
$script:DSCResourceFriendlyName = 'SqlScriptQuery'
$script:DSCResourceName = "MSFT_$($script:DSCResourceFriendlyName)"

if (-not $env:APPVEYOR -eq $true)
{
    Write-Warning -Message ('Integration test for {0} will be skipped unless $env:APPVEYOR equals $true' -f $script:DSCResourceName)
    return
}

#region HEADER
# Integration Test Template Version: 1.1.2
[String] $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Integration

#endregion

#$mockSqlServicePrimaryAccountPassword = ConvertTo-SecureString -String 'yig-C^Equ3' -AsPlainText -Force
$mockSqlServicePrimaryAccountUserName = "$env:COMPUTERNAME\svc-SqlPrimary"
#$mockSqlServicePrimaryCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $mockSqlServicePrimaryAccountUserName, $mockSqlServicePrimaryAccountPassword

$mockSqlPrivateKeyPassword = ConvertTo-SecureString -String '1234' -AsPlainText -Force
$mockSqlPriavteCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList 'Ignore', $mockSqlPrivateKeyPassword
Import-PfxCertificate -FilePath $env:SqlPrivateCertificatePath -Password $mockSqlPrivateKeyPassword -Exportable -CertStoreLocation 'Cert:\LocalMachine\Root'
try
{
    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName).config.ps1"
    . $configFile

    #$mockGetQuery      = $ConfigurationData.AllNodes.GetQuery
    #$mockTestQuery     = $ConfigurationData.AllNodes.TestQuery
    #$mockSetQuery      = $ConfigurationData.AllNodes.SetQuery
    #$mockDatabase1Name = $ConfigurationData.AllNodes.Database1Name
    #$mockDatabase2Name = $ConfigurationData.AllNodes.Database2Name

    Describe "$($script:DSCResourceName)_Integration" {
        BeforeAll {
            $resourceId = "[$($script:DSCResourceFriendlyName)]Integration_Test"
        }

        $configurationName = "$($script:DSCResourceName)_AddSecureConnection_Config"

        Context ('When using configuration {0}' -f $configurationName) {
            It 'Should compile and apply the MOF without throwing' {
                {
                    $configurationParameters = @{
                        $SqlServicePrimaryUserName = $mockSqlServicePrimaryAccountUserName
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
                    $_.ConfigurationName -eq $configurationName
                } | Where-Object -FilterScript {
                    $_.ResourceId -eq $resourceId
                }

                #$resultObject.Name | Should -Be $mockDatabase1Name
                #$resourceCurrentState.GetQuery | Should -Be $mockGetQuery
                #$resourceCurrentState.TestQuery | Should -Be $mockTestQuery
                #$resourceCurrentState.SetQuery | Should -Be $mockSetQuery
            }
        }

        $configurationName = "$($script:DSCResourceName)__RemoveSecureConnection_Config"

        Context ('When using configuration {0}' -f $configurationName) {
            It 'Should compile and apply the MOF without throwing' {
                {
                    $configurationParameters = @{
                        $SqlServicePrimaryUserName = $mockSqlServicePrimaryAccountUserName
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

                #$resourceCurrentState.GetResult | Should -Match $mockDatabase2Name
                #$resourceCurrentState.GetQuery | Should -Be $mockGetQuery
                #$resourceCurrentState.TestQuery | Should -Be $mockTestQuery
                #$resourceCurrentState.SetQuery | Should -Be $mockSetQuery
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
