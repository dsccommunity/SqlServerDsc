$currentPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Debug -Message "CurrentPath: $currentPath"

# Load Common Code
Import-Module $currentPath\..\..\xSQLServerHelper.psm1 -Verbose:$false -ErrorAction Stop

# DSC resource to manage SQL logins in server role

# NOTE: This resource requires WMF5 and PsDscRunAsCredential

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [System.Management.Automation.PSCredential]
        $LoginCredential,

        [ValidateSet("bulkadmin","dbcreator","diskadmin","processadmin","public","securityadmin","serveradmin","setupadmin","sysadmin")]
        [System.String[]]
        $ServerRoles,

        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [System.String]
        $SQLInstanceName = "MSSQLSERVER"
    )

    if(!$SQL)
    {
        $SQL = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName
    }

    if($SQL)
    {
        Write-Verbose "Getting SQL Roles"
        $SQLRoles = $SQL.Roles
        if($SQLRoles)
        {
            ForEach ($ServerRole in $ServerRoles)
            {
                if($SQLRoles[$ServerRole])
                {
                    Write-Verbose "SQL role name $ServerRole is present"
                    $membersInRole = $SQLRoles[$ServerRole].EnumMemberNames()             
                    if($membersInRole.Contains($Name))
                    {
                        $Ensure = "Present"
                        Write-Verbose "$Name is present in SQL role name $ServerRole"
                    }
                    else
                    {
                        Write-Verbose "$Name is absent in SQL role name $ServerRole"
                        $Ensure = "Absent"
                    }
                }
                else
                {
                    Write-Verbose "SQL role name $ServerRole is absent"
                    $Ensure = "Absent"
                }
            }
        }
        else
        {
            Write-Verbose "Failed getting SQL roles"
            $Ensure = "Absent"
        }
    }
    else
    {
        $Ensure = "Absent"
    }

    $returnValue = @{
        Ensure = $Ensure
        Name = $Name
        ServerRole = $ServerRole
        SQLServer = $SQLServer
        SQLInstanceName = $SQLInstanceName
    }

    $returnValue
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present",

        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [System.Management.Automation.PSCredential]
        $LoginCredential,

        [ValidateSet("bulkadmin","dbcreator","diskadmin","processadmin","public","securityadmin","serveradmin","setupadmin","sysadmin")]
        [System.String[]]
        $ServerRoles = "public",

        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [System.String]
        $SQLInstanceName = "MSSQLSERVER"
    )

    if(!$SQL)
    {
        $SQL = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName
    }

    if($SQL)
    {
        switch($Ensure)
        {
            "Present"
            {
                try
                {
                    $SQLRoles = $SQL.Roles
                    ForEach ($ServerRole in $ServerRoles)
                    {
                        Write-Verbose "Adding SQL login $Name in role $ServerRole"
                        $SQLRoles[$ServerRole].AddMember($Name)
                    }
                }
                catch
                {
                    Write-Verbose "Failed adding SQL login $Name in role $ServerRole"
                }
            }
            "Absent"
            {
                try
                {
                    $SQLRoles = $SQL.Roles
                    ForEach ($ServerRole in $ServerRoles)
                    {
                        Write-Verbose "Deleting SQL login $Name in role $ServerRole"
                        $SQLRoles[$ServerRole].DropMember($Name)
                    }
                }
                catch
                {
                    Write-Verbose "Failed deleting SQL login $Name"
                }
            }
        }
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present",

        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [System.Management.Automation.PSCredential]
        $LoginCredential,

        [ValidateSet("bulkadmin","dbcreator","diskadmin","processadmin","public","securityadmin","serveradmin","setupadmin","sysadmin")]
        [System.String[]]
        $ServerRoles = "public",

        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [System.String]
        $SQLInstanceName = "MSSQLSERVER"
    )

    if(!$SQL)
    {
        $SQL = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName
    }

    if($SQL)
    {
        switch($Ensure)
        {
            "Present"
            {
                try
                {
                    Write-Verbose "getting SQL login $Name in role $ServerRoles"
                    $numberSQLRolesPresent=0
                    $SQLRoles = $SQL.Roles
                    ForEach ($ServerRole in $ServerRoles)
                    {
                        $membersInRole = $SQLRoles[$ServerRole].EnumMemberNames()
                        if($membersInRole.Contains($Name))
                        {
                            New-VerboseMessage -Message "$Name is present in SQL role name $ServerRole"
                            $numberSQLRolesPresent++
                        }
                        Else
                        {
                            New-VerboseMessage -Message "$Name is absent in SQL role name $ServerRole"
                        }
                    }
                    if($ServerRoles.Count -eq $numberSQLRolesPresent){return $True}
                    Else{return $False}
                }
                catch
                {
                    Write-Verbose "Failed getting SQL login $Name in role $ServerRoles"
                }
            }
            "Absent"
            {
                try
                {
                    Write-Verbose "getting SQL login $Name in role $ServerRole"
                    $numberSQLRolesAbsent = 0
                    $SQLRoles = $SQL.Roles
                    ForEach ($ServerRole in $ServerRoles)
                    {
                        $membersInRole = $SQLRoles[$ServerRole].EnumMemberNames()
                        if($membersInRole.Contains($Name))
                        {
                            New-VerboseMessage -Message "$Name is absent in SQL role name $ServerRole"
                            $numberSQLRolesAbsent++
                        }
                        Else
                        {
                            New-VerboseMessage -Message "$Name is present in SQL role name $ServerRole"
                        }
                    }
                    if($ServerRoles.Count -eq $numberSQLRolesAbsent){return $False}
                    Else{return $True}
                }
                catch
                {
                    Write-Verbose "Failed getting SQL login $Name in role $ServerRole"
                }
            }
        }
    }
}

Export-ModuleMember -Function *-TargetResource
