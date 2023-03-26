$script:sqlServerDscHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\SqlServerDsc.Common'
$script:resourceHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DscResource.Common'

Import-Module -Name $script:sqlServerDscHelperModulePath
Import-Module -Name $script:resourceHelperModulePath

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

<#
    .SYNOPSIS
        Returns the current state of what the Get-query returns.

    .PARAMETER InstanceName
        Specifies the name of the SQL Server Database Engine instance. For the
        default instance specify 'MSSQLSERVER'.

    .PARAMETER GetQuery
        The full query that will perform the Get Action
        Any values returned by the T-SQL queries will also be returned by the cmdlet Get-DscConfiguration through the `GetResult` property.

    .PARAMETER TestQuery
        The full query that will perform the Test Action
        Any script that does not throw an error or returns null is evaluated to true.
        The cmdlet `Invoke-SqlCmd` treats T-SQL Print statements as verbose text, and will not cause the test to return false.

    .PARAMETER SetQuery
        The full query that will perform the Set Action

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
        For more information how to use this, please go to the help documentation for [`Invoke-SqlCmd`](https://docs.microsoft.com/en-us/powershell/module/sqlserver/Invoke-SqlCmd).

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
        Hash table containing key 'GetResult' which holds the value of the result from the SQL script that was ran from the parameter 'GetQuery'.
#>
function Get-TargetResource
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('SqlServerDsc.AnalyzerRules\Measure-CommandsNeededToLoadSMO', '', Justification='The command Import-SqlDscPreferredModule is implicitly called in Invoke-SqlScript')]
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $GetQuery,

        [Parameter(Mandatory = $true)]
        [System.String]
        $TestQuery,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SetQuery,

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
        $script:localizedData.ExecutingGetQuery -f $InstanceName, $ServerName
    )

    $serverInstance = ConvertTo-ServerInstanceName -InstanceName $InstanceName -ServerName $ServerName

    $invokeParameters = @{
        Query            = $GetQuery
        ServerInstance   = $serverInstance
        Credential       = $Credential
        Variable         = $Variable
        DisableVariables = $DisableVariables
        QueryTimeout     = $QueryTimeout
        Verbose          = $VerbosePreference
        ErrorAction      = 'Stop'
    }

    if ($PSBoundParameters.ContainsKey('Encrypt'))
    {
        $invokeParameters.Encrypt = $Encrypt
    }

    $result = Invoke-SqlScript @invokeParameters

    $getResult = Out-String -InputObject $result

    $returnValue = @{
        ServerName       = [System.String] $ServerName
        InstanceName     = [System.String] $InstanceName
        GetQuery         = [System.String] $GetQuery
        TestQuery        = [System.String] $TestQuery
        SetQuery         = [System.String] $SetQuery
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
        Executes the Set-query.

    .PARAMETER InstanceName
        Specifies the name of the SQL Server Database Engine instance. For the
        default instance specify 'MSSQLSERVER'.

    .PARAMETER GetQuery
        The full query that will perform the Get Action
        Any values returned by the T-SQL queries will also be returned by the cmdlet Get-DscConfiguration through the `GetResult` property.

        Not used in Set-TargetResource.

    .PARAMETER TestQuery
        The full query that will perform the Test Action
        Any script that does not throw an error or returns null is evaluated to true.
        The cmdlet `Invoke-SqlCmd` treats T-SQL Print statements as verbose text, and will not cause the test to return false.

        Not used in Set-TargetResource.

    .PARAMETER SetQuery
        The full query that will perform the Set Action

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
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('SqlServerDsc.AnalyzerRules\Measure-CommandsNeededToLoadSMO', '', Justification='The command Import-SqlDscPreferredModule is implicitly called in Invoke-SqlScript')]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $GetQuery,

        [Parameter(Mandatory = $true)]
        [System.String]
        $TestQuery,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SetQuery,

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
        $script:localizedData.ExecutingSetQuery -f $InstanceName, $ServerName
    )

    $serverInstance = ConvertTo-ServerInstanceName -InstanceName $InstanceName -ServerName $ServerName

    $invokeParameters = @{
        Query            = $SetQuery
        ServerInstance   = $serverInstance
        Credential       = $Credential
        Variable         = $Variable
        DisableVariables = $DisableVariables
        QueryTimeout     = $QueryTimeout
        Verbose          = $VerbosePreference
        ErrorAction      = 'Stop'
    }

    if ($PSBoundParameters.ContainsKey('Encrypt'))
    {
        $invokeParameters.Encrypt = $Encrypt
    }

    Invoke-SqlScript @invokeParameters
}

<#
    .SYNOPSIS
        Evaluates the value returned from the Test-query.

    .PARAMETER InstanceName
        Specifies the name of the SQL Server Database Engine instance. For the
        default instance specify 'MSSQLSERVER'.

    .PARAMETER GetQuery
        The full query that will perform the Get Action
        Any values returned by the T-SQL queries will also be returned by the cmdlet Get-DscConfiguration through the `GetResult` property.

        Not used in Test-TargetResource.

    .PARAMETER TestQuery
        The full query that will perform the Test Action
        Any script that does not throw an error or returns null is evaluated to true.
        The cmdlet `Invoke-SqlCmd` treats T-SQL Print statements as verbose text, and will not cause the test to return false.

    .PARAMETER SetQuery
        The full query that will perform the Set Action

        Not used in Test-TargetResource.

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
function Test-TargetResource
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('SqlServerDsc.AnalyzerRules\Measure-CommandsNeededToLoadSMO', '', Justification='The command Import-SqlDscPreferredModule is implicitly called in Invoke-SqlScript')]
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $GetQuery,

        [Parameter(Mandatory = $true)]
        [System.String]
        $TestQuery,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SetQuery,

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

    $serverInstance = ConvertTo-ServerInstanceName -InstanceName $InstanceName -ServerName $ServerName

    $invokeParameters = @{
        Query            = $TestQuery
        ServerInstance   = $serverInstance
        Credential       = $Credential
        Variable         = $Variable
        DisableVariables = $DisableVariables
        QueryTimeout     = $QueryTimeout
        Verbose          = $VerbosePreference
        ErrorAction      = 'Stop'
    }

    if ($PSBoundParameters.ContainsKey('Encrypt'))
    {
        $invokeParameters.Encrypt = $Encrypt
    }

    $result = $null

    try
    {
        Write-Verbose -Message (
            $script:localizedData.ExecutingTestQuery -f $InstanceName, $ServerName
        )

        $result = Invoke-SqlScript @invokeParameters
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
