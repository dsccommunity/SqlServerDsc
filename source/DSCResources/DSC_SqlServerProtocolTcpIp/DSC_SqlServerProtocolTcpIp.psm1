$script:sqlServerDscHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\SqlServerDsc.Common'
$script:resourceHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DscResource.Common'

Import-Module -Name $script:sqlServerDscHelperModulePath
Import-Module -Name $script:resourceHelperModulePath

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

<#
    .SYNOPSIS
        Returns the current state of the SQL Server TCP/IP protocol IP address
        group for the specified SQL Server instance.

    .PARAMETER InstanceName
        Specifies the name of the SQL Server instance to enable the protocol for.

    .PARAMETER IpAddressGroup
        Specifies the name of the IP address group in the TCP/IP protocol, e.g.
        'IP1', 'IP2' etc., or 'IPAll'.

    .PARAMETER ServerName
        Specifies the host name of the SQL Server to be configured. If the
        SQL Server belongs to a cluster or availability group specify the host
        name for the listener or cluster group. Default value is $env:COMPUTERNAME.

    .PARAMETER SuppressRestart
        If set to $true then the any attempt by the resource to restart the service
        is suppressed. The default value is $false.

    .PARAMETER RestartTimeout
        Timeout value for restarting the SQL Server services. The default value
        is 120 seconds.

    .NOTES
        The parameters SuppressRestart and RestartTimeout are part of the function
        Get-TargetResource to be able to return the value that the configuration
        have set, or the default values if not. If they weren't passed to the
        function Get-TargetResource we would have to always return $null which
        would indicate that they are not set at all.

        Thought this function should throw an exception if the address group is
        missing, but voted against it since run Test-DscConfiguration before
        running a configuration (that would configure NICs) would then fail.
        Instead choose to output a warning message indicating that the current
        state cannot be evaluated.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $IpAddressGroup,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = $env:COMPUTERNAME,

        [Parameter()]
        [System.Boolean]
        $SuppressRestart = $false,

        [Parameter()]
        [System.UInt16]
        $RestartTimeout = 120
    )

    $IpAddressGroup = Convert-IpAdressGroupCasing -IpAddressGroup $IpAddressGroup

    $returnValue = @{
        InstanceName       = $InstanceName
        IpAddressGroup     = $IpAddressGroup
        ServerName         = $ServerName
        SuppressRestart    = $SuppressRestart
        RestartTimeout     = $RestartTimeout
        Enabled            = $false
        IPAddress          = $null
        UseTcpDynamicPort  = $false
        TcpPort            = $null
        IsActive           = $false
        AddressFamily      = $null
        TcpDynamicPort     = $null
    }

    Write-Verbose -Message (
        $script:localizedData.GetCurrentState -f $IpAddressGroup, $InstanceName, $ServerName
    )

    Import-SQLPSModule

    <#
        Must connect to the local machine name because $ServerName can point
        to a cluster instance or availability group listener.
    #>
    $getServerProtocolObjectParameters = @{
        ServerName   = $env:COMPUTERNAME
        Instance     = $InstanceName
        ProtocolName = 'TcpIp'
    }

    $serverProtocolProperties = Get-ServerProtocolObject @getServerProtocolObjectParameters

    if ($serverProtocolProperties)
    {
        if ($IpAddressGroup -in $serverProtocolProperties.IPAddresses.Name)
        {
            $ipAddressGroupObject = $serverProtocolProperties.IPAddresses[$IpAddressGroup]

            # Values for all IP adress groups.
            $currentTcpPort = $ipAddressGroupObject.IPAddressProperties['TcpPort'].Value
            $currentTcpDynamicPort = $ipAddressGroupObject.IPAddressProperties['TcpDynamicPorts'].Value

            # Get the current state of TcpDynamicPort.
            if (-not (
                [System.String]::IsNullOrEmpty($currentTcpDynamicPort) `
                    -or [System.String]::IsNullOrWhiteSpace($currentTcpDynamicPort)
                )
            )
            {
                $returnValue.UseTcpDynamicPort = $true
                $returnValue.TcpDynamicPort = $currentTcpDynamicPort
            }

            # Get the current state of TcpPort.
            if (-not (
                    [System.String]::IsNullOrEmpty($currentTcpPort) `
                        -or [System.String]::IsNullOrWhiteSpace($currentTcpPort)
                )
            )
            {
                $returnValue.TcpPort = $currentTcpPort
            }

            # Values for all individual IP adress groups.
            switch ($IpAddressGroup)
            {
                'IPAll'
                {
                    <#
                        Left blank intentionally. There are no individual IP address
                        properties for the IP address group 'IPAll'.
                    #>
                }

                Default
                {
                    $returnValue.AddressFamily = $ipAddressGroupObject.IPAddress.AddressFamily
                    $returnValue.IPAddress = $ipAddressGroupObject.IPAddress.IPAddressToString
                    $returnValue.Enabled = $ipAddressGroupObject.IPAddressProperties['Enabled'].Value
                    $returnValue.IsActive = $ipAddressGroupObject.IPAddressProperties['Active'].Value
                }
            }
        }
        else
        {
            <#
                The IP address groups are created automatically so if this happens
                there is something wrong with the network interfaces on the node
                that this resource can not solve.
            #>
            Write-Warning -Message (
                $script:localizedData.MissingIpAddressGroup -f $IpAddressGroup
            )
        }
    }

    return $returnValue
}

<#
    .SYNOPSIS
        Sets the desired state of the SQL Server TCP/IP protocol IP address
        group for the specified SQL Server instance.

    .PARAMETER InstanceName
        Specifies the name of the SQL Server instance to enable the protocol for.

    .PARAMETER IpAddressGroup
        Specifies the name of the IP address group in the TCP/IP protocol, e.g.
        'IP1', 'IP2' etc., or 'IPAll'.

    .PARAMETER ServerName
        Specifies the host name of the SQL Server to be configured. If the SQL
        Server belongs to a cluster or availability group specify the host name
        for the listener or cluster group. Default value is `$env:COMPUTERNAME`.

    .PARAMETER Enabled
        Specified if the IP address group should be enabled or disabled. Only used if
        the IP address group is not set to 'IPAll'. If not specified, the existing
        value will not be changed.

    .PARAMETER IPAddress
        Specifies the IP address for the IP adress group. Only used if the IP address
        group is not set to 'IPAll'. If not specified, the existing value will not be
        changed.

    .PARAMETER UseTcpDynamicPort
        Specifies whether the SQL Server instance should use a dynamic port. If
        not specified the existing value will not be changed. This parameter is
        not allowed to be used at the same time as the parameter TcpPort.

    .PARAMETER TcpPort
        Specifies the TCP port(s) that SQL Server should be listening on. If the
        IP address should listen on more than one port, list all ports as a string
        value with the port numbers separated with a comma, e.g. '1433,1500,1501'.
        This parameter is limited to 2047 characters. If not specified, the existing
        value will not be changed.This parameter is not allowed to be used at the
        same time as the parameter UseTcpDynamicPort.

    .PARAMETER SuppressRestart
        If set to $true then the any attempt by the resource to restart the service
        is suppressed. The default value is $false.

    .PARAMETER RestartTimeout
        Timeout value for restarting the SQL Server services. The default value
        is 120 seconds.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $IpAddressGroup,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = $env:COMPUTERNAME,

        [Parameter()]
        [System.Boolean]
        $Enabled,

        [Parameter()]
        [System.String]
        $IPAddress,

        [Parameter()]
        [System.Boolean]
        $UseTcpDynamicPort,

        [Parameter()]
        [System.String]
        $TcpPort,

        [Parameter()]
        [System.Boolean]
        $SuppressRestart = $false,

        [Parameter()]
        [System.UInt16]
        $RestartTimeout = 120
    )

    $IpAddressGroup = Convert-IpAdressGroupCasing -IpAddressGroup $IpAddressGroup

    $protocolNameProperties = Get-ProtocolNameProperties -ProtocolName $ProtocolName

    <#
        Compare the current state against the desired state. Calling this will
        also import the necessary module to later call Get-ServerProtocolObject
        which uses the SMO class ManagedComputer.
    #>
    $propertyState = Compare-TargetResourceState @PSBoundParameters

    # Get all properties that are not in desired state.
    $propertiesNotInDesiredState = $propertyState.Where( { -not $_.InDesiredState })

    if ($propertiesNotInDesiredState.Count -gt 0)
    {
        Write-Verbose -Message (
            $script:localizedData.SetDesiredState -f $protocolNameProperties.DisplayName, $InstanceName
        )

        <#
            Must connect to the local machine name because $ServerName can point
            to a cluster instance or availability group listener.
        #>
        $getServerProtocolObjectParameters = @{
            ServerName   = $env:COMPUTERNAME
            Instance     = $InstanceName
            ProtocolName = $ProtocolName
        }

        $serverProtocolProperties = Get-ServerProtocolObject @getServerProtocolObjectParameters

        if ($serverProtocolProperties)
        {
            $isRestartNeeded = $false

            # Check if Enable property need updating.
            if ($propertiesNotInDesiredState.Where( { $_.ParameterName -eq 'Enabled' }))
            {
                $serverProtocolProperties.IsEnabled = $Enabled

                if ($Enabled)
                {
                    Write-Verbose -Message (
                        $script:localizedData.ProtocolHasBeenEnabled -f $protocolNameProperties.DisplayName, $InstanceName
                    )
                }
                else
                {
                    Write-Verbose -Message (
                        $script:localizedData.ProtocolHasBeenDisabled -f $protocolNameProperties.DisplayName, $InstanceName
                    )
                }

                $isRestartNeeded = $true
            }

            # Set individual protocol properties.
            switch ($ProtocolName)
            {
                'TcpIp'
                {
                    # Check if ListenOnAllIpAddresses property need updating.
                    if ($propertiesNotInDesiredState.Where( { $_.ParameterName -eq 'ListenOnAllIpAddresses' }))
                    {
                        Write-Verbose -Message (
                            $script:localizedData.ParameterHasBeenSetToNewValue -f 'ListenOnAllIpAddresses', $protocolNameProperties.DisplayName, $ListenOnAllIpAddresses
                        )

                        $serverProtocolProperties.ProtocolProperties['ListenOnAllIPs'].Value = $ListenOnAllIpAddresses
                    }

                    # Check if KeepAlive property need updating.
                    if ($propertiesNotInDesiredState.Where( { $_.ParameterName -eq 'KeepAlive' }))
                    {
                        Write-Verbose -Message (
                            $script:localizedData.ParameterHasBeenSetToNewValue -f 'KeepAlive', $protocolNameProperties.DisplayName, $KeepAlive
                        )

                        $serverProtocolProperties.ProtocolProperties['KeepAlive'].Value = $KeepAlive
                    }
                }

                'NamedPipes'
                {
                    # Check if PipeName property need updating.
                    if ($propertiesNotInDesiredState.Where( { $_.ParameterName -eq 'PipeName' }))
                    {
                        Write-Verbose -Message (
                            $script:localizedData.ParameterHasBeenSetToNewValue -f 'PipeName', $protocolNameProperties.DisplayName, $PipeName
                        )

                        $serverProtocolProperties.ProtocolProperties['PipeName'].Value = $PipeName
                    }
                }

                'SharedMemory'
                {
                    <#
                        Left blank intentionally. There are no individual protocol
                        properties for the protocol Shared Memory.
                    #>
                }
            }

            $serverProtocolProperties.Alter()
        }

        if (-not $SuppressRestart -and $isRestartNeeded)
        {
            $restartSqlServiceParameters = @{
                ServerName   = $ServerName
                InstanceName = $InstanceName
                Timeout      = $RestartTimeout
                OwnerNode    = $env:COMPUTERNAME
            }

            Restart-SqlService @restartSqlServiceParameters
        }
        elseif ($isRestartNeeded)
        {
            Write-Warning -Message $script:localizedData.RestartSuppressed
        }
    }
    else
    {
        Write-Verbose -Message (
            $script:localizedData.ProtocolIsInDesiredState -f $protocolNameProperties.DisplayName, $InstanceName
        )
    }
}

<#
    .SYNOPSIS
        Determines the desired state of the SQL Server TCP/IP protocol IP address
        group for the specified SQL Server instance.

    .PARAMETER InstanceName
        Specifies the name of the SQL Server instance to enable the protocol for.

    .PARAMETER IpAddressGroup
        Specifies the name of the IP address group in the TCP/IP protocol, e.g.
        'IP1', 'IP2' etc., or 'IPAll'.

    .PARAMETER ServerName
        Specifies the host name of the SQL Server to be configured. If the
        SQL Server belongs to a cluster or availability group specify the host
        name for the listener or cluster group. Default value is $env:COMPUTERNAME.

    .PARAMETER Enabled
        Specified if the IP address group should be enabled or disabled. Only used if
        the IP address group is not set to 'IPAll'. If not specified, the existing
        value will not be changed.

    .PARAMETER IPAddress
        Specifies the IP address for the IP adress group. Only used if the IP address
        group is not set to 'IPAll'. If not specified, the existing value will not be
        changed.

    .PARAMETER UseTcpDynamicPort
        Specifies whether the SQL Server instance should use a dynamic port. If
        not specified the existing value will not be changed. This parameter is
        not allowed to be used at the same time as the parameter TcpPort.

    .PARAMETER TcpPort
        Specifies the TCP port(s) that SQL Server should be listening on. If the
        IP address should listen on more than one port, list all ports as a string
        value with the port numbers separated with a comma, e.g. '1433,1500,1501'.
        This parameter is limited to 2047 characters. If not specified, the existing
        value will not be changed.This parameter is not allowed to be used at the
        same time as the parameter UseTcpDynamicPort.

    .PARAMETER SuppressRestart
        If set to $true then the any attempt by the resource to restart the service
        is suppressed. The default value is $false.

    .PARAMETER RestartTimeout
        Timeout value for restarting the SQL Server services. The default value
        is 120 seconds.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $IpAddressGroup,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = $env:COMPUTERNAME,

        [Parameter()]
        [System.Boolean]
        $Enabled,

        [Parameter()]
        [System.String]
        $IPAddress,

        [Parameter()]
        [System.Boolean]
        $UseTcpDynamicPort,

        [Parameter()]
        [System.String]
        $TcpPort,

        [Parameter()]
        [System.Boolean]
        $SuppressRestart = $false,

        [Parameter()]
        [System.UInt16]
        $RestartTimeout = 120
    )

    Write-Verbose -Message (
        $script:localizedData.TestDesiredState -f $IpAddressGroup, $InstanceName, $ServerName
    )

    $propertyState = Compare-TargetResourceState @PSBoundParameters


    if ($false -in $propertyState.InDesiredState)
    {
        $testTargetResourceReturnValue = $false

        Write-Verbose -Message (
            $script:localizedData.NotInDesiredState -f $IpAddressGroup, $InstanceName
        )
    }
    else
    {
        $testTargetResourceReturnValue = $true

        Write-Verbose -Message (
            $script:localizedData.InDesiredState -f $IpAddressGroup, $InstanceName
        )
    }

    return $testTargetResourceReturnValue
}

<#
    .SYNOPSIS
        Compares the properties in the current state with the properties of the
        desired state and returns a hashtable with the comparison result.

    .PARAMETER InstanceName
        Specifies the name of the SQL Server instance to enable the protocol for.

    .PARAMETER IpAddressGroup
        Specifies the name of the IP address group in the TCP/IP protocol, e.g.
        'IP1', 'IP2' etc., or 'IPAll'.

    .PARAMETER ServerName
        Specifies the host name of the SQL Server to be configured. If the
        SQL Server belongs to a cluster or availability group specify the host
        name for the listener or cluster group. Default value is $env:COMPUTERNAME.

    .PARAMETER Enabled
        Specified if the IP address group should be enabled or disabled. Only used if
        the IP address group is not set to 'IPAll'. If not specified, the existing
        value will not be changed.

    .PARAMETER IPAddress
        Specifies the IP address for the IP adress group. Only used if the IP address
        group is not set to 'IPAll'. If not specified, the existing value will not be
        changed.

    .PARAMETER UseTcpDynamicPort
        Specifies whether the SQL Server instance should use a dynamic port. If
        not specified the existing value will not be changed. This parameter is
        not allowed to be used at the same time as the parameter TcpPort.

    .PARAMETER TcpPort
        Specifies the TCP port(s) that SQL Server should be listening on. If the
        IP address should listen on more than one port, list all ports as a string
        value with the port numbers separated with a comma, e.g. '1433,1500,1501'.
        This parameter is limited to 2047 characters. If not specified, the existing
        value will not be changed.This parameter is not allowed to be used at the
        same time as the parameter UseTcpDynamicPort.

    .PARAMETER SuppressRestart
        If set to $true then the any attempt by the resource to restart the service
        is suppressed. The default value is $false.

    .PARAMETER RestartTimeout
        Timeout value for restarting the SQL Server services. The default value
        is 120 seconds.
#>
function Compare-TargetResourceState
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $IpAddressGroup,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = $env:COMPUTERNAME,

        [Parameter()]
        [System.Boolean]
        $Enabled,

        [Parameter()]
        [System.String]
        $IPAddress,

        [Parameter()]
        [System.Boolean]
        $UseTcpDynamicPort,

        [Parameter()]
        [System.String]
        $TcpPort,

        [Parameter()]
        [System.Boolean]
        $SuppressRestart = $false,

        [Parameter()]
        [System.UInt16]
        $RestartTimeout = 120
    )

    $assertBoundParameterParameters = @{
        BoundParameterList     = $PSBoundParameters
        MutuallyExclusiveList1 = @(
            'UseTcpDynamicPort'
        )
        MutuallyExclusiveList2 = @(
            'TcpPort'
        )
    }

    Assert-BoundParameter @assertBoundParameterParameters

    $getTargetResourceParameters = @{
        InstanceName    = $InstanceName
        IpAddressGroup  = $IpAddressGroup
        ServerName      = $ServerName
        SuppressRestart = $SuppressRestart
        RestartTimeout  = $RestartTimeout
    }

    <#
        We remove any parameters not passed by $PSBoundParameters so that
        Get-TargetResource can also evaluate $PSBoundParameters correctly.

        Need the @() around the Keys property to get a new array to enumerate.
    #>
    @($getTargetResourceParameters.Keys) | ForEach-Object {
        if (-not $PSBoundParameters.ContainsKey($_))
        {
            $getTargetResourceParameters.Remove($_)
        }
    }

    $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

    # Get individual IP address group properties to evaluate.
    switch ($IpAddressGroup)
    {
        'IPAll'
        {
            $propertiesToEvaluate = @(
                'UseTcpDynamicPort'
                'TcpPort'
            )
        }

        Default
        {
            $propertiesToEvaluate = @(
                'Enabled'
                'IPAddress'
                'UseTcpDynamicPort'
                'TcpPort'
            )
        }
    }

    $compareTargetResourceStateParameters = @{
        CurrentValues = $getTargetResourceResult
        DesiredValues = $PSBoundParameters
        Properties    = $propertiesToEvaluate
    }

    return Compare-ResourcePropertyState @compareTargetResourceStateParameters
}

<#
    .SYNOPSIS
        Converts a IP address group name to the correct casing.

    .PARAMETER IpAddressGroup
        Specifies the name of the IP address group in the TCP/IP protocol, e.g.
        'IP1', 'IP2' etc., or 'IPAll'.

    .NOTES
        SMO is case-sensitive with the address group names.
#>
function Convert-IpAdressGroupCasing
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $IpAddressGroup
    )

    return ($IpAddressGroup.ToUpper() -replace 'IPALL', 'IPAll')
}
