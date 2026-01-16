<#
    .SYNOPSIS
        Gets the Report Server URLs for a SQL Server Reporting Services instance.

    .DESCRIPTION
        Gets the Report Server URLs for SQL Server Reporting Services or Power BI
        Report Server by invoking the `GetReportServerUrls` CIM method on the
        `MSReportServer_Instance` CIM class. This returns the URLs for all
        configured Reporting Services applications (such as ReportServerWebService
        and ReportServerWebApp).

        The setup configuration can be obtained using `Get-SqlDscRSSetupConfiguration`
        and passed via the pipeline.

    .PARAMETER SetupConfiguration
        Specifies the setup configuration object for the Reporting Services
        instance. This can be obtained using `Get-SqlDscRSSetupConfiguration`.
        This parameter accepts pipeline input.

    .EXAMPLE
        Get-SqlDscRSSetupConfiguration -InstanceName 'SSRS' | Get-SqlDscRSUrl

        Gets the Report Server URLs for the Reporting Services instance 'SSRS'.

    .EXAMPLE
        Get-SqlDscRSSetupConfiguration | Get-SqlDscRSUrl

        Gets the Report Server URLs for all Reporting Services instances.

    .EXAMPLE
        $urls = Get-SqlDscRSSetupConfiguration -InstanceName 'SSRS' | Get-SqlDscRSUrl
        $urls | Where-Object -FilterScript { $_.ApplicationName -eq 'ReportServerWebService' }

        Gets only the ReportServerWebService URLs for the instance 'SSRS'.

    .INPUTS
        `System.Object`

        Accepts setup configuration objects from `Get-SqlDscRSSetupConfiguration`
        via pipeline.

    .OUTPUTS
        `[ReportServerUri[]]`

        Returns an array of ReportServerUri objects containing the instance name,
        application name, and URL. Returns `$null` if no URLs are configured.

    .NOTES
        The Reporting Services instance must have URLs configured via
        `Set-SqlDscRSUrlReservation` before URLs will be returned by this command.

    .LINK
        https://learn.microsoft.com/en-us/sql/reporting-services/wmi-provider-library-reference/msreportserver-instance-methods-getreportserverurls
#>
function Get-SqlDscRSUrl
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the examples use pipeline input the rule cannot validate.')]
    [CmdletBinding()]
    [OutputType([System.Object[]])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Object]
        $SetupConfiguration
    )

    process
    {
        $instanceName = $SetupConfiguration.InstanceName

        Write-Verbose -Message ($script:localizedData.Get_SqlDscRSUrl_GettingUrls -f $instanceName)

        # Validate that CurrentVersion is available
        if ([System.String]::IsNullOrEmpty($SetupConfiguration.CurrentVersion))
        {
            $errorMessage = $script:localizedData.Get_SqlDscRSUrl_VersionNotFound -f $instanceName

            $exception = New-Exception -Message $errorMessage

            $errorRecord = New-ErrorRecord -Exception $exception -ErrorId 'GSRSU0001' -ErrorCategory 'InvalidOperation' -TargetObject $SetupConfiguration

            $PSCmdlet.ThrowTerminatingError($errorRecord)
        }

        # Construct the CIM namespace for MSReportServer_Instance
        $version = ([System.Version] $SetupConfiguration.CurrentVersion).Major
        $namespace = 'root\Microsoft\SqlServer\ReportServer\RS_{0}\v{1}' -f $instanceName, $version

        try
        {
            # Get the MSReportServer_Instance CIM instance
            $getCimInstanceParameters = @{
                Namespace   = $namespace
                ClassName   = 'MSReportServer_Instance'
                Filter      = "InstanceId='{0}'" -f $SetupConfiguration.InstanceId
                ErrorAction = 'Stop'
            }

            $msReportServerInstance = Get-CimInstance @getCimInstanceParameters
        }
        catch
        {
            $errorMessage = $script:localizedData.Get_SqlDscRSUrl_FailedToGetInstance -f $instanceName

            $exception = New-Exception -Message $errorMessage -ErrorRecord $_

            $errorRecord = New-ErrorRecord -Exception $exception -ErrorId 'GSRSU0002' -ErrorCategory 'InvalidOperation' -TargetObject $SetupConfiguration

            $PSCmdlet.ThrowTerminatingError($errorRecord)
        }

        if (-not $msReportServerInstance)
        {
            $errorMessage = $script:localizedData.Get_SqlDscRSUrl_InstanceNotFound -f $instanceName

            $exception = New-Exception -Message $errorMessage

            $errorRecord = New-ErrorRecord -Exception $exception -ErrorId 'GSRSU0003' -ErrorCategory 'InvalidOperation' -TargetObject $SetupConfiguration

            $PSCmdlet.ThrowTerminatingError($errorRecord)
        }

        try
        {
            # Invoke the GetReportServerUrls method
            $invokeRsCimMethodParameters = @{
                CimInstance = $msReportServerInstance
                MethodName  = 'GetReportServerUrls'
            }

            $result = Invoke-RsCimMethod @invokeRsCimMethodParameters -ErrorAction 'Stop'
        }
        catch
        {
            $errorMessage = $script:localizedData.Get_SqlDscRSUrl_FailedToGetUrls -f $instanceName

            $exception = New-Exception -Message $errorMessage -ErrorRecord $_

            $errorRecord = New-ErrorRecord -Exception $exception -ErrorId 'GSRSU0004' -ErrorCategory 'InvalidOperation' -TargetObject $SetupConfiguration

            $PSCmdlet.ThrowTerminatingError($errorRecord)
        }

        # Check if any URLs were returned
        if (-not $result.ApplicationName -or $result.ApplicationName.Count -eq 0)
        {
            return $null
        }

        # Build the result array
        $reportServerUrls = @()

        for ($i = 0; $i -lt $result.ApplicationName.Count; $i++)
        {
            $applicationName = $result.ApplicationName[$i]
            $urls = $result.URLs[$i]

            # Each application can have multiple URLs
            foreach ($url in $urls)
            {
                Write-Verbose -Message ($script:localizedData.Get_SqlDscRSUrl_FoundUrl -f $applicationName, $url)

                $reportServerUrl = [ReportServerUri]::new()
                $reportServerUrl.InstanceName = $instanceName
                $reportServerUrl.ApplicationName = $applicationName
                $reportServerUrl.Uri = $url

                $reportServerUrls += $reportServerUrl
            }
        }

        return $reportServerUrls
    }
}
