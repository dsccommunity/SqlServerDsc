<#
    .SYNOPSIS
        Gets the available IP addresses for SQL Server Reporting Services.

    .DESCRIPTION
        Gets the IP addresses available on the machine for use with
        SQL Server Reporting Services or Power BI Report Server by calling
        the `ListIPAddresses` method on the
        `MSReportServer_ConfigurationSetting` CIM instance.

        This command returns information about IP addresses that can be
        used for URL reservations and SSL bindings. Each returned object
        includes the IP address, IP version (V4 or V6), and whether DHCP
        is enabled. If DHCP is enabled, the IP address is dynamic and should
        not be used for TLS bindings.

        The configuration CIM instance can be obtained using the
        `Get-SqlDscRSConfiguration` command and passed via the pipeline.

    .PARAMETER Configuration
        Specifies the `MSReportServer_ConfigurationSetting` CIM instance for
        the Reporting Services instance. This can be obtained using the
        `Get-SqlDscRSConfiguration` command. This parameter accepts pipeline
        input.

    .EXAMPLE
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | Get-SqlDscRSIPAddress

        Gets all available IP addresses for the Reporting Services instance.

    .EXAMPLE
        $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
        Get-SqlDscRSIPAddress -Configuration $config | Where-Object -FilterScript { $_.IPVersion -eq 'V4' }

        Gets available IPv4 addresses for the Reporting Services instance.

    .INPUTS
        `Microsoft.Management.Infrastructure.CimInstance`

        Accepts MSReportServer_ConfigurationSetting CIM instance via pipeline.

    .OUTPUTS
        `[ReportServerIPAddress[]]`

        Returns an array of ReportServerIPAddress objects containing the IP
        address, IP version, and DHCP status.

    .NOTES
        This command calls the WMI method `ListIPAddresses`.

    .LINK
        https://docs.microsoft.com/en-us/sql/reporting-services/wmi-provider-library-reference/configurationsetting-method-listipaddresses
#>
function Get-SqlDscRSIPAddress
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the examples use pipeline input the rule cannot validate.')]
    [CmdletBinding()]
    [OutputType([ReportServerIPAddress[]])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Object]
        $Configuration
    )

    process
    {
        $instanceName = $Configuration.InstanceName

        Write-Verbose -Message ($script:localizedData.Get_SqlDscRSIPAddress_Getting -f $instanceName)

        $invokeRsCimMethodParameters = @{
            CimInstance = $Configuration
            MethodName  = 'ListIPAddresses'
        }

        try
        {
            $result = Invoke-RsCimMethod @invokeRsCimMethodParameters

            # Return the IP addresses as ReportServerIPAddress objects
            if ($result.IPAddress -and $result.IPAddress.Count -gt 0)
            {
                $ipAddressObjects = for ($i = 0; $i -lt $result.IPAddress.Count; $i++)
                {
                    $ipAddressObject = [ReportServerIPAddress]::new()
                    $ipAddressObject.IPAddress = $result.IPAddress[$i]
                    $ipAddressObject.IPVersion = $result.IPVersion[$i]
                    $ipAddressObject.IsDhcpEnabled = $result.IsDhcpEnabled[$i]

                    $ipAddressObject
                }

                return $ipAddressObjects
            }
        }
        catch
        {
            $errorMessage = $script:localizedData.Get_SqlDscRSIPAddress_FailedToGet -f $instanceName

            $exception = New-Exception -Message $errorMessage -ErrorRecord $_

            $errorRecord = New-ErrorRecord -Exception $exception -ErrorId 'GSRSIP0001' -ErrorCategory 'InvalidOperation' -TargetObject $Configuration

            $PSCmdlet.ThrowTerminatingError($errorRecord)
        }
    }
}
