<#
    .SYNOPSIS
        Gets a SQL Agent Alert object from the JobServer.

    .DESCRIPTION
        Gets a SQL Agent Alert object from the JobServer based on the specified name.

    .PARAMETER ServerObject
        Specifies the SQL Server object.

    .PARAMETER Name
        Specifies the name of the SQL Agent Alert.

    .OUTPUTS
        [Microsoft.SqlServer.Management.Smo.Agent.Alert] or $null if not found.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine
        Get-AgentAlertObject -ServerObject $serverObject -Name 'MyAlert'

        Gets the SQL Agent Alert named 'MyAlert'.
#>
function Get-AgentAlertObject
{
    [CmdletBinding()]
    [OutputType([Microsoft.SqlServer.Management.Smo.Agent.Alert])]
    param
    (
        [Parameter(Mandatory = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name
    )

    Write-Verbose -Message ($script:localizedData.Get_AgentAlertObject_GettingAlert -f $Name)

    $alertObject = $ServerObject.JobServer.Alerts | Where-Object -FilterScript { $_.Name -eq $Name }

    return $alertObject
}
