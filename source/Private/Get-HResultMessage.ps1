<#
    .SYNOPSIS
        Gets a human-readable message for a given HRESULT code.

    .DESCRIPTION
        Translates common Windows HRESULT error codes into human-readable
        messages. This is particularly useful when CIM methods return an
        HRESULT code without detailed error information in ExtendedErrors
        or Error properties.

    .PARAMETER HResult
        The HRESULT code to translate. This is typically a 32-bit signed
        integer returned from a Windows API or CIM method call.

    .OUTPUTS
        `System.String`

        Returns a descriptive message for known HRESULT codes, or a generic
        message with the hexadecimal code for unknown values.

    .EXAMPLE
        Get-HResultMessage -HResult -2147023181

        Returns: The account has not been granted the requested logon type at
        this computer. Verify that the service account has the required
        permissions to interact with the Reporting Services WMI provider.

    .EXAMPLE
        Get-HResultMessage -HResult -2147024891

        Returns: Access is denied. Verify that the current user has administrator
        rights on the Reporting Services instance.

    .NOTES
        This function is used internally by other commands to provide actionable
        error messages when Reporting Services CIM methods fail without detailed
        error information. These codes have not been verified against any official
        Microsoft documentation, and based on the common HRESULT values in
        https://learn.microsoft.com/en-us/windows/win32/seccrypto/common-hresult-values.
#>
function Get-HResultMessage
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Int32]
        $HResult
    )

    <#
        HRESULT values are 32-bit signed integers. Negative values indicate
        errors. The HRESULT is composed of:
        - Bit 31: Severity (0 = success, 1 = error)
        - Bits 16-30: Facility code
        - Bits 0-15: Error code

        Common HRESULT values are documented at:
        https://learn.microsoft.com/en-us/windows/win32/seccrypto/common-hresult-values
    #>
    $hResultMessages = @{
        # cSpell: ignore ACCESSDENIED LOGON
        # E_ACCESSDENIED (0x80070005) - General access denied error
        -2147024891 = $script:localizedData.HResult_AccessDenied

        # ERROR_LOGON_TYPE_NOT_GRANTED (0x80070533) - Account lacks logon rights
        -2147023181 = $script:localizedData.HResult_LogonTypeNotGranted

        # E_FAIL (0x80004005) - Unspecified failure
        -2147467259 = $script:localizedData.HResult_UnspecifiedFailure

        # E_INVALIDARG (0x80070057) - One or more arguments are invalid
        -2147024809 = $script:localizedData.HResult_InvalidArgument

        # E_OUTOFMEMORY (0x8007000E) - Out of memory
        -2147024882 = $script:localizedData.HResult_OutOfMemory

        # RPC_E_DISCONNECTED (0x80010108) - The object invoked has disconnected
        -2147417848 = $script:localizedData.HResult_RpcDisconnected

        # RPC_S_SERVER_UNAVAILABLE (0x800706BA) - The RPC server is unavailable
        -2147023174 = $script:localizedData.HResult_RpcServerUnavailable

        # ERROR_SERVICE_NOT_ACTIVE (0x80070426) - The service has not been started
        -2147023834 = $script:localizedData.HResult_ServiceNotActive
    }

    if ($hResultMessages.ContainsKey($HResult))
    {
        return $hResultMessages[$HResult]
    }

    <#
        Return a generic message with the hexadecimal representation for unknown codes.
        Convert to hex using bitwise operation to handle negative values that would
        overflow when casting directly to UInt32 (e.g., Int32.MinValue = -2147483648).
    #>
    $hexValue = '0x{0:X8}' -f ($HResult -band 0xFFFFFFFF)

    return ($script:localizedData.HResult_Unknown -f $hexValue)
}
