<#
    .SYNOPSIS
        The `SqlDatabasePermission` DSC resource is used to grant, deny or revoke
        permissions for a user in a database

    .DESCRIPTION
        The `SqlDatabasePermission` DSC resource is used to grant, deny or revoke
        permissions for a user in a database. For more information about permissions,
        please read the article [Permissions (Database Engine)](https://docs.microsoft.com/en-us/sql/relational-databases/security/permissions-database-engine).

        >**Note:** When revoking permission with PermissionState 'GrantWithGrant', both the
        >grantee and _all the other users the grantee has granted the same permission to_,
        >will also get their permission revoked.

        Valid permission names can be found in the article [DatabasePermissionSet Class properties](https://docs.microsoft.com/en-us/dotnet/api/microsoft.sqlserver.management.smo.databasepermissionset#properties).

        ## Requirements

        * Target machine must be running Windows Server 2012 or later.
        * Target machine must be running SQL Server Database Engine 2012 or later.

        ## Known issues

        All issues are not listed here, see [here for all open issues](https://github.com/dsccommunity/SqlServerDsc/issues?q=is%3Aissue+is%3Aopen+in%3Atitle+SqlDatabasePermission).

        ### `PSDscRunAsCredential` not supported

        The built-in property `PSDscRunAsCredential` does not work with class-based
        resources that using advanced type like the parameter `Permission` does.
        Use the parameter `Credential` instead of `PSDscRunAsCredential`.

        ### Invalid values during compilation

        The parameter Permission is of type `[DatabasePermission]`. If a property
        in the type is set to an invalid value an error will occur, this is expected.
        This happens when the values are validated against the `[ValidateSet()]`
        of the resource. In such case the following error will be thrown from
        PowerShell DSC during the compilation of the configuration:

        ```plaintext
        Failed to create an object of PowerShell class SqlDatabasePermission.
            + CategoryInfo          : InvalidOperation: (root/Microsoft/...ConfigurationManager:String) [], CimException
            + FullyQualifiedErrorId : InstantiatePSClassObjectFailed
            + PSComputerName        : localhost
        ```

    .PARAMETER InstanceName
        The name of the SQL Server instance to be configured. Default value is
        'MSSQLSERVER'.

    .PARAMETER DatabaseName
        The name of the database.

    .PARAMETER Name
        The name of the user that should be granted or denied the permission.

    .PARAMETER ServerName
        The host name of the SQL Server to be configured. Default value is the
        current computer name.

    .PARAMETER Permission
        An array of database permissions to enforce.

        This is an array of CIM instances of class `DatabasePermission` from the
        namespace `root/Microsoft/Windows/DesiredStateConfiguration`.

    .PARAMETER Credential
        Specifies the credential to use to connect to the _SQL Server_ instance.
        The username of the credentials must be in the format `user@domain`, e.g.
        `MySqlUser@company.local`.

        If parameter **Credential'* is not provided then the resource instance is
        run using the credential that runs the configuration.

    .PARAMETER Ensure
        If the permission should be granted ('Present') or revoked ('Absent').

    .PARAMETER Reasons
        Returns the reason a property is not in desired state.

    .EXAMPLE
        Invoke-DscResource -ModuleName SqlServerDsc -Name SqlDatabasePermission -Method Get -Property @{
            Ensure               = 'Present'
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
        `Credential` must be used to specify how to connect to the SQL Server
        instance.

#>

[DscResource(RunAsCredential = 'NotSupported')]
class SqlDatabasePermission : ResourceBase
{
    [DscProperty(Key)]
    [System.String]
    $InstanceName

    [DscProperty(Key)]
    [System.String]
    $DatabaseName

    [DscProperty(Key)]
    [System.String]
    $Name

    [DscProperty()]
    [System.String]
    $ServerName = (Get-ComputerName)

    [DscProperty()]
    [DatabasePermission[]]
    $Permission

    [DscProperty()]
    [DatabasePermission[]]
    $PermissionToInclude

    [DscProperty()]
    [DatabasePermission[]]
    $PermissionToExclude

    [DscProperty()]
    [PSCredential]
    $Credential

    # [DscProperty()]
    # [Ensure]
    # $Ensure = [Ensure]::Present

    [DscProperty(NotConfigurable)]
    [Reason[]]
    $Reasons

    SqlDatabasePermission() : base ()
    {
        # These properties will not be enforced.
        $this.notEnforcedProperties = @(
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
                TODO: This does not work, Get() will return an empty PSCredential-object.
                      Using MOF-based resource variant does not work either as it throws
                      an error: https://github.com/dsccommunity/ActiveDirectoryDsc/blob/b2838d945204e1153cc3cbfca1a3d90671e0a61c/source/Modules/ActiveDirectoryDsc.Common/ActiveDirectoryDsc.Common.psm1#L1834-L1856
            #>
            $currentStateCredential = [PSCredential]::new(
                $this.Credential.UserName,
                [SecureString]::new()
            )
        }

        # The property Ensure and key properties will be handled by the base class.
        $currentState = @{
            Credential = $currentStateCredential
            Permission = [DatabasePermission[]] @()
        }

        $connectSqlDscDatabaseEngineParameters = @{
            ServerName = $this.ServerName
            InstanceName = $properties.InstanceName
        }

        if ($this.Credential)
        {
            $connectSqlDscDatabaseEngineParameters.Credential = $this.Credential
        }

        # TODO: By adding a hidden property that holds the server object we only need to connect when that property is $null.
        $serverObject = Connect-SqlDscDatabaseEngine @connectSqlDscDatabaseEngineParameters

        # TODO: TA BORT -VERBOSE!
        Write-Verbose -Verbose -Message (
            $this.localizedData.EvaluateDatabasePermissionForPrincipal -f @(
                $properties.Name,
                $properties.DatabaseName,
                $properties.InstanceName
            )
        )

        $databasePermissionInfo = $serverObject |
            Get-SqlDscDatabasePermission -DatabaseName $this.DatabaseName -Name $this.Name -ErrorAction 'SilentlyContinue'

        # If permissions was returned, build the current permission array of [DatabasePermission].
        if ($databasePermissionInfo)
        {
            $permissionState = @(
                $databasePermissionInfo | ForEach-Object -Process {
                    # Convert from the type PermissionState to String.
                    [System.String] $_.PermissionState
                } |
                Select-Object -Unique
            )

            foreach ($currentPermissionState in $permissionState)
            {
                $filteredDatabasePermission = $databasePermissionInfo |
                    Where-Object -FilterScript {
                        $_.PermissionState -eq $currentPermissionState
                    }

                $databasePermission = [DatabasePermission] @{
                    State = $currentPermissionState
                }

                # Initialize variable permission
                [System.String[]] $statePermissionResult = @()

                foreach ($currentPermission in $filteredDatabasePermission)
                {
                    # get the permissions that is set to $true
                    $permissionProperty = $currentPermission.PermissionType |
                        Get-Member -MemberType 'Property' |
                        Select-Object -ExpandProperty 'Name' |
                        Where-Object -FilterScript {
                            $currentPermission.PermissionType.$_
                        }


                    foreach ($currentPermissionProperty in $permissionProperty)
                    {
                        $statePermissionResult += $currentPermissionProperty
                    }
                }

                <#
                    Sort and remove any duplicate permissions, also make sure
                    it is an array even if only one item.
                #>
                $databasePermission.Permission = @(
                    $statePermissionResult |
                        Sort-Object -Unique
                )

                [DatabasePermission[]] $currentState.Permission += $databasePermission
            }
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

        $isPropertyPermissionToIncludeAssigned = $this | Test-ResourcePropertyIsAssigned -Name 'PermissionToInclude'

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

        $isPropertyPermissionToExcludeAssigned = $this | Test-ResourcePropertyIsAssigned -Name 'PermissionToExclude'

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
        enforced and that are not in desired state. It is not called if all
        properties are in desired state. The variable $properties contain the
        properties that are not in desired state.
    #>
    hidden [void] Modify([System.Collections.Hashtable] $properties)
    {
        # TODO: Remove line below
        Write-Verbose -Message ($properties | Out-String) -Verbose

        $connectSqlDscDatabaseEngineParameters = @{
            ServerName = $this.ServerName
            InstanceName = $this.InstanceName
        }

        if ($this.Credential)
        {
            $connectSqlDscDatabaseEngineParameters.Credential = $this.Credential
        }

        $serverObject = Connect-SqlDscDatabaseEngine @connectSqlDscDatabaseEngineParameters

        $testSqlDscIsDatabasePrincipalParameters = @{
            ServerObject      = $serverObject
            DatabaseName      = $this.DatabaseName
            Name              = $this.Name
            ExcludeFixedRoles = $true
        }

        # This will test wether the database and the principal exist.
        $isDatabasePrincipal = Test-SqlDscIsDatabasePrincipal @testSqlDscIsDatabasePrincipalParameters

        if ($isDatabasePrincipal)
        {
            $keyProperty = $this | Get-DscProperty -Type 'Key'

            $currentState = $this.GetCurrentState($keyProperty)

            <#
                TODO: Remove this comment-block.
                Update permissions if:

                - $properties contains property Permission
                - $properties contains property Ensure and it is set to 'Absent'

                First will happen when there are additional permissions to add
                to the current state.

                Second will happen when there are permissions in the current state
                that should be absent.
            #>
            if ($properties.ContainsKey('Permission'))
            {
                foreach ($currentPermission in $this.Permission)
                {
                    $currentPermissionsForState = $currentState.Permission |
                        Where-Object -FilterScript {
                            $_.State -eq $currentPermission.State
                        }

                    # Revoke permissions that are not part of the desired state
                    if ($currentPermissionsForState)
                    {
                        $permissionsToRevoke = @()

                        $revokePermissionSet = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionSet'

                        foreach ($permissionName in $currentPermissionsForState.Permission)
                        {
                            if ($permissionName -notin $currentPermission.Permission)
                            {
                                $permissionsToRevoke += $permissionName

                                $revokePermissionSet.$permissionName = $true
                            }
                        }

                        if ($permissionsToRevoke)
                        {
                            Write-Verbose -Message (
                                $this.localizedData.RevokePermissionNotInDesiredState -f @(
                                    ($permissionsToRevoke -join "', '"),
                                    $this.Name,
                                    $this.DatabaseName
                                )
                            )

                            $setSqlDscDatabasePermissionParameters = @{
                                ServerObject = $serverObject
                                DatabaseName = $this.DatabaseName
                                Name         = $this.Name
                                Permission   = $revokePermissionSet
                                State        = 'Revoke'
                            }

                            if ($currentPermission.State -eq 'GrantWithGrant')
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

                                <#
                                    TODO: Update the CONTRIBUTING.md section "Class-based DSC resource"
                                          that now says that 'throw' should be used.. we should use
                                          helper function instead. Or something similar to commands
                                          where the ID number is part of code? But might be a problem
                                          tracing a specific verbose string down?
                                #>
                                New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
                            }
                        }
                    }

                    # If there is not an empty array, change permissions.
                    if (-not [System.String]::IsNullOrEmpty($currentPermission.Permission))
                    {
                        $permissionSet = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionSet'

                        foreach ($permissionName in $currentPermission.Permission)
                        {
                            $permissionSet.$permissionName = $true
                        }

                        $setSqlDscDatabasePermissionParameters = @{
                            ServerObject = $serverObject
                            DatabaseName = $this.DatabaseName
                            Name         = $this.Name
                            Permission   = $permissionSet
                        }

                        try
                        {
                            switch ($currentPermission.State)
                            {
                                'GrantWithGrant'
                                {
                                    Set-SqlDscDatabasePermission @setSqlDscDatabasePermissionParameters -State 'Grant' -WithGrant
                                }

                                default
                                {
                                    Set-SqlDscDatabasePermission @setSqlDscDatabasePermissionParameters -State $currentPermission.State
                                }
                            }

                            # if ($currentPermission.State -eq 'GrantWithGrant')
                            # {
                            #     Set-SqlDscDatabasePermission @setSqlDscDatabasePermissionParameters -State 'Revoke' -WithGrant
                            # }
                            # else
                            # {
                            #     Set-SqlDscDatabasePermission @setSqlDscDatabasePermissionParameters -State 'Revoke'
                            # }
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
        else
        {
            $missingPrincipalMessage = $this.localizedData.NameIsMissing -f @(
                $this.Name,
                $this.DatabaseName,
                $this.InstanceName
            )

            New-InvalidOperationException -Message $missingPrincipalMessage
        }
    }

    <#
        Base method Assert() call this method with the properties that was passed
        a value.
    #>
    hidden [void] AssertProperties([System.Collections.Hashtable] $properties)
    {
        # TODO: Add the evaluation so that one permission can't be added two different states ('Grant' and 'Deny') in the same resource instance.

        # PermissionToInclude and PermissionToExclude should be mutually exclusive from Permission
        $assertBoundParameterParameters = @{
            BoundParameterList = $this | Get-DscProperty -Type 'Optional' -HasValue
            MutuallyExclusiveList1 = @(
                'Permission'
            )
            MutuallyExclusiveList2 = @(
                'PermissionToInclude'
                'PermissionToExclude'
            )
        }

        Assert-BoundParameter @assertBoundParameterParameters

        $isPropertyPermissionAssigned = $this | Test-ResourcePropertyIsAssigned -Name 'Permission'

        if ($isPropertyPermissionAssigned)
        {
            # One State cannot exist several times in the same resource instance.
            $permissionStateGroupCount = @(
                $this.Permission |
                    Group-Object -NoElement -Property 'State' -CaseSensitive:$false |
                    Select-Object -ExpandProperty 'Count'
            )

            if ($permissionStateGroupCount -gt 1)
            {
                throw $this.localizedData.DuplicatePermissionState
            }

            # Each State must exist once.
            $missingPermissionState = (
                $this.Permission.State -notcontains 'Grant' -or
                $this.Permission.State -notcontains 'GrantWithGrant' -or
                $this.Permission.State -notcontains 'Deny'
            )

            if ($missingPermissionState)
            {
                throw $this.localizedData.MissingPermissionState
            }
        }

        # TODO: PermissionToInclude and PermissionToExclude must not contain an empty collection for property Permission
    }
}
