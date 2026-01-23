<#
    .SYNOPSIS
        Determine if the current login has impersonate permissions

    .PARAMETER ServerObject
        The server object on which to perform the test.

    .PARAMETER SecurableName
        If set then impersonate permission on this specific securable (e.g. login) is also checked.

#>
function Test-ImpersonatePermissions
{
    param
    (
        [Parameter(Mandatory = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter()]
        [System.String]
        $SecurableName
    )

    # The impersonate any login permission only exists in SQL 2014 and above
    $testLoginEffectivePermissionsParams = @{
        ServerName   = $ServerObject.ComputerNamePhysicalNetBIOS
        InstanceName = $ServerObject.ServiceName
        LoginName    = $ServerObject.ConnectionContext.TrueLogin
        Permissions  = @('IMPERSONATE ANY LOGIN')
    }

    $impersonatePermissionsPresent = Test-LoginEffectivePermissions @testLoginEffectivePermissionsParams

    if ($impersonatePermissionsPresent)
    {
        Write-Verbose -Message ( 'The login "{0}" has impersonate any login permissions on the instance "{1}\{2}".' -f $testLoginEffectivePermissionsParams.LoginName, $testLoginEffectivePermissionsParams.ServerName, $testLoginEffectivePermissionsParams.InstanceName ) -Verbose
        return $impersonatePermissionsPresent
    }
    else
    {
        Write-Verbose -Message ( 'The login "{0}" does not have impersonate any login permissions on the instance "{1}\{2}".' -f $testLoginEffectivePermissionsParams.LoginName, $testLoginEffectivePermissionsParams.ServerName, $testLoginEffectivePermissionsParams.InstanceName ) -Verbose
    }

    # Check for sysadmin / control server permission which allows impersonation
    $testLoginEffectivePermissionsParams = @{
        ServerName   = $ServerObject.ComputerNamePhysicalNetBIOS
        InstanceName = $ServerObject.ServiceName
        LoginName    = $ServerObject.ConnectionContext.TrueLogin
        Permissions  = @('CONTROL SERVER')
    }

    $impersonatePermissionsPresent = Test-LoginEffectivePermissions @testLoginEffectivePermissionsParams

    if ($impersonatePermissionsPresent)
    {
        Write-Verbose -Message ( 'The login "{0}" has control server permissions on the instance "{1}\{2}".' -f $testLoginEffectivePermissionsParams.LoginName, $testLoginEffectivePermissionsParams.ServerName, $testLoginEffectivePermissionsParams.InstanceName ) -Verbose
        return $impersonatePermissionsPresent
    }
    else
    {
        Write-Verbose -Message ( 'The login "{0}" does not have control server permissions on the instance "{1}\{2}".' -f $testLoginEffectivePermissionsParams.LoginName, $testLoginEffectivePermissionsParams.ServerName, $testLoginEffectivePermissionsParams.InstanceName ) -Verbose
    }

    if (-not [System.String]::IsNullOrEmpty($SecurableName))
    {
        # Check for login-specific impersonation permissions
        $testLoginEffectivePermissionsParams = @{
            ServerName     = $ServerObject.ComputerNamePhysicalNetBIOS
            InstanceName   = $ServerObject.ServiceName
            LoginName      = $ServerObject.ConnectionContext.TrueLogin
            Permissions    = @('IMPERSONATE')
            SecurableClass = 'LOGIN'
            SecurableName  = $SecurableName
        }

        $impersonatePermissionsPresent = Test-LoginEffectivePermissions @testLoginEffectivePermissionsParams

        if ($impersonatePermissionsPresent)
        {
            Write-Verbose -Message ( 'The login "{0}" has impersonate permissions on the instance "{1}\{2}" for the login "{3}".' -f $testLoginEffectivePermissionsParams.LoginName, $testLoginEffectivePermissionsParams.ServerName, $testLoginEffectivePermissionsParams.InstanceName, $SecurableName ) -Verbose
            return $impersonatePermissionsPresent
        }
        else
        {
            Write-Verbose -Message ( 'The login "{0}" does not have impersonate permissions on the instance "{1}\{2}" for the login "{3}".' -f $testLoginEffectivePermissionsParams.LoginName, $testLoginEffectivePermissionsParams.ServerName, $testLoginEffectivePermissionsParams.InstanceName, $SecurableName ) -Verbose
        }

        # Check for login-specific control permissions
        $testLoginEffectivePermissionsParams = @{
            ServerName     = $ServerObject.ComputerNamePhysicalNetBIOS
            InstanceName   = $ServerObject.ServiceName
            LoginName      = $ServerObject.ConnectionContext.TrueLogin
            Permissions    = @('CONTROL')
            SecurableClass = 'LOGIN'
            SecurableName  = $SecurableName
        }

        $impersonatePermissionsPresent = Test-LoginEffectivePermissions @testLoginEffectivePermissionsParams

        if ($impersonatePermissionsPresent)
        {
            Write-Verbose -Message ( 'The login "{0}" has control permissions on the instance "{1}\{2}" for the login "{3}".' -f $testLoginEffectivePermissionsParams.LoginName, $testLoginEffectivePermissionsParams.ServerName, $testLoginEffectivePermissionsParams.InstanceName, $SecurableName ) -Verbose
            return $impersonatePermissionsPresent
        }
        else
        {
            Write-Verbose -Message ( 'The login "{0}" does not have control permissions on the instance "{1}\{2}" for the login "{3}".' -f $testLoginEffectivePermissionsParams.LoginName, $testLoginEffectivePermissionsParams.ServerName, $testLoginEffectivePermissionsParams.InstanceName, $SecurableName ) -Verbose
        }
    }

    Write-Verbose -Message ( 'The login "{0}" does not have any impersonate permissions required on the instance "{1}\{2}".' -f $testLoginEffectivePermissionsParams.LoginName, $testLoginEffectivePermissionsParams.ServerName, $testLoginEffectivePermissionsParams.InstanceName ) -Verbose

    return $impersonatePermissionsPresent
}
