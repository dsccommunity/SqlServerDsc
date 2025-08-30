<#
    .SYNOPSIS
        Grants server permissions to a principal on a SQL Server Database Engine instance.

    .DESCRIPTION
        This command grants server permissions to an existing principal on a SQL Server
        Database Engine instance.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER Name
        Specifies the name of the principal for which the permissions are granted.

    .PARAMETER State
        Specifies the state of the permission to be applied.

    .PARAMETER Permission
        Specifies the permissions as a ServerPermissionSet object containing the
        permissions to be applied.

    .PARAMETER WithGrant
        Specifies that the principal should also be granted the right to grant
        other principals the same permission. This parameter is only valid when
        parameter **State** is set to 'Grant'. When this parameter is used, the
        effective state will be 'GrantWithGrant'.

    .PARAMETER Force
        Specifies that the permissions should be granted without any confirmation.

    .OUTPUTS
        None.

    .EXAMPLE
        $serverInstance = Connect-SqlDscDatabaseEngine

        $permissionSet = [Microsoft.SqlServer.Management.Smo.ServerPermissionSet] @{
            ConnectSql = $true
            ViewServerState = $true
        }

        Grant-SqlDscServerPermission -ServerObject $serverInstance -Name 'MyPrincipal' -Permission $permissionSet

        Grants the specified permissions to the principal 'MyPrincipal'.

    .EXAMPLE
        $serverInstance = Connect-SqlDscDatabaseEngine

        $permissionSet = [Microsoft.SqlServer.Management.Smo.ServerPermissionSet] @{
            AlterAnyDatabase = $true
        }

        $serverInstance | Grant-SqlDscServerPermission -Name 'MyPrincipal' -Permission $permissionSet -WithGrant -Force

        Grants the specified permissions with grant option to the principal 'MyPrincipal' without prompting for confirmation.

    .NOTES
        If specifying `-ErrorAction 'SilentlyContinue'` then the command will silently
        ignore if the principal is not present. If specifying `-ErrorAction 'Stop'` the
        command will throw an error if the principal is missing.
#>
function Grant-SqlDscServerPermission
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('AvoidThrowOutsideOfTry', '', Justification = 'Because the code throws based on an prior expression')]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType()]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [Microsoft.SqlServer.Management.Smo.ServerPermissionSet]
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

        Write-Verbose -Message (
            $script:localizedData.ServerPermission_Grant_ShouldProcessVerboseDescription -f $Name, $ServerObject.InstanceName
        )

        $verboseDescriptionMessage = $script:localizedData.ServerPermission_Grant_ShouldProcessVerboseDescription -f $Name, $ServerObject.InstanceName
        $verboseWarningMessage = $script:localizedData.ServerPermission_Grant_ShouldProcessVerboseWarning -f $Name
        $captionMessage = $script:localizedData.ServerPermission_Grant_ShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage))
        {
            $invokeParameters = @{
                ServerObject = $ServerObject
                Name         = $Name
                Permission   = $Permission
            }

            try
            {
                if ($WithGrant.IsPresent)
                {
                    Invoke-SqlDscServerPermissionOperation @invokeParameters -State 'Grant' -WithGrant
                }
                else
                {
                    Invoke-SqlDscServerPermissionOperation @invokeParameters -State 'Grant'
                }
            }
            catch
            {
                $errorMessage = $script:localizedData.ServerPermission_FailedToGrantPermission -f $Name, $ServerObject.InstanceName

                New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
            }
        }
    }
}