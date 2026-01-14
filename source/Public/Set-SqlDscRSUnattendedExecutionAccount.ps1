<#
    .SYNOPSIS
        Sets the unattended execution account for SQL Server Reporting Services.

    .DESCRIPTION
        Sets the unattended execution account for SQL Server Reporting Services
        or Power BI Report Server by calling the `SetUnattendedExecutionAccount`
        method on the `MSReportServer_ConfigurationSetting` CIM instance.

        The unattended execution account is used when running reports that
        require credentials for data sources but no user credentials are
        available, such as scheduled subscriptions.

        The configuration CIM instance can be obtained using the
        `Get-SqlDscRSConfiguration` command and passed via the pipeline.

    .PARAMETER Configuration
        Specifies the `MSReportServer_ConfigurationSetting` CIM instance for
        the Reporting Services instance. This can be obtained using the
        `Get-SqlDscRSConfiguration` command. This parameter accepts pipeline
        input.

    .PARAMETER Credential
        Specifies the credentials for the unattended execution account. This
        account should have minimal permissions, only what is required to
        access data sources.

    .PARAMETER PassThru
        If specified, returns the configuration CIM instance after setting
        the unattended execution account.

    .PARAMETER Force
        If specified, suppresses the confirmation prompt.

    .EXAMPLE
        $credential = Get-Credential
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | Set-SqlDscRSUnattendedExecutionAccount -Credential $credential

        Sets the unattended execution account for the Reporting Services instance.

    .EXAMPLE
        $credential = Get-Credential
        $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
        Set-SqlDscRSUnattendedExecutionAccount -Configuration $config -Credential $credential -Force

        Sets the unattended execution account without confirmation.

    .EXAMPLE
        $credential = Get-Credential
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | Set-SqlDscRSUnattendedExecutionAccount -Credential $credential -PassThru

        Sets the unattended execution account and returns the configuration
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
        The Reporting Services service may need to be restarted for the
        changes to take effect.

        The unattended execution account credentials are stored encrypted
        in the report server database.

    .LINK
        https://docs.microsoft.com/en-us/sql/reporting-services/wmi-provider-library-reference/configurationsetting-method-setunattendedexecutionaccount
#>
function Set-SqlDscRSUnattendedExecutionAccount
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
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $PassThru,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    # cSpell:ignore BSTR
    process
    {
        if ($Force.IsPresent -and -not $Confirm)
        {
            $ConfirmPreference = 'None'
        }

        $instanceName = $Configuration.InstanceName
        $userName = $Credential.UserName

        Write-Verbose -Message ($script:localizedData.Set_SqlDscRSUnattendedExecutionAccount_Setting -f $userName, $instanceName)

        $descriptionMessage = $script:localizedData.Set_SqlDscRSUnattendedExecutionAccount_ShouldProcessDescription -f $userName, $instanceName
        $confirmationMessage = $script:localizedData.Set_SqlDscRSUnattendedExecutionAccount_ShouldProcessConfirmation -f $userName
        $captionMessage = $script:localizedData.Set_SqlDscRSUnattendedExecutionAccount_ShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($descriptionMessage, $confirmationMessage, $captionMessage))
        {
            $passwordBstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Credential.Password)

            try
            {
                $passwordPlainText = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($passwordBstr)

                $invokeRsCimMethodParameters = @{
                    CimInstance = $Configuration
                    MethodName  = 'SetUnattendedExecutionAccount'
                    Arguments   = @{
                        UserName = $userName
                        Password = $passwordPlainText
                    }
                }

                $null = Invoke-RsCimMethod @invokeRsCimMethodParameters -ErrorAction 'Stop'
            }
            catch
            {
                $PSCmdlet.ThrowTerminatingError(
                    [System.Management.Automation.ErrorRecord]::new(
                        ($script:localizedData.Set_SqlDscRSUnattendedExecutionAccount_FailedToSet -f $instanceName, $_.Exception.Message),
                        'SSRUEA0001',
                        [System.Management.Automation.ErrorCategory]::InvalidOperation,
                        $Configuration
                    )
                )
            }
            finally
            {
                [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($passwordBstr)
            }
        }

        if ($PassThru.IsPresent)
        {
            return $Configuration
        }
    }
}
