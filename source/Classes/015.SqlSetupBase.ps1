<#
    .SYNOPSIS
        The SqlSetupBase have generic properties and methods that are common for
        the setup action class-based resources.

    .PARAMETER MediaPath
        Specifies the path where to find the SQL Server installation media. On this
        path the SQL Server setup executable must be found.

    .PARAMETER ConfigurationFile
        Specifies an configuration file to use during SQL Server setup. This
        parameter cannot be used together with any of the setup actions, but instead
        it is expected that the configuration file specifies what setup action to
        run.

    .PARAMETER Timeout
        Specifies how long to wait for the setup process to finish. Uses the default
        value of the command `Install-SqlDscServer`. If the setup process does not
        finish before this time, an exception will be thrown.
#>
class SqlSetupBase : SqlResourceBase
{
    [DscProperty(Mandatory)]
    [System.String]
    $MediaPath

    [DscProperty()]
    [System.String]
    $ConfigurationFile

    [DscProperty()]
    [System.UInt32]
    $Timeout
}
