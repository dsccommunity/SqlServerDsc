<#
    .SYNOPSIS
        Gets package information for SQL Server Reporting Services or Power BI
        Report Server.

    .DESCRIPTION
        Gets package information for an installed SQL Server Reporting Services or
        Power BI Report Server package, or from a setup executable file. The command
        returns file version information including product name, product version,
        file version, and other version-related metadata.

        When using the `Package` parameter, the command retrieves the installed
        package executable and returns its version information.

        When using the `FilePath` parameter, the command returns version information
        from the specified executable file.

    .PARAMETER Package
        Specifies if either the Reporting Services or Power BI Report Server package
        should be retrieved. Valid values are 'SSRS' and 'PBIRS'.

    .PARAMETER FilePath
        Specifies the path to the executable file to return version information for.
        The file must have a product name matching either 'Microsoft SQL Server
        Reporting Services' or 'Microsoft Power BI Report Server'.

    .PARAMETER Force
        If specified, the ProductName validation is skipped when using the FilePath
        parameter. This allows retrieving version information for executables with
        different product names.

    .EXAMPLE
        Get-SqlDscRSPackage -Package 'SSRS'

        Returns package information for the installed SQL Server Reporting Services
        package.

    .EXAMPLE
        Get-SqlDscRSPackage -Package 'PBIRS'

        Returns package information for the installed Power BI Report Server package.

    .EXAMPLE
        Get-SqlDscRSPackage -FilePath 'E:\SQLServerReportingServices.exe'

        Returns package information from the specified SQL Server Reporting Services
        executable file.

    .EXAMPLE
        Get-SqlDscRSPackage -FilePath 'E:\PBIReportServer.exe'

        Returns package information from the specified Power BI Report Server
        executable file.

    .EXAMPLE
        Get-SqlDscRSPackage -FilePath 'E:\CustomReportServer.exe' -Force

        Returns package information from the specified executable file without
        validating the product name.

    .INPUTS
        None.

    .OUTPUTS
        `System.Diagnostics.FileVersionInfo`

        Returns the file version information for the package.
#>
function Get-SqlDscRSPackage
{
    # cSpell: ignore PBIRS
    [CmdletBinding(DefaultParameterSetName = 'Package')]
    [OutputType([System.Diagnostics.FileVersionInfo])]
    param
    (
        [Parameter(Mandatory = $true, ParameterSetName = 'Package')]
        [ValidateSet('SSRS', 'PBIRS')]
        [System.String]
        $Package,

        [Parameter(Mandatory = $true, ParameterSetName = 'FilePath')]
        [System.String]
        $FilePath,

        [Parameter(ParameterSetName = 'FilePath')]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    $versionInfo = $null
    $validProductNames = @(
        'Microsoft SQL Server Reporting Services'
        'Microsoft Power BI Report Server'
    )

    if ($PSCmdlet.ParameterSetName -eq 'Package')
    {
        Write-Debug -Message ($script:localizedData.Get_SqlDscRSPackage_GettingInstalledPackage -f $Package)

        $rsSetupConfiguration = Get-SqlDscRSSetupConfiguration -InstanceName $Package -ErrorAction 'SilentlyContinue'

        if (-not $rsSetupConfiguration)
        {
            $errorMessage = $script:localizedData.Get_SqlDscRSPackage_PackageNotFound -f $Package

            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    $errorMessage,
                    'GSDRSP0001',
                    [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                    $Package
                )
            )
        }

        $installFolder = $rsSetupConfiguration.InstallFolder

        Write-Debug -Message ($script:localizedData.Get_SqlDscRSPackage_FoundInstallFolder -f $installFolder)

        # Determine the executable name based on package type
        if ($Package -eq 'SSRS')
        {
            $executablePath = Join-Path -Path $installFolder -ChildPath 'RSHostingService\ReportingServicesService.exe'
        }
        else
        {
            # PBIRS
            $executablePath = Join-Path -Path $installFolder -ChildPath 'RSHostingService\ReportingServicesService.exe'
        }

        Write-Debug -Message ($script:localizedData.Get_SqlDscRSPackage_GettingVersionInfo -f $executablePath)

        $versionInfo = Get-FileVersion -Path $executablePath
    }
    else
    {
        Write-Debug -Message ($script:localizedData.Get_SqlDscRSPackage_GettingVersionFromFile -f $FilePath)

        $versionInfo = Get-FileVersion -Path $FilePath

        if (-not $Force.IsPresent)
        {
            if ($versionInfo.ProductName -notin $validProductNames)
            {
                $errorMessage = $script:localizedData.Get_SqlDscRSPackage_InvalidProductName -f $versionInfo.ProductName, ($validProductNames -join "', '")

                $PSCmdlet.ThrowTerminatingError(
                    [System.Management.Automation.ErrorRecord]::new(
                        $errorMessage,
                        'GSDRSP0002',
                        [System.Management.Automation.ErrorCategory]::InvalidArgument,
                        $FilePath
                    )
                )
            }
        }
    }

    Write-Debug -Message ($script:localizedData.Get_SqlDscRSPackage_ReturningVersionInfo -f $versionInfo.ProductName, $versionInfo.ProductVersion)

    return $versionInfo
}
