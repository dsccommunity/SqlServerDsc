<#
    .SYNOPSIS
        Assert that the specified SQL Server principal exists as a login.

    .DESCRIPTION
        This command asserts that the specified SQL Server principal exists as a
        login. If the principal does not exist as a login, a terminating error
        is thrown.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER Name
        Specifies the name of the principal that needs to exist as a login.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | Assert-SqlDscLogin -Name 'MyLogin'

        Asserts that the principal 'MyLogin' exists as a login.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        Assert-SqlDscLogin -ServerObject $serverObject -Name 'MyLogin'

        Asserts that the principal 'MyLogin' exists as a login.

    .INPUTS
        `Microsoft.SqlServer.Management.Smo.Server`

        Accepts a SQL Server server object via the pipeline.

    .OUTPUTS
        None.

    .NOTES
        This command throws a terminating error if the specified SQL Server
        principal does not exist as a SQL server login.
#>
function Assert-SqlDscLogin
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [CmdletBinding()]
    [OutputType()]
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
        Write-Verbose -Message ($script:localizedData.Assert_Login_CheckingLogin -f $Name, $ServerObject.InstanceName)

        if (-not (Test-SqlDscIsLogin -ServerObject $ServerObject -Name $Name))
        {
            $missingLoginMessage = $script:localizedData.Assert_Login_LoginMissing -f $Name, $ServerObject.InstanceName

            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    $missingLoginMessage,
                    'ASDL0001', # cspell: disable-line
                    [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                    $Name
                )
            )
        }

        Write-Debug -Message ($script:localizedData.Assert_Login_LoginExists -f $Name)
    }
}
