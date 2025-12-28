<#
    .SYNOPSIS
        Connect to a SQL Server Database Engine and return the server object.

    .DESCRIPTION
        This command connects to a  SQL Server Database Engine instance and returns
        the Server object.

    .PARAMETER ServerName
        String containing the host name of the SQL Server to connect to.
        Default value is the current computer name.

    .PARAMETER InstanceName
        String containing the SQL Server Database Engine instance to connect to.
        Default value is 'MSSQLSERVER'.

    .PARAMETER Credential
        The credentials to use to impersonate a user when connecting to the
        SQL Server Database Engine instance. If this parameter is left out, then
        the current user will be used to connect to the SQL Server Database Engine
        instance using Windows Integrated authentication.

    .PARAMETER LoginType
        Specifies which type of logon credential should be used. The valid types
        are 'WindowsUser' or 'SqlLogin'. Default value is 'WindowsUser'
        If set to 'WindowsUser' then the it will impersonate using the Windows
        login specified in the parameter Credential.
        If set to 'SqlLogin' then it will impersonate using the native SQL
        login specified in the parameter Credential.

    .PARAMETER Protocol
        Specifies the network protocol to use when connecting to the SQL Server
        instance. Valid values are 'tcp' for TCP/IP, 'np' for Named Pipes,
        and 'lpc' for Shared Memory.

        If not specified, the connection will use the default protocol order
        configured on the client.

    .PARAMETER Port
        Specifies the TCP port number to use when connecting to the SQL Server
        instance. This parameter is only applicable when connecting via TCP/IP
        (Protocol = 'tcp'). Valid values are 1-65535.

        If not specified for a named instance, the SQL Server Browser service
        will be used to determine the port. For default instances, port 1433
        is used by default.

    .PARAMETER StatementTimeout
        Set the query StatementTimeout in seconds. Default 600 seconds (10 minutes).

    .PARAMETER Encrypt
        Specifies if encryption should be used.

    .EXAMPLE
        Connect-SqlDscDatabaseEngine

        Connects to the default instance on the local server.

    .EXAMPLE
        Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'

        Connects to the instance 'MyInstance' on the local server.

    .EXAMPLE
        Connect-SqlDscDatabaseEngine -ServerName 'sql.company.local' -InstanceName 'MyInstance'

        Connects to the instance 'MyInstance' on the server 'sql.company.local'.

    .EXAMPLE
        Connect-SqlDscDatabaseEngine -Credential ([System.Management.Automation.PSCredential]::new('DOMAIN\SqlUser', (ConvertTo-SecureString -String 'MyP@ssw0rd1' -AsPlainText -Force)))

        Connects to the default instance on the local server impersonating the Windows user 'DOMAIN\SqlUser'.

    .EXAMPLE
        Connect-SqlDscDatabaseEngine -LoginType 'SqlLogin' -Credential ([System.Management.Automation.PSCredential]::new('sa', (ConvertTo-SecureString -String 'MyP@ssw0rd1' -AsPlainText -Force)))

        Connects to the default instance on the local server using the SQL login 'sa'.

    .EXAMPLE
        Connect-SqlDscDatabaseEngine -ServerName '192.168.1.1' -InstanceName 'MyInstance' -Protocol 'tcp' -Port 50200

        Connects to the named instance 'MyInstance' on server '192.168.1.1' using
        TCP/IP on port 50200. The connection string format is 'tcp:192.168.1.1\MyInstance,50200'.

    .EXAMPLE
        Connect-SqlDscDatabaseEngine -ServerName '192.168.1.1' -Protocol 'tcp' -Port 1433

        Connects to the default instance on server '192.168.1.1' using TCP/IP on
        port 1433. The connection string format is 'tcp:192.168.1.1,1433'.

    .INPUTS
        None.

    .OUTPUTS
        `Microsoft.SqlServer.Management.Smo.Server`

        Returns the SQL Server server object.

    .NOTES
        The protocol values ('tcp', 'np', 'lpc') are lowercase to match the SQL
        Server connection string prefix format, e.g., 'tcp:ServerName\Instance,Port'.
#>
function Connect-SqlDscDatabaseEngine
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when the output type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [OutputType([Microsoft.SqlServer.Management.Smo.Server])]
    [CmdletBinding(DefaultParameterSetName = 'SqlServer')]
    param
    (
        [Parameter(ParameterSetName = 'SqlServer')]
        [Parameter(ParameterSetName = 'SqlServerWithCredential')]
        [ValidateNotNull()]
        [System.String]
        $ServerName = (Get-ComputerName),

        [Parameter(ParameterSetName = 'SqlServer')]
        [Parameter(ParameterSetName = 'SqlServerWithCredential')]
        [ValidateNotNull()]
        [System.String]
        $InstanceName = 'MSSQLSERVER',

        [Parameter(ParameterSetName = 'SqlServerWithCredential', Mandatory = $true)]
        [ValidateNotNull()]
        [Alias('SetupCredential', 'DatabaseCredential')]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter(ParameterSetName = 'SqlServerWithCredential')]
        [ValidateSet('WindowsUser', 'SqlLogin')]
        [System.String]
        $LoginType = 'WindowsUser',

        [Parameter()]
        [ValidateSet('tcp', 'np', 'lpc')]
        [System.String]
        $Protocol,

        [Parameter()]
        [ValidateRange(1, 65535)]
        [System.UInt16]
        $Port,

        [Parameter()]
        [ValidateNotNull()]
        [System.Int32]
        $StatementTimeout = 600,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Encrypt
    )

    # Call the private function.
    return (Connect-Sql @PSBoundParameters)
}
