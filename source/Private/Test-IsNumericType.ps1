<#
    .SYNOPSIS
        Returns wether the specified object is of a numeric type.

    .DESCRIPTION
        Returns wether the specified object is of a numeric type.

    .PARAMETER Object
       The object to test if it is a numeric type.

    .EXAMPLE
        Test-IsNumericType -Object ([System.UInt32] 1)

        Returns $true since the object passed is of a numeric type.

    .OUTPUTS
        [System.Boolean]
#>
function Test-IsNumericType
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(ValueFromPipeline = $true)]
        [System.Object]
        $Object
    )

    $isNumeric = $false

    if (
        $Object -is [System.Byte] -or
        $Object -is [System.Int16] -or
        $Object -is [System.Int32] -or
        $Object -is [System.Int64] -or
        $Object -is [System.SByte] -or
        $Object -is [System.UInt16] -or
        $Object -is [System.UInt32] -or
        $Object -is [System.UInt64] -or
        $Object -is [System.Decimal] -or
        $Object -is [System.Double] -or
        $Object -is [System.Single]
    )
    {
        $isNumeric = $true
    }

    return $isNumeric
}
