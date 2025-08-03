<#
    .SYNOPSIS
        The `SqlRSSetup` DSC resource is used to install, repair, or uninstall
        SQL Server Reporting Services (SSRS) or Power BI Report Server (PBIRS).

    .DESCRIPTION
        The `SqlRSSetup` DSC resource is used to install, repair, or uninstall
        SQL Server Reporting Services (SSRS) or Power BI Report Server (PBIRS).

        The built-in parameter **PSDscRunAsCredential** can be used to run the resource
        as another user. The resource will then install as that user, otherwise
        install as SYSTEM.

        >[!TIP]
        >To install Microsoft SQL Server Reporting Services 2016 (or older),
        >please use the resource SqlSetup instead.

        > [!IMPORTANT]
        > When using the action 'Uninstall' and the target node to begin with
        > requires a restart, on the first run the Microsoft SQL Server Reporting
        > Services instance will not be uninstalled, but instead exits with code
        > 3010 and the node will be, by default, restarted. On the second run after
        > restart, the Microsoft SQL Server Reporting Services instance will be
        > uninstalled. If the parameter SuppressRestart is used, then the node must
        > be restarted manually before the Microsoft SQL Server Reporting Services
        > instance will be successfully uninstalled.
        >
        > The Microsoft SQL Server Reporting Services log will indicate that a
        > restart is required by outputting; "*No action was taken as a system
        > reboot is required (0x8007015E)*". The log is default located in the
        > SSRS folder in `%TEMP%`, e.g. `C:\Users\<user>\AppData\Local\Temp\SSRS`.


        ## Requirements

        * Target machine must be running Windows Server 2012 or later.
        * Target machine must have access to the SQL Server Reporting Services or
          Power BI Report Server installation media.
        * SYSTEM account or the users passed in the credentials for the `PsDscRunAsCredential`
          common parameter must have permissions to connect to the location
          where the _Microsoft SQL Server Reporting Services_ or _Microsoft Power_
          _BI Report Server_ media is placed.
        * The parameter `AcceptLicensingTerms` must be set to `$true`.
        * The parameter `InstanceName` can only be set to `SSRS` or `PBIRS` since there
          is no way to change the instance name.

        ## Known issues

        * When using action 'Uninstall', the same version of the executable as the
          version of the installed product must be used. If not, sometimes the uninstall
          is successful (because the executable returns exit code 0) but the instance
          was not actually removed.

        All issues are not listed here, see [here for all open issues](https://github.com/dsccommunity/SqlServerDsc/issues?q=is%3Aissue+is%3Aopen+in%3Atitle+SqlRSSetup).

    .PARAMETER InstanceName
        Specifies the instance name for the Reporting Services instance. This
        must be either `'SSRS'` for SQL Server Reporting Services or `'PBIRS'` for
        Power BI Report Server.

    .PARAMETER Action
        Specifies the action to take for the Reporting Services instance.
        This can be 'Install', 'Repair', or 'Uninstall'.

    .PARAMETER AcceptLicensingTerms
        Required parameter for Install and Repair actions to be able to run unattended.
        By specifying this parameter you acknowledge the acceptance of all license terms
        and notices for the specified features, the terms and notices that the setup
        executable normally asks for.

    .PARAMETER MediaPath
        Specifies the path where to find the SQL Server installation media. On this
        path the SQL Server setup executable must be found.

    .PARAMETER ProductKey
        Specifies the product key to use for the installation or repair, e.g.
        '12345-12345-12345-12345-12345'. This parameter is mutually exclusive with
        the parameter Edition.

    .PARAMETER EditionUpgrade
        Upgrades the edition of the installed product. Requires that either the
        ProductKey or the Edition parameter is also assigned. By default no edition
        upgrade is performed.

    .PARAMETER Edition
        Specifies a free custom edition to use for the installation or repair. This
        parameter is mutually exclusive with the parameter ProductKey.

    .PARAMETER LogPath
        Specifies the file path where to write the log files, e.g. 'C:\Logs\Install.log'.
        By default log files are created under %TEMP%.

    .PARAMETER InstallFolder
        Specifies the folder where to install the product, e.g. 'C:\Program Files\SSRS'.
        By default the product is installed under the default installation folder.

        Reporting Services: %ProgramFiles%\Microsoft SQL Server Reporting Services
        Power BI Report Server: %ProgramFiles%\Microsoft Power BI Report Server

    .PARAMETER SuppressRestart
        Suppresses the restart of the computer after the installation, repair, or
        uninstallation is finished. By default the computer is restarted after the
        operation is finished.

    .PARAMETER ForceRestart
        Forces a restart of the computer after the installation, repair, or
        uninstallation is finished, regardless of the operation's outcome. This
        parameter overrides SuppressRestart.

    .PARAMETER VersionUpgrade
        Specifies whether to upgrade the version of the installed product. By default,
        no version upgrade is performed.

        If this parameter is specified the installed product version will be compared
        against the product version of the setup executable. If the installed product
        version is lower than the product version of the setup executable, the setup
        will perform an upgrade. If the installed product version is equal to or higher
        than the product version of the setup executable, no upgrade will be performed.

    .PARAMETER Timeout
        Specifies how long to wait for the setup process to finish. Default value
        is `7200` seconds (2 hours). If the setup process does not finish before
        this time, an exception will be thrown.

    .NOTES
        The property InstanceName is the key property for this resource. It does
        not use a ValidateSet or Enum due to a limitation. A ValidateSet() or Enum
        would not allow a `$null` value to be set for the property. Setting
        a `$null` value is needed to be able to determine if the instance is
        installed or not. Due to this limitation the property is evaluated in
        the AssertProperties() method to have one of the valid values.

        Known issues:
        - Using `VersionUpgrade` with Microsoft SQL Server 2017 Reporting Services
          does not work because that version does not set a product version in the
          registry. So there is nothing to compare against the setup executable
          product version. It does set a current version, but that does not correlate
          to the product version. This apparently by design with Microsoft SQL Server
          2017 Reporting Services.

    .EXAMPLE
        Configuration Example
        {
            Import-DscResource -ModuleName SqlServerDsc

            Node localhost
            {
                SqlRSSetup 'InstallSSRS'
                {
                    InstanceName        = 'SSRS'
                    Action              = 'Install'
                    AcceptLicensingTerms = $true
                    MediaPath           = 'E:\SQLServerReportingServices.exe'
                    InstallFolder       = 'C:\Program Files\Microsoft SQL Server Reporting Services'
                    SuppressRestart     = $true
                }
            }
        }

        This example shows how to install SQL Server Reporting Services.
#>
[DscResource(RunAsCredential = 'Optional')]
class SqlRSSetup : ResourceBase
{
    [DscProperty(Key)]
    [System.String]
    $InstanceName

    [DscProperty(Mandatory)]
    [InstallAction]
    $Action

    [DscProperty(Mandatory)]
    [System.Boolean]
    $AcceptLicensingTerms

    [DscProperty(Mandatory)]
    [System.String]
    $MediaPath

    [DscProperty()]
    [System.String]
    $ProductKey

    [DscProperty()]
    [Nullable[System.Boolean]]
    $EditionUpgrade

    [DscProperty()]
    [ReportServerEdition]
    $Edition

    [DscProperty()]
    [System.String]
    $LogPath

    [DscProperty()]
    [System.String]
    $InstallFolder

    [DscProperty()]
    [Nullable[System.Boolean]]
    $SuppressRestart

    [DscProperty()]
    [Nullable[System.Boolean]]
    $ForceRestart

    [DscProperty()]
    [Nullable[System.Boolean]]
    $VersionUpgrade

    [DscProperty()]
    [ValidateRange(0, 2147483647)]
    [Nullable[System.UInt32]]
    $Timeout = 7200

    SqlRSSetup () : base ($PSScriptRoot)
    {
        # These properties will not be enforced.
        $this.ExcludeDscProperties = @(
            'Action'
            'AcceptLicensingTerms'
            'MediaPath'
            'ProductKey'
            'EditionUpgrade'
            'Edition'
            'LogPath'
            'InstallFolder'
            'SuppressRestart'
            'Timeout'
            'ForceRestart'
            'VersionUpgrade'
        )
    }

    [SqlRSSetup] Get()
    {
        # Call the base method to return the properties.
        return ([ResourceBase] $this).Get()
    }

    [System.Boolean] Test()
    {
        # Call the base method to test all of the properties that should be enforced.
        $baseTestResult = ([ResourceBase] $this).Test()

        # If $baseTestResult -eq $true, then the InstanceName exists.
        # If $baseTestResult -eq $false, then the InstanceName does not exist.

        $actionStateResult = $baseTestResult

        if ($this.Action -eq 'Repair' -and -not $baseTestResult)
        {
            # Instance is not installed, so it is not possible to perform a repair.
            $actionStateResult = $true
        }

        if ($this.Action -in @('Uninstall', 'Repair'))
        {
            if ($baseTestResult)
            {
                # Instance is installed, it should be uninstalled or repaired.
                $actionStateResult = $false
            }
            else
            {
                <#
                    Instance is not installed, or it is not possible to perform a
                    repair since the instance is uninstalled.
                #>
                $actionStateResult = $true
            }
        }

        $inDesiredState = $true

        <#
            The product version is evaluated if action is Install, instance is
            installed and VersionUpgrade is set to $true.
        #>
        if ($this.Action -eq 'Install' -and $baseTestResult)
        {
            if ($this.EditionUpgrade)
            {
                $currentState = Get-SqlDscRSSetupConfiguration -InstanceName $this.InstanceName

                if ([System.String]::IsNullOrEmpty($currentState.EditionId))
                {
                    New-InvalidResultException -Message (
                        $this.localizedData.CannotDetermineEdition -f $this.InstanceName
                    )
                }

                $currentEdition = ConvertTo-SqlDscEditionName -Id $currentState.EditionId

                if ($currentEdition.Edition -ne $this.Edition)
                {
                    $inDesiredState = $false

                    Write-Verbose -Message (
                        $this.localizedData.NotDesiredEdition -f @(
                            $currentEdition.Edition,
                            $this.InstanceName,
                            $this.Edition
                        )
                    )
                }
            }

            if ($this.VersionUpgrade)
            {
                $fileVersion = Get-FileProductVersion -Path $this.MediaPath -ErrorAction 'Stop'

                if ($fileVersion)
                {
                    $currentState = Get-SqlDscRSSetupConfiguration -InstanceName $this.InstanceName

                    if ([System.String]::IsNullOrEmpty($currentState.ProductVersion))
                    {
                        New-InvalidResultException -Message (
                            $this.localizedData.CannotDetermineProductVersion -f $this.InstanceName
                        )
                    }

                    $installedVersion = [System.Version] $currentState.ProductVersion

                    if ($installedVersion -lt $fileVersion)
                    {
                        $inDesiredState = $false

                        Write-Verbose -Message (
                            $this.localizedData.NotDesiredProductVersion -f @(
                                $fileVersion.ToString(),
                                $this.InstanceName,
                                $installedVersion.ToString()
                            )
                        )
                    }
                }
            }
        }

        return ($actionStateResult -and $inDesiredState)
    }

    [void] Set()
    {
        # Call the base method to enforce the properties.
        ([ResourceBase] $this).Set()
    }

    <#
        Base method Get() call this method to get the current state as a hashtable.
        The parameter properties will contain the key properties.
    #>
    hidden [System.Collections.Hashtable] GetCurrentState([System.Collections.Hashtable] $properties)
    {
        Write-Verbose -Message (
            $this.localizedData.Getting_Information_Instance -f @(
                $properties.InstanceName
            )
        )

        $currentState = @{
            # This must be set to the correct valid value for base method Get() to work.
            InstanceName  = $null
            InstallFolder = $null
        }

        # Get the configuration if installed
        $rsConfiguration = Get-SqlDscRSSetupConfiguration -InstanceName $properties.InstanceName

        if ($rsConfiguration)
        {
            # Instance is installed
            Write-Verbose -Message (
                $this.localizedData.Instance_Installed -f $properties.InstanceName
            )

            $currentState.InstanceName = $rsConfiguration.InstanceName
            $currentState.InstallFolder = $rsConfiguration.InstallFolder
        }
        else
        {
            # Instance is not installed
            Write-Verbose -Message (
                $this.localizedData.Instance_NotInstalled -f $properties.InstanceName
            )
        }

        return $currentState
    }

    <#
        Base method Set() call this method with the properties that are not in
        desired state and should be enforced. It is not called if all properties
        are in desired state. The variable $properties contains only the properties
        that are not in desired state.
    #>
    hidden [void] Modify([System.Collections.Hashtable] $properties)
    {
        $getDscPropertyParameters = @{
            HasValue    = $true
            Attribute   = @(
                'Optional'
                'Mandatory'
            )
            ExcludeName = @(
                # Remove mandatory property that is not a command parameter.
                'Action'

                # Remove optional property that is not a command parameter.
                'VersionUpgrade'
            )
        }

        # The command parameters are the same for all actions.
        if ($this.Action -eq 'Uninstall')
        {
            # Only retrieve properties that are needed for Uninstall
            $getDscPropertyParameters.Name = @(
                'MediaPath'
                'LogPath'
                'SuppressRestart'
                'Timeout'
            )
        }

        $commandParameters = $this |
            Get-DscProperty @getDscPropertyParameters

        $exitCode = $null

        # Switch based on the action to perform
        if ($this.InstanceName -eq 'SSRS')
        {
            switch ($this.Action)
            {
                'Install'
                {
                    Write-Verbose -Message $this.localizedData.Installing_ReportingServices

                    $exitCode = Install-SqlDscReportingService @commandParameters -PassThru -Force -ErrorAction 'Stop'

                    break
                }

                'Repair'
                {
                    Write-Verbose -Message $this.localizedData.Repairing_ReportingServices

                    $exitCode = Repair-SqlDscReportingService @commandParameters -PassThru -Force -ErrorAction 'Stop'

                    break
                }

                'Uninstall'
                {
                    Write-Verbose -Message $this.localizedData.Uninstalling_ReportingServices

                    $exitCode = Uninstall-SqlDscReportingService @commandParameters -PassThru -Force -ErrorAction 'Stop'

                    break
                }
            }
        }
        elseif ($this.InstanceName -eq 'PBIRS')
        {
            switch ($this.Action)
            {
                'Install'
                {
                    Write-Verbose -Message $this.localizedData.Installing_PowerBIReportServer

                    $exitCode = Install-SqlDscBIReportServer @commandParameters -PassThru -Force -ErrorAction 'Stop'

                    break
                }

                'Repair'
                {
                    Write-Verbose -Message $this.localizedData.Repairing_PowerBIReportServer

                    $exitCode = Repair-SqlDscBIReportServer @commandParameters -PassThru -Force -ErrorAction 'Stop'

                    break
                }

                'Uninstall'
                {
                    Write-Verbose -Message $this.localizedData.Uninstalling_PowerBIReportServer

                    $exitCode = Uninstall-SqlDscBIReportServer @commandParameters -PassThru -Force -ErrorAction 'Stop'

                    break
                }
            }
        }

        <#
            If ForceRestart is set it will always restart, and override SuppressRestart.
            If the exit code is 3010, then a restart is required.
        #>
        if ($this.ForceRestart -or ($exitCode -eq 3010 -and -not $this.SuppressRestart))
        {
            Set-DscMachineRebootRequired
        }
    }

    <#
        Base method Assert() call this method with the properties that was assigned
        a value.
    #>
    hidden [void] AssertProperties([System.Collections.Hashtable] $properties)
    {
        # TODO: Most or all of these checks are done in the Install, Uninstall or Repair-commands. We should remove them here if possible.

        # Verify that the instance name is valid.
        if ($properties.InstanceName -notin @('SSRS', 'PBIRS'))
        {
            New-ArgumentException -ArgumentName 'InstanceName' -Message ($this.localizedData.InstanceName_Invalid -f $properties.InstanceName)
        }

        # Verify that AcceptLicensingTerms is specified for Install and Repair actions.
        if ($properties.Action -in @('Install', 'Repair') -and -not $properties.AcceptLicensingTerms)
        {
            New-ArgumentException -ArgumentName 'AcceptLicensingTerms' -Message $this.localizedData.AcceptLicensingTerms_Required
        }

        # ProductKey and Edition are mutually exclusive.
        $assertBoundParameterParameters = @{
            BoundParameterList     = $properties
            MutuallyExclusiveList1 = @('ProductKey')
            MutuallyExclusiveList2 = @('Edition')
        }

        Assert-BoundParameter @assertBoundParameterParameters

        # Verify that MediaPath is valid.
        if (-not (Test-Path -Path $properties.MediaPath))
        {
            New-ArgumentException -ArgumentName 'MediaPath' -Message (
                $this.localizedData.MediaPath_Invalid -f $properties.MediaPath
            )
        }

        if ((Test-Path -Path $properties.MediaPath) -and (Get-Item -Path $properties.MediaPath).Extension -ne '.exe')
        {
            New-ArgumentException -ArgumentName 'MediaPath' -Message (
                $this.localizedData.MediaPath_DoesNotHaveRequiredExtension -f $properties.MediaPath
            )
        }

        # Must have specified either ProductKey or Edition.
        if ($properties.Action -eq 'Install' -and $properties.Keys -notcontains 'Edition' -and $properties.Keys -notcontains 'ProductKey')
        {
            New-ArgumentException -ArgumentName 'Edition, ProductKey' -Message $this.localizedData.EditionOrProductKeyMissing
        }

        # EditionUpgrade requires either ProductKey or Edition for Install and Repair actions.
        if ($properties.Action -in @('Repair') -and $properties.EditionUpgrade -and -not ($properties.ProductKey -or $properties.Edition))
        {
            New-ArgumentException -ArgumentName 'EditionUpgrade' -Message $this.localizedData.EditionUpgrade_RequiresKeyOrEdition
        }

        # LogPath validation if specified.
        if ($properties.Keys -contains 'LogPath')
        {
            # Verify that the log path parent directory exists.
            $logDirectory = Split-Path -Path $properties.LogPath -Parent

            if (-not (Test-Path -Path $logDirectory))
            {
                New-ArgumentException -ArgumentName 'LogPath' -Message (
                    $this.localizedData.LogPath_ParentMissing -f $logDirectory
                )
            }
        }

        # InstallFolder validation if specified for Install action.
        if ($properties.Action -eq 'Install' -and $properties.Keys -contains 'InstallFolder')
        {
            # Verify that the install folder parent directory exists.
            $installDirectory = Split-Path -Path $properties.InstallFolder -Parent

            if (-not (Test-Path -Path $installDirectory))
            {
                New-ArgumentException -ArgumentName 'InstallFolder' -Message (
                    $this.localizedData.InstallFolder_ParentMissing -f $installDirectory
                )
            }
        }
    }

    <#
        Base method Normalize() call this method with the properties that was assigned
        a value.
    #>
    hidden [void] NormalizeProperties([System.Collections.Hashtable] $properties)
    {
        $this.InstanceName = $properties.InstanceName.ToUpper()

        # Use array intersection for more efficient filtering
        $pathProperties = @(
            'MediaPath'
            'InstallFolder'
            'LogPath'
        ) |
            Where-Object {
                $properties.ContainsKey($_)
            }

        foreach ($property in $pathProperties)
        {
            $formatPathParameters = @{
                Path                         = $properties.$property
                EnsureDriveLetterRoot        = $true
                NoTrailingDirectorySeparator = $true
                ErrorAction                  = 'Stop'
            }

            # Normalize the property to lower case.
            $this.$property = Format-Path @formatPathParameters
        }
    }
}
