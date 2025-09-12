<#
    .SYNOPSIS
        Gets command parameters excluding specified ones.

    .DESCRIPTION
        This private function filters command parameters by excluding specified parameter names,
        common parameters, and optional common parameters. It returns an array of parameter names
        that can be used to set properties on objects.

    .PARAMETER Command
        Specifies the command information object containing parameter definitions.

    .PARAMETER Exclude
        Specifies an optional array of parameter names to exclude from the result.
        Common parameters and optional common parameters are always excluded.

    .INPUTS
        None.

    .OUTPUTS
        System.String[]

        Returns an array of parameter names that are not excluded.

    .EXAMPLE
        $settableProperties = Get-CommandParameter -Command $MyInvocation.MyCommand -Exclude @('ServerObject', 'Name', 'PassThru', 'Force')

        Returns all parameters except the excluded ones and common parameters.

    .EXAMPLE
        $settableProperties = Get-CommandParameter -Command $MyInvocation.MyCommand

        Returns all parameters except common parameters and optional common parameters.
#>
function Get-CommandParameter
{
    [CmdletBinding()]
    [OutputType([System.String[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.FunctionInfo]
        $Command,

        [Parameter()]
        [System.String[]]
        $Exclude = @()
    )

    $parametersWithoutCommon = Remove-CommonParameter -Hashtable $Command.Parameters

    $settableProperties = $parametersWithoutCommon.Keys | Where-Object -FilterScript { $_ -notin $Exclude }

    return $settableProperties
}
