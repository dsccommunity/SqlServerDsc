@{
# Version number of this module.
ModuleVersion = '7.0.0.0'

# ID used to uniquely identify this module
GUID = '74e9ddb5-4cbc-4fa2-a222-2bcfb533fd66'

# Author of this module
Author = 'Microsoft Corporation'

# Company or vendor of this module
CompanyName = 'Microsoft Corporation'

# Copyright statement for this module
Copyright = '(c) 2014 Microsoft Corporation. All rights reserved.'

# Description of the functionality provided by this module
Description = 'Module with DSC Resources for deployment and configuration of Microsoft SQL Server.'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '4.0'

# Minimum version of the common language runtime (CLR) required by this module
CLRVersion = '4.0'

# Functions to export from this module
FunctionsToExport = '*'

# Cmdlets to export from this module
CmdletsToExport = '*'

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = @('DesiredStateConfiguration', 'DSC', 'DSCResourceKit', 'DSCResource')

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/PowerShell/xSQLServer/blob/master/LICENSE'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/PowerShell/xSQLServer'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        ReleaseNotes = '- Examples
  - xSQLServerDatabaseRole
    - 1-AddDatabaseRole.ps1
    - 2-RemoveDatabaseRole.ps1
  - xSQLServerRole
    - 3-AddMembersToServerRole.ps1
    - 4-MembersToIncludeInServerRole.ps1
    - 5-MembersToExcludeInServerRole.ps1
  - xSQLServerSetup
    - 1-InstallDefaultInstanceSingleServer.ps1
    - 2-InstallNamedInstanceSingleServer.ps1
    - 3-InstallNamedInstanceSingleServerFromUncPathUsingSourceCredential.ps1
    - 4-InstallNamedInstanceInFailoverClusterFirstNode.ps1
    - 5-InstallNamedInstanceInFailoverClusterSecondNode.ps1
  - xSQLServerReplication
    - 1-ConfigureInstanceAsDistributor.ps1
    - 2-ConfigureInstanceAsPublisher.ps1
  - xSQLServerNetwork
    - 1-EnableTcpIpOnCustomStaticPort.ps1
  - xSQLServerAvailabilityGroupListener
    - 1-AddAvailabilityGroupListenerWithSameNameAsVCO.ps1
    - 2-AddAvailabilityGroupListenerWithDifferentNameAsVCO.ps1
    - 3-RemoveAvailabilityGroupListenerWithSameNameAsVCO.ps1
    - 4-RemoveAvailabilityGroupListenerWithDifferentNameAsVCO.ps1
    - 5-AddAvailabilityGroupListenerUsingDHCPWithDefaultServerSubnet.ps1
    - 6-AddAvailabilityGroupListenerUsingDHCPWithSpecificSubnet.ps1
  - xSQLServerEndpointPermission
    - 1-AddConnectPermission.ps1
    - 2-RemoveConnectPermission.ps1
    - 3-AddConnectPermissionToAlwaysOnPrimaryAndSecondaryReplicaEachWithDifferentSqlServiceAccounts.ps1
    - 4-RemoveConnectPermissionToAlwaysOnPrimaryAndSecondaryReplicaEachWithDifferentSqlServiceAccounts.ps1
  - xSQLServerPermission
    - 1-AddServerPermissionForLogin.ps1
    - 2-RemoveServerPermissionForLogin.ps1
  - xSQLServerEndpointState
    - 1-MakeSureEndpointIsStarted.ps1
    - 2-MakeSureEndpointIsStopped.ps1
  - xSQLServerConfiguration
    - 1-ConfigureTwoInstancesOnTheSameServerToEnableClr.ps1
    - 2-ConfigureInstanceToEnablePriorityBoost.ps1
  - xSQLServerEndpoint
    - 1-CreateEndpointWithDefaultValues.ps1
    - 2-CreateEndpointWithSpecificPortAndIPAddress.ps1
    - 3-RemoveEndpoint.ps1
- Changes to xSQLServerDatabaseRole
  - Fixed code style, added updated parameter descriptions to schema.mof and README.md.
- Changes to xSQLServer
  - Raised the CodeCov target to 70% which is the minimum and required target for HQRM resource.
- Changes to xSQLServerRole
  - **BREAKING CHANGE: The resource has been reworked in it"s entirely.** Below is what has changed.
    - The mandatory parameters now also include ServerRoleName.
    - The ServerRole parameter was before an array of server roles, now this parameter is renamed to ServerRoleName and can only be set to one server role.
      - ServerRoleName are no longer limited to built-in server roles. To add members to a built-in server role, set ServerRoleName to the name of the built-in server role.
      - The ServerRoleName will be created when Ensure is set to "Present" (if it does not already exist), or removed if Ensure is set to "Absent".
    - Three new parameters are added; Members, MembersToInclude and MembersToExclude.
      - Members can be set to one or more logins, and those will _replace all_ the memberships in the server role.
      - MembersToInclude and MembersToExclude can be set to one or more logins that will add or remove memberships, respectively, in the server role. MembersToInclude and MembersToExclude _can not_ be used at the same time as parameter Members. But both MembersToInclude and MembersToExclude can be used together at the same time.
- Changes to xSQLServerSetup
  - Added a note to the README.md saying that it is not possible to add or remove features from a SQL Server failover cluster (issue 433).
  - Changed so that it reports false if the desired state is not correct (issue 432).
    - Added a test to make sure we always return false if a SQL Server failover cluster is missing features.
  - Helper function Connect-SQLAnalysis
    - Now has correct error handling, and throw does not used the unknown named parameter "-Message" (issue 436)
    - Added tests for Connect-SQLAnalysis
    - Changed to localized error messages.
    - Minor changes to error handling.
  - This adds better support for Addnode (issue 369).
  - Now it skips cluster validation för add node (issue 442).
  - Now it ignores parameters that are not allowed for action Addnode (issue 441).
  - Added support for vNext CTP 1.4 (issue 472).
- Added new resource
  - xSQLServerAlwaysOnAvailabilityGroupReplica
- Changes to xSQLServerDatabaseRecoveryModel
  - Fixed code style, removed SQLServerDatabaseRecoveryModel functions from xSQLServerHelper.
- Changes to xSQLServerAlwaysOnAvailabilityGroup
  - Fixed the permissions check loop so that it exits the loop after the function determines the required permissions are in place.
- Changes to xSQLServerAvailabilityGroupListener
  - Removed the dependency of SQLPS provider (issue 460).
  - Cleaned up code.
  - Added test for more coverage.
  - Fixed PSSA rule warnings (issue 255).
  - Parameter Ensure now defaults to "Present" (issue 450).
- Changes to xSQLServerFirewall
  - Now it will correctly create rules when the resource is used for two or more instances on the same server (issue 461).
- Changes to xSQLServerEndpointPermission
  - Added description to the README.md
  - Cleaned up code (issue 257 and issue 231)
  - Now the default value for Ensure is "Present".
  - Removed dependency of SQLPS provider (issue 483).
  - Refactored tests so they use less code.
- Changes to README.md
  - Adding deprecated tag to xSQLServerFailoverClusterSetup, xSQLAOGroupEnsure and xSQLAOGroupJoin in README.md so it it more clear that these resources has been replaced by xSQLServerSetup, xSQLServerAlwaysOnAvailabilityGroup and xSQLServerAlwaysOnAvailabilityGroupReplica respectively.
- Changes to xSQLServerEndpoint
  - BREAKING CHANGE: Now SQLInstanceName is mandatory, and is a key, so SQLInstanceName has no longer a default value (issue 279).
  - BREAKING CHANGE: Parameter AuthorizedUser has been removed (issue 466, issue 275 and issue 80). Connect permissions can be set using the resource xSQLServerEndpointPermission.
  - Optional parameter IpAddress has been added. Default is to listen on any valid IP-address. (issue 232)
  - Parameter Port now has a default value of 5022.
  - Parameter Ensure now defaults to "Present".
  - Resource now supports changing IP address and changing port.
  - Added unit tests (issue 289)
  - Added examples.
- Changes to xSQLServerEndpointState
  - Cleaned up code, removed SupportsShouldProcess and fixed PSSA rules warnings (issue 258 and issue 230).
  - Now the default value for the parameter State is "Started".
  - Updated README.md with a description for the resources and revised the parameter descriptions.
  - Removed dependency of SQLPS provider (issue 481).
  - The parameter NodeName is no longer mandatory and has now the default value of $env:COMPUTERNAME.
  - The parameter Name is now a key so it is now possible to change the state on more than one endpoint on the same instance. _Note: The resource still only supports Database Mirror endpoints at this time._
- Changes to xSQLServerHelper module
  - Removing helper function Get-SQLAlwaysOnEndpoint because there is no resource using it any longer.
  - BREAKING CHANGE: Changed helper function Import-SQLPSModule to support SqlServer module (issue 91). The SqlServer module is the preferred module so if it is found it will be used, and if not found an attempt will be done to load SQLPS module instead.
- Changes to xSQLServerScript
  - Updated tests for this resource, because they failed when Import-SQLPSModule was updated.
'

    } # End of PSData hashtable

} # End of PrivateData hashtable
}






