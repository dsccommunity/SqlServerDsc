<#
    .SYNOPSIS
        Removes a SQL Server login.

    .DESCRIPTION
        This command removes a SQL Server login from a SQL Server Database Engine instance.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER LoginObject
        Specifies a login object to remove.

    .PARAMETER Name
        Specifies the name of the server login to be removed.

    .PARAMETER KillActiveSessions
        Specifies that any active sessions for the login should be terminated
        before attempting to drop the login. This is useful when the login has
        active connections that would otherwise prevent the drop operation.

    .PARAMETER Force
        Specifies that the login should be removed without any confirmation.

    .PARAMETER Refresh
        Specifies that the **ServerObject**'s logins should be refreshed before
        trying to remove the login object. This is helpful when logins could have
        been modified outside of the **ServerObject**, for example through T-SQL.
        But on instances with a large number of logins it might be better to make
        sure the **ServerObject** is recent enough, or pass in **LoginObject**.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $loginObject = $serverObject | Get-SqlDscLogin -Name 'MyLogin'
        $loginObject | Remove-SqlDscLogin

        Removes the login named **MyLogin**.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | Remove-SqlDscLogin -Name 'MyLogin'

        Removes the login named **MyLogin**.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | Remove-SqlDscLogin -Name 'MyLogin' -KillActiveSessions -Force

        Removes the login named **MyLogin** after terminating any active sessions
        for the login.

    .INPUTS
        `Microsoft.SqlServer.Management.Smo.Server`

        Specifies a server connection object.

    .INPUTS
        `Microsoft.SqlServer.Management.Smo.Login`

        Specifies a login object.

    .OUTPUTS
        None.
#>
function Remove-SqlDscLogin
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [OutputType([System.Void])]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param
    (
        [Parameter(ParameterSetName = 'ServerObject', Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter(ParameterSetName = 'LoginObject', Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Login]
        $LoginObject,

        [Parameter(ParameterSetName = 'ServerObject', Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $KillActiveSessions,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force,

        [Parameter(ParameterSetName = 'ServerObject')]
        [System.Management.Automation.SwitchParameter]
        $Refresh
    )

    process
    {
        if ($Force.IsPresent -and -not $Confirm)
        {
            $ConfirmPreference = 'None'
        }

        if ($PSCmdlet.ParameterSetName -eq 'ServerObject')
        {
            $getSqlDscLoginParameters = @{
                ServerObject = $ServerObject
                Name         = $Name
                Refresh      = $Refresh
                ErrorAction  = 'Stop'
            }

            # If this command does not find the login it will throw an exception.
            $loginObjectArray = Get-SqlDscLogin @getSqlDscLoginParameters

            # Pick the only object in the array.
            $LoginObject = $loginObjectArray | Select-Object -First 1
        }

        $verboseDescriptionMessage = $script:localizedData.Login_Remove_ShouldProcessVerboseDescription -f $LoginObject.Name, $LoginObject.Parent.InstanceName
        $verboseWarningMessage = $script:localizedData.Login_Remove_ShouldProcessVerboseWarning -f $LoginObject.Name
        $captionMessage = $script:localizedData.Login_Remove_ShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage))
        {
            if ($KillActiveSessions.IsPresent)
            {
                $serverObjectToUse = $LoginObject.Parent

                Write-Debug -Message (
                    $script:localizedData.Login_Remove_KillingActiveSessions -f $LoginObject.Name
                )

                $processes = $serverObjectToUse.EnumProcesses($LoginObject.Name)

                $originalErrorActionPreference = $ErrorActionPreference

                $ErrorActionPreference = 'Stop'

                # cSpell:ignore Spid
                foreach ($process in $processes.Rows)
                {
                    Write-Debug -Message (
                        $script:localizedData.Login_Remove_KillingProcess -f $process.Spid, $LoginObject.Name
                    )

                    # Ignore errors if process already terminated.
                    try
                    {
                        $serverObjectToUse.KillProcess($process.Spid)
                    }
                    catch
                    {
                        # Ignore error if process already terminated.
                        Write-Debug -Message (
                            $script:localizedData.Login_Remove_KillProcessFailed -f $process.Spid, $_.Exception.Message
                        )
                    }
                }

                $ErrorActionPreference = $originalErrorActionPreference
            }

            try
            {
                $originalErrorActionPreference = $ErrorActionPreference

                $ErrorActionPreference = 'Stop'

                $LoginObject.Drop()
            }
            catch
            {
                $errorMessage = $script:localizedData.Login_Remove_Failed -f $LoginObject.Name

                $PSCmdlet.ThrowTerminatingError(
                    [System.Management.Automation.ErrorRecord]::new(
                        [System.InvalidOperationException]::new($errorMessage, $_.Exception),
                        'RSDL0001', # cspell: disable-line
                        [System.Management.Automation.ErrorCategory]::InvalidOperation,
                        $LoginObject
                    )
                )
            }
            finally
            {
                $ErrorActionPreference = $originalErrorActionPreference
            }
        }
    }
}
