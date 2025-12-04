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

    .PARAMETER ManagedComputerObject
        Specifies a managed computer object from which to retrieve server protocol
        information. This parameter accepts pipeline input from Get-SqlDscManagedComputer.

    .PARAMETER ManagedComputerInstanceObject
        Specifies a managed computer instance object from which to retrieve server
        protocol information. This parameter accepts pipeline input from
        Get-SqlDscManagedComputerInstance.

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

    .EXAMPLE
        Get-SqlDscManagedComputer -ServerName 'MyServer' | Get-SqlDscServerProtocol -InstanceName 'MyInstance'

        Uses pipeline input from Get-SqlDscManagedComputer to retrieve all protocols
        for the specified instance.

    .EXAMPLE
        Get-SqlDscManagedComputerInstance -InstanceName 'MyInstance' | Get-SqlDscServerProtocol -ProtocolName 'TcpIp'

        Uses pipeline input from Get-SqlDscManagedComputerInstance to retrieve TcpIp
        protocol information.

    .INPUTS
        `Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer`

        A managed computer object can be piped to this command.

    .INPUTS
        `Microsoft.SqlServer.Management.Smo.Wmi.ServerInstance`

        A server instance object can be piped to this command.

    .OUTPUTS
        `Microsoft.SqlServer.Management.Smo.Wmi.ServerProtocol`

        Returns server protocol objects from SMO (SQL Server Management Objects).
#>
function Get-SqlDscServerProtocol
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [CmdletBinding(DefaultParameterSetName = 'ByServerName')]
    [OutputType([Microsoft.SqlServer.Management.Smo.Wmi.ServerProtocol])]
    param
    (
        [Parameter(ParameterSetName = 'ByServerName')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName,

        [Parameter(Mandatory = $true, ParameterSetName = 'ByServerName')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ByManagedComputerObject')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstanceName,

        [Parameter(ParameterSetName = 'ByServerName')]
        [Parameter(ParameterSetName = 'ByManagedComputerObject')]
        [Parameter(ParameterSetName = 'ByManagedComputerInstanceObject')]
        [ValidateSet('TcpIp', 'NamedPipes', 'SharedMemory')]
        [System.String]
        $ProtocolName,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'ByManagedComputerObject')]
        [Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer]
        $ManagedComputerObject,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'ByManagedComputerInstanceObject')]
        [Microsoft.SqlServer.Management.Smo.Wmi.ServerInstance]
        $ManagedComputerInstanceObject
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

        switch ($PSCmdlet.ParameterSetName)
        {
            'ByServerName'
            {
                $serverInstance = Get-SqlDscManagedComputerInstance -ServerName $ServerName -InstanceName $InstanceName -ErrorAction 'Stop'
            }

            'ByManagedComputerObject'
            {
                $serverInstance = $ManagedComputerObject | Get-SqlDscManagedComputerInstance -InstanceName $InstanceName -ErrorAction 'Stop'
            }

            'ByManagedComputerInstanceObject'
            {
                $serverInstance = $ManagedComputerInstanceObject
            }
        }

        if ($PSBoundParameters.ContainsKey('ProtocolName'))
        {
            # Get specific protocol
            $protocolMapping = Get-SqlDscServerProtocolName -ProtocolName $ProtocolName -ErrorAction 'Stop'

            $serverProtocolObject = $serverInstance.ServerProtocols[$protocolMapping.ShortName]

            $ErrorActionPreference = $previousErrorActionPreference

            if (-not $serverProtocolObject)
            {
                $errorMessage = $script:localizedData.ServerProtocol_ProtocolNotFound -f $protocolMapping.DisplayName, $InstanceName, $serverInstance.Parent.Name
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    [System.InvalidOperationException]::new($errorMessage),
                    'SqlServerProtocolNotFound',
                    [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                    $ProtocolName
                )
                $PSCmdlet.ThrowTerminatingError($errorRecord)
            }

            return $serverProtocolObject
        }
        else
        {
            # Get all protocols
            $allProtocolMappings = Get-SqlDscServerProtocolName -All -ErrorAction 'Stop'
            $allServerProtocols = @()

            foreach ($protocolMapping in $allProtocolMappings)
            {
                $serverProtocolObject = $serverInstance.ServerProtocols[$protocolMapping.ShortName]

                if ($serverProtocolObject)
                {
                    $allServerProtocols += $serverProtocolObject
                }
            }

            $ErrorActionPreference = $previousErrorActionPreference

            if ($allServerProtocols.Count -eq 0)
            {
                return $null
            }

            return $allServerProtocols
        }
    }
}
