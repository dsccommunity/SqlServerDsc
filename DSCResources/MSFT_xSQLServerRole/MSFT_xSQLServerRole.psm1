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

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure
    )

    if(!$SQL)
    {
        $SQL = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName
    }
    
    if($SQL)
    {
        if($SQL.Roles[$RoleName])
        {
            Write-Verbose "Server role $RoleName is present"
            $Ensure = "Present"
        }
        else
        {
            Write-Verbose "Server role $RoleName is absent"
            $Ensure = "Absent"
        }
    }

    $returnValue = @{
        RoleName = $RoleName
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

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure
    )

    if(!$SQL)
    {
        $SQL = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName
    }
    
    if($SQL)
    {
        if($Ensure -eq "Present")
        {
            Write-Verbose "Creating server role $RoleName"
            $null = [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.Smo')
            $role = New-Object Microsoft.SqlServer.Management.Smo.ServerRole $SQL,$RoleName
            $role.Create()
        }
        else
        {
            Write-Verbose "Droping server role $RoleName"
            $SQL.Roles[$RoleName].Drop()
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

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure
    )

    $testObject = Get-TargetResource @PSBoundParameters

    if($testObject.RoleName -eq $RoleName -and $testObject.Ensure -eq $Ensure)
    {
        return $true
    }
    else
    {
        return $false
    }
}

Export-ModuleMember -Function *-TargetResource
