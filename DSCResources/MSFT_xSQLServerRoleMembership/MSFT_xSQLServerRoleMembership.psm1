$currentPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Debug -Message "CurrentPath: $currentPath"

# Load Common Code
Import-Module $currentPath\..\..\xSQLServerHelper.psm1 -Verbose:$false -ErrorAction Stop

# DSC resource to manage SQL Server roles

# NOTE: This resource requires WMF5 and PsDscRunAsCredential

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $RoleName,

        [parameter(Mandatory = $true)]
        [System.String]
        $Login,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

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
        if($SQL.Roles[$RoleName].EnumMemberNames().Contains($Login))
        {
            Write-Verbose "SQL Server role $RoleName contains member $Login"
            $Ensure = "Present"
        }
        else
        {
            Write-Verbose "SQL Server role $RoleName does not contain member $Login"
            $Ensure = "Absent"
        }
    }


    $returnValue = @{
        RoleName = $RoleName
        Login = $Login
        Ensure = $Ensure
    }

    $returnValue
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $RoleName,

        [parameter(Mandatory = $true)]
        [System.String]
        $Login,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

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
        if($Ensure -eq "Present")
        {
            if(-not $SQL.Roles[$RoleName].EnumMemberNames().Contains($Login))
            {
                Write-Verbose "Adding login $Login to role $RoleName"
                $SQL.Roles[$RoleName].AddMember($Login)
            }
        }
        else
        {
            if($SQL.Roles[$RoleName].EnumMemberNames().Contains($Login))
            {
                Write-Verbose "Droping login $Login from role $RoleName"
                $SQL.Roles[$RoleName].DropMember($Login)
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
        $RoleName,

        [parameter(Mandatory = $true)]
        [System.String]
        $Login,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [System.String]
        $SQLInstanceName = "MSSQLSERVER"
    )

    $testObject = Get-TargetResource @PSBoundParameters
    
    if($testObject.RoleName -eq $RoleName -and $testObject.Login -eq $Login -and $testObject.Ensure -eq $Ensure)
    {
        return $true
    }
    else
    {
        return $false
    }
}

Export-ModuleMember -Function *-TargetResource
