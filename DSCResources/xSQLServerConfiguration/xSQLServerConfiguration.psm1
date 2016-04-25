Import-Module SQLPS

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
        [string]
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
        [string]
        $Ensure = 'Present'
    )

    $option = Get-SqlServerConfigurationOption $InstanceName $OptionName

    $option.ConfigValue = $OptionValue
    $svr.Configuration.Alter()
    if ($option.IsDynamic -eq $true)
    {  
        Write-Verbose "Configuration option has been updated."
    }
    else
    {
        Write-Verbose "Configuration option will be updated when SQL Server is restarted."
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
        [string]
        $Ensure = 'Present'
    )

    $option = Get-SqlServerConfigurationOption $InstanceName $OptionName

    return ($option.ConfigValue -eq $OptionValue)
}

Get-SqlServerConfigurationOption
{
    [CmdletBinding()]
    [OutputType([Microsoft.SqlServer.Management.Smo.ConfigProperty])]
    param(
        [parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [parameter(Mandatory = $true)]
        [System.String]
        $OptionName
    )

    $InstanceName = $InstanceName.ToUpper()
    $instaceNameSQLPS = $InstanceName

    if($InstanceName -eq '.' -or $InstanceName -eq 'LOCALHOST' -or $InstanceName -eq 'MSSQLSERVER')
    {
        $instaceNameSQLPS = 'DEFAULT'
    }

    $svr = Get-Item "SQLSERVER:\sql\$env:COMPUTERNAME\$instaceNameSQLPS"
    $option = $svr.Configuration.Properties | where {$_.DisplayName -eq $optionName}

    if(!$option)
    {
        throw "Specified option '$OptionName' was not found!"
    }

    return $option
}

Export-ModuleMember -Function *-TargetResource
