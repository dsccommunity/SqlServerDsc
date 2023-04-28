<#
    .SYNOPSIS
        Returns an installed Microsoft SQL Server component that runs as a service.

    .DESCRIPTION
        Returns an installed Microsoft SQL Server component that runs as a service.

    .PARAMETER ServerName
       Specifies the server name to return the components from.

    .EXAMPLE
        Get-SqlDscInstalledComponents

        Returns all the installed services.

    .OUTPUTS
        `[System.Management.Automation.PSCustomObject]`
#>
function Get-SqlDscInstalledService
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

    $serviceComponent = @()

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
        $serviceComponent += [PSCustomObject] @{
            ServiceName              = $installedService.Name
            ServiceType              = $serviceType
            ServiceDisplayName       = $installedService.DisplayName
            ServiceAccountName       = $installedService.ServiceAccount
            ServiceStartMode         = $serviceStartMode
            InstanceName             = $serviceInstanceName
            ServiceExecutableVersion = $fileProductVersion
        }
    }

    return $serviceComponent
}
