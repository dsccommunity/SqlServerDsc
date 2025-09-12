<#
    .SYNOPSIS
        Returns managed computer server instance information.

    .DESCRIPTION
        Returns managed computer server instance information for a SQL Server instance
        using SMO (SQL Server Management Objects). The command can retrieve a specific
        instance or all instances on a managed computer.

    .PARAMETER ServerName
        Specifies the name of the server where the SQL Server instance is running.
        Defaults to the local computer name.

    .PARAMETER InstanceName
        Specifies the name of the SQL Server instance to retrieve.
        If not specified, all instances are returned.

    .PARAMETER ManagedComputerObject
        Specifies a managed computer object from which to retrieve server instances.
        This parameter accepts pipeline input from Get-SqlDscManagedComputer.

    .EXAMPLE
        Get-SqlDscManagedComputerInstance -InstanceName 'MSSQLSERVER'

        Returns the default SQL Server instance information from the local computer.

    .EXAMPLE
        Get-SqlDscManagedComputerInstance -ServerName 'MyServer' -InstanceName 'MyInstance'

        Returns the MyInstance SQL Server instance information from the MyServer computer.

    .EXAMPLE
        Get-SqlDscManagedComputerInstance -ServerName 'MyServer'

        Returns all SQL Server instances information from the MyServer computer.

    .EXAMPLE
        Get-SqlDscManagedComputer -ServerName 'MyServer' | Get-SqlDscManagedComputerInstance -InstanceName 'MyInstance'

        Uses pipeline input to retrieve a specific instance from a managed computer object.

    .INPUTS
        Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer

        A managed computer object can be piped to this command.

    .OUTPUTS
        Microsoft.SqlServer.Management.Smo.Wmi.ServerInstance

        Returns server instance objects from SMO (SQL Server Management Objects).

    .NOTES
        This command uses SMO (SQL Server Management Objects) to retrieve server
        instance information from the specified managed computer.
#>
function Get-SqlDscManagedComputerInstance
{
    [CmdletBinding(DefaultParameterSetName = 'ByServerName')]
    [OutputType([Microsoft.SqlServer.Management.Smo.Wmi.ServerInstance])]
    param
    (
        [Parameter(ParameterSetName = 'ByServerName')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = (Get-ComputerName),

        [Parameter(ParameterSetName = 'ByServerName')]
        [Parameter(ParameterSetName = 'ByManagedComputerObject')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'ByManagedComputerObject')]
        [System.Object]
        $ManagedComputerObject
    )

    process
    {
        if ($PSCmdlet.ParameterSetName -eq 'ByServerName')
        {
            Write-Verbose -Message (
                $script:localizedData.ManagedComputerInstance_GetFromServer -f $ServerName
            )

            $ManagedComputerObject = Get-SqlDscManagedComputer -ServerName $ServerName
        }
        else
        {
            Write-Verbose -Message (
                $script:localizedData.ManagedComputerInstance_GetFromObject
            )


        }

        if ($PSBoundParameters.ContainsKey('InstanceName'))
        {
            Write-Verbose -Message (
                $script:localizedData.ManagedComputerInstance_GetSpecificInstance -f $InstanceName
            )

            $serverInstance = $ManagedComputerObject.ServerInstances[$InstanceName]

            if (-not $serverInstance)
            {
                $errorMessage = $script:localizedData.ManagedComputerInstance_InstanceNotFound -f $InstanceName, $ManagedComputerObject.Name
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    [System.InvalidOperationException]::new($errorMessage),
                    'SqlServerInstanceNotFound',
                    [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                    $InstanceName
                )
                $PSCmdlet.ThrowTerminatingError($errorRecord)
            }

            return $serverInstance
        }
        else
        {
            Write-Verbose -Message (
                $script:localizedData.ManagedComputerInstance_GetAllInstances
            )

            return $ManagedComputerObject.ServerInstances
        }
    }
}
