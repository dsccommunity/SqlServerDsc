<#
    .SYNOPSIS
        Returns server protocol information for a SQL Server instance.

    .DESCRIPTION
        Returns server protocol information for a SQL Server instance using
        SMO (SQL Server Management Objects). The command supports getting
        information for TcpIp, NamedPipes, and SharedMemory protocols.
        If no protocol is specified, all protocols are returned.

    .PARAMETER ServerName
        Specifies the name of the server where the SQL Server instance is running.
        Defaults to the local computer name.

    .PARAMETER InstanceName
        Specifies the name of the SQL Server instance for which to return protocol
        information.

    .PARAMETER ProtocolName
        Specifies the name of the network protocol to return information for.
        Valid values are 'TcpIp', 'NamedPipes', and 'SharedMemory'.
        If not specified, all protocols are returned.

    .EXAMPLE
        Get-SqlDscServerProtocol -InstanceName 'MSSQLSERVER' -ProtocolName 'TcpIp'

        Returns TcpIp protocol information for the default SQL Server instance
        on the local computer.

    .EXAMPLE
        Get-SqlDscServerProtocol -ServerName 'MyServer' -InstanceName 'MyInstance' -ProtocolName 'NamedPipes'

        Returns NamedPipes protocol information for the MyInstance SQL Server
        instance on the MyServer computer.

    .EXAMPLE
        Get-SqlDscServerProtocol -InstanceName 'MSSQLSERVER'

        Returns all protocol information for the default SQL Server instance
        on the local computer.

    .INPUTS
        None

    .OUTPUTS
        System.Object

        Returns protocol objects from SMO (SQL Server Management Objects).

    .NOTES
        This command uses SMO (SQL Server Management Objects) to retrieve server
        protocol information from the specified SQL Server instance.

        The Get-ProtocolNameProperties function used internally is deprecated
        and should be removed in the future when existing code has moved to
        new functionality.
#>
function Get-SqlDscServerProtocol
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = (Get-ComputerName),

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstanceName,

        [Parameter()]
        [ValidateSet('TcpIp', 'NamedPipes', 'SharedMemory')]
        [System.String]
        $ProtocolName
    )

    if ($PSBoundParameters.ContainsKey('ProtocolName'))
    {
        Write-Verbose -Message (
            $script:localizedData.ServerProtocol_GetState -f $ProtocolName, $InstanceName, $ServerName
        )
    }
    else
    {
        Write-Verbose -Message (
            $script:localizedData.ServerProtocol_GetAllProtocols -f $InstanceName, $ServerName
        )
    }

    $managedComputerObject = Get-SqlDscManagedComputer -ServerName $ServerName

    $serverInstance = $managedComputerObject.ServerInstances[$InstanceName]

    if ($serverInstance)
    {
        if ($PSBoundParameters.ContainsKey('ProtocolName'))
        {
            # Get specific protocol
            $protocolMapping = Get-SqlDscServerProtocolName -ProtocolName $ProtocolName

            $serverProtocolObject = $serverInstance.ServerProtocols[$protocolMapping.ShortName]

            if (-not $serverProtocolObject)
            {
                $errorMessage = $script:localizedData.ServerProtocol_ProtocolNotFound -f $ProtocolName, $InstanceName, $ServerName
                New-InvalidOperationException -Message $errorMessage
            }

            return $serverProtocolObject
        }
        else
        {
            # Get all protocols
            $allProtocolMappings = Get-SqlDscServerProtocolName -All
            $allServerProtocols = @()

            foreach ($protocolMapping in $allProtocolMappings)
            {
                $serverProtocolObject = $serverInstance.ServerProtocols[$protocolMapping.ShortName]

                if ($serverProtocolObject)
                {
                    $allServerProtocols += $serverProtocolObject
                }
            }

            return $allServerProtocols
        }
    }
    else
    {
        $errorMessage = $script:localizedData.ServerProtocol_InstanceNotFound -f $InstanceName, $ServerName
        New-InvalidOperationException -Message $errorMessage
    }
}