<#
    .SYNOPSIS
        Returns the SCHANNEL protocol target name for registry keys.

    .DESCRIPTION
        Returns either 'Server' or 'Client' depending on the provided
        `-Client` switch. This centralizes the logic used by public commands
        for choosing the registry subkey name.

    .PARAMETER Client
        When specified, return 'Client', otherwise return 'Server'.

    .OUTPUTS
        System.String

    .EXAMPLE
        Get-TlsProtocolTargetRegistryName

        Returns the string 'Server'.

    .EXAMPLE
        Get-TlsProtocolTargetRegistryName -Client

        Returns the string 'Client'.
#>
function Get-TlsProtocolTargetRegistryName
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Client
    )

    if ($Client.IsPresent)
    {
        return 'Client'
    }

    return 'Server'
}
