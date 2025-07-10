<#
    .SYNOPSIS
        Returns server protocol information for a SQL Server instance.

    .DESCRIPTION
        Returns server protocol information for a SQL Server instance using
        either CIM instances or SMO (SQL Server Management Objects) depending
        on availability. The command supports getting information for TcpIp,
        NamedPipes, and SharedMemory protocols.

    .PARAMETER ServerName
        Specifies the name of the server where the SQL Server instance is running.
        Defaults to the local computer name.

    .PARAMETER InstanceName
        Specifies the name of the SQL Server instance for which to return protocol
        information.

    .PARAMETER ProtocolName
        Specifies the name of the network protocol to return information for.
        Valid values are 'TcpIp', 'NamedPipes', and 'SharedMemory'.

    .PARAMETER UseCim
        Specifies to use CIM instances instead of SMO objects. This parameter
        is optional and will be automatically determined based on availability.

    .EXAMPLE
        Get-SqlDscServerProtocol -InstanceName 'MSSQLSERVER' -ProtocolName 'TcpIp'

        Returns TcpIp protocol information for the default SQL Server instance
        on the local computer.

    .EXAMPLE
        Get-SqlDscServerProtocol -ServerName 'MyServer' -InstanceName 'MyInstance' -ProtocolName 'NamedPipes'

        Returns NamedPipes protocol information for the MyInstance SQL Server
        instance on the MyServer computer.

    .EXAMPLE
        Get-SqlDscServerProtocol -InstanceName 'MSSQLSERVER' -ProtocolName 'SharedMemory' -UseCim

        Returns SharedMemory protocol information for the default SQL Server
        instance using CIM instances.

    .OUTPUTS
        System.Object

    .NOTES
        This command supports both CIM and SMO approaches for retrieving server
        protocol information. The CIM approach is preferred when available as
        it provides better performance and compatibility.
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
        $ProtocolName,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $UseCim
    )

    Write-Verbose -Message (
        $script:localizedData.ServerProtocol_GetState -f $ProtocolName, $InstanceName, $ServerName
    )

    $serverProtocolObject = $null

    try
    {
        # Try CIM approach first if requested or if SMO is not available
        if ($UseCim.IsPresent -or $script:preferCimOverSmo)
        {
            $serverProtocolObject = Get-ServerProtocolObjectByCim -ServerName $ServerName -InstanceName $InstanceName -ProtocolName $ProtocolName
        }
        else
        {
            # Fall back to SMO approach
            $serverProtocolObject = Get-ServerProtocolObjectBySmo -ServerName $ServerName -InstanceName $InstanceName -ProtocolName $ProtocolName
        }
    }
    catch
    {
        # If CIM fails and we haven't tried SMO, try SMO approach
        if ($UseCim.IsPresent -or $script:preferCimOverSmo)
        {
            Write-Verbose -Message (
                $script:localizedData.ServerProtocol_CimFallbackToSmo -f $ProtocolName, $InstanceName, $ServerName
            )

            $serverProtocolObject = Get-ServerProtocolObjectBySmo -ServerName $ServerName -InstanceName $InstanceName -ProtocolName $ProtocolName
        }
        else
        {
            throw
        }
    }

    return $serverProtocolObject
}