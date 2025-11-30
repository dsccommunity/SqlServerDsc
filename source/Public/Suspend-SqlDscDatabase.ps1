<#
    .SYNOPSIS
        Takes a SQL Server database offline.

    .DESCRIPTION
        This command takes a SQL Server database offline, making it temporarily
        unavailable. It is useful for maintenance scenarios, backups, or when you
        need to restrict access temporarily. The command uses the SMO
        Database.SetOffline() method to suspend the database.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER Name
        Specifies the name of the database to take offline.

    .PARAMETER DatabaseObject
        Specifies the database object to take offline (from Get-SqlDscDatabase).

    .PARAMETER Force
        Specifies that the database should be forced offline even if users are connected.
        When specified, active connections will be disconnected immediately with rollback.
        Use this parameter with caution as it can disrupt active sessions.

    .PARAMETER Refresh
        Specifies that the **ServerObject**'s databases should be refreshed before
        trying to get the database object. This is helpful when databases could have been
        modified outside of the **ServerObject**, for example through T-SQL. But
        on instances with a large amount of databases it might be better to make
        sure the **ServerObject** is recent enough.

        This parameter is only used when suspending a database using **ServerObject** and
        **Name** parameters.

    .PARAMETER PassThru
        Specifies that the database object should be returned after the operation.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        Suspend-SqlDscDatabase -ServerObject $serverObject -Name 'MyDatabase'

        Takes the database named **MyDatabase** offline.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $databaseObject = $serverObject | Get-SqlDscDatabase -Name 'MyDatabase'
        Suspend-SqlDscDatabase -DatabaseObject $databaseObject -Force

        Takes the database offline using a database object, forcing disconnection of any active users.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        Suspend-SqlDscDatabase -ServerObject $serverObject -Name 'MyDatabase' -PassThru

        Takes the database offline and returns the updated database object.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | Get-SqlDscDatabase -Name 'MyDatabase' | Suspend-SqlDscDatabase -Force

        Takes the database offline using pipeline input, forcing disconnection of any active users.

    .INPUTS
        Microsoft.SqlServer.Management.Smo.Server

        The server object from Connect-SqlDscDatabaseEngine.

    .INPUTS
        Microsoft.SqlServer.Management.Smo.Database

        The database object to take offline (from Get-SqlDscDatabase).

    .OUTPUTS
        None.

        By default, no output is returned.

    .OUTPUTS
        Microsoft.SqlServer.Management.Smo.Database

        When PassThru is specified, the updated database object is returned.
#>
function Suspend-SqlDscDatabase
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues.')]
    [OutputType()]
    [OutputType([Microsoft.SqlServer.Management.Smo.Database])]
    [CmdletBinding(DefaultParameterSetName = 'ServerObjectSet', SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param
    (
        [Parameter(ParameterSetName = 'ServerObjectSet', Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter(ParameterSetName = 'ServerObjectSet', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force,

        [Parameter(ParameterSetName = 'ServerObjectSet')]
        [System.Management.Automation.SwitchParameter]
        $Refresh,

        [Parameter(ParameterSetName = 'DatabaseObjectSet', Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Database]
        $DatabaseObject,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $PassThru
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
        # Get the database object based on the parameter set
        switch ($PSCmdlet.ParameterSetName)
        {
            'ServerObjectSet'
            {
                $previousErrorActionPreference = $ErrorActionPreference
                $ErrorActionPreference = 'Stop'

                $sqlDatabaseObject = $ServerObject |
                    Get-SqlDscDatabase -Name $Name -Refresh:$Refresh -ErrorAction 'Stop'

                $ErrorActionPreference = $previousErrorActionPreference
            }

            'DatabaseObjectSet'
            {
                $sqlDatabaseObject = $DatabaseObject
            }
        }

        $descriptionMessage = $script:localizedData.Database_Suspend_ShouldProcessVerboseDescription -f $sqlDatabaseObject.Name, $sqlDatabaseObject.Parent.InstanceName
        $confirmationMessage = $script:localizedData.Database_Suspend_ShouldProcessVerboseWarning -f $sqlDatabaseObject.Name
        $captionMessage = $script:localizedData.Database_Suspend_ShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($descriptionMessage, $confirmationMessage, $captionMessage))
        {
            # Check if database is already offline (idempotence)
            if ($sqlDatabaseObject.Status -eq [Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Offline)
            {
                Write-Debug -Message ($script:localizedData.Database_AlreadyOffline -f $sqlDatabaseObject.Name)
            }
            else
            {
                if ($Force.IsPresent)
                {
                    Write-Debug -Message ($script:localizedData.Database_TakingOfflineWithForce -f $sqlDatabaseObject.Name)

                    # Kill all processes before taking the database offline
                    Write-Debug -Message ($script:localizedData.Database_KillingProcesses -f $sqlDatabaseObject.Name)

                    try
                    {
                        $sqlDatabaseObject.Parent.KillAllProcesses($sqlDatabaseObject.Name)
                    }
                    catch
                    {
                        $errorMessage = $script:localizedData.Database_KillProcessesFailed -f $sqlDatabaseObject.Name

                        $PSCmdlet.ThrowTerminatingError(
                            [System.Management.Automation.ErrorRecord]::new(
                                [System.InvalidOperationException]::new($errorMessage, $_.Exception),
                                'SSDD0002', # cspell: disable-line
                                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                                $sqlDatabaseObject
                            )
                        )
                    }
                }
                else
                {
                    Write-Debug -Message ($script:localizedData.Database_TakingOffline -f $sqlDatabaseObject.Name)
                }

                try
                {
                    $sqlDatabaseObject.SetOffline()
                }
                catch
                {
                    $errorMessage = $script:localizedData.Database_SuspendFailed -f $sqlDatabaseObject.Name

                    $PSCmdlet.ThrowTerminatingError(
                        [System.Management.Automation.ErrorRecord]::new(
                            [System.InvalidOperationException]::new($errorMessage, $_.Exception),
                            'SSDD0001', # cspell: disable-line
                            [System.Management.Automation.ErrorCategory]::InvalidOperation,
                            $sqlDatabaseObject
                        )
                    )
                }

                Write-Debug -Message ($script:localizedData.Database_TakenOffline -f $sqlDatabaseObject.Name)
            }

            if ($PassThru.IsPresent)
            {
                # Refresh the database object to get the updated Status property
                $sqlDatabaseObject.Refresh()

                $sqlDatabaseObject
            }
        }
    }
}
