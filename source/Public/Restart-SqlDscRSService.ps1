<#
    .SYNOPSIS
        Restarts a SQL Server Reporting Services instance.

    .DESCRIPTION
        Restarts a SQL Server Reporting Services or Power BI Report Server
        Windows service. This command stops the service, optionally waits for
        a specified time, then starts the service again. It also restarts any
        dependent services that were running before the restart.

        The command can be used in two ways:
        - With a configuration CIM instance from `Get-SqlDscRSConfiguration`
        - With a service name directly

    .PARAMETER Configuration
        Specifies the `MSReportServer_ConfigurationSetting` CIM instance for
        the Reporting Services instance. This can be obtained using the
        `Get-SqlDscRSConfiguration` command. This parameter accepts pipeline
        input.

    .PARAMETER ServiceName
        Specifies the name of the Reporting Services Windows service to restart.
        This parameter is used when the service name is known and a configuration
        object is not available.

    .PARAMETER WaitTime
        Specifies the number of seconds to wait after stopping the service
        before starting it again. This can be useful to allow the service to
        fully release resources before restarting. Default value is 0 seconds.

    .PARAMETER Force
        If specified, suppresses the confirmation prompt.

    .PARAMETER PassThru
        If specified, returns the configuration CIM instance after restarting
        the service. Only applicable when using the Configuration parameter.

    .EXAMPLE
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | Restart-SqlDscRSService

        Restarts the Reporting Services instance 'SSRS'.

    .EXAMPLE
        Restart-SqlDscRSService -ServiceName 'SQLServerReportingServices'

        Restarts the Reporting Services service by name.

    .EXAMPLE
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | Restart-SqlDscRSService -WaitTime 30

        Restarts the Reporting Services instance and waits 30 seconds between
        stopping and starting the service.

    .EXAMPLE
        Restart-SqlDscRSService -ServiceName 'SQLServerReportingServices' -Force

        Restarts the service without confirmation.

    .EXAMPLE
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | Restart-SqlDscRSService -PassThru

        Restarts the service and returns the configuration CIM instance.

    .INPUTS
        `Microsoft.Management.Infrastructure.CimInstance`

        Accepts MSReportServer_ConfigurationSetting CIM instance via pipeline.

    .OUTPUTS
        None. By default, this command does not generate any output.

    .OUTPUTS
        `Microsoft.Management.Infrastructure.CimInstance`

        When PassThru is specified and using Configuration parameter, returns
        the MSReportServer_ConfigurationSetting CIM instance.

    .NOTES
        Dependent services that were running before the restart will be
        automatically restarted after the main service starts.

    .LINK
        https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/restart-service
#>
function Restart-SqlDscRSService
{
    # cSpell: ignore PBIRS
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the examples use pipeline input the rule cannot validate.')]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium', DefaultParameterSetName = 'ByServiceName')]
    [OutputType([System.Object])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'ByConfiguration')]
        [System.Object]
        $Configuration,

        [Parameter(Mandatory = $true, ParameterSetName = 'ByServiceName')]
        [System.String]
        $ServiceName,

        [Parameter()]
        [System.UInt16]
        $WaitTime = 0,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $PassThru,

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

        $targetServiceName = $ServiceName

        if ($PSCmdlet.ParameterSetName -eq 'ByConfiguration')
        {
            $targetServiceName = $Configuration.ServiceName
        }

        Write-Verbose -Message ($script:localizedData.Restart_SqlDscRSService_GettingService -f $targetServiceName)

        $reportingServicesService = Get-Service -Name $targetServiceName

        <#
            Get all dependent services that are running.
            There are scenarios where an automatic service is stopped and should
            not be restarted automatically.
        #>
        $dependentService = $reportingServicesService.DependentServices | Where-Object -FilterScript {
            $_.Status -eq 'Running'
        }

        $descriptionMessage = $script:localizedData.Restart_SqlDscRSService_ShouldProcessDescription -f $reportingServicesService.DisplayName
        $confirmationMessage = $script:localizedData.Restart_SqlDscRSService_ShouldProcessConfirmation -f $reportingServicesService.DisplayName
        $captionMessage = $script:localizedData.Restart_SqlDscRSService_ShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($descriptionMessage, $confirmationMessage, $captionMessage))
        {
            $reportingServicesService | Stop-Service -Force

            if ($WaitTime -ne 0)
            {
                Write-Debug -Message ($script:localizedData.Restart_SqlDscRSService_WaitingBeforeStart -f $WaitTime, $reportingServicesService.DisplayName)

                Start-Sleep -Seconds $WaitTime
            }

            $reportingServicesService | Start-Service

            # Start dependent services
            $dependentService | ForEach-Object -Process {
                Write-Debug -Message ($script:localizedData.Restart_SqlDscRSService_StartingDependentService -f $_.DisplayName)

                $_ | Start-Service
            }
        }

        if ($PassThru.IsPresent -and $PSCmdlet.ParameterSetName -eq 'ByConfiguration')
        {
            return $Configuration
        }
    }
}
