<#
    .SYNOPSIS
        Restarts a SQL Server instance and associated services

    .PARAMETER ServerName
        Hostname of the SQL Server to be configured

    .PARAMETER InstanceName
        Name of the SQL instance to be configured. Default is 'MSSQLSERVER'

    .PARAMETER Timeout
        Timeout value for restarting the SQL services. The default value is 120 seconds.

    .PARAMETER SkipClusterCheck
        If cluster check should be skipped. If this is present no connection
        is made to the instance to check if the instance is on a cluster.

        This need to be used for some resource, for example for the SqlServerNetwork
        resource when it's used to enable a disable protocol.

    .PARAMETER SkipWaitForOnline
        If this is present no connection is made to the instance to check if the
        instance is online.

        This need to be used for some resource, for example for the SqlServerNetwork
        resource when it's used to disable protocol.

    .PARAMETER OwnerNode
        Specifies a list of owner nodes names of a cluster groups. If the SQL Server
        instance is a Failover Cluster instance then the cluster group will only
        be taken offline and back online when the owner of the cluster group is
        one of the nodes specified in this list. These node names specified in this
        parameter must match the Owner property of the cluster resource, for example
        @('sqltest10', 'SQLTEST11'). The names are case-insensitive.
        If this parameter is not specified the cluster group will be taken offline
        and back online regardless of owner.

    .EXAMPLE
        Restart-SqlService -ServerName localhost

    .EXAMPLE
        Restart-SqlService -ServerName localhost -InstanceName 'NamedInstance'

    .EXAMPLE
        Restart-SqlService -ServerName localhost -InstanceName 'NamedInstance' -SkipClusterCheck -SkipWaitForOnline

    .EXAMPLE
        Restart-SqlService -ServerName CLU01 -Timeout 300

    .EXAMPLE
        Restart-SqlService -ServerName CLU01 -Timeout 300 -OwnerNode 'testclu10'
#>
function Restart-SqlService
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ServerName,

        [Parameter()]
        [System.String]
        $InstanceName = 'MSSQLSERVER',

        [Parameter()]
        [System.UInt32]
        $Timeout = 120,

        [Parameter()]
        [Switch]
        $SkipClusterCheck,

        [Parameter()]
        [Switch]
        $SkipWaitForOnline,

        [Parameter()]
        [System.String[]]
        $OwnerNode
    )

    $restartWindowsService = $true

    # Check if a cluster, otherwise assume that a Windows service should be restarted.
    if (-not $SkipClusterCheck.IsPresent)
    {
        ## Connect to the instance
        $serverObject = Connect-SQL -ServerName $ServerName -InstanceName $InstanceName -ErrorAction 'Stop'

        if ($serverObject.IsClustered)
        {
            # Make sure Windows service is not restarted outside of the cluster.
            $restartWindowsService = $false

            $restartSqlClusterServiceParameters = @{
                InstanceName = $serverObject.ServiceName
            }

            if ($PSBoundParameters.ContainsKey('Timeout'))
            {
                $restartSqlClusterServiceParameters['Timeout'] = $Timeout
            }

            if ($PSBoundParameters.ContainsKey('OwnerNode'))
            {
                $restartSqlClusterServiceParameters['OwnerNode'] = $OwnerNode
            }

            Restart-SqlClusterService @restartSqlClusterServiceParameters
        }
    }

    if ($restartWindowsService)
    {
        if ($InstanceName -eq 'MSSQLSERVER')
        {
            $serviceName = 'MSSQLSERVER'
        }
        else
        {
            $serviceName = 'MSSQL${0}' -f $InstanceName
        }

        Write-Verbose -Message ($script:localizedData.GetServiceInformation -f 'SQL Server') -Verbose

        $sqlService = Get-Service -Name $serviceName

        <#
            Get all dependent services that are running.
            There are scenarios where an automatic service is stopped and should not be restarted automatically.
        #>
        $agentService = $sqlService.DependentServices |
            Where-Object -FilterScript { $_.Status -eq 'Running' }

        # Restart the SQL Server service
        Write-Verbose -Message ($script:localizedData.RestartService -f 'SQL Server') -Verbose
        $sqlService |
            Restart-Service -Force

        # Start dependent services
        $agentService |
            ForEach-Object -Process {
                Write-Verbose -Message ($script:localizedData.StartingDependentService -f $_.DisplayName) -Verbose
                $_ | Start-Service
            }
    }

    Write-Verbose -Message ($script:localizedData.WaitingInstanceTimeout -f $ServerName, $InstanceName, $Timeout) -Verbose

    if (-not $SkipWaitForOnline.IsPresent)
    {
        $connectTimer = [System.Diagnostics.StopWatch]::StartNew()

        $connectSqlError = $null

        do
        {
            # This call, if it fails, will take between ~9-10 seconds to return.
            $testConnectionServerObject = Connect-SQL -ServerName $ServerName -InstanceName $InstanceName -ErrorAction 'SilentlyContinue' -ErrorVariable 'connectSqlError'

            # Make sure we have an SMO object to test Status
            if ($testConnectionServerObject)
            {
                if ($testConnectionServerObject.Status -eq 'Online')
                {
                    break
                }
            }

            # Waiting 2 seconds to not hammer the SQL Server instance.
            Start-Sleep -Seconds 2
        } until ($connectTimer.Elapsed.TotalSeconds -ge $Timeout)

        $connectTimer.Stop()

        # Was the timeout period reach before able to connect to the SQL Server instance?
        if (-not $testConnectionServerObject -or $testConnectionServerObject.Status -ne 'Online')
        {
            $errorMessage = $script:localizedData.FailedToConnectToInstanceTimeout -f @(
                $ServerName,
                $InstanceName,
                $Timeout
            )

            $newInvalidOperationExceptionParameters = @{
                Message = $errorMessage
            }

            if ($connectSqlError)
            {
                $newInvalidOperationExceptionParameters.ErrorRecord = $connectSqlError[$connectSqlError.Count - 1]
            }

            New-InvalidOperationException @newInvalidOperationExceptionParameters
        }
    }
}
