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
            + CategoryInfo          : InvalidOperation: (root/Microsoft/...gurationManager:String) [], CimException
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
            Credential  = $SqlInstallCredential
            Name                 = 'SQLTEST\sqluser'
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
                        Permission = @('update')
                    }
                )
            )
        }

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

    # TODO: Should also add IncludePermission and ExcludePermission which should be mutually exclusive from Permission
    [DscProperty(Mandatory)]
    [DatabasePermission[]]
    $Permission

    [DscProperty()]
    [PSCredential]
    $Credential

    [DscProperty()]
    [Ensure]
    $Ensure = [Ensure]::Present

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

        $sqlServerObject = Connect-SqlDscDatabaseEngine @connectSqlDscDatabaseEngineParameters

        # TODO: TA BORT -VERBOSE!
        Write-Verbose -Verbose -Message (
            $this.localizedData.EvaluateDatabasePermissionForPrincipal -f @(
                $properties.Name,
                $properties.DatabaseName,
                $properties.InstanceName
            )
        )

        $databasePermissionInfo = $sqlServerObject |
            Get-SqlDscDatabasePermission -DatabaseName $this.DatabaseName -Name $this.Name -ErrorAction 'SilentlyContinue'

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

        <#
            TODO:
            Need to handle Absent state: The property Permission is
            in desired state because the desired state permission
            ('update') does not exist in current state:
            {"State":"Grant","Permission":["update"]}, but was {"State":"Grant","Permission":["Connect"]}

            When $this.Ensure is 'Absent' and the node is in desired
            state the current state permissions will always differ
            from desired state permissions, since the current permission
            will never have the permission that desired state says
            should be removed.

            When $this.Ensure is 'Absent', and the permission does
            not exist in the current state when we should add 'Permission'
            to the property $this.notEnforcedProperties so that the
            Permission property is not compared. This way we return
            the correct current state. Maybe we can set
            $this.notEnforcedProperties in the constructor?

            We should also return the property 'Ensure' set to 'Absent'
            so the base class does not try to evaluate the state itself.
            The base class does not know and cannot know how to evaluate
            the permissions correctly.
        #>
        return $currentState
    }

    <#
        Base method Set() call this method with the properties that should be
        enforced and that are not in desired state. It is not called if all
        properties are in desired state.
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
            if ($properties.ContainsKey('Permission'))
            {
                # TODO: Remove this?
                # Write-Verbose -Message (
                #     $this.localizedData.ChangePermissionForUser -f @(
                #         $this.Name,
                #         $this.DatabaseName,
                #         $this.InstanceName
                #     )
                # )

                foreach ($currentPermission in $properties.Permission)
                {
                    try
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

                        switch ($this.Ensure)
                        {
                            'Present'
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
                            }

                            'Absent'
                            {
                                if ($currentPermission.State -eq 'GrantWithGrant')
                                {
                                    Set-SqlDscDatabasePermission @setSqlDscDatabasePermissionParameters -State 'Revoke' -WithGrant
                                }
                                else
                                {
                                    Set-SqlDscDatabasePermission @setSqlDscDatabasePermissionParameters -State 'Revoke'
                                }
                            }
                        }
                    }
                    catch
                    {
                        $errorMessage = $this.localizedData.FailedToSetPermissionDatabase -f $this.Name, $this.DatabaseName

                        New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
                    }
                }
            }
        }
        else
        {
            $missingPrincipalMessage = $this.localizedData.NameIsMissing -f @(
                $properties.Name,
                $properties.DatabaseName,
                $properties.InstanceName
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

        # TODO: Add the evaluation so that the same State cannot exist several times in the same resource instance.
        Write-Verbose -Verbose -Message 'NotImplemented: AssertProperties()'

        # @(
        #     'DirectoryPartitionAutoEnlistInterval',
        #     'TombstoneInterval'
        # ) | ForEach-Object -Process {
        #     $valueToConvert = $this.$_

        #     # Only evaluate properties that have a value.
        #     if ($null -ne $valueToConvert)
        #     {
        #         Assert-TimeSpan -PropertyName $_ -Value $valueToConvert -Minimum '0.00:00:00'
        #     }
        # }
    }
}
