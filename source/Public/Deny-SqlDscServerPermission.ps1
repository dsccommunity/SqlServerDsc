<#
    .SYNOPSIS
        Denies server permissions to a principal on a SQL Server Database Engine instance.

    .DESCRIPTION
        This command denies server permissions to an existing principal on a SQL Server
        Database Engine instance. The principal can be specified as either a Login
        object (from Get-SqlDscLogin) or a ServerRole object (from Get-SqlDscRole).

    .PARAMETER Login
        Specifies the Login object for which the permissions are denied.
        This parameter accepts pipeline input.

    .PARAMETER ServerRole
        Specifies the ServerRole object for which the permissions are denied.
        This parameter accepts pipeline input.

    .PARAMETER Permission
        Specifies the permissions to be denied. Specify multiple permissions by
        providing an array of SqlServerPermission enum values.

    .PARAMETER Force
        Specifies that the permissions should be denied without any confirmation.

    .OUTPUTS
        None.

    .EXAMPLE
        $serverInstance = Connect-SqlDscDatabaseEngine
        $login = $serverInstance | Get-SqlDscLogin -Name 'MyLogin'

        Deny-SqlDscServerPermission -Login $login -Permission ConnectSql, ViewServerState

        Denies the specified permissions to the login 'MyLogin'.

    .EXAMPLE
        $serverInstance = Connect-SqlDscDatabaseEngine
        $role = $serverInstance | Get-SqlDscRole -Name 'MyRole'

        $role | Deny-SqlDscServerPermission -Permission AlterAnyDatabase -Force

        Denies the specified permissions to the role 'MyRole' without prompting for confirmation.

    .NOTES
        The Login or ServerRole object must come from the same SQL Server instance
        where the permissions will be denied. If specifying `-ErrorAction 'SilentlyContinue'`
        then the command will silently continue if any errors occur. If specifying
        `-ErrorAction 'Stop'` the command will throw an error on any failure.
#>
function Deny-SqlDscServerPermission
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('AvoidThrowOutsideOfTry', '', Justification = 'Because the code throws based on an prior expression')]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType()]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'Login')]
        [Microsoft.SqlServer.Management.Smo.Login]
        $Login,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'ServerRole')]
        [Microsoft.SqlServer.Management.Smo.ServerRole]
        $ServerRole,

        [Parameter(Mandatory = $true)]
        [SqlServerPermission[]]
        $Permission,

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

        # Determine which principal object we're working with
        if ($PSCmdlet.ParameterSetName -eq 'Login')
        {
            $principalName = $Login.Name
            $serverObject = $Login.Parent
        }
        else
        {
            $principalName = $ServerRole.Name
            $serverObject = $ServerRole.Parent
        }

        $verboseDescriptionMessage = $script:localizedData.ServerPermission_Deny_ShouldProcessVerboseDescription -f $principalName, $serverObject.InstanceName, ($Permission -join ',')
        $verboseWarningMessage = $script:localizedData.ServerPermission_Deny_ShouldProcessVerboseWarning -f $principalName
        $captionMessage = $script:localizedData.ServerPermission_Deny_ShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage))
        {
            # Convert enum array to ServerPermissionSet object
            $permissionSet = [Microsoft.SqlServer.Management.Smo.ServerPermissionSet]::new()
            foreach ($permissionName in $Permission)
            {
                $permissionSet.$permissionName = $true
            }

            try
            {
                $serverObject.Deny($permissionSet, $principalName)
            }
            catch
            {
                $errorMessage = $script:localizedData.ServerPermission_Deny_FailedToDenyPermission -f $principalName, $serverObject.InstanceName, ($Permission -join ',')

                $exception = [System.InvalidOperationException]::new($errorMessage, $_.Exception)

                $PSCmdlet.ThrowTerminatingError(
                    [System.Management.Automation.ErrorRecord]::new(
                        $exception,
                        'DSDSP0001', # cSpell: disable-line
                        [System.Management.Automation.ErrorCategory]::InvalidOperation,
                        $principalName
                    )
                )
            }
        }
    }
}
