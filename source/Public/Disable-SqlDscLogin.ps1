<#
    .SYNOPSIS
        Disables a SQL Server login.

    .DESCRIPTION
        This command disables a SQL Server login in a SQL Server Database Engine instance.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER LoginObject
        Specifies a login object to disable.

    .PARAMETER Name
        Specifies the name of the server login to be disabled.

    .PARAMETER Force
        Specifies that the login should be disabled without any confirmation.

    .PARAMETER Refresh
        Specifies that the **ServerObject**'s logins should be refreshed before
        trying to disable the login object. This is helpful when logins could have
        been modified outside of the **ServerObject**, for example through T-SQL.
        But on instances with a large amount of logins it might be better to make
        sure the **ServerObject** is recent enough, or pass in **LoginObject**.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $loginObject = $serverObject | Get-SqlDscLogin -Name 'MyLogin'
        $loginObject | Disable-SqlDscLogin

        Disables the login named **MyLogin**.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | Disable-SqlDscLogin -Name 'MyLogin'

        Disables the login named **MyLogin**.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | Disable-SqlDscLogin -Name 'MyLogin' -Force

        Disables the login without confirmation using **-Force**.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | Disable-SqlDscLogin -Name 'MyLogin' -Refresh

        Refreshes the server logins collection before disabling **MyLogin**.
    .INPUTS
        [Microsoft.SqlServer.Management.Smo.Server]

        Server object accepted from the pipeline (ServerObject parameter set).

        [Microsoft.SqlServer.Management.Smo.Login]

        Login object accepted from the pipeline (LoginObject parameter set).

    .OUTPUTS
        None.
#>
function Disable-SqlDscLogin
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [OutputType()]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
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

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force,

        [Parameter(ParameterSetName = 'ServerObject')]
        [System.Management.Automation.SwitchParameter]
        $Refresh
    )

    begin
    {
        $ErrorActionPreference = 'Stop'
    }

    process
    {
        if ($Force.IsPresent -and -not $Confirm)
        {
            $ConfirmPreference = 'None'
        }

        if ($PSCmdlet.ParameterSetName -eq 'ServerObject')
        {
            $getSqlDscLoginParameters = @{
                ServerObject = $ServerObject
                Name         = $Name
                Refresh      = $Refresh
                ErrorAction  = 'Stop'
            }

            # If this command does not find the login it will throw an exception.
            $LoginObject = Get-SqlDscLogin @getSqlDscLoginParameters
        }

        $verboseDescriptionMessage = $script:localizedData.Login_Disable_ShouldProcessVerboseDescription -f $LoginObject.Name, $LoginObject.Parent.InstanceName
        $verboseWarningMessage = $script:localizedData.Login_Disable_ShouldProcessVerboseWarning -f $LoginObject.Name
        $captionMessage = $script:localizedData.Login_Disable_ShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage))
        {
            $LoginObject.Disable()
        }
    }
}
