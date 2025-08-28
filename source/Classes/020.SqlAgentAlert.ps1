<#
    .SYNOPSIS
        The `SqlAgentAlert` DSC resource is used to create, modify, or remove
        _SQL Server Agent_ alerts.

    .DESCRIPTION
        The `SqlAgentAlert` DSC resource is used to create, modify, or remove
        _SQL Server Agent_ alerts.

        An alert can be switched between a system-message–based alert and a severity-based
        alert by specifying the corresponding parameter. The alert type will be switched
        accordingly.

        The built-in parameter **PSDscRunAsCredential** can be used to run the resource
        as another user. The resource will then authenticate to the _SQL Server_
        instance as that user. It is also possible to use impersonation via the
        **Credential** parameter.

        ## Requirements

        * Target machine must be running Windows Server 2012 or later.
        * Target machine must be running SQL Server Database Engine 2012 or later.
        * Target machine must have access to the SQLPS PowerShell module or the SqlServer
          PowerShell module.

        ## Known issues

        All issues are not listed here, see [here for all open issues](https://github.com/dsccommunity/SqlServerDsc/issues?q=is%3Aissue+is%3Aopen+in%3Atitle+SqlAgentAlert).

        ### Property **Reasons** does not work with **PSDscRunAsCredential**

        When using the built-in parameter **PSDscRunAsCredential** the read-only
        property **Reasons** will return empty values for the properties **Code**
        and **Phrase**. The built-in property **PSDscRunAsCredential** does not work
        together with class-based resources that use advanced types, such as the
        **Reasons** parameter.

        ### Using **Credential** property

        SQL Authentication and Group Managed Service Accounts are not supported as
        impersonation credentials. Currently, only Windows Integrated Security is
        supported.

        For Windows Authentication the username must either be provided with the User
        Principal Name (UPN), e.g., `username@domain.local`, or, if using a non‑domain
        account (for example, a local Windows Server account), the username must be
        provided without the NetBIOS name, e.g., `username`. Using the NetBIOS name,
        for example `DOMAIN\username`, will not work.

        See more information in [Credential Overview](https://github.com/dsccommunity/SqlServerDsc/wiki/CredentialOverview).

    .PARAMETER Name
        The name of the _SQL Server Agent_ alert.

    .PARAMETER Ensure
        Specifies if the _SQL Server Agent_ alert should be present or absent.
        Default value is `'Present'`.

    .PARAMETER Severity
        The severity of the _SQL Server Agent_ alert. Valid range is 1 to 25.
        Cannot be used together with **MessageId**.

    .PARAMETER MessageId
        The message id of the _SQL Server Agent_ alert. Valid range is 1 to 2147483647.
        Cannot be used together with **Severity**.

    .EXAMPLE
        Invoke-DscResource -ModuleName SqlServerDsc -Name SqlAgentAlert -Method Get -Property @{
            InstanceName = 'MSSQLSERVER'
            Name         = 'Alert1'
        }

        This example shows how to get the current state of the _SQL Server Agent_
        alert named **Alert1**.

    .EXAMPLE
        Invoke-DscResource -ModuleName SqlServerDsc -Name SqlAgentAlert -Method Test -Property @{
            InstanceName = 'MSSQLSERVER'
            Name         = 'Alert1'
            Ensure       = 'Present'
            Severity     = 16
        }

        This example shows how to test if the _SQL Server Agent_ alert named
        **Alert1** is in the desired state.

    .EXAMPLE
        Invoke-DscResource -ModuleName SqlServerDsc -Name SqlAgentAlert -Method Set -Property @{
            InstanceName = 'MSSQLSERVER'
            Name         = 'Alert1'
            Ensure       = 'Present'
            Severity     = 16
        }

        This example shows how to set the desired state for the _SQL Server Agent_
        alert named **Alert1** with severity level 16.

    .EXAMPLE
        Invoke-DscResource -ModuleName SqlServerDsc -Name SqlAgentAlert -Method Set -Property @{
            InstanceName = 'MSSQLSERVER'
            Name         = 'Alert1'
            Ensure       = 'Present'
            MessageId    = 50001
        }

        This example shows how to set the desired state for the _SQL Server Agent_
        alert named **Alert1** with message ID 50001.

    .EXAMPLE
        Invoke-DscResource -ModuleName SqlServerDsc -Name SqlAgentAlert -Method Set -Property @{
            InstanceName = 'MSSQLSERVER'
            Name         = 'Alert1'
            Ensure       = 'Absent'
        }

        This example shows how to remove the _SQL Server Agent_ alert named
        **Alert1**.
#>
[DscResource(RunAsCredential = 'Optional')]
class SqlAgentAlert : SqlResourceBase
{
    [DscProperty(Key)]
    [System.String]
    $Name

    [DscProperty()]
    [ValidateSet('Present', 'Absent')]
    [System.String]
    $Ensure = 'Present'

    [DscProperty()]
    [ValidateRange(1, 25)]
    [Nullable[System.Int32]]
    $Severity

    [DscProperty()]
    [ValidateRange(1, 2147483647)]
    [Nullable[System.Int32]]
    $MessageId

    SqlAgentAlert () : base ()
    {
        # Property names that cannot be enforced
        $this.ExcludeDscProperties = @(
            'InstanceName',
            'ServerName',
            'Credential'
            'Name'
        )
    }

    [SqlAgentAlert] Get()
    {
        # Call base implementation to get current state
        $currentState = ([ResourceBase] $this).Get()

        return $currentState
    }

    [System.Boolean] Test()
    {
        # Call base implementation to test current state
        $inDesiredState = ([ResourceBase] $this).Test()

        return $inDesiredState
    }

    [void] Set()
    {
        # Call base implementation to set desired state
        ([ResourceBase] $this).Set()
    }

    hidden [void] AssertProperties([System.Collections.Hashtable] $properties)
    {
        # Validate that at least one of Severity or MessageId is specified
        $assertAtLeastOneParams = @{
            BoundParameterList   = $properties
            AtLeastOneList       = @('Severity', 'MessageId')
            IfEqualParameterList = @{
                Ensure = 'Present'
            }
        }

        Assert-BoundParameter @assertAtLeastOneParams

        # Validate that both Severity and MessageId are not specified
        $assertMutuallyExclusiveParams = @{
            BoundParameterList       = $properties
            MutuallyExclusiveList1   = @('Severity')
            MutuallyExclusiveList2   = @('MessageId')
            IfEqualParameterList     = @{
                Ensure = 'Present'
            }
        }

        Assert-BoundParameter @assertMutuallyExclusiveParams

        # When Ensure is 'Absent', Severity and MessageId must not be set
        $assertAbsentParams = @{
            BoundParameterList   = $properties
            NotAllowedList       = @('Severity', 'MessageId')
            IfEqualParameterList = @{
                Ensure = 'Absent'
            }
        }

        Assert-BoundParameter @assertAbsentParams
    }

    hidden [System.Collections.Hashtable] GetCurrentState([System.Collections.Hashtable] $properties)
    {
        $serverObject = $this.GetServerObject()

        Write-Verbose -Message ($this.localizedData.SqlAgentAlert_GettingCurrentState -f $this.Name, $this.InstanceName)

        $currentState = @{
            InstanceName = $this.InstanceName
            ServerName   = $this.ServerName
            Name         = $this.Name
            Ensure       = 'Absent'
        }

        $alertObject = $serverObject | Get-SqlDscAgentAlert -Name $this.Name -ErrorAction 'SilentlyContinue'

        if ($alertObject)
        {
            Write-Verbose -Message ($this.localizedData.SqlAgentAlert_AlertExists -f $this.Name)

            $currentState.Ensure = 'Present'

            # Get the current severity and message ID
            if ($alertObject.Severity -gt 0)
            {
                $currentState.Severity = $alertObject.Severity
            }

            if ($alertObject.MessageId -gt 0)
            {
                $currentState.MessageId = $alertObject.MessageId
            }
        }
        else
        {
            Write-Verbose -Message ($this.localizedData.SqlAgentAlert_AlertDoesNotExist -f $this.Name)
        }

        return $currentState
    }

    hidden [void] Modify([System.Collections.Hashtable] $properties)
    {
        $serverObject = $this.GetServerObject()

        if ($this.Ensure -eq 'Present')
        {
            $alertObject = $serverObject | Get-SqlDscAgentAlert -Name $this.Name -ErrorAction 'SilentlyContinue'

            if ($null -eq $alertObject)
            {
                Write-Verbose -Message ($this.localizedData.SqlAgentAlert_CreatingAlert -f $this.Name)

                $newAlertParameters = @{
                    ServerObject = $serverObject
                    Name         = $this.Name
                    ErrorAction  = 'Stop'
                }

                if ($properties.ContainsKey('Severity'))
                {
                    $newAlertParameters.Severity = $properties.Severity
                }

                if ($properties.ContainsKey('MessageId'))
                {
                    $newAlertParameters.MessageId = $properties.MessageId
                }

                $null = New-SqlDscAgentAlert @newAlertParameters
            }
            else
            {
                Write-Verbose -Message ($this.localizedData.SqlAgentAlert_UpdatingAlert -f $this.Name)

                $setAlertParameters = @{
                    AlertObject = $alertObject
                    ErrorAction = 'Stop'
                }

                $needsUpdate = $false

                if ($properties.ContainsKey('Severity') -and $alertObject.Severity -ne $properties.Severity)
                {
                    $setAlertParameters.Severity = $properties.Severity
                    $needsUpdate = $true
                }

                if ($properties.ContainsKey('MessageId') -and $alertObject.MessageId -ne $properties.MessageId)
                {
                    $setAlertParameters.MessageId = $properties.MessageId
                    $needsUpdate = $true
                }

                if ($needsUpdate)
                {
                    $null = Set-SqlDscAgentAlert @setAlertParameters
                }
                else
                {
                    Write-Verbose -Message ($this.localizedData.SqlAgentAlert_NoChangesNeeded -f $this.Name)
                }
            }
        }
        else # Ensure = 'Absent'
        {
            Write-Verbose -Message ($this.localizedData.SqlAgentAlert_RemovingAlert -f $this.Name)

            $null = $serverObject | Remove-SqlDscAgentAlert -Name $this.Name -Force -ErrorAction 'Stop'
        }
    }
}
