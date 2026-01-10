---
Category: How-to
---

# Setting up a SQL Server AlwaysOn Availability Groups

This will reference examples that show how to setup high availability using
AlwaysOn Availability Group.
It assumes that a working domain exists with at least one Domain Controller,
and both servers that should contain the SQL Server nodes are domain joined.

## Prepare Active Directory

Please see [Prepare Active Directory](#prepare-active-directory). The same applies
to the failover cluster needed for SQL Server AlwaysOn Availability Groups.

## Create Failover Cluster

Please see [Create Failover Cluster](#create-failover-cluster). The same applies
to the failover cluster needed for SQL Server AlwaysOn Availability Groups.

## Install SQL Server on replicas

> [!NOTE]
> Make sure any user accounts you use in the configuration exist in
> Active Directory and that they have the correct permission.

### Install SQL Server on the primary node

The example shows how to
[install a SQL Server named instance on a single server](https://github.com/PowerShell/SqlServerDsc/blob/dev/Examples/Resources/SqlSetup/2-InstallNamedInstanceSingleServer.ps1)
which will be used as the primary replica node in the SQL Server AlwaysOn
Availability Group.

### Install SQL Server on the secondary node

The example shows how to
[install a SQL Server named instance on a single server](https://github.com/PowerShell/SqlServerDsc/blob/dev/Examples/Resources/SqlSetup/2-InstallNamedInstanceSingleServer.ps1)
which will be used as the secondary replica node in the SQL Server AlwaysOn
Availability Group.

## Enable AlwaysOn on both primary and secondary replica

AlwaysOn must be enabled on both the primary and secondary replica, and the example
[Enable AlwaysOn](https://github.com/PowerShell/SqlServerDsc/blob/dev/Examples/Resources/SqlAlwaysOnService/1-EnableAlwaysOn.ps1)
shows how to enable it (which requires that a working Failover Cluster is
present on the node).

## Configure SQL Server AlwaysOn Availability Group

Once AlwaysOn is enabled we can create the Availability Group. The example
[Create Availability Group](https://github.com/PowerShell/SqlServerDsc/blob/dev/Examples/Resources/SqlAGReplica/1-CreateAvailabilityGroupReplica.ps1)
shows how to create the Availability Group on the primary replica and join the
Availability Group on the secondary replica.

> [!IMPORTANT]
> Make sure any user accounts you use in the configuration exist in
> Active Directory and that they have the correct permission.
