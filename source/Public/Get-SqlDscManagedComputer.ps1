<#
    .SYNOPSIS
        Returns the managed computer object.

    .DESCRIPTION
        Returns the managed computer object, by default for the node the command
        is run on.

    .PARAMETER ServerName
       Specifies the server name for which to return the managed computer object.

    .EXAMPLE
        Get-SqlDscManagedComputer

        Returns the managed computer object for the current node.

    .EXAMPLE
        Get-SqlDscManagedComputer -ServerName 'MyServer'

        Returns the managed computer object for the server 'MyServer'.

    .OUTPUTS
        `[Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer]`
#>
function Get-SqlDscManagedComputer
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when the output type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]    [OutputType([Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer])]
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.String]
        $ServerName = (Get-ComputerName)
    )

    Write-Verbose -Message (
        $script:localizedData.ManagedComputer_GetState -f $ServerName
    )

    $managedComputerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer' -ArgumentList $ServerName

    return $managedComputerObject
}
