Import-Module -Name (Join-Path -Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) `
                               -ChildPath 'xSQLServerHelper.psm1') `
                               -Force
<#
    .SYNOPSIS
        Returns the current state of the permissions for the principal (login).

    .PARAMETER InstanceName
        The name of the SQL instance to be configured.

    .PARAMETER NodeName
        The host name of the SQL Server to be configured.

    .PARAMETER Principal
        The login to which permission will be set.

    .PARAMETER Permission
        The permission to set for the login. Valid values are AlterAnyAvailabilityGroup, ViewServerState or AlterAnyEndPoint.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter()]
        [System.String]
        $NodeName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Principal,

        [Parameter()]
        [ValidateSet('AlterAnyAvailabilityGroup','ViewServerState','AlterAnyEndPoint')]
        [System.String[]]
        $Permission
    )

    New-VerboseMessage -Message "Enumerating permissions for $Principal"

    try
    {
        $instance = Get-SQLPSInstance -NodeName $NodeName -InstanceName $InstanceName

        $permissionSet = Get-SQLServerPermissionSet -Permission $Permission

        $enumeratedPermission = $instance.EnumServerPermissions( $Principal, $permissionSet ) |
                                    Where-Object { $_.PermissionState -eq 'Grant' }

        if ($null -ne $enumeratedPermission)
        {
            $grantedPermissionSet = Get-SQLServerPermissionSet -PermissionSet $enumeratedPermission.PermissionType

            if (-not (Compare-Object -ReferenceObject $permissionSet -DifferenceObject $grantedPermissionSet -Property $Permission))
            {
                $ensure = 'Present'
            }
            else
            {
                $ensure = 'Absent'
            }

            $grantedPermission = Get-SQLPermission -ServerPermissionSet $grantedPermissionSet
        }
        else
        {
            $ensure = 'Absent'
            $grantedPermission = ''
        }
    }
    catch
    {
        throw New-TerminatingError -ErrorType PermissionGetError -FormatArgs @($Principal) -ErrorCategory InvalidOperation -InnerException $_.Exception
    }

    return @{
        InstanceName = [System.String] $InstanceName
        NodeName = [System.String] $NodeName
        Ensure = [System.String] $ensure
        Principal = [System.String] $Principal
        Permission = [System.String[]] $grantedPermission
    }
}

<#
    .SYNOPSIS
        Grants or revokes the permission for the the principal (login).

    .PARAMETER InstanceName
        The name of the SQL instance to be configured.

    .PARAMETER NodeName
        The host name of the SQL Server to be configured.

    .PARAMETER Ensure
        If the permission should be present or absent. Default value is 'Present'.

    .PARAMETER Principal
        The login to which permission will be set.

    .PARAMETER Permission
        The permission to set for the login. Valid values are AlterAnyAvailabilityGroup, ViewServerState or AlterAnyEndPoint.
#>
function Set-TargetResource
{
    [CmdletBinding(SupportsShouldProcess)]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter()]
        [System.String]
        $NodeName = $env:COMPUTERNAME,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [System.String]
        $Principal,

        [Parameter()]
        [ValidateSet('AlterAnyAvailabilityGroup','ViewServerState','AlterAnyEndPoint')]
        [System.String[]]
        $Permission
    )

    $parameters = @{
        InstanceName = [System.String] $InstanceName
        NodeName = [System.String] $NodeName
        Principal = [System.String] $Principal
        Permission = [System.String[]] $Permission
    }

    $permissionState = Get-TargetResource @parameters
    if ($null -ne $permissionState)
    {
        if ($Ensure -ne '')
        {
            if ($permissionState.Ensure -ne $Ensure)
            {
                $instance = Get-SQLPSInstance -NodeName $NodeName -InstanceName $InstanceName
                if ($null -ne $instance)
                {
                    $permissionSet = Get-SQLServerPermissionSet -Permission $Permission

                    if ($Ensure -eq 'Present')
                    {
                        Write-Verbose -Message ('Grant permission for ''{0}''' -f $Principal)

                        $instance.Grant($permissionSet, $Principal )
                    }
                    else
                    {
                        Write-Verbose -Message ('Revoke permission for ''{0}''' -f $Principal)

                        $instance.Revoke($permissionSet, $Principal )
                    }
                }
                else
                {
                    throw New-TerminatingError -ErrorType PrincipalNotFound -FormatArgs @($Principal) -ErrorCategory ObjectNotFound
                }
            }
            else
            {
                New-VerboseMessage -Message "State is already $Ensure"
            }
        }
        else
        {
            throw New-TerminatingError -ErrorType PermissionMissingEnsure -FormatArgs @($Principal) -ErrorCategory InvalidOperation
        }
    }
    else
    {
        throw New-TerminatingError -ErrorType UnexpectedErrorFromGet -ErrorCategory InvalidResult
    }
}

<#
    .SYNOPSIS
        Tests if the principal (login) has the desired permissions.

    .PARAMETER InstanceName
        The name of the SQL instance to be configured.

    .PARAMETER NodeName
        The host name of the SQL Server to be configured.

    .PARAMETER Ensure
        If the permission should be present or absent. Default value is 'Present'.

    .PARAMETER Principal
        The login to which permission will be set.

    .PARAMETER Permission
        The permission to set for the login. Valid values are AlterAnyAvailabilityGroup, ViewServerState or AlterAnyEndPoint.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter()]
        [System.String]
        $NodeName = $env:COMPUTERNAME,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [System.String]
        $Principal,

        [Parameter()]
        [ValidateSet('AlterAnyAvailabilityGroup','ViewServerState','AlterAnyEndPoint')]
        [System.String[]]
        $Permission
    )

    $parameters = @{
        InstanceName = $InstanceName
        NodeName = $NodeName
        Principal = $Principal
        Permission = $Permission
    }

    New-VerboseMessage -Message "Testing state of permissions for $Principal"

    $permissionState = Get-TargetResource @parameters
    if ($null -ne $permissionState)
    {
        $result = $false

        if( $permissionState.Ensure -eq $Ensure)
        {
            $result = $true
        }
    }
    else
    {
        throw New-TerminatingError -ErrorType UnexpectedErrorFromGet -ErrorCategory InvalidResult
    }

    return $result
}

<#
    .SYNOPSIS
       Takes a Microsoft.SqlServer.Management.Smo.ServerPermissionSet object which will be
       enumerated and returned as a string array.

    .PARAMETER ServerPermissionSet
        A PermissionSet object which should be enumerated.
#>
function Get-SQLPermission
{
    [CmdletBinding()]
    [OutputType([System.String[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [Microsoft.SqlServer.Management.Smo.ServerPermissionSet]
        [ValidateNotNullOrEmpty()]
        $ServerPermissionSet
    )

    [System.String[]] $permissionArray = @()

    foreach ($property in $($ServerPermissionSet | Get-Member -Type Property))
    {
        if ($ServerPermissionSet.$($property.Name))
        {
            $permissionArray += $property.Name
        }
    }

    return $permissionArray
}

<#
    .SYNOPSIS
       Takes either an array of strings or an array of Microsoft.SqlServer.Management.Smo.ServerPermissionSet objects which
       will be enumerated and concatenated to a single Microsoft.SqlServer.Management.Smo.ServerPermissionSet object.

    .PARAMETER Permission
        An array of strings which should be concatenated to a single Microsoft.SqlServer.Management.Smo.ServerPermissionSet object.

    .PARAMETER ServerPermissionSet
        An array of Microsoft.SqlServer.Management.Smo.ServerPermissionSet objects which should be concatenated to a single
        Microsoft.SqlServer.Management.Smo.ServerPermissionSet object.
#>
function Get-SQLServerPermissionSet
{
    [CmdletBinding()]
    [OutputType([Object])]
    param
    (
        [Parameter(Mandatory = $true,ParameterSetName='Permission')]
        [System.String[]]
        [ValidateNotNullOrEmpty()]
        $Permission,

        [Parameter(Mandatory = $true,ParameterSetName='ServerPermissionSet')]
        [Microsoft.SqlServer.Management.Smo.ServerPermissionSet[]]
        [ValidateNotNullOrEmpty()]
        $PermissionSet
    )

    if ($Permission)
    {
        [Microsoft.SqlServer.Management.Smo.ServerPermissionSet] $concatenatedPermissionSet = New-Object -TypeName Microsoft.SqlServer.Management.Smo.ServerPermissionSet

        foreach ($currentPermission in $Permission)
        {
            $concatenatedPermissionSet.$($currentPermission) = $true
        }
    }
    else
    {
        $concatenatedPermissionSet = Merge-SQLPermissionSet -Object $PermissionSet
    }

    return $concatenatedPermissionSet
}

<#
    .SYNOPSIS
       Merges an array of any PermissionSet objects into a single PermissionSet.

       The though with this helper function si it can be used for any permission set object
       because all inheriths from Microsoft.SqlServer.Management.Smo.PermissionSetBase.

    .PARAMETER Object
        An array of strings which should be concatenated to a single PermissionSet object.
#>
function Merge-SQLPermissionSet
{
    param
    (
        [Parameter(Mandatory = $true)]
        [Object[]]
        [ValidateNotNullOrEmpty()]
        $Object
    )

    $baseObject = New-Object -TypeName ($Object[0].GetType())

    foreach ($currentObject in $Object)
    {
        foreach ($Property in $($currentObject | Get-Member -Type Property))
        {
            if ($currentObject.$($Property.Name))
            {
                $baseObject.$($Property.Name) = $currentObject.$($Property.Name)
            }
        }
    }

    return $baseObject
}

Export-ModuleMember -Function *-TargetResource
