<#
    .SYNOPSIS
        Gets the SQL Server Reporting Services configuration CIM instance.

    .DESCRIPTION
        Gets the SQL Server Reporting Services or Power BI Report Server
        configuration CIM instance (`MSReportServer_ConfigurationSetting`).
        This CIM instance can be used with other commands that manage
        Reporting Services configuration, such as `Enable-SqlDscRSTls` and
        `Disable-SqlDscRSTls`.

        The configuration CIM instance provides access to properties like
        `SecureConnectionLevel`, `DatabaseServerName`, `VirtualDirectoryReportServer`,
        and methods for managing Reporting Services configuration.

    .PARAMETER InstanceName
        Specifies the name of the Reporting Services instance. This is a
        mandatory parameter.

    .PARAMETER Version
        Specifies the major version number of the Reporting Services instance.
        If not specified, the version is automatically detected using
        `Get-SqlDscRSSetupConfiguration`.

    .EXAMPLE
        Get-SqlDscRSConfiguration -InstanceName 'SSRS'

        Returns the configuration CIM instance for the SSRS instance. The version
        is automatically detected.

    .EXAMPLE
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' -Version 15

        Returns the configuration CIM instance for the SSRS instance with
        explicit version 15 (SQL Server 2019).

    .EXAMPLE
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | Enable-SqlDscRSTls

        Gets the configuration CIM instance for the SSRS instance and enables
        TLS using the pipeline.

    .INPUTS
        None.

    .OUTPUTS
        `Microsoft.Management.Infrastructure.CimInstance`

        Returns the MSReportServer_ConfigurationSetting CIM instance for the
        specified Reporting Services instance.
#>
function Get-SqlDscRSConfiguration
{
    # cSpell: ignore PBIRS
    [CmdletBinding()]
    [OutputType([Microsoft.Management.Infrastructure.CimInstance])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter()]
        [System.Int32]
        $Version
    )

    if (-not $PSBoundParameters.ContainsKey('Version'))
    {
        Write-Verbose -Message ($script:localizedData.Get_SqlDscRSConfiguration_DetectingVersion -f $InstanceName)

        $rsSetupConfiguration = Get-SqlDscRSSetupConfiguration -InstanceName $InstanceName

        if (-not $rsSetupConfiguration)
        {
            $errorMessage = $script:localizedData.Get_SqlDscRSConfiguration_InstanceNotFound -f $InstanceName

            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    [System.InvalidOperationException]::new($errorMessage),
                    'GSRSCD0001',
                    [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                    $InstanceName
                )
            )
        }

        if ([System.String]::IsNullOrEmpty($rsSetupConfiguration.CurrentVersion))
        {
            $errorMessage = $script:localizedData.Get_SqlDscRSConfiguration_VersionNotFound -f $InstanceName

            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    [System.InvalidOperationException]::new($errorMessage),
                    'GSRSCD0002',
                    [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                    $InstanceName
                )
            )
        }

        $Version = ([System.Version] $rsSetupConfiguration.CurrentVersion).Major
    }

    Write-Verbose -Message ($script:localizedData.Get_SqlDscRSConfiguration_GettingConfiguration -f $InstanceName, $Version)

    $getCimInstanceParameters = @{
        ClassName   = 'MSReportServer_ConfigurationSetting'
        Namespace   = 'root\Microsoft\SQLServer\ReportServer\RS_{0}\v{1}\Admin' -f $InstanceName, $Version
        ErrorAction = 'Stop'
    }

    try
    {
        $reportingServicesConfiguration = Get-CimInstance @getCimInstanceParameters
    }
    catch
    {
        $errorMessage = $script:localizedData.Get_SqlDscRSConfiguration_FailedToGetConfiguration -f $InstanceName, $_.Exception.Message

        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                [System.InvalidOperationException]::new($errorMessage, $_.Exception),
                'GSRSCD0003',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $InstanceName
            )
        )
    }

    # Filter to ensure we get the correct instance if multiple are returned.
    $reportingServicesConfiguration = $reportingServicesConfiguration |
        Where-Object -FilterScript {
            $_.InstanceName -eq $InstanceName
        }

    if (-not $reportingServicesConfiguration)
    {
        $errorMessage = $script:localizedData.Get_SqlDscRSConfiguration_ConfigurationNotFound -f $InstanceName

        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                [System.InvalidOperationException]::new($errorMessage),
                'GSRSCD0004',
                [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                $InstanceName
            )
        )
    }

    return $reportingServicesConfiguration
}
