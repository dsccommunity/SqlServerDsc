<#
    .SYNOPSIS
        Returns a hashtable with property name and their expected value.

    .PARAMETER CompareResult
       The result from Compare-DscParameterState.

    .EXAMPLE
        ConvertFrom-CompareResult -CompareResult (Compare-DscParameterState)

        Returns a hashtable that contain all the properties not in desired state
        and their expected value.

    .OUTPUTS
        [System.Collections.Hashtable]
#>
function ConvertFrom-CompareResult
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Collections.Hashtable[]]
        $CompareResult
    )

    begin
    {
        $returnHashtable = @{}
    }

    process
    {
        $CompareResult | ForEach-Object -Process {
            $returnHashtable[$_.Property] = $_.ExpectedValue
        }
    }

    end
    {
        return $returnHashtable
    }
}
