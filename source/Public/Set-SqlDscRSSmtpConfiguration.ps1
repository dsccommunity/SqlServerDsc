<#
    .SYNOPSIS
        Sets the SMTP configuration for SQL Server Reporting Services.

    .DESCRIPTION
        Sets the SMTP configuration for SQL Server Reporting Services
        or Power BI Report Server by calling the `SetEmailConfiguration`
        method on the `MSReportServer_ConfigurationSetting` CIM instance.

        This command configures the SMTP settings used for email delivery
        of reports through subscriptions.

        The configuration CIM instance can be obtained using the
        `Get-SqlDscRSConfiguration` command and passed via the pipeline.

    .PARAMETER Configuration
        Specifies the `MSReportServer_ConfigurationSetting` CIM instance for
        the Reporting Services instance. This can be obtained using the
        `Get-SqlDscRSConfiguration` command. This parameter accepts pipeline
        input.

    .PARAMETER SmtpServer
        Specifies the SMTP server to use for sending email. This can be a
        server name or IP address.

    .PARAMETER SenderEmailAddress
        Specifies the email address to use in the "From" field of sent emails.

    .PARAMETER PassThru
        If specified, returns the configuration CIM instance after setting
        the SMTP configuration.

    .PARAMETER Force
        If specified, suppresses the confirmation prompt.

    .EXAMPLE
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | Set-SqlDscRSSmtpConfiguration -SmtpServer 'smtp.contoso.com' -SenderEmailAddress 'reports@contoso.com'

        Configures SMTP delivery using the specified SMTP server.

    .EXAMPLE
        $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
        Set-SqlDscRSSmtpConfiguration -Configuration $config -SmtpServer 'smtp.contoso.com' -SenderEmailAddress 'reports@contoso.com' -Force

        Configures SMTP delivery without confirmation.

    .EXAMPLE
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | Set-SqlDscRSSmtpConfiguration -SmtpServer 'smtp.contoso.com' -SenderEmailAddress 'reports@contoso.com' -PassThru

        Configures SMTP delivery and returns the configuration CIM instance.

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
        The Reporting Services service may need to be restarted for the
        changes to take effect.

    .LINK
        https://docs.microsoft.com/en-us/sql/reporting-services/wmi-provider-library-reference/configurationsetting-method-setemailconfiguration
#>
function Set-SqlDscRSSmtpConfiguration
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the examples use pipeline input the rule cannot validate.')]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([System.Object])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Object]
        $Configuration,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SmtpServer,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SenderEmailAddress,

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

        Write-Verbose -Message ($script:localizedData.Set_SqlDscRSSmtpConfiguration_Setting -f $SmtpServer, $instanceName)

        $descriptionMessage = $script:localizedData.Set_SqlDscRSSmtpConfiguration_ShouldProcessDescription -f $SmtpServer, $SenderEmailAddress, $instanceName
        $confirmationMessage = $script:localizedData.Set_SqlDscRSSmtpConfiguration_ShouldProcessConfirmation -f $SmtpServer
        $captionMessage = $script:localizedData.Set_SqlDscRSSmtpConfiguration_ShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($descriptionMessage, $confirmationMessage, $captionMessage))
        {
            $invokeRsCimMethodParameters = @{
                CimInstance = $Configuration
                MethodName  = 'SetEmailConfiguration'
                Arguments   = @{
                    SendUsingSMTPServer = $true
                    SMTPServer          = $SmtpServer
                    SenderEmailAddress  = $SenderEmailAddress
                }
            }

            try
            {
                $null = Invoke-RsCimMethod @invokeRsCimMethodParameters -ErrorAction 'Stop'
            }
            catch
            {
                $errorMessage = $script:localizedData.Set_SqlDscRSSmtpConfiguration_FailedToSet -f $instanceName

                $exception = New-Exception -Message $errorMessage -ErrorRecord $_

                $errorRecord = New-ErrorRecord -Exception $exception -ErrorId 'SSRSSC0001' -ErrorCategory 'InvalidOperation' -TargetObject $Configuration

                $PSCmdlet.ThrowTerminatingError($errorRecord)
            }
        }

        if ($PassThru.IsPresent)
        {
            return $Configuration
        }
    }
}
