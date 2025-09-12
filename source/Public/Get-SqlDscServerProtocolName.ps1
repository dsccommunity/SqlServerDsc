<#
    .SYNOPSIS
        Returns SQL Server protocol name mappings.

    .DESCRIPTION
        Returns SQL Server protocol name mappings including the protocol name,
        display name, and short name. This command provides standardized
        protocol naming across different SQL Server management interfaces.

    .PARAMETER ProtocolName
        Specifies the protocol name using the ServerProtocols enumeration.
        Valid values are 'TcpIp', 'NamedPipes', and 'SharedMemory'.

    .PARAMETER DisplayName
        Specifies the protocol display name as shown in SQL Server Configuration Manager.
        Valid values are 'TCP/IP', 'Named Pipes', and 'Shared Memory'.

    .PARAMETER ShortName
        Specifies the short protocol name as used by SMO.
        Valid values are 'Tcp', 'Np', and 'Sm'.

    .PARAMETER All
        Returns all available protocol name mappings.

    .EXAMPLE
        Get-SqlDscServerProtocolName -ProtocolName 'TcpIp'

        Returns the protocol name mapping for TCP/IP protocol.

    .EXAMPLE
        Get-SqlDscServerProtocolName -DisplayName 'Named Pipes'

        Returns the protocol name mapping for Named Pipes protocol using its display name.

    .EXAMPLE
        Get-SqlDscServerProtocolName -ShortName 'Sm'

        Returns the protocol name mapping for Shared Memory protocol using its short name.

    .EXAMPLE
        Get-SqlDscServerProtocolName -All

        Returns all available protocol name mappings.

    .INPUTS
        None

    .OUTPUTS
        System.Management.Automation.PSCustomObject

        Returns a PSCustomObject with the properties Name, DisplayName, and ShortName.

    .NOTES
        This command replaces the deprecated Get-ProtocolNameProperties function.
#>
function Get-SqlDscServerProtocolName
{
    [CmdletBinding(DefaultParameterSetName = 'All')]
    [OutputType([System.Management.Automation.PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true, ParameterSetName = 'ByProtocolName')]
        [ValidateSet('TcpIp', 'NamedPipes', 'SharedMemory')]
        [System.String]
        $ProtocolName,

        [Parameter(Mandatory = $true, ParameterSetName = 'ByDisplayName')]
        [ValidateSet('TCP/IP', 'Named Pipes', 'Shared Memory')]
        [System.String]
        $DisplayName,

        [Parameter(Mandatory = $true, ParameterSetName = 'ByShortName')]
        [ValidateSet('Tcp', 'Np', 'Sm')]
        [System.String]
        $ShortName,

        [Parameter(ParameterSetName = 'All')]
        [System.Management.Automation.SwitchParameter]
        $All
    )

    Write-Verbose -Message (
        $script:localizedData.ServerProtocolName_GetProtocolMappings
    )

    # Define all protocol mappings
    $protocolMappings = @(
        [PSCustomObject]@{
            Name = 'TcpIp'
            DisplayName = 'TCP/IP'
            ShortName = 'Tcp'
        },
        [PSCustomObject]@{
            Name = 'NamedPipes'
            DisplayName = 'Named Pipes'
            ShortName = 'Np'
        },
        [PSCustomObject]@{
            Name = 'SharedMemory'
            DisplayName = 'Shared Memory'
            ShortName = 'Sm'
        }
    )

    switch ($PSCmdlet.ParameterSetName)
    {
        'ByProtocolName'
        {
            $result = $protocolMappings | Where-Object -FilterScript { $_.Name -eq $ProtocolName }
        }

        'ByDisplayName'
        {
            $result = $protocolMappings | Where-Object -FilterScript { $_.DisplayName -eq $DisplayName }
        }

        'ByShortName'
        {
            $result = $protocolMappings | Where-Object -FilterScript { $_.ShortName -eq $ShortName }
        }

        'All'
        {
            $result = $protocolMappings
        }
    }

    return $result
}