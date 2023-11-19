<#
    .SYNOPSIS
        The `SqlDatabasePermission` DSC resource is used to grant, deny or revoke
        permissions for a user in a database.

    .DESCRIPTION
        The `SqlDatabasePermission` DSC resource is used to grant, deny or revoke
        permissions for a user in a database. For more information about permissions,
        please read the article [Permissions (Database Engine)](https://docs.microsoft.com/en-us/sql/relational-databases/security/permissions-database-engine).

        > [!CAUTION]
        > When revoking permission with PermissionState 'GrantWithGrant', both the
        > grantee and _all the other users the grantee has granted the same permission_
        > _to_, will also get their permission revoked.

        ## Requirements

        * Target machine must be running Windows Server 2012 or later.
        * Target machine must be running SQL Server Database Engine 2012 or later.

        ## Known issues

        All issues are not listed here, see [here for all open issues](https://github.com/dsccommunity/SqlServerDsc/issues?q=is%3Aissue+is%3Aopen+in%3Atitle+SqlDatabasePermission).

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

        The parameter Permission is of type `[DatabasePermission]`. If a property
        in the type is set to an invalid value an error will occur, correct the
        values in the properties to valid values.
        This happens when the values are validated against the `[ValidateSet()]`
        of the resource. When there is an invalid value the following error will
        be thrown when the configuration is run (it will not show during compilation):

        ```plaintext
        Failed to create an object of PowerShell class SqlDatabasePermission.
            + CategoryInfo          : InvalidOperation: (root/Microsoft/...ConfigurationManager:String) [], CimException
            + FullyQualifiedErrorId : InstantiatePSClassObjectFailed
            + PSComputerName        : localhost
        ```

    .PARAMETER DatabaseName
        The name of the database.

    .PARAMETER Name
        The name of the user that should be granted or denied the permission.

    .PARAMETER Permission
        An array of database permissions to enforce. Any permission that is not
        part of the desired state will be revoked.

        Must provide all permission states (`Grant`, `Deny`, `GrantWithGrant`) with
        at least an empty string array for the advanced type `DatabasePermission`'s
        property `Permission`.

        Valid permission names can be found in the article [DatabasePermissionSet Class properties](https://docs.microsoft.com/en-us/dotnet/api/microsoft.sqlserver.management.smo.databasepermissionset#properties).

        This is an array of CIM instances of advanced type `DatabasePermission` from
        the namespace `root/Microsoft/Windows/DesiredStateConfiguration`.

    .PARAMETER PermissionToInclude
        An array of database permissions to include to the current state. The
        current state will not be affected unless the current state contradict the
        desired state. For example if the desired state specifies a deny permissions
        but in the current state that permission is granted, that permission will
        be changed to be denied.

        Valid permission names can be found in the article [DatabasePermissionSet Class properties](https://docs.microsoft.com/en-us/dotnet/api/microsoft.sqlserver.management.smo.databasepermissionset#properties).

        This is an array of CIM instances of advanced type `DatabasePermission` from
        the namespace `root/Microsoft/Windows/DesiredStateConfiguration`.

    .PARAMETER PermissionToExclude
        An array of database permissions to exclude (revoke) from the current state.

        Valid permission names can be found in the article [DatabasePermissionSet Class properties](https://docs.microsoft.com/en-us/dotnet/api/microsoft.sqlserver.management.smo.databasepermissionset#properties).

        This is an array of CIM instances of advanced type `DatabasePermission` from
        the namespace `root/Microsoft/Windows/DesiredStateConfiguration`.

    .EXAMPLE
        Invoke-DscResource -ModuleName SqlServerDsc -Name SqlDatabasePermission -Method Get -Property @{
            ServerName           = 'localhost'
            InstanceName         = 'SQL2017'
            DatabaseName         = 'AdventureWorks'
            Credential           = (Get-Credential -UserName 'myuser@company.local' -Message 'Password:')
            Name                 = 'INSTANCE\SqlUser'
            Permission           = [Microsoft.Management.Infrastructure.CimInstance[]] @(
                (
                    New-CimInstance -ClientOnly -Namespace root/Microsoft/Windows/DesiredStateConfiguration -ClassName DatabasePermission -Property @{
                            State = 'Grant'
                            Permission = @('select')
                    }
                )
                (
                    New-CimInstance -ClientOnly -Namespace root/Microsoft/Windows/DesiredStateConfiguration -ClassName DatabasePermission -Property @{
                        State = 'GrantWithGrant'
                        Permission = [System.String[]] @()
                    }
                )
                (
                    New-CimInstance -ClientOnly -Namespace root/Microsoft/Windows/DesiredStateConfiguration -ClassName DatabasePermission -Property @{
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
        `Credential` must be used to specify how to connect to the _SQL Server_
        instance.
#>

[DscResource(RunAsCredential = 'NotSupported')]
class SqlDatabasePermission : SqlResourceBase
{
    [DscProperty(Key)]
    [System.String]
    $DatabaseName

    [DscProperty(Key)]
    [System.String]
    $Name

    [DscProperty()]
    [DatabasePermission[]]
    $Permission

    [DscProperty()]
    [DatabasePermission[]]
    $PermissionToInclude

    [DscProperty()]
    [DatabasePermission[]]
    $PermissionToExclude

    SqlDatabasePermission() : base ()
    {
        # These properties will not be enforced.
        $this.ExcludeDscProperties = @(
            'ServerName'
            'InstanceName'
            'DatabaseName'
            'Name'
            'Credential'
        )
    }

    [SqlDatabasePermission] Get()
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
            Permission = [DatabasePermission[]] @()
        }

        Write-Verbose -Message (
            $this.localizedData.EvaluateDatabasePermissionForPrincipal -f @(
                $properties.Name,
                $properties.DatabaseName,
                $properties.InstanceName
            )
        )

        $serverObject = $this.GetServerObject()

        $databasePermissionInfo = $serverObject |
            Get-SqlDscDatabasePermission -DatabaseName $this.DatabaseName -Name $this.Name -ErrorAction 'SilentlyContinue'

        # If permissions was returned, build the current permission array of [DatabasePermission].
        if ($databasePermissionInfo)
        {
            [DatabasePermission[]] $currentState.Permission = $databasePermissionInfo | ConvertTo-SqlDscDatabasePermission
        }

        # Always return all State; 'Grant', 'GrantWithGrant', and 'Deny'.
        foreach ($currentPermissionState in @('Grant', 'GrantWithGrant', 'Deny'))
        {
            if ($currentState.Permission.State -notcontains $currentPermissionState)
            {
                [DatabasePermission[]] $currentState.Permission += [DatabasePermission] @{
                    State      = $currentPermissionState
                    Permission = @()
                }
            }
        }

        $isPropertyPermissionToIncludeAssigned = $this | Test-DscProperty -Name 'PermissionToInclude' -HasValue

        if ($isPropertyPermissionToIncludeAssigned)
        {
            $currentState.PermissionToInclude = [DatabasePermission[]] @()

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

                $currentStatePermissionToInclude = [DatabasePermission] @{
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

                [DatabasePermission[]] $currentState.PermissionToInclude += $currentStatePermissionToInclude
            }
        }

        $isPropertyPermissionToExcludeAssigned = $this | Test-DscProperty -Name 'PermissionToExclude' -HasValue

        if ($isPropertyPermissionToExcludeAssigned)
        {
            $currentState.PermissionToExclude = [DatabasePermission[]] @()

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

                $currentStatePermissionToExclude = [DatabasePermission] @{
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

                [DatabasePermission[]] $currentState.PermissionToExclude += $currentStatePermissionToExclude
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

        $testSqlDscIsDatabasePrincipalParameters = @{
            ServerObject      = $serverObject
            DatabaseName      = $this.DatabaseName
            Name              = $this.Name
            ExcludeFixedRoles = $true
        }

        # This will test wether the database and the principal exist.
        $isDatabasePrincipal = Test-SqlDscIsDatabasePrincipal @testSqlDscIsDatabasePrincipalParameters

        if (-not $isDatabasePrincipal)
        {
            $missingPrincipalMessage = $this.localizedData.NameIsMissing -f @(
                $this.Name,
                $this.DatabaseName,
                $this.InstanceName
            )

            New-InvalidOperationException -Message $missingPrincipalMessage
        }

        # This holds each state and their permissions to be revoked.
        [DatabasePermission[]] $permissionsToRevoke = @()
        [DatabasePermission[]] $permissionsToGrantOrDeny = @()

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
                            [DatabasePermission[]] $permissionsToRevoke += [DatabasePermission] @{
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
            [DatabasePermission[]] $permissionsToGrantOrDeny = $properties.Permission
        }

        if ($properties.ContainsKey('PermissionToExclude'))
        {
            <#
                At least one permission were present in the current state. Revoke
                all permission assigned to the property PermissionToExclude
                regardless if they were already revoked or not.
            #>
            [DatabasePermission[]] $permissionsToRevoke = $properties.PermissionToExclude
        }

        if ($properties.ContainsKey('PermissionToInclude'))
        {
            <#
                At least one permission were missing or should have not be present
                in the current state. Grant or Deny all permission assigned to the
                property Permission regardless if they were already present or not.
            #>
            [DatabasePermission[]] $permissionsToGrantOrDeny = $properties.PermissionToInclude
        }

        # Revoke all the permissions set in $permissionsToRevoke
        if ($permissionsToRevoke)
        {
            foreach ($currentStateToRevoke in $permissionsToRevoke)
            {
                $revokePermissionSet = $currentStateToRevoke | ConvertFrom-SqlDscDatabasePermission

                $setSqlDscDatabasePermissionParameters = @{
                    ServerObject = $serverObject
                    DatabaseName = $this.DatabaseName
                    Name         = $this.Name
                    Permission   = $revokePermissionSet
                    State        = 'Revoke'
                    Force        = $true
                }

                if ($currentStateToRevoke.State -eq 'GrantWithGrant')
                {
                    $setSqlDscDatabasePermissionParameters.WithGrant = $true
                }

                try
                {
                    Set-SqlDscDatabasePermission @setSqlDscDatabasePermissionParameters
                }
                catch
                {
                    $errorMessage = $this.localizedData.FailedToRevokePermissionFromCurrentState -f @(
                        $this.Name,
                        $this.DatabaseName
                    )

                    New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
                }
            }
        }

        if ($permissionsToGrantOrDeny)
        {
            foreach ($currentDesiredPermissionState in $permissionsToGrantOrDeny)
            {
                # If there is not an empty array, change permissions.
                if (-not [System.String]::IsNullOrEmpty($currentDesiredPermissionState.Permission))
                {
                    $permissionSet = $currentDesiredPermissionState | ConvertFrom-SqlDscDatabasePermission

                    $setSqlDscDatabasePermissionParameters = @{
                        ServerObject = $serverObject
                        DatabaseName = $this.DatabaseName
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
                                Set-SqlDscDatabasePermission @setSqlDscDatabasePermissionParameters -State 'Grant' -WithGrant
                            }

                            default
                            {
                                Set-SqlDscDatabasePermission @setSqlDscDatabasePermissionParameters -State $currentDesiredPermissionState.State
                            }
                        }
                    }
                    catch
                    {
                        $errorMessage = $this.localizedData.FailedToSetPermission -f @(
                            $this.Name,
                            $this.DatabaseName
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
                foreach ($currentDatabasePermission in $properties.$currentAssignedPermissionProperty)
                {
                    if ($currentDatabasePermission.Permission.Count -eq 0)
                    {
                        $errorMessage = $this.localizedData.MustHaveMinimumOnePermissionInState -f $currentAssignedPermissionProperty

                        New-InvalidArgumentException -ArgumentName $currentAssignedPermissionProperty -Message $errorMessage
                    }
                }
            }
        }
    }
}
