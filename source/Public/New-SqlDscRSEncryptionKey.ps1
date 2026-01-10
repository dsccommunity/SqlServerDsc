<#
    .SYNOPSIS
        Generates a new encryption key for SQL Server Reporting Services.

    .DESCRIPTION
        Generates a new encryption key for SQL Server Reporting Services or
        Power BI Report Server by calling the `ReencryptSecureInformation`
        method on the `MSReportServer_ConfigurationSetting` CIM instance.

        This command generates a new symmetric encryption key and re-encrypts
        all stored secure information (such as credentials and connection
        strings) with the new key. This operation is typically performed
        when security requirements mandate key rotation.

        WARNING: After generating a new encryption key, you should immediately
        back up the new key using `Backup-SqlDscRSEncryptionKey`. Any previous
        encryption key backups will no longer be valid.

        The configuration CIM instance can be obtained using the
        `Get-SqlDscRSConfiguration` command and passed via the pipeline.

    .PARAMETER Configuration
        Specifies the `MSReportServer_ConfigurationSetting` CIM instance for
        the Reporting Services instance. This can be obtained using the
        `Get-SqlDscRSConfiguration` command. This parameter accepts pipeline
        input.

    .PARAMETER PassThru
        If specified, returns the configuration CIM instance after generating
        the new encryption key.

    .PARAMETER Force
        If specified, suppresses the confirmation prompt.

    .EXAMPLE
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | New-SqlDscRSEncryptionKey

        Generates a new encryption key for the Reporting Services instance.

    .EXAMPLE
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | New-SqlDscRSEncryptionKey -Force

        Generates a new encryption key without confirmation.

    .EXAMPLE
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | New-SqlDscRSEncryptionKey -PassThru

        Generates a new encryption key and returns the configuration CIM instance.

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
        This operation invalidates any existing encryption key backups.
        Immediately back up the new encryption key after this operation.
        The Reporting Services service may need to be restarted after
        generating a new encryption key.

    .LINK
        https://docs.microsoft.com/en-us/sql/reporting-services/wmi-provider-library-reference/configurationsetting-method-reencryptsecureinformation
#>
function New-SqlDscRSEncryptionKey
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the examples use pipeline input the rule cannot validate.')]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
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

        Write-Verbose -Message ($script:localizedData.New_SqlDscRSEncryptionKey_Generating -f $instanceName)

        $descriptionMessage = $script:localizedData.New_SqlDscRSEncryptionKey_ShouldProcessDescription -f $instanceName
        $confirmationMessage = $script:localizedData.New_SqlDscRSEncryptionKey_ShouldProcessConfirmation -f $instanceName
        $captionMessage = $script:localizedData.New_SqlDscRSEncryptionKey_ShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($descriptionMessage, $confirmationMessage, $captionMessage))
        {
            $invokeRsCimMethodParameters = @{
                CimInstance = $Configuration
                MethodName  = 'ReencryptSecureInformation'
            }

            try
            {
                $null = Invoke-RsCimMethod @invokeRsCimMethodParameters -ErrorAction 'Stop'

                Write-Warning -Message ($script:localizedData.New_SqlDscRSEncryptionKey_BackupReminder)
            }
            catch
            {
                $errorMessage = $script:localizedData.New_SqlDscRSEncryptionKey_FailedToGenerate -f $instanceName, $_.Exception.Message

                $errorRecord = New-ErrorRecord -Exception (New-InvalidOperationException -Message $errorMessage -ErrorRecord $_ -PassThru) -ErrorId 'NSRSEK0001' -ErrorCategory 'InvalidOperation' -TargetObject $Configuration

                $PSCmdlet.ThrowTerminatingError($errorRecord)
            }
        }

        if ($PassThru.IsPresent)
        {
            return $Configuration
        }
    }
}
