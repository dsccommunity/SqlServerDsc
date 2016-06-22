<#
.Synopsis
   Automated unit test for RPS_TSQL DSC Resource
#>


# TODO: Customize these parameters...
$Global:DSCModuleName      = 'MSFT_xSQLServerScript' # Example xNetworking
$Global:DSCResourceName    = 'MSFT_xSQLServerScript' # Example MSFT_xFirewall
# /TODO

#region HEADER
# Unit Test Template Version: 1.1.0
[String] $moduleRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))
if ( (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $Global:DSCModuleName `
    -DSCResourceName $Global:DSCResourceName `
    -TestType Unit 
#endregion HEADER

# Begin Testing
try
{
    InModuleScope $Global:DSCResourceName {
        #region Pester Test Initialization
            Function GLobal:Invoke-SqlCmd {}
        #endregion Pester Test Initialization

        #region Function Get-TargetResource
        Describe "$($Global:DSCResourceName)\Get-TargetResource" {
            It "Should throw if SQLPS module cannot be found" {
                $throwMessage = "Failed to find module"

                Mock -CommandName Import-Module -MockWith { Throw $throwMessage }

                { Get-TargetResource -ServerInstance $env:COMPUTERNAME -SetFilePath "set.sql" -GetFilePath "get.sql" -TestFilePath "test.sql" } | should throw $throwMessage
            }

            It "Should throw if Invoke-SqlCmd throws" {
                $throwMessage = "Failed to run SQL Script"

                Mock -CommandName Import-Module -MockWith {}
                Mock -CommandName Invoke-SqlCmd -MockWith { Throw $throwMessage }

                { Get-TargetResource -ServerInstance $env:COMPUTERNAME -SetFilePath "set.sql" -GetFilePath "get.sql" -TestFilePath "test.sql" } | should throw $throwMessage
            }
            
            It "Should return a hashtable if the Get SQL script returns" {
                Mock -CommandName Import-Module -MockWith {}
                Mock -CommandName Invoke-SqlCmd -MockWith { "" }

                $result = Get-TargetResource -ServerInstance $env:COMPUTERNAME -SetFilePath "set.sql" -GetFilePath "get.sql" -TestFilePath "test.sql"

                $result.ServerInstance | should be $env:COMPUTERNAME
                $result.SetFilePath | should be "set.sql"
                $result.GetFilePath | should be "get.sql"
                $result.TestFilePath | should be "test.sql"
                $result.GetType() | should be "hashtable"
            }
        }
        #endregion Function Get-TargetResource


        #region Function Test-TargetResource
        Describe "$($Global:DSCResourceName)\Test-TargetResource" {
            It "Should throw if SQLPS module cannot be found" {
                $throwMessage = "Failed to find module"

                Mock -CommandName Import-Module -MockWith { Throw $throwMessage }

                { Test-TargetResource -ServerInstance $env:COMPUTERNAME -SetFilePath "set.sql" -GetFilePath "get.sql" -TestFilePath "test.sql" } | should throw $throwMessage
            }

            It "Should return false if Invoke-SqlCmd throws" {
                $throwMessage = "Failed to run SQL Script"

                Mock -CommandName Import-Module -MockWith {}
                Mock -CommandName Invoke-SqlCmd -MockWith { Throw $throwMessage }

                Test-TargetResource -ServerInstance $env:COMPUTERNAME -SetFilePath "set.sql" -GetFilePath "get.sql" -TestFilePath "test.sql" | should be $false
            }

            It "Should return true if Invoke-SqlCmd returns null" {
                Mock -CommandName Import-Module -MockWith {}
                Mock -CommandName Invoke-SqlCmd -MockWith {}

                Test-TargetResource -ServerInstance $env:COMPUTERNAME -SetFilePath "set.sql" -GetFilePath "get.sql" -TestFilePath "test.sql" | should be $true
            }
        }
        #endregion Function Test-TargetResource


        #region Function Set-TargetResource
        Describe "$($Global:DSCResourceName)\Set-TargetResource" {
            It "Should throw if SQLPS module cannot be found" {
                $throwMessage = "Failed to find module"

                Mock -CommandName Import-Module -MockWith { Throw $throwMessage }

                { Set-TargetResource -ServerInstance $env:COMPUTERNAME -SetFilePath "set.sql" -GetFilePath "get.sql" -TestFilePath "test.sql" } | should throw $throwMessage
            }

            It "Should throw if Invoke-SqlCmd throws" {
                $throwMessage = "Failed to run SQL Script"

                Mock -CommandName Import-Module -MockWith {}
                Mock -CommandName Invoke-SqlCmd -MockWith { Throw $throwMessage }

                { Set-TargetResource -ServerInstance $env:COMPUTERNAME -SetFilePath "set.sql" -GetFilePath "get.sql" -TestFilePath "test.sql" } | should throw $throwMessage
            }

            It "Should always attempt to execute Invoke-SqlCmd" {
                Mock -CommandName Import-Module -MockWith {}
                Mock -CommandName Invoke-SqlCmd -MockWith {} -Verifiable

                $result = Set-TargetResource -ServerInstance $env:COMPUTERNAME -SetFilePath "set.sql" -GetFilePath "get.sql" -TestFilePath "test.sql" 

                Assert-MockCalled -CommandName Invoke-SqlCmd -Times 1
            }
        }
        #endregion Function Set-TargetResource
    }
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
