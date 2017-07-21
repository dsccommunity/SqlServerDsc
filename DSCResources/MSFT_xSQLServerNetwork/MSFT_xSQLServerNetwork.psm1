Import-Module -Name (Join-Path -Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) `
                               -ChildPath 'xSQLServerHelper.psm1') `
                               -Force
<#
    .SYNOPSIS
    Returns the current state of the SQL Server network properties.

    .PARAMETER InstanceName
    The name of the SQL instance to be configured.

    .PARAMETER ProtocolName
    The name of network protocol to be configured. Only tcp is currently supported.
#>
Function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        # For now there is only support for the tcp protocol.
        [Parameter(Mandatory = $true)]
        [ValidateSet('Tcp')]
        [System.String]
        $ProtocolName
    )

    try
    {
        $applicationDomainObject = Register-SqlWmiManagement -SQLInstanceName $InstanceName

        $managedComputerObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer

        Write-Verbose "Getting network protocol [$ProtocolName] for SQL instance [$InstanceName]."
        $tcp = $managedComputerObject.ServerInstances[$InstanceName].ServerProtocols[$ProtocolName]

        Write-Verbose "Reading current network properties."
        $returnValue = @{
            InstanceName = $InstanceName
            ProtocolName = $ProtocolName
            IsEnabled = $tcp.IsEnabled
            TcpDynamicPorts = $tcp.IPAddresses['IPAll'].IPAddressProperties['TcpDynamicPorts'].Value
            TcpPort = $tcp.IPAddresses['IPAll'].IPAddressProperties['TcpPort'].Value
        }

        $returnValue.Keys | ForEach-Object {
            Write-Verbose "$_ = $($returnValue[$_])"
        }
    }
    finally
    {
        Unregister-SqlAssemblies -ApplicationDomain $applicationDomainObject
    }

    return $returnValue
}

<#
    .SYNOPSIS
    Sets the SQL Server network properties.

    .PARAMETER SQLServer
    The host name of the SQL Server to be configured. Default value is $env:COMPUTERNAME.

    .PARAMETER InstanceName
    The name of the SQL instance to be configured.

    .PARAMETER ProtocolName
    The name of network protocol to be configured. Only tcp is currently supported.

    .PARAMETER IsEnabled
    Enables or disables the network protocol.

    .PARAMETER TcpDynamicPorts
    Set the value to '0' if dynamic ports should be used.
    If static port should be used set this to a empty string value.
    Value can not be set to '0' if TcpPort is also set to a value.

    .PARAMETER TcpPort
    The TCP port(s) that SQL Server should be listening on.
    If the IP address should listen on more than one port, list all ports
    separated with a comma ('1433,1500,1501'). To use this parameter set
    TcpDynamicPorts to the value '' (empty string).

    .PARAMETER RestartService
    If set to $true then SQL Server and dependent services will be restarted
    if a change to the configuration is made. The default value is $false.

    .PARAMETER RestartTimeout
    Timeout value for restarting the SQL Server services. The default value
    is 120 seconds.
#>
Function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Tcp')]
        [System.String]
        $ProtocolName,

        [Parameter()]
        [System.Boolean]
        $IsEnabled,

        [Parameter()]
        [ValidateSet('0','')]
        [System.String]
        $TcpDynamicPorts,

        [Parameter()]
        [System.String]
        $TcpPort,

        [Parameter()]
        [System.Boolean]
        $RestartService = $false,

        [Parameter()]
        [System.UInt16]
        $RestartTimeout = 120
    )

    if ($TcpDynamicPorts -eq '0' -and $TcpPort)
    {
        throw New-TerminatingError -ErrorType UnableToUseBothDynamicAndStaticPort -ErrorCategory InvalidOperation
    }

    $getTargetResourceResult = Get-TargetResource -InstanceName $InstanceName -ProtocolName $ProtocolName

    try
    {
        $applicationDomainObject = Register-SqlWmiManagement -SQLInstanceName $InstanceName

        $desiredState = @{
            InstanceName = $InstanceName
            ProtocolName = $ProtocolName
            IsEnabled = $IsEnabled
            TcpDynamicPorts = $TcpDynamicPorts
            TcpPort = $TcpPort
        }

        $isRestartNeeded = $false

        $managedComputerObject = New-Object Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer

        Write-Verbose "Getting [$ProtocolName] network protocol for [$InstanceName] SQL instance"
        $tcp = $managedComputerObject.ServerInstances[$InstanceName].ServerProtocols[$ProtocolName]

        Write-Verbose 'Checking [IsEnabled] property.'
        if ($desiredState.IsEnabled -ine $getTargetResourceResult.IsEnabled)
        {
            Write-Verbose "Updating [IsEnabled] from $($getTargetResourceResult.IsEnabled) to $($desiredState.IsEnabled)."
            $tcp.IsEnabled = $desiredState.IsEnabled
            $tcp.Alter()

            $isRestartNeeded = $true
        }

        Write-Verbose 'Checking [TcpDynamicPorts] property.'
        if ($desiredState.TcpDynamicPorts -ine $getTargetResourceResult.TcpDynamicPorts)
        {
            $fromTcpDynamicPortsValue = $getTargetResourceResult.TcpDynamicPorts
            if ($fromTcpDynamicPortsValue -eq '')
            {
                $fromTcpDynamicPortsValue = 'none'
            }

            $toTcpDynamicPortsValue = $desiredState.TcpDynamicPorts
            if ($toTcpDynamicPortsValue -eq '')
            {
                $toTcpDynamicPortsValue = 'none'
            }

            Write-Verbose "Updating [TcpDynamicPorts] from $($fromTcpDynamicPortsValue) to $($toTcpDynamicPortsValue)."
            $tcp.IPAddresses['IPAll'].IPAddressProperties['TcpDynamicPorts'].Value = $desiredState.TcpDynamicPorts
            $tcp.Alter()

            $isRestartNeeded = $true
        }

        Write-Verbose 'Checking [TcpPort property].'
        if ($desiredState.TcpPort -ine $getTargetResourceResult.TcpPort)
        {
            $fromTcpPort = $getTargetResourceResult.TcpPort
            if ($fromTcpPort -eq '')
            {
                $fromTcpPort = 'none'
            }

            $toTcpPort = $desiredState.TcpPort
            if ($toTcpPort -eq '')
            {
                $toTcpPort = 'none'
            }

            Write-Verbose "Updating [TcpPort] from $($fromTcpPort) to $($toTcpPort)."
            $tcp.IPAddresses['IPAll'].IPAddressProperties['TcpPort'].Value = $desiredState.TcpPort
            $tcp.Alter()

            $isRestartNeeded = $true
        }

        if ($RestartService -and $isRestartNeeded)
        {
            Restart-SqlService -SQLServer $SQLServer -SQLInstanceName $InstanceName -Timeout $RestartTimeout
        }
    }
    finally
    {
        Unregister-SqlAssemblies -ApplicationDomain $applicationDomainObject
    }
}

<#
    .SYNOPSIS
    Sets the SQL Server network properties.

    .PARAMETER SQLServer
    The host name of the SQL Server to be configured. Default value is $env:COMPUTERNAME.

    Not used in Test-TargetResource.

    .PARAMETER InstanceName
    The name of the SQL instance to be configured.

    .PARAMETER ProtocolName
    The name of network protocol to be configured. Only tcp is currently supported.

    .PARAMETER IsEnabled
    Enables or disables the network protocol.

    .PARAMETER TcpDynamicPorts
    Set the value to '0' if dynamic ports should be used.
    If static port should be used set this to a empty string value.
    Value can not be set to '0' if TcpPort is also set to a value.

    .PARAMETER TcpPort
    The TCP port(s) that SQL Server should be listening on.
    If the IP address should listen on more than one port, list all ports
    separated with a comma ('1433,1500,1501'). To use this parameter set
    TcpDynamicPorts to the value '' (empty string).

    .PARAMETER RestartService
    If set to $true then SQL Server and dependent services will be restarted
    if a change to the configuration is made. The default value is $false.

    Not used in Test-TargetResource.

    .PARAMETER RestartTimeout
    Timeout value for restarting the SQL Server services. The default value
    is 120 seconds.

    Not used in Test-TargetResource.
#>
Function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Tcp')]
        [System.String]
        $ProtocolName,

        [Parameter()]
        [System.Boolean]
        $IsEnabled,

        [Parameter()]
        [ValidateSet('0','')]
        [System.String]
        $TcpDynamicPorts,

        [Parameter()]
        [System.String]
        $TcpPort,

        [Parameter()]
        [System.Boolean]
        $RestartService = $false,

        [Parameter()]
        [System.UInt16]
        $RestartTimeout = 120
    )

    if ($TcpDynamicPorts -eq '0' -and $TcpPort)
    {
        throw New-TerminatingError -ErrorType UnableToUseBothDynamicAndStaticPort -ErrorCategory InvalidOperation
    }

    $getTargetResourceResult = Get-TargetResource -InstanceName $InstanceName -ProtocolName $ProtocolName

    Write-Verbose "Comparing desired state with current state."

    $isInDesiredState = $true

    if ($ProtocolName -ne $getTargetResourceResult.ProtocolName)
    {
        Write-Verbose ('Expected protocol to be ''{0}'', but was ''{1}''.' -f $ProtocolName, $getTargetResourceResult.ProtocolName)

        $isInDesiredState = $false
    }

    if ($PSBoundParameters.ContainsKey('IsEnabled'))
    {
        if ($IsEnabled -ne $getTargetResourceResult.IsEnabled)
        {
            $evaluateEnableOrDisable = @{
                $true='enabled'
                $false='disabled'
            }

            Write-Verbose ('Expected protocol to be {0}, but was {1}.' -f $evaluateEnableOrDisable[$IsEnabled], $evaluateEnableOrDisable[$getTargetResourceResult.IsEnabled])

            $isInDesiredState = $false
        }
    }

    if ($PSBoundParameters.ContainsKey('TcpDynamicPorts'))
    {
        if ($TcpDynamicPorts -eq '0' -and $getTargetResourceResult.TcpDynamicPorts -eq '')
        {
            Write-Verbose 'Expected tcp dynamic port to be used, but it was not.'

            $isInDesiredState = $false
        }
    }

    if ($PSBoundParameters.ContainsKey('TcpPort'))
    {
        if ($getTargetResourceResult.TcpPort -eq '')
        {
            Write-Verbose 'Expected tcp static port to be used, but it was not.'

            $isInDesiredState = $false
        }
        elseif ($TcpPort -ne $getTargetResourceResult.TcpPort)
        {
            Write-Verbose ('Expected tcp static port to be ''{0}'', but was ''{1}''.' -f $TcpPort, $getTargetResourceResult.TcpPort)

            $isInDesiredState = $false
        }
    }

    if ($isInDesiredState)
    {
        Write-Verbose "In desired state."
    }

    return $isInDesiredState
}

Export-ModuleMember -Function *-TargetResource
