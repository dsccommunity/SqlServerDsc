@{
    # There is a bug when using an array of paths here. No custom rules are used at all.
    CustomRulePath      = @(
        '.\output\RequiredModules\DscResource.AnalyzerRules'
        '.\source\AnalyzerRules'
    )
    IncludeDefaultRules = $true
    IncludeRules        = @(
        # DSC Resource Kit style guideline rules.
        'PSAvoidDefaultValueForMandatoryParameter',
        'PSAvoidDefaultValueSwitchParameter',
        'PSAvoidInvokingEmptyMembers',
        'PSAvoidNullOrEmptyHelpMessageAttribute',
        'PSAvoidUsingCmdletAliases',
        'PSAvoidUsingComputerNameHardcoded',
        'PSAvoidUsingDeprecatedManifestFields',
        'PSAvoidUsingEmptyCatchBlock',
        'PSAvoidUsingInvokeExpression',
        'PSAvoidUsingPositionalParameters',
        'PSAvoidShouldContinueWithoutForce',
        'PSAvoidUsingWMICmdlet',
        'PSAvoidUsingWriteHost',
        'PSDSCReturnCorrectTypesForDSCFunctions',
        'PSDSCStandardDSCFunctionsInResource',
        'PSDSCUseIdenticalMandatoryParametersForDSC',
        'PSDSCUseIdenticalParametersForDSC',
        'PSMisleadingBacktick',
        'PSMissingModuleManifestField',
        'PSPossibleIncorrectComparisonWithNull',
        'PSProvideCommentHelp',
        'PSReservedCmdletChar',
        'PSReservedParams',
        'PSUseApprovedVerbs',
        'PSUseCmdletCorrectly',
        'PSUseOutputTypeCorrectly',
        'PSAvoidGlobalVars',
        'PSAvoidUsingConvertToSecureStringWithPlainText',
        'PSAvoidUsingPlainTextForPassword',
        'PSAvoidUsingUsernameAndPasswordParams',
        'PSDSCUseVerboseMessageInDSCResource',
        'PSShouldProcess',
        'PSUseDeclaredVarsMoreThanAssignments',
        'PSUsePSCredentialType',

        # Additional rules
        'PSUseConsistentWhitespace',
        'UseCorrectCasing',
        'PSPlaceOpenBrace',
        'PSPlaceCloseBrace',
        'AlignAssignmentStatement',
        'AvoidUsingDoubleQuotesForConstantString',

        'Measure-*'
    )

    Rules               = @{
        PSUseConsistentWhitespace  = @{
            Enable                          = $true
            CheckOpenBrace                  = $false
            CheckInnerBrace                 = $true
            CheckOpenParen                  = $true
            CheckOperator                   = $false
            CheckSeparator                  = $true
            CheckPipe                       = $true
            CheckPipeForRedundantWhitespace = $true
            CheckParameter                  = $false
        }

        PSPlaceOpenBrace           = @{
            Enable             = $true
            OnSameLine         = $false
            NewLineAfter       = $true
            IgnoreOneLineBlock = $false
        }

        PSPlaceCloseBrace          = @{
            Enable             = $true
            NoEmptyLineBefore  = $true
            IgnoreOneLineBlock = $false
            NewLineAfter       = $true
        }

        PSAlignAssignmentStatement = @{
            Enable         = $true
            CheckHashtable = $true
        }
    }
}
