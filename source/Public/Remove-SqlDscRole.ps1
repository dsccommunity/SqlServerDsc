<#
    .SYNOPSIS
        Removes a server role from a SQL Server Database Engine instance.

    .DESCRIPTION
        This command removes a server role from a SQL Server Database Engine instance.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER RoleObject
        Specifies a server role object to remove.

    .PARAMETER Name
        Specifies the name of the server role to be removed.

    .PARAMETER Force
        Specifies that the role should be removed without any confirmation.

    .PARAMETER Refresh
        Specifies that the **ServerObject**'s roles should be refreshed before
        trying to remove the role object. This is helpful when roles could have been
        modified outside of the **ServerObject**, for example through T-SQL. But
        on instances with a large amount of roles it might be better to make
        sure the **ServerObject** is recent enough, or pass in **RoleObject**.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $roleObject = $serverObject | Get-SqlDscRole -Name 'MyCustomRole'
        $roleObject | Remove-SqlDscRole

        Removes the role named **MyCustomRole**.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | Remove-SqlDscRole -Name 'MyCustomRole'

        Removes the role named **MyCustomRole**.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | Remove-SqlDscRole -Name 'MyCustomRole' -Force

        Removes the role named **MyCustomRole** without prompting for confirmation.

    .OUTPUTS
        None.
#>
function Remove-SqlDscRole
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [OutputType()]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param
    (
        [Parameter(ParameterSetName = 'ServerObject', Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter(ParameterSetName = 'RoleObject', Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.ServerRole]
        $RoleObject,

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

    process
    {
        if ($PSCmdlet.ParameterSetName -eq 'ServerObject')
        {
            if ($Refresh.IsPresent)
            {
                # Refresh the server object's roles collection
                $ServerObject.Roles.Refresh()
            }

            Write-Verbose -Message ($script:localizedData.Role_Remove -f $Name, $ServerObject.InstanceName)

            # Get the role object
            $RoleObject = $ServerObject.Roles[$Name]

            if (-not $RoleObject)
            {
                $errorMessage = $script:localizedData.Role_NotFound -f $Name

                $PSCmdlet.ThrowTerminatingError(
                    [System.Management.Automation.ErrorRecord]::new(
                        [System.Management.Automation.ItemNotFoundException]::new($errorMessage),
                        'RSDR0001', # cspell: disable-line
                        [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                        $Name
                    )
                )
            }
        }
        else
        {
            $Name = $RoleObject.Name
            Write-Verbose -Message ($script:localizedData.Role_Remove -f $Name, $RoleObject.Parent.InstanceName)
        }

        # Check if the role is a built-in role (cannot be dropped)
        if ($RoleObject.IsFixedRole)
        {
            $errorMessage = $script:localizedData.Role_CannotRemoveBuiltIn -f $Name

            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    [System.InvalidOperationException]::new($errorMessage),
                    'RSDR0002', # cspell: disable-line
                    [System.Management.Automation.ErrorCategory]::InvalidOperation,
                    $RoleObject
                )
            )
        }

        $verboseDescriptionMessage = $script:localizedData.Role_Remove_ShouldProcessVerboseDescription -f $Name, $RoleObject.Parent.InstanceName
        $verboseWarningMessage = $script:localizedData.Role_Remove_ShouldProcessVerboseWarning -f $Name
        $captionMessage = $script:localizedData.Role_Remove_ShouldProcessCaption

        if ($Force.IsPresent -or $PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage))
        {
            try
            {
                Write-Verbose -Message ($script:localizedData.Role_Removing -f $Name)

                $RoleObject.Drop()

                Write-Verbose -Message ($script:localizedData.Role_Removed -f $Name)
            }
            catch
            {
                $errorMessage = $script:localizedData.Role_RemoveFailed -f $Name, $RoleObject.Parent.InstanceName

                $PSCmdlet.ThrowTerminatingError(
                    [System.Management.Automation.ErrorRecord]::new(
                        [System.InvalidOperationException]::new($errorMessage, $_.Exception),
                        'RSDR0003', # cspell: disable-line
                        [System.Management.Automation.ErrorCategory]::InvalidOperation,
                        $RoleObject
                    )
                )
            }
        }
    }
}
