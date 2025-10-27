<#
    .SYNOPSIS
        Gets the supported database compatibility levels for a SQL Server instance or version.

    .DESCRIPTION
        This command returns the supported database compatibility levels for a SQL Server
        Database Engine instance or a specific SQL Server version.

        The compatibility levels are determined based on the SQL Server version, following
        the official Microsoft documentation for supported compatibility level ranges.

    .PARAMETER ServerObject
        Specifies the SQL Server connection object to get supported compatibility levels for.

    .PARAMETER Version
        Specifies the SQL Server version to get supported compatibility levels for.
        Only the major version number is used for determining compatibility levels.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        Get-SqlDscCompatibilityLevel -ServerObject $serverObject

        Returns all supported compatibility levels for the connected SQL Server instance.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | Get-SqlDscCompatibilityLevel

        Returns all supported compatibility levels using pipeline input.

    .EXAMPLE
        Get-SqlDscCompatibilityLevel -Version '16.0.1000.6'

        Returns all supported compatibility levels for SQL Server 2022 (version 16).

    .INPUTS
        Microsoft.SqlServer.Management.Smo.Server

        The server object to get supported compatibility levels for.

    .OUTPUTS
        System.String[]

        Returns an array of supported compatibility level names (e.g., 'Version160', 'Version150').
#>
function Get-SqlDscCompatibilityLevel
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [CmdletBinding(DefaultParameterSetName = 'ServerObject')]
    [OutputType([System.String[]])]
    param
    (
        [Parameter(ParameterSetName = 'ServerObject', Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter(ParameterSetName = 'Version', Mandatory = $true)]
        [System.Version]
        $Version
    )

    process
    {
        # Get the major version based on parameter set
        $majorVersion = if ($PSCmdlet.ParameterSetName -eq 'ServerObject')
        {
            Write-Verbose -Message ($script:localizedData.GetCompatibilityLevel_GettingForInstance -f $ServerObject.InstanceName, $ServerObject.VersionMajor)
            $ServerObject.VersionMajor
        }
        else
        {
            Write-Verbose -Message ($script:localizedData.GetCompatibilityLevel_GettingForVersion -f $Version, $Version.Major)
            $Version.Major
        }

        # Get all available compatibility levels from the enum
        $allCompatibilityLevels = [System.Enum]::GetNames([Microsoft.SqlServer.Management.Smo.CompatibilityLevel])

        <#
            Determine minimum supported compatibility level based on SQL Server version
            Reference: https://learn.microsoft.com/en-us/sql/t-sql/statements/alter-database-transact-sql-compatibility-level
        #>
        $minimumCompatLevel = switch ($majorVersion)
        {
            { $_ -ge 12 }
            {
                100 # SQL 2014 (v12) and later support minimum compat level 100
            }

            11
            {
                90 # SQL 2012 (v11) supports minimum compat level 90
            }

            { $_ -le 10 }
            {
                80 # SQL 2008 R2 (v10.5) and earlier support minimum compat level 80
            }
        }

        <#
            Filter compatibility levels that are supported by this SQL Server version
            CompatibilityLevel enum values are named like "Version80", "Version90", etc.
            SQL Server supports compatibility levels from the minimum up to (version * 10)
        #>
        $supportedCompatibilityLevels = $allCompatibilityLevels | Where-Object -FilterScript {
            if ($_ -match 'Version(\d+)')
            {
                $compatLevelVersion = [System.Int32] $Matches[1]
                ($compatLevelVersion -ge $minimumCompatLevel) -and ($compatLevelVersion -le ($majorVersion * 10))
            }
            else
            {
                $false
            }
        }

        <#
            Warn if SQL Server version is newer than what SMO library supports
            Check if the expected maximum compatibility level is missing from the supported list
        #>
        $expectedMaxCompatLevel = "Version$($majorVersion * 10)"
        if ($expectedMaxCompatLevel -notin $supportedCompatibilityLevels -and $supportedCompatibilityLevels.Count -gt 0)
        {
            # Get the actual maximum from the last element (they're in ascending order)
            $lastCompatLevel = $supportedCompatibilityLevels[-1]
            if ($lastCompatLevel -match 'Version(\d+)')
            {
                $maxCompatLevelInEnum = [System.Int32] $Matches[1]
                Write-Warning -Message ($script:localizedData.GetCompatibilityLevel_SmoTooOld -f $majorVersion, $maxCompatLevelInEnum, ($majorVersion * 10))
            }
        }

        Write-Debug -Message ($script:localizedData.GetCompatibilityLevel_Found -f $supportedCompatibilityLevels.Count, $majorVersion)

        return $supportedCompatibilityLevels
    }
}
