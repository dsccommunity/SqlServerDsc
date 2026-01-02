<#
    .SYNOPSIS
        Gets the Reporting Services web portal application name based on version.

    .DESCRIPTION
        Gets the Reporting Services web portal application name based on the SQL
        Server major version. SQL Server 2016 (version 13) and later use
        'ReportServerWebApp', while earlier versions use 'ReportManager'.

        The setup configuration object can be obtained using the
        `Get-SqlDscRSSetupConfiguration` command and passed via the pipeline.

        See more information at:
        https://docs.microsoft.com/en-us/sql/reporting-services/breaking-changes-in-sql-server-reporting-services-in-sql-server-2016

    .PARAMETER Configuration
        Specifies the setup configuration object for the Reporting Services instance.
        This can be obtained using the `Get-SqlDscRSSetupConfiguration` command.
        This parameter accepts pipeline input.

    .EXAMPLE
        Get-SqlDscRSSetupConfiguration -InstanceName 'SSRS' | Get-SqlDscRSWebPortalApplicationName

        Returns 'ReportServerWebApp' or 'ReportManager' based on the SQL Server
        version, using pipeline input from the setup configuration object.

    .INPUTS
        `System.Management.Automation.PSCustomObject`

        Accepts setup configuration object via pipeline.

    .OUTPUTS
        `System.String`

        Returns either 'ReportServerWebApp' for SQL Server 2016 and later,
        or 'ReportManager' for earlier versions.
#>
function Get-SqlDscRSWebPortalApplicationName
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the examples use pipeline input the rule cannot validate.')]
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Object]
        $Configuration
    )

    process
    {
        Write-Debug -Message $script:localizedData.Get_SqlDscRSWebPortalApplicationName_GettingApplicationName

        $sqlVersion = $Configuration | Get-SqlDscRSVersion

        if (-not $sqlVersion)
        {
            return
        }

        $sqlMajorVersion = $sqlVersion.Major

        <#
            SQL Server Reporting Services Web Portal application name changed
            in SQL Server 2016 (version 13).
        #>
        if ($sqlMajorVersion -ge 13)
        {
            $reportsApplicationName = 'ReportServerWebApp'
        }
        else
        {
            $reportsApplicationName = 'ReportManager'
        }

        Write-Debug -Message ($script:localizedData.Get_SqlDscRSWebPortalApplicationName_ApplicationName -f $reportsApplicationName)

        return $reportsApplicationName
    }
}
