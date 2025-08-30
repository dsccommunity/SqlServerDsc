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
        $Refresh
    )

    $ErrorActionPreference = 'Stop'

    process
    {
        if ($PSCmdlet.ParameterSetName -eq 'ServerObject')
        {
            if ($Refresh.IsPresent)
            {
                # Refresh the server object's databases collection
                $ServerObject.Databases.Refresh()
            }

            Write-Verbose -Message ($script:localizedData.Database_Remove -f $Name, $ServerObject.InstanceName)

            # Check if the database is a system database (cannot be dropped)
            $systemDatabases = @('master', 'model', 'msdb', 'tempdb')
            if ($Name -in $systemDatabases)
            {
                $errorMessage = $script:localizedData.Database_CannotRemoveSystem -f $Name
                New-InvalidOperationException -Message $errorMessage
            }

            # Get the database object
            $DatabaseObject = $ServerObject.Databases[$Name]

            if (-not $DatabaseObject)
            {
                $errorMessage = $script:localizedData.Database_NotFound -f $Name
                New-InvalidOperationException -Message $errorMessage
            }
        }
        else
        {
            $Name = $DatabaseObject.Name
            Write-Verbose -Message ($script:localizedData.Database_Remove -f $Name, $DatabaseObject.Parent.InstanceName)

            # Check if the database is a system database (cannot be dropped)
            $systemDatabases = @('master', 'model', 'msdb', 'tempdb')
            if ($Name -in $systemDatabases)
            {
                $errorMessage = $script:localizedData.Database_CannotRemoveSystem -f $Name
                New-InvalidOperationException -Message $errorMessage
            }
        }

        $verboseDescriptionMessage = $script:localizedData.Database_Remove_ShouldProcessVerboseDescription -f $Name, $DatabaseObject.Parent.InstanceName
        $verboseWarningMessage = $script:localizedData.Database_Remove_ShouldProcessVerboseWarning -f $Name
        $captionMessage = $script:localizedData.Database_Remove_ShouldProcessCaption

        if ($Force.IsPresent -or $PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage))
        {
            try
            {
                Write-Verbose -Message ($script:localizedData.Database_Removing -f $Name)

                $DatabaseObject.Drop()

                Write-Verbose -Message ($script:localizedData.Database_Removed -f $Name)
            }
            catch
            {
                $errorMessage = $script:localizedData.Database_RemoveFailed -f $Name, $DatabaseObject.Parent.InstanceName
                New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
            }
        }
    }
}
