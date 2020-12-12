<#
    .DESCRIPTION
        This example will wait for both the cluster roles/groups 'AGTest1' and 'AGTest2'.
#>
Configuration Example
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $SqlAdministratorCredential
    )

    Import-DscResource -ModuleName 'SqlServerDsc'

    node localhost
    {
        SqlWaitForAG 'SQLConfigureAG-WaitAGTest1'
        {
            Name                 = 'AGTest1'
            RetryIntervalSec     = 20
            RetryCount           = 30
            InstanceName         = 'MSSQLSERVER'

            PsDscRunAsCredential = $SqlAdministratorCredential
        }

        SqlWaitForAG 'SQLConfigureAG-WaitAGTest2'
        {
            Name                 = 'AGTest2'
            RetryIntervalSec     = 20
            RetryCount           = 30
            InstanceName         = 'MSSQLSERVER'

            PsDscRunAsCredential = $SqlAdministratorCredential
        }
    }
}
