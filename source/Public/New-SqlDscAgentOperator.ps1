<#
    .SYNOPSIS
        Creates a new SQL Agent Operator.

    .DESCRIPTION
        This command creates a new SQL Agent Operator on a SQL Server Database Engine instance.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER Name
        Specifies the name of the SQL Agent Operator to create.

    .PARAMETER EmailAddress
        Specifies the email address for the SQL Agent Operator.

    .PARAMETER PassThru
        If specified, the created operator object will be returned.

    .INPUTS
        Microsoft.SqlServer.Management.Smo.Server

        SQL Server Database Engine instance object.

    .OUTPUTS
        `[Microsoft.SqlServer.Management.Smo.Agent.Operator]` if passing parameter **PassThru**,
         otherwise none.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        New-SqlDscAgentOperator -ServerObject $serverObject -Name 'MyOperator'

        Creates a new SQL Agent Operator named 'MyOperator'.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | New-SqlDscAgentOperator -Name 'MyOperator' -EmailAddress 'admin@contoso.com'

        Creates a new SQL Agent Operator named 'MyOperator' with an email address using pipeline input.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $operatorObject = $serverObject | New-SqlDscAgentOperator -Name 'MyOperator' -PassThru

        Creates a new SQL Agent Operator and returns the created object.
#>
function New-SqlDscAgentOperator
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([Microsoft.SqlServer.Management.Smo.Agent.Operator])]
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
        $EmailAddress,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $PassThru
    )

    # cSpell: ignore NSAO
    process
    {
        # Check if operator already exists
        $existingOperator = Get-AgentOperatorObject -ServerObject $ServerObject -Name $Name

        if ($existingOperator)
        {
            $errorMessage = $script:localizedData.New_SqlDscAgentOperator_OperatorAlreadyExists -f $Name
            New-InvalidOperationException -Message $errorMessage
        }

        $verboseDescriptionMessage = $script:localizedData.New_SqlDscAgentOperator_CreateShouldProcessVerboseDescription -f $Name, $ServerObject.InstanceName
        $verboseWarningMessage = $script:localizedData.New_SqlDscAgentOperator_CreateShouldProcessVerboseWarning -f $Name
        $captionMessage = $script:localizedData.New_SqlDscAgentOperator_CreateShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage))
        {
            try
            {
                Write-Verbose -Message ($script:localizedData.New_SqlDscAgentOperator_CreatingOperator -f $Name)

                # Create the new operator SMO object
                $newOperatorObject = [Microsoft.SqlServer.Management.Smo.Agent.Operator]::new($ServerObject.JobServer, $Name)

                if ($PSBoundParameters.ContainsKey('EmailAddress'))
                {
                    Write-Verbose -Message ($script:localizedData.New_SqlDscAgentOperator_SettingEmailAddress -f $EmailAddress, $Name)
                    $newOperatorObject.EmailAddress = $EmailAddress
                }

                $newOperatorObject.Create()

                Write-Verbose -Message ($script:localizedData.New_SqlDscAgentOperator_OperatorCreated -f $Name)

                if ($PassThru.IsPresent)
                {
                    return $newOperatorObject
                }
            }
            catch
            {
                $errorMessage = $script:localizedData.New_SqlDscAgentOperator_CreateFailed -f $Name
                New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
            }
        }
    }
}