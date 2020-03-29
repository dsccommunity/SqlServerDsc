$script:resourceModulePath = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
$script:modulesFolderPath = Join-Path -Path $script:resourceModulePath -ChildPath 'Modules'

$script:resourceHelperModulePath = Join-Path -Path $script:modulesFolderPath -ChildPath 'SqlServerDsc.Common'
Import-Module -Name (Join-Path -Path $script:resourceHelperModulePath -ChildPath 'SqlServerDsc.Common.psm1')

$script:localizedData = Get-LocalizedData -ResourceName 'MSFT_SqlDatabaseUserRole'

<# MSFT_SqlDatabaseUserRole

This resource was initially copied from MSFT_SqlDatabaseRole and modified to add/remove roles for users rather than members of roles.
In addition, resolutions for the following issues have been included in this code: #1487, #1484

#>

<#
    .SYNOPSIS
        Returns the current state of the user regarding database role membership.

    .PARAMETER ServerName
        Specifies the host name of the SQL Server to be configured.

    .PARAMETER InstanceName
        Specifies the name of the SQL instance to be configured.
        Can be NULL, an empty string or 'MSSQLSERVER' for an unnamed instance.

    .PARAMETER DatabaseName
        Specifies the name of the database in which the user roles are to be configured.

    .PARAMETER UserName
        Specifies the name of the database user to be configured.

    .PARAMETER RoleNamesToEnforce
        Specifies the names of the database roles the user should have.
        Roles that the user currently does not have will be added.
        Existing user roles not included in this parameter will be removed.

    .PARAMETER RoleNamesToInclude
        Specifies the names of the database roles that should be added if not already present.
        Existing user roles not included in this parameter will be unchanged unless specified in RoleNamesToExclude.

    .PARAMETER RoleNamesToExclude
        Specifies the names of the database roles that should be removed if they exist.

#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName,

        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [AllowEmptyString()]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $DatabaseName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $UserName,

        [Parameter(ParameterSetName = 'A', Mandatory = $true)]
        [System.String[]]
        $RoleNamesToEnforce,

        [Parameter(ParameterSetName = 'B')]
        [System.String[]]
        $RoleNamesToInclude,

        [Parameter(ParameterSetName = 'B')]
        [System.String[]]
        $RoleNamesToExclude

    )

    Write-Verbose -Message (
        $script:localizedData.GetDatabaseUserRoleMembership -f $UserName
    )

    if ([String]::IsNullOrEmpty($InstanceName)) {
       $sqlServerObject = Connect-SQL -ServerName $ServerName
    }
    else {
       $sqlServerObject = Connect-SQL -ServerName $ServerName -InstanceName $InstanceName
    }

    $isPrimaryReplica = $NULL
    if ($sqlServerObject)
    {
        # Check if database exists.
        if (-not ($sqlDatabaseObject = $sqlServerObject.Databases[$DatabaseName]))
        {
            $sqlServerObject.ConnectionContext.Disconnect()
            $sqlServerObject = $NULL
            $errorMessage = $script:localizedData.DatabaseNotFound -f $DatabaseName
            New-ObjectNotFoundException -Message $errorMessage
        }
        else {
            if ($sqlServerObject -and $sqlServerObject.IsHadrEnabled) {
                $sqlAvailGroup = $sqlServerObject.AvailabilityGroups | Where-Object { $_.AvailabilityDatabases.Name -contains $DatabaseName }
                $isPrimaryReplica = $true
                if ($sqlAvailGroup.PrimaryReplicaServerName -ne $sqlServerObject.DomainInstanceName) {
                   $isPrimaryReplica = $false
                # not primary replica - connect to listener - $sqlDatabaseObject.Roles is empty if not primary replica
                   $sqlAvailListener = $sqlAvailGroup.AvailabilityGroupListeners[0]
                   $listenerServerName = "$($sqlAvailListener.AvailabilityGroupListenerIPAddresses[0].IPAddress),$($sqlAvailListener.PortNumber)"
                   $sqlServerObject.ConnectionContext.Disconnect()
                   $sqlServerObject = Connect-SQL -ServerName $listenerServerName
                }
            }
        }
    }

    if ($sqlServerObject)
    {

        $sqlDatabaseObject = $sqlServerObject.Databases[$DatabaseName]
        Write-Verbose -Message (
            $script:localizedData.GetDatabaseUserRoleNames -f $UserName
        )
        [System.String[]] $dbUserRoleNames = $sqlDatabaseObject.Roles | Where-Object { $_.EnumMembers() -contains $UserName }
        Write-Verbose -Message (
            $script:localizedData.GetDatabaseUserRoleNamesCount -f $UserName, $dbUserRoles.Count
        )

        $sqlServerObject.ConnectionContext.Disconnect()

    }
    else {
        [System.String[]] $dbUserRoleNames = $NULL
    }

    $returnValue = @{
        ServerName         = $ServerName
        InstanceName       = $InstanceName
        DatabaseName       = $DatabaseName
        UserName           = $UserName
        RoleNamesToEnforce = $RoleNamesToEnforce
        RoleNamesToInclude = $RoleNamesToInclude
        RoleNamesToExclude = $RoleNamesToExclude
        RoleName           = $dbUserRoleNames
        IsPrimaryReplica   = $isPrimaryReplica
        OnAllReplicas      = $OnAllReplicas
    }

    Write-Output -InputObject $returnValue
}

<#
    .SYNOPSIS
        Adds or removes database roles from the database user.

    .PARAMETER ServerName
        Specifies the host name of the SQL Server to be configured.

    .PARAMETER InstanceName
        Specifies the name of the SQL instance to be configured.
        Can be NULL, an empty string or 'MSSQLSERVER' for an unnamed instance.

    .PARAMETER DatabaseName
        Specifies the name of the database in which the user roles are to be configured.

    .PARAMETER UserName
        Specifies the name of the database user to be configured.

    .PARAMETER RoleNamesToEnforce
        Specifies the names of the database roles the user should have.
        Roles that the user currently does not have will be added.
        Existing user roles not included in this parameter will be removed.

    .PARAMETER RoleNamesToInclude
        Specifies the names of the database roles that should be added if not already present.
        Existing user roles not included in this parameter will be unchanged unless specified in RoleNamesToExclude.

    .PARAMETER RoleNamesToExclude
        Specifies the names of the database roles that should be removed if they exist.

#>

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName,

        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [AllowEmptyString()]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $DatabaseName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $UserName,

        [Parameter(ParameterSetName = 'A', Mandatory = $true)]
        [System.String[]]
        $RoleNamesToEnforce,

        [Parameter(ParameterSetName = 'B')]
        [System.String[]]
        $RoleNamesToInclude,

        [Parameter(ParameterSetName = 'B')]
        [System.String[]]
        $RoleNamesToExclude,

        [Parameter()]
        [System.Boolean]
        $OnAllReplicas

    )

    Write-Verbose -Message (
        $script:localizedData.SetDatabaseUserRoleMembership -f $UserName
    )

    if ([String]::IsNullOrEmpty($InstanceName)) {
       $sqlServerObject = Connect-SQL -ServerName $ServerName
    }
    else {
       $sqlServerObject = Connect-SQL -ServerName $ServerName -InstanceName $InstanceName
    }

    if ($sqlServerObject)
    {
        # Check if database exists.
        if (-not ($sqlDatabaseObject = $sqlServerObject.Databases[$DatabaseName]))
        {
            $sqlServerObject.ConnectionContext.Disconnect()
            $sqlServerObject = $NULL
            $errorMessage = $script:localizedData.DatabaseNotFound -f $DatabaseName
            New-ObjectNotFoundException -Message $errorMessage
        }
        else {
            if ($sqlServerObject -and $sqlServerObject.IsHadrEnabled) {
                $sqlAvailGroup = $sqlServerObject.AvailabilityGroups | Where-Object { $_.AvailabilityDatabases.Name -contains $DatabaseName }
                if ($sqlAvailGroup.PrimaryReplicaServerName -ne $sqlServerObject.DomainInstanceName) {
                   if ($OnAllReplicas) {
                   # not primary replica - connect to listener - $sqlDatabaseObject.Roles is empty if not primary replica
                      $sqlAvailListener = $sqlAvailGroup.AvailabilityGroupListeners[0]
                      $listenerServerName = "$($sqlAvailListener.AvailabilityGroupListenerIPAddresses[0].IPAddress),$($sqlAvailListener.PortNumber)"
                      $sqlServerObject.ConnectionContext.Disconnect()
                      $sqlServerObject = Connect-SQL -ServerName $listenerServerName
                   }
                   else {
                      $sqlServerObject.ConnectionContext.Disconnect()
                      $sqlServerObject = $NULL
                   }
                }
            }
        }
    }

    if ($sqlServerObject)
    {

        $sqlDatabaseObject = $sqlServerObject.Databases[$DatabaseName]
        [Microsoft.SqlServer.Management.Smo.DatabaseRole[]] $dbUserRoles = $sqlDatabaseObject.Roles | Where-Object { $_.EnumMembers() -contains $UserName }

        if ($RoleNamesToEnforce)
        {

            if ($RoleNamesToInclude -or $RoleNamesToExclude)
            {
                $errorMessage = $script:localizedData.RoleNamesToIncludeAndExcludeParamMustBeNull
                New-InvalidOperationException -Message $errorMessage
            }

            foreach ($roleName in $RoleNamesToEnforce)
            {
                if ($dbUserRoles.Names -contains $roleName)
                {
                    $addMemberParams = @{
                        SqlDatabaseObject = $sqlDatabaseObject
                        RoleName          = $roleName
                        MemberName        = $UserName
                    }
                    Add-SqlDscDatabaseRoleMember @addMemberParams
                }
                else {
                    $removeMemberParams = @{
                        SqlDatabaseObject = $sqlDatabaseObject
                        RoleName          = $roleName
                        MemberName        = $UserName
                    }
                    Remove-SqlDscDatabaseRoleMember @removeMemberParams
                }
            }

        }
        else
        {

            if ($RoleNamesToInclude)
            {
                foreach ($roleName in $RoleNamesToInclude)
                {
                    if (-not ($dbUserRoles.Name -contains $roleName))
                    {
                        Write-Verbose -Message (
                            $script:localizedData.RoleNotPresent -f $UserName, $roleName, $DatabaseName
                        )
                        $addMemberParams = @{
                            SqlDatabaseObject = $sqlDatabaseObject
                            RoleName          = $roleName
                            MemberName        = $UserName
                        }
                        Add-SqlDscDatabaseRoleMember @addMemberParams
                    }
                }
            }

            if ($RoleNamesToExclude)
            {
                foreach ($roleName in $RoleNamesToExclude)
                {
                    if ($dbUserRoles.Name -contains $roleName)
                    {
                        Write-Verbose -Message (
                            $script:localizedData.RolePresent -f $UserName, $roleName, $DatabaseName
                        )
                        $removeMemberParams = @{
                            SqlDatabaseObject = $sqlDatabaseObject
                            RoleName          = $roleName
                            MemberName        = $UserName
                        }
                        Remove-SqlDscDatabaseRoleMember @removeMemberParams
                    }
                }
            }

        }

        $sqlServerObject.ConnectionContext.Disconnect()

    }
}

<#
    .SYNOPSIS
        Tests the current state of the database role along with its membership.

    .PARAMETER ServerName
        Specifies the host name of the SQL Server to be configured.

    .PARAMETER InstanceName
        Specifies the name of the SQL instance to be configured.
        Can be NULL, an empty string or 'MSSQLSERVER' for an unnamed instance.

    .PARAMETER DatabaseName
        Specifies the name of the database in which the user roles are to be configured.

    .PARAMETER UserName
        Specifies the name of the database user to be configured.

    .PARAMETER RoleNamesToEnforce
        Specifies the names of the database roles the user should have.
        Roles that the user currently does not have will be added.
        Existing user roles not included in this parameter will be removed.

    .PARAMETER RoleNamesToInclude
        Specifies the names of the database roles that should be added if not already present.
        Existing user roles not included in this parameter will be unchanged unless specified in RoleNamesToExclude.

    .PARAMETER RoleNamesToExclude
        Specifies the names of the database roles that should be removed if they exist.

#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName,

        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [AllowEmptyString()]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $DatabaseName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $UserName,

        [Parameter(ParameterSetName = 'A')]
        [System.String[]]
        $RoleNamesToEnforce,

        [Parameter(ParameterSetName = 'B')]
        [System.String[]]
        $RoleNamesToInclude,

        [Parameter(ParameterSetName = 'B')]
        [System.String[]]
        $RoleNamesToExclude,

        [Parameter()]
        [System.Boolean]
        $OnAllReplicas

    )

    Write-Verbose -Message (
        $script:localizedData.TestDatabaseUserRoleMembership -f $UserName
    )

    if ([String]::IsNullOrEmpty($InstanceName)) {
       $sqlServerObject = Connect-SQL -ServerName $ServerName
    }
    else {
       $sqlServerObject = Connect-SQL -ServerName $ServerName -InstanceName $InstanceName
    }

    if ($sqlServerObject)
    {
        # Check if database exists.
        if (-not ($sqlDatabaseObject = $sqlServerObject.Databases[$DatabaseName]))
        {
            $sqlServerObject.ConnectionContext.Disconnect()
            $sqlServerObject = $NULL
            $errorMessage = $script:localizedData.DatabaseNotFound -f $DatabaseName
            New-ObjectNotFoundException -Message $errorMessage
        }
        else {
            if ($sqlServerObject -and $sqlServerObject.IsHadrEnabled) {
                $sqlAvailGroup = $sqlServerObject.AvailabilityGroups | Where-Object { $_.AvailabilityDatabases.Name -contains $DatabaseName }
                if ($sqlAvailGroup.PrimaryReplicaServerName -ne $sqlServerObject.DomainInstanceName) {
                # not primary replica - connect to listener - $sqlDatabaseObject.Roles is empty if not primary replica
                   $sqlAvailListener = $sqlAvailGroup.AvailabilityGroupListeners[0]
                   $listenerServerName = "$($sqlAvailListener.AvailabilityGroupListenerIPAddresses[0].IPAddress),$($sqlAvailListener.PortNumber)"
                   $sqlServerObject.ConnectionContext.Disconnect()
                   $sqlServerObject = Connect-SQL -ServerName $listenerServerName
                }
            }
        }
    }

    if ($sqlServerObject)
    {

        $sqlDatabaseObject = $sqlServerObject.Databases[$DatabaseName]
        [Microsoft.SqlServer.Management.Smo.DatabaseRole[]] $dbUserRoles = $sqlDatabaseObject.Roles | Where-Object { $_.EnumMembers() -contains $UserName }

        if ($RoleNamesToEnforce)
        {

            if ($RoleNamesToInclude -or $RoleNamesToExclude)
            {
                $errorMessage = $script:localizedData.RoleNamesToIncludeAndExcludeParamMustBeNull
                New-InvalidOperationException -Message $errorMessage
            }

            if ($null -ne (Compare-Object -ReferenceObject $dbUserRoles.Name -DifferenceObject $RoleNamesToEnforce))
            {
                Write-Verbose -Message (
                    $script:localizedData.RolesDoNotMatchListToBeEnforced -f $UserName, $DatabaseName
                )
                $inDesiredState = $false
            }
            else {
                $inDesiredState = $true
            }

        }
        else
        {

            $inDesiredState = $true

            if ($RoleNamesToInclude)
            {
                foreach ($roleName in $RoleNamesToInclude)
                {
                    if (-not ($dbUserRoles.Name -contains $roleName))
                    {
                        Write-Verbose -Message (
                            $script:localizedData.RoleNotPresent -f $UserName, $roleName, $DatabaseName
                        )
                        $inDesiredState = $false
                    }
                }
            }

            if ($RoleNamesToExclude)
            {
                foreach ($roleName in $RoleNamesToExclude)
                {
                    if ($dbUserRoles.Name -contains $roleName)
                    {
                        Write-Verbose -Message (
                            $script:localizedData.RolePresent -f $UserName, $roleName, $DatabaseName
                        )
                        $inDesiredState = $false
                    }
                }
            }

        }

        $sqlServerObject.ConnectionContext.Disconnect()

    }
    else {
       $inDesiredState = $false
    }

    Write-Output -InputObject $inDesiredState
}

<#
    .SYNOPSIS
        Adds a member to a database role in the SQL Server instance provided.

    .PARAMETER SqlDatabaseObject
        A database object.

    .PARAMETER RoleName
        String containing the name of the database role to add the member to.

    .PARAMETER MemberName
        String containing the name of the user or group which should be added to the database role.

#>
function Add-SqlDscDatabaseRoleMember
{
    [CmdletBinding()]
    param
    (

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        $SqlDatabaseObject,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $RoleName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $MemberName

    )

    $databaseName = $SqlDatabaseObject.Name

    if (-not ($SqlDatabaseObject.Roles[$RoleName] -or $SqlDatabaseObject.Users[$MemberName]))
    {
        $errorMessage = $script:localizedData.DatabaseRoleOrUserNotFound -f $MemberName, $RoleName, $databaseName
        New-ObjectNotFoundException -Message $errorMessage
    }

    try
    {
        Write-Verbose -Message (
            $script:localizedData.AddDatabaseRoleMember -f $MemberName, $RoleName, $databaseName
        )
        $SqlDatabaseObject.Roles[$RoleName].AddMember($MemberName)
    }
    catch
    {
        $errorMessage = $script:localizedData.AddDatabaseRoleMemberError -f $MemberName, $RoleName, $databaseName
        New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
    }

}

<#
    .SYNOPSIS
        Removes a member from a database role in the SQL Server instance provided.

    .PARAMETER SqlDatabaseObject
        A database object.

    .PARAMETER RoleName
        String containing the name of the database role to remove the member from.

    .PARAMETER MemberName
        String containing the name of the user or group which should be removed from the database role.

#>
function Remove-SqlDscDatabaseRoleMember
{
    [CmdletBinding()]
    param
    (

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        $SqlDatabaseObject,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $RoleName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $MemberName

    )

    $databaseName = $SqlDatabaseObject.Name

    try
    {
        Write-Verbose -Message (
            $script:localizedData.DropDatabaseRoleMember -f $MemberName, $RoleName, $databaseName
        )
        $SqlDatabaseObject.Roles[$RoleName].DropMember($MemberName)
    }
    catch
    {
        $errorMessage = $script:localizedData.DropDatabaseRoleMemberError -f $MemberName, $RoleName, $databaseName
        New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
    }

}

Export-ModuleMember -Function *-TargetResource
