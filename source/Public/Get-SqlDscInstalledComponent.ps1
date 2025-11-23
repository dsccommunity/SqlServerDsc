<#
    .SYNOPSIS
        Returns installed Microsoft SQL Server component.

    .DESCRIPTION
        Returns installed Microsoft SQL Server component.

    .PARAMETER ServerName
       Specifies the server name to return the components from.

    .PARAMETER InstanceName
       Specifies the instance name for which to return installed components.

    .PARAMETER Version
       Specifies the version for which to return installed components. If the
       parameter InstanceName is not provided then all instances with the version
       will be returned.

    .EXAMPLE
        Get-SqlDscInstalledComponent

        Returns all the installed components.

    .OUTPUTS
        `[System.Management.Automation.PSCustomObject]`
#>
function Get-SqlDscInstalledComponent
{
    [OutputType([System.Management.Automation.PSCustomObject])]
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = (Get-ComputerName),

        [Parameter()]
        [System.String]
        $InstanceName,

        [Parameter()]
        [System.Version]
        $Version
    )

    Assert-ElevatedUser -ErrorAction 'Stop'

    $serviceComponent = Get-SqlDscManagedComputerService -ServerName $ServerName -WithExtendedProperties

    $installedComponents = @()

    # Evaluate features based on installed services.
    foreach ($currentServiceComponent in $serviceComponent)
    {
        $installedComponent = [PSCustomObject] @{
            Feature = $null
        }

        $serviceType = if ($currentServiceComponent.ManagedServiceType)
        {
            $currentServiceComponent.ManagedServiceType
        }
        else
        {
            $currentServiceComponent.Type
        }

        switch ($serviceType)
        {
            # TODO: Add a Test-command for the path HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL16.SQL2022\ConfigurationState\SQL_FullText_Adv
            '9'
            {
                $installedComponent.Feature += 'FullText'

                break
            }

            # TODO: Add an Test-command for the path HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft SQL Server\MSAS16.SQL2022\ConfigurationState\Analysis_Server_Full
            'AnalysisServices'
            {
                $installedComponent.Feature += 'AS'

                break
            }

            # TODO: Add an Test-command for the path HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft SQL Server\MSRS13.SQL2016\ConfigurationState\RS_Server_Adv
            'ReportingServices'
            {
                $installedComponent.Feature += 'RS'

                break
            }

            default
            {
                # Skip services like SQL Browser and SQL Agent.

                break
            }
        }

        # Skip service if it wasn't detected as a feature.
        if ($installedComponent.Feature)
        {
            $installedComponent |
                Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value $currentServiceComponent.InstanceName -PassThru |
                Add-Member -MemberType 'NoteProperty' -Name 'Version' -Value $currentServiceComponent.ServiceExecutableVersion -PassThru |
                Add-Member -MemberType 'NoteProperty' -Name 'ServiceProperties' -Value $currentServiceComponent

            # Get InstanceId for all installed services.
            if ($currentServiceComponent.ServiceType -in ('DatabaseEngine', 'AnalysisServices', 'ReportingServices'))
            {
                $installedComponent |
                    Add-Member -MemberType 'NoteProperty' -Name 'InstanceId' -Value (
                        $currentServiceComponent.ServiceType |
                            Get-InstanceId -InstanceName $currentServiceComponent.InstanceName
                        )
            }

            $installedComponents += $installedComponent
        }
    }

    # Fetch registry keys that is three digits, like 100, 110, .., 160, and so on.
    $installedDatabaseLevel = (Split-Path -Leaf -Path (Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\').Name) -match '^\d\d\d$'

    foreach ($databaseLevel in $installedDatabaseLevel)
    {
        $databaseLevelVersion = [System.Version] ('{0}.{1}' -f $databaseLevel.Substring(0, 2), $databaseLevel.Substring(2, 1))

        $isIntegrationServicesInstalled = Test-SqlDscIsIntegrationServicesInstalled -Version $databaseLevelVersion

        if ($isIntegrationServicesInstalled)
        {
            $installedComponents += [PSCustomObject] @{
                Feature = 'IS'
                Version = $databaseLevelVersion
            }
        }

        # Look for installed version of Data Quality Client.
        $isDQInstalled = Test-SqlDscIsDataQualityClientInstalled -Version $databaseLevelVersion

        if ($isDQInstalled)
        {
            $installedComponents += [PSCustomObject] @{
                Feature = 'DQC'
                Version = $databaseLevelVersion
            }
        }

        # Look for installed version of SQL Server Books Online.
        $isBOLInstalled = Test-SqlDscIsBooksOnlineInstalled -Version $databaseLevelVersion

        if ($isBOLInstalled)
        {
            $installedComponents += [PSCustomObject] @{
                Feature = 'BOL'
                Version = $databaseLevelVersion
            }
        }

        # Look for installed version of Connectivity Components.
        $isConnInstalled = Test-SqlDscIsConnectivityComponentsInstalled -Version $databaseLevelVersion

        if ($isConnInstalled)
        {
            $installedComponents += [PSCustomObject] @{
                Feature = 'CONN'
                Version = $databaseLevelVersion
            }
        }

        # Look for installed version of Backward Compatibility Components.
        $isBCInstalled = Test-SqlDscIsBackwardCompatibilityComponentsInstalled -Version $databaseLevelVersion

        if ($isBCInstalled)
        {
            $installedComponents += [PSCustomObject] @{
                Feature = 'BC'
                Version = $databaseLevelVersion
            }
        }

        # Look for installed version of Software Development Kit.
        $isSDKInstalled = Test-SqlDscIsSoftwareDevelopmentKitInstalled -Version $databaseLevelVersion

        if ($isSDKInstalled)
        {
            $installedComponents += [PSCustomObject] @{
                Feature = 'SDK'
                Version = $databaseLevelVersion
            }
        }

        # Look for installed version of Master Data Services.
        $masterDataServicesSettings = Test-SqlDscIsMasterDataServicesInstalled -Version $databaseLevelVersion

        if ($masterDataServicesSettings)
        {
            $installedComponents += [PSCustomObject] @{
                Feature = 'MDS'
                Version = $databaseLevelVersion
            }
        }

        # Look for installed version of SQL Server Management Studio.
        $isManagementStudioInstalled = Test-SqlDscIsManagementStudioInstalled -Version $databaseLevelVersion -ErrorAction 'SilentlyContinue'

        if ($isManagementStudioInstalled)
        {
            $installedComponents += [PSCustomObject] @{
                Feature = 'SSMS'
                Version = $databaseLevelVersion
            }
        }

        # Look for installed version of SQL Server Management Studio Advanced.
        $isManagementStudioAdvancedInstalled = Test-SqlDscIsManagementStudioAdvancedInstalled -Version $databaseLevelVersion -ErrorAction 'SilentlyContinue'

        if ($isManagementStudioAdvancedInstalled)
        {
            $installedComponents += [PSCustomObject] @{
                Feature = 'ADV_SSMS'
                Version = $databaseLevelVersion
            }
        }
    }

    # Fetch all database engine instances.
    $installedDatabaseEngineInstance = Get-SqlDscInstalledInstance -ServiceType 'DatabaseEngine'

    foreach ($currentInstance in $installedDatabaseEngineInstance)
    {
        # Look for installed version of Database Engine.
        $databaseEngineSettings = Get-SqlDscDatabaseEngineInstalledSetting -InstanceId $currentInstance.InstanceId -ErrorAction 'SilentlyContinue'

        if ($databaseEngineSettings)
        {
            $installedComponents += [PSCustomObject] @{
                Feature      = 'SQLENGINE'
                InstanceName = $currentInstance.InstanceName
                Version      = $databaseEngineSettings.Version
            }
        }

        # Looking for installed version for Replication.
        $isReplicationInstalled = Test-SqlDscIsReplicationInstalled -InstanceId $currentInstance.InstanceId

        if ($isReplicationInstalled)
        {
            $installedComponents += [PSCustomObject] @{
                Feature      = 'Replication'
                #Version = $currentInstance.Version
                InstanceName = $currentInstance.InstanceName
                InstanceId   = $currentInstance.InstanceId
            }
        }

        # Looking for installed version for Advanced Analytics - R Services (In-Database)).
        $isReplicationInstalled = Test-SqlDscIsRServicesInstalled -InstanceId $currentInstance.InstanceId

        if ($isReplicationInstalled)
        {
            $installedComponents += [PSCustomObject] @{
                Feature      = 'AdvancedAnalytics'
                #Version = $currentInstance.Version
                InstanceName = $currentInstance.InstanceName
                InstanceId   = $currentInstance.InstanceId
            }
        }

        $isDataQualityServerInstalled = Test-SqlDscIsDataQualityServerInstalled -InstanceId $currentInstance.InstanceId

        if ($isDataQualityServerInstalled)
        {
            $installedComponents += [PSCustomObject] @{
                Feature      = 'DQ'
                #Version = $currentInstance.Version
                InstanceName = $currentInstance.InstanceName
                InstanceId   = $currentInstance.InstanceId
            }
        }

        $isROpenRPackagesInstalled = Test-SqlDscIsROpenRPackagesInstalled -InstanceId $currentInstance.InstanceId

        if ($isROpenRPackagesInstalled)
        {
            $installedComponents += [PSCustomObject] @{
                Feature      = 'SQL_INST_MR'
                #Version = $currentInstance.Version
                InstanceName = $currentInstance.InstanceName
                InstanceId   = $currentInstance.InstanceId
            }
        }
    }

    # Filter result

    $componentsToReturn = @()

    if ($PSBoundParameters.ContainsKey('Version'))
    {
        if ($PSBoundParameters.ContainsKey('InstanceName'))
        {
            $componentsToReturn += $installedComponents |
                Where-Object -FilterScript {
                    -not $_.InstanceName -and $_.Version.Major -eq $Version.Major
                }
        }
        else
        {
            $componentsToReturn += $installedComponents |
                Where-Object -FilterScript {
                    $_.Version.Major -eq $Version.Major
                }
        }
    }

    if ($PSBoundParameters.ContainsKey('InstanceName'))
    {
        $componentsToReturn += $installedComponents |
            Where-Object -FilterScript {
                $_.InstanceName -eq $InstanceName
            }
    }

    if (-not $componentsToReturn)
    {
        $componentsToReturn = $installedComponents
    }

    return $componentsToReturn
}
