$script:sqlServerDscHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\SqlServerDsc.Common'
$script:resourceHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DscResource.Common'

Import-Module -Name $script:sqlServerDscHelperModulePath
Import-Module -Name $script:resourceHelperModulePath

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

<#
    .SYNOPSIS
        Returns the current state of the SQL Server alias.

    .PARAMETER Name
        The name of Alias (e.g. svr01\\inst01).
#>
function Get-TargetResource
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('SqlServerDsc.AnalyzerRules\Measure-CommandsNeededToLoadSMO', '', Justification='Neither command is needed for this resource since the resource modifies registry')]
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name
    )

    $returnValue = @{
        Name              = [System.String] $Name
        Protocol          = [System.String] ''
        ServerName        = [System.String] $null
        TcpPort           = [System.UInt16] 0
        UseDynamicTcpPort = [System.Boolean] $false
        PipeName          = [System.String] ''
        Ensure            = [System.String] 'Absent'
    }

    $protocolTcp = 'DBMSSOCN'
    $protocolNamedPipes = 'DBNMPNTW'

    Write-Verbose -Message (
        $script:localizedData.GetClientAlias -f $Name
    )

    $itemValue = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo' `
        -Name $Name `
        -ErrorAction SilentlyContinue

    $isWow6432Node = $false

    if (((Get-CimInstance -ClassName win32_OperatingSystem).OSArchitecture) -eq '64-bit')
    {
        Write-Verbose -Message (
            $script:localizedData.OSArchitecture64Bit -f $Name
        )

        $isWow6432Node = $true
        $itemValueWow6432Node = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\MSSQLServer\Client\ConnectTo' `
            -Name $Name `
            -ErrorAction SilentlyContinue
    }

    if ((-not $isWow6432Node -and $null -ne $itemValue ) -or `
        (($null -ne $itemValue -and $null -ne $itemValueWow6432Node) -and `
            ($isWow6432Node -and $itemValueWow6432Node."$Name" -eq $itemValue."$Name")))
    {
        $itemConfig = $itemValue."$Name" | ConvertFrom-Csv -Header 'Protocol', 'ServerName', 'TcpPort'
        if ($itemConfig)
        {
            if ($itemConfig.Protocol -eq $protocolTcp)
            {
                $returnValue.Ensure = 'Present'
                $returnValue.Protocol = 'TCP'
                $returnValue.ServerName = $itemConfig.ServerName
                if ($itemConfig.TcpPort)
                {
                    $returnValue.TcpPort = $itemConfig.TcpPort
                    $returnValue.UseDynamicTcpPort = $false
                }
                else
                {
                    $returnValue.UseDynamicTcpPort = $true
                    $returnValue.TcpPort = 0
                }
            }
            elseif ($itemConfig.Protocol -eq $protocolNamedPipes)
            {
                $returnValue.Ensure = 'Present'
                $returnValue.Protocol = 'NP'
                $returnValue.PipeName = $itemConfig.ServerName
            }
        }
        else
        {
            $returnValue.Ensure = 'Absent'
        }
    }
    else
    {
        $returnValue.Ensure = 'Absent'
    }

    $returnValue
}

<#
    .SYNOPSIS
        Sets the desired state of the SQL Server alias.

    .PARAMETER Name
        The name of Alias (e.g. svr01\\inst01).

    .PARAMETER Protocol
        Protocol to use when connecting. Valid values are 'TCP' or 'NP' (Named Pipes).
        Default value is 'TCP'.

    .PARAMETER ServerName
        The SQL Server you are aliasing (the NetBIOS name or FQDN).

    .PARAMETER TcpPort
        The TCP port the SQL Server instance is listening on. Only used when protocol
        is set to 'TCP'. Default value is port 1433.

    .PARAMETER UseDynamicTcpPort
        The UseDynamicTcpPort specify that the Net-Library will determine the port
        dynamically. The port specified in Port number will not be used. Default
        value is $false.

    .PARAMETER Ensure
        Determines whether the alias should be added or removed. Default value is
        'Present'.
#>
function Set-TargetResource
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('SqlServerDsc.AnalyzerRules\Measure-CommandsNeededToLoadSMO', '', Justification='Neither command is needed for this resource since the resource modifies registry')]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter()]
        [ValidateSet('TCP', 'NP')]
        [System.String]
        $Protocol = 'TCP',

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName,

        [Parameter()]
        [System.UInt16]
        $TcpPort = 1433,

        [Parameter()]
        [System.Boolean]
        $UseDynamicTcpPort = $false,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    if ($Protocol -eq 'NP')
    {
        $itemValue = "DBNMPNTW,\\$ServerName\PIPE\sql\query"
    }

    if ($Protocol -eq 'TCP')
    {
        $itemValue = "DBMSSOCN,$ServerName"
        if (-not $UseDynamicTcpPort)
        {
            $itemValue += ",$TcpPort"
        }
    }

    $registryPath = 'HKLM:\SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo'
    $registryPathWow6432Node = 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\MSSQLServer\Client\ConnectTo'

    if ($Ensure -eq 'Present')
    {
        Write-Verbose -Message (
            $script:localizedData.AddClientAlias64Bit -f $Name
        )

        if (-not (Test-Path -Path $registryPath))
        {
            New-Item -Path $registryPath -Force | Out-Null
        }

        Set-ItemProperty -Path $registryPath -Name $Name -Value $itemValue | Out-Null

        # If this is a 64-bit OS then also update Wow6432Node
        if (((Get-CimInstance -ClassName win32_OperatingSystem).OSArchitecture) -eq '64-bit')
        {
            Write-Verbose -Message (
                $script:localizedData.AddClientAlias32Bit -f $Name
            )

            if (-not (Test-Path -Path $registryPathWow6432Node))
            {
                New-Item -Path $registryPathWow6432Node -Force | Out-Null
            }

            Set-ItemProperty -Path $registryPathWow6432Node -Name $Name -Value $itemValue | Out-Null
        }
    }

    if ($Ensure -eq 'Absent')
    {
        Write-Verbose -Message (
            $script:localizedData.RemoveClientAlias64Bit -f $Name
        )

        if (Test-Path -Path $registryPath)
        {
            Remove-ItemProperty -Path $registryPath -Name $Name
        }

        # If this is a 64-bit OS then also remove from Wow6432Node
        if (((Get-CimInstance -ClassName win32_OperatingSystem).OSArchitecture) -eq '64-bit' `
                -and (Test-Path -Path $registryPathWow6432Node))
        {
            Write-Verbose -Message (
                $script:localizedData.RemoveClientAlias32Bit -f $Name
            )

            Remove-ItemProperty -Path $registryPathWow6432Node -Name $Name
        }
    }
}

<#
    .SYNOPSIS
        Determines the desired state of the SQL Server alias.

    .PARAMETER Name
        The name of Alias (e.g. svr01\\inst01).

    .PARAMETER Protocol
        Protocol to use when connecting. Valid values are 'TCP' or 'NP' (Named Pipes).
        Default value is 'TCP'.

    .PARAMETER ServerName
        The SQL Server you are aliasing (the NetBIOS name or FQDN).

    .PARAMETER TcpPort
        The TCP port the SQL Server instance is listening on. Only used when protocol
        is set to 'TCP'. Default value is port 1433.

    .PARAMETER UseDynamicTcpPort
        The UseDynamicTcpPort specify that the Net-Library will determine the port
        dynamically. The port specified in Port number will not be used. Default
        value is $false.

    .PARAMETER Ensure
        Determines whether the alias should be added or removed. Default value is
        'Present'.
#>
function Test-TargetResource
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('SqlServerDsc.AnalyzerRules\Measure-CommandsNeededToLoadSMO', '', Justification='Neither command is needed for this resource since the resource modifies registry')]
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter()]
        [ValidateSet('TCP', 'NP')]
        [System.String]
        $Protocol = 'TCP',

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName,

        [Parameter()]
        [System.UInt16]
        $TcpPort = 1433,

        [Parameter()]
        [System.Boolean]
        $UseDynamicTcpPort = $false,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    Write-Verbose -Message (
        $script:localizedData.TestingConfiguration -f $Name
    )

    $result = $false

    $parameters = @{
        Name = $PSBoundParameters.Name
    }

    $currentValues = Get-TargetResource @parameters

    if ($Ensure -eq $currentValues.Ensure)
    {
        if ($Ensure -eq 'Absent')
        {
            Write-Verbose -Message (
                $script:localizedData.ClientAliasMissing -f $Name
            )

            $result = $true
        }
        else
        {
            Write-Verbose -Message (
                $script:localizedData.ClientAliasPresent -f $Name
            )

            if ($Protocol -eq $currentValues.Protocol)
            {
                if ($Protocol -eq 'NP' -and
                    $currentValues.PipeName -eq "\\$ServerName\PIPE\sql\query")
                {
                    $result = $true
                }
                elseif ($Protocol -eq 'TCP' -and
                    $UseDynamicTcpPort -and
                    $currentValues.UseDynamicTcpPort -eq $UseDynamicTcpPort -and
                    $currentValues.ServerName -eq $ServerName)
                {
                    $result = $true
                }
                elseif ($Protocol -eq 'TCP' -and
                    -not $UseDynamicTcpPort -and
                    $currentValues.UseDynamicTcpPort -eq $UseDynamicTcpPort -and
                    $currentValues.ServerName -eq $ServerName -and
                    $currentValues.TcpPort -eq $TcpPort)
                {
                    $result = $true
                }
            }
        }
    }

    if ($result)
    {
        Write-Verbose -Message (
            $script:localizedData.InDesiredState -f $Name
        )
    }
    else
    {
        Write-Verbose -Message (
            $script:localizedData.NotInDesiredState -f $Name
        )
    }

    return $result
}
