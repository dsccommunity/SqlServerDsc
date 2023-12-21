@{
    Gallery         = 'PSGallery'
    AllowPrerelease = $false
    WithYAML        = $true

    UsePSResourceGet = $true
    PSResourceGetVersion = '1.0.0'
    UsePowerShellGetCompatibilityModule = $true
    UsePowerShellGetCompatibilityModuleVersion = '3.0.22-beta22'
    # By enabling this the pipeline can encounter breaking changes or issues in code that
    # is merged in the ModuleFast repository, this could affect the pipeline negatively.
    # Make sure to use a clean PowerShell session after changing this.
    ModuleFastBleedingEdge = $true
}
