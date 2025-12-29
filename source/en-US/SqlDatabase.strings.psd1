<#
    .SYNOPSIS
        The localized resource strings in English (en-US) for the
        resource SqlDatabase.
#>

ConvertFrom-StringData @'
    ## Strings overrides for the ResourceBase's default strings.
    # None

    ## Strings directly used by the derived class SqlDatabase.
    EvaluatingDatabaseState = Evaluating the current state of the database '{0}' on the instance '{1}'. (SD0001)
    CreatingDatabase = Creating the database '{0}' on the instance '{1}'. (SD0002)
    DroppingDatabase = Dropping the database '{0}' on the instance '{1}'. (SD0003)
    UpdatingDatabase = Updating the database '{0}' on the instance '{1}'. (SD0004)
    SettingOwner = Setting the database owner to '{0}'. (SD0005)
    FailedToSetOwner = Failed to set the owner to '{0}' for the database '{1}'. (SD0006)
    FailedToCreateDatabase = Failed to create the database '{0}'. (SD0007)
    FailedToDropDatabase = Failed to drop the database '{0}'. (SD0008)
    FailedToUpdateDatabase = Failed to update the database '{0}'. (SD0009)
    EnablingSnapshotIsolation = Enabling snapshot isolation. (SD0010)
    DisablingSnapshotIsolation = Disabling snapshot isolation. (SD0011)
    InvalidCollation = The specified collation '{0}' is not a valid collation for the instance '{1}'. (SD0012)
    InvalidCompatibilityLevel = The specified compatibility level '{0}' is not a valid compatibility level for the instance '{1}'. (SD0013)
    CatalogCollationCannotBeChanged = The property CatalogCollation cannot be changed after the database is created. (SD0014)
    IsLedgerCannotBeChanged = The property IsLedger cannot be changed after the database is created. (SD0015)
    FailedToEnableSnapshotIsolation = Failed to enable snapshot isolation for the database '{0}'. (SD0016)
    FailedToDisableSnapshotIsolation = Failed to disable snapshot isolation for the database '{0}'. (SD0017)
    SmoCompatibilityLevelTypeNotFound = Unable to find type 'Microsoft.SqlServer.Management.Smo.CompatibilityLevel'. Ensure SQL Server Management Objects (SMO) are installed. (SD0018)
'@
