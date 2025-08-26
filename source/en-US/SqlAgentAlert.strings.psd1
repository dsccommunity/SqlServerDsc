<#
    .SYNOPSIS
        The localized resource strings in English (en-US) for the
        resource SqlAgentAlert.
#>

ConvertFrom-StringData @'
    ## SqlAgentAlert
    SqlAgentAlert_GettingCurrentState = Getting current state of SQL Agent Alert '{0}' on instance '{1}'. (SAAA0002)
    SqlAgentAlert_AlertExists = SQL Agent Alert '{0}' exists. (SAAA0003)
    SqlAgentAlert_AlertDoesNotExist = SQL Agent Alert '{0}' does not exist. (SAAA0004)
    SqlAgentAlert_CreatingAlert = Creating SQL Agent Alert '{0}'. (SAAA0005)
    SqlAgentAlert_UpdatingAlert = Updating SQL Agent Alert '{0}'. (SAAA0006)
    SqlAgentAlert_RemovingAlert = Removing SQL Agent Alert '{0}'. (SAAA0007)
    SqlAgentAlert_SeverityOrMessageIdNotAllowedWhenAbsent = Cannot specify Severity or MessageId when Ensure is set to 'Absent'. (SAAA0008)
    SqlAgentAlert_NoChangesNeeded = No changes needed for SQL Agent Alert '{0}'. (SAAA0009)
'@
