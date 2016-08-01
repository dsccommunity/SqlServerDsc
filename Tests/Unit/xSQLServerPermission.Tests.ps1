$script:DSCModuleName      = 'xSQLServer'
$script:DSCResourceName    = 'xSQLServerPermission'

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

    # Loading mocked classes
    Add-Type -Path (Join-Path -Path $script:moduleRoot -ChildPath 'Tests\Unit\Stubs\SMO.cs')

    $nodeName = 'localhost'
    $instanceName = 'DEFAULT'
    $principal = 'COMPANY\SqlServiceAcct'
    $permission = @( 'AlterAnyAvailabilityGroup','ViewServerState' )

    #endregion Pester Test Initialization

    Describe 'The system is not in the desired state' {
        Mock -CommandName Get-SQLPSInstance -MockWith { 
            $mockObjectSmoServer = New-Object Microsoft.SqlServer.Management.Smo.Server -ArgumentList @( $false )
            $mockObjectSmoServer.Name = "$nodeName\$instanceName"
            $mockObjectSmoServer.DisplayName = $instanceName
            $mockObjectSmoServer.InstanceName = $instanceName
            $mockObjectSmoServer.IsHadrEnabled = $False
            $mockObjectSmoServer.MockGranteeName = $principal

            return $mockObjectSmoServer
        } -ModuleName $script:DSCResourceName -Verifiable
 
        $testParameters = @{
            InstanceName = $instanceName
            NodeName = $nodeName
            Principal = $principal
            Permission = $permission
        }

        $result = Get-TargetResource @testParameters

        It 'Get method returns desired state is absent' {
            $result.Ensure | Should Be 'Absent'
        }

        It 'Get method returns correct node name' {
            $result.NodeName | Should Be $nodeName
        }

        It 'Get method returns correct instance name' {
            $result.InstanceName | Should Be $instanceName
        }

        It 'Get method returns correct principal' {
            $result.Principal | Should Be $principal
        }

        It 'Get method returns no permissions' {
            $result.Permission | Should Be $null
        }

        $testParameters += @{
            Ensure = 'Present'
        }

        $result = Test-TargetResource @testParameters

        It 'Test method returns desired state is absent' {
            $result | Should Be $false
        }

        It 'Set method calls Get-SQLPSInstance' {
            Assert-MockCalled Get-SQLPSInstance -Exactly -Times 2 -ModuleName $script:DSCResourceName
        }

        It 'Set method should not throw' {
            { Set-TargetResource @testParameters } | Should Not Throw
        }

        It 'Get,Test and Set method calls Get-SQLPSInstance' {
            Assert-MockCalled Get-SQLPSInstance -Exactly 4 -ModuleName $script:DSCResourceName
        }

        Assert-VerifiableMocks
    }

    Describe 'The system is in the desired state' {
        Mock -CommandName Get-SQLPSInstance -MockWith { 
            $mockObjectSmoServer = New-Object Microsoft.SqlServer.Management.Smo.Server -ArgumentList @($true)
            $mockObjectSmoServer.Name = "$nodeName\$instanceName"
            $mockObjectSmoServer.DisplayName = $instanceName
            $mockObjectSmoServer.InstanceName = $instanceName
            $mockObjectSmoServer.IsHadrEnabled = $False
            $mockObjectSmoServer.MockGranteeName = $principal

            return $mockObjectSmoServer
        } -ModuleName $script:DSCResourceName -Verifiable

        $testParameters = @{
            InstanceName = $instanceName
            NodeName = $nodeName
            Principal = $principal
            Permission = $permission
        }

        $result = Get-TargetResource @testParameters

        It 'Get method returns desired state is present' {
            $result.Ensure | Should Be 'Present'
        }

        It 'Get method returns correct node name' {
            $result.NodeName | Should Be $nodeName
        }

        It 'Get method returns correct instance name' {
            $result.InstanceName | Should Be $instanceName
        }

        It 'Get method returns correct principal' {
            $result.Principal | Should Be $principal
        }

        It 'Get method returns correct permissions' {
            foreach ($currentPermission in $permission) {
                if( $result.Permission -ccontains $currentPermission ) {
                    $permissionState = $true 
                } else {
                    $permissionState = $false
                    break
                }
            } 
            
            $permissionState | Should Be $true
        }

        $testParameters += @{
            Ensure = 'Present'
        }

        $result = Test-TargetResource @testParameters
        
        It 'Test method returns desired state is present' {
            $result | Should Be $true
        }

        It 'Set method should not throw' {
            { Set-TargetResource @testParameters } | Should Not Throw
        }

        It 'Get,Test and Set method calls Get-SQLPSInstance' {
            Assert-MockCalled Get-SQLPSInstance -Exactly 3 -ModuleName $script:DSCResourceName
        }

        Assert-VerifiableMocks
    }
}
finally
{
    #region FOOTER

    Restore-TestEnvironment -TestEnvironment $TestEnvironment 

    #endregion

    Remove-module $script:DSCResourceName -Force
}
