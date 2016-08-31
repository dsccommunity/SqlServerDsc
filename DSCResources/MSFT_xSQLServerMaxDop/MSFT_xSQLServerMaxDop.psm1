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
        [Parameter(Mandatory = $true)]
        [System.String]
        $SQLInstanceName,

        [System.String]
        $SQLServer = $env:COMPUTERNAME
    )

    if(!$SQL)
    {
        $SQL = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName
    }

    if($SQL)
    {
        $currentMaxDop = $SQL.Configuration.MaxDegreeOfParallelism.ConfigValue
        If($currentMaxDop)
        {
             New-VerboseMessage -Message "MaxDop is $currentMaxDop"
        }
    }

    $returnValue = @{
        SQLInstanceName = $SQLInstanceName
        SQLServer = $SQLServer
        MaxDop = $currentMaxDop
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
        $SQLInstanceName,

        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = 'Present',

        [System.Boolean]
        $DynamicAlloc = $false,

        [System.Int32]
        $MaxDop = 0
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
                If($DynamicAlloc -eq $true)
                {
                    $MaxDop = Get-MaxDopDynamic $SQL
                }
            }
            
            "Absent"
            {
                $MaxDop = 0
            }
        }

        try
        {
            $SQL.Configuration.MaxDegreeOfParallelism.ConfigValue = $MaxDop
            $SQL.alter()
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
        [Parameter(Mandatory = $true)]
        [System.String]
        $SQLInstanceName,

        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = 'Present',

        [System.Boolean]
        $DynamicAlloc = $false,

        [System.Int32]
        $MaxDop = 0
    )

    if(!$SQL)
    {
        $SQL = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName
    }
    
    $currentMaxDop = $SQL.Configuration.MaxDegreeOfParallelism.ConfigValue

    switch($Ensure)
    {
        "Present"
        {
            If($DynamicAlloc -eq $true)
            {
                $MaxDop = Get-MaxDopDynamic $SQL
                New-VerboseMessage -Message "Dynamic MaxDop is $MaxDop."
            }

            If ($currentMaxDop -eq $MaxDop)
            {
                New-VerboseMessage -Message "Current MaxDop is at Requested value $MaxDop."
                return $true
            }
            else 
            {
                New-VerboseMessage -Message "Current MaxDop is $currentMaxDop should be updated to $MaxDop"
                return $false
            }
        }

        "Absent"
        {
            If ($currentMaxDop -eq 0)
            {
                New-VerboseMessage -Message "Current MaxDop is at Requested value 0."
                return $true
            }
            else 
            {
                New-VerboseMessage -Message "Current MaxDop is $currentMaxDop should be updated to 0"
                return $false
            }
        }
    }
}

function Get-MaxDopDynamic
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param(
        $SQL
    )

    $numCores = $SQL.Processors
    $numProcs = ($SQL.AffinityInfo.NumaNodes | Measure-Object).Count

    if ($numProcs -eq 1)
    {
        $maxDop = ($numCores /2)
        $maxDop = [Math]::Round($maxDop, [system.midpointrounding]::AwayFromZero)
    }
    elseif ($numCores -ge 8)
    {
        $maxDop = 8
    }
    else
    {
        $maxDop = $numCores
    }

    $maxDop
}

Export-ModuleMember -Function *-TargetResource
