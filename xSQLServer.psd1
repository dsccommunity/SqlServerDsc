@{
# Version number of this module.
ModuleVersion = '8.1.0.0'

# ID used to uniquely identify this module
GUID = '74e9ddb5-4cbc-4fa2-a222-2bcfb533fd66'

# Author of this module
Author = 'Microsoft Corporation'

# Company or vendor of this module
CompanyName = 'Microsoft Corporation'

# Copyright statement for this module
Copyright = '(c) 2017 Microsoft Corporation. All rights reserved.'

# Description of the functionality provided by this module
Description = 'Module with DSC Resources for deployment and configuration of Microsoft SQL Server.'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '5.0'

# Minimum version of the common language runtime (CLR) required by this module
CLRVersion = '4.0'

# Functions to export from this module
FunctionsToExport = '*'

# Cmdlets to export from this module
CmdletsToExport = '*'

RequiredAssemblies = @()

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
        ReleaseNotes = '- Changes to xSQLServer
  - Added back .markdownlint.json so that lint rule MD013 is enforced.
  - Change the module to use the image "Visual Studio 2017" as the build worker
    image for AppVeyor (issue 685).
  - Minor style change in CommonResourceHelper. Added missing [Parameter()] on
    three parameters.
  - Minor style changes to the unit tests for CommonResourceHelper.
  - Changes to xSQLServerHelper
    - Added Swedish localization ([issue 695](https://github.com/PowerShell/xSQLServer/issues/695)).
  - Opt-in for module files common tests ([issue 702](https://github.com/PowerShell/xFailOverCluster/issues/702)).
    - Removed Byte Order Mark (BOM) from the files; CommonResourceHelper.psm1,
      MSFT\_xSQLServerAvailabilityGroupListener.psm1, MSFT\_xSQLServerConfiguration.psm1,
      MSFT\_xSQLServerEndpointPermission.psm1, MSFT\_xSQLServerEndpointState.psm1,
      MSFT\_xSQLServerNetwork.psm1, MSFT\_xSQLServerPermission.psm1,
      MSFT\_xSQLServerReplication.psm1, MSFT\_xSQLServerScript.psm1,
      SQLPSStub.psm1, SQLServerStub.psm1.
  - Opt-in for script files common tests ([issue 707](https://github.com/PowerShell/xFailOverCluster/issues/707)).
    - Removed Byte Order Mark (BOM) from the files; DSCClusterSqlBuild.ps1,
      DSCFCISqlBuild.ps1, DSCSqlBuild.ps1, DSCSQLBuildEncrypted.ps1,
      SQLPush_SingleServer.ps1, 1-AddAvailabilityGroupListenerWithSameNameAsVCO.ps1,
      2-AddAvailabilityGroupListenerWithDifferentNameAsVCO.ps1,
      3-RemoveAvailabilityGroupListenerWithSameNameAsVCO.ps1,
      4-RemoveAvailabilityGroupListenerWithDifferentNameAsVCO.ps1,
      5-AddAvailabilityGroupListenerUsingDHCPWithDefaultServerSubnet.ps1,
      6-AddAvailabilityGroupListenerUsingDHCPWithSpecificSubnet.ps1,
      2-ConfigureInstanceToEnablePriorityBoost.ps1, 1-CreateEndpointWithDefaultValues.ps1,
      2-CreateEndpointWithSpecificPortAndIPAddress.ps1, 3-RemoveEndpoint.ps1,
      1-AddConnectPermission.ps1, 2-RemoveConnectPermission.ps1,
      3-AddConnectPermissionToAlwaysOnPrimaryAndSecondaryReplicaEachWithDifferentSqlServiceAccounts.ps1,
      4-RemoveConnectPermissionToAlwaysOnPrimaryAndSecondaryReplicaEachWithDifferentSqlServiceAccounts.ps1,
      1-MakeSureEndpointIsStarted.ps1, 2-MakeSureEndpointIsStopped.ps1,
      1-EnableTcpIpWithStaticPort.ps1, 2-EnableTcpIpWithDynamicPort.ps1,
      1-AddServerPermissionForLogin.ps1, 2-RemoveServerPermissionForLogin.ps1,
      1-ConfigureInstanceAsDistributor.ps1, 2-ConfigureInstanceAsPublisher.ps1,
      1-WaitForASingleClusterGroup.ps1, 2-WaitForMultipleClusterGroups.ps1.
  - Updated year to 2017 in license file ([issue 711](https://github.com/PowerShell/xFailOverCluster/issues/711)).
  - Code style clean-up throughout the module to align against the Style Guideline.
  - Fixed typos and the use of wrong parameters in unit tests which was found
    after release of new version of Pester ([issue 773](https://github.com/PowerShell/xFailOverCluster/issues/773)).
- Changes to xSQLServerAlwaysOnService
  - Added resource description in README.md.
  - Updated parameters descriptions in comment-based help, schema.mof and README.md.
  - Changed the datatype of the parameter to Uint32 so the same datatype is used
    in both the Get-/Test-/Set-TargetResource functions as in the schema.mof
    (issue 688).
  - Added read-only property IsHadrEnabled to schema.mof and the README.md
    (issue 687).
  - Minor cleanup of code.
  - Added examples (issue 633)
    - 1-EnableAlwaysOn.ps1
    - 2-DisableAlwaysOn.ps1
  - Fixed PS Script Analyzer errors ([issue 724](https://github.com/PowerShell/xSQLServer/issues/724))
  - Casting the result of the property IsHadrEnabled to [System.Boolean] so that
    $null is never returned, which resulted in an exception ([issue 763](https://github.com/PowerShell/xFailOverCluster/issues/763)).
- Changes to xSQLServerDatabasePermission
  - Fixed PS Script Analyzer errors ([issue 725](https://github.com/PowerShell/xSQLServer/issues/725))
- Changes to xSQLServerScript
  - Fixed PS Script Analyzer errors ([issue 728](https://github.com/PowerShell/xSQLServer/issues/728))
- Changes to xSQLServerSetup
  - Added Swedish localization ([issue 695](https://github.com/PowerShell/xSQLServer/issues/695)).
  - Now Get-TargetResource correctly returns an array for property ASSysAdminAccounts,
    and no longer throws an error when there is just one Analysis Services
    administrator (issue 691).
  - Added a simple integration test ([issue 709](https://github.com/PowerShell/xSQLServer/issues/709)).
  - Fixed PS Script Analyzer errors ([issue 729](https://github.com/PowerShell/xSQLServer/issues/729))

'

    } # End of PSData hashtable

} # End of PrivateData hashtable
}









