<#
    .SYNOPSIS
        Removes encrypted information from SQL Server Reporting Services.

    .DESCRIPTION
        Removes all encrypted information stored in the SQL Server Reporting
        Services or Power BI Report Server database by calling the
        `DeleteEncryptedInformation` method on the
        `MSReportServer_ConfigurationSetting` CIM instance.

        This command deletes all encrypted data stored in the report server
        database, including stored credentials, connection strings, and
        other sensitive data.

        WARNING: This is a destructive operation. After removing encrypted
        information, stored credentials and connection strings are permanently
        deleted and cannot be recovered. The report server will need to be
        re-initialized and data sources will need to be reconfigured with
        new credentials.

        The configuration CIM instance can be obtained using the
        `Get-SqlDscRSConfiguration` command and passed via the pipeline.

    .PARAMETER Configuration
        Specifies the `MSReportServer_ConfigurationSetting` CIM instance for
        the Reporting Services instance. This can be obtained using the
        `Get-SqlDscRSConfiguration` command. This parameter accepts pipeline
        input.

    .PARAMETER PassThru
        If specified, returns the configuration CIM instance after removing
        the encrypted information.

    .PARAMETER Force
        If specified, suppresses the confirmation prompt.

    .EXAMPLE
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | Remove-SqlDscRSEncryptedInformation

        Removes all encrypted information from the Reporting Services instance.

    .EXAMPLE
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | Remove-SqlDscRSEncryptedInformation -Force

        Removes all encrypted information without confirmation.

    .EXAMPLE
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | Remove-SqlDscRSEncryptedInformation -PassThru

        Removes all encrypted information and returns the configuration CIM instance.

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
        This is a destructive operation. Ensure you understand the impact
        before removing encrypted information. The Reporting Services service
        may need to be restarted after this operation.

    .LINK
        https://docs.microsoft.com/en-us/sql/reporting-services/wmi-provider-library-reference/configurationsetting-method-deleteencryptedinformation
#>
function Remove-SqlDscRSEncryptedInformation
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the examples use pipeline input the rule cannot validate.')]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([Microsoft.Management.Infrastructure.CimInstance])]
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

        Write-Verbose -Message ($script:localizedData.Remove_SqlDscRSEncryptedInformation_Removing -f $instanceName)

        $descriptionMessage = $script:localizedData.Remove_SqlDscRSEncryptedInformation_ShouldProcessDescription -f $instanceName
        $confirmationMessage = $script:localizedData.Remove_SqlDscRSEncryptedInformation_ShouldProcessConfirmation -f $instanceName
        $captionMessage = $script:localizedData.Remove_SqlDscRSEncryptedInformation_ShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($descriptionMessage, $confirmationMessage, $captionMessage))
        {
            try
            {
                $invokeRsCimMethodParameters = @{
                    CimInstance = $Configuration
                    MethodName  = 'DeleteEncryptedInformation'
                }

                $null = Invoke-RsCimMethod @invokeRsCimMethodParameters -ErrorAction 'Stop'
            }
            catch
            {
                $errorRecord = New-ErrorRecord -Message ($script:localizedData.Remove_SqlDscRSEncryptedInformation_FailedToRemove -f $instanceName, $_.Exception.Message) -ErrorId 'RRSREI0001' -ErrorCategory 'InvalidOperation' -TargetObject $Configuration

                $PSCmdlet.ThrowTerminatingError($errorRecord)
            }
        }

        if ($PassThru.IsPresent)
        {
            return $Configuration
        }
    }
}
