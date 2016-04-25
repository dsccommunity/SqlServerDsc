Function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param(
        [parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [parameter(Mandatory = $true)]
        [System.String]
        $OptionName,

        [parameter(Mandatory = $true)]
        [System.Int32]
        $OptionValue,

        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    if(Test-TargetResource $InstanceName $OptionName $OptionValue $Ensure)
    {
        $Ensure = 'Present'
    }
    else
    {
        $Ensure = 'Absent'
    }
    
    $returnValue = @{
        InstanceName = $InstanceName
        OptionName = $OptionName
        OptionValue = $OptionValue
        Ensure = $Ensure
    }
    
    return $returnValue
}

Function Set-TargetResource
{
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [parameter(Mandatory = $true)]
        [System.String]
        $OptionName,

        [parameter(Mandatory = $true)]
        [System.Int32]
        $OptionValue,

        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    $sqlServer = Get-SqlServerObject $InstanceName

    $option = $sqlServer.Configuration.Properties | where {$_.DisplayName -eq $optionName}

    if(!$option)
    {
        throw "Specified option '$OptionName' was not found!"
    }

    $option.ConfigValue = $OptionValue
    $sqlServer.Configuration.Alter()
    if ($option.IsDynamic -eq $true)
    {  
        Write-Verbose "Configuration option has been updated."
    }
    else
    {
        Write-Warning "Configuration option will be updated when SQL Server is restarted."
    }
}

Function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param(
        [parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [parameter(Mandatory = $true)]
        [System.String]
        $OptionName,

        [parameter(Mandatory = $true)]
        [System.Int32]
        $OptionValue,

        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    Write-Verbose "OptionName: $OptionName"
    Write-Verbose "OptionValue: $OptionValue"

    $sqlServer = Get-SqlServerObject $InstanceName
    $option = $sqlServer.Configuration.Properties | where {$_.DisplayName -eq $optionName}
    if(!$option)
    {
        throw "Specified option '$OptionName' was not found!"
    }
        
    Write-Verbose "ConfigValue: $($option.ConfigValue)"

    return ($option.ConfigValue -eq $OptionValue)
}

Function Get-SqlServerMajorVersion
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param(
        [parameter(Mandatory = $true)]
        [System.String]
        $InstanceName
    )

    $instanceId = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL").$InstanceName
    $sqlVersion = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$instanceId\Setup").Version
    $sqlMajorVersion = $sqlVersion.Split(".")[0]
    if (!$sqlMajorVersion)
    {
        throw "Unable to detect version for sql server instance: $InstanceName!"
    }
    return $sqlMajorVersion
}

Function Get-SqlServerObject
{
    param(
        [parameter(Mandatory = $true)]
        [System.String]
        $InstanceName
    )

    if($InstanceName -eq "MSSQLSERVER")
    {
        $connectSQL = $env:COMPUTERNAME
    }
    else
    {
        $connectSQL = "$($env:COMPUTERNAME)\$InstanceName"
    }

    $dom_set = [AppDomain]::CreateDomain("xSQLServerConfiguration_Set_$InstanceName")
    $sqlMajorVersion = Get-SqlServerMajorVersion $InstanceName
    $smo = $dom_set.Load("Microsoft.SqlServer.Smo, Version=$sqlMajorVersion.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91")

    $sqlServer = new-object $smo.GetType("Microsoft.SqlServer.Management.Smo.Server") $connectSQL

    if(!$sqlServer)
    {
        throw "Unable to connect to sql instance: $InstanceName"
    }

    return $sqlServer
}

Export-ModuleMember -Function *-TargetResource
