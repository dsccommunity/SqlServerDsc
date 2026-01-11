<#
    .SYNOPSIS
        Invokes a CIM method on a Reporting Services configuration instance.

    .DESCRIPTION
        A helper function that wraps Invoke-CimMethod to provide consistent
        error handling for Reporting Services CIM method calls. This function
        handles both ExtendedErrors and Error properties that can be returned
        by the CIM method.

        By default, the function retries failed method calls (HRESULT failures)
        up to 2 times with a 30-second delay between attempts. This behavior
        can be customized using the RetryCount and RetryDelaySeconds parameters,
        or disabled entirely using the SkipRetry switch. Exceptions thrown by
        Invoke-CimMethod are not retried and will immediately terminate.

    .PARAMETER CimInstance
        The CIM instance object that contains the method to call.

    .PARAMETER MethodName
        The name of the method to invoke on the CIM instance.

    .PARAMETER Arguments
        A hashtable of arguments to pass to the method.

    .PARAMETER Timeout
        Specifies the timeout in seconds for the CIM operation. If not specified,
        the default timeout of the CIM session is used.

    .PARAMETER RetryCount
        Specifies the number of retry attempts after the initial failure. The
        default is 2. Set to 0 to disable retries (equivalent to SkipRetry).

    .PARAMETER RetryDelaySeconds
        Specifies the number of seconds to wait between retry attempts. The
        default is 30.

    .PARAMETER SkipRetry
        When specified, disables retry behavior entirely. The method will only
        be attempted once.

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

    .EXAMPLE
        $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
        Invoke-RsCimMethod -CimInstance $config -MethodName 'GenerateDatabaseCreationScript' -Arguments @{ DatabaseName = 'ReportServer' } -Timeout 240

        Invokes the GenerateDatabaseCreationScript method with a 240 second timeout.

    .EXAMPLE
        $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
        Invoke-RsCimMethod -CimInstance $config -MethodName 'SetDatabaseConnection' -RetryCount 5 -RetryDelaySeconds 60

        Invokes the SetDatabaseConnection method with up to 5 retries and a 60 second
        delay between attempts.

    .EXAMPLE
        $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
        Invoke-RsCimMethod -CimInstance $config -MethodName 'ListReservedUrls' -SkipRetry

        Invokes the ListReservedUrls method without any retry behavior.
#>
function Invoke-RsCimMethod
{
    [CmdletBinding(DefaultParameterSetName = 'Retry')]
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
        $Arguments,

        [Parameter()]
        [System.UInt32]
        $Timeout,

        [Parameter(ParameterSetName = 'Retry')]
        [System.UInt32]
        $RetryCount = 2,

        [Parameter(ParameterSetName = 'Retry')]
        [System.UInt32]
        $RetryDelaySeconds = 30,

        [Parameter(ParameterSetName = 'NoRetry')]
        [System.Management.Automation.SwitchParameter]
        $SkipRetry
    )

    $invokeCimMethodParameters = @{
        MethodName  = $MethodName
        ErrorAction = 'Stop'
    }

    if ($PSBoundParameters.ContainsKey('Arguments'))
    {
        $invokeCimMethodParameters['Arguments'] = $Arguments
    }

    if ($PSBoundParameters.ContainsKey('Timeout'))
    {
        $invokeCimMethodParameters['OperationTimeoutSec'] = $Timeout
    }

    # Calculate total attempts (1 initial + RetryCount retries, unless SkipRetry is specified).
    $maxAttempts = if ($SkipRetry.IsPresent)
    {
        1
    }
    else
    {
        1 + $RetryCount
    }

    # Track unique errors across attempts to provide comprehensive error information.
    $collectedErrors = [System.Collections.Generic.List[System.String]]::new()
    $uniqueErrorKeys = [System.Collections.Generic.HashSet[System.String]]::new()

    # cSpell: ignore HRESULT
    for ($attemptNumber = 1; $attemptNumber -le $maxAttempts; $attemptNumber++)
    {
        $invokeCimMethodResult = $CimInstance | Invoke-CimMethod @invokeCimMethodParameters

        <#
            Successfully calling the method returns $invokeCimMethodResult.HRESULT -eq 0.
            If a general error occurs in the Invoke-CimMethod, like calling a method
            that does not exist, returns $null in $invokeCimMethodResult or throws
            an exception (which will terminate immediately without retry).
        #>
        $isSuccess = $null -ne $invokeCimMethodResult -and $invokeCimMethodResult.HRESULT -eq 0

        if ($isSuccess)
        {
            return $invokeCimMethodResult
        }

        # Build error details for this attempt.
        $errorDetails = $null
        $errorKey = $null

        if ($null -ne $invokeCimMethodResult -and $invokeCimMethodResult.HRESULT -ne 0)
        {
            # Handle HRESULT failure.
            $hResult = $invokeCimMethodResult.HRESULT
            $methodErrorDetails = $null

            <#
                The returned object property ExtendedErrors is an array
                so that needs to be concatenated. Check if it has actual
                content before using it.
            #>
            if (($invokeCimMethodResult | Get-Member -Name 'ExtendedErrors') -and $invokeCimMethodResult.ExtendedErrors)
            {
                $methodErrorDetails = $invokeCimMethodResult.ExtendedErrors -join ';'
            }

            # Fall back to Error property if ExtendedErrors was empty or not present.
            if (-not $methodErrorDetails -and ($invokeCimMethodResult | Get-Member -Name 'Error') -and $invokeCimMethodResult.Error)
            {
                $methodErrorDetails = $invokeCimMethodResult.Error
            }

            # Use a fallback message if neither property had content.
            if (-not $methodErrorDetails)
            {
                $methodErrorDetails = $script:localizedData.Invoke_RsCimMethod_NoErrorDetails
            }

            $errorDetails = $script:localizedData.Invoke_RsCimMethod_HResultError -f $hResult, $methodErrorDetails
            $errorKey = "HRESULT:$hResult`:$methodErrorDetails"
        }

        # Track unique errors with attempt number prefix.
        if ($errorDetails -and -not $uniqueErrorKeys.Contains($errorKey))
        {
            $null = $uniqueErrorKeys.Add($errorKey)

            $attemptError = $script:localizedData.Invoke_RsCimMethod_AttemptError -f $attemptNumber, $errorDetails
            $collectedErrors.Add($attemptError)
        }

        Write-Debug -Message ($script:localizedData.Invoke_RsCimMethod_AttemptFailed -f $attemptNumber, $errorDetails)

        # If there are more attempts, wait before retrying.
        if ($attemptNumber -lt $maxAttempts)
        {
            Write-Debug -Message ($script:localizedData.Invoke_RsCimMethod_WaitingBeforeRetry -f $RetryDelaySeconds, ($attemptNumber + 1))

            Start-Sleep -Seconds $RetryDelaySeconds
        }
    }

    # All attempts failed, throw with collected unique errors.
    $allErrors = $collectedErrors -join ' '

    $errorMessage = $script:localizedData.Invoke_RsCimMethod_FailedToInvokeMethod -f $MethodName, $allErrors

    Write-Error -Message $errorMessage -Category 'InvalidResult' -ErrorId 'IRCM0001' -TargetObject $MethodName -ErrorAction 'Stop'
}
