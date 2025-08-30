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

    .PARAMETER Permission
        Specifies the desired permissions as ServerPermission objects. Each object must
        specify the State ('Grant', 'GrantWithGrant', or 'Deny') and the permissions
        that should be present.

    .OUTPUTS
        [System.Boolean]

    .EXAMPLE
        $serverInstance = Connect-SqlDscDatabaseEngine

        $permissions = @(
            [ServerPermission] @{
                State = 'Grant'
                Permission = @('ConnectSql', 'ViewServerState')
            }
            [ServerPermission] @{
                State = 'GrantWithGrant'
                Permission = @()
            }
            [ServerPermission] @{
                State = 'Deny'
                Permission = @()
            }
        )

        Test-SqlDscServerPermission -ServerObject $serverInstance -Name 'MyPrincipal' -Permission $permissions

        Tests if the principal 'MyPrincipal' has exactly the specified permissions.

    .EXAMPLE
        $serverInstance = Connect-SqlDscDatabaseEngine

        $permissions = @(
            [ServerPermission] @{
                State = 'Grant'
                Permission = @('AlterAnyDatabase')
            }
        )

        $serverInstance | Test-SqlDscServerPermission -Name 'MyPrincipal' -Permission $permissions

        Tests if the principal 'MyPrincipal' has the specified grant permissions.

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
        [ServerPermission[]]
        $Permission
    )

    process
    {
        Write-Verbose -Message (
            $script:localizedData.ServerPermission_TestingDesiredState -f $Name, $ServerObject.InstanceName
        )

        try
        {
            $isInDesiredState = Test-SqlDscServerPermissionState -ServerObject $ServerObject -Name $Name -Permission $Permission

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