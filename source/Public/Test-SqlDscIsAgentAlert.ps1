<#
    .SYNOPSIS
        Tests if a SQL Agent Alert exists.

    .DESCRIPTION
        This command tests if a SQL Agent Alert exists on a SQL Server Database Engine
        instance.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER Name
        Specifies the name of the SQL Agent Alert to test.

    .INPUTS
        `Microsoft.SqlServer.Management.Smo.Server`

        SQL Server Database Engine instance object.

    .OUTPUTS
        `System.Boolean`

        Returns the output object.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        Test-SqlDscIsAgentAlert -ServerObject $serverObject -Name 'MyAlert'

        Tests if the SQL Agent Alert named 'MyAlert' exists.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | Test-SqlDscIsAgentAlert -Name 'MyAlert'

        Tests if the SQL Agent Alert named 'MyAlert' exists using pipeline input.
#>
function Test-SqlDscIsAgentAlert
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [Alias('Test-SqlDscAgentAlert')]
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name
    )

    process
    {
        Write-Verbose -Message ($script:localizedData.Test_SqlDscIsAgentAlert_TestingAlert -f $Name)

        $alertObject = Get-AgentAlertObject -ServerObject $ServerObject -Name $Name -ErrorAction 'SilentlyContinue'

        if ($null -eq $alertObject)
        {
            Write-Verbose -Message ($script:localizedData.Test_SqlDscIsAgentAlert_AlertNotFound -f $Name)

            return $false
        }

        Write-Verbose -Message ($script:localizedData.Test_SqlDscIsAgentAlert_AlertFound -f $Name)

        return $true
    }
}
