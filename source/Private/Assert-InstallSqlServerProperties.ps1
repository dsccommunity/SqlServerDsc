<#
    .SYNOPSIS
        Assert that the bound parameters are set as required

    .DESCRIPTION
        Assert that required parameters has been specified, and throws an exception if not.

    .PARAMETER BoundParameter
       A hashtable containing the parameters to evaluate. Normally this is set to
       $PSBoundParameters.

    .EXAMPLE
        Assert-InstallSqlServerProperties -BoundParameter $PSBoundParameters

        Throws an exception if the bound parameters are not in the correct state.

    .OUTPUTS
        None.

    .NOTES
        This function is used by the command Install-SqlDscServer to verify that
        the bound parameters are in the required state.
#>
function Assert-InstallSqlServerProperties
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]
        $BoundParameter
    )

    #region If one of the properties PBStartPortRange and PBEndPortRange are specified, then both must be specified
    $assertParameters = @('PBStartPortRange', 'PBEndPortRange')

    $assertRequiredCommandParameterParameters = @{
        BoundParameter = $BoundParameter
        RequiredParameter = $assertParameters
        IfParameterPresent = $assertParameters
    }

    Assert-RequiredCommandParameter @assertRequiredCommandParameterParameters
    #endregion
}
