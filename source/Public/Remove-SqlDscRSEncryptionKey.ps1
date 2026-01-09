<#
    .SYNOPSIS
        Removes the encryption key from SQL Server Reporting Services.

    .DESCRIPTION
        Removes the encryption key from SQL Server Reporting Services or
        Power BI Report Server by calling the `DeleteEncryptionKey` method
        on the `MSReportServer_ConfigurationSetting` CIM instance.

        This command deletes the current encryption key from the report
        server. Optionally, it can also delete all encrypted information
        stored in the report server database using the
        `-IncludeEncryptedInformation` parameter.

        WARNING: This is a destructive operation. After removing the
        encryption key, stored credentials and connection strings cannot
        be decrypted. The report server will need to be re-initialized
        with a new or restored encryption key.

        The configuration CIM instance can be obtained using the
        `Get-SqlDscRSConfiguration` command and passed via the pipeline.

    .PARAMETER Configuration
        Specifies the `MSReportServer_ConfigurationSetting` CIM instance for
        the Reporting Services instance. This can be obtained using the
        `Get-SqlDscRSConfiguration` command. This parameter accepts pipeline
        input.

    .PARAMETER IncludeEncryptedInformation
        If specified, also deletes all encrypted information stored in the
        report server database. This includes stored credentials, connection
        strings, and other sensitive data that was encrypted with the key.

    .PARAMETER PassThru
        If specified, returns the configuration CIM instance after removing
        the encryption key.

    .PARAMETER Force
        If specified, suppresses the confirmation prompt.

    .EXAMPLE
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | Remove-SqlDscRSEncryptionKey

        Removes the encryption key from the Reporting Services instance.

    .EXAMPLE
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | Remove-SqlDscRSEncryptionKey -IncludeEncryptedInformation -Force

        Removes the encryption key and all encrypted information without
        confirmation.

    .EXAMPLE
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | Remove-SqlDscRSEncryptionKey -PassThru

        Removes the encryption key and returns the configuration CIM instance.

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
        This is a destructive operation. Ensure you have a backup of the
        encryption key before removing it. The Reporting Services service
        may need to be restarted after this operation.

    .LINK
        https://docs.microsoft.com/en-us/sql/reporting-services/wmi-provider-library-reference/configurationsetting-method-deleteencryptionkey
#>
function Remove-SqlDscRSEncryptionKey
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
        $IncludeEncryptedInformation,

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

        Write-Verbose -Message ($script:localizedData.Remove_SqlDscRSEncryptionKey_Removing -f $instanceName)

        $descriptionMessage = $script:localizedData.Remove_SqlDscRSEncryptionKey_ShouldProcessDescription -f $instanceName
        $confirmationMessage = $script:localizedData.Remove_SqlDscRSEncryptionKey_ShouldProcessConfirmation -f $instanceName
        $captionMessage = $script:localizedData.Remove_SqlDscRSEncryptionKey_ShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($descriptionMessage, $confirmationMessage, $captionMessage))
        {
            try
            {
                $invokeRsCimMethodParameters = @{
                    CimInstance = $Configuration
                    MethodName  = 'DeleteEncryptionKey'
                    Arguments   = @{
                        InstallationID = $Configuration.InstallationID
                    }
                }

                $null = Invoke-RsCimMethod @invokeRsCimMethodParameters -ErrorAction 'Stop'
            }
            catch
            {
                $errorRecord = New-ErrorRecord -Message ($script:localizedData.Remove_SqlDscRSEncryptionKey_FailedToRemove -f $instanceName, $_.Exception.Message) -ErrorId 'RRSEK0001' -ErrorCategory 'InvalidOperation' -TargetObject $Configuration

                $PSCmdlet.ThrowTerminatingError($errorRecord)
            }

            if ($IncludeEncryptedInformation.IsPresent)
            {
                Write-Verbose -Message ($script:localizedData.Remove_SqlDscRSEncryptionKey_DeletingEncryptedInformation -f $instanceName)

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
                    $PSCmdlet.ThrowTerminatingError(
                        [System.Management.Automation.ErrorRecord]::new(
                            ($script:localizedData.Remove_SqlDscRSEncryptionKey_FailedToDeleteEncryptedInformation -f $instanceName, $_.Exception.Message),
                            'RRSEK0002',
                            [System.Management.Automation.ErrorCategory]::InvalidOperation,
                            $Configuration
                        )
                    )
                }
            }
        }

        if ($PassThru.IsPresent)
        {
            return $Configuration
        }
    }
}
