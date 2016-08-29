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
        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [parameter(Mandatory = $true)]
        [ValidateSet("bulkadmin","dbcreator","diskadmin","processadmin","public","securityadmin","serveradmin","setupadmin","sysadmin")]
        [System.String[]]
        $ServerRole,

        [parameter(Mandatory = $true)]
        [System.String]
        $SQLServer,

        [parameter(Mandatory = $true)]
        [System.String]
        $SQLInstanceName
    )

    if(!$SQL)
    {
        $SQL = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName
    }

    if($SQL)
    {
        Write-Verbose "Getting SQL Server roles for $Name on SQL Server $SQLServer."
        $SQLRole = $SQL.Roles
        if($SQLRole)
        {
            ForEach ($srvRole in $ServerRole)
            {
                if($SQLRole[$srvRole])
                {
                    $membersInRole = $SQLRole[$srvRole].EnumMemberNames()             
                    if($membersInRole.Contains($Name))
                    {
                        $Ensure = "Present"
                        Write-Verbose "$Name is present in SQL role name $srvRole"
                    }
                    else
                    {
                        Write-Verbose "$Name is absent in SQL role name $srvRole"
                        $Ensure = "Absent"
                    }
                }
                else
                {
                    Write-Verbose "SQL role name $srvRole is absent"
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
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [parameter(Mandatory = $true)]
        [ValidateSet("bulkadmin","dbcreator","diskadmin","processadmin","public","securityadmin","serveradmin","setupadmin","sysadmin")]
        [System.String[]]
        $ServerRole,

        [parameter(Mandatory = $true)]
        [System.String]
        $SQLServer,

        [parameter(Mandatory = $true)]
        [System.String]
        $SQLInstanceName
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
                    $SQLRole = $SQL.Roles
                    ForEach ($srvRole in $ServerRole)
                    {
                        Write-Verbose "Adding SQL login $Name in role $srvRole"
                        $SQLRole[$srvRole].AddMember($Name)
                    }
                }
                catch
                {
                    Write-Verbose "Failed adding SQL login $Name in role $srvRole"
                }
            }
            "Absent"
            {
                try
                {
                    $SQLRole = $SQL.Roles
                    ForEach ($srvRole in $ServerRole)
                    {
                        Write-Verbose "Deleting SQL login $Name in role $srvRole"
                        $SQLRole[$srvRole].DropMember($Name)
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
        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [parameter(Mandatory = $true)]
        [ValidateSet("bulkadmin","dbcreator","diskadmin","processadmin","public","securityadmin","serveradmin","setupadmin","sysadmin")]
        [System.String[]]
        $ServerRole,

        [parameter(Mandatory = $true)]
        [System.String]
        $SQLServer,

        [parameter(Mandatory = $true)]
        [System.String]
        $SQLInstanceName
    )

    Write-Verbose -Message "Testing SQL roles for login $Name"
    $CurrentValues = Get-TargetResource @PSBoundParameters
    
    $result = ($CurrentValues.Ensure -eq $Ensure) -and ($CurrentValues.ServerRole -eq $ServerRole)
    
    $result
    
}


Export-ModuleMember -Function *-TargetResource

