$script:sqlServerDscHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\SqlServerDsc.Common'
$script:resourceHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DscResource.Common'

Import-Module -Name $script:sqlServerDscHelperModulePath
Import-Module -Name $script:resourceHelperModulePath

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

<#
    .SYNOPSIS
        Returns the current permissions for the object in the database.

    .PARAMETER InstanceName
        Specifies the name of the SQL instance to be configured.

    .PARAMETER DatabaseName
        Specifies the name of the database where the object resides.

    .PARAMETER SchemaName
        Specifies the name of the schema for the database object.

    .PARAMETER ObjectName
        Specifies the name of the database object to set permission for.
        Can be an empty value when setting permission for a schema.

    .PARAMETER ObjectType
        Specifies the type of the database object to set permission for.

    .PARAMETER Name
        Specifies the name of the database user, user-defined database role, or
        database application role that will have the permission.

    .PARAMETER Permission
        Specifies the permissions as an array of embedded instances of the
        DSC_DatabaseObjectPermission CIM class.

    .PARAMETER ServerName
        Specifies the host name of the SQL Server to be configured. Default value
        is the current computer name.

    .PARAMETER Force
        Specifies that permissions that has parameter Ensure set to 'Present'
        (the default value for permissions) should always be enforced even if that
        encompasses cascading revocations. An example if the desired state is
        'Grant' but the current state is 'GrantWithGrant'. If parameter Force is set
        to $true the With Grant permission is revoked, if set to $false an exception
        is thrown since the desired state could not be set. Default is to throw an
        exception.
#>
function Get-TargetResource
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('SqlServerDsc.AnalyzerRules\Measure-CommandsNeededToLoadSMO', '', Justification='The command Connect-Sql is called when Get-DatabaseObject is called')]
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DatabaseName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SchemaName,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [System.String]
        $ObjectName,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Schema', 'Table', 'View', 'StoredProcedure')]
        [System.String]
        $ObjectType,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $Permission,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = (Get-ComputerName),

        [Parameter()]
        [System.Boolean]
        $Force
    )

    Write-Verbose -Message (
        $script:localizedData.GetObjectPermission -f ('{0}.{1}' -f $SchemaName, $ObjectName), $ObjectType, $DatabaseName, $InstanceName, $ServerName
    )

    $Permission = Assert-PermissionEnsureProperty -Permission $Permission

    # Create an empty collection of CimInstance that we can return.
    $cimInstancePermissionCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

    $returnValue = @{
        ServerName   = $ServerName
        InstanceName = $InstanceName
        DatabaseName = $DatabaseName
        SchemaName   = $SchemaName
        ObjectName   = $ObjectName
        ObjectType   = $ObjectType
        Name         = $Name
        Permission   = $cimInstancePermissionCollection
        Force        = $Force
    }

    $getDatabaseObjectParameters = @{
        ServerName   = $ServerName
        InstanceName = $InstanceName
        DatabaseName = $DatabaseName
        SchemaName   = $SchemaName
        ObjectName   = $ObjectName
        ObjectType   = $ObjectType
    }

    $sqlObject = Get-DatabaseObject @getDatabaseObjectParameters

    if ($sqlObject)
    {
        # Get the names of the possible permissions by creating an empty object.
        $permissionProperties = (
            New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ObjectPermissionSet' |
                Get-Member -MemberType 'Property'
        ).Name

        # Loop through each desired permission state.
        foreach ($desiredPermission in $Permission)
        {
            [System.String[]] $currentObjectPermissionNames = @()

            # Get all current permissions for the permission state.
            $currentObjectPermissions = $sqlObject.EnumObjectPermissions($Name) |
                Where-Object -FilterScript {
                    $_.PermissionState -eq $desiredPermission.State
                }

            if ($currentObjectPermissions)
            {
                # Loop through each property to see if it is set to $true
                foreach ($currentPermissionProperty in $permissionProperties)
                {
                    if ($true -in $currentObjectPermissions.PermissionType.$currentPermissionProperty)
                    {
                        $currentObjectPermissionNames += $currentPermissionProperty
                    }
                }

                # Remove any duplicate permission names.
                $currentObjectPermissionNames = @(
                    $currentObjectPermissionNames |
                        Sort-Object -Unique
                )
            }

            $compareObjectParameters = @{
                ReferenceObject  = $desiredPermission.Permission
                DifferenceObject = $currentObjectPermissionNames
            }

            $resultOfPermissionCompare = Compare-Object @compareObjectParameters |
                Where-Object -FilterScript {
                    $_.SideIndicator -eq '<='
                }

            # If there are no missing permission then return 'Ensure' state as 'Present'.
            if ($null -eq $resultOfPermissionCompare)
            {
                $currentState = 'Present'
            }
            else
            {
                $currentState = 'Absent'
            }

            $cimInstancePermissionCollection += ConvertTo-CimDatabaseObjectPermission `
                -Permission $desiredPermission.Permission `
                -PermissionState $desiredPermission.State `
                -Ensure $currentState
        }

        $returnValue['Permission'] = $cimInstancePermissionCollection
    }

    return $returnValue
}

<#
    .SYNOPSIS
        Sets the permissions for the object in the database.

    .PARAMETER InstanceName
        Specifies the name of the SQL instance to be configured.

    .PARAMETER DatabaseName
        Specifies the name of the database where the object resides.

    .PARAMETER SchemaName
        Specifies the name of the schema for the database object.

    .PARAMETER ObjectName
        Specifies the name of the database object to set permission for.
        Can be an empty value when setting permission for a schema.

    .PARAMETER ObjectType
        Specifies the type of the database object to set permission for.

    .PARAMETER Name
        Specifies the name of the database user, user-defined database role, or
        database application role that will have the permission.

    .PARAMETER Permission
        Specifies the permissions as an array of embedded instances of the
        DSC_DatabaseObjectPermission CIM class.

    .PARAMETER ServerName
        Specifies the host name of the SQL Server to be configured. Default value
        is the current computer name.

    .PARAMETER Force
        Specifies that permissions that has parameter Ensure set to 'Present'
        (the default value for permissions) should always be enforced even if that
        encompasses cascading revocations. An example if the desired state is
        'Grant' but the current state is 'GrantWithGrant'. If parameter Force is set
        to $true the With Grant permission is revoked, if set to $false an exception
        is thrown since the desired state could not be set. Default is to throw an
        exception.
#>
function Set-TargetResource
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('SqlServerDsc.AnalyzerRules\Measure-CommandsNeededToLoadSMO', '', Justification='The command Connect-Sql will be implicitly called in the call to Compare-TargetResourceState')]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DatabaseName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SchemaName,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [System.String]
        $ObjectName,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Schema', 'Table', 'View', 'StoredProcedure')]
        [System.String]
        $ObjectType,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $Permission,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = (Get-ComputerName),

        [Parameter()]
        [System.Boolean]
        $Force
    )

    $Permission = Assert-PermissionEnsureProperty -Permission $Permission

    <#
        Compare the current state against the desired state. Calling this will
        also import the necessary module to later call Get-ServerProtocolObject
        which uses the SMO class ManagedComputer.
    #>
    $propertyState = Compare-TargetResourceState @PSBoundParameters

    # Get all properties that are not in desired state.
    $propertiesNotInDesiredState = $propertyState | Where-Object -FilterScript { -not $_.InDesiredState }

    if ($propertiesNotInDesiredState.Count -gt 0)
    {
        Write-Verbose -Message (
            $script:localizedData.SetDesiredState -f ('{0}.{1}' -f $SchemaName, $ObjectName)
        )

        $getDatabaseObjectParameters = @{
            ServerName   = $ServerName
            InstanceName = $InstanceName
            DatabaseName = $DatabaseName
            SchemaName   = $SchemaName
            ObjectName   = $ObjectName
            ObjectType   = $ObjectType
        }

        $sqlObject = Get-DatabaseObject @getDatabaseObjectParameters

        if ($sqlObject)
        {
            $permissionProperty = $propertiesNotInDesiredState | Where-Object -FilterScript { $_.ParameterName -eq 'Permission' }

            # Check if Permission property need updating.
            if ($permissionProperty)
            {
                # Loop through each desired permission state.
                foreach ($desiredPermissionState in $Permission)
                {
                    # Get the equivalent permission state form the current state.
                    $currentPermissionState = $permissionProperty.Actual | Where-Object -FilterScript { $_.State -eq $desiredPermissionState.State }

                    if ($desiredPermissionState.Ensure -ne $currentPermissionState.Ensure)
                    {
                        try
                        {
                            $permissionSet = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ObjectPermissionSet'

                            # Prepare the desired permission set to assign to the object.
                            foreach ($permissionName in $desiredPermissionState.Permission)
                            {
                                $permissionSet."$permissionName" = $true
                            }

                            switch ($desiredPermissionState.Ensure)
                            {
                                'Present'
                                {
                                    Write-Verbose -Message (
                                        $script:localizedData.SetPermission -f @(
                                            ($desiredPermissionState.Permission -join ','),
                                            $Name
                                            $desiredPermissionState.State,
                                            ('{0}.{1}' -f $SchemaName, $ObjectName),
                                            $ObjectType,
                                            $DatabaseName
                                        )
                                    )

                                    switch ($desiredPermissionState.State)
                                    {
                                        'GrantWithGrant'
                                        {
                                            $sqlObject.Grant($permissionSet, $Name, $true)
                                        }

                                        'Grant'
                                        {
                                            <#
                                                If the permission was previously granted using With Grant then With Grant is
                                                revoked from all permissions since it is not the desired state.

                                                Even if we just revoke the With Grant and leaving the desired permission the
                                                permissions must always be granted regardless, this is because it is not known
                                                which permissions existed with With Grant or did not exist at all. It could be
                                                known if looping through the permissions and evaluating With Grant for each,
                                                but that would mean additional calls that did not seem necessary at the time
                                            #>
                                            if ($sqlObject.EnumObjectPermissions($Name, $permissionSet).PermissionState -contains 'GrantWithGrant')
                                            {
                                                if ($Force)
                                                {
                                                    Write-Verbose -Message (
                                                        $script:localizedData.RevokePermissionWithGrant -f @(
                                                            ($desiredPermissionState.Permission -join ','),
                                                            $Name
                                                            ('{0}.{1}' -f $SchemaName, $ObjectName),
                                                            $ObjectType,
                                                            $DatabaseName
                                                        )
                                                    )

                                                    # This must cascade the revoke.
                                                    $sqlObject.Revoke($permissionSet, $Name, $true, $true)
                                                }
                                                else
                                                {
                                                    $errorMessage = $script:localizedData.GrantCantBeSetBecauseRevokeIsNotOptedIn -f @(
                                                        ($desiredPermissionState.Permission -join ','),
                                                        $Name
                                                        ('{0}.{1}' -f $SchemaName, $ObjectName),
                                                        $ObjectType,
                                                        $DatabaseName
                                                    )

                                                    New-InvalidOperationException -Message $errorMessage
                                                }
                                            }

                                            $sqlObject.Grant($permissionSet, $Name)
                                        }

                                        'Deny'
                                        {
                                            $sqlObject.Deny($permissionSet, $Name)
                                        }
                                    }
                                }

                                'Absent'
                                {
                                    Write-Verbose -Message (
                                        $script:localizedData.RevokePermission -f @(
                                            ($desiredPermissionState.Permission -join ','),
                                            $Name
                                            $desiredPermissionState.State,
                                            ('{0}.{1}' -f $SchemaName, $ObjectName),
                                            $ObjectType,
                                            $DatabaseName
                                        )
                                    )

                                    if ($desiredPermissionState.State -eq 'GrantWithGrant')
                                    {
                                        $sqlObject.Revoke($permissionSet, $Name, $false, $true)
                                    }
                                    else
                                    {
                                        $sqlObject.Revoke($permissionSet, $Name)
                                    }
                                }
                            }
                        }
                        catch
                        {
                            $errorMessage = $script:localizedData.FailedToSetDatabaseObjectPermission -f @(
                                $Name,
                                ('{0}.{1}' -f $SchemaName, $ObjectName),
                                $DatabaseName
                            )

                            New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
                        }
                    }
                    else
                    {
                        Write-Verbose -Message (
                            $script:localizedData.PermissionStateInDesiredState -f @(
                                $desiredPermissionState.State,
                                ('{0}.{1}' -f $SchemaName, $ObjectName)
                            )
                        )
                    }
                }
            }
        }
        else
        {
            $errorMessage = $script:localizedData.FailedToGetDatabaseObject -f @(
                ('{0}.{1}' -f $SchemaName, $ObjectName),
                $ObjectType,
                $DatabaseName
            )

            New-InvalidOperationException -Message $errorMessage
        }
    }
    else
    {
        Write-Verbose -Message (
            $script:localizedData.DatabaseObjectIsInDesiredState -f $ObjectName, $ObjectType
        )
    }
}

<#
    .SYNOPSIS
        Determines if the permissions is set for the object in the database.

    .PARAMETER InstanceName
        Specifies the name of the SQL instance to be configured.

    .PARAMETER DatabaseName
        Specifies the name of the database where the object resides.

    .PARAMETER SchemaName
        Specifies the name of the schema for the database object.

    .PARAMETER ObjectName
        Specifies the name of the database object to set permission for.
        Can be an empty value when setting permission for a schema.

    .PARAMETER ObjectType
        Specifies the type of the database object to set permission for.

    .PARAMETER Name
        Specifies the name of the database user, user-defined database role, or
        database application role that will have the permission.

    .PARAMETER Permission
        Specifies the permissions as an array of embedded instances of the
        DSC_DatabaseObjectPermission CIM class.

    .PARAMETER ServerName
        Specifies the host name of the SQL Server to be configured. Default value
        is the current computer name.

    .PARAMETER Force
        Specifies that permissions that has parameter Ensure set to 'Present'
        (the default value for permissions) should always be enforced even if that
        encompasses cascading revocations. An example if the desired state is
        'Grant' but the current state is 'GrantWithGrant'. If parameter Force is set
        to $true the With Grant permission is revoked, if set to $false an exception
        is thrown since the desired state could not be set. Default is to throw an
        exception.
#>
function Test-TargetResource
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('SqlServerDsc.AnalyzerRules\Measure-CommandsNeededToLoadSMO', '', Justification='The command Connect-Sql will be implicitly called in the call to Compare-TargetResourceState')]
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DatabaseName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SchemaName,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [System.String]
        $ObjectName,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Schema', 'Table', 'View', 'StoredProcedure')]
        [System.String]
        $ObjectType,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $Permission,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = (Get-ComputerName),

        [Parameter()]
        [System.Boolean]
        $Force
    )

    $fullObjectName = '{0}.{1}' -f $SchemaName, $ObjectName

    Write-Verbose -Message (
        $script:localizedData.TestDesiredState -f @(
            $fullObjectName,
            $ObjectType,
            $DatabaseName,
            $InstanceName,
            $ServerName
        )
    )

    $propertyState = Compare-TargetResourceState @PSBoundParameters

    if ($false -in $propertyState.InDesiredState)
    {
        $testTargetResourceReturnValue = $false

        Write-Verbose -Message (
            $script:localizedData.NotInDesiredState -f $fullObjectName
        )
    }
    else
    {
        $testTargetResourceReturnValue = $true

        Write-Verbose -Message (
            $script:localizedData.InDesiredState -f $fullObjectName
        )
    }

    return $testTargetResourceReturnValue
}

<#
    .SYNOPSIS
        Determines if the permissions is set for the object in the database.

    .PARAMETER InstanceName
        Specifies the name of the SQL instance to be configured.

    .PARAMETER DatabaseName
        Specifies the name of the database where the object resides.

    .PARAMETER SchemaName
        Specifies the name of the schema for the database object.

    .PARAMETER ObjectName
        Specifies the name of the database object to set permission for.
        Can be an empty value when setting permission for a schema.

    .PARAMETER ObjectType
        Specifies the type of the database object to set permission for.

    .PARAMETER Name
        Specifies the name of the database user, user-defined database role, or
        database application role that will have the permission.

    .PARAMETER Permission
        Specifies the permissions as an array of embedded instances of the
        DSC_DatabaseObjectPermission CIM class.

    .PARAMETER ServerName
        Specifies the host name of the SQL Server to be configured. Default value
        is the current computer name.

    .PARAMETER Force
        Specifies that permissions that has parameter Ensure set to 'Present'
        (the default value for permissions) should always be enforced even if that
        encompasses cascading revocations. An example if the desired state is
        'Grant' but the current state is 'GrantWithGrant'. If parameter Force is set
        to $true the With Grant permission is revoked, if set to $false an exception
        is thrown since the desired state could not be set. Default is to throw an
        exception.
#>
function Compare-TargetResourceState
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DatabaseName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SchemaName,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [System.String]
        $ObjectName,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Schema', 'Table', 'View', 'StoredProcedure')]
        [System.String]
        $ObjectType,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $Permission,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = (Get-ComputerName),

        [Parameter()]
        [System.Boolean]
        $Force
    )

    $Permission = Assert-PermissionEnsureProperty -Permission $Permission

    $getTargetResourceParameters = @{
        InstanceName = $InstanceName
        DatabaseName = $DatabaseName
        SchemaName   = $SchemaName
        ObjectName   = $ObjectName
        ObjectType   = $ObjectType
        Name         = $Name
        Permission   = $Permission
        ServerName   = $ServerName
        Force        = $Force
    }

    <#
        We remove any parameters not passed by $PSBoundParameters so that
        Get-TargetResource can also evaluate $PSBoundParameters correctly.

        Need the @() around the Keys property to get a new array to enumerate.
    #>
    @($getTargetResourceParameters.Keys) | ForEach-Object -Process {
        if (-not $PSBoundParameters.ContainsKey($_))
        {
            $getTargetResourceParameters.Remove($_)
        }
    }

    $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

    $compareTargetResourceStateParameters = @{
        CurrentValues            = $getTargetResourceResult
        DesiredValues            = $PSBoundParameters
        Properties               = @(
            'Permission'
        )
        <#
            This is the property that makes each DSC_DatabaseObjectPermission
            CIM instance unique in the collection. It will be used to filter out
            the values to compare against in the current state.
        #>
        CimInstanceKeyProperties = @{
            Permission = @('Permission', 'State')
        }
    }

    return Compare-ResourcePropertyState @compareTargetResourceStateParameters
}

<#
    .SYNOPSIS
        Returns the object class for the specified name och object type.

    .PARAMETER ServerName
        Specifies the host name of the SQL Server to be configured.

    .PARAMETER InstanceName
        Specifies the name of the SQL instance to be configured.

    .PARAMETER DatabaseName
        Specifies the name of the database where the object resides.

    .PARAMETER SchemaName
        Specifies the name of the schema for the database object.

    .PARAMETER ObjectName
        Specifies the name of the database object to set per mission for.
        Can be an empty value when setting permission for a schema.

    .PARAMETER ObjectType
        Specifies the type of the database object to set permission for.
#>
function Get-DatabaseObject
{
    [CmdletBinding()]
    [OutputType([PSObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ServerName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DatabaseName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SchemaName,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [System.String]
        $ObjectName,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Schema', 'Table', 'View', 'StoredProcedure')]
        [System.String]
        $ObjectType
    )

    $sqlObject = $null

    $sqlServerObject = Connect-SQL -ServerName $ServerName -InstanceName $InstanceName -ErrorAction 'Stop'

    if ($sqlServerObject)
    {
        $sqlDatabaseObject = $sqlServerObject.Databases[$DatabaseName]

        if ($sqlDatabaseObject)
        {
            $sqlObject = switch ($ObjectType)
            {
                'Schema'
                {
                    $sqlDatabaseObject.Schemas.Item($SchemaName)
                }

                'Table'
                {
                    $sqlDatabaseObject.Tables.Item($ObjectName, $SchemaName)
                }

                'StoredProcedure'
                {
                    $sqlDatabaseObject.StoredProcedures.Item($ObjectName, $SchemaName)
                }

                'View'
                {
                    $sqlDatabaseObject.Views.Item($ObjectName, $SchemaName)
                }
            }
        }
    }

    return $sqlObject
}

<#
    .SYNOPSIS
        Converts permission names to DSC_DatabaseObjectPermission CIM class.

    .PARAMETER Permission
        This represents a SQL Server database object permission.

    .PARAMETER PermissionState
        This is the state of permission set. Valid values are 'Grant', 'Deny', or 'GrantWithGrant'.

    .PARAMETER Ensure
        Ensure if the permission should be granted (Present) or revoked (Absent).
        Default value is 'Present'.
#>
function ConvertTo-CimDatabaseObjectPermission
{
    [CmdletBinding()]
    [OutputType([Microsoft.Management.Infrastructure.CimInstance])]
    param
    (
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [AllowNull()]
        [System.String]
        $Permission,

        [Parameter(Mandatory = $true)]
        [System.String]
        $PermissionState,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure
    )

    if (-not $PSBoundParameters.ContainsKey('Ensure'))
    {
        $Ensure = 'Present'
    }

    $cimClassName = 'DSC_DatabaseObjectPermission'
    $cimNamespace = 'root/microsoft/Windows/DesiredStateConfiguration'

    $cimProperties = @{
        State      = $PermissionState
        Permission = $Permission
        Ensure     = $Ensure
    }

    return New-CimInstance -ClassName $cimClassName `
        -Namespace $cimNamespace `
        -Property $cimProperties `
        -ClientOnly
}

<#
    .SYNOPSIS
        Asserts that if Ensure property is not set, then the Ensure property is
        set to 'Present' (which is the default).

    .PARAMETER Permission
        Specifies array of permission CIM instances.
#>
function Assert-PermissionEnsureProperty
{
    [CmdletBinding()]
    [OutputType([Microsoft.Management.Infrastructure.CimInstance[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $Permission
    )

    foreach ($desiredPermission in $Permission)
    {
        if (-not $desiredPermission.Ensure)
        {
            $desiredPermission.Ensure = 'Present'
        }
    }

    return $Permission
}
