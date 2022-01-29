# Examples

This will help to understand how to setup certain scenarios with SqlServerDsc
resource module.

## Resource examples

These are the links to the examples for each individual resource.

- [SqlAG](Resources/SqlAG)
- [SqlAGDatabase](Resources/SqlAGDatabase)
- [SqlAgentAlert](Resources/SqlAgentAlert)
- [SqlAgentOperator](Resources/SqlAgentOperator)
- [SqlAGListener](Resources/SqlAGListener)
- [SqlAGReplica](Resources/SqlAGReplica)
- [SqlAlias](Resources/SqlAlias)
- [SqlAlwaysOnService](Resources/SqlAlwaysOnService)
- [SqlDatabase](Resources/SqlDatabase)
- [SqlDatabaseDefaultLocation](Resources/SqlDatabaseDefaultLocation)
- [SqlDatabasePermission](Resources/SqlDatabasePermission)
- [SqlDatabaseRole](Resources/SqlDatabaseRole)
- [SqlDatabaseUser](Resources/SqlDatabaseUser)
- [SqlRS](Resources/SqlRS)
- [SqlRSSetup](Resources/SqlRSSetup)
- [SqlScript](Resources/SqlScript)
- [SqlScriptQuery](Resources/SqlScriptQuery)
- [SqlConfiguration](Resources/SqlConfiguration)
- [SqlDatabaseMail](Resources/SqlDatabaseMail)
- [SqlEndpoint](Resources/SqlEndpoint)
- [SqlEndpointPermission](Resources/SqlEndpointPermission)
- [SqlLogin](Resources/SqlLogin)
- [SqlMaxDop](Resources/SqlMaxDop)
- [SqlMemory](Resources/SqlMemory)
- [SqlPermission](Resources/SqlPermission)
- [SqlReplication](Resources/SqlReplication)
- [SqlRole](Resources/SqlRole)
- [SqlSecureConnection](Resources/SqlSecureConnection)
- [SqlServiceAccount](Resources/SqlServiceAccount)
- [SqlSetup](Resources/SqlSetup)
- [SqlWaitForAG](Resources/SqlWaitForAG)
- [SqlWindowsFirewall](Resources/SqlWindowsFirewall)

## Setting up a SQL Server Failover Cluster

This will reference examples that show how to setup high availability SQL Server
using a Failover Cluster.
It assumes that a working domain exists with at least one Domain Controller, and
and both servers that should contain the SQL Server nodes are domain joined.

### Prepare Active Directory

If the user who creates the failover cluster has the **Create Computer Objects**
permission to the organizational unit (OU) where the servers that will form the
cluster reside, then there is no need to prestage the Cluster Named Object (CNO)
computer object.
However, if the user creating the failover cluster does not have this permission,
prestaging the Cluster Named Object (CNO) computer object becomes necessary.
It is also possible to prestage the Virtual Computer Objects (VCO).

Read more about it here
[Prestage Cluster Computer Objects in Active Directory Domain Services](https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2012-R2-and-2012/dn466519(v=ws.11)).

#### Prestage the Cluster Named Object (CNO) computer object

There could be one Active Directory Organizational Unit (OU) where the Cluster
Named Object (CNO) computer object resides. This is so that permission can be given
to the CNO to allow the creation of a Virtual Computer Object (VCO).
Preferably the CNO should be added to an Active Directory security group and that
group has the permission to create computer objects inside the OU. This way, more
than one CNO computer object can use the same OU.

Please note that the prestaged CNO computer object must be disabled before creating
the failover cluster, and that the security group must be given the permission
**Create Computer Objects** on the OU where the CNO computer object was created.
Also the user creating the failover cluster must have the permission **Full Control**
on the CNO computer object.

The [xADObjectPermissionEntry examples](https://github.com/PowerShell/xActiveDirectory/tree/dev/Examples/Resources/xADObjectPermissionEntry)
at the resource module [xActiveDirectory](https://github.com/PowerShell/xActiveDirectory)
can be used to set the correct permissions.

```powershell
<#
    Creates the Organizational Unit for the CNO.
#>
xADOrganizationalUnit 'ClusterComputerObjects'
{
    Ensure                          = 'Present'
    Name                            = 'Cluster Computer Objects'
    Path                            = 'DC=companylab,DC=se'
    ProtectedFromAccidentalDeletion = $true
    Description                     = 'The Cluster Computer Objects (CNO) ' `
                                      + 'and Virtual Computer Objects (VCO).'

    # A user with enough permission to create the OU.
    Credential                      = $DomainAdministratorCredential
}

<#
    Creates the Cluster Named Object (CNO) computer object.
#>
xADComputer 'TESTCLU01'
{
    ComputerName                  = 'TESTCLU01'
    DnsHostName                   = 'TESTCLU01.companylab.se'
    Path                          = 'OU=Cluster Computer Objects,DC=companylab,DC=se'
    Description                   = 'Cluster Network Object (CNO) ' `
                                    + 'for Failover Cluster TESTCLU01.'

    # A user with enough permission to create the computer object.
    DomainAdministratorCredential = $DomainAdministratorCredential
}

<#
    Creates the security group and adds the Cluster Named Object (CNO)
    as a member to the group.
#>
xADGroup 'ActiveDirectoryCreateClusterVirtualComputerObjects'
{
    Ensure      = 'Present'
    GroupName   = 'Active Directory Create Cluster Virtual Computer Objects'
    GroupScope  = 'Global'
    Category    = 'Security'
    Description = 'Group that will give permission to a Cluster Name Object ' `
                  + '(CNO) to create one or more Virtual Computer Object (VCO).'
    MembersToInclude = 'TESTCLU01$'

    # A user with enough permission to create the security group.
    Credential  = $DomainAdministratorCredential
}
```

#### Create Failover Cluster

The example [Create a Failover Cluster with two nodes](https://github.com/PowerShell/xFailOverCluster/blob/dev/Examples/Resources/xCluster/3-CreateFailoverClusterWithTwoNodes.ps1)
at the resource module [xFailOverCluster](https://github.com/PowerShell/xFailOverCluster)
can be used to create the failover cluster. It is an example, and it should be
changed to match your configuration. Also, please see other resource examples in
[xFailOverCluster](https://github.com/PowerShell/xFailOverCluster) to see if
they could improve you configuration, for example the resource xClusterQuorum.

>**Note:** Make sure any user accounts you use in the configuration exist in
>Active Directory and that they have the correct permission.

#### Install SQL Server Failover Cluster Instance

The example shows how to
[install the first SQL Server Failover Cluster node for a named instance](https://github.com/PowerShell/SqlServerDsc/blob/dev/Examples/Resources/SqlSetup/4-InstallNamedInstanceInFailoverClusterFirstNode.ps1).
And this example shows how to
[install the second SQL Server Failover Cluster node for a named instance](https://github.com/PowerShell/SqlServerDsc/blob/dev/Examples/Resources/SqlSetup/5-InstallNamedInstanceInFailoverClusterSecondNode.ps1).

>**Note:** Make sure any user accounts you use in the configuration exist in
>Active Directory and that they have the correct permission.

## Setting up a SQL Server AlwaysOn Availability Groups

This will reference examples that show how to setup high availability using
AlwaysOn Availability Group.
It assumes that a working domain exists with at least one Domain Controller,
and both servers that should contain the SQL Server nodes are domain joined.

### Prepare Active Directory

Please see [Prepare Active Directory](#prepare-active-directory). The same applies
to the failover cluster needed for SQL Server AlwaysOn Availability Groups.

#### Create Failover Cluster

Please see [Create Failover Cluster](#create-failover-cluster). The same applies
to the failover cluster needed for SQL Server AlwaysOn Availability Groups.

#### Install SQL Server on replicas

>**Note:** Make sure any user accounts you use in the configuration exist in
>Active Directory and that they have the correct permission.

##### Install SQL Server on the primary node

The example shows how to
[install a SQL Server named instance on a single server](https://github.com/PowerShell/SqlServerDsc/blob/dev/Examples/Resources/SqlSetup/2-InstallNamedInstanceSingleServer.ps1)
which will be used as the primary replica node in the SQL Server AlwaysOn
Availability Group.

##### Install SQL Server on the secondary node

The example shows how to
[install a SQL Server named instance on a single server](https://github.com/PowerShell/SqlServerDsc/blob/dev/Examples/Resources/SqlSetup/2-InstallNamedInstanceSingleServer.ps1)
which will be used as the secondary replica node in the SQL Server AlwaysOn
Availability Group.

#### Enable AlwaysOn on both primary and secondary replica

AlwaysOn must be enabled on both the primary and secondary replica, and the example
[Enable AlwaysOn](https://github.com/PowerShell/SqlServerDsc/blob/dev/Examples/Resources/SqlAlwaysOnService/1-EnableAlwaysOn.ps1)
shows how to enable it (which requires that a working Failover Cluster is
present on the node).

#### Configure SQL Server AlwaysOn Availability Group

Once AlwaysOn is enabled we can create the Availability Group. The example [Create Availability Group](https://github.com/PowerShell/SqlServerDsc/blob/dev/Examples/Resources/SqlAGReplica/1-CreateAvailabilityGroupReplica.ps1)
shows how to create the Availability Group on the primary replica and join the
Availability Group on the secondary replica.

>**Note:** Make sure any user accounts you use in the configuration exist in
>Active Directory and that they have the correct permission.
