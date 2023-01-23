$script:sqlServerDscHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\SqlServerDsc.Common'
$script:resourceHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DscResource.Common'

Import-Module -Name $script:sqlServerDscHelperModulePath
Import-Module -Name $script:resourceHelperModulePath

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

<#
    .SYNOPSIS
        This function gets the sql server role properties.

    .PARAMETER ServerName
        The host name of the SQL Server to be configured. Default value is the
        current computer name.

    .PARAMETER InstanceName
        The name of the SQL instance to be configured.

    .PARAMETER ServerRoleName
        The name of server role to be created or dropped.

    .Notes
        Because the return of this function will always be the actual members in the role,
        and not the desired members in a role, there is no point in returning $MembersToInclude and exclude.
        You now get "present" if the role exists, and when it exists, you get the current members in that role.

        The way it was: if a role does not exists, you still get $membersToInclude And $membersToExclude.
        To me that seems like strange behavior.
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
        $ServerRoleName
    )

    $sqlServerObject = Connect-SQL -ServerName $ServerName -InstanceName $InstanceName -ErrorAction 'Stop'
    $ensure = 'Absent'
    $membersInRole = $null

    if ($sqlServerObject)
    {
        Write-Verbose -Message (
            $script:localizedData.GetProperties `
                -f $ServerRoleName
        )

        if ($sqlServerRoleObject = $sqlServerObject.Roles[$ServerRoleName])
        {
            try
            {
                [System.String[]] $membersInRole = $sqlServerRoleObject.EnumMemberNames()
                $ensure = 'Present'
            }
            catch
            {
                $errorMessage = $script:localizedData.EnumMemberNamesServerRoleGetError `
                    -f $ServerName, $InstanceName, $ServerRoleName

                New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
            }
        }
    }

    return @{
        ServerRoleName     = $ServerRoleName
        Ensure             = $ensure
        ServerName         = $ServerName
        InstanceName       = $InstanceName
        Members            = $membersInRole
        MembersToInclude   = $null
        MembersToExclude   = $null
    }
}

<#
    .SYNOPSIS
        This function sets the sql server role properties.

    .PARAMETER Ensure
        When set to 'Present', the server role will be created.
        When set to 'Absent', the server role will be dropped.

    .PARAMETER Members
        The members the server role should have.

    .PARAMETER MembersToInclude
        The members the server role should include.

    .PARAMETER MembersToExclude
        The members the server role should exclude.

    .PARAMETER ServerRoleName
        The name of server role to be created or dropped.

    .PARAMETER ServerName
        The host name of the SQL Server to be configured. Default value is the
        current computer name.

    .PARAMETER InstanceName
        The name of the SQL instance to be configured.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [System.String[]]
        $Members,

        [Parameter()]
        [System.String[]]
        $MembersToInclude,

        [Parameter()]
        [System.String[]]
        $MembersToExclude,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerRoleName,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = (Get-ComputerName),

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstanceName
    )

    $assertBoundParameterParameters = @{
        BoundParameterList = $PSBoundParameters
        MutuallyExclusiveList1 = @(
            'Members'
        )
        MutuallyExclusiveList2 = @(
            'MembersToExclude', 'MembersToInclude'
        )
    }

    Assert-BoundParameter @assertBoundParameterParameters

    $sqlServerObject = Connect-SQL -ServerName $ServerName -InstanceName $InstanceName -ErrorAction 'Stop'

    if ($sqlServerObject)
    {
        Write-Verbose -Message (
            $script:localizedData.SetProperties `
                -f $ServerRoleName
        )

        switch ($Ensure)
        {
            'Absent'
            {
                try
                {
                    $sqlServerRoleObjectToDrop = $sqlServerObject.Roles[$ServerRoleName]
                    if ($sqlServerRoleObjectToDrop)
                    {
                        Write-Verbose -Message (
                            $script:localizedData.DropRole `
                                -f $ServerRoleName
                        )

                        $sqlServerRoleObjectToDrop.Drop()
                    }
                }
                catch
                {
                    $errorMessage = $script:localizedData.DropServerRoleSetError `
                        -f $ServerName, $InstanceName, $ServerRoleName

                    New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
                }
            }

            'Present'
            {
                if ($null -eq $sqlServerObject.Roles[$ServerRoleName])
                {
                    try
                    {
                        $sqlServerRoleObjectToCreate = New-Object -TypeName Microsoft.SqlServer.Management.Smo.ServerRole `
                            -ArgumentList $sqlServerObject, $ServerRoleName
                        if ($sqlServerRoleObjectToCreate)
                        {
                            Write-Verbose -Message (
                                $script:localizedData.CreateRole `
                                    -f $ServerRoleName
                            )

                            $sqlServerRoleObjectToCreate.Create()
                        }
                    }
                    catch
                    {
                        $errorMessage = $script:localizedData.CreateServerRoleSetError `
                            -f $ServerName, $InstanceName, $ServerRoleName

                        New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
                    }
                }

                $originalParameters = @{
                    ServerRoleName   = $ServerRoleName
                    Members          = $Members
                    MembersToInclude = $MembersToInclude
                    MembersToExclude = $MembersToExclude
                }

                $correctedParameters = Get-CorrectedMemberParameters @originalParameters

                if ($Members)
                {
                    $memberNamesInRoleObject = $sqlServerObject.Roles[$ServerRoleName].EnumMemberNames()

                    foreach ($memberName in $memberNamesInRoleObject)
                    {
                        if ($correctedParameters.Members -notcontains $memberName)
                        {
                            Remove-SqlDscServerRoleMember -SqlServerObject $sqlServerObject `
                                -SecurityPrincipal $memberName `
                                -ServerRoleName $ServerRoleName
                        }
                    }

                    foreach ($memberToAdd in $correctedParameters.Members)
                    {
                        if ($memberNamesInRoleObject -notcontains $memberToAdd)
                        {
                            Add-SqlDscServerRoleMember -SqlServerObject $sqlServerObject `
                                -SecurityPrincipal $memberToAdd `
                                -ServerRoleName $ServerRoleName
                        }
                    }
                }
                else
                {
                    if ($MembersToInclude)
                    {
                        $memberNamesInRoleObject = $sqlServerObject.Roles[$ServerRoleName].EnumMemberNames()

                        foreach ($memberToInclude in $correctedParameters.MembersToInclude)
                        {
                            if ($memberNamesInRoleObject -notcontains $memberToInclude)
                            {
                                Add-SqlDscServerRoleMember -SqlServerObject $sqlServerObject `
                                    -SecurityPrincipal $memberToInclude `
                                    -ServerRoleName $ServerRoleName
                            }
                        }
                    }

                    if ($MembersToExclude)
                    {
                        $memberNamesInRoleObject = $sqlServerObject.Roles[$ServerRoleName].EnumMemberNames()

                        foreach ($memberToExclude in $correctedParameters.MembersToExclude)
                        {
                            if ($memberNamesInRoleObject -contains $memberToExclude)
                            {
                                Remove-SqlDscServerRoleMember -SqlServerObject $sqlServerObject `
                                    -SecurityPrincipal $memberToExclude `
                                    -ServerRoleName $ServerRoleName
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
        This function tests the sql server role properties.

    .PARAMETER Ensure
        When set to 'Present', the server role will be created.
        When set to 'Absent', the server role will be dropped.

    .PARAMETER Members
        The members the server role should have.

    .PARAMETER MembersToInclude
        The members the server role should include.

    .PARAMETER MembersToExclude
        The members the server role should exclude.

    .PARAMETER ServerRoleName
        The name of server role to be created or dropped.

    .PARAMETER ServerName
        The host name of the SQL Server to be configured. Default value is the
        current computer name.

    .PARAMETER InstanceName
        The name of the SQL instance to be configured.
#>
function Test-TargetResource
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('SqlServerDsc.AnalyzerRules\Measure-CommandsNeededToLoadSMO', '', Justification='The command Connect-Sql is called when Get-TargetResource is called')]
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [System.String[]]
        $Members,

        [Parameter()]
        [System.String[]]
        $MembersToInclude,

        [Parameter()]
        [System.String[]]
        $MembersToExclude,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerRoleName,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = (Get-ComputerName),

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstanceName
    )

    Write-Verbose -Message (
        $script:localizedData.TestProperties `
            -f $ServerRoleName
    )

    $assertBoundParameterParameters = @{
        BoundParameterList = $PSBoundParameters
        MutuallyExclusiveList1 = @(
            'Members'
        )
        MutuallyExclusiveList2 = @(
            'MembersToExclude', 'MembersToInclude'
        )
    }

    Assert-BoundParameter @assertBoundParameterParameters

    $originalParameters = @{
        ServerRoleName   = $ServerRoleName
        Members          = $Members
        MembersToInclude = $MembersToInclude
        MembersToExclude = $MembersToExclude
    }

    $correctedParameters = Get-CorrectedMemberParameters @originalParameters

    $getTargetResourceParameters = @{
        InstanceName     = $InstanceName
        ServerName       = $ServerName
        ServerRoleName   = $ServerRoleName
    }

    $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters
    $isServerRoleInDesiredState = $true

    switch ($Ensure)
    {
        'Absent'
        {
            if ($getTargetResourceResult.Ensure -ne 'Absent')
            {
                Write-Verbose -Message (
                    $script:localizedData.EnsureIsAbsent `
                        -f $ServerRoleName
                )

                $isServerRoleInDesiredState = $false
            }
        }

        'Present'
        {
            if ($getTargetResourceResult.Ensure -ne 'Present')
            {
                Write-Verbose -Message (
                    $script:localizedData.EnsureIsPresent `
                        -f $ServerRoleName
                )

                $isServerRoleInDesiredState = $false
            }
            else
            {
                if ($Members)
                {
                    if ( $null -ne (Compare-Object -ReferenceObject $getTargetResourceResult.Members -DifferenceObject $correctedParameters.Members))
                    {
                        Write-Verbose -Message (
                            $script:localizedData.DesiredMembersNotPresent `
                                -f $ServerRoleName
                        )

                        $isServerRoleInDesiredState = $false
                    }
                }
                else
                {
                    if ($MembersToInclude)
                    {
                        foreach ($memberToInclude in $correctedParameters.MembersToInclude)
                        {
                            if ($getTargetResourceResult.Members -notcontains $memberToInclude)
                            {
                                Write-Verbose -Message (
                                    $script:localizedData.MemberNotPresent `
                                        -f $ServerRoleName, $memberToInclude
                                )

                                $isServerRoleInDesiredState = $false
                            }
                        }
                    }

                    if ($MembersToExclude)
                    {
                        foreach ($memberToExclude in $correctedParameters.MembersToExclude)
                        {
                            if ($getTargetResourceResult.Members -contains $memberToExclude)
                            {
                                Write-Verbose -Message (
                                    $script:localizedData.MemberPresent `
                                        -f $ServerRoleName, $memberToExclude
                                )

                                $isServerRoleInDesiredState = $false
                            }
                        }
                    }
                }
            }
        }
    }

    $isServerRoleInDesiredState
}

<#
    .SYNOPSIS
        Add a user to a server role in the SQL Server instance provided.

    .PARAMETER SqlServerObject
        An object returned from Connect-SQL function.

    .PARAMETER SecurityPrincipal
        String containing the login (user) which should be added as a member to the server role.

    .PARAMETER ServerRoleName
        String containing the name of the server role which the user will be added as a member to.
#>
function Add-SqlDscServerRoleMember
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        $SqlServerObject,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SecurityPrincipal,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerRoleName
    )

    try
    {
        Test-SqlSecurityPrincipal -SqlServerObject $SqlServerObject -SecurityPrincipal $SecurityPrincipal

        Write-Verbose -Message (
            $script:localizedData.AddMemberToRole `
                -f $SecurityPrincipal, $ServerRoleName
        )

        $SqlServerObject.Roles[$ServerRoleName].AddMember($SecurityPrincipal)
    }
    catch
    {
        $errorMessage = $script:localizedData.AddMemberServerRoleSetError `
            -f $ServerName, $InstanceName, $ServerRoleName, $SecurityPrincipal

        New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
    }
}

<#
    .SYNOPSIS
        Remove a user in a server role in the SQL Server instance provided.

    .PARAMETER SqlServerObject
        An object returned from Connect-SQL function.

    .PARAMETER SecurityPrincipal
        String containing the login (user) which should be removed as a member in the server role.

    .PARAMETER ServerRoleName
        String containing the name of the server role for which the user will be removed as a member.
#>
function Remove-SqlDscServerRoleMember
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        $SqlServerObject,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SecurityPrincipal,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerRoleName
    )

    try
    {
        # Determine whether a valid principal has been supplied
        Test-SqlSecurityPrincipal -SqlServerObject $SqlServerObject -SecurityPrincipal $SecurityPrincipal

        Write-Verbose -Message (
            $script:localizedData.RemoveMemberFromRole `
                -f $SecurityPrincipal, $ServerRoleName
        )

        $SqlServerObject.Roles[$ServerRoleName].DropMember($SecurityPrincipal)
    }
    catch
    {
        $errorMessage = $script:localizedData.DropMemberServerRoleSetError `
            -f $ServerName, $InstanceName, $ServerRoleName, $SecurityPrincipal

        New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
    }
}

<#
    .SYNOPSIS
        Tests whether a security principal is valid on the specified SQL Server instance.

    .PARAMETER SqlServerObject
        The object returned from the Connect-SQL function.

    .PARAMETER SecurityPrincipal
        String containing the name of the principal to validate.
#>
function Test-SqlSecurityPrincipal
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Object]
        $SqlServerObject,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SecurityPrincipal
    )

    if ($SqlServerObject.Logins.Name -notcontains $SecurityPrincipal)
    {
        if ($SqlServerObject.Roles.Name -notcontains $SecurityPrincipal)
        {
            $errorMessage = $script:localizedData.SecurityPrincipalNotFound -f (
                $SecurityPrincipal,
                $($SqlServerObject.Name)
            )

            # Principal is neither a Login nor a Server role, raise exception
            New-ObjectNotFoundException -Message $errorMessage
        }
    }

    return $true
}

<#
    .SYNOPSIS
        This function sanitizes the parameters
        If Members is filled, MembersToInclude and MembersToExclude should be empty.
        If ServerRoleName is sysadmin, make sure we dont try to delete SA from it.

    .PARAMETER Members
        The members the server role should have.

    .PARAMETER MembersToInclude
        The members the server role should include.

    .PARAMETER MembersToExclude
        The members the server role should exclude.

    .PARAMETER ServerRoleName
        The name of server role to be created or dropped.
#>
function Get-CorrectedMemberParameters
{
    param
    (
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
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerRoleName
    )

    if ($ServerRoleName -eq 'sysadmin')
    {
        if ($Members)
        {
            if ($Members -notcontains 'SA')
            {
                $Members += 'SA'
            }
        }
        else
        {
            if ($MembersToExclude -contains 'SA')
            {
                $MembersToExclude = $MembersToExclude -ne 'SA'
            }
        }
    }

    return @{
        Members          = [System.String[]]$Members
        MembersToInclude = [System.String[]]$MembersToInclude
        MembersToExclude = [System.String[]]$MembersToExclude
    }
}
