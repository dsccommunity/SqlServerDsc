<#
    .DESCRIPTION
        This example shows how to configure two SQL Server instances on the same
        server to have CLR enabled.

    .NOTES
        To get all available options run sp_configure on the SQL Server instance,
        or refer to https://msdn.microsoft.com/en-us/library/ms189631.aspx
#>

Configuration Example
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node localhost
    {
        foreach ($sqlInstance in @('CONTENT', 'DIST'))
        {
            SqlConfiguration ('SQLConfigCLR_{0}' -f $sqlInstance)
            {
                ServerName   = $Node.NodeName
                InstanceName = $sqlInstance
                OptionName   = 'clr enabled'
                OptionValue  = 1
            }
        }
    }
}
