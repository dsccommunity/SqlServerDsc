<#
    .SYNOPSIS
        Returns whether the database principal exist.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER DatabaseName
        Specifies the SQL database name.

    .PARAMETER Name
        Specifies the name of the database principal.

    .PARAMETER ExcludeUsers
        Specifies that database users should not be evaluated.

    .PARAMETER ExcludeRoles
        Specifies that database roles should not be evaluated for the specified
        name. This will also exclude fixed roles.

    .PARAMETER ExcludeFixedRoles
        Specifies that fixed roles should not be evaluated for the specified name.

    .PARAMETER ExcludeApplicationRoles
        Specifies that fixed application roles should not be evaluated for the
        specified name.

    .OUTPUTS
        [System.Boolean]

    .EXAMPLE
        $serverInstance = Connect-SqlDscDatabaseEngine
        Test-SqlDscIsDatabasePrincipal -ServerObject $serverInstance -DatabaseName 'MyDatabase' -Name 'MyPrincipal'

#>
function Test-SqlDscIsDatabasePrincipal
{
    <#
        The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error
        in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8
        When QA test run it loads the stub SMO classes so that the rule passes.
    #>
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DatabaseName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $ExcludeUsers,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $ExcludeRoles,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $ExcludeFixedRoles,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $ExcludeApplicationRoles
    )

    $principalExist = $false

    $sqlDatabaseObject = $ServerObject.Databases[$DatabaseName]

    if (-not $sqlDatabaseObject)
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                ($script:localizedData.IsDatabasePrincipal_DatabaseMissing -f $DatabaseName),
                'TSDISO0001',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $DatabaseName
            )
        )
    }

    if (-not $ExcludeUsers.IsPresent -and $sqlDatabaseObject.Users[$Name])
    {
        $principalExist = $true
    }

    if (-not $ExcludeRoles.IsPresent)
    {
        $userDefinedRole = if ($ExcludeFixedRoles.IsPresent)
        {
            # Skip fixed roles like db_datareader.
            $sqlDatabaseObject.Roles | Where-Object -FilterScript {
                -not $_.IsFixedRole -and $_.Name -eq $Name
            }
        }
        else
        {
            $sqlDatabaseObject.Roles[$Name]
        }

        if ($userDefinedRole)
        {
            $principalExist = $true
        }
    }

    if (-not $ExcludeApplicationRoles.IsPresent -and $sqlDatabaseObject.ApplicationRoles[$Name])
    {
        $principalExist = $true
    }

    return $principalExist
}
