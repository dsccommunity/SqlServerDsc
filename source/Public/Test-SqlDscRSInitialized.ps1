<#
    .SYNOPSIS
        Tests if SQL Server Reporting Services is initialized.

    .DESCRIPTION
        Tests if SQL Server Reporting Services or Power BI Report Server
        is initialized by checking the `IsInitialized` property on the
        `MSReportServer_ConfigurationSetting` CIM instance.

        A Reporting Services instance is considered initialized when:
        - The report server database is configured
        - The encryption keys are set up
        - The service is ready to serve reports

        The configuration CIM instance can be obtained using the
        `Get-SqlDscRSConfiguration` command and passed via the pipeline.

    .PARAMETER Configuration
        Specifies the `MSReportServer_ConfigurationSetting` CIM instance for
        the Reporting Services instance. This can be obtained using the
        `Get-SqlDscRSConfiguration` command. This parameter accepts pipeline
        input.

    .EXAMPLE
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | Test-SqlDscRSInitialized

        Returns $true if the Reporting Services instance 'SSRS' is initialized.

    .EXAMPLE
        $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
        if (Test-SqlDscRSInitialized -Configuration $config) {
            Write-Host 'Reporting Services is initialized'
        }

        Tests if Reporting Services is initialized and performs an action.

    .INPUTS
        `Microsoft.Management.Infrastructure.CimInstance`

        Accepts MSReportServer_ConfigurationSetting CIM instance via pipeline.

    .OUTPUTS
        `System.Boolean`

        Returns $true if the Reporting Services instance is initialized,
        $false otherwise.

    .NOTES
        This is a convenience wrapper around checking the `IsInitialized`
        property of the configuration CIM instance.

    .LINK
        https://docs.microsoft.com/en-us/sql/reporting-services/wmi-provider-library-reference/msreportserver-configurationsetting-properties
#>
function Test-SqlDscRSInitialized
{
    # cSpell: ignore PBIRS
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSyntacticallyCorrectExamples', '', Justification = 'Because the examples use pipeline input the rule cannot validate.')]
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Object]
        $Configuration
    )

    process
    {
        $instanceName = $Configuration.InstanceName

        Write-Verbose -Message ($script:localizedData.Test_SqlDscRSInitialized_Testing -f $instanceName)

        $isInitialized = $Configuration.IsInitialized

        if ($isInitialized)
        {
            Write-Verbose -Message ($script:localizedData.Test_SqlDscRSInitialized_IsInitialized -f $instanceName)
        }
        else
        {
            Write-Verbose -Message ($script:localizedData.Test_SqlDscRSInitialized_NotInitialized -f $instanceName)
        }

        return $isInitialized
    }
}
