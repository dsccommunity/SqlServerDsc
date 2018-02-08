Import-Module -Name (Join-Path -Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) `
        -ChildPath 'SqlServerDscHelper.psm1') -Force
Import-Module -Name (Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) `
        -ChildPath 'CommonResourceHelper.psm1')

# Load localized string data
$script:localizedData = Get-LocalizedData -ResourceName 'MSFT_SqlServerNetwork'

<#
    .SYNOPSIS
    Returns the current state of the SQL Server network properties.

    .PARAMETER InstanceName
    The name of the SQL instance to be configured.

    .PARAMETER ProtocolName
    The name of network protocol to be configured. Only tcp is currently supported.

    .PARAMETER IPAddress
    Specify the IP address to configure. Use IPAll for all ip adresses (listen on all).
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

        # For now there is only support for the tcp protocol.
        [Parameter(Mandatory = $true)]
        [ValidateSet('Tcp')]
        [System.String]
        $ProtocolName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $IPAddress
    )

    try
    {
        $applicationDomainObject = Register-SqlWmiManagement -SQLInstanceName $InstanceName

        $managedComputerObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer

        Write-Verbose -Message ($script:localizedData.GetNetworkProtocol -f $ProtocolName, $InstanceName)
        $tcp = $managedComputerObject.ServerInstances[$InstanceName].ServerProtocols[$ProtocolName]

        $ipAddressKey = Resolve-SqlProtocolIPAddress -Protocol $tcp -IPAddress $IPAddress

        Write-Verbose -Message $script:localizedData.ReadingNetworkProperties
        $returnValue = @{
            InstanceName   = $InstanceName
            ProtocolName   = $ProtocolName
            IPAddress      = $IPAddress
            IsEnabled      = $(if($ipAddressKey -eq 'IPAll') { $tcp.IsEnabled } else { $tcp.IPAddresses[$ipAddressKey].IPAddressProperties['Enabled'].Value })
            ListenAll      = $(if($ipAddressKey -eq 'IPAll') { $tcp.ProtocolProperties['ListenOnAllIPs'].Value } else { $null })
            TcpDynamicPort = ($tcp.IPAddresses[$ipAddressKey].IPAddressProperties['TcpDynamicPorts'].Value -ge 0)
            TcpPort        = $tcp.IPAddresses[$ipAddressKey].IPAddressProperties['TcpPort'].Value
        }

        $returnValue.Keys | ForEach-Object {
            Write-Verbose -Message "$_ = $($returnValue[$_])"
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

    .PARAMETER ServerName
    The host name of the SQL Server to be configured. Default value is $env:COMPUTERNAME.

    .PARAMETER InstanceName
    The name of the SQL instance to be configured.

    .PARAMETER ProtocolName
    The name of network protocol to be configured. Only tcp is currently supported.

    .PARAMETER IPAddress
    Specify the IP address to configure. Use IPAll for all ip adresses (listen on all).

    .PARAMETER IsEnabled
    Enables or disables the network protocol.

    .PARAMETER ListenAll
    Enables or disables to listen on all IP adresses. Will be ignored if IPAddress is
    not set to 'IPAll'.

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
        $ServerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Tcp')]
        [System.String]
        $ProtocolName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $IPAddress,

        [Parameter()]
        [System.Boolean]
        $IsEnabled,

        [Parameter()]
        [System.Boolean]
        $ListenAll,

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
        $errorMessage = $script:localizedData.ErrorDynamicAndStaticPortSpecified
        New-InvalidOperationException -Message $errorMessage
    }

    $getTargetResourceResult = Get-TargetResource -InstanceName $InstanceName -ProtocolName $ProtocolName -IPAddress $IPAddress

    try
    {
        $applicationDomainObject = Register-SqlWmiManagement -SQLInstanceName $InstanceName

        $desiredState = @{
            InstanceName   = $InstanceName
            ProtocolName   = $ProtocolName
            IPAddress      = $IPAddress
            ListenAll      = $ListenAll
            IsEnabled      = $IsEnabled
            TcpDynamicPort = $TcpDynamicPort
            TcpPort        = $TcpPort
        }

        $isRestartNeeded = $false

        $managedComputerObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer

        Write-Verbose -Message ($script:localizedData.GetNetworkProtocol -f $ProtocolName, $InstanceName)
        $tcp = $managedComputerObject.ServerInstances[$InstanceName].ServerProtocols[$ProtocolName]

        $ipAddressKey = Resolve-SqlProtocolIPAddress -Protocol $tcp -IPAddress $IPAddress

        Write-Verbose -Message ($script:localizedData.CheckingProperty -f 'IsEnabled')
        if ($desiredState.IsEnabled -ine $getTargetResourceResult.IsEnabled)
        {
            Write-Verbose -Message ($script:localizedData.UpdatingProperty -f 'IsEnabled', $getTargetResourceResult.IsEnabled, $desiredState.IsEnabled)
            if ($ipAddressKey -eq 'IPAll')
            {
                $tcp.IsEnabled = $desiredState.IsEnabled
                $tcp.Alter()
            }
            else
            {
                $tcp.IPAddresses[$ipAddressKey].IPAddressProperties['Enabled'].Value = $desiredState.IsEnabled
                $tcp.Alter()
            }
            $isRestartNeeded = $true
        }

        Write-Verbose -Message ($script:localizedData.CheckingProperty -f 'ListenAll')
        if ($desiredState.ListenAll -ine $getTargetResourceResult.ListenAll -and $ipAddressKey -eq 'IPAll')
        {
            Write-Verbose -Message ($script:localizedData.UpdatingProperty -f 'ListenAll', $getTargetResourceResult.ListenAll, $desiredState.ListenAll)
            $tcp.ProtocolProperties['ListenOnAllIPs'].Value = $desiredState.ListenAll
            $tcp.Alter()
            $isRestartNeeded = $true
        }

        Write-Verbose -Message ($script:localizedData.CheckingProperty -f 'TcpDynamicPort')
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

            Write-Verbose -Message ($script:localizedData.UpdatingProperty -f 'TcpDynamicPorts', $fromTcpDynamicPortDisplayValue, $toTcpDynamicPortDisplayValue)
            $tcp.IPAddresses[$ipAddressKey].IPAddressProperties['TcpDynamicPorts'].Value = $desiredDynamicPortValue[$desiredState.TcpDynamicPort]
            $tcp.Alter()

            $isRestartNeeded = $true
        }

        Write-Verbose -Message ($script:localizedData.CheckingProperty -f 'TcpPort')
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

            Write-Verbose -Message ($script:localizedData.UpdatingProperty -f 'TcpPort', $fromTcpPort, $toTcpPort)
            $tcp.IPAddresses[$ipAddressKey].IPAddressProperties['TcpPort'].Value = $desiredState.TcpPort
            $tcp.Alter()

            $isRestartNeeded = $true
        }

        if ($RestartService -and $isRestartNeeded)
        {
            Restart-SqlService -SQLServer $ServerName -SQLInstanceName $InstanceName -Timeout $RestartTimeout
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

    .PARAMETER ServerName
    The host name of the SQL Server to be configured. Default value is $env:COMPUTERNAME.

    Not used in Test-TargetResource.

    .PARAMETER InstanceName
    The name of the SQL instance to be configured.

    .PARAMETER ProtocolName
    The name of network protocol to be configured. Only tcp is currently supported.

    .PARAMETER IPAddress
    Specify the IP address to configure. Use IPAll for all ip adresses (listen on all).

    .PARAMETER IsEnabled
    Enables or disables the network protocol.

    .PARAMETER ListenAll
    Enables or disables to listen on all IP adresses. Will be ignored if IPAddress is
    not set to 'IPAll'.

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
        $ServerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Tcp')]
        [System.String]
        $ProtocolName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $IPAddress,

        [Parameter()]
        [System.Boolean]
        $IsEnabled,

        [Parameter()]
        [System.Boolean]
        $ListenAll,

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
        $errorMessage = $script:localizedData.ErrorDynamicAndStaticPortSpecified
        New-InvalidOperationException -Message $errorMessage
    }

    $getTargetResourceResult = Get-TargetResource -InstanceName $InstanceName -ProtocolName $ProtocolName -IPAddress $IPAddress

    Write-Verbose -Message $script:localizedData.CompareStates

    $isInDesiredState = $true

    if ($ProtocolName -ne $getTargetResourceResult.ProtocolName)
    {
        Write-Verbose -Message ($script:localizedData.ExpectedPropertyValue -f 'ProtocolName', $ProtocolName, $getTargetResourceResult.ProtocolName)

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

            Write-Verbose -Message ($script:localizedData.ExpectedPropertyValue -f 'IsEnabled', $evaluateEnableOrDisable[$IsEnabled], $evaluateEnableOrDisable[$getTargetResourceResult.IsEnabled])

            $isInDesiredState = $false
        }
    }

    if ($PSBoundParameters.ContainsKey('ListenAll') -and $IPAddress -eq 'IPAll')
    {
        if ($ListenAll -ne $getTargetResourceResult.ListenAll)
        {
            $evaluateEnableOrDisable = @{
                $true  = 'enabled'
                $false = 'disabled'
            }

            Write-Verbose -Message ($script:localizedData.ExpectedPropertyValue -f 'ListenAll', $evaluateEnableOrDisable[$ListenAll], $evaluateEnableOrDisable[$getTargetResourceResult.ListenAll])

            $isInDesiredState = $false
        }
    }

    if ($PSBoundParameters.ContainsKey('TcpDynamicPort'))
    {
        if ($TcpDynamicPort -and $getTargetResourceResult.TcpDynamicPort -eq $false)
        {
            Write-Verbose -Message ($script:localizedData.ExpectedPropertyValue -f 'TcpDynamicPort', $TcpDynamicPort, $getTargetResourceResult.TcpDynamicPort)

            $isInDesiredState = $false
        }
    }

    if ($PSBoundParameters.ContainsKey('TcpPort'))
    {
        if ($getTargetResourceResult.TcpPort -eq '')
        {
            Write-Verbose -Message ($script:localizedData.ExpectedPropertyValue -f 'TcpPort', $TcpPort, $getTargetResourceResult.TcpPort)

            $isInDesiredState = $false
        }
        elseif ($TcpPort -ne $getTargetResourceResult.TcpPort)
        {
            Write-Verbose -Message ($script:localizedData.ExpectedPropertyValue -f 'TcpPort', $TcpPort, $getTargetResourceResult.TcpPort)

            $isInDesiredState = $false
        }
    }

    if ($isInDesiredState)
    {
        Write-Verbose -Message ($script:localizedData.InDesiredState)
    }

    return $isInDesiredState
}

<#
    .SYNOPSIS
    Resolve the IP Adress to the SQL Server protocol key.

    .PARAMETER Protocol
    SQL Server protocol object.

    .PARAMETER IPAddress
    The IP address to resolve.
#>
function Resolve-SqlProtocolIPAddress
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        $Protocol,

        [Parameter(Mandatory = $true)]
        [System.String]
        $IPAddress
    )

    Write-Verbose ($script:localizedData.GetSQLProtocolIPAddressKey -f $IPAddress)

    if ($IPAddress -eq 'IPAll')
    {
        return $IPAddress
    }
    else
    {
        $ipAddressObject = $Protocol.IPAddresses.Where({$_.IPAddress.IPAddressToString -eq $IPAddress})

        if ($null -eq $ipAddressObject)
        {
            throw ($script:localizedData.IPAddressNotFoundError -f $IPAddress)
        }
        else
        {
            return $ipAddressObject.Name
        }
    }
}

Export-ModuleMember -Function *-TargetResource
