<#
    .SYNOPSIS
        Impersonates a login and determines whether required permissions are present.

    .PARAMETER ServerName
        String containing the host name of the SQL Server to connect to.

    .PARAMETER InstanceName
        String containing the SQL Server Database Engine instance to connect to.

    .PARAMETER LoginName
        String containing the login (user) which should be checked for a permission.

    .PARAMETER Permissions
        This is a list that represents a SQL Server set of database permissions.

    .PARAMETER SecurableClass
        String containing the class of permissions to test. It can be:
            SERVER: A permission that is applicable against server objects.
            LOGIN: A permission that is applicable against login objects.

        Default is 'SERVER'.

    .PARAMETER SecurableName
        String containing the name of the object against which permissions exist,
        e.g. if SecurableClass is LOGIN this is the name of a login permissions
        may exist against.

        Default is $null.

    .NOTES
        These SecurableClass are not yet in this module yet and so are not implemented:
            'APPLICATION ROLE', 'ASSEMBLY', 'ASYMMETRIC KEY', 'CERTIFICATE',
            'CONTRACT', 'DATABASE', 'ENDPOINT', 'FULLTEXT CATALOG',
            'MESSAGE TYPE', 'OBJECT', 'REMOTE SERVICE BINDING', 'ROLE',
            'ROUTE', 'SCHEMA', 'SERVICE', 'SYMMETRIC KEY', 'TYPE', 'USER',
            'XML SCHEMA COLLECTION'

#>
function Test-LoginEffectivePermissions
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $LoginName,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $Permissions,

        [Parameter()]
        [ValidateSet('SERVER', 'LOGIN')]
        [System.String]
        $SecurableClass = 'SERVER',

        [Parameter()]
        [System.String]
        $SecurableName
    )

    # Assume the permissions are not present
    $permissionsPresent = $false

    $invokeSqlDscQueryParameters = @{
        ServerName   = $ServerName
        InstanceName = $InstanceName
        DatabaseName = 'master'
        PassThru     = $true
    }

    if ( [System.String]::IsNullOrEmpty($SecurableName) )
    {
        $queryToGetEffectivePermissionsForLogin = "
            EXECUTE AS LOGIN = '$LoginName'
            SELECT DISTINCT permission_name
            FROM fn_my_permissions(null,'$SecurableClass')
            REVERT
        "
    }
    else
    {
        $queryToGetEffectivePermissionsForLogin = "
            EXECUTE AS LOGIN = '$LoginName'
            SELECT DISTINCT permission_name
            FROM fn_my_permissions('$SecurableName','$SecurableClass')
            REVERT
        "
    }

    Write-Verbose -Message ($script:localizedData.GetEffectivePermissionForLogin -f $LoginName, $InstanceName) -Verbose

    $loginEffectivePermissionsResult = Invoke-SqlDscQuery @invokeSqlDscQueryParameters -Query $queryToGetEffectivePermissionsForLogin
    $loginEffectivePermissions = $loginEffectivePermissionsResult.Tables.Rows.permission_name

    if ( $null -ne $loginEffectivePermissions )
    {
        $loginMissingPermissions = Compare-Object -ReferenceObject $Permissions -DifferenceObject $loginEffectivePermissions |
            Where-Object -FilterScript { $_.SideIndicator -ne '=>' } |
            Select-Object -ExpandProperty InputObject

        if ( $loginMissingPermissions.Count -eq 0 )
        {
            $permissionsPresent = $true
        }
    }

    return $permissionsPresent
}
