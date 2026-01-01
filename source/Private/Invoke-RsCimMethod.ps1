<#
    .SYNOPSIS
        Invokes a CIM method on a Reporting Services configuration instance.

    .DESCRIPTION
        A helper function that wraps Invoke-CimMethod to provide consistent
        error handling for Reporting Services CIM method calls. This function
        handles both ExtendedErrors and Error properties that can be returned
        by the CIM method.

    .PARAMETER CimInstance
        The CIM instance object that contains the method to call.

    .PARAMETER MethodName
        The name of the method to invoke on the CIM instance.

    .PARAMETER Arguments
        A hashtable of arguments to pass to the method.

    .OUTPUTS
        Microsoft.Management.Infrastructure.CimMethodResult

        Returns the result of the CIM method call.

    .EXAMPLE
        $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
        Invoke-RsCimMethod -CimInstance $config -MethodName 'ListReservedUrls'

        Invokes the ListReservedUrls method on the configuration CIM instance.

    .EXAMPLE
        $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
        Invoke-RsCimMethod -CimInstance $config -MethodName 'SetSecureConnectionLevel' -Arguments @{ Level = 1 }

        Invokes the SetSecureConnectionLevel method with the Level argument.
#>
function Invoke-RsCimMethod
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('AvoidThrowOutsideOfTry', '', Justification = 'Because the code throws based on an prior expression')]
    [CmdletBinding()]
    [OutputType([Microsoft.Management.Infrastructure.CimMethodResult])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Object]
        $CimInstance,

        [Parameter(Mandatory = $true)]
        [System.String]
        $MethodName,

        [Parameter()]
        [System.Collections.Hashtable]
        $Arguments
    )

    $invokeCimMethodParameters = @{
        MethodName  = $MethodName
        ErrorAction = 'Stop'
    }

    if ($PSBoundParameters.ContainsKey('Arguments'))
    {
        $invokeCimMethodParameters['Arguments'] = $Arguments
    }

    $invokeCimMethodResult = $CimInstance | Invoke-CimMethod @invokeCimMethodParameters

    <#
        Successfully calling the method returns $invokeCimMethodResult.HRESULT -eq 0.
        If a general error occurs in the Invoke-CimMethod, like calling a method
        that does not exist, returns $null in $invokeCimMethodResult.

        cSpell: ignore HRESULT
    #>
    if ($invokeCimMethodResult -and $invokeCimMethodResult.HRESULT -ne 0)
    {
        if ($invokeCimMethodResult | Get-Member -Name 'ExtendedErrors')
        {
            <#
                The returned object property ExtendedErrors is an array
                so that needs to be concatenated.
            #>
            $errorMessage = $invokeCimMethodResult.ExtendedErrors -join ';'
        }
        else
        {
            $errorMessage = $invokeCimMethodResult.Error
        }

        $errorMessage = $script:localizedData.Invoke_RsCimMethod_FailedToInvokeMethod -f $MethodName, $errorMessage, $invokeCimMethodResult.HRESULT

        throw $errorMessage
    }

    return $invokeCimMethodResult
}
