<#
    .SYNOPSIS
        Backs up the encryption key for SQL Server Reporting Services.

    .DESCRIPTION
        Backs up the encryption key for SQL Server Reporting Services or
        Power BI Report Server by calling the `BackupEncryptionKey` method
        on the `MSReportServer_ConfigurationSetting` CIM instance.

        The encryption key is essential for decrypting stored credentials
        and connection strings in the report server database. This backup
        should be stored securely and is required for disaster recovery
        or migration scenarios.

        The configuration CIM instance can be obtained using the
        `Get-SqlDscRSConfiguration` command and passed via the pipeline.

    .PARAMETER Configuration
        Specifies the `MSReportServer_ConfigurationSetting` CIM instance for
        the Reporting Services instance. This can be obtained using the
        `Get-SqlDscRSConfiguration` command. This parameter accepts pipeline
        input.

    .PARAMETER Path
        Specifies the full path where the encryption key backup file will
        be saved. The file extension should be .snk (Strong Name Key).

    .PARAMETER Password
        Specifies the password to protect the encryption key backup file.
        This password will be required when restoring the encryption key.

    .PARAMETER Credential
        Specifies the credentials to use when accessing a UNC path. Use this
        parameter when the Path is a network share that requires authentication.

    .PARAMETER DriveName
        Specifies the name of the temporary PSDrive to create when accessing
        a UNC path with credentials. Defaults to 'RSKeyBackup'. This parameter
        can only be used together with the Credential parameter.

    .PARAMETER PassThru
        If specified, returns the configuration CIM instance after backing
        up the encryption key.

    .PARAMETER Force
        If specified, suppresses the confirmation prompt.

    .EXAMPLE
        $password = Read-Host -AsSecureString -Prompt 'Enter backup password'
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | Backup-SqlDscRSEncryptionKey -Path 'C:\Backup\RSKey.snk' -Password $password

        Backs up the encryption key to a local file.

    .EXAMPLE
        $password = ConvertTo-SecureString -String 'MyP@ssw0rd' -AsPlainText -Force
        $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
        Backup-SqlDscRSEncryptionKey -Configuration $config -Path '\\Server\Share\RSKey.snk' -Password $password -Credential (Get-Credential) -Force

        Backs up the encryption key to a UNC path with credentials and
        without confirmation.

    .EXAMPLE
        $password = Read-Host -AsSecureString -Prompt 'Enter backup password'
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | Backup-SqlDscRSEncryptionKey -Path 'C:\Backup\RSKey.snk' -Password $password -PassThru

        Backs up the encryption key and returns the configuration CIM instance.

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
        Store the backup file and password securely. They are required to
        restore the encryption key in disaster recovery scenarios or when
        migrating to a new server.

    .LINK
        https://docs.microsoft.com/en-us/sql/reporting-services/wmi-provider-library-reference/configurationsetting-method-backupencryptionkey
#>
function Backup-SqlDscRSEncryptionKey
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the examples use pipeline input the rule cannot validate.')]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([Microsoft.Management.Infrastructure.CimInstance])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Object]
        $Configuration,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Path,

        [Parameter(Mandatory = $true)]
        [System.Security.SecureString]
        $Password,

        [Parameter(ParameterSetName = 'ByCredential')]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter(ParameterSetName = 'ByCredential')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $DriveName = 'RSKeyBackup',

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

        Write-Verbose -Message ($script:localizedData.Backup_SqlDscRSEncryptionKey_BackingUp -f $instanceName, $Path)

        $descriptionMessage = $script:localizedData.Backup_SqlDscRSEncryptionKey_ShouldProcessDescription -f $instanceName, $Path
        $confirmationMessage = $script:localizedData.Backup_SqlDscRSEncryptionKey_ShouldProcessConfirmation -f $instanceName
        $captionMessage = $script:localizedData.Backup_SqlDscRSEncryptionKey_ShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($descriptionMessage, $confirmationMessage, $captionMessage))
        {
            # Convert SecureString to plain text for the WMI method
            $passwordBstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)

            try
            {
                $passwordPlainText = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($passwordBstr)

                $invokeRsCimMethodParameters = @{
                    CimInstance = $Configuration
                    MethodName  = 'BackupEncryptionKey'
                    Arguments   = @{
                        Password = $passwordPlainText
                    }
                }

                $result = Invoke-RsCimMethod @invokeRsCimMethodParameters -ErrorAction 'Stop'

                # The WMI method returns the key as a byte array in the KeyFile property
                $keyData = $result.KeyFile

                # Handle UNC path with credentials
                $psDriveCreated = $false
                $targetPath = $Path

                if ($PSBoundParameters.ContainsKey('Credential'))
                {
                    $parentPath = Split-Path -Path $Path -Parent

                    if ($parentPath -match '^\\\\')
                    {
                        New-PSDrive -Name $DriveName -PSProvider 'FileSystem' -Root $parentPath -Credential $Credential -ErrorAction 'Stop' | Out-Null

                        $psDriveCreated = $true
                        $fileName = Split-Path -Path $Path -Leaf
                        $targetPath = (Resolve-Path -LiteralPath "${DriveName}:\$fileName").ProviderPath
                    }
                }

                try
                {
                    # Write the key data to file
                    [System.IO.File]::WriteAllBytes($targetPath, $keyData)
                }
                finally
                {
                    if ($psDriveCreated)
                    {
                        Remove-PSDrive -Name $DriveName -Force -ErrorAction 'SilentlyContinue'
                    }
                }
            }
            catch
            {
                $errorMessage = $script:localizedData.Backup_SqlDscRSEncryptionKey_FailedToBackup -f $instanceName

                $exception = New-Exception -Message $errorMessage -ErrorRecord $_

                $errorRecord = New-ErrorRecord -Exception $exception -ErrorId 'BSRSEK0001' -ErrorCategory 'InvalidOperation' -TargetObject $Configuration

                $PSCmdlet.ThrowTerminatingError($errorRecord)
            }
            finally
            {
                # Clear the plain text password from memory
                [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($passwordBstr)
            }
        }

        if ($PassThru.IsPresent)
        {
            return $Configuration
        }
    }
}
