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
        Get-SqlDscInstalledComponents

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

    $serviceComponent = Get-SqlDscInstalledService -ServerName $ServerName

    $installedComponents = @()

    # Evaluate features based on installed services.
    foreach ($currentServiceComponent in $serviceComponent)
    {
        $installedComponent = [PSCustomObject] @{
            Feature = $null
        }

        switch ($currentServiceComponent.ServiceType)
        {
            'DatabaseEngine'
            {
                $installedComponent.Feature = 'SQLEngine'

                break
            }

            '9'
            {
                $installedComponent.Feature += 'FullText'

                break
            }

            '12'
            {
                $installedComponent.Feature += 'AdvancedAnalytics'

                break
            }

            'AnalysisServices'
            {
                $installedComponent.Feature += 'AS'

                break
            }

            'IntegrationServices'
            {
                $installedComponent.Feature += 'IS'

                break
            }

            'ReportingServices'
            {
                $installedComponent.Feature += 'RS'

                break
            }

            Default
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
        $databaseLevelVersion = [System.Version] ('{0}.{1}' -f $databaseLevel.Substring(0,2), $databaseLevel.Substring(2,1))

        # Look for installed version of Data Quality Client.
        $isDQInstalled = Test-IsDataQualityClientInstalled -Version $databaseLevelVersion

        if ($isDQInstalled)
        {
            $installedComponents += [PSCustomObject] @{
                Feature = 'DQC'
                Version = $databaseLevelVersion
            }
        }

        # Look for installed version of SQL Server Books Online.
        $isBOLInstalled = Test-IsBooksOnlineInstalled -Version $databaseLevelVersion

        if ($isBOLInstalled)
        {
            $installedComponents += [PSCustomObject] @{
                Feature = 'BOL'
                Version = $databaseLevelVersion
            }
        }

        # Look for installed version of Connectivity Components.
        $isConnInstalled = Test-IsConnectivityComponentsInstalled -Version $databaseLevelVersion

        if ($isConnInstalled)
        {
            $installedComponents += [PSCustomObject] @{
                Feature = 'CONN'
                Version = $databaseLevelVersion
            }
        }

        # Look for installed version of Backward Compatibility Components.
        $isBCInstalled = Test-IsBackwardCompatibilityComponentsInstalled -Version $databaseLevelVersion

        if ($isBCInstalled)
        {
            $installedComponents += [PSCustomObject] @{
                Feature = 'BC'
                Version = $databaseLevelVersion
            }
        }

        # Look for installed version of Software Development Kit.
        $isSDKInstalled = Test-IsSoftwareDevelopmentKitInstalled -Version $databaseLevelVersion

        if ($isSDKInstalled)
        {
            $installedComponents += [PSCustomObject] @{
                Feature = 'SDK'
                Version = $databaseLevelVersion
            }
        }

        # Look for installed version of Master Data Services.
        $isMDSInstalled = Test-IsMasterDataServicesInstalled -Version $databaseLevelVersion

        if ($isMDSInstalled)
        {
            $installedComponents += [PSCustomObject] @{
                Feature = 'MDS'
                Version = $databaseLevelVersion
            }
        }
    }

    $databaseEngineInstance = $installedComponents |
            Where-Object -FilterScript {
                $_.InstanceId -match '^MSSQL'
            }

    foreach ($currentInstance in $databaseEngineInstance)
    {
        # Looking for installed version for Replication.
        $isReplicationInstalled = Test-IsReplicationInstalled -InstanceId $currentInstance.InstanceId

        if ($isReplicationInstalled)
        {
            $installedComponents += [PSCustomObject] @{
                Feature = 'Replication'
                Version = $currentInstance.Version
                InstanceName = $currentInstance.InstanceName
                InstanceId = $currentInstance.InstanceId
            }
        }

        # Looking for installed version for Replication.
        $isReplicationInstalled = Test-IsAdvancedAnalyticsInstalled -InstanceId $currentInstance.InstanceId

        if ($isReplicationInstalled)
        {
            $installedComponents += [PSCustomObject] @{
                Feature = 'AdvancedAnalytics'
                Version = $currentInstance.Version
                InstanceName = $currentInstance.InstanceName
                InstanceId = $currentInstance.InstanceId
            }
        }
    }

    # SQL_DQ_Full = DQ : Data Quality Services
    # sql_inst_mr = SQL_INST_MR : R Open and proprietary R packages
    # sql_inst_mpy = SQL_INST_MPY : Anaconda and proprietary Python packages.
    # SQL_Polybase_Core_Inst = PolyBaseCore : PolyBase technology

    #$isDQInstalled = Test-IsDQComponentInstalled -InstanceName $InstanceName -SqlServerMajorVersion $sqlVersion

    # if ($isDQInstalled)
    # {
    #     $component.Feature = 'DQ'
    # }

    # #$isSsmsInstalled = Test-IsSsmsInstalled -SqlServerMajorVersion $sqlVersion

    # if ($isSsmsInstalled)
    # {
    #     $component.Feature = 'SSMS'
    # }

    # #$isSsmsAdvancedInstalled = Test-IsSsmsAdvancedInstalled -SqlServerMajorVersion $sqlVersion

    # if ($isSsmsAdvancedInstalled)
    # {
    #     $component.Feature = 'ADV_SSMS'
    # }


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
