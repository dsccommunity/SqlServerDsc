function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $SourcePath,

        [System.String]
        $SourceFolder = "\SQLServer2012.en",

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $SetupCredential,

        [System.String]
        $Features = "SQLENGINE",

        [parameter(Mandatory = $true)]
        [System.String]
        $InstanceName
    )

    $InstanceName = $InstanceName.ToUpper()

    Import-Module $PSScriptRoot\..\..\xPDT.psm1

    $Path = Join-Path -Path (Join-Path -Path $SourcePath -ChildPath $SourceFolder) -ChildPath "setup.exe"
    $Path = ResolvePath $Path
    Write-Verbose "Path: $Path"
    $SQLVersion = GetSQLVersion -Path $Path
    
    if($InstanceName -eq "MSSQLSERVER")
    {
        $DBServiceName = "MSSQLSERVER"
        $AgtServiceName = "SQLSERVERAGENT"
        $FTServiceName = "MSSQLFDLauncher"
        $RSServiceName = "ReportServer"
        $ASServiceName = "MSSQLServerOLAPService"
    }
    else
    {
        $DBServiceName = "MSSQL`$$InstanceName"
        $AgtServiceName = "SQLAgent`$$InstanceName"
        $FTServiceName = "MSSQLFDLauncher`$$InstanceName"
        $RSServiceName = "ReportServer`$$InstanceName"
        $ASServiceName = "MSOLAP`$$InstanceName"
    }
    $ISServiceName = "MsDtsServer" + $SQLVersion + "0"
    
    $Services = Get-Service
    $Features = ""
    if($Services | Where-Object {$_.Name -eq $DBServiceName})
    {
        $Features += "SQLENGINE,"
        $SQLSvcAccountUsername = (Get-WmiObject -Class Win32_Service | Where-Object {$_.Name -eq $DBServiceName}).StartName
        $AgtSvcAccountUsername = (Get-WmiObject -Class Win32_Service | Where-Object {$_.Name -eq $AgtServiceName}).StartName
        $FullInstanceID = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL' -Name $InstanceName).$InstanceName
        $InstanceID = $FullInstanceID.Split(".")[1]
        $InstanceDir = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$FullInstanceID\Setup" -Name 'SqlProgramDir').SqlProgramDir.Trim("\")
        $null = [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO')
        if($InstanceName -eq "MSSQLSERVER")
        {
            $DBServer = New-Object ('Microsoft.SqlServer.Management.Smo.Server') "localhost"
        }
        else
        {
            $DBServer = New-Object ('Microsoft.SqlServer.Management.Smo.Server') "localhost\$InstanceName"
        }
        $SQLCollation = $DBServer.Collation
        $SQLSysAdminAccounts = @() 
        foreach($SQLUser in $DBServer.Logins)
        {
            foreach ($SQLRole in $SQLUser.ListMembers())
            {
                if($SQLRole -like "sysadmin")
                {
                    $SQLSysAdminAccounts += $SQLUser.Name
                }
            }
        }
        if($DBServer.LoginMode -eq "Mixed")
        {
            $SecurityMode = "SQL"
        }
        else
        {
            $SecurityMode = "Windows"
        }
        $InstallSQLDataDir = $DBServer.InstallDataDirectory
        $SQLUserDBDir = $DBServer.DefaultFile
        $SQLUserDBLogDir = $DBServer.DefaultLog
#        $SQLTempDBDir = 
#        $SQLTempDBLogDir = 
        $SQLBackupDir = $DBServer.BackupDirectory
    }
    if($Services | Where-Object {$_.Name -eq $FTServiceName})
    {
        $Features += "FULLTEXT,"
        $FTSvcAccountUsername = (Get-WmiObject -Class Win32_Service | Where-Object {$_.Name -eq $FTServiceName}).StartName
    }
    if($Services | Where-Object {$_.Name -eq $RSServiceName})
    {
        $Features += "RS,"
        $RSSvcAccountUsername = (Get-WmiObject -Class Win32_Service | Where-Object {$_.Name -eq $RSServiceName}).StartName
    }
    if($Services | Where-Object {$_.Name -eq $ASServiceName})
    {
        $Features += "AS,"
        $ASSvcAccountUsername = (Get-WmiObject -Class Win32_Service | Where-Object {$_.Name -eq $ASServiceName}).StartName
        [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.AnalysisServices")
        $ASServer = New-Object Microsoft.AnalysisServices.Server
        if($InstanceName -eq "MSSQLSERVER")
        {
            $ASServer.Connect("localhost")
        }
        else
        {
            $ASServer.Connect("localhost\$InstanceName")
        }
        $ASCollation = ($ASServer.ServerProperties | Where-Object {$_.Name -eq "CollationName"}).Value
        $ASSERVERMODE =  $(IF ($($ASServer.ServerMode) -eq 'Default') {'MULTIDIMENSIONAL'}
                            Else {$($ASServer.ServerMode)})
        $ASSysAdminAccounts = @(($ASServer.Roles | Where-Object {$_.Name -eq "Administrators"}).Members.Name)
        $ASDataDir = ($ASServer.ServerProperties | Where-Object {$_.Name -eq "DataDir"}).Value
        $ASTempDir = ($ASServer.ServerProperties | Where-Object {$_.Name -eq "TempDir"}).Value
        $ASLogDir = ($ASServer.ServerProperties | Where-Object {$_.Name -eq "LogDir"}).Value
        $ASBackupDir = ($ASServer.ServerProperties | Where-Object {$_.Name -eq "BackupDir"}).Value
        $ASConfigDir = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\$ASServiceName" -Name "ImagePath").ImagePath.Replace(" -s ",",").Split(",")[1].Trim("`"")
    }
    if($Services | Where-Object {$_.Name -eq $ISServiceName})
    {
        $Features += "IS,"
        $ISSvcAccountUsername = (Get-WmiObject -Class Win32_Service | Where-Object {$_.Name -eq $ISServiceName}).StartName
    }
    $Products = Get-WmiObject -Class Win32_Product
    switch($SQLVersion)
    {
        "11"
        {
            $IdentifyingNumber = "{A7037EB2-F953-4B12-B843-195F4D988DA1}"
        }
        "12"
        {
            $IdentifyingNumber = "{75A54138-3B98-4705-92E4-F619825B121F}"
        }
    }
    if($Products | Where-Object {$_.IdentifyingNumber -eq $IdentifyingNumber})
    {
        $Features += "SSMS,"
    }
    switch($SQLVersion)
    {
        "11"
        {
            $IdentifyingNumber = "{7842C220-6E9A-4D5A-AE70-0E138271F883}"
        }
        "12"
        {
            $IdentifyingNumber = "{B5ECFA5C-AC4F-45A4-A12E-A76ABDD9CCBA}"
        }
    }
    if($Products | Where-Object {$_.IdentifyingNumber -eq $IdentifyingNumber})
    {
        $Features += "ADV_SSMS,"
    }
    $Features = $Features.Trim(",")
    if($Features -ne "")
    {
        switch($SQLVersion)
        {
            "11"
            {
                $InstallSharedDir = (GetFirstItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components" -Name "FEE2E540D20152D4597229B6CFBC0A69")
                $InstallSharedWOWDir = (GetFirstItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components" -Name "A79497A344129F64CA7D69C56F5DD8B4")
            }
            "12"
            {
                $InstallSharedDir = (GetFirstItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components" -Name "FEE2E540D20152D4597229B6CFBC0A69")
                $InstallSharedWOWDir = (GetFirstItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components" -Name "C90BFAC020D87EA46811C836AD3C507F")
            }
        }
    }

    $returnValue = @{
        SourcePath = $SourcePath
        SourceFolder = $SourceFolder
        Features = $Features
        InstanceName = $InstanceName
        InstanceID = $InstanceID
        InstallSharedDir = $InstallSharedDir
        InstallSharedWOWDir = $InstallSharedWOWDir
        InstanceDir = $InstanceDir
        SQLSvcAccountUsername = $SQLSvcAccountUsername
        AgtSvcAccountUsername = $AgtSvcAccountUsername
        SQLCollation = $SQLCollation
        SQLSysAdminAccounts = $SQLSysAdminAccounts
        SecurityMode = $SecurityMode
        InstallSQLDataDir = $InstallSQLDataDir
        SQLUserDBDir = $SQLUserDBDir
        SQLUserDBLogDir = $SQLUserDBLogDir
#        SQLTempDBDir = $SQLTempDBDir
#        SQLTempDBLogDir = $SQLTempDBLogDir
        SQLBackupDir = $SQLBackupDir
        FTSvcAccountUsername = $FTSvcAccountUsername
        RSSvcAccountUsername = $RSSvcAccountUsername
        ASSvcAccountUsername = $ASSvcAccountUsername
        ASCollation = $ASCollation
        ASSERVERMODE = $ASSERVERMODE
        ASSysAdminAccounts = $ASSysAdminAccounts
        ASDataDir = $ASDataDir
        ASLogDir = $ASLogDir
        ASBackupDir = $ASBackupDir
        ASTempDir = $ASTempDir
        ASConfigDir = $ASConfigDir
        ISSvcAccountUsername = $ISSvcAccountUsername
    }

    $returnValue
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $SourcePath,

        [System.String]
        $SourceFolder = "\SQLServer2012.en",

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $SetupCredential,

        [System.String]
        $Features = "SQLENGINE",

        [parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [System.String]
        $InstanceID,

        [System.String]
        $PID,

        [System.String]
        $UpdateEnabled = "True",

        [System.String]
        $UpdateSource = ".\Updates",

        [System.String]
        $SQMReporting,

        [System.String]
        $ErrorReporting,

        [System.String]
        $InstallSharedDir,

        [System.String]
        $InstallSharedWOWDir,

        [System.String]
        $InstanceDir,

        [System.Management.Automation.PSCredential]
        $SQLSvcAccount,

        [System.Management.Automation.PSCredential]
        $AgtSvcAccount,

        [System.String]
        $SQLCollation,

        [System.String[]]
        $SQLSysAdminAccounts,

        [System.String]
        $SecurityMode,

        [System.Management.Automation.PSCredential]
        $SAPwd,

        [System.String]
        $InstallSQLDataDir,

        [System.String]
        $SQLUserDBDir,

        [System.String]
        $SQLUserDBLogDir,

        [System.String]
        $SQLTempDBDir,

        [System.String]
        $SQLTempDBLogDir,

        [System.String]
        $SQLBackupDir,

        [System.Management.Automation.PSCredential]
        $FTSvcAccount,

        [System.Management.Automation.PSCredential]
        $RSSvcAccount,

        [System.Management.Automation.PSCredential]
        $ASSvcAccount,

        [System.String]
        $ASCollation,

        [System.String]
        $ASSERVERMODE,

        [System.String[]]
        $ASSysAdminAccounts,

        [System.String]
        $ASDataDir,

        [System.String]
        $ASLogDir,

        [System.String]
        $ASBackupDir,

        [System.String]
        $ASTempDir,

        [System.String]
        $ASConfigDir,

        [System.Management.Automation.PSCredential]
        $ISSvcAccount
    )

    $SQLData = Get-TargetResource -SourcePath $SourcePath -SourceFolder $SourceFolder -SetupCredential $SetupCredential -Features $Features -InstanceName $InstanceName
    $InstanceName = $InstanceName.ToUpper()

    #@mikefrobbins: The contains method is case sensitive so the specified features have to be in upper case to match the case specified in this function.
    $Features = $Features.ToUpper()

    Import-Module $PSScriptRoot\..\..\xPDT.psm1

    $Path = Join-Path -Path (Join-Path -Path $SourcePath -ChildPath $SourceFolder) -ChildPath "setup.exe"
    $Path = ResolvePath $Path
    Write-Verbose "Path: $Path"
    $SQLVersion = GetSQLVersion -Path $Path

    if($InstanceName -eq "MSSQLSERVER")
    {
        $DBServiceName = "MSSQLSERVER"
        $AgtServiceName = "SQLSERVERAGENT"
        $FTServiceName = "MSSQLFDLauncher"
        $RSServiceName = "ReportServer"
        $ASServiceName = "MSSQLServerOLAPService"
    }
    else
    {
        $DBServiceName = "MSSQL`$$InstanceName"
        $AgtServiceName = "SQLAgent`$$InstanceName"
        $FTServiceName = "MSSQLFDLauncher`$$InstanceName"
        $RSServiceName = "ReportServer`$$InstanceName"
        $ASServiceName = "MSOLAP`$$InstanceName"
    }
    $ISServiceName = "MsDtsServer" + $SQLVersion + "0"

    # Determine features to install
    $FeaturesToInstall = ""
    foreach($Feature in $Features.Split(","))
    {
        if(!($SQLData.Features.Contains($Feature)))
        {
            $FeaturesToInstall += "$Feature,"
        }
    }
    $Features = $FeaturesToInstall.Trim(",")

    # If SQL shared components already installed, clear InstallShared*Dir variables
    switch($SQLVersion)
    {
        "11"
        {
            if((Get-Variable -Name "InstallSharedDir" -ErrorAction SilentlyContinue) -and (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\30AE1F084B1CF8B4797ECB3CCAA3B3B6" -ErrorAction SilentlyContinue))
            {
                Set-Variable -Name "InstallSharedDir" -Value ""
            }
            if((Get-Variable -Name "InstallSharedWOWDir" -ErrorAction SilentlyContinue) -and (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\A79497A344129F64CA7D69C56F5DD8B4" -ErrorAction SilentlyContinue))
            {
                Set-Variable -Name "InstallSharedWOWDir" -Value ""
            }
        }
        "12"
        {
            if((Get-Variable -Name "InstallSharedDir" -ErrorAction SilentlyContinue) -and (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\FEE2E540D20152D4597229B6CFBC0A69" -ErrorAction SilentlyContinue))
            {
                Set-Variable -Name "InstallSharedDir" -Value ""
            }
            if((Get-Variable -Name "InstallSharedWOWDir" -ErrorAction SilentlyContinue) -and (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\C90BFAC020D87EA46811C836AD3C507F" -ErrorAction SilentlyContinue))
            {
                Set-Variable -Name "InstallSharedWOWDir" -Value ""
            }
        }
    }

    # Remove trailing "\" from paths
    foreach($Var in @("InstallSQLDataDir","SQLUserDBDir","SQLUserDBLogDir","SQLTempDBDir","SQLTempDBLogDir","SQLBackupDir","ASDataDir","ASLogDir","ASBackupDir","ASTempDir","ASConfigDir"))
    {
        if(Get-Variable -Name $Var -ErrorAction SilentlyContinue)
        {
            Set-Variable -Name $Var -Value (Get-Variable -Name $Var).Value.TrimEnd("\")
        }
    }

    # Create install arguments
    $Arguments = "/Quiet=`"True`" /IAcceptSQLServerLicenseTerms=`"True`" /Action=`"Install`""
    $ArgumentVars = @(
        "InstanceName",
        "InstanceID",
        "UpdateEnabled",
        "UpdateSource",
        "Features",
        "PID",
        "SQMReporting",
        "ErrorReporting",
        "InstallSharedDir",
        "InstallSharedWOWDir",
        "InstanceDir"
    )
    if($Features.Contains("SQLENGINE"))
    {
        $ArgumentVars += @(
            "SecurityMode",
            "SQLCollation",
            "InstallSQLDataDir",
            "SQLUserDBDir",
            "SQLUserDBLogDir",
            "SQLTempDBDir",
            "SQLTempDBLogDir",
            "SQLBackupDir"
        )
        if($PSBoundParameters.ContainsKey("SQLSvcAccount"))
        {
            if($SQLSvcAccount.UserName -eq "SYSTEM")
            {
                $Arguments += " /SQLSVCACCOUNT=`"NT AUTHORITY\SYSTEM`""
            }
            else
            {
                $Arguments += " /SQLSVCACCOUNT=`"" + $SQLSvcAccount.UserName + "`""
                $Arguments += " /SQLSVCPASSWORD=`"" + $SQLSvcAccount.GetNetworkCredential().Password + "`""
            }
        }
        if($PSBoundParameters.ContainsKey("AgtSvcAccount"))
        {
            if($AgtSvcAccount.UserName -eq "SYSTEM")
            {
                $Arguments += " /AGTSVCACCOUNT=`"NT AUTHORITY\SYSTEM`""
            }
            else
            {
                $Arguments += " /AGTSVCACCOUNT=`"" + $AgtSvcAccount.UserName + "`""
                $Arguments += " /AGTSVCPASSWORD=`"" + $AgtSvcAccount.GetNetworkCredential().Password + "`""
            }

        }
        $Arguments += " /AGTSVCSTARTUPTYPE=Automatic"
    }
    if($Features.Contains("FULLTEXT"))
    {
        if($PSBoundParameters.ContainsKey("FTSvcAccount"))
        {
            if($FTSvcAccount.UserName -eq "SYSTEM")
            {
                $Arguments += " /FTSVCACCOUNT=`"NT AUTHORITY\LOCAL SERVICE`""
            }
            else
            {
                $Arguments += " /FTSVCACCOUNT=`"" + $FTSvcAccount.UserName + "`""
                $Arguments += " /FTSVCPASSWORD=`"" + $FTSvcAccount.GetNetworkCredential().Password + "`""
            }
        }
    }
    if($Features.Contains("RS"))
    {
        if($PSBoundParameters.ContainsKey("RSSvcAccount"))
        {
            if($RSSvcAccount.UserName -eq "SYSTEM")
            {
                $Arguments += " /RSSVCACCOUNT=`"NT AUTHORITY\SYSTEM`""
            }
            else
            {
                $Arguments += " /RSSVCACCOUNT=`"" + $RSSvcAccount.UserName + "`""
                $Arguments += " /RSSVCPASSWORD=`"" + $RSSvcAccount.GetNetworkCredential().Password + "`""
            }
        }
    }

    if($Features.Contains("AS"))
    {
        $ArgumentVars += @(
            "ASCollation",
            "ASDataDir",
            "ASLogDir",
            "ASBackupDir",
            "ASTempDir",
            "ASConfigDir"
        )
        IF ((Get-Variable -Name "ASSERVERMODE" -ErrorAction SilentlyContinue))
        {
            $ArgumentVars += @("ASSERVERMODE")
        }
        if($PSBoundParameters.ContainsKey("ASSvcAccount"))
        {
            if($ASSvcAccount.UserName -eq "SYSTEM")
            {
                $Arguments += " /ASSVCACCOUNT=`"NT AUTHORITY\SYSTEM`""
            }
            else
            {
                $Arguments += " /ASSVCACCOUNT=`"" + $ASSvcAccount.UserName + "`""
                $Arguments += " /ASSVCPASSWORD=`"" + $ASSvcAccount.GetNetworkCredential().Password + "`""
            }
        }
    }
    if($Features.Contains("IS"))
    {
        if($PSBoundParameters.ContainsKey("ISSvcAccount"))
        {
            if($ISSvcAccount.UserName -eq "SYSTEM")
            {
                $Arguments += " /ISSVCACCOUNT=`"NT AUTHORITY\SYSTEM`""
            }
            else
            {
                $Arguments += " /ISSVCACCOUNT=`"" + $ISSvcAccount.UserName + "`""
                $Arguments += " /ISSVCPASSWORD=`"" + $ISSvcAccount.GetNetworkCredential().Password + "`""
            }
        }
    }
    foreach($ArgumentVar in $ArgumentVars)
    {
        if((Get-Variable -Name $ArgumentVar).Value -ne "")
        {
            $Arguments += " /$ArgumentVar=`"" + (Get-Variable -Name $ArgumentVar).Value + "`""
        }
    }
    if($Features.Contains("SQLENGINE"))
    {
        $Arguments += " /SQLSysAdminAccounts=`"" + $SetupCredential.UserName + "`""
        if($PSBoundParameters.ContainsKey("SQLSysAdminAccounts"))
        {
            foreach($AdminAccount in $SQLSysAdminAccounts)
            {
                $Arguments += " `"$AdminAccount`""
            }
        }
        if($SecurityMode -eq "SQL")
        {
            $Arguments += " /SAPwd=" + $SAPwd.GetNetworkCredential().Password
        }
    }
    if($Features.Contains("AS"))
    {
        $Arguments += " /ASSysAdminAccounts=`"" + $SetupCredential.UserName + "`""
        if($PSBoundParameters.ContainsKey("ASSysAdminAccounts"))
        {
            foreach($AdminAccount in $ASSysAdminAccounts)
            {
                $Arguments += " `"$AdminAccount`""
            }
        }
    }

    # Replace sensitive values for verbose output
    $Log = $Arguments
    if($SecurityMode -eq "SQL")
    {
        $Log = $Log.Replace($SAPwd.GetNetworkCredential().Password,"********")
    }
    if($PID -ne "")
    {
        $Log = $Log.Replace($PID,"*****-*****-*****-*****-*****")
    }
    $LogVars = @("AgtSvcAccount","SQLSvcAccount","FTSvcAccount","RSSvcAccount","ASSvcAccount","ISSvcAccount")
    foreach($LogVar in $LogVars)
    {
        if($PSBoundParameters.ContainsKey($LogVar))
        {
            $Log = $Log.Replace((Get-Variable -Name $LogVar).Value.GetNetworkCredential().Password,"********")
        }
    }
    Write-Verbose "Arguments: $Log"

    NetUse -SourcePath $SourcePath -Credential $SetupCredential -Ensure "Present"
    $Process = StartWin32Process -Path $Path -Arguments $Arguments
    Write-Verbose $Process
    WaitForWin32ProcessEnd -Path $Path -Arguments $Arguments
    NetUse -SourcePath $SourcePath -Credential $SetupCredential -Ensure "Absent"

    if((Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -Name 'PendingFileRenameOperations' -ErrorAction SilentlyContinue) -ne $null)
    {
        $global:DSCMachineStatus = 1
    }
    else
    {
        if(!(Test-TargetResource -SourcePath $SourcePath -SourceFolder $SourceFolder -SetupCredential $SetupCredential -Features $Features -InstanceName $InstanceName))
        {
            throw "Set-TargetResouce failed"
        }
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $SourcePath,

        [System.String]
        $SourceFolder = "\SQLServer2012.en",

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $SetupCredential,

        [System.String]
        $Features = "SQLENGINE",

        [parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [System.String]
        $InstanceID,

        [System.String]
        $PID,

        [System.String]
        $UpdateEnabled = "True",

        [System.String]
        $UpdateSource = ".\Updates",

        [System.String]
        $SQMReporting,

        [System.String]
        $ErrorReporting,

        [System.String]
        $InstallSharedDir,

        [System.String]
        $InstallSharedWOWDir,

        [System.String]
        $InstanceDir,

        [System.Management.Automation.PSCredential]
        $SQLSvcAccount,

        [System.Management.Automation.PSCredential]
        $AgtSvcAccount,

        [System.String]
        $SQLCollation,

        [System.String[]]
        $SQLSysAdminAccounts,

        [System.String]
        $SecurityMode,

        [System.Management.Automation.PSCredential]
        $SAPwd,

        [System.String]
        $InstallSQLDataDir,

        [System.String]
        $SQLUserDBDir,

        [System.String]
        $SQLUserDBLogDir,

        [System.String]
        $SQLTempDBDir,

        [System.String]
        $SQLTempDBLogDir,

        [System.String]
        $SQLBackupDir,

        [System.Management.Automation.PSCredential]
        $FTSvcAccount,

        [System.Management.Automation.PSCredential]
        $RSSvcAccount,

        [System.Management.Automation.PSCredential]
        $ASSvcAccount,

        [System.String]
        $ASCollation,

        [System.String]
        $ASSERVERMODE,

        [System.String[]]
        $ASSysAdminAccounts,

        [System.String]
        $ASDataDir,

        [System.String]
        $ASLogDir,

        [System.String]
        $ASBackupDir,

        [System.String]
        $ASTempDir,

        [System.String]
        $ASConfigDir,

        [System.Management.Automation.PSCredential]
        $ISSvcAccount
    )

    $SQLData = Get-TargetResource -SourcePath $SourcePath -SourceFolder $SourceFolder -SetupCredential $SetupCredential -Features $Features -InstanceName $InstanceName

    $result = $true
    foreach($Feature in $Features.Split(","))
    {
        if(!($SQLData.Features.Contains($Feature)))
        {
            $result = $false
        }
    }

    $result
}


function GetSQLVersion
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [String]
        $Path
    )

    (Get-Item -Path $Path).VersionInfo.ProductVersion.Split(".")[0]
}


function GetFirstItemPropertyValue
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [String]
        $Path,

        [Parameter(Mandatory=$true)]
        [String]
        $Name
    )

    if(Get-ItemProperty -Path "$Path\$Name" -ErrorAction SilentlyContinue)
    {
        $FirstName = ((Get-ItemProperty -Path "$Path\$Name") | Get-Member -MemberType NoteProperty | Where-Object {$_.Name.Substring(0,2) -ne "PS"}).Name[0]
        (Get-ItemProperty -Path "$Path\$Name" -Name $FirstName).$FirstName.TrimEnd("\")
    }
}


Export-ModuleMember -Function *-TargetResource
