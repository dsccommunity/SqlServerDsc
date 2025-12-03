<#
    .SYNOPSIS
        Converts a ServerPermission object into an object of the type
        Microsoft.SqlServer.Management.Smo.ServerPermissionSet.

    .DESCRIPTION
        Converts a ServerPermission object into an object of the type
        Microsoft.SqlServer.Management.Smo.ServerPermissionSet.

    .PARAMETER Permission
        Specifies a ServerPermission object.

    .EXAMPLE
        [ServerPermission] @{
            State = 'Grant'
            Permission = 'Connect'
        } | ConvertFrom-SqlDscServerPermission

        Returns an object of type `[Microsoft.SqlServer.Management.Smo.ServerPermissionSet]`
        with all the permissions set to $true that was part of the `[ServerPermission]`.

    .INPUTS
        `ServerPermission`

        Accepts a ServerPermission object via the pipeline.

    .OUTPUTS
        `Microsoft.SqlServer.Management.Smo.ServerPermissionSet`

        Returns a server permission set object.
#>
function ConvertFrom-SqlDscServerPermission
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when the output type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [CmdletBinding()]
    [OutputType([Microsoft.SqlServer.Management.Smo.ServerPermissionSet])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ServerPermission]
        $Permission
    )

    begin
    {
        $permissionSet = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionSet'
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
