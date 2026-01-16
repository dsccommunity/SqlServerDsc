<#
    .SYNOPSIS
        Stops the Reporting Services Windows service.

    .DESCRIPTION
        Stops the SQL Server Reporting Services or Power BI Report Server
        Windows service by calling the `SetServiceState` WMI method with
        `EnableWindowsService` set to `$false`.

        This command preserves the current state of the web service. If the
        Windows service is already disabled, the command proceeds without error
        (idempotent behavior).

        The configuration CIM instance can be obtained using the
        `Get-SqlDscRSConfiguration` command and passed via the pipeline.

    .PARAMETER Configuration
        Specifies the `MSReportServer_ConfigurationSetting` CIM instance for
        the Reporting Services instance. This can be obtained using the
        `Get-SqlDscRSConfiguration` command. This parameter accepts pipeline
        input.

    .PARAMETER Force
        If specified, suppresses the confirmation prompt.

    .EXAMPLE
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | Stop-SqlDscRSWindowsService

        Stops the Windows service for the SSRS instance by piping the configuration
        from `Get-SqlDscRSConfiguration`.

    .EXAMPLE
        $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
        Stop-SqlDscRSWindowsService -Configuration $config -Force

        Stops the Windows service for the SSRS instance without confirmation.

    .INPUTS
        `Microsoft.Management.Infrastructure.CimInstance`

        Accepts MSReportServer_ConfigurationSetting CIM instance via pipeline.

    .OUTPUTS
        None.
#>
function Stop-SqlDscRSWindowsService
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the examples use pipeline input the rule cannot validate.')]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType()]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Object]
        $Configuration,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    process
    {
        if ($Force.IsPresent -and -not $Confirm)
        {
            $ConfirmPreference = 'None'
        }

        $instanceName = $Configuration.InstanceName

        Write-Verbose -Message ($script:localizedData.Stop_SqlDscRSWindowsService_Stopping -f $instanceName)

        $descriptionMessage = $script:localizedData.Stop_SqlDscRSWindowsService_ShouldProcessDescription -f $instanceName
        $confirmationMessage = $script:localizedData.Stop_SqlDscRSWindowsService_ShouldProcessConfirmation -f $instanceName
        $captionMessage = $script:localizedData.Stop_SqlDscRSWindowsService_ShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($descriptionMessage, $confirmationMessage, $captionMessage))
        {
            $serviceStateArguments = Get-RSServiceState -Configuration $Configuration -DisableWindowsService

            $invokeRsCimMethodParameters = @{
                CimInstance = $Configuration
                MethodName  = 'SetServiceState'
                Arguments   = $serviceStateArguments
            }

            try
            {
                $null = Invoke-RsCimMethod @invokeRsCimMethodParameters
            }
            catch
            {
                $errorMessage = $script:localizedData.Stop_SqlDscRSWindowsService_FailedToStop -f $instanceName

                $exception = New-Exception -Message $errorMessage -ErrorRecord $_

                $errorRecord = New-ErrorRecord -Exception $exception -ErrorId 'SRSWS0001' -ErrorCategory 'InvalidOperation' -TargetObject $Configuration

                $PSCmdlet.ThrowTerminatingError($errorRecord)
            }
        }
    }
}
