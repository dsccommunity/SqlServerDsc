$currentPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Debug -Message "CurrentPath: $currentPath"

# DSC resource to manage SQL Server Instance Memory Dynamically or Statically

# Load Common Code
Import-Module $currentPath\..\..\xSQLServerHelper.psm1 -Verbose:$false -ErrorAction Stop

function ConnectSQL
{
    param
    (
        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [System.String]
        $SQLInstanceName = "MSSQLSERVER"
    )
    
    $null = [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.Smo')
    
    if($SQLInstanceName -eq "MSSQLSERVER")
    {
        $ConnectSQL = $SQLServer
    }
    else
    {
        $ConnectSQL = "$SQLServer\$SQLInstanceName"
    }

    Write-Verbose "Connecting to SQL $ConnectSQL"
    $SQL = New-Object Microsoft.SqlServer.Management.Smo.Server $ConnectSQL

    if($SQL)
    {
        Write-Verbose "Connected to SQL $ConnectSQL"
        $SQL
    }
    else
    {
        Write-Verbose "Failed connecting to SQL $ConnectSQL"
    }
}

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
        $MinMemory,

        [System.Int32]
        $MaxMemory,

        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [System.String]
        $SQLInstanceName= "MSSQLSERVER"
    )

        if(!$SQL)
        {
            $SQL = ConnectSQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName
        }

        if($SQL)
        {
            Write-Verbose "Getting Current Min and Max Server Memory Settings"
            $GetMinMemory = $sql.Configuration.MinServerMemory.ConfigValue
            $GetMaxMemory = $sql.Configuration.MaxServerMemory.ConfigValue
        }

        if ($GetMaxMemory -eq 2147483647)
        {
            $Ensure = "Absent"
        }
        else
        {
            $Ensure = "Present"
        }

        $returnValue = @{
                DynamicAlloc = $DynamicAlloc
                MinMemory = $MinMemory
                MaxMemory = $MaxMemory
                Ensure = $Ensure
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
        $Ensure,

        [parameter(Mandatory = $true)]
        [System.Boolean]
        $DynamicAlloc,

        [System.Int32]
        $MinMemory,

        [System.Int32]
        $MaxMemory,

        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [System.String]
        $SQLInstanceName= "MSSQLSERVER"
    )

    if(!$SQL)
    {
        $SQL = ConnectSQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName
    }

    If($SQL)
    {
        $serverMem = $sql.PhysicalMemory
        switch($Ensure)
        {
            "Absent"
            {
                If($Ensure -eq "Absent")
                {
                   $MaxMemory =2147483647
                   $MinMemory = 128
                } 
            }
            "Present"
            {       
                if ($DynamicAlloc)
                {
                    if ($serverMem -ge 128000) 
                    {
                        #Server mem - 10GB
                        $MaxMemory = $serverMem - 10000 
                    }
                    elseif ($serverMem -ge 32000 -and $serverMem -lt 128000) 
                    {
                        #Server mem - 4GB 
                        $MaxMemory = $serverMem - 4000
                    }
                    elseif ($serverMem -ge 16000)
                    {
                        #Server mem - 2GB 
                        $MaxMemory = $serverMem - 2000
                    }
                    else
                    {
                        #Server mem - 1GB 
                        $MaxMemory = $serverMem - 1000
                    }
                }
                else
                {
                    if (!$MaxMemory -xor !$MinMemory)
                    {
                        Throw "Dynamic Allocation is not set and Min and Max memory were not passed."
                        Exit
                    } 
                }
            }
        }
        try
        {
            Write-Verbose -message "Dynamic Alloc is $DynamicAlloc. MaxMem will be set to $MaxMemory."
            Write-Verbose -message "Server Memory is $serverMem and should be capped."
            $sql.Configuration.MaxServerMemory.ConfigValue = $MaxMemory
            if($MinMemory)
            {
                $sql.Configuration.MinServerMemory.ConfigValue = $MinMemory
            }
            $sql.alter()
        }
        catch
        {
            Write-Verbose -Message "Failed setting Min and Max SQL Memory"
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
        $MinMemory,

        [System.Int32]
        $MaxMemory,

        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [System.String]
        $SQLInstanceName= "MSSQLSERVER"
    )

    if(!$SQL)
    {
        $SQL = ConnectSQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName
    }

    if($SQL)
    {
        $GetMinMemory = $sql.Configuration.MinServerMemory.ConfigValue
        $GetMaxMemory = $sql.Configuration.MaxServerMemory.ConfigValue
    }

    switch($Ensure)
    {
        "Absent"
        {
            if ($GetMaxMemory  -eq 2147483647)
            {
                Write-Verbose -Message "Current Max Memory is $GetMaxMemory. Min Memory is $GetMinMemory"
                return $true
            }
            else 
            {
                Write-Verbose -Message "Current Max Memory is $GetMaxMemory. Min Memory is $GetMinMemory"
                return $false
            }
        }
        "Present"
        {      
       
             If ($DynamicAlloc)
             {
                 if ($GetMaxMemory  -eq 2147483647)
                 {
                     Write-Verbose -Message "Current Max Memory is $GetMaxMemory. Min Memory is $GetMinMemory"
                     return $false
                 }
                 else 
                 {
                     Write-Verbose -Message "Current Max Memory is $GetMaxMemory. Min Memory is $GetMinMemory"
                     return $true
                 }
             }
             else
             {
                 If($MinMemory -ne $GetMinMemory -or $MaxMemory -ne $GetMaxMemory)
                 {
                    Write-Verbose -Message "Current Max Memory is $GetMaxMemory. Min Memory is $GetMinMemory"
                    return $false
                 }
                 else
                 {
                    Write-Verbose -Message "Current Max Memory is $GetMaxMemory. Min Memory is $GetMinMemory"
                    return $true
                 }
             }
        }
    }
}


Export-ModuleMember -Function *-TargetResource

