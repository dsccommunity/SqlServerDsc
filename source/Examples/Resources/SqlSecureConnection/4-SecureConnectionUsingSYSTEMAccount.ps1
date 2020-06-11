<#
    .DESCRIPTION
        This example performs a standard Sql encryption setup using the "SYSTEM" account.
        Note that the "LocalSystem" account should not be used because it returns a connection error,
        even though it inherits the "SYSTEM" account's privileges.
#>
Configuration Example
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node localhost
    {
        SqlSecureConnection 'SecureConnectionUsingSYSTEMAccount'
        {
            InstanceName    = 'MSSQLSERVER'
            Thumbprint      = 'fb0b82c94b80da26cf0b86f10ec0c50ae7864a2c'
            ForceEncryption = $false
            Ensure          = 'Present'
            ServiceAccount  = 'SYSTEM'
        }
    }
}
