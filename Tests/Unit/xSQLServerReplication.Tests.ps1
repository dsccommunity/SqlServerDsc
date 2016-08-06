$script:DSCModuleName   = 'xSQLServer'
$script:DSCResourceName = 'xSQLServerReplication'

#region HEADER

# Unit Test Template Version: 1.1.0
[String] $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit 

#endregion HEADER

# Begin Testing
try
{
    #region Pester Test Initialization

    #TODO: Load stubs
    #TODO: define variables

    #endregion Pester Test Initialization

    #region Example state 1
    Describe 'The system is not in the desired state' {
        #TODO: Mock cmdlets here that represent the system not being in the desired state

        #TODO: Create a set of parameters to test your get/test/set methods in this state
        $testParameters = @{
            Property1 = 'value'
            Property2 = 'value'
        }

        #TODO: Update the assertions below to align with the expected results of this state
        It 'Get method returns something' {
            Get-TargetResource @testParameters | Should Be 'something'
        }

        It 'Test method returns false' {
            Test-TargetResource @testParameters | Should be $false
        }

        It 'Set method calls Demo-CmdletName' {
            Set-TargetResource @testParameters

            #TODO: Assert that the appropriate cmdlets were called
            Assert-MockCalled Demo-CmdletName 
        }
    }
    #endregion Example state 1

    #region Example state 2
    Describe 'The system is in the desired state' {
        #TODO: Mock cmdlets here that represent the system being in the desired state

        #TODO: Create a set of parameters to test your get/test/set methods in this state
        $testParameters = @{
            Property1 = 'value'
            Property2 = 'value'
        }

        #TODO: Update the assertions below to align with the expected results of this state
        It 'Get method returns something' {
            Get-TargetResource @testParameters | Should Be 'something'
        }

        It 'Test method returns true' {
            Test-TargetResource @testParameters | Should be $true
        }
    }
    #endregion Example state 1

    #region Non-Exported Function Unit Tests

    # TODO: Pester Tests for any non-exported Helper Cmdlets
    # If the resource does not contain any non-exported helper cmdlets then
    # this block may be safetly deleted.
    InModuleScope $script:DSCResourceName {

        Describe 'Get-SqlServerMajorVersion' {

            Mock -CommandName Get-ItemProperty `
                -MockWith { return New-Object psobject -Property @{ MSSQLSERVER = 'MSSQL12.MSSQLSERVER'} } `
                -ParameterFilter { $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL' }

            It 'Should return corrent major version for default instance' {

                Mock -CommandName Get-ItemProperty `
                    -MockWith { return New-Object psobject -Property @{ Version = '12.1.4100.1' } } `
                    -ParameterFilter { $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL12.MSSQLSERVER\Setup' }
               
                Get-SqlServerMajorVersion -InstanceName 'MSSQLSERVER' | Should be '12'
            }

            It 'Should throw error if major version cannot be resolved' {
                
                Mock -CommandName Get-ItemProperty `
                    -MockWith { return New-Object psobject -Property @{ Version = '' } }`
                    -ParameterFilter { $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL12.MSSQLSERVER\Setup' }

                { Get-SqlServerMajorVersion -InstanceName 'MSSQLSERVER' } | Should Throw "instance: MSSQLSERVER!"
            }
        }
    }
    #endregion Non-Exported Function Unit Tests
}
finally
{
    #region FOOTER

    Restore-TestEnvironment -TestEnvironment $TestEnvironment

    #endregion
}
