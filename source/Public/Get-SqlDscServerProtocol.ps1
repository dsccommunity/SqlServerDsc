<#
    .SYNOPSIS
        Returns server protocol information for a SQL Server instance.

    .DESCRIPTION
        Returns server protocol information for a SQL Server instance using
        SMO (SQL Server Management Objects). The command supports getting
        information for TcpIp, NamedPipes, and SharedMemory protocols.

    .PARAMETER ServerName
        Specifies the name of the server where the SQL Server instance is running.
        Defaults to the local computer name.

    .PARAMETER InstanceName
        Specifies the name of the SQL Server instance for which to return protocol
        information.

    .PARAMETER ProtocolName
        Specifies the name of the network protocol to return information for.
        Valid values are 'TcpIp', 'NamedPipes', and 'SharedMemory'.

    .EXAMPLE
        Get-SqlDscServerProtocol -InstanceName 'MSSQLSERVER' -ProtocolName 'TcpIp'

        Returns TcpIp protocol information for the default SQL Server instance
        on the local computer.

    .EXAMPLE
        Get-SqlDscServerProtocol -ServerName 'MyServer' -InstanceName 'MyInstance' -ProtocolName 'NamedPipes'

        Returns NamedPipes protocol information for the MyInstance SQL Server
        instance on the MyServer computer.

    .EXAMPLE
        Get-SqlDscServerProtocol -InstanceName 'MSSQLSERVER' -ProtocolName 'SharedMemory'

        Returns SharedMemory protocol information for the default SQL Server
        instance.

    .OUTPUTS
        System.Object

    .NOTES
        This command uses SMO (SQL Server Management Objects) to retrieve server
        protocol information from the specified SQL Server instance.
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

        [Parameter(Mandatory = $true)]
        [ValidateSet('TcpIp', 'NamedPipes', 'SharedMemory')]
        [System.String]
        $ProtocolName
    )

    Write-Verbose -Message (
        $script:localizedData.ServerProtocol_GetState -f $ProtocolName, $InstanceName, $ServerName
    )

    $managedComputerObject = Get-SqlDscManagedComputer -ServerName $ServerName

    $serverInstance = $managedComputerObject.ServerInstances[$InstanceName]

    if ($serverInstance)
    {
        $protocolNameProperties = Get-ProtocolNameProperties -ProtocolName $ProtocolName

        $serverProtocolObject = $serverInstance.ServerProtocols[$protocolNameProperties.Name]

        if (-not $serverProtocolObject)
        {
            $errorMessage = $script:localizedData.ServerProtocol_ProtocolNotFound -f $ProtocolName, $InstanceName, $ServerName
            New-InvalidOperationException -Message $errorMessage
        }
    }
    else
    {
        $errorMessage = $script:localizedData.ServerProtocol_InstanceNotFound -f $InstanceName, $ServerName
        New-InvalidOperationException -Message $errorMessage
    }

    return $serverProtocolObject
}