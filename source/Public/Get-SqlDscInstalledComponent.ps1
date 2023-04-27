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

    $installedComponents = @()

    $currentInstalledServices = Get-SqlDscManagedComputerService -ServerName $ServerName -ErrorAction 'Stop'

    foreach ($installedService in $currentInstalledServices)
    {
        $serviceType = $installedService.Type | ConvertFrom-ManagedServiceType -ErrorAction 'SilentlyContinue'

        if (-not $serviceType)
        {
            <#
                This is a workaround because [Microsoft.SqlServer.Management.Smo.Wmi.ManagedServiceType]
                does not support all service types yet.
            #>
            $serviceType = $installedService.Type
        }

        $fileProductVersion = $null

        $serviceExecutablePath = (($installedService.PathName -replace '"') -split ' -')[0]

        if ((Test-Path -Path $serviceExecutablePath))
        {
            $fileProductVersion = [System.Version] (Get-FileVersionInformation -FilePath $serviceExecutablePath).ProductVersion
        }

        # Get InstanceName from the service name if it exist.
        $serviceInstanceName = if ($installedService.Name -match '\$(.*)$')
        {
            $Matches[1]
        }

        $serviceStartMode = $installedService.StartMode | ConvertFrom-ServiceStartMode

        <#
            There are more properties that can be fetch from advanced properties,
            for example InstanceId, Clustered, and Version (for some), but it takes
            about 6 seconds for it to return a value. Because of the slowness this
            command does not use advanced properties, e.g:
            ($installedService.AdvancedProperties | ? Name -eq 'InstanceId').Value
        #>
        $serviceComponent = [PSCustomObject] @{
            ServiceName              = $installedService.Name
            ServiceType              = $serviceType
            ServiceDisplayName       = $installedService.DisplayName
            ServiceAccountName       = $installedService.ServiceAccount
            ServiceStartMode         = $serviceStartMode
            InstanceName             = $serviceInstanceName
            ServiceExecutableVersion = $fileProductVersion

            # Properties that should be on all objects, but set later
            InstanceId               = $null
            Feature                  = @()
        }

        $installedComponents += $serviceComponent
    }

    # Loop to set InstanceId.
    foreach ($component in $installedComponents.Where({ $_.ServiceType -in ('DatabaseEngine', 'AnalysisServices', 'ReportingServices') }))
    {
        $component.InstanceId = $component.ServiceType | Get-InstanceId -InstanceName $component.InstanceName
    }

    # Loop to get features.
    foreach ($component in $installedComponents)
    {
        switch ($component.ServiceType)
        {
            'DatabaseEngine'
            {
                $component.Feature += 'SQLEngine'

                #$isReplicationInstalled = Test-IsReplicationFeatureInstalled -InstanceName $InstanceName

                if ($isReplicationInstalled)
                {
                    $component.Feature += 'Replication'
                }

                #$isDQInstalled = Test-IsDQComponentInstalled -InstanceName $InstanceName -SqlServerMajorVersion $sqlVersion

                if ($isDQInstalled)
                {
                    $component.Feature += 'DQ'
                }

                #TODO: This has nothing to do with DatabaseEngine.
                $isDQInstalled = Test-IsDataQualityClientInstalled -Version $component.Version

                if ($isDQInstalled)
                {
                    $component.Feature += 'DQC'
                }

                #$isSsmsInstalled = Test-IsSsmsInstalled -SqlServerMajorVersion $sqlVersion

                if ($isSsmsInstalled)
                {
                    $component.Feature += 'SSMS'
                }

                #$isSsmsAdvancedInstalled = Test-IsSsmsAdvancedInstalled -SqlServerMajorVersion $sqlVersion

                if ($isSsmsAdvancedInstalled)
                {
                    $component.Feature += 'ADV_SSMS'
                }

                break
            }

            '9'
            {
                $component.Feature += 'FullText'

                break
            }

            '12'
            {
                $component.Feature += 'AdvancedAnalytics'

                break
            }

            'AnalysisServices'
            {
                $component.Feature += 'AS'

                break
            }

            'IntegrationServices'
            {
                $component.Feature += 'IS'

                break
            }

            'ReportingServices'
            {
                $component.Feature += 'RS'

                break
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
                    -not $_.InstanceName -and $_.FileProductVersion.Major -eq $Version.Major
                }
        }
        else
        {
            $componentsToReturn += $installedComponents |
                Where-Object -FilterScript {
                    $_.FileProductVersion.Major -eq $Version.Major
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
