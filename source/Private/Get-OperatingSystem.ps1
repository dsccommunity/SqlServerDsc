<#
    .SYNOPSIS
        Gets the operating system CIM instance.

    .DESCRIPTION
        Gets the operating system CIM instance from Win32_OperatingSystem class.
        This function is used to retrieve operating system information such as
        the OS language (OSLanguage) which is needed for Reporting Services
        URL reservation operations.

    .EXAMPLE
        Get-OperatingSystem

        Returns the Win32_OperatingSystem CIM instance.

    .EXAMPLE
        (Get-OperatingSystem).OSLanguage

        Returns the operating system language code (e.g., 1033 for English).

    .INPUTS
        None.

    .OUTPUTS
        `Microsoft.Management.Infrastructure.CimInstance`

        Returns the Win32_OperatingSystem CIM instance.
#>
function Get-OperatingSystem
{
    [CmdletBinding()]
    [OutputType([Microsoft.Management.Infrastructure.CimInstance])]
    param ()

    Write-Verbose -Message $script:localizedData.Get_OperatingSystem_Getting

    $operatingSystem = Get-CimInstance -ClassName 'Win32_OperatingSystem' -Namespace 'root/cimv2' -ErrorAction 'SilentlyContinue'

    if ($null -eq $operatingSystem)
    {
        Write-Error -Message $script:localizedData.Get_OperatingSystem_FailedToGet -Category 'ObjectNotFound' -ErrorId 'GOS0001' -TargetObject $null

        return
    }

    return $operatingSystem
}
