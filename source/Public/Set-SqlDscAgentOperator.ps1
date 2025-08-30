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
        $WeekdayPagerStartTime
    )

    # cSpell: ignore SSAO
    process
    {
        if ($PSCmdlet.ParameterSetName -eq 'ByName')
        {
            Write-Verbose -Message ($script:localizedData.Set_SqlDscAgentOperator_RefreshingServerObject)
            
            $ServerObject.JobServer.Operators.Refresh()
            
            $OperatorObject = Get-SqlDscAgentOperator -ServerObject $ServerObject -Name $Name

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

        if ($PSBoundParameters.ContainsKey('CategoryName'))
        {
            if ($OperatorObject.CategoryName -ne $CategoryName)
            {
                $changesNeeded = $true
            }
            else
            {
                Write-Verbose -Message ($script:localizedData.Set_SqlDscAgentOperator_CategoryNameAlreadyCorrect -f $CategoryName, $OperatorObject.Name)
            }
        }

        if ($PSBoundParameters.ContainsKey('NetSendAddress'))
        {
            if ($OperatorObject.NetSendAddress -ne $NetSendAddress)
            {
                $changesNeeded = $true
            }
            else
            {
                Write-Verbose -Message ($script:localizedData.Set_SqlDscAgentOperator_NetSendAddressAlreadyCorrect -f $NetSendAddress, $OperatorObject.Name)
            }
        }

        if ($PSBoundParameters.ContainsKey('PagerAddress'))
        {
            if ($OperatorObject.PagerAddress -ne $PagerAddress)
            {
                $changesNeeded = $true
            }
            else
            {
                Write-Verbose -Message ($script:localizedData.Set_SqlDscAgentOperator_PagerAddressAlreadyCorrect -f $PagerAddress, $OperatorObject.Name)
            }
        }

        if ($PSBoundParameters.ContainsKey('PagerDays'))
        {
            if ($OperatorObject.PagerDays -ne $PagerDays)
            {
                $changesNeeded = $true
            }
            else
            {
                Write-Verbose -Message ($script:localizedData.Set_SqlDscAgentOperator_PagerDaysAlreadyCorrect -f $PagerDays, $OperatorObject.Name)
            }
        }

        if ($PSBoundParameters.ContainsKey('SaturdayPagerEndTime'))
        {
            if ($OperatorObject.SaturdayPagerEndTime -ne $SaturdayPagerEndTime)
            {
                $changesNeeded = $true
            }
            else
            {
                Write-Verbose -Message ($script:localizedData.Set_SqlDscAgentOperator_SaturdayPagerEndTimeAlreadyCorrect -f $SaturdayPagerEndTime, $OperatorObject.Name)
            }
        }

        if ($PSBoundParameters.ContainsKey('SaturdayPagerStartTime'))
        {
            if ($OperatorObject.SaturdayPagerStartTime -ne $SaturdayPagerStartTime)
            {
                $changesNeeded = $true
            }
            else
            {
                Write-Verbose -Message ($script:localizedData.Set_SqlDscAgentOperator_SaturdayPagerStartTimeAlreadyCorrect -f $SaturdayPagerStartTime, $OperatorObject.Name)
            }
        }

        if ($PSBoundParameters.ContainsKey('SundayPagerEndTime'))
        {
            if ($OperatorObject.SundayPagerEndTime -ne $SundayPagerEndTime)
            {
                $changesNeeded = $true
            }
            else
            {
                Write-Verbose -Message ($script:localizedData.Set_SqlDscAgentOperator_SundayPagerEndTimeAlreadyCorrect -f $SundayPagerEndTime, $OperatorObject.Name)
            }
        }

        if ($PSBoundParameters.ContainsKey('SundayPagerStartTime'))
        {
            if ($OperatorObject.SundayPagerStartTime -ne $SundayPagerStartTime)
            {
                $changesNeeded = $true
            }
            else
            {
                Write-Verbose -Message ($script:localizedData.Set_SqlDscAgentOperator_SundayPagerStartTimeAlreadyCorrect -f $SundayPagerStartTime, $OperatorObject.Name)
            }
        }

        if ($PSBoundParameters.ContainsKey('WeekdayPagerEndTime'))
        {
            if ($OperatorObject.WeekdayPagerEndTime -ne $WeekdayPagerEndTime)
            {
                $changesNeeded = $true
            }
            else
            {
                Write-Verbose -Message ($script:localizedData.Set_SqlDscAgentOperator_WeekdayPagerEndTimeAlreadyCorrect -f $WeekdayPagerEndTime, $OperatorObject.Name)
            }
        }

        if ($PSBoundParameters.ContainsKey('WeekdayPagerStartTime'))
        {
            if ($OperatorObject.WeekdayPagerStartTime -ne $WeekdayPagerStartTime)
            {
                $changesNeeded = $true
            }
            else
            {
                Write-Verbose -Message ($script:localizedData.Set_SqlDscAgentOperator_WeekdayPagerStartTimeAlreadyCorrect -f $WeekdayPagerStartTime, $OperatorObject.Name)
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

                if ($PSBoundParameters.ContainsKey('CategoryName'))
                {
                    Write-Verbose -Message ($script:localizedData.Set_SqlDscAgentOperator_SettingCategoryName -f $CategoryName, $OperatorObject.Name)
                    $OperatorObject.CategoryName = $CategoryName
                }

                if ($PSBoundParameters.ContainsKey('NetSendAddress'))
                {
                    Write-Verbose -Message ($script:localizedData.Set_SqlDscAgentOperator_SettingNetSendAddress -f $NetSendAddress, $OperatorObject.Name)
                    $OperatorObject.NetSendAddress = $NetSendAddress
                }

                if ($PSBoundParameters.ContainsKey('PagerAddress'))
                {
                    Write-Verbose -Message ($script:localizedData.Set_SqlDscAgentOperator_SettingPagerAddress -f $PagerAddress, $OperatorObject.Name)
                    $OperatorObject.PagerAddress = $PagerAddress
                }

                if ($PSBoundParameters.ContainsKey('PagerDays'))
                {
                    Write-Verbose -Message ($script:localizedData.Set_SqlDscAgentOperator_SettingPagerDays -f $PagerDays, $OperatorObject.Name)
                    $OperatorObject.PagerDays = $PagerDays
                }

                if ($PSBoundParameters.ContainsKey('SaturdayPagerEndTime'))
                {
                    Write-Verbose -Message ($script:localizedData.Set_SqlDscAgentOperator_SettingSaturdayPagerEndTime -f $SaturdayPagerEndTime, $OperatorObject.Name)
                    $OperatorObject.SaturdayPagerEndTime = $SaturdayPagerEndTime
                }

                if ($PSBoundParameters.ContainsKey('SaturdayPagerStartTime'))
                {
                    Write-Verbose -Message ($script:localizedData.Set_SqlDscAgentOperator_SettingSaturdayPagerStartTime -f $SaturdayPagerStartTime, $OperatorObject.Name)
                    $OperatorObject.SaturdayPagerStartTime = $SaturdayPagerStartTime
                }

                if ($PSBoundParameters.ContainsKey('SundayPagerEndTime'))
                {
                    Write-Verbose -Message ($script:localizedData.Set_SqlDscAgentOperator_SettingSundayPagerEndTime -f $SundayPagerEndTime, $OperatorObject.Name)
                    $OperatorObject.SundayPagerEndTime = $SundayPagerEndTime
                }

                if ($PSBoundParameters.ContainsKey('SundayPagerStartTime'))
                {
                    Write-Verbose -Message ($script:localizedData.Set_SqlDscAgentOperator_SettingSundayPagerStartTime -f $SundayPagerStartTime, $OperatorObject.Name)
                    $OperatorObject.SundayPagerStartTime = $SundayPagerStartTime
                }

                if ($PSBoundParameters.ContainsKey('WeekdayPagerEndTime'))
                {
                    Write-Verbose -Message ($script:localizedData.Set_SqlDscAgentOperator_SettingWeekdayPagerEndTime -f $WeekdayPagerEndTime, $OperatorObject.Name)
                    $OperatorObject.WeekdayPagerEndTime = $WeekdayPagerEndTime
                }

                if ($PSBoundParameters.ContainsKey('WeekdayPagerStartTime'))
                {
                    Write-Verbose -Message ($script:localizedData.Set_SqlDscAgentOperator_SettingWeekdayPagerStartTime -f $WeekdayPagerStartTime, $OperatorObject.Name)
                    $OperatorObject.WeekdayPagerStartTime = $WeekdayPagerStartTime
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
