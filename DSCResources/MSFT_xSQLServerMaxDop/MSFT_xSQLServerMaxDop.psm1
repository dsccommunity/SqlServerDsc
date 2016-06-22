$currentPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Verbose -Message "CurrentPath: $currentPath"

# Load Common Code
Import-Module $currentPath\..\..\xSQLServerHelper.psm1 -Verbose:$false -ErrorAction Stop

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
        [System.Boolean]
        $DynamicAlloc,

        [System.Int32]
        $MaxDop,

        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [System.String]
        $SQLInstanceName= "MSSQLSERVER"
    )

    if(!$SQL)
    {
        $SQL = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName
    }

    if($SQL)
    {
        $GetMaxDop = $sql.Configuration.MaxDegreeOfParallelism.ConfigValue
        If($GetMaxDop)
        {
             New-VerboseMessage -Message "MaxDop is $GetMaxDop"
        }
        Switch ($Ensure)
        {
            "Present"
            {
                if ($GetMaxDop -eq 0)
                {$EnsureResult = $false}
                else
                {$EnsureResult = $true}
            }
            "Absent"
            {
                if ($GetMaxDop -eq 0)
                {$EnsureResult = $true}
                else
                {$EnsureResult =$false}
            }
    }

    $returnValue = @{
            Ensure = $EnsureResult
            DynamicAlloc =$DynamicAlloc
            MaxDop = $GetMaxDop 
            }
    $returnValue
}
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [parameter(Mandatory = $true)]
        [System.Boolean]
        $DynamicAlloc,

        [System.Int32]
        $MaxDop,

        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [System.String]
        $SQLInstanceName= "MSSQLSERVER"
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
                If($DynamicAlloc -eq $True)
                {
                    $NumCores = $SQL.Processors
                    $NumProcs = ($sql.AffinityInfo.NumaNodes | Measure-Object).Count
                    if ($NumProcs -eq 1) 
                    {
                        $MaxDop =  ($NumCores /2)
                        $MaxDop=[math]::round( $MaxDop,[system.midpointrounding]::AwayFromZero)
                    }
                    elseif ($NumCores -ge 8) 
                    {
                        $MaxDop = 8
                    }
                    else
                    {
                        $MaxDop = $NumCores
                    }
                } 
            }
                
            "Absent"
            {
                $MaxDop = 0
            }

            }

            try
            {
                $sql.Configuration.MaxDegreeOfParallelism.ConfigValue =$MaxDop
                $sql.alter()
                New-VerboseMessage -Message "Set MaxDop to $MaxDop"
            }
            catch
            {
                New-VerboseMessage -Message "Failed setting MaxDop to $MaxDop"
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
        $Ensure,

        [parameter(Mandatory = $true)]
        [System.Boolean]
        $DynamicAlloc,

        [System.Int32]
        $MaxDop,

        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [System.String]
        $SQLInstanceName= "MSSQLSERVER"
    )

    if(!$SQL)
    {
        $SQL = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName
    }
    
    $GetMaxDop = $SQL.Configuration.MaxDegreeOfParallelism.ConfigValue
    switch($Ensure)
    {
        "Present"
        {
            If ($DynamicAlloc)
            {
                
                If ($GetMaxDop -eq 0)
                {
                    New-VerboseMessage -Message "Current MaxDop is $GetMaxDop should be updated to $MaxDop"
                    return $false
                }
                else 
                {
                    New-VerboseMessage -Message "Current MaxDop is configured at $GetMaxDop."
                    return $True
                }
            }
            else
            {
                If ($GetMaxDop -eq $MaxDop)
                {
                    New-VerboseMessage -Message "Current MaxDop is at Requested value. Do nothing." 
                    return $true
                }
                else 
                {
                    New-VerboseMessage -Message "Current MaxDop is $GetMaxDop should be updated to $MaxDop"
                    return $False
                }
            }
        }
        "Absent" 
        {
            If ($GetMaxDop -eq 0)
            {
                New-VerboseMessage -Message "Current MaxDop is at Requested value. Do nothing." 
                return $true
            }
            else 
            {
                New-VerboseMessage -Message "Current MaxDop is $GetMaxDop should be updated"
                return $False
            }
        }
    }
}


Export-ModuleMember -Function *-TargetResource

