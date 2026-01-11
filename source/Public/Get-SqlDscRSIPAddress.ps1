<#
    .SYNOPSIS
        Gets the available IP addresses for SQL Server Reporting Services.

    .DESCRIPTION
        Gets the IP addresses available on the machine for use with
        SQL Server Reporting Services or Power BI Report Server by calling
        the `ListIPAddresses` method on the
        `MSReportServer_ConfigurationSetting` CIM instance.

        This command returns information about IP addresses that can be
        used for URL reservations and SSL bindings.

        The configuration CIM instance can be obtained using the
        `Get-SqlDscRSConfiguration` command and passed via the pipeline.

    .PARAMETER Configuration
        Specifies the `MSReportServer_ConfigurationSetting` CIM instance for
        the Reporting Services instance. This can be obtained using the
        `Get-SqlDscRSConfiguration` command. This parameter accepts pipeline
        input.

    .PARAMETER Lcid
        Specifies the language code identifier (LCID) for the request.
        If not specified, defaults to the operating system language. Common
        values include 1033 for English (US).

    .EXAMPLE
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | Get-SqlDscRSIPAddress

        Gets all available IP addresses for the Reporting Services instance.

    .EXAMPLE
        $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
        Get-SqlDscRSIPAddress -Configuration $config -Lcid 1033

        Gets available IP addresses with a specific LCID.

    .INPUTS
        `Microsoft.Management.Infrastructure.CimInstance`

        Accepts MSReportServer_ConfigurationSetting CIM instance via pipeline.

    .OUTPUTS
        `System.String`

        Returns the IP addresses available on the machine.

    .NOTES
        This command calls the WMI method `ListIPAddresses`.

    .LINK
        https://docs.microsoft.com/en-us/sql/reporting-services/wmi-provider-library-reference/configurationsetting-method-listipaddresses
#>
function Get-SqlDscRSIPAddress
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the examples use pipeline input the rule cannot validate.')]
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Object]
        $Configuration,

        [Parameter()]
        [System.Int32]
        $Lcid
    )

    process
    {
        $instanceName = $Configuration.InstanceName

        if (-not $PSBoundParameters.ContainsKey('Lcid'))
        {
            $Lcid = (Get-OperatingSystem).OSLanguage
        }

        Write-Verbose -Message ($script:localizedData.Get_SqlDscRSIPAddress_Getting -f $instanceName)

        $invokeRsCimMethodParameters = @{
            CimInstance = $Configuration
            MethodName  = 'ListIPAddresses'
            Arguments   = @{
                Lcid = $Lcid
            }
        }

        try
        {
            $result = Invoke-RsCimMethod @invokeRsCimMethodParameters -ErrorAction 'Stop'

            # Return the IP addresses
            if ($result.IPAddress)
            {
                return $result.IPAddress
            }
        }
        catch
        {
            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    ($script:localizedData.Get_SqlDscRSIPAddress_FailedToGet -f $instanceName, $_.Exception.Message),
                    'GSRSIP0001',
                    [System.Management.Automation.ErrorCategory]::InvalidOperation,
                    $Configuration
                )
            )
        }
    }
}
