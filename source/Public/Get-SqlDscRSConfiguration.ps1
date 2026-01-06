<#
    .SYNOPSIS
        Gets the SQL Server Reporting Services configuration CIM instance.

    .DESCRIPTION
        Gets the SQL Server Reporting Services or Power BI Report Server
        configuration CIM instance (`MSReportServer_ConfigurationSetting`).
        This CIM instance can be used with other commands that manage
        Reporting Services configuration, such as `Enable-SqlDscRsSecureConnection`
        and `Disable-SqlDscRsSecureConnection`.

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
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | Enable-SqlDscRsSecureConnection

        Gets the configuration CIM instance for the SSRS instance and enables
        secure connection using the pipeline.

    .INPUTS
        None.

    .OUTPUTS
        `Microsoft.Management.Infrastructure.CimInstance`

        Returns the MSReportServer_ConfigurationSetting CIM instance for the
        specified Reporting Services instance.
#>
function Get-SqlDscRSConfiguration
{
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

            $errorRecord = New-ErrorRecord -Exception (New-InvalidOperationException -Message $errorMessage -PassThru) -ErrorId 'GSRSCD0001' -ErrorCategory 'ObjectNotFound' -TargetObject $InstanceName

            $PSCmdlet.ThrowTerminatingError($errorRecord)
        }

        if ([System.String]::IsNullOrEmpty($rsSetupConfiguration.CurrentVersion))
        {
            $errorMessage = $script:localizedData.Get_SqlDscRSConfiguration_VersionNotFound -f $InstanceName

            $errorRecord = New-ErrorRecord -Exception (New-InvalidOperationException -Message $errorMessage -PassThru) -ErrorId 'GSRSCD0002' -ErrorCategory 'ObjectNotFound' -TargetObject $InstanceName

            $PSCmdlet.ThrowTerminatingError($errorRecord)
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

        $errorRecord = New-ErrorRecord -Exception (New-InvalidOperationException -Message $errorMessage -ErrorRecord $_ -PassThru) -ErrorId 'GSRSCD0003' -ErrorCategory 'InvalidOperation' -TargetObject $InstanceName

        $PSCmdlet.ThrowTerminatingError($errorRecord)
    }

    # Filter to ensure we get the correct instance if multiple are returned.
    $reportingServicesConfiguration = $reportingServicesConfiguration |
        Where-Object -FilterScript {
            $_.InstanceName -eq $InstanceName
        }

    if (-not $reportingServicesConfiguration)
    {
        $errorMessage = $script:localizedData.Get_SqlDscRSConfiguration_ConfigurationNotFound -f $InstanceName

        $errorRecord = New-ErrorRecord -Exception (New-InvalidOperationException -Message $errorMessage -PassThru) -ErrorId 'GSRSCD0004' -ErrorCategory 'ObjectNotFound' -TargetObject $InstanceName

        $PSCmdlet.ThrowTerminatingError($errorRecord)
    }

    return $reportingServicesConfiguration
}
