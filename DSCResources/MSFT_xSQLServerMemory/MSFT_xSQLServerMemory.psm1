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
        $minMemory = $sql.Configuration.MinServerMemory.ConfigValue
        $maxMemory = $sql.Configuration.MaxServerMemory.ConfigValue
    }

    $returnValue = @{
        SQLInstanceName = $SQLInstanceName
        SQLServer = $SQLServer
        MinMemory = $minMemory
        MaxMemory = $maxMemory
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
        $MaxMemory = 2147483647,

        [System.Int32]
        $MinMemory = 0
    )

    if(!$SQL)
    {
        $SQL = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName
    }

    If($SQL)
    {
        switch($Ensure)
        {
            "Absent"
            {
                $MaxMemory = 2147483647
                $MinMemory = 0
            }

            "Present"
            {
                if ($DynamicAlloc)
                {
                    $MaxMemory = Get-MaxMemoryDynamic $SQL.PhysicalMemory
                    $MinMemory = 128

                    New-VerboseMessage -Message "Dynamic Max Memory is $MaxMemory"
                }
            }
        }

        try
        {            
            $SQL.Configuration.MaxServerMemory.ConfigValue = $MaxMemory
            $SQL.Configuration.MinServerMemory.ConfigValue = $MinMemory
            $SQL.alter()

            New-VerboseMessage -Message "SQL Server Memory has been capped to $MaxMemory. MinMemory set to $MinMemory."
        }
        catch
        {
            New-VerboseMessage -Message "Failed setting Min and Max SQL Memory"
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
        $MaxMemory = 0,

        [System.Int32]
        $MinMemory
    )

    if(!$SQL)
    {
        $SQL = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName
    }

    if($SQL)
    {
        $getMinMemory = $sql.Configuration.MinServerMemory.ConfigValue
        $getMaxMemory = $sql.Configuration.MaxServerMemory.ConfigValue
    }

    switch($Ensure)
    {
        "Absent"
        {
            if ($getMaxMemory -ne 2147483647)
            {
                New-VerboseMessage -Message "Current Max Memory is $getMaxMemory. Expected 2147483647"
                return $false
            }

            if ($getMinMemory -ne 0)
            {
                New-VerboseMessage -Message "Current Min Memory is $getMinMemory. Expected 0"
                return $false
            }
        }

        "Present"
        {
            if ($DynamicAlloc)
            {
                $MaxMemory = Get-MaxMemoryDynamic $SQL.PhysicalMemory
                $MinMemory = 128

                New-VerboseMessage -Message "Dynamic Max Memory is $MaxMemory"
            }

            if($MaxMemory -ne $getMaxMemory)
            {
                New-VerboseMessage -Message "Current Max Memory is $getMaxMemory, expected $MaxMemory"
                return $false
            }

            if($PSBoundParameters.ContainsKey('MinMemory'))
            {
                if($MinMemory -ne $getMinMemory)
                {
                    New-VerboseMessage -Message "Current Min Memory is $getMinMemory, expected $MinMemory"
                    return $false
                }
            }
        }
    }

    $true
}

function Get-MaxMemoryDynamic
{
    param(
        $PhysicalMemory
    )

    if ($PhysicalMemory -ge 128000)
    {
        #Server mem - 10GB
        $maxMemory = $PhysicalMemory - 10000 
    }
    elseif ($PhysicalMemory -ge 32000 -and $PhysicalMemory -lt 128000) 
    {
        #Server mem - 4GB 
        $maxMemory = $PhysicalMemory - 4000
    }
    elseif ($PhysicalMemory -ge 16000)
    {
        #Server mem - 2GB 
        $maxMemory = $PhysicalMemory - 2000
    }
    else
    {
        #Server mem - 1GB 
        $maxMemory = $PhysicalMemory - 1000
    }

    $maxMemory
}

Export-ModuleMember -Function *-TargetResource
