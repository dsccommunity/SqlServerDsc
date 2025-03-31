<#
    .SYNOPSIS
        The localized resource strings in English (en-US) for the
        resource SqlRSSetup.
#>

# cSpell:ignore SSRS PBIRS
ConvertFrom-StringData @'
    ## Strings overrides for the ResourceBase's default strings.
    # None

    ## Strings directly used by the derived class SqlRSSetup.
    Evaluating = Evaluating SQL Reporting Services setup for instance '{0}'.
    Instance_NotInstalled = Instance '{0}' is not installed.
    Instance_Installed = Instance '{0}' is installed.
    AcceptLicensingTerms_Required = AcceptLicensingTerms must be set for Install and Repair operations.
    MediaPath_Invalid = The media path '{0}' does not exist.
    MediaPath_DoesNotHaveRequiredExtension = The media path '{0}' does not reference an executable with the required extension .exe.
    EditionOrProductKeyMissing = Neither the parameters Edition or ProductKey was specified.
    EditionUpgrade_RequiresKeyOrEdition = EditionUpgrade requires either ProductKey or Edition to be specified.
    LogPath_ParentMissing = The parent directory '{0}' for LogPath does not exist.
    InstallFolder_ParentMissing = The parent directory '{0}' for InstallFolder does not exist.
    Installing_ReportingServices = Installing SQL Server Reporting Services.
    Installing_PowerBIReportServer = Installing Power BI Report Server.
    Repairing_ReportingServices = Repairing SQL Server Reporting Services.
    Repairing_PowerBIReportServer = Repairing Power BI Report Server.
    Uninstalling_ReportingServices = Uninstalling SQL Server Reporting Services.
    Uninstalling_PowerBIReportServer = Uninstalling Power BI Report Server.
    NotDesiredProductVersion = The product version '{0}' is not the desired for the instance '{1}'. Desired version in executable: '{2}'.
    InstanceName_Invalid = The instance name '{0}' is invalid. Only one of the supported instance name can be used, either SSRS or PBIRS depending on what setup executable is used.
    CannotDetermineProductVersion = Could not determine the product version for the installed instance '{0}'. Run the command `Get-SqlDscRSSetupConfiguration -InstanceName '{0}'` to get the configuration for the instance and verify that it returns a valid product version.
    MissingProductVersionUsingCurrentVersion = The product version for the instance '{0}' is missing. Returning the current version '{1}' instead.
'@
