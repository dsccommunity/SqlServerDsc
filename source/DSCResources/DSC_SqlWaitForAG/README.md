# Description

The `SqlWaitForAG` DSC resource will wait for a cluster role/group to be
created. When the cluster group is found it will wait for the availability group to become available. 
When the availability group has been found the resource will wait the amount of time specified 
in the parameter RetryIntervalSec before returning.

## Requirements

* Target machine must be running Windows Server 2012 or later.
* Target machine must be running SQL Server Database Engine 2012 or later.
* Target machine must have access to the Failover Cluster PowerShell module.

## Security Requirements

* The account running this resource must have permission in the cluster to be able
  to run the cmdlet Get-ClusterGroup.

## Known issues

All issues are not listed here, see [here for all open issues](https://github.com/dsccommunity/SqlServerDsc/issues?q=is%3Aissue+is%3Aopen+in%3Atitle+SqlWaitForAG).
