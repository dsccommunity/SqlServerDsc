<#
    .SYNOPSIS
        Assert that a feature is supported by a Microsoft SQL Server major version.

    .DESCRIPTION
        Assert that a feature is supported by a Microsoft SQL Server major version.

    .PARAMETER Feature
       Specifies the feature to evaluate.

    .PARAMETER ProductVersion
       Specifies the product version of the Microsoft SQL Server. At minimum the
       major version must be provided.

    .EXAMPLE
        Assert-Feature -Feature 'RS' -ProductVersion '14'

        Throws an exception if the feature is not supported.

    .OUTPUTS
        None.
#>
function Assert-Feature
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.String[]]
        $Feature,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ProductVersion
    )

    process
    {
        foreach ($currentFeature in $Feature)
        {
            if (-not ($currentFeature | Test-SqlDscIsSupportedFeature -ProductVersion $ProductVersion))
            {
                $PSCmdlet.ThrowTerminatingError(
                    [System.Management.Automation.ErrorRecord]::new(
                        ($script:localizedData.Feature_Assert_NotSupportedFeature -f $currentFeature, $ProductVersion),
                        'AF0001', # cSpell: disable-line
                        [System.Management.Automation.ErrorCategory]::InvalidOperation,
                        $currentFeature
                    )
                )
            }
        }
    }
}
