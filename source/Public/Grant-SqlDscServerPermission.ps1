<#
    .SYNOPSIS
        Grants server permissions to a principal on a SQL Server Database Engine instance.

    .DESCRIPTION
        This command grants server permissions to an existing principal on a SQL Server
        Database Engine instance. The principal can be specified as either a Login
        object (from Get-SqlDscLogin) or a ServerRole object (from Get-SqlDscRole).

    .PARAMETER Login
        Specifies the Login object for which the permissions are granted.
        This parameter accepts pipeline input.

    .PARAMETER ServerRole
        Specifies the ServerRole object for which the permissions are granted.
        This parameter accepts pipeline input.

    .PARAMETER Permission
        Specifies the permissions to be granted. Specify multiple permissions by
        providing an array of SqlServerPermission enum values.

    .PARAMETER WithGrant
        Specifies that the principal should also be granted the right to grant
        other principals the same permission.

    .PARAMETER Force
        Specifies that the permissions should be granted without any confirmation.

    .INPUTS
        `Microsoft.SqlServer.Management.Smo.Login`

        Accepts input via the pipeline.

    .INPUTS
        `Microsoft.SqlServer.Management.Smo.ServerRole`

        Accepts input via the pipeline.

    .OUTPUTS
        None.

    .EXAMPLE
        $serverInstance = Connect-SqlDscDatabaseEngine
        $login = $serverInstance | Get-SqlDscLogin -Name 'MyLogin'
        Grant-SqlDscServerPermission -Login $login -Permission ConnectSql, ViewServerState

        Grants the specified permissions to the login 'MyLogin'.

    .EXAMPLE
        $serverInstance = Connect-SqlDscDatabaseEngine
        $role = $serverInstance | Get-SqlDscRole -Name 'MyRole'
        $role | Grant-SqlDscServerPermission -Permission AlterAnyDatabase -WithGrant -Force

        Grants the specified permissions with grant option to the role 'MyRole' without prompting for confirmation.

    .EXAMPLE
        $serverInstance = Connect-SqlDscDatabaseEngine
        $serverInstance | Get-SqlDscLogin | Grant-SqlDscServerPermission -Permission ConnectSql

        Grants ConnectSql permission to all logins from the pipeline.

    .NOTES
        The Login or ServerRole object must come from the same SQL Server instance
        where the permissions will be granted. If specifying `-ErrorAction 'SilentlyContinue'`
        then the command will silently continue if any errors occur. If specifying
        `-ErrorAction 'Stop'` the command will throw an error on any failure.
#>
function Grant-SqlDscServerPermission
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
        $WithGrant,

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

        $verboseDescriptionMessage = $script:localizedData.ServerPermission_Grant_ShouldProcessVerboseDescription -f $principalName, $serverObject.InstanceName, ($Permission -join ',')
        $verboseWarningMessage = $script:localizedData.ServerPermission_Grant_ShouldProcessVerboseWarning -f $principalName
        $captionMessage = $script:localizedData.ServerPermission_Grant_ShouldProcessCaption

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
                if ($WithGrant.IsPresent)
                {
                    $serverObject.Grant($permissionSet, $principalName, $true)
                }
                else
                {
                    $serverObject.Grant($permissionSet, $principalName)
                }
            }
            catch
            {
                $errorMessage = $script:localizedData.ServerPermission_Grant_FailedToGrantPermission -f $principalName, $serverObject.InstanceName, ($Permission -join ', ')

                $exception = [System.InvalidOperationException]::new($errorMessage, $_.Exception)

                $PSCmdlet.ThrowTerminatingError(
                    [System.Management.Automation.ErrorRecord]::new(
                        $exception,
                        'GSDSP0001', # cSpell: disable-line
                        [System.Management.Automation.ErrorCategory]::InvalidOperation,
                        $principalName
                    )
                )
            }
        }
    }
}
