<#
    .SYNOPSIS
        Restores the encryption key for SQL Server Reporting Services.

    .DESCRIPTION
        Restores the encryption key for SQL Server Reporting Services or
        Power BI Report Server by calling the `RestoreEncryptionKey` method
        on the `MSReportServer_ConfigurationSetting` CIM instance.

        This command restores a previously backed up encryption key to
        the report server. This is required after migrating to a new server
        or in disaster recovery scenarios to decrypt stored credentials
        and connection strings in the report server database.

        The configuration CIM instance can be obtained using the
        `Get-SqlDscRSConfiguration` command and passed via the pipeline.

    .PARAMETER Configuration
        Specifies the `MSReportServer_ConfigurationSetting` CIM instance for
        the Reporting Services instance. This can be obtained using the
        `Get-SqlDscRSConfiguration` command. This parameter accepts pipeline
        input.

    .PARAMETER Path
        Specifies the full path to the encryption key backup file (.snk).

    .PARAMETER Password
        Specifies the password that was used when backing up the encryption
        key.

    .PARAMETER Credential
        Specifies the credentials to use when accessing a UNC path. Use this
        parameter when the Path is a network share that requires authentication.

    .PARAMETER DriveName
        Specifies the name of the temporary PSDrive to create when accessing
        a UNC path with credentials. Defaults to 'RSKeyRestore'. This parameter
        can only be used together with the Credential parameter.

    .PARAMETER PassThru
        If specified, returns the configuration CIM instance after restoring
        the encryption key.

    .PARAMETER Force
        If specified, suppresses the confirmation prompt.

    .EXAMPLE
        $password = Read-Host -AsSecureString -Prompt 'Enter backup password'
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | Restore-SqlDscRSEncryptionKey -Path 'C:\Backup\RSKey.snk' -Password $password

        Restores the encryption key from a local file.

    .EXAMPLE
        $password = ConvertTo-SecureString -String 'MyP@ssw0rd' -AsPlainText -Force
        $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
        Restore-SqlDscRSEncryptionKey -Configuration $config -Path '\\Server\Share\RSKey.snk' -Password $password -Credential (Get-Credential) -Force

        Restores the encryption key from a UNC path with credentials and
        without confirmation.

    .EXAMPLE
        $password = Read-Host -AsSecureString -Prompt 'Enter backup password'
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | Restore-SqlDscRSEncryptionKey -Path 'C:\Backup\RSKey.snk' -Password $password -PassThru

        Restores the encryption key and returns the configuration CIM instance.

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
        The Reporting Services service may need to be restarted after restoring
        the encryption key.

    .LINK
        https://docs.microsoft.com/en-us/sql/reporting-services/wmi-provider-library-reference/configurationsetting-method-restoreencryptionkey
#>
function Restore-SqlDscRSEncryptionKey
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the examples use pipeline input the rule cannot validate.')]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
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
        $DriveName = 'RSKeyRestore',

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

        Write-Verbose -Message ($script:localizedData.Restore_SqlDscRSEncryptionKey_Restoring -f $instanceName, $Path)

        $descriptionMessage = $script:localizedData.Restore_SqlDscRSEncryptionKey_ShouldProcessDescription -f $instanceName, $Path
        $confirmationMessage = $script:localizedData.Restore_SqlDscRSEncryptionKey_ShouldProcessConfirmation -f $instanceName
        $captionMessage = $script:localizedData.Restore_SqlDscRSEncryptionKey_ShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($descriptionMessage, $confirmationMessage, $captionMessage))
        {
            # Convert SecureString to plain text for the WMI method
            $passwordBstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)

            try
            {
                $passwordPlainText = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($passwordBstr)

                # Handle UNC path with credentials
                $psDriveCreated = $false
                $sourcePath = $Path

                if ($PSBoundParameters.ContainsKey('Credential'))
                {
                    $parentPath = Split-Path -Path $Path -Parent

                    if ($parentPath -match '^\\\\')
                    {
                        New-PSDrive -Name $DriveName -PSProvider 'FileSystem' -Root $parentPath -Credential $Credential -ErrorAction 'Stop' | Out-Null

                        $psDriveCreated = $true
                        $fileName = Split-Path -Path $Path -Leaf
                        $sourcePath = (Resolve-Path -LiteralPath "${DriveName}:\$fileName").ProviderPath
                    }
                }

                try
                {
                    # Read the key data from file
                    $keyData = [System.IO.File]::ReadAllBytes($sourcePath)
                }
                finally
                {
                    if ($psDriveCreated)
                    {
                        Remove-PSDrive -Name $DriveName -Force -ErrorAction 'SilentlyContinue'
                    }
                }

                $invokeRsCimMethodParameters = @{
                    CimInstance = $Configuration
                    MethodName  = 'RestoreEncryptionKey'
                    Arguments   = @{
                        KeyFile  = $keyData
                        Length   = $keyData.Length
                        Password = $passwordPlainText
                    }
                }

                $null = Invoke-RsCimMethod @invokeRsCimMethodParameters -ErrorAction 'Stop'
            }
            catch
            {
                $errorMessage = $script:localizedData.Restore_SqlDscRSEncryptionKey_FailedToRestore -f $instanceName

                $exception = New-Exception -Message $errorMessage -ErrorRecord $_

                $errorRecord = New-ErrorRecord -Exception $exception -ErrorId 'RSRSEK0001' -ErrorCategory 'InvalidOperation' -TargetObject $Configuration

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
