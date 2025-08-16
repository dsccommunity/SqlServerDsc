<#
    .SYNOPSIS
        Get server login.

    .DESCRIPTION
        This command gets a server login from a SQL Server Database Engine instance.

    .PARAMETER ServerObject
        .PARAMETER ServerObject
            Specifies the current server connection object.
    .PARAMETER Name
        Specifies the name of the server login to get.

    .PARAMETER Refresh
        Specifies that the **ServerObject**'s logins should be refreshed before
        trying get the login object. This is helpful when logins could have been
        modified outside of the **ServerObject**, for example through T-SQL. But
        on instances with a large amount of logins it might be better to make
        sure the **ServerObject** is recent enough.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | Get-SqlDscLogin -Name 'MyLogin'

        Get the login named **MyLogin**.

    .OUTPUTS
        `[Microsoft.SqlServer.Management.Smo.Login]`

        Returns a single Login object when the Name parameter is specified and a
        match is found.

    .OUTPUTS
        `[Microsoft.SqlServer.Management.Smo.Login[]]`

        Returns an array of Login objects when the Name parameter is not specified
        (returns all logins) or when multiple matches are found.
#>
function Get-SqlDscLogin
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [OutputType([Microsoft.SqlServer.Management.Smo.Login[]])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter()]
        [System.String]
        $Name,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Refresh
    )

    process
    {
        if ($Refresh.IsPresent)
        {
            # Make sure the logins are up-to-date to get any newly created logins.
            $ServerObject.Logins.Refresh()
        }

        $loginObject = @()

        if ($PSBoundParameters.ContainsKey('Name'))
        {
            $loginObject = $ServerObject.Logins[$Name]

            if (-not $loginObject)
            {
                $missingLoginMessage = $script:localizedData.Login_Get_Missing -f $Name

                $writeErrorParameters = @{
                    Message      = $missingLoginMessage
                    Category     = 'ObjectNotFound'
                    ErrorId      = 'GSDL0001' # cspell: disable-line
                    TargetObject = $Name
                }

                Write-Error @writeErrorParameters
            }
        }
        else
        {
            $loginObject = $ServerObject.Logins
        }

        return [Microsoft.SqlServer.Management.Smo.Login[]] $loginObject
    }
}
