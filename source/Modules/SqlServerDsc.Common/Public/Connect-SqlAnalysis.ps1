<#
    .SYNOPSIS
        Connect to a SQL Server Analysis Service and return the server object.

    .PARAMETER ServerName
        String containing the host name of the SQL Server to connect to.

    .PARAMETER InstanceName
        String containing the SQL Server Analysis Service instance to connect to.

    .PARAMETER SetupCredential
        PSCredential object with the credentials to use to impersonate a user when
        connecting. If this is not provided then the current user will be used to
        connect to the SQL Server Analysis Service instance.
#>
function Connect-SqlAnalysis
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = (Get-ComputerName),

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstanceName = 'MSSQLSERVER',

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $SetupCredential,

        [Parameter()]
        [System.String[]]
        $FeatureFlag
    )

    if ($InstanceName -eq 'MSSQLSERVER')
    {
        $analysisServiceInstance = $ServerName
    }
    else
    {
        $analysisServiceInstance = "$ServerName\$InstanceName"
    }

    if ($SetupCredential)
    {
        $userName = $SetupCredential.UserName
        $password = $SetupCredential.GetNetworkCredential().Password

        $analysisServicesDataSource = "Data Source=$analysisServiceInstance;User ID=$userName;Password=$password"
    }
    else
    {
        $analysisServicesDataSource = "Data Source=$analysisServiceInstance"
    }

    try
    {
        if ((Test-FeatureFlag -FeatureFlag $FeatureFlag -TestFlag 'AnalysisServicesConnection'))
        {
            Import-SqlDscPreferredModule

            $analysisServicesObject = New-Object -TypeName 'Microsoft.AnalysisServices.Server'

            if ($analysisServicesObject)
            {
                $analysisServicesObject.Connect($analysisServicesDataSource)
            }

            if ((-not $analysisServicesObject) -or ($analysisServicesObject -and $analysisServicesObject.Connected -eq $false))
            {
                $errorMessage = $script:localizedData.FailedToConnectToAnalysisServicesInstance -f $analysisServiceInstance

                New-InvalidOperationException -Message $errorMessage
            }
            else
            {
                Write-Verbose -Message ($script:localizedData.ConnectedToAnalysisServicesInstance -f $analysisServiceInstance) -Verbose
            }
        }
        else
        {
            $null = Import-Assembly -Name 'Microsoft.AnalysisServices' -LoadWithPartialName

            $analysisServicesObject = New-Object -TypeName 'Microsoft.AnalysisServices.Server'

            if ($analysisServicesObject)
            {
                $analysisServicesObject.Connect($analysisServicesDataSource)
            }
            else
            {
                $errorMessage = $script:localizedData.FailedToConnectToAnalysisServicesInstance -f $analysisServiceInstance

                New-InvalidOperationException -Message $errorMessage
            }

            Write-Verbose -Message ($script:localizedData.ConnectedToAnalysisServicesInstance -f $analysisServiceInstance) -Verbose
        }
    }
    catch
    {
        $errorMessage = $script:localizedData.FailedToConnectToAnalysisServicesInstance -f $analysisServiceInstance

        New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
    }

    return $analysisServicesObject
}
