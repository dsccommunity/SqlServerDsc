<#
    .SYNOPSIS
        Creates a new server role in a SQL Server Database Engine instance.

    .DESCRIPTION
        This command creates a new server role in a SQL Server Database Engine instance.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER Name
        Specifies the name of the server role to be created.

    .PARAMETER Owner
        Specifies the owner of the server role. If not specified, the role
        will be owned by the login that creates it.

    .PARAMETER Force
        Specifies that the role should be created without any confirmation.

    .PARAMETER Refresh
        Specifies that the **ServerObject**'s roles should be refreshed before
        creating the role object. This is helpful when roles could have been
        modified outside of the **ServerObject**, for example through T-SQL. But
        on instances with a large amount of roles it might be better to make
        sure the **ServerObject** is recent enough.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | New-SqlDscRole -Name 'MyCustomRole'

        Creates a new server role named **MyCustomRole**.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | New-SqlDscRole -Name 'MyCustomRole' -Owner 'MyOwner' -Force

        Creates a new server role named **MyCustomRole** with the specified owner
        without prompting for confirmation.

    .OUTPUTS
        `[Microsoft.SqlServer.Management.Smo.ServerRole]`
#>
function New-SqlDscRole
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [OutputType([Microsoft.SqlServer.Management.Smo.ServerRole])]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
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
        $Owner,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Refresh
    )

    begin
    {
         }

    process
    {
        if ($Refresh.IsPresent)
        {
            # Refresh the server object's roles collection
            $ServerObject.Roles.Refresh()
        }

        Write-Verbose -Message ($script:localizedData.Role_Create -f $Name, $ServerObject.InstanceName)

        # Check if the role already exists
        if ($ServerObject.Roles[$Name])
        {
            $errorMessage = $script:localizedData.Role_AlreadyExists -f $Name, $ServerObject.InstanceName
            New-InvalidOperationException -Message $errorMessage
        }

        $verboseDescriptionMessage = $script:localizedData.Role_Create_ShouldProcessVerboseDescription -f $Name, $ServerObject.InstanceName
        $verboseWarningMessage = $script:localizedData.Role_Create_ShouldProcessVerboseWarning -f $Name
        $captionMessage = $script:localizedData.Role_Create_ShouldProcessCaption

        if ($Force.IsPresent -or $PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage))
        {
            try
            {
                $serverRole = New-Object -TypeName Microsoft.SqlServer.Management.Smo.ServerRole -ArgumentList $ServerObject, $Name

                if ($PSBoundParameters.ContainsKey('Owner'))
                {
                    $serverRole.Owner = $Owner
                }

                Write-Verbose -Message ($script:localizedData.Role_Creating -f $Name)

                $serverRole.Create()

                Write-Verbose -Message ($script:localizedData.Role_Created -f $Name)

                return $serverRole
            }
            catch
            {
                $errorMessage = $script:localizedData.Role_CreateFailed -f $Name, $ServerObject.InstanceName
                New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
            }
        }
    }
}
