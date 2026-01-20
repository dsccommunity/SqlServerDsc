<#
    .SYNOPSIS
        Restarts a SQL Server cluster instance and associated services

    .PARAMETER InstanceName
        Specifies the instance name that matches a SQL Server MSCluster_Resource
        property <clustergroup>.PrivateProperties.InstanceName.

    .PARAMETER Timeout
        Timeout value for restarting the SQL services. The default value is 120 seconds.

    .PARAMETER OwnerNode
        Specifies a list of owner nodes names of a cluster groups. If the SQL Server
        instance is a Failover Cluster instance then the cluster group will only
        be taken offline and back online when the owner of the cluster group is
        one of the nodes specified in this list. These node names specified in this
        parameter must match the Owner property of the cluster resource, for example
        @('sqltest10', 'SQLTEST11'). The names are case-insensitive.
        If this parameter is not specified the cluster group will be taken offline
        and back online regardless of owner.
#>
function Restart-SqlClusterService
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter()]
        [System.UInt32]
        $Timeout = 120,

        [Parameter()]
        [System.String[]]
        $OwnerNode
    )

    # Get the cluster resources
    Write-Verbose -Message ($script:localizedData.GetSqlServerClusterResources) -Verbose

    $sqlService = Get-CimInstance -Namespace 'root/MSCluster' -ClassName 'MSCluster_Resource' -Filter "Type = 'SQL Server'" |
        Where-Object -FilterScript {
            $_.PrivateProperties.InstanceName -eq $InstanceName -and $_.State -eq 2
        }

    # If the cluster resource is found and online then continue.
    if ($sqlService)
    {
        $isOwnerOfClusterResource = $true

        if ($PSBoundParameters.ContainsKey('OwnerNode') -and $sqlService.OwnerNode -notin $OwnerNode)
        {
            $isOwnerOfClusterResource = $false
        }

        if ($isOwnerOfClusterResource)
        {
            Write-Verbose -Message ($script:localizedData.GetSqlAgentClusterResource) -Verbose

            $agentService = $sqlService |
                Get-CimAssociatedInstance -ResultClassName MSCluster_Resource |
                Where-Object -FilterScript {
                    $_.Type -eq 'SQL Server Agent' -and $_.State -eq 2
                }

            # Build a listing of resources being acted upon
            $resourceNames = @($sqlService.Name, ($agentService |
                        Select-Object -ExpandProperty Name)) -join "', '"

            # Stop the SQL Server and dependent resources
            Write-Verbose -Message ($script:localizedData.BringClusterResourcesOffline -f $resourceNames) -Verbose

            $sqlService |
                Invoke-CimMethod -MethodName TakeOffline -Arguments @{
                    Timeout = $Timeout
                }

            # Start the SQL server resource
            Write-Verbose -Message ($script:localizedData.BringSqlServerClusterResourcesOnline) -Verbose

            $sqlService |
                Invoke-CimMethod -MethodName BringOnline -Arguments @{
                    Timeout = $Timeout
                }

            # Start the SQL Agent resource
            if ($agentService)
            {
                if ($PSBoundParameters.ContainsKey('OwnerNode') -and $agentService.OwnerNode -notin $OwnerNode)
                {
                    $isOwnerOfClusterResource = $false
                }

                if ($isOwnerOfClusterResource)
                {
                    Write-Verbose -Message ($script:localizedData.BringSqlServerAgentClusterResourcesOnline) -Verbose

                    $agentService |
                        Invoke-CimMethod -MethodName BringOnline -Arguments @{
                            Timeout = $Timeout
                        }
                }
                else
                {
                    Write-Verbose -Message (
                        $script:localizedData.NotOwnerOfClusterResource -f (Get-ComputerName), $agentService.Name, $agentService.OwnerNode
                    ) -Verbose
                }
            }
        }
        else
        {
            Write-Verbose -Message (
                $script:localizedData.NotOwnerOfClusterResource -f (Get-ComputerName), $sqlService.Name, $sqlService.OwnerNode
            ) -Verbose
        }
    }
    else
    {
        Write-Warning -Message ($script:localizedData.ClusterResourceNotFoundOrOffline -f $InstanceName)
    }
}
