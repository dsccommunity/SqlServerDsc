<#
    .SYNOPSIS
        Gets the service account for SQL Server Reporting Services.

    .DESCRIPTION
        Gets the Windows service account for SQL Server Reporting Services or
        Power BI Report Server from the `MSReportServer_ConfigurationSetting`
        CIM instance.

        This command returns the current service account name that is being
        used by the Reporting Services Windows service.

        The configuration CIM instance can be obtained using the
        `Get-SqlDscRSConfiguration` command and passed via the pipeline.

    .PARAMETER Configuration
        Specifies the `MSReportServer_ConfigurationSetting` CIM instance for
        the Reporting Services instance. This can be obtained using the
        `Get-SqlDscRSConfiguration` command. This parameter accepts pipeline
        input.

    .EXAMPLE
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | Get-SqlDscRSServiceAccount

        Gets the service account for the Reporting Services instance 'SSRS'.

    .EXAMPLE
        $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
        Get-SqlDscRSServiceAccount -Configuration $config

        Gets the service account using a stored configuration object.

    .INPUTS
        `Microsoft.Management.Infrastructure.CimInstance`

        Accepts MSReportServer_ConfigurationSetting CIM instance via pipeline.

    .OUTPUTS
        `System.String`

        Returns the service account name.

    .NOTES
        This is a convenience wrapper around accessing the
        `WindowsServiceIdentityActual` property of the configuration CIM
        instance.

    .LINK
        https://docs.microsoft.com/en-us/sql/reporting-services/wmi-provider-library-reference/msreportserver-configurationsetting-properties
#>
function Get-SqlDscRSServiceAccount
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
        $instanceName = $Configuration.InstanceName

        Write-Verbose -Message ($script:localizedData.Get_SqlDscRSServiceAccount_Getting -f $instanceName)

        return $Configuration.WindowsServiceIdentityActual
    }
}
