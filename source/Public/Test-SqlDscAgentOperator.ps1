<#
    .SYNOPSIS
        Tests the state of a SQL Agent Operator.

    .DESCRIPTION
        This command tests if a SQL Agent Operator exists and has the desired properties on a SQL Server Database Engine instance.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER Name
        Specifies the name of the SQL Agent Operator to test.

    .PARAMETER EmailAddress
        Specifies the expected email address for the SQL Agent Operator.

    .INPUTS
        Microsoft.SqlServer.Management.Smo.Server

        SQL Server Database Engine instance object.

    .OUTPUTS
        System.Boolean

        Returns $true if the operator exists and has the desired properties, $false otherwise.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        Test-SqlDscAgentOperator -ServerObject $serverObject -Name 'MyOperator'

        Tests if the SQL Agent Operator named 'MyOperator' exists.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | Test-SqlDscAgentOperator -Name 'MyOperator' -EmailAddress 'admin@contoso.com'

        Tests if the SQL Agent Operator exists and has the specified email address using pipeline input.
#>
function Test-SqlDscAgentOperator
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
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $EmailAddress
    )

    # cSpell: ignore TSAO
    process
    {
        Write-Verbose -Message ($script:localizedData.Test_SqlDscAgentOperator_TestingOperator -f $Name)

        $operatorObject = Get-SqlDscAgentOperator -ServerObject $ServerObject -Name $Name

        if (-not $operatorObject)
        {
            Write-Verbose -Message ($script:localizedData.Test_SqlDscAgentOperator_OperatorNotFound -f $Name)
            return $false
        }

        Write-Verbose -Message ($script:localizedData.Test_SqlDscAgentOperator_OperatorFound -f $Name)

        # If no specific properties to test, return true since operator exists
        if (-not $PSBoundParameters.ContainsKey('EmailAddress'))
        {
            Write-Verbose -Message ($script:localizedData.Test_SqlDscAgentOperator_NoPropertyTest)
            return $true
        }

        # Test EmailAddress if specified
        if ($PSBoundParameters.ContainsKey('EmailAddress'))
        {
            if ($operatorObject.EmailAddress -ne $EmailAddress)
            {
                Write-Verbose -Message ($script:localizedData.Test_SqlDscAgentOperator_EmailAddressMismatch -f $operatorObject.EmailAddress, $EmailAddress)
                return $false
            }
            else
            {
                Write-Verbose -Message ($script:localizedData.Test_SqlDscAgentOperator_EmailAddressMatch -f $EmailAddress)
            }
        }

        Write-Verbose -Message ($script:localizedData.Test_SqlDscAgentOperator_AllTestsPassed -f $Name)
        return $true
    }
}
