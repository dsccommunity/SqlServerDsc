<#
    .SYNOPSIS
        Converts a friendly protocol identifier to the SCHANNEL registry key name.

    .DESCRIPTION
        Maps user-friendly protocol names accepted by the public commands
        (e.g. Tls12) to the actual SCHANNEL registry key names (e.g. 'TLS 1.2').

    .PARAMETER Protocol
        The protocol identifier, e.g. 'Tls12', 'Ssl3', 'Tls'.

    .OUTPUTS
        System.String

    .EXAMPLE
        ConvertTo-TlsProtocolRegistryKeyName -Protocol Tls12

        Returns the string 'TLS 1.2'.
#>
function ConvertTo-TlsProtocolRegistryKeyName
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Protocol
    )

    $protocolRegistryKeyName = switch ($Protocol.ToLower())
    {
        'ssl2'
        {
            'SSL 2.0'
        }

        'ssl3'
        {
            'SSL 3.0'
        }

        'tls'
        {
            'TLS 1.0'
        }

        'tls11'
        {
            'TLS 1.1'
        }

        'tls12'
        {
            'TLS 1.2'
        }

        'tls13'
        {
            'TLS 1.3'
        }

        default
        {
            $message = "Unknown protocol '$Protocol'. Valid values: Ssl2, Ssl3, Tls, Tls11, Tls12, Tls13."
            $exception = New-Exception -Message $message
            $errorRecord = New-ErrorRecord -Exception $exception -ErrorId 'InvalidProtocol' -ErrorCategory ([System.Management.Automation.ErrorCategory]::InvalidArgument) -TargetObject $Protocol
            $PSCmdlet.ThrowTerminatingError($errorRecord)
        }
    }

    return $protocolRegistryKeyName
}
