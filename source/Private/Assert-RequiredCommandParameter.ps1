<#
    .SYNOPSIS
        Assert that required parameters has been specified.

    .DESCRIPTION
        Assert that required parameters has been specified, and throws an exception if not.

    .PARAMETER BoundParameter
       A hashtable containing the parameters to evaluate. Normally this is set to
       $PSBoundParameters.

    .PARAMETER RequiredParameter
       One or more parameter names that is required to have been specified.

    .PARAMETER IfParameterPresent
       One or more parameter names that if specified will trigger the evaluation.
       If neither of the parameter names has been specified the evaluation of required
       parameters are not made.

    .EXAMPLE
        Assert-RequiredCommandParameter -BoundParameter $PSBoundParameters -RequiredParameter @('PBStartPortRange', 'PBEndPortRange')

        Throws an exception if either of the two parameters are not specified.

    .EXAMPLE
        Assert-RequiredCommandParameter -BoundParameter $PSBoundParameters -RequiredParameter @('Property2', 'Property3') -IfParameterPresent @('Property1')

        Throws an exception if the parameter 'Property1' is specified and one of the required parameters are not.

    .OUTPUTS
        None.

    .NOTES
        This command should probably be a parmeter set of the command Assert-BoundParameter
        in the module DscResource.Common, instead of being a separate command.
#>
function Assert-RequiredCommandParameter
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]
        $BoundParameter,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $RequiredParameter,

        [Parameter()]
        [System.String[]]
        $IfParameterPresent
    )

    $evaluateRequiredParameter = $true

    if ($PSBoundParameters.ContainsKey('IfParameterPresent'))
    {
        $hasIfParameterPresent = $BoundParameter.Keys.Where( { $_ -in $IfParameterPresent } )

        if (-not $hasIfParameterPresent)
        {
            $evaluateRequiredParameter = $false
        }
    }

    if ($evaluateRequiredParameter)
    {
        foreach ($parameter in $RequiredParameter)
        {
             if ($parameter -notin $BoundParameter.Keys)
             {
                $errorMessage = if ($PSBoundParameters.ContainsKey('IfParameterPresent'))
                {
                    $script:localizedData.RequiredCommandParameter_SpecificParametersMustAllBeSetWhenParameterExist -f ($RequiredParameter -join ''', '''), ($IfParameterPresent -join ''', ''')
                }
                else
                {
                    $script:localizedData.RequiredCommandParameter_SpecificParametersMustAllBeSet -f ($RequiredParameter -join ''', ''')
                }

                $PSCmdlet.ThrowTerminatingError(
                    [System.Management.Automation.ErrorRecord]::new(
                        $errorMessage,
                        'ARCP0001', # cspell: disable-line
                        [System.Management.Automation.ErrorCategory]::InvalidOperation,
                        'Command parameters'
                    )
                )
             }
        }
    }
}
