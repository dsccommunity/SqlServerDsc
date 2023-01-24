$script:sqlServerDscHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\SqlServerDsc.Common'
$script:resourceHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DscResource.Common'

Import-Module -Name $script:sqlServerDscHelperModulePath
Import-Module -Name $script:resourceHelperModulePath

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

<#
    .SYNOPSIS
        Returns the current state of the database role along with its membership.

    .PARAMETER ServerName
        Specifies the host name of the SQL Server to be configured. Default value is
        the current computer name.

    .PARAMETER InstanceName
        Specifies the name of the SQL instance to be configured.

    .PARAMETER DatabaseName
        Specifies name of the database in which the role should be configured.

    .PARAMETER Name
        Specifies the name of the database role to be added or removed.

    .PARAMETER Members
        Specifies the members the database role should have. Existing members not included in this parameter will be
        removed.

    .PARAMETER MembersToInclude
        Specifies members the database role should include. Existing members will be left alone.

    .PARAMETER MembersToExclude
        Specifies members the database role should exclude.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = (Get-ComputerName),

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $DatabaseName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter()]
        [System.String[]]
        $Members,

        [Parameter()]
        [System.String[]]
        $MembersToInclude,

        [Parameter()]
        [System.String[]]
        $MembersToExclude
    )

    Write-Verbose -Message (
        $script:localizedData.GetDatabaseRoleProperties -f $Name
    )

    $roleMembers = @()
    $roleStatus = 'Absent'
    $membersInDesiredState = $false

    $sqlServerObject = Connect-SQL -ServerName $ServerName -InstanceName $InstanceName -ErrorAction 'Stop'
    if ($sqlServerObject)
    {
        $membersInDesiredState = $true

        # Check if database exists.
        if (-not ($sqlDatabaseObject = $sqlServerObject.Databases[$DatabaseName]))
        {
            $errorMessage = $script:localizedData.DatabaseNotFound -f $DatabaseName
            New-ObjectNotFoundException -Message $errorMessage
        }

        $databaseIsUpdateable  = $sqlDatabaseObject.IsUpdateable

        if ($sqlDatabaseRoleObject = $sqlDatabaseObject.Roles[$Name])
        {
            try
            {
                [System.String[]] $roleMembers = $sqlDatabaseRoleObject.EnumMembers()
            }
            catch
            {
                $errorMessage = $script:localizedData.EnumDatabaseRoleMemberNamesError -f $Name, $DatabaseName
                New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
            }

            if ($Members)
            {
                if ($MembersToInclude -or $MembersToExclude)
                {
                    $errorMessage = $script:localizedData.MembersToIncludeAndExcludeParamMustBeNull
                    New-InvalidOperationException -Message $errorMessage
                }

                if ($null -ne (Compare-Object -ReferenceObject $roleMembers -DifferenceObject $Members))
                {
                    Write-Verbose -Message (
                        $script:localizedData.DesiredMembersNotPresent -f $Name, $DatabaseName
                    )
                    $membersInDesiredState = $false
                }
            }
            else
            {
                if ($MembersToInclude)
                {
                    foreach ($memberName in $MembersToInclude)
                    {
                        if (-not ($memberName -in $roleMembers))
                        {
                            Write-Verbose -Message (
                                $script:localizedData.MemberNotPresent -f $memberName, $Name, $DatabaseName
                            )
                            $membersInDesiredState = $false
                        }
                    }
                }

                if ($MembersToExclude)
                {
                    foreach ($memberName in $MembersToExclude)
                    {
                        if ($memberName -in $roleMembers)
                        {
                            Write-Verbose -Message (
                                $script:localizedData.MemberPresent -f $memberName, $Name, $DatabaseName
                            )
                            $membersInDesiredState = $false
                        }
                    }
                }
            }

            $roleStatus = 'Present'
        }
    }

    $returnValue = @{
        ServerName            = $ServerName
        InstanceName          = $InstanceName
        DatabaseName          = $DatabaseName
        DatabaseIsUpdateable  = $databaseIsUpdateable
        Name                  = $Name
        Members               = $roleMembers
        MembersToInclude      = $MembersToInclude
        MembersToExclude      = $MembersToExclude
        MembersInDesiredState = $membersInDesiredState
        Ensure                = $roleStatus
    }

    $returnValue
}

<#
    .SYNOPSIS
        Adds the role to the database and sets role membership when Ensure is set to 'Present'. When Ensure is set to
        'Absent' the role is removed from the database.

    .PARAMETER ServerName
        Specifies the host name of the SQL Server to be configured. Default value is
        the current computer name.

    .PARAMETER InstanceName
        Specifies the name of the SQL instance to be configured.

    .PARAMETER DatabaseName
        Specifies name of the database in which the role should be configured.

    .PARAMETER Name
        Specifies the name of the database role to be added or removed.

    .PARAMETER Members
        Specifies the members the database role should have. Existing members not included in this parameter will be
        removed.

    .PARAMETER MembersToInclude
        Specifies members the database role should include. Existing members will be left alone.

    .PARAMETER MembersToExclude
        Specifies members the database role should exclude.

    .PARAMETER Ensure
        Specifies the desired state of the role.
#>

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = (Get-ComputerName),

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $DatabaseName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter()]
        [System.String[]]
        $Members,

        [Parameter()]
        [System.String[]]
        $MembersToInclude,

        [Parameter()]
        [System.String[]]
        $MembersToExclude,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    Write-Verbose -Message (
        $script:localizedData.SetDatabaseRoleProperties -f $Name
    )

    $sqlServerObject = Connect-SQL -ServerName $ServerName -InstanceName $InstanceName -ErrorAction 'Stop'
    if ($sqlServerObject)
    {
        $sqlDatabaseObject = $sqlServerObject.Databases[$DatabaseName]

        switch ($Ensure)
        {
            'Absent'
            {
                try
                {
                    $sqlDatabaseRoleObjectToDrop = $sqlDatabaseObject.Roles[$Name]
                    if ($sqlDatabaseRoleObjectToDrop)
                    {
                        Write-Verbose -Message (
                            $script:localizedData.DropDatabaseRole -f $Name, $DatabaseName
                        )
                        $sqlDatabaseRoleObjectToDrop.Drop()
                    }
                }
                catch
                {
                    $errorMessage = $script:localizedData.DropDatabaseRoleError -f $Name, $DatabaseName
                    New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
                }
            }

            'Present'
            {
                if ($null -eq $sqlDatabaseObject.Roles[$Name])
                {
                    try
                    {
                        $newRoleObjectParams = @{
                            TypeName     = 'Microsoft.SqlServer.Management.Smo.DatabaseRole'
                            ArgumentList = @($sqlDatabaseObject, $Name)
                        }
                        $sqlDatabaseRoleObject = New-Object @newRoleObjectParams
                        if ($sqlDatabaseRoleObject)
                        {
                            Write-Verbose -Message (
                                $script:localizedData.CreateDatabaseRole -f $Name, $DatabaseName
                            )
                            $sqlDatabaseRoleObject.Create()
                        }
                    }
                    catch
                    {
                        $errorMessage = $script:localizedData.CreateDatabaseRoleError -f $Name, $DatabaseName
                        New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
                    }
                }

                if ($Members)
                {
                    if ($MembersToInclude -or $MembersToExclude)
                    {
                        $errorMessage = $script:localizedData.MembersToIncludeAndExcludeParamMustBeNull
                        New-InvalidOperationException -Message $errorMessage
                    }

                    $roleMembers = $sqlDatabaseObject.Roles[$Name].EnumMembers()
                    foreach ($memberName in $roleMembers)
                    {
                        if (-not ($memberName -in $Members))
                        {
                            $removeMemberParams = @{
                                SqlDatabaseObject = $sqlDatabaseObject
                                Name              = $Name
                                MemberName        = $memberName
                            }
                            Remove-SqlDscDatabaseRoleMember @removeMemberParams
                        }
                    }

                    $roleMembers = $sqlDatabaseObject.Roles[$Name].EnumMembers()
                    foreach ($memberName in $Members)
                    {
                        if (-not ($memberName -in $roleMembers))
                        {
                            $addMemberParams = @{
                                SqlDatabaseObject = $sqlDatabaseObject
                                Name              = $Name
                                MemberName        = $memberName
                            }
                            Add-SqlDscDatabaseRoleMember @addMemberParams
                        }
                    }
                }
                else
                {
                    if ($MembersToInclude)
                    {
                        $roleMembers = $sqlDatabaseObject.Roles[$Name].EnumMembers()
                        foreach ($memberName in $MembersToInclude)
                        {
                            if (-not ($memberName -in $roleMembers))
                            {
                                $addMemberParams = @{
                                    SqlDatabaseObject = $sqlDatabaseObject
                                    Name              = $Name
                                    MemberName        = $memberName
                                }
                                Add-SqlDscDatabaseRoleMember @addMemberParams
                            }
                        }
                    }

                    if ($MembersToExclude)
                    {
                        $roleMembers = $sqlDatabaseObject.Roles[$Name].EnumMembers()
                        foreach ($memberName in $MembersToExclude)
                        {
                            if ($memberName -in $roleMembers)
                            {
                                $removeMemberParams = @{
                                    SqlDatabaseObject = $sqlDatabaseObject
                                    Name              = $Name
                                    MemberName        = $memberName
                                }
                                Remove-SqlDscDatabaseRoleMember @removeMemberParams
                            }
                        }
                    }
                }
            }
        }
    }
}

<#
    .SYNOPSIS
        Tests the current state of the database role along with its membership.

    .PARAMETER ServerName
        Specifies the host name of the SQL Server to be configured. Default value is
        the current computer name.

    .PARAMETER InstanceName
        Specifies the name of the SQL instance to be configured.

    .PARAMETER DatabaseName
        Specifies name of the database in which the role should be configured.

    .PARAMETER Name
        Specifies the name of the database role to be added or removed.

    .PARAMETER Members
        Specifies the members the database role should have. Existing members not included in this parameter will be
        removed.

    .PARAMETER MembersToInclude
        Specifies members the database role should include. Existing members will be left alone.

    .PARAMETER MembersToExclude
        Specifies members the database role should exclude.

    .PARAMETER Ensure
        Specifies the desired state of the role.
#>
function Test-TargetResource
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('SqlServerDsc.AnalyzerRules\Measure-CommandsNeededToLoadSMO', '', Justification='The command Connect-Sql is called when Get-TargetResource is called')]
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = (Get-ComputerName),

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $DatabaseName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter()]
        [System.String[]]
        $Members,

        [Parameter()]
        [System.String[]]
        $MembersToInclude,

        [Parameter()]
        [System.String[]]
        $MembersToExclude,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    Write-Verbose -Message (
        $script:localizedData.TestDatabaseRoleProperties -f $Name
    )

    $getTargetResourceParameters = @{
        ServerName       = $ServerName
        InstanceName     = $PSBoundParameters.InstanceName
        DatabaseName     = $PSBoundParameters.DatabaseName
        Name             = $PSBoundParameters.Name
        Members          = $PSBoundParameters.Members
        MembersToInclude = $PSBoundParameters.MembersToInclude
        MembersToExclude = $PSBoundParameters.MembersToExclude
    }

    $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

    $isDatabaseRoleInDesiredState = $true

    if ($true -eq $getTargetResourceResult.DatabaseIsUpdateable)
    {
        switch ($Ensure)
        {
            'Absent'
            {
                if ($getTargetResourceResult.Ensure -ne 'Absent')
                {
                    Write-Verbose -Message (
                        $script:localizedData.EnsureIsAbsent -f $Name
                    )
                    $isDatabaseRoleInDesiredState = $false
                }
            }

            'Present'
            {
                if ($getTargetResourceResult.Ensure -ne 'Present' -or $getTargetResourceResult.MembersInDesiredState -eq $false)
                {
                    Write-Verbose -Message (
                        $script:localizedData.EnsureIsPresent -f $Name
                    )
                    $isDatabaseRoleInDesiredState = $false
                }
            }
        }
    }

    $isDatabaseRoleInDesiredState
}

<#
    .SYNOPSIS
        Adds a member to a database role in the SQL Server instance provided.

    .PARAMETER SqlDatabaseObject
        A database object.

    .PARAMETER Name
        String containing the name of the database role to add the member to.

    .PARAMETER MemberName
        String containing the name of the member which should be added to the database role.
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
        $Name,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $MemberName
    )

    $databaseName = $SqlDatabaseObject.Name

    if (-not ($SqlDatabaseObject.Roles[$Name] -and $SqlDatabaseObject.Users[$MemberName]))
    {
        $errorMessage = $script:localizedData.DatabaseRoleOrUserNotFound -f $Name, $MemberName, $databaseName
        New-ObjectNotFoundException -Message $errorMessage
    }

    try
    {
        Write-Verbose -Message (
            $script:localizedData.AddDatabaseRoleMember -f $MemberName, $Name, $databaseName
        )
        $SqlDatabaseObject.Roles[$Name].AddMember($MemberName)
    }
    catch
    {
        $errorMessage = $script:localizedData.AddDatabaseRoleMemberError -f $MemberName, $Name, $databaseName
        New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
    }
}

<#
    .SYNOPSIS
        Removes a member from a database role in the SQL Server instance provided.

    .PARAMETER SqlDatabaseObject
        A database object.

    .PARAMETER Name
        String containing the name of the database role to remove the member from.

    .PARAMETER MemberName
        String containing the name of the member which should be removed from the database role.
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
        $Name,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $MemberName
    )

    $databaseName = $SqlDatabaseObject.Name

    try
    {
        Write-Verbose -Message (
            $script:localizedData.DropDatabaseRoleMember -f $MemberName, $Name, $databaseName
        )
        $SqlDatabaseObject.Roles[$Name].DropMember($MemberName)
    }
    catch
    {
        $errorMessage = $script:localizedData.DropDatabaseRoleMemberError -f $MemberName, $Name, $databaseName
        New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
    }
}
