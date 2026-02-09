<#
    .SYNOPSIS
        The localized resource strings in English (en-US) for the
        resource SqlRSSetup.
#>

# cSpell:ignore SRSS
ConvertFrom-StringData @'
    ## Strings overrides for the ResourceBase's default strings.
    # None

    ## Strings directly used by the derived class SqlRSSetup. (SRSS0001)
    Getting_Information_Instance = Getting information about instance '{0}'. (SRSS0002)
    Instance_NotInstalled = Instance '{0}' is not installed. (SRSS0003)
    Instance_Installed = Instance '{0}' is installed. (SRSS0004)
    AcceptLicensingTerms_Required = AcceptLicensingTerms must be set for Install and Repair operations. (SRSS0005)
    MediaPath_Invalid = The media path '{0}' does not exist. (SRSS0006)
    MediaPath_DoesNotHaveRequiredExtension = The media path '{0}' does not reference an executable with the required extension .exe. (SRSS0007)
    EditionOrProductKeyMissing = Neither the parameters Edition or ProductKey was specified. (SRSS0008)
    EditionUpgrade_RequiresKeyOrEdition = EditionUpgrade requires either ProductKey or Edition to be specified. (SRSS0009)
    LogPath_ParentMissing = The parent directory '{0}' for LogPath does not exist. (SRSS0010)
    InstallFolder_ParentMissing = The parent directory '{0}' for InstallFolder does not exist. (SRSS0011)
    Installing_ReportingServices = Installing SQL Server Reporting Services. (SRSS0012)
    Installing_PowerBIReportServer = Installing Power BI Report Server. (SRSS0013)
    Repairing_ReportingServices = Repairing SQL Server Reporting Services. (SRSS0014)
    Repairing_PowerBIReportServer = Repairing Power BI Report Server. (SRSS0015)
    Uninstalling_ReportingServices = Uninstalling SQL Server Reporting Services. (SRSS0016)
    Uninstalling_PowerBIReportServer = Uninstalling Power BI Report Server. (SRSS0017)
    NotDesiredProductVersion = The product version '{0}' is not the desired for the instance '{1}'. Desired version in executable: '{2}'. (SRSS0018)
    InstanceName_Invalid = The instance name '{0}' is invalid. Only one of the supported instance name can be used, either SSRS or PBIRS depending on what setup executable is used. (SRSS0019)
    CannotDetermineProductVersion = Could not determine the product version for the installed instance '{0}'. Run the command `Get-SqlDscRSSetupConfiguration -InstanceName '{0}'` to get the configuration for the instance and verify that it returns a valid product version. (SRSS0020)
    CannotDetermineEdition = Could not determine the edition for the installed instance '{0}'. Run the command `Get-SqlDscRSSetupConfiguration -InstanceName '{0}'` to get the configuration for the instance and verify that it returns a valid edition. (SRSS0021)
    NotDesiredEdition = The edition '{0}' is not the desired for the instance '{1}'. Desired edition in executable: '{2}'. (SRSS0022)
    SQLInstanceNotReachable = Unable to connect to SQL instance or retrieve option. Assuming resource is not in desired state. Error: {0} (SRSS0023)
'@
