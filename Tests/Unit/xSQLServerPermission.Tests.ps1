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

# TODO: Other Optional Init Code Goes Here...

# Begin Testing
try
{
    #region Pester Test Initialization

    # TODO: Optionally create any variables here for use by your tests
    $nodeName = 'localhost'
    $instanceName = 'DEFAULT'

    # See https://github.com/PowerShell/xNetworking/blob/dev/Tests/Unit/MSFT_xDhcpClient.Tests.ps1
    # Mocks that should be applied to all cmdlets being tested may
    # also be created here if required.

    #endregion Pester Test Initialization

    # TODO: Common DSC Resource describe block structure
    # The following three Describe blocks are included as a common test pattern.
    # If a different test pattern would be more suitable, then test describe blocks
    # may be completely replaced. The goal of this pattern should be to describe 
    # the potential states a system could be in so that the get/test/set cmdlets
    # can be tested in those states. Any mocks that relate to that specific state
    # can be included in the relevant describe block. For a more detailed description
    # of this approach please review https://github.com/PowerShell/DscResources/issues/143 

    # Add as many of these example 'states' as required to simulate the scenarions that
    # the DSC resource is designed to work with, below a simple "is in desired state" and
    # "is not in desired state" are used, but there may be more complex combinations of 
    # factors, depending on how complex your resource is.

    #region Example state 1
    Describe 'The system is not in the desired state' {
        #TODO: Mock cmdlets here that represent the system not being in the desired state
        
        # http://windowsitpro.com/powershell/powershell-basics-custom-objects
        # https://social.technet.microsoft.com/wiki/contents/articles/7804.powershell-creating-custom-objects.aspx
        
        # TypeName: Microsoft.SqlServer.Management.Smo.Server
        # BaseType: Microsoft.SqlServer.Management.Smo.SqlSmoObject
        
        #START Using this requires V5
        Class SqlSmoObject { 
            [string] $name; 
         
            SqlSmoObject([string] $NameIn) { 
                $this.name = $NameIn; 
            } 

            [string] EnumServerPermissions() { 
                #$a = $null 
                #[char[]]$this.Name | Sort-Object {Get-Random} | %{ $a = $PSItem + $a} 
                return "Hejdå ($name)" 
            } 
        } 

        $x = [SqlSmoObject]::new("Microsoft.SqlServer.Management.Smo.Server") 
        $x.EnumServerPermissions() 
        #END Using this requires V5

        #region Mock Microsoft.SqlServer.Management.Smo.Server
        $mockObjectSmoServer = [PSCustomObject] @{
            Name = "$nodeName\$instanceName"
            DisplayName = $instanceName
            InstanceName = $instanceName
            IsHadrEnabled = $False
        }

        $mockMethodEnumServerPermissions = @{
            Name = 'EnumServerPermissions'
            MemberType = 'ScriptMethod'
            Value = {  
                "Hejdå"
            }
        }

        $mockObjectSmoServer.PSTypeNames.Insert(0,'Microsoft.SqlServer.Management.Smo.Server')
        $mockObjectSmoServer | Add-Member @mockMethodEnumServerPermissions
        #endregion Mock Microsoft.SqlServer.Management.Smo.Server

        $TestNetIPInterfaceEnabled = [PSObject]@{
            State                   = 'Enabled'
            InterfaceAlias          = $MockNetAdapter.Name
            AddressFamily           = 'IPv4'
        }

        Mock Get-SQLPSInstance -MockWith { $MockNetAdapter }

        #TODO: Create a set of parameters to test your get/test/set methods in this state
        $testParameters = @{
            InstanceName = 'localhost'
            NodeName = 'MSSQLSERVER'
            Principal = 'COMPANY\DummyAccount'
            Permission = @('ALTER ANY AVAILABILITY GROUP','VIEW SERVER STATE')
        }

        #TODO: Update the assertions below to align with the expected results of this state
        It 'Get method returns desired state is absent' {
            $result = Get-TargetResource @testParameters
            $result.Ensure | Should Be 'Absent'
        }

        $testParameters = @{
            Ensure = 'Present'
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
        # The InModuleScope command allows you to perform white-box unit testing
        # on the internal (non-exported) code of a Script Module.

    }
    #endregion Non-Exported Function Unit Tests
}
finally
{
    #region FOOTER

    Restore-TestEnvironment -TestEnvironment $TestEnvironment

    #endregion

    # TODO: Other Optional Cleanup Code Goes Here...
}
