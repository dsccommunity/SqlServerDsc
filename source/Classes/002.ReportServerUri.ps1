<#
    .SYNOPSIS
        Represents a Reporting Services URL returned by the GetReportServerUrls
        CIM method.

    .DESCRIPTION
        This class represents a URL for a Reporting Services application, including
        the instance name, application name (such as ReportServerWebService or
        ReportServerWebApp), and the URL itself.

    .PARAMETER InstanceName
        The name of the Reporting Services instance.

    .PARAMETER ApplicationName
        The name of the Reporting Services application. Common values include:
        - ReportServerWebService
        - ReportServerWebApp
        - ReportManager (for older versions)

    .PARAMETER Uri
        The URL for accessing the Reporting Services application.

    .EXAMPLE
        [ReportServerUri]::new()

        Creates a new empty ReportServerUri instance.

    .EXAMPLE
        $uri = [ReportServerUri]::new()
        $uri.InstanceName = 'SSRS'
        $uri.ApplicationName = 'ReportServerWebService'
        $uri.Uri = 'http://localhost:80/ReportServer'

        Creates a new ReportServerUri instance with property values.
#>
class ReportServerUri
{
    [System.String]
    $InstanceName

    [System.String]
    $ApplicationName

    [System.String]
    $Uri

    ReportServerUri()
    {
    }
}
