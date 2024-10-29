---
Category: Usage
---

# Setting up a SQL Server Failover Cluster

This will reference examples that show how to setup high availability SQL Server
using a Failover Cluster.
It assumes that a working domain exists with at least one Domain Controller, and
and both servers that should contain the SQL Server nodes are domain joined.

## Prepare Active Directory

If the user who creates the failover cluster has the **Create Computer Objects**
permission to the organizational unit (OU) where the servers that will form the
cluster reside, then there is no need to prestage the Cluster Named Object (CNO)
computer object.
However, if the user creating the failover cluster does not have this permission,
prestaging the Cluster Named Object (CNO) computer object becomes necessary.
It is also possible to prestage the Virtual Computer Objects (VCO).

Read more about it here
[Prestage Cluster Computer Objects in Active Directory Domain Services](https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2012-R2-and-2012/dn466519(v=ws.11)).

### Prestage the Cluster Named Object (CNO) computer object

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

## Create Failover Cluster

The example [Create a Failover Cluster with two nodes](https://github.com/PowerShell/xFailOverCluster/blob/dev/Examples/Resources/xCluster/3-CreateFailoverClusterWithTwoNodes.ps1)
at the resource module [xFailOverCluster](https://github.com/PowerShell/xFailOverCluster)
can be used to create the failover cluster. It is an example, and it should be
changed to match your configuration. Also, please see other resource examples in
[xFailOverCluster](https://github.com/PowerShell/xFailOverCluster) to see if
they could improve you configuration, for example the resource xClusterQuorum.

> [!IMPORTANT]
> Make sure any user accounts you use in the configuration exist in
> Active Directory and that they have the correct permission.

### Install SQL Server Failover Cluster Instance

The example shows how to
[install the first SQL Server Failover Cluster node for a named instance](https://github.com/PowerShell/SqlServerDsc/blob/dev/Examples/Resources/SqlSetup/4-InstallNamedInstanceInFailoverClusterFirstNode.ps1).
And this example shows how to
[install the second SQL Server Failover Cluster node for a named instance](https://github.com/PowerShell/SqlServerDsc/blob/dev/Examples/Resources/SqlSetup/5-InstallNamedInstanceInFailoverClusterSecondNode.ps1).

> [!IMPORTANT]
> Make sure any user accounts you use in the configuration exist in
> Active Directory and that they have the correct permission.
