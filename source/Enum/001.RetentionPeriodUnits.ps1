<#
    .SYNOPSIS
        Enum for change tracking retention period units.

    .DESCRIPTION
        This enum represents the units for the change tracking retention period.
        The value None (0) indicates change tracking is not enabled or no unit
        is specified.
#>
[Flags()]
enum RetentionPeriodUnits
{
    None    = 0
    Days    = 1
    Hours   = 2
    Minutes = 3
}
