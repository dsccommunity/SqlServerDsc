<#
    .SYNOPSIS
        Get server roles from a SQL Server Database Engine instance.

    .DESCRIPTION
        This command gets one or more server roles from a SQL Server Database Engine instance.
        If no name is specified, all server roles are returned.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER Name
        Specifies the name of the server role to get. If not specified, all
        server roles are returned.

    .PARAMETER Refresh
        Specifies that the **ServerObject**'s roles should be refreshed before
        trying to get the role object. This is helpful when roles could have been
        modified outside of the **ServerObject**, for example through T-SQL. But
        on instances with a large amount of roles it might be better to make
        sure the **ServerObject** is recent enough.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | Get-SqlDscRole

        Get all server roles from the instance.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | Get-SqlDscRole -Name 'MyCustomRole'

        Get the server role named **MyCustomRole**.

    .OUTPUTS
        `[Microsoft.SqlServer.Management.Smo.ServerRole[]]`
#>
function Get-SqlDscRole
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [OutputType([Microsoft.SqlServer.Management.Smo.ServerRole[]])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter()]
        [System.String]
        $Name,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Refresh
    )

    process
    {
        if ($Refresh.IsPresent)
        {
            # Refresh the server object's roles collection
            $ServerObject.Roles.Refresh()
        }

        Write-Verbose -Message ($script:localizedData.Role_Get -f $ServerObject.InstanceName)

        $roleObject = @()

        if ($PSBoundParameters.ContainsKey('Name'))
        {
            $roleObject = $ServerObject.Roles[$Name]

            if (-not $roleObject)
            {
                Write-Verbose -Message ($script:localizedData.Get_SqlDscRole_NotFound -f $Name)

                $missingRoleMessage = $script:localizedData.Get_SqlDscRole_NotFound -f $Name

                $writeErrorParameters = @{
                    Message      = $missingRoleMessage
                    Category     = 'ObjectNotFound'
                    ErrorId      = 'GSDR0001' # cspell: disable-line
                    TargetObject = $Name
                }

                Write-Error @writeErrorParameters
            }
            else
            {
                Write-Verbose -Message ($script:localizedData.Role_Found -f $Name)
            }
        }
        else
        {
            Write-Verbose -Message ($script:localizedData.Role_GetAll)

            $roleObject = $ServerObject.Roles
        }

        return [Microsoft.SqlServer.Management.Smo.ServerRole[]] $roleObject
    }
}
