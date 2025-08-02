<#
    .SYNOPSIS
        Assert that the specified SQL Server principal exists as a login.

    .DESCRIPTION
        This command asserts that the specified SQL Server principal exists as a
        login. If the principal does not exist as a login, a terminating error
        is thrown.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER Principal
        Specifies the principal that need to exist as a login.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | Assert-SqlLogin -Principal 'MyLogin'

        Asserts that the principal 'MyLogin' exists as a login.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        Assert-SqlLogin -ServerObject $serverObject -Principal 'MyLogin'

        Asserts that the principal 'MyLogin' exists as a login.

    .NOTES
        This command throws a terminating error if the specified SQL Server
        principal does not exist as a SQL server login.
#>
function Assert-SqlLogin
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Principal
    )

    process
    {
        Write-Verbose -Message ($script:localizedData.AssertLogin_CheckingLogin -f $Principal, $ServerObject.InstanceName)

        if (-not $ServerObject.Logins[$Principal])
        {
            $missingLoginMessage = $script:localizedData.AssertLogin_LoginMissing -f $Principal, $ServerObject.InstanceName

            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    $missingLoginMessage,
                    'ASL0001', # cspell: disable-line
                    [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                    $Principal
                )
            )
        }

        Write-Debug -Message ($script:localizedData.AssertLogin_LoginExists -f $Principal)
    }
}
