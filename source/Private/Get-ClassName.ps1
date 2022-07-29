<#
    .SYNOPSIS
        Get the class name of the passed object, and optional an array with
        all inherited classes.

    .PARAMETER InputObject
       The object to be evaluated.

    .PARAMETER Recurse
       Specifies if the class name of inherited classes shall be returned. The
       recursive stops when the first object of the type `[System.Object]` is
       found.

    .EXAMPLE
        Get-ClassName -InputObject $this -Recurse

        Get the class name of the current instance and all the inherited (parent)
        classes.

    .OUTPUTS
        [System.String[]]
#>
function Get-ClassName
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseOutputTypeCorrectly', '', Justification = 'Because the rule does not understands that the command returns [System.String[]] when using , (comma) in the return statement')]
    [CmdletBinding()]
    [OutputType([System.String[]])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSObject]
        $InputObject,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Recurse
    )

    # Create a list of the inherited class names
    $class = @($InputObject.GetType().FullName)

    if ($Recurse.IsPresent)
    {
        $parentClass = $InputObject.GetType().BaseType

        while ($parentClass -ne [System.Object])
        {
            $class += $parentClass.FullName

            $parentClass = $parentClass.BaseType
        }
    }

    return , [System.String[]] $class
}
