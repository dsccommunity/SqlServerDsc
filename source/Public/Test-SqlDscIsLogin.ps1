<#
    .SYNOPSIS
        Returns whether the server principal exist and is a login.

    .DESCRIPTION
        Returns whether the server principal exist and is a login.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER Name
        Specifies the name of the server principal.

    .OUTPUTS
        [System.Boolean]

    .EXAMPLE
        $serverInstance = Connect-SqlDscDatabaseEngine
        Test-SqlDscIsLogin -ServerObject $serverInstance -Name 'MyPrincipal'

        Returns $true if the principal exist as a login, if not $false is returned.
#>
function Test-SqlDscIsLogin
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name
    )

    $ErrorActionPreference = 'Stop'

    process
    {
        $loginExist = $false

        if ($ServerObject.Logins[$Name])
        {
            $loginExist = $true
        }

        return $loginExist
    }
}
