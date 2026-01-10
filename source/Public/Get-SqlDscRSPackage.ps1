<#
    .SYNOPSIS
        Gets package information for SQL Server Reporting Services or Power BI
        Report Server.

    .DESCRIPTION
        Gets package information for a SQL Server Reporting Services or Power BI
        Report Server executable file. The command returns file version information
        including product name, product version, file version, and other
        version-related metadata.

    .PARAMETER FilePath
        Specifies the path to the executable file to return version information for.
        The file must have a product name matching either 'Microsoft SQL Server
        Reporting Services' or 'Microsoft Power BI Report Server'.

    .PARAMETER Force
        If specified, the ProductName validation is skipped. This allows retrieving
        version information for executables with different product names.

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
    [CmdletBinding()]
    [OutputType([System.Diagnostics.FileVersionInfo])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $FilePath,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    $validProductNames = @(
        'Microsoft SQL Server Reporting Services'
        'Microsoft Power BI Report Server'
    )

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

    Write-Debug -Message ($script:localizedData.Get_SqlDscRSPackage_ReturningVersionInfo -f $versionInfo.ProductName, $versionInfo.ProductVersion)

    return $versionInfo
}
