<#
    .SYNOPSIS
        Updates properties of a SQL Agent Operator.

    .DESCRIPTION
        This command updates properties of an existing SQL Agent Operator on a SQL Server Database Engine instance.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER OperatorObject
        Specifies the SQL Agent Operator object to update.

    .PARAMETER Name
        Specifies the name of the SQL Agent Operator to update.

    .PARAMETER EmailAddress
        Specifies the email address for the SQL Agent Operator.

    .INPUTS
        Microsoft.SqlServer.Management.Smo.Server

        SQL Server Database Engine instance object.

    .INPUTS
        Microsoft.SqlServer.Management.Smo.Agent.Operator

        SQL Agent Operator object.

    .OUTPUTS
        None.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        Set-SqlDscAgentOperator -ServerObject $serverObject -Name 'MyOperator' -EmailAddress 'admin@contoso.com'

        Updates the email address of the SQL Agent Operator named 'MyOperator'.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | Set-SqlDscAgentOperator -Name 'MyOperator' -EmailAddress 'admin@contoso.com'

        Updates the email address of the SQL Agent Operator using pipeline input.

    .EXAMPLE
        $operatorObject = Get-SqlDscAgentOperator -ServerObject $serverObject -Name 'MyOperator'
        $operatorObject | Set-SqlDscAgentOperator -EmailAddress 'admin@contoso.com'

        Updates the email address of the SQL Agent Operator using operator object pipeline input.
#>
function Set-SqlDscAgentOperator
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'ByName')]
    [OutputType()]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'ByName')]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'ByObject')]
        [Microsoft.SqlServer.Management.Smo.Agent.Operator]
        $OperatorObject,

        [Parameter(Mandatory = $true, ParameterSetName = 'ByName')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $EmailAddress
    )

    # cSpell: ignore SSAO
    process
    {
        if ($PSCmdlet.ParameterSetName -eq 'ByName')
        {
            Write-Verbose -Message ($script:localizedData.Set_SqlDscAgentOperator_RefreshingServerObject)
            
            $ServerObject.JobServer.Operators.Refresh()
            
            $OperatorObject = Get-AgentOperatorObject -ServerObject $ServerObject -Name $Name

            if (-not $OperatorObject)
            {
                $errorMessage = $script:localizedData.Set_SqlDscAgentOperator_OperatorNotFound -f $Name
                New-ObjectNotFoundException -Message $errorMessage
            }
        }

        # Check if any changes are needed
        $changesNeeded = $false

        if ($PSBoundParameters.ContainsKey('EmailAddress'))
        {
            if ($OperatorObject.EmailAddress -ne $EmailAddress)
            {
                $changesNeeded = $true
            }
            else
            {
                Write-Verbose -Message ($script:localizedData.Set_SqlDscAgentOperator_EmailAddressAlreadyCorrect -f $EmailAddress, $OperatorObject.Name)
            }
        }

        if (-not $changesNeeded)
        {
            Write-Verbose -Message ($script:localizedData.Set_SqlDscAgentOperator_NoChangesNeeded -f $OperatorObject.Name)
            return
        }

        $verboseDescriptionMessage = $script:localizedData.Set_SqlDscAgentOperator_UpdateShouldProcessVerboseDescription -f $OperatorObject.Name, $OperatorObject.Parent.Parent.InstanceName
        $verboseWarningMessage = $script:localizedData.Set_SqlDscAgentOperator_UpdateShouldProcessVerboseWarning -f $OperatorObject.Name
        $captionMessage = $script:localizedData.Set_SqlDscAgentOperator_UpdateShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage))
        {
            try
            {
                Write-Verbose -Message ($script:localizedData.Set_SqlDscAgentOperator_UpdatingOperator -f $OperatorObject.Name)

                if ($PSBoundParameters.ContainsKey('EmailAddress'))
                {
                    Write-Verbose -Message ($script:localizedData.Set_SqlDscAgentOperator_SettingEmailAddress -f $EmailAddress, $OperatorObject.Name)
                    $OperatorObject.EmailAddress = $EmailAddress
                }

                $OperatorObject.Alter()

                Write-Verbose -Message ($script:localizedData.Set_SqlDscAgentOperator_OperatorUpdated -f $OperatorObject.Name)
            }
            catch
            {
                $errorMessage = $script:localizedData.Set_SqlDscAgentOperator_UpdateFailed -f $OperatorObject.Name
                New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
            }
        }
    }
}