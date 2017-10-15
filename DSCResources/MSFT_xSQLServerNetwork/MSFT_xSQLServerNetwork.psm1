Import-Module -Name (Join-Path -Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) `
        -ChildPath 'xSQLServerHelper.psm1') -Force
<#
    .SYNOPSIS
    Returns the current state of the SQL Server network properties.

    .PARAMETER SQLInstanceName
    The name of the SQL instance to be configured.

    .PARAMETER ProtocolName
    The name of network protocol to be configured. Only tcp is currently supported.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $SQLInstanceName,

        # For now there is only support for the tcp protocol.
        [Parameter(Mandatory = $true)]
        [ValidateSet('Tcp')]
        [System.String]
        $ProtocolName
    )

    try
    {
        $applicationDomainObject = Register-SqlWmiManagement -SQLInstanceName $SQLInstanceName

        $managedComputerObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer

        Write-Verbose "Getting network protocol [$ProtocolName] for SQL instance [$SQLInstanceName]."
        $tcp = $managedComputerObject.ServerInstances[$SQLInstanceName].ServerProtocols[$ProtocolName]

        Write-Verbose "Reading current network properties."
        $returnValue = @{
            SQLInstanceName = $SQLInstanceName
            ProtocolName    = $ProtocolName
            IsEnabled       = $tcp.IsEnabled
            TcpDynamicPort  = ($tcp.IPAddresses['IPAll'].IPAddressProperties['TcpDynamicPorts'].Value -ge 0)
            TcpPort         = $tcp.IPAddresses['IPAll'].IPAddressProperties['TcpPort'].Value
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

    .PARAMETER SQLInstanceName
    The name of the SQL instance to be configured.

    .PARAMETER ProtocolName
    The name of network protocol to be configured. Only tcp is currently supported.

    .PARAMETER IsEnabled
    Enables or disables the network protocol.

    .PARAMETER TcpDynamicPort
    Specifies whether the SQL Server instance should use a dynamic port.
    Value cannot be set to $true if TcpPort is set to a non-empty string.

    .PARAMETER TcpPort
    The TCP port(s) that SQL Server should be listening on.
    If the IP address should listen on more than one port, list all ports
    separated with a comma ('1433,1500,1501'). To use this parameter set
    TcpDynamicPort to 'False'.

    .PARAMETER RestartService
    If set to $true then SQL Server and dependent services will be restarted
    if a change to the configuration is made. The default value is $false.

    .PARAMETER RestartTimeout
    Timeout value for restarting the SQL Server services. The default value
    is 120 seconds.
#>
function Set-TargetResource
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
        $SQLInstanceName,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Tcp')]
        [System.String]
        $ProtocolName,

        [Parameter()]
        [System.Boolean]
        $IsEnabled,

        [Parameter()]
        [System.Boolean]
        $TcpDynamicPort,

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

    if ($TcpDynamicPort -and $TcpPort)
    {
        throw New-TerminatingError -ErrorType 'Unable to set both tcp dynamic port and tcp static port. Only one can be set.' -ErrorCategory InvalidOperation
    }

    $getTargetResourceResult = Get-TargetResource -SQLInstanceName $SQLInstanceName -ProtocolName $ProtocolName

    try
    {
        $applicationDomainObject = Register-SqlWmiManagement -SQLInstanceName $SQLInstanceName

        $desiredState = @{
            SQLInstanceName = $SQLInstanceName
            ProtocolName    = $ProtocolName
            IsEnabled       = $IsEnabled
            TcpDynamicPort  = $TcpDynamicPort
            TcpPort         = $TcpPort
        }

        $isRestartNeeded = $false

        $managedComputerObject = New-Object Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer

        Write-Verbose "Getting [$ProtocolName] network protocol for [$SQLInstanceName] SQL instance"
        $tcp = $managedComputerObject.ServerInstances[$SQLInstanceName].ServerProtocols[$ProtocolName]

        Write-Verbose 'Checking [IsEnabled] property.'
        if ($desiredState.IsEnabled -ine $getTargetResourceResult.IsEnabled)
        {
            Write-Verbose "Updating [IsEnabled] from $($getTargetResourceResult.IsEnabled) to $($desiredState.IsEnabled)."
            $tcp.IsEnabled = $desiredState.IsEnabled
            $tcp.Alter()

            $isRestartNeeded = $true
        }

        Write-Verbose 'Checking [TcpDynamicPort] property.'
        if ($desiredState.TcpDynamicPort -ne $getTargetResourceResult.TcpDynamicPort)
        {
            # Translates the current and desired state to a string for display
            $dynamicPortDisplayValueTable = @{
                $true = 'enabled'
                $false = 'disabled'
            }

            # Translates the desired state to a valid value
            $desiredDynamicPortValue = @{
                $true = '0'
                $false = ''
            }

            $fromTcpDynamicPortDisplayValue = $dynamicPortDisplayValueTable[$getTargetResourceResult.TcpDynamicPort]
            $toTcpDynamicPortDisplayValue = $dynamicPortDisplayValueTable[$desiredState.TcpDynamicPort]

            Write-Verbose "Updating [TcpDynamicPorts] from $($fromTcpDynamicPortDisplayValue) to $($toTcpDynamicPortDisplayValue)."
            $tcp.IPAddresses['IPAll'].IPAddressProperties['TcpDynamicPorts'].Value = $desiredDynamicPortValue[$desiredState.TcpDynamicPort]
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
            Restart-SqlService -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName -Timeout $RestartTimeout
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

    .PARAMETER SQLInstanceName
    The name of the SQL instance to be configured.

    .PARAMETER ProtocolName
    The name of network protocol to be configured. Only tcp is currently supported.

    .PARAMETER IsEnabled
    Enables or disables the network protocol.

    .PARAMETER TcpDynamicPort
    Specifies whether the SQL Server instance should use a dynamic port.
    Value cannot be set to $true if TcpPort is set to a non-empty string.

    .PARAMETER TcpPort
    The TCP port(s) that SQL Server should be listening on.
    If the IP address should listen on more than one port, list all ports
    separated with a comma ('1433,1500,1501'). To use this parameter set
    TcpDynamicPort to 'False'.

    .PARAMETER RestartService
    If set to $true then SQL Server and dependent services will be restarted
    if a change to the configuration is made. The default value is $false.

    Not used in Test-TargetResource.

    .PARAMETER RestartTimeout
    Timeout value for restarting the SQL Server services. The default value
    is 120 seconds.

    Not used in Test-TargetResource.
#>
function Test-TargetResource
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
        $SQLInstanceName,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Tcp')]
        [System.String]
        $ProtocolName,

        [Parameter()]
        [System.Boolean]
        $IsEnabled,

        [Parameter()]
        [System.Boolean]
        $TcpDynamicPort,

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

    if ($TcpDynamicPort -and $TcpPort)
    {
        throw New-TerminatingError -ErrorType 'Unable to set both tcp dynamic port and tcp static port. Only one can be set.' -ErrorCategory InvalidOperation
    }

    $getTargetResourceResult = Get-TargetResource -SQLInstanceName $SQLInstanceName -ProtocolName $ProtocolName

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
                $true  = 'enabled'
                $false = 'disabled'
            }

            Write-Verbose ('Expected protocol to be {0}, but was {1}.' -f $evaluateEnableOrDisable[$IsEnabled], $evaluateEnableOrDisable[$getTargetResourceResult.IsEnabled])

            $isInDesiredState = $false
        }
    }

    if ($PSBoundParameters.ContainsKey('TcpDynamicPort'))
    {
        if ($TcpDynamicPort -and $getTargetResourceResult.TcpDynamicPort -eq $false)
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
