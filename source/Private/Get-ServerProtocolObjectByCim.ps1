<#
    .SYNOPSIS
        Gets server protocol information using CIM instances.

    .DESCRIPTION
        This is a helper function that retrieves server protocol information
        using CIM instances for better performance and compatibility.

    .PARAMETER ServerName
        Specifies the name of the server where the SQL Server instance is running.

    .PARAMETER InstanceName
        Specifies the name of the SQL Server instance.

    .PARAMETER ProtocolName
        Specifies the name of the network protocol.

    .NOTES
        This function tries multiple SQL Server CIM namespaces to find the
        appropriate one for the SQL Server version installed.
#>
function Get-ServerProtocolObjectByCim
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName,

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
        $script:localizedData.ServerProtocol_UsingCimApproach -f $ProtocolName, $InstanceName, $ServerName
    )

    $protocolNameProperties = Get-ProtocolNameProperties -ProtocolName $ProtocolName

    # Try to find the appropriate SQL Server version namespace
    $sqlServerNamespaces = @(
        'ROOT\Microsoft\SqlServer\ComputerManagement16', # SQL Server 2022
        'ROOT\Microsoft\SqlServer\ComputerManagement15', # SQL Server 2019
        'ROOT\Microsoft\SqlServer\ComputerManagement14', # SQL Server 2017
        'ROOT\Microsoft\SqlServer\ComputerManagement13', # SQL Server 2016
        'ROOT\Microsoft\SqlServer\ComputerManagement12', # SQL Server 2014
        'ROOT\Microsoft\SqlServer\ComputerManagement11', # SQL Server 2012
        'ROOT\Microsoft\SqlServer\ComputerManagement10'  # SQL Server 2008
    )

    $serverProtocolObject = $null

    foreach ($namespace in $sqlServerNamespaces)
    {
        try
        {
            Write-Verbose -Message (
                $script:localizedData.ServerProtocol_TryingNamespace -f $namespace
            )

            $cimInstances = Get-CimInstance -ComputerName $ServerName -Namespace $namespace -ClassName 'ServerNetworkProtocol' -ErrorAction 'Stop'

            $serverProtocolObject = $cimInstances | Where-Object -FilterScript {
                $_.InstanceName -eq $InstanceName -and $_.ProtocolName -eq $protocolNameProperties.Name
            }

            if ($serverProtocolObject)
            {
                Write-Verbose -Message (
                    $script:localizedData.ServerProtocol_FoundProtocol -f $ProtocolName, $InstanceName, $namespace
                )
                break
            }
        }
        catch
        {
            Write-Verbose -Message (
                $script:localizedData.ServerProtocol_NamespaceNotFound -f $namespace, $_.Exception.Message
            )
            continue
        }
    }

    if (-not $serverProtocolObject)
    {
        $errorMessage = $script:localizedData.ServerProtocol_CimProtocolNotFound -f $ProtocolName, $InstanceName, $ServerName
        New-InvalidOperationException -Message $errorMessage
    }

    return $serverProtocolObject
}