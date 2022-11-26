@{
    PSDependOptions                = @{
        AddToPath  = $true
        Target     = 'output\RequiredModules'
        Parameters = @{
            Repository = 'PSGallery'
        }
    }

    InvokeBuild                    = 'latest'
    PSScriptAnalyzer               = 'latest'

    <#
        If preview release of Pester prevents release we should temporary shift
        back to stable.
    #>
    Pester                         = @{
        Version    = 'latest'
        Parameters = @{
            AllowPrerelease = $true
        }
    }

    Plaster                        = 'latest'
    ModuleBuilder                  = 'latest'
    ChangelogManagement            = 'latest'
    Sampler                        = 'latest'
    'Sampler.GitHubTasks'          = 'latest'
    MarkdownLinkCheck              = 'latest'
    'DscResource.Common'           = 'latest'
    'DscResource.Test'             = 'latest'
    xDscResourceDesigner           = 'latest'
    'DscResource.DocGenerator'     = 'latest'

    # Analyzer rules
    'DscResource.AnalyzerRules'    = 'latest'
    'Indented.ScriptAnalyzerRules' = 'latest'

    # Dependency for integration tests
    LoopbackAdapter                = 'latest'
    PSPKI                          = 'latest'

    # Prerequisites modules needed for examples or integration tests
    PSDscResources                 = '2.12.0.0'
    StorageDsc                     = '4.9.0.0'
    NetworkingDsc                  = '7.4.0.0'
    PowerShellGet                  = '2.1.2'
}
