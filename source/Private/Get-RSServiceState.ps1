<#
    .SYNOPSIS
        Gets the service state arguments for the SetServiceState method.

    .DESCRIPTION
        A helper function that reads the current service state from the
        Reporting Services configuration CIM instance and returns the arguments
        needed for the SetServiceState WMI method. This function preserves the
        state of services that are not being changed.

        The function reads the `IsWindowsServiceEnabled` and `IsWebServiceEnabled`
        properties from the configuration instance and applies the requested
        change.

    .PARAMETER Configuration
        The CIM instance object that contains the Reporting Services configuration.
        This is typically obtained from `Get-SqlDscRSConfiguration`.

    .PARAMETER EnableWindowsService
        If specified, sets the `EnableWindowsService` argument to `$true`.

    .PARAMETER DisableWindowsService
        If specified, sets the `EnableWindowsService` argument to `$false`.

    .PARAMETER EnableWebService
        If specified, sets the `EnableWebService` argument to `$true`.

    .PARAMETER DisableWebService
        If specified, sets the `EnableWebService` argument to `$false`.

    .OUTPUTS
        System.Collections.Hashtable

        Returns a hashtable with the following keys:
        - EnableWindowsService: Boolean value for the Windows service state.
        - EnableWebService: Boolean value for the web service state.
        - EnableReportManager: Boolean value (deprecated, always matches EnableWebService).

    .EXAMPLE
        $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
        Get-RSServiceState -Configuration $config -EnableWindowsService

        Returns a hashtable with EnableWindowsService set to $true and the
        current state of EnableWebService preserved.

    .EXAMPLE
        $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
        Get-RSServiceState -Configuration $config -DisableWebService

        Returns a hashtable with EnableWebService set to $false and the
        current state of EnableWindowsService preserved.
#>
function Get-RSServiceState
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Object]
        $Configuration,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $EnableWindowsService,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $DisableWindowsService,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $EnableWebService,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $DisableWebService
    )

    # Get the current state from the configuration instance.
    $currentWindowsServiceEnabled = $Configuration.IsWindowsServiceEnabled
    $currentWebServiceEnabled = $Configuration.IsWebServiceEnabled

    Write-Debug -Message ($script:localizedData.Get_RSServiceState_CurrentState -f $currentWindowsServiceEnabled, $currentWebServiceEnabled)

    # Initialize the result with current state.
    $windowsServiceState = $currentWindowsServiceEnabled
    $webServiceState = $currentWebServiceEnabled

    # Apply the requested changes.
    if ($EnableWindowsService.IsPresent)
    {
        $windowsServiceState = $true
    }
    elseif ($DisableWindowsService.IsPresent)
    {
        $windowsServiceState = $false
    }

    if ($EnableWebService.IsPresent)
    {
        $webServiceState = $true
    }
    elseif ($DisableWebService.IsPresent)
    {
        $webServiceState = $false
    }

    Write-Debug -Message ($script:localizedData.Get_RSServiceState_NewState -f $windowsServiceState, $webServiceState)

    # Return the arguments hashtable for SetServiceState.
    return @{
        EnableWindowsService = $windowsServiceState
        EnableWebService     = $webServiceState
        # EnableReportManager is deprecated since SQL Server 2016 CU2, but we still need to pass it.
        EnableReportManager  = $webServiceState
    }
}
