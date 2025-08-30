<#
    .SYNOPSIS
        Returns whether the server login is enabled or disabled.

    .DESCRIPTION
        Tests the state of a SQL Server login and returns a Boolean result.
        When a Server object is provided, the login is resolved using
        Get-SqlDscLogin (optionally refreshing the server logins first).
        When a Login object is provided, its current state is evaluated directly.
    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER LoginObject
        Specifies a login object to test.

    .PARAMETER Name
        Specifies the name of the server login to test.

    .PARAMETER Refresh
        Specifies that the **ServerObject**'s logins should be refreshed before
        trying to test the login object. This is helpful when logins could have
        been modified outside of the **ServerObject**, for example through T-SQL.
        But on instances with a large amount of logins it might be better to make
        sure the **ServerObject** is recent enough, or pass in **LoginObject**.

    .INPUTS
        [Microsoft.SqlServer.Management.Smo.Server]

        Server object accepted from the pipeline.

        [Microsoft.SqlServer.Management.Smo.Login]

        Login object accepted from the pipeline.

    .OUTPUTS
        [System.Boolean]

        Returns $true if the login is enabled, $false if the login is disabled.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        Test-SqlDscIsLoginEnabled -ServerObject $serverObject -Name 'MyLogin'

        Returns $true if the login is enabled, if not $false is returned.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $loginObject = $serverObject | Get-SqlDscLogin -Name 'MyLogin'
        Test-SqlDscIsLoginEnabled -LoginObject $loginObject

        Returns $true if the login is enabled, if not $false is returned.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $result = $serverObject | Test-SqlDscIsLoginEnabled -Name 'MyLogin'

        Demonstrates pipeline usage with ServerObject. Returns $true if the login is enabled, if not $false is returned.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $loginObject = $serverObject | Get-SqlDscLogin -Name 'MyLogin'
        $result = $loginObject | Test-SqlDscIsLoginEnabled

        Demonstrates pipeline usage with LoginObject. Returns $true if the login is enabled, if not $false is returned.
#>
function Test-SqlDscIsLoginEnabled
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(ParameterSetName = 'ServerObject', Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter(ParameterSetName = 'LoginObject', Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Login]
        $LoginObject,

        [Parameter(ParameterSetName = 'ServerObject', Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(ParameterSetName = 'ServerObject')]
        [System.Management.Automation.SwitchParameter]
        $Refresh
    )

    $ErrorPreference = 'Stop'

    process
    {
        if ($PSCmdlet.ParameterSetName -eq 'ServerObject')
        {
            $getSqlDscLoginParameters = @{
                ServerObject = $ServerObject
                Name         = $Name
                Refresh      = $Refresh
                ErrorAction  = 'Stop'
            }

            # If this command does not find the login it will throw an exception.
            $loginObjectArray = Get-SqlDscLogin @getSqlDscLoginParameters

            # Pick the only object in the array.
            $LoginObject = $loginObjectArray
        }

        $loginEnabled = -not $LoginObject.IsDisabled

        return $loginEnabled
    }
}
