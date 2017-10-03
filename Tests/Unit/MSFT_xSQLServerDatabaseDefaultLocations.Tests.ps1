#region Header

# Unit Test Template Version: 1.2.1
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))
}

Import-Module -Name ( Join-Path -Path ( Join-Path -Path $PSScriptRoot -ChildPath Stubs ) -ChildPath SQLPSStub.psm1 ) -Force -Global
Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force
Add-Type -Path ( Join-Path -Path ( Join-Path -Path $PSScriptRoot -ChildPath Stubs ) -ChildPath SMO.cs )

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName 'xSQLServer' `
    -DSCResourceName 'MSFT_xSQLServerDatabaseDefaultLocations' `
    -TestType Unit

#endregion HEADER

function Invoke-TestSetup {}

function Invoke-TestCleanup {
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}


# Begin Testing
try
{
    Invoke-TestSetup

    InModuleScope 'MSFT_xSQLServerDatabaseDefaultLocations' {
        $mockSQLServerName = 'localhost'
        $mockSQLServerInstanceName = 'MSSQLSERVER'
        $mockSQLDefaultDataLocation = 'C:\Program Files\Data\'
        $mockSQLDefaultLogLocation = 'C:\Program Files\Log\'
        $mockSQLDefaultBackupLocation = 'C:\Program Files\Backup\'
        $mockSQLAltDefaultDataLocation = 'C:\Program Files\'
        $mockSQLAltDefaultLogLocation = 'C:\Program Files\'
        $mockSQLAltDefaultBackupLocation = 'C:\Program Files\'
        $mockRestartService = $true
        $mockExpectedAlterDefaultFileLocationPath = "C:\temp"
        $mockExpectedAlterDefaultLogLocationPath = "C:\temp"
        $mockExpectedAlterBackupDirectoryLocationPath = "C:\temp"
        $mockInvalidOperationForAlterMethod = $false

        #region Function mocks

        # Default parameters that are used for the It-blocks
        $mockDefaultParameters = @{
            SQLInstanceName = $mockSQLServerInstanceName
            SQLServer       = $mockSQLServerName
        }

        $mockConnectSQL = {
            return New-Object Object |
                        Add-Member -MemberType NoteProperty -Name InstanceName -Value $mockSQLServerInstanceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name ComputerNamePhysicalNetBIOS -Value $mockSQLServerName -PassThru |
                        Add-Member -MemberType NoteProperty -Name DefaultFile -Value $mockSQLDefaultDataLocation -PassThru |
                        Add-Member -MemberType NoteProperty -Name DefaultLog -Value $mockSQLDefaultLogLocation -PassThru |
                        Add-Member -MemberType NoteProperty -Name BackupDirectory -Value $mockSQLDefaultBackupLocation -PassThru |
                        Add-Member -MemberType ScriptMethod -Name Alter -Value {
                            if ($mockInvalidOperationForAlterMethod)
                            {
                                throw 'Mock Alter Method was called with invalid operation.'
                            }
                        } -PassThru
                        Add-Member -MemberType ScriptMethod -Name AlterLog -Value {
                            if ($mockInvalidOperationForAlterMethod)
                            {
                                throw 'Mock Alter Method was called with invalid operation.'
                            }
                        } -PassThru
                        Add-Member -MemberType ScriptMethod -Name AlterBackup -Value {
                            if ($mockInvalidOperationForAlterMethod)
                            {
                                throw 'Mock Alter Method was called with invalid operation.'
                            }
                        } -PassThru -Force
        }

        $testCases = @(
            @{
                DefaultLocationType = 'Data'
                DefaultLocationPath= $mockSQLDefaultDataLocation
                AltLocationPath = $mockSQLAltDefaultDataLocation
                AlterLocationPath = $mockExpectedAlterDefaultFileLocationPath
            },
            @{
                DefaultLocationType = 'Log'
                DefaultLocationPath= $mockSQLDefaultLogLocation
                AltLocationPath = $mockSQLAltDefaultLogLocation
                AlterLocationPath = $mockExpectedAlterDefaultLogLocationPath
            },
            @{
                DefaultLocationType = 'Backup'
                DefaultLocationPath= $mockSQLDefaultBackupLocation
                AltLocationPath = $mockSQLAltDefaultBackupLocation
                AlterLocationPath = $mockExpectedAlterBackupDirectoryLocationPath
            }
        )
        #endregion

        Describe "MSFT_xSQLServerDatabaseDefaultLocations\Get-TargetResource" -Tag 'Get'{
            Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

                Context 'When the system is either in the desired state or not in the desired state' {

                    It 'Should get the default path for <DefaultLocationType> with the value <DefaultLocationPath>' -testcases $testCases {
                        param
                        (
                            $DefaultLocationType,
                            $DefaultLocationPath
                        )

                        $result = Get-TargetResource @mockDefaultParameters -DefaultLocationType $DefaultLocationType -DefaultLocationPath $DefaultLocationPath

                        $result.DefaultLocationPath | Should Be $DefaultLocationPath
                        $result.DefaultLocationType | Should Be $DefaultLocationType
                        $result.SQLServer | Should Be $mockDefaultParameters.SQLServer
                        $result.SQLInstanceName | Should Be $mockDefaultParameters.SQLInstanceName
                    }

                    It 'Should call the mock function Connect-SQL' {
                        Assert-MockCalled Connect-SQL -Exactly -Times 3 -Scope Context
                    }
             }
        }

        Describe "MSFT_xSQLServerDatabaseDefaultLocations\Test-TargetResource" -Tag 'Test'{
            BeforeEach {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
            }

            Context 'When the default path is already set.' {
                It 'Should return true when the desired state of the <DefaultLocationType> path has the value <DefaultLocationPath>' -testcases $testCases {
                    param
                    (
                        $DefaultLocationType,
                        $DefaultLocationPath,
                        $AltLocationPath
                    )

                    Test-TargetResource @mockDefaultParameters -DefaultLocationType $DefaultLocationType -DefaultLocationPath $DefaultLocationPath | Should Be $true
                }
                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 3 -Scope Context
                }
            }
            Context 'When the default path is different.' {
                It 'Should return false when the desired state of the <DefaultLocationType> path does not equal <DefaultLocationPath>' -testcases $testCases {
                    param
                    (
                        $DefaultLocationType,
                        $DefaultLocationPath,
                        $AltLocationPath
                    )

                    Test-TargetResource @mockDefaultParameters -DefaultLocationType $DefaultLocationType -DefaultLocationPath $AltLocationPath | Should Be $false
                }
                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 3 -Scope Context
                }
            }
        }

        Describe "MSFT_xSQLServerDatabaseDefaultLocations\Set-TargetResource" -Tag 'Set'{
            BeforeAll {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
                Mock -CommandName Restart-SqlService -MockWith {} -Verifiable
            }

            Context 'When the desired Default location parameter is not set.' {
                It 'Should not throw when the default path is not set to value and restart service is true.' -testcases $testCases {
                    param
                    (
                        $DefaultLocationType,
                        $DefaultLocationPath,
                        $AltLocationPath
                    )

                    $setTargetResourceParameters = @{
                        DefaultLocationType = $DefaultLocationType
                        DefaultLocationPath = $AltLocationPath
                        RestartService = $mockRestartService
                    }


                    {Set-TargetResource @mockDefaultParameters @setTargetResourceParameters} | Should Not Throw

                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                    Assert-MockCalled Restart-SqlService -Exactly -Times 1 -Scope It
                }
            }


            $mockInvalidOperationForAlterMethod = $true

            Context 'When the desired Default location parameter is not set.' {
                It 'Should throw the correct error when Alter() method was called with invalid operation' -testcases $testCases {
                    param
                    (
                        $DefaultLocationType,
                        $DefaultLocationPath,
                        $AltLocationPath,
                        $AlterLocationPath
                    )

                    $throwInvalidOperation = "The alter command for setting the default location failed."

                    $setTargetResourceParameters = @{
                        DefaultLocationType = $DefaultLocationType
                        DefaultLocationPath = $AlterLocationPath
                        RestartService = $mockRestartService
                    }

                    {Set-TargetResource @mockDefaultParameters @setTargetResourceParameters} | Should Throw $throwInvalidOperation

                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                    Assert-MockCalled Restart-SqlService -Exactly -Times 0 -Scope It
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}

## invoke-pester -Script .\tests\unit\MSFT_xSQLServerDatabaseDefaultLocations.Tests.ps1
# invoke-pester -Script .\tests\unit\MSFT_xSQLServerDatabaseDefaultLocations.Tests.ps1 -CodeCoverage .\DSCResources\MSFT_xSQLServerDatabaseDefaultLocations\MSFT_xSQLServerDatabaseDefaultLocations.psm1
