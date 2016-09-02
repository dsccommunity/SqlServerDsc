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
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [Parameter(Mandatory = $true)]
        [ValidateSet("bulkadmin","dbcreator","diskadmin","processadmin","public","securityadmin","serveradmin","setupadmin","sysadmin")]
        [System.String[]]
        $serverRole,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SQLServer,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SQLInstanceName
    )

    if(!$sql)
    {
        $sql = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName
    }

    if($sql)
    {
        Write-Verbose "Getting SQL Server roles for $Name on SQL Server $SQLServer."
        $sqlRole = $sql.Roles
        if($sqlRole)
        {
            ForEach ($srvRole in $serverRole)
            {
                if($sqlRole[$srvRole])
                {
                    $membersInRole = $sqlRole[$srvRole].EnumMemberNames()             
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
        serverRole = $serverRole
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
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [Parameter(Mandatory = $true)]
        [ValidateSet("bulkadmin","dbcreator","diskadmin","processadmin","public","securityadmin","serveradmin","setupadmin","sysadmin")]
        [System.String[]]
        $serverRole,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SQLServer,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SQLInstanceName
    )

    if(!$sql)
    {
        $sql = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName
    }

    if($sql)
    {
        switch($Ensure)
        {
            "Present"
            {
                try
                {
                    $sqlRole = $sql.Roles
                    ForEach ($srvRole in $serverRole)
                    {
                        Write-Verbose "Adding SQL login $Name in role $srvRole"
                        $sqlRole[$srvRole].AddMember($Name)
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
                    $sqlRole = $sql.Roles
                    ForEach ($srvRole in $serverRole)
                    {
                        Write-Verbose "Deleting SQL login $Name in role $srvRole"
                        $sqlRole[$srvRole].DropMember($Name)
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
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [Parameter(Mandatory = $true)]
        [ValidateSet("bulkadmin","dbcreator","diskadmin","processadmin","public","securityadmin","serveradmin","setupadmin","sysadmin")]
        [System.String[]]
        $serverRole,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SQLServer,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SQLInstanceName
    )

    Write-Verbose -Message "Testing SQL roles for login $Name"
    $currentValues = Get-TargetResource @PSBoundParameters
    
    $result = ($currentValues.Ensure -eq $Ensure) -and ($currentValues.serverRole -eq $serverRole)
    $result    
}

Export-ModuleMember -Function *-TargetResource

