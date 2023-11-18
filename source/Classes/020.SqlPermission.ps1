<#
    .SYNOPSIS
        The `SqlPermission` DSC resource is used to grant, deny or revoke
        server permissions for a login.

    .DESCRIPTION
        The `SqlPermission` DSC resource is used to grant, deny or revoke
        Server permissions for a login. For more information about permissions,
        please read the article [Permissions (Database Engine)](https://docs.microsoft.com/en-us/sql/relational-databases/security/permissions-database-engine).

        > [!CAUTION]
        > When revoking permission with PermissionState 'GrantWithGrant', both the
        > grantee and _all the other users the grantee has granted the same permission_
        > _to_, will also get their permission revoked.

        ## Requirements

        * Target machine must be running Windows Server 2012 or later.
        * Target machine must be running SQL Server Database Engine 2012 or later.
        * Target machine must have access to the SQLPS PowerShell module or the SqlServer
          PowerShell module.

        ## Known issues

        All issues are not listed here, see [here for all open issues](https://github.com/dsccommunity/SqlServerDsc/issues?q=is%3Aissue+is%3Aopen+in%3Atitle+SqlPermission).

        ### `PSDscRunAsCredential` not supported

        The built-in property `PSDscRunAsCredential` does not work with class-based
        resources that using advanced type like the parameters `Permission` and
        `Reasons` has. Use the parameter `Credential` instead of `PSDscRunAsCredential`.

        ### Using `Credential` property.

        SQL Authentication and Group Managed Service Accounts is not supported as
        impersonation credentials. Currently only Windows Integrated Security is
        supported to use as credentials.

        For Windows Authentication the username must either be provided with the User
        Principal Name (UPN), e.g. 'username@domain.local' or if using non-domain
        (for example a local Windows Server account) account the username must be
        provided without the NetBIOS name, e.g. 'username'. The format 'DOMAIN\username'
        will not work.

        See more information in [Credential Overview](https://github.com/dsccommunity/SqlServerDsc/wiki/CredentialOverview).

        ### Invalid values during compilation

        The parameter Permission is of type `[ServerPermission]`. If a property
        in the type is set to an invalid value an error will occur, correct the
        values in the properties to valid values.
        This happens when the values are validated against the `[ValidateSet()]`
        of the resource. When there is an invalid value the following error will
        be thrown when the configuration is run (it will not show during compilation):

        ```plaintext
        Failed to create an object of PowerShell class SqlPermission.
            + CategoryInfo          : InvalidOperation: (root/Microsoft/...ConfigurationManager:String) [], CimException
            + FullyQualifiedErrorId : InstantiatePSClassObjectFailed
            + PSComputerName        : localhost
        ```

    .PARAMETER Name
        The name of the user that should be granted or denied the permission.

    .PARAMETER Permission
        An array of server permissions to enforce. Any permission that is not
        part of the desired state will be revoked.

        Must provide all permission states (`Grant`, `Deny`, `GrantWithGrant`) with
        at least an empty string array for the advanced type `ServerPermission`'s
        property `Permission`.

        Valid permission names can be found in the article [ServerPermissionSet Class properties](https://docs.microsoft.com/en-us/dotnet/api/microsoft.sqlserver.management.smo.serverpermissionset#properties).

        This is an array of CIM instances of advanced type `ServerPermission` from
        the namespace `root/Microsoft/Windows/DesiredStateConfiguration`.

    .PARAMETER PermissionToInclude
        An array of server permissions to include to the current state. The
        current state will not be affected unless the current state contradict the
        desired state. For example if the desired state specifies a deny permissions
        but in the current state that permission is granted, that permission will
        be changed to be denied.

        Valid permission names can be found in the article [ServerPermissionSet Class properties](https://docs.microsoft.com/en-us/dotnet/api/microsoft.sqlserver.management.smo.serverpermissionset#properties).

        This is an array of CIM instances of advanced type `ServerPermission` from
        the namespace `root/Microsoft/Windows/DesiredStateConfiguration`.

    .PARAMETER PermissionToExclude
        An array of server permissions to exclude (revoke) from the current state.

        Valid permission names can be found in the article [ServerPermissionSet Class properties](https://docs.microsoft.com/en-us/dotnet/api/microsoft.sqlserver.management.smo.serverpermissionset#properties).

        This is an array of CIM instances of advanced type `ServerPermission` from
        the namespace `root/Microsoft/Windows/DesiredStateConfiguration`.

    .EXAMPLE
        Invoke-DscResource -ModuleName SqlServerDsc -Name SqlPermission -Method Get -Property @{
            ServerName           = 'localhost'
            InstanceName         = 'SQL2017'
            Credential           = (Get-Credential -UserName 'myuser@company.local' -Message 'Password:')
            Name                 = 'INSTANCE\SqlUser'
            Permission           = [Microsoft.Management.Infrastructure.CimInstance[]] @(
                (
                    New-CimInstance -ClientOnly -Namespace root/Microsoft/Windows/DesiredStateConfiguration -ClassName ServerPermission -Property @{
                            State = 'Grant'
                            Permission = @('select')
                    }
                )
                (
                    New-CimInstance -ClientOnly -Namespace root/Microsoft/Windows/DesiredStateConfiguration -ClassName ServerPermission -Property @{
                        State = 'GrantWithGrant'
                        Permission = [System.String[]] @()
                    }
                )
                (
                    New-CimInstance -ClientOnly -Namespace root/Microsoft/Windows/DesiredStateConfiguration -ClassName ServerPermission -Property @{
                        State = 'Deny'
                        Permission = [System.String[]] @()
                    }
                )
            )
        }

        This example shows how to call the resource using Invoke-DscResource.

    .NOTES
        The built-in property `PsDscRunAsCredential` is not supported on this DSC
        resource as it uses a complex type (another class as the type for a DSC
        property). If the property `PsDscRunAsCredential` would be used, then the
        complex type will not return any values from Get(). This is most likely an
        issue (bug) with _PowerShell DSC_. Instead (as a workaround) the property
        `Credential` must be used to specify how to connect to the SQL Server
        instance.
#>

[DscResource(RunAsCredential = 'NotSupported')]
class SqlPermission : SqlResourceBase
{
    [DscProperty(Key)]
    [System.String]
    $Name

    [DscProperty()]
    [ServerPermission[]]
    $Permission

    [DscProperty()]
    [ServerPermission[]]
    $PermissionToInclude

    [DscProperty()]
    [ServerPermission[]]
    $PermissionToExclude

    SqlPermission() : base ()
    {
        # These properties will not be enforced.
        $this.ExcludeDscProperties = @(
            'ServerName'
            'InstanceName'
            'Name'
            'Credential'
        )
    }

    [SqlPermission] Get()
    {
        # Call the base method to return the properties.
        return ([ResourceBase] $this).Get()
    }

    [System.Boolean] Test()
    {
        # Call the base method to test all of the properties that should be enforced.
        return ([ResourceBase] $this).Test()
    }

    [void] Set()
    {
        # Call the base method to enforce the properties.
        ([ResourceBase] $this).Set()
    }

    <#
        Base method Get() call this method to get the current state as a hashtable.
        The parameter properties will contain the key properties.
    #>
    hidden [System.Collections.Hashtable] GetCurrentState([System.Collections.Hashtable] $properties)
    {
        $currentStateCredential = $null

        if ($this.Credential)
        {
            <#
                This does not work, even if username is set, the method Get() will
                return an empty PSCredential-object. Kept it here so it at least
                return a Credential object.
            #>
            $currentStateCredential = [PSCredential]::new(
                $this.Credential.UserName,
                [SecureString]::new()
            )
        }

        $currentState = @{
            Credential = $currentStateCredential
            Permission = [ServerPermission[]] @()
        }

        Write-Verbose -Message (
            $this.localizedData.EvaluateServerPermissionForPrincipal -f @(
                $properties.Name,
                $properties.InstanceName
            )
        )

        $serverObject = $this.GetServerObject()

        $serverPermissionInfo = $serverObject |
            Get-SqlDscServerPermission -Name $this.Name -ErrorAction 'SilentlyContinue'

        # If permissions was returned, build the current permission array of [ServerPermission].
        if ($serverPermissionInfo)
        {
            [ServerPermission[]] $currentState.Permission = $serverPermissionInfo | ConvertTo-SqlDscServerPermission
        }

        # Always return all State; 'Grant', 'GrantWithGrant', and 'Deny'.
        foreach ($currentPermissionState in @('Grant', 'GrantWithGrant', 'Deny'))
        {
            if ($currentState.Permission.State -notcontains $currentPermissionState)
            {
                [ServerPermission[]] $currentState.Permission += [ServerPermission] @{
                    State      = $currentPermissionState
                    Permission = @()
                }
            }
        }

        $isPropertyPermissionToIncludeAssigned = $this | Test-DscProperty -Name 'PermissionToInclude' -HasValue

        if ($isPropertyPermissionToIncludeAssigned)
        {
            $currentState.PermissionToInclude = [ServerPermission[]] @()

            # Evaluate so that the desired state is present in the current state.
            foreach ($desiredIncludePermission in $this.PermissionToInclude)
            {
                <#
                    Current state will always have all possible states, so this
                    will always return one item.
                #>
                $currentStatePermissionForState = $currentState.Permission |
                    Where-Object -FilterScript {
                        $_.State -eq $desiredIncludePermission.State
                    }

                $currentStatePermissionToInclude = [ServerPermission] @{
                    State      = $desiredIncludePermission.State
                    Permission = @()
                }

                foreach ($desiredIncludePermissionName in $desiredIncludePermission.Permission)
                {
                    if ($currentStatePermissionForState.Permission -contains $desiredIncludePermissionName)
                    {
                        <#
                            If the permission exist in the current state, add the
                            permission to $currentState.PermissionToInclude so that
                            the base class's method Compare() sees the property as
                            being in desired state (when the property PermissionToInclude
                            in the current state and desired state are equal).
                        #>
                        $currentStatePermissionToInclude.Permission += $desiredIncludePermissionName
                    }
                    else
                    {
                        Write-Verbose -Message (
                            $this.localizedData.DesiredPermissionAreAbsent -f @(
                                $desiredIncludePermissionName
                            )
                        )
                    }
                }

                [ServerPermission[]] $currentState.PermissionToInclude += $currentStatePermissionToInclude
            }
        }

        $isPropertyPermissionToExcludeAssigned = $this | Test-DscProperty -Name 'PermissionToExclude' -HasValue

        if ($isPropertyPermissionToExcludeAssigned)
        {
            $currentState.PermissionToExclude = [ServerPermission[]] @()

            # Evaluate so that the desired state is missing from the current state.
            foreach ($desiredExcludePermission in $this.PermissionToExclude)
            {
                <#
                    Current state will always have all possible states, so this
                    will always return one item.
                #>
                $currentStatePermissionForState = $currentState.Permission |
                    Where-Object -FilterScript {
                        $_.State -eq $desiredExcludePermission.State
                    }

                $currentStatePermissionToExclude = [ServerPermission] @{
                    State      = $desiredExcludePermission.State
                    Permission = @()
                }

                foreach ($desiredExcludedPermissionName in $desiredExcludePermission.Permission)
                {
                    if ($currentStatePermissionForState.Permission -contains $desiredExcludedPermissionName)
                    {
                        Write-Verbose -Message (
                            $this.localizedData.DesiredAbsentPermissionArePresent -f @(
                                $desiredExcludedPermissionName
                            )
                        )
                    }
                    else
                    {
                        <#
                            If the permission does _not_ exist in the current state, add
                            the permission to $currentState.PermissionToExclude so that
                            the base class's method Compare() sees the property as being
                            in desired state (when the property PermissionToExclude in
                            the current state and desired state are equal).
                        #>
                        $currentStatePermissionToExclude.Permission += $desiredExcludedPermissionName
                    }
                }

                [ServerPermission[]] $currentState.PermissionToExclude += $currentStatePermissionToExclude
            }
        }

        return $currentState
    }

    <#
        Base method Set() call this method with the properties that should be
        enforced are not in desired state. It is not called if all properties
        are in desired state. The variable $properties contain the properties
        that are not in desired state.
    #>
    hidden [void] Modify([System.Collections.Hashtable] $properties)
    {
        $serverObject = $this.GetServerObject()

        $testSqlDscIsLoginParameters = @{
            ServerObject      = $serverObject
            Name              = $this.Name
        }

        # This will test wether the principal exist.
        $isLogin = Test-SqlDscIsLogin @testSqlDscIsLoginParameters

        if (-not $isLogin)
        {
            $missingPrincipalMessage = $this.localizedData.NameIsMissing -f @(
                $this.Name,
                $this.InstanceName
            )

            New-InvalidOperationException -Message $missingPrincipalMessage
        }

        # This holds each state and their permissions to be revoked.
        [ServerPermission[]] $permissionsToRevoke = @()
        [ServerPermission[]] $permissionsToGrantOrDeny = @()

        if ($properties.ContainsKey('Permission'))
        {
            $keyProperty = $this | Get-DscProperty -Attribute 'Key'

            $currentState = $this.GetCurrentState($keyProperty)

            <#
                Evaluate if there are any permissions that should be revoked
                from the current state.
            #>
            foreach ($currentDesiredPermissionState in $properties.Permission)
            {
                $currentPermissionsForState = $currentState.Permission |
                    Where-Object -FilterScript {
                        $_.State -eq $currentDesiredPermissionState.State
                    }

                foreach ($permissionName in $currentPermissionsForState.Permission)
                {
                    if ($permissionName -notin $currentDesiredPermissionState.Permission)
                    {
                        # Look for an existing object in the array.
                        $updatePermissionToRevoke = $permissionsToRevoke |
                            Where-Object -FilterScript {
                                $_.State -eq $currentDesiredPermissionState.State
                            }

                        # Update the existing object in the array, or create a new object
                        if ($updatePermissionToRevoke)
                        {
                            $updatePermissionToRevoke.Permission += $permissionName
                        }
                        else
                        {
                            [ServerPermission[]] $permissionsToRevoke += [ServerPermission] @{
                                State      = $currentPermissionsForState.State
                                Permission = $permissionName
                            }
                        }
                    }
                }
            }

            <#
                At least one permission were missing or should have not be present
                in the current state. Grant or Deny all permission assigned to the
                property Permission regardless if they were already present or not.
            #>
            [ServerPermission[]] $permissionsToGrantOrDeny = $properties.Permission
        }

        if ($properties.ContainsKey('PermissionToExclude'))
        {
            <#
                At least one permission were present in the current state. Revoke
                all permission assigned to the property PermissionToExclude
                regardless if they were already revoked or not.
            #>
            [ServerPermission[]] $permissionsToRevoke = $properties.PermissionToExclude
        }

        if ($properties.ContainsKey('PermissionToInclude'))
        {
            <#
                At least one permission were missing or should have not be present
                in the current state. Grant or Deny all permission assigned to the
                property Permission regardless if they were already present or not.
            #>
            [ServerPermission[]] $permissionsToGrantOrDeny = $properties.PermissionToInclude
        }

        # Revoke all the permissions set in $permissionsToRevoke
        if ($permissionsToRevoke)
        {
            <#
                TODO: Could verify with $sqlServerObject.EnumServerPermissions($Principal, $desiredPermissionSet)
                      which permissions are not already revoked.
            #>
            foreach ($currentStateToRevoke in $permissionsToRevoke)
            {
                $revokePermissionSet = $currentStateToRevoke | ConvertFrom-SqlDscServerPermission

                $setSqlDscServerPermissionParameters = @{
                    ServerObject = $serverObject
                    Name         = $this.Name
                    Permission   = $revokePermissionSet
                    State        = 'Revoke'
                    Force        = $true
                }

                if ($currentStateToRevoke.State -eq 'GrantWithGrant')
                {
                    $setSqlDscServerPermissionParameters.WithGrant = $true
                }

                try
                {
                    Set-SqlDscServerPermission @setSqlDscServerPermissionParameters
                }
                catch
                {
                    $errorMessage = $this.localizedData.FailedToRevokePermissionFromCurrentState -f @(
                        $this.Name
                    )

                    New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
                }
            }
        }

        if ($permissionsToGrantOrDeny)
        {
            <#
                TODO: Could verify with $sqlServerObject.EnumServerPermissions($Principal, $desiredPermissionSet)
                      which permissions are not already set.
            #>
            foreach ($currentDesiredPermissionState in $permissionsToGrantOrDeny)
            {
                # If there is not an empty array, change permissions.
                if (-not [System.String]::IsNullOrEmpty($currentDesiredPermissionState.Permission))
                {
                    $permissionSet = $currentDesiredPermissionState | ConvertFrom-SqlDscServerPermission

                    $setSqlDscServerPermissionParameters = @{
                        ServerObject = $serverObject
                        Name         = $this.Name
                        Permission   = $permissionSet
                        Force        = $true
                    }

                    try
                    {
                        switch ($currentDesiredPermissionState.State)
                        {
                            'GrantWithGrant'
                            {
                                Set-SqlDscServerPermission @setSqlDscServerPermissionParameters -State 'Grant' -WithGrant
                            }

                            default
                            {
                                Set-SqlDscServerPermission @setSqlDscServerPermissionParameters -State $currentDesiredPermissionState.State
                            }
                        }
                    }
                    catch
                    {
                        $errorMessage = $this.localizedData.FailedToSetPermission -f @(
                            $this.Name
                        )

                        New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
                    }
                }
            }
        }
    }

    <#
        Base method Assert() call this method with the properties that was assigned
        a value.
    #>
    hidden [void] AssertProperties([System.Collections.Hashtable] $properties)
    {
        # PermissionToInclude and PermissionToExclude should be mutually exclusive from Permission
        $assertBoundParameterParameters = @{
            BoundParameterList     = $properties
            MutuallyExclusiveList1 = @(
                'Permission'
            )
            MutuallyExclusiveList2 = @(
                'PermissionToInclude'
                'PermissionToExclude'
            )
        }

        Assert-BoundParameter @assertBoundParameterParameters

        # Get all assigned permission properties.
        $assignedPermissionProperty = $properties.Keys.Where({
                $_ -in @(
                    'Permission',
                    'PermissionToInclude',
                    'PermissionToExclude'
                )
            })

        # Must include either of the permission properties.
        if ([System.String]::IsNullOrEmpty($assignedPermissionProperty))
        {
            $errorMessage = $this.localizedData.MustAssignOnePermissionProperty

            New-InvalidArgumentException -ArgumentName 'Permission, PermissionToInclude, PermissionToExclude' -Message $errorMessage
        }

        foreach ($currentAssignedPermissionProperty in $assignedPermissionProperty)
        {
            # One State cannot exist several times in the same resource instance.
            $permissionStateGroupCount = @(
                $properties.$currentAssignedPermissionProperty |
                    Group-Object -NoElement -Property 'State' -CaseSensitive:$false |
                    Select-Object -ExpandProperty 'Count'
            )

            if ($permissionStateGroupCount -gt 1)
            {
                $errorMessage = $this.localizedData.DuplicatePermissionState

                New-InvalidArgumentException -ArgumentName $currentAssignedPermissionProperty -Message $errorMessage
            }

            # A specific permission must only exist in one permission state.
            $permissionGroupCount = $properties.$currentAssignedPermissionProperty.Permission |
                Group-Object -NoElement -CaseSensitive:$false |
                Select-Object -ExpandProperty 'Count'

            if ($permissionGroupCount -gt 1)
            {
                $errorMessage = $this.localizedData.DuplicatePermissionBetweenState

                New-InvalidArgumentException -ArgumentName $currentAssignedPermissionProperty -Message $errorMessage
            }
        }

        if ($properties.Keys -contains 'Permission')
        {
            # Each State must exist once.
            $missingPermissionState = (
                $properties.Permission.State -notcontains 'Grant' -or
                $properties.Permission.State -notcontains 'GrantWithGrant' -or
                $properties.Permission.State -notcontains 'Deny'
            )

            if ($missingPermissionState)
            {
                $errorMessage = $this.localizedData.MissingPermissionState

                New-InvalidArgumentException -ArgumentName 'Permission' -Message $errorMessage
            }
        }

        <#
            Each permission state in the properties PermissionToInclude and PermissionToExclude
            must have specified at minimum one permission.
        #>
        foreach ($currentAssignedPermissionProperty in @('PermissionToInclude', 'PermissionToExclude'))
        {
            if ($properties.Keys -contains $currentAssignedPermissionProperty)
            {
                foreach ($currentServerPermission in $properties.$currentAssignedPermissionProperty)
                {
                    if ($currentServerPermission.Permission.Count -eq 0)
                    {
                        $errorMessage = $this.localizedData.MustHaveMinimumOnePermissionInState -f $currentAssignedPermissionProperty

                        New-InvalidArgumentException -ArgumentName $currentAssignedPermissionProperty -Message $errorMessage
                    }
                }
            }
        }
    }
}
