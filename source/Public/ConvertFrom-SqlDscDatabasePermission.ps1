<#
    .SYNOPSIS
        Converts a DatabasePermission object into an object of the type
        Microsoft.SqlServer.Management.Smo.DatabasePermissionSet.

    .DESCRIPTION
        Converts a DatabasePermission object into an object of the type
        Microsoft.SqlServer.Management.Smo.DatabasePermissionSet.

    .PARAMETER Permission
        Specifies a DatabasePermission object.

    .EXAMPLE
        [DatabasePermission] @{
            State = 'Grant'
            Permission = 'Connect'
        } | ConvertFrom-SqlDscDatabasePermission

        Returns an object of `[Microsoft.SqlServer.Management.Smo.DatabasePermissionSet]`
        with all the permissions set to $true that was part of the `[DatabasePermission]`.

    .OUTPUTS
        [Microsoft.SqlServer.Management.Smo.DatabasePermissionSet]
#>
function ConvertFrom-SqlDscDatabasePermission
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when the output type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [CmdletBinding()]
    [OutputType([Microsoft.SqlServer.Management.Smo.DatabasePermissionSet])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [DatabasePermission]
        $Permission
    )

    begin
    {
        $permissionSet = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionSet'
    }

    process
    {
        foreach ($permissionName in $Permission.Permission)
        {
            $permissionSet.$permissionName = $true
        }
    }

    end
    {
        return $permissionSet
    }
}
