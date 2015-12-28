[reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo")
[reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.SqlWmiManagement")

Function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param(
        [parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        # for now support is just for tcp protocol
        # possible future feature to support aditional protocols
        [parameter(Mandatory = $true)]
        [ValidateSet("tcp")]
        [System.String]
        $ProtocolName
    )
    Write-Verbose "xSQLServerNetwork.Get-TargetResourece ..."
    Write-Verbose "Parameters: InstanceName = $InstanceName; ProtocolName = $ProtocolName"

    Write-Verbose "Loading [Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer] wmi object"
    $wmi = new-object Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer

    Write-Verbose "Getting [$ProtocolName] network protocol for [$InstanceName] SQL instance"
    $tcp = $wmi.ServerInstances[$InstanceName].ServerProtocols[$ProtocolName]

    Write-Verbose "Reading state values:"
    $returnValue = @{
        InstanceName = $InstanceName
        ProtocolName = $ProtocolName
        IsEnabled = $tcp.IsEnabled
        TCPDynamicPorts = $tcp.IPAddresses["IPAll"].IPAddressProperties["TcpDynamicPorts"].Value
        TCPPort = $tcp.IPAddresses["IPAll"].IPAddressProperties["TcpPort"].Value
    }

    $returnValue.Keys | % { Write-Verbose "$_ = $($returnValue[$_])" }
    
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
        [ValidateSet("tcp")]
        [System.String]
        $ProtocolName,

        [System.Boolean]
        $IsEnabled,

        [ValidateSet("0")]
        [System.String]
        $TCPDynamicPorts,

        [System.String]
        $TCPPort,

        [System.Boolean]
        $RestartService = $false
    )
    Write-Verbose "xSQLServerNetwork.Set-TargetResource ..."
    Write-Verbose "Parameters: InstanceName = $InstanceName; ProtocolName = $ProtocolName; IsEnabled=$IsEnabled; TCPDynamicPorts = $TCPDynamicPorts; TCPPort = $TCPPort; RestartService=$RestartService;"
      
    $serviceSate = [Microsoft.SqlServer.Management.Smo.Wmi.ServiceState]

    $desiredState = @{
        InstanceName = $InstanceName
        ProtocolName = $ProtocolName
        IsEnabled = $IsEnabled
        TCPDynamicPorts = $TCPDynamicPorts
        TCPPort = $TCPPort
    }
    
    Write-Verbose "Calling xSQLServerNetwork.Get-TargetResource ..."
    $currentState = Get-TargetResource -InstanceName $InstanceName -ProtocolName $ProtocolName

    Write-Verbose "Loading [Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer] wmi object"
    $wmi = new-object Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer

    Write-Verbose "Getting [$ProtocolName] network protocol for [$InstanceName] SQL instance"
    $tcp = $wmi.ServerInstances[$InstanceName].ServerProtocols[$ProtocolName]

    Write-Verbose "Checking [IsEnabled] property ..."
    if($desiredState["IsEnabled"] -ine $currentState["IsEnabled"])
    {
        Write-Verbose "Updating [IsEnabled] from $($currentState["IsEnabled"]) to $($desiredState["IsEnabled"])"
        $tcp.IsEnabled = $desiredState["IsEnabled"]
    }

    Write-Verbose "Checking [TCPDynamicPorts] property ..."
    if($desiredState["TCPDynamicPorts"] -ine $currentState["TCPDynamicPorts"])
    {
        Write-Verbose "Updating [TCPDynamicPorts] from $($currentState["TCPDynamicPorts"]) to $($desiredState["TCPDynamicPorts"])"
        $tcp.IPAddresses["IPAll"].IPAddressProperties["TcpDynamicPorts"].Value = $desiredState["TCPDynamicPorts"]
    }

    Write-Verbose "Checking [TCPPort property] ..."
    if($desiredState["TCPPort"] -ine $currentState["TCPPort"])
    {
        Write-Verbose "Updating [TCPPort] from $($currentState["TCPPort"]) to $($desiredState["TCPPort"])"
        $tcp.IPAddresses["IPAll"].IPAddressProperties["TcpPort"].Value = $desiredState["TCPPort"]
    }

    Write-Verbose "Saving changes ..."
    $tcp.Alter()

    if($RestartService)
    {
        Write-Verbose "SQL Service will be restarted ..."
        if($InstanceName -eq "MSSQLSERVER")
        {
            $DBServiceName = "MSSQLSERVER"
            $AgtServiceName = "SQLSERVERAGENT"
        }
        else
        {
            $DBServiceName = "MSSQL`$$InstanceName"
            $AgtServiceName = "SQLAgent`$$InstanceName"
        }

        $sqlService = $wmi.Services[$DBServiceName]
        $agentService = $wmi.Services[$AgtServiceName]
        $startAgent = ($agentService.ServiceState -eq $serviceSate::Running)

        Write-Verbose "Stopping [$DBServiceName] service ..."
        $sqlService.Stop()

        while($sqlService.ServiceState -ne $serviceSate::Stopped)
        {
            Start-Sleep -Milliseconds 500
            $sqlService.Refresh()
        }
        Write-Verbose "[$DBServiceName] service stopped"

        Write-Verbose "Starting [$DBServiceName] service ..."
        $sqlService.Start()

        while($sqlService.ServiceState -ne $serviceSate::Running)
        {
            Start-Sleep -Milliseconds 500
            $sqlService.Refresh()
        }
        Write-Verbose "[$DBServiceName] service started"

        if ($startAgent)
        {
            Write-Verbose "Staring [$AgtServiceName] service ..."
            $agentService.Start()
            while($agentService.ServiceState -ne $serviceSate::Running)
            {
                Start-Sleep -Milliseconds 500
                $agentService.Refresh()
            }
            Write-Verbose "[$AgtServiceName] service started"
        }

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
        [ValidateSet("tcp")]
        [System.String]
        $ProtocolName,

        [System.Boolean]
        $IsEnabled,

        [ValidateSet("0")]
        [System.String]
        $TCPDynamicPorts,

        [System.String]
        $TCPPort,

        [System.Boolean]
        $RestartService = $false
    )
    Write-Verbose "xSQLServerNetwork.Test-TargetResource ..."
    Write-Verbose "Parameters: InstanceName = $InstanceName; ProtocolName = $ProtocolName; IsEnabled=$IsEnabled; TCPDynamicPorts = $TCPDynamicPorts; TCPPort = $TCPPort; RestartService=$RestartService;"

    $desiredState = @{
        InstanceName = $InstanceName
        ProtocolName = $ProtocolName
        IsEnabled = $IsEnabled
        TCPDynamicPorts = $TCPDynamicPorts
        TCPPort = $TCPPort
    } 
    
    Write-Verbose "Calling xSQLServerNetwork.Get-TargetResource ..."
    $currentState = Get-TargetResource -InstanceName $InstanceName -ProtocolName $ProtocolName

    Write-Verbose "Comparing desiredState with currentSate ..."
    foreach($key in $desiredState.Keys)
    {
        if($currentState.Keys -eq $key)
        {
            if($desiredState[$key] -ine $currentState[$key] )
            {
                Write-Verbose "$key is different: desired = $($desiredState[$key]); current = $($currentState[$key])"
                return $false
            }
        }
        else
        {
            Write-Verbose "$key is missing"
            return $false
        }
    }

    Write-Verbose "States match"        
    return $true
}

Export-ModuleMember -Function *-TargetResource