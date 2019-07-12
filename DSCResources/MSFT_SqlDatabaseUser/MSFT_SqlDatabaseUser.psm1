$script:resourceModulePath = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
$script:modulesFolderPath = Join-Path -Path $script:resourceModulePath -ChildPath 'Modules'

$script:localizationModulePath = Join-Path -Path $script:modulesFolderPath -ChildPath 'DscResource.LocalizationHelper'
Import-Module -Name (Join-Path -Path $script:localizationModulePath -ChildPath 'DscResource.LocalizationHelper.psm1')

$script:resourceHelperModulePath = Join-Path -Path $script:modulesFolderPath -ChildPath 'DscResource.Common'
Import-Module -Name (Join-Path -Path $script:resourceHelperModulePath -ChildPath 'DscResource.Common.psm1')

$script:localizedData = Get-LocalizedData -ResourceName 'MSFT_SqlDatabaseUser'

<#
    .SYNOPSIS
        Returns the current state of the user in a database.

    .PARAMETER ServerName
        Specifies the SQL server to be configured.

    .PARAMETER InstanceName
        Specifies the SQL instance to be configured.

    .PARAMETER Database
        Specifies the name of the database to configure the user in.

    .PARAMETER LoginName
        Specifies the name of the SQL login to associate with the database user.

    .PARAMETER Name
        Specifies the name of the database user.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Database,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $LoginName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name
    )

    Write-Verbose -Message (
        $script:localizedData.GetDatabaseUserProperties -f $Name, $Database
    )

    $sqlServerObject = Connect-SQL -ServerName $ServerName -InstanceName $InstanceName
    if ($sqlServerObject)
    {
        # Check if database exists.
        if (-not ($sqlDatabaseObject = $sqlServerObject.Databases[$Database]))
        {
            $errorMessage = $script:localizedData.DatabaseNotFound -f $Database
            New-ObjectNotFoundException -Message $errorMessage
        }

        # Check if login exists and throw an error only if we want it to exist.
        if (-not ($sqlServerObject.Logins[$LoginName]) -and $Ensure -eq 'Present')
        {
            $errorMessage = $script:localizedData.SqlLoginNotFound -f $LoginName
            New-ObjectNotFoundException -Message $errorMessage
        }

        $userInDesiredState = $false
        $userStatus = 'Absent'

        if ($sqlUserObject = $sqlDatabaseObject.Users[$Name])
        {
            $userStatus = 'Present'

            if ($null -ne $sqlUserObject.Sid -and $null -ne $sqlUserObject.Login -and $sqlUserObject.Login -eq $LoginName)
            {
                $userInDesiredState = $true
            }
        }
    }

    $returnValue = @{
        ServerName         = $ServerName
        InstanceName       = $InstanceName
        Database           = $Database
        LoginName          = $LoginName
        Name               = $Name
        UserInDesiredState = $userInDesiredState
        Ensure             = $userStatus
    }

    $returnValue
}

<#
    .SYNOPSIS
        If 'Present' (the default value) then the user will be added to the database(s) and, if needed, the login
        mapping will be updated. If 'Absent' then the user will be removed from the database(s).

    .PARAMETER ServerName
        Specifies the SQL server to be configured.

    .PARAMETER InstanceName
        Specifies the SQL instance to be configured.

    .PARAMETER Database
        Specifies the name of the database to configure the user in.

    .PARAMETER LoginName
        Specifies the name of the SQL login to associate with the database user.

    .PARAMETER Name
        Specifies the name of the database user.

    .PARAMETER Ensure
        Specifies the desired state of the user.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Database,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $LoginName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    Write-Verbose -Message (
        $script:localizedData.SetDatabaseUser -f $Name, $Database
    )

    $sqlServerObject = Connect-SQL -ServerName $ServerName -InstanceName $InstanceName
    if ($sqlServerObject)
    {
        $sqlDatabaseObject = $sqlServerObject.Databases[$Database]

        switch ($Ensure)
        {
            'Present'
            {
                if ($sqlUserObject = $sqlDatabaseObject.Users[$Name])
                {
                    if (($null -ne $sqlUserObject.Sid -and $null -eq $sqlUserObject.Login) -or
                        ($null -ne $sqlUserObject.Sid -and $null -ne $sqlUserObject.Login -and $sqlUserObject.Login -ne $LoginName))
                    {
                        try
                        {
                            Write-Verbose -Message (
                                $script:localizedData.UpdateDatabaseUser -f $Name, $LoginName, $Database
                            )
                            $updateUserLoginStatement = "EXEC sp_change_users_login 'UPDATE_ONE', '$Name', '$LoginName'"
                            $sqlDatabaseObject.ExecuteNonQuery($updateUserLoginStatement)
                        }
                        catch
                        {
                            $errorMessage = $script:localizedData.UpdateDatabaseUserError -f $Name, $LoginName, $Database
                            New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
                        }
                    }
                }
                else
                {
                    try
                    {
                        Write-Verbose -Message (
                            $script:localizedData.CreateDatabaseUser -f $Name, $LoginName, $Database
                        )
                        $createUserStatement = "CREATE USER [$Name] FOR LOGIN [$LoginName];"
                        $sqlDatabaseObject.ExecuteNonQuery($createUserStatement)
                    }
                    catch
                    {
                        $errorMessage = $script:localizedData.CreateDatabaseUserError -f $Name, $LoginName, $Database
                        New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
                    }
                }
            }

            'Absent'
            {
                if ($sqlUserObject = $sqlDatabaseObject.Users[$Name])
                {
                    try
                    {
                        Write-Verbose -Message (
                            $script:localizedData.DropDatabaseUser -f $Name, $Database
                        )
                        $dropDatabaseUserStatement = "DROP USER [$Name];"
                        $sqlDatabaseObject.ExecuteNonQuery($dropDatabaseUserStatement)
                    }
                    catch
                    {
                        $errorMessage = $script:localizedData.DropDatabaseUserError -f $Name, $Database
                        New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
                    }
                }
            }
        }
    }
}

<#
    .SYNOPSIS
        Tests the current state of the user in a database.

    .PARAMETER ServerName
        Specifies the SQL server to be configured.

    .PARAMETER InstanceName
        Specifies the SQL instance to be configured.

    .PARAMETER Database
        Specifies the name of the database to configure the user in.

    .PARAMETER LoginName
        Specifies the name of the SQL login to associate with the database user.

    .PARAMETER Name
        Specifies the name of the database user.

    .PARAMETER Ensure
        Specifies the desired state of the user.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Database,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $LoginName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    Write-Verbose -Message (
        $script:localizedData.TestDatabaseUser -f $Name, $Database
    )

    $getTargetResourceParameters = @{
        ServerName   = $PSBoundParameters.ServerName
        InstanceName = $PSBoundParameters.InstanceName
        Database     = $PSBoundParameters.Database
        LoginName    = $PSBoundParameters.LoginName
        Name         = $PSBoundParameters.Name
    }

    $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

    <#
        There is no need to evaluate the parameter Permissions here.
        In the Get-TargetResource function there is a test to verify if Permissions is in
        desired state. If the permissions are correct, then Get-TargetResource will return
        the value 'Present' for the Ensure parameter, otherwise Ensure will have the value
        'Absent'.
    #>
    return Test-DscParameterState -CurrentValues $getTargetResourceResult `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck @('LoginName', 'Name', 'Ensure')
}

Export-ModuleMember -Function *-TargetResource
