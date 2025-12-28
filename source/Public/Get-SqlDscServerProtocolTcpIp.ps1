<#
    .SYNOPSIS
        Returns TCP/IP address group information for a SQL Server instance.

    .DESCRIPTION
        Returns TCP/IP address group information for a SQL Server instance using
        SMO (SQL Server Management Objects). The command returns the IP address
        groups configured for the TCP/IP protocol, including their port configuration.

        Each returned object contains an IPAddressProperties collection with
        properties such as 'TcpPort', 'TcpDynamicPorts', 'Enabled', and 'Active'.

    .PARAMETER ServerName
        Specifies the name of the server where the SQL Server instance is running.
        Defaults to the local computer name.

    .PARAMETER InstanceName
        Specifies the name of the SQL Server instance for which to return TCP/IP
        address group information.

    .PARAMETER IpAddressGroup
        Specifies the name of the IP address group to return. Valid values include
        'IPAll', 'IP1', 'IP2', etc. If not specified, all IP address groups are
        returned.

    .PARAMETER ServerProtocolObject
        Specifies a server protocol object from which to retrieve IP address
        information. This parameter accepts pipeline input from Get-SqlDscServerProtocol.
        The protocol object must be the TCP/IP protocol.

    .EXAMPLE
        Get-SqlDscServerProtocolTcpIp -InstanceName 'MSSQLSERVER'

        Returns all TCP/IP address groups for the default SQL Server instance
        on the local computer.

    .EXAMPLE
        Get-SqlDscServerProtocolTcpIp -InstanceName 'MSSQLSERVER' -IpAddressGroup 'IPAll'

        Returns the IPAll address group for the default SQL Server instance
        on the local computer.

    .EXAMPLE
        $ipAllGroup = Get-SqlDscServerProtocolTcpIp -InstanceName 'DSCSQLTEST' -IpAddressGroup 'IPAll'
        $tcpPort = $ipAllGroup.IPAddressProperties['TcpPort'].Value

        Returns the static TCP port configured for the IPAll address group.

    .EXAMPLE
        Get-SqlDscServerProtocol -InstanceName 'MSSQLSERVER' -ProtocolName 'TcpIp' | Get-SqlDscServerProtocolTcpIp

        Uses pipeline input from Get-SqlDscServerProtocol to retrieve all TCP/IP
        address groups.

    .EXAMPLE
        Get-SqlDscServerProtocol -InstanceName 'MSSQLSERVER' -ProtocolName 'TcpIp' | Get-SqlDscServerProtocolTcpIp -IpAddressGroup 'IPAll'

        Uses pipeline input from Get-SqlDscServerProtocol to retrieve the IPAll
        address group.

    .INPUTS
        `Microsoft.SqlServer.Management.Smo.Wmi.ServerProtocol`

        A server protocol object can be piped to this command. The protocol
        object must be the TCP/IP protocol.

    .OUTPUTS
        `Microsoft.SqlServer.Management.Smo.Wmi.ServerIPAddress`

        Returns server IP address objects from SMO (SQL Server Management Objects).

    .NOTES
        The returned ServerIPAddress object's IPAddressProperties collection contains:
        - TcpPort: The static TCP port number(s) as a comma-separated string
        - TcpDynamicPorts: The dynamic port number (only for IPAll group)
        - Enabled: Whether the IP address group is enabled
        - Active: Whether the IP address is active
#>
function Get-SqlDscServerProtocolTcpIp
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [CmdletBinding(DefaultParameterSetName = 'ByServerName')]
    [OutputType([Microsoft.SqlServer.Management.Smo.Wmi.ServerIPAddress])]
    param
    (
        [Parameter(ParameterSetName = 'ByServerName')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName,

        [Parameter(Mandatory = $true, ParameterSetName = 'ByServerName')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstanceName,

        [Parameter(ParameterSetName = 'ByServerName')]
        [Parameter(ParameterSetName = 'ByServerProtocolObject')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $IpAddressGroup,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'ByServerProtocolObject')]
        [Microsoft.SqlServer.Management.Smo.Wmi.ServerProtocol]
        $ServerProtocolObject
    )

    process
    {
        $previousErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'

        # Set default value for ServerName if not provided
        if (-not $PSBoundParameters.ContainsKey('ServerName'))
        {
            $ServerName = Get-ComputerName -ErrorAction 'Stop'
        }

        switch ($PSCmdlet.ParameterSetName)
        {
            'ByServerName'
            {
                if ($PSBoundParameters.ContainsKey('IpAddressGroup'))
                {
                    Write-Verbose -Message (
                        $script:localizedData.ServerProtocolTcpIp_GetIpAddressGroup -f $IpAddressGroup, $InstanceName, $ServerName
                    )
                }
                else
                {
                    Write-Verbose -Message (
                        $script:localizedData.ServerProtocolTcpIp_GetAllIpAddressGroups -f $InstanceName, $ServerName
                    )
                }

                $serverProtocol = Get-SqlDscServerProtocol -ServerName $ServerName -InstanceName $InstanceName -ProtocolName 'TcpIp' -ErrorAction 'Stop'
            }

            'ByServerProtocolObject'
            {
                if ($ServerProtocolObject.Name -ne 'Tcp')
                {
                    $ErrorActionPreference = $previousErrorActionPreference

                    $errorMessage = $script:localizedData.ServerProtocolTcpIp_InvalidProtocol -f $ServerProtocolObject.Name
                    $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                        [System.ArgumentException]::new($errorMessage),
                        'InvalidServerProtocol',
                        [System.Management.Automation.ErrorCategory]::InvalidArgument,
                        $ServerProtocolObject
                    )
                    $PSCmdlet.ThrowTerminatingError($errorRecord)
                }

                $serverProtocol = $ServerProtocolObject

                if ($PSBoundParameters.ContainsKey('IpAddressGroup'))
                {
                    Write-Verbose -Message (
                        $script:localizedData.ServerProtocolTcpIp_GetIpAddressGroupFromProtocol -f $IpAddressGroup
                    )
                }
                else
                {
                    Write-Verbose -Message (
                        $script:localizedData.ServerProtocolTcpIp_GetAllIpAddressGroupsFromProtocol
                    )
                }
            }
        }

        if ($PSBoundParameters.ContainsKey('IpAddressGroup'))
        {
            # Get specific IP address group
            $ipAddressObject = $serverProtocol.IPAddresses[$IpAddressGroup]

            $ErrorActionPreference = $previousErrorActionPreference

            if (-not $ipAddressObject)
            {
                $errorMessage = $script:localizedData.ServerProtocolTcpIp_IpAddressGroupNotFound -f $IpAddressGroup
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    [System.InvalidOperationException]::new($errorMessage),
                    'IpAddressGroupNotFound',
                    [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                    $IpAddressGroup
                )
                $PSCmdlet.ThrowTerminatingError($errorRecord)
            }

            return $ipAddressObject
        }
        else
        {
            # Get all IP address groups
            $allIpAddresses = @()

            foreach ($ipAddress in $serverProtocol.IPAddresses)
            {
                $allIpAddresses += $ipAddress
            }

            $ErrorActionPreference = $previousErrorActionPreference

            foreach ($ipAddressItem in $allIpAddresses)
            {
                $ipAddressItem
            }
        }
    }
}
