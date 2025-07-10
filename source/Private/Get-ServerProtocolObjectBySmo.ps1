<#
    .SYNOPSIS
        Gets server protocol information using SMO objects.

    .DESCRIPTION
        This is a helper function that retrieves server protocol information
        using SMO (SQL Server Management Objects) for backward compatibility.

    .PARAMETER ServerName
        Specifies the name of the server where the SQL Server instance is running.

    .PARAMETER InstanceName
        Specifies the name of the SQL Server instance.

    .PARAMETER ProtocolName
        Specifies the name of the network protocol.

    .NOTES
        This function uses the existing SMO approach that was originally implemented
        in the Get-ServerProtocolObject private function.
#>
function Get-ServerProtocolObjectBySmo
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
        $script:localizedData.ServerProtocol_UsingSmoApproach -f $ProtocolName, $InstanceName, $ServerName
    )

    $serverProtocolObject = $null

    $newObjectParameters = @{
        TypeName     = 'Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer'
        ArgumentList = @($ServerName)
    }

    $managedComputerObject = New-Object @newObjectParameters

    $serverInstance = $managedComputerObject.ServerInstances[$InstanceName]

    if ($serverInstance)
    {
        $protocolNameProperties = Get-ProtocolNameProperties -ProtocolName $ProtocolName

        $serverProtocolObject = $serverInstance.ServerProtocols[$protocolNameProperties.Name]

        if ($serverProtocolObject)
        {
            Write-Verbose -Message (
                $script:localizedData.ServerProtocol_FoundProtocol -f $ProtocolName, $InstanceName, 'SMO'
            )
        }
        else
        {
            $errorMessage = $script:localizedData.ServerProtocol_SmoProtocolNotFound -f $ProtocolName, $InstanceName, $ServerName
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