<#
    .SYNOPSIS
        Returns whether the server principal exists and is a server role.

    .DESCRIPTION
        Returns whether the server principal exist and is a server role.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER Name
        Specifies the name of the server principal.

    
    .INPUTS
        `Microsoft.SqlServer.Management.Smo.Server`

        Accepts input via the pipeline.

.OUTPUTS
        `System.Boolean`

        Returns the output object.

    .EXAMPLE
        $serverInstance = Connect-SqlDscDatabaseEngine
        Test-SqlDscIsRole -ServerObject $serverInstance -Name 'MyPrincipal'

        Returns $true if the principal exist as a server role, if not $false is returned.
#>
function Test-SqlDscIsRole
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

    process
    {
        $principalExist = $false

        if ($ServerObject.Roles[$Name])
        {
            $principalExist = $true
        }

        return $principalExist
    }
}
