<#
    .SYNOPSIS
        Removes a database from a SQL Server Database Engine instance.

    .DESCRIPTION
        This command removes a database from a SQL Server Database Engine instance.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER DatabaseObject
        Specifies a database object to remove.

    .PARAMETER Name
        Specifies the name of the database to be removed.

    .PARAMETER Force
        Specifies that the database should be removed without any confirmation.

    .PARAMETER Refresh
        Specifies that the **ServerObject**'s databases should be refreshed before
        trying to remove the database object. This is helpful when databases could have been
        modified outside of the **ServerObject**, for example through T-SQL. But
        on instances with a large amount of databases it might be better to make
        sure the **ServerObject** is recent enough, or pass in **DatabaseObject**.

    .PARAMETER DropConnections
        Specifies that all active connections to the database should be dropped
        before removing the database. This sets the database to single-user mode
        with immediate rollback of active transactions, which forcibly disconnects
        all users and allows the database to be removed even when there are
        active connections.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $databaseObject = $serverObject | Get-SqlDscDatabase -Name 'MyDatabase'
        $databaseObject | Remove-SqlDscDatabase

        Removes the database named **MyDatabase**.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | Remove-SqlDscDatabase -Name 'MyDatabase'

        Removes the database named **MyDatabase**.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | Remove-SqlDscDatabase -Name 'MyDatabase' -Force

        Removes the database named **MyDatabase** without prompting for confirmation.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | Remove-SqlDscDatabase -Name 'MyDatabase' -DropConnections -Force

        Drops all active connections to the database named **MyDatabase** and then removes it
        without prompting for confirmation. This is useful when the database has active
        connections that prevent removal.

    
    .INPUTS
        `Microsoft.SqlServer.Management.Smo.Server`

        Server object accepted from the pipeline (ServerObject parameter set).

    .INPUTS
        `Microsoft.SqlServer.Management.Smo.Database`

        Database object accepted from the pipeline (DatabaseObject parameter set).

    .OUTPUTS
        None.
#>
function Remove-SqlDscDatabase
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [OutputType()]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param
    (
        [Parameter(ParameterSetName = 'ServerObject', Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter(ParameterSetName = 'DatabaseObject', Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Database]
        $DatabaseObject,

        [Parameter(ParameterSetName = 'ServerObject', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force,

        [Parameter(ParameterSetName = 'ServerObject')]
        [System.Management.Automation.SwitchParameter]
        $Refresh,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $DropConnections
    )

    begin
    {
        if ($Force.IsPresent -and -not $Confirm)
        {
            $ConfirmPreference = 'None'
        }
    }

    process
    {
        if ($PSCmdlet.ParameterSetName -eq 'ServerObject')
        {
            if ($Refresh.IsPresent)
            {
                # Refresh the server object's databases collection
                $ServerObject.Databases.Refresh()
            }

            # Get the database object
            $DatabaseObject = $ServerObject.Databases[$Name]

            if (-not $DatabaseObject)
            {
                $errorMessage = $script:localizedData.Remove_SqlDscDatabase_NotFound -f $Name

                $PSCmdlet.ThrowTerminatingError(
                    [System.Management.Automation.ErrorRecord]::new(
                        [System.Management.Automation.ItemNotFoundException]::new($errorMessage),
                        'RSDD0002', # cspell: disable-line
                        [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                        $Name
                    )
                )
            }
        }
        else
        {
            $Name = $DatabaseObject.Name
        }

        # Check if the database is a system database (cannot be dropped)
        if ($Name -in @('master', 'model', 'msdb', 'tempdb'))
        {
            $errorMessage = $script:localizedData.Database_CannotRemoveSystem -f $Name

            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    [System.InvalidOperationException]::new($errorMessage),
                    'RSDD0001', # cspell: disable-line
                    [System.Management.Automation.ErrorCategory]::InvalidOperation,
                    $Name
                )
            )
        }

        $descriptionMessage = $script:localizedData.Database_Remove_ShouldProcessDescription -f $Name, $DatabaseObject.Parent.InstanceName
        $confirmationMessage = $script:localizedData.Database_Remove_ShouldProcessConfirmation -f $Name
        $captionMessage = $script:localizedData.Database_Remove_ShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($descriptionMessage, $confirmationMessage, $captionMessage))
        {
            # Drop all active connections if requested
            if ($DropConnections.IsPresent)
            {
                Write-Verbose -Message ($script:localizedData.Database_DroppingConnections -f $Name)

                try
                {
                    $DatabaseObject.UserAccess = [Microsoft.SqlServer.Management.Smo.DatabaseUserAccess]::Single
                    $DatabaseObject.Alter([Microsoft.SqlServer.Management.Smo.TerminationClause]::RollbackTransactionsImmediately)
                }
                catch
                {
                    $errorMessage = $script:localizedData.Database_DropConnectionsFailed -f $Name

                    $PSCmdlet.ThrowTerminatingError(
                        [System.Management.Automation.ErrorRecord]::new(
                            [System.InvalidOperationException]::new($errorMessage, $_.Exception),
                            'RSDD0004', # cspell: disable-line
                            [System.Management.Automation.ErrorCategory]::InvalidOperation,
                            $DatabaseObject
                        )
                    )
                }
            }

            try
            {
                $DatabaseObject.Drop()
            }
            catch
            {
                $errorMessage = $script:localizedData.Database_RemoveFailed -f $Name, $DatabaseObject.Parent.InstanceName

                $PSCmdlet.ThrowTerminatingError(
                    [System.Management.Automation.ErrorRecord]::new(
                        [System.InvalidOperationException]::new($errorMessage, $_.Exception),
                        'RSDD0005', # cspell: disable-line
                        [System.Management.Automation.ErrorCategory]::InvalidOperation,
                        $DatabaseObject
                    )
                )
            }
        }
    }
}
