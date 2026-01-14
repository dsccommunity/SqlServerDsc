<#
    .SYNOPSIS
        Removes the unattended execution account from SQL Server Reporting Services.

    .DESCRIPTION
        Removes the unattended execution account from SQL Server Reporting
        Services or Power BI Report Server by calling the
        `RemoveUnattendedExecutionAccount` method on the
        `MSReportServer_ConfigurationSetting` CIM instance.

        After removing the unattended execution account, reports that require
        credentials but have no user context (such as scheduled subscriptions
        with data sources that require credentials) will fail.

        The configuration CIM instance can be obtained using the
        `Get-SqlDscRSConfiguration` command and passed via the pipeline.

    .PARAMETER Configuration
        Specifies the `MSReportServer_ConfigurationSetting` CIM instance for
        the Reporting Services instance. This can be obtained using the
        `Get-SqlDscRSConfiguration` command. This parameter accepts pipeline
        input.

    .PARAMETER PassThru
        If specified, returns the configuration CIM instance after removing
        the unattended execution account.

    .PARAMETER Force
        If specified, suppresses the confirmation prompt.

    .EXAMPLE
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | Remove-SqlDscRSUnattendedExecutionAccount

        Removes the unattended execution account from the Reporting Services
        instance.

    .EXAMPLE
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | Remove-SqlDscRSUnattendedExecutionAccount -Force

        Removes the unattended execution account without confirmation.

    .EXAMPLE
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | Remove-SqlDscRSUnattendedExecutionAccount -PassThru

        Removes the unattended execution account and returns the configuration
        CIM instance.

    .INPUTS
        `Microsoft.Management.Infrastructure.CimInstance`

        Accepts MSReportServer_ConfigurationSetting CIM instance via pipeline.

    .OUTPUTS
        None. By default, this command does not generate any output.

    .OUTPUTS
        `Microsoft.Management.Infrastructure.CimInstance`

        When PassThru is specified, returns the MSReportServer_ConfigurationSetting
        CIM instance.

    .NOTES
        After removing the unattended execution account, scheduled reports
        and subscriptions that rely on this account may fail.

    .LINK
        https://docs.microsoft.com/en-us/sql/reporting-services/wmi-provider-library-reference/configurationsetting-method-removeunattendedexecutionaccount
#>
function Remove-SqlDscRSUnattendedExecutionAccount
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the examples use pipeline input the rule cannot validate.')]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([System.Object])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Object]
        $Configuration,

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

        $instanceName = $Configuration.InstanceName

        Write-Verbose -Message ($script:localizedData.Remove_SqlDscRSUnattendedExecutionAccount_Removing -f $instanceName)

        $descriptionMessage = $script:localizedData.Remove_SqlDscRSUnattendedExecutionAccount_ShouldProcessDescription -f $instanceName
        $confirmationMessage = $script:localizedData.Remove_SqlDscRSUnattendedExecutionAccount_ShouldProcessConfirmation -f $instanceName
        $captionMessage = $script:localizedData.Remove_SqlDscRSUnattendedExecutionAccount_ShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($descriptionMessage, $confirmationMessage, $captionMessage))
        {
            $invokeRsCimMethodParameters = @{
                CimInstance = $Configuration
                MethodName  = 'RemoveUnattendedExecutionAccount'
            }

            try
            {
                $null = Invoke-RsCimMethod @invokeRsCimMethodParameters -ErrorAction 'Stop'
            }
            catch
            {
                $PSCmdlet.ThrowTerminatingError(
                    [System.Management.Automation.ErrorRecord]::new(
                        ($script:localizedData.Remove_SqlDscRSUnattendedExecutionAccount_FailedToRemove -f $instanceName, $_.Exception.Message),
                        'RSRUEA0001',
                        [System.Management.Automation.ErrorCategory]::InvalidOperation,
                        $Configuration
                    )
                )
            }
        }

        if ($PassThru.IsPresent)
        {
            return $Configuration
        }
    }
}
