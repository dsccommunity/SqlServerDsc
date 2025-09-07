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

    .PARAMETER CategoryName
        Specifies the category name for the SQL Agent Operator.

    .PARAMETER NetSendAddress
        Specifies the net send address for the SQL Agent Operator.

    .PARAMETER PagerAddress
        Specifies the pager address for the SQL Agent Operator.

    .PARAMETER PagerDays
        Specifies the days when pager notifications are active for the SQL Agent Operator.

    .PARAMETER SaturdayPagerEndTime
        Specifies the Saturday pager end time for the SQL Agent Operator.

    .PARAMETER SaturdayPagerStartTime
        Specifies the Saturday pager start time for the SQL Agent Operator.

    .PARAMETER SundayPagerEndTime
        Specifies the Sunday pager end time for the SQL Agent Operator.

    .PARAMETER SundayPagerStartTime
        Specifies the Sunday pager start time for the SQL Agent Operator.

    .PARAMETER WeekdayPagerEndTime
        Specifies the weekday pager end time for the SQL Agent Operator.

    .PARAMETER WeekdayPagerStartTime
        Specifies the weekday pager start time for the SQL Agent Operator.

    .PARAMETER Force
        Specifies that the operator should be updated without any confirmation.

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
        $EmailAddress,

        [Parameter()]
        [System.String]
        $CategoryName,

        [Parameter()]
        [System.String]
        $NetSendAddress,

        [Parameter()]
        [System.String]
        $PagerAddress,

        [Parameter()]
        [Microsoft.SqlServer.Management.Smo.Agent.WeekDays]
        $PagerDays,

        [Parameter()]
        [System.TimeSpan]
        $SaturdayPagerEndTime,

        [Parameter()]
        [System.TimeSpan]
        $SaturdayPagerStartTime,

        [Parameter()]
        [System.TimeSpan]
        $SundayPagerEndTime,

        [Parameter()]
        [System.TimeSpan]
        $SundayPagerStartTime,

        [Parameter()]
        [System.TimeSpan]
        $WeekdayPagerEndTime,

        [Parameter()]
        [System.TimeSpan]
        $WeekdayPagerStartTime,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    begin
    {
        # Dynamically get settable properties by filtering out common parameters and control parameters
        $settableProperties = Get-CommandParameter -Command $MyInvocation.MyCommand -Exclude @('ServerObject', 'OperatorObject', 'Name', 'Force')

        Assert-BoundParameter -BoundParameterList $PSBoundParameters -AtLeastOneList $settableProperties
    }

    # cSpell: ignore SSAO
    process
    {
        if ($Force.IsPresent -and -not $Confirm)
        {
            $ConfirmPreference = 'None'
        }
        if ($PSCmdlet.ParameterSetName -eq 'ByName')
        {
            Write-Verbose -Message ($script:localizedData.Set_SqlDscAgentOperator_RefreshingServerObject)

            $ServerObject.JobServer.Operators.Refresh()

            $originalErrorActionPreference = $ErrorActionPreference
            $ErrorActionPreference = 'Stop'
            $OperatorObject = Get-AgentOperatorObject -ServerObject $ServerObject -Name $Name -ErrorAction 'Stop'
            $ErrorActionPreference = $originalErrorActionPreference
        }

        # Build description of parameters being set for ShouldProcess
        $excludeParameters = @('ServerObject', 'OperatorObject', 'Name', 'Force')
        $parametersText = ConvertTo-FormattedParameterDescription -BoundParameters $PSBoundParameters -Exclude $excludeParameters

        $verboseDescriptionMessage = $script:localizedData.Set_SqlDscAgentOperator_UpdateShouldProcessVerboseDescription -f $OperatorObject.Name, $OperatorObject.Parent.Parent.InstanceName, $parametersText
        $verboseWarningMessage = $script:localizedData.Set_SqlDscAgentOperator_UpdateShouldProcessVerboseWarning -f $OperatorObject.Name
        $captionMessage = $script:localizedData.Set_SqlDscAgentOperator_UpdateShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage))
        {
            try
            {
                if ($PSBoundParameters.ContainsKey('EmailAddress'))
                {
                    $OperatorObject.EmailAddress = $EmailAddress
                }

                if ($PSBoundParameters.ContainsKey('CategoryName'))
                {
                    $OperatorObject.CategoryName = $CategoryName
                }

                if ($PSBoundParameters.ContainsKey('NetSendAddress'))
                {
                    $OperatorObject.NetSendAddress = $NetSendAddress
                }

                if ($PSBoundParameters.ContainsKey('PagerAddress'))
                {
                    $OperatorObject.PagerAddress = $PagerAddress
                }

                if ($PSBoundParameters.ContainsKey('PagerDays'))
                {
                    $OperatorObject.PagerDays = $PagerDays
                }

                if ($PSBoundParameters.ContainsKey('SaturdayPagerEndTime'))
                {
                    $OperatorObject.SaturdayPagerEndTime = $SaturdayPagerEndTime
                }

                if ($PSBoundParameters.ContainsKey('SaturdayPagerStartTime'))
                {
                    $OperatorObject.SaturdayPagerStartTime = $SaturdayPagerStartTime
                }

                if ($PSBoundParameters.ContainsKey('SundayPagerEndTime'))
                {
                    $OperatorObject.SundayPagerEndTime = $SundayPagerEndTime
                }

                if ($PSBoundParameters.ContainsKey('SundayPagerStartTime'))
                {
                    $OperatorObject.SundayPagerStartTime = $SundayPagerStartTime
                }

                if ($PSBoundParameters.ContainsKey('WeekdayPagerEndTime'))
                {
                    $OperatorObject.WeekdayPagerEndTime = $WeekdayPagerEndTime
                }

                if ($PSBoundParameters.ContainsKey('WeekdayPagerStartTime'))
                {
                    $OperatorObject.WeekdayPagerStartTime = $WeekdayPagerStartTime
                }

                $OperatorObject.Alter()
            }
            catch
            {
                $errorMessage = $script:localizedData.Set_SqlDscAgentOperator_UpdateFailed -f $OperatorObject.Name

                $PSCmdlet.ThrowTerminatingError(
                    [System.Management.Automation.ErrorRecord]::new(
                        [System.InvalidOperationException]::new($errorMessage, $_.Exception),
                        'SSAO0001', # cspell: disable-line
                        [System.Management.Automation.ErrorCategory]::InvalidOperation,
                        $OperatorObject
                    )
                )
            }
        }
    }
}
