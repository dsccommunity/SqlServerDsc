<#
.EXAMPLE
    This example performs a standard Sql encryption setup. Forcing all connections to be encrypted.
#>
Configuration Example
{
    Import-DscResource -ModuleName SqlServerDsc

    node localhost {
        SqlServerSecureConnection SecureConnectionAbsent
        {
            InstanceName    = 'MSSQLSERVER'
            Thumbprint      = ''
            Ensure          = 'Absent'
            ServiceAccount  = 'SqlSvc'
        }
    }
}
