<#
    .SYNOPSIS
        A class to handle startup parameters of a manged computer service object.

    .EXAMPLE
        $startupParameters = [StartupParameters]::Parse(((Get-SqlDscManagedComputer).Services | ? type -eq 'SqlServer').StartupParameters)
        $startupParameters | fl
        $startupParameters.ToString()

        Parses the startup parameters of the database engine default instance on the
        current node, and then outputs the resulting object. Also shows how the object
        can be turned back to a startup parameters string by calling ToString().

    .NOTES
        This class supports an array of data file paths, log file paths, and error
        log paths though currently it seems that there can only be one of each.
        This class was made with arrays in case there is an unknown edge case where
        it is possible to have more than one of those paths.
#>
class StartupParameters
{
    [System.String[]]
    $DataFilePath

    [System.String[]]
    $LogFilePath

    [System.String[]]
    $ErrorLogPath

    [System.UInt32[]]
    $TraceFlag

    [System.UInt32[]]
    $InternalTraceFlag

    StartupParameters ()
    {
    }

    static [StartupParameters] Parse([System.String] $InstanceStartupParameters)
    {
        Write-Debug -Message (
            $script:localizedData.StartupParameters_DebugParsingStartupParameters -f 'StartupParameters.Parse()', $InstanceStartupParameters
        )

        $startupParameters = [StartupParameters]::new()

        $startupParameterValues = $InstanceStartupParameters -split ';'

        $startupParameters.TraceFlag = [System.UInt32[]] @(
            $startupParameterValues |
                Where-Object -FilterScript {
                    $_ -cmatch '^-T\d+'
                } |
                ForEach-Object -Process {
                    [System.UInt32] $_.TrimStart('-T')
                }
        )

        Write-Debug -Message (
            $script:localizedData.StartupParameters_DebugFoundTraceFlags -f 'StartupParameters.Parse()', ($startupParameters.TraceFlag -join ', ')
        )

        $startupParameters.DataFilePath = [System.String[]] @(
            $startupParameterValues |
                Where-Object -FilterScript {
                    $_ -cmatch '^-d'
                } |
                ForEach-Object -Process {
                    $_.TrimStart('-d')
                }
        )

        $startupParameters.LogFilePath = [System.String[]] @(
            $startupParameterValues |
                Where-Object -FilterScript {
                    $_ -cmatch '^-l'
                } |
                ForEach-Object -Process {
                    $_.TrimStart('-l')
                }
        )

        $startupParameters.ErrorLogPath = [System.String[]] @(
            $startupParameterValues |
                Where-Object -FilterScript {
                    $_ -cmatch '^-e'
                } |
                ForEach-Object -Process {
                    $_.TrimStart('-e')
                }
        )

        $startupParameters.InternalTraceFlag = [System.UInt32[]] @(
            $startupParameterValues |
                Where-Object -FilterScript {
                    $_ -cmatch '^-t\d+'
                } |
                ForEach-Object -Process {
                    [System.UInt32] $_.TrimStart('-t')
                }
        )

        return $startupParameters
    }

    [System.String] ToString()
    {
        $startupParametersValues = [System.String[]] @()

        if ($this.DataFilePath)
        {
            $startupParametersValues += $this.DataFilePath |
                ForEach-Object -Process {
                    '-d{0}' -f $_
                }
        }

        if ($this.ErrorLogPath)
        {
            $startupParametersValues += $this.ErrorLogPath |
                ForEach-Object -Process {
                    '-e{0}' -f $_
                }
        }

        if ($this.LogFilePath)
        {
            $startupParametersValues += $this.LogFilePath |
                ForEach-Object -Process {
                    '-l{0}' -f $_
                }
        }

        if ($this.TraceFlag)
        {
            $startupParametersValues += $this.TraceFlag |
                ForEach-Object -Process {
                    '-T{0}' -f $_
                }
        }

        if ($this.InternalTraceFlag)
        {
            $startupParametersValues += $this.InternalTraceFlag |
                ForEach-Object -Process {
                    '-t{0}' -f $_
                }
        }

        return $startupParametersValues -join ';'
    }
}
