<#
    .SYNOPSIS
        Tests if server permissions for a principal are in the desired state.

    .DESCRIPTION
        This command tests if server permissions for an existing principal on a SQL Server
        Database Engine instance are in the desired state.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER Name
        Specifies the name of the principal for which the permissions are tested.

    .PARAMETER State
        Specifies the desired state of the permission to be tested.

    .PARAMETER Permission
        Specifies the desired permissions as a ServerPermissionSet object containing the
        permissions that should be present in the specified state.

    .PARAMETER WithGrant
        Specifies that the principal should have the right to grant other principals
        the same permission. This parameter is only valid when parameter **State** is
        set to 'Grant'. When this parameter is used, the effective state tested will
        be 'GrantWithGrant'.

    .OUTPUTS
        [System.Boolean]

    .EXAMPLE
        $serverInstance = Connect-SqlDscDatabaseEngine

        $permissionSet = [Microsoft.SqlServer.Management.Smo.ServerPermissionSet] @{
            ConnectSql = $true
            ViewServerState = $true
        }

        $isInDesiredState = Test-SqlDscServerPermission -ServerObject $serverInstance -Name 'MyPrincipal' -State 'Grant' -Permission $permissionSet

        Tests if the specified permissions are granted to the principal 'MyPrincipal'.

    .EXAMPLE
        $serverInstance = Connect-SqlDscDatabaseEngine

        $permissionSet = [Microsoft.SqlServer.Management.Smo.ServerPermissionSet] @{
            AlterAnyDatabase = $true
        }

        $isInDesiredState = $serverInstance | Test-SqlDscServerPermission -Name 'MyPrincipal' -State 'Grant' -Permission $permissionSet -WithGrant

        Tests if the specified permissions are granted with grant option to the principal 'MyPrincipal'.

    .NOTES
        If specifying `-ErrorAction 'SilentlyContinue'` then the command will silently
        ignore if the principal is not present. If specifying `-ErrorAction 'Stop'` the
        command will throw an error if the principal is missing.
#>
function Test-SqlDscServerPermission
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('AvoidThrowOutsideOfTry', '', Justification = 'Because the code throws based on an prior expression')]
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Grant', 'GrantWithGrant', 'Deny')]
        [System.String]
        $State,

        [Parameter(Mandatory = $true)]
        [Microsoft.SqlServer.Management.Smo.ServerPermissionSet]
        $Permission,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $WithGrant
    )

    process
    {
        Write-Verbose -Message (
            $script:localizedData.ServerPermission_TestingDesiredState -f $Name, $ServerObject.InstanceName
        )

        try
        {
            $testParameters = @{
                ServerObject = $ServerObject
                Name         = $Name
                State        = $State
                Permission   = $Permission
            }

            if ($WithGrant.IsPresent)
            {
                $testParameters['WithGrant'] = $true
            }

            $isInDesiredState = Test-SqlDscServerPermissionState @testParameters

            return $isInDesiredState
        }
        catch
        {
            # If the principal doesn't exist or there's another error, return false
            Write-Verbose -Message (
                $script:localizedData.ServerPermission_TestFailed -f $Name, $_.Exception.Message
            )
            
            return $false
        }
    }
}