<#
    .EXAMPLE
        This example will add connect permission to the credentials provided in $SqlServiceCredential
        to the endpoint named 'DefaultMirrorEndpoint'.
#>
Configuration Example
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $SqlAdministratorCredential,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $SqlServiceCredential
    )

    Import-DscResource -ModuleName SqlServerDsc

    node localhost
    {
        SqlServerEndpointPermission SQLConfigureEndpointPermission
        {
            Ensure               = 'Present'
            ServerName           = 'SQLTEST'
            InstanceName         = 'DSCINSTANCE'
            Name                 = 'DefaultMirrorEndpoint'
            Principal            = $SqlServiceCredential.UserName
            Permission           = 'CONNECT'

            PsDscRunAsCredential = $SqlAdministratorCredential
        }
    }
}
