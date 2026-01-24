<#
    .SYNOPSIS
        Returns the SCHANNEL registry path for a given protocol and target.

    .DESCRIPTION
        Builds the registry path under
        HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols
        for the provided friendly protocol name and selects the `Server` or
        `Client` subkey depending on the `-Client` switch.

    .PARAMETER Protocol
        The protocol identifier, e.g. 'Tls12'.

    .PARAMETER Client
        When specified, return the path for the `Client` subkey, otherwise
        return the `Server` subkey path.

    .OUTPUTS
        System.String
#>
function Get-TlsProtocolRegistryPath
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Protocol,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Client
    )

    $protocolKeyName = ConvertTo-TlsProtocolRegistryKeyName -Protocol $Protocol

    $target = Get-TlsProtocolTargetRegistryName -Client:$Client

    return "HKLM:\\SYSTEM\\CurrentControlSet\\Control\\SecurityProviders\\SCHANNEL\\Protocols\\$protocolKeyName\\$target"
}
