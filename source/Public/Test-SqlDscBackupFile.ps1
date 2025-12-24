<#
    .SYNOPSIS
        Verifies the integrity of a SQL Server backup file.

    .DESCRIPTION
        This command verifies the integrity of a SQL Server backup file using
        SQL Server Management Objects (SMO). It uses the Restore.SqlVerify()
        method to check that the backup file is readable and that all data
        can be successfully read.

    .PARAMETER ServerObject
        Specifies the current server connection object.

    .PARAMETER BackupFile
        Specifies the full path to the backup file to verify.

    .PARAMETER FileNumber
        Specifies the backup set number to verify when the backup file contains
        multiple backup sets. If not specified, the first backup set is verified.

    .PARAMETER LoadHistory
        Specifies whether to load the backup history during verification.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | Test-SqlDscBackupFile -BackupFile 'C:\Backups\MyDatabase.bak'

        Verifies the integrity of the specified backup file and returns $true
        if the backup is valid, or $false if it is not.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | Test-SqlDscBackupFile -BackupFile 'C:\Backups\MyDatabase.bak' -LoadHistory

        Verifies the integrity of the specified backup file and loads the backup
        history during verification.

    .INPUTS
        `Microsoft.SqlServer.Management.Smo.Server`

        Server object accepted from the pipeline.

    .OUTPUTS
        `System.Boolean`

        Returns $true if the backup file is valid, $false otherwise. Use
        -Verbose to see detailed error messages when verification fails.
#>
function Test-SqlDscBackupFile
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [OutputType([System.Boolean])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $BackupFile,

        [Parameter()]
        [ValidateRange(1, 2147483647)]
        [System.Int32]
        $FileNumber,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $LoadHistory
    )

    process
    {
        Write-Debug -Message ($script:localizedData.Test_SqlDscBackupFile_Verifying -f $BackupFile)

        # Create the restore object for verification
        $restore = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Restore'

        # Create and add the backup device
        $backupDevice = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.BackupDeviceItem' -ArgumentList $BackupFile, 'File'
        $restore.Devices.Add($backupDevice)

        if ($PSBoundParameters.ContainsKey('FileNumber'))
        {
            $restore.FileNumber = $FileNumber
        }

        try
        {
            # Verify the backup with error message output
            $errorMessage = $null
            $result = $restore.SqlVerify($ServerObject, $LoadHistory.IsPresent, [ref] $errorMessage)
        }
        catch
        {
            $errorMessageText = $script:localizedData.Test_SqlDscBackupFile_Error -f $BackupFile

            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    [System.InvalidOperationException]::new($errorMessageText, $_.Exception),
                    'TSBF0004', # cspell: disable-line
                    [System.Management.Automation.ErrorCategory]::InvalidOperation,
                    $BackupFile
                )
            )
        }

        if ($result)
        {
            Write-Debug -Message ($script:localizedData.Test_SqlDscBackupFile_VerifySuccess -f $BackupFile)
        }
        else
        {
            # If verification failed, output the detailed error message as verbose
            $verboseMessage = $script:localizedData.Test_SqlDscBackupFile_VerifyFailed -f $BackupFile, ($errorMessage | Out-String)

            Write-Verbose -Message $verboseMessage
        }

        return $result
    }
}
