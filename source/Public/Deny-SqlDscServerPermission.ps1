<#
    .SYNOPSIS
        Denies server permissions to a principal on a SQL Server Database Engine instance.

    .DESCRIPTION
        This command denies server permissions to an existing principal on a SQL Server
        Database Engine instance.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER Name
        Specifies the name of the principal for which the permissions are denied.

    .PARAMETER Permission
        Specifies the permissions to be denied. Specify multiple permissions by
        providing an array of permission names.

    .PARAMETER Force
        Specifies that the permissions should be denied without any confirmation.

    .OUTPUTS
        None.

    .EXAMPLE
        $serverInstance = Connect-SqlDscDatabaseEngine

        Deny-SqlDscServerPermission -ServerObject $serverInstance -Name 'MyPrincipal' -Permission 'ConnectSql', 'ViewServerState'

        Denies the specified permissions to the principal 'MyPrincipal'.

    .EXAMPLE
        $serverInstance = Connect-SqlDscDatabaseEngine

        $serverInstance | Deny-SqlDscServerPermission -Name 'MyPrincipal' -Permission 'AlterAnyDatabase' -Force

        Denies the specified permissions to the principal 'MyPrincipal' without prompting for confirmation.

    .NOTES
        If specifying `-ErrorAction 'SilentlyContinue'` then the command will silently
        ignore if the principal is not present. If specifying `-ErrorAction 'Stop'` the
        command will throw an error if the principal is missing.
#>
function Deny-SqlDscServerPermission
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
        [ValidateSet(
            'AdministerBulkOperations',
            'AlterAnyServerAudit',
            'AlterAnyCredential',
            'AlterAnyConnection',
            'AlterAnyDatabase',
            'AlterAnyEventNotification',
            'AlterAnyEndpoint',
            'AlterAnyLogin',
            'AlterAnyLinkedServer',
            'AlterResources',
            'AlterServerState',
            'AlterSettings',
            'AlterTrace',
            'AuthenticateServer',
            'ControlServer',
            'ConnectSql',
            'CreateAnyDatabase',
            'CreateDdlEventNotification',
            'CreateEndpoint',
            'CreateTraceEventNotification',
            'Shutdown',
            'ViewAnyDefinition',
            'ViewAnyDatabase',
            'ViewServerState',
            'ExternalAccessAssembly',
            'UnsafeAssembly',
            'AlterAnyServerRole',
            'CreateServerRole',
            'AlterAnyAvailabilityGroup',
            'CreateAvailabilityGroup',
            'AlterAnyEventSession',
            'SelectAllUserSecurables',
            'ConnectAnyDatabase',
            'ImpersonateAnyLogin'
        )]
        [System.String[]]
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

        Write-Verbose -Message (
            $script:localizedData.ServerPermission_Deny_ShouldProcessVerboseDescription -f $Name, $ServerObject.InstanceName
        )

        $verboseDescriptionMessage = $script:localizedData.ServerPermission_Deny_ShouldProcessVerboseDescription -f $Name, $ServerObject.InstanceName
        $verboseWarningMessage = $script:localizedData.ServerPermission_Deny_ShouldProcessVerboseWarning -f $Name
        $captionMessage = $script:localizedData.ServerPermission_Deny_ShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage))
        {
            # Convert string array to ServerPermissionSet object
            $permissionSet = [Microsoft.SqlServer.Management.Smo.ServerPermissionSet]::new()
            foreach ($permissionName in $Permission)
            {
                $permissionSet.$permissionName = $true
            }

            $invokeParameters = @{
                ServerObject = $ServerObject
                Name         = $Name
                Permission   = $permissionSet
                State        = 'Deny'
            }

            try
            {
                Invoke-SqlDscServerPermissionOperation @invokeParameters
            }
            catch
            {
                $errorMessage = $script:localizedData.ServerPermission_FailedToDenyPermission -f $Name, $ServerObject.InstanceName

                New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
            }
        }
    }
}