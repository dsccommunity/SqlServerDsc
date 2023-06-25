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
    ConvertToSARIF                 = 'latest' # cSpell: disable-line

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
    'DscResource.Test'             = 'latest'
    xDscResourceDesigner           = 'latest'
    'DscResource.DocGenerator'     = 'latest'

    # Build dependencies needed for using the module
    'DscResource.Base'             = 'latest'
    'DscResource.Common'           = 'latest'

    # Analyzer rules
    'DscResource.AnalyzerRules'    = 'latest'
    'Indented.ScriptAnalyzerRules' = 'latest'

    # Dependency for integration tests
    LoopbackAdapter                = 'latest'

    # Need to pin this to 3.7.2 because 4.0.0 made the integration tests fail.
    PSPKI                          = '3.7.2'

    # Prerequisites modules needed for examples or integration tests
    PSDscResources                 = '2.12.0.0'
    StorageDsc                     = '4.9.0.0'
    NetworkingDsc                  = '7.4.0.0'
    WSManDsc                       = '3.1.1'
}
