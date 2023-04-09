$script:sqlServerDscHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\SqlServerDsc.Common'
$script:resourceHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DscResource.Common'

Import-Module -Name $script:sqlServerDscHelperModulePath
Import-Module -Name $script:resourceHelperModulePath

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

<#
    .SYNOPSIS
        Returns the current state of what the Get-script returns.

    .PARAMETER InstanceName
        Specifies the name of the SQL Server Database Engine instance. For the
        default instance specify 'MSSQLSERVER'.

    .PARAMETER SetFilePath
        Path to the T-SQL file that will perform Set action.

    .PARAMETER GetFilePath
        Path to the T-SQL file that will perform Get action.
        Any values returned by the T-SQL queries will also be returned by the cmdlet Get-DscConfiguration through the `GetResult` property.

    .PARAMETER TestFilePath
        Path to the T-SQL file that will perform Test action.
        Any script that does not throw an error or returns null is evaluated to true.
        The cmdlet `Invoke-SqlCmd` treats T-SQL Print statements as verbose text, and will not cause the test to return false.

    .PARAMETER ServerName
        Specifies the host name of the SQL Server to be configured. Default value
        is the current computer name.

    .PARAMETER Credential
        The credentials to authenticate with, using SQL Authentication. To authenticate using Windows Authentication, assign the credentials
        to the built-in parameter `PsDscRunAsCredential`. If both parameters `Credential` and `PsDscRunAsCredential` are not assigned,
        then SYSTEM account will be used to authenticate using Windows Authentication.

    .PARAMETER Variable
        Specifies, as a string array, a `Invoke-SqlCmd` scripting variable for use in the `Invoke-SqlCmd` script, and sets a value for the variable.
        Use a Windows PowerShell array to specify multiple variables and their values. For more information how to use this,
        please go to the help documentation for [`Invoke-SqlCmd`](https://docs.microsoft.com/en-us/powershell/module/sqlserver/Invoke-SqlCmd).

    .PARAMETER DisableVariables
        Specifies, as a boolean, whether or not PowerShell will ignore `Invoke-SqlCmd` scripting variables that share a format such as $(variable_name).
        For more information how to use this, please go to the help documentation for [`Invoke-SqlCmd`](https://docs.microsoft.com/en-us/powershell/module/sqlserver/Invoke-SqlCmd)")]

    .PARAMETER QueryTimeout
        Specifies, as an integer, the number of seconds after which the T-SQL script execution will time out.
        In some SQL Server versions there is a bug in `Invoke-SqlCmd` where the normal default value 0 (no timeout) is not respected and the default value is incorrectly set to 30 seconds.

    .PARAMETER Encrypt
        Specifies how encryption should be enforced when using command `Invoke-SqlCmd`.
        When not specified, the default value is `Mandatory`.

        This value maps to the Encrypt property SqlConnectionEncryptOption
        on the SqlConnection object of the Microsoft.Data.SqlClient driver.

        This parameter can only be used when the module SqlServer v22.x.x is installed.

    .OUTPUTS
        Hash table containing key 'GetResult' which holds the value of the result from the SQL script that was ran from the parameter 'GetFilePath'.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SetFilePath,

        [Parameter(Mandatory = $true)]
        [System.String]
        $GetFilePath,

        [Parameter(Mandatory = $true)]
        [System.String]
        $TestFilePath,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = (Get-ComputerName),

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        [Parameter()]
        [System.UInt32]
        $QueryTimeout,

        [Parameter()]
        [System.String[]]
        $Variable,

        [Parameter()]
        [System.Boolean]
        $DisableVariables,

        [Parameter()]
        [ValidateSet('Mandatory', 'Optional', 'Strict')]
        [System.String]
        $Encrypt
    )

    Write-Verbose -Message (
        $script:localizedData.ExecutingGetScript -f $GetFilePath, $InstanceName, $ServerName
    )

    Import-SqlDscPreferredModule

    $invokeSqlCmdParameters = Get-InvokeSqlCmdParameter -BoundParameters $PSBoundParameters

    $result = Invoke-SqlCmd @invokeSqlCmdParameters

    $getResult = Out-String -InputObject $result

    $returnValue = @{
        ServerName       = [System.String] $ServerName
        InstanceName     = [System.String] $InstanceName
        SetFilePath      = [System.String] $SetFilePath
        GetFilePath      = [System.String] $GetFilePath
        TestFilePath     = [System.String] $TestFilePath
        Credential       = [System.Object] $Credential
        QueryTimeout     = [System.UInt32] $QueryTimeout
        Variable         = [System.String[]] $Variable
        DisableVariables = [System.Boolean] $DisableVariables
        GetResult        = [System.String[]] $getResult
        Encrypt          = [System.String] $Encrypt
    }

    return $returnValue
}

<#
    .SYNOPSIS
        Executes the Set-script.

    .PARAMETER InstanceName
        Specifies the name of the SQL Server Database Engine instance. For the
        default instance specify 'MSSQLSERVER'.

    .PARAMETER SetFilePath
        Path to the T-SQL file that will perform Set action.

    .PARAMETER GetFilePath
        Path to the T-SQL file that will perform Get action.
        Any values returned by the T-SQL queries will also be returned by the cmdlet Get-DscConfiguration through the `GetResult` property.

        Not used in Set-TargetResource.

    .PARAMETER TestFilePath
        Path to the T-SQL file that will perform Test action.
        Any script that does not throw an error or returns null is evaluated to true.
        The cmdlet `Invoke-SqlCmd` treats T-SQL Print statements as verbose text, and will not cause the test to return false.

        Not used in Set-TargetResource.

    .PARAMETER ServerName
        Specifies the host name of the SQL Server to be configured. Default value
        is the current computer name.

    .PARAMETER Credential
        The credentials to authenticate with, using SQL Authentication. To authenticate using Windows Authentication, assign the credentials
        to the built-in parameter `PsDscRunAsCredential`. If both parameters `Credential` and `PsDscRunAsCredential` are not assigned,
        then SYSTEM account will be used to authenticate using Windows Authentication.

    .PARAMETER QueryTimeout
        Specifies, as an integer, the number of seconds after which the T-SQL script execution will time out.
        In some SQL Server versions there is a bug in `Invoke-SqlCmd` where the normal default value 0 (no timeout) is not respected and the default value is incorrectly set to 30 seconds.

    .PARAMETER Variable
        Specifies, as a string array, a `Invoke-SqlCmd` scripting variable for use in the `Invoke-SqlCmd` script, and sets a value for the variable.
        Use a Windows PowerShell array to specify multiple variables and their values. For more information how to use this,
        please go to the help documentation for [`Invoke-SqlCmd`](https://docs.microsoft.com/en-us/powershell/module/sqlserver/Invoke-SqlCmd).

    .PARAMETER DisableVariables
        Specifies, as a boolean, whether or not PowerShell will ignore `Invoke-SqlCmd` scripting variables that share a format such as $(variable_name).
        For more information how to use this, please go to the help documentation for [`Invoke-SqlCmd`](https://docs.microsoft.com/en-us/powershell/module/sqlserver/Invoke-SqlCmd)")]

    .PARAMETER Encrypt
        Specifies how encryption should be enforced when using command `Invoke-SqlCmd`.
        When not specified, the default value is `Mandatory`.

        This value maps to the Encrypt property SqlConnectionEncryptOption
        on the SqlConnection object of the Microsoft.Data.SqlClient driver.

        This parameter can only be used when the module SqlServer v22.x.x is installed.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SetFilePath,

        [Parameter(Mandatory = $true)]
        [System.String]
        $GetFilePath,

        [Parameter(Mandatory = $true)]
        [System.String]
        $TestFilePath,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = (Get-ComputerName),

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        [Parameter()]
        [System.UInt32]
        $QueryTimeout,

        [Parameter()]
        [System.String[]]
        $Variable,

        [Parameter()]
        [System.Boolean]
        $DisableVariables,

        [Parameter()]
        [ValidateSet('Mandatory', 'Optional', 'Strict')]
        [System.String]
        $Encrypt
    )

    Write-Verbose -Message (
        $script:localizedData.ExecutingSetScript -f $SetFilePath, $InstanceName, $ServerName
    )

    Import-SqlDscPreferredModule

    $invokeSqlCmdParameters = Get-InvokeSqlCmdParameter -BoundParameters $PSBoundParameters

    Invoke-SqlCmd @invokeSqlCmdParameters | Out-Null
}

<#
    .SYNOPSIS
        Evaluates the value returned from the Test-script.

    .PARAMETER InstanceName
        Specifies the name of the SQL Server Database Engine instance. For the
        default instance specify 'MSSQLSERVER'.

    .PARAMETER SetFilePath
        Path to the T-SQL file that will perform Set action.

        Not used in Test-TargetResource.

    .PARAMETER GetFilePath
        Path to the T-SQL file that will perform Get action.
        Any values returned by the T-SQL queries will also be returned by the cmdlet Get-DscConfiguration through the `GetResult` property.

        Not used in Test-TargetResource.

    .PARAMETER TestFilePath
        Path to the T-SQL file that will perform Test action.
        Any script that does not throw an error or returns null is evaluated to true.
        The cmdlet `Invoke-SqlCmd` treats T-SQL Print statements as verbose text, and will not cause the test to return false.

    .PARAMETER ServerName
        Specifies the host name of the SQL Server to be configured. Default value
        is the current computer name.

    .PARAMETER Credential
        The credentials to authenticate with, using SQL Authentication. To authenticate using Windows Authentication, assign the credentials
        to the built-in parameter `PsDscRunAsCredential`. If both parameters `Credential` and `PsDscRunAsCredential` are not assigned,
        then SYSTEM account will be used to authenticate using Windows Authentication.

    .PARAMETER QueryTimeout
        Specifies, as an integer, the number of seconds after which the T-SQL script execution will time out.
        In some SQL Server versions there is a bug in `Invoke-SqlCmd` where the normal default value 0 (no timeout) is not respected and the default value is incorrectly set to 30 seconds.

    .PARAMETER Variable
        Specifies, as a string array, a `Invoke-SqlCmd` scripting variable for use in the `Invoke-SqlCmd` script, and sets a value for the variable.
        Use a Windows PowerShell array to specify multiple variables and their values. For more information how to use this,
        please go to the help documentation for [`Invoke-SqlCmd`](https://docs.microsoft.com/en-us/powershell/module/sqlserver/Invoke-SqlCmd).

    .PARAMETER DisableVariables
        Specifies, as a boolean, whether or not PowerShell will ignore `Invoke-SqlCmd` scripting variables that share a format such as $(variable_name).
        For more information how to use this, please go to the help documentation for [`Invoke-SqlCmd`](https://docs.microsoft.com/en-us/powershell/module/sqlserver/Invoke-SqlCmd).

    .PARAMETER Encrypt
        Specifies how encryption should be enforced when using command `Invoke-SqlCmd`.
        When not specified, the default value is `Mandatory`.

        This value maps to the Encrypt property SqlConnectionEncryptOption
        on the SqlConnection object of the Microsoft.Data.SqlClient driver.

        This parameter can only be used when the module SqlServer v22.x.x is installed.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SetFilePath,

        [Parameter(Mandatory = $true)]
        [System.String]
        $GetFilePath,

        [Parameter(Mandatory = $true)]
        [System.String]
        $TestFilePath,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = (Get-ComputerName),

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        [Parameter()]
        [System.UInt32]
        $QueryTimeout,

        [Parameter()]
        [System.String[]]
        $Variable,

        [Parameter()]
        [System.Boolean]
        $DisableVariables,

        [Parameter()]
        [ValidateSet('Mandatory', 'Optional', 'Strict')]
        [System.String]
        $Encrypt
    )

    Write-Verbose -Message (
        $script:localizedData.TestingConfiguration
    )

    Import-SqlDscPreferredModule

    $invokeSqlCmdParameters = Get-InvokeSqlCmdParameter -BoundParameters $PSBoundParameters

    $result = $null

    try
    {
        Write-Verbose -Message (
            $script:localizedData.ExecutingTestScript -f $TestFilePath, $InstanceName, $ServerName
        )

        $result = Invoke-SqlCmd @invokeSqlCmdParameters
    }
    catch [Microsoft.SqlServer.Management.PowerShell.SqlPowerShellSqlExecutionException]
    {
        Write-Verbose $_

        return $false
    }

    if ($null -eq $result)
    {
        Write-Verbose -Message (
            $script:localizedData.InDesiredState
        )

        return $true
    }
    else
    {
        Write-Verbose -Message (
            $script:localizedData.NotInDesiredState
        )

        return $false
    }
}

<#
    .SYNOPSIS
        Returns the parameters that should be used to call Invoke-SqlCmd.

    .PARAMETER BoundParameters
        Specifies the parameters that was bound when the resource was called.

    .NOTES
        When this resource is refactored into a class-based resource, this function
        should be moved to a method in a base class.

        Parameter `Encrypt` controls whether the connection used by `Invoke-SqlCmd`
        should enforce encryption. This parameter can only be used together with the
        module _SqlServer_ v22.x (minimum v22.0.49-preview). The parameter will be
        ignored if an older major versions of the module _SqlServer_ is used.
        Encryption is mandatory by default, which generates the following exception
        when the correct certificates are not present:

        "A connection was successfully established with the server, but then
        an error occurred during the login process. (provider: SSL Provider,
        error: 0 - The certificate chain was issued by an authority that is
        not trusted.)"

        For more details, see the article [Connect to SQL Server with strict encryption](https://learn.microsoft.com/en-us/sql/relational-databases/security/networking/connect-with-strict-encryption?view=sql-server-ver16)
        and [Configure SQL Server Database Engine for encrypting connections](https://learn.microsoft.com/en-us/sql/database-engine/configure-windows/configure-sql-server-encryption?view=sql-server-ver16).
#>
function Get-InvokeSqlCmdParameter
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]
        $BoundParameters
    )

    $serverInstance = ConvertTo-ServerInstanceName -InstanceName $BoundParameters.InstanceName -ServerName $BoundParameters.ServerName

    $invokeSqlCmdParameters = @{
        ServerInstance = $serverInstance
        InputFile      = $BoundParameters.GetFilePath
        Verbose        = $VerbosePreference
        ErrorAction    = 'Stop'
    }

    if ($BoundParameters.ContainsKey('Credential'))
    {
        $invokeSqlCmdParameters.Credential = $BoundParameters.Credential
    }

    if ($BoundParameters.ContainsKey('Variable'))
    {
        $invokeSqlCmdParameters.Variable = $BoundParameters.Variable
    }

    if ($BoundParameters.ContainsKey('DisableVariables'))
    {
        $invokeSqlCmdParameters.DisableVariables = $BoundParameters.DisableVariables
    }

    if ($BoundParameters.ContainsKey('QueryTimeout'))
    {
        $invokeSqlCmdParameters.QueryTimeout = $BoundParameters.QueryTimeout
    }

    if ($BoundParameters.ContainsKey('Encrypt'))
    {
        $commandInvokeSqlCmd = Get-Command -Name 'Invoke-SqlCmd'

        if ($null -ne $commandInvokeSqlCmd -and $commandInvokeSqlCmd.Parameters.Keys -contains 'Encrypt')
        {
            $invokeSqlCmdParameters.Encrypt = $BoundParameters.Encrypt
        }
    }

    return $invokeSqlCmdParameters
}
