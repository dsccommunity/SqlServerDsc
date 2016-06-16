# Load Common Code
Import-Module $PSScriptRoot\..\..\xSQLServerHelper.psm1 -Verbose:$false -ErrorAction Stop

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
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
        $CurrentMaxDop = $SQL.Configuration.MaxDegreeOfParallelism.ConfigValue
        If($CurrentMaxDop)
        {
             New-VerboseMessage -Message "MaxDop is $CurrentMaxDop"
        }
    }

    $returnValue = @{
        SQLInstanceName = $SQLInstanceName
        SQLServer = $SQLServer
        MaxDop = $CurrentMaxDop
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
        [parameter(Mandatory = $true)]
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
    
    $CurrentMaxDop = $SQL.Configuration.MaxDegreeOfParallelism.ConfigValue

    switch($Ensure)
    {
        "Present"
        {
            If($DynamicAlloc -eq $true)
            {
                $MaxDop = Get-MaxDopDynamic $SQL
                New-VerboseMessage -Message "Dynamic MaxDop is $MaxDop."
            }

            If ($CurrentMaxDop -eq $MaxDop)
            {
                New-VerboseMessage -Message "Current MaxDop is at Requested value $MaxDop."
                return $true
            }
            else 
            {
                New-VerboseMessage -Message "Current MaxDop is $CurrentMaxDop should be updated to $MaxDop"
                return $False
            }
        }

        "Absent"
        {
            If ($CurrentMaxDop -eq 0)
            {
                New-VerboseMessage -Message "Current MaxDop is at Requested value 0."
                return $true
            }
            else 
            {
                New-VerboseMessage -Message "Current MaxDop is $CurrentMaxDop should be updated to 0"
                return $False
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

    $NumCores = $SQL.Processors
    $NumProcs = ($SQL.AffinityInfo.NumaNodes | Measure-Object).Count

    if ($NumProcs -eq 1)
    {
        $MaxDop =  ($NumCores /2)
        $MaxDop=[Math]::Round( $MaxDop, [system.midpointrounding]::AwayFromZero)
    }
    elseif ($NumCores -ge 8)
    {
        $MaxDop = 8
    }
    else
    {
        $MaxDop = $NumCores
    }

    $MaxDop
}


Export-ModuleMember -Function *-TargetResource

