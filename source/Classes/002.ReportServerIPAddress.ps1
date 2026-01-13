<#
    .SYNOPSIS
        Represents an IP address entry returned by the ListIPAddresses CIM method.

    .DESCRIPTION
        This class represents an IP address available on the report server machine,
        including the IP version (V4 or V6) and whether it is DHCP-enabled.

    .PARAMETER IPAddress
        The IP address string.

    .PARAMETER IPVersion
        The version of the IP address. Values are 'V4' for IPv4 or 'V6' for IPv6.

    .PARAMETER IsDhcpEnabled
        Indicates whether the IP address is DHCP-enabled. If true, the IP address
        is dynamic and should not be used for TLS bindings.

    .EXAMPLE
        [ReportServerIPAddress]::new()

        Creates a new empty ReportServerIPAddress instance.

    .EXAMPLE
        $ipAddress = [ReportServerIPAddress]::new()
        $ipAddress.IPAddress = '192.168.1.1'
        $ipAddress.IPVersion = 'V4'
        $ipAddress.IsDhcpEnabled = $false

        Creates a new ReportServerIPAddress instance with property values.
#>
class ReportServerIPAddress
{
    [System.String]
    $IPAddress

    [System.String]
    $IPVersion

    [System.Boolean]
    $IsDhcpEnabled

    ReportServerIPAddress()
    {
    }
}
