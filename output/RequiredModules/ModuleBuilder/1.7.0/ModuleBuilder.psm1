#Region '.\Private\ConvertToAst.ps1' 0
function ConvertToAst {
    <#
        .SYNOPSIS
            Parses the given code and returns an object with the AST, Tokens and ParseErrors
    #>
    param(
        # The script content, or script or module file path to parse
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias("Path", "PSPath", "Definition", "ScriptBlock", "Module")]
        $Code
    )
    process {
        Write-Debug "    ENTER: ConvertToAst $Code"
        $ParseErrors = $null
        $Tokens = $null
        if ($Code | Test-Path -ErrorAction SilentlyContinue) {
            Write-Debug "      Parse Code as Path"
            $AST = [System.Management.Automation.Language.Parser]::ParseFile(($Code | Convert-Path), [ref]$Tokens, [ref]$ParseErrors)
        } elseif ($Code -is [System.Management.Automation.FunctionInfo]) {
            Write-Debug "      Parse Code as Function"
            $String = "function $($Code.Name) { $($Code.Definition) }"
            $AST = [System.Management.Automation.Language.Parser]::ParseInput($String, [ref]$Tokens, [ref]$ParseErrors)
        } else {
            Write-Debug "      Parse Code as String"
            $AST = [System.Management.Automation.Language.Parser]::ParseInput([String]$Code, [ref]$Tokens, [ref]$ParseErrors)
        }

        Write-Debug "    EXIT: ConvertToAst"
        [PSCustomObject]@{
            PSTypeName  = "PoshCode.ModuleBuilder.ParseResults"
            ParseErrors = $ParseErrors
            Tokens      = $Tokens
            AST         = $AST
        }
    }
}
#EndRegion '.\Private\ConvertToAst.ps1' 36
#Region '.\Private\CopyReadMe.ps1' 0
function CopyReadMe {
    [CmdletBinding()]
    param(
        # The path to the ReadMe document to copy
        [Parameter(ValueFromPipelineByPropertyName)]
        [AllowNull()][AllowEmptyString()]
        [string]$ReadMe,

        # The name of the module -- because the file is renamed to about_$ModuleName.help.txt
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
        [Alias("Name")]
        [string]$ModuleName,

        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
        [string]$OutputDirectory,

        # The culture (language) to store the ReadMe as (defaults to "en")
        [Parameter(ValueFromPipelineByPropertyName)]
        [Globalization.CultureInfo]$Culture = $(Get-UICulture),

        # If set, overwrite the existing readme
        [Switch]$Force
    )

    # Copy the readme file as an about_ help file
    Write-Verbose "Test for ReadMe: $Pwd\$($ReadMe)"
    if($ReadMe -and (Test-Path $ReadMe -PathType Leaf)) {
        # Make sure there's a language path
        $LanguagePath = Join-Path $OutputDirectory $Culture
        if(!(Test-Path $LanguagePath -PathType Container)) {
            $null = New-Item $LanguagePath -Type Directory -Force
        }
        Write-Verbose "Copy ReadMe to: $LanguagePath"

        $about_module = Join-Path $LanguagePath "about_$($ModuleName).help.txt"
        if(!(Test-Path $about_module)) {
            Write-Verbose "Turn readme into about_module"
            Copy-Item -LiteralPath $ReadMe -Destination $about_module
        }
    }
}
#EndRegion '.\Private\CopyReadMe.ps1' 41
#Region '.\Private\GetBuildInfo.ps1' 0
function GetBuildInfo {
    [CmdletBinding()]
    param(
        # The path to the Build Manifest Build.psd1
        [Parameter()][AllowNull()]
        [string]$BuildManifest,

        # Pass MyInvocation from the Build-Command so we can read parameter values
        [Parameter(DontShow)]
        [AllowNull()]
        $BuildCommandInvocation
    )

    $BuildInfo = if ($BuildManifest -and (Test-Path $BuildManifest) -and (Split-path -Leaf $BuildManifest) -eq 'build.psd1') {
        # Read the build.psd1 configuration file for default parameter values
        Write-Debug "Load Build Manifest $BuildManifest"
        Import-Metadata -Path $BuildManifest
    } else {
        @{}
    }

    $CommonParameters = [System.Management.Automation.Cmdlet]::CommonParameters +
                        [System.Management.Automation.Cmdlet]::OptionalCommonParameters
    $BuildParameters = $BuildCommandInvocation.MyCommand.Parameters
    # Make we can always look things up in BoundParameters
    $BoundParameters = if ($BuildCommandInvocation.BoundParameters) {
        $BuildCommandInvocation.BoundParameters
    } else {
        @{}
    }

    # Combine the defaults with parameter values
    $ParameterValues = @{}
    if ($BuildCommandInvocation) {
        foreach ($parameter in $BuildParameters.GetEnumerator().Where({$_.Key -notin $CommonParameters})) {
            Write-Debug "  Parameter: $($parameter.key)"
            $key = $parameter.Key

            # We want to map the parameter aliases to the parameter name:
            foreach ($k in @($parameter.Value.Aliases)) {
                if ($null -ne $k -and $BuildInfo.ContainsKey($k)) {
                    Write-Debug "    ... Update BuildInfo[$key] from $k"
                    $BuildInfo[$key] = $BuildInfo[$k]
                    $null = $BuildInfo.Remove($k)
                }
            }
            # Bound parameter values > build.psd1 values > default parameters values
            if (-not $BuildInfo.ContainsKey($key) -or $BoundParameters.ContainsKey($key)) {
                # Reading the current value of the $key variable returns either the bound parameter or the default
                if ($null -ne ($value = Get-Variable -Name $key -ValueOnly -ErrorAction Ignore )) {
                    if ($value -ne ($null -as $parameter.Value.ParameterType)) {
                        $ParameterValues[$key] = $value
                    }
                }
                if ($BoundParameters.ContainsKey($key)) {
                    Write-Debug "    From Parameter: $($ParameterValues[$key] -join ', ')"
                } elseif ($ParameterValues[$key]) {
                    Write-Debug "    From Default: $($ParameterValues[$key] -join ', ')"
                }
            } elseif ($BuildInfo[$key]) {
                Write-Debug "    From Manifest: $($BuildInfo[$key] -join ', ')"
            }
        }
    }
    # BuildInfo.SourcePath should point to a module manifest
    if ($BuildInfo.SourcePath -and $BuildInfo.SourcePath -ne $BuildManifest) {
        $ParameterValues["SourcePath"] = $BuildInfo.SourcePath
    }
    # If SourcePath point to build.psd1, we should clear it
    if ($ParameterValues["SourcePath"] -eq $BuildManifest) {
        $ParameterValues.Remove("SourcePath")
    }
    Write-Debug "Finished parsing Build Manifest $BuildManifest"

    $BuildManifestParent = if ($BuildManifest) {
        Split-Path -Parent $BuildManifest
    } else {
        Get-Location -PSProvider FileSystem
    }

    Write-Verbose ('BuildInfo.SourcePath: {0}' -f ($BuildInfo.SourcePath| out-string)) -Verbose
    Write-Verbose ('ParameterValues["SourcePath"]: {0}' -f ($ParameterValues["SourcePath"] | out-string)) -Verbose

    if ((-not $BuildInfo.SourcePath) -and $ParameterValues["SourcePath"] -notmatch '\.psd1') {
        # Find a module manifest (or maybe several)
        Write-Verbose ('BuildManifestParent: {0}' -f ($BuildManifestParent| out-string)) -Verbose

        $ModuleInfo = Get-ChildItem $BuildManifestParent -Recurse -Filter *.psd1 -ErrorAction SilentlyContinue |
            ImportModuleManifest -ErrorAction SilentlyContinue

        Write-Verbose ('@(ModuleInfo).Count: {0}' -f (@($ModuleInfo).Count | out-string)) -Verbose
        Write-Verbose ('@(ModuleInfo).Name: {0}' -f (@($ModuleInfo).Name | out-string)) -Verbose

        # If we found more than one module info, the only way we have of picking just one is if it matches a folder name
        if (@($ModuleInfo).Count -gt 1) {
            # Resolve Build Manifest's parent folder to find the Absolute path
            $ModuleName = Split-Path -Leaf $BuildManifestParent
            # If we're in a "well known" source folder, look higher for a name
            if ($ModuleName -in 'Source', 'src') {
                $ModuleName = Split-Path (Split-Path -Parent $BuildManifestParent) -Leaf
            }
            $ModuleInfo = @($ModuleInfo).Where{ $_.Name -eq $ModuleName }
        }

        Write-Verbose ('@(ModuleInfo).Count: {0}' -f (@($ModuleInfo).Count | out-string)) -Verbose
        Write-Verbose ('@(ModuleInfo).Name: {0}' -f (@($ModuleInfo).Name | out-string)) -Verbose
        Write-Verbose ('@(ModuleInfo).Path: {0}' -f (@($ModuleInfo).Path | out-string)) -Verbose

        if (@($ModuleInfo).Count -eq 1) {
            Write-Debug "Updating BuildInfo SourcePath to $($ModuleInfo.Path)"
            $ParameterValues["SourcePath"] = $ModuleInfo.Path
        }

        Write-Verbose ('ParameterValues["SourcePath"]: {0}' -f ($ParameterValues["SourcePath"] | out-string)) -Verbose

        if (-Not $ModuleInfo) {
            throw "Can't find a module manifest in $BuildManifestParent"
        }
    }

    $BuildInfo = $BuildInfo | Update-Object $ParameterValues
    Write-Debug "Using Module Manifest $($BuildInfo.SourcePath)"

    # Make sure the SourcePath is absolute and points at an actual file
    if (!(Split-Path -IsAbsolute $BuildInfo.SourcePath) -and $BuildManifestParent) {
        $BuildInfo.SourcePath = Join-Path $BuildManifestParent $BuildInfo.SourcePath | Convert-Path
    } else {
        $BuildInfo.SourcePath = Convert-Path $BuildInfo.SourcePath
    }
    if (!(Test-Path $BuildInfo.SourcePath)) {
        throw "Can't find module manifest at the specified SourcePath: $($BuildInfo.SourcePath)"
    }

    $BuildInfo
}
#EndRegion '.\Private\GetBuildInfo.ps1' 118
#Region '.\Private\GetCommandAlias.ps1' 0
function GetCommandAlias {
    [CmdletBinding()]
    param(
        # Path to the PSM1 file to amend
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [System.Management.Automation.Language.Ast]$AST
    )
    begin {
        $Result = [Ordered]@{}
    }
    process {
        foreach($function in $AST.FindAll(
                { $Args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] },
                $false )
        ) {
            $Result[$function.Name] = $function.Body.ParamBlock.Attributes.Where{
                $_.TypeName.Name -eq "Alias" }.PositionalArguments.Value
        }
    }
    end {
        $Result
    }
}
#EndRegion '.\Private\GetCommandAlias.ps1' 23
#Region '.\Private\ImportModuleManifest.ps1' 0
function ImportModuleManifest {
    [CmdletBinding()]
    param(
        [Alias("PSPath")]
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]$Path
    )
    process {
        # Get all the information in the module manifest
        $ModuleInfo = Get-Module $Path -ListAvailable -WarningAction SilentlyContinue -ErrorAction SilentlyContinue -ErrorVariable Problems

        # Some versions fails silently. If the GUID is empty, we didn't get anything at all
        if ($ModuleInfo.Guid -eq [Guid]::Empty) {
            Write-Error "Cannot parse '$Path' as a module manifest, try Test-ModuleManifest for details"
            return
        }

        # Some versions show errors are when the psm1 doesn't exist (yet), but we don't care
        $ErrorsWeIgnore = "^" + (@(
            "Modules_InvalidRequiredModulesinModuleManifest"
            "Modules_InvalidRootModuleInModuleManifest"
        ) -join "|^")

        # If there are any OTHER problems we'll fail
        if ($Problems = $Problems.Where({ $_.FullyQualifiedErrorId -notmatch $ErrorsWeIgnore })) {
            foreach ($problem in $Problems) {
                Write-Error $problem
            }
            # Short circuit - don't output the ModuleInfo if there were errors
            return
        }

        # Workaround the fact that Get-Module returns the DefaultCommandPrefix as Prefix
        Update-Object -InputObject $ModuleInfo -UpdateObject @{ DefaultCommandPrefix = $ModuleInfo.Prefix; Prefix = "" }
    }
}
#EndRegion '.\Private\ImportModuleManifest.ps1' 36
#Region '.\Private\InitializeBuild.ps1' 0
function InitializeBuild {
    <#
        .SYNOPSIS
            Loads build.psd1 and the module manifest and combines them with the parameter values of the calling function.
        .DESCRIPTION
            This function is for internal use from Build-Module only
            It does a few things that make it really only work properly there:

            1. It calls ResolveBuildManifest to resolve the Build.psd1 from the given -SourcePath (can be Folder, Build.psd1 or Module manifest path)
            2. Then calls GetBuildInfo to read the Build configuration file and override parameters passed through $Invocation (read from the PARENT MyInvocation)
            2. It gets the Module information from the ModuleManifest, and merges it with the $ModuleInfo
        .NOTES
            Depends on the Configuration module Update-Object and (the built in Import-LocalizedData and Get-Module)
    #>
    [CmdletBinding()]
    param(
        # The root folder where the module source is (including the Build.psd1 and the module Manifest.psd1)
        [string]$SourcePath,

        [Parameter(DontShow)]
        [AllowNull()]
        $BuildCommandInvocation = $(Get-Variable MyInvocation -Scope 1 -ValueOnly)
    )
    Write-Debug "Initializing build variables"

    # GetBuildInfo reads the parameter values from the Build-Module command and combines them with the Manifest values
    $BuildManifest = ResolveBuildManifest $SourcePath

    Write-Debug "BuildCommand: $(
        @(
            @($BuildCommandInvocation.MyCommand.Name)
            @($BuildCommandInvocation.BoundParameters.GetEnumerator().ForEach{ "-{0} '{1}'" -f $_.Key, $_.Value })
        ) -join ' ')"
    $BuildInfo = GetBuildInfo -BuildManifest $BuildManifest -BuildCommandInvocation $BuildCommandInvocation

    # Finally, add all the information in the module manifest to the return object
    if ($ModuleInfo = ImportModuleManifest $BuildInfo.SourcePath) {
        # Update the module manifest with our build configuration and output it
        Update-Object -InputObject $ModuleInfo -UpdateObject $BuildInfo
    } else {
        throw "Unresolvable problems in module manifest: '$($BuildInfo.SourcePath)'"
    }
}
#EndRegion '.\Private\InitializeBuild.ps1' 43
#Region '.\Private\MoveUsingStatements.ps1' 0
function MoveUsingStatements {
    <#
        .SYNOPSIS
            A command to comment out and copy to the top of the file the Using Statements
        .DESCRIPTION
            When all files are merged together, the Using statements from individual files
            don't  necessarily end up at the beginning of the PSM1, creating Parsing Errors.

            This function uses AST to comment out those statements (to preserver line numbering)
            and insert them (conserving order) at the top of the script.

            Should the merged RootModule already have errors not related to the Using statements,
            or no errors caused by misplaced Using statements, this steps is skipped.

            If moving (comment & copy) the Using statements introduce parsing errors to the script,
            those changes won't be applied to the file.
    #>
    [CmdletBinding()]
    Param(
        # Path to the PSM1 file to amend
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [System.Management.Automation.Language.Ast]$AST,

        [Parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [AllowNull()]
        [System.Management.Automation.Language.ParseError[]]$ParseErrors,

        # The encoding defaults to UTF8 (or UTF8NoBom on Core)
        [Parameter(DontShow)]
        [string]$Encoding = $(if ($IsCoreCLR) { "UTF8NoBom" } else { "UTF8" })
    )

    # Avoid modifying the file if there's no Parsing Error caused by Using Statements or other errors
    if (!$ParseErrors.Where{$_.ErrorId -eq 'UsingMustBeAtStartOfScript'}) {
        Write-Debug "No using statement errors found."
        return
    }
    # Avoid modifying the file if there's other parsing errors than Using Statements misplaced
    if ($ParseErrors.Where{$_.ErrorId -ne 'UsingMustBeAtStartOfScript'}) {
        Write-Warning "Parsing errors found. Skipping moving using statements."
        return
    }

    # Find all Using statements including those non erroring (to conserve their order)
    $UsingStatementExtents = $AST.FindAll(
        {$Args[0] -is [System.Management.Automation.Language.UsingStatementAst]},
        $false
    ).Extent

    # Edit the Script content by commenting out existing statements (conserving line numbering)
    $ScriptText = $AST.Extent.Text
    $InsertedCharOffset = 0
    $StatementsToCopy = New-Object System.Collections.ArrayList
    foreach ($UsingSatement in $UsingStatementExtents) {
        $ScriptText = $ScriptText.Insert($UsingSatement.StartOffset + $InsertedCharOffset, '#')
        $InsertedCharOffset++

        # Keep track of unique statements we'll need to insert at the top
        if (!$StatementsToCopy.Contains($UsingSatement.Text)) {
            $null = $StatementsToCopy.Add($UsingSatement.Text)
        }
    }

    $ScriptText = $ScriptText.Insert(0, ($StatementsToCopy -join "`r`n") + "`r`n")

    # Verify we haven't introduced new Parsing errors
    $null = [System.Management.Automation.Language.Parser]::ParseInput(
        $ScriptText,
        [ref]$null,
        [ref]$ParseErrors
    )

    if ($ParseErrors) {
        Write-Warning "We introduced parsing error(s) while attempting to move using statements. Cancelling changes."
    } else {
        $null = Set-Content -Value $ScriptText -Path $RootModule -Encoding $Encoding
    }
}
#EndRegion '.\Private\MoveUsingStatements.ps1' 78
#Region '.\Private\ParameterValues.ps1' 0
Update-TypeData -TypeName System.Management.Automation.InvocationInfo -MemberName ParameterValues -MemberType ScriptProperty -Value {
    $results = @{}
    foreach ($key in $this.MyCommand.Parameters.Keys) {
        if ($this.BoundParameters.ContainsKey($key)) {
            $results.$key = $this.BoundParameters.$key
        } elseif ($value = Get-Variable -Name $key -Scope 1 -ValueOnly -ErrorAction Ignore) {
            $results.$key = $value
        }
    }
    return $results
} -Force
#EndRegion '.\Private\ParameterValues.ps1' 11
#Region '.\Private\ParseLineNumber.ps1' 0
function ParseLineNumber {
    <#
        .SYNOPSIS
            Parses the SourceFile and SourceLineNumber from a position message
        .DESCRIPTION
            Parses messages like:
                at <ScriptBlock>, <No file>: line 1
                at C:\Test\Path\ErrorMaker.ps1:31 char:1
                at C:\Test\Path\Modules\ErrorMaker\ErrorMaker.psm1:27 char:4
    #>
    [Cmdletbinding()]
    param(
        # A position message, starting with "at ..." and containing a line number
        [Parameter(ValueFromPipeline)]
        [string]$PositionMessage
    )
    process {
        foreach($line in $PositionMessage -split "\r?\n") {
            # At (optional invocation,) <source file>:(maybe " line ") number
            if ($line -match "at(?: (?<InvocationBlock>[^,]+),)?\s+(?<SourceFile>.+):(?<!char:)(?: line )?(?<SourceLineNumber>\d+)(?: char:(?<OffsetInLine>\d+))?") {
                [PSCustomObject]@{
                    PSTypeName       = "Position"
                    SourceFile       = $matches.SourceFile
                    SourceLineNumber = $matches.SourceLineNumber
                    OffsetInLine     = $matches.OffsetInLine
                    PositionMessage  = $line
                    PSScriptRoot     = Split-Path $matches.SourceFile
                    PSCommandPath    = $matches.SourceFile
                    InvocationBlock  = $matches.InvocationBlock
                }
            } elseif($line -notmatch "\s*\+") {
                Write-Warning "Can't match: '$line'"
            }
        }
    }
}
#EndRegion '.\Private\ParseLineNumber.ps1' 36
#Region '.\Private\ResolveBuildManifest.ps1' 0
function ResolveBuildManifest {
    [CmdletBinding()]
    param(
        # The Source folder path, the Build Manifest Path, or the Module Manifest path used to resolve the Build.psd1
        [Alias("BuildManifest")]
        [string]$SourcePath = $(Get-Location -PSProvider FileSystem)
    )
    Write-Debug "ResolveBuildManifest $SourcePath"
    if ((Split-Path $SourcePath -Leaf) -eq 'build.psd1') {
        $BuildManifest = $SourcePath
    } elseif (Test-Path $SourcePath -PathType Leaf) {
        # When you pass the SourcePath as parameter, you must have the Build Manifest in the same folder
        $BuildManifest = Join-Path (Split-Path -Parent $SourcePath) [Bb]uild.psd1
    } else {
        # It's a container, assume the Build Manifest is directly under
        $BuildManifest = Join-Path $SourcePath [Bb]uild.psd1
    }

    # Make sure we are resolving the absolute path to the manifest, and test it exists
    $ResolvedBuildManifest = (Resolve-Path $BuildManifest -ErrorAction SilentlyContinue).Path

    if ($ResolvedBuildManifest) {
        $ResolvedBuildManifest
    }

}
#EndRegion '.\Private\ResolveBuildManifest.ps1' 26
#Region '.\Private\ResolveOutputFolder.ps1' 0
function ResolveOutputFolder {
    [CmdletBinding()]
    param(
        # Where to build the module.
        # Defaults to an \output folder, adjacent to the "SourcePath" folder
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]$OutputDirectory,

        # If set (true) adds a folder named after the version number to the OutputDirectory
        [Parameter(ValueFromPipelineByPropertyName)]
        [switch]$VersionedOutputDirectory,

        # specifies the module version for use in the output path if -VersionedOutputDirectory is true
        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias("ModuleVersion")]
        [string]$Version,

        # Where to resolve the $OutputDirectory from when relative
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]$ModuleBase
    )
    process {
        Write-Verbose "Resolve OutputDirectory path: $OutputDirectory"

        # Ensure the OutputDirectory makes sense (it's never blank anymore)
        if (!(Split-Path -IsAbsolute $OutputDirectory)) {
            # Relative paths are relative to the ModuleBase
            $OutputDirectory = Join-Path $ModuleBase $OutputDirectory
        }

        # Make sure the OutputDirectory exists (relative to ModuleBase or absolute)
        $OutputDirectory = New-Item $OutputDirectory -ItemType Directory -Force | Convert-Path
        if ($VersionedOutputDirectory -and $OutputDirectory.TrimEnd("/\") -notmatch "\d+\.\d+\.\d+$") {
            $OutputDirectory = New-Item (Join-Path $OutputDirectory $Version) -ItemType Directory -Force | Convert-Path
            Write-Verbose "Added ModuleVersion to OutputDirectory path: $OutputDirectory"
        }
        $OutputDirectory
    }
}
#EndRegion '.\Private\ResolveOutputFolder.ps1' 39
#Region '.\Private\SetModuleContent.ps1' 0
function SetModuleContent {
    <#
        .SYNOPSIS
            A wrapper for Set-Content that handles arrays of file paths
        .DESCRIPTION
            The implementation here is strongly dependent on Build-Module doing the right thing
            Build-Module can optionally pass a PREFIX or SUFFIX, but otherwise only passes files

            Because of that, SetModuleContent doesn't test for that

            The goal here is to pretend this is a pipeline, for the sake of memory and file IO
    #>
    [CmdletBinding()]
    param(
        # Where to write the joined output
        [Parameter(Position=0, Mandatory)]
        [string]$OutputPath,

        # Input files, the scripts that will be copied to the output path
        # The FIRST and LAST items can be text content instead of file paths.
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias("PSPath", "FullName")]
        [AllowEmptyCollection()]
        [string[]]$SourceFile,

        # The working directory (allows relative paths for other values)
        [string]$WorkingDirectory = $pwd,

        # The encoding defaults to UTF8 (or UTF8NoBom on Core)
        [Parameter(DontShow)]
        [string]$Encoding = $(if($IsCoreCLR) { "UTF8Bom" } else { "UTF8" })
    )
    begin {
        Write-Debug "SetModuleContent WorkingDirectory $WorkingDirectory"
        Push-Location $WorkingDirectory -StackName SetModuleContent
        $ContentStarted = $false # There has been no content yet

        # Create a proxy command style scriptblock for Set-Content to keep the file handle open
        $SetContentCmd = $ExecutionContext.InvokeCommand.GetCommand('Microsoft.PowerShell.Management\Set-Content', [System.Management.Automation.CommandTypes]::Cmdlet)
        $SetContent = {& $SetContentCmd -Path $OutputPath -Encoding $Encoding }.GetSteppablePipeline($myInvocation.CommandOrigin)
        $SetContent.Begin($true)
    }
    process  {
        foreach($file in $SourceFile) {
            if($SourceName = Resolve-Path $file -Relative -ErrorAction SilentlyContinue) {
                Write-Verbose "Adding $SourceName"
                $SetContent.Process("#Region '$SourceName' 0")
                Get-Content $SourceName -OutVariable source | ForEach-Object { $SetContent.Process($_) }
                $SetContent.Process("#EndRegion '$SourceName' $($Source.Count)")
            } else {
                if(!$ContentStarted) {
                    $SetContent.Process("#Region 'PREFIX' 0")
                    $SetContent.Process($file)
                    $SetContent.Process("#EndRegion 'PREFIX'")
                    $ContentStarted = $true
                } else {
                    $SetContent.Process("#Region 'SUFFIX' 0")
                    $SetContent.Process($file)
                    $SetContent.Process("#EndRegion 'SUFFIX'")
                }
            }
        }
    }
    end {
        $SetContent.End()
        Pop-Location -StackName SetModuleContent
    }
}
#EndRegion '.\Private\SetModuleContent.ps1' 68
#Region '.\Public\Build-Module.ps1' 0
function Build-Module {
    <#
        .Synopsis
            Compile a module from ps1 files to a single psm1

        .Description
            Compiles modules from source according to conventions:
            1. A single ModuleName.psd1 manifest file with metadata
            2. Source subfolders in the same directory as the Module manifest:
               Enum, Classes, Private, Public contain ps1 files
            3. Optionally, a build.psd1 file containing settings for this function

            The optimization process:
            1. The OutputDirectory is created
            2. All psd1/psm1/ps1xml files (except build.psd1) in the Source will be copied to the output
            3. If specified, $CopyPaths (relative to the Source) will be copied to the output
            4. The ModuleName.psm1 will be generated (overwritten completely) by concatenating all .ps1 files in the $SourceDirectories subdirectories
            5. The ModuleVersion and ExportedFunctions in the ModuleName.psd1 may be updated (depending on parameters)

        .Example
            Build-Module -Suffix "Export-ModuleMember -Function *-* -Variable PreferenceVariable"

            This example shows how to build a simple module from it's manifest, adding an Export-ModuleMember as a Suffix

        .Example
            Build-Module -Prefix "using namespace System.Management.Automation"

            This example shows how to build a simple module from it's manifest, adding a using statement at the top as a prefix

        .Example
            $gitVersion = gitversion | ConvertFrom-Json | Select -Expand InformationalVersion
            Build-Module -SemVer $gitVersion

            This example shows how to use a semantic version from gitversion to version your build.
            Note, this is how we version ModuleBuilder, so if you want to see it in action, check out our azure-pipelines.yml
            https://github.com/PoshCode/ModuleBuilder/blob/master/azure-pipelines.yml
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "", Justification="Build is approved now")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCmdletCorrectly", "")]
    [CmdletBinding(DefaultParameterSetName="SemanticVersion")]
    [Alias("build")]
    param(
        # The path to the module folder, manifest or build.psd1
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [ValidateScript({
            if (Test-Path $_) {
                $true
            } else {
                throw "Source must point to a valid module"
            }
        })]
        [Alias("ModuleManifest", "Path")]
        [string]$SourcePath = $(Get-Location -PSProvider FileSystem),

        # Where to build the module.
        # Defaults to an ..\output folder (adjacent to the "SourcePath" folder)
        [Alias("Destination")]
        [string]$OutputDirectory = "..\Output",

        # If set (true) adds a folder named after the version number to the OutputDirectory
        [switch]$VersionedOutputDirectory,

        # Semantic version, like 1.0.3-beta01+sha.22c35ffff166f34addc49a3b80e622b543199cc5
        # If the SemVer has metadata (after a +), then the full Semver will be added to the ReleaseNotes
        [Parameter(ParameterSetName="SemanticVersion")]
        [string]$SemVer,

        # The module version (must be a valid System.Version such as PowerShell supports for modules)
        [Alias("ModuleVersion")]
        [Parameter(ParameterSetName="ModuleVersion", Mandatory)]
        [version]$Version = $(if(($V = $SemVer.Split("+")[0].Split("-",2)[0])){$V}),

        # Setting pre-release forces the release to be a pre-release.
        # Must be valid pre-release tag like PowerShellGet supports
        [Parameter(ParameterSetName="ModuleVersion")]
        [string]$Prerelease = $($SemVer.Split("+")[0].Split("-",2)[1]),

        # Build metadata (like the commit sha or the date).
        # If a value is provided here, then the full Semantic version will be inserted to the release notes:
        # Like: ModuleName v(Version(-Prerelease?)+BuildMetadata)
        [Parameter(ParameterSetName="ModuleVersion")]
        [string]$BuildMetadata = $($SemVer.Split("+",2)[1]),

        # Folders which should be copied intact to the module output
        # Can be relative to the  module folder
        [AllowEmptyCollection()]
        [Alias("CopyDirectories")]
        [string[]]$CopyPaths = @(),

        # Folders which contain source .ps1 scripts to be concatenated into the module
        # Defaults to Enum, Classes, Private, Public
        [string[]]$SourceDirectories = @(
            "Enum", "Classes", "Private", "Public"
        ),

        # A Filter (relative to the module folder) for public functions
        # If non-empty, FunctionsToExport will be set with the file BaseNames of matching files
        # Defaults to Public\*.ps1
        [AllowEmptyString()]
        [string[]]$PublicFilter = "Public\*.ps1",

        # A switch that allows you to disable the update of the AliasesToExport
        # By default, (if PublicFilter is not empty, and this is not set)
        # Build-Module updates the module manifest FunctionsToExport and AliasesToExport
        # with the combination of all the values in [Alias()] attributes on public functions in the module
        [switch]$IgnoreAliasAttribute,

        # File encoding for output RootModule (defaults to UTF8)
        # Converted to System.Text.Encoding for PowerShell 6 (and something else for PowerShell 5)
        [ValidateSet("UTF8", "UTF8Bom", "UTF8NoBom", "UTF7", "ASCII", "Unicode", "UTF32")]
        [string]$Encoding = $(if($IsCoreCLR) { "UTF8Bom" } else { "UTF8" }),

        # The prefix is either the path to a file (relative to the module folder) or text to put at the top of the file.
        # If the value of prefix resolves to a file, that file will be read in, otherwise, the value will be used.
        # The default is nothing. See examples for more details.
        [string]$Prefix,

        # The Suffix is either the path to a file (relative to the module folder) or text to put at the bottom of the file.
        # If the value of Suffix resolves to a file, that file will be read in, otherwise, the value will be used.
        # The default is nothing. See examples for more details.
        [Alias("ExportModuleMember","Postfix")]
        [string]$Suffix,

        # Controls whether or not there is a build or cleanup performed
        [ValidateSet("Clean", "Build", "CleanBuild")]
        [string]$Target = "CleanBuild",

        # Output the ModuleInfo of the "built" module
        [switch]$Passthru
    )

    begin {
        if ($Encoding -notmatch "UTF8") {
            Write-Warning "For maximum portability, we strongly recommend you build your script modules with UTF8 encoding (with a BOM, for backwards compatibility to PowerShell 5)."
        }
    }
    process {
        try {
            # BEFORE we InitializeBuild we need to "fix" the version
            if($PSCmdlet.ParameterSetName -ne "SemanticVersion") {
                Write-Verbose "Calculate the Semantic Version from the $Version - $Prerelease + $BuildMetadata"
                $SemVer = "$Version"
                if($Prerelease) {
                    $SemVer = "$Version-$Prerelease"
                }
                if($BuildMetadata) {
                    $SemVer = "$SemVer+$BuildMetadata"
                }
            }

            # Push into the module source (it may be a subfolder)
            $ModuleInfo = InitializeBuild $SourcePath
            Write-Progress "Building $($ModuleInfo.Name)" -Status "Use -Verbose for more information"
            Write-Verbose  "Building $($ModuleInfo.Name)"

            # Output file names
            $OutputDirectory = $ModuleInfo | ResolveOutputFolder
            $RootModule = Join-Path $OutputDirectory "$($ModuleInfo.Name).psm1"
            $OutputManifest = Join-Path $OutputDirectory "$($ModuleInfo.Name).psd1"
            Write-Verbose  "Output to: $OutputDirectory"

            if ($Target -match "Clean") {
                Write-Verbose "Cleaning $OutputDirectory"
                if (Test-Path $OutputDirectory -PathType Leaf) {
                    throw "Unable to build. There is a file in the way at $OutputDirectory"
                }
                if (Test-Path $OutputDirectory -PathType Container) {
                    if (Get-ChildItem $OutputDirectory\*) {
                        Remove-Item $OutputDirectory\* -Recurse -Force
                    }
                }
                if ($Target -notmatch "Build") {
                    return # No build, just cleaning
                }
            } else {
                # If we're not cleaning, skip the build if it's up to date already
                Write-Verbose "Target $Target"
                $NewestBuild = (Get-Item $RootModule -ErrorAction SilentlyContinue).LastWriteTime
                $IsNew = Get-ChildItem $ModuleInfo.ModuleBase -Recurse |
                    Where-Object LastWriteTime -gt $NewestBuild |
                    Select-Object -First 1 -ExpandProperty LastWriteTime
                if ($null -eq $IsNew) {
                    return # Skip the build
                }
            }
            $null = New-Item -ItemType Directory -Path $OutputDirectory -Force

            # Note that the module manifest parent folder is the "root" of the source directories
            Push-Location $ModuleInfo.ModuleBase -StackName Build-Module

            Write-Verbose "Copy files to $OutputDirectory"
            # Copy the files and folders which won't be processed
            Copy-Item *.psm1, *.psd1, *.ps1xml -Exclude "build.psd1" -Destination $OutputDirectory -Force
            if ($ModuleInfo.CopyPaths) {
                Write-Verbose "Copy Entire Directories: $($ModuleInfo.CopyPaths)"
                Copy-Item -Path $ModuleInfo.CopyPaths -Recurse -Destination $OutputDirectory -Force
            }

            Write-Verbose "Combine scripts to $RootModule"

            # SilentlyContinue because there don't *HAVE* to be functions at all
            $AllScripts = Get-ChildItem -Path @($ModuleInfo.SourceDirectories).ForEach{ Join-Path $ModuleInfo.ModuleBase $_ } -Filter *.ps1 -Recurse -ErrorAction SilentlyContinue

            # We have to force the Encoding to string because PowerShell Core made up encodings
            SetModuleContent -Source (@($ModuleInfo.Prefix) + $AllScripts.FullName + @($ModuleInfo.Suffix)).Where{$_} -Output $RootModule -Encoding "$($ModuleInfo.Encoding)"

            # If there is a PublicFilter, update ExportedFunctions
            if ($ModuleInfo.PublicFilter) {
                # SilentlyContinue because there don't *HAVE* to be public functions
                if (($PublicFunctions = Get-ChildItem $ModuleInfo.PublicFilter -Recurse -ErrorAction SilentlyContinue | Where-Object BaseName -in $AllScripts.BaseName | Select-Object -ExpandProperty BaseName)) {
                    Update-Metadata -Path $OutputManifest -PropertyName FunctionsToExport -Value $PublicFunctions
                }
            }

            $ParseResult = ConvertToAst $RootModule
            $ParseResult | MoveUsingStatements -Encoding "$($ModuleInfo.Encoding)"

            if ($PublicFunctions -and -not $ModuleInfo.IgnoreAliasAttribute) {
                if (($AliasesToExport = ($ParseResult | GetCommandAlias)[$PublicFunctions] | ForEach-Object { $_ } | Select-Object -Unique)) {
                    Update-Metadata -Path $OutputManifest -PropertyName AliasesToExport -Value $AliasesToExport
                }
            }

            try {
                if ($Version) {
                    Write-Verbose "Update Manifest at $OutputManifest with version: $Version"
                    Update-Metadata -Path $OutputManifest -PropertyName ModuleVersion -Value $Version
                }
            } catch {
                Write-Warning "Failed to update version to $Version. $_"
            }

            if ($null -ne (Get-Metadata -Path $OutputManifest -PropertyName PrivateData.PSData.Prerelease -ErrorAction SilentlyContinue)) {
                if ($Prerelease) {
                    Write-Verbose "Update Manifest at $OutputManifest with Prerelease: $Prerelease"
                    Update-Metadata -Path $OutputManifest -PropertyName PrivateData.PSData.Prerelease -Value $Prerelease
                } else {
                    Update-Metadata -Path $OutputManifest -PropertyName PrivateData.PSData.Prerelease -Value ""
                }
            } elseif($Prerelease) {
                Write-Warning ("Cannot set Prerelease in module manifest. Add an empty Prerelease to your module manifest, like:`n" +
                               '         PrivateData = @{ PSData = @{ Prerelease = "" } }')
            }

            if ($BuildMetadata) {
                Write-Verbose "Update Manifest at $OutputManifest with metadata: $BuildMetadata from $SemVer"
                $RelNote = Get-Metadata -Path $OutputManifest -PropertyName PrivateData.PSData.ReleaseNotes -ErrorAction SilentlyContinue
                if ($null -ne $RelNote) {
                    $Line = "$($ModuleInfo.Name) v$($SemVer)"
                    if ([string]::IsNullOrWhiteSpace($RelNote)) {
                        Write-Verbose "New ReleaseNotes:`n$Line"
                        Update-Metadata -Path $OutputManifest -PropertyName PrivateData.PSData.ReleaseNotes -Value $Line
                    } elseif ($RelNote -match "^\s*\n") {
                        # Leading whitespace includes newlines
                        Write-Verbose "Existing ReleaseNotes:$RelNote"
                        $RelNote = $RelNote -replace "^(?s)(\s*)\S.*$|^$","`${1}$($Line)`$_"
                        Write-Verbose "New ReleaseNotes:$RelNote"
                        Update-Metadata -Path $OutputManifest -PropertyName PrivateData.PSData.ReleaseNotes -Value $RelNote
                    } else {
                        Write-Verbose "Existing ReleaseNotes:`n$RelNote"
                        $RelNote = $RelNote -replace "^(?s)(\s*)\S.*$|^$","`${1}$($Line)`n`$_"
                        Write-Verbose "New ReleaseNotes:`n$RelNote"
                        Update-Metadata -Path $OutputManifest -PropertyName PrivateData.PSData.ReleaseNotes -Value $RelNote
                    }
                }
            }

            # This is mostly for testing ...
            if ($Passthru) {
                Get-Module $OutputManifest -ListAvailable
            }
        } finally {
            Pop-Location -StackName Build-Module -ErrorAction SilentlyContinue
        }
        Write-Progress "Building $($ModuleInfo.Name)" -Completed
    }
}
#EndRegion '.\Public\Build-Module.ps1' 277
#Region '.\Public\Convert-CodeCoverage.ps1' 0
function Convert-CodeCoverage {
    <#
        .SYNOPSIS
            Convert the file name and line numbers from Pester code coverage of "optimized" modules to the source
        .EXAMPLE
            Invoke-Pester .\Tests -CodeCoverage (Get-ChildItem .\Output -Filter *.psm1).FullName -PassThru |
                Convert-CodeCoverage -SourceRoot .\Source -Relative

            Runs pester tests from a "Tests" subfolder against an optimized module in the "Output" folder,
            piping the results through Convert-CodeCoverage to render the code coverage misses with the source paths.
    #>
    param(
        # The root of the source folder (for resolving source code paths)
        [Parameter(Mandatory)]
        [string]$SourceRoot,

        # The output of `Invoke-Pester -Pasthru`
        # Note: Pester doesn't apply a custom type name
        [Parameter(ValueFromPipeline)]
        [PSObject]$InputObject,

        # Output paths as short paths, relative to the SourceRoot
        [switch]$Relative
    )
    process {
        Push-Location $SourceRoot
        try {
            $InputObject.CodeCoverage.MissedCommands | Convert-LineNumber -Passthru |
                Select-Object SourceFile, @{Name="Line"; Expr={$_.SourceLineNumber}}, Command
        } finally {
            Pop-Location
        }
    }
}
#EndRegion '.\Public\Convert-CodeCoverage.ps1' 34
#Region '.\Public\Convert-LineNumber.ps1' 0
function Convert-LineNumber {
    <#
        .SYNOPSIS
            Convert the line number in a built module to a file and line number in source
        .EXAMPLE
            Convert-LineNumber -SourceFile ~\ErrorMaker.psm1 -SourceLineNumber 27
        .EXAMPLE
            Convert-LineNumber -PositionMessage "At C:\Users\Joel\OneDrive\Documents\PowerShell\Modules\ErrorMaker\ErrorMaker.psm1:27 char:4"
    #>
    [CmdletBinding(DefaultParameterSetName="FromString")]
    param(
        # A position message as found in PowerShell's error messages, ScriptStackTrace, or InvocationInfo
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName="FromString")]
        [string]$PositionMessage,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, Position=0, ParameterSetName="FromInvocationInfo")]
        [Alias("PSCommandPath", "File", "ScriptName", "Script")]
        [string]$SourceFile,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, Position=1, ParameterSetName="FromInvocationInfo")]
        [Alias("LineNumber", "Line", "ScriptLineNumber")]
        [int]$SourceLineNumber,

        [Parameter(ValueFromPipeline, DontShow, ParameterSetName="FromInvocationInfo")]
        [psobject]$InputObject,

        [Parameter(ParameterSetName="FromInvocationInfo")]
        [switch]$Passthru,

        # Output paths as short paths, relative to the SourceRoot
        [switch]$Relative
    )
    begin {
        $filemap = @{}
    }
    process {
        if($PSCmdlet.ParameterSetName -eq "FromString") {
            $Invocation = ParseLineNumber $PositionMessage
            $SourceFile = $Invocation.SourceFile
            $SourceLineNumber = $Invocation.SourceLineNumber
        }
        if(!(Test-Path $SourceFile)) {
            throw "'$SourceFile' does not exist"
        }
        $PSScriptRoot = Split-Path $SourceFile

        Push-Location $PSScriptRoot
        try {
            if (!$filemap.ContainsKey($SourceFile)) {
                # Note: the new pattern is #Region but the old one was # BEGIN
                $matches = Select-String '^(?:#Region|# BEGIN) (?<SourceFile>.*) (?<LineNumber>\d+)?$' -Path $SourceFile
                $filemap[$SourceFile] = @($matches.ForEach{
                        [PSCustomObject]@{
                            PSTypeName = "BuildSourceMapping"
                            SourceFile = $_.Matches[0].Groups["SourceFile"].Value.Trim("'")
                            StartLineNumber = $_.LineNumber
                        }
                    })
            }

            $hit = $filemap[$SourceFile]

            # These are all negative, because BinarySearch returns the match *after* the line we're searching for
            # We need the match *before* the line we're searching for
            # And we need it as a zero-based index:
            $index = -2 - [Array]::BinarySearch($hit.StartLineNumber, $SourceLineNumber)
            $Source = $hit[$index]

            if($Passthru) {
                $InputObject |
                    Add-Member -MemberType NoteProperty -Name SourceFile -Value $Source.SourceFile -PassThru -Force |
                    Add-Member -MemberType NoteProperty -Name SourceLineNumber -Value ($SourceLineNumber - $Source.StartLineNumber) -PassThru -Force
            } else {
                [PSCustomObject]@{
                    PSTypeName = "SourceLocation"
                    SourceFile = $Source.SourceFile
                    SourceLineNumber = $SourceLineNumber - $Source.StartLineNumber
                }
            }
        } finally {
            Pop-Location
        }
    }
}
#EndRegion '.\Public\Convert-LineNumber.ps1' 84
