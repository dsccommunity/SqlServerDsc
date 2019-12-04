if (
    $Env:ProjectName -and $Env:ProjectName.Count -eq 1 -and
    $Env:BuildSystem -ne 'unknown'
) {
    if ($Env:BranchName -eq 'master') {
        Deploy Module {
            by PSGalleryModule {
                FromSource $(Get-Item ".\BuildOutput\$Env:ProjectName")
                To $Env:ModuleRepositoryToDeployTo
                WithOptions @{
                    ApiKey = $Env:NugetApiKey
                }
            }
        }
    }
}
else {
    Write-Warning "Condition to Deploy not met"
}
