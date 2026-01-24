<#
    .SYNOPSIS
        Execute an SQL script located in a file on disk.

    .PARAMETER ServerInstance
        The name of an instance of the Database Engine.
        For default instances, only specify the computer name. For named instances,
        use the format ComputerName\InstanceName.

    .PARAMETER InputFile
        Path to SQL script file that will be executed.

    .PARAMETER Query
        The full query that will be executed.

    .PARAMETER Credential
        The credentials to use to authenticate using SQL Authentication. To
        authenticate using Windows Authentication, assign the credentials
        to the built-in parameter 'PsDscRunAsCredential'. If both parameters
        'Credential' and 'PsDscRunAsCredential' are not assigned, then the
        SYSTEM account will be used to authenticate using Windows Authentication.

    .PARAMETER QueryTimeout
        Specifies, as an integer, the number of seconds after which the T-SQL
        script execution will time out. In some SQL Server versions there is a
        bug in Invoke-SqlCmd where the normal default value 0 (no timeout) is not
        respected and the default value is incorrectly set to 30 seconds.

    .PARAMETER Variable
        Creates a Invoke-SqlCmd scripting variable for use in the Invoke-SqlCmd
        script, and sets a value for the variable.

    .PARAMETER DisableVariables
        Specifies, as a boolean, whether or not PowerShell will ignore Invoke-SqlCmd
        scripting variables that share a format such as $(variable_name). For more
        information how to use this, please go to the help documentation for
        [Invoke-SqlCmd](https://docs.microsoft.com/en-us/powershell/module/sqlserver/Invoke-Sqlcmd).

    .PARAMETER Encrypt
        Specifies how encryption should be enforced. When not specified, the default
        value is `Mandatory`.

        This value maps to the Encrypt property SqlConnectionEncryptOption
        on the SqlConnection object of the Microsoft.Data.SqlClient driver.

        This parameter can only be used when the module SqlServer v22.x.x is installed.

    .NOTES
        This wrapper for Invoke-SqlCmd make verbose functionality of PRINT and
        RAISEERROR statements work as those are outputted in the verbose output
        stream. For some reason having the wrapper in a separate module seems to
        trigger (so that it works getting) the verbose output for those statements.

        Parameter `Encrypt` controls whether the connection used by `Invoke-SqlCmd`
        should enforce encryption. This parameter can only be used together with the
        module _SqlServer_ v22.x (minimum v22.0.49-preview). The parameter will be
        ignored if an older major versions of the module _SqlServer_ is used.
        Encryption is mandatory by default, which generates the following exception
        when the correct certificates are not present:

        "A connection was successfully established with the server, but then
        an error occurred during the login process. (provider: SSL Provider,
        error: 0 - The certificate chain was issued by an authority that is
        not trusted.)"

        For more details, see the article [Connect to SQL Server with strict encryption](https://learn.microsoft.com/en-us/sql/relational-databases/security/networking/connect-with-strict-encryption?view=sql-server-ver16)
        and [Configure SQL Server Database Engine for encrypting connections](https://learn.microsoft.com/en-us/sql/database-engine/configure-windows/configure-sql-server-encryption?view=sql-server-ver16).
#>
function Invoke-SqlScript
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ServerInstance,

        [Parameter(ParameterSetName = 'File', Mandatory = $true)]
        [System.String]
        $InputFile,

        [Parameter(ParameterSetName = 'Query', Mandatory = $true)]
        [System.String]
        $Query,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        [Parameter()]
        [System.UInt32]
        $QueryTimeout,

        [Parameter()]
        [System.String[]]
        $Variable,

        [Parameter()]
        [System.Boolean]
        $DisableVariables,

        [Parameter()]
        [ValidateSet('Mandatory', 'Optional', 'Strict')]
        [System.String]
        $Encrypt
    )

    Import-SqlDscPreferredModule

    if ($PSCmdlet.ParameterSetName -eq 'File')
    {
        $null = $PSBoundParameters.Remove('Query')
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'Query')
    {
        $null = $PSBoundParameters.Remove('InputFile')
    }

    if ($null -ne $Credential)
    {
        $null = $PSBoundParameters.Add('Username', $Credential.UserName)

        $null = $PSBoundParameters.Add('Password', $Credential.GetNetworkCredential().Password)
    }

    $null = $PSBoundParameters.Remove('Credential')

    if ($PSBoundParameters.ContainsKey('Encrypt'))
    {
        $commandInvokeSqlCmd = Get-Command -Name 'Invoke-SqlCmd'

        if ($null -ne $commandInvokeSqlCmd -and $commandInvokeSqlCmd.Parameters.Keys -notcontains 'Encrypt')
        {
            $null = $PSBoundParameters.Remove('Encrypt')
        }
    }

    if ([System.String]::IsNullOrEmpty($Variable))
    {
        $null = $PSBoundParameters.Remove('Variable')
    }

    Invoke-SqlCmd @PSBoundParameters
}
