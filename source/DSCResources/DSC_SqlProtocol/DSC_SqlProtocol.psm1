$script:sqlServerDscHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\SqlServerDsc.Common'
$script:resourceHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DscResource.Common'

Import-Module -Name $script:sqlServerDscHelperModulePath
Import-Module -Name $script:resourceHelperModulePath

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

<#
    .SYNOPSIS
        Returns the current state of the SQL Server protocol for the specified
        SQL Server instance.

    .PARAMETER InstanceName
        Specifies the name of the SQL Server instance to enable the protocol for.

    .PARAMETER ProtocolName
        Specifies the name of network protocol to be configured. Possible values
        are 'TcpIp', 'NamedPipes', or 'ShareMemory'.

    .PARAMETER ServerName
        Specifies the host name of the SQL Server to be configured. If the SQL
        Server belongs to a cluster or availability group specify the host name
        for the listener or cluster group. Default value is the current computer
        name.

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
        [ValidateSet('TcpIp', 'NamedPipes', 'SharedMemory')]
        [System.String]
        $ProtocolName,

        [Parameter()]
        [System.String]
        $ServerName = (Get-ComputerName),

        [Parameter()]
        [System.Boolean]
        $SuppressRestart = $false,

        [Parameter()]
        [System.UInt16]
        $RestartTimeout = 120
    )

    $returnValue = @{
        InstanceName           = $InstanceName
        ProtocolName           = $ProtocolName
        ServerName             = $ServerName
        SuppressRestart        = $SuppressRestart
        RestartTimeout         = $RestartTimeout
        Enabled                = $false
        ListenOnAllIpAddresses = $false
        KeepAlive              = 0
        PipeName               = $null
        HasMultiIPAddresses    = $false
    }

    $protocolNameProperties = Get-ProtocolNameProperties -ProtocolName $ProtocolName

    # Getting the server protocol properties by using the computer name.
    $computerName = Get-ComputerName

    Write-Verbose -Message (
        $script:localizedData.GetCurrentState -f $protocolNameProperties.DisplayName, $InstanceName, $computerName
    )

    Import-SqlDscPreferredModule

    <#
        Must connect to the local machine name because $ServerName can point
        to a cluster instance or availability group listener.
    #>
    $getServerProtocolObjectParameters = @{
        ServerName   = $computerName
        Instance     = $InstanceName
        ProtocolName = $ProtocolName
    }

    $serverProtocolProperties = Get-ServerProtocolObject @getServerProtocolObjectParameters

    if ($serverProtocolProperties)
    {
        # Properties that exist on all protocols.
        $returnValue.Enabled = $serverProtocolProperties.IsEnabled
        $returnValue.HasMultiIPAddresses = $serverProtocolProperties.HasMultiIPAddresses

        # Get individual protocol properties.
        switch ($ProtocolName)
        {
            'TcpIp'
            {
                $returnValue.ListenOnAllIpAddresses = $serverProtocolProperties.ProtocolProperties['ListenOnAllIPs'].Value
                $returnValue.KeepAlive = $serverProtocolProperties.ProtocolProperties['KeepAlive'].Value
            }

            'NamedPipes'
            {
                $returnValue.PipeName = $serverProtocolProperties.ProtocolProperties['PipeName'].Value
            }

            'SharedMemory'
            {
                <#
                    Left blank intentionally. There are no individual protocol
                    properties for the protocol Shared Memory.
                #>
            }
        }
    }

    return $returnValue
}

<#
    .SYNOPSIS
        Sets the desired state of the SQL Server protocol for the specified
        SQL Server instance.

    .PARAMETER InstanceName
        Specifies the name of the SQL Server instance to enable the protocol for.

    .PARAMETER ProtocolName
        Specifies the name of network protocol to be configured. Possible values
        are 'TcpIp', 'NamedPipes', or 'ShareMemory'.

    .PARAMETER ServerName
        Specifies the host name of the SQL Server to be configured. If the SQL
        Server belongs to a cluster or availability group specify the host name
        for the listener or cluster group. Default value is the current computer
        name.

    .PARAMETER Enabled
        Specifies if the protocol should be enabled or disabled.

    .PARAMETER ListenOnAllIpAddresses
        Specifies to listen on all IP addresses. Only used for the TCP/IP protocol,
        ignored for all other protocols.

    .PARAMETER KeepAlive
        Specifies the keep alive duration. Only used for the TCP/IP protocol,
        ignored for all other protocols.

    .PARAMETER PipeName
        Specifies the name of the named pipe. Only used for the Named Pipes protocol,
        ignored for all other protocols.

    .PARAMETER SuppressRestart
        If set to $true then the any attempt by the resource to restart the service
        is suppressed. The default value is $false.

    .PARAMETER RestartTimeout
        Timeout value for restarting the SQL Server services. The default value
        is 120 seconds.

    .NOTES
        If a protocol is disabled that prevents Restart-SqlService to contact the
        instance to evaluate if it is a cluster then the parameter `SuppressRestart`
        must be used to override the restart. Same if a protocol is enabled that
        was previously disabled and no other protocol allows connecting to the
        instance then the parameter `SuppressRestart` must also be used.
#>
function Set-TargetResource
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('SqlServerDsc.AnalyzerRules\Measure-CommandsNeededToLoadSMO', '', Justification='The command Import-SqlDscPreferredModule is implicitly called when calling Compare-TargetResourceState')]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [ValidateSet('TcpIp', 'NamedPipes', 'SharedMemory')]
        [System.String]
        $ProtocolName,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = (Get-ComputerName),

        [Parameter()]
        [System.Boolean]
        $Enabled,

        [Parameter()]
        [System.Boolean]
        $ListenOnAllIpAddresses,

        [Parameter()]
        [System.Int32]
        $KeepAlive,

        [Parameter()]
        [System.String]
        $PipeName,

        [Parameter()]
        [System.Boolean]
        $SuppressRestart = $false,

        [Parameter()]
        [System.UInt16]
        $RestartTimeout = 120
    )

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
        # Getting the server protocol properties by using the computer name.
        $computerName = Get-ComputerName

        Write-Verbose -Message (
            $script:localizedData.SetDesiredState -f $protocolNameProperties.DisplayName, $InstanceName, $computerName
        )

        <#
            Must connect to the local machine name because $ServerName can point
            to a cluster instance or availability group listener.
        #>
        $getServerProtocolObjectParameters = @{
            ServerName   = $computerName
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
        else
        {
            $errorMessage = $script:localizedData.FailedToGetSqlServerProtocol

            New-InvalidOperationException -Message $errorMessage
        }

        if (-not $SuppressRestart -and $isRestartNeeded)
        {
            <#
                This is using the $ServerName to be able to restart a cluster
                instance or availability group listener.
            #>
            $restartSqlServiceParameters = @{
                ServerName   = $ServerName
                InstanceName = $InstanceName
                Timeout      = $RestartTimeout
                OwnerNode    = Get-ComputerName
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
        Determines the current state of the SQL Server protocol for the specified
        SQL Server instance.

    .PARAMETER InstanceName
        Specifies the name of the SQL Server instance to enable the protocol for.

    .PARAMETER ProtocolName
        Specifies the name of network protocol to be configured. Possible values
        are 'TcpIp', 'NamedPipes', or 'ShareMemory'.

    .PARAMETER ServerName
        Specifies the host name of the SQL Server to be configured. If the SQL
        Server belongs to a cluster or availability group specify the host name
        for the listener or cluster group. Default value is the current computer
        name.

    .PARAMETER Enabled
        Specifies if the protocol should be enabled or disabled.

    .PARAMETER ListenOnAllIpAddresses
        Specifies to listen on all IP addresses. Only used for the TCP/IP protocol,
        ignored for all other protocols.

    .PARAMETER KeepAlive
        Specifies the keep alive duration. Only used for the TCP/IP protocol,
        ignored for all other protocols.

    .PARAMETER PipeName
        Specifies the name of the named pipe. Only used for the Named Pipes protocol,
        ignored for all other protocols.

    .PARAMETER SuppressRestart
        If set to $true then the any attempt by the resource to restart the service
        is suppressed. The default value is $false.

    .PARAMETER RestartTimeout
        Timeout value for restarting the SQL Server services. The default value
        is 120 seconds.
#>
function Test-TargetResource
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('SqlServerDsc.AnalyzerRules\Measure-CommandsNeededToLoadSMO', '', Justification='The command Import-SqlDscPreferredModule is implicitly called when calling Compare-TargetResourceState')]
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [ValidateSet('TcpIp', 'NamedPipes', 'SharedMemory')]
        [System.String]
        $ProtocolName,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = (Get-ComputerName),

        [Parameter()]
        [System.Boolean]
        $Enabled,

        [Parameter()]
        [System.Boolean]
        $ListenOnAllIpAddresses,

        [Parameter()]
        [System.Int32]
        $KeepAlive,

        [Parameter()]
        [System.String]
        $PipeName,

        [Parameter()]
        [System.Boolean]
        $SuppressRestart = $false,

        [Parameter()]
        [System.UInt16]
        $RestartTimeout = 120
    )

    $protocolNameProperties = Get-ProtocolNameProperties -ProtocolName $ProtocolName

    Write-Verbose -Message (
        $script:localizedData.TestDesiredState -f $protocolNameProperties.DisplayName, $InstanceName, $ServerName
    )

    $propertyState = Compare-TargetResourceState @PSBoundParameters


    if ($false -in $propertyState.InDesiredState)
    {
        $testTargetResourceReturnValue = $false

        Write-Verbose -Message (
            $script:localizedData.NotInDesiredState -f $protocolNameProperties.DisplayName, $InstanceName
        )
    }
    else
    {
        $testTargetResourceReturnValue = $true

        Write-Verbose -Message (
            $script:localizedData.InDesiredState -f $protocolNameProperties.DisplayName, $InstanceName
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

    .PARAMETER ProtocolName
        Specifies the name of network protocol to be configured. Possible values
        are 'TcpIp', 'NamedPipes', or 'ShareMemory'.

    .PARAMETER ServerName
        Specifies the host name of the SQL Server to be configured. Default value
        is the current computer name.

    .PARAMETER Enabled
        Specifies if the protocol should be enabled or disabled.

    .PARAMETER ListenOnAllIpAddresses
        Specifies to listen on all IP addresses. Only used for the TCP/IP protocol,
        ignored for all other protocols.

    .PARAMETER KeepAlive
        Specifies the keep alive duration. Only used for the TCP/IP protocol,
        ignored for all other protocols.

    .PARAMETER PipeName
        Specifies the name of the named pipe. Only used for the Named Pipes protocol,
        ignored for all other protocols.

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
        [ValidateSet('TcpIp', 'NamedPipes', 'SharedMemory')]
        [System.String]
        $ProtocolName,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = (Get-ComputerName),

        [Parameter()]
        [System.Boolean]
        $Enabled,

        [Parameter()]
        [System.Boolean]
        $ListenOnAllIpAddresses,

        [Parameter()]
        [System.Int32]
        $KeepAlive,

        [Parameter()]
        [System.String]
        $PipeName,

        [Parameter()]
        [System.Boolean]
        $SuppressRestart,

        [Parameter()]
        [System.UInt16]
        $RestartTimeout
    )

    if ($ProtocolName -eq 'SharedMemory')
    {
        <#
            If the protocol is Shared Memory, assert that no other individual
            protocol properties are passed.
        #>
        $assertBoundParameterParameters = @{
            BoundParameterList     = $PSBoundParameters
            <#
                Since SharedMemory does not have any individual properties this
                mandatory property is being used to compare against.
            #>
            MutuallyExclusiveList1 = @(
                'ProtocolName'
            )
            # These must not be passed for Shared Memory.
            MutuallyExclusiveList2 = @(
                'KeepAlive'
                'ListenOnAllIpAddresses'
                'PipeName'
            )
        }
    }
    else
    {
        <#
            If the protocol is set to TCP/IP or Named Pipes, assert that one or
            more of their individual protocol properties are not passed together.
        #>
        $assertBoundParameterParameters = @{
            BoundParameterList     = $PSBoundParameters
            # Individual properties for TCP/IP.
            MutuallyExclusiveList1 = @(
                'KeepAlive'
                'ListenOnAllIpAddresses'
            )
            # Individual properties for Named Pipes.
            MutuallyExclusiveList2 = @(
                'PipeName'
            )
        }
    }

    Assert-BoundParameter @assertBoundParameterParameters

    $getTargetResourceParameters = @{
        InstanceName    = $InstanceName
        ProtocolName    = $ProtocolName
        ServerName      = $ServerName
        SuppressRestart = $SuppressRestart
        RestartTimeout  = $RestartTimeout
    }

    <#
        We remove any parameters not passed by $PSBoundParameters so that
        Get-TargetResource can also evaluate $PSBoundParameters correctly.

        Need the @() around the Keys property to get a new array to enumerate.
    #>
    @($getTargetResourceParameters.Keys) | ForEach-Object -Process {
        if (-not $PSBoundParameters.ContainsKey($_))
        {
            $getTargetResourceParameters.Remove($_)
        }
    }

    $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

    $propertiesToEvaluate = @(
        'Enabled'
    )

    # Get individual protocol properties to evaluate.
    switch ($ProtocolName)
    {
        'TcpIp'
        {
            $propertiesToEvaluate += 'ListenOnAllIpAddresses'
            $propertiesToEvaluate += 'KeepAlive'
        }

        'NamedPipes'
        {
            $propertiesToEvaluate += 'PipeName'
        }

        'SharedMemory'
        {
            <#
                Left blank intentionally. There are no individual protocol
                properties for the protocol Shared Memory.
            #>
        }
    }

    $compareTargetResourceStateParameters = @{
        CurrentValues = $getTargetResourceResult
        DesiredValues = $PSBoundParameters
        Properties    = $propertiesToEvaluate
    }

    return Compare-ResourcePropertyState @compareTargetResourceStateParameters
}
