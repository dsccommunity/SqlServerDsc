<#
    .SYNOPSIS
        Returns the current permissions for the principal.

    .DESCRIPTION
        Returns the current permissions for the principal.

    .PARAMETER ServerObject
        Specifies current server connection object.

    .PARAMETER Name
        Specifies the name of the principal for which the permissions are
        returned.

    .OUTPUTS
        [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo[]]

    .EXAMPLE
        $serverInstance = Connect-SqlDscDatabaseEngine
        Get-SqlDscServerPermission -ServerObject $serverInstance -Name 'MyPrincipal'

        Get the permissions for the principal 'MyPrincipal'.

    .NOTES
        If specifying `-ErrorAction 'SilentlyContinue'` then the command will silently
        ignore if the principal (parameter **Name**) is not present. In such case the
        command will return `$null`. If specifying `-ErrorAction 'Stop'` the command
        will throw an error if the principal is missing.
#>
function Get-SqlDscServerPermission
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseOutputTypeCorrectly', '', Justification = 'Because the rule does not understands that the command returns [System.String[]] when using , (comma) in the return statement')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('AvoidThrowOutsideOfTry', '', Justification = 'Because the code throws based on an prior expression')]
    [CmdletBinding()]
    [OutputType([Microsoft.SqlServer.Management.Smo.ServerPermissionInfo[]])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name
    )

    # cSpell: ignore GSDSP
    process
    {
        $getSqlDscServerPermissionResult = $null

        $testSqlDscIsLoginParameters = @{
            ServerObject = $ServerObject
            Name         = $Name
        }

        $isLogin = Test-SqlDscIsLogin @testSqlDscIsLoginParameters

        if ($isLogin)
        {
            $getSqlDscServerPermissionResult = $ServerObject.EnumServerPermissions($Name)
        }
        else
        {
            $missingPrincipalMessage = $script:localizedData.ServerPermission_MissingPrincipal -f $Name, $ServerObject.InstanceName

            Write-Error -Message $missingPrincipalMessage -Category 'InvalidOperation' -ErrorId 'GSDSP0001' -TargetObject $Name
        }

        return , [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo[]] $getSqlDscServerPermissionResult
    }
}
