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
    SqlAgentAlert_NoChangesNeeded = No changes needed for SQL Agent Alert '{0}'. (SAAA0009)
    SQLInstanceNotReachable = Unable to connect to SQL instance or retrieve option. Assuming resource is not in desired state. Error: {0} (SAAA0010)
'@
