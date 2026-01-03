<#
    .SYNOPSIS
        Returns the current permissions for a SQL Server login or server role.

    .DESCRIPTION
        Returns the current permissions for a SQL Server login or server role.
        The command can retrieve permissions for both user-defined and built-in
        server principals including SQL Server logins and server roles.

        The command supports two modes of operation:
        1. By name: Specify ServerObject, Name, and optionally PrincipalType
        2. By object: Pass Login or ServerRole objects via pipeline

    .PARAMETER ServerObject
        Specifies current server connection object. This parameter is used in the
        default parameter set for backward compatibility.

    .PARAMETER Name
        Specifies the name of the SQL Server login or server role for which
        the permissions are returned. This parameter is used in the default
        parameter set for backward compatibility.

    .PARAMETER PrincipalType
        Specifies the type(s) of principal to check. Valid values are 'Login'
        and 'Role'. If not specified, both login and role checks will be performed.
        If specified, only the specified type(s) will be checked. This parameter
        is used in the default parameter set for backward compatibility.

    .PARAMETER Login
        Specifies the Login object for which the permissions are returned.
        This parameter accepts pipeline input.

    .PARAMETER ServerRole
        Specifies the ServerRole object for which the permissions are returned.
        This parameter accepts pipeline input.


    .INPUTS
        `Microsoft.SqlServer.Management.Smo.Server`

        Server object accepted from the pipeline.

    .INPUTS
        `Microsoft.SqlServer.Management.Smo.Login`

        Login object accepted from the pipeline.

    .INPUTS
        `Microsoft.SqlServer.Management.Smo.ServerRole`

        ServerRole object accepted from the pipeline.

    .OUTPUTS
        `Microsoft.SqlServer.Management.Smo.ServerPermissionInfo[]`

        Returns server permissions for the specified principal.

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

    .EXAMPLE
        $serverInstance = Connect-SqlDscDatabaseEngine
        $login = $serverInstance | Get-SqlDscLogin -Name 'MyLogin'
        Get-SqlDscServerPermission -Login $login

        Get the permissions for the login 'MyLogin' using a Login object.

    .EXAMPLE
        $serverInstance = Connect-SqlDscDatabaseEngine
        $role = $serverInstance | Get-SqlDscRole -Name 'MyRole'
        $role | Get-SqlDscServerPermission

        Get the permissions for the server role 'MyRole' using a ServerRole object from the pipeline.

    .EXAMPLE
        $serverInstance = Connect-SqlDscDatabaseEngine
        $serverInstance | Get-SqlDscLogin | Get-SqlDscServerPermission

        Get the permissions for all logins from the pipeline.

    .NOTES
        If specifying `-ErrorAction 'SilentlyContinue'` then the command will silently
        ignore if the principal (parameter **Name**) is not present. In such case the
        command will return `$null`. If specifying `-ErrorAction 'Stop'` the command
        will throw an error if the principal is missing.

        The Login or ServerRole object must come from the same SQL Server instance
        where the permissions will be retrieved.
#>
function Get-SqlDscServerPermission
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('AvoidThrowOutsideOfTry', '', Justification = 'Because the code throws based on an prior expression')]
    [CmdletBinding(DefaultParameterSetName = 'ByName')]
    [OutputType([Microsoft.SqlServer.Management.Smo.ServerPermissionInfo[]])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'ByName')]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter(Mandatory = $true, ParameterSetName = 'ByName')]
        [System.String]
        $Name,

        [Parameter(ParameterSetName = 'ByName')]
        [ValidateSet('Login', 'Role')]
        [System.String[]]
        $PrincipalType,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'Login')]
        [Microsoft.SqlServer.Management.Smo.Login]
        $Login,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'ServerRole')]
        [Microsoft.SqlServer.Management.Smo.ServerRole]
        $ServerRole
    )

    # cSpell: ignore GSDSP
    process
    {
        $getSqlDscServerPermissionResult = $null

        # Determine which parameter set we're using and set up variables accordingly
        if ($PSCmdlet.ParameterSetName -eq 'Login')
        {
            $principalName = $Login.Name
            $serverObject = $Login.Parent
            $isLogin = $true
            $isRole = $false
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'ServerRole')
        {
            $principalName = $ServerRole.Name
            $serverObject = $ServerRole.Parent
            $isLogin = $false
            $isRole = $true
        }
        else
        {
            # ByName parameter set (default for backward compatibility)
            $principalName = $Name
            $serverObject = $ServerObject

            $testSqlDscIsPrincipalParameters = @{
                ServerObject = $serverObject
                Name         = $principalName
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

            $isRole = if ($checkRole)
            {
                Test-SqlDscIsRole @testSqlDscIsPrincipalParameters
            }
            else
            {
                $false
            }
        }

        if ($isLogin -or $isRole)
        {
            $getSqlDscServerPermissionResult = $serverObject.EnumServerPermissions($principalName)
        }
        else
        {
            $missingPrincipalMessage = $script:localizedData.ServerPermission_MissingPrincipal -f $principalName, $serverObject.InstanceName

            Write-Error -Message $missingPrincipalMessage -Category 'InvalidOperation' -ErrorId 'GSDSP0001' -TargetObject $principalName
        }

        return [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo[]] $getSqlDscServerPermissionResult
    }
}
