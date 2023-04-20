<#
    .SYNOPSIS
        Converts the specified start mode to the equivalent normalized startup type.

    .DESCRIPTION
        Converts the specified start mode of a Win32_Service CIM object or
        a `[Microsoft.SqlServer.Management.Smo.Wmi.Service]` object to the
        equivalent normalized startup type.

    .PARAMETER StartMode
        Specifies the start mode to convert to normalized startup type.

    .EXAMPLE
        ConvertFrom-ServiceStartMode -StartMode 'Auto'

        Returns the startup type 'Automatic'.
#>
function ConvertFrom-ServiceStartMode
{
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.String]
        $StartMode
    )

    process
    {
        if ($StartMode -eq 'Auto')
        {
            $StartMode = 'Automatic'
        }

        return $StartMode
    }
}
