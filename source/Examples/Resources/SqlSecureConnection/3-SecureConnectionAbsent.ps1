<#
    .DESCRIPTION
        This example performs a standard Sql encryption setup. Forcing all connections to be encrypted.
#>
Configuration Example
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node localhost
    {
        SqlSecureConnection 'SecureConnectionAbsent'
        {
            InstanceName    = 'MSSQLSERVER'
            Thumbprint      = ''
            Ensure          = 'Absent'
            ServiceAccount  = 'SqlSvc'
        }
    }
}
