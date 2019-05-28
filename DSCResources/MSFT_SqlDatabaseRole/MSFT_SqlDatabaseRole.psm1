$script:resourceModulePath = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
$script:modulesFolderPath = Join-Path -Path $script:resourceModulePath -ChildPath 'Modules'

$script:localizationModulePath = Join-Path -Path $script:modulesFolderPath -ChildPath 'DscResource.LocalizationHelper'
Import-Module -Name (Join-Path -Path $script:localizationModulePath -ChildPath 'DscResource.LocalizationHelper.psm1')

$script:resourceHelperModulePath = Join-Path -Path $script:modulesFolderPath -ChildPath 'SqlServerDsc.Common'
Import-Module -Name (Join-Path -Path $script:resourceHelperModulePath -ChildPath 'SqlServerDsc.Common.psm1')

$script:localizedData = Get-LocalizedData -ResourceName 'MSFT_SqlDatabaseRole'

<#
    .SYNOPSIS
    Returns the current state of the user memberships in the role(s).

    .PARAMETER Ensure
    Specifies the desired state of the membership of the role(s).

    .PARAMETER Name
    Specifies the name of the login that evaluated if it is member of the role(s).

    .PARAMETER ServerName
    Specifies the SQL server on which the instance exist.

    .PARAMETER InstanceName
    Specifies the SQL instance in which the database exist.

    .PARAMETER Database
    Specifies the database in which the login (user) and role(s) exist.

    .PARAMETER Role
    Specifies one or more roles to which the login (user) will be evaluated if it should be added or removed.
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
        $Name,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Database,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $Role
    )

    Write-Verbose -Message (
        $script:localizedData.GetDatabaseRole -f $Name, $Database, $InstanceName
    )

    $sqlServerObject = Connect-SQL -ServerName $ServerName -InstanceName $InstanceName
    if ($sqlServerObject)
    {
        # Check database exists
        if ( -not ($sqlDatabaseObject = $sqlServerObject.Databases[$Database]) )
        {
            $errorMessage = $script:localizedData.DatabaseNotFound -f $Database
            New-ObjectNotFoundException -Message $errorMessage
        }

        # Check role exists
        foreach ($currentRole in $Role)
        {
            if ( -not ($sqlDatabaseObject.Roles[$currentRole]) )
            {
                $errorMessage = $script:localizedData.RoleNotFound -f $currentRole, $Database
                New-ObjectNotFoundException -Message $errorMessage
            }
        }

        # Check login exists
        if ( -not ($sqlServerObject.Logins[$Name]) )
        {
            $errorMessage = $script:localizedData.LoginNotFound -f $Name
            New-ObjectNotFoundException -Message $errorMessage
        }

        $ensure = 'Absent'
        $grantedRole = @()

        if ($sqlDatabaseUser = $sqlDatabaseObject.Users[$Name] )
        {
            foreach ($currentRole in $Role)
            {
                if ($sqlDatabaseUser.IsMember($currentRole))
                {
                    Write-Verbose -Message (
                        $script:localizedData.IsMember -f $Name, $currentRole, $Database
                    )

                    $grantedRole += $currentRole
                }
                else
                {
                    Write-Verbose -Message (
                        $script:localizedData.IsNotMember -f $Name, $currentRole, $Database
                    )
                }
            }

            if ( -not (Compare-Object -ReferenceObject $Role -DifferenceObject $grantedRole) )
            {
                $ensure = 'Present'
            }
        }
        else
        {
            Write-Verbose -Message (
                $script:localizedData.LoginIsNotUser -f $Name, $Database
            )
        }
    }

    $returnValue = @{
        Ensure       = $ensure
        Name         = $Name
        ServerName   = $ServerName
        InstanceName = $InstanceName
        Database     = $Database
        Role         = $grantedRole
    }

    $returnValue
}

<#
    .SYNOPSIS
    Adds the login (user) to each of the provided roles when Ensure is set to 'Present'.
    When Ensure is set to 'Absent' the login (user) will be removed from each of the provided roles.
    If the login does not exist as a user in the database, then the user will be created in the database using the login.

    .PARAMETER Ensure
    Specifies the desired state of the membership of the role(s).

    .PARAMETER Name
    Specifies the name of the login that evaluated if it is member of the role(s), if it is not it will be added.
    If the login does not exist as a user, a user will be created using the login.

    .PARAMETER ServerName
    Specifies the SQL server on which the instance exist.

    .PARAMETER InstanceName
    Specifies the SQL instance in which the database exist.

    .PARAMETER Database
    Specifies the database in which the login (user) and role(s) exist.

    .PARAMETER Role
    Specifies one or more roles to which the login (user) will be added or removed.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Database,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $Role
    )

    $sqlServerObject = Connect-SQL -ServerName $ServerName -InstanceName $InstanceName
    if ($sqlServerObject)
    {
        $sqlDatabaseObject = $sqlServerObject.Databases[$Database]

        switch ($Ensure)
        {
            'Present'
            {
                # Adding database user if it does not exist.
                if ( -not ($sqlDatabaseObject.Users[$Name]) )
                {
                    try
                    {
                        Write-Verbose -Message (
                            '{0} {1}' -f
                                ($script:localizedData.LoginIsNotUser -f $Name, $Database),
                                $script:localizedData.AddingLoginAsUser
                        )

                        $sqlDatabaseUser = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.User' `
                            -ArgumentList $sqlDatabaseObject, $Name
                        $sqlDatabaseUser.Login = $Name
                        $sqlDatabaseUser.Create()
                    }
                    catch
                    {
                        $errorMessage = $script:localizedData.FailedToAddUser -f $Name, $Database
                        New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
                    }
                }

                # Adding database user to the role.
                foreach ($currentRole in $Role)
                {
                    try
                    {
                        Write-Verbose -Message (
                            $script:localizedData.AddUserToRole -f $Name, $currentRole, $Database
                        )

                        $sqlDatabaseRole = $sqlDatabaseObject.Roles[$currentRole]
                        $sqlDatabaseRole.AddMember($Name)
                    }
                    catch
                    {
                        $errorMessage = $script:localizedData.FailedToAddUserToRole -f $Name, $currentRole, $Database
                        New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
                    }
                }
            }

            'Absent'
            {
                try
                {
                    foreach ($currentRole in $Role)
                    {
                        Write-Verbose -Message (
                            $script:localizedData.DropUserFromRole -f $Name, $currentRole, $Database
                        )

                        $sqlDatabaseRole = $sqlDatabaseObject.Roles[$currentRole]
                        $sqlDatabaseRole.DropMember($Name)
                    }
                }
                catch
                {
                    $errorMessage = $script:localizedData.FailedToDropUserFromRole -f $Name, $currentRole, $Database
                    New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
                }
            }
        }
    }
}

<#
    .SYNOPSIS
    Tests if the login (user) has the desired state in each of the provided roles.

    .PARAMETER Ensure
    Specifies the desired state of the membership of the role(s).

    .PARAMETER Name
    Specifies the name of the login that evaluated if it is member of the role(s).

    .PARAMETER ServerName
    Specifies the SQL server on which the instance exist.

    .PARAMETER InstanceName
    Specifies the SQL instance in which the database exist.

    .PARAMETER Database
    Specifies the database in which the login (user) and role(s) exist.

    .PARAMETER Role
    Specifies one or more roles to which the login (user) will be tested if it should added or removed.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Database,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $Role
    )

    Write-Verbose -Message (
        $script:localizedData.TestingConfiguration -f $Name, $Database, $InstanceName
    )

    $getTargetResourceParameters = @{
        InstanceName = $PSBoundParameters.InstanceName
        ServerName   = $PSBoundParameters.ServerName
        Role         = $PSBoundParameters.Role
        Database     = $PSBoundParameters.Database
        Name         = $PSBoundParameters.Name
    }

    $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

    $isDatabaseRoleInDesiredState = $true

    switch ($Ensure)
    {
        'Absent'
        {
            if ($getTargetResourceResult.Ensure -ne 'Absent')
            {
                Write-Verbose -Message (
                    $script:localizedData.NotInDesiredStateAbsent -f $Name, $Database
                )

                $isDatabaseRoleInDesiredState = $false
            }
        }

        'Present'
        {
            if ($getTargetResourceResult.Ensure -ne 'Present')
            {
                Write-Verbose -Message (
                    $script:localizedData.NotInDesiredStatePresent -f $Name, $Database
                )

                $isDatabaseRoleInDesiredState = $false
            }
        }
    }

    if ($isDatabaseRoleInDesiredState)
    {
        Write-Verbose -Message (
            $script:localizedData.InDesiredState -f $Name, $Database
        )
    }

    return $isDatabaseRoleInDesiredState
}

Export-ModuleMember -Function *-TargetResource
