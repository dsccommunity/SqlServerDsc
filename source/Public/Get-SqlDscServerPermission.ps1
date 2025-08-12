<#
    .SYNOPSIS
        Returns the current permissions for a SQL Server login or server role.

    .DESCRIPTION
        Returns the current permissions for a SQL Server login or server role.
        The command can retrieve permissions for both user-defined and built-in
        server principals including SQL Server logins and server roles.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER Name
        Specifies the name of the SQL Server login or server role for which
        the permissions are returned.

    .PARAMETER PrincipalType
        Specifies the type(s) of principal to check. Valid values are 'Login'
        and 'Role'. If not specified, both login and role checks will be performed.
        If specified, only the specified type(s) will be checked.

    .OUTPUTS
        [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo[]]

    .EXAMPLE
        $serverInstance = Connect-SqlDscDatabaseEngine
        Get-SqlDscServerPermission -ServerObject $serverInstance -Name 'MyPrincipal'

        Get the permissions for the principal 'MyPrincipal'.

    .EXAMPLE
        $serverInstance = Connect-SqlDscDatabaseEngine
        Get-SqlDscServerPermission -ServerObject $serverInstance -Name 'sysadmin'

        Get the permissions for the server role 'sysadmin'.

    .EXAMPLE
        $serverInstance = Connect-SqlDscDatabaseEngine
        Get-SqlDscServerPermission -ServerObject $serverInstance -Name 'MyLogin' -PrincipalType 'Login'

        Get the permissions for the login 'MyLogin', only checking if it exists as a login.

    .EXAMPLE
        $serverInstance = Connect-SqlDscDatabaseEngine
        Get-SqlDscServerPermission -ServerObject $serverInstance -Name 'MyRole' -PrincipalType 'Role'

        Get the permissions for the server role 'MyRole', only checking if it exists as a role.

    .NOTES
        If specifying `-ErrorAction 'SilentlyContinue'` then the command will silently
        ignore if the principal (parameter **Name**) is not present. In such case the
        command will return `$null`. If specifying `-ErrorAction 'Stop'` the command
        will throw an error if the principal is missing.
#>
function Get-SqlDscServerPermission
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseOutputTypeCorrectly', '', Justification = 'Because the rule does not understands that the command returns [System.String[]] when using , (comma) in the return statement')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('AvoidThrowOutsideOfTry', '', Justification = 'Because the code throws based on an prior expression')]
    [CmdletBinding()]
    [OutputType([Microsoft.SqlServer.Management.Smo.ServerPermissionInfo[]])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [ValidateSet('Login', 'Role')]
        [System.String[]]
        $PrincipalType
    )

    # cSpell: ignore GSDSP
    process
    {
        $getSqlDscServerPermissionResult = $null

        $testSqlDscIsPrincipalParameters = @{
            ServerObject = $ServerObject
            Name         = $Name
        }

        # Determine which checks to perform based on PrincipalType parameter
        $checkLogin = $true
        $checkRole = $true

        if ($PSBoundParameters.ContainsKey('PrincipalType'))
        {
            $checkLogin = $PrincipalType -contains 'Login'
            $checkRole = $PrincipalType -contains 'Role'
        }

        # Perform the appropriate checks
        $isLogin = if ($checkLogin)
        {
            Test-SqlDscIsLogin @testSqlDscIsPrincipalParameters
        }
        else
        {
            $false
        }

        $isRole = if ($checkRole -and -not $isLogin)
        {
            Test-SqlDscIsRole @testSqlDscIsPrincipalParameters
        }
        else
        {
            $false
        }

        if ($isLogin -or $isRole)
        {
            $getSqlDscServerPermissionResult = $ServerObject.EnumServerPermissions($Name)
        }
        else
        {
            $missingPrincipalMessage = $script:localizedData.ServerPermission_MissingPrincipal -f $Name, $ServerObject.InstanceName

            Write-Error -Message $missingPrincipalMessage -Category 'InvalidOperation' -ErrorId 'GSDSP0001' -TargetObject $Name
        }

        return , [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo[]] $getSqlDscServerPermissionResult
    }
}
