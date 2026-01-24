<#
    .SYNOPSIS
        Imports the assembly into the session.

    .DESCRIPTION
        Imports the assembly into the session and returns a reference to the
        assembly.

    .PARAMETER Name
        Specifies the name of the assembly to load.

    .PARAMETER LoadWithPartialName
        Specifies if the imported assembly should be the first found in GAC,
        regardless of version.

    .OUTPUTS
        [System.Reflection.Assembly]

        Returns a reference to the assembly object.

    .EXAMPLE
        Import-Assembly -Name "Microsoft.SqlServer.ConnectionInfo, Version=$SqlMajorVersion.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91"

    .EXAMPLE
        Import-Assembly -Name 'Microsoft.AnalysisServices' -LoadWithPartialName

    .NOTES
        This should normally work using Import-Module and New-Object instead of
        using the method [System.Reflection.Assembly]::Load(). But due to a
        missing assembly in the module SqlServer this is still needed.

        Import-Module SqlServer
        $connectionInfo = New-Object -TypeName 'Microsoft.SqlServer.Management.Common.ServerConnection' -ArgumentList @('testclu01a\SQL2014')
        # Missing assembly 'Microsoft.SqlServer.Rmo' in module SqlServer prevents this call from working.
        $replication = New-Object -TypeName 'Microsoft.SqlServer.Replication.ReplicationServer' -ArgumentList @($connectionInfo)
#>
function Import-Assembly
{
    [CmdletBinding()]
    [OutputType([System.Reflection.Assembly])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $LoadWithPartialName
    )

    try
    {
        if ($LoadWithPartialName.IsPresent)
        {
            $assemblyInformation = [System.Reflection.Assembly]::LoadWithPartialName($Name)
        }
        else
        {
            $assemblyInformation = [System.Reflection.Assembly]::Load($Name)
        }

        Write-Verbose -Message (
            $script:localizedData.LoadedAssembly -f $assemblyInformation.FullName
        )
    }
    catch
    {
        $errorMessage = $script:localizedData.FailedToLoadAssembly -f $Name

        New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
    }

    return $assemblyInformation
}
