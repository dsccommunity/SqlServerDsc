<#
    .SYNOPSIS
        Gets the SQL Server Reporting Services configuration CIM instance.

    .DESCRIPTION
        Gets the SQL Server Reporting Services or Power BI Report Server
        configuration CIM instance (`MSReportServer_ConfigurationSetting`).
        This CIM instance can be used with other commands that manage
        Reporting Services configuration, such as `Enable-SqlDscRsSecureConnection`
        and `Disable-SqlDscRsSecureConnection`.

        The returned CIM instance provides access to properties documented in
        [MSReportServer_ConfigurationSetting](https://learn.microsoft.com/en-us/sql/reporting-services/wmi-provider-library-reference/msreportserver-configurationsetting-properties),
        such as `SecureConnectionLevel`, `DatabaseServerName`,
        `VirtualDirectoryReportServer`, `WindowsServiceIdentityActual`,
        'WindowsServiceIdentityConfigured' and methods for managing Reporting
        Services configuration.

        By default, if the CIM instance is not found on the first attempt, the
        command will retry after a delay. This handles intermittent failures
        when the Report Server service or WMI provider is not immediately ready.
        Use `-SkipRetry` to disable retry behavior.

    .PARAMETER InstanceName
        Specifies the name of the Reporting Services instance. This is a
        mandatory parameter.

    .PARAMETER Version
        Specifies the major version number of the Reporting Services instance.
        If not specified, the version is automatically detected using
        `Get-SqlDscRSSetupConfiguration`.

    .PARAMETER RetryCount
        Specifies the number of retry attempts if the CIM instance is not found.
        Default is 1 retry attempt.

    .PARAMETER RetryDelaySeconds
        Specifies the delay in seconds between retry attempts. Default is 30
        seconds.

    .PARAMETER SkipRetry
        If specified, skips retry attempts and throws an error immediately if
        the CIM instance is not found.

    .EXAMPLE
        Get-SqlDscRSConfiguration -InstanceName 'SSRS'

        Returns the configuration CIM instance for the SSRS instance. The version
        is automatically detected. Retries once after 30 seconds if not found.

    .EXAMPLE
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' -Version 15

        Returns the configuration CIM instance for the SSRS instance with
        explicit version 15 (SQL Server 2019).

    .EXAMPLE
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | Enable-SqlDscRsSecureConnection

        Gets the configuration CIM instance for the SSRS instance and enables
        secure connection using the pipeline.

    .EXAMPLE
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' -RetryCount 3 -RetryDelaySeconds 10

        Returns the configuration CIM instance for the SSRS instance, retrying
        up to 3 times with a 10-second delay between attempts if not found.

    .EXAMPLE
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' -SkipRetry

        Returns the configuration CIM instance for the SSRS instance without
        any retry attempts. Throws an error immediately if not found.

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
        $Version,

        [Parameter()]
        [ValidateRange(1, [System.Int32]::MaxValue)]
        [System.Int32]
        $RetryCount = 1,

        [Parameter()]
        [ValidateRange(1, [System.Int32]::MaxValue)]
        [System.Int32]
        $RetryDelaySeconds = 30,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $SkipRetry
    )

    if (-not $PSBoundParameters.ContainsKey('Version'))
    {
        Write-Verbose -Message ($script:localizedData.Get_SqlDscRSConfiguration_DetectingVersion -f $InstanceName)

        $rsSetupConfiguration = Get-SqlDscRSSetupConfiguration -InstanceName $InstanceName

        if (-not $rsSetupConfiguration)
        {
            $errorMessage = $script:localizedData.Get_SqlDscRSConfiguration_InstanceNotFound -f $InstanceName

            $exception = New-Exception -Message $errorMessage

            $errorRecord = New-ErrorRecord -Exception $exception -ErrorId 'GSRSCD0001' -ErrorCategory 'ObjectNotFound' -TargetObject $InstanceName

            $PSCmdlet.ThrowTerminatingError($errorRecord)
        }

        if ([System.String]::IsNullOrEmpty($rsSetupConfiguration.CurrentVersion))
        {
            $errorMessage = $script:localizedData.Get_SqlDscRSConfiguration_VersionNotFound -f $InstanceName

            $exception = New-Exception -Message $errorMessage

            $errorRecord = New-ErrorRecord -Exception $exception -ErrorId 'GSRSCD0002' -ErrorCategory 'ObjectNotFound' -TargetObject $InstanceName

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

    $maxAttempts = if ($SkipRetry.IsPresent)
    {
        1
    }
    else
    {
        1 + $RetryCount
    }

    $attempt = 0
    $reportingServicesConfiguration = $null

    while ($attempt -lt $maxAttempts)
    {
        $attempt++

        try
        {
            $reportingServicesConfiguration = Get-CimInstance @getCimInstanceParameters
        }
        catch
        {
            $errorMessage = $script:localizedData.Get_SqlDscRSConfiguration_FailedToGetConfiguration -f $InstanceName

            $exception = New-Exception -Message $errorMessage -ErrorRecord $_

            $errorRecord = New-ErrorRecord -Exception $exception -ErrorId 'GSRSCD0003' -ErrorCategory 'InvalidOperation' -TargetObject $InstanceName

            $PSCmdlet.ThrowTerminatingError($errorRecord)
        }

        # Filter to ensure we get the correct instance if multiple are returned.
        $reportingServicesConfiguration = $reportingServicesConfiguration |
            Where-Object -FilterScript {
                $_.InstanceName -eq $InstanceName
            }

        if ($reportingServicesConfiguration)
        {
            break
        }

        if ($attempt -lt $maxAttempts)
        {
            Write-Debug -Message ($script:localizedData.Get_SqlDscRSConfiguration_RetryingAfterDelay -f $InstanceName, $attempt, $maxAttempts, $RetryDelaySeconds)

            Start-Sleep -Seconds $RetryDelaySeconds
        }
    }

    if (-not $reportingServicesConfiguration)
    {
        $errorMessage = $script:localizedData.Get_SqlDscRSConfiguration_ConfigurationNotFound -f $InstanceName

        $exception = New-Exception -Message $errorMessage

        $errorRecord = New-ErrorRecord -Exception $exception -ErrorId 'GSRSCD0004' -ErrorCategory 'ObjectNotFound' -TargetObject $InstanceName

        $PSCmdlet.ThrowTerminatingError($errorRecord)
    }

    return $reportingServicesConfiguration
}
