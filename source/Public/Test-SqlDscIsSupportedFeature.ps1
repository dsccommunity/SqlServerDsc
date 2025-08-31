<#
    .SYNOPSIS
        Tests that a feature is supported by a Microsoft SQL Server major version.

    .DESCRIPTION
        Tests that a feature is supported by a Microsoft SQL Server major version.

    .PARAMETER Feature
       Specifies the feature to evaluate.

    .PARAMETER ProductVersion
       Specifies the product version of the Microsoft SQL Server. At minimum the
       major version must be provided.

    .EXAMPLE
        Test-SqlDscIsSupportedFeature -Feature 'RS' -ProductVersion '13'

        Returns $true if the feature is supported.

    .OUTPUTS
        [System.Boolean]
#>
function Test-SqlDscIsSupportedFeature
{
    [OutputType([System.Boolean])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.String]
        $Feature,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ProductVersion
    )

    begin
    {
        $targetMajorVersion = ($ProductVersion -split '\.')[0]

        <#
            List of features that was removed from a specific major version (and later).
            Feature list: https://learn.microsoft.com/en-us/sql/database-engine/install-windows/install-sql-server-from-the-command-prompt#Feature
        #>
        $removedFeaturesPerMajorVersion = @{
            13 = @('ADV_SSMS', 'SSMS') # cSpell: disable-line
            14 = @('RS', 'RS_SHP', 'RS_SHPWFE') # cSpell: disable-line
            16 = @('Tools', 'BC', 'CONN', 'BC', 'DREPLAY_CTLR', 'DREPLAY_CLT', 'SNAC_SDK', 'SDK', 'PolyBaseJava', 'SQL_INST_MR', 'SQL_INST_MPY', 'SQL_SHARED_MPY', 'SQL_SHARED_MR') # cSpell: disable-line
        }

        <#
            List of features that was added to a specific major version.
            Feature list: https://learn.microsoft.com/en-us/sql/database-engine/install-windows/install-sql-server-from-the-command-prompt#Feature
        #>
        $addedFeaturesPerMajorVersion = @{
            13 = @('SQL_INST_MR', 'SQL_INST_MPY', 'SQL_INST_JAVA')
            15 = @('PolyBaseCore', 'PolyBaseJava', 'SQL_INST_JAVA') # cSpell: disable-line
        }

        # Evaluate features that was removed and are unsupported for the target's major version.
        $targetUnsupportedFeatures = $removedFeaturesPerMajorVersion.Keys |
            Where-Object -FilterScript {
                $_ -le $targetMajorVersion
            } |
            ForEach-Object -Process {
                $removedFeaturesPerMajorVersion.$_
            }

        <#
            Evaluate features that was added to higher major versions than the
            target's major version which will be unsupported for the target's
            major version.
        #>
        $targetUnsupportedFeatures += $addedFeaturesPerMajorVersion.Keys |
            Where-Object -FilterScript {
                $_ -gt $targetMajorVersion
            } |
            ForEach-Object -Process {
                $addedFeaturesPerMajorVersion.$_
            }

        $supported = $true
    }

    process
    {
        # This does case-insensitive match against the list of unsupported features.
        if ($targetUnsupportedFeatures -and $Feature -in $targetUnsupportedFeatures)
        {
            $supported = $false
        }
    }

    end
    {
        return $supported
    }
}
