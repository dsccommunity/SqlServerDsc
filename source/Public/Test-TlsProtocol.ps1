<#
    .SYNOPSIS
        Tests if specified TLS/SSL protocols are enabled on the local machine.

    .DESCRIPTION
        Tests one or more SCHANNEL protocol keys under
        HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols
        to determine whether the protocol is enabled for server-side connections.

    .PARAMETER Protocol
        One or more protocol names to check. Valid values: Ssl2, Ssl3, Tls, Tls11, Tls12, Tls13.

    .PARAMETER Client
        When specified, will check the protocol `Client` registry
        key instead of the default `Server` key.

    .PARAMETER Disabled
        When specified, test that the protocol(s) are disabled. By default the
        command tests that the protocol(s) are enabled.

    .OUTPUTS
        System.Boolean

    .EXAMPLE
        Test-TlsProtocol -Protocol Tls12

        Tests if TLS 1.2 is enabled for server-side connections.

    .EXAMPLE
        Test-TlsProtocol -Protocol Tls13 -Client

        Tests if TLS 1.3 is enabled for client-side connections.
#>
function Test-TlsProtocol
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        # TODO: Should use enum [System.Security.Authentication.SslProtocols]
        [Parameter(Mandatory = $true)]
        [ValidateSet('Ssl2', 'Ssl3', 'Tls', 'Tls11', 'Tls12', 'Tls13', IgnoreCase = $true)]
        [System.String[]]
        $Protocol,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Client,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Disabled
    )

    foreach ($p in $Protocol)
    {
        $regPath = Get-TlsProtocolRegistryPath -Protocol $p -Client:$Client

        $protocolEnabled = Get-RegistryPropertyValue -Path $regPath -Name 'Enabled' -ErrorAction SilentlyContinue
        $protocolDisabled = Get-RegistryPropertyValue -Path $regPath -Name 'DisabledByDefault' -ErrorAction SilentlyContinue

        $protocolEnabled = if ($null -ne $protocolEnabled)
        {
            [System.Int32] $protocolEnabled
        }
        else
        {
            $null
        }

        $protocolDisabled = if ($null -ne $protocolDisabled)
        {
            [System.Int32] $protocolDisabled
        }
        else
        {
            $null
        }

        if ($Disabled.IsPresent)
        {
            # Consider protocol enabled when both Enabled and DisabledByDefault are missing
            if ($null -eq $protocolEnabled -and $null -eq $protocolDisabled)
            {
                return $false
            }

            # Consider protocol disabled when Enabled != 1 or DisabledByDefault == 1
            if (($null -ne $protocolEnabled -and $protocolEnabled -ne 1) -or ($null -ne $protocolDisabled -and $protocolDisabled -eq 1))
            {
                continue
            }
            else
            {
                return $false
            }
        }
        else
        {
            if ($null -eq $protocolEnabled -and $null -eq $protocolDisabled)
            {
                continue
            }

            if ($protocolEnabled -eq 1 -and $protocolDisabled -ne 1)
            {
                continue
            }
            else
            {
                return $false
            }
        }
    }

    return $true
}
