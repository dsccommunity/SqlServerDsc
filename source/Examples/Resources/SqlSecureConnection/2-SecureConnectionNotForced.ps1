<#
    .DESCRIPTION
        This example performs a standard Sql encryption setup. All connections are not forced to be encrypted.
#>
Configuration Example
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node localhost
    {
        SqlSecureConnection 'SecureConnectionNotForced'
        {
            InstanceName    = 'MSSQLSERVER'
            Thumbprint      = 'fb0b82c94b80da26cf0b86f10ec0c50ae7864a2c'
            ForceEncryption = $false
            Ensure          = 'Present'
            ServiceAccount  = 'SqlSvc'
        }
    }
}
