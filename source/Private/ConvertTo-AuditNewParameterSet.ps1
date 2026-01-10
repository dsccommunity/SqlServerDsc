<#
    .SYNOPSIS
        Converts audit object properties to parameters for New-SqlDscAudit.

    .DESCRIPTION
        This helper function analyzes an existing audit object and returns a hashtable
        of parameters that can be splatted to New-SqlDscAudit to recreate the audit
        with the same configuration.

    .PARAMETER AuditObject
        The audit object to analyze.

    .PARAMETER AuditGuid
        Optional GUID to set on the audit. If not specified, the existing GUID is used.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine
        $auditObject = $serverObject.Audits['MyAudit']
        $parameters = ConvertTo-AuditNewParameterSet -AuditObject $auditObject

        Converts an existing audit object to a parameter set that can be used with New-SqlDscAudit.

    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine
        $auditObject = $serverObject.Audits['MyAudit']
        $parameters = ConvertTo-AuditNewParameterSet -AuditObject $auditObject -AuditGuid '12345678-1234-1234-1234-123456789012'

        Converts an existing audit object to a parameter set with a custom GUID.

    .INPUTS
        None.

    .OUTPUTS
        `System.Collections.Hashtable`

        Returns a hashtable of parameters for New-SqlDscAudit.
#>
function ConvertTo-AuditNewParameterSet
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [Microsoft.SqlServer.Management.Smo.Audit]
        $AuditObject,

        [Parameter()]
        [System.String]
        $AuditGuid
    )

    $parameters = @{
        ServerObject = $AuditObject.Parent
        Name         = $AuditObject.Name
    }

    # Determine LogType or Path based on DestinationType
    switch ($AuditObject.DestinationType)
    {
        'ApplicationLog'
        {
            $parameters['LogType'] = 'ApplicationLog'
        }

        'SecurityLog'
        {
            $parameters['LogType'] = 'SecurityLog'
        }

        'File'
        {
            $parameters['Path'] = $AuditObject.FilePath

            # Add file size parameters if set (not unlimited)
            if ($AuditObject.MaximumFileSize -gt 0)
            {
                $parameters['MaximumFileSize'] = $AuditObject.MaximumFileSize

                # Convert SMO unit to parameter value
                $parameters['MaximumFileSizeUnit'] = switch ($AuditObject.MaximumFileSizeUnit)
                {
                    'MB'
                    {
                        'Megabyte'
                    }
                    'GB'
                    {
                        'Gigabyte'
                    }
                    'TB'
                    {
                        'Terabyte'
                    }
                }
            }

            # Add MaximumFiles or MaximumRolloverFiles (mutually exclusive)
            if ($AuditObject.MaximumFiles -gt 0)
            {
                $parameters['MaximumFiles'] = $AuditObject.MaximumFiles

                if ($AuditObject.ReserveDiskSpace)
                {
                    $parameters['ReserveDiskSpace'] = $true
                }
            }
            elseif ($AuditObject.MaximumRolloverFiles -gt 0)
            {
                $parameters['MaximumRolloverFiles'] = $AuditObject.MaximumRolloverFiles
            }
        }
    }

    # Add optional parameters if they have values
    if ($null -ne $AuditObject.OnFailure)
    {
        $parameters['OnFailure'] = $AuditObject.OnFailure
    }

    if ($AuditObject.QueueDelay -gt 0)
    {
        $parameters['QueueDelay'] = $AuditObject.QueueDelay
    }

    if ($AuditObject.Filter)
    {
        $parameters['AuditFilter'] = $AuditObject.Filter
    }

    # Use provided GUID or existing GUID
    if ($PSBoundParameters.ContainsKey('AuditGuid'))
    {
        $parameters['AuditGuid'] = $AuditGuid
    }
    elseif ($AuditObject.Guid -and $AuditObject.Guid -ne '00000000-0000-0000-0000-000000000000')
    {
        $parameters['AuditGuid'] = $AuditObject.Guid
    }

    return $parameters
}
