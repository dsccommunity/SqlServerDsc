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

    .PARAMETER Ensure
        If the permission should be granted ('Present') or revoked ('Absent').

    .PARAMETER Reasons
        Returns the reason a property is not in desired state.
#>

[DscResource()]
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

    [DscProperty(Mandatory)]
    [DatabasePermission[]]
    $Permission

    [DscProperty()]
    [Ensure]
    $Ensure = [Ensure]::Present

    [DscProperty(NotConfigurable)]
    [Reason[]]
    $Reasons

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
        $currentState = @{
            Ensure       = 'Absent'
            ServerName   = $this.ServerName
            InstanceName = $properties.InstanceName
            DatabaseName = $properties.DatabaseName
            Permission   = [DatabasePermission[]] @()
            Name         = $properties.Name
        }

        $sqlServerObject = Connect-SqlDscDatabaseEngine -ServerName $this.ServerName -InstanceName $properties.InstanceName

        # TA BORT -VERBOSE!
        Write-Verbose -Verbose -Message (
            $script:localizedData.EvaluateDatabasePermissionForPrincipal -f @(
                $properties.Name,
                $properties.DatabaseName,
                $properties.InstanceName
            )
        )

        $databasePermissionInfo = $sqlServerObject |
            Get-SqlDscDatabasePermission -DatabaseName $this.DatabaseName -Name $this.Name -IgnoreMissingPrincipal

        if ($databasePermissionInfo)
        {
            $permissionState = $databasePermissionInfo | ForEach-Object -Process {
                # Convert from the type PermissionState to String.
                [System.String] $_.PermissionState
            } | Select-Object -Unique

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
                    $permissionProperty = (
                        $currentPermission.PermissionType |
                            Get-Member -MemberType Property
                    ).Name

                    foreach ($currentPermissionProperty in $permissionProperty)
                    {
                        if ($currentPermission.PermissionType."$currentPermissionProperty")
                        {
                            $statePermissionResult += $currentPermissionProperty
                        }
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

                $currentState.Permission += $databasePermission
            }
        }

        return $currentState
    }

    <#
        Base method Set() call this method with the properties that should be
        enforced and that are not in desired state.
    #>
    hidden [void] Modify([System.Collections.Hashtable] $properties)
    {
        Write-Verbose -Message ($properties | Out-String) -Verbose

        #Set-DnsServerDsSetting @properties
    }

    <#
        Base method Assert() call this method with the properties that was passed
        a value.
    #>
    hidden [void] AssertProperties([System.Collections.Hashtable] $properties)
    {
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
