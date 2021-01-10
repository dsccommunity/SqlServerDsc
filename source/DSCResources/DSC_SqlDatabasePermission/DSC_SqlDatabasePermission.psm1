$script:sqlServerDscHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\SqlServerDsc.Common'
$script:resourceHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DscResource.Common'

Import-Module -Name $script:sqlServerDscHelperModulePath
Import-Module -Name $script:resourceHelperModulePath

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

<#
    .SYNOPSIS
        Returns the current permissions for the user in the database.

    .PARAMETER DatabaseName
        This is the SQL database

    .PARAMETER Name
        This is the name of the SQL login for the permission set.

    .PARAMETER PermissionState
        This is the state of permission set. Valid values are 'Grant' or 'Deny'.

    .PARAMETER Permissions
        This is a list that represents a SQL Server set of database permissions.

    .PARAMETER ServerName
        This is the SQL Server for the database. Default value is the current
        computer name.

    .PARAMETER InstanceName
        This is the SQL instance for the database.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $DatabaseName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Grant', 'Deny', 'GrantWithGrant')]
        [System.String]
        $PermissionState,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $Permissions,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = (Get-ComputerName),


        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName
    )

    Write-Verbose -Message (
        $script:localizedData.GetDatabasePermission -f $Name, $DatabaseName, $InstanceName
    )

    $returnValue = @{
        Ensure          = 'Absent'
        ServerName      = $ServerName
        InstanceName    = $InstanceName
        DatabaseName    = $DatabaseName
        Name            = $Name
        PermissionState = $PermissionState
        Permissions     = @()
    }

    $sqlServerObject = Connect-SQL -ServerName $ServerName -InstanceName $InstanceName

    if ($sqlServerObject)
    {
        if ($sqlDatabaseObject = $sqlServerObject.Databases[$DatabaseName])
        {
            $databasePermissionInfo = $sqlDatabaseObject.EnumDatabasePermissions($Name) |
                Where-Object -FilterScript {
                    $_.PermissionState -eq $PermissionState
                }

            if ($databasePermissionInfo)
            {
                # Initialize variable permission
                [System.String[]] $getSqlDatabasePermissionResult = @()

                foreach ($currentDatabasePermissionInfo in $databasePermissionInfo)
                {
                    $permissionProperty = ($currentDatabasePermissionInfo.PermissionType |
                            Get-Member -MemberType Property).Name

                    foreach ($currentPermissionProperty in $permissionProperty)
                    {
                        if ($currentDatabasePermissionInfo.PermissionType."$currentPermissionProperty")
                        {
                            $getSqlDatabasePermissionResult += $currentPermissionProperty
                        }
                    }

                    # Remove any duplicate permissions.
                    $getSqlDatabasePermissionResult = @(
                        $getSqlDatabasePermissionResult |
                            Sort-Object -Unique
                    )
                }

                if ($getSqlDatabasePermissionResult)
                {
                    $returnValue['Permissions'] = $getSqlDatabasePermissionResult

                    $compareObjectParameters = @{
                        ReferenceObject  = $Permissions
                        DifferenceObject = $getSqlDatabasePermissionResult
                    }

                    $resultOfPermissionCompare = Compare-Object @compareObjectParameters |
                        Where-Object -FilterScript {
                            $_.SideIndicator -eq '<='
                        }

                    # If there are no missing permission then return 'Ensure' state as 'Present'.
                    if ($null -eq $resultOfPermissionCompare)
                    {
                        $returnValue['Ensure'] = 'Present'
                    }
                }
            }
        }
    }

    return $returnValue
}

<#
    .SYNOPSIS
        Sets the permissions for the user in the database.

    .PARAMETER Ensure
        This is The Ensure if the permission should be granted (Present) or
        revoked (Absent).

    .PARAMETER DatabaseName
        This is the SQL database

    .PARAMETER Name
        This is the name of the SQL login for the permission set.

    .PARAMETER PermissionState
        This is the state of permission set. Valid values are 'Grant' or 'Deny'.

    .PARAMETER Permissions
        This is a list that represents a SQL Server set of database permissions.

    .PARAMETER ServerName
        This is the SQL Server for the database. Default value is the current
        computer name.

    .PARAMETER InstanceName
        This is the SQL instance for the database.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DatabaseName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Grant', 'Deny', 'GrantWithGrant')]
        [System.String]
        $PermissionState,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $Permissions,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = (Get-ComputerName),

        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName = 'MSSQLSERVER'
    )

    $sqlServerObject = Connect-SQL -ServerName $ServerName -InstanceName $InstanceName
    if ($sqlServerObject)
    {
        Write-Verbose -Message (
            $script:localizedData.ChangePermissionForUser -f $Name, $DatabaseName, $InstanceName
        )

        if ($sqlDatabaseObject = $sqlServerObject.Databases[$DatabaseName])
        {
            $nameExist = $sqlDatabaseObject.Users[$Name] `
                -or (
                <#
                        Skip fixed roles like db_datareader as it is not possible to set
                        permissions on those.
                    #>
                $sqlDatabaseObject.Roles | Where-Object -FilterScript {
                    -not $_.IsFixedRole -and $_.Name -eq $Name
                }
            ) `
                -or $sqlDatabaseObject.ApplicationRoles[$Name]

            if ($nameExist)
            {
                try
                {
                    $permissionSet = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionSet'

                    foreach ($permission in $permissions)
                    {
                        $permissionSet."$permission" = $true
                    }

                    switch ($Ensure)
                    {
                        'Present'
                        {
                            Write-Verbose -Message (
                                $script:localizedData.AddPermission -f $PermissionState, ($Permissions -join ','), $DatabaseName
                            )

                            switch ($PermissionState)
                            {
                                'GrantWithGrant'
                                {
                                    $sqlDatabaseObject.Grant($permissionSet, $Name, $true)
                                }

                                'Grant'
                                {
                                    $sqlDatabaseObject.Grant($permissionSet, $Name)
                                }

                                'Deny'
                                {
                                    $sqlDatabaseObject.Deny($permissionSet, $Name)
                                }
                            }
                        }

                        'Absent'
                        {
                            Write-Verbose -Message (
                                $script:localizedData.DropPermission -f $PermissionState, ($Permissions -join ','), $DatabaseName
                            )

                            if ($PermissionState -eq 'GrantWithGrant')
                            {
                                $sqlDatabaseObject.Revoke($permissionSet, $Name, $false, $true)
                            }
                            else
                            {
                                $sqlDatabaseObject.Revoke($permissionSet, $Name)
                            }
                        }
                    }
                }
                catch
                {
                    $errorMessage = $script:localizedData.FailedToSetPermissionDatabase -f $Name, $DatabaseName
                    New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
                }
            }
            else
            {
                $errorMessage = $script:localizedData.NameIsMissing -f $Name, $DatabaseName

                New-InvalidOperationException -Message $errorMessage
            }
        }
        else
        {
            $errorMessage = $script:localizedData.DatabaseNotFound -f $DatabaseName
            New-ObjectNotFoundException -Message $errorMessage
        }
    }
}

<#
    .SYNOPSIS
        Tests if the permissions is set for the user in the database.

    .PARAMETER Ensure
        This is The Ensure if the permission should be granted (Present) or
        revoked (Absent).

    .PARAMETER DatabaseName
        This is the SQL database

    .PARAMETER Name
        This is the name of the SQL login for the permission set.

    .PARAMETER PermissionState
        This is the state of permission set. Valid values are 'Grant' or 'Deny'.

    .PARAMETER Permissions
        This is a list that represents a SQL Server set of database permissions.

    .PARAMETER ServerName
        This is the SQL Server for the database. Default value is the current
        computer name.

    .PARAMETER InstanceName
        This is the SQL instance for the database.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DatabaseName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Grant', 'Deny', 'GrantWithGrant')]
        [System.String]
        $PermissionState,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $Permissions,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = (Get-ComputerName),

        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName = 'MSSQLSERVER'
    )

    Write-Verbose -Message (
        $script:localizedData.TestingConfiguration -f $Name, $DatabaseName, $InstanceName
    )

    $getTargetResourceParameters = @{
        InstanceName    = $PSBoundParameters.InstanceName
        ServerName      = $ServerName
        DatabaseName    = $PSBoundParameters.DatabaseName
        Name            = $PSBoundParameters.Name
        PermissionState = $PSBoundParameters.PermissionState
        Permissions     = $PSBoundParameters.Permissions
    }

    $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

    <#
        There is no need to evaluate the parameter Permissions here.
        In the Get-TargetResource function there is a test to verify if Permissions is in
        desired state. If the permissions are correct, then Get-TargetResource will return
        the value 'Present' for the Ensure parameter, otherwise Ensure will have the value
        'Absent'.
    #>
    return Test-DscParameterState -CurrentValues $getTargetResourceResult `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck @('Name', 'Ensure', 'PermissionState') `
        -TurnOffTypeChecking
}

